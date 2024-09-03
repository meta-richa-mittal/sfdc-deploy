@isTest
global without sharing class QB_SyncVendorInvoicingBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
        List<customHttpHeaderWrapper> headerList = new List<customHttpHeaderWrapper>();
        customHttpHeaderWrapper header = new customHttpHeaderWrapper('Content-Type', 'applications/json');
        headerList.add(header);
    }
    static testMethod void vendorInvoicePayload(){
        Test.startTest();
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Vendor Credit' , IFWConfigObj[0].Id);
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        BPScriptUtility.disbaleTrigger('PartFIFOBucketTrigger');
        BPScriptUtility.disbaleTrigger('CategoryTrigger');
        BPScriptUtility.disbaleTrigger('PartTrigger');
        Account vendor = TestDataFactory.createVendor('vendorName');
        Category__c catRec = TestDataFactory.createCategory('categoryName');
        Part__c partRec = TestDataFactory.createPart(vendor.Id, 10, 12, 15, 13, 2, catRec.Id);
        Part_Fifo_Bucket__c partBucketRec = TestDataFactory.createPartFifoBucket(partRec.Id);
        Vendor_Invoicing_Header__c vendorInvoiceHeaderRec = TestDataFactory.createVIHeader(vendor.Id,'Completed');
        vendorInvoiceHeaderRec.Status__c = 'Invoiced';
        vendorInvoiceHeaderRec.Total__c = -30;
        update vendorInvoiceHeaderRec;
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
   		Test.stopTest();

        String query = 'SELECT availForQBSync__c From Vendor_Invoicing_Header__c';
        Vendor_Invoicing_Header__c vendorinvoiceRecord = Database.query(query);
        System.assertEquals(vendorinvoiceRecord.availForQBSync__c, false);
    }
}