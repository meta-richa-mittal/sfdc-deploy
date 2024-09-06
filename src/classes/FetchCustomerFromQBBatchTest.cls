@isTest
private without sharing class FetchCustomerFromQBBatchTest {
    
    @TestSetup 
    private static void setup() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
    }

    @IsTest
    private static void testFetchCustomerFromQBBatch() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Database.executeBatch(new FetchCustomerFromQBBatch(),100);
        Test.stopTest(); 
        List <Account> customerList = [SELECT id,name FROM Account];
        System.assertEquals(1, customerList.size());
    }


}