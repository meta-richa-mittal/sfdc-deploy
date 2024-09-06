/**
 * Author: Namarta Gocher
 * updated: March 1, 2022
 * Name: PopulateTotalCostOnPartsBatchTest
 * Description: Test class for PopulateTotalCostOnPartsBatch
**/
@isTest
private without sharing class PopulateTotalCostOnPartsBatchTest {
    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        Account accRec = TestDataFactory.createVendor('newacc');
        
        Category__c catRec = TestDataFactory.createCategory('categoryName');
        
        Part__c partRec = TestDataFactory.createNewPart(accRec.Id, catRec.Id);
        
        Part_Fifo_Bucket__c partBucketRec = TestDataFactory.createNewPartFifoBucket(partRec.Id);
    }

    @isTest
    private static void PopulateTotalCostOnPartsMethodsTest(){
        Part__c partRec = [Select Id from Part__c];
        Test.startTest();
        Id batchprocessid =Database.executeBatch(new PopulateTotalCostOnPartsBatch());
        Part__c partRec1 = [Select Id,Average_Cost__c  From Part__c];
        System.assertEquals(0.00, partRec1.Average_Cost__c);
        Test.stopTest();
    }
}