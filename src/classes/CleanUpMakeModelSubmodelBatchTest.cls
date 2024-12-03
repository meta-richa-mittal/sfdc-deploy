@isTest
private class CleanUpMakeModelSubmodelBatchTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Unit_Make__c unitMake = new Unit_Make__c(name = 'Test Make');
        insert unitMake;
        Unit_Model__c unitModel = new Unit_Model__c(Name__c = 'Test Model', Unit_Make__c = unitMake.id);
        insert unitModel;
        Unit_Sub_Model__c unitSubModel = new Unit_Sub_Model__c(Sub_Model_Name__c = 'Test Sub Model', Unit_Model__c = unitModel.id);
        insert unitSubModel;
        unitModel.Sub_Model__c = unitSubModel.id;
        update unitModel;
    }

    @isTest
    private static void testCleanUpMakeModelSubmodelBatchMethods() {
        Test.startTest();
        Database.executeBatch(new CleanUpMakeModelSubmodelBatch());
        Test.stopTest();
        list<Unit_Sub_Model__c> result = [SELECT id from Unit_Sub_Model__c limit 1];
        system.assertEquals(1, result.size());
    }
}