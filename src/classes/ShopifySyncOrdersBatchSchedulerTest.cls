/** 
* Author: Reena Singh
* Since: Feb 10, 2020
* Name: ShopifySyncOrdersBatchSchedulerTest 
* Description: Batch Apex Test class which sync orders to shopify store.
**/
@isTest
public class ShopifySyncOrdersBatchSchedulerTest {
    private static String partNumber = 'FS6801-04-04-NWO-SS';
    private static String vendorCode = 'HCM';
    
    @testSetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
    	TestUtil.activateShopifyIntegration();
    	
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigsForShopify();
        
        List<IFW_IntegrationConfigItem__c> configItemsToInsert = new List<IFW_IntegrationConfigItem__c>();
        configItemsToInsert.add(createIFWConfigItem('Token', IFWConfigObj.Id, 'https://super-connector.us.auth0.com/oauth/token'));
        configItemsToInsert.add(createIFWConfigItem('Shopify Order', IFWConfigObj.Id, 'https://api.super-connectors.com/order'));
        insert configItemsToInsert;
        
        TestUtil.createShopifyConfiguration();
        
        Account vendor = TestUtil.createVendor(false, 'Test Vendor');
        vendor.Vendor_Code__c = vendorCode;
        insert vendor;
        
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Fee__c feeRec = TestUtil.createFee(true, true, testCategory.Id, 'FeeCode', null, 'Description', 100, true);
        
        Configurations__c config = Configurations__c.getOrgDefaults();
    	config.Shopify_Fee_Id__c = feeRec.Id;
    	upsert config;
    }
    
    private static IFW_IntegrationConfigItem__c createIFWConfigItem(String entityName, String IFWConfigId, String endpoint) {
    	IFW_IntegrationConfigItem__c IFWConfigItemObj = new IFW_IntegrationConfigItem__c();
        IFWConfigItemObj.HTTP_Method__c = 'GET';
        IFWConfigItemObj.Timeout__c = 5000;
        IFWConfigItemObj.IFW_IntegrationConfig__c = IFWConfigId;
        IFWConfigItemObj.Entity_Name__c = entityName;
     	IFWConfigItemObj.Endpoint_URL__c = endpoint;
     	return IFWConfigItemObj;
    }
    
    @isTest
    private static void ShopifySyncOrdersBatchTest() {
    	Test.setMock(HttpCalloutMock.class, new ShopifyMockResponseGenerator());
		Test.startTest();
		Database.executeBatch(new ShopifySyncOrdersBatchScheduler());
		Test.stopTest();
		List<CO_Header__c> coList = [Select Id from CO_Header__c];
		system.assertEquals(3, coList.size());
    }
    
    public class ShopifyMockResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if(req.getEndpoint().contains('https://super-connector.us.auth0.com/oauth/token')) {
            	res.setBody('{"access_token": "eyJhbGciOiJSUzI1NiIsIn","scope": "access:product access:order","expires_in": 86400,"token_type": "Bearer"}');
            } else if(req.getEndpoint().contains('https://api.super-connectors.com/product')) {
	            res.setBody('[{"shopifyID": "6060527157421","productNumber": "' + partNumber + '","vendorCode": "' + vendorCode + '"}]');
            } else if(req.getEndpoint().contains('https://api.super-connectors.com/order')) {
                res.setBody('{"cursor":"eyJsYXN0X2lkIjozMjYyMjAwNDc5OTM3LCJsYXN0X3ZhbHVlIjoiMjAyMS0wMi0wOCAwNjo1NzowNC41NTQyNTAifQ==","hasNextPage":false,"orders":[{"shopifyId":"3261339861185","orderNumber":"#1019","customer":{"shopifyId":"4663399416001","firstName":"Test without Last last","lastName":"","company":null,"address1":null,"address2":null,"city":null,"province":null,"provinceCode":null,"country":null,"countryCode":null,"postalZip":null,"phone":null,"email":null,"locale":"en","note":"test notes from shopify","acceptsMarketing":false,"tags":null},"discount":0.0,"shippingCharge":0.0,"totalTax":13.32,"total":124.27,"createdAt":"2021-02-07T18:43:03+00:00","updatedAt":"2021-02-07T18:43:05+00:00","lineItems":[{"shopifyId":"9233253007553","productShopifyId":"6164749942977","productNumber":"BPTestPart001","vendorCode":"VC1","quantity":1,"price":10.95,"discount":0.0,"total":10.95,"taxable":true,"taxLines":[{"title":"GST","rate":0.05,"tax":0.55},{"title":"PST","rate":0.07,"tax":0.77}]},{"shopifyId":"9233253040321","productShopifyId":"6275727425729","productNumber":"","vendorCode":"","quantity":1,"price":100.0,"discount":0.0,"total":100.0,"taxable":true,"taxLines":[{"title":"GST","rate":0.05,"tax":5.0},{"title":"PST","rate":0.07,"tax":7.0}]}],"taxLines":[{"title":"PST","rate":0.07,"tax":7.77},{"title":"GST","rate":0.05,"tax":5.55}]},{"shopifyId":"3262198513857","orderNumber":"#1020","customer":null,"discount":0.0,"shippingCharge":0.0,"totalTax":2.63,"total":24.53,"createdAt":"2021-02-08T06:55:22+00:00","updatedAt":"2021-02-08T06:55:22+00:00","lineItems":[{"shopifyId":"9234778423489","productShopifyId":"6164749942977","productNumber":"BPTestPart001","vendorCode":"VC1","quantity":2,"price":10.95,"discount":0.0,"total":21.9,"taxable":true,"taxLines":[{"title":"GST","rate":0.05,"tax":1.1},{"title":"PST","rate":0.07,"tax":1.53}]}],"taxLines":[{"title":"PST","rate":0.07,"tax":1.53},{"title":"GST","rate":0.05,"tax":1.1}]},{"shopifyId":"3262200479937","orderNumber":"#1021","customer":{"shopifyId":"4538019741889","firstName":"John2","lastName":"Smith","company":"","address1":"1120 Hamilton Street","address2":"","city":"Vancouver","province":"British Columbia","provinceCode":"BC","country":"Canada","countryCode":"CA","postalZip":"V6B 2S2","phone":"+12505450531","email":"johns123@dealervu.com","locale":"en","note":"","acceptsMarketing":false,"tags":null},"discount":0.0,"shippingCharge":0.0,"totalTax":18.0,"total":168.0,"createdAt":"2021-02-08T06:57:04+00:00","updatedAt":"2021-02-08T06:57:06+00:00","lineItems":[{"shopifyId":"9234780782785","productShopifyId":"6202362101953","productNumber":"New PFI Part 1","vendorCode":"TES299","quantity":1,"price":150.0,"discount":0.0,"total":150.0,"taxable":true,"taxLines":[{"title":"GST","rate":0.05,"tax":7.5},{"title":"PST","rate":0.07,"tax":10.5}]}],"taxLines":[{"title":"PST","rate":0.07,"tax":10.5},{"title":"GST","rate":0.05,"tax":7.5}]}]}');
            }
            return res;
        }
    }
}