@isTest
private class DealDocumentPrintCtrlTest {
    @TestSetup
    private static void setup(){
        Account customer = new Account(name = 'xyz', is_customer__c = true);
        insert customer;
        CO_Header__c coHeader = new CO_Header__c(Customer__c = customer.id);
        insert coHeader;
        Deal__C deal = new Deal__c(CO_Header__c = coHeader.id);        
        insert deal;
        Deal_Item__c dealItem = new Deal_Item__c(Deal__c = deal.Id, Type__c = 'Trade In');
        insert dealItem;
        Option_Fee__c optionFee = new Option_Fee__c(Deal_Item__c = dealItem.id);
        insert optionFee;
        Deal_Kit_Header__c dealKitHeader = new Deal_Kit_Header__c(Deal_Item__c = dealItem.id, CO_Header__c = coHeader.id);
        insert dealKitHeader;
        Deal_Item__c dealItem1 = new Deal_Item__c(Deal__c = deal.Id, Type__c = 'Unit');
        insert dealItem1;
        Option_Fee__c optionFee1 = new Option_Fee__c(Deal_Item__c = dealItem1.id);
        insert optionFee1;
        Deal_Kit_Header__c dealKitHeader1 = new Deal_Kit_Header__c(Deal_Item__c = dealItem1.id, CO_Header__c = coHeader.id);
        insert dealKitHeader1;
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id);
        insert coInvoiceHeader;
        CO_Invoice_Payment__c coInvoicePayment = new CO_Invoice_Payment__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoicePayment;
    }
    @isTest
    private static void testDealDocumentPrintCtrlMethods() {
        Test.startTest();
        DealDocumentPrintCtrl DealDocumentPrintConstructor = new DealDocumentPrintCtrl();
        List<Deal__c> dealRec = [Select id from Deal__c limit 1]; 
        String dealIdStr = dealRec[0].id;
        dealIdStr = BPUtility.getEncodedString(dealIdStr);
        string result = DealDocumentPrintCtrl.getDealDocumentDetails(dealIdStr);
        result = BPUtility.getDecodedString(result);
        System.assertNotEquals(null, result);
        Test.stopTest();
        List<CO_Invoice_Payment__c> records = [SELECT id from CO_Invoice_Payment__c];
        system.assertEquals(1, records.size());
    }
}