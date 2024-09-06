@isTest
public with sharing class PopulateDealConfirmedSaleDateBatchTest {

    @TestSetup
    static void makeData(){
        Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        customer.AccountingId__c = '1234567';
        insert customer;

        CO_Header__c coHeader = TestUtil.createCOHeader(false, customer.id);
        coHeader.Customer_PO_Number__c = '23445345';
        insert coHeader;

        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true, coHeader.Id, 'Closed');

        Unit_Make__c unitMake = TestDataFactory.createUnitMake('Test Unit Make', 'Tes', true);
    	Unit_Model__c unitModel = TestDataFactory.createUnitModel('Test Unit Model', 'Tes', true, unitMake.Id);
    	Unit_Sub_Model__c unitSubModel = TestDataFactory.createSubModel(unitModel);
    	Customer_Owned_Unit__c customerOwnedUnit = TestDataFactory.createCustomerOwnedUnit(customer.Id, unitMake.Id, unitModel.Id, 
    																												unitSubModel.Id, 'VIN001');
		Deal__c deal = TestDataFactory.createDeal(coHeader.Id, customerOwnedUnit.Id);

        CO_Deposit__c coDeposit = TestDataFactory.createCODeposit(coHeader.Id, null, 'Cash', 200);
    }

    @isTest
    public static void populateDealConfirmedSaleDateBatchTest1() {
        Test.startTest();
        List<Deal__c> dealList = [SELECT Delivery_Date__c FROM Deal__c LIMIT 1];
        dealList[0].Delivery_Date__c = Date.today().addDays(-1);
        dealList[0].Confirmed_Sale_Date__c = null;
        update dealList;
        Database.executeBatch(new PopulateDealConfirmedSaleDateBatch());
        Test.stopTest();
        List<Deal__c> dealRecs = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(Date.today().addDays(-1), dealRecs[0].Confirmed_Sale_Date__c);
    }

    @isTest
    public static void populateDealConfirmedSaleDateBatchTest2() {
        Test.startTest();
        List<Deal__c> dealList = [SELECT Delivery_Date__c FROM Deal__c LIMIT 1];
        dealList[0].Delivery_Date__c = null;
        dealList[0].Confirmed_Sale_Date__c = null;
        update dealList;
        Database.executeBatch(new PopulateDealConfirmedSaleDateBatch());
        Test.stopTest();
        List<Deal__c> dealRecs = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(null, dealRecs[0].Confirmed_Sale_Date__c);
    }

    
    @isTest
    public static void populateDealConfirmedSaleDateBatchTest3() {
        Test.startTest();
        List<Deal__c> dealList = [SELECT Delivery_Date__c FROM Deal__c LIMIT 1];
        dealList[0].Delivery_Date__c = null;
        dealList[0].Status__c = 'Approved';
        dealList[0].Confirmed_Sale_Date__c = null;
        update dealList;
        Database.executeBatch(new PopulateDealConfirmedSaleDateBatch());
        Test.stopTest();
        List<Deal__c> dealRecs = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(Date.today(), dealRecs[0].Confirmed_Sale_Date__c);
    }

    @isTest
    public static void populateDealConfirmedSaleDateBatchTest4() {
        Test.startTest();
        List<Deal__c> dealList = [SELECT Delivery_Date__c FROM Deal__c LIMIT 1];
        List<CO_Invoice_Header__c> coInvoiceHeaderList = [SELECT Id FROM CO_Invoice_Header__c LIMIT 1];
        dealList[0].Delivery_Date__c = null;
        dealList[0].Invoice_Number__c = coInvoiceHeaderList[0].Id;
        dealList[0].Status__c = 'Invoiced';
        dealList[0].Confirmed_Sale_Date__c = null;
        update dealList;
        Database.executeBatch(new PopulateDealConfirmedSaleDateBatch());
        Test.stopTest();
        List<CO_Invoice_Header__c> invoiceList = [SELECT Invoice_Date_Formula__c FROM CO_Invoice_Header__c WHERE Id =: coInvoiceHeaderList[0].Id];
        List<Deal__c> dealRecs = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(invoiceList[0].Invoice_Date_Formula__c, dealRecs[0].Confirmed_Sale_Date__c);
    }

    @isTest
    public static void populateDealConfirmedSaleDateBatchTest5() {
        Test.startTest();
        List<Deal__c> dealList = [SELECT Delivery_Date__c FROM Deal__c LIMIT 1];        
        dealList[0].Delivery_Date__c = null;
        dealList[0].Confirmed_Sale_Date__c = null;
        update dealList;

        List<CO_Deposit__c> coDepositList = [SELECT Id FROM CO_Deposit__c LIMIT 1];
        coDepositList[0].Deal__c = dealList[0].Id;
        coDepositList[0].Payment_Date__c = Date.today();
        update coDepositList;

        Database.executeBatch(new PopulateDealConfirmedSaleDateBatch());
        Test.stopTest();
        List<Deal__c> dealRecs = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(Date.today(), dealRecs[0].Confirmed_Sale_Date__c);
    }
}