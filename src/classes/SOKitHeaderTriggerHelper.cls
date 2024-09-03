public without sharing class SOKitHeaderTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    public static List<Service_Order_Kit_Header__c> soKitHeaderNewList = new List<Service_Order_Kit_Header__c>();
    public static List<Service_Order_Kit_Header__c> soKitHeaderOldList = new List<Service_Order_Kit_Header__c>();
    public static Map<Id, Service_Order_Kit_Header__c> soKitHeaderNewMap = new Map<Id, Service_Order_Kit_Header__c>();
    public static Map<Id, Service_Order_Kit_Header__c> soKitHeaderOldMap = new Map<Id, Service_Order_Kit_Header__c>();
    
    public static void afterInsert() {
    	populateKitCCCOnSO(soKitHeaderNewList);
    }
    
    public static void populateKitCCCOnSO(List<Service_Order_Kit_Header__c> soKitHeaderNewList) {
    	Set<String> soHeaderIdSet = new Set<String>();
    	Set<String> kitHeaderIdSet = new Set<String>();
    	for(Service_Order_Kit_Header__c soKitHeaderRec : soKitHeaderNewList) {
    		soHeaderIdSet.add(soKitHeaderRec.Service_Order_Header__c);
    		kitHeaderIdSet.add(soKitHeaderRec.Kit_Header__c);
    	}
    	soHeaderIdSet.remove(null);
    	kitHeaderIdSet.remove(null);
    	
    	if(soHeaderIdSet.size() > 0 && kitHeaderIdSet.size() > 0) {
    		Map<String, Service_Order_Header__c> soHeaderIdToRecMap = 
    				new Map<String, Service_Order_Header__c>([Select Id, SO_Cause__c, SO_Concern__c, SO_Correction__c from Service_Order_Header__c where Id In: soHeaderIdSet]);
    		Map<String, Kit_Header__c> kitHeaderIdToRecMap = 
    				new Map<String, Kit_Header__c>([Select Id, Cause__c, Concern__c, Correction__c from Kit_Header__c where Id In: kitHeaderIdSet]);
    		
			Set<String> soHeaderIdSetToUpdate = new Set<String>();
			    		
    		Set<String> soCauseSet, soConcernSet, soCorrectionSet, kitCauseSet, kitConcernSet, kitCorrectionSet;
    		for(Service_Order_Kit_Header__c soKitHeaderRec : soKitHeaderNewList) {
    			if(kitHeaderIdToRecMap.containsKey(soKitHeaderRec.Kit_Header__c) && 
    					(kitHeaderIdToRecMap.get(soKitHeaderRec.Kit_Header__c).Cause__c != null || kitHeaderIdToRecMap.get(soKitHeaderRec.Kit_Header__c).Concern__c != null
    						|| kitHeaderIdToRecMap.get(soKitHeaderRec.Kit_Header__c).Correction__c != null)) {
    				soCauseSet = soConcernSet = soCorrectionSet = kitCauseSet = kitConcernSet = kitCorrectionSet = new Set<String>();

    				Kit_Header__c kitRec = kitHeaderIdToRecMap.get(soKitHeaderRec.Kit_Header__c);
    				kitCauseSet = (kitRec.Cause__c != null) ? new Set<String>(kitRec.Cause__c.split('\n')) : new Set<String>();
    				kitConcernSet = (kitRec.Concern__c != null) ? new Set<String>(kitRec.Concern__c.split('\n')) : new Set<String>();
    				kitCorrectionSet = (kitRec.Correction__c != null) ? new Set<String>(kitRec.Correction__c.split('\n')) : new Set<String>();
    				
	    			if(soHeaderIdToRecMap.containsKey(soKitHeaderRec.Service_Order_Header__c)) {
	    				Service_Order_Header__c soRec = soHeaderIdToRecMap.get(soKitHeaderRec.Service_Order_Header__c);
	    				soCauseSet = (soRec.SO_Cause__c != null) ? new Set<String>(soRec.SO_Cause__c.split('\n')) : new Set<String>();
	    				soConcernSet = (soRec.SO_Concern__c != null) ? new Set<String>(soRec.SO_Concern__c.split('\n')) : new Set<String>();
	    				soCorrectionSet = (soRec.SO_Correction__c != null) ? new Set<String>(soRec.SO_Correction__c.split('\n')) : new Set<String>();
	    				
	    				
	    				Boolean isNewCCCAdded = false;
		    			for(String kitCauseStr : kitCauseSet) {
		    				if(!soCauseSet.contains(kitCauseStr)) {
		    					kitCauseStr = (kitCauseStr.contains('\n')) ? kitCauseStr.replaceAll('\n', '') : kitCauseStr;
			    				soCauseSet.add(kitCauseStr);
			    				isNewCCCAdded = true;
			    			}
		    			}
		    			
		    			for(String kitConcernStr : kitConcernSet) {
		    				if(!soConcernSet.contains(kitConcernStr)) {
		    					kitConcernStr = (kitConcernStr.contains('\n')) ? kitConcernStr.replaceAll('\n', '') : kitConcernStr;
			    				soConcernSet.add(kitConcernStr);
			    				isNewCCCAdded = true;
			    			}
		    			}
		    			
		    			for(String kitCorrectionStr : kitCorrectionSet) {
		    				if(!soCorrectionSet.contains(kitCorrectionStr)) {
		    					kitCorrectionStr = (kitCorrectionStr.contains('\n')) ? kitCorrectionStr.replaceAll('\n', '') : kitCorrectionStr;
			    				soCorrectionSet.add(kitCorrectionStr);
			    				isNewCCCAdded = true;
			    			}
		    			}
		    			if(isNewCCCAdded) {
			    			soHeaderIdToRecMap.get(soKitHeaderRec.Service_Order_Header__c).SO_Cause__c = string.join((new List<String>(soCauseSet)),'\n');
			    			soHeaderIdToRecMap.get(soKitHeaderRec.Service_Order_Header__c).SO_Concern__c = string.join((new List<String>(soConcernSet)),'\n');
			    			soHeaderIdToRecMap.get(soKitHeaderRec.Service_Order_Header__c).SO_Correction__c = string.join((new List<String>(soCorrectionSet)),'\n');
			    			soHeaderIdSetToUpdate.add(soKitHeaderRec.Service_Order_Header__c);
		    			}
	    			}
    			}
    		}
    		List<Service_Order_Header__c> soHeaderListToUpdate = new List<Service_Order_Header__c>();
    		
    		for(String soId : soHeaderIdSetToUpdate) {
    			if(soHeaderIdToRecMap.containsKey(soId)) { 
    				soHeaderListToUpdate.add(soHeaderIdToRecMap.get(soId));
    			}
    		}
    		SOTriggerHelper.isForceStopTrigger = true;
    		update soHeaderListToUpdate;
    		SOTriggerHelper.isForceStopTrigger = false;
    	}
    }
}