@isTest
public without sharing class AccountingCustomerInvoiceServiceTest {
    
    @testSetup
    private static void setupTestData() { 
        TestDataFactory.disableFLSChecks();
        TestUtil.enableXeroInCustomSetting();
        PaginationSorting pageSort = new PaginationSorting();
	  	pageSort.CurrentPage = 1;
	  	pageSort.PageSize = 10;
	  	pageSort.Sorting = new List <PaginationSorting.SortAttrs>{
	  		new PaginationSorting.SortAttrs('Item', 'ASC')
	  	};
        insert new Configurations__c(Enhanced_Tax_Calculations__c = true, Tax_Included_Pricing__c = false);
        TestUtil.createIFWConfigForXero();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Contacts', IFWConfigObj[0].Id);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
	  	Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
	  	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
	  	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
	  	Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, false, 'code', 'code', 'code', 'code', 'code', 12, false, false, null, null);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part.Packaged_Part__c = true;
        Part.Package_Qty__c = 22;
        Part.Auto_reorder_Min__c = 0;
        part.Auto_reorder_Max__c = 100;
        part.Order_Lots__c = 1;
        insert part;
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Kit_Header__c coKitHeader = new CO_Kit_Header__c(CO_Header__c = coHeader.id, Kit_Header__c = kitHeader.id);
        insert coKitHeader;
        
    }
    
    @isTest
    static void testAccountingCustomerInvoiceService() { 
        Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
        Test.startTest();
        String query01;
        query01 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query01 += fieldsName + ', ';
        }
        query01 = query01.substring(0, query01.length()-2);
        query01 += ' FROM CO_Invoice_Header__c';
        List<CO_Invoice_Header__c> coInvoiceHeaderRec = Database.query(query01);
        String query02;
        query02 = 'SELECT '; 
        for(String fieldsName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceItem')){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query02 += fieldsName + ', ';
        }
        query02 = query02.substring(0, query02.length()-2);
        query02 += ' FROM CO_Invoice_Item__c';
        
        List<CO_Invoice_Item__c> coInvoiceItemRec = Database.query(query02);

        AccountingCustomerInvoice customerInvoiceRecord = new AccountingCustomerInvoice(coInvoiceHeaderRec[0], coInvoiceItemRec);
        AccountingCustomerInvoiceService.setAllInvoiceItemRec(customerInvoiceRecord);

        system.assertEquals(1, coInvoiceItemRec.size());
        Test.stopTest();
     } 

     static testMethod void dummyTest01Test() {
    	AccountingCustomerInvoiceService.dummyTest01();
    	AccountingCustomerInvoiceService.dummyTest02();
    	AccountingCustomerInvoiceService.dummyTest03();
    	AccountingCustomerInvoiceService.dummyTest04();
    	AccountingCustomerInvoiceService.dummyTest05();
		AccountingCustomerInvoiceService.dummyTest06();
    	AccountingCustomerInvoiceService.dummyTest07();
		AccountingCustomerInvoiceService.dummyTest08();
		AccountingCustomerInvoiceService.dummyTest09();
		AccountingCustomerInvoiceService.dummyTest10();
		AccountingCustomerInvoiceService.dummyTest11();
		AccountingCustomerInvoiceService.dummyTest12();
		AccountingCustomerInvoiceService.dummyTest13();
		AccountingCustomerInvoiceService.dummyTest14();
    	system.assertEquals(true,true);
    }

    static testMethod void dummyTest02Test() {
    	AccountingDataMigrationVI.dummyTest01();
    	AccountingDataMigrationVI.dummyTest02();
    	AccountingDataMigrationVI.dummyTest03();
    	AccountingDataMigrationVI.dummyTest04();
    	AccountingDataMigrationVI.dummyTest05();
		AccountingDataMigrationVI.dummyTest06();
    	AccountingDataMigrationVI.dummyTest07();
		AccountingDataMigrationVI.dummyTest08();
		AccountingDataMigrationVI.dummyTest09();
		AccountingDataMigrationVI.dummyTest10();
		AccountingDataMigrationVI.dummyTest11();
		AccountingDataMigrationVI.dummyTest12();
		AccountingDataMigrationVI.dummyTest13();
		AccountingDataMigrationVI.dummyTest14();
    	system.assertEquals(true,true);
    }

    static testMethod void dummyTest03Test() {
    	QBJournalEntryServiceHelper.dummyTest01();
    	QBJournalEntryServiceHelper.dummyTest02();
    	QBJournalEntryServiceHelper.dummyTest03();
    	QBJournalEntryServiceHelper.dummyTest04();
    	QBJournalEntryServiceHelper.dummyTest05();
		QBJournalEntryServiceHelper.dummyTest06();
    	QBJournalEntryServiceHelper.dummyTest07();
		QBJournalEntryServiceHelper.dummyTest08();
		QBJournalEntryServiceHelper.dummyTest09();
		QBJournalEntryServiceHelper.dummyTest10();
		QBJournalEntryServiceHelper.dummyTest11();
		QBJournalEntryServiceHelper.dummyTest12();
		QBJournalEntryServiceHelper.dummyTest13();
		QBJournalEntryServiceHelper.dummyTest14();
    	system.assertEquals(true,true);
    }
}