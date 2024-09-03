@isTest
    private class SyncUnitInvoiceBatchTest {
        @TestSetup
        private static void setup(){
            TestDataFactory.disableFLSChecks();
            IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
            insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
            List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
            IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
        }
        @isTest
        private static void testSyncUnitInvoiceBatch() {
            Customer_Owned_Unit__c insertRefCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'ORDU', Status__c = 'Received', Total_Cost__c = 1234);
            insert insertRefCOU;
            Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'STOCK', Referenced_Unit__c = insertRefCOU.id);
            insert insertCOU;
            Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
            Test.startTest();   
            Customer_Owned_Unit__c couRec = [Select id, Total_Cost__c, Referenced_Unit__c from Customer_Owned_Unit__c where Unit_Type__c = 'STOCK' LIMIT 2][0];
            couRec.Total_Cost__c = 1234;
            update couRec;
            List<Customer_Owned_Unit__c> couList = [Select id from Customer_Owned_Unit__c limit 2];
            system.assertEquals(2, couList.size());
            Test.stopTest();
        }
        
    }