public without sharing class UnitSubModelTriggerHelper {
    
    public static List<Unit_Sub_Model__c> unitSubModelNewList = new List<Unit_Sub_Model__c>();
    public static List<Unit_Sub_Model__c> unitSubModelOldList = new List<Unit_Sub_Model__c>();
    public static Map<Id, Unit_Sub_Model__c> unitSubModelNewMap = new Map<Id, Unit_Sub_Model__c>();
    public static Map<Id, Unit_Sub_Model__c> unitSubModelOldMap = new Map<Id, Unit_Sub_Model__c>();
    
    public static void checkForUniqueSubModel() {
    	
    	Map<String, Set<String>> modelIdToSubModelNameSetMap = new Map<String, Set<String>>();
    	for(Unit_Sub_Model__c unitSubModelRec : unitSubModelNewList) {
    		if(String.isBlank(unitSubModelRec.Sub_Model_Name__c)) {
    			continue;
    		}
    		if(String.isBlank(unitSubModelRec.Unit_Model__c)) {
    			unitSubModelRec.addError('Model is required for a submodel');
    			continue;
    		}
    		if(!modelIdToSubModelNameSetMap.containsKey(unitSubModelRec.Unit_Model__c)) {
    			modelIdToSubModelNameSetMap.put(unitSubModelRec.Unit_Model__c, new Set<String>{unitSubModelRec.Sub_Model_Name__c});
    		} else if(modelIdToSubModelNameSetMap.get(unitSubModelRec.Unit_Model__c).contains(unitSubModelRec.Sub_Model_Name__c)) {
    			unitSubModelRec.addError('Duplicate submodel for same model in list');
    		} else {
    			modelIdToSubModelNameSetMap.get(unitSubModelRec.Unit_Model__c).add(unitSubModelRec.Sub_Model_Name__c);
    		}
    	}
    	
    	List<Unit_Model__c> modelList = [Select Id, Name__c, (Select Id, Sub_Model_Name__c from Unit_Sub_Models__r) from Unit_Model__c where 
    		Id In: modelIdToSubModelNameSetMap.keySet()];
    	
    	Map<String, Map<String, String>> existingModelIdToSubModelNameToIdMap = new Map<String, Map<String, String>>();
    	for(Unit_Model__c modelRec : modelList) {
    		existingModelIdToSubModelNameToIdMap.put(modelRec.Id, new Map<String, String>());
    		for(Unit_Sub_Model__c unitSubModelRec : modelRec.Unit_Sub_Models__r) {
    			if(String.isNotBlank(unitSubModelRec.Sub_Model_Name__c)) {
	    			existingModelIdToSubModelNameToIdMap.get(modelRec.Id).put((unitSubModelRec.Sub_Model_Name__c).toLowerCase(), unitSubModelRec.Id);
	    		}
    		}
    	}
    	
    	Set<String> newMakeNameSet = new Set<String>();
    	for(Unit_Sub_Model__c unitSubModelRec : unitSubModelNewList) {
    		if(String.isBlank(unitSubModelRec.Sub_Model_Name__c)) {
    			continue;
    		}
    		if(String.isBlank(unitSubModelRec.Unit_Model__c)) {
    			unitSubModelRec.addError('Model is required for a submodel');
    			continue;
    		}
    		if(unitSubModelRec.Unit_Model__c != null && unitSubModelRec.Sub_Model_Name__c != null && existingModelIdToSubModelNameToIdMap.get(unitSubModelRec.Unit_Model__c) != null &&
    			existingModelIdToSubModelNameToIdMap.get(unitSubModelRec.Unit_Model__c).containsKey((unitSubModelRec.Sub_Model_Name__c).toLowerCase())) {
    			String subModelId = existingModelIdToSubModelNameToIdMap.get(unitSubModelRec.Unit_Model__c).get((unitSubModelRec.Sub_Model_Name__c).toLowerCase());
    			if(String.isBlank(unitSubModelRec.Id) || unitSubModelRec.Id != subModelId) {
    				unitSubModelRec.addError('SubModel name for this model already exists');
    			}
    		}
    	}
    }
}