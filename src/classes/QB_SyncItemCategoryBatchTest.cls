@isTest
global without sharing class QB_SyncItemCategoryBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
		List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
		customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
		headerList.add(header);
    }

    static testMethod void itemCategoryPayLoad() {
		//Integration Metadata
		Test.startTest();
		List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Item' , IFWConfigObj[0].Id);
        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        Category__c testCategory_III = TestUtil.createCategory(false, 'Test Category III');
        testCategory_III.Income_GL__c = '35';
        insert new List<SObject>{vendor,testCategory_III};
       	Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
       	Test.stopTest();
       	List<Category__c> itemRes = [Select Id,Name,AccountingId__c,availForQBSync__c from Category__c Limit 1];
       	system.assertEquals(itemRes[0].Name,'Test Category III');
       	testCategory_III.Description__c = 'Test Category III for Testing';
        update testCategory_III;
	}
}