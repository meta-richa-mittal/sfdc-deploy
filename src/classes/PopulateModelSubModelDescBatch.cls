/**
 * Author: Tarun Khandelwal
 * Since: July 1, 2021
 * Name: PopulateModelSubModelDescBatch
 * Description: Batch for Populating Description field on Unit Model and Unit SubModel
**/ 
global without sharing class PopulateModelSubModelDescBatch implements Database.Batchable<sobject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        BPScriptUtility.disbaleTrigger('UnitModelTrigger');
        BPScriptUtility.disbaleTrigger('UnitSubModelTrigger');
        return Database.getQueryLocator('SELECT Model_Description__c FROM Unit_Model__c');
    }
    
    public void execute(Database.batchableContext bc, List<Unit_Model__c> unitModelList) {
        updateModelDescription(unitModelList);
        
        Set<Id> unitModelIdSet = getModelIdSet(unitModelList);
        updateSubModelDescription(unitModelIdSet); 
    }
    
    private void updateModelDescription(List<Unit_Model__c> unitModelList) {
        List<Unit_Model__c> modelListToUpdate = new List<Unit_Model__c>();
        for(Unit_Model__c unitModel : unitModelList) {
            if(String.isNotBlank(unitModel.Model_Description__c)) {
                unitModel.Description__c = unitModel.Model_Description__c;
                modelListToUpdate.add(unitModel);
            }
        }
        if(modelListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Unit_Model__c', modelListToUpdate);
        }
    }
    
    private void updateSubModelDescription(Set<Id> unitModelIdSet) {
        List<Unit_Sub_Model__c> unitSubModelListToUpdate = new List<Unit_Sub_Model__c>();
        for(Unit_Sub_Model__c unitSubModel : [SELECT Sub_Model_Description__c FROM Unit_Sub_Model__c WHERE Unit_Model__c IN: unitModelIdSet]) {
            if(String.isNotBlank(unitSubModel.Sub_Model_Description__c)) {
                unitSubModel.Description__c = unitSubModel.Sub_Model_Description__c;
                unitSubModelListToUpdate.add(unitSubModel);
            }
        }
        if(unitSubModelListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Unit_Sub_Model__c', unitSubModelListToUpdate);
        }
    }
    
    private Set<Id> getModelIdSet(List<Unit_Model__c> unitModelList) {
        Set<Id> unitModelIdSet = new Set<Id>();
        for(Unit_Model__c unitModel : unitModelList) {
            unitModelIdSet.add(unitModel.Id);
        }
        return unitModelIdSet;
    }
    
    public void finish(Database.batchableContext bc) {
        BPScriptUtility.enableTrigger('UnitModelTrigger');
        BPScriptUtility.enableTrigger('UnitSubModelTrigger');
    }
}