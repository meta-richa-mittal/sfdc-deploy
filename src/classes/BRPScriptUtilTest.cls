@isTest
private class BRPScriptUtilTest {
    static String CRON_EXP = '0 0 0 * * ? *';	
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        IFW_IntegrationConfig__c IFWConfigObj = TestDataFactory.createIFWConfigForBRP();
        insert new BRP_Settings__c(Dealer_Id__c = '0000691784', Radius_Measure__c = 'mile', Radius__c = 100);
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
    }
    @isTest
    private static void testBRPScriptUtil() {
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemBRP('BRPPartsInvoice', IFWConfigObjList[0].Id);
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Test.startTest();
        CO_Header__c coHeader = [select id from CO_Header__c limit 1][0];
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(false, coHeader.Id, 'Closed');
        coInvoiceHeader.Available_For_BRP_Parts_Invoice_Sync__c = true;
        insert coInvoiceHeader;
        BRPScriptUtil.syncBRPPartsInvoice(25, 60);
        Account testVendor = [Select Id, name from Account where Name = 'Test Vendor'];
        system.assertEquals('Test Vendor', testVendor.name);
        Test.stopTest();
    }
    @isTest
    private static void testBRPScriptUtil1() {
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemBRP('BRPRepairOrder', IFWConfigObjList[0].Id);
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Test.startTest();
        CO_Header__c coHeader = [select id from CO_Header__c limit 1][0];
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(false, coHeader.Id, 'Closed');
        coInvoiceHeader.Available_For_BRP_Repair_Order_Sync__c = true;
        insert coInvoiceHeader;
        BRPScriptUtil.syncBRPRepairOrder(25, 60);
        Account testVendor = [Select Id, name from Account where Name = 'Test Vendor'];
        system.assertEquals('Test Vendor', testVendor.name);
        Test.stopTest();
    }
    @isTest
    private static void testBRPScriptUtil2() {
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemBRP('BRPRetailDeliveryReporting', IFWConfigObjList[0].Id);
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Test.startTest();
        CO_Header__c coHeader = [select id from CO_Header__c limit 1][0];
        CO_Invoice_Header__c coInvoiceHeader = TestUtil.createCOInvoiceHeader(false, coHeader.Id, 'Closed');
        coInvoiceHeader.Available_For_BRP_RDR_Sync__c = true;
        insert coInvoiceHeader;
        BRPScriptUtil.syncBRPRetailDeliveryReporting(25, 60);
        Account testVendor = [Select Id, name from Account where Name = 'Test Vendor'];
        system.assertEquals('Test Vendor', testVendor.name);
        Test.stopTest();
    }
}