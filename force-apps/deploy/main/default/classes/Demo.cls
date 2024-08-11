public with sharing class Demo {
	private static String simulatorName = 'SIMULATOR';

	@AuraEnabled
	public static void createMasterRecords() {
		try {
			delete [SELECT Id FROM ETOrchestrateDC__DCO_Master__c];
			List<ETOrchestrateDC__DCO_Master__c> masters = new List<ETOrchestrateDC__DCO_Master__c>();
			masters.add(
				new ETOrchestrateDC__DCO_Master__c(
					Name = 'DEMO 01: Normalize Phones',
					ETOrchestrateDC__FlowName__c = 'Individuals',
					ETOrchestrateDC__DataSource__c = 'Contact*',
					ETOrchestrateDC__ActionType__c = 'Data Transform',
					ETOrchestrateDC__ActionName__c = 'Normalize Phone Numbers',
					ETOrchestrateDC__IsActive__c = true,
					ETOrchestrateDC__Status__c = 'New'
				)
			);
			masters.add(
				new ETOrchestrateDC__DCO_Master__c(
					Name = 'DEMO 02: Create buckets',
					ETOrchestrateDC__FlowName__c = 'Contact Point Phones',
					ETOrchestrateDC__DataSource__c = 'NormalizePhoneNumbers',
					ETOrchestrateDC__ActionType__c = 'Identity Resolution',
					ETOrchestrateDC__ActionName__c = 'Create Buckets',
					ETOrchestrateDC__IsActive__c = true,
					ETOrchestrateDC__Status__c = 'New',
					ETOrchestrateDC__MaxFrequency__c = '1 D'
				)
			);
			masters.add(
				new ETOrchestrateDC__DCO_Master__c(
					Name = 'DEMO 03: Calculate RFM',
					ETOrchestrateDC__FlowName__c = 'Unified Individuals',
					ETOrchestrateDC__DataSource__c = 'ANY',
					ETOrchestrateDC__ActionType__c = 'Calculated Insight',
					ETOrchestrateDC__ActionName__c = 'RFM__cio',
					ETOrchestrateDC__IsActive__c = true,
					ETOrchestrateDC__Status__c = 'New',
					ETOrchestrateDC__MaxFrequency__c = '1 H'
				)
			);
			masters.add(
				new ETOrchestrateDC__DCO_Master__c(
					Name = 'DEMO 04: Publish Top Or Adult Customers',
					ETOrchestrateDC__FlowName__c = 'Calculated Insights',
					ETOrchestrateDC__DataSource__c = 'ANY',
					ETOrchestrateDC__ActionType__c = 'Publish Segment',
					ETOrchestrateDC__ActionName__c = 'Top Or Adult Customers',
					ETOrchestrateDC__IsActive__c = true,
					ETOrchestrateDC__Status__c = 'New',
					ETOrchestrateDC__MaxFrequency__c = '30 M'
				)
			);
			insert masters;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

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

	@AuraEnabled
	public static void clearTable(String sObjName) {
		delete Database.query('SELECT Id FROM ' + sObjName);
	}

	@AuraEnabled
	public static Object getMetadata(List<String> sObjectNames) {
		Map<String, Object> output = new Map<String, Object>();
		Map<String, Schema.SObjectType> mapSObjects = Schema.getGlobalDescribe();

		for (String sObjectName : sObjectNames) {
			Map<String, Object> item = new Map<String, Object>();
			Schema.SObjectType tSObj = mapSObjects.get(sObjectName);
			Schema.DescribeSObjectResult drSObj = tSObj.getDescribe();
			Map<String, Schema.SObjectField> mapFields = drSObj.fields.getMap();
			for (String fieldName : mapFields.keySet()) {
				Schema.SObjectField tField = mapFields.get(fieldName);
				Schema.DescribeFieldResult drField = tField.getDescribe();
				String jsonField = JSON.serialize(drField);
				item.put(fieldName, jsonField);
			}
			output.put(sObjectName, item);
		}
		return output;
	}

	@AuraEnabled
	public static Map<String, Object> loadAccount(String jsonRecords) {
		Map<String, Object> output = new Map<String, Object>();
		List<Account> records = (List<Account>) JSON.deserialize(jsonRecords, List<Account>.class);
		output.put('IDS', loadTable(records));
		output.put('RECORDS', records);
		return output;
	}
	@AuraEnabled
	public static Map<String, Object> loadProduct(String jsonRecords) {
		Map<String, Object> output = new Map<String, Object>();
		List<Product__c> records = (List<Product__c>) JSON.deserialize(jsonRecords, List<Product__c>.class);
		output.put('IDS', loadTable(records));
		output.put('RECORDS', records);
		return output;
	}
	@AuraEnabled
	public static Map<String, Object> loadContact(String jsonRecords) {
		Map<String, Object> output = new Map<String, Object>();
		List<Contact> records = (List<Contact>) JSON.deserialize(jsonRecords, List<Contact>.class);
		output.put('IDS', loadTable(records));
		output.put('RECORDS', records);
		return output;
	}
	@AuraEnabled
	public static Map<String, Object> loadLead(String jsonRecords) {
		Map<String, Object> output = new Map<String, Object>();
		List<Lead> records = (List<Lead>) JSON.deserialize(jsonRecords, List<Lead>.class);
		output.put('IDS', loadTable(records));
		output.put('RECORDS', records);
		return output;
	}
	@AuraEnabled
	public static Map<String, Object> loadOrder(String jsonRecords) {
		Map<String, Object> output = new Map<String, Object>();
		List<Order__c> records = (List<Order__c>) JSON.deserialize(jsonRecords, List<Order__c>.class);
		output.put('IDS', loadTable(records));
		output.put('RECORDS', records);
		return output;
	}
	@AuraEnabled
	public static Map<String, Object> loadOrderItem(String jsonRecords) {
		Map<String, Object> output = new Map<String, Object>();
		List<OrderItem__c> records = (List<OrderItem__c>) JSON.deserialize(jsonRecords, List<OrderItem__c>.class);
		output.put('IDS', loadTable(records));
		output.put('RECORDS', records);
		return output;
	}

	@AuraEnabled
	public static Map<Id, Id> loadTable(List<SObject> records) {
		Map<Id, Id> output = new Map<Id, Id>();
		Map<Id, SObject> mapRecords = new Map<Id, SObject>();
		for (SObject record : records) {
			// Put the record with the old Id, but then clear it so the records can be inserrted
			mapRecords.put(record.Id, record);
			record.Id = null;
		}
		insert records;
		for (Id recordId : mapRecords.keySet()) {
			// Map the new Id to the old one
			output.put(recordId, mapRecords.get(recordId).Id);
		}
		return output;
	}
}
