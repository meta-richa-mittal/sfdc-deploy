@isTest
private without sharing class SOMPartsOnOrderBatchTest {
    
    @testSetup
    private static void testSetup() { 
    	TestDataFactory.createSOMConfig();
    	TestDataFactory.disableFLSChecks();
    	
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        part.Packaged_Part__c = false;
        part.Qty_On_Order__c = 0;
        part.Order_Lots__c = 1;
        insert part;
        
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader.Id, part.Id, 150);
        Vendor_Order_Header__c voHeader = TestUtil.createVendorOrderHeader(false, vendor.Id);
        voHeader.Ordered_Date__c = system.today();
        voHeader.Status__c = 'On Order';
        insert voHeader;
    }
    
    @isTest
    private static void testCheckForFileData() { 
        Vendor_Order_Header__c voHeader = [SELECT Id FROM Vendor_Order_Header__c limit 1];
        Vendor_Order_Line_Item__c voli = [SELECT Id FROM Vendor_Order_Line_Item__c limit 1];
        voli.Vendor_Order_Header__c = voHeader.Id;
        update voli;
        
        Test.startTest();
        Database.executeBatch(new SOMPartsOnOrderBatch(system.today()));
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM SOM_Integration__c].size());
    }
}