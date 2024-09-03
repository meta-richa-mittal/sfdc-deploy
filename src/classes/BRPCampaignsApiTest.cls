@isTest
private class BRPCampaignsApiTest {
    public class BRPCampaignsApiPositiveRespone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"serial_no": "2BPSMXKF5KV000020","usage_descr": "Personal/Recreational","product_code": "000MXKF00","platform_descr": "REV-G4","model_year": 2019,"model_descr": "MXZ","brand_descr": "Ski-Doo Snowmobile","package_descr": "X rs","color_descr": "Black","length": "129","engine_type": "850 E-TEC","target_market_descr": "Canada, US","is_cross_border": true,"comments": "This unit was purchased in another country, normal warranty coverage is voided. Warranty coverage may be valid upon confirmation customer is a tourist, documentation will be requested.","campaigns": [{"type_descr": "Regular","period_valid_to": "2024-06-08","period_valid_from": "2023-08-16","is_claimed": false, "campaign_no": "9890", "campaign_descr": "TEST12","bulletin_no": "","articles": []},{"type_descr": "Regular","period_valid_to": "2022-01-31","period_valid_from": "2019-01-22", "is_claimed": true,"campaign_no": "0010","campaign_descr": "ENGINE COOLANT OUTLET HOSE LEAK","bulletin_no": "2019-9","articles": [{"last_publish_date": "2019-03-11T17:10:42Z","content_type": "PDF","article_url": "brp--qacopy.sandbox.my.salesforce-sites.com/kAA0c000000fxSR?lang=en_US","article_no": "000136062","article_descr": "SKI-DOO 2019-9 Engine Coolant Outlet Hose Leak_136062_WCN11Y019S01_en"}]}]}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }

    public class BRPCampaignsApiNegativeRespone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "400","id": "rrt-0ef8248cf88949471-c-ea-11756-1483377-1.1","title": "not_found","meta": { "service": "03","detail": "VIN YDV40501Afff was not found","payload": {"errors": [{"title": "VIN YDV40501Afff was not found","code": "not_found" }]}} }');
            res.setStatusCode(400);
            res.setStatus('error');
            return res;
        }
    }

    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks(); 
        IFW_IntegrationConfig__c ifwConfigBRP = TestDataFactory.createIFWConfigForBRP();
        IFW_IntegrationConfig__c ifwConfigBRP2 = TestDataFactory.createIFWConfigForBRP2();
        IFW_IntegrationConfigItem__c ifwConfigItem = TestDataFactory.createIFWConfigItemForBRP2('GetCampaigns', ifwConfigBRP2.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForBRP2('Token', ifwConfigBRP2.Id);
        BRP_Settings__c brpConfig = TestDataFactory.createBRPConfig();
    }

    @isTest
    private static void testCampaignsApiForPositiveRes() { 
        Test.setMock(HttpCalloutMock.class, new BRPCampaignsApiPositiveRespone());
        Test.startTest();
        BRPCampaignResponseWrapper result = BRPUnitSpecificationsService.getCampaignsByVIN('2BPSCEKCXKV000009');
        Test.stopTest();
        List<WebService_Log__c> webServiceList = [SELECT Id FROM WebService_Log__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'BRP 2.0'];
        List<BRP_log__c> brpLogList = [SELECT Id FROM BRP_log__c WHERE Apex_Class__c = 'BRPUnitSpecificationsService'];
        System.assertEquals(0, brpLogList.size());
        System.assertEquals(1, webServiceList.size());
        System.assertEquals(2, result.SuccessResponse.campaigns.size());
    }

    @isTest
    private static void testCampaignsApiForNegativeRes() { 
        Test.setMock(HttpCalloutMock.class, new BRPCampaignsApiNegativeRespone());
        Test.startTest();
        BRPCampaignResponseWrapper result = BRPUnitSpecificationsService.getCampaignsByVIN('3JBLGAR15GJ000100');
        Test.stopTest();
        List<WebService_Log__c> webServiceList = [SELECT Id FROM WebService_Log__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'BRP 2.0'];
        System.assertEquals(1, webServiceList.size());
        System.assertEquals('VIN YDV40501Afff was not found', result.ErrorResponse.errors[0].title);
        System.assertEquals('not_found', result.ErrorResponse.errors[0].code);
    }

    @isTest
    private static void testCampaignsApiForLargeVinNumber() { 
        Test.startTest();
        try{
            BRPUnitSpecificationsService.getCampaignsByVIN('123qweasdzxc098poilkj');
        } catch (Exception e) {
            System.assertEquals('Vin number can\'t be empty or greater than 18.', e.getMessage());
        }
        Test.stopTest();
    }

}