/**
 * Author: Nidhi Sharma
 * Since: Sept 10, 2019
 * Name: CountSessionTriggerHelper
 * Description: 
**/
public without sharing class CountSessionTriggerHelper {
    public static Boolean isForceStopTrigger = false;
    private static BaseIntegrationService integrationRec;
    
    public static void populatesAccountingSyncFields(List<Count_Session__c> countSessionNewList, Map<Id, Count_Session__c> countSessionOldMap) {
        IntegrationSyncFlagService.manageCountSessionSyncFlag( countSessionNewList, countSessionOldMap);
        
    }
    
    public static void setCountSessionDataForAccountingSync(List<Count_Session__c> countSessionNewList) {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(countSessionNewList, IntegrationUtility.COUNT_SESSION_JE);
    }
}