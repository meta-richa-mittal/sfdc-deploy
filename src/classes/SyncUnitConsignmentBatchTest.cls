@isTest
    private class SyncUnitConsignmentBatchTest {
        @TestSetup
        private static void setup(){
            TestDataFactory.disableFLSChecks();
            IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
            insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
            List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
            IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
            Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
            customer.Is_Customer__c = true;
            customer.Xero_Customer_Accounting_Id__c = '6d037ca7-113b-4919-b4dd-22432503e76a';
            insert customer;
        }
        @isTest
        private static void testSyncUnitConsignmentBatch() {
            Customer_Owned_Unit__c insertCOU = new Customer_Owned_Unit__c(consignment__c = true, Unit_Type__c = 'COU', Status__c = 'Active', VIN_Number__c = '1234', Suggested_price__c = 20, Agreed_payout__c = 12);
            insert insertCOU;
            Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
            Test.startTest();   
            Customer_Owned_Unit__c couRec = [Select id, Status__c from Customer_Owned_Unit__c LIMIT 1][0];
            couRec.Status__c = 'Transferred';
            update couRec;
            List<Customer_Owned_Unit__c> couList = [Select id from Customer_Owned_Unit__c limit 1];
            system.assertEquals(1, couList.size());
            Test.stopTest();
        }
        
    }