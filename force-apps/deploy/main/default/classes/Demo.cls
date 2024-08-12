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
	public static void clearTable(String sObjName) {
		Map<String, Schema.SObjectType> mapSObjects = Schema.getGlobalDescribe();
		if (mapSObjects.containsKey(sObjName)) {
			delete Database.query('SELECT Id FROM ' + sObjName);
		}
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

	/*
	These multiple methods could be combined, if we apply some code like this....
		Type listType = Type.forName('List<Contact>');
		System.debug(listType.getName());
		
		String jsonRecords = '[{"Name": "Acme", "LastName": "Perez", "DateBirth__c":"1968-10-03T03:00:00", "NumberOfEmployees": 3900}]';
		List<SObject> records = (List<SObject>) JSON.deserialize(jsonRecords, listType);
		System.debug(records);
		insert records;
		System.debug('INSERTED: ' + records);
		
		Integer i = 0;
		System.debug(5/i);
	*/
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
