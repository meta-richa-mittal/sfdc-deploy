global without sharing class BRPRetailTransactionBatch extends BRPBaseSyncingBatch {

    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('CO_Invoice_Header__c', new List<String>(BRPRetailTransactionService.objectToFieldMap.get('COInvoiceHeader')), new Map<String, List<String>>()));
    }

	global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> coInvList) {

		Map<String, List<CO_Line_Item__c>> coInvHeaderIdToCOLIListMap = BRPRetailTransactionService.getCOInvHeaderToCOLIListMap(coInvList);
		Map<String, List<Service_Order_Header__c>> coInvHeaderIdToSOListMap = BRPRetailTransactionService.getCOInvHeaderToSOListMap(coInvList);
		Map<String, List<Deal__c>> coInvHeaderIdToDealListMap = BRPRetailTransactionService.getCOInvHeaderToDealListMap(coInvList);
        
        for(CO_Invoice_Header__c customerInvoiceRec : coInvList) {
        	try {
        		List<CO_Line_Item__c> coliList = coInvHeaderIdToCOLIListMap.containsKey(customerInvoiceRec.Id) ? coInvHeaderIdToCOLIListMap.get(customerInvoiceRec.Id) : new List<CO_Line_Item__c>();
				List<Service_Order_Header__c> soList = coInvHeaderIdToSOListMap.containsKey(customerInvoiceRec.Id) ? coInvHeaderIdToSOListMap.get(customerInvoiceRec.Id) : new List<Service_Order_Header__c>();
				List<Deal__c> dealList = coInvHeaderIdToDealListMap.containsKey(customerInvoiceRec.Id) ? coInvHeaderIdToDealListMap.get(customerInvoiceRec.Id) : new List<Deal__c>();
	        	String requestBody = BRPRetailTransactionService.createRequestBody(customerInvoiceRec, coliList, soList, dealList);
	            HttpResponse response = BRPUtility.syncToBRP(BRPUtility.RETAIL_TRANSACTIONS, requestBody, 'POST', new Map<String, String>(), new Map<String, String> {'{{dealer_no}}' => BRP_Settings__c.getOrgDefaults().Dealer_Id__c});
	            
	            populateBRPLogRec(BRPUtility.handleResponse(this.syncEntityName, requestBody, response), customerInvoiceRec);
	            if(response.getStatusCode() == 200) {
	            	updateInvoiceSyncFlag(customerInvoiceRec);
	            }
			} catch(HttpRequestException e) {
        		BRPUtility.checkForRetryLogic(e, customerInvoiceRec, this.retryRequestNumber, this.failedRecordsMap);
        	} catch(Exception e) {
				BRPUtility.checkForRetryLogic(e, customerInvoiceRec, this.retryRequestNumber, this.failedRecordsMap);
        		this.brpLogs.add(new BRPLogService().sampleLog(this.syncEntityName, String.valueOf(customerInvoiceRec), null, null, LogService.NOT_APPLICABLE, 
        														(e.getMessage() + '\n\n' + e.getStackTraceString()), 'Error', 'BRPRetailTransactionBatch', 
        														'execute', customerInvoiceRec.Id));
	    	}
        }
    }
 
    global override void finish(Database.batchableContext bc) {
    	finishAction();
    }
}