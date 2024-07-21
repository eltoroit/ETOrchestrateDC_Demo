public with sharing class Demo {
	@AuraEnabled
	public static void resetMasters() {
		delete [SELECT Id FROM ETOrchestrateDC__DCO_DmoReceived__c];
		delete [SELECT Id FROM ETOrchestrateDC__DCO_DmoScheduled__c];

		System.debug('DEBUG: Reseting masters');
		List<ETOrchestrateDC__DCO_Master__c> masters = [SELECT Id FROM ETOrchestrateDC__DCO_Master__c];
		for (ETOrchestrateDC__DCO_Master__c master : masters) {
			master.ETOrchestrateDC__Message__c = null;
			master.ETOrchestrateDC__LastRun__c = null;
			master.ETOrchestrateDC__NextRun__c = null;
			master.ETOrchestrateDC__Status__c = 'New';
		}
		update masters;
	}

	@AuraEnabled
	public static void simulateIngestAPI() {
		System.debug('DEBUG: Simulating Ingest API');
		// String strDTTM = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
		String strDTTM = Datetime.now().format('yyyy-MM-dd\'T\'HH');
		List<ETOrchestrateDC__DCO_DmoReceived__c> logs = new List<ETOrchestrateDC__DCO_DmoReceived__c>();
		for (Integer i = 0; i < 5; i++) {
			ETOrchestrateDC__DCO_DmoReceived__c dmoLogger = new ETOrchestrateDC__DCO_DmoReceived__c();
			dmoLogger.ETOrchestrateDC__Message__c = 'APEX_SIM: simulateIngestAPI';
			dmoLogger.ETOrchestrateDC__FlowName__c = 'Individuals';
			dmoLogger.ETOrchestrateDC__SourceObject__c = 'OrchestrateDC_Customers ' + strDTTM;
			logs.add(dmoLogger);
		}
		insert logs;
	}
}