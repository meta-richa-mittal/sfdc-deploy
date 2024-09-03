@IsTest
public class VO_VendorOrderTest {

    @TestSetup
    static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    }
    
    static void makeTestData() {
        List<Account_Type__c> accountTypeList = TestDataFactory_V2.createTestDataForAccountType(true, 'Supplier', 'Vendors');
        List<Category__c> categoryList = TestDataFactory_V2.createTestDataForCategory(true);
        List<Sales_Tax__c> salesTaxList = TestDataFactory_V2.createTestDataForSalesTax(true, 'Purchase');
        List<Sales_Tax_Item__c> salesTaxItemList = TestDataFactory_V2.createTestDataForSalesTaxItem('Purchase', categoryList, true);
        List<Applicable_Taxes__c> applicableTaxList = TestDataFactory_V2.createTestDataForApplicableTax(salesTaxList, salesTaxItemList, true);
        List<Account> vendorList = TestDataFactory_V2.createTestDataForVendor(true, accountTypeList, salesTaxList);
        List<Part__c> partList = TestDataFactory_V2.createTestDataForPart(categoryList, vendorList, salesTaxList, true);
        
        accountTypeList = TestDataFactory_V2.createTestDataForAccountType(true);
        List<Price_Level__c> priceLevelList = TestDataFactory_V2.createTestDataForPriceLevel(true);
        List<Account> accountList = TestDataFactory_V2.createTestDataForCustomer(accountTypeList, priceLevelList, true);

    }

    @IsTest
    static void searchVendorTest() {
        makeTestData();
        
        Test.startTest();
            String jsonString = BPUtility.getEncodedString('{"ObjectLabel":"Vendor","SearchText":"test0","SearchFieldName":"Name","FilterValues":[{"Field":"Active__c","Value":true,"Operator":"="}]}');
            String result = AutoCompleteCtrl.getSearchResults(jsonString);
            AutoCompleteCtrl.ResultJSON searchObj = (AutoCompleteCtrl.ResultJSON) System.JSON.deserialize(BPUtility.getDecodedString(result), AutoCompleteCtrl.ResultJSON.class);
        Test.stopTest();

        System.assertEquals([SELECT Id FROM Account LIMIT 1].Id, searchObj.CustomerList[0].Id);
    }

    @IsTest
    static void activeVOCountTest() {
        makeTestData();

        Test.startTest();
            Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
            Vendor_Order_Header__c vo1 = new Vendor_Order_Header__c(Vendor__c = vendorId, Status__c = 'Open');
            Vendor_Order_Header__c vo2 = new Vendor_Order_Header__c(Vendor__c = vendorId, Status__c = 'Locked');
            Vendor_Order_Header__c vo3 = new Vendor_Order_Header__c(Vendor__c = vendorId, Status__c = 'Open');
            insert new List<Vendor_Order_Header__c> {vo1, vo2, vo3};

            String activeVOCount = BPUtility.getDecodedString(VendorOrderCtrl.getActiveVOCountByVendorId(BPUtility.getEncodedString(vendorId)));
        Test.stopTest();
            
        System.assertEquals('3', activeVOCount, 'Incorrect active VO count for vendorId ' + vendorId);
    }

    @IsTest
    static void createVendorOrderTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;

        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
        Test.stopTest();
        assertCreateVendorOrder(voHeaderId);
    }

    @IsTest
    static void addVOLineItemTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
            String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
            String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
            String lineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), 1, itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, BPUtility.getEncodedString(null), true));        
            String voLineItemDetail = VendorOrderCtrl.getVOLineItemWrapperJSON(null, BPUtility.getEncodedString(voHeaderId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, null, null);
            VendorOrderLineItemWrapper resultWrapper = (VendorOrderLineItemWrapper) System.JSON.deserializeStrict(BPUtility.getDecodedString(voLineItemDetail), VendorOrderLineItemWrapper.class);
        Test.stopTest();

        assertAddVOLineItem(resultWrapper);
    }

    @IsTest
    static void getBPExportFormatTest(){
        GE_File_Config__c fileConfig1 = new GE_File_Config__c(Object_API_Name__c = 'Part__c', File_Content_Type__c = 'csv', File_Separator__c = 'comma', File_Name__c = 'Yamaha Australia', Blackpurl_Format__c = true);
        GE_File_Config__c fileConfig2 = new GE_File_Config__c(Object_API_Name__c = 'Part__c', File_Content_Type__c = 'csv', File_Separator__c = 'comma', File_Name__c = 'Honda Australia', Blackpurl_Format__c = false);
        insert new List<GE_File_Config__c>{fileConfig1, fileConfig2};

        Yamaha_Australia_Config__c yamahaConfig = new Yamaha_Australia_Config__c(Dealer_Code__c = '123', Sales_Person_Code__c = '123', User_ID__c = '123');
        insert yamahaConfig;

        Test.startTest();
            String result = BPUtility.getDecodedString(VendorOrderCtrl.getBPExportFormatList());
            List<GenericExportWrapper.BPExportFormatWrapper> bpExportFormatList = (List<GenericExportWrapper.BPExportFormatWrapper>) System.JSON.deserialize(result, List<GenericExportWrapper.BPExportFormatWrapper>.class);
        Test.stopTest();
        system.assertEquals(fileConfig1.Id, bpExportFormatList[0].Id);
    }

    @IsTest
    static void deleteVOLIGroupTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
            String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
            String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
            // Create VO Group Line Item
            String lineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), 1, itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, BPUtility.getEncodedString(null), true));        
            
            String voLineItemDetail = VendorOrderCtrl.getVOLineItemWrapperJSON(null, BPUtility.getEncodedString(voHeaderId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, null, null);
            VendorOrderLineItemWrapper resultWrapper = (VendorOrderLineItemWrapper) System.JSON.deserializeStrict(BPUtility.getDecodedString(voLineItemDetail), VendorOrderLineItemWrapper.class);
            
            // Delete VO Group Line Item
            VendorOrderCtrl.removeGroupFromOrder(BPUtility.getEncodedString(resultWrapper.VendorOrderLineItemGroupList[0].Id), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);  
        Test.stopTest();

        assertCreateVendorOrder(voHeaderId);
    }

    @IsTest
    static void deleteVOLITest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Test.startTest();

           // Create CO with Line Item
            CO_CreateCOTest.coWithCustomer = true;
            CO_CreateCOTest.createCO(CO_CreateCOTest.partSaleSellingGroup, false);
            String customerId = [SELECT Id FROM Account LIMIT 1].Id;
            List<CO_Header__c> coHeaderList = [SELECT Id FROM CO_Header__c LIMIT 1];
            Account vendor = [SELECT Id, Name FROM Account LIMIT 1];
            Part__c part = [SELECT Id, Part_Number__c,AvailableParts__c,Description__c, Item_Description__c,Category__c,Non_Inventory_Part__c,Vendor__c,Order_Lots__c,Average_Cost__c,Last_Cost__c,MSRP__c,Retail_Price__c,Qty_In_Stock__c, Qty_Committed__c FROM Part__c LIMIT 1];
            String jSONString = '[{"AvailableQty": "' + part.AvailableParts__c * 2 + '", "Item": "'+ part.Part_Number__c +' - '+ part.Item_Description__c +'", "NonInventoryPart": ' + part.Non_Inventory_Part__c  + ' , "PartId": "' + part.Id + '", "Price": "'+ part.Retail_Price__c +'", "Qty": "'+ part.Qty_In_Stock__c +'", "QtyCommitted": "' + part.Qty_Committed__c + '", "Status": "In Stock", "VendorId": "'+ vendor.Id +'", "VendorName": "'+ vendor.Name +'"}]';
            String soHeaderId = null;
            Boolean isSuppress = false;
            Boolean isDuplicateCheck = false;
            COLineItemTriggerHelper.isTotalCalculated = false;
            CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString(customerId));
            CustomerOrderCtrl_V2.insertCOLineItems(BPUtility.getEncodedString(part.Id), BPUtility.getEncodedString(coHeaderList[0].Id), BPUtility.getEncodedString(jSONString), isSuppress, isDuplicateCheck, BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString(customerId));
            List<CO_Line_Item__c> coliList = [SELECT Id, Qty__c, Qty_To_Order__c FROM CO_Line_Item__c];
            delete coliList[0];
            
            // Create Vendor Order
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
            String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
            String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
            
            List<Vendor_Order_Line_Item__c> voliList = [SELECT Id FROM Vendor_Order_Line_Item__c];

            // Create VO Line Item
            VendorOrderCtrl.addSelectedLineItems(BPUtility.getEncodedString(System.JSON.serialize(new List<String>{voliList[0].Id})), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);	
        Test.stopTest();

            VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), 1, itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, BPUtility.getEncodedString(null), true);        

            String voLineItemDetail = VendorOrderCtrl.getVOLineItemWrapperJSON(null, BPUtility.getEncodedString(voHeaderId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, null, null);
            VendorOrderLineItemWrapper resultWrapper = (VendorOrderLineItemWrapper) System.JSON.deserializeStrict(BPUtility.getDecodedString(voLineItemDetail), VendorOrderLineItemWrapper.class);
            
            // Delete VO Line Item
            BPUtility.getDecodedString(VendorOrderCtrl.removeLineItemFromOrder(BPUtility.getEncodedString(resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[1].Id), BPUtility.getEncodedString(resultWrapper.VendorOrderLineItemGroupList[0].Id), BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vendorId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON));																						

            assertDeleteVOLI(voHeaderId);
    }

    @IsTest
    static void deleteVendorOrderTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;

        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            VendorOrderCtrl.deleteVendorOrder(BPUtility.getEncodedString(voHeaderId));
        Test.stopTest();
        System.assertEquals(0, [SELECT Id FROM Vendor_Order_Header__c].size());
    }

    @IsTest
    static void finalizeVendorOrderTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        
        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
            String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
            String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
            // Create VO Group Line Item
            String lineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), 1, itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, BPUtility.getEncodedString(null), true));        
            
            // Finalize Vendor order
            String finalizedLineItems = VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vendorId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
            VendorOrderLineItemWrapper resultWrapper = (VendorOrderLineItemWrapper) System.JSON.deserializeStrict(BPUtility.getDecodedString(finalizedLineItems), VendorOrderLineItemWrapper.class);
        Test.stopTest();

        assertFinalizeVendorOrder(resultWrapper);
    }

    static void assertFinalizeVendorOrder(VendorOrderLineItemWrapper resultWrapper) {
        Part__c partRec = [SELECT Id FROM Part__c LIMIT 1];
        PO_Type__c poTypeRec = [SELECT Id FROM PO_Type__c LIMIT 1];
        Vendor_Order_Header__c voHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Order_Header__c LIMIT 1];
        Vendor_Order_Line_Item__c voLineItemRec = [SELECT Id, Name FROM Vendor_Order_Line_Item__c LIMIT 1];
        Vendor_Order_Line_Item_Group__c voLineItemGroupRec = [SELECT Id, Name FROM Vendor_Order_Line_Item_Group__c LIMIT 1];
        
        system.assertEquals(100.0000, resultWrapper.GroupTotalCost);
        system.assertEquals(null, resultWrapper.NewLineItemId);

        system.assertEquals(poTypeRec.Id, resultWrapper.OrderTypes[0].Id);
        system.assertEquals(true, resultWrapper.OrderTypes[0].IsDefault);
        system.assertEquals('STANDARD', resultWrapper.OrderTypes[0].Name);
        system.assertEquals(true, resultWrapper.OrderTypes[0].UpdateCurrentCost);

        system.assertEquals(1, resultWrapper.TotalLineItemGroups);
        system.assertEquals(0, resultWrapper.TotalReceivedCost);
        system.assertEquals(0, resultWrapper.TotalRequiredForCustomers);
        system.assertEquals(0, resultWrapper.TotalRequiredForStocks);
        system.assertEquals(100.00, resultWrapper.TotalUnreceivedCost);

        system.assertEquals(null, resultWrapper.VendorOrderHeader.BRPStatus);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.HondaDealerNumber);
        system.assertEquals(voHeaderRec.Id, resultWrapper.VendorOrderHeader.Id);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.InProgressVR);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.InProgressVRId);
        system.assertEquals(false, resultWrapper.VendorOrderHeader.IsVOAssociatedWithBRPVendor);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.Notes);
        system.assertEquals(poTypeRec.Id, resultWrapper.VendorOrderHeader.OrderType.Id);
        system.assertEquals('STANDARD', resultWrapper.VendorOrderHeader.OrderType.Name);
        system.assertEquals(true, resultWrapper.VendorOrderHeader.OrderType.UpdateCurrentCost);
        
        system.assertEquals(null, resultWrapper.VendorOrderHeader.PercentRecieved);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyNeeded);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyReceived);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyUnreceived);
        system.assertEquals('On Order', resultWrapper.VendorOrderHeader.Status);
        system.assertEquals(0.0, resultWrapper.VendorOrderHeader.TotalReceived);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.VOLIGroups);
        system.assertEquals(voHeaderRec.Name, resultWrapper.VendorOrderHeader.VOName);
        system.assertEquals(voHeaderRec.Vendor__c, resultWrapper.VendorOrderHeader.VendorId);
        system.assertEquals(voHeaderRec.Vendor_Name__c, resultWrapper.VendorOrderHeader.VendorName);

        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].AvailablePart);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].CassonsId);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].CassonsSOH);
        system.assertEquals(voLineItemGroupRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].Id);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsBRPPart);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsExcess);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].IsOrderedAsIndividualItem);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsPackagedPart);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].ItemDesc);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].Need);
        system.assertEquals('Stock', resultWrapper.VendorOrderLineItemGroupList[0].NeededFor);
        system.assertEquals('', resultWrapper.VendorOrderLineItemGroupList[0].OrderType);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].OrderValue);
        system.assertEquals(partRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].PartId);
        system.assertEquals('test0', resultWrapper.VendorOrderLineItemGroupList[0].PartNumber);
        system.assertEquals(00, resultWrapper.VendorOrderLineItemGroupList[0].PercentRecieved);
        system.assertEquals(00, resultWrapper.VendorOrderLineItemGroupList[0].ReceivedQty);
        system.assertEquals('On Order', resultWrapper.VendorOrderLineItemGroupList[0].Status);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].SubletId);
        system.assertEquals(100, resultWrapper.VendorOrderLineItemGroupList[0].Total);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].UnitType);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].UnreceivedQty);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VOHeaderName);

        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].CoHeaderId);
        system.assertEquals(100.0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Cost);
        system.assertEquals('', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Customer);
        system.assertEquals(voLineItemRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Id);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Incoming);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsExcess);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsReceivingStockExcess);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsRequiredForCustomer);
        system.assertEquals(true, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsSearchAdded);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsService);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Item);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].ItemDesc);
        system.assertEquals('', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Location);

        system.assertEquals(100.0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].MSRP);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Need);
        system.assertEquals('Stock', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].NeededFor);
        system.assertEquals(partRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].PartId);
        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].QtyAvailable);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].ReceivedQty);
        system.assertEquals(100.0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Retail);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].SalePrice);
        system.assertEquals('On Order', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Status);
        system.assertEquals(100.0000, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Total);
        system.assertEquals(voHeaderRec.Name, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].VendorOrderHeaderName);
    }

    @Future
    static void assertDeleteVOLI(String voHeaderId) {
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String voLineItemDetail = VendorOrderCtrl.getVOLineItemWrapperJSON(null, BPUtility.getEncodedString(voHeaderId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, null, null);
        VendorOrderLineItemWrapper resultWrapper = (VendorOrderLineItemWrapper) System.JSON.deserializeStrict(BPUtility.getDecodedString(voLineItemDetail), VendorOrderLineItemWrapper.class);

        Part__c partRec = [SELECT Id FROM Part__c LIMIT 1];
        PO_Type__c poTypeRec = [SELECT Id FROM PO_Type__c LIMIT 1];
        Vendor_Order_Header__c voHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Order_Header__c LIMIT 1];
        Vendor_Order_Line_Item__c voLineItemRec = [SELECT Id, Name FROM Vendor_Order_Line_Item__c LIMIT 1];
        Vendor_Order_Line_Item_Group__c voLineItemGroupRec = [SELECT Id, Name FROM Vendor_Order_Line_Item_Group__c LIMIT 1];
        CO_Header__c coHeaderRec = [SELECT Id, Name FROM CO_Header__c LIMIT 1];

        system.assertEquals(500.00, resultWrapper.GroupTotalCost);
        system.assertEquals(null, resultWrapper.NewLineItemId);

        system.assertEquals(poTypeRec.Id, resultWrapper.OrderTypes[0].Id);
        system.assertEquals(true, resultWrapper.OrderTypes[0].IsDefault);
        system.assertEquals('STANDARD', resultWrapper.OrderTypes[0].Name);
        system.assertEquals(true, resultWrapper.OrderTypes[0].UpdateCurrentCost);

        system.assertEquals(1, resultWrapper.TotalLineItemGroups);
        system.assertEquals(0, resultWrapper.TotalReceivedCost);
        system.assertEquals(0, resultWrapper.TotalRequiredForCustomers);
        system.assertEquals(0, resultWrapper.TotalRequiredForStocks);
        system.assertEquals(500.00, resultWrapper.TotalUnreceivedCost);

        system.assertEquals(null, resultWrapper.VendorOrderHeader.BRPStatus);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.HondaDealerNumber);
        system.assertEquals(voHeaderRec.Id, resultWrapper.VendorOrderHeader.Id);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.InProgressVR);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.InProgressVRId);
        system.assertEquals(false, resultWrapper.VendorOrderHeader.IsVOAssociatedWithBRPVendor);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.Notes);
        system.assertEquals(poTypeRec.Id, resultWrapper.VendorOrderHeader.OrderType.Id);
        system.assertEquals('STANDARD', resultWrapper.VendorOrderHeader.OrderType.Name);
        system.assertEquals(true, resultWrapper.VendorOrderHeader.OrderType.UpdateCurrentCost);
        
        system.assertEquals(null, resultWrapper.VendorOrderHeader.PercentRecieved);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyNeeded);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyReceived);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyUnreceived);
        system.assertEquals('Open', resultWrapper.VendorOrderHeader.Status);
        system.assertEquals(0.0, resultWrapper.VendorOrderHeader.TotalReceived);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.VOLIGroups);
        system.assertEquals(voHeaderRec.Name, resultWrapper.VendorOrderHeader.VOName);
        system.assertEquals(voHeaderRec.Vendor__c, resultWrapper.VendorOrderHeader.VendorId);
        system.assertEquals(voHeaderRec.Vendor_Name__c, resultWrapper.VendorOrderHeader.VendorName);

        
        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].AvailablePart);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].CassonsId);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].CassonsSOH);
        system.assertEquals(100.00, resultWrapper.VendorOrderLineItemGroupList[0].Cost);
        system.assertEquals(voLineItemGroupRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].Id);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsBRPPart);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsExcess);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].IsOrderedAsIndividualItem);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsPackagedPart);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].ItemDesc);
        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].Need);
        system.assertEquals(coHeaderRec.Name, resultWrapper.VendorOrderLineItemGroupList[0].NeededFor);
        system.assertEquals('', resultWrapper.VendorOrderLineItemGroupList[0].OrderType);
        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].OrderValue);
        system.assertEquals(partRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].PartId);
        system.assertEquals('test0', resultWrapper.VendorOrderLineItemGroupList[0].PartNumber);
        system.assertEquals(00, resultWrapper.VendorOrderLineItemGroupList[0].PercentRecieved);
        system.assertEquals(00, resultWrapper.VendorOrderLineItemGroupList[0].ReceivedQty);
        system.assertEquals('On Order', resultWrapper.VendorOrderLineItemGroupList[0].Status);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].SubletId);
        system.assertEquals(500, resultWrapper.VendorOrderLineItemGroupList[0].Total);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].UnitType);
        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].UnreceivedQty);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VOHeaderName);

        system.assertEquals(coHeaderRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].CoHeaderId);
        system.assertEquals(100.0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Cost);
        system.assertEquals('test0', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Customer);
        system.assertEquals(voLineItemRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Id);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Incoming);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsExcess);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsReceivingStockExcess);
        system.assertEquals(true, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsRequiredForCustomer);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsSearchAdded);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsService);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Item);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].ItemDesc);
        system.assertEquals('', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Location);

        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].MSRP);
        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Need);
        system.assertEquals('Merch ' + coHeaderRec.Name, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].NeededFor);
        system.assertEquals(partRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].PartId);
        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].QtyAvailable);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].ReceivedQty);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Retail);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].SalePrice);
        system.assertEquals('On Order', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Status);
        system.assertEquals(500.00, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Total);
        system.assertEquals(voHeaderRec.Name, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].VendorOrderHeaderName);
    }

    static void assertCreateVendorOrder(String voHeaderId) {
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String voLineItemDetail = VendorOrderCtrl.getVOLineItemWrapperJSON(null, BPUtility.getEncodedString(voHeaderId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, null, null);
        VendorOrderLineItemWrapper resultWrapper = (VendorOrderLineItemWrapper) System.JSON.deserializeStrict(BPUtility.getDecodedString(voLineItemDetail), VendorOrderLineItemWrapper.class);

        Part__c partRec = [SELECT Id FROM Part__c LIMIT 1];
        PO_Type__c poTypeRec = [SELECT Id FROM PO_Type__c LIMIT 1];
        Vendor_Order_Header__c voHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Order_Header__c LIMIT 1];
        
        system.assertEquals(0, resultWrapper.GroupTotalCost);
        system.assertEquals(null, resultWrapper.NewLineItemId);

        system.assertEquals(poTypeRec.Id, resultWrapper.OrderTypes[0].Id);
        system.assertEquals(true, resultWrapper.OrderTypes[0].IsDefault);
        system.assertEquals('STANDARD', resultWrapper.OrderTypes[0].Name);
        system.assertEquals(true, resultWrapper.OrderTypes[0].UpdateCurrentCost);

        system.assertEquals(0, resultWrapper.TotalLineItemGroups);
        system.assertEquals(0, resultWrapper.TotalReceivedCost);
        system.assertEquals(0, resultWrapper.TotalRequiredForCustomers);
        system.assertEquals(0, resultWrapper.TotalRequiredForStocks);
        system.assertEquals(0, resultWrapper.TotalUnreceivedCost);

        system.assertEquals(null, resultWrapper.VendorOrderHeader.BRPStatus);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.HondaDealerNumber);
        system.assertEquals(voHeaderRec.Id, resultWrapper.VendorOrderHeader.Id);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.InProgressVR);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.InProgressVRId);
        system.assertEquals(false, resultWrapper.VendorOrderHeader.IsVOAssociatedWithBRPVendor);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.Notes);
        system.assertEquals(poTypeRec.Id, resultWrapper.VendorOrderHeader.OrderType.Id);
        system.assertEquals('STANDARD', resultWrapper.VendorOrderHeader.OrderType.Name);
        system.assertEquals(true, resultWrapper.VendorOrderHeader.OrderType.UpdateCurrentCost);
        
        system.assertEquals(null, resultWrapper.VendorOrderHeader.PercentRecieved);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyNeeded);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyReceived);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyUnreceived);
        system.assertEquals('Open', resultWrapper.VendorOrderHeader.Status);
        system.assertEquals(0.0, resultWrapper.VendorOrderHeader.TotalReceived);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.VOLIGroups);
        system.assertEquals(voHeaderRec.Name, resultWrapper.VendorOrderHeader.VOName);
        system.assertEquals(voHeaderRec.Vendor__c, resultWrapper.VendorOrderHeader.VendorId);
        system.assertEquals(voHeaderRec.Vendor_Name__c, resultWrapper.VendorOrderHeader.VendorName);

        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList.size());
    }

    static void assertAddVOLineItem(VendorOrderLineItemWrapper resultWrapper) {
        Part__c partRec = [SELECT Id FROM Part__c LIMIT 1];
        PO_Type__c poTypeRec = [SELECT Id FROM PO_Type__c LIMIT 1];
        Vendor_Order_Header__c voHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Order_Header__c LIMIT 1];
        Vendor_Order_Line_Item__c voLineItemRec = [SELECT Id, Name FROM Vendor_Order_Line_Item__c LIMIT 1];
        Vendor_Order_Line_Item_Group__c voLineItemGroupRec = [SELECT Id, Name FROM Vendor_Order_Line_Item_Group__c LIMIT 1];
        
        system.assertEquals(100.0000, resultWrapper.GroupTotalCost);
        system.assertEquals(null, resultWrapper.NewLineItemId);

        system.assertEquals(poTypeRec.Id, resultWrapper.OrderTypes[0].Id);
        system.assertEquals(true, resultWrapper.OrderTypes[0].IsDefault);
        system.assertEquals('STANDARD', resultWrapper.OrderTypes[0].Name);
        system.assertEquals(true, resultWrapper.OrderTypes[0].UpdateCurrentCost);

        system.assertEquals(1, resultWrapper.TotalLineItemGroups);
        system.assertEquals(0, resultWrapper.TotalReceivedCost);
        system.assertEquals(0, resultWrapper.TotalRequiredForCustomers);
        system.assertEquals(0, resultWrapper.TotalRequiredForStocks);
        system.assertEquals(100.00, resultWrapper.TotalUnreceivedCost);

        system.assertEquals(null, resultWrapper.VendorOrderHeader.BRPStatus);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.HondaDealerNumber);
        system.assertEquals(voHeaderRec.Id, resultWrapper.VendorOrderHeader.Id);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.InProgressVR);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.InProgressVRId);
        system.assertEquals(false, resultWrapper.VendorOrderHeader.IsVOAssociatedWithBRPVendor);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.Notes);
        system.assertEquals(poTypeRec.Id, resultWrapper.VendorOrderHeader.OrderType.Id);
        system.assertEquals('STANDARD', resultWrapper.VendorOrderHeader.OrderType.Name);
        system.assertEquals(true, resultWrapper.VendorOrderHeader.OrderType.UpdateCurrentCost);
        
        system.assertEquals(null, resultWrapper.VendorOrderHeader.PercentRecieved);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyNeeded);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyReceived);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.QtyUnreceived);
        system.assertEquals('Open', resultWrapper.VendorOrderHeader.Status);
        system.assertEquals(0.0, resultWrapper.VendorOrderHeader.TotalReceived);
        system.assertEquals(null, resultWrapper.VendorOrderHeader.VOLIGroups);
        system.assertEquals(voHeaderRec.Name, resultWrapper.VendorOrderHeader.VOName);
        system.assertEquals(voHeaderRec.Vendor__c, resultWrapper.VendorOrderHeader.VendorId);
        system.assertEquals(voHeaderRec.Vendor_Name__c, resultWrapper.VendorOrderHeader.VendorName);

        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].AvailablePart);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].CassonsId);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].CassonsSOH);
        system.assertEquals(voLineItemGroupRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].Id);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsBRPPart);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsExcess);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].IsOrderedAsIndividualItem);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].IsPackagedPart);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].ItemDesc);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].Need);
        system.assertEquals('Stock', resultWrapper.VendorOrderLineItemGroupList[0].NeededFor);
        system.assertEquals('', resultWrapper.VendorOrderLineItemGroupList[0].OrderType);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].OrderValue);
        system.assertEquals(partRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].PartId);
        system.assertEquals('test0', resultWrapper.VendorOrderLineItemGroupList[0].PartNumber);
        system.assertEquals(00, resultWrapper.VendorOrderLineItemGroupList[0].PercentRecieved);
        system.assertEquals(00, resultWrapper.VendorOrderLineItemGroupList[0].ReceivedQty);
        system.assertEquals('On Order', resultWrapper.VendorOrderLineItemGroupList[0].Status);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].SubletId);
        system.assertEquals(100, resultWrapper.VendorOrderLineItemGroupList[0].Total);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].UnitType);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].UnreceivedQty);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VOHeaderName);

        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].CoHeaderId);
        system.assertEquals(100.0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Cost);
        system.assertEquals('', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Customer);
        system.assertEquals(voLineItemRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Id);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Incoming);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsExcess);
        system.assertEquals(null, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsReceivingStockExcess);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsRequiredForCustomer);
        system.assertEquals(true, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsSearchAdded);
        system.assertEquals(false, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].IsService);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Item);
        system.assertEquals('test0 - test0', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].ItemDesc);
        system.assertEquals('', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Location);

        system.assertEquals(100.0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].MSRP);
        system.assertEquals(1, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Need);
        system.assertEquals('Stock', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].NeededFor);
        system.assertEquals(partRec.Id, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].PartId);
        system.assertEquals(5, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].QtyAvailable);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].ReceivedQty);
        system.assertEquals(100.0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Retail);
        system.assertEquals(0, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].SalePrice);
        system.assertEquals('On Order', resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Status);
        system.assertEquals(100.0000, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].Total);
        system.assertEquals(voHeaderRec.Name, resultWrapper.VendorOrderLineItemGroupList[0].VendorOrderLineItemList[0].VendorOrderHeaderName);
    }   
}