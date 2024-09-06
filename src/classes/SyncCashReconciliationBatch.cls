global without sharing class SyncCashReconciliationBatch extends BaseSyncingBatch {
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Cash_Reconciliation__c', AccountingCashReconciliation.fieldsList(), IntegrationUtility.CASH_RECONCILIATION));
    }
    
    global void execute(Database.batchableContext bc, List<Cash_Reconciliation__c> listCashRecon) {
    	for(Cash_Reconciliation__c cashRecon : listCashRecon) {
        	String accId = String.valueOf(cashRecon.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.CASH_RECONCILIATION).Integration_Id_API_Name__c));
    		Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.JOURNAL_ENTRY => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
        	this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingCashReconciliation>{new AccountingCashReconciliation(cashRecon)}, (List<SObject>) sobjctListToUpdate, 
                                            IntegrationUtility.CASH_RECONCILIATION, integrationEntityNameToActionMap));
        }
    }
    
    global override void finish(Database.batchableContext bc){
        CashReconciliationTriggerHelper.isForceStopTrigger = true;
        finishAction();
        CashReconciliationTriggerHelper.isForceStopTrigger = false;
    }
}