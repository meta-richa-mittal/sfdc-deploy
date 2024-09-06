@isTest
public with sharing class DealServiceTest {
    @TestSetup
    static void setupData(){
        Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        customer.AccountingId__c = '1234567';
        insert customer;

        CO_Header__c coHeader = TestUtil.createCOHeader(false, customer.id);
        coHeader.Customer_PO_Number__c = '23445345';
        insert coHeader;

        Unit_Make__c unitMake = TestDataFactory.createUnitMake('Test Unit Make', 'Tes', true);
    	Unit_Model__c unitModel = TestDataFactory.createUnitModel('Test Unit Model', 'Tes', true, unitMake.Id);
    	Unit_Sub_Model__c unitSubModel = TestDataFactory.createSubModel(unitModel);
    	Customer_Owned_Unit__c customerOwnedUnit = TestDataFactory.createCustomerOwnedUnit(customer.Id, unitMake.Id, unitModel.Id, 
    																												unitSubModel.Id, 'VIN001');
		Deal__c deal = TestDataFactory.createDeal(coHeader.Id, customerOwnedUnit.Id);
    }

    @isTest
    public static void updateConfirmedSaleDate1() {
        Test.startTest();
        List<Deal__c> dealList = [SELECT Status__c FROM Deal__c LIMIT 1];
        dealList[0].Status__c = 'In Progress';
        update dealList;
        List<Deal__c> dealRecs = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(Date.today(), dealRecs[0].Confirmed_Sale_Date__c);
        dealRecs[0].Status__c = 'Quotation';
        update dealRecs;
        List<Deal__c> dealRecs1 = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(null, dealRecs1[0].Confirmed_Sale_Date__c);
        Test.stopTest();
    }

    @isTest
    public static void updateConfirmedSaleDate2() {
        Test.startTest();
        List<Deal__c> dealList = [SELECT Delivery_Date__c FROM Deal__c LIMIT 1];        
        dealList[0].Delivery_Date__c = null;
        dealList[0].Confirmed_Sale_Date__c = null;
        update dealList;

        CO_Header__c coHeader = [SELECT Id FROM CO_Header__c LIMIT 1];

        CO_Deposit__c coDepositRec = new CO_Deposit__c();
        coDepositRec.CO_Header__c = coHeader.Id;
        coDepositRec.Payment_Method__c = 'Cash';
        coDepositRec.Amount__c = 200;
        coDepositRec.Deal__c = dealList[0].Id;
        coDepositRec.Payment_Date__c = Date.today();
        insert coDepositRec;

        List<Deal__c> dealRecs = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(Date.today(), dealRecs[0].Confirmed_Sale_Date__c);

        Test.stopTest();
    }

    @isTest
    public static void updateConfirmedSaleDate3() {
        Test.startTest();
        List<Deal__c> dealList = [SELECT Delivery_Date__c FROM Deal__c LIMIT 1];        
        dealList[0].Delivery_Date__c = null;
        dealList[0].Confirmed_Sale_Date__c = null;
        update dealList;

        CO_Header__c coHeader = [SELECT Id FROM CO_Header__c LIMIT 1];

        List<CO_Deposit__c> coDepositToInsert = new List<CO_Deposit__c>();
        CO_Deposit__c coDepositRec = new CO_Deposit__c();
        coDepositRec.CO_Header__c = coHeader.Id;
        coDepositRec.Payment_Method__c = 'Cash';
        coDepositRec.Amount__c = 200;
        coDepositRec.Deal__c = dealList[0].Id;
        coDepositRec.Payment_Date__c = Date.today();
        coDepositToInsert.add(coDepositRec);

        CO_Deposit__c coDepositRec1 = new CO_Deposit__c();
        coDepositRec1.CO_Header__c = coHeader.Id;
        coDepositRec1.Payment_Method__c = 'Debit';
        coDepositRec1.Amount__c = -200;
        coDepositRec1.Deal__c = dealList[0].Id;
        coDepositRec1.Payment_Date__c = Date.today();
        coDepositToInsert.add(coDepositRec1);

        insert coDepositToInsert;

        List<Deal__c> dealRecs = [SELECT Confirmed_Sale_Date__c FROM Deal__c LIMIT 1];
        System.assertEquals(null, dealRecs[0].Confirmed_Sale_Date__c);
        Test.stopTest();
    }
}