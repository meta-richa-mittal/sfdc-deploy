@IsTest
public class VR_VendorReceivingTest {
    
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
    static void activeVRCountTest() {
        makeTestData();

        Test.startTest();
            Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
            Vendor_Receiving_Header__c vr1 = new Vendor_Receiving_Header__c(Vendor__c = vendorId, Status__c = 'In Progress');
            Vendor_Receiving_Header__c vr2 = new Vendor_Receiving_Header__c(Vendor__c = vendorId, Status__c = 'In Progress');
            Vendor_Receiving_Header__c vr3 = new Vendor_Receiving_Header__c(Vendor__c = vendorId, Status__c = 'Stocked');
            insert new List<Vendor_Receiving_Header__c> {vr1, vr2, vr3};

            String activeVRCount = BPUtility.getDecodedString(VendorOrderReceivingCtrl.getActiveVRCountByVendorId(BPUtility.getEncodedString(vendorId)));
        Test.stopTest();
            
        System.assertEquals('2', activeVRCount, 'Incorrect active VR count for vendorId ' + vendorId);
    }


    @IsTest
    static void createVendorReceivingTest() {
        makeTestData();
    
        Test.startTest();
            Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
            String vrHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorReceiving(BPUtility.getEncodedString(vendorId)));
        Test.stopTest();

        assertCreateVendorReceiving(vrHeaderId);
    }

    static void assertCreateVendorReceiving(String vrHeaderId) {
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        String vorDetails = VendorOrderReceivingCtrl.getVORDetails(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(null), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);  
        VendorOrderReceivingCtrl.VendorOrderReceiving vendorReceivingItems = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(BPUtility.getDecodedString(vorDetails), VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        Vendor_Receiving_Header__c vrHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Receiving_Header__c LIMIT 1];

        system.assertEquals(0, vendorReceivingItems.GroupTotalCost);
        system.assertEquals(0, vendorReceivingItems.TotalReceivedLineItem);
        system.assertEquals(0, vendorReceivingItems.TotalReceivedQty);
        system.assertEquals(true, vendorReceivingItems.isAllVOSelected);
        system.assertEquals(false, vendorReceivingItems.isFoundPartInOtherVOHeader);
        system.assertEquals(0, vendorReceivingItems.totalGroupItems);
        system.assertEquals(0, vendorReceivingItems.totalOutstandingItems);
        system.assertEquals(0, vendorReceivingItems.totalVendorOrders);
        system.assertEquals(0, vendorReceivingItems.vendorOrdersList.size());

        system.assertEquals(null, vendorReceivingItems.VOR_Header.FXCurrencyDetails);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsCalculatePartRetailPriceFlag);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsForeignVendor);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsReceivingFromInvoice);
        system.assertEquals(null, vendorReceivingItems.VOR_Header.PackagingSlipNumber);
        system.assertEquals(null, vendorReceivingItems.VOR_Header.ReceivingFromInvoiceTotal);
        system.assertEquals(null, vendorReceivingItems.VOR_Header.ReceivingTotal);
        system.assertEquals('MSRP', vendorReceivingItems.VOR_Header.RetailBaseValue);
        system.assertEquals(0, vendorReceivingItems.VOR_Header.RetailRate);
        system.assertEquals(95, vendorReceivingItems.VOR_Header.RetailRoundTo);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.RetailRounding);
        system.assertEquals('In Progress', vendorReceivingItems.VOR_Header.Status);
        system.assertEquals(0, vendorReceivingItems.VOR_Header.TotalLineItem);
        system.assertEquals(0, vendorReceivingItems.VOR_Header.TotalReceivedQty);
        system.assertEquals(vrHeaderRec.Id, vendorReceivingItems.VOR_Header.VORId);
        system.assertEquals(vrHeaderRec.Name, vendorReceivingItems.VOR_Header.VORName);
        system.assertEquals(vrHeaderRec.Vendor__c, vendorReceivingItems.VOR_Header.VendorId);
        system.assertEquals(vrHeaderRec.Vendor_Name__c, vendorReceivingItems.VOR_Header.VendorName);
    }

    @IsTest
    static void deleteVendorOrderReceivingTest() {
        makeTestData();

        Test.startTest();
            Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
            String vrHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorReceiving(BPUtility.getEncodedString(vendorId)));
            VendorOrderReceivingCtrl.deleteVendorOrderRecieving(BPUtility.getEncodedString(vrHeaderId));
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM Vendor_Receiving_Header__c].size());
    }

    @IsTest
    static void addVOLIToVRTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            TestDataFactory_V2.resetAllStaticVariables();
            String lineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), 1, itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, BPUtility.getEncodedString(null), true));        
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vendorId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
            
            TestDataFactory_V2.resetAllStaticVariables();
            String vrHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorReceiving(BPUtility.getEncodedString(vendorId)));
            update new Vendor_Receiving_Header__c(Id = vrHeaderId, Packing_Slip_Number__c = 'TestPackageSlip');

            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vrHeaderId), true);
            TestDataFactory_V2.resetAllStaticVariables();
            String voliGroupItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.getAllVOLIGroupItem(BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(vrHeaderId)));
            List<VROutstandingLineItemWrapper.SelectedRecordWrapper> voliGroupItemObjList = (List<VROutstandingLineItemWrapper.SelectedRecordWrapper>)System.JSON.deserialize(voliGroupItems, List<VROutstandingLineItemWrapper.SelectedRecordWrapper>.class);
            List<Id> lineitemlist = new List<Id>();
            for(VROutstandingLineItemWrapper.SelectedRecordWrapper selectedRecObj: voliGroupItemObjList) {
                lineitemlist.add(selectedRecObj.Id);
            }
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.groupSelectedLineItems(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(System.JSON.serialize(lineitemlist)), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
        Test.stopTest();        

        assertAddVOLIsToVR(vrHeaderId);
    }

    @IsTest
    static void commitVRTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            TestDataFactory_V2.resetAllStaticVariables();
            String lineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), 1, itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, BPUtility.getEncodedString(null), true));        
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vendorId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
            
            TestDataFactory_V2.resetAllStaticVariables();
            String vrHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorReceiving(BPUtility.getEncodedString(vendorId)));
            update new Vendor_Receiving_Header__c(Id = vrHeaderId, Packing_Slip_Number__c = 'TestPackageSlip');

            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vrHeaderId), true);
            TestDataFactory_V2.resetAllStaticVariables();
            String voliGroupItems = BPUtility.getDecodedString(VendorOrderReceivingCtrl.getAllVOLIGroupItem(BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(vrHeaderId)));
            List<VROutstandingLineItemWrapper.SelectedRecordWrapper> voliGroupItemObjList = (List<VROutstandingLineItemWrapper.SelectedRecordWrapper>)System.JSON.deserialize(voliGroupItems, List<VROutstandingLineItemWrapper.SelectedRecordWrapper>.class);
            List<Id> lineitemlist = new List<Id>();
            for(VROutstandingLineItemWrapper.SelectedRecordWrapper selectedRecObj: voliGroupItemObjList) {
                lineitemlist.add(selectedRecObj.Id);
            }
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.groupSelectedLineItems(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(System.JSON.serialize(lineitemlist)), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.commitRecevingAction(BPUtility.getEncodedString(vrHeaderId));
        Test.stopTest();        

        assertCommitVR(vrHeaderId);
    }

    @Future
    static void assertCommitVR(String vrHeaderId) {
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        String vorDetail = VendorOrderReceivingCtrl.getVORDetails(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(null), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);  
        VendorOrderReceivingCtrl.VendorOrderReceiving vendorReceivingItems = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(BPUtility.getDecodedString(vorDetail), VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        Vendor_Receiving_Header__c vrHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Receiving_Header__c LIMIT 1];
        Vendor_Order_Header__c voHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Order_Header__c LIMIT 1];
        Part__c partRec = [SELECT Id FROM Part__c LIMIT 1];
        PO_Type__c poTypeRec = [SELECT Id FROM PO_Type__c LIMIT 1];
        Vendor_Order_Line_Item__c voLineItemRec = [SELECT Id, Name FROM Vendor_Order_Line_Item__c LIMIT 1];
        Vendor_Order_Line_Item_Group__c voLineItemGroupRec = [SELECT Id, Name FROM Vendor_Order_Line_Item_Group__c LIMIT 1];
        Vendor_Receiving_Group__c vrGroupRec = [SELECT Id, Name FROM Vendor_Receiving_Group__c LIMIT 1];
        In_Progress_VR__c inPorgressVRRec = [SELECT Id, Name FROM In_Progress_VR__c LIMIT 1];

        system.assertEquals(100, vendorReceivingItems.GroupTotalCost);
        system.assertEquals(1, vendorReceivingItems.TotalReceivedLineItem);
        system.assertEquals(1, vendorReceivingItems.TotalReceivedQty);
        system.assertEquals(true, vendorReceivingItems.isAllVOSelected);
        system.assertEquals(false, vendorReceivingItems.isFoundPartInOtherVOHeader);
        system.assertEquals(1, vendorReceivingItems.totalGroupItems);
        system.assertEquals(0, vendorReceivingItems.totalOutstandingItems);
        system.assertEquals(0, vendorReceivingItems.totalVendorOrders);
        system.assertEquals(0, vendorReceivingItems.vendorOrdersList.size());

        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].Cost);
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].Discount);
        system.assertEquals(vrGroupRec.Id, vendorReceivingItems.VORGroupList[0].Id);
        system.assertEquals(false, vendorReceivingItems.VORGroupList[0].IsExcess);
        system.assertEquals('test0 - test0', vendorReceivingItems.VORGroupList[0].ItemDesc);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].Need);
        system.assertEquals('Stock', vendorReceivingItems.VORGroupList[0].NeededFor);
        system.assertEquals('', vendorReceivingItems.VORGroupList[0].OrderType);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].OrderValue);
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].OtherVOHeaderNameList.size());
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].PackageQty);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].PartCost);
        system.assertEquals(partRec.Id, vendorReceivingItems.VORGroupList[0].PartId);
        system.assertEquals('test0', vendorReceivingItems.VORGroupList[0].PartNumber);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].ReceivedQty);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].SubletId);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].Total);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].UnitType);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].CoHeaderId);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Cost);
        system.assertEquals('', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Customer);
        system.assertEquals(voLineItemRec.Id, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Id);
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Incoming);
        system.assertEquals(false, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsExcess);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsReceivingStockExcess);
        system.assertEquals(false, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsRequiredForCustomer);
        system.assertEquals(true, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsSearchAdded);
        system.assertEquals(false, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsService);
        system.assertEquals('test0 - test0', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Item);
        system.assertEquals('test0 - test0', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].ItemDesc);
        system.assertEquals('', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Location);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].MSRP);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Need);
        system.assertEquals('Stock', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].NeededFor);
        system.assertEquals(partRec.Id, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].PartId);
        system.assertEquals(6, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].QtyAvailable);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].ReceivedQty);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Retail);
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].SalePrice);
        system.assertEquals('Stocked', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Status);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].SubletId);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Total);
        system.assertEquals(voHeaderRec.name, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].VendorOrderHeaderName);

        system.assertEquals(null, vendorReceivingItems.VOR_Header.FXCurrencyDetails);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsCalculatePartRetailPriceFlag);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsForeignVendor);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsReceivingFromInvoice);
        system.assertEquals('TestPackageSlip', vendorReceivingItems.VOR_Header.PackagingSlipNumber);
        system.assertEquals(null, vendorReceivingItems.VOR_Header.ReceivingFromInvoiceTotal);
        system.assertEquals(100, vendorReceivingItems.VOR_Header.ReceivingTotal);
        system.assertEquals('MSRP', vendorReceivingItems.VOR_Header.RetailBaseValue);
        system.assertEquals(0, vendorReceivingItems.VOR_Header.RetailRate);
        system.assertEquals(95, vendorReceivingItems.VOR_Header.RetailRoundTo);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.RetailRounding);
        system.assertEquals('Stocked', vendorReceivingItems.VOR_Header.Status);
        system.assertEquals(1, vendorReceivingItems.VOR_Header.TotalLineItem);
        system.assertEquals(1, vendorReceivingItems.VOR_Header.TotalReceivedQty);
        system.assertEquals(vrHeaderRec.Id, vendorReceivingItems.VOR_Header.VORId);
        system.assertEquals(vrHeaderRec.Name, vendorReceivingItems.VOR_Header.VORName);
        system.assertEquals(vrHeaderRec.Vendor__c, vendorReceivingItems.VOR_Header.VendorId);
        system.assertEquals(vrHeaderRec.Vendor_Name__c, vendorReceivingItems.VOR_Header.VendorName);
    }

    @Future
    static void assertAddVOLIsToVR(String vrHeaderId) {
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        String vorDetail = VendorOrderReceivingCtrl.getVORDetails(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(null), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);  
        VendorOrderReceivingCtrl.VendorOrderReceiving vendorReceivingItems = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(BPUtility.getDecodedString(vorDetail), VendorOrderReceivingCtrl.VendorOrderReceiving.class);
        Vendor_Receiving_Header__c vrHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Receiving_Header__c LIMIT 1];
        Vendor_Order_Header__c voHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Vendor_Order_Header__c LIMIT 1];
        Part__c partRec = [SELECT Id FROM Part__c LIMIT 1];
        PO_Type__c poTypeRec = [SELECT Id FROM PO_Type__c LIMIT 1];
        Vendor_Order_Line_Item__c voLineItemRec = [SELECT Id, Name FROM Vendor_Order_Line_Item__c LIMIT 1];
        Vendor_Order_Line_Item_Group__c voLineItemGroupRec = [SELECT Id, Name FROM Vendor_Order_Line_Item_Group__c LIMIT 1];
        Vendor_Receiving_Group__c vrGroupRec = [SELECT Id, Name FROM Vendor_Receiving_Group__c LIMIT 1];

        system.assertEquals(100, vendorReceivingItems.GroupTotalCost);
        system.assertEquals(1, vendorReceivingItems.TotalReceivedLineItem);
        system.assertEquals(1, vendorReceivingItems.TotalReceivedQty);
        system.assertEquals(true, vendorReceivingItems.isAllVOSelected);
        system.assertEquals(false, vendorReceivingItems.isFoundPartInOtherVOHeader);
        system.assertEquals(1, vendorReceivingItems.totalGroupItems);
        system.assertEquals(0, vendorReceivingItems.totalOutstandingItems);
        system.assertEquals(1, vendorReceivingItems.totalVendorOrders);
        system.assertEquals(1, vendorReceivingItems.vendorOrdersList.size());

        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].Cost);
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].Discount);
        system.assertEquals(vrGroupRec.Id, vendorReceivingItems.VORGroupList[0].Id);
        system.assertEquals(false, vendorReceivingItems.VORGroupList[0].IsExcess);
        system.assertEquals('test0 - test0', vendorReceivingItems.VORGroupList[0].ItemDesc);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].Need);
        system.assertEquals('Stock', vendorReceivingItems.VORGroupList[0].NeededFor);
        system.assertEquals('', vendorReceivingItems.VORGroupList[0].OrderType);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].OrderValue);
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].OtherVOHeaderNameList.size());
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].PackageQty);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].PartCost);
        system.assertEquals(partRec.Id, vendorReceivingItems.VORGroupList[0].PartId);
        system.assertEquals('test0', vendorReceivingItems.VORGroupList[0].PartNumber);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].ReceivedQty);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].SubletId);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].Total);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].UnitType);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].CoHeaderId);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Cost);
        system.assertEquals('', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Customer);
        system.assertEquals(voLineItemRec.Id, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Id);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Incoming);
        system.assertEquals(false, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsExcess);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsReceivingStockExcess);
        system.assertEquals(false, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsRequiredForCustomer);
        system.assertEquals(true, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsSearchAdded);
        system.assertEquals(false, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].IsService);
        system.assertEquals('test0 - test0', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Item);
        system.assertEquals('test0 - test0', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].ItemDesc);
        system.assertEquals('', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Location);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].MSRP);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Need);
        system.assertEquals('Stock', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].NeededFor);
        system.assertEquals(partRec.Id, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].PartId);
        system.assertEquals(5, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].QtyAvailable);
        system.assertEquals(1, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].ReceivedQty);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Retail);
        system.assertEquals(0, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].SalePrice);
        system.assertEquals('In Receiving', vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Status);
        system.assertEquals(null, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].SubletId);
        system.assertEquals(100, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].Total);
        system.assertEquals(voHeaderRec.name, vendorReceivingItems.VORGroupList[0].VendorOrderLineItemList[0].VendorOrderHeaderName);

        system.assertEquals(null, vendorReceivingItems.VOR_Header.FXCurrencyDetails);
        system.assertEquals('', vendorReceivingItems.VOR_Header.FinalizedDate);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsCalculatePartRetailPriceFlag);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsForeignVendor);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.IsReceivingFromInvoice);
        system.assertEquals('TestPackageSlip', vendorReceivingItems.VOR_Header.PackagingSlipNumber);
        system.assertEquals(null, vendorReceivingItems.VOR_Header.ReceivingFromInvoiceTotal);
        system.assertEquals(100, vendorReceivingItems.VOR_Header.ReceivingTotal);
        system.assertEquals('MSRP', vendorReceivingItems.VOR_Header.RetailBaseValue);
        system.assertEquals(0, vendorReceivingItems.VOR_Header.RetailRate);
        system.assertEquals(95, vendorReceivingItems.VOR_Header.RetailRoundTo);
        system.assertEquals(false, vendorReceivingItems.VOR_Header.RetailRounding);
        system.assertEquals('In Progress', vendorReceivingItems.VOR_Header.Status);
        system.assertEquals(1, vendorReceivingItems.VOR_Header.TotalLineItem);
        system.assertEquals(1, vendorReceivingItems.VOR_Header.TotalReceivedQty);
        system.assertEquals(vrHeaderRec.Id, vendorReceivingItems.VOR_Header.VORId);
        system.assertEquals(vrHeaderRec.Name, vendorReceivingItems.VOR_Header.VORName);
        system.assertEquals(vrHeaderRec.Vendor__c, vendorReceivingItems.VOR_Header.VendorId);
        system.assertEquals(vrHeaderRec.Vendor_Name__c, vendorReceivingItems.VOR_Header.VendorName);

        system.assertEquals(null, vendorReceivingItems.vendorOrdersList[0].BRPStatus);
        system.assertEquals(null, vendorReceivingItems.vendorOrdersList[0].HondaDealerNumber);
        system.assertEquals(voHeaderRec.Id, vendorReceivingItems.vendorOrdersList[0].Id);
        system.assertEquals(vrHeaderRec.Name, vendorReceivingItems.vendorOrdersList[0].InProgressVR);
        system.assertEquals(vrHeaderRec.Id, vendorReceivingItems.vendorOrdersList[0].InProgressVRId);
        system.assertEquals(null, vendorReceivingItems.vendorOrdersList[0].IsVOAssociatedWithBRPVendor);
        system.assertEquals(null, vendorReceivingItems.vendorOrdersList[0].PercentRecieved);
        system.assertEquals(null, vendorReceivingItems.vendorOrdersList[0].QtyNeeded);
        system.assertEquals(null, vendorReceivingItems.vendorOrdersList[0].QtyReceived);
        system.assertEquals(null, vendorReceivingItems.vendorOrdersList[0].QtyUnreceived);
        system.assertEquals('On Order', vendorReceivingItems.vendorOrdersList[0].Status);
        system.assertEquals(0.0, vendorReceivingItems.vendorOrdersList[0].TotalReceived);
        system.assertEquals(null, vendorReceivingItems.vendorOrdersList[0].VOLIGroups);
        system.assertEquals(voHeaderRec.Name, vendorReceivingItems.vendorOrdersList[0].VOName);
        system.assertEquals(vrHeaderRec.Vendor__c, vendorReceivingItems.vendorOrdersList[0].VendorId);
        system.assertEquals(vrHeaderRec.Vendor_Name__c, vendorReceivingItems.vendorOrdersList[0].VendorName);
        system.assertEquals(poTypeRec.Id, vendorReceivingItems.vendorOrdersList[0].OrderType.Id);
        system.assertEquals('STANDARD', vendorReceivingItems.vendorOrdersList[0].OrderType.Name);
        system.assertEquals(true, vendorReceivingItems.vendorOrdersList[0].OrderType.UpdateCurrentCost);
    }

    @IsTest
    static void removeVOLIFromVRTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            TestDataFactory_V2.resetAllStaticVariables();
            String lineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), 1, itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, BPUtility.getEncodedString(null), true));        
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vendorId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
            
            TestDataFactory_V2.resetAllStaticVariables();
            String vrHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorReceiving(BPUtility.getEncodedString(vendorId)));
            update new Vendor_Receiving_Header__c(Id = vrHeaderId, Packing_Slip_Number__c = 'TestPackageSlip');

            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vrHeaderId), true);
            String lineitemJson = BPUtility.getDecodedString(VendorOrderReceivingCtrl.getAllVOLIGroupItem(BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(vrHeaderId)));
            List<VROutstandingLineItemWrapper.SelectedRecordWrapper> lineitemObjList = (List<VROutstandingLineItemWrapper.SelectedRecordWrapper>)System.JSON.deserialize(lineitemJson, List<VROutstandingLineItemWrapper.SelectedRecordWrapper>.class);
            List<Id> lineitemlist = new List<Id>();
            for(VROutstandingLineItemWrapper.SelectedRecordWrapper selectedRecObj: lineitemObjList) {
                lineitemlist.add(selectedRecObj.Id);
            }
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.groupSelectedLineItems(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(System.JSON.serialize(lineitemlist)), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
            TestDataFactory_V2.resetAllStaticVariables();
            Vendor_Receiving_Group__c vrGroupRec = [SELECT Id FROM Vendor_Receiving_Group__c LIMIT 1];
            VendorOrderReceivingCtrl.removeItem(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(vrGroupRec.Id), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);

        Test.stopTest();        

        assertRemoveVOLIFromVR(vrHeaderId);
    }

    @Future
    static void assertRemoveVOLIFromVR(String vrHeaderId) {
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        String vorDetail = VendorOrderReceivingCtrl.getVORDetails(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(null), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);  
        VendorOrderReceivingCtrl.VendorOrderReceiving vendorReceivingItems = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(BPUtility.getDecodedString(vorDetail), VendorOrderReceivingCtrl.VendorOrderReceiving.class);

        system.assertEquals(0, vendorReceivingItems.GroupTotalCost);
        system.assertEquals(0, vendorReceivingItems.TotalReceivedLineItem);
        system.assertEquals(0, vendorReceivingItems.TotalReceivedQty);
        system.assertEquals(true, vendorReceivingItems.isAllVOSelected);
        system.assertEquals(false, vendorReceivingItems.isFoundPartInOtherVOHeader);
        system.assertEquals(0, vendorReceivingItems.totalGroupItems);
        system.assertEquals(1, vendorReceivingItems.totalOutstandingItems);
        system.assertEquals(1, vendorReceivingItems.totalVendorOrders);
        system.assertEquals(0, vendorReceivingItems.VORGroupList.size());
    }

    @IsTest
    static void updateVOLIFromVRTest() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String voHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorOrder(BPUtility.getEncodedString(vendorId)));
            TestDataFactory_V2.resetAllStaticVariables();
            String lineItemFromAddToSearch = BPUtility.getDecodedString(VendorOrderCtrl.addVOLineItemFromSearchToAdd(BPUtility.getEncodedString(partId), BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(voHeaderId), 1, itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON, BPUtility.getEncodedString(null), true));        
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderCtrl.finalizeVendorOrder(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vendorId), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
            
            TestDataFactory_V2.resetAllStaticVariables();
            String vrHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorReceiving(BPUtility.getEncodedString(vendorId)));
            update new Vendor_Receiving_Header__c(Id = vrHeaderId, Packing_Slip_Number__c = 'TestPackageSlip');

            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.receiveVendorOrderItems(BPUtility.getEncodedString(voHeaderId), BPUtility.getEncodedString(vrHeaderId), true);
            String lineitemJson = BPUtility.getDecodedString(VendorOrderReceivingCtrl.getAllVOLIGroupItem(BPUtility.getEncodedString(vendorId), BPUtility.getEncodedString(vrHeaderId)));
            List<VROutstandingLineItemWrapper.SelectedRecordWrapper> lineitemObjList = (List<VROutstandingLineItemWrapper.SelectedRecordWrapper>)System.JSON.deserialize(lineitemJson, List<VROutstandingLineItemWrapper.SelectedRecordWrapper>.class);
            List<Id> lineitemlist = new List<Id>();
            for(VROutstandingLineItemWrapper.SelectedRecordWrapper selectedRecObj: lineitemObjList) {
                lineitemlist.add(selectedRecObj.Id);
            }
            TestDataFactory_V2.resetAllStaticVariables();
            VendorOrderReceivingCtrl.groupSelectedLineItems(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(System.JSON.serialize(lineitemlist)), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);
            TestDataFactory_V2.resetAllStaticVariables();
            Vendor_Receiving_Group__c vrGroupRec = [SELECT Id FROM Vendor_Receiving_Group__c LIMIT 1];
            String jsonString = '{"Id":"'+ vrGroupRec.Id +'", "Cost":100, "ReceivedQty":"3", "Discount":0}';
            VendorOrderReceivingCtrl.updateVendorReceivingGroup(BPUtility.getEncodedString(jsonString));

        Test.stopTest();        

        assertUpdateVOLIFromVR(vrHeaderId);
    }

    static void assertUpdateVOLIFromVR(String vrHeaderId) {
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        String vorDetail = VendorOrderReceivingCtrl.getVORDetails(BPUtility.getEncodedString(vrHeaderId), BPUtility.getEncodedString(null), BPUtility.getEncodedString(null), itemsPageSortAttrsJSON, customersPageSortAttrsJSON, stocksPageSortAttrsJSON);  
        VendorOrderReceivingCtrl.VendorOrderReceiving vendorReceivingItems = (VendorOrderReceivingCtrl.VendorOrderReceiving)System.JSON.deserialize(BPUtility.getDecodedString(vorDetail), VendorOrderReceivingCtrl.VendorOrderReceiving.class);

        system.assertEquals(300, vendorReceivingItems.GroupTotalCost);
        system.assertEquals(1, vendorReceivingItems.TotalReceivedLineItem);
        system.assertEquals(3, vendorReceivingItems.TotalReceivedQty);
        system.assertEquals(true, vendorReceivingItems.isAllVOSelected);
        system.assertEquals(false, vendorReceivingItems.isFoundPartInOtherVOHeader);
        system.assertEquals(1, vendorReceivingItems.totalGroupItems);
        system.assertEquals(0, vendorReceivingItems.totalOutstandingItems);
        system.assertEquals(1, vendorReceivingItems.totalVendorOrders);
        system.assertEquals(1, vendorReceivingItems.VORGroupList.size());
    }
}