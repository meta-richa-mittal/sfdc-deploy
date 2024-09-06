/** 
* Author: Nidhi Sharma
* Since: Feb 11, 2022
* Name: OutdatedDataCleanupBatchSch 
* Description: Batch Apex class which cleanup outdated data.
**/
global without sharing class OutdatedDataCleanupBatchSch implements Database.Batchable<SObject>, Schedulable {
    
    public String dataType;
    public String NDays;
    global OutdatedDataCleanupBatchSch(String typeVal) {
        this.dataType = typeVal;
    }
    
    global List<SObject> start(Database.BatchableContext bc) {
        List<SObject> sobjList = new List<SObject>();
        if(String.isNotBlank(this.dataType) && this.dataType.equalsIgnoreCase('File')) {
        	this.NDays = '30';
            Set<String> parentIdSet = new Set<String>();
            //SOM parent Id
            for(SOM_Integration__c somRec : [Select Id From SOM_Integration__c LIMIT :SOQLUtility.getAvailableQueryRowsLimit()]) {
                parentIdSet.add(somRec.Id);
            }
            //File Storage parent Id (FTP/BRP)
            for(File_Storage__c storageRec : [Select Id From File_Storage__c LIMIT :SOQLUtility.getAvailableQueryRowsLimit()]) {
                parentIdSet.add(storageRec.Id);
            }
            if(parentIdSet.size() > 0) {
                String query = 'Select Id FROM Attachment Where ParentId IN: parentIdSet' + (Test.isRunningTest() ? '' : ' AND CreatedDate < LAST_N_DAYS:'+this.NDays);
                sobjList = Database.query(query);
            }
        } else {
        	this.NDays = '90';
            sobjList.addAll(SOQLUtility.getQueryResults('Log__c', 'Select Id from Log__c Where CreatedDate < LAST_N_DAYS:' + this.NDays));
            sobjList.addAll(SOQLUtility.getQueryResults('WebService_Log__c', 'Select Id from WebService_Log__c Where CreatedDate < LAST_N_DAYS:' + this.NDays));
            sobjList.addAll(SOQLUtility.getQueryResults('BRP_Log__c', 'Select Id from BRP_Log__c Where CreatedDate < LAST_N_DAYS:' + this.NDays));
            sobjList.addAll(SOQLUtility.getQueryResults('Price_File_Error_Log__c', 'Select Id from Price_File_Error_Log__c Where CreatedDate < LAST_N_DAYS:' + this.NDays));
            sobjList.addAll(SOQLUtility.getQueryResults('Summary_Log__c', 'Select Id from Summary_Log__c Where CreatedDate < LAST_N_DAYS:' + this.NDays));
        }
        return sobjList;
    }

    global void execute(Database.batchableContext bc, List<SObject> recordsToDelete) {        
        if(AccessControl.ifObjectIsDeletable('Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('WebService_Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('BRP_Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Price_File_Error_Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Summary_Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete recordsToDelete;
    }

    global void finish(Database.batchableContext bc) {
        if(String.isNotBlank(this.dataType)) {
            Database.executeBatch(new OutdatedDataCleanupBatchSch(null), 500);
        }
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new OutdatedDataCleanupBatchSch(this.dataType), 500);
    }
}