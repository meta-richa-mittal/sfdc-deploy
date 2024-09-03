/**
 * Author: Nidhi Sharma
 * Since: July 22, 2019
 * Name: SyncARPaymentBatch
 * Description: 
**/
global without sharing class SyncARPaymentBatch extends BaseSyncingBatch {
    
    global List<AR_Payment__c> arPaymentListToUpdate;
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('AR_Payment__c', AccountingARPayment.fieldsList(), IntegrationUtility.AR_PAYMENT));
    }

    global void execute(Database.batchableContext bc, List<AR_Payment__c> arPaymentList) {
        for(AR_Payment__c arPaymentRec : arPaymentList) {
        	String accId = String.valueOf(arPaymentRec.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.AR_PAYMENT).Integration_Id_API_Name__c));
        	Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.INVOICE_PAYMENT => IntegrationUtility.CREATE_ACTION};
        	this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingARPayment>{new AccountingARPayment(arPaymentRec)}, (List<SObject>) sobjctListToUpdate, 
                                                IntegrationUtility.AR_PAYMENT, integrationEntityNameToActionMap));
        }
    }
 
    global override void finish(Database.batchableContext bc){
    	finishAction();
    }
}