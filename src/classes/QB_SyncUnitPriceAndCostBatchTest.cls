@isTest
private class QB_SyncUnitPriceAndCostBatchTest {
    @TestSetup
    private static void setup(){
        TestUtil.setQuickBooksConfigurations(false);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.BILL, IFWConfigObj[0].Id);
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.VENDOR_CREDIT, IFWConfigObj[0].Id);
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.CREDIT_MEMO, IFWConfigObj[0].Id);

        Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
        customer.Is_Customer__c = true;
        customer.AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
        insert customer;
        Account vendor = TestUtil.createVendor(false, 'test vendor');
        insert vendor;
        CO_Header__c coHeader = new CO_Header__c(Customer__c = customer.id); 
        insert coHeader;
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id, Invoice_Date__c = date.today());
        insert coInvoiceHeader;
        Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'Stock', Status__c = 'Available', VIN_Number__c = '1234');
        insert insertCOU;
    }
    @isTest
    private static void testSyncUnitPriceAndCostBatch() {
        
        Test.startTest();  
        Account testCustomer = [Select Id from Account where Name = 'test customer' AND AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a'][0];
        Account testvendor = [Select Id from Account where Name = 'test vendor' AND Is_Vendor__c = true][0];
        CO_Invoice_Header__c coInvoiceHeaderRec = [Select Id from CO_Invoice_Header__c LIMIT 1][0];
        Customer_Owned_Unit__c couRec = [Select Id from Customer_Owned_Unit__c LIMIT 1][0]; 
        Unit_Price_Cost__c unitPriceCostRec = new Unit_Price_Cost__c(Ref_No__c = 'UA-23', Total_Cost__c = 120, Type__c = 'Factory', CO_Invoice_Header__c = coInvoiceHeaderRec.id, Customer_Owned_Unit__c = couRec.id, vendor__c = testvendor.id);
        insert unitPriceCostRec;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Test.stopTest();
        Unit_Price_Cost__c unitPriceCostRec1 = [Select availForQBSync__c, AccountingId__c from Unit_Price_Cost__c LIMIT 1][0];
        system.assertEquals(false ,unitPriceCostRec1.availForQBSync__c);
        system.assertNotEquals(unitPriceCostRec1.AccountingId__c, null);
    }

    @isTest
    private static void testSyncUnitPriceAndCostBatch2() {
        
        Test.startTest();  
        Account testCustomer = [Select Id from Account where Name = 'test customer' AND AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a'][0];
        Account testvendor = [Select Id from Account where Name = 'test vendor' AND Is_Vendor__c = true][0];
        CO_Invoice_Header__c coInvoiceHeaderRec = [Select Id from CO_Invoice_Header__c LIMIT 1][0];
        Customer_Owned_Unit__c couRec = [Select Id from Customer_Owned_Unit__c LIMIT 1][0]; 
        Unit_Price_Cost__c unitPriceCostRec = new Unit_Price_Cost__c(Ref_No__c = 'UA-23', Total_Cost__c = -120, Type__c = 'Factory', CO_Invoice_Header__c = coInvoiceHeaderRec.id, Customer_Owned_Unit__c = couRec.id, vendor__c = testvendor.id);
        insert unitPriceCostRec;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Test.stopTest();
        Unit_Price_Cost__c unitPriceCostRec1 = [Select availForQBSync__c, AccountingId__c from Unit_Price_Cost__c LIMIT 1][0];
        system.assertEquals(false ,unitPriceCostRec1.availForQBSync__c);
        system.assertNotEquals(unitPriceCostRec1.AccountingId__c, null);
    }

    @isTest
    private static void testSyncUnitPriceAndCostBatch3() {
        
        Test.startTest();  
        Account testCustomer = [Select Id from Account where Name = 'test customer' AND AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a'][0];
        Account testvendor = [Select Id from Account where Name = 'test vendor' AND Is_Vendor__c = true][0];
        CO_Invoice_Header__c coInvoiceHeaderRec = [Select Id from CO_Invoice_Header__c LIMIT 1][0];
        Customer_Owned_Unit__c couRec = [Select Id from Customer_Owned_Unit__c LIMIT 1][0]; 
        Unit_Price_Cost__c unitPriceCostRec = new Unit_Price_Cost__c(Ref_No__c = 'UA-23', Total_Cost__c = 120, Type__c = 'Factory', CO_Invoice_Header__c = coInvoiceHeaderRec.id, Customer_Owned_Unit__c = couRec.id, Customer__c = testCustomer.id);
        insert unitPriceCostRec;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Test.stopTest();
        Unit_Price_Cost__c unitPriceCostRec1 = [Select availForQBSync__c, AccountingId__c from Unit_Price_Cost__c LIMIT 1][0];
        system.assertEquals(false ,unitPriceCostRec1.availForQBSync__c);
        system.assertNotEquals(unitPriceCostRec1.AccountingId__c, null);
    }
}