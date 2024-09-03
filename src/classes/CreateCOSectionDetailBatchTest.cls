@isTest
private class CreateCOSectionDetailBatchTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        CO_Header__c coHeader = new CO_Header__c(Order_status__c = 'Open');
        insert coHeader;
        CO_Line_Item__c coLineItem = new CO_Line_Item__c(CO_Header__c = coHeader.id);
        insert coLineItem;
        CO_Section_Detail__c coSectionDetail = new CO_Section_Detail__c(CO_Header__c = coHeader.id, Section_Type__c = 'Deal Merchandise');
        insert coSectionDetail;
    }

    @isTest
    private static void testCreateCOSectionDetailBatchTestMethods() {
        Test.startTest();
        Database.executebatch(new CreateCOSectionDetailBatch());
        Test.stopTest();
        list<CO_Section_Detail__c> coSectionDetail = [SELECT id from CO_Section_Detail__c limit 1];
        system.assertEquals(1, coSectionDetail.size());
    }
}