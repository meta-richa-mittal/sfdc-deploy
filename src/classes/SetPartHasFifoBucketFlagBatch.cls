/**
 * Author: Manoj Sharma
 * Since: July 06, 2023
 * Name: SetPartHasFifoBucketFlagBatch
 * Description: Batch for Populating field on part
**/
global without sharing class SetPartHasFifoBucketFlagBatch extends PostInstallScriptBaseBatch  {
    global SetPartHasFifoBucketFlagBatch() {
        this.scriptName = 'executeSetPartHasFifoBucketFlagBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id FROM Part__c WHERE Has_FIFO_Bucket__c = false ';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> partList) {
        partList = [SELECT Has_FIFO_Bucket__c, (Select Id From Part_FIFO_Buckets__r Where Is_FIFO_Bucket__c = true limit 1) FROM Part__c WHERE Id In: partList];
        List<Part__c> partListToUpdate = new List<Part__c>();
        for(Part__c partRec : (List<Part__c>)partList) {
            if(!partRec.Part_FIFO_Buckets__r.isEmpty()) {
                partListToUpdate.add(new Part__c(Id = partRec.Id, Has_FIFO_Bucket__c = true));
            }
        }
        if(partListToUpdate.size() > 0) {
            PartTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Part__c', partListToUpdate);
            PartTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}