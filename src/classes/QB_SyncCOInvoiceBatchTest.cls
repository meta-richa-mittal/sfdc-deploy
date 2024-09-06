@isTest
global without sharing class QB_SyncCOInvoiceBatchTest {
    @TestSetup
    private static void setup(){
        TestUtil.setQuickBooksConfigurations(false);
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObjList[0].Id);
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.SALES_RECEIPT , IFWConfigObjList[0].Id);
    }
    @isTest
    private static void testSyncCOInvoiceBatch() {
        Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
        customer.Is_Customer__c = true;
        customer.AccountingId__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
        insert customer;
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 120);
        CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(true, coHeader1.Id, 'Active');
        CO_Invoice_Item__c coinvoiceitem1  = TestUtil.createCOInvoiceItem(true, testCategory.Id, coinvoiceHeader1.Id, coLineItemRec.Id, true );
       
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeader1.Id)));
        CustomerOrderCtrl.closedInvoiceAction(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeader1.Id), BPUtility.getEncodedString('Customer'));
        Test.stopTest();

        CO_Invoice_Header__c coInvoiceHeaderRec1 = [Select availForQBSync__c, availForQBJournalEntrySync__c from CO_Invoice_Header__c  where Id = :coinvoiceHeader1.Id limit 1][0];
        system.assertEquals(coInvoiceHeaderRec1.availForQBJournalEntrySync__c, false);
        system.assertEquals(coInvoiceHeaderRec1.availForQBSync__c, false);
    }
}