global without sharing class Oauth_callbackCtrl {
    
    public static String Application {get;}
    public static String Assests {get;}
    
    public Oauth_callbackCtrl() {
        Application = GlobalController.GetResourceURL('Application');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    @RemoteAction
    global static String saveAccessSecretKeys(String urlParams) {
        urlParams = BPUtility.getDecodedString(urlParams);
        OAuthWrapper urlParamObj = (OAuthWrapper) system.JSON.deserialize(urlParams, OAuthWrapper.class);
        String returnRespose = '';
        try {
        	HttpResponse response;
        	if(!XeroUtility.isXeroOAuth2Enabled()) {
        		response = XeroPublicUtility.OAuthConnectionStep2(urlParamObj.oauth_token, urlParamObj.oauth_verifier);
        	} else {
        		response = XeroPublicUtility.OAuth2ConnectionStep2(urlParamObj.code);
        	}
            if(response.getStatusCode() == 200) {
            	if(!XeroUtility.isXeroOAuth2Enabled()) {
            		Map<String, String> responseItemMap = AccountingIntegrationSettingsService.parseOAuthStep1Response(response.getBody());
                	AccountingIntegrationSettingsService.saveOauthTokenSecret(responseItemMap.get('oauth_token'), responseItemMap.get('oauth_token_secret'), 'Xero');
            	} else {
            		Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
	            	IFW_IntegrationConfig__c configRec = AccountingIntegrationSettingsService.getIFWConfiguration('Xero');
			        configRec.Access_Token__c = (String)response_Map.get('access_token');
			        configRec.Token_Expiry__c = (Decimal)response_Map.get('expires_in');
			        configRec.Refresh_Token__c = (String)response_Map.get('refresh_token');
			        configRec.Token_Type__c = (String)response_Map.get('token_type');
			        
			        if(String.isBlank(configRec.Access_Token__c)) {
			        	return BPUtility.getEncodedString('Blank access token');
			        }
			        
			        List<String> strList = configRec.Access_Token__c.split('\\.');
			        if(strList.size() < 2) { // String at index 1 contains info about authentication
			        	return BPUtility.getEncodedString('Unable to decode authentication payload from access token');
			        }
			        
			        String decodedPayload = BPUtility.getDecodedString(strList[1]);
			        if(String.isBlank(decodedPayload)) {
			        	return BPUtility.getEncodedString('Authentication payload decoded from access token is blank');
			        }
			        
			        JSONWebTokenWrapper jwtObj = (JSONWebTokenWrapper) System.JSON.deserialize(decodedPayload, JSONWebTokenWrapper.class);
			        if(jwtObj == null || String.isBlank(jwtObj.authentication_event_id)) {
			        	return BPUtility.getEncodedString('Blank authentication_event_id');
			        }
			        
			        response = XeroPublicUtility.getAuthorizedTenants(configRec, jwtObj.authentication_event_id);
			        
			        if(response.getStatusCode() == 200) {
			        	List<XeroTenantWrapper> tenantList = (List<XeroTenantWrapper>) System.JSON.deserialize(response.getBody(), List<XeroTenantWrapper>.class);
			        	if(tenantList.size() > 0) {
			        		QuickBooks_Configurations__c integrationConfig = QuickBooks_Configurations__c.getOrgDefaults();
					    	integrationConfig.Company_Id__c = tenantList[0].tenantId;
					    	integrationConfig.Connection_Id__c = tenantList[0].id;
							DMLUtility.upsertSobjectList('QuickBooks_Configurations__c', integrationConfig);
			        	} else {
			        		return BPUtility.getEncodedString('No tenant matching with authentication_event_id: ' + jwtObj.authentication_event_id + ' is found');
			        	}
						DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', configRec);
			        } else {
			        	returnRespose = response.getBody();
			        }
            	}
                returnRespose = 'success';
            } else {
            	if(!XeroUtility.isXeroOAuth2Enabled()) {
            		IFW_IntegrationConfig__c configRec = AccountingIntegrationSettingsService.getIntegrationConfig('Xero');
            		configRec.Access_Token_Secret__c = null;
					DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', configRec);
            	}
                returnRespose = response.getBody();
            }
        } catch(Exception e) {
        	if(!XeroUtility.isXeroOAuth2Enabled()) {
        		IFW_IntegrationConfig__c configRec = AccountingIntegrationSettingsService.getIntegrationConfig('Xero');
	        	configRec.Access_Token__c = null;
				DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', configRec);
        	}
            returnRespose = e.getMessage();       
        }
        returnRespose = BPUtility.getEncodedString(returnRespose);
        return returnRespose;
    }
    
    public class OAuthWrapper {
        public String oauth_token;
        public String oauth_verifier;
        public String org;
        public String code;
        public String scope;
    }
    
    public class JSONWebTokenWrapper {
    	public String client_id;
    	public String authentication_event_id;
    }
}