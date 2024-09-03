/**
 * Author: Manoj Sharma
 * Since: April 09, 2020
 * Name: VendorMasterImportPriceFileService
 * Description: VendorMasterImportPriceFileService class.
**/
public without sharing class VendorMasterImportPriceFileService {
    public static List<SubscriberResponseWrapper> sendPriceFileDetailsRequest(List<String> vendorMasterNameList) {
    	// get LMA authentication access token
        LMAAuthenticationService.OAuth2 objAuthenticationInfo = LMAAuthenticationService.getAccessToken();
        
    	String reqbody = System.JSON.serialize(new SubscriberRequestWrapper(vendorMasterNameList, UserInfo.getOrganizationId().substring(0, 15)));
        HTTPResponse res = LMAAuthenticationService.sendRequest(reqbody, objAuthenticationInfo, 'ImportPriceFile');
        //system.assert(false, res.getBody());
        List<SubscriberResponseWrapper> responseObjList = (List<SubscriberResponseWrapper>)System.JSON.deserialize(res.getBody(), List<SubscriberResponseWrapper>.class);
        return responseObjList;
    }
    
    public static List<VendorMasterWrapper> handleResponse(List<String> vendorMasterNameList, List<SubscriberResponseWrapper> responseObjList) {
    	List<VendorMasterWrapper> vendorMasterObjList = new List<VendorMasterWrapper>();
        
        for(SubscriberResponseWrapper responseObj: responseObjList) {
        	if(responseObj.Message == 'error') {
                // insert log with error message
                AutomatedPriceFileService.logListToInsert.add(new LogService().createErrorLog('VendorMasterImportPriceFileService', 'handleResponse()', responseObj.ResponseStr, LogService.NOT_APPLICABLE, LogService.NOT_APPLICABLE, 
                                                  system.Json.serialize(vendorMasterNameList), LogService.AUTOMATED_PRICE_FILE, false));
            } else if(responseObj.Message == 'success') {
                // save in vendor master object
                VendorMasterWrapper vendorMasterObj = (VendorMasterWrapper)System.JSON.deserialize(responseObj.ResponseStr, VendorMasterWrapper.class);
                vendorMasterObjList.add(vendorMasterObj);
            } else {
                // insert log with responseObj
                AutomatedPriceFileService.logListToInsert.add(new LogService().createErrorLog('VendorMasterImportPriceFileService', 'handleResponse()', system.Json.serialize(responseObj), LogService.NOT_APPLICABLE, LogService.NOT_APPLICABLE, 
                                                  system.Json.serialize(vendorMasterNameList), LogService.AUTOMATED_PRICE_FILE, false));
            }
        }
        return vendorMasterObjList;
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
        String Message;
        String ResponseStr;
    }
}