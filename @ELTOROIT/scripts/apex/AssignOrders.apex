Integer rowNumber = 0;
List<Order__c> orders = [SELECT Id FROM Order__c];
List<OrderItem__c> items = [SELECT Id FROM OrderItem__c];

for (OrderItem__c item : items) {
	item.SalesOrder__c = orders[rowNumber++].Id;
	if (rowNumber >= orders.size()) {
		rowNumber = 0;
	}
}
update items;
