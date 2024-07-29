public void assignPermissionSet(String userId, String permissionSetName) {
	// Query the Permission Set ID based on the name
	System.debug(permissionSetName);
	PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
	System.debug(permSet);

	// Create the PermissionSetAssignment record
	PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permSet.Id);

	// Insert the PermissionSetAssignment record
	try {
		insert psa;
		System.debug('Permission Set assigned successfully.');
	} catch (DmlException e) {
		System.debug('An error occurred: ' + e.getMessage());
		throw e;
	}
}
// User u = [SELECT Id, Name FROM User WHERE Name = 'Platform Integration User'];
User u = [SELECT Id, Name FROM User WHERE Name = 'Automated Process'];
System.debug(u);
// System.debug('PermSet: psDemo');
// assignPermissionSet(u.Id, 'psDemo');
// System.debug('PermSet: psDataCloudData');
// assignPermissionSet(u.Id, 'psDataCloudData');
// System.debug('PermSet: ETOrchestrateDC');
// assignPermissionSet(u.Id, 'ETOrchestrateDC');
System.debug('PermSet: ETOrchestrateDC_AutomatedProcess');
assignPermissionSet(u.Id, 'ETOrchestrateDC_AutomatedProcess');
// System.debug('PermSet: ETOrchestrateDC_Credentials');
// assignPermissionSet(u.Id, 'ETOrchestrateDC_Credentials');
System.debug('Done');
