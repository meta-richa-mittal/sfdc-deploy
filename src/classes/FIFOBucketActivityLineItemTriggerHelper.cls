/**
 * Author: Richa Mittal
 * Since: Jan 09, 2017
 * Name: FIFOBucketActivityLineItemTriggerHelper
 * Description: Helper class for triggers on Part_FIFO_Bucket_Activity_Line_Item__c object
**/
public without sharing class FIFOBucketActivityLineItemTriggerHelper {
    // List to store trigger new list
    public static List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFIBucketActivityLINewList = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
    
    // List to store trigger old list
    public static List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFIBucketActivityLIOldList = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Part_FIFO_Bucket_Activity_Line_Item__c> partFIFIBucketActivityLINewMap = new Map<Id, Part_FIFO_Bucket_Activity_Line_Item__c>();

    // Map to store Old Trigger Map
    public static Map<Id, Part_FIFO_Bucket_Activity_Line_Item__c> partFIFIBucketActivityLIOldMap = new Map<Id, Part_FIFO_Bucket_Activity_Line_Item__c>();
     
    // Trigger run boolean
    public static Boolean isTriggerRun;
    
    private static BaseIntegrationService integrationRec;
    
    public static void populatesAccountingSyncFields() {
    	IntegrationSyncFlagService.managePartFIFOBucketLISyncFlag(partFIFIBucketActivityLINewList);
        
    }
    
    public static void populatePartOnFIFOBucketActivityLI() {
		Set<String> fifoBktIdSet = new Set<String>();
    	for(Part_FIFO_Bucket_Activity_Line_Item__c fifoActivityLI : partFIFIBucketActivityLINewList) {
    		if(String.isBlank(fifoActivityLI.Part__c)) {
    			fifoBktIdSet.add(fifoActivityLI.Part_FIFO_Bucket__c);
    		}
    	}
		if(fifoBktIdSet.size() > 0) {
	    	Set<String> partIdSet = new Set<String>();
	    	Map<Id, Part_FIFO_Bucket__c> fifoBktIdToRecMap = new Map<Id, Part_FIFO_Bucket__c>([Select Id, Part__c from Part_FIFO_Bucket__c where Id IN: fifoBktIdSet]);
	    	for(Part_FIFO_Bucket_Activity_Line_Item__c fifoActivityLI : partFIFIBucketActivityLINewList) {
	    		if(String.isBlank(fifoActivityLI.Part__c) && fifoBktIdToRecMap.containsKey(fifoActivityLI.Part_FIFO_Bucket__c) && 
	    										fifoBktIdToRecMap.get(fifoActivityLI.Part_FIFO_Bucket__c).Part__c != null) {
	    			fifoActivityLI.Part__c = fifoBktIdToRecMap.get(fifoActivityLI.Part_FIFO_Bucket__c).Part__c;
	    		}
	    	}
		}
    }
	
    public static void populateInStockWhenCreated() {
    	Set<String> fifoBktIdSet = new Set<String>();
    	for(Part_FIFO_Bucket_Activity_Line_Item__c fifoActivityLI : partFIFIBucketActivityLINewList) {
    		fifoBktIdSet.add(fifoActivityLI.Part_FIFO_Bucket__c);
    	}
    	Set<String> partIdSet = new Set<String>();
    	Map<Id, Part_FIFO_Bucket__c> fifoBktIdToRecMap = new Map<Id, Part_FIFO_Bucket__c>([Select Id, Part__r.Qty_In_Stock__c, Part__r.Oversold_Qty__c, Part__r.Average_Cost__c from Part_FIFO_Bucket__c where Id IN: fifoBktIdSet]);
    	for(Part_FIFO_Bucket_Activity_Line_Item__c fifoActivityLI : partFIFIBucketActivityLINewList) {
    		if(fifoBktIdToRecMap.containsKey(fifoActivityLI.Part_FIFO_Bucket__c) && fifoBktIdToRecMap.get(fifoActivityLI.Part_FIFO_Bucket__c).Part__c != null) {
    			partIdSet.add(fifoBktIdToRecMap.get(fifoActivityLI.Part_FIFO_Bucket__c).Part__c);
    		}
    	}
    	if(system.isBatch() || system.isFuture()) {
    		String partStrQuery = 'SELECT Id, (Select Id, CreatedDate, Cost__c, Qty_In__c, Qty_In_Stock_When_Created__c, Average_Cost_When_Created__c ' +
        	'FROM Part_FIFO_Buckets__r WHERE Is_FIFO_Bucket__c = true Order By CreatedDate ASC) FROM Part__c where Id IN: partIdSet Order By CreatedDate ASC';
	        List<Part__c> partList = Database.query(partStrQuery);
	    	FIFOTransaction.updatePartFIFODetails(partList);	
    	} else if(!Test.isRunningTest()) {
    		system.enqueueJob(new SetQtyAndAvgCostOnFIFOBktAndLIQueueable(partIdSet));
    	}
    	
    }
    
    public static void setPartFIFOBucketActivityLIDataForAccountSync() {
		IntegrationSyncFlagService.checkAndInitiateSyncBatch(partFIFIBucketActivityLINewList, IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM);
    }
}