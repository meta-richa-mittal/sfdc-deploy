/**
 * Author: Richa Mittal
 * Since: Mar 21, 2022
 * Name: PopulatePartTypeFieldOnPartV2Batch
 * Description: Batch for Populating fields on part and vendor
**/
global without sharing class PopulatePartTypeFieldOnPartV2Batch extends PostInstallScriptBaseBatch {
    global PopulatePartTypeFieldOnPartV2Batch() {
        this.scriptName = 'executePopulatePartTypeFieldOnPartV2Batch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        String strQuery = 'SELECT Id, Part_Type__c, Vendor__c FROM Part__c WHERE Part_Type__c = null OR (Vendor__c != null AND Vendor__r.Part_Purchases__c = false)';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> partList) {
        List<Part__c> partListToUpdate = new List<Part__c>();
        List<Account> vendorListToUpdate = new List<Account>();
        
        Set<Id> vendorIdSet = new Set<Id>();
        for(Part__c partRec : (List<Part__c>)partList) {
            if(String.isBlank(partRec.Part_Type__c)) {
                partListToUpdate.add(new Part__c(Id = partRec.Id, Part_Type__c = 'Part'));
            }
            if(String.isNotBlank(partRec.Vendor__c)) {
                vendorIdSet.add(partRec.Vendor__c);
            }
        }
        for(Id vendorId: vendorIdSet) {
            vendorListToUpdate.add(new Account(Id = vendorId, Part_Purchases__c = true));
        }
        if(partListToUpdate.size() > 0) {
            PartTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Part__c', partListToUpdate);
            PartTriggerHelper.isForceStopTrigger = false;
        }
        if(vendorListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Account', vendorListToUpdate);
        }
    }
    
    global override void finishScript(Database.BatchableContext bc) {
        BPScriptUtility.enableTrigger('CustomerTrigger');
    }
}