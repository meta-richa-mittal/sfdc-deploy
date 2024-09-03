
@isTest
private without sharing class IntextDuplicatePartsEmailAlertBatchTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
    @isTest
    private static void intextDuplicatePartsEmailAlertBatchMethodsTest(){
        String exportType = 'exportType';
        DateTime dateTimeValue =  Datetime.now();

        BPScriptUtility.disbaleTrigger('PartTrigger');
        Account accRec = TestDataFactory.createVendor('newacc');

        Category__c catRec = TestDataFactory.createCategory('categoryName');
        
        Part__c partRec = TestDataFactory.createNewPart(accRec.Id, catRec.Id);

        GE_File_Config__c fileConfigRec = TestDataFactory.createGEFileConfig();
        
        Test.startTest();
        IntextDuplicatePartsEmailAlertBatch reassign = new IntextDuplicatePartsEmailAlertBatch(exportType,fileConfigRec,dateTimeValue);
	 	Id batchprocessid = Database.executeBatch(reassign);
        Test.stopTest();
    }

}
