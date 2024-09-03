@isTest
global without sharing class QB_SyncStoreCreditTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }

    static testMethod void storeCreditPayload(){
        Test.startTest();
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);
        Account customer =  TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test', 'Customer');
        Store_Credit__c storeCred = new Store_Credit__c(Customer__c = customer.Id, Amount__c = 100);
        insert storeCred;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();
        String query = 'SELECT availForQBSync__c FROM Store_Credit__c'; 
        Store_Credit__c storecredRec = Database.query(query);
        System.assertEquals(storecredRec.availForQBSync__c, false);   
    }

}