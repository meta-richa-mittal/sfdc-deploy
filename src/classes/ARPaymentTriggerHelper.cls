/**
 * Author: Nidhi Sharma
 * Since: July 18, 2019
 * Name: ARPaymentTriggerHelper
 * Description: Trigger executes on after insert event of AR Payment object
**/
public without sharing class ARPaymentTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    private static BaseIntegrationService integrationRec;
    
    public static void beforeInsert(List<AR_Payment__c> newList) {
    	setAccountingSyncFlag(newList);
    }
    
    public static void afterInsert(List<AR_Payment__c> newList) {
    	syncToAccounting(newList);
    }
    
    public static void setAccountingSyncFlag(List<AR_Payment__c> newList) {
    	if(!QBUtil.isQBEnabled()) IntegrationSyncFlagService.manageARPaymentSyncFlag(newList);
    }
    
    public static void syncToAccounting(List<AR_Payment__c> newList) {
        if(!QBUtil.isQBEnabled()) IntegrationSyncFlagService.checkAndInitiateSyncBatch(newList, IntegrationUtility.AR_PAYMENT);
    }
}