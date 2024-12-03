/**
 * Author: Reena Singh
 * Since: Oct 5, 2020
 * Name: MMSManagementCtrl test
 * Description: Controller test Class of make model and sub model.
**/
@isTest
public without sharing class MMSManagementCtrlTest {

    @testSetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
    	Unit_Make__c unitMakeRec = TestUtil.createUnitMake(true, 'unitMakeName', 'tes', true);
    	Unit_Model__c unitModelRec = TestUtil.createUnitModel(true, 'unitModelName', 'tes', true, unitMakeRec.Id);
        Unit_Sub_Model__c unitSubModelRec = TestUtil.createSubModel(unitModelRec.Id);
    }

    @isTest
    private static void deleteMakeTest() {
        List<Unit_Make__c> unitMakeRec = [SELECT Id, Name FROM Unit_Make__c];
        Test.startTest();
        MMSManagementCtrl controller = new MMSManagementCtrl();
        MMSManagementCtrl.deleteMake(BPUtility.getEncodedString(unitMakeRec[0].Id));
    	Test.stopTest();
    	List<Unit_Make__c> unitMakeList = [select Id from Unit_Make__c];  
        system.assertEquals(unitMakeList.size(), 0);
    }

    @isTest
    private static void deleteModelTest() {
        List<Unit_Model__c> unitModelRec = [SELECT Id, Name FROM Unit_Model__c];
        Test.startTest();
        MMSManagementCtrl.deleteModel(BPUtility.getEncodedString(unitModelRec[0].Id));
    	Test.stopTest();
    	List<Unit_Model__c> unitModelList = [select Id from Unit_Model__c];        
        system.assertEquals(unitModelList.size(), 0);
    }

    @isTest
    private static void deleteSubModelTest() {
        List<Unit_Sub_Model__c> unitSubModelRec = [SELECT Id, Name FROM Unit_Sub_Model__c];
        Test.startTest();
        MMSManagementCtrl.deleteSubModel(BPUtility.getEncodedString(unitSubModelRec[0].Id));
    	Test.stopTest();
    	List<Unit_Sub_Model__c> unitSubModelList = [select Id from Unit_Sub_Model__c];
        system.assertEquals(unitSubModelList.size(), 0);
    }

    @isTest
    private static void deleteUsedMakeTest() {
        Account customer = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test First Name', 'Test Last Name');
    	Unit_Make__c unitMake = TestDataFactory.createUnitMake('Test Unit Make', 'Tes', true);
    	Unit_Model__c unitModel = TestDataFactory.createUnitModel('Test Unit Model', 'Tes', true, unitMake.Id);
    	Unit_Sub_Model__c unitSubModel = TestDataFactory.createSubModel(unitModel);
    	Customer_Owned_Unit__c customerOwnedUnit = TestDataFactory.createCustomerOwnedUnit(customer.Id, unitMake.Id, unitModel.Id, unitSubModel.Id, 'VIN001');
        try {
            MMSManagementCtrl.deleteMake(BPUtility.getEncodedString(unitMake.Id));
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Cannot delete this make. This make is currently in use.'),  e.getMessage());
        }  
    }
    
    @isTest
    private static void saveMakeTest() {
        Unit_Make__c unitMakeRec = new Unit_Make__c();
        MakeModelSubModelService.MakeModelSubmodelWrapper makeModelSubmodelWrapperObj = new MakeModelSubModelService.MakeModelSubmodelWrapper(unitMakeRec);
        makeModelSubmodelWrapperObj.UnitMakeName = 'Test Make';
        makeModelSubmodelWrapperObj.Active = True;

        String unitMakeWrapper = System.JSON.serialize(makeModelSubmodelWrapperObj);
        Test.startTest();
        String result = BPUtility.getDecodedString(MMSManagementCtrl.saveMake(BPUtility.getEncodedString(unitMakeWrapper)));
        List<Unit_Make__c> unitMakeList = [select Name, Id from Unit_Make__c where Id =: result];
    	Test.stopTest();
        system.assertEquals(unitMakeList[0].Id, result);
    }

    @isTest
    private static void saveModelTest() {
        Unit_Model__c unitModelRec = new Unit_Model__c();
        List<Unit_Make__c> unitMakeList = [select Name, Id from Unit_Make__c];
        MakeModelSubModelService.MakeModelSubmodelWrapper makeModelSubmodelWrapperObj = new MakeModelSubModelService.MakeModelSubmodelWrapper(unitModelRec);
        makeModelSubmodelWrapperObj.UnitModelName = 'Test Model';
        makeModelSubmodelWrapperObj.ModelDescription = 'Test Model';
        makeModelSubmodelWrapperObj.Active = True;
        makeModelSubmodelWrapperObj.MakeId = unitMakeList[0].Id;

        String modelWrapper = System.JSON.serialize(makeModelSubmodelWrapperObj);
        Test.startTest();
        String result = BPUtility.getDecodedString(MMSManagementCtrl.saveModel(BPUtility.getEncodedString(modelWrapper)));
        List<Unit_Model__c> modelList = [select Name, Id from Unit_Model__c where Id =: result];
        Test.stopTest();
        System.assertEquals(modelList[0].Id, result);
    }

    @isTest
    private static void updateModelTest() {
        Unit_Model__c unitModelRec = new Unit_Model__c();
        List<Unit_Model__c> modelMakeList = [select Name, Id from Unit_Model__c Limit 1];
        MakeModelSubModelService.MakeModelSubmodelWrapper makeModelSubmodelWrapperObj = new MakeModelSubModelService.MakeModelSubmodelWrapper(unitModelRec);
        makeModelSubmodelWrapperObj.UnitModelName = 'Test Model';
        makeModelSubmodelWrapperObj.ModelDescription = 'Test Model';
        makeModelSubmodelWrapperObj.Active = True;
        makeModelSubmodelWrapperObj.Id = modelMakeList[0].Id;

        String modelWrapper = System.JSON.serialize(makeModelSubmodelWrapperObj);
        Test.startTest();
        Test.stopTest();
        System.assertNotEquals(null, BPUtility.getDecodedString(MMSManagementCtrl.saveModel(BPUtility.getEncodedString(modelWrapper))));
    }

    @isTest
    private static void saveSubModelTest() {
        Unit_Sub_Model__c subModelRec = new Unit_Sub_Model__c();
        MakeModelSubModelService.MakeModelSubmodelWrapper submodelObj = new MakeModelSubModelService.MakeModelSubmodelWrapper(subModelRec);
        submodelObj.SubModelName = 'Test Sub Model';
        submodelObj.SubModelDescription = 'Test Sub Model';
        submodelObj.ModelId = [SELECT Id from Unit_Model__c limit 1].Id;
        submodelObj.Active = true;

        Test.startTest();
        String result = BPUtility.getDecodedString(MMSManagementCtrl.saveSubModel(BPUtility.getEncodedString(System.JSON.serialize(submodelObj))));
        List<Unit_Sub_Model__c> subModelList = [SELECT Sub_Model_Name__c FROM Unit_Sub_Model__c WHERE Id =: result];
        Test.stopTest();
        System.assertEquals(subModelList[0].Sub_Model_Name__c, 'Test Sub Model');
    }
}