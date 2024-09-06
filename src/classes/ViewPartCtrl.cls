/**
 * Author: Tarun Khandelwal
 * Since: June 17, 2015
 * Name: ViewPartCtrl
 * Description: Controller Class of Part Detail Page.
**/
global without sharing class ViewPartCtrl {
	
	
	global ViewPartCtrl (NewHomePageCtrl controller){}
    public ViewPartCtrl() {}
	
	/**
     * Name: getPartInfo
     * Desc: To get Part Inforamtion used in View Part Page
     * @param: (1) partId - String - Id of Part
     * @return: String - JSON string of Part Info. 
    **/
   	@RemoteAction
    global static String getPartInfo(String partId) {
    	try{
    		partId = BPUtility.getDecodedString(partId);
	    	boolean previewMode =  false;
	        List<Part__c> parts = SOQLUtil.getPartDetailRecordsByFieldName('Id', partId);
	        
	        Map<String, String> fieldNameToFieldValueMap = new  Map<String, String>();
	        fieldNameToFieldValueMap.put('Part__c', partId);
	        
	        List<Part_FIFO_Bucket__c> partFIFOBucketList = SOQLUtil.getPartFIFOBucketByPartID(fieldNameToFieldValueMap, previewMode);
	        List<Part_FIFO_Bucket__c> partFIFOBucketTotalPartList = SOQLUtil.getPartFIFOBucketByPartID(fieldNameToFieldValueMap, true);
	        String JSONString = '{}';
	        if(parts.size() > 0) {
	           JSONString = System.JSON.serialize(new PartDetailWrapper(parts[0], getStatisticsCalculation(partId), partFIFOBucketList, partFIFOBucketTotalPartList.size()));
	        }
	        return BPUtility.getEncodedString(JSONString);  
    	}catch(exception ex){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
    	} 
    }  
 
 	/**
     * Name: getStatisticsCalculation
     * Desc:  
     * @param: (1) partId - String - Id of Part
     * @return: List<String> 
    **/
 	public static List<String> getStatisticsCalculation(String partId) {
 		List<String> calculatedValuesList = new List<String>();
 		try{
	 		partId = BPUtility.escapeSingleQuotes(partId);
	 		
	 		String query = 'SELECT Id, Non_Inventory_Part__c, Last_Sold__c, Last_Edited_By__r.Name, Last_Edited__c, Last_Price_Update__c, Last_Counted__c, ' +
	 						  '(SELECT Qty__c, Qty_Committed__c, Price__c FROM CO_Line_Items__r WHERE Closed_CO_Invoice_link__c != null), ' +
							  '(SELECT Qty_Needed__c, Received__c, Is_required_For_Customer__c, Is_Service__c  FROM Vendor_Order_Line_Items__r Where Received__c > 0), ' +
							  '(SELECT CreatedDate FROM Vendor_Order_Line_Item_Groups__r ORDER BY CreatedDate DESC LIMIT 1) ' +
						   'FROM Part__c WHERE Id =: partId ';
	 		
	 		if(AccessControl.ifObjectIsAccessible('Part__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
	 		List<Part__c> partList = Database.query(query);
	 		
			DateTime lastSoldDate, lastOrderDate;
	 		Decimal soldLifeTimeQty = 0; 
	 		Decimal revenueLifetime = 0;
	 		Decimal totalSpecialOrderQtyReceived = 0;
 			Decimal totalQtyReceived = 0;
 			
	 		if(partList.size() > 0) {
	 			lastSoldDate = partList[0].Last_Sold__c;
	 			
	 			// Sold life time and Revenue life time.
	 			for(CO_Line_Item__c coLineItemRec : partList[0].CO_Line_Items__r) {
	 				Decimal QtyUsed = 0;
	 				if(partList[0].Non_Inventory_Part__c) {
	 					QtyUsed = (coLineItemRec.Qty__c != null) ? coLineItemRec.Qty__c : 0;
	 				} else {
	 					QtyUsed = (coLineItemRec.Qty_Committed__c != null) ? coLineItemRec.Qty_Committed__c : 0;
	 				}
	 				soldLifeTimeQty += (QtyUsed != null) ? QtyUsed : 0;
 					revenueLifetime += (coLineItemRec.Price__c != null) ? (QtyUsed * coLineItemRec.Price__c).setScale(2, RoundingMode.HALF_UP) : 0;
	 			}
	 			
	 			// Special Order Received Percentage
	 			for(Vendor_Order_Line_item__c voLineItemRec : partList[0].Vendor_Order_Line_Items__r) {
					totalQtyReceived += (voLineItemRec.Received__c != null) ? voLineItemRec.Received__c : 0;
					if(voLineItemRec.Is_required_For_Customer__c || voLineItemRec.Is_Service__c) {
						totalSpecialOrderQtyReceived += (voLineItemRec.Received__c != null) ? voLineItemRec.Received__c : 0;
					}
	 			}
	 			
	 			// Last Order Date
	 			if(partList[0].Vendor_Order_Line_Item_Groups__r.size() == 1) {
	 				lastOrderDate = partList[0].Vendor_Order_Line_Item_Groups__r[0].CreatedDate;
	 			}
	 		}
	 		
	 		totalQtyReceived = (totalQtyReceived == 0) ? 1 : totalQtyReceived;
	 		Decimal specialOrderReceivedPaercentage = ((totalSpecialOrderQtyReceived  * 100)/ totalQtyReceived).setScale(2, RoundingMode.HALF_UP);
 			
	 		calculatedValuesList.add(String.valueOf(soldLifeTimeQty));
	    	calculatedValuesList.add(String.valueOf(revenueLifetime));
	    	calculatedValuesList.add(String.valueOf(specialOrderReceivedPaercentage));
	    	calculatedValuesList.add(convertIntoLastDuration(lastSoldDate));
	    	calculatedValuesList.add(convertIntoLastDuration(lastOrderDate));
			if(!partList.isEmpty()) {
				calculatedValuesList.add(String.valueOf(convertIntoLastDuration(partList[0].Last_Counted__c)));
				calculatedValuesList.add(String.valueOf(convertIntoLastDuration(partList[0].Last_Price_Update__c)));
				calculatedValuesList.add(String.valueOf(convertIntoLastDuration(partList[0].Last_Edited__c)));
				calculatedValuesList.add(partList[0].Last_Edited_By__c != null ? partList[0].Last_Edited_By__r.Name : '');
			}
	    	
	    	return calculatedValuesList;
 		}catch(exception ex){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
    	}
 	}  
 	
    private static String convertIntoLastDuration(DateTime dateTimeToChange) {
 		String lastDurationTime = '';
 		if(dateTimeToChange != null) {
			Long dateValue = dateTimeToChange.getTime();
			Long currentDateValue = system.now().getTime();
			lastDurationTime = String.valueOf(Integer.valueOf(((currentDateValue - dateValue)/ (1000 * 60 * 60 * 24)) / 30 )) + 'm ';
			lastDurationTime += String.valueOf(Integer.valueOf( Math.mod(((currentDateValue - dateValue)/ (1000 * 60 * 60 * 24)), 30))) + 'd ';
			lastDurationTime += String.valueOf(Integer.valueOf( Math.mod(((currentDateValue - dateValue)/ (1000 * 60 * 60)), 24))) + 'h ';
		}
		return lastDurationTime;
 	}
    
   	/**
     * Name: increaseAdjustInStock
     * Desc: To get Part Inforamtion used in View Part Page
     * @param: (1) partId - String - Id of Part 
     * @return: String - JSON string of Part Info. 
   	**/
   	@RemoteAction
   	global static String increaseAdjustInStock(String partId, Decimal qtyIn, Decimal cost) {
   		try{
   			partId = BPUtility.getDecodedString(partId);
	   		Part_FIFO_Bucket__c partBucketRec = createAdjustmentBucket(partId, 'Stock Count', 'Count Adjustment', qtyIn, cost, true, null);
	      	return getPartInfo(BPUtility.getEncodedString(partId));
	      	
   		}catch(exception ex){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
    	}
   	}
   	
   	/**
     * Name: increaseAdjustInStock
     * Desc: To get Part Inforamtion used in View Part Page
     * @param: (1) partId - String - Id of Part 
     * @return: String - JSON string of Part Info. 
   	**/
   	@RemoteAction
   	global static String decreaseAdjustInStock(String partId, Decimal qty, String FIFOBucketJSONString) {
   			partId = BPUtility.getDecodedString(partId);
   			FIFOBucketJSONString = BPUtility.getDecodedString(FIFOBucketJSONString);
   			
	   		validateDecreasedQty(partId, qty);
	   		
	   		List<PartFifoBucket> partFIFOObjList = (List<PartFifoBucket>)System.JSON.deserialize(FIFOBucketJSONString, List<PartFifoBucket>.class);
	   		validateFIFOData(partFIFOObjList);
			
			List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList =  new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
	   		
			Part_FIFO_Bucket__c partBucketRec = createAdjustmentBucket(partId, 'Stock Adjust', 'Stock Adjustment', 0, 0, false, null);
	 	  	
	   		for(PartFifoBucket partBucketObj : PartFifoObjList) {
	 	  		if(qty > 0) {
		 	  		Part_FIFO_Bucket_Activity_Line_Item__c partActivityLineItemRec = new Part_FIFO_Bucket_Activity_Line_Item__c();
		 	  		partActivityLineItemRec.Part_Adjustment__c = partBucketRec.Id;
		 	  		partActivityLineItemRec.Part_FIFO_Bucket__c = partBucketObj.FIFOBucketId;
		 	  		partActivityLineItemRec.Reference__c = 'Count Adjustment';
	 	  		
	 	  			if((qty - partBucketObj.RemainingQty) > 0) {
	 	  				partActivityLineItemRec.Qty_Out__c = partBucketObj.RemainingQty;
	 	  			} else {
	 	  				partActivityLineItemRec.Qty_Out__c = qty;
	 	  			}
	 	  			qty -= partActivityLineItemRec.Qty_Out__c;
	 	  			partFIFOBucketLineItemList.add(partActivityLineItemRec);
	 	  		} 
	 	  	}
	 	  	
	 	  	if(partFIFOBucketLineItemList.size() > 0) {
	 	  		if(AccessControl.ifObjectIsAccessible('Part_FIFO_Bucket_Activity_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
	 	  		if(AccessControl.ifObjectIsCreateable('Part_FIFO_Bucket_Activity_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
	 	  		insert partFIFOBucketLineItemList;
	 	  	}
	 	  	//FIFOTransaction.updatePartInStock(new List<String>{partId});
	      	return getPartInfo(BPUtility.getEncodedString(partId));
   	}
   	
   	private static void validateDecreasedQty(String partId, Decimal qty) {
		if(!isPartAvailable(partId, qty)) throw new BlackpurlException('The Decreased quantity cannot be more than the available Stock. Please refresh page and try again.');
   		return;
   	}

	public static Boolean isPartAvailable(String partId, Decimal qty) {
		List<Part__c> partList = [Select Id from Part__c where Id =: partId AND AvailableParts__c >=: qty LIMIT 1];
		if(partList.size() == 0) return false;
		return true;
	}

	public static Decimal getMaxPartAdjCount() {
		Decimal maxPartAdjustCount = 0;
		if(AccessControl.ifObjectIsAccessible('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
		List<Part_FIFO_Bucket__c> existingPartBucketList = [select Part_Adjust_Number__c from Part_FIFO_Bucket__c order by Part_Adjust_Number__c DESC  NULLS LAST limit 1];
		if(existingPartBucketList.size() > 0) {
			maxPartAdjustCount = (existingPartBucketList[0].Part_Adjust_Number__c != null) ? existingPartBucketList[0].Part_Adjust_Number__c : 0;
		}
		return maxPartAdjustCount;
	}

	global static Part_FIFO_Bucket__c createAdjustmentBucket(String partId, String sourceName, String ref, Decimal qtyIn, Decimal cost, Boolean isFIFO, String secReference) {
		Decimal maxPartAdjustCount = getMaxPartAdjCount();
		Part_FIFO_Bucket__c partBucketRec = new Part_FIFO_Bucket__c();
		partBucketRec.Source_Name__c = sourceName;			
		partBucketRec.Part_Adjust_Number__c = maxPartAdjustCount + 1;
		partBucketRec.Reference__c = ref;
		partBucketRec.Qty_In__c = qtyIn;
		partBucketRec.Cost__c = cost;
		partBucketRec.VRCost__c = cost;
		partBucketRec.Part__c = partId;
		partBucketRec.Is_FIFO_Bucket__c = isFIFO;
		partBucketRec.Secondary_Reference__c = secReference;
		if(AccessControl.ifObjectIsCreateable('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
		insert partBucketRec;
		return partBucketRec;
	}

	private static void validateFIFOData(List<PartFifoBucket> partFIFOObjList) {
		Map<Id, PartFifoBucket> fifoBucketIdToObjMap = new Map<Id, PartFifoBucket>();
		for(PartFifoBucket partBucketObj: PartFifoObjList) {
			fifoBucketIdToObjMap.put(partBucketObj.FIFOBucketId, partBucketObj);
		}

		if(fifoBucketIdToObjMap.size() == 0) return;
		Map<Id, Part_FIFO_Bucket__c> fifoBucketMap = new Map<Id, Part_FIFO_Bucket__c>([SELECT Remaining_Qty__c FROM Part_FIFO_Bucket__c WHERE Id IN :fifoBucketIdToObjMap.keySet()]);
		for(Id fifoBucketId: fifoBucketMap.keySet()) {
			if(fifoBucketMap.get(fifoBucketId).Remaining_Qty__c !=  fifoBucketIdToObjMap.get(fifoBucketId).RemainingQty) 
				throw new BlackpurlException('One or more line item in cost detail section are changed during your edit session. Please refresh the page and try again.');
		}
	}
   
   	@RemoteAction
   	global static String modifyCostSummary(String FIFOBucketJSONString, Decimal newCost) {
   		try{
   			FIFOBucketJSONString = BPUtility.getDecodedString(FIFOBucketJSONString);
   			
	 	  	List<PartFifoBucket> PartFifoObjList = (List<PartFifoBucket>)System.JSON.deserialize(FIFOBucketJSONString, List<PartFifoBucket>.class); 	
			validateFIFOData(PartFifoObjList);
			
			List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList =  new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
	 	  	Decimal totalQtyRemaining = 0;
	 	  	String partId;
	 	  	for(PartFifoBucket partBucketObj : PartFifoObjList) {
	 	  		totalQtyRemaining += partBucketObj.RemainingQty;
	 	  		if(partId == null) {
	 	  			partId = partBucketObj.PartId;
	 	  		}
	 	  	}
	 	  	
	 	  	Decimal maxPartAdjustCount = 0;
	 	  	if(AccessControl.ifObjectIsAccessible('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
	 	 	List<Part_FIFO_Bucket__c> existingPartBucketList = [select Part_Adjust_Number__c from Part_FIFO_Bucket__c order by Part_Adjust_Number__c DESC  NULLS LAST limit 1];
	 	  	if(existingPartBucketList.size() > 0) {
	 	  		maxPartAdjustCount = (existingPartBucketList[0].Part_Adjust_Number__c != null) ? existingPartBucketList[0].Part_Adjust_Number__c : 0;
	 	  	}
	 	  	
	 	  	
	 	  	Part_FIFO_Bucket__c partBucketRec = new Part_FIFO_Bucket__c();
	 	  	partBucketRec.Source_Name__c = 'Cost Adjust';			
	 	  	partBucketRec.Part_Adjust_Number__c = maxPartAdjustCount + 1;
	 	  	partBucketRec.Reference__c = 'Cost Adjustment';
	 	  	partBucketRec.Qty_In__c = totalQtyRemaining;
	 	  	partBucketRec.Cost__c = newCost;
			partBucketRec.VRCost__c = newCost;
	 	  	partBucketRec.Part__c = partId;
	 	  	partBucketRec.Is_FIFO_Bucket__c = true;
	 	  	if(AccessControl.ifObjectIsCreateable('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
 	  		insert partBucketRec;
	 	  	for(PartFifoBucket partBucketObj : PartFifoObjList) {
	 	  		Part_FIFO_Bucket_Activity_Line_Item__c partActivityLineItemRec = new Part_FIFO_Bucket_Activity_Line_Item__c();
	 	  		partActivityLineItemRec.Part_Adjustment__c = partBucketRec.Id;
	 	  		partActivityLineItemRec.Part_FIFO_Bucket__c = partBucketObj.FIFOBucketId;
	 	  		partActivityLineItemRec.Reference__c = 'Cost Adjustment';
	 	  		partActivityLineItemRec.Qty_Out__c = partBucketObj.RemainingQty;
	 	  		partBucketObj.PartFIFOActivityLineItemList.add(new PartFifoBucket.PartFIFOActivityLineItem(partActivityLineItemRec));
	 	  		partFIFOBucketLineItemList.add(partActivityLineItemRec);
	 	  	}
	 	  	
	 	  	//PartFifoObjList.add(new PartFifoBucket(partBucketRec));
	 	  	if(partFIFOBucketLineItemList.size() > 0) {
	 	  			if(AccessControl.ifObjectIsAccessible('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
	 	  			if(AccessControl.ifObjectIsCreateable('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
	 	  			
	 	  			if(AccessControl.ifObjectIsCreateable('Part_FIFO_Bucket_Activity_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
	 	  		insert partFIFOBucketLineItemList;
	 	  	}
	 	  	FIFOTransaction.updatePartInStock(new List<String>{partId});
	      	return getPartInfo(BPUtility.getEncodedString(partId));
   		}catch(exception ex){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
    	}	
   	}
   	
   	@RemoteAction
	global static String saveAdjustedCostDetails(String costDetailsJson,Decimal newCost,Boolean isAdjustedRemaining) {
		try{
			costDetailsJson = BPUtility.getDecodedString(costDetailsJson);
			
	 	  	PartFifoBucket PartFifoBucketobj = (PartFifoBucket)System.JSON.deserialize(costDetailsJson,PartFifoBucket.class);
			validateFIFOData(new List<PartFifoBucket>{PartFifoBucketobj});
			
			List<PartFifoBucket> PartFifoObjList = new List<PartFifoBucket>(); 
			List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList =  new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
			List<Coli_Fifo_Line_Item_Junction__c> ColiFifoItemListToUpdate = new List<Coli_Fifo_Line_Item_Junction__c>();
			map<Id,Decimal> FIFOIdToCostMap = new map<Id,Decimal>();
	 	  	FIFOTransaction fifoTransactionObject = new FIFOTransaction();
			String partId;
			partId = PartFifoBucketobj.PartId;
	 	  	Decimal totalQtyRemaining = 0;
	 	 	Decimal maxPartAdjustCount = 0;
	 	 	if(AccessControl.ifObjectIsAccessible('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
	 	 	List<Part_FIFO_Bucket__c> existingPartBucketList = [select Part_Adjust_Number__c from Part_FIFO_Bucket__c order by Part_Adjust_Number__c DESC  NULLS LAST limit 1];
	 	  	if(existingPartBucketList.size() > 0) {
	 	  		maxPartAdjustCount = (existingPartBucketList[0].Part_Adjust_Number__c != null) ? existingPartBucketList[0].Part_Adjust_Number__c : 0;
	 	  	}
	 	  	
	 	  	Part_FIFO_Bucket__c partBucketRec = new Part_FIFO_Bucket__c();
	 	  	partBucketRec.Source_Name__c = 'Cost Adjust';			
	 	  	partBucketRec.Reference__c =  'Re:' + PartFifoBucketobj.UniqueId;
	 	  	partBucketRec.Part__c = partId;
	 	  	partBucketRec.Part_Adjust_Number__c = maxPartAdjustCount + 1;
	 	  	if(isAdjustedRemaining){
	 	  		partBucketRec.Qty_In__c = PartFifoBucketobj.RemainingQty;
	 	  	}
	 	  	else{
	 	  		partBucketRec.Qty_In__c = PartFifoBucketobj.QtyIn;partBucketRec.VRCost__c = newCost;
	 	  	}
	 	  	partBucketRec.Cost__c = newCost;
			partBucketRec.VRCost__c = newCost;
	 	  	partBucketRec.Is_FIFO_Bucket__c = true;
	 	  	if(AccessControl.ifObjectIsCreateable('Part_FIFO_Bucket__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
	 	  	insert partBucketRec;
	 	  	if(!isAdjustedRemaining){
	 	  		
	 	  		if(PartFifoBucketobj.SourceName == 'Cost Adjust'){
	 	  			// Getting  last cost adjusted bucket 
		 	  			List<Coli_Fifo_Line_Item_Junction__c>	colIFifoLineItemForCostAdjustList = [select Part_FIFO_Bucket_Activity_Line_Item__r.Part_FIFO_Bucket__c,Part_FIFO_Bucket_Activity_Line_Item__c from Coli_Fifo_Line_Item_Junction__c where Part_FIFO_Bucket__c =: PartFifoBucketobj.FIFOBucketId ];
		 	  			set<Id>	fifobucketAdjustSet= new Set<Id>();
		 	  			
		 	  			for(Coli_Fifo_Line_Item_Junction__c colififoitem : colIFifoLineItemForCostAdjustList){
		 	  				if(colififoitem.Part_FIFO_Bucket_Activity_Line_Item__c !=null){
		 	  					fifobucketAdjustSet.add(colififoitem.Part_FIFO_Bucket_Activity_Line_Item__r.Part_FIFO_Bucket__c);
		 	  				}
		 	  				
		 	  			}
		 	  			
		 	  			List<Part_FIFO_Bucket_Activity_Line_Item__c> FifoActivityBucketListFromJunction =  [select Id from Part_FIFO_Bucket_Activity_Line_Item__c where Part_FIFO_Bucket__c IN : fifobucketAdjustSet ];
			 	  		
			 	  		for(Part_FIFO_Bucket_Activity_Line_Item__c FifoActivityBucketItem : FifoActivityBucketListFromJunction)	{
			 	  			FIFOIdToCostMap.put(FifoActivityBucketItem.Id ,newCost);
			 	  		}
	 	  			}	
		 	  	
		 	  		List<Part_FIFO_Bucket_Activity_Line_Item__c> FifoActivityBucketList =  [select Id from Part_FIFO_Bucket_Activity_Line_Item__c where Part_FIFO_Bucket__c =: PartFifoBucketobj.FIFOBucketId ];
		 	  		for(Part_FIFO_Bucket_Activity_Line_Item__c FifoActivityBucketItem : FifoActivityBucketList)	{
		 	  			FIFOIdToCostMap.put(FifoActivityBucketItem.Id ,newCost);
		 	  		}
		 	  		
		 	  		ColiFifoItemListToUpdate = FIFOTransaction.updateInvoiceParts(FIFOIdToCostMap);
			 	  	 for(Coli_Fifo_Line_Item_Junction__c colififItem :  ColiFifoItemListToUpdate){
				 	  			colififItem.Part_FIFO_Bucket__c = partBucketRec.Id;
				 	 }	
	 	  		
	 	  		Part_FIFO_Bucket_Activity_Line_Item__c partpresoldActivityLineItemRec = new Part_FIFO_Bucket_Activity_Line_Item__c();
		 	  	partpresoldActivityLineItemRec.Part_Adjustment__c = partBucketRec.Id;
		 	  	partpresoldActivityLineItemRec.Part_FIFO_Bucket__c = partBucketRec.Id;
		 	  	partpresoldActivityLineItemRec.Reference__c = 'Presold on ' + PartFifoBucketobj.UniqueId;
		 	  	partpresoldActivityLineItemRec.Qty_Out__c = PartFifoBucketobj.QtyOut;
		 	  	partpresoldActivityLineItemRec.Cost__c = newCost;
		 	  	PartFifoBucketobj.PartFIFOActivityLineItemList.add(new PartFifoBucket.PartFIFOActivityLineItem(partpresoldActivityLineItemRec));
		 	  	partFIFOBucketLineItemList.add(partpresoldActivityLineItemRec);
		 	  	PartFifoObjList.add(new PartFifoBucket(partBucketRec));
	 	  	}  	
	 	  	Part_FIFO_Bucket_Activity_Line_Item__c partActivityLineItemRec = new Part_FIFO_Bucket_Activity_Line_Item__c();
		 	partActivityLineItemRec.Part_Adjustment__c = partBucketRec.Id;
		 	partActivityLineItemRec.Part_FIFO_Bucket__c = PartFifoBucketobj.FIFOBucketId;
		 	partActivityLineItemRec.Reference__c = 'Cost Adjustment';
		 	partActivityLineItemRec.Qty_Out__c = PartFifoBucketobj.RemainingQty;
			partActivityLineItemRec.Unique_Id__c = (isAdjustedRemaining ? '' : 'Presold'); // To identify FIFO line item for presold while sending accounting entries
	 	  	PartFifoBucketobj.PartFIFOActivityLineItemList.add(new PartFifoBucket.PartFIFOActivityLineItem(partActivityLineItemRec));
	 	  	partFIFOBucketLineItemList.add(partActivityLineItemRec);
	 	  	PartFifoObjList.add(new PartFifoBucket(partBucketRec));
	 	  	if(partFIFOBucketLineItemList.size()>0)
	 	  	{
	 	  		if(AccessControl.ifObjectIsAccessible('Part_FIFO_Bucket_Activity_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
	 	  		if(AccessControl.ifObjectIsCreateable('Part_FIFO_Bucket_Activity_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
	 	  		insert partFIFOBucketLineItemList;
	 	  	}
	 	  	
	 	  	if(ColiFifoItemListToUpdate.size() > 0){
	 	  		update ColiFifoItemListToUpdate;
	 	  	}
	 	  	set<String> coliFifoSet = new set<String>();
	 	  	for(Coli_Fifo_Line_Item_Junction__c   ColififoRec : ColiFifoItemListToUpdate){
	 	  		
				coliFifoSet.add(ColififoRec.Id);
			}
			if( coliFifoSet.size() > 0 && !Test.isRunningTest()){
				system.debug('!!!!!!!!1' + coliFifoSet);
				FIFOTransaction.ajdustPartCost(coliFifoSet);
			}
	 	  	FIFOTransaction.updatePartInStock(new List<String>{partId});
	 	  	
	  		return getPartInfo(BPUtility.getEncodedString(partId));
		}catch(exception ex){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
    	}	
   	}
	  
	  
	@RemoteAction
	global static String resolveOversoldInStock(String FIFOBucketJSONString) {
		try{				
	 	  	List<PartFifoBucket> PartFifoObjList = (List<PartFifoBucket>)System.JSON.deserialize(BPUtility.getDecodedString(FIFOBucketJSONString), List<PartFifoBucket>.class); 	
	 	  	
			Set<String> partIdSet = new Set<String>();
	 	  	if(PartFifoObjList.size() > 0) partIdSet.add(PartFifoObjList[0].PartId);
	 	  	else throw new BlackPurlException('Error occured while resolving oversold.');
			
			Set<String> partFifoIdSet = new Set<String>();
	 	  	for(PartFifoBucket partFifoBucketRec: PartFifoObjList){
				partFifoIdSet.add(partFifoBucketRec.FIFOBucketId);
			}
			List<Part_FIFO_Bucket__c> currentFifoBucketList = [Select Id, Remaining_Qty__c from Part_FIFO_Bucket__c where Id IN:partFifoIdSet];
			for(Part_FIFO_Bucket__c partFifoBucketRec: currentFifoBucketList){
				if(partFifoBucketRec.Remaining_Qty__c == 0){ throw new BlackPurlException('Some Changes are made by another process. Please Refresh the page.'); }
			}

	 	  	Decimal maxPartAdjustCount = PartFIFOAdjustmentService.getMaxPartAdjustCount();
			List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketLineItemList = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
	 	  	
			VendorOrderReceivingService.createCountAdjustment(partIdSet, PartFifoObjList, maxPartAdjustCount, partFIFOBucketLineItemList);
			DMLUtility.insertSobjectList('Part_FIFO_Bucket_Activity_Line_Item__c', partFIFOBucketLineItemList);

	      	return getPartInfo(BPUtility.getEncodedString(PartFifoObjList[0].PartId));
		}catch(exception ex){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
    	}
   	}
   
   @RemoteAction   
	global static String getHistoryRecords(String PartId, boolean previewMode ) {
		try{
			PartId = BPUtility.getDecodedString(PartId);
			
			Map<String, String> fieldNameToFieldValueMap = new  Map<String, String>();
	        fieldNameToFieldValueMap.put('Part__c', partId);
	        List<Part_FIFO_Bucket__c> partFIFOBucketRecList = SOQLUtil.getPartFIFOBucketByPartID(fieldNameToFieldValueMap, previewMode);
	        
	        
	        List<PartFifoBucket> partFIFOBucketList = new List<PartFifoBucket>();
	        for(Part_FIFO_Bucket__c partFIFOBucketRec : partFIFOBucketRecList) {
	            partFIFOBucketList.add(new PartFifoBucket(partFIFOBucketRec));
	        }
	        return BPUtility.getEncodedString(System.JSON.serialize(partFIFOBucketList));  
		}catch(exception ex){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
    	}  
	}
	
	@RemoteAction 
    global static String getPartsLocator(String partId, Integer quantity, String searchType) {
    	try {
    		partId = BPUtility.getDecodedString(partId);
    		searchType = BPUtility.getDecodedString(searchType);
            return BPUtility.getEncodedString(BRPAPIManager.getPartLocator(partId, quantity, searchType));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: calculatePartRetailPriceOnUpsert
     * Desc: calculate retail price of part record of a vendor
     * @param: 
     * @return: 
    **/
    public static void calculatePartRetailPriceOnUpsert(Part__c partRecToUpsert, Account vendorRec) {
		Escalator__c vendorRetailEscalatorRec = vendorRec.Escalators__r != null && vendorRec.Escalators__r.size() > 0 ? vendorRec.Escalators__r[0] : null;
    	calculatePartRetailPriceOnUpsert(partRecToUpsert, vendorRec, vendorRetailEscalatorRec);
    }

	public static void calculatePartRetailPriceOnUpsert(Part__c partRecToUpsert, Account vendorRec, Escalator__c vendorRetailEscalatorRec) {
    	Decimal BaseValue;
		Decimal taxRate = 0;
    	if(vendorRec.Retail_Base_Value__c == 'Item Cost')	{
    		BaseValue = (partRecToUpsert.Last_Cost__c != null) ? partRecToUpsert.Last_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0.00;//Item Cost
			if(GeneralConfiguration.getTaxIncludingPricing() && partRecToUpsert.Applicable_Tax__c != null) taxRate = partRecToUpsert.Applicable_Tax__r.Rate__c;
    	} else {
    		BaseValue = (partRecToUpsert.MSRP__c != null) ? partRecToUpsert.MSRP__c.setScale(2, RoundingMode.HALF_UP) : 0.00;//MSRP
    	}
    	
		Decimal markupValue = EscalatorService.getMarkupValue(BaseValue, vendorRetailEscalatorRec);
    	Decimal calculatedRetailPrice = BaseValue + (BaseValue * (markupValue/100));
    	calculatedRetailPrice = (calculatedRetailPrice * (1 + taxRate/100)).setScale(2, RoundingMode.HALF_UP);
    	calculatedRetailPrice = calculatedRetailPrice.setScale(2, RoundingMode.HALF_UP);
    	if(vendorRec.Retail_Rounding__c)	{
    		calculatedRetailPrice = applyRoundingToCalculatedRetailPrice(vendorRec.Retail_Round_To__c, calculatedRetailPrice);
    	}
    	system.debug('calculatedRetailPrice==' + calculatedRetailPrice);
    	partRecToUpsert.Retail_Price__c = calculatedRetailPrice;
    }
    
    /**
     * Name: calculatePartsRetailPrice
     * Desc: calculate retail price of part record of a vendor
     * @param: 
     * @return: 
    **/
	public static void calculatePartRetailPrice(Part__c partRecToUpdate, Escalator__c escalatorRec) {
        if(partRecToUpdate.Vendor__r.Is_Calculate_Part_Retail_Price__c) {
    		calculatePartRetailPriceOnUpsert(partRecToUpdate, partRecToUpdate.Vendor__r, escalatorRec);
    	} else {
    		partRecToUpdate.Retail_Price__c = partRecToUpdate.MSRP__c;
    	}
    }
    
    public static Decimal applyRoundingToCalculatedRetailPrice(Decimal RetailRoundingCentValue, Decimal RetailPriceValue) {
    	Decimal RoundingValue = RetailRoundingCentValue/100;
    	Integer RetailPriceIntegerValue = Integer.valueOf(Math.floor(RetailPriceValue)); 
    	system.debug('RetailRoundingCentValue==' + RetailRoundingCentValue + 'RetailPriceValue ==' + RetailPriceValue + 'RoundingValue==' +RoundingValue + 'RetailPriceIntegerValue==' + RetailPriceIntegerValue + 'diff==' + (RetailPriceValue - Decimal.valueOf(RetailPriceIntegerValue)));
    	if((RetailPriceValue - Decimal.valueOf(RetailPriceIntegerValue)) > RoundingValue)	{
    		RetailPriceIntegerValue = RetailPriceIntegerValue + 1;
    	}
	    Decimal roundedRetailPriceValue = Decimal.valueOf(RetailPriceIntegerValue) + RoundingValue;
	    system.debug('RetailPriceIntegerValue==' + RetailPriceIntegerValue + 'roundedRetailPriceValue==' + roundedRetailPriceValue);
    	return roundedRetailPriceValue;
	}

	@RemoteAction
    global static String getCassonsInventoryByCassonsId(String partId) {
    	try {
            return BPUtility.getEncodedString(CassonsService.getCassonsInventoryByPartId(BPUtility.getDecodedString(partId)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getProductVariants(String partId) {
		return BPUtility.getEncodedString(System.JSON.serialize(
		      WebsiteProductManagementService.getProductVariantsByPartId(BPUtility.getDecodedString(partId)), true));
    }
}