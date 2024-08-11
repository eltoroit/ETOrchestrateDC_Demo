List<ETOrchestrateDC__DCO_Master__c> masters = [
	SELECT
		Id,
		Name,
		ETOrchestrateDC__ActionName__c,
		ETOrchestrateDC__ActionType__c,
		ETOrchestrateDC__DataSource__c,
		ETOrchestrateDC__FlowName__c,
		ETOrchestrateDC__IsActive__c,
		ETOrchestrateDC__MaxFrequency__c,
		ETOrchestrateDC__Status__c
	FROM ETOrchestrateDC__DCO_Master__c
];

String code = '\n';
code += '=== === === === === \n';
code += 'Delete [SELECT Id FROM ETOrchestrateDC__DCO_Master__c];\n';
code += 'List<ETOrchestrateDC__DCO_Master__c> masters = new List<ETOrchestrateDC__DCO_Master__c>();\n';
for (ETOrchestrateDC__DCO_Master__c master : masters) {
	code += 'masters.add(new ETOrchestrateDC__DCO_Master__c( \n';
	code += '    Name = \'' + master.Name + '\', \n';
	code += '    ETOrchestrateDC__FlowName__c = \'' + master.ETOrchestrateDC__FlowName__c + '\', \n';
	code += '    ETOrchestrateDC__DataSource__c = \'' + master.ETOrchestrateDC__DataSource__c + '\', \n';
	code += '    ETOrchestrateDC__ActionType__c = \'' + master.ETOrchestrateDC__ActionType__c + '\', \n';
	code += '    ETOrchestrateDC__ActionName__c = \'' + master.ETOrchestrateDC__ActionName__c + '\', \n';
	code += '    ETOrchestrateDC__IsActive__c = ' + master.ETOrchestrateDC__IsActive__c + ', \n';
	code += '    ETOrchestrateDC__Status__c = \'' + master.ETOrchestrateDC__Status__c + '\'';
	if (master.ETOrchestrateDC__MaxFrequency__c != null) {
		code += ',\n';
		code += '    ETOrchestrateDC__MaxFrequency__c = \'' + master.ETOrchestrateDC__MaxFrequency__c + '\'';
	}
	code += '\n';
	code += '));\n';
}
code += 'insert masters;\n';
code += '=== === === === === \n';
System.debug(code);
