global without sharing abstract class BRPBaseSyncingBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    public Set<Id> idSet;
    public String syncEntityName;
    public List<BRP_Log__c> brpLogs;
    global List<Sobject> sobjctListToUpdate;
    public Map<String, List<SObject>> failedRecordsMap;
    public Integer retryRequestNumber;
    
    public BRPBaseSyncingBatch() {
        this.brpLogs = new List<BRP_Log__c>();
        sobjctListToUpdate = new List<Sobject>();
        failedRecordsMap = new Map<String, List<SObject>>();
        retryRequestNumber = 1;
    }
    
    global virtual Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
    
    global virtual void execute(Database.batchableContext bc, List<Sobject> recordsList) {}
    
    global virtual void finish(Database.batchableContext bc){}
    
    public void setIdSet(Set<Id> idSet) {
        this.idSet = idSet;
    }
    
    public void setSyncEntityName(String syncEntityName) {
        this.syncEntityName = syncEntityName;
    }
    
    public String getBaseQuery(String objectAPIName, List<String> fieldsList, 
    							Map<String, List<String>> childObjectAPINameToFieldsListMap) {
        String syncFlag = BRPUtility.syncEntityNameToSyncFlagAPINameMap.get(syncEntityName);
        
        String query = 'SELECT ';
        for(String fieldName : fieldsList){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        for(String childObjectAPIName : childObjectAPINameToFieldsListMap.keyset()) {
        	query += '( SELECT ';
        	for(String fieldName : childObjectAPINameToFieldsListMap.get(childObjectAPIName)) {
	            fieldName = BPUtility.escapeSingleQuotes(fieldName);
	            query += fieldName + ', ';
	        }
	        query = query.substring(0, query.length() - 2);
        	query += ' FROM ' + childObjectAPIName + ' ), ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM ' + objectAPIName + ' WHERE ' + syncFlag + ' = true';
        if(idSet != null) {
            query += ' AND Id IN: idSet';
        }
        return query;
    }
    
    public void populateBRPLogRec(BRP_log__c brpLogRec, CO_Invoice_Header__c customerInvoiceRec) {
    	brpLogRec.CO_Invoice_Header__c = customerInvoiceRec.Id;
    	brpLogRec.Apex_Class__c = String.valueOf(BRPUtility.syncEntityNameToBatchName.get(syncEntityName));
		brpLogRec.Method__c = 'execute';
		this.brpLogs.add(brpLogRec);
    }
    
    public void updateInvoiceSyncFlag(CO_Invoice_Header__c customerInvoiceRec) {
		customerInvoiceRec.put(BRPUtility.syncEntityNameToSyncFlagAPINameMap.get(syncEntityName), false);
		this.sobjctListToUpdate.add(customerInvoiceRec);
    }
    
    public void finishAction() {
    	try {
    		if(!this.sobjctListToUpdate.isEmpty()) {
                BPUtility.updateRecordList(this.sobjctListToUpdate, 0);
			}
	        if(!this.brpLogs.isEmpty()) {
	           insert this.brpLogs;
	        }
            doRetry();

    	} catch(Exception e) {
    		String customerInvoiceId;
    		if(this.sobjctListToUpdate.size() > 0 && String.valueOf(this.sobjctListToUpdate[0].getSObjectType()) == Constants.NAMESPACE + 'CO_Invoice_Header__c') {
    			customerInvoiceId = String.valueOf(sobjctListToUpdate[0].get('Id'));
    		}
    		new BRPLogService().createLog(this.syncEntityName, (this.sobjctListToUpdate + '\n\n' + this.brpLogs), null, null, LogService.NOT_APPLICABLE, 
        														(e.getMessage() + '\n\n' + e.getStackTraceString()), 'Error', 'BRPPartsInvoiceBatch', 
        														'finish', customerInvoiceId);
    	}
    }

    public void doRetry() {
        if(!failedRecordsMap.IsEmpty()) {
            Map<String, Integration_Error_Handling_Config__mdt> errorTypeToRetryConfigListMap = AccountingUtil.getRetryConfigsByIntegration(BRPUtility.BRP);
            BRPIntegrationExceptionHandler exceptionHandlerObj = new BRPIntegrationExceptionHandler(this.syncEntityName);
            
            for(String errorType : failedRecordsMap.keySet()) {
                system.debug(' == errorType == ' + errorType);
                Integration_Error_Handling_Config__mdt retryConfig = errorTypeToRetryConfigListMap.get(errorType);
                
                if(retryConfig.Retry_After_sec__c != null) {
                    if(retryConfig.Retry_After_sec__c < 10) {
                        exceptionHandlerObj.doRetry(this.idSet, this.retryRequestNumber);
	                } else {
	                    exceptionHandlerObj.doRetryWithScheduledJob(this.idSet, Integer.valueOf(retryConfig.Retry_After_sec__c),  this.retryRequestNumber);
	                }
                }
            }
        }
    }
}