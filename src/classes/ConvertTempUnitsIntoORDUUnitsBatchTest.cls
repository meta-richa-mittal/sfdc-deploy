/**
 * Author: Balveer Choudhary
 * Since: Apr 29, 2022
 * Name: ConvertTempUnitsIntoORDUUnitsBatch
 * Description: Test Batch for converting Temp units into Order units and add back to deal
**/
@isTest
public without sharing class ConvertTempUnitsIntoORDUUnitsBatchTest {
    @TestSetup
    public static void setup(){
        TestDataFactory.disableFLSChecks();
        Account customer = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Fname', 'Lname');
        CO_Header__c coHeader = TestDataFactory.createCOHeader(customer.Id);
        Unit_Make__c unitMakeRec = TestDataFactory.createUnitMake('Test make', 'TES', true);
    	Unit_Model__c unitModelRec = TestDataFactory.createUnitModel('Test Model', 'TES', true, unitMakeRec.Id);
    	Unit_Sub_Model__c unitSubModelRec = TestDataFactory.createSubModel(unitModelRec);        
        Deal__c dealRec = new Deal__c(CO_Header__c = coHeader.Id, Status__c = Constants.QUOTATION, Type__c = Constants.CASH_DEAL, Unit_Status__c = Constants.TEMPORARY);
        insert dealRec;
        Deal_Item__c dealItemRec = TestDataFactory.createDealItem(unitModelRec.Id, dealRec.Id);
        dealItemRec.Type__c = 'Unit';
        dealItemRec.Unit_Make__c = unitMakeRec.Id;
        update dealItemRec;
        Deal_Unit_Price_Cost__c dealUPC = TestDataFactory.createDealUnitPriceCost('Base', 1, 100);
        dealUPC.Item_Description__c = 'Base Unit';
        dealUPC.Deal_Item__c = dealItemRec.Id;
        update dealUPC;
        insert new Post_Install_Log__c(Script_Name__c = 'executeConvertTempUnitsIntoORDUUnitsBatch()', Status__c = 'Pending');
    }

    @isTest
    public static void testConvertTempUnitsIntoORDUUnitsBatch() {
        ConvertTempUnitsIntoORDUUnitsBatch batchObj = new ConvertTempUnitsIntoORDUUnitsBatch();
        Test.startTest();
        Id batchprocessid = Database.executeBatch(batchObj, 1);
        Test.stopTest();
        List<Customer_Owned_Unit__c> unitList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'ORDU' AND Status__c = 'Temporary'];
        system.assertEquals(1, unitList.size());
        system.assertEquals(unitList[0].Id, [SELECT Id, Customer_Owned_Unit__c FROM Deal_Item__c LIMIT 1].Customer_Owned_Unit__c);
    }
}