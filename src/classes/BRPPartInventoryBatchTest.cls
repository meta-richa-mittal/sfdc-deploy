@isTest
public class BRPPartInventoryBatchTest {
    @testSetup
    private static void testSetup() { 
        TestDataFactory.disableFLSChecks();
        IFW_IntegrationConfig__c IFWConfigObj = TestDataFactory.createIFWConfigForBRP();
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Packaged_Part__c = false;
        part.Qty_On_Order__c = 0;
        part.Auto_reorder_Min__c = 1;
        part.Last_Sold__c = System.today();
        part.Auto_reorder_Max__c = 4;
        part.Last_Stocked__c = System.today();
        part.Last_Counted__c = System.today();
        part.Qty_In_Stock__c = 5;
        part.BRP_Part_Index__c = 1;
        part.Is_Included_In_BRP_Inventory__c =  false;
        insert part;

        Part__c part1 = TestUtil.createPart(false, 'partNumberP011', vendor.Id, 'Test Part1', testCategory.Id, 10, 220, 530, 100, 100);
        part1.Packaged_Part__c = false;
        part1.Qty_On_Order__c = 0;
        part.Qty_In_Stock__c = 5;
        part1.Auto_reorder_Min__c = 1;
        part1.Last_Sold__c = System.today();
        part1.Auto_reorder_Max__c = 4;
        part1.Last_Stocked__c = System.today();
        part1.Last_Counted__c = System.today();
        part1.BRP_Part_Index__c = 1;
        part1.Is_Included_In_BRP_Inventory__c =  false;
        insert part1;

        File_Storage__c fileStorage =  new File_Storage__c();
        fileStorage.Name__c= 'BRP';
        insert fileStorage;

        BRP_Vendors_List__c brpVendorListRec = new BRP_Vendors_List__c();
        brpVendorListRec.Is_Active_Vendor__c = true;
        brpVendorListRec.Name = vendor.Id;
        brpVendorListRec.Type__c = 'Vendor';
        insert brpVendorListRec;
        
        BRP_Settings__c brpSettingRec =  new BRP_Settings__c();
        brpSettingRec.Currency_Code__c ='CAD';
        brpSettingRec.Radius_Measure__c = 'mile';
        brpSettingRec.Org_Name__c = 'DEV01';
        brpSettingRec.Dealer_Id__c = '0000691784';
        brpSettingRec.Radius__c = 100;
        brpSettingRec.Endpoint__c = '';
        insert brpSettingRec;
    }

    @isTest
    private static void testBRPPartInventoryBatch() { 

        Integer partIndex = 1;
        Integer batchNumber = 1;
        System.assertEquals(2, [SELECT Id, Name, vendor__r.Name, Qty_In_Stock__c, Last_Sold__c FROM Part__c].size());

        Test.startTest();
        Database.executeBatch(new BRPPartInventoryBatch(system.today(), partIndex, batchNumber));
        Database.executeBatch(new BRPPartInventoryBatch(system.today(), partIndex));
        Test.stopTest();
            
    }
}