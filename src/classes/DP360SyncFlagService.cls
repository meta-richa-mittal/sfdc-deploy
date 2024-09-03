/**
 * Author: Tarun Khandelwal
 * Since: Nov 07, 2020
 * Name: DP360SyncFlagService
 * Description: Service class for setting/resetting sync flag value for DP360 Integration
**/
public without sharing class DP360SyncFlagService {
    
    public static void manageDealSyncFlag(List<Deal__c> newList, Map<Id, Deal__c> oldMap) {
        for(Deal__c dealRec : newList) {
            if(dealRec.DP360_Lead_Id__c != null && dealRec.Status__c != oldMap.get(dealRec.Id).Status__c && dealRec.Status__c == 'Invoiced') {
                dealRec.Available_For_DP360_Sync__c = true;
            }
        }
    }
}