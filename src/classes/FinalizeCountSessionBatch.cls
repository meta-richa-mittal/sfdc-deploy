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
	    'Part__r.Assigned_Location_1__c, Part__r.Assigned_Location_2__c,Part__r.Oversold_Qty__c, Part__r.Last_Cost__c ' +
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
    			Map<Id,Decimal> countSessionLIIdToOversoldQtyMap = updateParts(countSessionLineItemList);
    			createPartAdjustments(countSessionLineItemWithVarianceList,countSessionLIIdToOversoldQtyMap);
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
			Database.executeBatch(new ShopifySyncWebsiteProductBatch(true), ShopifyUtil.BulkProcessBatchSize);
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
    
    private Map<Id,Decimal> updateParts(List<Count_Session_Line_Item__c> countSessionLineItemList) {
    	Map<Id,Decimal> countSessionLIIdToOversoldQtyMap = new Map<Id,Decimal>();
        try {
    		List<Part__c> partList = new List<Part__c>();
			Set<String> locationNameInsertSet = new Set<String>();
	    	for(Count_Session_Line_Item__c countSessionLineItemRec : countSessionLineItemList) {
    			DateTime lastCounted = countSessionLineItemRec.Count_Session__r.Count_Date_Time__c != null ? countSessionLineItemRec.Count_Session__r.Count_Date_Time__c : System.now();
    			Decimal qtyInStock = (countSessionLineItemRec.Part__r.Qty_In_Stock__c != null ? countSessionLineItemRec.Part__r.Qty_In_Stock__c : 0) + (countSessionLineItemRec.Counted_Qty__c - countSessionLineItemRec.Qty_Available__c);
    			Part__c partRecToUpdate;
				if(qtyInStock < 0) {
					partRecToUpdate = new Part__c(Id = countSessionLineItemRec.Part__c, Oversold_Qty__c = -qtyInStock, Qty_In_Stock__c = 0);
					partList.add(updateOtherRecordsOnPart(partRecToUpdate, countSessionLineItemRec, lastCounted));
                    countSessionLIIdToOversoldQtyMap.put(countSessionLineItemRec.Id,-qtyInStock);
                } else {
					partRecToUpdate = new Part__c(Id = countSessionLineItemRec.Part__c, Qty_In_Stock__c = qtyInStock);
					partList.add(updateOtherRecordsOnPart(partRecToUpdate, countSessionLineItemRec, lastCounted));
				}
				populateLocationsToInsertSet(partRecToUpdate, locationNameInsertSet);
	    	}
	    	if(partList.size() > 0) {
	    		PartTriggerHelper.isRunningFromFinalizeCountSessionAction = PartTriggerHelper.isBulkPartProcess = true;
				DMLUtility.updateSobjectList('Part__c', partList);
	    		PartTriggerHelper.isRunningFromFinalizeCountSessionAction = PartTriggerHelper.isBulkPartProcess = false;
	    	}

			if(!locationNameInsertSet.isEmpty()) {
				LocationManagementService.createNewLocations(locationNameInsertSet);
			}
    	} catch(Exception e) {
    		createLogs(e, countSessionLineItemList, 'updateParts');
    	}
        return countSessionLIIdToOversoldQtyMap;
    }

	private void populateLocationsToInsertSet(Part__c partRecToUpdate, Set<String> locationNameInsertSet) {
		for(String newLocation: LocationManagementService.getLocationsList(partRecToUpdate)) {
			if(newLocation.length() <= 20) {
				locationNameInsertSet.add(newLocation);
			}
		}
	}
    
    private Part__c updateOtherRecordsOnPart(Part__c partRecToUpdate, Count_Session_Line_Item__c countSessionLineItemRec, DateTime lastCounted){
		if(String.isNotBlank(countSessionLineItemRec.Assigned_Location_1__c)) {
			partRecToUpdate.Assigned_Location_1__c = countSessionLineItemRec.Assigned_Location_1__c;
		}
		if(String.isNotBlank(countSessionLineItemRec.Assigned_Location_2__c)) {
			partRecToUpdate.Assigned_Location_2__c = countSessionLineItemRec.Assigned_Location_2__c;
		}
		if(countSessionLineItemRec.Is_Counted__c) {
			partRecToUpdate.Last_Counted__c = lastCounted; 
		}
		return partRecToUpdate;
	}

    private void createPartAdjustments(List<Count_Session_Line_Item__c> countSessionLineItemList, Map<Id,Decimal> countSessionLIIdToOversoldQtyMap) {
    	try {
    		Map<Id, PartFIFOAdjustmentService.PartCountAjustmentWrapper> partIdToCountAjustmentWrapperMap = new Map<Id, PartFIFOAdjustmentService.PartCountAjustmentWrapper>();
			Map<Id, Count_Session_Line_Item__c> countSessionLIIDToRecordMap = new Map<Id, Count_Session_Line_Item__c>();
			for(Count_Session_Line_Item__c countSessionLineItemRec : countSessionLineItemList) {
	    		countSessionLineItemRec.Part__r.Qty_In_Stock__c = countSessionLineItemRec.Part__r.Qty_In_Stock__c != null ? countSessionLineItemRec.Part__r.Qty_In_Stock__c : 0;
	    		PartFIFOAdjustmentService.PartCountAjustmentWrapper partCountAdjustmentWrapperObj = 
	    			new PartFIFOAdjustmentService.PartCountAjustmentWrapper(countSessionLineItemRec.Part__c, 
	    					countSessionLineItemRec.Part__r.Qty_In_Stock__c, 
	    					countSessionLineItemRec.Cost__c, countSessionLineItemRec.Id, countSessionLineItemRec.Count_Session__r.Count_Date_Time__c);
	    		partIdToCountAjustmentWrapperMap.put(countSessionLineItemRec.Part__c, partCountAdjustmentWrapperObj);
				countSessionLIIDToRecordMap.put(countSessionLineItemRec.Id, countSessionLineItemRec);
	    	}
	    	List<Part_FIFO_Bucket__c> partFifoBucketsList = PartFIFOAdjustmentService.adjustPartQty(partIdToCountAjustmentWrapperMap);
            createPartFifoAndFifoLIForOversoldQty(countSessionLIIdToOversoldQtyMap, countSessionLIIDToRecordMap);
    	} catch(Exception e) {
    		createLogs(e, countSessionLineItemList, 'createPartAdjustments');
    	}
    }
    
    private void createPartFifoAndFifoLIForOversoldQty(Map<Id,Decimal> countSessionLIIdToOversoldQtyMap, Map<Id, Count_Session_Line_Item__c> countSessionLIIDToRecordMap){
        if(countSessionLIIdToOversoldQtyMap != null){
			List<Part_FIFO_Bucket__c> fifoToInsertList = new List<Part_FIFO_Bucket__c>();
        	List<Part_FIFO_Bucket_Activity_Line_Item__c> fifoLIToInsertList = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
        	for(Count_Session_Line_Item__c countSessionLineItemRec: countSessionLIIDToRecordMap.values()) {
            	if(countSessionLIIdToOversoldQtyMap.containsKey(countSessionLineItemRec.Id)) {
					Part_FIFO_Bucket__c bucket = new Part_FIFO_Bucket__c();  
            		bucket.Source_Name__c = 'Oversold';
        			bucket.Qty_In__c = -countSessionLIIdToOversoldQtyMap.get(countSessionLineItemRec.Id);
            		bucket.Cost__c =  countSessionLineItemRec.Part__r.Last_Cost__c;
            		bucket.VRCost__c = countSessionLineItemRec.Part__r.Last_Cost__c;
            		bucket.Part__c = countSessionLineItemRec.Part__c;
            		bucket.Is_FIFO_Bucket__c = true;
            		bucket.Count_Session_Line_Item__c = countSessionLineItemRec.Id;
            		fifoToInsertList.add(bucket);

            		Part_FIFO_Bucket__c bucketOverSold = new Part_FIFO_Bucket__c();  
            		bucketOverSold.Source_Name__c = 'Oversold profits';
            		bucketOverSold.Cost__c =  countSessionLineItemRec.Part__r.Last_Cost__c;
            		bucketOverSold.Qty_In__c = countSessionLIIdToOversoldQtyMap.get(countSessionLineItemRec.Id);
            		bucketOverSold.Part__c = countSessionLineItemRec.Part__c;
            		bucketOverSold.Is_FIFO_Bucket__c = false;
            		fifoToInsertList.add(bucketOverSold);
				}
        	}
		
        	DMLUtility.insertSobjectList('Part_FIFO_Bucket__c', fifoToInsertList);

        	for(Part_FIFO_Bucket__c fifoBucketRec: fifoToInsertList){
				if(fifoBucketRec.Source_Name__c == 'Oversold profits'){
            		Part_FIFO_Bucket_Activity_Line_Item__c objFifoActivityLineItemRec = new Part_FIFO_Bucket_Activity_Line_Item__c();
       				objFifoActivityLineItemRec.Qty_Out__c = fifoBucketRec.Qty_In__c;
       				objFifoActivityLineItemRec.Part_FIFO_Bucket__c = FifoBucketRec.Id;
       				objFifoActivityLineItemRec.Part__c = FifoBucketRec.Part__c;
       				objFifoActivityLineItemRec.Type__c = 'Over Sold Profits';
       				objFifoActivityLineItemRec.Cost__c = fifoBucketRec.Cost__c;
            		fifoLIToInsertList.add(objFifoActivityLineItemRec);
				}
        	}
        	DMLUtility.insertSobjectList('Part_FIFO_Bucket_Activity_Line_Item__c',fifoLIToInsertList);
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