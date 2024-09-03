@isTest
public without sharing class PopulateCustomerOnPaymentBatchTest {
    
    @TestSetup
    static void createSampleData() {
        TestDataFactory.disableFLSChecks();
    	Account customer = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Fname', 'Lname');
        CO_Header__c coHeader = TestDataFactory.createCOHeader(customer.Id);
        CO_Invoice_Header__c coinvoiceHeader = TestDataFactory.createCOInvoiceHeader(coHeader.Id, 'Active');
        Cash_Drawer__c cashDrawer = TestDataFactory.createCashDrawer('Test Drawer');
        CO_Invoice_Payment__c coInvoicePaymentRec = TestDataFactory.createCOInvoicePayment(cashDrawer.Id, coInvoiceHeader.Id);
        CO_Deposit__c coDeposit = TestDataFactory.createCODeposit(coHeader.Id, cashDrawer.Id, 'Visa', 100);
    }

    @isTest
    public static void PopulateCustomerOnPaymentBatchTest() {
        Test.startTest();
        Database.executeBatch(new PopulateCustomerOnPaymentBatch('CODeposit'), 200);
        Database.executeBatch(new PopulateCustomerOnPaymentBatch('COInvoicePayment'), 200);
        Test.stopTest();
        List<CO_Deposit__c> coDepositList = [SELECT Customer_Name__r.Name FROM CO_Deposit__c LIMIT 1];
        List<CO_Invoice_Payment__c> coInvoicePaymentList = [SELECT Customer_Name__r.Name FROM CO_Invoice_Payment__c LIMIT 1];
        System.assertEquals('Test Customer', coDepositList[0].Customer_Name__r.Name);
        System.assertEquals('Test Customer', coInvoicePaymentList[0].Customer_Name__r.Name);
    }
}