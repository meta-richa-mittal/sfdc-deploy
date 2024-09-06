/**
 * Author: Gourav Goyal
 * Since: Dec 27, 2017
 * Name: PartSyncAgeBatch_Schedular
 * Description: Apex class to schedule PartSyncAgeBatch_Schedular .
**/

global without sharing class PartSyncAgeBatch_Schedular implements Database.Batchable<sobject>, Database.Stateful, Schedulable {
	private List<String> partAgingConfigFieldList = new List<String> {'Period_1__c', 'Period_2__c', 'Period_3__c', 'Period_4__c'};
    private List<String> partAgingQtyFieldList = new List<String> {'PRD1Qty__c', 'PRD2Qty__c', 'PRD3Qty__c', 'PRD4Qty__c'};
    private List<String> partAgingCostFieldList = new List<String> {'PRD1Cost__c', 'PRD2Cost__c', 'PRD3Cost__c', 'PRD4Cost__c'};
	
	global Database.QueryLocator start(Database.BatchableContext bc){	
        return Database.getQueryLocator('SELECT Id from part__c order by Qty_In_Stock__c DESC'); 
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> listParts) {
		List<Part__c> partsList = [SELECT Id, Part_Aging_Detail__c, (SELECT Age__c,Total__c, Remaining_Qty__c FROM Part_FIFO_Buckets__r where Remaining_Qty__c > 0), (SELECT Id, Part__c FROM Part_Aging_Details__r limit 1) from part__c where Id IN : listParts];
    	Part_Aging_Period__c partAgingConfigObj = Part_Aging_Period__c.getOrgDefaults();
    	Map<Integer, List<Decimal>> periodToAgingValuesMap = new Map<Integer, List<Decimal>>();
        
       	List<Part_Aging_Detail__c> partAgingDetailListToUpsert = new List<Part_Aging_Detail__c>();
       	List<Part__c> partListToUpdate = new List<Part__c>();
		List<Part_Aging_Detail__c> partAgingDetailListToDelete = new List<Part_Aging_Detail__c>();
        
        for(Part__c part : partsList) {
			if(!part.Part_FIFO_Buckets__r.isEmpty()) {
        	for(Integer counter = 0; counter < partAgingConfigFieldList.size() ; counter++) {
        		periodToAgingValuesMap.put(counter+1, new List<Decimal>{0, 0, 0});
        	}
	    	
				for(Part_FIFO_Bucket__c partFifoBucket :  part.Part_FIFO_Buckets__r) {
        		//system.assert(false,partFifoBucket);
        		for(Integer i = 0; i < partAgingConfigFieldList.size(); i++) {
    				if(partFifoBucket.Age__c != null && partAgingConfigObj.get(partAgingConfigFieldList[i]) != null && 
    					(i == partAgingConfigFieldList.size() - 1 || partFifoBucket.Age__c <= Decimal.valueOf(String.valueOf(partAgingConfigObj.get(partAgingConfigFieldList[i]))))) {
	        			List<Decimal> agingValueList = periodToAgingValuesMap.get(i+1);
	        			agingValueList[0] += partFifoBucket.Remaining_Qty__c;
	        			agingValueList[1] += (partFifoBucket.Total__c);
	        			//system.assert(false,agingValueList);
	        			break;
        			}
    			}
        	}
			Part_Aging_Detail__c partAgingDetailRec = !part.Part_Aging_Details__r.isEmpty() ? part.Part_Aging_Details__r[0] : new Part_Aging_Detail__c(Part__c = part.Id);
        	
        	for(Integer periodValue : periodToAgingValuesMap.keyset()) {
        		List<Decimal> agingValueList = periodToAgingValuesMap.get(periodValue);
        		partAgingDetailRec.put(partAgingQtyFieldList[periodValue - 1], agingValueList[0]);
        		partAgingDetailRec.put(partAgingCostFieldList[periodValue - 1], agingValueList[1]);
        	}
        	partAgingDetailListToUpsert.add(partAgingDetailRec);
			if(part.Part_Aging_Detail__c == null) {
        	partListToUpdate.add(part);
        }
			} else if(!part.Part_Aging_Details__r.isEmpty()) {
				partAgingDetailListToDelete.addAll(part.Part_Aging_Details__r);
        }
        }
        if(partAgingDetailListToUpsert.size() > 0){
			DMLUtility.upsertSobjectList('Part_Aging_Detail__c', partAgingDetailListToUpsert);
    	}
        if(partListToUpdate.size() > 0){
			updateParts(partAgingDetailListToUpsert, partListToUpdate);
    	}
		if(!partAgingDetailListToDelete.isEmpty()){
			DMLUtility.deleteSobjectList('Part_Aging_Detail__c', partAgingDetailListToDelete);
    	}
    }
    
    global void finish(Database.batchableContext bc){  	
    }
    
    global void execute(SchedulableContext SC) {
		Database.executeBatch(new PartSyncAgeBatch_Schedular(), 2000);
		
	}

	private void updateParts(List<Part_Aging_Detail__c> partAgingDetailListToUpsert, List<Part__c> partListToUpdate) {
		Map<String, String> partIdToPartAgingIdMap = new Map<String, String>();
		for(Part_Aging_Detail__c partAgingDetailRec : partAgingDetailListToUpsert) {
			if(!partIdToPartAgingIdMap.containsKey(partAgingDetailRec.Part__c)) {
				partIdToPartAgingIdMap.put(partAgingDetailRec.Part__c, partAgingDetailRec.Id);
			}
		}
		for(Part__c partRec : partListToUpdate) {
			if(partIdToPartAgingIdMap.containsKey(partRec.Id)) {
				partRec.Part_Aging_Detail__c = partIdToPartAgingIdMap.get(partRec.Id);
			} 
		}
		PartTriggerHelper.isForceStopTrigger = true;
		DMLUtility.updateSobjectList('Part__c', partListToUpdate);
		PartTriggerHelper.isForceStopTrigger = false;
	}
}