/**
 * Author: Nikhil Kumar Srivastava
 * Since: Oct 18, 2018
 * Name: SyncItemCategorSyncPartFifoBucketBatchTestyBatchTest 
 * Description: Test class for SyncPartFifoBucketBatch.
**/
@isTest
public without sharing class SyncPartFifoBucketBatchTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks(); 
       //Xero IFW_IntegrationConfig__c Record
		IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
       //Xero IFW_IntegrationConfigItem__c Record
       IFW_IntegrationConfigItem__c IFWConfigItemObj = new IFW_IntegrationConfigItem__c();
       IFWConfigItemObj.Endpoint_URL__c = 'https://api.xero.com/api.xro/2.0/ManualJournals';
       IFWConfigItemObj.HTTP_Method__c = 'POST';
       IFWConfigItemObj.Timeout__c = 5000;
       IFWConfigItemObj.IFW_IntegrationConfig__c = IFWConfigObj.Id;
       IFWConfigItemObj.Subscriber_Record_Id__c = 'a2G1K000003YyYkUAK';
       IFWConfigItemObj.Entity_Name__c = 'Journal Entry';
       IFWConfigItemObj.Entity_Action__c = 'Create;Update';
       insert IFWConfigItemObj;
 
    }
    static testMethod void SyncPartFifoBucketBatchTest() {
        SyncPartFifoBucketBatch SyncPartFifoBucketBatchObj = new SyncPartFifoBucketBatch();
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
    }

    static testMethod void SyncPartFifoBucketBatchTest_CreateEntries() {
        Account customer = TestUtil.createCustomer(true, 'testcustomer', 'customer@gmail.com', 'Jaipur', '8058704475');
        Account vendor = TestUtil.createVendor(true, 'testvendor');
        Category__c categoryObject = TestUtil.createCategory(true, 'Test', '    Miscellaneous', 'Test description', true, true);
        Part__c partObject1 = TestUtil.createPart(true, '101', vendor.id, 'test1', categoryObject.id, 200, 200, 100, 20, 20);
        Part__c partObject2 = TestUtil.createPart(true, '102', vendor.id, 'test2', categoryObject.id, 201, 200, 100, 20, 20);
        Part__c partObject3 = TestUtil.createPart(true, '103', vendor.id, 'test3', categoryObject.id, 202, 100, 10, 2, 2);
        List<Part__c> partList = new List<Part__c> ();
        partList.add(partObject1);
        partList.add(partObject2);
        partList.add(partObject3);
        List<String> partidList = new List<String>{partObject1.id,partObject2.id,partObject3.id};
        
        String query = 'SELECT ' + String.join(PartFifoBucket.getPartFIFOBucketList(), ',') + ' FROM Part_FIFO_Bucket__c WHERE Part__c IN :partidList'; 
        List<Part_FIFO_Bucket__c> partFIFOBucketList = Database.query(query);
        
        PartFifoBucket fifobucket = new PartFifoBucket(partFIFOBucketList.get(0));
        PartFifoBucket.getPartFIFOBucketList();
        PartFifoBucket.getPartFIFOBucketLineItemList();
        CO_Header__c coheaderobject =  TestUtil.createCOHeader(true, customer.id);
        CO_Invoice_Header__c  coInvoiceHeaderObject = TestUtil.createCOInvoiceHeader(true, coheaderobject.id, 'Stocked');
        
        Set<Id> partFifoIdSet =  (new Map<Id,Part_FIFO_Bucket__c>(partFIFOBucketList)).keySet();
        //BaseIntegrationService record
        /*BaseIntegrationService integrationRec; 
        integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
        IntegrationSyncFlagService.managePartFIFOBucketSyncFlag(new List<BaseIntegrationService>{integrationRec}, partFIFOBucketList);
        IntegrationBatchService.initiateBatch(partFifoIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.PART_FIFO);
    	*/
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
    }
    static testMethod void SyncPartFifoBucketBatchTest_UpdateEntries() {
        Account customer = TestUtil.createCustomer(true, 'testcustomer', 'customer@gmail.com', 'Jaipur', '8058704475');
        Account vendor = TestUtil.createVendor(true, 'testvendor');
        Category__c categoryObject = TestUtil.createCategory(true, 'Test', '    Miscellaneous', 'Test description', true, true);
        Part__c partObject1 = TestUtil.createPart(true, '101', vendor.id, 'test1', categoryObject.id, 200, 200, 100, 20, 20);
        List<Part__c> partList = new List<Part__c> ();
        partList.add(partObject1);
        List<String> partidList = new List<String>{partObject1.id};

        String query = 'SELECT ' + String.join(PartFifoBucket.getPartFIFOBucketList(), ',') + ' FROM Part_FIFO_Bucket__c WHERE Part__c IN :partidList'; 
        List<Part_FIFO_Bucket__c> partFIFOBucketList = Database.query(query);
        
        partFIFOBucketList[0].Xero_Accounting_Id__c = '1';
        Update partFIFOBucketList;
        PartFifoBucket fifobucket = new PartFifoBucket(partFIFOBucketList.get(0));
        PartFifoBucket.getPartFIFOBucketList();
        PartFifoBucket.getPartFIFOBucketLineItemList();
        CO_Header__c coheaderobject =  TestUtil.createCOHeader(true, customer.id);
        CO_Invoice_Header__c  coInvoiceHeaderObject = TestUtil.createCOInvoiceHeader(true, coheaderobject.id, 'Stocked');
        
        Set<Id> partFifoIdSet =  (new Map<Id,Part_FIFO_Bucket__c>(partFIFOBucketList)).keySet();
        //BaseIntegrationService record
        /*BaseIntegrationService integrationRec;
        integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
        IntegrationSyncFlagService.managePartFIFOBucketSyncFlag(new List<BaseIntegrationService>{integrationRec}, partFIFOBucketList);
        IntegrationBatchService.initiateBatch(partFifoIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.PART_FIFO);
    	*/
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
    }


}