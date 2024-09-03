@isTest
private without sharing class CreateLocationsBasedOnPartLocatBatchTest {
    
    @testSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Account vendorRec = TestDataFactory.createVendor('Test Vendor');
        Category__c categoryRec = TestDataFactory.createCategory('Test Category');
        Part__c partRec1 = TestDataFactory.samplePart(vendorRec.Id, 2, 2, 2, 2, 3, categoryRec.Id);
        partRec1.Location__c = 'Test1;Test2;Test1';
        insert partRec1;
    }
    
    @isTest
    private static void testCreateLocation() {
        Test.startTest();
        Database.executeBatch(new CreateLocationsBasedOnPartLocationBatch());
        Test.stopTest();
        
        System.assertEquals(2, [SELECT Id FROM Location__c WHERE Name__c != null].size());
    }
}