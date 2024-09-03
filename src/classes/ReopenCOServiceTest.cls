@isTest
public class ReopenCOServiceTest {
   
    @testsetup
    private static void setup() {
		TestDataFactory.disableFLSChecks();
    	Account vendor = TestUtil.createVendor(true, 'Vendor001');
    	Account customer = TestUtil.createCustomer(true, 'Cust001', 'cust@bp.com', 'jp', '11111111111');
    	Category__c category = TestUtil.createCategory(true, 'Category001', 'Part', 'Testing Category', true, true);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', category.Id, 10, 20, 50, 100, 100);
    	
    	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
    	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
    	
    	CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
    	CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 1);
    	
    	CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true, coHeader.Id, 'Closed');
		coInvoiceHeader.Invoice_Date__c = Date.today();
		coInvoiceHeader.Closed_Invoice_Date__c = Date.today();
		coInvoiceHeader.Checkout_Type__c = 'Customer';
		coInvoiceHeader.Total__c = 100;
		coInvoiceHeader.Invoice_Status__c = 'Closed';
		update coInvoiceHeader;

		coLineItem.Invoice_Number__c = coInvoiceHeader.Id;
		update coLineItem;

		coHeader.Order_status__c = 'Closed';
		coHeader.Uninvoiced_Amount__c = 0;
		coHeader.CO_Type__c = Constants.CASH_SALE;
		update coHeader;

    	CO_Invoice_Item__c coinvoiceitem  = TestUtil.createCOInvoiceItem(true, category.Id, coInvoiceHeader.Id, coLineItem.Id);

    	Service_Order_Header__c soHeaderRec = TestUtil.createSOHeader(coHeader.Id, coInvoiceHeader.Id);
    	Service_Order_Line_Item__c serviceOrderLineItem = TestUtil.createServiceOrderLineItem(soHeaderRec.Id);
        Part_FIFO_Bucket__c fifoBucket = TestUtil.createFifoBucket(false, part.Id, 20, 40, null); 
		fifoBucket.Customer_Return__c = coInvoiceHeader.Id;
		insert fifoBucket;
		Part_FIFO_Bucket_Activity_Line_Item__c partFifoActivityLineItem = TestUtil.createFifoBucketLI(true, fifoBucket.id, 2, part.Id);
		partFifoActivityLineItem.CO_Invoice_Header__c = coInvoiceHeader.Id;
		update partFifoActivityLineItem;
    }


	@isTest
    private static void validateAndReOpenInvoiceTest() {
		IFW_IntegrationConfig__c IFWConfigObj = TestUtil.sampleIFWConfigForXero();
    	IFWConfigObj.Enabled__c = true;
    	insert IFWConfigObj;
    	insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
    	IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Invoices', IFWConfigObj.Id);
		List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select id, Checkout_Type__c from CO_Invoice_Header__c where Status__c = 'Closed'];
		coInvoiceHeaderlist[0].Checkout_Type__c = 'Internal';
		update coInvoiceHeaderlist;
		CustomerOrderCtrl_V2.validateInvoiceReOpening(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id));
        String  reopenInvoiceResult = new ReopenCOService().reOpenInvoice(coInvoiceHeaderlist[0].Id);
        System.assertEquals('success', reopenInvoiceResult.toLowerCase());
    }

	@isTest
	private static void reOpenInvoiceQBTest() {
		TestUtil.setQuickBooksConfigurations(false);
		List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		TestUtil.createIFWConfigItemForQB(IntegrationUtility.JOURNAL_ENTRY , IFWConfigObj[0].Id);
		TestUtil.createIFWConfigItemForQB(IntegrationUtility.INVOICE_PAYMENT , IFWConfigObj[0].Id);
		TestUtil.createIFWConfigItemForQB(IntegrationUtility.SALES_RECEIPT , IFWConfigObj[0].Id);
		List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select id, AccountingIdForCOInvoicePayment__c, SyncTokenForCOInvoicePayment__c, AccountingId__c, JournalEntryAccountingId__c from CO_Invoice_Header__c where Status__c = 'Closed'];
		CustomerOrderCtrl_V2.validateInvoiceReOpening(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id));
		coInvoiceHeaderlist[0].SyncTokenForCOInvoicePayment__c = '';
		coInvoiceHeaderlist[0].AccountingId__c = '12345';
		coInvoiceHeaderlist[0].SyncToken__c = '';
		coInvoiceHeaderlist[0].JournalEntryAccountingId__c = '123456';
		update coInvoiceHeaderlist;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        String  reopenInvoiceResult = new ReopenCOService().reOpenInvoice(coInvoiceHeaderlist[0].Id);
		Test.stopTest();
        System.assertEquals('success',reopenInvoiceResult.toLowerCase());
	}

	@isTest
	private static void reopenInvoiceXeroTest() {
		IFW_IntegrationConfig__c IFWConfigObj = TestUtil.sampleIFWConfigForXero();
    	IFWConfigObj.Enabled__c = true;
    	insert IFWConfigObj;
    	insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
    	IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Invoices', IFWConfigObj.Id);	
		List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select id, AccountingIdForCOInvoicePayment__c, AccountingId__c, JournalEntryAccountingId__c from CO_Invoice_Header__c where Status__c = 'Closed'];
		CustomerOrderCtrl_V2.validateInvoiceReOpening(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id));
		coInvoiceHeaderlist[0].Xero_Accounting_Id__c = '123456';
		update coInvoiceHeaderlist;
        String  reopenInvoiceResult = new ReopenCOService().reOpenInvoice(coInvoiceHeaderlist[0].Id);
		System.assertEquals('error',reopenInvoiceResult.toLowerCase());
	}

	@isTest
	private static void reOpenInvoiceQBFailureTest() {
		Test.startTest();
		TestUtil.setQuickBooksConfigurations(false);
		List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select id, Total__c, AccountingIdForCOInvoicePayment__c, SyncTokenForCOInvoicePayment__c, AccountingId__c, JournalEntryAccountingId__c from CO_Invoice_Header__c where Status__c = 'Closed'];
		CustomerOrderCtrl_V2.validateInvoiceReOpening(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id));
		coInvoiceHeaderlist[0].AccountingIdForCOInvoicePayment__c = '1234';
		coInvoiceHeaderlist[0].AccountingId__c = '12345';
		coInvoiceHeaderlist[0].Total__c = -100;
		update coInvoiceHeaderlist;
        String  reopenInvoiceResult = new ReopenCOService().reOpenInvoice(coInvoiceHeaderlist[0].Id);
		Test.stopTest();
        System.assertEquals('error',reopenInvoiceResult.toLowerCase());
	}
    
	@isTest
	private static void reOpenInvoiceQBReadTimeOutTest() {
		Test.startTest();
		TestUtil.setQuickBooksConfigurations(false);
		List<CO_Invoice_Header__c> coInvoiceHeaderlist = [select id, Total__c, AccountingIdForCOInvoicePayment__c, SyncTokenForCOInvoicePayment__c, AccountingId__c, JournalEntryAccountingId__c from CO_Invoice_Header__c where Status__c = 'Closed'];
		CO_Invoice_Payment__c coPayment = TestUtil.createCOInvoicePayment(true,coInvoiceHeaderlist[0].Id);
		coPayment.Payment_Method__c = 'Charge Account';
		update coPayment;
		CustomerOrderCtrl_V2.validateInvoiceReOpening(BPUtility.getEncodedString(coInvoiceHeaderlist[0].Id));
		coInvoiceHeaderlist[0].AccountingId__c = '12345';
		coInvoiceHeaderlist[0].Total__c = -100;
		update coInvoiceHeaderlist;
        String  reopenInvoiceResult = new ReopenCOService().reOpenInvoice(coInvoiceHeaderlist[0].Id);
		Test.stopTest();
        System.assertEquals('error',reopenInvoiceResult.toLowerCase());
	}
    

}