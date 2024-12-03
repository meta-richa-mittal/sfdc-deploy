@isTest
global class VendorMasterSubscriberCtrlTest {
	
	@testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
    	LMA_Config__c lmaConfig = LMA_Config__c.getOrgDefaults();
    	lmaConfig.Client_Id__c = '3MVG9Z8h6Bxz0zc4xEvbwlKEZ0Tdjp1fpbbP903heXt9zjCDHtmiAGKdT0LqRws.vRXounsKpnhv0y8jLjUfG';
    	lmaConfig.Client_Secret__c = '2CB76DDC97EC788D6AF4D34FD6F8A4884CBE5A56A687C90783928E79005B7902';
    	lmaConfig.End_Point__c = 'https://test.salesforce.com';
    	lmaConfig.Password__c = 'V2VsY29tZUAxMjM0NSM=';
    	lmaConfig.Security_Token__c = 'jAked8zTunbmliCC5x9r2SvZC';
    	lmaConfig.Username__c = 'bWN1YmVfYWRtaW5AYmxhY2twdXJsLmNvbS5JQ1NERVYwMQ==';
    	insert lmaConfig;
    }
    
    @isTest
	private static void subscribeToVendorMasterFromPartnerOrgTest() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Test.startTest();
		VendorMasterSubscriberCtrl.subscribeToVendorMasterFromPartnerOrg(new Set<String>{'VM-00000001', 'VM-00000004', 'VM-00000002', 'VM-00000003'});
		Test.stopTest();
		List<Vendor_Master__c> vendorMasterList = [Select Id FROM Vendor_Master__c];
		System.assertEquals(3, vendorMasterList.size());
		
		List<Log__c> logList = [Select Id from Log__c];
		System.assertEquals(1, logList.size());
	}
	
    global class MockHttpResponseGenerator implements HttpCalloutMock {
    	// Implement this interface method
		global HTTPResponse respond(HTTPRequest req) {
			// Optionally, only send a mock response for a specific endpoint
			// and method.
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			if(req.getEndpoint().substring(req.getEndpoint().lastIndexOf('/')+1) == 'token') {
				res.setBody('{"access_token":"SESSION_ID_REMOVED","instance_url":"https://na96.salesforce.com","id":"https://login.salesforce.com/id/00D41000000ezKnEAI/00541000005cc60AAA","token_type":"Bearer","issued_at":"1583233133580","signature":"EeGo0V6tDp5FYJIBcnG70iKFrP7U74IFs2kDNDEBCjM="}');
			}
			else {
				res.setBody('[{"ResponseStr":"{\\"VendorName\\":\\"HONDA Aus\\",\\"VendorMasterUID\\":\\"VM-00000001\\",\\"SKUNum\\":false,\\"Replaces\\":false,\\"ReplacedBy\\":true,\\"Price\\":false,\\"PkgQty\\":false,\\"PartNum\\":false,\\"OtherPrice\\":false,\\"OtherCost\\":false,\\"MFGNum\\":false,\\"DescriptionFR\\":false,\\"DescriptionEN\\":false,\\"Cost\\":false,\\"Category\\":null}","Message":"success"},{"ResponseStr":"{\\"VendorName\\":\\"HONDA US\\",\\"VendorMasterUID\\":\\"VM-00000004\\",\\"SKUNum\\":false,\\"Replaces\\":true,\\"ReplacedBy\\":true,\\"Price\\":false,\\"PkgQty\\":false,\\"PartNum\\":true,\\"OtherPrice\\":false,\\"OtherCost\\":true,\\"MFGNum\\":true,\\"DescriptionFR\\":false,\\"DescriptionEN\\":true,\\"Cost\\":true,\\"Category\\":\\"Testing\\"}","Message":"success"},{"ResponseStr":"{\\"VendorName\\":\\"HONDA Can\\",\\"VendorMasterUID\\":\\"VM-00000002\\",\\"SKUNum\\":false,\\"Replaces\\":false,\\"ReplacedBy\\":false,\\"Price\\":false,\\"PkgQty\\":false,\\"PartNum\\":true,\\"OtherPrice\\":false,\\"OtherCost\\":true,\\"MFGNum\\":true,\\"DescriptionFR\\":false,\\"DescriptionEN\\":true,\\"Cost\\":true,\\"Category\\":\\"Testing,Part New\\"}","Message":"success"},{"ResponseStr":"Vendor Master does not exists with name VM-00000003","Message":"error"}]');
			}
			res.setStatusCode(200);
			return res;
		}
	}
}