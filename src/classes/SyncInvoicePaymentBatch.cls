/**
 * Author: Richa Mittal
 * Since: Nov 01, 2022
 * Name: SyncInvoicePaymentBatch
 * Description: batch class for resyncing payments with invoices
**/
global without sharing class SyncInvoicePaymentBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, List<String>> childObjectAPINameToFieldsList = new Map<String, List<String>>{'CO_Invoice_Payments__r' => new List<String>(AccountingCOInvoicePayment.fieldsList())};
        return Database.getQueryLocator(getBaseQuery('CO_Invoice_Header__c', new List<String>(AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')), IntegrationUtility.INVOICE_PAYMENT, childObjectAPINameToFieldsList));
    }

    global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> coInvList) {
		Set<Id> coInvoiceIdSet = new Set<Id>();
        for(CO_Invoice_Header__c invoiceRec : coInvList) {
        	coInvoiceIdSet.add(invoiceRec.Id);
        }
        Map<String, List<CO_Invoice_Item__c>> invoiceIdToInvoiceItemListMap = AccountingUtil.getInvoiceIdToInvoiceItemListMap(coInvoiceIdSet);
    	for(CO_Invoice_Header__c customerInvoice : coInvList) {
            AccountingCustomerInvoice customerInvoiceObj =  new AccountingCustomerInvoice(customerInvoice, (invoiceIdToInvoiceItemListMap.get(customerInvoice.Id)),customerInvoice.CO_Invoice_Payments__r,null);
            
        	String accId = String.valueOf(customerInvoice.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.INVOICE_PAYMENT).Integration_Id_API_Name__c));
			Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.INVOICE_PAYMENT => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
	    	this.webserviceLogs = integrationInstanceList[0].sync(new List<AccountingCustomerInvoice>{customerInvoiceObj}, (List<SObject>) sobjctListToUpdate, 
	                                    IntegrationUtility.INVOICE_PAYMENT, integrationEntityNameToActionMap);
        }
    }
 
    global override void finish(Database.batchableContext bc) {
		finishAction();
    }
}