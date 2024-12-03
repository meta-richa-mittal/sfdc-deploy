/**
 * Author: Nidhi Sharma
 * Since: July 22, 2019
 * Name: SyncPaymentOnAccountBatch
 * Description: 
**/
global without sharing class SyncPaymentOnAccountBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Payment_on_Account__c', AccountingPaymentOnAccount.fieldsList(), IntegrationUtility.PAYMENT_ON_ACCOUNT));
    }

    global void execute(Database.batchableContext bc, List<Payment_on_Account__c> paymentOnAccountList) {
        for(Payment_on_Account__c paymentOnAccountRec : paymentOnAccountList) {
        	String accId = String.valueOf(paymentOnAccountRec.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.PAYMENT_ON_ACCOUNT).Integration_Id_API_Name__c));
    		Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.JOURNAL_ENTRY => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
        	this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingPaymentOnAccount>{new AccountingPaymentOnAccount(paymentOnAccountRec)}, (List<SObject>) sobjctListToUpdate, 
                                                IntegrationUtility.PAYMENT_ON_ACCOUNT, integrationEntityNameToActionMap));
        }
    }
 
    global override void finish(Database.batchableContext bc) {
    	PaymentOnAccountTriggerHelper.isForceStopTrigger = true;
		finishAction();
		PaymentOnAccountTriggerHelper.isForceStopTrigger = false;
    }
}