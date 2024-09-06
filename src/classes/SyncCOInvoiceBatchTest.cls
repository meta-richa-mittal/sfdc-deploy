@isTest
    private class SyncCOInvoiceBatchTest {
        @TestSetup
        private static void setup(){
            TestDataFactory.disableFLSChecks();
            IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
            insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
            List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
            IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
            Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
            customer.Is_Customer__c = true;
            customer.Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
            insert customer;
        }
        @isTest
        private static void testSyncCOInvoiceBatch() {
            Account testCustomer = [Select Id from Account where Name = 'test customer' AND Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a'];
            CO_Header__c coHeader = new CO_Header__c(Customer__c = testCustomer.id); 
            insert coHeader;
            Account vendor = TestUtil.createVendor(false, 'balveer');
            insert vendor;
            CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id, Invoice_Date__c = date.today());
            insert coInvoiceHeader;
            CO_Invoice_Item__c coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
            insert coInvoiceItem;
            CO_Invoice_Item__c coInvoiceItem1 = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
            insert coInvoiceItem1;
            CO_Invoice_Payment__c coInvoicePayment = new CO_Invoice_Payment__c(CO_Invoice_Header__c = coInvoiceHeader.id);
            insert coInvoicePayment;
            Deal__c deal = new Deal__c(CO_Header__c = coHeader.id, Invoice_Number__c = coInvoiceHeader.id);
            insert deal;
            Deal_Item__c dealItem = new Deal_Item__c(Finance_Company__c = vendor.id, Deal__c = deal.id, type__c = 'Trade In', Lien_Payout__c = 122, Lien_Payout_Avail_For_Xero_Sync__c = true);
            insert dealItem;
            Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
            Test.startTest();   
            Deal__c dealRec = [Select Id, status__c from Deal__c limit 1][0];
            dealRec.status__c = 'Invoiced';
            update dealRec;
            Deal_Item__c dealItemRec = [Select Id, Is_Stocked_In__c from Deal_Item__c limit 1][0];
            dealItemRec.Is_Stocked_In__c = true;
            update dealItemRec;
            CO_Invoice_Header__c coInvoiceHeaderRec = [Select Id, Invoice_Status__c, Checkout_Type__c from CO_Invoice_Header__c limit 1][0];
            coInvoiceHeaderRec.Invoice_Status__c = 'Closed';
            update coInvoiceHeaderRec;
            List<Deal__c> dealList = [Select id from Deal__c limit 1];
            system.assertEquals(1, dealList.size());
            Test.stopTest();
        }
        
    }