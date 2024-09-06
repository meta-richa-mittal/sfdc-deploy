/**
 * Author: Balveer Choudhary
 * Since: Aug 23, 2022
 * Name: SyncQBARPaymentBatch
 * Description: Sync AR payment enteries on POA object for QB 
**/
global without sharing class SyncQBARPaymentBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, List<String>> childObjectAPINameToFieldsList = new Map<String, List<String>>{'AR_Payments__r' => new List<String>(AccountingARPayment.fieldsList())};
        return Database.getQueryLocator(getBaseQuery('Payment_on_Account__c', AccountingPaymentOnAccount.fieldsList(), IntegrationUtility.QB_AR_PAYMENT, childObjectAPINameToFieldsList));
    }

    global void execute(Database.batchableContext bc, List<Payment_on_Account__c> paymentOnAccountList) {
        Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
        String accId;

        for(Payment_on_Account__c paymentOnAccountRec : paymentOnAccountList) {
            Map<String, Integration_Entity__mdt> entityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.QB_AR_PAYMENT}, this.activeIntegrationName);
            accId = String.valueOf(paymentOnAccountRec.get(entityNameToRecMap.get(IntegrationUtility.QB_AR_PAYMENT).Integration_Id_API_Name__c));
            integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.INVOICE_PAYMENT => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
            this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingPaymentOnAccount>{new AccountingPaymentOnAccount(paymentOnAccountRec)}, (List<SObject>) sobjctListToUpdate, 
                                                IntegrationUtility.QB_AR_PAYMENT, integrationEntityNameToActionMap));
        }
    }
 
    global override void finish(Database.batchableContext bc){
        PaymentOnAccountTriggerHelper.isForceStopTrigger = true;
		finishAction();
		PaymentOnAccountTriggerHelper.isForceStopTrigger = false;
    }
}