@isTest
global without sharing class QB_SyncVendorRecevingBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }
    
    static testMethod void vendorRecevingPayload(){
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Journal Entry' , IFWConfigObj[0].Id);
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        BPScriptUtility.disbaleTrigger('PartFIFOBucketTrigger');
        BPScriptUtility.disbaleTrigger('CategoryTrigger');
        BPScriptUtility.disbaleTrigger('PartTrigger');
        Account vendor = TestDataFactory.createVendor('vendorName');
        Category__c catRec = TestDataFactory.createCategory('categoryName');
        Part__c partRec = TestDataFactory.createPart(vendor.Id, 10, 12, 15, 13, 2, catRec.Id);
        Part_Fifo_Bucket__c partBucketRec = TestDataFactory.createPartFifoBucket(partRec.Id);
        Vendor_Invoicing_Header__c vendorInvoiceHeaderRec = TestDataFactory.createVIHeader(vendor.Id,'Completed');
        Vendor_Receiving_Header__c vendorRecevingRec = TestDataFactory.createVendorReceivingHeader(vendorInvoiceHeaderRec.Id, vendor.Id);
        vendorRecevingRec.Receiving_Total__c = 100;
        vendorRecevingRec.Status__c = 'Stocked';
        update vendorRecevingRec;

        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();

        String query = 'SELECT availForQBJournalEntrySync__c From Vendor_Receiving_Header__c';
        Vendor_Receiving_Header__c vendorRecRecord = Database.query(query);
        System.assertEquals(vendorRecRecord.availForQBJournalEntrySync__c, false);
    }

}