@isTest
global without sharing class QB_SyncFIFOBucketLITest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }

    static testMethod void partFifoBucketActivityLineItemPayload(){
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);
    
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        Account customer = TestUtil.createCustomer(true, 'testcustomer', 'customer@gmail.com', 'Jaipur', '8058704475');
        Account vendor = TestUtil.createVendor(true, 'testvendor');
        Category__c categoryObject = TestUtil.createCategory(true, 'Test', '    Miscellaneous', 'Test description', true, true);
        Part__c partObject1 = TestUtil.createPart(true, '101', vendor.id, 'test1', categoryObject.id, 200, 200, 100, 20, 20);
        Part_FIFO_Bucket__c partRec = [Select Id from Part_FIFO_Bucket__c];
        Part_FIFO_Bucket_Activity_Line_Item__c partActivityLineitem = new Part_FIFO_Bucket_Activity_Line_Item__c();
        partActivityLineitem.Part_Adjustment__c = partRec.Id;
        partActivityLineitem.Part_FIFO_Bucket__c = partRec.Id;
        partActivityLineitem.Qty_Out__c = 20;
        insert partActivityLineitem;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();
        String query = 'SELECT availForQBSync__c FROM Part_FIFO_Bucket_Activity_Line_Item__c'; 
        Part_FIFO_Bucket_Activity_Line_Item__c part = Database.query(query);
        System.assertEquals(part.availForQBSync__c, false);       
    }
}