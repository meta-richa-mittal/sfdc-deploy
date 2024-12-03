global without sharing class SyncHoursLoggedBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        String query = getBaseQuery('Hours_Logged__c', AccountingHoursLogged.fieldsList(), IntegrationUtility.HOURS_LOGGED);
        try {
            setAccPeriodCloseDate();
        } catch(Exception e) {
            // create info log
            integrationInstanceList[0].errorLogs.add(new LogService().createErrorLog('SyncHoursLoggedBatch', 'getAccountingPeriodClosedDate()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                idSet + LogService.METHOD_PARAM_SEPERATOR, LogService.XERO, false, 'Info'));
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.batchableContext bc, List<Hours_Logged__c> hoursLoggedList) {
        for(Hours_Logged__c hoursLoggedRec : hoursLoggedList) {
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.JOURNAL_ENTRY => IntegrationUtility.CREATE_ACTION};
            this.webserviceLogs = integrationInstanceList[0].sync(new List<AccountingHoursLogged>{new AccountingHoursLogged(hoursLoggedRec, accPeriodCloseDate)}, 
                      (List<SObject>) sobjctListToUpdate, IntegrationUtility.HOURS_LOGGED, integrationEntityNameToActionMap);
        }
    }
    
    global override void finish(Database.batchableContext bc) {
        HoursLoggedTriggerHelper.isForceStopTrigger = true;
        finishAction();
        HoursLoggedTriggerHelper.isForceStopTrigger = false;
    }
}