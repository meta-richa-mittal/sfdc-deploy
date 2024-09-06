@IsTest
public class VI_VendorInvoiceTest {
    
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
        List<Fee__c> feeList = TestDataFactory_V2.createTestDataForFee(salesTaxList, categoryList, false);
        feeList[0].Type__c = 'Purchasing';
        insert feeList;

    }

    @IsTest
    static void createNewVendorInvoicingTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        
        Test.startTest();
            String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
        Test.stopTest();

        assertCreateNewVendorInvoicingTest(viHeaderId);
    }

    static void assertCreateNewVendorInvoicingTest(String viHeaderId) {
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        Vendor_Invoicing_Header__c viHeaderRec = [SELECT Id, Name, Vendor__c, Vendor__r.Name FROM Vendor_Invoicing_Header__c LIMIT 1];
  
        String vendorInvoicingDetails = VendorInvoicingCtrl.getVendorInvoicingDetails(BPUtility.getEncodedString(viHeaderId), null, receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);
        system.assertEquals(0.0, vendorInvoicingDetailObj.ItemsTotal);
        system.assertEquals(0.0, vendorInvoicingDetailObj.Taxes);
        system.assertEquals(0.0, vendorInvoicingDetailObj.Total);
        system.assertEquals(0.0, vendorInvoicingDetailObj.TotalOtherCharges);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalGroupItems);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalOtherChargesRec);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalVendorOrderInvoicing);
        system.assertEquals(0, vendorInvoicingDetailObj.OtherChargesList.size());
        system.assertEquals(0, vendorInvoicingDetailObj.VIGroupList.size());
        system.assertEquals(1, vendorInvoicingDetailObj.VIHeaderRec.size());
        system.assertEquals(0, vendorInvoicingDetailObj.VRHeaderList.size());
        system.assertEquals('', vendorInvoicingDetailObj.VIHeaderRec[0].ClosedInvoiceDate);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].FXCurrencyDetails);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IncludeOtherChargeInCosting);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IsForeignVendor);
        system.assertEquals('In Progress', vendorInvoicingDetailObj.VIHeaderRec[0].Status);
        system.assertEquals(viHeaderRec.Id, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderId);
        system.assertEquals(viHeaderRec.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderNumber);
        system.assertEquals(viHeaderRec.Vendor__c, vendorInvoicingDetailObj.VIHeaderRec[0].VendorId);
        system.assertEquals(viHeaderRec.Vendor__r.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VendorName);
    }

    @IsTest
    static void updateVIHeaderTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
            String vendorInvoicingDetails = VendorInvoicingCtrl.updateVIHeader(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString('InvoiceNumber1234'), null, receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        Test.stopTest();

        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);
        system.assertEquals('InvoiceNumber1234', vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);

        // Duplicate Invoice Number
        viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
        vendorInvoicingDetails = VendorInvoicingCtrl.updateVIHeader(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString('InvoiceNumber1234'), null, receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        
        vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);
    }
    
    @IsTest
    static void addToItemsSubsectionTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
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

        String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
        String vendorInvoicingDetails = VendorInvoicingCtrl.addToItemsSubsection(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(vrHeaderId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);
        assertAddToItemsSubsectionTest(viHeaderId, vendorInvoicingDetailObj);
    }
    
    static void assertAddToItemsSubsectionTest(String viHeaderId, VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj) {
        Vendor_Invoicing_Header__c viHeaderRec = [SELECT Id, Name, Vendor__c, Vendor__r.Name FROM Vendor_Invoicing_Header__c LIMIT 1];
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Id viGroupId = [SELECT Id FROM Vendor_Invoicing_Group__c LIMIT 1].Id;
        Id vrHeaderId = [SELECT Id FROM Vendor_Receiving_Header__c LIMIT 1].Id;

        system.assertEquals(100.00, vendorInvoicingDetailObj.ItemsTotal);
        system.assertEquals(10.0, vendorInvoicingDetailObj.Taxes);
        system.assertEquals(100.0, vendorInvoicingDetailObj.Total);
        system.assertEquals(0.0, vendorInvoicingDetailObj.TotalOtherCharges);
        system.assertEquals(110.0, vendorInvoicingDetailObj.TotalWithTax);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalOtherChargesRec);
        system.assertEquals(1.0, vendorInvoicingDetailObj.totalGroupItems);
        system.assertEquals(1.0, vendorInvoicingDetailObj.totalVendorOrderInvoicing);
        system.assertEquals(0, vendorInvoicingDetailObj.OtherChargesList.size());

        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].AppliedCharge);
        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].Discount);
        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].DiscountAmout);
        system.assertEquals(100.0, vendorInvoicingDetailObj.VIGroupList[0].InvoiceCost);
        system.assertEquals(1, vendorInvoicingDetailObj.VIGroupList[0].InvoiceQty);
        system.assertEquals('test0 - test0', vendorInvoicingDetailObj.VIGroupList[0].Item);
        system.assertEquals('', vendorInvoicingDetailObj.VIGroupList[0].OrderType);
        system.assertEquals(1, vendorInvoicingDetailObj.VIGroupList[0].PackageQty);
        system.assertEquals('EA', vendorInvoicingDetailObj.VIGroupList[0].PackageUnit);
        system.assertEquals('TestPackageSlip', vendorInvoicingDetailObj.VIGroupList[0].PackingNumber);
        system.assertEquals(100.00, vendorInvoicingDetailObj.VIGroupList[0].PartCost);
        system.assertEquals(partId, vendorInvoicingDetailObj.VIGroupList[0].PartId);
        system.assertEquals(100.0, vendorInvoicingDetailObj.VIGroupList[0].ReceivingCost);
        system.assertEquals(1.0, vendorInvoicingDetailObj.VIGroupList[0].ReceivingQty);
        system.assertEquals(100.0, vendorInvoicingDetailObj.VIGroupList[0].SubTotal);
        system.assertEquals(null, vendorInvoicingDetailObj.VIGroupList[0].SubletId);
        system.assertEquals(viGroupId, vendorInvoicingDetailObj.VIGroupList[0].VIGroupId);

        system.assertEquals(1, vendorInvoicingDetailObj.VIHeaderRec.size());
        system.assertEquals('', vendorInvoicingDetailObj.VIHeaderRec[0].ClosedInvoiceDate);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].FXCurrencyDetails);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IncludeOtherChargeInCosting);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IsForeignVendor);
        system.assertEquals('In Progress', vendorInvoicingDetailObj.VIHeaderRec[0].Status);
        system.assertEquals(viHeaderRec.Id, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderId);
        system.assertEquals(viHeaderRec.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderNumber);
        system.assertEquals(viHeaderRec.Vendor__c, vendorInvoicingDetailObj.VIHeaderRec[0].VendorId);
        system.assertEquals(viHeaderRec.Vendor__r.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VendorName);

        system.assertEquals('TestPackageSlip', vendorInvoicingDetailObj.VRHeaderList[0].PackingSlipNumber);
        system.assertEquals(100, vendorInvoicingDetailObj.VRHeaderList[0].TotalCost);
        system.assertEquals(1, vendorInvoicingDetailObj.VRHeaderList[0].TotalNumberOfLineItems);
        system.assertEquals(vrHeaderId, vendorInvoicingDetailObj.VRHeaderList[0].VRHeaderId);
        system.assertEquals(viHeaderId, vendorInvoicingDetailObj.VRHeaderList[0].InProgressVIHeaderId);
    }
    
    @IsTest
    static void removeFromItemSubSectionTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
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

        String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
        VendorInvoicingCtrl.addToItemsSubsection(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(vrHeaderId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        String vendorInvoicingDetails = VendorInvoicingCtrl.removeFromItemSubSection(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(vrHeaderId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);

        assertRemoveFromItemSubSectionTest(viHeaderId, vendorInvoicingDetailObj);
    }
    
    static void assertRemoveFromItemSubSectionTest(String viHeaderId, VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj) {
        Vendor_Invoicing_Header__c viHeaderRec = [SELECT Id, Name, Vendor__c, Vendor__r.Name FROM Vendor_Invoicing_Header__c LIMIT 1];
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Id vrHeaderId = [SELECT Id FROM Vendor_Receiving_Header__c LIMIT 1].Id;

        system.assertEquals(0.0, vendorInvoicingDetailObj.ItemsTotal);
        system.assertEquals(0.0, vendorInvoicingDetailObj.Taxes);
        system.assertEquals(0.0, vendorInvoicingDetailObj.Total);
        system.assertEquals(0.0, vendorInvoicingDetailObj.TotalOtherCharges);
        system.assertEquals(0.0, vendorInvoicingDetailObj.TotalWithTax);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalOtherChargesRec);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalGroupItems);
        system.assertEquals(1.0, vendorInvoicingDetailObj.totalVendorOrderInvoicing);
        system.assertEquals(0, vendorInvoicingDetailObj.OtherChargesList.size());

        system.assertEquals(0, vendorInvoicingDetailObj.VIGroupList.size());

        system.assertEquals(1, vendorInvoicingDetailObj.VIHeaderRec.size());
        system.assertEquals('', vendorInvoicingDetailObj.VIHeaderRec[0].ClosedInvoiceDate);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].FXCurrencyDetails);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IncludeOtherChargeInCosting);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IsForeignVendor);
        system.assertEquals('In Progress', vendorInvoicingDetailObj.VIHeaderRec[0].Status);
        system.assertEquals(viHeaderRec.Id, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderId);
        system.assertEquals(viHeaderRec.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderNumber);
        system.assertEquals(viHeaderRec.Vendor__c, vendorInvoicingDetailObj.VIHeaderRec[0].VendorId);
        system.assertEquals(viHeaderRec.Vendor__r.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VendorName);

        system.assertEquals('TestPackageSlip', vendorInvoicingDetailObj.VRHeaderList[0].PackingSlipNumber);
        system.assertEquals(100, vendorInvoicingDetailObj.VRHeaderList[0].TotalCost);
        system.assertEquals(1, vendorInvoicingDetailObj.VRHeaderList[0].TotalNumberOfLineItems);
        system.assertEquals(vrHeaderId, vendorInvoicingDetailObj.VRHeaderList[0].VRHeaderId);
        system.assertEquals(null, vendorInvoicingDetailObj.VRHeaderList[0].InProgressVIHeaderId);
    }

    @IsTest
    static void updateVIGroupTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
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

        String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
        VendorInvoicingCtrl.addToItemsSubsection(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(vrHeaderId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        String vendorInvoicingGroupId = [SELECT Id FROM Vendor_Invoicing_Group__c LIMIT 1].Id;
        String jsonString = BPUtility.getEncodedString('{"VIGroupId":"'+ vendorInvoicingGroupId +'", "SubTotal": 100, "SubletId": null, "ReceivingQty": 1, "ReceivingCost": 100, "PartId": "'+ partId +'", "PartCost": 100,"PackingNumber": "TestPackageSlip", "PackageUnit": "EA", "PackageQty": 1, "OrderType": "", "Item": "test0 - test0", "InvoiceQty": 1,"InvoiceCost": "200.00","DiscountAmout": 0,"Discount": 0,"AppliedCharge": 0}');
        String vendorInvoicingDetails = VendorInvoicingCtrl.updateVIGroup(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(vrHeaderId), jsonString, receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);
        assertUpdateVIGroupTest(viHeaderId, vendorInvoicingDetailObj);
    }
    
    static void assertUpdateVIGroupTest(String viHeaderId, VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj) {
        Vendor_Invoicing_Header__c viHeaderRec = [SELECT Id, Name, Vendor__c, Vendor__r.Name FROM Vendor_Invoicing_Header__c LIMIT 1];
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Id viGroupId = [SELECT Id FROM Vendor_Invoicing_Group__c LIMIT 1].Id;
        Id vrHeaderId = [SELECT Id FROM Vendor_Receiving_Header__c LIMIT 1].Id;

        system.assertEquals(200.0, vendorInvoicingDetailObj.ItemsTotal);
        system.assertEquals(20.0, vendorInvoicingDetailObj.Taxes);
        system.assertEquals(200.0, vendorInvoicingDetailObj.Total);
        system.assertEquals(0.0, vendorInvoicingDetailObj.TotalOtherCharges);
        system.assertEquals(220.0, vendorInvoicingDetailObj.TotalWithTax);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalOtherChargesRec);
        system.assertEquals(1.0, vendorInvoicingDetailObj.totalGroupItems);
        system.assertEquals(1.0, vendorInvoicingDetailObj.totalVendorOrderInvoicing);
        system.assertEquals(0, vendorInvoicingDetailObj.OtherChargesList.size());

        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].AppliedCharge);
        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].Discount);
        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].DiscountAmout);
        system.assertEquals(200.0, vendorInvoicingDetailObj.VIGroupList[0].InvoiceCost);
        system.assertEquals(1, vendorInvoicingDetailObj.VIGroupList[0].InvoiceQty);
        system.assertEquals('test0 - test0', vendorInvoicingDetailObj.VIGroupList[0].Item);
        system.assertEquals('', vendorInvoicingDetailObj.VIGroupList[0].OrderType);
        system.assertEquals(1, vendorInvoicingDetailObj.VIGroupList[0].PackageQty);
        system.assertEquals('EA', vendorInvoicingDetailObj.VIGroupList[0].PackageUnit);
        system.assertEquals('TestPackageSlip', vendorInvoicingDetailObj.VIGroupList[0].PackingNumber);
        system.assertEquals(100.00, vendorInvoicingDetailObj.VIGroupList[0].PartCost);
        system.assertEquals(partId, vendorInvoicingDetailObj.VIGroupList[0].PartId);
        system.assertEquals(100.0, vendorInvoicingDetailObj.VIGroupList[0].ReceivingCost);
        system.assertEquals(1.0, vendorInvoicingDetailObj.VIGroupList[0].ReceivingQty);
        system.assertEquals(200.0, vendorInvoicingDetailObj.VIGroupList[0].SubTotal);
        system.assertEquals(null, vendorInvoicingDetailObj.VIGroupList[0].SubletId);
        system.assertEquals(viGroupId, vendorInvoicingDetailObj.VIGroupList[0].VIGroupId);

        system.assertEquals(1, vendorInvoicingDetailObj.VIHeaderRec.size());
        system.assertEquals('', vendorInvoicingDetailObj.VIHeaderRec[0].ClosedInvoiceDate);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].FXCurrencyDetails);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IncludeOtherChargeInCosting);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IsForeignVendor);
        system.assertEquals('In Progress', vendorInvoicingDetailObj.VIHeaderRec[0].Status);
        system.assertEquals(viHeaderRec.Id, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderId);
        system.assertEquals(viHeaderRec.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderNumber);
        system.assertEquals(viHeaderRec.Vendor__c, vendorInvoicingDetailObj.VIHeaderRec[0].VendorId);
        system.assertEquals(viHeaderRec.Vendor__r.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VendorName);

        system.assertEquals('TestPackageSlip', vendorInvoicingDetailObj.VRHeaderList[0].PackingSlipNumber);
        system.assertEquals(100, vendorInvoicingDetailObj.VRHeaderList[0].TotalCost);
        system.assertEquals(1, vendorInvoicingDetailObj.VRHeaderList[0].TotalNumberOfLineItems);
        system.assertEquals(vrHeaderId, vendorInvoicingDetailObj.VRHeaderList[0].VRHeaderId);
        system.assertEquals(viHeaderId, vendorInvoicingDetailObj.VRHeaderList[0].InProgressVIHeaderId);
    }

    @IsTest
    static void getSearchResultsUpdatedTest () {
        makeTestData();
        String jsonString = '{"ObjectLabel":"","SearchText":"test0","PreferredObject":"Vendor","SearchableObjects":"Vendor", "SearchConfigNames" : "Vendor", "FilterValues":[]}';
        jsonString = BPUtility.getDecodedString(CustomerOrderCtrl.getSearchResultsUpdated(BPUtility.getEncodedString(jsonString)));
        System.assertEquals('[]', jsonString);
    }
    
    @IsTest
    static void deleteVendorOrderInvoicingTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        
        Test.startTest();
            String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
            String response = BPUtility.getDecodedString(VendorInvoicingCtrl.deleteVendorOrderInvoicing(BPUtility.getEncodedString(viHeaderId))); 
        Test.stopTest();
        system.assertEquals('Success', response);
        System.assertEquals(0, [SELECT Id FROM Vendor_Invoicing_Header__c].size());
    }
    
    
    @IsTest
    static void addOtherChargesTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id feeId = [SELECT Id FROM Fee__c LIMIT 1].Id;
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
            String vendorInvoicingDetails = VendorInvoicingCtrl.addOtherCharges(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(feeId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON); 
        Test.stopTest();

        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);
        assertAddOtherChargesTest(viHeaderId, vendorInvoicingDetailObj);
    }
    
    static void assertAddOtherChargesTest(String viHeaderId, VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj) {
        Vendor_Invoicing_Header__c viHeaderRec = [SELECT Id, Name, Vendor__c, Vendor__r.Name FROM Vendor_Invoicing_Header__c LIMIT 1];
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Other_Charges__c otherChargeRec = [SELECT Id, Name FROM Other_Charges__c LIMIT 1];
        Id feeId = [SELECT Id FROM Fee__c LIMIT 1].Id;

        system.assertEquals(0.00, vendorInvoicingDetailObj.ItemsTotal);
        system.assertEquals(10.0, vendorInvoicingDetailObj.Taxes);
        system.assertEquals(100.0, vendorInvoicingDetailObj.Total);
        system.assertEquals(100.0, vendorInvoicingDetailObj.TotalOtherCharges);
        system.assertEquals(110.0, vendorInvoicingDetailObj.TotalWithTax);
        system.assertEquals(1.0, vendorInvoicingDetailObj.totalOtherChargesRec);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalGroupItems);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalVendorOrderInvoicing);
        system.assertEquals(1, vendorInvoicingDetailObj.OtherChargesList.size());

        system.assertEquals(0, vendorInvoicingDetailObj.OtherChargesList[0].AppliedAmount);
        system.assertEquals('feecode', vendorInvoicingDetailObj.OtherChargesList[0].Code);
        system.assertEquals(100.0, vendorInvoicingDetailObj.OtherChargesList[0].Cost);
        system.assertEquals('test0', vendorInvoicingDetailObj.OtherChargesList[0].Description);
        system.assertEquals(feeId, vendorInvoicingDetailObj.OtherChargesList[0].Fee);
        system.assertEquals(otherChargeRec.Id, vendorInvoicingDetailObj.OtherChargesList[0].Id);
        system.assertEquals('feecode - test0', vendorInvoicingDetailObj.OtherChargesList[0].ItemDesc);
        system.assertEquals(otherChargeRec.Name, vendorInvoicingDetailObj.OtherChargesList[0].Name);
        system.assertEquals('', vendorInvoicingDetailObj.OtherChargesList[0].Notes);
        system.assertEquals(0.0, vendorInvoicingDetailObj.OtherChargesList[0].TaxPercent);

        system.assertEquals(1, vendorInvoicingDetailObj.VIHeaderRec.size());
        system.assertEquals('', vendorInvoicingDetailObj.VIHeaderRec[0].ClosedInvoiceDate);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].FXCurrencyDetails);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IncludeOtherChargeInCosting);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IsForeignVendor);
        system.assertEquals('In Progress', vendorInvoicingDetailObj.VIHeaderRec[0].Status);
        system.assertEquals(viHeaderRec.Id, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderId);
        system.assertEquals(viHeaderRec.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderNumber);
        system.assertEquals(viHeaderRec.Vendor__c, vendorInvoicingDetailObj.VIHeaderRec[0].VendorId);
        system.assertEquals(viHeaderRec.Vendor__r.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VendorName);
    }

    @IsTest
    static void updateOtherChargesTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id feeId = [SELECT Id FROM Fee__c LIMIT 1].Id;
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
            VendorInvoicingCtrl.addOtherCharges(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(feeId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON); 
            Other_Charges__c otherChargeRec = [SELECT Id, Name FROM Other_Charges__c LIMIT 1];
            String jsonString = '{"TaxPercent":0,"Notes":"","Name":"'+ otherChargeRec.Name +'","ItemDesc":"fee0 - fee0","Id":"' + otherChargeRec.Id + '","Fee":"' + feeId + '","Description":"fee0", "Cost":"200.00", "Code":"fee0", "AppliedAmount":0}';
            String vendorInvoicingDetails = VendorInvoicingCtrl.updateOtherCharges(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(jsonString), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON); 
        Test.stopTest();

        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);
        assertUpdateOtherChargesTest(viHeaderId, vendorInvoicingDetailObj);
    }
    
    static void assertUpdateOtherChargesTest(String viHeaderId, VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj) {
        Vendor_Invoicing_Header__c viHeaderRec = [SELECT Id, Name, Vendor__c, Vendor__r.Name FROM Vendor_Invoicing_Header__c LIMIT 1];
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Other_Charges__c otherChargeRec = [SELECT Id, Name FROM Other_Charges__c LIMIT 1];
        Id feeId = [SELECT Id FROM Fee__c LIMIT 1].Id;

        system.assertEquals(0.00, vendorInvoicingDetailObj.ItemsTotal);
        system.assertEquals(20.0, vendorInvoicingDetailObj.Taxes);
        system.assertEquals(200.0, vendorInvoicingDetailObj.Total);
        system.assertEquals(200.0, vendorInvoicingDetailObj.TotalOtherCharges);
        system.assertEquals(220.0, vendorInvoicingDetailObj.TotalWithTax);
        system.assertEquals(1.0, vendorInvoicingDetailObj.totalOtherChargesRec);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalGroupItems);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalVendorOrderInvoicing);
        system.assertEquals(1, vendorInvoicingDetailObj.OtherChargesList.size());

        system.assertEquals(0, vendorInvoicingDetailObj.OtherChargesList[0].AppliedAmount);
        system.assertEquals('feecode', vendorInvoicingDetailObj.OtherChargesList[0].Code);
        system.assertEquals(200.0, vendorInvoicingDetailObj.OtherChargesList[0].Cost);
        system.assertEquals('fee0', vendorInvoicingDetailObj.OtherChargesList[0].Description);
        system.assertEquals(feeId, vendorInvoicingDetailObj.OtherChargesList[0].Fee);
        system.assertEquals(otherChargeRec.Id, vendorInvoicingDetailObj.OtherChargesList[0].Id);
        system.assertEquals('feecode - fee0', vendorInvoicingDetailObj.OtherChargesList[0].ItemDesc);
        system.assertEquals(otherChargeRec.Name, vendorInvoicingDetailObj.OtherChargesList[0].Name);
        system.assertEquals('', vendorInvoicingDetailObj.OtherChargesList[0].Notes);
        system.assertEquals(0.0, vendorInvoicingDetailObj.OtherChargesList[0].TaxPercent);

        system.assertEquals(1, vendorInvoicingDetailObj.VIHeaderRec.size());
        system.assertEquals('', vendorInvoicingDetailObj.VIHeaderRec[0].ClosedInvoiceDate);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].FXCurrencyDetails);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IncludeOtherChargeInCosting);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IsForeignVendor);
        system.assertEquals('In Progress', vendorInvoicingDetailObj.VIHeaderRec[0].Status);
        system.assertEquals(viHeaderRec.Id, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderId);
        system.assertEquals(viHeaderRec.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderNumber);
        system.assertEquals(viHeaderRec.Vendor__c, vendorInvoicingDetailObj.VIHeaderRec[0].VendorId);
        system.assertEquals(viHeaderRec.Vendor__r.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VendorName);
    }

    @IsTest
    static void saveVIHeaderDetailsTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id feeId = [SELECT Id FROM Fee__c LIMIT 1].Id;
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
            VendorInvoicingCtrl.addOtherCharges(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(feeId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON); 
            String jsonString = BPUtility.getEncodedString('{"VIHeaderId":"'+ viHeaderId +'","IncludeOtherChargeInCosting":true}');
            String response = BPUtility.getDecodedString(VendorInvoicingCtrl.saveVIHeaderDetails(jsonString));
        Test.stopTest();
       
        system.assertEquals('Success', response);
        system.assertEquals(true, [SELECT Id, Include_Other_Charge_In_Costing__c FROM Vendor_Invoicing_Header__c LIMIT 1].Include_Other_Charge_In_Costing__c);
    }

    @IsTest
    static void deleteOtherChargesTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id feeId = [SELECT Id FROM Fee__c LIMIT 1].Id;
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
        Test.startTest();
            String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
            VendorInvoicingCtrl.addOtherCharges(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(feeId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON); 
            Id otherChargeId = [SELECT Id FROM Other_Charges__c LIMIT 1].Id;
            VendorInvoicingCtrl.deleteOtherCharges(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(otherChargeId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON); 
        Test.stopTest();

        system.assertEquals(0, [SELECT Id FROM Other_Charges__c].size());
    }

    @IsTest
    static void finalizeInvoiceAction() {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        String itemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"CreatedDate","SortDirection":"ASC"}]}');
        String customersPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String stocksPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String receivingPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        String groupItemsPageSortAttrsJSON = BPUtility.getEncodedString('{"CurrentPage":1,"PageSize":"50","Sorting":[{"FieldName":"Item","SortDirection":"ASC"}]}');
        
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

        String viHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewVendorInvoicing(BPUtility.getEncodedString(vendorId))); 
        VendorInvoicingCtrl.addToItemsSubsection(BPUtility.getEncodedString(viHeaderId), BPUtility.getEncodedString(vrHeaderId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        String vendorInvoicingDetails = VendorInvoicingCtrl.finalizeInvoiceAction(BPUtility.getEncodedString(viHeaderId), receivingPageSortAttrsJSON, groupItemsPageSortAttrsJSON);
        VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj = (VendorInvoicingCtrl.VIHeaderWrapper) System.JSON.deserialize(BPUtility.getDecodedString(vendorInvoicingDetails), VendorInvoicingCtrl.VIHeaderWrapper.class);
        
        assertFinalizeInvoiceAction(viHeaderId, vendorInvoicingDetailObj);
    }
    
    static void assertFinalizeInvoiceAction(String viHeaderId, VendorInvoicingCtrl.VIHeaderWrapper vendorInvoicingDetailObj) {
        Vendor_Invoicing_Header__c viHeaderRec = [SELECT Id, Name, Vendor__c, Vendor__r.Name FROM Vendor_Invoicing_Header__c LIMIT 1];
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        Id viGroupId = [SELECT Id FROM Vendor_Invoicing_Group__c LIMIT 1].Id;
        Id vrHeaderId = [SELECT Id FROM Vendor_Receiving_Header__c LIMIT 1].Id;

        system.assertEquals(100.00, vendorInvoicingDetailObj.ItemsTotal);
        system.assertEquals(10.0, vendorInvoicingDetailObj.Taxes);
        system.assertEquals(100.0, vendorInvoicingDetailObj.Total);
        system.assertEquals(0.0, vendorInvoicingDetailObj.TotalOtherCharges);
        system.assertEquals(110.0, vendorInvoicingDetailObj.TotalWithTax);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalOtherChargesRec);
        system.assertEquals(1.0, vendorInvoicingDetailObj.totalGroupItems);
        system.assertEquals(0.0, vendorInvoicingDetailObj.totalVendorOrderInvoicing);
        system.assertEquals(0, vendorInvoicingDetailObj.OtherChargesList.size());

        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].AppliedCharge);
        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].Discount);
        system.assertEquals(0.0, vendorInvoicingDetailObj.VIGroupList[0].DiscountAmout);
        system.assertEquals(100.0, vendorInvoicingDetailObj.VIGroupList[0].InvoiceCost);
        system.assertEquals(1, vendorInvoicingDetailObj.VIGroupList[0].InvoiceQty);
        system.assertEquals('test0 - test0', vendorInvoicingDetailObj.VIGroupList[0].Item);
        system.assertEquals('', vendorInvoicingDetailObj.VIGroupList[0].OrderType);
        system.assertEquals(1, vendorInvoicingDetailObj.VIGroupList[0].PackageQty);
        system.assertEquals('EA', vendorInvoicingDetailObj.VIGroupList[0].PackageUnit);
        system.assertEquals('TestPackageSlip', vendorInvoicingDetailObj.VIGroupList[0].PackingNumber);
        system.assertEquals(100.00, vendorInvoicingDetailObj.VIGroupList[0].PartCost);
        system.assertEquals(partId, vendorInvoicingDetailObj.VIGroupList[0].PartId);
        system.assertEquals(100.0, vendorInvoicingDetailObj.VIGroupList[0].ReceivingCost);
        system.assertEquals(1.0, vendorInvoicingDetailObj.VIGroupList[0].ReceivingQty);
        system.assertEquals(100.0, vendorInvoicingDetailObj.VIGroupList[0].SubTotal);
        system.assertEquals(null, vendorInvoicingDetailObj.VIGroupList[0].SubletId);
        system.assertEquals(viGroupId, vendorInvoicingDetailObj.VIGroupList[0].VIGroupId);

        system.assertEquals(1, vendorInvoicingDetailObj.VIHeaderRec.size());
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].FXCurrencyDetails);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IncludeOtherChargeInCosting);
        system.assertEquals(null, vendorInvoicingDetailObj.VIHeaderRec[0].InvoiceNumber);
        system.assertEquals(false, vendorInvoicingDetailObj.VIHeaderRec[0].IsForeignVendor);
        system.assertEquals('Invoiced', vendorInvoicingDetailObj.VIHeaderRec[0].Status);
        system.assertEquals(viHeaderRec.Id, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderId);
        system.assertEquals(viHeaderRec.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VIHeaderNumber);
        system.assertEquals(viHeaderRec.Vendor__c, vendorInvoicingDetailObj.VIHeaderRec[0].VendorId);
        system.assertEquals(viHeaderRec.Vendor__r.Name, vendorInvoicingDetailObj.VIHeaderRec[0].VendorName);
    }
}