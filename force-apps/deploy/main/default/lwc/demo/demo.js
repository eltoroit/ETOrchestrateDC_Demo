import { LightningElement } from "lwc";
import resetMasters from "@salesforce/apex/Demo.resetMasters";
import deleteTempRecords from "@salesforce/apex/Demo.deleteTempRecords";
import createMasterRecords from "@salesforce/apex/Demo.createMasterRecords";

export default class Demo extends LightningElement {
	isLoading = false;

	onViewMasterRecords() {
		window.open("/lightning/o/ETOrchestrateDC__DCO_Master__c/list?filterName=ETOrchestrateDC__All", "MaterRecords").focus();
	}

	onView__mdt() {
		window.open("/lightning/setup/CustomMetadata/home", "mdt").focus();
	}

	onShowTimeQueue() {
		window.open("/lightning/setup/DataManagementManageWorkflowQueue/home", "timeQueue").focus();
	}

	async onCreateMasterData() {
		this.isLoading = true;
		await createMasterRecords();
		this.isLoading = false;
	}

	async onResetData() {
		this.isLoading = true;
		await resetMasters();
		this.isLoading = false;
	}

	async onDeleteTempRecords() {
		this.isLoading = true;
		await deleteTempRecords();
		this.isLoading = false;
	}
}
