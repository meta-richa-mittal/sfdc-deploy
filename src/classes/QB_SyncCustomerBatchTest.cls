@isTest
global without sharing class QB_SyncCustomerBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }

    static testMethod void customerPayload(){
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Customer' , IFWConfigObj[0].Id);
        Account customer =  TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test', 'Customer');
        Account customerRec = [Select FirstName__c From Account];
        customerRec.FirstName__c = 'Namarta';
        update customerRec;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();
        String query = 'SELECT availForQBSync__c FROM Account'; 
        Account cust = Database.query(query);
        System.assertEquals(cust.availForQBSync__c, false);   
    }

}