/*
    Apex class to sync Count Session with accounting server
*/
global without sharing class AccSync_CountSession_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    public String strQuery;
    public Set<Id> countSessionIdSet;
    public static boolean preventOnAccountingSync = false;
    global List<Count_Session__c> countSessionListToUpdate; 
    global List<Log__c> errorLogToInsert;   
    
    public static void runCountSessionForSync(Set<Id> countSessionIdSetVal , Integer batchSize) {
        AccSync_CountSession_Batch accSyncClsBatch = new AccSync_CountSession_Batch();
        accSyncClsBatch.countSessionIdSet = countSessionIdSetVal;
        accSyncClsBatch.strQuery = getBaseQuery();
        accSyncClsBatch.strQuery += ' AND Id IN :countSessionIdSet';
        Id batchstart = Database.executeBatch(accSyncClsBatch, batchSize);
    }
        
    public static String getBaseQuery() {
        String baseQuery = 'SELECT '; 
        for(String fieldName : AccountingCountSession.getCountSessionfieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
        baseQuery = baseQuery.substring(0, baseQuery.length()-2);
        baseQuery += ' FROM Count_Session__c ';
        baseQuery += 'WHERE Available_For_QB_Sync__c = true';
        return baseQuery;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        countSessionListToUpdate = new List<Count_Session__c>();
        errorLogToInsert = new List<Log__c>();
        if(String.isBlank(strQuery)){
            strQuery = getBaseQuery();
            if(countSessionIdSet != null && countSessionIdSet.size() > 0) {
                strQuery += ' AND Id IN :countSessionIdSet';
            }
        }
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Count_Session__c> countSessionList) {
    	Map<Id, List<Count_Session_Line_Item__c>> countSessionIdToLineItemListMap = AccountingUtil.getCountSessionIdToCountSessionLineItemsMap(countSessionList);
        List<AccountingCountSession> accountingCountSessionList = new List<AccountingCountSession>();
        for(Count_Session__c countSessionRec : countSessionList) {
        	List<Count_Session_Line_Item__c> countSessionLIList = countSessionIdToLineItemListMap.containsKey(countSessionRec.Id) ? 
            											countSessionIdToLineItemListMap.get(countSessionRec.Id) : new List<Count_Session_Line_Item__c>();
            QBUtil.BatchResultWrapper batchResultObj = QBCountSessionService.syncAccountingServer(new AccountingCountSession(countSessionRec, countSessionLIList), countSessionListToUpdate);
			errorLogToInsert.addAll(batchResultObj.ErrorLogToInsert);
			if(batchResultObj.RefreshToken !=  null) {
				QBUtil.saveRefreshToken(batchResultObj.RefreshToken, batchResultObj.RefreshTokenExpiresIn);
			}
        }
    }  
 
    global void finish(Database.batchableContext bc) {
        updateCountSession(countSessionListToUpdate);
        if(errorLogToInsert.size() > 0) {
          insert errorLogToInsert;
        }
    }
    
    public static void updateCountSession(List<Count_Session__c> countSessionListToUpdate) {
        if(countSessionListToUpdate != null && countSessionListToUpdate.size() > 0) { 
            preventOnAccountingSync = true;
            CountSessionTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Count_Session__c', countSessionListToUpdate);
            CountSessionTriggerHelper.isForceStopTrigger = true;
        }
    }
}