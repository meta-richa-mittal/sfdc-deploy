@isTest
private class ClaimLineItemTriggerHelperTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Service_Order_Line_Item__c ServiceOrderLineItem = new Service_Order_Line_Item__c();
        insert ServiceOrderLineItem;
        Claim_Line_Item__c ClaimLineItem = new Claim_Line_Item__c(Service_Order_Line_Item__c = ServiceOrderLineItem.id);
        insert ClaimLineItem;
    }

    @isTest
    private static void testClaimLineItemTriggerHelperMethods() {
        Test.startTest();
        list<Claim_Line_Item__c> ClaimLineItemList = [SELECT id, Claimed_Price__c, Claimed_Qty__c from Claim_Line_Item__c limit 1];
        for(Claim_Line_Item__c ClaimLineItemRec:ClaimLineItemList){
            ClaimLineItemRec.Claimed_Qty__c = 12;
            ClaimLineItemRec.Claimed_Price__c = 100.3;
        }
        update ClaimLineItemList;
        Test.stopTest();
        list<Claim_Line_Item__c> result = [SELECT id, Claimed_Qty__c from Claim_Line_Item__c limit 1];
        system.assertEquals(12, result[0].Claimed_Qty__c);
    }
}