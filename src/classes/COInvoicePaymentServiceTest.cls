@isTest
private class COInvoicePaymentServiceTest {

    @TestSetup
    private static void makeData(){        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Invoice_Header__c coinvoiceHeader = TestUtil.createCOInvoiceHeader(false, coHeader.Id, 'Active');
        coinvoiceHeader.SyncTokenForCOInvoicePayment__c = '123456';
        coinvoiceHeader.availForQBCOInvoicePayment__c = true;
        coinvoiceHeader.Invoice_Date__c = System.now();
        insert coinvoiceHeader;
        CO_Invoice_Payment__c coInvoicePaymentRec = TestUtil.createCOInvoicePaymentWithPaymentMethod(true, coInvoiceHeader.id, 'Cash', 125);
        CO_Invoice_Item__c coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem;
        CO_Invoice_Item__c coInvoiceItem1 = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeader.id);
        insert coInvoiceItem1;
        IFW_IntegrationConfig__c  IFWIntegrationConfigObj = TestUtil.createIFWConfigForQB();
        QuickBooks_Configurations__c qbConfig = new QuickBooks_Configurations__c();
        qbConfig.Consumer_Key__c = 'qyprdFawAAiD3SLud6d5RvREaVOoAn';
        qbConfig.End_Point_URL__c = 'https://sandbox-quickbooks.api.intuit.com/v3/company/';
        qbConfig.Consumer_Secret__c = 'q3JPBvXRxwRWldrpEQzXlByXs7joEglmCBhRPinr';
        qbConfig.OAuth_Token__c = 'qyprdAVMsASHRkSalO3JwbyPdnzistYmRRfJBFbAxL6AOlDj';
        qbConfig.OAuth_Token_Secret__c = 'TN3csfs1tTSX77SW5ysYkcVxJo1gIq8Lq3wusQKO';
        qbConfig.Company_Id__c = '123145730762509';
        qbConfig.Enable_QuickBooks__c = true;
        insert qbConfig;
        insert new General_Configurations__c(Enable_QB_Accounting__c = true);
    }

    @isTest
    private static void TestSyncAccountingServer() {
        Test.startTest();
        String query1;
        query1 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query1 += fieldsName + ', ';
        }
        query1 = query1.substring(0, query1.length()-2);
        query1 += ' FROM CO_Invoice_Header__c';

        String query2;
        query2 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceItem')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query2 += fieldsName + ', ';
        }
        query2 = query2.substring(0, query2.length()-2);
        query2 += ' FROM CO_Invoice_Item__c';
        List<CO_Invoice_Item__c> coInvoiceItem = Database.query(query2);

        String query3 = 'SELECT ';  
    	for(String fieldsName : COInvoicePayment.fieldsList()) {
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
        	query3 += fieldsName + ', ';  
    	}
    	query3 = query3.substring(0, query3.length()-2);
    	query3 += ', CO_Invoice_Header__r.CO_Header__c, CO_Invoice_Header__r.CO_Header__r.CO_Type__c, CO_Invoice_Header__r.CO_Header__r.Name, Customer_Name__c, Customer_Name__r.Name, Customer_Name__r.AccountingId__c, ' +
        ' CO_Invoice_Header__r.AccountingId__c, CO_Invoice_Header__r.CO_Header__r.Customer__r.AccountingId__c, CO_Invoice_Header__r.CO_Header__r.Customer__r.Name, ' +
        ' CO_Invoice_Header__r.CO_Header__r.Customer__c , AccountingIdForJournalEntry__c, SyncTokenForJournalEntry__c, AccountingResponseForJournalEntry__c, Xero_Accounting_Id__c FROM CO_Invoice_Payment__c LIMIT 1';
    	List<CO_Invoice_Payment__c> coInvoicePaymentList = Database.query(query3);
        AccountingCustomerInvoice accountingCustomerInvoice = new AccountingCustomerInvoice(Database.query(query1), coInvoiceItem, coInvoicePaymentList, '1234');
        List<CO_Invoice_Header__c> coInvoiceHeaderList = Database.query(query1);
        CO_Invoice_Header__c coInvoiceHeaderRec = COInvoicePaymentService.syncAccountingServer(new List<AccountingCustomerInvoice>{accountingCustomerInvoice}, coInvoiceHeaderList[0]);
        Test.stopTest();
        system.assertEquals(false, coInvoiceHeaderRec.availForQBCOInvoicePayment__c);
    }
}