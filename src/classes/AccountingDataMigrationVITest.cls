@isTest
public without sharing class AccountingDataMigrationVITest{

	 @testSetup
	 private static void setupTestData(){
		  TestUtil.createNameSpaceInGeneralConfig();
		  List <General_Configurations__c> config = [SELECT Id FROM General_Configurations__c LIMIT: SOQLUtil.getAvailableQueryRowsLimit()];
		  system.assertNotEquals(0, config.size());
	 }
	
	 @isTest
	 static void executeDataMigrationBatchTest(){
	  	Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        Vendor_Invoicing_Header__c viHeader = TestUtil.createVendorInvoiceHeader(true, vendor.Id, 'Invoiced');
	  	Vendor_Receiving_Header__c vor = TestUtil.createVendorOrderReceiveHeader(false, vendor.Id, 'Stocked');
	  	vor.Finalized_Date__c = Date.today().addDays(3);
	  	insert vor;
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
	  	Part.Packaged_Part__c = true;
	  	Part.Package_Qty__c = 22;
	  	Part.Auto_reorder_Min__c = 0;
	  	part.Auto_reorder_Max__c = 100;
	  	part.Order_Lots__c = 1;
	  	insert part;
        Vendor_Receiving_Group__c vrg = new Vendor_Receiving_Group__c();
	  	vrg.Vendor_Receiving_Header__c = vor.Id;
	  	vrg.Part__c = part.Id;
	  	vrg.Cost__c = 10;
	  	vrg.Recieved__c = 128;
	  	insert vrg;
        Vendor_Invoicing_Group__c viGroup = TestUtil.createVendorInvoicingGroup(viHeader.id, vrg.id, 10);
        viGroup.VI_Cost__c = 10;
        viGroup.VI_Qty__c = 10;
        viGroup.VI_SubTotal__c = 100;
        viGroup.Vendor_Receiving_Group__c = vrg.id;
        Update viGroup;
	  	Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
	  	Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
	  	Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
	  	CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(true, coHeader.id, 'Closed');
        Deal__c deal = new Deal__c(CO_Header__c = coHeader.id, Invoice_Number__c = coInvoiceHeader.id);
        insert deal;
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(false, coHeader.Id, part.Id, 130);
        coLineItem.Avg_Cost__c = 100;
        coLineItem.Deal__c = deal.id;
        insert coLineItem;
        CO_Invoice_Item__c coInvoiceItem = TestUtil.createCOInvoiceItem(false, testCategory.Id, coInvoiceHeader.Id, null);
        coInvoiceItem.CO_Line_Item__c = coLineItem.id;
        insert coInvoiceItem;
        Customer_Owned_Unit__c referencedUnit = TestUtil.createCustomerOwnedUnit(true, null, null, null, null);
        Customer_Owned_Unit__c cou = TestUtil.createCustomerOwnedUnit(false, null, null, null, null);
        cou.Unit_Type__c = 'STOCK';
        cou.Referenced_Unit__c = referencedUnit.id;
        cou.Status__c = 'Available';
        insert cou;
        Vendor_Order_Line_Item__c voLineItem = TestUtil.createVendorOrderLineItem(false, voHeader.Id, part.Id, 150);
	  	voLineItem.Vendor_Receiving_Group__c = vrg.Id;
	  	insert voLineItem;
        Return_VO_Header__c returnVOHeader = new Return_VO_Header__c(vendor__c = vendor.id, Status__c = 'Credited', Credited_Date__c = system.today(), Returned_Date__c = system.today(), Submitted_Date__c = system.today());
        insert returnVOHeader;
        insert new Return_VO_Line_Item__c(part__c = part.id, Return_VO_Header__c = returnVOHeader.id, Return_Qty__c = 10, Item_Cost__c = 10, Inventory_Cost__c = 10);
	  	
	  	Test.startTest();
	  	List <Accounting_Data_Migration__c> accountMigrate = TestUtil.createAccountMigration(true, 1, 'Vendor Invoicing', 'Vendor Invoicing');
	  	Id batchId = AccountingDataMigrationVI.executeDataMigrationBatch(200, null, 'THIS_WEEK', DateTime.now(), DateTime.now().addDays(2), DataExportUtil.VENDOR_INVOICING_ACCOUNTING_OBJECT_NAME);
	  	Test.stopTest();
	  
	  	List <Accounting_Data_Migration__c> accountMigrateList = [SELECT Id FROM Accounting_Data_Migration__c WHERE Object_Name__c = 'Vendor Invoicing'];
	  	List <Attachment> attachmentList = [SELECT Id FROM Attachment WHERE ParentId IN: accountMigrateList];
	  	system.assertEquals(1, attachmentList.size());
	 }
	
	 	@isTest
	 	static void ConstructorCallTest(){
            AccountingDataMigrationVI AccountingDataMigrationVIObj1 = new AccountingDataMigrationVI();
            AccountingDataMigrationVI AccountingDataMigrationVIObj2 = new AccountingDataMigrationVI(null, true);
            AccountingDataMigrationVI AccountingDataMigrationVIObj3 = new AccountingDataMigrationVI(null, true, null, null, null);
	  		System.assertEquals(0, [Select count() from account]);
	 }
}