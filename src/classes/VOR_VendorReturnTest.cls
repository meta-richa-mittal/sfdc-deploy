@IsTest
public class VOR_VendorReturnTest {
    
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
    static void createNewReturnVOTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        
        Test.startTest();
            String voReturnId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewReturnVO(BPUtility.getEncodedString(vendorId))); 
        Test.stopTest();
        assertCreateNewReturnVOTest(voReturnId);
    }

    static void assertCreateNewReturnVOTest (String voReturnId) {
        String returnVoDetail = BPUtility.getDecodedString(ReturnVOCtrl.getReturnVODetail(BPUtility.getEncodedString(voReturnId)));
        ReturnVOHeaderWrapper voReturnWrapper = (ReturnVOHeaderWrapper) System.JSON.deserialize(returnVoDetail, ReturnVOHeaderWrapper.class);
        Return_VO_Header__c returnVoHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Return_VO_Header__c LIMIT 1];
        System.assertEquals(null, voReturnWrapper.FXCurrencyDetails);
        System.assertEquals(false, voReturnWrapper.IsForeignVendor);
        System.assertEquals(returnVoHeaderRec.Name, voReturnWrapper.Name);
        System.assertEquals(null, voReturnWrapper.RMANumber);
        System.assertEquals('In Progress', voReturnWrapper.Status);
        System.assertEquals(0, voReturnWrapper.SubTotal);
        System.assertEquals(0, voReturnWrapper.Tax);
        System.assertEquals(0, voReturnWrapper.Total);
        System.assertEquals(returnVoHeaderRec.Vendor__c, voReturnWrapper.VendorId);
        System.assertEquals(returnVoHeaderRec.Vendor_Name__c, voReturnWrapper.VendorName);
    }
    
    @IsTest
    static void saveRVOLITest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;
        
        Test.startTest();
            String voReturnId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewReturnVO(BPUtility.getEncodedString(vendorId))); 
            Return_VO_Header__c returnVoHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Return_VO_Header__c LIMIT 1];
            
            String jsonString = '[{"UnitType":null,"ReturnVOId":"'+voReturnId+'","ReturnQty":"1","PartId":"'+partId+'","partAvailableQty":1,"Name":"'+returnVoHeaderRec.Name+'","ItemDescription":"test0 - test0","ItemCost":100,"Item":"test0","InventoryCost":0,"Description":"test0"}]';
            String returnVoDetail = BPUtility.getDecodedString(ReturnVOCtrl.saveRVOLI(BPUtility.getEncodedString(voReturnId), BPUtility.getEncodedString(jsonString))); 
        Test.stopTest();
        assertsaveRVOLITest(returnVoDetail);
    }

    
    static void assertsaveRVOLITest (String returnVoDetail) {
        ReturnVOHeaderWrapper voReturnWrapper = (ReturnVOHeaderWrapper) System.JSON.deserialize(returnVoDetail, ReturnVOHeaderWrapper.class);
        Return_VO_Header__c returnVoHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Return_VO_Header__c LIMIT 1];
        Return_VO_Line_Item__c returnVOLIRec = [SELECT Id, Name, part__c, Return_Qty__c, Item_Desc__c, Item__c, Description__c FROM Return_VO_Line_Item__c LIMIT 1];

        System.assertEquals(null, voReturnWrapper.FXCurrencyDetails);
        System.assertEquals(false, voReturnWrapper.IsForeignVendor);
        System.assertEquals(returnVoHeaderRec.Name, voReturnWrapper.Name);
        System.assertEquals(null, voReturnWrapper.RMANumber);
        System.assertEquals('In Progress', voReturnWrapper.Status);
        System.assertEquals(100, voReturnWrapper.SubTotal);
        System.assertEquals(10, voReturnWrapper.Tax);
        System.assertEquals(110, voReturnWrapper.Total);
        System.assertEquals(returnVoHeaderRec.Vendor__c, voReturnWrapper.VendorId);
        System.assertEquals(returnVoHeaderRec.Vendor_Name__c, voReturnWrapper.VendorName);
        System.assertEquals(returnVOLIRec.Description__c, voReturnWrapper.ReturnVOLIList[0].Description);
        System.assertEquals(0, voReturnWrapper.ReturnVOLIList[0].InventoryCost);
        System.assertEquals(returnVOLIRec.Item__c, voReturnWrapper.ReturnVOLIList[0].Item);
        System.assertEquals(100.00, voReturnWrapper.ReturnVOLIList[0].ItemCost);
        System.assertEquals(returnVOLIRec.Item_Desc__c, voReturnWrapper.ReturnVOLIList[0].ItemDescription);
        System.assertEquals(returnVOLIRec.Name, voReturnWrapper.ReturnVOLIList[0].Name);
        System.assertEquals(returnVOLIRec.Part__c, voReturnWrapper.ReturnVOLIList[0].PartId);
        System.assertEquals(returnVOLIRec.Return_Qty__c, voReturnWrapper.ReturnVOLIList[0].ReturnQty);
        System.assertEquals(returnVoHeaderRec.Id, voReturnWrapper.ReturnVOLIList[0].ReturnVOId);
        System.assertEquals(null, voReturnWrapper.ReturnVOLIList[0].UnitType);
        System.assertEquals(5.0, voReturnWrapper.ReturnVOLIList[0].partAvailableQty);

    }

    @IsTest
    static void deleteRVOLITest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;

        Test.startTest();
            String voReturnId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewReturnVO(BPUtility.getEncodedString(vendorId))); 
            Return_VO_Header__c returnVoHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Return_VO_Header__c LIMIT 1];

            String jsonString = '[{"UnitType":null,"ReturnVOId":"'+voReturnId+'","ReturnQty":"1","PartId":"'+partId+'","partAvailableQty":1,"Name":"'+returnVoHeaderRec.Name+'","ItemDescription":"test0 - test0","ItemCost":100,"Item":"test0","InventoryCost":0,"Description":"test0"}]';
            ReturnVOCtrl.saveRVOLI(BPUtility.getEncodedString(voReturnId), BPUtility.getEncodedString(jsonString)); 
            Return_VO_Line_Item__c rovliRec = [SELECT Id FROM Return_VO_Line_Item__c LIMIT 1];
            ReturnVOCtrl.deleteRVOLI(BPUtility.getEncodedString(voReturnId), BPUtility.getEncodedString(rovliRec.Id)); 
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM Return_VO_Line_Item__c].Size());
        assertCreateNewReturnVOTest(voReturnId);
    }
    
    @IsTest
    static void saveRVOHTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        
        Test.startTest();
            String voReturnId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewReturnVO(BPUtility.getEncodedString(vendorId))); 
            String jsonString = '{"Id":"'+voReturnId+'", "VendorId":"'+vendorId+'", "RMANumber":"1234"}';
            String returnVODetail = BPUtility.getDecodedString(ReturnVOCtrl.saveRVOH(BPUtility.getEncodedString(jsonString))); 
        Test.stopTest();
        assertSaveRVOHTest(returnVODetail);
    }

    static void assertSaveRVOHTest(String returnVODetail) {
        ReturnVOHeaderWrapper voReturnWrapper = (ReturnVOHeaderWrapper) System.JSON.deserialize(returnVoDetail, ReturnVOHeaderWrapper.class);
        Return_VO_Header__c returnVoHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Return_VO_Header__c LIMIT 1];
        
        System.assertEquals(null, voReturnWrapper.FXCurrencyDetails);
        System.assertEquals(false, voReturnWrapper.IsForeignVendor);
        System.assertEquals(returnVoHeaderRec.Name, voReturnWrapper.Name);
        System.assertEquals('1234', voReturnWrapper.RMANumber);
        System.assertEquals('In Progress', voReturnWrapper.Status);
        System.assertEquals(0, voReturnWrapper.SubTotal);
        System.assertEquals(0, voReturnWrapper.Tax);
        System.assertEquals(0, voReturnWrapper.Total);
        System.assertEquals(returnVoHeaderRec.Vendor__c, voReturnWrapper.VendorId);
        System.assertEquals(returnVoHeaderRec.Vendor_Name__c, voReturnWrapper.VendorName);
    }

    @IsTest
    static void submitReturnTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;

        Test.startTest();
            String voReturnId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewReturnVO(BPUtility.getEncodedString(vendorId))); 
            Return_VO_Header__c returnVoHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Return_VO_Header__c LIMIT 1];

            String jsonString = '[{"UnitType":null,"ReturnVOId":"'+voReturnId+'","ReturnQty":"1","PartId":"'+partId+'","partAvailableQty":1,"Name":"'+returnVoHeaderRec.Name+'","ItemDescription":"test0 - test0","ItemCost":100,"Item":"test0","InventoryCost":0,"Description":"test0"}]';
            ReturnVOCtrl.saveRVOLI(BPUtility.getEncodedString(voReturnId), BPUtility.getEncodedString(jsonString)); 
            Return_VO_Line_Item__c rovliRec = [SELECT Id FROM Return_VO_Line_Item__c LIMIT 1];
            ReturnVOCtrl.submitReturn(BPUtility.getEncodedString(voReturnId)); 
        Test.stopTest();

        System.assertEquals('Submitted', [SELECT Id, Status__c FROM Return_VO_Header__c LIMIT 1].Status__c);
    }

    @IsTest
    static void approvedReturnVOTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        Id partId = [SELECT Id FROM Part__c LIMIT 1].Id;

        Test.startTest();
            String voReturnId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewReturnVO(BPUtility.getEncodedString(vendorId))); 
            Return_VO_Header__c returnVoHeaderRec = [SELECT Id, Name, Vendor__c, Vendor_Name__c FROM Return_VO_Header__c LIMIT 1];

            String jsonString = '[{"UnitType":null,"ReturnVOId":"'+voReturnId+'","ReturnQty":"1","PartId":"'+partId+'","partAvailableQty":1,"Name":"'+returnVoHeaderRec.Name+'","ItemDescription":"test0 - test0","ItemCost":100,"Item":"test0","InventoryCost":0,"Description":"test0"}]';
            ReturnVOCtrl.saveRVOLI(BPUtility.getEncodedString(voReturnId), BPUtility.getEncodedString(jsonString)); 
            Return_VO_Line_Item__c rovliRec = [SELECT Id, Part__c FROM Return_VO_Line_Item__c LIMIT 1];
            String returnVODetail = ReturnVOCtrl.SetAsApprovedReturnVO(BPUtility.getEncodedString(voReturnId)); 
        Test.stopTest();

        List<Part_FIFO_Bucket_Activity_Line_Item__c> partFifoActivityLineItemList = [SELECT Id,Reference__c,Cost__c,Type__c,Return_VO_Header__c,Return_VO_Line_Item__c,Part__c,Qty_Out__c FROM Part_FIFO_Bucket_Activity_Line_Item__c];
        System.assertEquals('Approved', [SELECT Id, Status__c FROM Return_VO_Header__c LIMIT 1].Status__c);
        System.assertEquals('Vendor Return', partFifoActivityLineItemList[0].Reference__c);
        System.assertEquals(100, partFifoActivityLineItemList[0].Cost__c);
        System.assertEquals('Vendor Return', partFifoActivityLineItemList[0].Type__c);
        System.assertEquals(voReturnId, partFifoActivityLineItemList[0].Return_VO_Header__c);
        System.assertEquals(rovliRec.Id, partFifoActivityLineItemList[0].Return_VO_Line_Item__c);
        System.assertEquals(rovliRec.Part__c, partFifoActivityLineItemList[0].Part__c);
        System.assertEquals(1, partFifoActivityLineItemList[0].Qty_Out__c);
    }

    @IsTest
    static void deleteReturnVOTest () {
        makeTestData();
        Id vendorId = [SELECT Id FROM Account LIMIT 1].Id;
        
        Test.startTest();
            String voReturnId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewReturnVO(BPUtility.getEncodedString(vendorId))); 
            ReturnVOCtrl.deleteReturnVOLI(BPUtility.getEncodedString(voReturnId));     
        Test.stopTest();
        System.assertEquals(0, [SELECT Id FROM Return_VO_Header__c LIMIT 1].Size());
    }
}