@isTest
    private class SyncVendorReceivingBatchTest {
        @TestSetup
        private static void setup(){
            IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
            insert new Configurations__c(Accrue_Trade_Tax_Until_Unit_Sold__c = true);
            insert new General_Configurations__c(Enable_Xero_Accounting__c = true);
            List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
            IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForXero('Journal Entry' , IFWConfigObjList[0].Id);
        }
        @isTest
        private static void testSyncVendorReceivingBatch() {
            Vendor_Receiving_Header__c vendorReceivingHeader = new Vendor_Receiving_Header__c(Receiving_Total__c = 123, Status__c = 'In Progress');
            insert vendorReceivingHeader;
            Test.setMock(HttpCalloutMock.class, new Xero_MockHttpResponseGenerator());
            Test.startTest();  
            Vendor_Receiving_Header__c vendorRecivingHeaderRec = [Select Id, Status__c from Vendor_Receiving_Header__c LIMIT 1][0];
            vendorRecivingHeaderRec.Status__c = 'Stocked';
            update vendorRecivingHeaderRec;
            List<Vendor_Receiving_Header__c> vrHeaderList = [Select id from Vendor_Receiving_Header__c limit 1];
            system.assertEquals(1, vrHeaderList.size());
            Test.stopTest();
        }
        
    }