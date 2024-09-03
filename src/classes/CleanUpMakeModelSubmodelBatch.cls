public without sharing class CleanUpMakeModelSubmodelBatch implements Database.Batchable<sobject>, Database.Stateful  {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<Unit_Model__c> duplicateModalList = [SELECT Id, Unit_Make__c FROM Unit_Model__c WHERE Sub_Model__c != null];
        Set<Id> makeIdSet = new Set<Id>();
        for(Unit_Model__c model : duplicateModalList) {
            makeIdSet.add(model.Unit_Make__c);
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Unit_Make__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.getQueryLocator('SELECT Id FROM Unit_Make__c WHERE Id IN: makeIdSet'); 
    }

    public void execute(Database.batchableContext bc, List<Unit_Make__c> makeList) {
        List<Unit_Model__c> unitModelList = [SELECT Name__c, Description__c, Sub_Model__c, (SELECT Sub_Model_Name__c FROM Unit_Sub_Models__r) FROM Unit_Model__c WHERE Unit_Make__c IN: makeList order by Name__c ASC, Name ASC];
        
        Map<String, List<Unit_Model__c>> modelNameToModelListMap = new Map<String, List<Unit_Model__c>>();
        Map<String, Id> modelNameToModelIdMap = new Map<String, Id>();
        
        for(Unit_Model__c model : unitModelList) {
            if(!modelNameToModelListMap.containsKey(model.Name__c.toLowerCase())) {
                modelNameToModelListMap.put(model.Name__c.toLowerCase(), new List<Unit_Model__c>());
                modelNameToModelIdMap.put(model.Name__c.toLowerCase(), model.Id);
            }
            modelNameToModelListMap.get(model.Name__c.toLowerCase()).add(model);
        }
        
        List<Unit_Sub_Model__c> subModelToUpsertList = new List<Unit_Sub_Model__c>();
        List<Unit_Model__c> modelToDeleteList = new List<Unit_Model__c>();
        List<Unit_Model__c> modelToUpdateList = new List<Unit_Model__c>();
        
        for(String modelName : modelNameToModelListMap.keySet()) {
            Set<String> subModelNameSet = new Set<String>();
            List<Unit_Model__c> modelList = modelNameToModelListMap.get(modelName);
            
            for(Integer i = 0; i < modelList.size(); i++) {
                if(i == 0) {
                    for(Unit_Sub_Model__c subModel : modelList[i].Unit_Sub_Models__r) {
                        subModelNameSet.add(subModel.Sub_Model_Name__c.toLowerCase());
                    }
                    system.debug('subModelNameSet == ' + subModelNameSet);
                } else {
                    for(Unit_Sub_Model__c subModel : modelList[i].Unit_Sub_Models__r) {
                        if(String.isNotBlank(subModel.Sub_Model_Name__c) && !subModelNameSet.contains(subModel.Sub_Model_Name__c.toLowerCase())) {
                            subModel.Unit_Model__c = modelList[0].Id;
                            subModelToUpsertList.add(subModel);
                            subModelNameSet.add(subModel.Sub_Model_Name__c.toLowerCase());
                        }
                    }
                    modelToDeleteList.add(modelList[i]);
                }
            }
            
            for(Integer i = 0; i < modelList.size(); i++) {
                if(String.isNotBlank(modelList[i].Sub_Model__c)) {
                    if(!subModelNameSet.contains(modelList[i].Sub_Model__c.toLowerCase())) {
	                    Unit_Sub_Model__c newSubmodelRec = new Unit_Sub_Model__c();
	                    newSubmodelRec.Unit_Model__c = modelList[0].Id;
	                    newSubmodelRec.Sub_Model_Name__c = modelList[i].Sub_Model__c;
	                    newSubmodelRec.Description__c = modelList[i].Description__c;
	                    subModelToUpsertList.add(newSubmodelRec);
	                    subModelNameSet.add(modelList[i].Sub_Model__c.toLowerCase());
                    }
                    if(i == 0) {
                        Unit_Model__c model = modelList[i];
                        model.Sub_Model__c = null;
                        modelToUpdateList.add(model);
                    }
                }
            }
        }
        
        if(subModelToUpsertList.size() > 0) {
            DMLUtility.upsertSobjectList('Unit_Sub_Model__c', subModelToUpsertList);
        }
        
        Map<String, Id> modelSubModelUniqueNameToSubModelIdMap = new Map<String, Id>();
        List<Unit_Sub_Model__c> subModelList = [SELECT Sub_Model_Name__c, Unit_Model__r.Name__c FROM Unit_Sub_Model__c WHERE Unit_Model__c IN: modelNameToModelIdMap.values()];
        for(Unit_Sub_Model__c subModel : subModelList) {
            String uniqueKey = subModel.Unit_Model__r.Name__c.toLowerCase() + '-' + subModel.Sub_Model_Name__c.toLowerCase();
            if(!modelSubModelUniqueNameToSubModelIdMap.containsKey(uniqueKey)) {
                modelSubModelUniqueNameToSubModelIdMap.put(uniqueKey, subModel.Id);
            }
        }
        
        updateRelatedRecords(makeList, modelNameToModelIdMap, modelSubModelUniqueNameToSubModelIdMap);
        
        DMLUtility.updateSobjectList('Unit_Model__c', modelToUpdateList);
        DMLUtility.deleteSobjectList('Unit_Model__c', modelToDeleteList);
    }
    
    // Update Related records - 
    private void updateRelatedRecords(List<Unit_Make__c> makeList, Map<String, Id> modelNameToModelIdMap, Map<String, Id> modelSubModelUniqueNameToSubModelIdMap) {
        List<Deal_Item__c> dealItemList = [SELECT Unit_Model__c, Unit_Model__r.Name__c, Unit_Model__r.Sub_Model__c, Sub_Model__c, Sub_Model__r.Sub_Model_Name__c FROM Deal_Item__c WHERE Unit_Make__c IN: makeList AND Unit_Model__c != null];
        for(Deal_Item__c dealItemRec : dealItemList) {
            dealItemRec.Unit_Model__c = modelNameToModelIdMap.get((dealItemRec.Unit_Model__r.Name__c.toLowerCase()).toLowerCase());
            String submodelId = getSubModelId(dealItemRec.Unit_Model__r.Name__c, dealItemRec.Sub_Model__r.Sub_Model_Name__c, dealItemRec.Unit_Model__r.Sub_Model__c, modelSubModelUniqueNameToSubModelIdMap);
            if(submodelId != null) {
                dealItemRec.Sub_Model__c = submodelId;
            }
        }
        
        List<Customer_Owned_Unit__c> unitList = [SELECT Unit_Model__c, Unit_Model__r.Name__c, Unit_Model__r.Sub_Model__c, Sub_Model__r.Sub_Model_Name__c FROM Customer_Owned_Unit__c WHERE Unit_Make__c IN: makeList AND Unit_Model__c != null];
        for(Customer_Owned_Unit__c unitRec : unitList) {
            unitRec.Unit_Model__c = modelNameToModelIdMap.get((unitRec.Unit_Model__r.Name__c.toLowerCase()).toLowerCase());
            String submodelId = getSubModelId(unitRec.Unit_Model__r.Name__c, unitRec.Sub_Model__r.Sub_Model_Name__c, unitRec.Unit_Model__r.Sub_Model__c, modelSubModelUniqueNameToSubModelIdMap);
            if(submodelId != null) {
                unitRec.Sub_Model__c = submodelId;
            }
        }
        
        List<Kit_Header__c> kitHeaderList = [SELECT Model__c, Model__r.Name__c, Model__r.Sub_Model__c, Sub_Model__r.Sub_Model_Name__c FROM Kit_Header__c WHERE Make__c IN: makeList AND Model__c != null];
        system.debug('kitHeaderList == ' + kitHeaderList);
        for(Kit_Header__c kitHeaderRec : kitHeaderList) {
            system.debug('kitHeaderRec.Model__r.Name__c.toLowerCase() == ' + kitHeaderRec.Model__r.Name__c.toLowerCase());
            system.debug('modelNameToModelIdMap == ' + modelNameToModelIdMap);
            kitHeaderRec.Model__c = modelNameToModelIdMap.get((kitHeaderRec.Model__r.Name__c.toLowerCase()).toLowerCase());
            system.debug('kitHeaderRec.Model__c == ' + kitHeaderRec.Model__c);
            
            String submodelId = getSubModelId(kitHeaderRec.Model__r.Name__c, kitHeaderRec.Sub_Model__r.Sub_Model_Name__c, kitHeaderRec.Model__r.Sub_Model__c, modelSubModelUniqueNameToSubModelIdMap);
            system.debug('submodelId == ' + submodelId);
            if(submodelId != null) {
                kitHeaderRec.Sub_Model__c = submodelId;
            }
        }
        
        update dealItemList;
        update unitList;
        update kitHeaderList;
    }
    
    private String getSubModelId(String modelName, String submodelName1, String submodelName2, Map<String, Id> modelSubModelUniqueNameToSubModelIdMap) {
        String submodelId;
        String assignedSubModelName;
        system.debug('modelName == ' + modelName);
        system.debug('submodelName1 == ' + submodelName1);
        system.debug('submodelName2 == ' + submodelName2);
        if(String.isNotBlank(submodelName1)) {
            assignedSubModelName = submodelName1;
        } else if(String.isNotBlank(submodelName2)){
            assignedSubModelName = submodelName2;
        }
        if(assignedSubModelName != null) {
            String uniqueKey = modelName.toLowerCase() + '-' + assignedSubModelName.toLowerCase();
            system.debug('uniqueKey == ' + uniqueKey);
            system.debug('modelSubModelUniqueNameToSubModelIdMap == ' + modelSubModelUniqueNameToSubModelIdMap);
            submodelId = modelSubModelUniqueNameToSubModelIdMap.get(uniqueKey);
        }
        return submodelId;
    }
    
    public void finish(Database.batchableContext bc) {
        BPScriptUtility.createUniqueSubmodel();
        
        List<Unit_Sub_Model__c> submodelList = [SELECT Id FROM Unit_Sub_Model__c where Sub_Model_Name__c = null AND Unit_Model__c = null];
        DMLUtility.deleteSobjectList('Unit_Sub_Model__c', submodelList);
    }
}