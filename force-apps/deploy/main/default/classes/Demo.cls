public with sharing class Demo {
	private static String simulatorName = 'SIMULATOR';

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
	public static void deleteTempRecords() {
		delete [SELECT Id FROM ETOrchestrateDC__DCO_DmoReceived__c];
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

	@AuraEnabled
	public static Map<String, List<SObject>> getDataToRandomize() {
		Map<String, List<SObject>> output = new Map<String, List<SObject>>();
		output.put(
			'contacts',
			[
				SELECT Id, PersonName__c, CustomerId__c, DateBirth__c, Phone, OtherPhone, MobilePhone, HomePhone, AssistantPhone
				FROM Contact
				ORDER BY CustomerId__c
			]
		);
		output.put('orders', [SELECT Id, Name, OrderCreatedDate__c, PromiseDate__c, SoldToCustomer__c FROM Order__c]);
		return output;
	}

	@AuraEnabled
	public static void saveRandomizedData(List<SObject> data) {
		update data;
	}

	@AuraEnabled
	public static void createSimulationData() {
		deleteSimulationData();
		List<ETOrchestrateDC__DCO_Master__c> masters = new List<ETOrchestrateDC__DCO_Master__c>();
		masters.add(
			new ETOrchestrateDC__DCO_Master__c(
				Name = simulatorName + ' 01: Normalize Phones',
				ETOrchestrateDC__FlowName__c = 'Individuals',
				ETOrchestrateDC__DataSource__c = 'OrchestrateDC_Customers*',
				ETOrchestrateDC__IsActive__c = false,
				ETOrchestrateDC__ActionType__c = 'Data Transform',
				ETOrchestrateDC__ActionName__c = 'Normalize Phone Numbers',
				ETOrchestrateDC__Status__c = 'New'
			)
		);
		masters.add(
			new ETOrchestrateDC__DCO_Master__c(
				Name = simulatorName + ' 02: Create buckets',
				ETOrchestrateDC__FlowName__c = 'Contact Point Phones',
				ETOrchestrateDC__DataSource__c = 'NormalizePhoneNumbers',
				ETOrchestrateDC__IsActive__c = false,
				ETOrchestrateDC__ActionType__c = 'Identity Resolution',
				ETOrchestrateDC__ActionName__c = 'ETOrchestrateDC',
				ETOrchestrateDC__MaxFrequency__c = '1 D',
				ETOrchestrateDC__Status__c = 'New'
			)
		);
		masters.add(
			new ETOrchestrateDC__DCO_Master__c(
				Name = simulatorName + ' 03: Calculate RFM',
				ETOrchestrateDC__FlowName__c = 'Unified Individuals',
				ETOrchestrateDC__DataSource__c = 'ANY',
				ETOrchestrateDC__IsActive__c = false,
				ETOrchestrateDC__ActionType__c = 'Calculated Insight',
				ETOrchestrateDC__ActionName__c = 'RFM__cio',
				ETOrchestrateDC__MaxFrequency__c = '1 H',
				ETOrchestrateDC__Status__c = 'New'
			)
		);
		masters.add(
			new ETOrchestrateDC__DCO_Master__c(
				Name = simulatorName + ' 04: Publish Top Customers',
				ETOrchestrateDC__FlowName__c = 'Calculated Insights',
				ETOrchestrateDC__DataSource__c = 'ANY',
				ETOrchestrateDC__IsActive__c = false,
				ETOrchestrateDC__ActionType__c = 'Publish Segment',
				ETOrchestrateDC__ActionName__c = 'Top Adult Customers',
				ETOrchestrateDC__MaxFrequency__c = '30 M',
				ETOrchestrateDC__Status__c = 'New'
			)
		);
		insert masters;
	}

	@AuraEnabled
	public static void deleteSimulationData() {
		String prefix = simulatorName + '%';
		delete [SELECT Id FROM ETOrchestrateDC__DCO_Master__c WHERE Name LIKE :prefix];
	}
}
