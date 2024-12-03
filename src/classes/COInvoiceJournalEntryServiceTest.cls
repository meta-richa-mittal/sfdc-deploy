@isTest
private class COInvoiceJournalEntryServiceTest {
    @TestSetup
    private static void makeData(){
        TestDataFactory.disableFLSChecks();
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        Category__c testCategory = TestUtil.createCategory(false, 'Test Category');
        testCategory.AccountingId__c = '123';
        testCategory.Type__c = 'unit';
        testCategory.Default__c = true;
        testCategory.Active__c = true;
        insert testCategory;
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 50);        
        CO_Invoice_Header__c coinvoiceHeaderRec = TestUtil.createCOInvoiceHeader(false, coHeader.Id, 'Active');
        coinvoiceHeaderRec.SyncTokenForJournalEntry__c = '123456789';
        coinvoiceHeaderRec.Invoice_Date__c = System.now();
        insert coinvoiceHeaderRec;
        Unit_Make__c unitMake = TestDataFactory.createUnitMake('Test Unit Make', 'Tes', true);
    	Unit_Model__c unitModel = TestDataFactory.createUnitModel('Test Unit Model', 'Tes', true, unitMake.Id);
    	Unit_Sub_Model__c unitSubModel = TestDataFactory.createSubModel(unitModel);
    	Customer_Owned_Unit__c customerOwnedUnit = TestDataFactory.createCustomerOwnedUnit(customer.Id, unitMake.Id, unitModel.Id, unitSubModel.Id, 'VIN001');
		Deal__c deal = TestDataFactory.createDeal(coHeader.Id, customerOwnedUnit.Id);
		List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
		for(Integer i = 0; i < 20; i++){
			Deal_Item__c dealItem = TestDataFactory.sampleDealItem(unitModel.Id, deal.Id);
			dealItem.Avail_For_QB_Sync__c = true;
			dealItemList.add(dealItem);
		}
		insert dealItemList;
        Service_Order_Header__c soHeaderRec = TestUtil.createSOHeader(coHeader.Id, coinvoiceHeaderRec.Id);
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, false, 'code', 'code', 'code', 'code', 'code', 12, false, false, null, null);
        CO_Kit_Header__c coKitHeader = TestDataFactory.createCOKitHeader(coHeader.Id);

        CO_Invoice_Item__c coInvoiceitemRec  = TestUtil.createCOInvoiceItem(true, testCategory.Id, coinvoiceHeaderRec.Id, coLineItemRec.id);
        IFW_IntegrationConfig__c  IFWIntegrationConfigObj = TestUtil.createIFWConfigForQB();
        TestUtil.createIFWConfigItemForQB('Journal Entry', IFWIntegrationConfigObj.Id);
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
    private static void testSyncCustomerInvoices() {
        Test.startTest();
        CO_Line_Item__c coLineItem = [Select id from CO_Line_Item__c limit 1][0];
        CO_Invoice_Item__c coInvoiceitemRec = [Select id, CO_Line_Item__c from CO_Invoice_Item__c limit 1][0];
        coInvoiceitemRec.CO_Line_Item__c = coLineItem.id;
        update coInvoiceitemRec;
        List<CO_Invoice_Header__c> coinvoiceHeaderList = [Select id, Total__c, Invoice_Status__c, Invoice_Date__c from CO_Invoice_Header__c];
        for(CO_Invoice_Header__c coInvoiceHeader:coinvoiceHeaderList){
            coInvoiceHeader.Total__c = 100;
            coInvoiceHeader.Invoice_Status__c = 'Closed';
            coInvoiceHeader.Invoice_Date__c = System.now();
        }
        update coinvoiceHeaderList;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Test.stopTest();
        CO_Invoice_Header__c updatedCoInvoiceHeaderRec = [Select id, availForQBJournalEntrySync__c from CO_Invoice_Header__c Limit 1][0];
        system.assertEquals(false, updatedCoInvoiceHeaderRec.availForQBJournalEntrySync__c);
    }
    @isTest
    private static void testSyncCustomerInvoices1() {
        Test.startTest();
        Service_Order_Header__c soHeaderRec = [Select id from Service_Order_Header__c limit 1][0];
        CO_Invoice_Item__c coInvoiceitemRec = [Select id, deal__c, CO_Line_Item__c, Service_Order_Header__c from CO_Invoice_Item__c limit 1][0];
        coInvoiceitemRec.CO_Line_Item__c = null;
        coInvoiceitemRec.Service_Order_Header__c = soHeaderRec.id;
        update coInvoiceitemRec;
        List<CO_Invoice_Header__c> coinvoiceHeaderList = [Select id, Total__c, Invoice_Status__c, Invoice_Date__c from CO_Invoice_Header__c];
        for(CO_Invoice_Header__c coInvoiceHeader:coinvoiceHeaderList){
            coInvoiceHeader.Total__c = 100;
            coInvoiceHeader.Invoice_Status__c = 'Closed';
            coInvoiceHeader.Invoice_Date__c = System.now();
        }
        update coinvoiceHeaderList;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Test.stopTest();
        CO_Invoice_Header__c updatedCoInvoiceHeaderRec = [Select id, availForQBJournalEntrySync__c from CO_Invoice_Header__c Limit 1][0];
        system.assertEquals(false, updatedCoInvoiceHeaderRec.availForQBJournalEntrySync__c);
    }
    @isTest
    private static void testSyncCustomerInvoices2() {
        Test.startTest();
        CO_Kit_Header__c coKitHeader = [Select id from CO_Kit_Header__c limit 1][0];
        CO_Invoice_Item__c coInvoiceitemRec = [Select id, CO_Kit_Header__c, deal__c, CO_Line_Item__c, Service_Order_Header__c from CO_Invoice_Item__c limit 1][0];
        coInvoiceitemRec.CO_Kit_Header__c = coKitHeader.id;
        coInvoiceitemRec.CO_Line_Item__c = null;
        coInvoiceitemRec.Service_Order_Header__c = null;
        coInvoiceitemRec.deal__c = null;
        update coInvoiceitemRec;
        List<CO_Invoice_Header__c> coinvoiceHeaderList = [Select id, Total__c, Invoice_Status__c, Invoice_Date__c from CO_Invoice_Header__c];
        for(CO_Invoice_Header__c coInvoiceHeader:coinvoiceHeaderList){
            coInvoiceHeader.Total__c = 100;
            coInvoiceHeader.Invoice_Status__c = 'Closed';
            coInvoiceHeader.Invoice_Date__c = System.now();
        }
        update coinvoiceHeaderList;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Test.stopTest();
        CO_Invoice_Header__c updatedCoInvoiceHeaderRec = [Select id, availForQBJournalEntrySync__c from CO_Invoice_Header__c Limit 1][0];
        system.assertEquals(false, updatedCoInvoiceHeaderRec.availForQBJournalEntrySync__c);
    }
}
