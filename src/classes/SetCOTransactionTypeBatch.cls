/** 
* Author: Manoj Sharma
* Since: July 17, 2020 
* Name: SetCOTransactionTypeBatch 
* Description: Apex class to set CO Transaction Type.
**/
global without sharing class SetCOTransactionTypeBatch implements Database.Batchable<sobject>, Database.Stateful {
  
    public Map<String, Id> transactionTypeTottRecMap = new Map<String, Id>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<Transaction_Type__c> ttList = [SELECT Id, Code_Label__c, Default__c FROM Transaction_Type__c WHERE Type__c = 'Part Sale' AND Active__c = true AND (Default__c = true OR Code_Label__c = 'Layby' OR Code_Label__c = 'Layaway') Order by Code_Label__c ASC];
        for(Transaction_Type__c ttRec : ttList) {
            if(ttRec.Default__c) {
                transactionTypeTottRecMap.put('Part sale', ttRec.Id);
            } else if (ttRec.Code_Label__c == 'Layby') {
                transactionTypeTottRecMap.put('Layby', ttRec.Id);
            } else if (ttRec.Code_Label__c == 'Layaway') {
                transactionTypeTottRecMap.put('Layaway', ttRec.Id);
            }
        }
        String strQuery = 'Select Merchandise_Transaction_Type__c, Transaction_Type__c from CO_Header__c where Transaction_Type__c = null AND Merchandise_Transaction_Type__c != ';
        strQuery += SOQLUtil.getBussinessCountryName() == 'Australia' ? '\'Layaway\'' : '\'Layby\'';
        return Database.getQueryLocator(strQuery); 
    }
      
    global void execute(Database.batchableContext bc, List<CO_Header__c> coHeaderRecList) {
        for(CO_Header__c coHeaderRec : coHeaderRecList) {
            if(transactionTypeTottRecMap.containsKey(coHeaderRec.Merchandise_Transaction_Type__c)) {
                coHeaderRec.Transaction_Type__c = transactionTypeTottRecMap.get(coHeaderRec.Merchandise_Transaction_Type__c);
            }
        }
        
        COTriggerHelper.isForceStopTrigger = true;
        update coHeaderRecList;
        COTriggerHelper.isForceStopTrigger = false;
    }
      
    global void finish(Database.batchableContext bc) {

    }
}