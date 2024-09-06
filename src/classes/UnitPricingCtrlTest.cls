/**
 * Author: Reena Singh
 * Since: Dec 31, 2020
 * Name: UnitPricingCtrlTest test
 * Description: Controller test Class unit pricing page.
**/
@isTest
public without sharing class UnitPricingCtrlTest {
    @testSetup
    private static void setup() {
        Unit_Make__c unitMakeRec = TestUtil.createUnitMake(true, 'AssignedUnitPricingMake', 'tes', true);
        Unit_Make__c unitMakeRec1 = TestUtil.createUnitMake(false, 'UnassignedUnitPricingMakeName', 'tes', true);
        Unit_Model__c unitModelRec = TestUtil.createUnitModel(true, 'unitModelName', 'tes', true, unitMakeRec.Id);
        unitMakeRec1.Enable_Unit_Pricing__c =  true;
        insert unitMakeRec1;
        Factory_Option__c factoryOptionRec = TestUtil.createFactoryOption(true, 'Test1', 'Test1', 30, 34, unitMakeRec.Id);
        Unit_Sub_Model__c unitSubModelRec = TestUtil.createSubModel(unitModelRec.Id);
        Submodel_Factory_Option_Junction__c subModelFactoryOptionJRec = TestUtil.createSubModelFactoryOptionJuntion(true, 30, 34, factoryOptionRec.Id, unitModelRec.Id, unitSubModelRec.Id);
    }

    @isTest
    private static void getUnassignedUnitPricingMakeListTest() {
        Test.startTest();
        String result = BPUtility.getDecodedString(UnitPricingCtrl.getUnassignedUnitPricingMakeList());
        List<UnitPricingService.UnitMakeWrapper> unitMakeRec =  (List<UnitPricingService.UnitMakeWrapper>) System.JSON.deserialize(result, List<UnitPricingService.UnitMakeWrapper>.class);
        system.assertEquals(unitMakeRec[0].ActiveModelsCount, 1);
        Test.stopTest(); 
    }
    
    @isTest
    private static void getAssignedUnitPricingMakeList() {
        UnitPricingCtrl unitPricingCtrlobj = new UnitPricingCtrl();
        Test.startTest();
        String result = BPUtility.getDecodedString(UnitPricingCtrl.getAssignedUnitPricingMakeList());
        List<UnitPricingService.UnitMakeWrapper> unitMakeRec =  (List<UnitPricingService.UnitMakeWrapper>) System.JSON.deserialize(result, List<UnitPricingService.UnitMakeWrapper>.class);
        system.assertEquals(unitMakeRec[0].ActiveModelsCount, 0);
        Test.stopTest();
    }

    @isTest
    private static void enableUnitPricingOnMakeTest() {   
        List<Unit_Make__c> unitMakeRec = [SELECT Id, Name FROM Unit_Make__c];
        Test.startTest();
        System.assertEquals('Success', BPUtility.getDecodedString(UnitPricingCtrl.enableUnitPricingOnMake(BPUtility.getEncodedString(unitMakeRec[0].Id))));
        Test.stopTest();
    }
    
    @isTest
    private static void getMakePricingAndOptionsDetailsTest() {
        List<Unit_Make__c> unitMakeList = [SELECT Id, Name FROM Unit_Make__c LIMIT 1]; 
        Test.startTest();
        String result = BPUtility.getDecodedString(UnitPricingCtrl.getMakePricingAndOptionsDetails(BPUtility.getEncodedString(unitMakeList[0].Id)));
        MakePricingAndOptionWrapper makePricingWrapper = (MakePricingAndOptionWrapper) System.JSON.deserialize(result, MakePricingAndOptionWrapper.class);
        Test.stopTest();
        system.assertEquals(1, makePricingWrapper.FactoryOptionCount);
    }
    
    @isTest
    private static void createFactoryOptionTest() {
        List<Unit_Make__c> unitMakeList = [SELECT Id, Name FROM Unit_Make__c LIMIT 1]; 
        Test.startTest();
        String factObj = '{"Code": "Test","Cost": 30,"Description": "Test","MakeId": "' + unitMakeList[0].Id + '","Price": 34}';
        UnitPricingCtrl.createFactoryOption(BPUtility.getEncodedString(factObj));
        Test.stopTest();
        List<Factory_Option__c> factOptList = [Select Id, Code__c from Factory_Option__c WHERE Description__c = 'Test' ];
        system.assertEquals(1, factOptList.size());
        factOptList[0].Code__c = 'Test2';
        update factOptList[0];
        system.assertEquals('Test2', [Select Id, Code__c from Factory_Option__c WHERE Description__c = 'Test'].Code__c );
    }

    @isTest
    private static void getAllFactoryOptionsListByMakeIdTest() {
        List<Unit_Make__c> unitMakeList = [SELECT Id, Name FROM Unit_Make__c WHERE Name ='AssignedUnitPricingMake' LIMIT 1]; 
        Test.startTest();
        String result = BPUtility.getDecodedString(UnitPricingCtrl.getAllFactoryOptionsListByMakeId(BPUtility.getEncodedString(unitMakeList[0].Id)));
        List<FactoryOptionWrapper> makePricingWrapper = (List<FactoryOptionWrapper>) System.JSON.deserialize(result, List<FactoryOptionWrapper>.class);
        Test.stopTest();
        system.assertEquals('Test1', makePricingWrapper[0].Description);
    }

    @isTest
    private static void deleteFactoryOptionTest() {
        List<Factory_Option__c> factOptList = [Select Id, Code__c from Factory_Option__c];
        system.assertEquals(1, factOptList.size());
        Test.startTest();        
        system.assertEquals('Success', BPUtility.getDecodedString(UnitPricingCtrl.deleteFactoryOption(BPUtility.getEncodedString(factOptList[0].Id))));
        Test.stopTest();
    }

    @isTest
    private static void deleteSubModelFactoryOptionTest() {
        List<Submodel_Factory_Option_Junction__c> sofjList = [Select Id from Submodel_Factory_Option_Junction__c];
        system.assertEquals(1, sofjList.size());
        Test.startTest();        
        system.assertEquals('Success', BPUtility.getDecodedString(UnitPricingCtrl.deleteSubModelFactoryOption(BPUtility.getEncodedString(sofjList[0].Id))));
        Test.stopTest();
    }

    @isTest
    private static void getModelPricingAndOptionsDetailsTest() {
        List<Unit_Model__c> unitModelList = [SELECT Id, Name__c FROM Unit_Model__c LIMIT 1]; 
        Test.startTest();
        String result = BPUtility.getDecodedString(UnitPricingCtrl.getModelPricingAndOptionsDetails(BPUtility.getEncodedString(unitModelList[0].Id)));
        FactoryOptionModelWrapper modelPricingWrapper = (FactoryOptionModelWrapper) System.JSON.deserialize(result, FactoryOptionModelWrapper.class);
        Test.stopTest();
        system.assertEquals('unitModelName', modelPricingWrapper.ModelName);
    }

    @isTest
    private static void saveUnitSubModelTest() {
        List<Unit_Sub_Model__c> unitSubModelList = [SELECT Id, Cost__c,Price__c, Holdback__c FROM Unit_Sub_Model__c LIMIT 1]; 
        UnitPricingService.UnitSubModelWrapper subModelObj = new UnitPricingService.UnitSubModelWrapper(unitSubModelList[0]);
        subModelObj.Cost = 30;
        subModelObj.Price = 40;
        subModelObj.Holdback = 40;
        Test.startTest();
        UnitPricingCtrl.saveSubModel(BPUtility.getEncodedString(System.JSON.serialize(subModelObj)));
        Test.stopTest();
        system.assertEquals(40, [SELECT Id, Holdback__c FROM Unit_Sub_Model__c LIMIT 1].Holdback__c);
    }

    @isTest
    private static void saveUnitModelTest() {
        List<Unit_Model__c> unitModelList = [SELECT Id FROM Unit_Model__c LIMIT 1]; 
        Test.startTest();
        String factObj = '{"Cost": 30,"Holdback": 40,"Id": "' + unitModelList[0].Id + '","Price": 34}';
        UnitPricingCtrl.saveSubModel(BPUtility.getEncodedString(factObj));
        Test.stopTest();
        system.assertEquals(40, [SELECT Id, Default_Holdback__c FROM Unit_Model__c LIMIT 1].Default_Holdback__c);
    }

    @isTest
    private static void getAllFactoryOptionsListByRecIdTest() {
        List<Unit_Sub_Model__c> unitSubModelList = [SELECT Id FROM Unit_Sub_Model__c LIMIT 1]; 
        Test.startTest();
        String result = BPUtility.getDecodedString(UnitPricingCtrl.getAllFactoryOptionsListByRecId(BPUtility.getEncodedString(unitSubModelList[0].Id)));
        List<FactoryOptionWrapper> factoryOptionList = (List<FactoryOptionWrapper>) System.JSON.deserialize(result, List<FactoryOptionWrapper>.class);
        Test.stopTest();
        system.assertEquals(30, factoryOptionList[0].Cost);
    }

    @isTest
    private static void saveSubModelFactoryOptionTest() {
        Submodel_Factory_Option_Junction__c subModelFactoryRec = new Submodel_Factory_Option_Junction__c();
        FactoryOptionWrapper factoryOptionObj = new FactoryOptionWrapper(subModelFactoryRec);
        factoryOptionObj.ModelId = [SELECT Name, Id FROM Unit_Model__c LIMIT 1].Id;
        factoryOptionObj.SubModelId = [SELECT Id FROM Unit_Sub_Model__c LIMIT 1].Id;
        factoryOptionObj.FactoryOptionId = [SELECT Id, Code__c FROM Factory_Option__c LIMIT 1].Id;
        factoryOptionObj.Cost = 30;
        factoryOptionObj.Price = 40;
        factoryOptionObj.Id = [SELECT Id, Price__c FROM Submodel_Factory_Option_Junction__c LIMIT 1].Id;
        Test.startTest();
        UnitPricingCtrl.saveSubModelFactoryOption(BPUtility.getEncodedString(System.JSON.serialize(factoryOptionObj)));
        Test.stopTest();
        system.assertEquals(40, [SELECT Id, Price__c FROM Submodel_Factory_Option_Junction__c LIMIT 1].Price__c);
    }

    @isTest
    private static void addSubModelFactoryOptionTest() {
        Submodel_Factory_Option_Junction__c subModelFactoryRec = new Submodel_Factory_Option_Junction__c();
        List<Unit_Sub_Model__c> unitSubModelList = [SELECT Id FROM Unit_Sub_Model__c LIMIT 1];
        List<FactoryOptionWrapper> factoryOptionList = new List<FactoryOptionWrapper>();
        FactoryOptionWrapper factoryOptionObj = new FactoryOptionWrapper(subModelFactoryRec);

        factoryOptionObj.ModelId = [SELECT Name, Id FROM Unit_Model__c LIMIT 1].Id;
        factoryOptionObj.SubModelId = [SELECT Id FROM Unit_Sub_Model__c LIMIT 1].Id;
        factoryOptionObj.FactoryOptionId = [Select Id, Code__c from Factory_Option__c LIMIT 1].Id;
        factoryOptionObj.Cost = 30;
        factoryOptionObj.Price = 40;
        factoryOptionObj.Id = [SELECT Id, Price__c FROM Submodel_Factory_Option_Junction__c LIMIT 1].Id;
        factoryOptionList.add(factoryOptionObj);
        Set<String> subModelIdSet = new Set<String>{unitSubModelList[0].Id};
        Test.startTest();
        System.assertEquals('Success', BPUtility.getDecodedString(UnitPricingCtrl.addSubModelFactoryOption(BPUtility.getEncodedString(System.JSON.serialize(factoryOptionList)), BPUtility.getEncodedString(System.JSON.serialize(subModelIdSet)))));
        Test.stopTest();
    }
}