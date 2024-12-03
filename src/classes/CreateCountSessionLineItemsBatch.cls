/**
 * Author: Nidhi Sharma
 * Since: Aug 29, 2019
 * Name: CreateCountSessionLineItemsBatch
 * Description: Batch for creating count session line items
**/
global without sharing class CreateCountSessionLineItemsBatch implements Database.Batchable<sobject> {
    
    private String countSessionId;
    global CreateCountSessionLineItemsBatch(String recordId) {
	    countSessionId = recordId;
	}
	
    global Iterable<Sobject> start(Database.BatchableContext BC) {
    	List<Count_Session__c> countSessionRecList = [Select Id, Type__c, Vendors__c, Categories__c, Assigned_Location_1__c, Assigned_Location_2__c from 
    					Count_Session__c where Id =: countSessionId AND Type__c != 'Random Count'];

    	if(countSessionRecList.size() > 0 && countSessionRecList[0].Type__c != 'Random Count') {
    		List<String> vendorIdList;
			List<String> categoryIdList;
			List<String> locationNameList;
			
			String whereClause = '';
			if(countSessionRecList[0].Type__c.toUpperCase() == 'CYCLE COUNT') {
	        	if(countSessionRecList[0].Vendors__c != null) {
	        		vendorIdList = countSessionRecList[0].Vendors__c.split(';');
	        		whereClause += (vendorIdList.size() > 0) ? ' AND Vendor__c IN: vendorIdList' : '';
	        	}
	        	
	        	if(countSessionRecList[0].Categories__c != null) {
	        		categoryIdList = countSessionRecList[0].Categories__c.split(';');
	        		whereClause += (categoryIdList.size() > 0) ? ' AND Category__c IN: categoryIdList' : '';
	        	}
	        	
	        	if(countSessionRecList[0].Assigned_Location_1__c != null) {
	        		locationNameList = countSessionRecList[0].Assigned_Location_1__c.split(';');
	        		if(countSessionRecList[0].Assigned_Location_2__c != null) {
	        			locationNameList.addAll(countSessionRecList[0].Assigned_Location_2__c.split(';'));
	        		}
	        		
	        		whereClause += (locationNameList.size() > 0) ? ' AND ' + HomeSearchReportInterface.getAssignedTagClause('Parts', locationNameList, 'Location') : '';
	        	}
			}
			
			countSessionRecList[0].Is_Creation_Completed__c = false;
			DMLUtility.updateSobjectList('Count_Session__c', countSessionRecList);

	        String query = 'SELECT Id, Average_Cost__c, Last_Cost__c, AvailableParts__c, Vendor__c,  Assigned_Location_1__c, Assigned_Location_2__c FROM Part__c WHERE ' +
	        	' (((AvailableParts__c != null AND AvailableParts__c != 0) OR (Oversold_Qty__c != null AND Oversold_Qty__c != 0)) AND Active__c = true) ';
    		query += whereClause;
    		return Database.query(query);
    	}
    	return new List<SObject>();
	}
    
    global void execute(Database.batchableContext bc, List<sObject> scope) {
    	List<Part__c> partList = (List<Part__c>) scope;
    	insertCountSessionLineItems(partList);
    }
    
    global void finish(Database.batchableContext bc) {
		Count_Session__c countSessionRec = new Count_Session__c(Id = countSessionId, Is_Creation_Completed__c = true);
		DMLUtility.updateSobjectList('Count_Session__c', countSessionRec);
    }
    
    private void insertCountSessionLineItems(List<Part__c> partList) {
    	List<Count_Session_Line_Item__c> countSessionLineItemRecList = new List<Count_Session_Line_Item__c>();
    	for(Part__c partRec : partList) {
    		Count_Session_Line_Item__c countSessionLineItemRec = new Count_Session_Line_Item__c(Count_Session__c = countSessionId, Is_Selected_Part__c = true);
    		countSessionLineItemRec.Part__c = partRec.Id;
    		countSessionLineItemRec.Cost__c = (partRec.Average_Cost__c != null && partRec.Average_Cost__c != 0) ? partRec.Average_Cost__c : partRec.Last_Cost__c;
    		countSessionLineItemRec.Qty_Available__c = partRec.AvailableParts__c;
    		countSessionLineItemRec.Assigned_Location_1__c = partRec.Assigned_Location_1__c;
    		countSessionLineItemRec.Assigned_Location_2__c = partRec.Assigned_Location_2__c;
    		countSessionLineItemRecList.add(countSessionLineItemRec);
    	}
    	
    	if(countSessionLineItemRecList.size() > 0) {
			DMLUtility.insertSobjectList('Count_Session_Line_Item__c', countSessionLineItemRecList);
    	}
    }
}