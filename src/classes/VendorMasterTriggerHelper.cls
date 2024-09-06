public with sharing class VendorMasterTriggerHelper {

    public static Boolean isForceStopTrigger = false;
    public static List<Vendor_Master__c> vendorMasterOldList = new List<Vendor_Master__c>();

    public static void beforeDelete() {
        for(Vendor_Master__c vmToDelete: vendorMasterOldList) {
			vmToDelete.addError('Use "Unsubscribe and delete" action to delete vendor master.');
		}
    }
}