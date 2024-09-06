/**
 * Author: Richa Mittal
 * Since: Sept 13, 2019
 * Name: FinalizeCountSessionBatch
 * Description: Batch for updating count session, its LI and parts on finalize action
**/
global without sharing class FinalizeCountSessionBatch implements Database.Batchable<sobject>, Database.Stateful {
    
    private Count_Session__c countSessionRec;
    private List<Log__c> errorLogToInsert;
    private Integer batchNumber = 0;
    global FinalizeCountSessionBatch(Count_Session__c countSession) {
	    countSessionRec = countSession;
	}
	
    global Iterable<Sobject> start(Database.BatchableContext BC) {
    	errorLogToInsert = new List<Log__c>();
    	String countSessionId = countSessionRec.Id;
	    String query = 'SELECT Id, Is_Counted__c, Cost__c, Counted_Qty__c, Qty_Available__c, Variance__c, Part_Category__c, Part__c, Part__r.Category__c, Part__r.Qty_In_Stock__c, ' +
	    'Count_Session__r.Is_Adjust_Uncounted_Parts_To_Zero_Qty__c, Count_Session__r.Count_Date_Time__c, Assigned_Location_1__c, Assigned_Location_2__c, ' +
	    'Part__r.Assigned_Location_1__c, Part__r.Assigned_Location_2__c ' +
	    'FROM Count_Session_Line_Item__c WHERE Count_Session__c = :countSessionId';
	    if(countSessionRec != null && !countSessionRec.Is_Adjust_Uncounted_Parts_To_Zero_Qty__c) {
	    	query += ' AND Is_Counted__c = true';
	    }
		return Database.query(query);
	}
    
    global void execute(Database.batchableContext bc, List<sObject> scope) {
    	Savepoint sp = Database.setSavepoint();
		List<Count_Session_Line_Item__c> csliList = (List<Count_Session_Line_Item__c>) scope;
		Set<String> partFIFOCSLIIdSet = new Set<String>();

		List<Part_FIFO_Bucket__c> partFIFOList = [SELECT Id, Count_Session_Line_Item__c FROM Part_FIFO_Bucket__c Where Count_Session_Line_Item__c IN: csliList];
		List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOLIList = [SELECT Id, Count_Session_Line_Item__c FROM Part_FIFO_Bucket_Activity_Line_Item__c Where Count_Session_Line_Item__c IN: csliList];

		for(Part_FIFO_Bucket__c partRec : partFIFOList) {
			partFIFOCSLIIdSet.add(partRec.Count_Session_Line_Item__c);
		}

		for(Part_FIFO_Bucket_Activity_Line_Item__c partLIRec : partFIFOLIList) {
			partFIFOCSLIIdSet.add(partLIRec.Count_Session_Line_Item__c);
		}

    	List<Count_Session_Line_Item__c> countSessionLineItemList = new List<Count_Session_Line_Item__c>();
    	List<Count_Session_Line_Item__c> countSessionLineItemWithVarianceList = new List<Count_Session_Line_Item__c>();
    	try {
    		batchNumber++;
    		for(Count_Session_Line_Item__c countSessionLIRec: csliList) {
    			if(!partFIFOCSLIIdSet.contains(countSessionLIRec.Id)) {
    				countSessionLineItemList.add(countSessionLIRec);
    				countSessionLIRec.Counted_Qty__c = countSessionLIRec.Counted_Qty__c != null ? countSessionLIRec.Counted_Qty__c : 0;
    				countSessionLIRec.Qty_Available__c = countSessionLIRec.Qty_Available__c != null ? countSessionLIRec.Qty_Available__c : 0;
    				if(((countSessionLIRec.Counted_Qty__c - countSessionLIRec.Qty_Available__c) != 0) && (countSessionLIRec.Is_Counted__c || countSessionLIRec.Count_Session__r.Is_Adjust_Uncounted_Parts_To_Zero_Qty__c)) {
    					countSessionLineItemWithVarianceList.add(countSessionLIRec);
    				}
    			}
    		}
    		
    		if(countSessionLineItemList.size() > 0) {
    			updateParts(countSessionLineItemList);
    			createPartAdjustments(countSessionLineItemWithVarianceList);
    			updateCountSessionLineItems(countSessionLineItemList);
    		}
    	} catch(Exception e) {
            Database.rollback(sp);
            createLogs(e, scope, 'execute');
        }
    }
    
    global void finish(Database.batchableContext bc) {
    	if(errorLogToInsert.size() > 0) {
			DMLUtility.insertSobjectList('Log__c', errorLogToInsert);
			updateCountSession(false);
    	} else {
    		updateCountSession(true);
    	}
    }
    
    private void updateCountSessionLineItems(List<Count_Session_Line_Item__c> countSessionLineItemList) {
    	try {
	    	List<Count_Session_Line_Item__c> countSessionLineItemListAfterAdjustment = [SELECT Id, Is_Counted__c, Count_Session__r.Is_Adjust_Uncounted_Parts_To_Zero_Qty__c, Part__r.Category__c, 
	    																					(SELECT Id, Qty_In__c, Cost__c FROM Part_FIFO_Buckets__r), 
	    																					(SELECT Id, Qty_Out__c, Part_FIFO_Bucket__r.Cost__c FROM Part_FIFO_Bucket_Activity_Line_Items__r)
	    																					FROM Count_Session_Line_Item__c WHERE Id IN :countSessionLineItemList];
	    	for(Count_Session_Line_Item__c countSessionLineItemRec : countSessionLineItemListAfterAdjustment) {
	    		if(!countSessionLineItemRec.Is_Counted__c && countSessionLineItemRec.Count_Session__r.Is_Adjust_Uncounted_Parts_To_Zero_Qty__c) {
	    			countSessionLineItemRec.Is_Counted__c = true;
	    		}
	    		countSessionLineItemRec.Part_Category__c = countSessionLineItemRec.Is_Counted__c ? countSessionLineItemRec.Part__r.Category__c : null;
	    		Decimal netAdjustedCostAfterFinalize = 0;
	    		for(Part_FIFO_Bucket__c fifoBucketRec : countSessionLineItemRec.Part_FIFO_Buckets__r) {
	    			netAdjustedCostAfterFinalize += ((fifoBucketRec.Qty_In__c != null ? fifoBucketRec.Qty_In__c : 0) * (fifoBucketRec.Cost__c != null ? fifoBucketRec.Cost__c : 0)).setScale(2, RoundingMode.HALF_UP); 
	    		}
	    		
	    		for(Part_FIFO_Bucket_Activity_Line_Item__c fifoBucketLIRec : countSessionLineItemRec.Part_FIFO_Bucket_Activity_Line_Items__r) {
	    			netAdjustedCostAfterFinalize -= ((fifoBucketLIRec.Qty_Out__c != null ? fifoBucketLIRec.Qty_Out__c : 0) * (fifoBucketLIRec.Part_FIFO_Bucket__r.Cost__c != null ? fifoBucketLIRec.Part_FIFO_Bucket__r.Cost__c : 0)).setScale(2, RoundingMode.HALF_UP); 
	    		}
	    		countSessionLineItemRec.Total_Cost_Adjustment__c = netAdjustedCostAfterFinalize;
	    	}
	    	
	    	if(countSessionLineItemListAfterAdjustment.size() > 0) {
				DMLUtility.updateSobjectList('Count_Session_Line_Item__c', countSessionLineItemListAfterAdjustment);
	    	}
    	} catch(Exception e) {
    		createLogs(e, countSessionLineItemList, 'updateCountSessionLineItems');
    	}
    }
    
    private void updateParts(List<Count_Session_Line_Item__c> countSessionLineItemList) {
    	try {
    		List<Part__c> partList = new List<Part__c>();
	    	for(Count_Session_Line_Item__c countSessionLineItemRec : countSessionLineItemList) {
    			DateTime lastCounted = countSessionLineItemRec.Count_Session__r.Count_Date_Time__c != null ? countSessionLineItemRec.Count_Session__r.Count_Date_Time__c : System.now();
    			Decimal qtyInStock = (countSessionLineItemRec.Part__r.Qty_In_Stock__c != null ? countSessionLineItemRec.Part__r.Qty_In_Stock__c : 0) + (countSessionLineItemRec.Counted_Qty__c - countSessionLineItemRec.Qty_Available__c);
    			Part__c partRecToUpdate = new Part__c(Id = countSessionLineItemRec.Part__c, Qty_In_Stock__c = qtyInStock);
    			if(String.isNotBlank(countSessionLineItemRec.Assigned_Location_1__c)) {
    				partRecToUpdate.Assigned_Location_1__c = countSessionLineItemRec.Assigned_Location_1__c;
    			}
    			if(String.isNotBlank(countSessionLineItemRec.Assigned_Location_2__c)) {
    				partRecToUpdate.Assigned_Location_2__c = countSessionLineItemRec.Assigned_Location_2__c;
    			}
    			if(countSessionLineItemRec.Is_Counted__c) {
    				partRecToUpdate.Last_Counted__c = lastCounted; 
    			}
    			partList.add(partRecToUpdate);
	    	}
	    	if(partList.size() > 0) {
	    		PartTriggerHelper.isRunningFromFinalizeCountSessionAction = true;
				DMLUtility.updateSobjectList('Part__c', partList);
	    		PartTriggerHelper.isRunningFromFinalizeCountSessionAction = false;
	    	}
    	} catch(Exception e) {
    		createLogs(e, countSessionLineItemList, 'updateParts');
    	}
    }
    
    private void createPartAdjustments(List<Count_Session_Line_Item__c> countSessionLineItemList) {
    	try {
    		Map<Id, PartFIFOAdjustmentService.PartCountAjustmentWrapper> partIdToCountAjustmentWrapperMap = new Map<Id, PartFIFOAdjustmentService.PartCountAjustmentWrapper>();
	    	for(Count_Session_Line_Item__c countSessionLineItemRec : countSessionLineItemList) {
	    		countSessionLineItemRec.Part__r.Qty_In_Stock__c = countSessionLineItemRec.Part__r.Qty_In_Stock__c != null ? countSessionLineItemRec.Part__r.Qty_In_Stock__c : 0;
	    		PartFIFOAdjustmentService.PartCountAjustmentWrapper partCountAdjustmentWrapperObj = 
	    			new PartFIFOAdjustmentService.PartCountAjustmentWrapper(countSessionLineItemRec.Part__c, 
	    					countSessionLineItemRec.Part__r.Qty_In_Stock__c, 
	    					countSessionLineItemRec.Cost__c, countSessionLineItemRec.Id, countSessionLineItemRec.Count_Session__r.Count_Date_Time__c);
	    		partIdToCountAjustmentWrapperMap.put(countSessionLineItemRec.Part__c, partCountAdjustmentWrapperObj);
	    	}
	    	List<Part_FIFO_Bucket__c> partFifoBucketsList = PartFIFOAdjustmentService.adjustPartQty(partIdToCountAjustmentWrapperMap);
    	} catch(Exception e) {
    		createLogs(e, countSessionLineItemList, 'createPartAdjustments');
    	}
    }
    
    private void updateCountSession(Boolean isClosed) {
    	try {
    		countSessionRec.Status__c = isClosed ? 'Closed' : 'In Progress';
			DMLUtility.updateSobjectList('Count_Session__c', countSessionRec);
    	} catch(Exception e) {
    		errorLogToInsert.add(new LogService().createErrorLog('FinalizeCountSessionBatch', 'updateCountSession()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              countSessionRec + '', LogService.PART_COUNT, false,'Error'));
    	}
    }
    
    private void createLogs(Exception e, List<Count_Session_Line_Item__c> countSessionLineItemList, String methodName) {
    	String failedCountSessionIds = '';
        for(Count_Session_Line_Item__c countSessionLineItemRec: countSessionLineItemList) {
        	failedCountSessionIds += countSessionLineItemRec.Id + ';';
        }
        errorLogToInsert.add(new LogService().createErrorLog('FinalizeCountSessionBatch', methodName + ' - Batch Number ' + batchNumber, e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              failedCountSessionIds, LogService.PART_COUNT, false,'Error'));
    }
}