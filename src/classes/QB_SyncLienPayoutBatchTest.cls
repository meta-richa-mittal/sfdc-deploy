@isTest
private class QB_SyncLienPayoutBatchTest {
    @TestSetup
    private static void setup(){
        TestUtil.setQuickBooksConfigurations(false);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.BILL, IFWConfigObj[0].Id);
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.JOURNAL_ENTRY, IFWConfigObj[0].Id);
        Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
        customer.Is_Customer__c = true;
        customer.AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
        insert customer;
    }
    @isTest
    private static void testSyncLienPayoutBatch() {
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Account testCustomer = [Select Id from Account where Name = 'test customer' AND AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a'];
        Account vendor = TestUtil.createVendor(false, 'test vendor');
        vendor.Vendor_AccountingId__c = '1234';
        insert vendor;
        CO_Header__c coHeader = new CO_Header__c(Customer__c = testCustomer.id); 
        insert coHeader;
        CO_Invoice_Header__c coInvoiceHeader = new CO_Invoice_Header__c(CO_Header__c = coHeader.id, Invoice_Date__c = date.today());
        insert coInvoiceHeader;
        Deal__c deal = new Deal__c(CO_Header__c = coHeader.id, Invoice_Number__c = coInvoiceHeader.id);
        insert deal;
        CO_Invoice_Item__c coInvoiceItemRec = new CO_Invoice_Item__c();
        coInvoiceItemRec.Category__c = testCategory.Id;
        coInvoiceItemRec.CO_Invoice_Header__c = coInvoiceHeader.Id;
        coInvoiceItemRec.Deal__c = deal.Id;
        coInvoiceItemRec.isActive__c = true;
        insert coInvoiceItemRec;
        Deal_Item__c dealItem = new Deal_Item__c(Deal__c = deal.id, type__c = 'Trade In', Lien_Payout__c = 122, Finance_Company__c = vendor.Id);
        insert dealItem;
        Test.startTest();   
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Deal__c dealRec = [Select Id, status__c from Deal__c limit 1][0];
        dealRec.status__c = 'Invoiced';
        dealRec.Invoice_Number__c = coInvoiceHeader.Id;
        update dealRec;
        List<Deal_Item__c> dealItemList = [SELECT Id, Lien_Payout_Avail_For_Xero_Sync__c, Lien_Payout_Avail_For_QB_Sync__c FROM Deal_Item__c WHERE Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN AND Lien_Payout__c > 0 
        										AND Finance_Company__c != null AND (Lien_Payout_Avail_For_Xero_Sync__c = true OR Lien_Payout_Avail_For_QB_Sync__c = true)];
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(dealItemList, IntegrationUtility.LIEN_PAYOUT);
        Test.stopTest();
        List<Deal_Item__c> dealItemList1 = [Select Lien_Payout_Avail_For_QB_Sync__c, Lien_Payout_Accounting_Id__c from Deal_Item__c limit 1];
        system.assertEquals(false ,dealItemList1[0].Lien_Payout_Avail_For_QB_Sync__c);
        system.assertNotEquals(dealItemList1[0].Lien_Payout_Accounting_Id__c, null);
    }
}