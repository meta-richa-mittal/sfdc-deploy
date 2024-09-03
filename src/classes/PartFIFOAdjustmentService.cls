global without sharing class PartFIFOAdjustmentService {
	
    public static List<Part_FIFO_Bucket__c> adjustPartQty(Map<Id, PartCountAjustmentWrapper> partIdToCountAjustmentWrapperMap) {
    	if(AccessControl.ifObjectIsAccessible('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
 	 	if(AccessControl.ifObjectIsAccessible('Part__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
   		
		Map<String, Part__c> partIdToRecMap = new Map<String, Part__c>([Select Id, Qty_In_Stock__c from Part__c where Id In: partIdToCountAjustmentWrapperMap.keySet()]);
		DateTime countDateTime;
		
		List<PartCountAjustmentWrapper> partIncreaseCountAjustmentWrapperList = new List<PartCountAjustmentWrapper>();
		Map<Id, PartCountAjustmentWrapper> partIdToDecreaseCountAjustmentWrapperMap = new Map<Id, PartCountAjustmentWrapper>();
		for(PartCountAjustmentWrapper partCountAjustmentWrapperObj : partIdToCountAjustmentWrapperMap.values()) {
			countDateTime = partCountAjustmentWrapperObj.CountDateTime;
			if(partCountAjustmentWrapperObj.Qty > partIdToRecMap.get(partCountAjustmentWrapperObj.Id).Qty_In_Stock__c) {
 	 			partIdToDecreaseCountAjustmentWrapperMap.put(partCountAjustmentWrapperObj.Id, partCountAjustmentWrapperObj);
 	 		} else if(partCountAjustmentWrapperObj.Qty < partIdToRecMap.get(partCountAjustmentWrapperObj.Id).Qty_In_Stock__c){
 	 			partIncreaseCountAjustmentWrapperList.add(partCountAjustmentWrapperObj);
 	 		}
		}
		
 	 	Decimal maxPartAdjustCount = getMaxPartAdjustCount();
 	 	
        //Increased Qty FIFO creation
 	  	Set<String> partIdSet = new Set<String>();
 	  	List<Part_FIFO_Bucket__c> partFIFOBucketForIncreasedQtyList = new List<Part_FIFO_Bucket__c>();
   		for(PartCountAjustmentWrapper partObj : partIncreaseCountAjustmentWrapperList) {
   			maxPartAdjustCount += 1;
   			partIdSet.add(partObj.Id);
   			Decimal qtyToIncrease = partIdToRecMap.get(partObj.Id).Qty_In_Stock__c - partObj.Qty;
   			Part_FIFO_Bucket__c bucketRec = setBucketFields(partObj.Id, qtyToIncrease, partObj.Cost, maxPartAdjustCount, true, 'Stock Count', 'Count Adjustment');
   			if(partObj.CountSessionLineItemId != null) {
   				bucketRec.Count_Session_Line_Item__c = partObj.CountSessionLineItemId;
   				bucketRec.Source_Name__c = 'Part Count';
   				bucketRec.Reference__c = 'Count Adjustment';
   			}
   			partFIFOBucketForIncreasedQtyList.add(bucketRec);
   		}
        
		//Decreased Qty get FIFO buckets
   		Map<Id, List<Part_FIFO_Bucket__c>> partIdToFIFOBucketListMap = new Map<Id, List<Part_FIFO_Bucket__c>>();
   		if(partIdToDecreaseCountAjustmentWrapperMap.size() > 0) {
   			List<Part_FIFO_Bucket__c> partFIFOBucketToUpdateList = SOQLUtil.getPartFIFOBucketByPartList(partIdToDecreaseCountAjustmentWrapperMap.keySet());
   			for(Part_FIFO_Bucket__c partFIFOBucketRec : partFIFOBucketToUpdateList) {
   				if(!partIdToFIFOBucketListMap.containsKey(partFIFOBucketRec.Part__c)) {
   					partIdToFIFOBucketListMap.put(partFIFOBucketRec.Part__c, new List<Part_FIFO_Bucket__c>());
   				}
   				partIdToFIFOBucketListMap.get(partFIFOBucketRec.Part__c).add(partFIFOBucketRec);
   			}
   		}
   		//Decreased Qty FIFO creation
   		Map<Id, Part_FIFO_Bucket__c> partIdToDecreasedFIFOBucketRecMap = new Map<Id, Part_FIFO_Bucket__c>();
   		for(PartCountAjustmentWrapper partObj : partIdToDecreaseCountAjustmentWrapperMap.values()) {
   			if(partIdToFIFOBucketListMap.containsKey(partObj.Id)) {
   				maxPartAdjustCount += 1;
	   			partIdSet.add(partObj.Id);
	   			Part_FIFO_Bucket__c bucketRec = setBucketFields(partObj.Id, 0, 0, maxPartAdjustCount, false, 'Stock Adjust', 'Stock Adjustment');
	   			if(partObj.CountSessionLineItemId != null) {
	   				bucketRec.Count_Session_Line_Item__c = partObj.CountSessionLineItemId;
	   				bucketRec.Source_Name__c = 'Part Count';
	   				bucketRec.Reference__c = 'Count Adjustment';
	   			}
	   			partIdToDecreasedFIFOBucketRecMap.put(partObj.Id, bucketRec);
   			}
   		}
   		
   		List<Part_FIFO_Bucket__c> partFIFOBucketList = new List<Part_FIFO_Bucket__c>(partFIFOBucketForIncreasedQtyList);
   		if(partIdToDecreasedFIFOBucketRecMap.values().size() > 0) {
   			partFIFOBucketList.addAll(partIdToDecreasedFIFOBucketRecMap.values());
   		}
 	  	if(partFIFOBucketList.size() > 0) {
			DMLUtility.insertSobjectList('Part_FIFO_Bucket__c', partFIFOBucketList);
   		}
		
        //Decreased Qty FIFO Bucket LI creation
		List<Part_FIFO_Bucket_Activity_Line_Item__c> fifoActivityLIList = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
		for(PartCountAjustmentWrapper partObj : partIdToDecreaseCountAjustmentWrapperMap.values()) {
   			if(partIdToFIFOBucketListMap.containsKey(partObj.Id)) {
   				if(partIdToDecreasedFIFOBucketRecMap.containsKey(partObj.Id)) {
   					Decimal qtyToDecrease = partObj.Qty - partIdToRecMap.get(partObj.Id).Qty_In_Stock__c;
	   				List<Part_FIFO_Bucket_Activity_Line_Item__c> bucketActivityLIList = decreaseAdjustInStock(partObj.Id, qtyToDecrease, partIdToDecreasedFIFOBucketRecMap.get(partObj.Id).Id, partIdToFIFOBucketListMap.get(partObj.Id));
   					for(Part_FIFO_Bucket_Activity_Line_Item__c bucketActivityLIRec : bucketActivityLIList) {
   						bucketActivityLIRec.Count_Session_Line_Item__c = partObj.CountSessionLineItemId;
   					}
   					if(bucketActivityLIList.size() > 0) {
   						fifoActivityLIList.addAll(bucketActivityLIList);
			 	  	}
   				}
   			}
   		}
		
		if(fifoActivityLIList.size() > 0) {
			DMLUtility.insertSobjectList('Part_FIFO_Bucket_Activity_Line_Item__c', fifoActivityLIList);
 	  	}
 	  	//To prevent trigger from rerun
 	  	PartTriggerHelper.isPreventOnDataLoad = true;
   		FIFOTransaction.updatePartInStock(new List<String>(partIdSet), countDateTime);
   		return partFIFOBucketList;
    }
    
    public static Part_FIFO_Bucket__c setBucketFields(String partId, Decimal qtyIn, Decimal cost, Decimal adjustmentNumber, Boolean isBucket, String sourceName, String reference) {
 	  	Part_FIFO_Bucket__c partBucketRec = new Part_FIFO_Bucket__c();
 	  	partBucketRec.Source_Name__c = sourceName;			
 	  	partBucketRec.Part_Adjust_Number__c = adjustmentNumber;
 	  	partBucketRec.Reference__c = reference;
 	  	partBucketRec.Qty_In__c = qtyIn;
 	  	partBucketRec.Cost__c = cost;
		partBucketRec.VRCost__c = cost;
 	  	partBucketRec.Part__c = partId;
 	  	partBucketRec.Is_FIFO_Bucket__c = isBucket;
 	  	return partBucketRec;
   	}
   
   	public static Decimal getMaxPartAdjustCount() {
   		Decimal maxPartAdjustCount = 0;
 		List<Part_FIFO_Bucket__c> existingPartBucketList = [select Part_Adjust_Number__c from Part_FIFO_Bucket__c order by Part_Adjust_Number__c DESC NULLS LAST limit 1];
 	  	if(existingPartBucketList.size() > 0) {
 	  		maxPartAdjustCount = (existingPartBucketList[0].Part_Adjust_Number__c != null) ? existingPartBucketList[0].Part_Adjust_Number__c : 0;
 	  	}
 	  	return maxPartAdjustCount;
   	}
   	
   	public static List<Part_FIFO_Bucket_Activity_Line_Item__c> decreaseAdjustInStock(String partId, Decimal qty, Id fifoBucketId, List<Part_FIFO_Bucket__c> partFIFORecList) {
   		List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList =  new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
   		
   		for(Part_FIFO_Bucket__c partBucketRec : partFIFORecList) {
 	  		if(qty > 0) {
	 	  		Part_FIFO_Bucket_Activity_Line_Item__c partActivityLineItemRec = new Part_FIFO_Bucket_Activity_Line_Item__c();
	 	  		partActivityLineItemRec.Part__c = partId;
	 	  		partActivityLineItemRec.Part_Adjustment__c = fifoBucketId;
	 	  		partActivityLineItemRec.Part_FIFO_Bucket__c = partBucketRec.Id;
	 	  		partActivityLineItemRec.Reference__c = 'Count Adjustment';
 	  			if((qty - partBucketRec.Remaining_Qty__c) > 0) {
 	  				partActivityLineItemRec.Qty_Out__c = partBucketRec.Remaining_Qty__c;
 	  			} else {
 	  				partActivityLineItemRec.Qty_Out__c = qty;
 	  			}
 	  			qty -= partActivityLineItemRec.Qty_Out__c;
 	  			partFIFOBucketLineItemList.add(partActivityLineItemRec);
 	  		} 
 	  	}
 	  	return partFIFOBucketLineItemList;
   	}
   	
   	public class PartCountAjustmentWrapper {
   		public String Id;
   		public Decimal Qty;
   		public Decimal Cost;
   		public String CountSessionLineItemId;
   		public DateTime CountDateTime;
   		
   		public PartCountAjustmentWrapper(String partId, Decimal qtyIn, Decimal cost) {
   			this.Id = partId;
   			this.Qty = qtyIn;
   			this.Cost = cost;
   		}
   		
   		public PartCountAjustmentWrapper(String partId, Decimal qtyIn, Decimal cost, String CountSessionLineItemId, DateTime countDateTime) {
   			this.Id = partId;
   			this.Qty = qtyIn;
   			this.Cost = cost;
   			this.CountSessionLineItemId = CountSessionLineItemId;
   			this.CountDateTime = countDateTime;
   		}
   	}
}