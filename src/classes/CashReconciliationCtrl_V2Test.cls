@isTest
private class CashReconciliationCtrl_V2Test {

    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    }

    static void testData() {
        List<Cash_Drawer__c> cashDrawerList = TestDataFactory_V2.createTestDataForCashDrawer(true, 'Test Cash Drawer');
        List<CO_Header__c> coHeaderList = TestDataFactory_V2.createTestDataForCOHeader(true);
        List<CO_Invoice_Header__c> coInvoiceHeaderList = TestDataFactory_V2.createTestDataForCOInvoiceHeader(coHeaderList, false);
        coInvoiceHeaderList[0].Invoice_Status__c = 'Active';
        insert coInvoiceHeaderList[0];
        List<CO_Invoice_Payment__c> coInvoicePaymentList = TestDataFactory_V2.createTestDataForCOInvoicePayment(coInvoiceHeaderList, true);
        List<CO_Deposit__c> coDepositList = TestDataFactory_V2.createTestDataForCODeposit(coHeaderList, true);
    }

    @isTest
    public static void getCashDrawerReconciliationByDrawerIdTest() {
        testData();
        List<Cash_Drawer__c> cashDrawerList = [SELECT Id FROM Cash_Drawer__c];
        List<CO_Invoice_Payment__c> coInvoicePaymentList = [SELECT Id,Payment_Method__c,Amount__c,Cash_Drawer__c FROM CO_Invoice_Payment__c];
        coInvoicePaymentList[0].Payment_Method__c = 'Cash';
        coInvoicePaymentList[0].Amount__c = 100;
        coInvoicePaymentList[0].Cash_Drawer__c = cashDrawerList[0].Id;
        update coInvoicePaymentList[0];
        
        String reconciledDateStr = '1/12/2018';
        
        // Test the getCashDrawerReconciliationByDrawerId method
        String reconciliationRecJson = CashReconciliationCtrl.getCashDrawerReconciliationByDrawerId(
            BPUtility.getEncodedString(reconciledDateStr),
            BPUtility.getEncodedString(cashDrawerList[0].Id)
        );
        reconciliationRecJson = BPUtility.getDecodedString(reconciliationRecJson);
        ReconciliationWrapper reconciliationObj = (ReconciliationWrapper) JSON.deserialize(reconciliationRecJson, ReconciliationWrapper.class);
        // Assertion
        System.assert(reconciliationObj.CashDrawerReconcilationObjList[0].DrawerId != null);
    }

    @isTest
    public static void getReconciliationListTest() {
        // Test data setup
        testData();
        TestDataFactory_V2.createTestDataForCashDrawer(true, 'Test Cash Drawer1');
        List<CO_Invoice_Header__c> coInvoiceHeaderList = [SELECT Id FROM CO_Invoice_Header__c];
        TestDataFactory_V2.createTestDataForCOInvoicePayment(coInvoiceHeaderList, true);
    
        List<Cash_Drawer__c> cashDrawerList = [SELECT Id FROM Cash_Drawer__c];
        List<CO_Invoice_Payment__c> coInvoicePaymentList = [SELECT Id, Payment_Date__c, Payment_Method__c, Cash_Drawer__c, Amount__c FROM CO_Invoice_Payment__c];
        List<CO_Deposit__c> coDepositList = [SELECT Id, Payment_Date__c, Payment_Method__c, Cash_Drawer__c FROM CO_Deposit__c];

        coInvoicePaymentList[0].Payment_Method__c = 'Cash';
        coInvoicePaymentList[0].Amount__c = 100;
        coInvoicePaymentList[0].Cash_Drawer__c = cashDrawerList[0].Id;
        coInvoicePaymentList[0].Payment_Date__c = system.today();
        update coInvoicePaymentList[0];

        coInvoicePaymentList[1].Payment_Method__c = 'Store Credit';
        coInvoicePaymentList[1].Amount__c = -100;
        coInvoicePaymentList[1].Cash_Drawer__c = cashDrawerList[1].Id;
        coInvoicePaymentList[0].Payment_Date__c = system.today();
        update coInvoicePaymentList[1];
        
        coDepositList[0].Cash_Drawer__c = cashDrawerList[0].Id;
        coDepositList[0].Payment_Date__c = system.today();
        coDepositList[0].Payment_Method__c = 'Debit';
        update coDepositList[0];

        Date todayDate = System.today();
        String reconciledDateStr = todayDate.format();
        
        // Test the getReconciliationList method for 'Drawer' view
        String reconciliationRecJson = CashReconciliationCtrl.getReconciliationList(
            BPUtility.getEncodedString(reconciledDateStr),
            BPUtility.getEncodedString('Drawer')
        );
        reconciliationRecJson = BPUtility.getDecodedString(reconciliationRecJson);
        ReconciliationWrapper reconciliationObj = (ReconciliationWrapper) JSON.deserialize(reconciliationRecJson, ReconciliationWrapper.class);
        
        // Assertion
        System.assertEquals(reconciliationObj.ReconciliationInfo.Status, 'Unreconciled');
        
        // Test the getReconciliationList method for 'Transaction Type' view
        reconciliationRecJson = CashReconciliationCtrl.getReconciliationList(
            BPUtility.getEncodedString(reconciledDateStr),
            BPUtility.getEncodedString('Transaction Type')
        );
        reconciliationRecJson = BPUtility.getDecodedString(reconciliationRecJson);
        List<CashReconciliationTTWrapper> transactionTypeList = (List<CashReconciliationTTWrapper>) JSON.deserialize(reconciliationRecJson, List<CashReconciliationTTWrapper>.class);
       // Assertions
        for (CashReconciliationTTWrapper ttRec : transactionTypeList) {
            system.assertEquals(ttRec.CashDrawerDetailObjList.size(), 2);

            if (ttRec.PaymentMethod == 'Cash') {
                System.assertEquals(ttRec.TotalProcessedAmount, 100);
            }
            if (ttRec.PaymentMethod == 'Debit') {
                System.assertEquals(ttRec.TotalProcessedAmount, 1000);
            }
        }
    }

    @isTest
    public static void getMiniCalenderDataByDrawerIdTest() {
        // Test data setup
        testData();
        List<Cash_Drawer__c> cashDrawerList = [SELECT Id FROM Cash_Drawer__c];
                
        String StartDateStr = '1/12/2018';
        String EndDateStr = '31/12/2018';
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('StartDate', StartDateStr);
        gen.writeStringField('EndDate', EndDateStr);
        gen.writeEndObject();
        String jsonString = gen.getAsString();
        
        // Test the getMiniCalenderDataByDrawerId method
        String response = CashReconciliationCtrl.getMiniCalenderDataByDrawerId(
            BPUtility.getEncodedString(jsonString),
            BPUtility.getEncodedString(null)
        );
        String getMinicalenderDataStr = BPUtility.getDecodedString(response);
        List<ReconciliationWrapper.ReconciliationInfo> reconciliationInfoObj = (List<ReconciliationWrapper.ReconciliationInfo>) JSON.deserialize(getMinicalenderDataStr, List<ReconciliationWrapper.ReconciliationInfo>.class);
        
        // Assertion
        System.assertEquals(reconciliationInfoObj.size(), 0);
    }

    @isTest
    public static void saveReconciliationTest() {
        // Test data setup
        testData();
        List<Cash_Drawer__c> cashDrawerList = [SELECT Id FROM Cash_Drawer__c];
        List<CO_Invoice_Payment__c> coInvoicePaymentList = [SELECT Id,Payment_Method__c,Amount__c,Cash_Drawer__c FROM CO_Invoice_Payment__c];
        coInvoicePaymentList[0].Payment_Method__c = 'Cash';
        coInvoicePaymentList[0].Amount__c = 100;
        coInvoicePaymentList[0].Cash_Drawer__c = cashDrawerList[0].Id;
        update coInvoicePaymentList[0];
        
        String reconciledDateStr = '1/12/2018';
        
        // Test the saveReconciliation method
        String reconciliationRecJson = CashReconciliationCtrl.getCashDrawerReconciliationByDrawerId(
            BPUtility.getEncodedString(reconciledDateStr),
            BPUtility.getEncodedString(cashDrawerList[0].Id)
        );
        reconciliationRecJson = BPUtility.getDecodedString(reconciliationRecJson);
        ReconciliationWrapper reconciliationObj = (ReconciliationWrapper) JSON.deserialize(reconciliationRecJson, ReconciliationWrapper.class);
        reconciliationObj.CashDrawerReconcilationObjList[0].Status = 'Submitted';
        
        String response = CashReconciliationCtrl.saveReconciliation(
            BPUtility.getEncodedString(system.JSON.serialize(reconciliationObj)),
            null
        );
        
        // Assertion
        System.assertEquals(response, 'Success');
    }
}