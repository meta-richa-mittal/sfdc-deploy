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
        if(QBUtil.isQBEnabled()) {
            QBSyncFlagService.manageCountSessionSyncFlag(countSessionNewList, countSessionOldMap);
        } else {
            integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
            if(integrationRec != null) {
                IntegrationSyncFlagService.manageCountSessionSyncFlag(new List<BaseIntegrationService>{integrationRec}, countSessionNewList, countSessionOldMap);
            }
        }
    }
    
    public static void setCountSessionDataForAccountingSync(List<Count_Session__c> countSessionNewList) {
        Set<Id> setCountSessionIds = new Set<Id>();
        for(Count_Session__c countSessionRec : countSessionNewList) {
            if(QBUtil.isQBEnabled()) {
                if(countSessionRec.Available_For_QB_Sync__c) {
                    setCountSessionIds.add(countSessionRec.Id);
                }
            } else if(integrationRec != null) {
                if(countSessionRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.COUNT_SESSION_JE).Sync_Flag_API_Name__c) != null && 
                    Boolean.valueOf(countSessionRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.COUNT_SESSION_JE).Sync_Flag_API_Name__c))) {
                    setCountSessionIds.add(countSessionRec.Id);
                }
            }
        }
        if(setCountSessionIds.size() > 0) {
            if(QBUtil.isQBEnabled()) {
                QBCountSessionService.syncCountSession(setCountSessionIds);
            } else {
                IntegrationBatchService.initiateBatch(setCountSessionIds, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.COUNT_SESSION_JE);
            }  
            
        }
    }
}