public class PartFIFOBucketTriggerHelper {

	public static Boolean isForceStopPartQtyChange = false; //doing this to stop shopify job running 2 times in case of vendor receiving only
	
	public static List<Part_FIFO_Bucket__c> partFIFOBucketNewList = new List<Part_FIFO_Bucket__c>();
    public static List<Part_FIFO_Bucket__c> partFIFOBucketOldList = new List<Part_FIFO_Bucket__c>();
    public static Map<Id, Part_FIFO_Bucket__c> partFIFOBucketNewMap = new Map<Id, Part_FIFO_Bucket__c>();
    public static Map<Id, Part_FIFO_Bucket__c> partFIFOBucketOldMap = new Map<Id, Part_FIFO_Bucket__c>();
    
    // Trigger run boolean: Added by Pooja 9 Jan. 2017 (QB Integration)
    public static Boolean preventOnAccountingSync = false;
    private static BaseIntegrationService integrationRec;
    
    private static Set<Id> partIdSet = new Set<Id>();
    
	public static void afterInsertCalculation() {
		getPartIdListToUpdate(partFIFOBucketNewList);
	}
	
	public static void afterUpdateCalculation() {
		getPartIdListToUpdate(partFIFOBucketNewList);
	}
	
	public static void getPartIdListToUpdate(List<Part_FIFO_Bucket__c> partFIFOBucketList) {
		for(Part_FIFO_Bucket__c partFIFOBucketObj : partFIFOBucketList) {
			//if(partFIFOBucketObj.Source_Name__c != null && partFIFOBucketObj.Source_Name__c == 'Oversold') {
				if(partFIFOBucketObj.Part__c != null) {
					if(trigger.isDelete && partFIFOBucketObj.Has_Part_FIFO_Bucket__c) {
						partIdSet.add(partFIFOBucketObj.Part__c);	
					} else{
						partIdSet.add(partFIFOBucketObj.Part__c);	
					}
				}
				
				if(trigger.isUpdate) {
					Part_FIFO_Bucket__c oldpartFIFOBucket = partFIFOBucketOldMap.get(partFIFOBucketObj.Id);
					if(oldpartFIFOBucket.Part__c != null && oldpartFIFOBucket.Part__c != partFIFOBucketObj.Part__c) {
						partIdSet.add(oldpartFIFOBucket.Part__c);
					}
				}
			//}
		}
		updatePartList();
	}
	
	public static void populateInStockWhenCreated() {
    	Set<String> partIdSet = new Set<String>();
    	for(Part_FIFO_Bucket__c fifoRec : partFIFOBucketNewList) {
    		partIdSet.add(fifoRec.Part__c);
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
    
	public static void updatePartList() {
		//START : Modified by Nidhi - Ticket #1280 - 11-11-2016
		List<Part__c> partList = [Select Id, Oversold_Qty__c, Oversold_Cost__c, Total_Cost__c, Average_Cost__c, Has_FIFO_Bucket__c, (Select id, Qty_In__c, Qty_Out__c, Total__c, Source_Name__c, Remaining_Qty__c from Part_FIFO_Buckets__r Where Is_FIFO_Bucket__c = true ) from Part__c where Id In :partIdSet];
		
		/**
		for(Part__c partRec : partList) {
			Decimal oversoldQty = 0;
			Decimal oversoldCost = 0;
			for(Part_FIFO_Bucket__c partFIFOBucketRec : partRec.Part_FIFO_Buckets__r) {
				oversoldQty += ((partFIFOBucketRec.Qty_In__c != null) ? partFIFOBucketRec.Qty_In__c : 0.00) - ((partFIFOBucketRec.Qty_Out__c != null) ? partFIFOBucketRec.Qty_Out__c : 0.00);
				oversoldCost += (partFIFOBucketRec.Total__c != null) ? partFIFOBucketRec.Total__c : 0.00;
			}
			partRec.Oversold_Qty__c = oversoldQty;
			partRec.Oversold_Cost__c = oversoldCost;
		}
		*/
		for(Part__c partRec : partList) {
			Decimal oversoldQty = 0;
			Decimal oversoldCost = 0;
			Decimal TotalCost = 0;
			Decimal QtyInStock = 0;
			for(Part_FIFO_Bucket__c partFIFOBucketRec : partRec.Part_FIFO_Buckets__r) {
				if(!String.isBlank(partFIFOBucketRec.Source_Name__c) && (partFIFOBucketRec.Source_Name__c.equalsIgnoreCase('Oversold') || partFIFOBucketRec.Remaining_Qty__c < 0)){
					oversoldQty += ((partFIFOBucketRec.Qty_In__c != null) ? partFIFOBucketRec.Qty_In__c : 0.00) - ((partFIFOBucketRec.Qty_Out__c != null) ? partFIFOBucketRec.Qty_Out__c : 0.00);
					oversoldCost += (partFIFOBucketRec.Total__c != null) ? partFIFOBucketRec.Total__c : 0.00;
				} else {
	    			TotalCost  += (partFIFOBucketRec.Total__c != null ) ? partFIFOBucketRec.Total__c : 0.00;
	    			QtyInStock += (partFIFOBucketRec.Remaining_Qty__c != null ) ? partFIFOBucketRec.Remaining_Qty__c : 0;
    			}
			}
			//changed by anurag
			//partRec.Oversold_Qty__c = oversoldQty;
			//partRec.Oversold_Cost__c = oversoldCost;
			if(!isForceStopPartQtyChange) {
				PartRec.Qty_In_Stock__c = QtyInStock;
				PartRec.Last_Counted__c = system.Now();
			}
			partRec.Oversold_Qty__c = oversoldQty < 0 ? -(oversoldQty) : oversoldQty;
			partRec.Oversold_Cost__c = oversoldCost < 0 ? -(oversoldCost) : oversoldCost;
			partRec.Total_Cost__c = TotalCost;
			
	        partRec.Average_Cost__c = (QtyInStock > 0) ? (TotalCost / QtyInStock) : 0.00;
			partRec.Has_FIFO_Bucket__c = !partRec.Part_FIFO_Buckets__r.isEmpty();
		}
		//END : Modified by Nidhi - Ticket #1280 - 11-11-2016
		update partList;
	}
	
	
	// Start: Added by Pooja 9 Jan. 2017 (QB Integration)
    public static void populatesAccountingSyncFields(){
        IntegrationSyncFlagService.managePartFIFOBucketSyncFlag( partFIFOBucketNewList);
    }
    
    public static void setPartFIFOBucketDataForAccountSync(){
		IntegrationSyncFlagService.checkAndInitiateSyncBatch(partFIFOBucketNewList, IntegrationUtility.PART_FIFO);
    }
    // End: Added by Pooja 9 Jan. 2017 (QB Integration)

	public static void afterDeleteCalculation() {
		getPartIdListToUpdate(partFIFOBucketOldList);
	}
}
