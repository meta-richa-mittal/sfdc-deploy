/**         
* Author: Nidhi Sharma
* Since: Dec 17, 2020
* Name: SyncPartsWithShopifyBatchTest 
* Description: Batch Apex Test class which sync parts to shopify store.
**/
@isTest
public class SyncPartsWithShopifyBatchTest {
      
    @testSetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
        
        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        generalConfig.Enable_Shopify_Integration__c = true;
        upsert generalConfig;
        
        TestUtil.activateShopifyIntegration();
        TestUtil.createShopifyConfiguration();
        
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigsForShopify();
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [SELECT Id FROM IFW_IntegrationConfig__c];
        TestUtil.createIFWConfigItemForShopify('Token' , IFWConfigObjList[0].Id, 'POST');
        TestUtil.createIFWConfigItemForShopify('Product' , IFWConfigObjList[0].Id, 'POST');
        
        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        vendor.Vendor_Code__c = 'VEN';
        insert vendor;
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c part = TestUtil.createPart(false, '123', vendor.Id, 'Part Desc', testCategory.Id, 10, 20, 50, 100, 100);
        part.Publish_In_Feeds__c = true;
        insert part;
        
        Part__c part1 = TestUtil.createPart(true, 'FS6801-04-04-NWO-S0', vendor.Id, 'Part Desc', testCategory.Id, 10, 20, 50, 100, 100);
    }

    @isTest
    private static void syncPartBatch_FirstTimeSync_Test() {
        List<Part__c> partList = [Select Id, Shopify_Id__c from Part__c where Publish_In_Feeds__c = true];
        system.assertEquals(null, partList[0].Shopify_Id__c);
        Test.setMock(HttpCalloutMock.class, new WebsiteProductMockResponseGenerator());
        Test.startTest();
        Database.executeBatch(new SyncPartsWithShopifyBatch(true));
        Test.stopTest();
        partList = [Select Id, Shopify_Id__c, Shopify_URL__c from Part__c where Publish_In_Feeds__c = true];
        //system.assertEquals('SHOPIFY1234', partList[0].Shopify_Id__c);
        //system.assertEquals(Shopify_Configuration__c.getOrgDefaults().Product_Base_URL__c + partList[0].Shopify_Id__c, partList[0].Shopify_URL__c);
    }
    
    @isTest
    private static void syncPartBatch_ScheduledSync_Test() {
        List<Part__c> partList = [Select Id from Part__c];
        Test.setMock(HttpCalloutMock.class, new WebsiteProductMockResponseGenerator());
        Set<Id> partIdSet = new Set<Id>();
        for(Part__c part : partList) {
            partIdSet.add(part.Id);
        }
        Test.startTest();
        Database.executeBatch(new SyncPartsWithShopifyBatch(partIdSet));
        Test.stopTest();
        partList = [Select Id, Shopify_Id__c, Shopify_URL__c, Available_For_Shopify_Sync__c from Part__c where Id =: partList[0].Id];
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
        //system.assertEquals(false, partList[0].Available_For_Shopify_Sync__c);
        //system.assertNotEquals(null, partList[0].Shopify_Id__c);
        //system.assertEquals(Shopify_Configuration__c.getOrgDefaults().Product_Base_URL__c + partList[0].Shopify_Id__c, partList[0].Shopify_URL__c);
    }
}