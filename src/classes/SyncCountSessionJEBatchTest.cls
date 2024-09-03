@isTest
    private class SyncCountSessionJEBatchTest {
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
        private static void testSyncCountSessionJEBatch() {
            Count_Session__c newCountSession = new Count_Session__c(name__c = 'balveer', Count_Date_Time__c=date.today());
            insert newCountSession;
            Count_Session_Line_Item__c CountSessionLineItem = new Count_Session_Line_Item__c(Count_Session__c = newCountSession.id, Total_Cost_Adjustment__c = 123.9);
            insert CountSessionLineItem;
            Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
            Test.startTest();   
            List<Count_Session__c> countSessionRec = new List<Count_Session__c>();
            List<Count_Session__c> CountSession = [select id, name__c, Status__c, Net_Adjustment_After_Finalize__c from Count_Session__c];
            CountSession[0].name__c = 'jay';
            CountSession[0].Status__c = 'Closed';
            countSessionRec.add(CountSession[0]);
            update countSessionRec;
            List<Count_Session__c> arPaymentList = [Select id from Count_Session__c limit 1];
            system.assertEquals(1, arPaymentList.size());
            Test.stopTest();
        }
        
    }