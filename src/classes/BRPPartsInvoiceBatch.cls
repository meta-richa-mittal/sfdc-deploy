/*
    Apex class to sync parts invoices to BRP
*/
global without sharing class BRPPartsInvoiceBatch extends BRPBaseSyncingBatch {

    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('CO_Invoice_Header__c', new List<String>(BRPPartsInvoiceService.objectToFieldMap.get('COInvoiceHeader')), new Map<String, List<String>>()));
    }

	global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> coInvList) {
		Map<String, List<CO_Line_Item__c>> coInvHeaderIdToCOLIListMap = getCOInvHeaderToCOLIListMap(coInvList);
	    Map<String, Account> customerIdToRecMap = BRPUtility.getCustomerIdToRecMap(coInvList);
        
        for(CO_Invoice_Header__c customerInvoiceRec : coInvList) {
        	try {
        		List<CO_Line_Item__c> coliList = coInvHeaderIdToCOLIListMap.containsKey(customerInvoiceRec.Id) ? coInvHeaderIdToCOLIListMap.get(customerInvoiceRec.Id) : new List<CO_Line_Item__c>();
	        	Account customerRec = customerIdToRecMap.containsKey(customerInvoiceRec.CO_Header__r.Customer__c) ? 
                                  										customerIdToRecMap.get(customerInvoiceRec.CO_Header__r.Customer__c) : null;
	        	String requestBody = BRPPartsInvoiceService.createRequestBody(customerInvoiceRec, customerRec, coliList);
	            HttpResponse response = BRPUtility.syncToBRP('BRPPartsInvoice', requestBody);
	            
	            populateBRPLogRec(BRPUtility.handleResponse(this.syncEntityName, requestBody, response), customerInvoiceRec);
	            if(response.getStatusCode() == 200) {
	            	updateInvoiceSyncFlag(customerInvoiceRec);
	            }
			} catch(HttpRequestException e) {
        		BRPUtility.checkForRetryLogic(e, customerInvoiceRec, this.retryRequestNumber, this.failedRecordsMap);
        	} catch(Exception e) {
				BRPUtility.checkForRetryLogic(e, customerInvoiceRec, this.retryRequestNumber, this.failedRecordsMap);
        		this.brpLogs.add(new BRPLogService().sampleLog(this.syncEntityName, String.valueOf(customerInvoiceRec), null, null, LogService.NOT_APPLICABLE, 
        														(e.getMessage() + '\n\n' + e.getStackTraceString()), 'Error', 'BRPPartsInvoiceBatch', 
        														'execute', customerInvoiceRec.Id));
	    	}
        }
    }
 
    global override void finish(Database.batchableContext bc) {
    	finishAction();
    }
    
    private static Map<String, List<CO_Line_Item__c>> getCOInvHeaderToCOLIListMap(List<CO_Invoice_Header__c> coInvList) {
    	String query = 'SELECT ';
        for(String fieldName : BRPPartsInvoiceService.objectToFieldMap.get('COLineItem')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query += '( SELECT ';
    	for(String fieldName : BRPPartsInvoiceService.objectToFieldMap.get('IndividualTax')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
    	query += ' FROM Individual_Taxes__r )';
        query += ' FROM CO_Line_Item__c WHERE Invoice_Number__c IN: coInvList AND Service_Order_Line_Item__c = null';
        
        Map<String, List<CO_Line_Item__c>> coInvHeaderIdToCOLIListMap = new Map<String, List<CO_Line_Item__c>>();
        for(CO_Line_Item__c coliRec: Database.query(query)) {
        	if(!coInvHeaderIdToCOLIListMap.containsKey(coliRec.Invoice_Number__c)) {
        		coInvHeaderIdToCOLIListMap.put(coliRec.Invoice_Number__c, new List<CO_Line_Item__c>());
        	}
        	coInvHeaderIdToCOLIListMap.get(coliRec.Invoice_Number__c).add(coliRec);
        }
        
        return coInvHeaderIdToCOLIListMap;
    }
}