/**
 * Author: Richa Mittal
 * Since: Aug 24, 2017
 * Name: StoreCreditTriggerHelper
 * Description: Helper class for triggers on Store Credit object
**/
public without sharing class StoreCreditTriggerHelper {
    // List to store trigger new list
    public static List<Store_Credit__c> storeCreditNewList = new List<Store_Credit__c>();
    
    // List to store trigger old list
    public static List<Store_Credit__c> storeCreditOldList = new List<Store_Credit__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Store_Credit__c> storeCreditNewMap = new Map<Id, Store_Credit__c>();

    // Map to store Old Trigger Map
    public static Map<Id, Store_Credit__c> storeCreditOldMap = new Map<Id, Store_Credit__c>();
    
    private static BaseIntegrationService integrationRec;
     
    // Trigger run boolean
    public static Boolean preventOnAccountingSync = false;
    
    public static void populatesAccountingSyncFields() {
        IntegrationSyncFlagService.manageStoreCreditSyncFlag(storeCreditNewList);
    }
    
    public static void setStoreCreditDataForAccountSync() { 
    	IntegrationSyncFlagService.checkAndInitiateSyncBatch(storeCreditNewList, IntegrationUtility.STORE_CREDIT);
	}
}