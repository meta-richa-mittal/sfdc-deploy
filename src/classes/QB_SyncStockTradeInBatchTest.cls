@isTest
public without sharing class QB_SyncStockTradeInBatchTest {
    @testsetup
    private static void setup(){
    	TestUtil.setQuickBooksConfigurations(false);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
        TestUtil.createIFWConfigItemForQB(IntegrationUtility.JOURNAL_ENTRY, IFWConfigObj[0].Id);
    	Unit_Make__c unitMakeRec = TestDataFactory.createUnitMake('Test make', 'TES', true);
    	Unit_Model__c unitModelRec = TestDataFactory.createUnitModel('Test Model', 'TES', true, unitMakeRec.Id);
    	Account customerRec = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test', 'Customer');
    	CO_Header__c coHeaderRec = TestDataFactory.createCoHeader(customerRec.Id);
    	Unit_Sub_Model__c unitSubModelRec = TestDataFactory.createSubModel(unitModelRec);
    	Customer_Owned_Unit__c unitRec = TestDataFactory.createStockUnit(unitMakeRec.Id, unitModelRec.Id, unitSubModelRec.Id, 'TES');
    	Deal__c dealRec = TestDataFactory.createDeal(coHeaderRec.Id, unitRec.Id);
    	Deal_Item__c dealItemRec = TestDataFactory.createDealItem(unitModelRec.Id, dealRec.Id);
    }
    
    @isTest
    private static void test(){
    	Deal_Item__c dealItemRec = [SELECT Id, Type__c, Is_Stocked_In__c FROM Deal_Item__c LIMIT 1];
    	Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
    	dealItemRec.Type__c = QBUtil.DEAL_ITEM_TYPE_TRADE_IN; 
    	dealItemRec.Is_Stocked_In__c = true;
    	update dealItemRec;
    	Test.stopTest(); 
    	dealItemRec = [SELECT Id, Avail_For_QB_Sync__c, Accounting_Id__c FROM Deal_Item__c WHERE Id=:dealItemRec.Id];
    	system.assertEquals(false ,dealItemRec.Avail_For_QB_Sync__c);
    	system.assertNotEquals(dealItemRec.Accounting_Id__c, null);
    }
}