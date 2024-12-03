@isTest
private class COInvoiceItemServiceTest {

    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Cash_Reconciliation__c cashReconciliationRec = TestDataFactory.createCashReconciliation('Reconciled');
        Cash_Drawer__c cashDrawerRec = TestDataFactory.createCashDrawer('Cash drawer');
        Category__c categoryRec = TestDataFactory.createCategory('Test');
        Account customerRec = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test', 'Customer');
    	CO_Header__c coHeaderRec = TestDataFactory.createCoHeader(customerRec.Id);
        CO_Invoice_Header__c coInvoiceHeaderRec = TestDataFactory.createCOInvoiceHeader(coHeaderRec.Id, 'Active');
        CO_Invoice_Item__c coInvoiceItemRec = TestDataFactory.createCoInvoiceItem(categoryRec.Id, coInvoiceHeaderRec.id);
        CO_Deposit__c coDepositRec = TestDataFactory.createCODeposit(coHeaderRec.Id, cashDrawerRec.Id, 'Cash', 20);
        Service_Order_Header__c soHeader = TestDataFactory.createSOHeader(coHeaderRec.Id);
    }
    
    @isTest
    private static void testCOInvoiceItemService() {
        Test.startTest();
        CO_Header__c coHeaderRec = [Select id from CO_Header__c limit 1][0];
        COInvoiceItemService.getCOCheckoutInfo(coHeaderRec.id);
        Test.stopTest();
        List<Cash_Reconciliation__c> cashReconciliationList = [Select id from Cash_Reconciliation__c];
        system.assertEquals(1, cashReconciliationList.size());
    }

    @isTest
    private static void testCOInvoiceItemService1() {
        Test.startTest();
        CO_Header__c coHeader = [Select id from CO_Header__c LIMIT 1][0];
        string coHeaderId = string.valueof(coHeader.id);
        CO_Invoice_Header__c coInvoiceHeader = [Select id from CO_Invoice_Header__c LIMIT 1][0];
        
        string coInvoiceHeaderId = string.valueof(coInvoiceHeader.id);
        CO_Invoice_Item__c coInvoiceItem = [Select id, isActive__c from CO_Invoice_Item__c LIMIT 1][0];
        coInvoiceItem.isActive__c = false;
        update coInvoiceItem;
        string coInvoiceItemId = string.valueof(coInvoiceItem.id);
        String recordIdsJson = '["' + coInvoiceItemId + '"]';
        try {
        	COInvoiceItemService.finalizeCOInvoice(BPUtility.getEncodedString(recordIdsJson), BPUtility.getEncodedString(coHeaderId));
        	system.assert(false, 'Missing Exception');
        } catch(Exception e) {
            system.assertEquals(true, e.getMessage().containsIgnoreCase(COInvoiceItemService.INVOICE_ALREADY_CLOSED));
        }
        Test.stopTest();

    }
}