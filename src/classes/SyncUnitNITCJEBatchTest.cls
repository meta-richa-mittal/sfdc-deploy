@isTest
    private class SyncUnitNITCJEBatchTest {
        @TestSetup
        private static void setup(){
            TestDataFactory.disableFLSChecks();
            IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
            insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
            List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
            IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
        }
        @isTest
        private static void testSyncUnitNITCJEBatch() {
            Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(Unit_Type__c = 'STOCK', Sales_Tax_Credit__c = 1209, NITC_Claimed_Manually__c = false);
            insert insertCOU;
            Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
            Test.startTest();   
            Customer_Owned_Unit__c couRec = [Select id, NITC_Claimed_Manually__c, Sales_Tax_Credit__c from Customer_Owned_Unit__c where Unit_Type__c = 'STOCK' LIMIT 1][0];
            couRec.NITC_Claimed_Manually__c = true;
            couRec.NITC_Date_Claimed__c = system.today();
            update couRec;
            List<Customer_Owned_Unit__c> couList = [Select id from Customer_Owned_Unit__c limit 1];
            system.assertEquals(1, couList.size());
            Test.stopTest();
        }
        
    }