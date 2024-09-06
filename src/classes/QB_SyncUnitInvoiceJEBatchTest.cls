@isTest
global without sharing class QB_SyncUnitInvoiceJEBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }
    
    static testMethod void unitinvoicejePayload(){
        Test.startTest();
        insert new Configurations__c(Accrue_Trade_Tax_Until_Unit_Sold__c = true);
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);

        Customer_Owned_Unit__c insertRefCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'ORDU', Status__c = 'Received', Total_Cost__c = 1324);
        insert insertRefCOU;
        Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'STOCK', Referenced_Unit__c = insertRefCOU.id, Purchase_Tax_Credit__c = 100);
        insert insertCOU;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());  
        Customer_Owned_Unit__c couRec = [Select id, Purchase_Tax_Credit__c, Referenced_Unit__c from Customer_Owned_Unit__c where Unit_Type__c = 'STOCK' LIMIT 2][0];
        couRec.Purchase_Tax_Credit__c = 1234;
        couRec.Invoice_Number__c = '152375';
        update couRec;
        List<Customer_Owned_Unit__c> couList = [Select id from Customer_Owned_Unit__c limit 2];
        system.assertEquals(2, couList.size());
   		Test.stopTest();

        String query = 'SELECT Available_For_QB_Unit_Invoice_JE_Sync__c From Customer_Owned_Unit__c where Referenced_Unit__c != null ';
        Customer_Owned_Unit__c unitRecord = Database.query(query);
        System.assertEquals(unitRecord.Available_For_QB_Unit_Invoice_JE_Sync__c, false);
    }
}