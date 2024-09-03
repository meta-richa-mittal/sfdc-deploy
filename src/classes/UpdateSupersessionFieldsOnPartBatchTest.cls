@isTest
private class UpdateSupersessionFieldsOnPartBatchTest {
    
    @testsetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
    	Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Part__c partA = TestUtil.createPart(true, 'partA', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part__c partB = TestUtil.createPart(true, 'partB', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        Part_Alternates__c partsAlternate1 = TestUtil.createPartAlternates(true, partB.Id, partA.Id, 'Replaces');
        Part_Alternates__c partsAlternate2 = TestUtil.createPartAlternates(true, partA.Id, partB.Id, 'Replaced By');
        
    }
    
    @isTest
    private static void test() {
    	Test.startTest();
    	Id batchId = Database.executeBatch(new UpdateSupersessionFieldsOnPartBatch());
    	Test.stopTest();  
    	Part__c partB = [SELECT Is_Superseded__c FROM Part__c WHERE Part_Number__c LIKE '%partB%'];
    	system.assertEquals(partB.Is_Superseded__c, true);
    }
    
    @isTest
    private static void test1() {
    	Test.startTest();
    	Id batchId = Database.executeBatch(new PopulateSupersessionFieldsOnPartBatch());
    	Test.stopTest();  
    	Part__c partB = [SELECT Is_Superseded__c FROM Part__c WHERE Part_Number__c LIKE '%partB%'];
    	system.assertEquals(partB.Is_Superseded__c, true);
    }
}