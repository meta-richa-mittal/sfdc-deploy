/**
 * Author: Manoj Sharma
 * Since: Oct 26, 2022
 * Name: DP360SyncSoldUnitBatchTest
 * Description: Apex test class for DP360SyncSoldUnitBatch class.
**/
@isTest
global class DP360SyncSoldUnitBatchTest {
    @testSetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
        Unit_Make__c unitMakeRec = TestDataFactory.createUnitMake('Test make', 'TES', true);
        Unit_Model__c unitModelRec = TestDataFactory.createUnitModel('Test Model', 'TES', true, unitMakeRec.Id);
        Unit_Sub_Model__c unitSubModelRec = TestDataFactory.createSubModel(unitModelRec);
    }

    @isTest
    private static void syncUnitsBatch() {
        Unit_Make__c unitMakeRec = [SELECT Id FROM Unit_Make__c limit 1];
        Unit_Model__c unitModelRec = [SELECT Id FROM Unit_Model__c limit 1];
        Unit_Sub_Model__c unitSubModelRec = [SELECT Id FROM Unit_Sub_Model__c limit 1];
        Customer_Owned_Unit__c unitRec = TestDataFactory.sampleStockUnit(unitMakeRec.Id, unitModelRec.Id, unitSubModelRec.Id, 'VIN#123');
        unitRec.Status__c = 'Sold';
        unitRec.DP360_Inventory_Id__c = 'UNT-00001';
        insert unitRec;  
        IFW_IntegrationConfig__c ifwConfig = TestDataFactory.createIFWConfigForDP360();
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForDP360('Token', ifwConfig.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem2 = TestDataFactory.createIFWConfigItemForDP360('Create Unit', ifwConfig.Id);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DP360MockResponseGenerator());
        Database.executeBatch(new DP360SyncSoldUnitBatch(), 10);
        Test.stopTest();
        system.assertEquals('UNT-00001', [SELECT DP360_Inventory_Id__c FROM Customer_Owned_Unit__c limit 1].DP360_Inventory_Id__c);
    }
    
    global class DP360MockResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Inventory has been saved", "data": {"AddedVins": ["VIN#123"], "existingVins": []}}');
            res.setStatusCode(200);
            return res;
        }
    }
}
