
@isTest
private without sharing class PopulateCassonsPartDetailsBatchTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }

    @isTest
    private static void PopulateCassonsPartDetailsBatchMethodsTest(){
        BPScriptUtility.disbaleTrigger('PartTrigger');
        CassonsHerokuService.CassonsPartWrapper partRecOne = new CassonsHerokuService.CassonsPartWrapper();
        List<CassonsHerokuService.CassonsPartWrapper> partList = new List<CassonsHerokuService.CassonsPartWrapper>();
        partList.add(partRecOne);

        Account vendor = TestDataFactory.createVendor('vendorName');
        CASSONS_Vendor_List__c cassonsVendorList = new CASSONS_Vendor_List__c(Active__c = true, name = vendor.Id);
        DMLUtility.insertSobjectList('CASSONS_Vendor_List__c', cassonsVendorList);

        Set<String> cassonsVendorsIdSet = CassonsUtility.getAllCassonsVendorsIdSet();
        
        Category__c category = TestDataFactory.createCategory('Merchandise');
        category.Type__c = 'Merchandise';
        DMLUtility.updateSobjectList('Category__c', category);
        
        
        Part__c partOne = TestDataFactory.createCassonsPart(vendor.Id, category.Id);
        
        partRecOne.PartNo = partOne.Part_Number__c;
        partRecOne.Description = partOne.Description__c;
        
        Test.startTest();
        PopulateCassonsPartDetailsBatch cassonBatchObj = new PopulateCassonsPartDetailsBatch(0, partList,true);
        Id batchprocessid =Database.executeBatch(cassonBatchObj);
        Test.stopTest();
        Part__c partrec1 = [Select Id, Cassons_Description__c From Part__c];
        System.assertEquals(partrec1.Cassons_Description__c,partOne.Description__c);
        
    }
}
