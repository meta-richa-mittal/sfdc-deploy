@isTest
global without sharing class QB_SyncUnitConsignmentBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }

    static testMethod void unitConsignmentPayload(){
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        BPScriptUtility.disbaleTrigger('COTrigger');
        BPScriptUtility.disbaleTrigger('CategoryTrigger');
        BPScriptUtility.disbaleTrigger('COLineItemTrigger');
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Credit Memo' , IFWConfigObj[0].Id);
        Unit_Make__c unitMakeRec = TestDataFactory.createUnitMake('Test make', 'TES', true);
    	Unit_Model__c unitModelRec = TestDataFactory.createUnitModel('Test Model', 'TES', true, unitMakeRec.Id);
    	Account customerRec = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test', 'Customer');
        customerRec.AccountingId__c = '1231';
        update customerRec;
    	CO_Header__c coHeaderRec = TestDataFactory.createCoHeader(customerRec.Id);
    	Unit_Sub_Model__c unitSubModelRec = TestDataFactory.createSubModel(unitModelRec);
    	Customer_Owned_Unit__c unitRec = TestDataFactory.createStockUnit(unitMakeRec.Id, unitModelRec.Id, unitSubModelRec.Id, 'TES');
    	//Deal__c dealRec = TestDataFactory.createDeal(coHeaderRec.Id, unitRec.Id);
        //Deal_Item__c dealItem = TestDataFactory.createConDealItem(unitModelRec.Id,dealRec.Id,unitRec.Id);
        unitRec.Consignment__c = true;
        unitRec.Unit_Type__c = 'COU';
        unitRec.Status__c = 'Transferred';
        unitRec.Sales_Tax_Credit__c = 2;
        unitRec.Agreed_Payout__c = 100;
        unitRec.VIN_Number__c = '3313132132132';
        unitRec.Suggested_Price__c = 150;
        unitRec.Invoice_Number__c = 'INV -432424';
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitRec);
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();

        String query = 'SELECT Available_For_QB_Consignment_Sync__c From Customer_Owned_Unit__c';
        Customer_Owned_Unit__c unitRecord = Database.query(query);
        System.assertEquals(unitRecord.Available_For_QB_Consignment_Sync__c, false);
    }
}