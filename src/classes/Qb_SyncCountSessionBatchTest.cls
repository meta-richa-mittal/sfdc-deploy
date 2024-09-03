@isTest
global without sharing class Qb_SyncCountSessionBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }

    static testMethod void countSessionPayLoad(){
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);
        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        Count_Session__c brandingLocationRec = new Count_Session__c(name__c = 'namarta', Count_Date_Time__c=date.today());
        DMLUtility.insertSobjectList('Count_Session__c', brandingLocationRec);

        Count_Session_Line_Item__c CountSessionLineItem = new Count_Session_Line_Item__c(Count_Session__c = brandingLocationRec.id, Total_Cost_Adjustment__c = 123.9);
        DMLUtility.insertSobjectList('Count_Session_Line_Item__c', CountSessionLineItem);

        brandingLocationRec.name__c = 'jay';
        brandingLocationRec.Status__c = 'Closed';
        DMLUtility.updateSobjectList('Count_Session__c', brandingLocationRec);
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        Test.stopTest();
        String query = 'SELECT Available_For_QB_Sync__c From Count_Session__c';
        Count_Session__c countSessionRecord = Database.query(query);
        System.assertEquals(countSessionRecord.Available_For_QB_Sync__c, false);
    }
}