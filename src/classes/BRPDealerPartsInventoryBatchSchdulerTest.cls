@isTest
private class BRPDealerPartsInventoryBatchSchdulerTest {

    public class BRPDealerPartsInventoryPositiveRespone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('"status": "success","filename": "dealer_inventory_update_api_v2_delta_20230502_142707Z_8f75c22c-f6da-419f-b17d-4653869df9d9.json.gz"');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }

    public class BRPDealerPartsInventoryNegativeRespone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": 401,"id": "rrt-0b8f470f8a6f5fd93-d-ea-19151-78124536-2", "title": "unauthorized", "meta": {"service": "05", "detail": "Please verify your credentials or the Bearer token you provided. Contact the DCP team if you need further assistance."}}');
            res.setStatusCode(401);
            res.setStatus('error');
            return res;
        }
    }
    
    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks(); 
        IFW_IntegrationConfig__c ifwConfigBRP = TestDataFactory.createIFWConfigForBRP();
        IFW_IntegrationConfig__c ifwConfigBRP2 = TestDataFactory.createIFWConfigForBRP2();
        IFW_IntegrationConfigItem__c ifwConfigItem = TestDataFactory.createIFWConfigItemForBRP2('Dealer Inventory', ifwConfigBRP2.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForBRP2('Token', ifwConfigBRP2.Id);
        BRP_Settings__c brpConfig = TestDataFactory.createBRPConfig();
        Account vendor = TestUtil.createVendor(true, 'brp');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        Part__c part = TestUtil.createPart(true, 'partNumberP01', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);      
        Part__c part1 = TestUtil.createPart(true, 'partNumberP011', vendor.Id, 'Test Part1', testCategory.Id, 10, 220, 530, 100, 100);
        
        BRP_Vendors_List__c brpVendorListRec = new BRP_Vendors_List__c();
        brpVendorListRec.Is_Active_Vendor__c = true;
        brpVendorListRec.Name = vendor.Id;
        brpVendorListRec.Type__c = 'Vendor';
        insert brpVendorListRec;
    }

    @isTest
    private static void testRunAt11PM() { 
        Test.setMock(HttpCalloutMock.class, new BRPDealerPartsInventoryPositiveRespone());
        Test.startTest();
        BRPDealerPartsInventoryBatchScheduler.runAt11PM();
        Test.stopTest();
        List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'BRP Part Inventory Scheduler%'];
        System.assertEquals(1, existingSheduledJobs.size());
    }

    @isTest
    private static void testBRPDealerPartsInventoryPositiveRespone() { 
        Test.setMock(HttpCalloutMock.class, new BRPDealerPartsInventoryPositiveRespone());
        Test.startTest();
        Database.executeBatch(new BRPDealerPartsInventoryBatchScheduler(), 2000);
        Test.stopTest();
        List<WebService_Log__c> webServiceList = [SELECT Id FROM WebService_Log__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'BRP 2.0'];
        List<BRP_log__c> brpLogList = [SELECT Id FROM BRP_log__c WHERE Apex_Class__c = 'BRPDealerPartsInventoryBatchScheduler'];
        System.assertEquals(0, brpLogList.size());
        System.assertEquals(1, webServiceList.size());
    }

    @isTest
    private static void testBRPDealerPartsInventoryNegativeRespone() { 
        Test.setMock(HttpCalloutMock.class, new BRPDealerPartsInventoryNegativeRespone());
        Test.startTest();
        Database.executeBatch(new BRPDealerPartsInventoryBatchScheduler(), 2000);
        Test.stopTest();
        List<WebService_Log__c> webServiceList = [SELECT Id FROM WebService_Log__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'BRP 2.0'];
        List<BRP_log__c> brpLogList = [SELECT Id FROM BRP_log__c WHERE Apex_Class__c = 'BRPDealerPartsInventoryBatchScheduler'];
        System.assertEquals(1, brpLogList.size());
        System.assertEquals(1, webServiceList.size());
    }

}