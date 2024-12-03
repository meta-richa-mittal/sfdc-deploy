@isTest
global without sharing class QB_SyncVendorBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }

    static testMethod void vendorPayload(){
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Vendor' , IFWConfigObj[0].Id);
        Account vendoe =  TestDataFactory.createVendor('Test Customer');
        Account vendRec = [Select FirstName__c From Account];
        vendRec.FirstName__c = 'Namarta';
        update vendRec;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();
        String query = 'SELECT Vendor_AvailForQBSync__c FROM Account'; 
        Account cust = Database.query(query);
        System.assertEquals(cust.Vendor_AvailForQBSync__c, false);   
    }

}