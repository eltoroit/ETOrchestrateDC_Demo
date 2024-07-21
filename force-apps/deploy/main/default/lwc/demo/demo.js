import { LightningElement } from "lwc";
import resetMasters from "@salesforce/apex/Demo.resetMasters";
import simulateIngestAPI from "@salesforce/apex/Demo.simulateIngestAPI";

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

	onModify__mdt() {
		window.open("/lightning/setup/CustomMetadata/home", "mdt").focus();
	}

	onShowTimeQueue() {
		window.open("/lightning/setup/DataManagementManageWorkflowQueue/home", "timeQueue").focus();
	}
}
