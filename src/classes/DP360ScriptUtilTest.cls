@isTest
global without sharing class DP360ScriptUtilTest {
    
    @testSetup
    private static void setup() {
        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForDP360();
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForDP360('Token', ifwConfig.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem2 = TestDataFactory.createIFWConfigItemForDP360('Create Unit', ifwConfig.Id);
        
        Unit_Make__c unitMakeRec = TestDataFactory.createUnitMake('Test make', 'TES', true);
        Unit_Model__c unitModelRec = TestDataFactory.createUnitModel('Test Model', 'TES', true, unitMakeRec.Id);
        Unit_Sub_Model__c unitSubModelRec = TestDataFactory.createSubModel(unitModelRec);
    }
    
    @isTest
    private static void syncUnitsBatch() {
        Unit_Make__c unitMakeRec = [SELECT Id FROM Unit_Make__c limit 1];
        Unit_Model__c unitModelRec = [SELECT Id FROM Unit_Model__c limit 1];
        Unit_Sub_Model__c unitSubModelRec = [SELECT Id FROM Unit_Sub_Model__c limit 1];
        
        Test.setMock(HttpCalloutMock.class, new DP360UnitMockResponseGenerator());  
        Test.startTest();
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
        Customer_Owned_Unit__c unitRec = TestDataFactory.sampleStockUnit(unitMakeRec.Id, unitModelRec.Id, unitSubModelRec.Id, 'VIN#123');
        unitRec.Status__c = 'Available';
        unitRec.Unit_Id__c = 'UNT-000001';
        insert unitRec;
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
        
        DP360ScriptUtil.syncAvailableStockUnitsToDP360();
        Test.stopTest();
        
        system.assertEquals('UNT-000001', [SELECT DP360_Inventory_Id__c FROM Customer_Owned_Unit__c limit 1].DP360_Inventory_Id__c);
    }
    
    global class DP360UnitMockResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Inventory has been saved", "data": {"AddedVins": ["VIN#123"], "existingVins": []}}');
            res.setStatusCode(200);
            return res;
        }
    }
}