/**
 * Author: Richa Mittal
 * Since: Jan 09, 2017
 * Name: VendorReceivingHeaderTriggerHelper
 * Description: Helper class for triggers on Vendor_Receiving_Header__c object
**/
public without sharing class VendorReceivingHeaderTriggerHelper {
    // List to store trigger new list
    public static List<Vendor_Receiving_Header__c> receivingNewList = new List<Vendor_Receiving_Header__c>();
    
    // List to store trigger old list
    public static List<Vendor_Receiving_Header__c> receivingOldList = new List<Vendor_Receiving_Header__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Vendor_Receiving_Header__c> receivingNewMap = new Map<Id, Vendor_Receiving_Header__c>();

    // Map to store Old Trigger Map
    public static Map<Id, Vendor_Receiving_Header__c> receivingOldMap = new Map<Id, Vendor_Receiving_Header__c>();
     
    // Trigger run boolean
    public static Boolean isTriggerRun;
    
    // Trigger run boolean
    public static Boolean preventOnAccountingSync = false;
    
    private static BaseIntegrationService integrationRec;
    
    
    public static void populatesAccountingSyncFields() {
		IntegrationSyncFlagService.manageVendorReceivingSyncFlag(receivingNewList, receivingOldMap);
        }
    
    public static void setVendorReceivingDataForAccountSync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(receivingOldMap, receivingNewList, IntegrationUtility.VENDOR_RECEIVING);
    }
}