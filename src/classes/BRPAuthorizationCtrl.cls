/**
 * Author: Richa Mittal
 * Since: May 19, 2021
 * Name: BRPAuthorizationCtrl
 * Description: Ctrl class for BRP Oauth 2.0
**/
global without sharing class BRPAuthorizationCtrl {
	public static String Application {get;}
    public static String Assests {get;}
    
    public BRPAuthorizationCtrl() {
        Application = GlobalController.GetResourceURL('Application');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    public PageReference authorizeBRP() {
    	return new BRPAuthorizationService().authorizeBRP();
    }
    
    @RemoteAction
    global static String saveAccessToken(String urlParams) {
    	return BPUtility.getEncodedString(BRPAuthorizationService.saveAccessToken(BPUtility.getDecodedString(urlParams)));
    }
}