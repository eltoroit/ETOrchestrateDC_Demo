public void callFlow(List<SObject> records, String dcType, String dcValue) {
	if (records.size() == 1) {
		Map<String, String> inputParams = new Map<String, String>();
		inputParams.put('DCType', dcType);
		inputParams.put('DCValue', records[0].Id);
		System.debug(inputParams);
		// Flow.Interview.DCO_Steps_Runner flowInstance = new Flow.Interview.DCO_Steps_Runner(inputParams);
		Flow.Interview.ETOrchestrateDC.DCO_Steps_Runner flowInstance = new Flow.Interview.ETOrchestrateDC.DCO_Steps_Runner(inputParams);
		flowInstance.start();
		String output = (String) flowInstance.getVariableValue('Output');
		Boolean isSuccess = (Boolean) flowInstance.getVariableValue('IsSuccess');
		if (isSuccess) {
			System.debug(output);
		} else {
			throw new AuraException(output);
		}
	} else if (records.size() == 0) {
		throw new AuraException('Expecting one Data Cloud step (found ' + records.size() + '). [' + dcType + ' = ' + dcValue + ']');
	} else {
		throw new AuraException('Expecting one Data Cloud step (found ' + records.size() + '). [' + dcType + ' = ' + dcValue + ']');
	}
}

String name = 'Top Or Adult Customers';
List<MarketSegment> records = [
	SELECT Id, Name
	FROM MarketSegment
	WHERE Name = :name
	WITH USER_MODE
];
System.debug(records);
callFlow(records, 'MarketSegment', name);
