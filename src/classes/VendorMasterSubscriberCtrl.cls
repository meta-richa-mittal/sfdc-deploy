/** 
* Author: Richa Mittal
* Since: Mar 19, 2020
* Name: VendorMasterSubscriberCtrl 
* Description: Apex class which contains all remoted methods related to vendor master subscriber
**/
global class VendorMasterSubscriberCtrl {
    public static List<Log__c> logListToInsert = new List<Log__c>();
    
    webservice static Boolean subscribeAction(String vendorMasterName) {
        subscribeToVendorMasterFromPartnerOrg(new Set<String>{vendorMasterName});
        return (logListToInsert.size() > 0);
    }
    
    webservice static void subscribe(String vendorMasterName) {
    	//subscribeToVendorMasterFromPartnerOrg(new Set<String>{vendorMasterName});
    }

    webservice static Boolean unsubscribeAndDeleteAction(String vendorMasterId, String partnerVendorMasterName) {
        try {
            unsubscribeToVendorMasterFromPartnerOrg(new Set<String>{partnerVendorMasterName});
            if(logListToInsert.isEmpty()) {
                deleteVendorMaster(vendorMasterId);
            }
        } catch(Exception e) {
            logListToInsert.add(new LogService().createErrorLog('VendorMasterSubscriberCtrl', 'unsubscribeAndDeleteAction()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                                    partnerVendorMasterName, LogService.AUTOMATED_PRICE_FILE, false));
        }
        
        DMLUtility.insertSobjectList('Log__c', logListToInsert);
        return (logListToInsert.size() > 0);
    }
    
    global static void subscribeToVendorMasterFromPartnerOrg(Set<String> vendorMasterNameSet) {
        try {
            // send request to partner org and get the vendor master details
            List<VendorMasterSubscriberService.SubscriberResponseWrapper> responseObjList = VendorMasterSubscriberService.sendSubscribeRequest(new List<String>(vendorMasterNameSet));
            
            List<VendorMasterWrapper> vendorMasterObjList = new List<VendorMasterWrapper>();
            
            // handle response from partner org and set to list "vendorMasterObjList" of vendor master obj to upsert. Also get the list of vendor master identifier list for parten org
            List<String> partnerVMUIDList = VendorMasterSubscriberService.handleResponse(new List<String>(vendorMasterNameSet), responseObjList, vendorMasterObjList);
            
            // upsert vendor master records
            VendorMasterSubscriberService.upsertVendorMaster(partnerVMUIDList, vendorMasterObjList);
        } catch(Exception e) {
            // insert log with strResponse exception
            logListToInsert.add(new LogService().createErrorLog('VendorMasterSubscriberCtrl', 'subscribeToVendorMasterFromPartnerOrg()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                  system.Json.serialize(vendorMasterNameSet), LogService.AUTOMATED_PRICE_FILE, false));
        }
        
        if(logListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Log__c', logListToInsert);
        }
    }

    global static void unsubscribeToVendorMasterFromPartnerOrg(Set<String> vendorMasterNameSet) {
        // send request to partner org and get the vendor master details
        List<VendorMasterSubscriberService.SubscriberResponseWrapper> responseObjList = VendorMasterSubscriberService.sendUnsubscribeRequest(new List<String>(vendorMasterNameSet));
        VendorMasterSubscriberService.handleUnsubscribeResponse(vendorMasterNameSet, responseObjList);
    }

    private static void deleteVendorMaster(String vendorMasterId) {
        DMLUtility.deleteSobjectList('Escalator__c', [SELECT Id FROM Escalator__c WHERE APF_Mapping__r.Vendor_Master__c = :vendorMasterId]);
        VendorMasterTriggerHelper.isForceStopTrigger = true;
        DMLUtility.deleteSobjectList('Vendor_Master__c', new Vendor_Master__c(Id = vendorMasterId));
        VendorMasterTriggerHelper.isForceStopTrigger = false;
    }
}