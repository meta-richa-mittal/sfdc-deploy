global without sharing class SyncCOInvoicePaymentBatch extends BaseSyncingBatch {
    
    global List<CO_Invoice_Payment__c> coInvoicePaymentListToUpdate;
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('CO_Invoice_Payment__c', AccountingCOInvoicePayment.fieldsList(), IntegrationUtility.CO_INVOICE_PAYMENT));
    }
    
    global void execute(Database.batchableContext bc, List<CO_Invoice_Payment__c> coInvoicePaymentList) {
        for(CO_Invoice_Payment__c coInvoicePaymentRec : coInvoicePaymentList){
            String accId = String.valueOf(coInvoicePaymentRec.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.CO_INVOICE_PAYMENT).Integration_Id_API_Name__c));
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.JOURNAL_ENTRY => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
            this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingCOInvoicePayment>{new AccountingCOInvoicePayment(coInvoicePaymentRec)}, (List<SObject>) sobjctListToUpdate, 
                                            IntegrationUtility.CO_INVOICE_PAYMENT, integrationEntityNameToActionMap));
        }
    }
    
    global override void finish(Database.batchableContext bc) {
        finishAction();
    }
}