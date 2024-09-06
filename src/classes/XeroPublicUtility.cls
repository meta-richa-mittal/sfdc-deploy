public class XeroPublicUtility { 

    public static String Access_Token_URL_OAUTH2 = 'https://identity.xero.com/connect/token';
    public static String Redirect_URI = 'https://login.salesforce.com/apex/' + Constants.NAMESPACE + 'Oauth_callback';

    public static HttpResponse OAuth2ConnectionStep2(String code) {
    	IFW_IntegrationConfig__c configRec = AccountingIntegrationSettingsService.getIFWConfiguration('Xero');
        String encodedString = EncodingUtil.base64Encode(Blob.valueOf(configRec.Client_Id__c+':'+configRec.Client_Secret__c));
		
		String requestBody = 'grant_type=authorization_code&code='+code+'&redirect_uri='+Redirect_URI;
		
		HttpRequest httpReq = new HttpRequest();
		HttpResponse httpRes = new HttpResponse();
		Http http = new Http();
		httpReq.setMethod('POST');
		httpReq.setEndPoint(Access_Token_URL_OAUTH2);
		httpReq.setHeader('Authorization' , 'Basic ' + encodedString);
		httpReq.setHeader('Content-Type' , 'application/x-www-form-urlencoded');
		httpReq.setBody(requestBody);
		//system.assert(false, requestBody);
		try {
			httpRes = http.send(httpReq);
		} catch(System.Exception e) {
			throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
	 	}
	 	return httpRes;
    }
    
    public static HttpResponse getAuthorizedTenants(IFW_IntegrationConfig__c configRec, String authEventId) {
    	List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems('Xero', new Map<String, String>{IntegrationUtility.CONNECTION => null}, false);
        if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
        
        integrationConfigList[0].Access_Token__c = configRec.Access_Token__c;
        integrationConfigList[0].Refresh_Token__c = configRec.Refresh_Token__c;
        
        List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
        if(configItemList.size() == 0) throw new BlackpurlException('Config item for Connection not defined');
        
        Map<String, String> urlParamMap = new Map<String, String>{'authEventId' => authEventId};
    	HttpResponse response = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], '', new List<customHttpHeaderWrapper>(), urlParamMap, IntegrationUtility.CONNECTION);
    	return response;
    }
    
    public static HttpResponse removeXeroConnection(QuickBooks_Configurations__c qbConfig) {
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems('Xero', new Map<String, String>{IntegrationUtility.CONNECTION => null}, false);
        if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
        
        String connectionId = qbConfig.Connection_Id__c;
        if(String.isBlank(qbConfig.Connection_Id__c)) {
            connectionId = getConnectionId(integrationConfigList, qbConfig);
        }
        Integer timeout = integrationConfigList[0].Timeout__c != null ? Integer.valueOf(integrationConfigList[0].Timeout__c) : BaseIntegration.DEFAULT_TIMEOUT;
        HttpResponse httpRes = BaseIntegration.refreshAccessToken(integrationConfigList[0]);
        String accessToken = BaseIntegration.getAccessTokenFromResponse(httpRes, integrationConfigList[0]);
        
        return OAuthUtility.executeOauth2Callout('DELETE', '', accessToken, qbConfig.Company_Id__c, 
        	'https://api.xero.com/connections/' + connectionId, new Map<String, String>(), timeout);
    }
    
    public static String getConnectionId(List<IFW_IntegrationConfig__c> integrationConfigList, QuickBooks_Configurations__c qbConfig) {
        String connectionId;
        List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
        if(configItemList.size() == 0) throw new BlackpurlException('Config item for Connection not defined');
    
        HttpResponse response = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], '', new List<customHttpHeaderWrapper>(), new Map<String, String>(), IntegrationUtility.CONNECTION);
        if(response.getStatusCode() == 200) {
            List<XeroTenantWrapper> tenantList = (List<XeroTenantWrapper>) System.JSON.deserialize(response.getBody(), List<XeroTenantWrapper>.class);
            for(XeroTenantWrapper tenant : tenantList) {
                if(tenant.tenantId == qbConfig.Company_Id__c) {
                    connectionId = tenant.id;
                    break;
                }
            }
        }
        return connectionId;
    }
}