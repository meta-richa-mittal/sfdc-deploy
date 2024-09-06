/**
 * Author: Namarta Gocher
 * updated: March 1, 2022
 * Name: PopulateSpecialOrderStatusBatchTest
 * Description: Test class for PopulateSpecialOrderStatusBatch
**/
@isTest
private without sharing class PopulateSpecialOrderStatusBatchTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }

    @isTest
    private static void OrderStatusBatchMethodsTest(){
        Account accRec = TestDataFactory.createCustomer('customerName', 'customerType', 'firstName', 'lastName');
        
        CO_Header__c customerOrderRec = TestDataFactory.createCoHeader(accRec.Id);
        customerOrderRec.Order_status__c = 'Open';
        DMLUtility.updateSobjectList('CO_Header__c', customerOrderRec);

        PopulateSpecialOrderStatusBatch reassign = new PopulateSpecialOrderStatusBatch();
    
        Test.startTest();
        Id batchprocessid =Database.executeBatch(reassign);
        Test.stopTest();
        }
    
}


