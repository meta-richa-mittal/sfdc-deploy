/**
 * Author: Richa Mittal
 * Since: June 14, 2021
 * Name: BRPAuthorizationService
 * Description: Service class for BRPAuthorizationCtrl
**/
public without sharing class BRPAuthorizationService {
    public PageReference authorizeBRP() {
    	HttpResponse response = new HttpResponse();
    	try {
    		IFW_IntegrationConfig__c ifwConfigRec = BRPUtility.getIFWConfigForOAuth2WithConfigItem('Authorize', 'GET');
	        Map<String, String> params = new Map<String, String>{
	        									'response_type'	=>	'code',
	        									'client_id'	=>	ifwConfigRec.Client_Id__c,
	        									'redirect_uri'	=>	BRPUtility.OAUTH2_REDIRECT_URI
	        								};
	        
	        response = BaseIntegration.performCallout(ifwConfigRec, ifwConfigRec.IFW_IntegrationConfigItems__r[0], null, new List<CustomHttpHeaderWrapper>(), params);
	        
	        if(response.getStatusCode() == 302) {
	        	String endPoint = response.getHeader('Location');
	        	if(String.isNotBlank(endPoint)) {
	        		PageReference retURL = new PageReference(endPoint);
			      	retURL.setRedirect(true);
			      	return retURL;
	        	} else {
	        		throw new BlackPurlException(response.getBody() + ' - ' + response.getStatusCode());
	        	}
			} else if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
				// ??
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, response.getBody() + ' - ' + response.getStatusCode()));
			}
			if(BaseIntegration.webServiceLogs != null && BaseIntegration.webServiceLogs.size() > 0) {
				DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
	        }
    	} catch(Exception e) {
    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
        	BRPLogService obj = new BRPLogService('authorize', null, null, null, null, 
			    				e.getMessage() + ' - ' + response.getBody(), 'Error', 'BRPAuthorizationCtrl', 'authorizeBRP');
			obj.createLog();
        }
		return null;
    }
    
    public static String saveAccessToken(String urlParams) {
        Oauth_callbackCtrl.OAuthWrapper urlParamObj = (Oauth_callbackCtrl.OAuthWrapper) system.JSON.deserialize(urlParams, Oauth_callbackCtrl.OAuthWrapper.class);
        String returnRespose = '';
        try {
        	IFW_IntegrationConfig__c ifwConfigRec = BRPUtility.getIFWConfigForOAuth2WithConfigItem('Token', 'POST');
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
			    				returnRespose, 'Error', 'BRPAuthorizationCtrl', 'saveAccessToken');
			obj.createLog();       
        }
        return returnRespose;
    }
    
    public static String refreshAccessToken(List<IFW_IntegrationConfig__c> ifwConfigRecList) {
		if(ifwConfigRecList.size() == 0) return null;
    	HttpResponse response = new HttpResponse();
		try {
			Map<String, String> urlParams = new Map<String, String>{
	    									'grant_type'	=>	'refresh_token',
	    									'client_id'	=>	ifwConfigRecList[0].Client_Id__c,
	    									'client_secret'	=>	ifwConfigRecList[0].Client_Secret__c,
	    									'refresh_token' => ifwConfigRecList[0].Refresh_Token__c,
	    									'redirect_uri'	=>	BRPUtility.OAUTH2_REDIRECT_URI
	    								};
			
			response = BaseIntegration.performCallout(ifwConfigRecList[0], ifwConfigRecList[0].IFW_IntegrationConfigItems__r[0], 
	        							null, new List<CustomHttpHeaderWrapper>{new CustomHttpHeaderWrapper('Content-Length', '0')}, urlParams);
		
			if(response.getStatusCode() == 200) {
 				Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
 				ifwConfigRecList[0].Access_Token__c = (String)response_Map.get('access_token');
				ifwConfigRecList[0].Refresh_Token__c = (String)response_Map.get('refresh_token');
 				return (String)response_Map.get('access_token');
			} else {
				throw new BlackpurlException(response.getBody());
			}
		} catch(System.Exception e) {
			BRPLogService obj = new BRPLogService('Refresh access token', null, null, null, null, 
			    				e.getMessage() + ' - ' + response.getBody(), 'Error', 'BRPAuthorizationCtrl', 'refreshAccessToken');
			obj.createLog();
	 	}
	 	return null;
 	}

	 public static String refreshAccessTokenForBRPDMS(List<IFW_IntegrationConfig__c> ifwConfigRecList) {
		if(ifwConfigRecList.size() == 0) return null;
		String payload = 'client_id='+EncodingUtil.urlEncode(ifwConfigRecList[0].Client_Id__c,'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(ifwConfigRecList[0].Client_Secret__c,'UTF-8')+'&grant_type=client_credentials';
		HttpRequest req = BasicAuthUtility.generateBasicRequest(ifwConfigRecList[0], ifwConfigRecList[0].IFW_IntegrationConfigItems__r[0], payload,
																	 new List<CustomHttpHeaderWrapper>{new CustomHttpHeaderWrapper('Content-Type', 'application/x-www-form-urlencoded'), new CustomHttpHeaderWrapper('Content-Length', '0')}, new Map<String, String>());
		
		HttpResponse response = new HttpResponse();
		response = new Http().send(req);
		if(response.getStatusCode() == 200) {
			Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
			ifwConfigRecList[0].Access_Token__c = (String)response_Map.get('access_token');
			return (String)response_Map.get('access_token');
		} 
	 	return null;
 	}
 	
 	public static HttpResponse refreshBRPAccessTokenAndPerformCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                List<CustomHttpHeaderWrapper> headerList, Map<String, String> parameters) {
    	List<IFW_IntegrationConfig__c> ifwConfigRecList = new List<IFW_IntegrationConfig__c>{BRPUtility.getIFWConfigForOAuth2WithConfigItem('Token', 'POST')};
            	
        // replace new access token in req body
        body = body.substringBefore('<star:Password>') + '<star:Password>' + 
        		refreshAccessToken(ifwConfigRecList) + 
        		'</star:Password>' + body.substringAfter('</star:Password>');
        
        HttpResponse res = BasicAuthUtility.performCallout(parent, child, body, headerList, parameters);
        
        // update new access token in IFW config
		DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigRecList);
        
        return res;
    }
}