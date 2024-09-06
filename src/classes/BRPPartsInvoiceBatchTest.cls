@isTest
private class BRPPartsInvoiceBatchTest {
    @testSetup
    private static void testSetup() { 
    	TestUtil.bypassValidation();
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForBRP(); 
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemBRP('BRPPartsInvoice' , IFWConfigObj.Id);  
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        TestUtil.createBRPSettings();
        TestUtil.createBRPVendorList(vendor);
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
    	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    	Sales_Tax__c salestax =  TestUtil.createSalesTax(true, 'HST');
        
        Sales_Tax_Item__c salesTaxItem = TestUtil.createSalesTaxItem(true, 'Test Item', 8.0, 'Testing ', true, testCategory.Id);
        Sales_Tax_Item__c salesTaxItem1 = TestUtil.createSalesTaxItem(true, 'Test Item1', 10.0, 'Testing1 ', true, testCategory.Id);
        
        Applicable_Taxes__c applicabletax = TestUtil.createApplicableTax(true, salestax.Id, salesTaxItem.Id);
        Applicable_Taxes__c applicabletax1 = TestUtil.createApplicableTax(true, salestax.Id, salesTaxItem1.Id);
        
        Account customer = TestUtil.createCustomer(true, 'testcustomer', 'customer@gmail.com', 'Jaipur', '8058704475', null, null, false, true, 'Individual');
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Line_Item__c coLineItemRec1 = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 50);
    }
    
    static testMethod void createBRPPartInvoiceTest() {
	    CO_Header__c coHeaderRec = [Select Id from CO_Header__c];
	    List<CO_Invoice_Header__c> coInvoiceHeaderRec = [Select Id from CO_Invoice_Header__c];
	    String COInvoiceItemJSON = BPUtility.getDecodedString(CustomerOrderCtrl.getCOInvoiceItemsByCOInvoiceHeaderId(BPUtility.getEncodedString(coInvoiceHeaderRec[0].Id)));
	    String closedOrder = BPUtility.getDecodedString(CustomerOrderCtrl.closedorderAction(BPUtility.getEncodedString(COInvoiceItemJSON), BPUtility.getEncodedString(coHeaderRec.Id), BPUtility.getEncodedString('Customer')));
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Test.stopTest();
        
        coInvoiceHeaderRec = [Select Available_For_BRP_Parts_Invoice_Sync__c, Invoice_Number__c, Status__c, Invoice_Date__c from CO_Invoice_Header__c];
	    system.assertEquals('Closed',coInvoiceHeaderRec[0].Status__c);
	    // if success
	    BRP_log__c brpLogRec = [Select Id, Apex_Class__c, Response_Code__c, Error_Messages__c, Type__c FROM BRP_log__c ];
	    system.assertEquals(false, coInvoiceHeaderRec[0].Available_For_BRP_Parts_Invoice_Sync__c);
	    system.assertEquals(null, brpLogRec.Error_Messages__c);
	    system.assertEquals('200', brpLogRec.Response_Code__c);
	    system.assertEquals('Info', brpLogRec.Type__c);
    }

}