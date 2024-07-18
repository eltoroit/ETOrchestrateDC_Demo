Integer accNumber = 0;
List<Account> accs = [SELECT Id FROM Account ORDER BY Name];
List<Contact> cts = [SELECT Id, Phone, IndividualId__c FROM Contact ORDER BY IndividualId__c];

for (Contact ct : cts) {
	ct.AccountId = accs[accNumber++].Id;
	if (accNumber >= accs.size()) {
		accNumber = 0;
	}
}
update cts;
