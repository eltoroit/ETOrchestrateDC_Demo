import Utils from "c/utils";
import { LightningElement } from "lwc";
// import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Apex Methods
import clearTable from "@salesforce/apex/Demo.clearTable";
import getMetadata from "@salesforce/apex/Demo.getMetadata";
import loadAccount from "@salesforce/apex/Demo.loadAccount";
import loadProduct__c from "@salesforce/apex/Demo.loadProduct";
import loadContact from "@salesforce/apex/Demo.loadContact";
import loadLead from "@salesforce/apex/Demo.loadLead";
import loadOrder__c from "@salesforce/apex/Demo.loadOrder";
import loadOrderItem__c from "@salesforce/apex/Demo.loadOrderItem";

// Static Resources
import Data_Account from "@salesforce/resourceUrl/Data_Account";
import Data_Contact from "@salesforce/resourceUrl/Data_Contact";
import Data_Lead from "@salesforce/resourceUrl/Data_Lead";
import Data_Order from "@salesforce/resourceUrl/Data_Order";
import Data_OrderItem from "@salesforce/resourceUrl/Data_OrderItem";
import Data_Product from "@salesforce/resourceUrl/Data_Product";

let loadDataIds = {};
const dataItems = {
	Data_Account: { sr: Data_Account, json: "Data_Account", salesforce: "Account", loader: loadAccount },
	Data_Product: { sr: Data_Product, json: "Data_Product", salesforce: "Product__c", loader: loadProduct__c },
	Data_Contact: { sr: Data_Contact, json: "Data_Contact", salesforce: "Contact", loader: loadContact },
	Data_Lead: { sr: Data_Lead, json: "Data_Lead", salesforce: "Lead", loader: loadLead },
	Data_Order: { sr: Data_Order, json: "Data_Order", salesforce: "Order__c", loader: loadOrder__c },
	Data_OrderItem: { sr: Data_OrderItem, json: "Data_OrderItem", salesforce: "OrderItem__c", loader: loadOrderItem__c }
};
// In the order they are supposed to be loaded
const dataItemsOrder = ["Data_Account", "Data_Product", "Data_Contact", "Data_Lead", "Data_Order", "Data_OrderItem"];

export default class LoadData extends LightningElement {
	data = {};
	loading = false;
	message = "Data Loader";

	async onDeleteDataClick() {
		const deleteRecordsViaApex = async ({ sObjName }) => {
			this.message = `Deleting ${sObjName}`;
			console.log(`*** ${this.message}`);
			await clearTable({ sObjName });
		};

		this.loading = true;
		try {
			await deleteRecordsViaApex({ sObjName: "Case" });
			await deleteRecordsViaApex({ sObjName: "Entitlement" });
			// Loop in reverse order
			for (let i = dataItemsOrder.length - 1; i >= 0; i--) {
				let sObjName = dataItems[dataItemsOrder[i]].salesforce;
				await deleteRecordsViaApex({ sObjName }); // eslint-disable-line no-await-in-loop
			}
		} catch (ex) {
			this.showErrors({ ex, title: "Error Deleting Data" });
			throw ex;
		}
		this.loading = false;
		this.message = "Data Loader";
	}

	async onLoadDataClick() {
		try {
			// First delete all records
			await this.onDeleteDataClick();

			// Then reload data from static resources
			await this.initializeData();

			// Now create the new ones
			this.loading = true;
			for (const dataItemName of dataItemsOrder) {
				let dataItem = dataItems[dataItemName];
				this.message = `Creating ${dataItem.salesforce}`;
				console.log(`*** ${this.message}`);
				let chunks = this.getData({ dataItem });
				for (const records of chunks) {
					// eslint-disable-next-line no-await-in-loop
					await dataItem
						.loader({ jsonRecords: JSON.stringify(records) })
						// eslint-disable-next-line no-loop-func
						.then((output) => {
							console.log(`***`, JSON.parse(JSON.stringify(output)));
							if (Object.keys(output.IDS).length !== output.RECORDS.length) {
								console.log(`*** ${Object.keys(output.IDS).length} !== ${output.RECORDS.length}`);
								debugger;
							}
							loadDataIds = { ...loadDataIds, ...output.IDS };
						})
						.catch((ex) => {
							this.showErrors({ ex, title: `Error Loading ${dataItem.salesforce} Data` });
						});
				}
			}
			this.loading = false;
			this.message = "Data Loader";
			console.log(`***`, "DONE");
		} catch (ex) {
			this.showErrors({ ex, title: `Error Loading Data` });
		}
	}

	async initializeData() {
		const fetchSR = async ({ staticResource }) => {
			let response = await fetch(staticResource, { method: "GET" });
			let jsonData = await response.json();
			jsonData = JSON.parse(JSON.stringify(jsonData));
			let output = jsonData.records.map((record) => {
				delete record.attributes;
				return record;
			});
			if (jsonData.sizeTotal !== jsonData.sizeFetched || jsonData.sizeTotal !== jsonData.length) {
				debugger;
			}
			return output;
		};

		this.loading = true;
		this.message = "Initializing Data...";
		console.log(`***`, this.message);

		this.data = {};
		loadDataIds = {};

		// Get meatadata
		try {
			let result = await getMetadata({ sObjectNames: dataItemsOrder.map((dataItemName) => dataItems[dataItemName].salesforce) });
			dataItemsOrder.forEach((dataItemName) => {
				let dataItem = dataItems[dataItemName];
				dataItem.dfr = {};
				let objName = dataItem.salesforce;
				Object.keys(result[objName]).forEach((fieldName) => {
					let dfr = JSON.parse(result[objName][fieldName]);
					dataItem.dfr[dfr.name] = dfr;
				});
			});
		} catch (ex) {
			this.showErrors({ ex, title: `Error Retrieving Metadata` });
		}

		// Gate data
		await Promise.allSettled(
			dataItemsOrder.map((dataItemName) => {
				let dataItem = dataItems[dataItemName];
				return fetchSR({ staticResource: dataItem.sr })
					.then((result) => {
						this.data[dataItem.json] = result;
						this.cleanData({ dataItem });
					})
					.catch((ex) => {
						this.showErrors({ ex, title: `Error Loading ${dataItemName} Static Resource` });
					});
			})
		);
		console.log(`***`, JSON.parse(JSON.stringify(this.data)));
		console.log(`***`, JSON.parse(JSON.stringify(dataItems)));
		this.loading = false;
		this.message = "Data Loader";
	}

	cleanData({ dataItem }) {
		this.data[dataItem.json] = this.data[dataItem.json].map((record) => {
			let fields = {};
			Object.keys(record).forEach((fieldName) => {
				let fieldValue = record[fieldName];
				if (dataItem.dfr[fieldName]) {
					if (fieldValue !== null && fieldValue !== undefined) {
						if (loadDataIds[fieldValue]) {
							// If it's an Id that we have alredy loaded, then replace with new Id.
							fields[fieldName] = loadDataIds[fieldValue];
						} else {
							fields[fieldName] = fieldValue;
						}
					} else {
						// console.log(`*** ${dataItem.salesforce}.${fieldName} is null`);
					}
				} else {
					console.log(`*** ${dataItem.salesforce}.${fieldName} does NOT exist`);
				}
			});
			return fields;
		});
	}

	getData({ dataItem }) {
		// Randomize It
		switch (dataItem.json) {
			case "Data_Contact": {
				this.randomizeContacts();
				break;
			}
			case "Data_Order": {
				this.randomizeOrders();
				break;
			}
			default:
				break;
		}

		// Clean data
		this.cleanData({ dataItem });

		// Chunk it!
		const chunks = [];
		const chunkSize = 1e3;
		const data = this.data[dataItem.json];
		for (let i = 0; i < data.length; i += chunkSize) {
			chunks.push(data.slice(i, i + chunkSize));
		}
		return chunks;
	}

	randomizeContacts() {
		const getRandomNumber = (min, max, requiredLength) => {
			// Ensure min and max are integers
			min = Math.ceil(min);
			max = Math.floor(max);

			// Return a random number between min and max (inclusive)
			let randomValue = Math.floor(Math.random() * (max - min + 1)) + min;
			randomValue = String(randomValue).padStart(requiredLength, "0");
			return randomValue;
		};

		const makeRandomPhone = (oldPhone) => {
			let newPhone = oldPhone.substring(0, oldPhone.length - 4);
			newPhone += getRandomNumber(0, 9999, 4);
			return newPhone;
		};

		console.log("*** Randomizing Contacts");
		let data = [];
		try {
			// First 61 names are funny :-)
			let funnyNamesCount = 61;
			let contacts = this.data[dataItems.Data_Contact.json];
			data = [...contacts];
			data.forEach((record, idx) => {
				// Ramdom Birthdate
				let strNewDTTM = "";
				let isFunny = Number(record.CustomerId__c.split("-")[1]) <= funnyNamesCount;
				let year = isFunny ? 1950 : getRandomNumber(1951, 2020, 4);
				let month = isFunny ? String(Math.floor(idx / 10) + 1).padStart(2, "0") : getRandomNumber(1, 12, 2);
				// Every month has at least 28 days
				let day = isFunny ? String(Math.floor(idx % 10) + 1).padStart(2, "0") : getRandomNumber(1, 28, 2);
				strNewDTTM += `${year}-${month}-${day}T`; // Date
				strNewDTTM += `${getRandomNumber(0, 23, 2)}:${getRandomNumber(0, 59, 2)}:${getRandomNumber(0, 59, 2)}.${getRandomNumber(0, 999, 3)}z`; // Time
				record.DateBirth__c = new Date(strNewDTTM);

				// Random Phones
				record.Phone = makeRandomPhone(record.Phone);
				record.HomePhone = makeRandomPhone(record.HomePhone);
				record.OtherPhone = makeRandomPhone(record.OtherPhone);
				record.MobilePhone = makeRandomPhone(record.MobilePhone);
				record.AssistantPhone = makeRandomPhone(record.AssistantPhone);
			});
			this.data[dataItems.Data_Contact.json] = data;
		} catch (ex) {
			this.showErrors({ ex, title: `Error Randomizing Contacts` });
		}
	}

	randomizeOrders() {
		const getCreatedDate = ({ offset }) => {
			// 6 months ago, but the hour changes per record
			const dttm = new Date();
			dttm.setMonth(dttm.getMonth() - 6);
			dttm.setHours(0, 0, 0, 0);
			dttm.setMinutes(dttm.getMinutes() + offset);
			return dttm.toJSON();
		};
		const getPromisedDate = () => {
			// Calculate the date 5 months ago
			const fiveMonthsAgo = new Date();
			fiveMonthsAgo.setMonth(fiveMonthsAgo.getMonth() - 5);

			// Calculate the date 1 month in the future
			const oneMonthInFuture = new Date();
			oneMonthInFuture.setMonth(oneMonthInFuture.getMonth() + 1);

			// Generate a random date between fiveMonthsAgo and oneMonthInFuture
			const randomTimestamp = Math.random() * (oneMonthInFuture.getTime() - fiveMonthsAgo.getTime()) + fiveMonthsAgo.getTime();
			return new Date(randomTimestamp).toJSON();
		};

		console.log("*** Randomizing Orders");
		let orders = this.data[dataItems.Data_Order.json];
		let contacts = this.data[dataItems.Data_Contact.json];
		const updatedOrders = [];
		try {
			// Shuffle the orders array
			const shuffledOrders = [...orders].sort(() => Math.random() - 0.5);

			// Calculate the average number of orders per contact
			const avgOrdersPerContact = Math.ceil(orders.length / contacts.length);

			// Variable to keep track of the current contact index
			let currentOrderIndex = 0;
			let currentContactIndex = 0;

			// Distribute orders to contacts using forEach
			shuffledOrders.forEach((order, offset) => {
				// Assign the order to the current contact
				const contact = contacts[currentContactIndex];
				order.SoldToCustomer__c = contact.Id;
				// Compute date time fields
				order.OrderCreatedDate__c = getCreatedDate({ offset });
				order.PromiseDate__c = getPromisedDate();
				updatedOrders.push(order);

				// Next order and possibly contact
				currentOrderIndex++;
				if (currentOrderIndex >= avgOrdersPerContact) {
					currentContactIndex = (currentContactIndex + 1) % contacts.length;
					currentOrderIndex = 0;
				}
			});
			this.data[dataItems.Data_Order.json] = updatedOrders;
		} catch (ex) {
			this.showErrors({ ex, title: `Error Randomizing Orders` });
		}
	}

	showErrors({ ex, title }) {
		if (!title) {
			title = "Error Communication With Server";
		}
		Utils.reportError(this, { error: ex, title });
	}
}
