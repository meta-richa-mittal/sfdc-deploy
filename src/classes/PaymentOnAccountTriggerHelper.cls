/**
 * Author: R
 * Since: July 18, 2019
 * Name: PaymentOnAccountTriggerHelper
 * Description: Trigger executes on after insert event of Payment on Account object
**/
public without sharing class PaymentOnAccountTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    private static BaseIntegrationService integrationRec;

    public static void beforeInsert(List<Payment_on_Account__c> newList) {
        setPOAAccountingSyncFlag(newList);
    }
    
    public static void beforeUpdate(List<Payment_on_Account__c> newList, Map<Id, Payment_on_Account__c> oldMap) {
        setARPaymentAccountingSyncFlag(newList, oldMap);
    }

    public static void afterInsert(List<Payment_on_Account__c> newList) {
        syncPOAToAccounting(newList);
    }

    public static void afterUpdate(List<Payment_on_Account__c> newList, Map<Id, Payment_on_Account__c> oldMap) {
        syncARPaymentToAccounting(newList);
    }

    private static void setPOAAccountingSyncFlag(List<Payment_on_Account__c> newList) {
        IntegrationSyncFlagService.managePaymentOnAccountSyncFlag(newList);
    }

    private static void syncPOAToAccounting(List<Payment_on_Account__c> newList) {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(newList, IntegrationUtility.PAYMENT_ON_ACCOUNT);
    }
    
    private static void setARPaymentAccountingSyncFlag(List<Payment_on_Account__c> newList, Map<Id, Payment_on_Account__c> oldMap) {
        IntegrationSyncFlagService.manageARPaymentSyncFlagForQB(newList, oldMap);
    }
        
    private static void syncARPaymentToAccounting(List<Payment_on_Account__c> newList) {
        if(QBUtil.isQBEnabled()) IntegrationSyncFlagService.checkAndInitiateSyncBatch(newList, IntegrationUtility.QB_AR_PAYMENT);      
    }
}