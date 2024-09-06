/**
 * Author: Manoj Sharma
 * Since: April 10, 2020
 * Name: VendorMasterSubscriberUpdateService
 * Description: VendorMasterSubscriberUpdateService class.
**/
public without sharing class VendorMasterSubscriberUpdateService {
    
    public static List<SubscriberResponseWrapper> sendVMSUpdateRequest(List<String> vendorMasterNameList) {
    	// get LMA authentication access token
        LMAAuthenticationService.OAuth2 objAuthenticationInfo = LMAAuthenticationService.getAccessToken();
        
    	String reqbody = System.JSON.serialize(new SubscriberRequestWrapper(vendorMasterNameList, UserInfo.getOrganizationId().substring(0, 15)));
        HTTPResponse res = LMAAuthenticationService.sendRequest(reqbody, objAuthenticationInfo, 'UpdateVendorMasterSubscriber');
        List<SubscriberResponseWrapper> responseObjList = (List<SubscriberResponseWrapper>)System.JSON.deserialize(res.getBody(), List<SubscriberResponseWrapper>.class);
        return responseObjList;
    }
    
    public class SubscriberRequestWrapper {
        List<String> vendorMasterNameList;
        String orgId;
        
        private SubscriberRequestWrapper(List<String> vendorMasterNameList, String orgId) {
            this.vendorMasterNameList = vendorMasterNameList;
            this.orgId = orgId;
        }
    }
    
    public class SubscriberResponseWrapper {
        public String Message;
        public String ResponseStr;
    }
}