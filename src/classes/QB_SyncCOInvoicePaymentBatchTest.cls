@isTest
global without sharing class QB_SyncCOInvoicePaymentBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);
    }
    
    static testMethod void createCOIPPayLoad() {
       	Test.startTest();
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        
        List<Part__c> partList = new List<Part__c> ();
        Part__c partObject1 = TestUtil.createPart(true, '101', vendor.id, 'test1', testCategory.id, 200, 200, 100, 20, 20);
        partList.add(partObject1);
        List<String> partidList = new List<String>{partObject1.id};
        
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, partObject1.Id, 50);
        CO_Invoice_Header__c invoice = TestUtil.createCOInvoiceHeader(true, coHeader1.Id, 'Open');
        CO_Invoice_Payment__c coInvoicePayment = TestUtil.createCOInvoicePaymentWithPaymentMethod(true, invoice.Id, 'Cash', 10);
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();
   		
   		List<CO_Invoice_Payment__c> coInvoicePaymentRes = [Select availForQBJournalEntrySync__c from CO_Invoice_Payment__c Limit 1];
       	system.assertEquals(coInvoicePaymentRes[0].availForQBJournalEntrySync__c, false);
	}
}