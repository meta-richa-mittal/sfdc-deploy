/**
 * Author: Richa Mittal
 * Since: May 23, 2024
 * Name: UpdateCOSalespersonBatch
**/
global without sharing class UpdateCOSalespersonBatch extends PostInstallScriptBaseBatch {

    global UpdateCOSalespersonBatch() {
        this.scriptName = 'executeUpdateCOSalespersonBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Id from CO_Header__c WHERE CO_Salesperson_Names__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> coList) {
        Set<Id> coHeaderToUpdateIds = new Set<Id>();
        for(CO_Header__c coRec: (List<CO_Header__c>)coList) {
            coHeaderToUpdateIds.add(coRec.Id);
        }
        Map<Id, SObject> sobjUpdateMap = new Map<Id, SObject>();
        COSalespersonTriggerHelper.updateCOHeaderSalespersonNames(coHeaderToUpdateIds, sobjUpdateMap);
        if(!sobjUpdateMap.isEmpty()) {
            COTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectListWithRetry(sobjUpdateMap.values());
            COTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}