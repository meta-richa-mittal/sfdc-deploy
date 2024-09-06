@isTest
    private class SyncUnitPriceAndCostBatchTest {
        @TestSetup
        private static void setup(){
            IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
            insert new Configurations__c(Accrue_Trade_Tax_Until_Unit_Sold__c = true);
            insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
            List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
            IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
            Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
            customer.Is_Customer__c = true;
            customer.Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
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
            
            Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
            Test.startTest();  
            Account testCustomer = [Select Id from Account where Name = 'test customer' AND Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a'][0];
            Account testvendor = [Select Id from Account where Name = 'test vendor' AND Is_Vendor__c = true][0];
            CO_Invoice_Header__c coInvoiceHeaderRec = [Select Id from CO_Invoice_Header__c LIMIT 1][0];
            Customer_Owned_Unit__c couRec = [Select Id from Customer_Owned_Unit__c LIMIT 1][0]; 
            Unit_Price_Cost__c unitPriceCostRec = new Unit_Price_Cost__c(Ref_No__c = 'UA-23', Total_Cost__c = 120, Type__c = 'Factory', CO_Invoice_Header__c = coInvoiceHeaderRec.id, Customer_Owned_Unit__c = couRec.id, vendor__c = testvendor.id);
            insert unitPriceCostRec;
            List<Customer_Owned_Unit__c> couList = [Select id from Customer_Owned_Unit__c limit 1];
            system.assertEquals(1, couList.size());
            Test.stopTest();
        }
        
    }