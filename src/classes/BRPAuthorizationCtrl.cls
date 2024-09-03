/**
 * Author: Richa Mittal
 * Since: May 19, 2021
 * Name: BRPAuthorizationCtrl
 * Description: Ctrl class for BRP Oauth 2.0
**/
global without sharing class BRPAuthorizationCtrl {
	public static String Application {get;set;}
    public static String Assests {get;set;}
    
    public BRPAuthorizationCtrl() {
        Application = GlobalController.GetResourceURL('Application');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    public Pagereference authorizeBRP() {
        return BRPAPIManager.authorizeBRP();
    }
    
    @RemoteAction
    global static String saveAccessToken(String urlParams) {
    	return BPUtility.getEncodedString(BRPAPIManager.saveAccessToken(BPUtility.getDecodedString(urlParams)));
    }
}