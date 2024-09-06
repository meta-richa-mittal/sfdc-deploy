/**
 * Author: Richa Mittal
 * Since: Nov 30, 2023
 * Name: ReturnCRHeaderTriggerHelper
 * Description: Helper class for triggers on ReturnCR object
**/
public without sharing class ReturnCRHeaderTriggerHelper {
	
    // List to store trigger new list
    public static List<Return_CR_Header__c> returnCRNewList = new List<Return_CR_Header__c>();
    
    // List to store trigger old list
    public static List<Return_CR_Header__c> returnCROldList = new List<Return_CR_Header__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Return_CR_Header__c> returnCRNewMap = new Map<Id, Return_CR_Header__c>();

    // Map to store Old Trigger Map
    public static Map<Id, Return_CR_Header__c> returnCROldMap = new Map<Id, Return_CR_Header__c>();
    
    private static BaseIntegrationService integrationRec;
    
    // Trigger run boolean
    public static Boolean preventOnAccountingSync = false;

    public static void populatesAccountingSyncFields() {
        if(!returnCRNewList.isEmpty()) IntegrationSyncFlagService.manageVOReturnSyncFlag(returnCRNewList, returnCROldMap);
    }
    
    public static void setReturnCreditDataForAccountSync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(returnCRNewList, IntegrationUtility.VO_RETURN);
    }
}