/**
 * Author: Nidhi Sharma
 * Since: Sept 11, 2019
 * Name: SyncCountSessionJEBatch
 * Description: 
**/
global without sharing class SyncCountSessionJEBatch extends BaseSyncingBatch {
	
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Count_Session__c', AccountingCountSession.getCountSessionfieldsList(), IntegrationUtility.COUNT_SESSION_JE));
    }
    
    global void execute(Database.batchableContext bc, List<Count_Session__c> countSessionRecList) {
    	Map<Id, List<Count_Session_Line_Item__c>> countSessionIdToLineItemListMap = AccountingUtil.getCountSessionIdToCountSessionLineItemsMap(countSessionRecList);
    	
        for(Count_Session__c countSessionRec : countSessionRecList) {
            String accId = String.valueOf(countSessionRec.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.COUNT_SESSION_JE).Integration_Id_API_Name__c));
            
            List<Count_Session_Line_Item__c> countSessionLIList = countSessionIdToLineItemListMap.containsKey(countSessionRec.Id) ? 
            											countSessionIdToLineItemListMap.get(countSessionRec.Id) : new List<Count_Session_Line_Item__c>();
            AccountingCountSession countSessionObj = new AccountingCountSession(countSessionRec, countSessionLIList);
            
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.JOURNAL_ENTRY => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
            this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingCountSession>{countSessionObj}, (List<SObject>) sobjctListToUpdate, 
                                            IntegrationUtility.COUNT_SESSION_JE, integrationEntityNameToActionMap));
        }
    }
  
    global override void finish(Database.batchableContext bc) {
    	CountSessionTriggerHelper.isForceStopTrigger = true;
        finishAction();
        CountSessionTriggerHelper.isForceStopTrigger = false;
    }
}