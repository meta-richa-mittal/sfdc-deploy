/** 
 * Author: Nidhi Sharma
 * Since: March 4, 2021
 * Name: SupersededPartService 
 * Description: Apex class to handle all operations related to superseded parts.
**/
public without sharing class SupersededPartService {
	
    public static Map<String, PartModal> getSupersededParts(Set<String> partIds) {
        Map<String, Part__c> partIdToSupersededPartRecMap = new Map<String, Part__c>();
       	Map<String, String> supersededPartIdToActivePartIdMap = new Map<String, String>(); 
        for(String partId : partIds) {
        	supersededPartIdToActivePartIdMap.put(partId, partId);    
        }
        populateSupersededParts(supersededPartIdToActivePartIdMap, partIdToSupersededPartRecMap);
        
        Map<String, PartModal> supercededPartMap = new Map<String, PartModal>();
        for(String partId : partIdToSupersededPartRecMap.keySet()) {
        	if(partIdToSupersededPartRecMap.get(partId) != null) {
            	supercededPartMap.put(partId, new PartModal(partIdToSupersededPartRecMap.get(partId)));
        	}
        }
        return supercededPartMap;
    }

    public static Part__c getSupersededPart(String partId) {
        Map<String, Part__c> partIdToSupersededPartRecMap = new Map<String, Part__c>();
       	Map<String, String> supersededPartIdToActivePartIdMap = new Map<String, String>(); 
        supersededPartIdToActivePartIdMap.put(partId, partId);    
        
        populateSupersededParts(supersededPartIdToActivePartIdMap, partIdToSupersededPartRecMap);
        if(partIdToSupersededPartRecMap.get(partId) != null) {
            return partIdToSupersededPartRecMap.get(partId);
        }
        return null;
    }

    private static void populateSupersededParts(Map<String, String> supersededPartIdToActivePartIdMap, Map<String, Part__c> partIdToSupersededPartRecMap) {
    	if(supersededPartIdToActivePartIdMap.size() > 0) {
	        List<Part__c> supersededParts = [Select Id, Is_Superseded__c, Superseded_To__c, Part_Number__c, Description__c,
	    				Superseded_To__r.Is_Superseded__c, Superseded_To__r.Superseded_To__c, Superseded_To__r.Part_Number__c, Superseded_To__r.Description__c,
	    				Superseded_To__r.Superseded_To__r.Is_Superseded__c, Superseded_To__r.Superseded_To__r.Superseded_To__c, Superseded_To__r.Superseded_To__r.Part_Number__c, Superseded_To__r.Superseded_To__r.Description__c, 
	    				Superseded_To__r.Superseded_To__r.Superseded_To__r.Is_Superseded__c, Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__c, Superseded_To__r.Superseded_To__r.Superseded_To__r.Part_Number__c, Superseded_To__r.Superseded_To__r.Superseded_To__r.Description__c,
	    				Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Is_Superseded__c, Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__c , Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Part_Number__c, Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Description__c
	    				from Part__c where Id IN :supersededPartIdToActivePartIdMap.values()];
	        
	        Map<String, String> remainingActivePartIdToSupersededPartIdMap = new Map<String, String>();
	        
	        for(Part__c part : supersededParts) {
	            Integer depth = 1;	//Since query can only provide 5 level of Parent record, we hae started from 1
	            Part__c supersededPart = findSupersededPart(depth, part);
	            
	            for(String activePartId : supersededPartIdToActivePartIdMap.keySet()) {
	                if(supersededPartIdToActivePartIdMap.get(activePartId) == part.Id) {
	                    if(part.Id == supersededPart.Id) {
	                        partIdToSupersededPartRecMap.put(activePartId, null);
	                    } else if(supersededPart.Is_Superseded__c) {
	                        remainingActivePartIdToSupersededPartIdMap.put(activePartId, supersededPart.Id);
	                    } else {
	                        partIdToSupersededPartRecMap.put(activePartId, supersededPart);
	                    }
	                }
	            }
	        }
	        if(remainingActivePartIdToSupersededPartIdMap.size() > 0) {
	            // parts which have more than 5 levels hierarchy
	            populateSupersededParts(remainingActivePartIdToSupersededPartIdMap, partIdToSupersededPartRecMap);
	        }
    	}
    }
    
    private static Part__c findSupersededPart(Integer depth, Part__c part) {
        if(part.Is_Superseded__c && depth != 5) {
            return findSupersededPart(++depth, part.Superseded_To__r);
        } 
        return part;
    }

    public class PartModal {
        public String partId;
        public String partNumber;
        public String partDescription;

        public PartModal(Part__c part) {
            this.partId = part.Id;
            this.partNumber = part.Part_Number__c;
            this.partDescription = part.Description__c;
        }
    }
}