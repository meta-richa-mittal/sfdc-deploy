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
    	if(!QBUtil.isQBEnabled()) {
    		try {
				integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
				IntegrationSyncFlagService.manageARPaymentSyncFlag(new List<BaseIntegrationService>{integrationRec}, newList);
            } catch(Exception e) {
            
            }
        }
    }
    
    public static void syncToAccounting(List<AR_Payment__c> newList) {
        Set<Id> arPaymentIdSet = new Set<Id>();
        for(AR_Payment__c arPaymentRec : newList){
            if(!QBUtil.isQBEnabled() && integrationRec != null) {
                if(arPaymentRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.AR_PAYMENT).Sync_Flag_API_Name__c) != null && 
                    Boolean.valueOf(arPaymentRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.AR_PAYMENT).Sync_Flag_API_Name__c))) {
                    arPaymentIdSet.add(arPaymentRec.Id);
                }
            }
        }
        if(arPaymentIdSet.size() > 0) {
            if(!QBUtil.isQBEnabled()) {
                IntegrationBatchService.initiateBatch(arPaymentIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.AR_PAYMENT);
            }
        }
    }
}