@isTest
private without sharing class GenerateExportFileForStockUnitsBatchTest {
    
    @testSetup
    private static void testSetup() {
        
        Unit_Make__c make = TestDataFactory.createUnitMake('Test make', 'TES', true);
        Unit_Model__c model = TestDataFactory.createUnitModel('Test Model', 'TES', true, make.Id);
        Unit_Sub_Model__c subModel = TestDataFactory.createSubModel(model);
        Customer_Owned_Unit__c unitRec = TestDataFactory.createStockUnit(make.Id, model.Id, subModel.Id, 'TES');
    }
    
    @isTest
    private static void testExportFileForMotorlot() {
        Test.startTest();
        Database.executeBatch(new GenerateExportFileForStockUnitsBatch('Motorlot'));
        Test.stopTest();
        List<Attachment> attachmentList = [Select id from Attachment];
        System.assertEquals(1, attachmentList.size());
    }

    @isTest
    private static void testExportFileForRVTrader() {
        Test.startTest();
        Database.executeBatch(new GenerateExportFileForStockUnitsBatch('RV Trader'));
        Test.stopTest();
        List<Attachment> attachmentList = [Select id from Attachment];
        System.assertEquals(1, attachmentList.size());
    }

    @isTest
    private static void testExportFileForRVT() {
        Test.startTest();
        Database.executeBatch(new GenerateExportFileForStockUnitsBatch('RVT'));
        Test.stopTest();
        List<Attachment> attachmentList = [Select id from Attachment];
        System.assertEquals(1, attachmentList.size());
    }
}