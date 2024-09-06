@isTest
private without sharing class FetchCustomerFromQBBatchTest {
    
    @TestSetup 
    private static void setup() {
        QuickBooks_Configurations__c qbConfig = TestDataFactory.createQBConfig();
    }

    @IsTest
    private static void testFetchCustomerFromQBBatch() {
        Test.startTest();
        Database.executeBatch(new FetchCustomerFromQBBatch(),100);
        Test.stopTest(); 
        List <Account> customerList = [SELECT id,name FROM Account];
        System.assertEquals(1, customerList.size());
    }


}