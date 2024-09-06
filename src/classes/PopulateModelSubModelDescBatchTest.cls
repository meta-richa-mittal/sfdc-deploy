@isTest
public without sharing class PopulateModelSubModelDescBatchTest {
    
    @TestSetup
    static void createSampleData(){
        Unit_Make__c unitMake = TestDataFactory.createUnitMake('Test Unit Make', 'Te1', true);

        Unit_Model__c unitModel = TestDataFactory.createUnitModel('Test Unit Model', 'Te1', true, unitMake.Id);
        unitModel.Model_Description__c = 'Model description';
        update unitModel;

        Unit_Sub_Model__c unitSubModel = TestDataFactory.createSubModel(unitModel);
        unitSubModel.Sub_Model_Description__c = 'Sub-Model description';
        update unitSubModel;
    }

    @isTest
    public static void PopulateModelSubModelDescBatch_test() {
        Test.startTest();
        Database.executeBatch(new PopulateModelSubModelDescBatch());
        Test.stopTest();
        Unit_Sub_Model__c unitSubModelRec = [SELECT Description__c, Unit_Model__r.Description__c FROM Unit_Sub_Model__c LIMIT 1];
        System.assertEquals(unitSubModelRec.Description__c, 'Sub-Model description');
        System.assertEquals(unitSubModelRec.Unit_Model__r.Description__c, 'Model description');
    }
}