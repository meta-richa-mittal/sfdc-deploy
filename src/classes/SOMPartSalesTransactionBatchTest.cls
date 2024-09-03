@isTest
private without sharing class SOMPartSalesTransactionBatchTest {
    
    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks(); 
    	TestUtil.bypassValidation();
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Packaged_Part__c = false;
        part.Qty_On_Order__c = 0;
        part.Order_Lots__c = 1;
        insert part;
    }
    
    @isTest
    private static void testCheckForFileData() { 
        CO_Header__c coHeader = [SELECT Id FROM CO_Header__c limit 1];
        Category__c testCategory = [SELECT Id FROM Category__c limit 1];
        Part__c part = [SELECT Id FROM Part__c limit 1];
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true, coHeader.Id, 'Active');
        CO_Invoice_Item__c coInvoiceItem = TestUtil.createCOInvoiceItem(true, testCategory.Id, coInvoiceHeader.Id, coLineItem.Id, true);
        
        Test.startTest();
        String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeader.Id)));
        CustomerOrderCtrl.closedInvoiceAction(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer'));
        Database.executeBatch(new SOMPartSalesTransactionBatchScheduler(system.today(), false));
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM SOM_Integration__c].size());
    }
}