/**
 * Author: Nidhi Sharma
 * Since: June 24, 2020
 * Name: BRPRepairOrderBatch
 * Description: Batch class for BRP repair order posting
**/
global without sharing class BRPRepairOrderBatch extends BRPBaseSyncingBatch {

	public Set<String> brpVendorsIdSet;
    public Set<String> brpUnitMakeIdSet;
	
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('CO_Invoice_Header__c', new List<String>(BRPRepairOrderService.objectToFieldMap.get('COInvoiceHeader')), new Map<String, List<String>>()));
    }

    global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> coInvList) {
        brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
        brpUnitMakeIdSet = BRPUtility.getAllBRPUnitMakeIdSet();
        Map<String, List<Service_Order_Header__c>> coInvHeaderIdToSOListMap = getCOInvHeaderToSOListMap(coInvList);
        
        Set<String> soHeaderIdSet = new Set<String>();
        for(List<Service_Order_Header__c> soList :coInvHeaderIdToSOListMap.values()) {
        	for(Service_Order_Header__c soRec : soList) {
        		soHeaderIdSet.add(soRec.Id);
        	}
        }
        Map<String, Account> customerIdToRecMap = BRPUtility.getCustomerIdToRecMap(coInvList);
        Map<String, Map<String, List<Individual_Tax__c>>> invIdToSOIdToIndividualTaxListMap = getInvIdToSOIdToIndividualTaxListMap(soHeaderIdSet);
        
        for(CO_Invoice_Header__c customerInvoiceRec : coInvList) {
        	try {
        		List<Service_Order_Header__c> soList = coInvHeaderIdToSOListMap.containsKey(customerInvoiceRec.Id) ? 
        													coInvHeaderIdToSOListMap.get(customerInvoiceRec.Id) : new List<Service_Order_Header__c>();
        													
        		Map<String, List<Individual_Tax__c>> soIdToIndividualTaxListMap = invIdToSOIdToIndividualTaxListMap.containsKey(customerInvoiceRec.Id) ? 
        													invIdToSOIdToIndividualTaxListMap.get(customerInvoiceRec.Id) : new Map<String, List<Individual_Tax__c>>();
        													
        		Account customerRec = customerIdToRecMap.containsKey(customerInvoiceRec.CO_Header__r.Customer__c) ? 
        													customerIdToRecMap.get(customerInvoiceRec.CO_Header__r.Customer__c) : null;
	        	if(soList.size() > 0) {
		        	String requestBody = BRPRepairOrderService.createRequestBody(customerRec, soList, soIdToIndividualTaxListMap);
		            HttpResponse response = BRPUtility.syncToBRP('BRPRepairOrder', requestBody);
		            
		            populateBRPLogRec(BRPUtility.handleResponse(this.syncEntityName, requestBody, response), customerInvoiceRec);
		            if(response.getStatusCode() == 200) {
		            	updateInvoiceSyncFlag(customerInvoiceRec);
		            }
	        	}
        	} catch(HttpRequestException e) {
        		BRPUtility.checkForRetryLogic(e, customerInvoiceRec, this.retryRequestNumber, this.failedRecordsMap);
        	} catch(Exception e) {
				BRPUtility.checkForRetryLogic(e, customerInvoiceRec, this.retryRequestNumber, this.failedRecordsMap);
        		this.brpLogs.add(new BRPLogService().sampleLog(this.syncEntityName, String.valueOf(customerInvoiceRec), null, null, LogService.NOT_APPLICABLE, 
        														(e.getMessage() + '\n\n' + e.getStackTraceString()), 'Error', 'BRPRepairOrderBatch', 
        														'execute', customerInvoiceRec.Id));
	    	}
        }
    }
 
    global override void finish(Database.batchableContext bc) {
    	finishAction();
    }
    
    private Map<String, List<Service_Order_Header__c>> getCOInvHeaderToSOListMap(List<CO_Invoice_Header__c> coInvList) {
    	String query = 'SELECT ';
        for(String fieldName : BRPRepairOrderService.objectToFieldMap.get('SoHeader')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query += ' (Select ';
        for(String fieldName : BRPRepairOrderService.objectToFieldMap.get('SOLI')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM Service_Order_Line_Items__r), ';
        
        query += ' (Select ';
        for(String fieldName : BRPRepairOrderService.objectToFieldMap.get('TechnicianHour')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM Technician_Hours__r)';
        
        query += ' FROM Service_Order_Header__c WHERE Invoice_Number__c IN: coInvList AND (Customer_Owned_Unit__r.Vendor__c IN: brpVendorsIdSet OR Customer_Owned_Unit__r.Unit_Make__c IN: brpUnitMakeIdSet) ';
        
        Map<String, List<Service_Order_Header__c>> coInvHeaderIdToSOListMap = new Map<String, List<Service_Order_Header__c>>();
        for(Service_Order_Header__c soRec: Database.query(query)) {
        	if(!coInvHeaderIdToSOListMap.containsKey(soRec.Invoice_Number__c)) {
        		coInvHeaderIdToSOListMap.put(soRec.Invoice_Number__c, new List<Service_Order_Header__c>());
        	}
        	coInvHeaderIdToSOListMap.get(soRec.Invoice_Number__c).add(soRec);
        }
        
        return coInvHeaderIdToSOListMap;
    }
    
    private Map<String, Map<String, List<Individual_Tax__c>>> getInvIdToSOIdToIndividualTaxListMap(Set<String> soHeaderIdSet) {
    	String query = 'SELECT ';
        for(String fieldName : BRPRepairOrderService.objectToFieldMap.get('IndividualTax')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM Individual_Tax__c WHERE Service_Order_Line_Item__r.Service_Order_Header__c IN: soHeaderIdSet '; 
        
        Map<String, Map<String, List<Individual_Tax__c>>> invIdToSOIdToIndividualTaxListMap = new Map<String, Map<String, List<Individual_Tax__c>>>();
        for(Individual_Tax__c individualTaxRec : Database.query(query)) {
        	String invHeaderId;
        	String soId;
        	//if(individualTaxRec.Service_Order_Line_Item__c != null) {
    		invHeaderId = individualTaxRec.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c;
    		soId = individualTaxRec.Service_Order_Line_Item__r.Service_Order_Header__c;
        	/**} else {
        		invHeaderId = individualTaxRec.CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c;
        		soId = individualTaxRec.CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__c;
        	}**/
        	if(!invIdToSOIdToIndividualTaxListMap.containsKey(invHeaderId)) {
        		invIdToSOIdToIndividualTaxListMap.put(invHeaderId, new Map<String, List<Individual_Tax__c>>());
        	}
        	if(!invIdToSOIdToIndividualTaxListMap.get(invHeaderId).containsKey(soId)) {
        		invIdToSOIdToIndividualTaxListMap.get(invHeaderId).put(soId, new List<Individual_Tax__c>());
        	}
        	invIdToSOIdToIndividualTaxListMap.get(invHeaderId).get(soId).add(individualTaxRec);
        }
        
        return invIdToSOIdToIndividualTaxListMap;
    }
}