@isTest
private class SOMPartInventoryBatchTest {
	
	@testsetup
	public static void setTestData() {
		TestDataFactory.createSOMConfig();
    	TestDataFactory.disableFLSChecks();
    	
    	SOM_Configuration__c somConfig = SOM_Configuration__c.getOrgDefaults();
        somConfig.Blackpurl_Heroku_Endpoint__c = 'https://blackpurl-som.herokuapp.com/SOMAPI';
        upsert somConfig;
    	
		Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
    	Part__c part1 = TestUtil.createPart(false, 'Part 1', vendor.Id, 'Test Part 1', testCategory.Id, 10, 21, 51, 100, 100);
    	Part__c part2 = TestUtil.createPart(false, 'Part 2', vendor.Id, 'Test Part 2', testCategory.Id, 11, 22, 52, 100, 100);
    	Part__c part3 = TestUtil.createPart(false, 'Part 3', vendor.Id, 'Test Part 3', testCategory.Id, 12, 23, 53, 100, 100);
    	Part__c part4 = TestUtil.createPart(false, 'Part 4', vendor.Id, 'Test Part 4', testCategory.Id, 13, 24, 54, 100, 100);
    	insert new List<Part__c>{part1, part2, part3, part4};
	}
   
	static testMethod void SOMPartInventoryBatchTest() {
		system.assertEquals(0, [Select Id from SOM_Integration__c].size());
		Test.startTest();
   		Database.executeBatch(new SOMPartInventoryBatch(system.today(), 5));
   		Test.stopTest();
   		
   		List<SOM_Integration__c> somIntegrationRecList = [Select Id, (Select Id from Attachments) from SOM_Integration__c];
   		system.assertEquals(1, somIntegrationRecList.size());
   		system.assertEquals(1, somIntegrationRecList[0].Attachments.size());
	}
   
}