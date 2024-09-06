@isTest
public without sharing class FetchVendorFromQBBatchTest {

    @IsTest
    private static void fetchCustomerFromQBTest() {
        QuickBooks_Configurations__c qbConfig = TestDataFactory.createQBConfig();
        Test.startTest();
        Database.executeBatch(new FetchVendorFromQBBatch(),50);
        Test.stopTest(); 
        List <Account> vendorList = [SELECT id,name FROM Account];
        System.assertEquals(1, vendorList.size());
    }
}