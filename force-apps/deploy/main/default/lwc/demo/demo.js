import { LightningElement } from "lwc";
import resetMasters from "@salesforce/apex/Demo.resetMasters";
import simulateIngestAPI from "@salesforce/apex/Demo.simulateIngestAPI";
import getDataToRandomize from "@salesforce/apex/Demo.getDataToRandomize";
import saveRandomizedData from "@salesforce/apex/Demo.saveRandomizedData";

export default class Demo extends LightningElement {
	isLoading = false;
	async onResetData() {
		this.isLoading = true;
		await resetMasters();
		this.isLoading = false;
	}

	async onRunSimulator() {
		this.isLoading = true;
		await simulateIngestAPI();
		this.isLoading = false;
	}

	onView__mdt() {
		window.open("/lightning/setup/CustomMetadata/home", "mdt").focus();
	}

	onShowTimeQueue() {
		window.open("/lightning/setup/DataManagementManageWorkflowQueue/home", "timeQueue").focus();
	}

	async onRandomizeData() {
		this.isLoading = true;
		let data = await getDataToRandomize();
		data = JSON.parse(JSON.stringify(data));
		console.log(data);
		debugger;
		data.contacts = this.randomContacts({ contacts: data.contacts });
		data.orders = this.randomOrders({ contacts: data.contacts, orders: data.orders });
		await saveRandomizedData({ data: [...data.contacts, ...data.orders] });
		this.isLoading = false;
	}

	randomContacts({ contacts }) {
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

		let data = [];
		try {
			// First 61 names are funny :-)
			let funnyNamesCount = 61;
			data = [...contacts];
			data.forEach((record, idx) => {
				// Ramdom Birthdate
				let strNewDTTM = "";
				let year = idx < funnyNamesCount ? 1950 : getRandomNumber(1951, 2020, 4);
				let month = idx < funnyNamesCount ? String(Math.floor(idx / 10) + 1).padStart(2, "0") : getRandomNumber(1, 12, 2);
				// Every month has at least 28 days
				let day = idx < funnyNamesCount ? String(Math.floor(idx % 10) + 1).padStart(2, "0") : getRandomNumber(1, 28, 2);
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
		} catch (ex) {
			debugger;
			throw ex;
		}
		return data;
	}

	randomOrders({ contacts, orders }) {
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
			shuffledOrders.forEach((order) => {
				// Assign the order to the current contact
				const contact = contacts[currentContactIndex];
				order.SoldToCustomer__c = contact.Id;
				updatedOrders.push(order);

				// Next order and possibly contact
				currentOrderIndex++;
				if (currentOrderIndex >= avgOrdersPerContact) {
					currentContactIndex = (currentContactIndex + 1) % contacts.length;
					currentOrderIndex = 0;
				}
			});
		} catch (ex) {
			debugger;
			throw ex;
		}
		return updatedOrders;
	}
}
