/**
 * Author: Nidhi Sharma
 * Since: June 25, 2023
 * Name: PopulateDealSalespersonBatch
 * Description: 
**/
global without sharing class PopulateDealSalespersonBatch extends PostInstallScriptBaseBatch {

    global PopulateDealSalespersonBatch() {
        this.scriptName = 'executePopulateDealSalespersonBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Id, Salesperson__c, CO_Header__r.Owner__c from Deal__c WHERE Id NOT IN (Select Deal__c FROM CO_Salesperson__c WHERE Deal__c != null)';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealList) {
        Map<Id, Id> userIdToTechIdMap = new Map<Id, Id>();
        for(Deal__c dealRec : (List<Deal__c>)dealList) {
            if(dealRec.Salesperson__c == null) {
                userIdToTechIdMap.put(dealRec.CO_Header__r.Owner__c, null);
            }
        }
        if(!userIdToTechIdMap.isEmpty()) {
            for(Technician__c techRec : [Select Id, User__c FROM Technician__c WHERE User__c IN: userIdToTechIdMap.keySet()]) {
                userIdToTechIdMap.put(techRec.User__c, techRec.Id);
            }
        }
        List<CO_Salesperson__c> spInsertList = new List<CO_Salesperson__c>();
        for(Deal__c dealRec : (List<Deal__c>)dealList) {
            if(dealRec.Salesperson__c != null) {
                spInsertList.add(new CO_Salesperson__c(Deal__c = dealRec.Id, Technician__c = dealRec.Salesperson__c));
            } else if(userIdToTechIdMap.get(dealRec.CO_Header__r.Owner__c) != null) {
                spInsertList.add(new CO_Salesperson__c(Deal__c = dealRec.Id, Technician__c = userIdToTechIdMap.get(dealRec.CO_Header__r.Owner__c)));
            }
        }
        DMLUtility.insertSobjectList('CO_Salesperson__c', spInsertList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}