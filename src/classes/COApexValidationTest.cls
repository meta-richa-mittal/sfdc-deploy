@isTest
private class COApexValidationTest {

    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Cash_Reconciliation__c cashReconciliationRec = TestDataFactory.createCashReconciliation('Reconciled');
        Category__c categoryRec = TestDataFactory.createCategory('Test');
        Account customerRec = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test', 'Customer');
    	CO_Header__c coHeaderRec = TestDataFactory.createCoHeader(customerRec.Id);
        CO_Invoice_Header__c coInvoiceHeaderRec = TestDataFactory.createCOInvoiceHeader(coHeaderRec.Id, 'Closed');
        CO_Invoice_Item__c coInvoiceItemRec = TestDataFactory.createCoInvoiceItem(categoryRec.Id, coInvoiceHeaderRec.id);
    }
    
    @isTest
    private static void validatePaymentDateTest() {
        Test.startTest();
        String paymentDate = BPutility.getFormatedDateTime(Date.today());
        COApexValidation.validatePaymentDate(paymentDate);
        Test.stopTest();
        List<Cash_Reconciliation__c> cashReconciliationList = [Select id from Cash_Reconciliation__c];
        system.assertEquals(1, cashReconciliationList.size());
    }

    @isTest
    private static void validateInvoiceDate() {
        Test.startTest();
        CO_Header__c coHeader = [Select id from CO_Header__c LIMIT 1][0];
        string coHeaderId = string.valueof(coHeader.id);
        CO_Invoice_Header__c coInvoiceHeader = [Select id from CO_Invoice_Header__c LIMIT 1][0];
        string coInvoiceHeaderId = string.valueof(coInvoiceHeader.id);
        CO_Invoice_Item__c coInvoiceItem = [Select id from CO_Invoice_Item__c LIMIT 1][0];
        string coInvoiceItemId = string.valueof(coInvoiceItem.id);
        COApexValidation.validateInvoiceDate('{"InvoiceId":"' + coInvoiceHeaderId + '","COHeaderId":"' + coHeaderId + '","SelectedInvoiceDate":"05/04/2021","SelectInvoiceItemList":["' + coInvoiceItemId + '"]}');
        Test.stopTest();
        List<CO_Header__c> coHeaderList = [Select id from CO_Header__c];
        system.assertEquals(1, coHeaderList.size());

    }
}