@isTest
private class BRPArticleApiTest {
    public class BRPArticleApiPositiveRespone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"last_publish_date": "2013-09-03T18:51:50Z","content_type": "PDF","content": "JVBERi0xLjYNJeLjz9MNCjEwMyAwIG9iag08PC9MaW5lYXJpemVkIDEvTCAxMjYxNzkvTyAxMDUvRSAxMDI2MDMvTiAyL1QgMTI1ODEzL0ggWyA1MTcgMjQ1XT4+DWVuZG9iag0gICAgICAgICAgICAgDQoxMjQgMCBvYmoNPDwvRGVjb2RlUGFybXM8PC9Db2x1bW5zIDUvUHJlZGljdG9yIDEyPj4vRmlsdGVyL0ZsYXRlRGVjb2RlL0lEWzwxOEZDNUQ3RjAyNkM1RTMxRTFCRUU2MTkzREQ2REE3Qj48RTU4Rjc0RDBBQjY4NkY0OUIzMzhFMEIyOEFBNUM0RDg+XS9JbmRleFsxMDMgNDFdL0luZm8gMTAyIDAgUi9MZW5ndGggMTA4L1ByZXYgMTI1ODE0L1Jvb3QgMTA0IDAgUi9TaXplIDE0NC9UeXBlL1hSZWYvV1sxIDMgMV0+PnN0cmVhbQ0KaN5iYmRgEGBgYmBgegUiGRPA5H4QydoMIpnvg2X9wWwhEMliA2aDdTHLgkktEMnTDWZHgEiGFBDJfwxEGvqCyGgXIMmYWwRiG20AkRqFQPJ","article_url": "brp--qacopy--c.sandbox.vf.force.com/apex/Article_Detail_Warranty_Bulletin?lang=fr&id=kAA30000000GmjdGAC", "article_no": "000020951", "article_descr": "PWC 2010-5 Mécanisme iCatch Arrimant Peut-Être pas Adéquatement la Motomarine_000020951_WCN21Y010S99_fr"}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }

    public class BRPArticleApiNegativeRespone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "404","id": "rrt-00a574511a562afb5-b-ea-22206-2601758-1.1","title": "not_found", "meta": {"service": "03","detail": "Backend error","payload": { "status": "404","errors": [ {"title": "Article 123456789 was not found","code": "not_found"}]}}}');
            res.setStatusCode(404);
            res.setStatus('error');
            return res;
        }
    }

    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks(); 
        IFW_IntegrationConfig__c ifwConfigBRP = TestDataFactory.createIFWConfigForBRP();
        IFW_IntegrationConfig__c ifwConfigBRP2 = TestDataFactory.createIFWConfigForBRP2();
        IFW_IntegrationConfigItem__c ifwConfigItem = TestDataFactory.createIFWConfigItemForBRP2('GetArticle', ifwConfigBRP2.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForBRP2('Token', ifwConfigBRP2.Id);
        BRP_Settings__c brpConfig = TestDataFactory.createBRPConfig();
    }

    @isTest
    private static void testArticleApiForPositiveRes() { 
        Test.setMock(HttpCalloutMock.class, new BRPArticleApiPositiveRespone());
        Test.startTest();
        BRPArticleResponseWrapper result = BRPUnitSpecificationsService.getArticleByArticleNo('3JBLGAR15GJ000100');
        Test.stopTest();
        List<WebService_Log__c> webServiceList = [SELECT Id FROM WebService_Log__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'BRP 2.0'];
        List<BRP_log__c> brpLogList = [SELECT Id FROM BRP_log__c WHERE Apex_Class__c = 'BRPUnitSpecificationsService'];
        System.assertEquals(0, brpLogList.size());
        System.assertEquals(1, webServiceList.size());
        System.assertEquals('PDF', result.SuccessResponse.content_type);
    }

    @isTest
    private static void testArticleApiForNegativeRes() { 
        Test.setMock(HttpCalloutMock.class, new BRPArticleApiNegativeRespone());
        Test.startTest();
        BRPArticleResponseWrapper result = BRPUnitSpecificationsService.getArticleByArticleNo('123456789');
        Test.stopTest();
        List<WebService_Log__c> webServiceList = [SELECT Id FROM WebService_Log__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'BRP 2.0'];
        System.assertEquals(1, webServiceList.size());
        System.assertEquals('Article 123456789 was not found', result.ErrorResponse.errors[0].title);
    }

    @isTest
    private static void testArticleApiForNullArticleNumber() { 
        Test.startTest();
        try{
            BRPUnitSpecificationsService.getArticleByArticleNo(null);
        } catch (Exception e) {
            System.assertEquals('Article number can\'t be empty or greater than 18.', e.getMessage());
        }
        Test.stopTest();
    }

}