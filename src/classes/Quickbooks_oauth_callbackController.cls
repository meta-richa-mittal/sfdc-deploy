global without sharing class Quickbooks_oauth_callbackController {
    
    public static String Application{get;set;}
    public static String Assests{get;set;}
    public static String Application_Images{get;set;}
    
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
	/* No more used */
	@RemoteAction   
    global static String saveAccessSecretsKeys(String oauth_token, String oauth_verifier, String realmId) {
    	return null;
    }
    
    @RemoteAction   
    global static String handleOauth2ServerResponse(String urlParamsJSON) {
    	urlParamsJSON = BPUtility.getDecodedString(urlParamsJSON);
    	UrlParamsWrapper urlParamsObj = (UrlParamsWrapper) System.JSON.deserialize(urlParamsJSON, UrlParamsWrapper.class);
    	String returnRespose = '';
    	try {
	    	HttpResponse apiResponse = QBCalloutManager.fetchAccessToken(urlParamsObj.code, urlParamsObj.realmId);
	    	if(apiResponse.getStatusCode() == 200) {
	    		Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(apiResponse.getBody());
				QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
				
				Map<String, Object> fieldsMap = new Map<String, Object>{'Integration_Name__c' => QBUtil.QUICKBOOKS_ONLINE, 'Enabled__c' => true};
        		List<IFW_IntegrationConfig__c> ifwConfigList = IFW_SOQLUtil.getIntegrationConfig(fieldsMap);
				if(ifwConfigList.size() == 0) {
		        	throw new BlackPurlException('Some configurations are missing.');
		        }
				qbConfig.Access_Token_Generation_Date__c = system.today();
				ifwConfigList[0].Refresh_Token__c = (String)response_Map.get('refresh_token');
				qbConfig.Company_Id__c = urlParamsObj.realmId;
				ifwConfigList[0].Token_Expiry__c = (Decimal)response_Map.get('x_refresh_token_expires_in');
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