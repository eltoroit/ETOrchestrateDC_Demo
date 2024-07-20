Integer rowNumber = 0;
List<Product__c> products = [SELECT Id, Name, MSRPAmount__c FROM Product__c];
List<Order__c> orders = [
	SELECT Id, Name, OrderCreatedDate__c, GrandTotalAmount__c, IsTaxExempt__c, PromiseDate__c, SoldToCustomer__c
	FROM Order__c
];
List<OrderItem__c> items = [
	SELECT Id, Name, DiscountPercent__c, ListPriceAmount__c, OrderedQuantity__c, Product__c, SalesOrder__c, UnitPriceAmount__c, LineTotal__c
	FROM OrderItem__c
];
// delete items;

items = new List<OrderItem__c>();
for (Order__c order : orders) {
	Integer numberOfItems = Math.round(Math.random() * 3) + 2; // 2 ~ 5
	for (Integer i = 0; i < numberOfItems; i++) {
		Integer productIndex = Integer.valueOf(Math.floor(Math.random() * products.size()));
		Product__c product = products[productIndex];
		OrderItem__c item = new OrderItem__c(
			DiscountPercent__c = Math.random() * 0.25, // 0 ~ 25%
			ListPriceAmount__c = product.MSRPAmount__c,
			OrderedQuantity__c = Math.round(Math.random() * 4) + 1, // 1 ~ 5
			Product__c = product.Id,
			SalesOrder__c = order.Id
		);
		items.add(item);
	}
}
System.debug(items.size());
insert items;

// Integer x = 0;
// System.debug(5 / x);

