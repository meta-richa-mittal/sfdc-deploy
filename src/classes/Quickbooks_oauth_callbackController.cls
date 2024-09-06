global without sharing class Quickbooks_oauth_callbackController {
    
    public static String Application{get;}
    public static String Assests{get;}
    public static String Application_Images{get;}
    public boolean isQBOAuth2Enabled { get{return QBUtil.isQBOAuth2Enabled();} private set;}
    
    public Quickbooks_oauth_callbackController(){
    	
    	Application = GlobalController.GetResourceURL('Application');
    	Application_Images = GlobalController.GetResourceURL('Application_Images');
    	Assests = GlobalController.GetResourceURL('Assests');
    	
    }
    /**
	 * Name: getFilterObjectTypes
	 * Description: Method to get the object labels which can be filtered on home search screen filter diaplog box
	 * @Param:	
	 * @Return:	String - JSON Sting
	 * 
	**/
	@RemoteAction   
    global static String saveAccessSecretsKeys(String oauth_token, String oauth_verifier, String realmId) {
    	oauth_token = BPUtility.getDecodedString(oauth_token);
    	oauth_verifier = BPUtility.getDecodedString(oauth_verifier);
    	realmId = BPUtility.getDecodedString(realmId);
    	String returnRespose = '';
    	try {
	    	HttpResponse apiResponse = QuickbookConnector.OAuthConnectionStep2(oauth_token, oauth_verifier);
	    	if(apiResponse.getStatusCode() == 200){
	    		Map<String,String> responseItems = new Map<String, String>();
		        for(String s : apiResponse.getBody().split('&')) {
		            List<String> kv = s.split('=');
		            responseItems.put(kv[0],kv[1]);
		        }
		        
		        QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
		        qbConfig.OAuth_Token__c = responseItems.get('oauth_token');
	        	qbConfig.OAuth_Token_Secret__c = responseItems.get('oauth_token_secret');
		        qbConfig.Company_Id__c = realmId;
				DMLUtility.updateSobjectList('QuickBooks_Configurations__c', qbConfig);
		        returnRespose = 'success';
		        
	    	}else{
	    		returnRespose = apiResponse.getBody();
	    	}
	    } catch(Exception e) {
            returnRespose = e.getMessage();       
        }
    	returnRespose = BPUtility.getEncodedString(returnRespose);
    	return returnRespose;
    }
    
    @RemoteAction   
    global static String handleOauth2ServerResponse(String urlParamsJSON) {
    	urlParamsJSON = BPUtility.getDecodedString(urlParamsJSON);
    	UrlParamsWrapper urlParamsObj = (UrlParamsWrapper) System.JSON.deserialize(urlParamsJSON, UrlParamsWrapper.class);
    	String returnRespose = '';
    	try {
	    	HttpResponse apiResponse = QuickbookConnector.fetchAccessToken(urlParamsObj.code, urlParamsObj.realmId);
	    	if(apiResponse.getStatusCode() == 200) {
	    		Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(apiResponse.getBody());
				QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
				
				List<IFW_IntegrationConfig__c> ifwConfigList = AccountingIntegrationSettingsService.getQuickBooksIFWConfig();
				if(ifwConfigList.size() == 0) {
		        	throw new BlackPurlException('Some configurations are missing.');
		        }
				qbConfig.Access_Token_Generation_Date__c = system.today();
				ifwConfigList[0].Refresh_Token__c = (String)response_Map.get('refresh_token');
				qbConfig.Company_Id__c = urlParamsObj.realmId;
				qbConfig.Refresh_Token_Expires_In__c = (Decimal)response_Map.get('x_refresh_token_expires_in');
				//Decimal expiresIn = (Decimal)response_Map.get('expires_in');
				DMLUtility.updateSobjectList('QuickBooks_Configurations__c', qbConfig);
				DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigList);
				returnRespose = 'success';
	    	} else {
	    		returnRespose = apiResponse.getBody();
	    	}
	    } catch(Exception e) {
            returnRespose = e.getMessage();       
        }
    	return BPUtility.getEncodedString(returnRespose);
    }
    
    
    public class UrlParamsWrapper {
    	public String code;
    	public String state;
    	public String realmId;
    }
}