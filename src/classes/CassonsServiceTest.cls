@isTest
private class CassonsServiceTest {
    
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Account vendor = new Account(name = 'vendor1', is_vendor__c =true);
        insert vendor;
        
        Category__c category = new Category__c(name = 'cat1', Description__c = 'cat Description');
        insert category;
        
        Part__c part = new Part__c(Description__c = 'description',
							        Order_Lots__c = 10,
							        Part_Number__c = 'part no xyz',
							        Cassons_ID__c = 'cassonsId', vendor__c = vendor.id, category__c = category.id, Cassons_SOH__c = 128);
        insert part;
    }
    
    @isTest
    private static void testCassonsService() {
        Part__c partRec = [SELECT Id FROM Part__c limit 1];
        Test.startTest();
        CassonsService.getCassonsInventoryByPartId(partRec.Id);
        Test.stopTest();
        List<Part__c> result = [SELECT id, AvailableParts__c, Cassons_Description__c, Part_Number__c from Part__c limit 1];
        system.assertEquals(1, result.size());
    }
}