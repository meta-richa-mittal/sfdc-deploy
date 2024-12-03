@isTest
private class PriceLevelTest {
	@testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
	static testMethod void testPriceLevel() {
		
		String priceLevelName = 'Default Price Level';
		TestUtil.createPriceLevel(true, priceLevelName, 'MSRP', 10 , true, true);
		
		Price_Level__c defaultPriceLevel = [Select Id, Name__c, Default__c, Description__c, Part_Price_Base__c, Discount_Markup__c, Labour_Rate__c, Active__c from Price_Level__c Where name__c=:priceLevelName Limit 1];
		PriceLevel priceLevelObj = new PriceLevel(defaultPriceLevel);
		
		System.assertEquals(priceLevelName, defaultPriceLevel.name__c);
		System.assertEquals(true, defaultPriceLevel.Default__c);
	}
	
	static testMethod void testFieldsList() {
		
		List<String> fieldsList = PriceLevel.fieldsList();
		
		System.assertNotEquals(null, fieldsList);
		System.assertEquals(8, fieldsList.size());
	}
}