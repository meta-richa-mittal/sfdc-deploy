@isTest
public class RecalculateCOTaxesBatchTest {
    @testSetup
    static void setup() {
        TestDataFactory.disableFLSChecks();
        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(false, null);
        coHeader1.Order_status__c = 'Open';
        insert coHeader1;
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItem = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
        ServiceJobService.createSOHeader(BPUtility.getEncodedString(coHeader1.Id));
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new RecalculateSOTaxesBatch(), 1);
        Test.stopTest();
        List<Internal_Comment__c> internalComment = [SELECT Id FROM Internal_Comment__c];
        System.assertEquals(1, internalComment.size());
    }
}