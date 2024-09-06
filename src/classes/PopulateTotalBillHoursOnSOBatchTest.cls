@isTest
private without sharing class PopulateTotalBillHoursOnSOBatchTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
    @isTest
    private static void PopulateTotalBilledOnSOTest(){
        Account accRec = TestDataFactory.createVendor('newacc');
        CO_Header__c customerOrderRec = TestDataFactory.createCoHeader(accRec.Id);

        Service_Order_Header__c soHeaderRec = TestDataFactory.createSOHeader(customerOrderRec.Id);
        soHeaderRec.Work_Status__c = ServiceJobUtil.NEW_JOB;
        soHeaderRec.Total_Hours_Billed__c = 3;
        update soHeaderRec;

        Category__c catRec = TestDataFactory.createCategory('categoryName');

        Labour_Code__c labourCode = TestDataFactory.createLabourCode(catRec.Id, '1234', customerOrderRec.Id, true, 3, 'labourCodeName', 2.00, false);
        
        Service_Order_Line_Item__c lineItemRec = TestDataFactory.createServiceOrderLineItem(soHeaderRec.Id);
        lineItemRec.Qty_Needed__c = 2;
        lineItemRec.Labour_Code__c = labourCode.Id;
        update lineItemRec;
        
        PopulateTotalBilledHoursOnSOHeaderBatch reassign = new PopulateTotalBilledHoursOnSOHeaderBatch();
    
        Test.startTest();
        Id batchprocessid =Database.executeBatch(reassign);
        System.assertEquals(3,soHeaderRec.Total_Hours_Billed__c);
        Test.stopTest();
        }
    
}