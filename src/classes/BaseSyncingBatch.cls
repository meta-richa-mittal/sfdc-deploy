global without sharing abstract class BaseSyncingBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    public Set<Id> idSet;
    public String integrationEntityName;
    public String activeIntegrationName;
    public String oldAccessToken;
    public List<BaseIntegrationService> integrationInstanceList;
    public List<WebService_Log__c> webserviceLogs;
    global List<Sobject> sobjctListToUpdate;
    public DateTime accPeriodCloseDate;
    
    public BaseSyncingBatch() {
        this.webserviceLogs = new List<WebService_Log__c>();
        sobjctListToUpdate = new List<Sobject>();
    }
    
    public BaseSyncingBatch(Set<Id> idSet) {
        this.idSet = idSet;
    }
    
    global virtual Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
    
    global virtual void execute(Database.batchableContext bc, List<Sobject> listItemCategories) {}
    global virtual void finish(Database.batchableContext bc){}
    
    public void setIdSet(Set<Id> idSet) {
        this.idSet = idSet;
    }
    
    public void setIntegrationInstanceList(List<BaseIntegrationService> integrationInstanceList) {
        this.integrationInstanceList = integrationInstanceList;
    }

    public void setIntegrationDetails(String activeIntegrationName, String integrationEntityName) {
        this.activeIntegrationName = activeIntegrationName;
        this.integrationEntityName = integrationEntityName;
    }
    
    public String getBaseQuery(String objectAPIName, List<String> fieldsList, String integrationEntityName) {
        return getBaseQuery(objectAPIName, fieldsList, integrationEntityName, new Map<String, List<String>>());
    }
    
    public String getBaseQuery(String objectAPIName, List<String> fieldsList, String integrationEntityName, 
                                                        Map<String, List<String>> childObjectAPINameToFieldsListMap) {
        this.integrationEntityName = integrationEntityName;
        setIntegrationInstanceList();
        this.oldAccessToken = integrationInstanceList[0].integrationConfigRec.Access_Token__c;
        String syncFlag = integrationInstanceList[0].integrationEntityNameToRecMap.get(integrationEntityName).Sync_Flag_API_Name__c;
        
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
    
    public void finishAction() {
        if(!checkForInvalidRefreshToken() && hasAccessTokenChanged()) {
    		update integrationInstanceList[0].integrationConfigRec;
    	}
        updateSobjectList(this.sobjctListToUpdate);
        if(integrationInstanceList[0].errorLogs.size() > 0) {
            insert integrationInstanceList[0].errorLogs;
        }
        if(!this.webserviceLogs.isEmpty()) {
           insert this.webserviceLogs;
        }
        if(integrationInstanceList[0].qbTermsList != null && !integrationInstanceList[0].qbTermsList.isEmpty()){
            QBTermService.deleteExistingTermsInBP();
            DMLUtility.insertSobjectList('QB_Term__c', integrationInstanceList[0].qbTermsList);
        }
        
        // In case of any technical failure, try resyncing the failed entity.
        doRetry();
    }
    
    public Boolean checkForInvalidRefreshToken() {
        Boolean isInvalidRefreshToken = false;
        for(Sobject sObjectRec : this.sobjctListToUpdate) {
            if(XeroUtility.entityTypeToAccResponseAPINameMap.containsKey(this.integrationEntityName)) {
                String fieldAPIName = XeroUtility.entityTypeToAccResponseAPINameMap.get(this.integrationEntityName);
                if(sObjectRec.get(fieldAPIName) != null && String.valueOf(sObjectRec.get(fieldAPIName)).containsIgnoreCase('invalid_grant')) {
                    isInvalidRefreshToken = true;
                    break;
                }
            }
        }
        return isInvalidRefreshToken;
    }
    
    public Boolean hasAccessTokenChanged() {
        return (this.oldAccessToken != integrationInstanceList[0].integrationConfigRec.Access_Token__c);
    }
    
    public void doRetry() {
        if(!integrationInstanceList[0].failedRecordsMap.IsEmpty()) {
            Map<String, Integration_Error_Handling_Config__mdt> errorTypeToRetryConfigListMap = AccountingUtil.getRetryConfigsByIntegration(this.activeIntegrationName);
            IntegrationExceptionHandler exceptionHandlerObj = new IntegrationExceptionHandler(this.integrationEntityName);
            
            for(String errorType : integrationInstanceList[0].failedRecordsMap.keySet()) {
                system.debug(' == errorType == ' + errorType);
                Integration_Error_Handling_Config__mdt retryConfig = errorTypeToRetryConfigListMap.get(errorType);
                
                if(retryConfig.Retry_After_sec__c != null) {
                    if(retryConfig.Retry_After_sec__c < 10) {
                        exceptionHandlerObj.doRetry(this.idSet, this.integrationInstanceList[0], retryConfig.Required_GET_call__c);
	                } else {
	                    exceptionHandlerObj.doRetryWithScheduledJob(this.integrationInstanceList[0], 
	                                                                 Integer.valueOf(retryConfig.Retry_After_sec__c), errorType);
	                }
                }
            }
        }
    }
    
    public void updateSobjectList(List<Sobject> sobjectList){
    	Map<Id,Sobject> IdToSObjectValueMap = new Map<Id,Sobject>();
    	for(Sobject sObjectRec : sobjectList) {
    		IdToSObjectValueMap.put(sObjectRec.Id,sObjectRec);
        }
	    if(IdToSObjectValueMap != null && IdToSObjectValueMap.size() > 0) {
            updateSObjectListValue(IdToSObjectValueMap.values());       
		}
    }

    public void updateSObjectListValue(List<Sobject> sobjectRecList) {
        try {
            DMLUtility.updateSobjectListWithRetry(sobjectRecList);        
        } catch (Exception ex) {
            integrationInstanceList[0].errorLogs.add(
                new LogService().createErrorLog('BaseSyncingBatch', 'updateSobjectList()', ex.getMessage(), LogService.NOT_APPLICABLE, ex.getStackTraceString(), 
                String.valueOf(sobjectRecList[0]), LogService.XERO, false, 'Error'));
        }
    }

    private void setIntegrationInstanceList() {
        if(this.integrationInstanceList == null) {
            this.integrationInstanceList = new List<BaseIntegrationService>();
            this.integrationInstanceList.add(IntegrationServiceFactory.getIntegrationServiceInstance('Accounting'));
            this.integrationInstanceList[0].integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{this.integrationEntityName}, this.activeIntegrationName);
        }
    }

    public void setAccPeriodCloseDate() {
        String accCloseDateStr;
        if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
            accCloseDateStr = QBUtil.getAccountingClosedDateWithRefreshToken(integrationInstanceList[0].integrationConfigRec);
            if(String.isNotBlank(accCloseDateStr)) {
                Date closeDate = DateTimeUtility.getDateFromFormattedDateStr(accCloseDateStr, 'YYYY-MM-DD');
                if(closeDate != null) {
                    accPeriodCloseDate = DateTimeUtility.getDateTimeFromDate(closeDate);
                }
            }
        } else if(activeIntegrationName == XeroUtility.XERO) {
            accCloseDateStr = XeroUtility.getAccountingClosedDateWithRefreshToken(null);
            if(String.isNotBlank(accCloseDateStr)) {
                accPeriodCloseDate = DateTimeUtility.getDateTimeFromMSAjaxDateStr(accCloseDateStr);
            }
        }
    }
}