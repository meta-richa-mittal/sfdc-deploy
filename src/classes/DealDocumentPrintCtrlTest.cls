@isTest
private class DealDocumentPrintCtrlTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        BPScriptManager.createDefaultUnitProductType();
        Account customer = new Account(name = 'xyz', is_customer__c = true);
        insert customer;
        CO_Header__c coHeader = new CO_Header__c(Customer__c = customer.id);
        insert coHeader;
        Deal__C deal = new Deal__c(CO_Header__c = coHeader.id);        
        insert deal;
        
        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(true, customer.Id, unitmake.Id, unitmodel.Id, null);
        Deal_Item__c dealItem = new Deal_Item__c(Deal__c = deal.Id, Type__c = 'Trade In', Customer_Owned_Unit__c = customerOwnedUnit.Id);
        insert dealItem;
        Option_Fee__c optionFee = new Option_Fee__c(Deal_Item__c = dealItem.id);
        insert optionFee;
        Deal_Kit_Header__c dealKitHeader = new Deal_Kit_Header__c(Deal_Item__c = dealItem.id, CO_Header__c = coHeader.id);
        insert dealKitHeader;
        Customer_Owned_Unit__c customerOwnedUnitRec = TestUtil.createCustomerOwnedUnit(false, null, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnitRec.Unit_Type__c = 'STOCK';
        customerOwnedUnitRec.Status__c = 'Available';
        insert customerOwnedUnitRec;
        
        Deal_Item__c dealItem1 = new Deal_Item__c(Deal__c = deal.Id, Type__c = 'Unit', Customer_Owned_Unit__c = customerOwnedUnitRec.Id);
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