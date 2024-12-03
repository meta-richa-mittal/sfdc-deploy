@isTest
private class BRPDealersControllerTest {
	
	@testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();

		IFW_IntegrationConfig__c IFWConfigObj = TestDataFactory.createIFWConfigForBRP();
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemBRP('GetCampaigns', IFWConfigObjList[0].Id);
        IFWConfigItemObj.Endpoint_URL__c = 'https://qa-cloud-api.brp.com/dealer_connect_program/service_history/v1/vin/{vin}/campaigns';
        IFWConfigItemObj.HTTP_Method__c = 'GET';
        upsert IFWConfigItemObj;

		IFW_IntegrationConfigItem__c IFWConfigItemObj1 = TestUtil.createIFWConfigItemBRP('GetArticle', IFWConfigObjList[0].Id);
        IFWConfigItemObj1.Endpoint_URL__c = 'https://qa-cloud-api.brp.com/dealer_connect_program/service_history/v1/article/{article-no}';
        IFWConfigItemObj1.HTTP_Method__c = 'GET';
        upsert IFWConfigItemObj1;

    	BRP_Dealers__c brpDealerRec = new BRP_Dealers__c();
    	brpDealerRec.Party_ID__c = '123';
    	brpDealerRec.Telephone__c = '36253673';
    	brpDealerRec.Fax__c = 'testFax';
    	brpDealerRec.Website__c = 'test website';
    	brpDealerRec.Email__c = 'test@gmail.com';
    	brpDealerRec.Street__c = 'test street';
    	brpDealerRec.Line_Two__c = 'test address2';
    	brpDealerRec.City__c = 'test city';
    	brpDealerRec.Postcode__c = '356253';
    	brpDealerRec.State__c = 'test state';
    	brpDealerRec.Country__c = 'test country';
    	brpDealerRec.Company_Name__c = 'test company';
    	insert brpDealerRec;
    	
    	List<BRP_Dealer_Product_Line__c> brpDealerProductLineList = new List<BRP_Dealer_Product_Line__c>();
    	brpDealerProductLineList.add(new BRP_Dealer_Product_Line__c(Name = 'Test product 1', BRP_Dealer__c = brpDealerRec.Id));
    	brpDealerProductLineList.add(new BRP_Dealer_Product_Line__c(Name = 'Test product 2', BRP_Dealer__c = brpDealerRec.Id));
    	brpDealerProductLineList.add(new BRP_Dealer_Product_Line__c(Name = 'Test product 3', BRP_Dealer__c = brpDealerRec.Id));
    	insert brpDealerProductLineList;
    }

	@isTest
    private static void getDealerTest() {
    	BRPDealersController brpDealersControllerObj = new BRPDealersController();
    	BRPDealersController brpDealersControllerWithHomePageObj = new BRPDealersController(new NewHomePageCtrl());
    	
    	Test.startTest();
    	String result = BPUtility.getDecodedString(BRPDealersController.getDealer());
    	List<BRPDealerWrapper> brpDealerWrapperList = (List<BRPDealerWrapper>)system.JSON.deserialize(result, List<BRPDealerWrapper>.class);
    	System.assertEquals(brpDealerWrapperList[0].PartyId, '123');
    	Test.stopTest();
    }

    @isTest
    private static void getArticleByArticleNoTest() {
        Test.setMock(HttpCalloutMock.class, new BRPVehicleIntegrationMockTest(null));
        Test.startTest();
		String articleNo = '000137651';
        String res = BPUtility.getDecodedString(BRPDealersController.getArticleByArticleNo(BPUtility.getEncodedString(articleNo)));
        BRPArticleResponseWrapper responseWrapper = (BRPArticleResponseWrapper)system.JSON.deserialize(res, BRPArticleResponseWrapper.class);
        system.assertEquals(200, responseWrapper.StatusCode);
		system.assertEquals(articleNo, responseWrapper.SuccessResponse.article_no);
        Test.stopTest();
    }

    @isTest
    private static void getCampaignsByVINTest() {
        Test.setMock(HttpCalloutMock.class, new BRPVehicleIntegrationMockTest(null));
        Test.startTest();
		String vinNo = '2BPSCEKCXKV000009';
        String res = BPUtility.getDecodedString(BRPDealersController.getCampaignsByVIN(BPUtility.getEncodedString(vinNo)));
        BRPCampaignResponseWrapper responseWrapper = (BRPCampaignResponseWrapper)system.JSON.deserialize(res, BRPCampaignResponseWrapper.class);
        system.assertEquals(200, responseWrapper.StatusCode);
		system.assertEquals(vinNo, responseWrapper.SuccessResponse.vin);
        Test.stopTest();
    }
}