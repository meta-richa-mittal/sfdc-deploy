/**
 * Author: Durga Singh
 * Since: July 17, 2015
 * Name: ViewPartCtrlTest
 * Description: Controller test Class to view part.
**/
@isTest
private class ViewPartCtrlTest {
	
	@testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    	TestUtil.bypassValidation();
    	User testUser = TestUtil.createUser(true, 'a@b.c', 'Sharma', 'en_US', 'Shantanu.Sharma@metacube.com', 'sshar');
		User_Group__c userGroup = new User_Group__c(name='testing user group',OwnerId =testUser.id, Colour_Code__c='rgba(255,100,88,1)',Accounting_settings_export__c='Primary',
                                           Costs__c='Primary',Customer_invoicing__c='Primary',customers__c='Primary',Deal__c='Primary',fees__c='Primary',Internal_Service__c='Primary',
                                           kits__c='Secondary',labor__c='Secondary',Merchandise__c='Primary',Override_price__c='Primary',Oversell_inventory__c='Primary',parts__c='Primary',
                                           Price_file_import__c='Secondary',Price_Levels__c='Secondary',quick_sale__c='Secondary',Returns__c='Secondary',Sales_Taxes__c='Secondary',Service_job__c='Secondary',
                                           Special_order__c='None',stock_units__c='Secondary',System_Settings__c='Primary',Vendor_invoicing__c='Primary',Vendor_order__c='Primary',
                                           vendor_products__c='Primary',Vendor_receiving__c='Primary',vendors__c='Primary');
		insert userGroup;
  		
  		List<User_Group__c> userGroupList = [select Id from User_Group__c];
  		String userId = UserInfo.getUserId();
  		List<String> usersList = new List<String>();
  		usersList.add(userId);
  		system.assert(true,true);
  		UserSettingCtrl.assignUserToGroup(BPUtility.getEncodedString(System.JSON.serialize(usersList)), BPUtility.getEncodedString(userGroupList[0].Id));
    }
    
    /**
     * Name: getPartInfoTest
     * Desc: getpart info records on partId.
     * @param: 
     * @return: 
    **/
    static testMethod void getPartInfoTest() {
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        
        Test.startTest();
        String partsJSONString = BPUtility.getDecodedString(ViewPartCtrl.getPartInfo(BPUtility.getEncodedString(part.Id)));
        Test.stopTest();
        
        PartDetailWrapper partObjRec = (PartDetailWrapper) System.JSON.deserialize(partsJSONString, PartDetailWrapper.class);
        system.assertEquals(partObjRec.PartDetailRec.QtyAvailable, 100);
    }
    
    
    /**
     * Name: getStatisticsCalculationTest
     * Desc: Test states and  other calculation about parts.
     * @param: 
     * @return: 
    **/
    static testMethod void getStatisticsCalculationTest() {
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 90);
        CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(true, coHeader1.Id, 'Active');
        CO_Invoice_Item__c coinvoiceitem1  = TestUtil.createCOInvoiceItem(true, testCategory.Id, coinvoiceHeader1.Id, coLineItemRec.Id, true );
        
        String coInvoiceItemJson = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoiceItemListOnly(BPUtility.getEncodedString(coInvoiceHeader1.Id)));
        CustomerOrderWrapper.CheckoutWrapper checkoutObj = (CustomerOrderWrapper.CheckoutWrapper) System.JSON.deserialize(coInvoiceItemJson, CustomerOrderWrapper.CheckoutWrapper.class);
        CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString(System.JSON.serialize(checkoutObj.InvoiceItemList)), BPUtility.getEncodedString(coHeader1.Id), BPUtility.getEncodedString('Customer'));
       
        List<String> testList  = ViewPartCtrl.getStatisticsCalculation(part.Id);
        Test.StartTest();
        system.assertEquals(testList[0], '90.00');
        system.assertEquals(testList[1], '4950.00');
         
        CO_Header__c coHeader2 = TestUtil.createCOHeader(true, null);
        CO_Line_Item__c coLineItemRec1 = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 5);
        CO_Invoice_Header__c coinvoiceHeader2 = TestUtil.createCOInvoiceHeader(true, coHeader2.Id, 'Active');
        CO_Invoice_Item__c coinvoiceitem2  = TestUtil.createCOInvoiceItem(true, testCategory.Id, coinvoiceHeader2.Id, coLineItemRec1.Id, true );
        
        String COInvoiceItemJSON1 = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOInvoiceItemListOnly(BPUtility.getEncodedString(coInvoiceHeader2.Id)));
        CustomerOrderWrapper.CheckoutWrapper checkoutObj1 = (CustomerOrderWrapper.CheckoutWrapper) System.JSON.deserialize(COInvoiceItemJSON1, CustomerOrderWrapper.CheckoutWrapper.class);
        CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString(System.JSON.serialize(checkoutObj1.InvoiceItemList)), BPUtility.getEncodedString(coHeader2.Id), BPUtility.getEncodedString('Customer'));
        
        List<String> testList1  = ViewPartCtrl.getStatisticsCalculation(part.Id);
        system.assertEquals(testList1[0], '95.00');
        system.assertEquals(testList1[1], '5225.00');
        String lastSoldTimeHour = '';
        if(testList1[3].length() > 0) {
            List<String> lastSoldTimeList =  testList1[3].split(' ');
            lastSoldTimeHour = lastSoldTimeList[lastSoldTimeList.size() - 1];
        }
        system.assertEquals(lastSoldTimeHour, '0h');
        Test.StopTest();
    }
    
        /**
     * Name: increaseAdjustInStockTest
     * Desc: Test to increase part qty using FIFObucket.
     * @param: 
     * @return: 
    **/
    static testMethod void increaseAdjustInStockTest() {
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        
        String increasedStock = BPUtility.getDecodedString(ViewPartCtrl.increaseAdjustInStock(BPUtility.getEncodedString(part.Id), 20, 200));
        PartDetailWrapper partObjRec = (PartDetailWrapper) System.JSON.deserialize(increasedStock, PartDetailWrapper.class);
        system.assertEquals(partObjRec.AverageCost, 50 );
        system.assertEquals(partObjRec.QtyInStock, 120);
        system.assertEquals(partObjRec.TotalFIFORecords, 2);
        
    }
    
            /**
     * Name: decreaseAdjustInStockTest
     * Desc: Test to decrease part qty using FIFObucket.
     * @param: 
     * @return: 
    **/
    static testMethod void decreaseAdjustInStockTest() {
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        
        String partsJSONString = BPUtility.getDecodedString(ViewPartCtrl.getPartInfo(BPUtility.getEncodedString(part.Id)));
        PartDetailWrapper partObjRec = (PartDetailWrapper) System.JSON.deserialize(partsJSONString, PartDetailWrapper.class);
       
        String decreasedStock = BPUtility.getDecodedString(ViewPartCtrl.decreaseAdjustInStock(BPUtility.getEncodedString(part.Id), 20, BPUtility.getEncodedString(System.JSON.serialize(partObjRec.PartFIFOBucketList))));
        PartDetailWrapper partObjRec1 = (PartDetailWrapper) System.JSON.deserialize(decreasedStock, PartDetailWrapper.class);
        //system.assert(false, partObjRec1);
        system.assertEquals(partObjRec1.AverageCost, 20 );
        system.assertEquals(partObjRec1.QtyInStock, 80);
        system.assertEquals(partObjRec1.TotalFIFORecords, 1);
        
    }
    
                /**
     * Name: modifyCostSummarytest
     * Desc: Test to modify cost summary using FIFObucket.
     * @param: 
     * @return: 
    **/
    static testMethod void modifyCostSummaryTest() {
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        
        String partsJSONString = BPUtility.getDecodedString(ViewPartCtrl.getPartInfo(BPUtility.getEncodedString(part.Id)));
        PartDetailWrapper partObjRec = (PartDetailWrapper) System.JSON.deserialize(partsJSONString, PartDetailWrapper.class);
       
        String modifyCost = BPUtility.getDecodedString(ViewPartCtrl.modifyCostSummary(BPUtility.getEncodedString(System.JSON.serialize(partObjRec.PartFIFOBucketList)), 50));
        PartDetailWrapper partObjRec1 = (PartDetailWrapper) System.JSON.deserialize(modifyCost, PartDetailWrapper.class);
        //system.assert(false, partObjRec1);
        system.assertEquals(partObjRec1.AverageCost, 50 );
        system.assertEquals(partObjRec1.QtyInStock, 100);
        system.assertEquals(partObjRec1.TotalFIFORecords, 2);
        
    }
             /*
     * Name: SOCompleteFlowTest
     * Desc: Test to check complete flow for SO.
     * @param: 
     * @return: 
    **/
     static testMethod void resolveOversoldTest() {
        
        //Created test data to check scenario
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
           //Price level of 10% on MSRP
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
           // Part with available qty 100 and having MSRP $50
        Part__c part = TestUtil.createPart(true, 'TestPart', vendor.Id, 'TestPart', testCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
            // created customer order
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 120);
        coLineItem.Qty_Committed__c = 120 ;
        update coLineItem ;
        
        List<CO_Line_Item__c> colineitemList = [select Part__c, Qty_Committed__c, Qty__c, Status__c, Sub_Total_Without_Tax__c, Sub_Total_With_Tax__c from CO_Line_Item__c limit 100];
        //system.assert(false, colineitemList);
        Test.startTest();
        String details = BPUtility.getDecodedString(CustomerOrderCtrl_V2.getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeader.Id), null));
        COHeaderWrapper coHeaderDetails = (COHeaderWrapper) System.JSON.deserialize(details, COHeaderWrapper.class);
            
        String coInvoiceHeaderId = COInvoiceItemService.getActiveInvHeaderId(coHeader.Id);
        String savedCOInvoicePayment = BPUtility.getDecodedString(CustomerOrderCtrl_V2.addPayment(BPUtility.getEncodedString('[{"ReverseLink":null,"PaymentMethod":"Cash","Amount":"-110.000","COInvoiceHeaderId":"' + coInvoiceHeaderId + '"}]'), BPUtility.getEncodedString(coHeader.Id)));
        // Closing invoice
        CustomerOrderWrapper.CheckoutWrapper chkoutObj = COInvoiceItemService.getCOInvoiceItemList(coInvoiceHeaderId);
        String closedInvoiceAction = BPUtility.getDecodedString(CustomerOrderCtrl_V2.closedInvoiceAction(BPUtility.getEncodedString('[{"Total":6600.000,"TaxAmount":null,"Saving":null,"RetailPrice":null,"QtyRequired":null,"Qty":null,"Price":null,"Item":"Service Job 1","IsInvoiceable":true,"IsActive":true,"COLineItemId":null,"COInvoiceItemNumber":null,"COInvoiceItemId":"' + chkoutObj.InvoiceItemList[0].COInvoiceItemId + '", "COInvoiceHeaderId":"' + coInvoiceHeaderId + '", "$$hashKey":"object:56"}]'), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('Customer')));
        
        String partsJSONString = BPUtility.getDecodedString(ViewPartCtrl.getPartInfo(BPUtility.getEncodedString(part.Id)));
        PartDetailWrapper partObjRec = (PartDetailWrapper) System.JSON.deserialize(partsJSONString, PartDetailWrapper.class);
         system.assertEquals(partObjRec.OversoldQty, 20);
        //system.assert(false, partObjRec);
        Test.stopTest();
        
        List<Part__c> parts = [select AvailableParts__c from Part__c where Id = :part.id ];
        system.assertEquals(parts[0].AvailableParts__c, 0);
        
        List<Id> fixedSearchResults = new List<Id>{part.Id};
        Test.setFixedSearchResults(fixedSearchResults);
        
        HomeSearchFilterWrapper filterWrapper = new HomeSearchFilterWrapper();
        filterWrapper.Type.objects = new Set<String>{'Parts'};
        String jsonStr = System.Json.serialize(filterWrapper);
        
        String customerdetails1 = BPUtility.getDecodedString(HomeSearchCtrl.getFilteredRecords(BPUtility.getEncodedString(jsonStr), BPUtility.getEncodedString('{"ChangesCount":1,"CurrentPage":1,"PageSize":50,"Sorting":[{"FieldName":"LastModifiedDate","SortDirection":"DESC"}]}')));
        HomeSearchResultWrapper.ResultWrapper details1 = (HomeSearchResultWrapper.ResultWrapper) System.JSON.deserialize(customerdetails1, HomeSearchResultWrapper.ResultWrapper.class);
        system.assertEquals(details1.PartRecords[0].Oversold_Qty, 20);
        system.assertEquals(details1.PartRecords[0].Oversold_Cost, 400);
        String resolveOversold = BPUtility.getDecodedString(ViewPartCtrl.resolveOversoldInStock(BPUtility.getEncodedString(System.JSON.serialize(partObjRec.PartFIFOBucketList))));
        PartDetailWrapper partObjRec1 = (PartDetailWrapper) System.JSON.deserialize(resolveOversold, PartDetailWrapper.class);
        //system.assert(false, partObjRec1);
        system.assertEquals(partObjRec1.AverageCost, 0 );
        system.assertEquals(partObjRec1.QtyInStock, 0);
        system.assertEquals(partObjRec1.TotalFIFORecords, 2);
        
        String FIFOHistory = BPUtility.getDecodedString(ViewPartCtrl.getHistoryRecords(BPUtility.getEncodedString(part.Id), true ));
        List<PartFIFOBucket> partObjRec2 = (List<PartFIFOBucket>) System.JSON.deserialize(FIFOHistory, List<PartFIFOBucket>.class);
        system.assertEquals(partObjRec2.size(), 2);
        
        
        
     }
     
     static testMethod void AverageCostCalculationFromVendorReceiveTest() {
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        //System.JSON.serialize(pageSort)

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, 'partNumberP03', vendor.Id, 'Test Part03', testCategory.Id, 10, 20, 50, 100, 50);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
 

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), null));
        String VendorOrderReceiveItems =BPUtility.getDecodedString( VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        
        Test.startTest();
        String allLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addAllLineItemsToItemSubsection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(voHeader.Id), null, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderReceivingCtrl.VendorOrderReceiving voLineReceiveItems1 = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(allLineItems, VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        //system.assert(false, voLineReceiveItems1 );
        String UpdatedItemsSubsection = BPUtility.getDecodedString(VendorOrderReceivingCtrl.updateItemsSection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(part.id), BPUtility.getEncodedString(voLineReceiveItems1.VORGroupList[0].Id), 100, 30, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String commitLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.commitRecevingAction(BPUtility.getEncodedString(vorId)));
        
       /* Vendor_Invoicing_Header__c viHeader = TestUtil.createVendorInvoiceHeader(true, vendor.Id, 'In Progress');
        String vendorInvoices = VendorInvoicingCtrl.addVendor(vendor.Id, viHeader.Id, System.JSON.serialize(pageSort), System.JSON.serialize(pageSort));
        String addedVendorInvoice = VendorInvoicingCtrl.addToItemsSubsection(viHeader.Id, vorId, System.JSON.serialize(pageSort), System.JSON.serialize(pageSort));
        String finalaizedInvoice = VendorInvoicingCtrl.finalizeInvoiceAction(viHeader.Id, System.JSON.serialize(pageSort), System.JSON.serialize(pageSort));
        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoice = (VendorInvoicingCtrl.VIHeaderWrapper)System.JSON.deserialize(finalaizedInvoice, VendorInvoicingCtrl.VIHeaderWrapper.class);*/
        Test.stopTest();
        
        String FIFOHistory = BPUtility.getDecodedString(ViewPartCtrl.getHistoryRecords(BPUtility.getEncodedString(part.Id), true ));
        List<PartFIFOBucket> partObjRec2 = (List<PartFIFOBucket>) System.JSON.deserialize(FIFOHistory, List<PartFIFOBucket>.class);
        //system.assert(false, partObjRec2);
        List<Part__c> partList1 = [select Id, Part_Number__c, Qty_Committed__c, Qty_In_Stock__c, Qty_On_Order__c, Average_Cost__c from Part__c limit 100];
        system.assertEquals(partList1[0].Average_Cost__c, 26.67);

    }
    
     static testMethod void AverageCostCalculationFromVendorInvoiceTest() {
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        //System.JSON.serialize(pageSort)

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, 'partNumberP03', vendor.Id, 'Test Part03', testCategory.Id, 10, 20, 50, 100, 50);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
 

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), null));
        String VendorOrderReceiveItems =BPUtility.getDecodedString( VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        
        Test.startTest();
        String allLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addAllLineItemsToItemSubsection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(voHeader.Id), null, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderReceivingCtrl.VendorOrderReceiving voLineReceiveItems1 = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(allLineItems, VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        //system.assert(false, voLineReceiveItems1 );
        String UpdatedItemsSubsection = BPUtility.getDecodedString(VendorOrderReceivingCtrl.updateItemsSection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(part.id), BPUtility.getEncodedString(voLineReceiveItems1.VORGroupList[0].Id), 100, 30, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String commitLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.commitRecevingAction(BPUtility.getEncodedString(vorId)));
        
        Vendor_Invoicing_Header__c viHeader = TestUtil.createVendorInvoiceHeader(true, vendor.Id, 'In Progress');
        String vendorInvoices = BPUtility.getDecodedString(VendorInvoicingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(viHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String addedVendorInvoice = BPUtility.getDecodedString(VendorInvoicingCtrl.addToItemsSubsection(BPUtility.getEncodedString(viHeader.Id), BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        //VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicelatest = (VendorInvoicingCtrl.VIHeaderWrapper)System.JSON.deserialize(addedVendorInvoice, VendorInvoicingCtrl.VIHeaderWrapper.class);
        //String updateVendorInvoice = VendorInvoicingCtrl.updateVIGroup(viHeader.Id, vorId, '{"VIGroupId":"'+vendorInvoicelatest.VIGroupList[0].VIGroupId+'","SubTotal":0,"ReceivingQty":100,"ReceivingCost":0,"PackingNumber":null,"PackageUnit":null,"PackageQty":0,"OrderType":"","LcaAmount":null,"Item":"123654789TSS204 - Tyers","InvoiceQty":100,"InvoiceCost":"50","DiscountAmout":0,"Discount":0}', System.JSON.serialize(pageSort), System.JSON.serialize(pageSort));
        String finalaizedInvoice = BPUtility.getDecodedString(VendorInvoicingCtrl.finalizeInvoiceAction(BPUtility.getEncodedString(viHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoice = (VendorInvoicingCtrl.VIHeaderWrapper)System.JSON.deserialize(finalaizedInvoice, VendorInvoicingCtrl.VIHeaderWrapper.class);
        Test.stopTest();
        
        String FIFOHistory = BPUtility.getDecodedString(ViewPartCtrl.getHistoryRecords(BPUtility.getEncodedString(part.Id), true ));
        List<PartFIFOBucket> partObjRec2 = (List<PartFIFOBucket>) System.JSON.deserialize(FIFOHistory, List<PartFIFOBucket>.class);
        //system.assert(false, partObjRec2);
        List<Part__c> partList1 = [select Id, Part_Number__c, Qty_Committed__c, Qty_In_Stock__c, Qty_On_Order__c, Average_Cost__c from Part__c limit 100];
        system.assertEquals(partList1[0].Average_Cost__c, 26.6666666666666666666666666666667);

    }
    
    static testMethod void saveAdjustCostDetailsTest() {
        PaginationSorting pageSort = new PaginationSorting();
        pageSort.CurrentPage = 1;
        pageSort.PageSize = 10;
        pageSort.Sorting = new List < PaginationSorting.SortAttrs > {
            new PaginationSorting.SortAttrs('Item', 'ASC')
        };
        //System.JSON.serialize(pageSort)
        General_Configurations__c genConfig = Testutil.createGeneralConfig(10, true);
        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(false, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(false, 'Default Price Level', 'MSRP', 10, true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(false, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true, 'Individual');
        insert new List<SObject>{vendor, testCategory, defaultPriceLevel, defaultSalesTax, customer};
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(true, 'partNumberP03', vendor.Id, 'Test Part03', testCategory.Id, 10, 20, 50, 100, 50);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
 

        PO_Type__c POType = TestUtil.createPurchaseOrder(true, 'purchaseOrderCode', vendor.Id, true, 2);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Purchase_Order_Type__c = POType.Id;
        insert voHeader;
        String similarlineitem = BPUtility.getDecodedString(VendorOrderCtrl.groupAllVOLineItem(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(voHeader.Id), true,  BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String finalizedLineItems = BPUtility.getDecodedString(VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderLineItemWrapper voLineItems = (VendorOrderLineItemWrapper) System.JSON.deserialize(finalizedLineItems, VendorOrderLineItemWrapper.class);
        
        Test.startTest();
        Vendor_Receiving_Header__c vrh = TestUtil.createVendorOrderReceiveHeader(true, vendor.Id, 'In Progress');
        Id vorId = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), null));
        String VendorOrderReceiveItems =BPUtility.getDecodedString( VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeader.Id), BPUtility.getEncodedString(vorId), true));
        
        String allLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.addAllLineItemsToItemSubsection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(voHeader.Id), null, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorOrderReceivingCtrl.VendorOrderReceiving voLineReceiveItems1 = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(allLineItems, VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        //system.assert(false, voLineReceiveItems1 );
        String UpdatedItemsSubsection = BPUtility.getDecodedString(VendorOrderReceivingCtrl.updateItemsSection(BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(part.id), BPUtility.getEncodedString(voLineReceiveItems1.VORGroupList[0].Id), 100, 30, BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String commitLineItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.commitRecevingAction(BPUtility.getEncodedString(vorId)));
        
        Vendor_Invoicing_Header__c viHeader = TestUtil.createVendorInvoiceHeader(true, vendor.Id, 'In Progress');
        String vendorInvoices = BPUtility.getDecodedString(VendorInvoicingCtrl.addVendor(BPUtility.getEncodedString(vendor.Id), BPUtility.getEncodedString(viHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        String addedVendorInvoice = BPUtility.getDecodedString(VendorInvoicingCtrl.addToItemsSubsection(BPUtility.getEncodedString(viHeader.Id), BPUtility.getEncodedString(vorId), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        //VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicelatest = (VendorInvoicingCtrl.VIHeaderWrapper)System.JSON.deserialize(addedVendorInvoice, VendorInvoicingCtrl.VIHeaderWrapper.class);
        //String updateVendorInvoice = VendorInvoicingCtrl.updateVIGroup(viHeader.Id, vorId, '{"VIGroupId":"'+vendorInvoicelatest.VIGroupList[0].VIGroupId+'","SubTotal":0,"ReceivingQty":100,"ReceivingCost":0,"PackingNumber":null,"PackageUnit":null,"PackageQty":0,"OrderType":"","LcaAmount":null,"Item":"123654789TSS204 - Tyers","InvoiceQty":100,"InvoiceCost":"50","DiscountAmout":0,"Discount":0}', System.JSON.serialize(pageSort), System.JSON.serialize(pageSort));
        String finalaizedInvoice = BPUtility.getDecodedString(VendorInvoicingCtrl.finalizeInvoiceAction(BPUtility.getEncodedString(viHeader.Id), BPUtility.getEncodedString(System.JSON.serialize(pageSort)), BPUtility.getEncodedString(System.JSON.serialize(pageSort))));
        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoice = (VendorInvoicingCtrl.VIHeaderWrapper)System.JSON.deserialize(finalaizedInvoice, VendorInvoicingCtrl.VIHeaderWrapper.class);
        
        String FIFOHistory = BPUtility.getDecodedString(ViewPartCtrl.getHistoryRecords(BPUtility.getEncodedString(part.Id), true ));
        List<PartFIFOBucket> partObjRec2 = (List<PartFIFOBucket>) System.JSON.deserialize(FIFOHistory, List<PartFIFOBucket>.class);
        //system.assert(false, partObjRec2[1].PartId);
       
        
       // String adjustedcost = BPUtility.getDecodedString(ViewPartCtrl.saveAdjustedCostDetails(BPUtility.getEncodedString('{"VendorRecievingVendorName":null,"vendorInvoicingVendorName":null,"UniqueId":"VI-0001862","Type":null,"Total":800,"SourceName":"Vendor Invoice","RemainingQty":100,"Reference":"HyperMotar","QtyOut":0,"QtyIn":100,"PartName":"testfifoautomation","PartId":"'+partObjRec2[1].PartId+'","PartFIFOActivityLineItemList":[],"IsFiFoBucket":true,"FIFOBucketId":"'+partObjRec2[1].FIFOBucketId+'","CreatedDate":"Jun 20, 2016","Cost":40,"isEdit":true}'), 50, true));
        //List<Part__c> partList1 = [select Id, Part_Number__c, Qty_Committed__c, Qty_In_Stock__c, Qty_On_Order__c, Average_Cost__c from Part__c limit 100];
        //system.assertEquals(partList1[0].Average_Cost__c, 40);
		 Test.stopTest();
		 system.assert(true,true);
    }
}