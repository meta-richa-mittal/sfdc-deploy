@isTest
private without sharing class PartAgingDetailTriggerTest {

    @isTest
    private static void triggerTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);

        Part_Aging_Detail__c agingAcc = new Part_Aging_Detail__c();
        agingAcc.Part__c = part.Id;
        agingAcc.PRD1Cost__c = 50;
        agingAcc.PRD1Qty__c = 20;
        insert agingAcc;

        system.assertNotEquals(null, [Select Part__c from Part_Aging_Detail__c WHERE Id =: agingAcc.Id].Part__c);
    }
}