/*
    Apex batch class to import supersession part number information and to create alternate part records
*/
global without sharing class ImportSupersessionPart_Batch implements Database.Batchable<sobject>, Database.Stateful {

    public String baseQuery;
    public List<String> partIdList;
    global Set<String> partIdSetWithChangedRelation;
    global Set<String> partIdSetWithReplacedByRelation; // Depricated 

    global ImportSupersessionPart_Batch(){}
    
    global ImportSupersessionPart_Batch(List<String> partIdList, Integer batchSize){
        ImportSupersessionPart_Batch clsPartBatch = new ImportSupersessionPart_Batch();
        clsPartBatch.partIdList = partIdList;
        Id batchstart = Database.executeBatch(clsPartBatch, batchSize);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	partIdSetWithChangedRelation = new Set<String>();
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(partIdList != null && partIdList.size() > 0) {
            baseQuery = 'SELECT Id FROM Part__c WHERE Id IN :partIdList';            
        } else {
            baseQuery = 'SELECT Id FROM Part__c WHERE Is_Processed_By_APF__c = true';
        }
        return Database.getQueryLocator(baseQuery);
    } 

    global void execute(Database.batchableContext bc, List<Part__c>  importedPartList) {
		importedPartList = [SELECT Id, Vendor__c, Part_Number__c, Is_Superseded__c, Superseded_To__r.Part_Number__c, Replaced_By_Part__c, Replaces_Part__c, Old_Replaced_By_Part__c, (SELECT Id, Part_ID__c, Relation__c, Alternate_Part_ID__r.Part_Number__c,  Alternate_Part_ID__r.Replaced_By_Part__c FROM Part_Alternates__r WHERE Relation__c = 'Replaced By') FROM Part__c WHERE Id IN : importedPartList];
    	Map<Id, Part__c> partMapToUpdate = new Map<Id, Part__c>();

		// Delete perviously created parts alternet if there is any change in relations
		deleteInvalidPartsAlternate(ImportedPartList, partMapToUpdate);
    	
		Map<String, Map<String, Id>> vendorIdToPartNumberToPartIdMap = createVendorIdToPartNumberToPartIdMap(ImportedPartList);
    	List<Part_Alternates__c> partsAlternateList = createPartsAlternate(ImportedPartList, vendorIdToPartNumberToPartIdMap, partMapToUpdate);

    	if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		DMLUtility.insertSobjectList('Part_Alternates__c', partsAlternateList, false);
        
        for(Part__c partRec : importedPartList) {
            Part__c part = (partMapToUpdate.containsKey(partRec.Id) ? partMapToUpdate.get(partRec.Id) : partRec);
            part.Is_Processed_By_APF__c = false;
            partMapToUpdate.put(part.Id, part);
        }
        
        if(partMapToUpdate.size() > 0) {
			DMLUtility.updateSobjectList('Part__c', partMapToUpdate.values());
        }
    }
        
    global void finish(Database.batchableContext bc){
		Database.executeBatch(new ShopifySyncWebsiteProductBatch(true), ShopifyUtil.BulkProcessBatchSize);
    }
    
    private Map<String, Map<String, Id>> createVendorIdToPartNumberToPartIdMap(List<Part__c> ImportedPartList)	{
    	Set<String> supersededPartNumberSet = new Set<String>();
    	for(Part__c partRec: ImportedPartList)	{
    		if(partRec.Replaced_By_Part__c != null)	{
    			if(partRec.Replaced_By_Part__c != partRec.Part_Number__c) {
    				supersededPartNumberSet.add(partRec.Replaced_By_Part__c);
    			} else {
    				partRec.Replaced_By_Part__c = null;
    			}
    		}
    		if(partRec.Replaces_Part__c != null)	{
    			if(partRec.Replaces_Part__c != partRec.Part_Number__c) {
    				supersededPartNumberSet.add(partRec.Replaces_Part__c);
    			} else {
    				partRec.Replaces_Part__c = null;
    			}
    		}
    	}
    	
    	List<Part__c> supersededPartList = [select Id, Part_Number__c, Vendor__c from Part__c where Part_Number__c IN: supersededPartNumberSet];
    	Map<String, Map<String, Id>> vendorIdToPartNumberToPartIdMap = new Map<String, Map<String, Id>>();
    	for(Part__c partRec: supersededPartList) {
    		if(!vendorIdToPartNumberToPartIdMap.containsKey(partRec.Vendor__c)) {
    			vendorIdToPartNumberToPartIdMap.put(partRec.Vendor__c, new Map<String, Id>());
    		}
    		vendorIdToPartNumberToPartIdMap.get(partRec.Vendor__c).put(partRec.Part_Number__c, partRec.Id);
    	}
    	return vendorIdToPartNumberToPartIdMap;
    }
    
    // deprecated
    global Map<String, Id> createPartNumberToPartIdMap(List<Part__c> ImportedPartList)	{
    	return new Map<String, Id>();
    }
    
    // deprecated
    global List<Part_Alternates__c> createPartsAlternate(List<Part__c> ImportedPartList, Map<String, Id> partNumberToPartIdMap)	{
    	return new List<Part_Alternates__c>();
    }
    
    public List<Part_Alternates__c> createPartsAlternate(List<Part__c> ImportedPartList, Map<String, Map<String, Id>> vendorIdToPartNumberToPartIdMap, Map<Id, Part__c> partMapToUpdate)	{
    	List<Part_Alternates__c> partsAlternateList = new List<Part_Alternates__c>();
    	if(vendorIdToPartNumberToPartIdMap != null)	{ 
    		for(Part__c partRec: ImportedPartList)	{
    			Map<String, Id> partNumberToPartIdMap = new Map<String, Id>();
				if(partRec.Vendor__c != null && vendorIdToPartNumberToPartIdMap.containsKey(partRec.Vendor__c) && 
						vendorIdToPartNumberToPartIdMap.get(partRec.Vendor__c) != null) {
					partNumberToPartIdMap = vendorIdToPartNumberToPartIdMap.get(partRec.Vendor__c);
				}
    			
    			if(partRec.Replaces_Part__c != null && partNumberToPartIdMap.containsKey(partRec.Replaces_Part__c) && 
    							(partIdSetWithChangedRelation.contains(partRec.Id) || partRec.Part_Alternates__r.size() == 0))	{
    								
    				if(partRec.Replaces_Part__c == partRec.Part_Number__c) {
    					partRec.Replaces_Part__c = null;
    				} else {
		    			partsAlternateList.add(setPartAlternateFields(partRec.Id, 'Replaces', partNumberToPartIdMap.get(partRec.Replaces_Part__c)));
	    				partsAlternateList.add(setPartAlternateFields(partNumberToPartIdMap.get(partRec.Replaces_Part__c), 'Replaced By', partRec.Id));
	    				partMapToUpdate.put(partNumberToPartIdMap.get(partRec.Replaces_Part__c), new Part__c(Id = partNumberToPartIdMap.get(partRec.Replaces_Part__c), Is_Superseded__c = true, Superseded_To__c = partRec.Id));
    				}
	    		}
                if(partRec.Replaced_By_Part__c != null &&  partNumberToPartIdMap.containsKey(partRec.Replaced_By_Part__c) && 
								(partIdSetWithChangedRelation.contains(partRec.Id) || partRec.Part_Alternates__r.size() == 0)) {
                	if(partRec.Replaced_By_Part__c == partRec.Part_Number__c) {
                		partRec.Replaced_By_Part__c = null;
    				} else {
	    				partsAlternateList.add(setPartAlternateFields(partRec.Id, 'Replaced By', partNumberToPartIdMap.get(partRec.Replaced_By_Part__c)));
	    				partsAlternateList.add(setPartAlternateFields(partNumberToPartIdMap.get(partRec.Replaced_By_Part__c), 'Replaces', partRec.Id));
	    				partMapToUpdate.put(partRec.Id, new Part__c(Id = partRec.Id, Is_Superseded__c = true, Superseded_To__c = partNumberToPartIdMap.get(partRec.Replaced_By_Part__c)));
                	}
	    		}
	    	}	
    	}
    	return partsAlternateList;
    }
    
    private Part_Alternates__c setPartAlternateFields(String partId, String relation, String alternatePartId) {
    	Part_Alternates__c partAlternateRec = new Part_Alternates__c(); 
    	partAlternateRec.Part_ID__c = partId;
		partAlternateRec.Relation__c = relation;
		partAlternateRec.Alternate_Part_ID__c = alternatePartId;
    	return partAlternateRec;
    }

	public void deleteInvalidPartsAlternate(List<Part__c> ImportedPartList, Map<Id, Part__c> partMapToUpdate) {
		Set<Part_Alternates__c> partsAlternateSetToDelete = new Set<Part_Alternates__c>();
		Map<Id,List<Part_Alternates__c>> partIdToPartsAlternateMap = new Map<Id,List<Part_Alternates__c>>();
		Set<Id> setOfPartIds = new Set<Id>();
		// Map of Part Id To Its Parts Alternate
		for(Part__c partRec: ImportedPartList) {
			setOfPartIds.add(partRec.Id);
			for(Part_Alternates__c partAlternate : partRec.Part_Alternates__r) {
				setOfPartIds.add(partAlternate.Alternate_Part_ID__r.Id);
			}
		}
		// Get all partsAlternate releted to imported parts
		for(Part_Alternates__c partsAlternate :[SELECT Id, Part_ID__c, Relation__c, Alternate_Part_ID__r.Part_Number__c,  Alternate_Part_ID__r.Replaced_By_Part__c from part_alternates__c where Part_ID__c IN : setOfPartIds]) {
			if(!partIdToPartsAlternateMap.containsKey(partsAlternate.Part_ID__c)) {
				partIdToPartsAlternateMap.put(partsAlternate.Part_ID__c, new List<Part_Alternates__c>());
			}
			partIdToPartsAlternateMap.get(partsAlternate.Part_ID__c).add(partsAlternate);
		}
		Boolean deleteSupersessionIfBlank = true;
		try {
			String deleteSupersessionIfBlankStr = GeneralConfiguration.getConfigurationByName(GeneralConfiguration.DELETE_SUPERSESSION_IF_BLANK);
			if(String.isNotBlank(deleteSupersessionIfBlankStr)) {
				deleteSupersessionIfBlank = Boolean.valueOf(deleteSupersessionIfBlankStr);
			}
		} catch(Exception e) {
			system.debug('Exception: ' + e.getMessage());
		}
		for(Part__c partRec: ImportedPartList) {
			//Check if there is any updation in Relation
			partRec.Old_Replaced_By_Part__c = partRec.Superseded_To__c != null ? partRec.Superseded_To__r.Part_Number__c : null;
			if((String.isNotBlank(partRec.Replaced_By_Part__c) || deleteSupersessionIfBlank) && partRec.Old_Replaced_By_Part__c != partRec.Replaced_By_Part__c && partRec.Replaced_By_Part__c != partRec.Part_Number__c) {				
				for(Part_Alternates__c PartAlternate : partRec.Part_Alternates__r) {
					
					// Delete Replaced By/Replaces Relation
					if(PartAlternate.Part_ID__c == partRec.Id && PartAlternate.Relation__c.equalsIgnoreCase('Replaced By')) {
						//Add part id to set for creating entery condition when creating new supersessions
						partIdSetWithChangedRelation.add(PartAlternate.Part_ID__c);
						//Part Alternet set which need to delete before creating new one
						partsAlternateSetToDelete.add(PartAlternate);
						//Reset Superseded To relation and Is Superseded flag
						partMapToUpdate.put(partRec.Id, new Part__c(Id = partRec.Id, Is_Superseded__c = false, Superseded_To__c = null));

						// Delete Replaces/Replaced By Relation
						if(partIdToPartsAlternateMap.get(PartAlternate.Alternate_Part_ID__c) != null) {
							for(Part_Alternates__c PartAlternateRec : partIdToPartsAlternateMap.get(PartAlternate.Alternate_Part_ID__c)) {
								if(PartAlternateRec.Alternate_Part_ID__c == PartAlternate.Part_ID__c) {
									//Part Alternet set which need to delete before creating new one
									partsAlternateSetToDelete.add(PartAlternateRec);
									//Reset Superseded To relation and Is Superseded flag
									partMapToUpdate.put(PartAlternateRec.Part_ID__c, new Part__c(Id = PartAlternateRec.Part_ID__c, Is_Superseded__c = false, Superseded_To__c = null));
								}
							}
						}
					}
				}
			}
		}
		DMLUtility.deleteSobjectList('Part_Alternates__c', new List<Part_Alternates__c>(partsAlternateSetToDelete));
	}
}