@isTest
private class SetBRPPartIndexBatchTest {
    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks(); 
        Account vendor = TestUtil.createVendor(true, 'brp');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
        Part__c part = TestUtil.createPart(false, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);      
        part.BRP_Part_Index__c = null;
        insert part;      

        PartTriggerHelper.isForceStopTrigger = false;

        Part__c part1 = TestUtil.createPart(false, 'partNumberP011', vendor.Id, 'Test Part1', testCategory.Id, 10, 220, 530, 100, 100);
        part1.BRP_Part_Index__c = null;
        insert part1;

        BRP_Vendors_List__c brpVendorListRec = new BRP_Vendors_List__c();
        brpVendorListRec.Is_Active_Vendor__c = true;
        brpVendorListRec.Name = vendor.Id;
        brpVendorListRec.Type__c = 'Vendor';
        insert brpVendorListRec;
        
    }
    
    @isTest
    private static void testBRPPartIndexBatch() { 
        Integer partIndex = 1;
        Test.startTest();
        Database.executeBatch(new SetBRPPartIndexBatch(partIndex));
        Test.stopTest();
        List<Part__c> partList = [SELECT Name, BRP_Part_Index__c FROM Part__c]; 
        System.assertEquals(1, partList[0].BRP_Part_Index__c);
    }
}