/**
 * Author: Nidhi Sharma
 * Since: January 04, 2021
 * Name: FactoryOptionTriggerHelper
 * Description: Factory Option trigger helper
**/
public without sharing class FactoryOptionTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    
    public static void beforeInsert(List<Factory_Option__c> factoryOptionList) {
    	validateFactoryOptions(factoryOptionList);
    }
    
    public static void beforeUpdate(List<Factory_Option__c> factoryOptionList) {
    	validateFactoryOptions(factoryOptionList);
    }
    
    private static void validateFactoryOptions(List<Factory_Option__c> factoryOptionList) {
    	Set<String> factOptCodeSet = new Set<String>();
    	Map<String, Set<String>> makeIdToFactOptCodeSet = new Map<String, Set<String>>();
    	
    	for(Factory_Option__c factOptRec : factoryOptionList) {
    		if(factOptRec.Code__c == null || String.isBlank(factOptRec.Code__c.trim()) || factOptRec.Code__c.trim().length() > 20) {
    			throw new BlackpurlException('Code must be unique to the Make and can be a maximum of 20 alphanumeric characters');
    		}
    		
    		if(factOptRec.Description__c == null || String.isBlank(factOptRec.Description__c.trim()) || factOptRec.Description__c.trim().length() > 230) {
    			throw new BlackpurlException('Description is required and can have a maximum of 230 alphanumeric characters');
    		}
    		
    		factOptRec.Cost__c = factOptRec.Cost__c != null ? factOptRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
    		if(factOptRec.Cost__c < 0) throw new BlackpurlException('Cost must be greater than or equals to zero');
    		
    		factOptRec.Price__c = factOptRec.Price__c != null ? factOptRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
    		if(factOptRec.Price__c < 0) throw new BlackpurlException('Price must be greater than or equals to zero');
    		
    		factOptCodeSet.add(factOptRec.Code__c);
    		
    		if(!makeIdToFactOptCodeSet.containsKey(factOptRec.Unit_Make__c)) {
    			makeIdToFactOptCodeSet.put(factOptRec.Unit_Make__c, new Set<String>{factOptRec.Code__c});
    		} else if(makeIdToFactOptCodeSet.get(factOptRec.Unit_Make__c).contains(factOptRec.Code__c)) {
    			throw new BlackpurlException('Duplicate factory options for same make in list');
    		} else {
    			makeIdToFactOptCodeSet.get(factOptRec.Unit_Make__c).add(factOptRec.Code__c);
    		}
    	}
    	
    	//Validate factory option code uniqueness under make
    	makeIdToFactOptCodeSet.remove(null);
    	factOptCodeSet.remove(null);
    	if(makeIdToFactOptCodeSet.size() > 0) {
    		if(!AccessControl.ifObjectFieldIsAccessible('Unit_Make__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        	List<Unit_Make__c> makeList = [Select Id, (Select Id, Code__c from Factory_Options__r where Code__c IN: factOptCodeSet) from Unit_Make__c where Id IN: makeIdToFactOptCodeSet.keySet()];
    		
    		Map<String, Map<String, String>> makeIdToExistingFactOptNameToIdMap = new Map<String, Map<String, String>>();
    		for(Unit_Make__c unitMakeRec : makeList) {
	    		makeIdToExistingFactOptNameToIdMap.put(unitMakeRec.Id, new Map<String, String>());
	    		for(Factory_Option__c factOptRec : unitMakeRec.Factory_Options__r) {
	    			makeIdToExistingFactOptNameToIdMap.get(unitMakeRec.Id).put(factOptRec.Code__c.toLowerCase(), factOptRec.Id);
	    		}
	    	}
    		
    		for(Factory_Option__c factOptRec : factoryOptionList) {
    			if(makeIdToExistingFactOptNameToIdMap.get(factOptRec.Unit_Make__c).containsKey((factOptRec.Code__c).toLowerCase()) && (String.isBlank(factOptRec.Id) || 
	    			factOptRec.Id != makeIdToExistingFactOptNameToIdMap.get(factOptRec.Unit_Make__c).get((factOptRec.Code__c).toLowerCase()))) {
	    			throw new BlackpurlException('Factory option Code for this make already exists');
	    		}
    		}
    	}
    }
}