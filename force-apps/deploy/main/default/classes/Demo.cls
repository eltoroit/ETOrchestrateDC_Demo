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

	@AuraEnabled
	public static List<DataStream> getDataStreamStatus() {
		return [SELECT Id, Name, LastModifiedDate, ImportRunStatus, LastRefreshDate, LastDataChangeStatusDateTime FROM DataStream ORDER BY Name ASC];
	}

	@AuraEnabled
	public static Map<String, Object> loadTable(String jsonRecords, String SObjectName) {
		Map<Id, Id> mapIDs = new Map<Id, Id>();
		Map<String, Object> output = new Map<String, Object>();
		Map<String, String> mapKey2Id_SR = new Map<String, String>();
		Map<String, String> mapKey2Id_DB = new Map<String, String>();

		// Make a list of explicit data type
		Type listType = Type.forName('List<' + SObjectName + '>');
		List<SObject> records_SR = (List<SObject>) JSON.deserialize(jsonRecords, listType);

		// Save Old Ids
		for (SObject sobj_SR : records_SR) {
			String key = (String) sobj_SR.get('ETODC_Key__c');
			mapKey2Id_SR.put(key, sobj_SR.Id);
		}

		// Find Ids for keys in database
		Set<String> keys = mapKey2Id_SR.keySet();
		for (SObject sobj_DB : Database.query('SELECT Id, ETODC_Key__c FROM ' + SObjectName + ' WHERE ETODC_Key__c in :keys')) {
			mapKey2Id_DB.put((String) sobj_DB.get('ETODC_Key__c'), sobj_DB.Id);
		}

		// Update the records_SR with the Database Ids
		for (SObject sobj_SR : records_SR) {
			Id Id_DB = null;
			String key = (String) sobj_SR.get('ETODC_Key__c');
			if (mapKey2Id_DB.containsKey(key)) {
				Id_DB = mapKey2Id_DB.get(key);
			}
			sobj_SR.Id = Id_DB;
		}
		upsert records_SR;

		// Create map of Ids
		for (SObject sobj_SR : records_SR) {
			String key = (String) sobj_SR.get('ETODC_Key__c');
			mapIDs.put(mapKey2Id_SR.get(key), sobj_SR.Id);
		}

		// Load the data
		output.put('IDS', mapIDs);
		output.put('RECORDS', records_SR);
		return output;
	}
}
