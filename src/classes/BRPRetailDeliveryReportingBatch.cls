/** 
* Author: Manoj Sharma
* Since: June 25, 2020 
* Name: BRPRetailDeliveryReportingBatch 
* Description: Apex batch class to send unit data on BRP.
**/
global without sharing class BRPRetailDeliveryReportingBatch extends BRPBaseSyncingBatch {
    public Set<String> brpVendorsIdSet;
    public Set<String> brpUnitMakeIdSet;
	
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('CO_Invoice_Header__c', new List<String>(BRPRetailDeliveryReportingService.objectToFieldMap.get('COInvoiceHeader')), new Map<String, List<String>>()));
    }

    global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> coInvList) {
        brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
        brpUnitMakeIdSet = BRPUtility.getAllBRPUnitMakeIdSet();
        Map<String, List<Deal__c>> coInvHeaderIdToDealListMap = getCOInvHeaderToDealListMap(coInvList);
        
        Set<String> dealIdSet = new Set<String>();
        for(List<Deal__c> dealList :coInvHeaderIdToDealListMap.values()) {
        	for(Deal__c dealRec : dealList) {
        		dealIdSet.add(dealRec.Id);
        	}
        }

        for(CO_Invoice_Header__c customerInvoiceRec : coInvList) {
        	try {
        		List<Deal__c> dealList = coInvHeaderIdToDealListMap.containsKey(customerInvoiceRec.Id) ? 
                                                        coInvHeaderIdToDealListMap.get(customerInvoiceRec.Id) : new List<Deal__c>();
	        	if(dealList.size() > 0) {
                    String requestBody = BRPRetailDeliveryReportingService.createRequestBody(dealList);
                    System.debug(requestBody);
		            HttpResponse response = BRPUtility.syncToBRP('BRPRetailDeliveryReporting', requestBody);
		            
		            populateBRPLogRec(BRPUtility.handleResponse(this.syncEntityName, requestBody, response), customerInvoiceRec);
		            if(response.getStatusCode() == 200) {
		            	updateInvoiceSyncFlag(customerInvoiceRec);
		            }
	        	}
        	} catch(Exception e) {
        		this.brpLogs.add(new BRPLogService().sampleLog(this.syncEntityName, String.valueOf(customerInvoiceRec), null, null, LogService.NOT_APPLICABLE, 
        														(e.getMessage() + '\n\n' + e.getStackTraceString()), 'Error', 'BRPRetailDeliveryReporting', 
        														'execute', customerInvoiceRec.Id));
	    	}
        }
    }
 
    global override void finish(Database.batchableContext bc) {
    	finishAction();
    }
    
    private Map<String, List<Deal__c>> getCOInvHeaderToDealListMap(List<CO_Invoice_Header__c> coInvList) {
    	String query = 'SELECT ';
        for(String fieldName : BRPRetailDeliveryReportingService.objectToFieldMap.get('Deal')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query += ' (Select ';
        for(String fieldName : BRPRetailDeliveryReportingService.objectToFieldMap.get('DealItem')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM Deal_Items__r WHERE Customer_Owned_Unit__r.Vendor__c IN: brpVendorsIdSet OR Customer_Owned_Unit__r.Unit_Make__c IN: brpUnitMakeIdSet OR Type__c = \'Trade In\'), ';
        
        query += ' (Select ';
        for(String fieldName : BRPRetailDeliveryReportingService.objectToFieldMap.get('DealFinance')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM Deal_Finances__r)';
        
        query += ' FROM Deal__c WHERE Invoice_Number__c IN: coInvList';
        
        Map<String, List<Deal__c>> coInvHeaderIdToDealListMap = new Map<String, List<Deal__c>>();
        System.debug(query);
        for(Deal__c dealRec: Database.query(query)) {
        	if(!coInvHeaderIdToDealListMap.containsKey(dealRec.Invoice_Number__c)) {
        		coInvHeaderIdToDealListMap.put(dealRec.Invoice_Number__c, new List<Deal__c>());
        	}
        	coInvHeaderIdToDealListMap.get(dealRec.Invoice_Number__c).add(dealRec);
        }
        return coInvHeaderIdToDealListMap;
    }
}