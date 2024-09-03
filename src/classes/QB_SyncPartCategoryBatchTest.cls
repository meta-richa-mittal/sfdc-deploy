@isTest
global without sharing class QB_SyncPartCategoryBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }
    static testMethod void partCategoryPayload(){
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);
        BPScriptUtility.disbaleTrigger('PartFIFOBucketTrigger');
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        Account customer = TestUtil.createCustomer(true, 'testcustomer', 'customer@gmail.com', 'Jaipur', '8058704475');
        Account vendor = TestUtil.createVendor(true, 'testvendor');
        Category__c category = TestDataFactory.createCategory('categoryName');
        category.Type__c = 'Adjustment';
        category.Inventory_GL__c = 'Inventory_GL__c';
        category.COGS_GL__c = 'Inventory_GL__c';
        category.Income_GL__c = 'Inventory_GL__c';
        category.AccountingId__c = 'Category__r.AccountingId__c';
        DMLUtility.updateSobjectList('Category__c',category);

        Category__c categoryUpdate = TestDataFactory.createCategory('cnewName');
        categoryUpdate.Type__c = 'Adjustment';
        categoryUpdate.Inventory_GL__c = '67';
        categoryUpdate.COGS_GL__c = '86';
        categoryUpdate.Income_GL__c = '88';
        categoryUpdate.AccountingId__c = 'Category__r.AccountingId__c';
        DMLUtility.updateSobjectList('Category__c',categoryUpdate);

        Part__c partObject1 = TestDataFactory.createPart(vendor.id, 101,56 , 100, 20, 20, category.id);
        partObject1.Category__c = categoryUpdate.Id;
        partObject1.Avail_For_QB_Sync_Category__c = true;
        update partObject1;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();

        String query = 'SELECT Avail_For_QB_Sync_Category__c FROM Part__c'; 
        Part__c part = Database.query(query);
        System.assertEquals(part.Avail_For_QB_Sync_Category__c, false);       
    }
}