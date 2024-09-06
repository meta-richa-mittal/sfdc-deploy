/*
    Apex class to sync customer with accounting server
*/
global without sharing class AccSync_HoursLogged_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    public String strQuery;
    public Set<Id> hoursLoggedIdSet;
    public static boolean preventOnAccountingSync = false;
    global List<Hours_Logged__c> hoursLoggedListToUpdate; 
    global List<Log__c> errorLogToInsert;
    private DateTime accPeriodCloseDate;
    
    public static void runHoursLoggedForSync(Set<Id> hoursLoggedIdSetVal , Integer batchSize) {
        AccSync_HoursLogged_Batch accSyncClsBatch = new AccSync_HoursLogged_Batch();
        accSyncClsBatch.hoursLoggedIdSet = hoursLoggedIdSetVal;
        accSyncClsBatch.strQuery = getBaseQuery();
        accSyncClsBatch.strQuery += ' AND Id IN :hoursLoggedIdSet';
        Id batchstart = Database.executeBatch(accSyncClsBatch, batchSize);
    }
        
    public static String getBaseQuery() {
        String baseQuery = 'SELECT '; 
        for(String fieldName : AccountingHoursLogged.fieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
        baseQuery = baseQuery.substring(0, baseQuery.length()-2);
        baseQuery += ' FROM Hours_Logged__c ';
        baseQuery += 'WHERE Available_For_QB_Sync__c = true';
        return baseQuery;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        hoursLoggedListToUpdate = new List<Hours_Logged__c>();
        errorLogToInsert = new List<Log__c>();
        if(String.isBlank(strQuery)){
            strQuery = getBaseQuery();
            if(hoursLoggedIdSet != null && hoursLoggedIdSet.size() > 0) {
                strQuery += ' AND Id IN :hoursLoggedIdSet';
            }
        }
        try {
            String accCloseDateStr = QBUtil.getAccountingPeriodClosedDate();
            if(String.isNotBlank(accCloseDateStr)) {
                Date closeDate = DateTimeUtility.getDateFromFormattedDateStr(accCloseDateStr, 'YYYY-MM-DD');
                if(closeDate != null) {
                    accPeriodCloseDate = DateTimeUtility.getDateTimeFromDate(closeDate);
                }
            }
            
        } catch(Exception e) {
            // create info log
            errorLogToInsert.add(new LogService().createErrorLog('AccSync_HoursLogged_Batch', 'getAccountingPeriodClosedDate()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                    hoursLoggedIdSet + LogService.METHOD_PARAM_SEPERATOR, LogService.QUICKBOOKS, false, 'Info'));
        }
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Hours_Logged__c> hoursLoggedList) {
        List<AccountingHoursLogged> accountingHoursLoggedList = new List<AccountingHoursLogged>();
        for(Hours_Logged__c hoursLoggedRec : hoursLoggedList) {
        	QBUtil.BatchResultWrapper batchResultObj = QBHoursLoggedService.syncAccountingServer(new AccountingHoursLogged(hoursLoggedRec, accPeriodCloseDate), hoursLoggedListToUpdate);
			errorLogToInsert.addAll(batchResultObj.ErrorLogToInsert);
			if(batchResultObj.RefreshToken !=  null) {
				QBUtil.saveRefreshToken(batchResultObj.RefreshToken, batchResultObj.RefreshTokenExpiresIn);
			}
        }
    }  
 
    global void finish(Database.batchableContext bc) {
        updateHoursLogged(hoursLoggedListToUpdate);
        if(errorLogToInsert.size() > 0) {
          insert errorLogToInsert;
        }
    }
    
    public static void updateHoursLogged(List<Hours_Logged__c> hoursLoggedListToUpdate) {
        if(hoursLoggedListToUpdate != null && hoursLoggedListToUpdate.size() > 0) { 
            preventOnAccountingSync = true;
            HoursLoggedTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Hours_Logged__c', hoursLoggedListToUpdate);
            HoursLoggedTriggerHelper.isForceStopTrigger = true;
        }
    }
}