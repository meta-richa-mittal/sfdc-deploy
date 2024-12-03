global without sharing class SyncCOInvoiceBatch extends BaseSyncingBatch {
    public List<CO_Invoice_Header__c> coinvoiceList = new List<CO_Invoice_Header__c>(); 
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
    	Map<String, List<String>> childObjectAPINameToFieldsList = new Map<String, List<String>>{'CO_Invoice_Payments__r' => new List<String>(AccountingCOInvoicePayment.fieldsList())};
        return Database.getQueryLocator(getBaseQuery('CO_Invoice_Header__c', new List<String>(AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')), IntegrationUtility.INVOICE, childObjectAPINameToFieldsList));
    }
    
    global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> listCOInvoice) {
        coinvoiceList = listCOInvoice;
		Set<Id> coInvoiceIdSet = new Set<Id>();
        for(CO_Invoice_Header__c invoiceRec : listCOInvoice) {
        	coInvoiceIdSet.add(invoiceRec.Id);
        }
        Map<String, List<CO_Invoice_Item__c>> invoiceIdToInvoiceItemListMap = AccountingUtil.getInvoiceIdToInvoiceItemListMap(coInvoiceIdSet);
    	for(CO_Invoice_Header__c customerInvoice : listCOInvoice) {
            AccountingCustomerInvoice customerInvoiceObj =  new AccountingCustomerInvoice(customerInvoice, (invoiceIdToInvoiceItemListMap.get(customerInvoice.Id)),customerInvoice.CO_Invoice_Payments__r,null);
    		
        	String accId = String.valueOf(customerInvoice.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.INVOICE).Integration_Id_API_Name__c));
			Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{customerInvoiceObj.SyncingObjectType => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
	    	this.webserviceLogs = integrationInstanceList[0].sync(new List<AccountingCustomerInvoice>{customerInvoiceObj}, (List<SObject>) sobjctListToUpdate, 
	                                    IntegrationUtility.INVOICE, integrationEntityNameToActionMap);
        }
    }
    
    global override void finish(Database.batchableContext bc){
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(coinvoiceList, IntegrationUtility.CO_INVOICE_JE);
        List<Deal_Item__c> dealItemList = checkLienPayoutsForSync(idSet);
        if(dealItemList.size() > 0) {
        	IntegrationSyncFlagService.checkAndInitiateSyncBatch(dealItemList, IntegrationUtility.LIEN_PAYOUT);
        }
        finishAction();
    }
    
    private static List<Deal_Item__c> checkLienPayoutsForSync(Set<Id> setcustomerInvoiceIds) {
    	if(!AccessControl.ifObjectFieldIsAccessible('Deal_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Deal_Item__c> dealItemList = [SELECT Id, Lien_Payout_Avail_For_Xero_Sync__c, Lien_Payout_Avail_For_QB_Sync__c FROM Deal_Item__c WHERE Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN AND Lien_Payout__c > 0 
        										AND Finance_Company__c != null AND (Lien_Payout_Avail_For_Xero_Sync__c = true OR Lien_Payout_Avail_For_QB_Sync__c = true)
        										AND Deal__r.Invoice_Number__c IN: setcustomerInvoiceIds];
        return dealItemList;
        }
}
