public without sharing class BRPDealerAuthorizationService {
    public String authorizeBRP() {
    	HttpResponse response = new HttpResponse();
    	try {
    		IFW_IntegrationConfig__c ifwConfigRec = BRPUtility.getIFWConfigForDealerAuthWithConfigItem('Authorize', 'GET');
	        Map<String, String> params = new Map<String, String>{
	        									'response_type'	=>	'code',
	        									'client_id'	=>	ifwConfigRec.Client_Id__c,
	        									'redirect_uri'	=>	BRPUtility.OAUTH2_REDIRECT_URI
	        								};
	        
	        response = BaseIntegration.performCallout(ifwConfigRec, ifwConfigRec.IFW_IntegrationConfigItems__r[0], null, new List<CustomHttpHeaderWrapper>(), params);
	        if(BaseIntegration.webServiceLogs != null && BaseIntegration.webServiceLogs.size() > 0) {
				DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
	        }
	        if(response.getStatusCode() == 302) {
	        	return response.getHeader('Location');
			} else if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
				// ??
			} else {
				return 'Error';
			}
    	} catch(Exception e) {
        	BRPLogService obj = new BRPLogService('authorize', null, null, null, null, 
			    				e.getMessage() + ' - ' + response.getBody(), 'Error', 'BRPDealerAuthorizationService', 'authorizeBRP');
			obj.createLog();
        }
		return 'Error';
    }
    
    public static String saveAccessToken(String urlParams) {
        Oauth_callbackCtrl.OAuthWrapper urlParamObj = (Oauth_callbackCtrl.OAuthWrapper) system.JSON.deserialize(urlParams, Oauth_callbackCtrl.OAuthWrapper.class);
        String returnRespose = '';
        try {
        	IFW_IntegrationConfig__c ifwConfigRec = BRPUtility.getIFWConfigForDealerAuthWithConfigItem('Token', 'POST');
        	Map<String, String> params = new Map<String, String>{
        									'grant_type'	=>	'authorization_code',
        									'client_id'	=>	ifwConfigRec.Client_Id__c,
        									'client_secret'	=>	ifwConfigRec.Client_Secret__c,
        									'code' => urlParamObj.code,
        									'redirect_uri'	=>	BRPUtility.OAUTH2_REDIRECT_URI
        								};
        	HttpResponse response = BaseIntegration.performCallout(ifwConfigRec, ifwConfigRec.IFW_IntegrationConfigItems__r[0], 
        							null, new List<CustomHttpHeaderWrapper>{new CustomHttpHeaderWrapper('Content-Length', '0')}, params);
        	
            if(response.getStatusCode() == 200) {
            	Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
		        ifwConfigRec.Access_Token__c = (String)response_Map.get('access_token');
		        ifwConfigRec.Refresh_Token__c = (String)response_Map.get('refresh_token');
		        ifwConfigRec.Token_Type__c = (String)response_Map.get('token_type');
		        
		        if(String.isBlank(ifwConfigRec.Access_Token__c)) {
		        	returnRespose = 'Blank access token';
		        } else {
					DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigRec);
                	returnRespose = 'success';
		        }
            } else {
                returnRespose = response.getBody();
            }
            if(BaseIntegration.webServiceLogs != null && BaseIntegration.webServiceLogs.size() > 0) {
				DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
	        }
        } catch(Exception e) {
            returnRespose = e.getMessage();
            BRPLogService obj = new BRPLogService('token', urlParams, null, null, null, 
			    				returnRespose, 'Error', 'BRPDealerAuthorizationService', 'saveAccessToken');
			obj.createLog();       
        }
        return returnRespose;
    }

	public static HttpResponse refreshAccessToken(List<IFW_IntegrationConfig__c> ifwConfigRecList) {
		if(ifwConfigRecList.size() == 0) return null;
		Map<String, String> urlParams = new Map<String, String>{
										'grant_type'	=>	'refresh_token',
										'client_id'	=>	ifwConfigRecList[0].Client_Id__c,
										'client_secret'	=>	ifwConfigRecList[0].Client_Secret__c,
										'refresh_token' => ifwConfigRecList[0].Refresh_Token__c,
										'redirect_uri'	=>	BRPUtility.OAUTH2_REDIRECT_URI
									};
		
		return BaseIntegration.performCallout(ifwConfigRecList[0], ifwConfigRecList[0].IFW_IntegrationConfigItems__r[0], 
	        							null, new List<CustomHttpHeaderWrapper>{new CustomHttpHeaderWrapper('Content-Length', '0')}, urlParams);
 	}


    public static HttpResponse refreshBRPAccessTokenAndPerformCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                List<CustomHttpHeaderWrapper> headerList, Map<String, String> parameters) {
    	List<IFW_IntegrationConfig__c> ifwConfigRecList = new List<IFW_IntegrationConfig__c>{BRPUtility.getIFWConfigForOAuth2WithConfigItem('Token', 'POST')};
		HttpResponse response = refreshAccessToken(ifwConfigRecList);
		String accessToken;
		if(response.getStatusCode() == 200) {
			Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
			ifwConfigRecList[0].Access_Token__c = (String)response_Map.get('access_token');
		   	ifwConfigRecList[0].Refresh_Token__c = (String)response_Map.get('refresh_token');
			accessToken = (String)response_Map.get('access_token');
		}
		if(accessToken == null) return response;
		
        for(CustomHttpHeaderWrapper customHTTPHeader : headerList) {
            if(customHTTPHeader.headerType.equalsIgnoreCase('Authorization')) {
                customHTTPHeader.headerValue = 'Bearer ' + accessToken;
            }
        }
        
		response = BasicAuthUtility.performCallout(parent, child, body, headerList, parameters);
        
        // update new access token in IFW config
		DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigRecList);
        return response;
    }
}