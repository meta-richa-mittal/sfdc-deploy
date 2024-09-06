/**
 * Author: R
 * Since: July 18, 2019
 * Name: PaymentOnAccountTriggerHelper
 * Description: Trigger executes on after insert event of Payment on Account object
**/
public without sharing class PaymentOnAccountTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    private static BaseIntegrationService integrationRec;
    
    public static void beforeUpdate(List<Payment_on_Account__c> newList, Map<Id, Payment_on_Account__c> oldMap) {
        setAccountingSyncFlag(newList, oldMap);
    }
    
    public static void afterUpdate(List<Payment_on_Account__c> newList, Map<Id, Payment_on_Account__c> oldMap) {
        syncToAccounting(newList);
    }
    
    public static void setAccountingSyncFlag(List<Payment_on_Account__c> newList, Map<Id, Payment_on_Account__c> oldMap) {
        if(QBUtil.isQBEnabled()) {
            QBSyncFlagService.managePaymentOnAccountSyncFlag(newList, oldMap);
        } else {
            try {
               integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
               IntegrationSyncFlagService.managePaymentOnAccountSyncFlag(new List<BaseIntegrationService>{integrationRec}, newList, oldMap);
            } catch(Exception e) {
            
            }
        }
    }
    
    public static void syncToAccounting(List<Payment_on_Account__c> newList) {
        Set<Id> validPaymentOnAccountIdSet = new Set<Id>();
        Set<Id> validPOAIdSetForARPayment = new Set<Id>();
        for(Payment_on_Account__c paymentOnAccountRec : newList){
            if(QBUtil.isQBEnabled()) { 
            	if(paymentOnAccountRec.Available_For_QB_Sync__c) {
            		validPaymentOnAccountIdSet.add(paymentOnAccountRec.Id);
            	}
            	if(paymentOnAccountRec.Available_For_QB_AR_Payment_Sync__c) {
            		validPOAIdSetForARPayment.add(paymentOnAccountRec.Id);
            	}
            } else if(integrationRec != null) {
                if(paymentOnAccountRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.PAYMENT_ON_ACCOUNT).Sync_Flag_API_Name__c) != null && 
                    Boolean.valueOf(paymentOnAccountRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.PAYMENT_ON_ACCOUNT).Sync_Flag_API_Name__c))) {
                    validPaymentOnAccountIdSet.add(paymentOnAccountRec.Id);
                }
            }
        }
        if(validPaymentOnAccountIdSet.size() > 0) {
            if(QBUtil.isQBEnabled()) {
                QBPaymentOnAccountService.syncPaymentsOnAccount(validPaymentOnAccountIdSet);
            } else {
                IntegrationBatchService.initiateBatch(validPaymentOnAccountIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.PAYMENT_ON_ACCOUNT);
            }
        }
        
        if(validPOAIdSetForARPayment.size() > 0) {
            if(QBUtil.isQBEnabled()) {
                QBARPaymentService.syncARPayments(validPOAIdSetForARPayment);
            }
        }
    }
}