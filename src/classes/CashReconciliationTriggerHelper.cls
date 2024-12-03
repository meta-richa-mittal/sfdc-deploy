public without sharing class CashReconciliationTriggerHelper {
    public static List<Cash_Reconciliation__c> CashReconNewList = new List<Cash_Reconciliation__c>();
    public static Boolean preventOnAccountingSync = false;
    public static Boolean isForceStopTrigger = false;
    private static BaseIntegrationService integrationRec;

    public static void afterUpdate() {
        if(!preventOnAccountingSync) {
            setCashReconciliationForAccountingSync();
        }
    }
    
    private static void setCashReconciliationForAccountingSync() {
        preventOnAccountingSync = true;
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(CashReconNewList, IntegrationUtility.CASH_RECONCILIATION);
    }
}