@isTest
private class Quickbooks_oauth_callbackControllerTest {
    @testSetup
    private static void setup() {
        QuickBooks_Configurations__c qbConfig = TestDataFactory.createQBConfig();
    }
    
    @isTest
    private static void handleOauth2ServerResponseTest(){
        General_Configurations__c genConfig = TestDataFactory.createGeneralConfig(1);
        IFW_IntegrationConfig__c iFWConfigObj = TestDataFactory.createIFWConfigForIntegrationCheck();

        iFWConfigObj.Integration_Name__c = QBUtil.QUICKBOOKS_ONLINE ;
        iFWConfigObj.Client_Id_Long__c = 'Client_Id_Long__c';
        iFWConfigObj.Client_Secret_Long__c = 'Client_Secret_Long__c';
        update iFWConfigObj;
        
        List<IFW_IntegrationConfig__c> ifwConfigList = [SELECT Id, Client_Id_Long__c, Client_Secret_Long__c, Refresh_Token__c FROM IFW_IntegrationConfig__c 
        		WHERE Integration_Name__c =: QBUtil.QUICKBOOKS_ONLINE AND Enabled__c = true];
        DMLUtility.deleteSobjectList('IFW_IntegrationConfig__c', ifwConfigList[0]);
        
        Quickbooks_oauth_callbackController.UrlParamsWrapper urlObj = new Quickbooks_oauth_callbackController.UrlParamsWrapper();
        urlObj.code = 'abcd';
        urlObj.realmId = '123145730762509';
        urlObj.state = 'state';
        String response = BPUtility.getDecodedString(Quickbooks_oauth_callbackController.handleOauth2ServerResponse(BPUtility.getEncodedString(System.json.serialize(urlObj))));
        System.assertEquals('Methods defined as TestMethod do not support Web service callouts', response);
    }
}