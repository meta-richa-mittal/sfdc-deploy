/**
 * Author: Richa Mittal
 * Since: March 23, 2020
 * Name: VendorMasterSubscriberService
 * Description: VendorMasterSubscriberService class.
**/
public without sharing class VendorMasterSubscriberService {
    
    public static List<SubscriberResponseWrapper> sendSubscribeRequest(List<String> vendorMasterNameList) {
    	// get LMA authentication access token
        LMAAuthenticationService.OAuth2 objAuthenticationInfo = LMAAuthenticationService.getAccessToken();
        
    	String reqbody = System.JSON.serialize(new VendorMasterSubscriberService.SubscriberRequestWrapper(vendorMasterNameList, UserInfo.getOrganizationId().substring(0, 15)));
        HTTPResponse res = LMAAuthenticationService.sendRequest(reqbody, objAuthenticationInfo, 'SubscribeVendorMaster');
        List<SubscriberResponseWrapper> responseObjList = (List<SubscriberResponseWrapper>)System.JSON.deserialize(res.getBody(), List<SubscriberResponseWrapper>.class);
        return responseObjList;
    }
    
    public static List<String> handleResponse(List<String> vendorMasterNameList, List<SubscriberResponseWrapper> responseObjList, List<VendorMasterWrapper> vendorMasterObjList) {
    	List<String> partnerVMUIDList = new List<String>();
        
        for(SubscriberResponseWrapper responseObj: responseObjList) {
        	if(responseObj.Message == 'error') {
                // insert log with error message
                VendorMasterSubscriberCtrl.logListToInsert.add(new LogService().createErrorLog('VendorMasterSubscriberService', 'handleResponse()', responseObj.ResponseStr, LogService.NOT_APPLICABLE, LogService.NOT_APPLICABLE, 
                                                  system.Json.serialize(vendorMasterNameList), LogService.AUTOMATED_PRICE_FILE, false));
            } else if(responseObj.Message == 'success') {
                // save in vendor master object
                VendorMasterWrapper vendorMasterObj = (VendorMasterWrapper)System.JSON.deserialize(responseObj.ResponseStr, VendorMasterWrapper.class);
                partnerVMUIDList.add(vendorMasterObj.VendorMasterUID);
                vendorMasterObjList.add(vendorMasterObj);
            } else {
                // insert log with responseObj
                VendorMasterSubscriberCtrl.logListToInsert.add(new LogService().createErrorLog('VendorMasterSubscriberService', 'handleResponse()', system.Json.serialize(responseObj), LogService.NOT_APPLICABLE, LogService.NOT_APPLICABLE, 
                                                  system.Json.serialize(vendorMasterNameList), LogService.AUTOMATED_PRICE_FILE, false));
            }
        }
        return partnerVMUIDList;
    }
    
    public static void upsertVendorMaster(List<String> partnerVMUIDList, List<VendorMasterWrapper> vendorMasterObjList) {
    	Map<String, Vendor_Master__c> partnerVMUIDToVendorMasterRecMap = getPartnerVMUIDToVendorMasterRecMap(partnerVMUIDList);
        
        List<Vendor_Master__c> vendorMasterListToUpsert = new List<Vendor_Master__c>();
        for(VendorMasterWrapper vendorMasterObj: vendorMasterObjList) {
        	String vendorMasterId = partnerVMUIDToVendorMasterRecMap.containsKey(vendorMasterObj.VendorMasterUID) ? 
        								partnerVMUIDToVendorMasterRecMap.get(vendorMasterObj.VendorMasterUID).Id : null;
            vendorMasterListToUpsert.add(setVendorMasterFields(vendorMasterObj, vendorMasterId));
        }
        
        if(vendorMasterListToUpsert.size() > 0) {
            DMLUtility.upsertSobjectList('Vendor_Master__c', vendorMasterListToUpsert);
        }
    }
    
    private static Map<String, Vendor_Master__c> getPartnerVMUIDToVendorMasterRecMap(List<String> partnerVMUIDList) {
    	Map<String, Vendor_Master__c> partnerVMUIDToVendorMasterRecMap = new Map<String, Vendor_Master__c>();
    	if(partnerVMUIDList.size() > 0) {
        	List<Vendor_Master__c> vendorMasterList = [SELECT Id, Partner_Vendor_Master_Identifier__c FROM Vendor_Master__c WHERE Partner_Vendor_Master_Identifier__c IN :partnerVMUIDList];
        	
            for(Vendor_Master__c vendorMasterRec: vendorMasterList) {
                partnerVMUIDToVendorMasterRecMap.put(vendorMasterRec.Partner_Vendor_Master_Identifier__c, vendorMasterRec);
            }
        }
        return partnerVMUIDToVendorMasterRecMap;
    }
    
    private static Vendor_Master__c setVendorMasterFields(VendorMasterWrapper vendorMasterObj, String vendorMasterId) {
    	Vendor_Master__c vendorMasterRec = new Vendor_Master__c();
    	vendorMasterRec.Category__c = vendorMasterObj.Category;
    	vendorMasterRec.Cost_New__c = vendorMasterObj.Cost;
    	vendorMasterRec.Description_EN__c = vendorMasterObj.DescriptionEN;
    	vendorMasterRec.Description_FR__c = vendorMasterObj.DescriptionFR;
    	vendorMasterRec.Mfg_Num__c = vendorMasterObj.MFGNum;
    	vendorMasterRec.Other_Cost_New__c = vendorMasterObj.OtherCost;
    	vendorMasterRec.Other_Price_New__c = vendorMasterObj.OtherPrice;
    	vendorMasterRec.Partner_Vendor_Master_Identifier__c = vendorMasterObj.VendorMasterUID;
    	vendorMasterRec.Part_Num__c = vendorMasterObj.PartNum;
    	vendorMasterRec.Pkg_Qty__c = vendorMasterObj.PkgQty;
    	vendorMasterRec.Price_New__c = vendorMasterObj.Price;
    	vendorMasterRec.Replaced_By__c = vendorMasterObj.ReplacedBy;
    	vendorMasterRec.Replaces__c = vendorMasterObj.Replaces;
    	vendorMasterRec.SKU_Num__c = vendorMasterObj.SKUNum;
    	vendorMasterRec.Vendor_Name__c = vendorMasterObj.VendorName;
    	vendorMasterRec.Id = vendorMasterId;
    	return vendorMasterRec;
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