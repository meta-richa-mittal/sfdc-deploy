/**
 * Author: Richa Mittal
 * Name: SetLastModifiedOnHistoricalDataBatch2
**/
global without sharing class SetLastModifiedOnHistoricalDataBatch2 implements Database.Batchable<sobject>, Database.Stateful {
    
    private List<String> objectsList;
    Boolean isError = false;
    private Post_Install_Log__c errorLog;

	global SetLastModifiedOnHistoricalDataBatch2(List<String> objectToProcessList) {
        this.objectsList = objectToProcessList;
        if(this.objectsList == null) this.objectsList = new List<String>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(this.objectsList.isEmpty()) {
            return null;
        }
        String strQuery = 'SELECT Id FROM ' + objectsList[0] + ' WHERE Last_Modified_By__c = NULL OR Last_Modified_Date__c = null';
        try {
            errorLog = PostInstallScriptUtil.upsertLog(null, 'SetLastModifiedOnHistoricalDataBatch2', LogService.NOT_APPLICABLE, objectsList[0], 'Pending', LogService.NOT_APPLICABLE, true);
        } catch(Exception e) {
            // added to catch error in case of log insertion failure
        }
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<SObject> listToProcess) {
        try {
            BPTriggerHandler.isExecuteTrigger = false;
            DMLUtility.updateSobjectList(this.objectsList[0], listToProcess, false);
            BPTriggerHandler.isExecuteTrigger = true;
        } catch(Exception e) {
            isError = true;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        try {
            if(!this.objectsList.isEmpty()) {
                if(isError) {
                    if(errorLog == null) {
                        errorLog = PostInstallScriptUtil.upsertLog(null, 'SetLastModifiedOnHistoricalDataBatch2', LogService.NOT_APPLICABLE, this.objectsList[0], 'Errored', 'finish()', false);
                    } else {
                        errorLog.Status__c = 'Errored';
                        errorLog.Stack_Trace__c = this.objectsList[0];
                    }
                } else if(errorLog != null) {
                    errorLog.Status__c = 'Completed';
                }
                this.objectsList.remove(0);
                if(!this.objectsList.isEmpty()) { // add logic for 5 parallel batches
                    SetLastModifiedOnHistoricalDataBatch1.executeBatch2ForLargeData(this.objectsList);
                }
            } else {
                return;
            }
        } catch(Exception e) {
            String errorString = String.valueOf(this.objectsList) + ' - ' + e.getMessage();
            errorString = (errorString.length() > 5000) ? errorString.subString(0, 5000) : errorString;
            if(errorLog == null) {
                errorLog = PostInstallScriptUtil.upsertLog(null, 'SetLastModifiedOnHistoricalDataBatch2', LogService.NOT_APPLICABLE, errorString, 'Errored', 'finish()', false);
            } else {
                errorLog.Status__c = 'Errored';
                errorLog.Stack_Trace__c = errorString;
            }
        }
        if(errorLog != null) DMLUtility.upsertSobjectList('Post_Install_Log__c', errorLog);
    }
}