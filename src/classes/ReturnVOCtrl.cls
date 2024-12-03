/** 
 * Author: Hitesh Gupta
 * Since: Sep 12, 2017
 * Name: ReturnVOCtrl 
 * Description: Apex class to handle all operations related to Return Vendor Order Page.
**/
global without sharing class ReturnVOCtrl {
  
    global ReturnVOCtrl(NewHomePageCtrl controller){}
    public ReturnVOCtrl() {} 
    
    
    @RemoteAction
    global static String addVendor(String vendorId, String returnVOId){
    	try{
    		vendorId = BPUtility.getDecodedString(vendorId);
    		returnVOId = BPUtility.getDecodedString(returnVOId);
    		
	    	Return_VO_Header__c returnVORec = new Return_VO_Header__c();
	    	if(!String.isBlank(returnVOId)) {
	    		returnVORec.Id = returnVOId;
	    	}
	    	returnVORec.Returned_Date__c = system.today();
	    	returnVORec.Vendor__c = vendorId;
	    	returnVORec.Status__c = 'In Progress';
	    	
	    	try{
				DMLUtility.upsertSobjectList('Return_VO_Header__c', returnVORec);
	    	} catch(Exception e){
	    		system.assert(false, e.getmessage());
	    		return BPUtility.getEncodedString(null);
	    	}
	    	if(String.isBlank(returnVOId)) {
	    		return BPUtility.getEncodedString(returnVORec.Id);
	    	} else {
	    	return getReturnVODetail(BPUtility.getEncodedString(returnVOId));
	    	}
    	}catch(Exception e){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    
    @RemoteAction
    global static String getReturnVODetail(String returnVOId){
    	returnVOId = BPUtility.getDecodedString(returnVOId);
    	
    	List<Return_VO_Header__c> returnVOList = SOQLUtil.getReturnVOHeaderDetail(new Map<String, String>{'Id' => returnVOId  }); 
    	ReturnVOHeaderWrapper returnVOHeaderRec;
    	if(returnVOList.size() > 0){
    		returnVOHeaderRec = new ReturnVOHeaderWrapper(returnVOList[0]);
    	}
        return BPUtility.getEncodedString(System.JSON.serialize(returnVOHeaderRec));
    	
    }
    
    @RemoteAction
    global static String saveRVOLI(String returnVOId, String returnVOLIJson){
    	
    	returnVOId = BPUtility.getDecodedString(returnVOId);
    	returnVOLIJson = BPUtility.getDecodedString(returnVOLIJson);
    	List<ReturnVOHeaderWrapper.ReturnVoLineItemWrapper>  returnVoliWrapperRecList = (List<ReturnVOHeaderWrapper.ReturnVoLineItemWrapper>)System.JSON.deserialize(returnVOLIJson, List<ReturnVOHeaderWrapper.ReturnVoLineItemWrapper>.class);
    	
    	Set<String> partIdSet = new Set<String>();
    	for(ReturnVOHeaderWrapper.ReturnVoLineItemWrapper  returnVoliRec : returnVoliWrapperRecList){
    		partIdSet.add(returnVoliRec.PartId);
    	}
    	
    	if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	Map<Id,Part__c> partIdToRecMap = new Map<Id,Part__c>([Select Id, Calculated_Cost__c from Part__c where Id IN: partIdSet]);
    	
    	List<Return_VO_Line_Item__c> returnVoliToUpsert = new List<Return_VO_Line_Item__c>();
    	
    	for(ReturnVOHeaderWrapper.ReturnVoLineItemWrapper  returnVoliRec : returnVoliWrapperRecList){
    		
    		Return_VO_Line_Item__c returnVOLIObj = new Return_VO_Line_Item__c();
    		
    		if(returnVoliRec.Id != null){
    			returnVOLIObj.Id = returnVoliRec.Id;
    			returnVOLIObj.Item_Cost__c =  returnVoliRec.ItemCost;
    		}else{
    			returnVOLIObj.Item_Cost__c =  partIdToRecMap.containsKey(returnVoliRec.PartId) ? partIdToRecMap.get(returnVoliRec.PartId).Calculated_Cost__c : 0;
    		}
    		
    		returnVOLIObj.Item__c = returnVoliRec.Item;
    		returnVOLIObj.Description__c = returnVoliRec.Description;
    		returnVOLIObj.Return_Qty__c = returnVoliRec.ReturnQty;
    		
    		returnVOLIObj.Inventory_Cost__c = returnVoliRec.InventoryCost;
    		returnVOLIObj.Return_VO_Header__c = returnVOId;
    		returnVOLIObj.Part__c = returnVoliRec.PartId;
    		
    		returnVoliToUpsert.add(returnVOLIObj);
    	}
    	
    	if(returnVoliToUpsert.size() > 0){
    		if(AccessControl.ifObjectFieldIsCreateable('Return_VO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
			if(AccessControl.ifObjectFieldIsUpdateable('Return_VO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
    		upsert returnVoliToUpsert;
    	}
    	
    	return getReturnVODetail(BPUtility.getEncodedString(returnVOId));
    	
    
    	
    }
    
    @RemoteAction
    global static String saveRVOH(String returnVOHJson){
    	returnVOHJson = BPUtility.getDecodedString(returnVOHJson);
    	
		Map<String, Object> rvoJsonMap = (Map<String, Object>)JSON.deserializeUntyped(returnVOHJson);
		String vendorId = rvoJsonMap.get('VendorId') != null ? (String)rvoJsonMap.get('VendorId') : null;
		String rvoId = rvoJsonMap.get('Id') != null ? (String)rvoJsonMap.get('Id') : null;
		if(rvoJsonMap.containsKey('RMANumber')) {
			String newRMANumber = rvoJsonMap.get('RMANumber') != null ? (String)rvoJsonMap.get('RMANumber') : null;
			List<Return_VO_Header__c> rvoRecList = [Select RMA__c from Return_VO_Header__c where Id = :rvoId];
			if(rvoRecList.size() > 0) {
				if(String.isNotBlank(newRMANumber) && rvoRecList[0].RMA__c != newRMANumber) {
					List<Return_VO_Header__c> rvoList = [Select RMA__c from Return_VO_Header__c where (Id != :rvoId AND 
															Vendor__c =: vendorId AND RMA__c =: newRMANumber) Limit 1];
					if(rvoList.size() > 0) {
						throw new BlackpurlException('This RMA number already exists. Please use a different number.');
					}
				}
			}
		}

    	Return_VO_Header__c returnVOHObjToUpdate = new Return_VO_Header__c(Id = rvoId);
		for(String objKey: ReturnVOService.rvoWrapperKeyToAPINameMap.keySet()) {
			if(rvoJsonMap.containsKey(objKey)) {
				String value = rvoJsonMap.get(objKey) != null ? (String)rvoJsonMap.get(objKey) : null;
				if(objKey == 'ReturnedDate' && rvoJsonMap.get(objKey) != null) {
					returnVOHObjToUpdate.put(ReturnVOService.rvoWrapperKeyToAPINameMap.get(objKey), DateTimeUtility.parseDate(value));
				} else {
					returnVOHObjToUpdate.put(ReturnVOService.rvoWrapperKeyToAPINameMap.get(objKey), value);
				}
			}
		}
    	DMLUtility.updateSobjectList('Return_VO_Header__c', returnVOHObjToUpdate);
    	
    	return getReturnVODetail(BPUtility.getEncodedString(returnVOHObjToUpdate.Id));
    }
    
    @RemoteAction
    global static String deleteRVOLI(String returnVOId, String returnVOLIId){
    	returnVOLIId = BPUtility.getDecodedString(returnVOLIId);
    	returnVOId = BPUtility.getDecodedString(returnVOId);
    	Return_VO_Line_Item__c returnVOLITodelete = new Return_VO_Line_Item__c();
    	returnVOLITodelete.Id = returnVOLIId;
    	if(AccessControl.ifObjectIsDeletable('Return_VO_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
    	delete returnVOLITodelete;
    	
    	return getReturnVODetail(BPUtility.getEncodedString(returnVOId));
    }
    
    @RemoteAction
    global static String validateUniqueCreditMemoForQB(String entityValue) { // No more used
    	// entityValue = BPUtility.getDecodedString(entityValue);
    	// entityValue = '\'' + entityValue + '\'';
    	// String response = QuickBookQueryService.validateUniqueEntityValue('VendorCredit', 'DocNumber', entityValue, '=');
        // if(QuickBookQueryService.refreshToken !=  null) {
		// 	QBUtil.saveRefreshToken(QuickBookQueryService.refreshToken, QuickBookQueryService.refreshTokenExpiresIn);
		// }
    	// return  BPUtility.getEncodedString(response);
		return 'Success';
    }
    
	@RemoteAction // moved to ReturnVendorCreditCtrl
    global static String validateUniqueCreditMemoInAccounting(String txnJson) { return null; }
    
    @RemoteAction
    global static String SubmitReturn(String returnVOId){
    	returnVOId = BPUtility.getDecodedString(returnVOId);
    	
    	Return_VO_Header__c returnVOHObjToUpdate = new Return_VO_Header__c();
    	returnVOHObjToUpdate.Id = returnVOId;
    	returnVOHObjToUpdate.Status__c = 'Submitted';
    	returnVOHObjToUpdate.Submitted_Date__c = system.today();
		returnVOHObjToUpdate.Submitted_By__c = UserInfo.getUserId();
    	if(AccessControl.ifObjectFieldIsUpdateable('Return_VO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
    	update returnVOHObjToUpdate;
    	
    	return getReturnVODetail(BPUtility.getEncodedString(returnVOId));
    }
    
    
    @RemoteAction
    global static String SetAsApprovedReturnVO(String returnVOId){
    	returnVOId = BPUtility.getDecodedString(returnVOId);
    	
    	try{
    		Return_VO_Header__c returnVOHObjToUpdate = new Return_VO_Header__c();
	    	returnVOHObjToUpdate.Id = returnVOId;
	    	returnVOHObjToUpdate.Status__c = 'Approved';
			returnVOHObjToUpdate.Approved_Date__c = system.today();
			returnVOHObjToUpdate.Approved_By__c = UserInfo.getUserId();
	    	if(AccessControl.ifObjectFieldIsUpdateable('Return_VO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
	    	update returnVOHObjToUpdate;
	    	
	    	if(AccessControl.ifObjectFieldIsAccessible('Return_VO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	    	List<Return_VO_Line_Item__c> returnLineItems = [select Id, Part__c, Return_Qty__c, Item_Cost__c 
	    													from Return_VO_Line_Item__c
	    													where Return_VO_Header__c = :returnVOId];
	    	
	    													
	    	FIFOTransaction.CreateFiFoBucketActivityForReturnVendor(returnLineItems, returnVOId);
    	}catch(Exception e){
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    	return getReturnVODetail(BPUtility.getEncodedString(returnVOId));
    }
    
    
    
    @RemoteAction // moved to ReturnVendorCreditCtrl
    global static String ProcessCreditReturnVO(String returnVOId) { return null; }
    
    
    @RemoteAction
    global static String deleteReturnVOLI(String returnVOId){
    	returnVOId = BPUtility.getDecodedString(returnVOId);
    	
    	List<Return_VO_Header__c> returnVOList = SOQLUtil.getReturnVOHeaderDetail(new Map<String, String>{'Id' => returnVOId  }); 
    	String response = 'Error';
    	if(returnVOList.size() > 0){
    		if((returnVOList[0].Status__c == 'In Progress' || returnVOList[0].Status__c == 'Submitted')
    			 && returnVOList[0].Return_VO_Line_Items__r.size() == 0){
    			Return_VO_Header__c rvoHeader = new Return_VO_Header__c();
    			rvoHeader.Id = returnVOList[0].Id;
    			if(AccessControl.ifObjectIsDeletable('Vendor_Order_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
    			delete rvoHeader;
    			response = 'Success';
    		}
    	}
    	return BPUtility.getEncodedString(response);
    }

	@RemoteAction
    global static String getActiveRVOCountByVendorId(String vendorId) {
        return BPUtility.getEncodedString(ReturnVOService.getActiveRVOCountByVendorId(BPUtility.getDecodedString(vendorId)));
    }
    
    @RemoteAction
    global static String getActiveReturnVendorOrdersByVendorId(String filterJsonStr) {
        return BPUtility.getEncodedString(System.JSON.serialize(ReturnVOService.getActiveReturnVendorOrdersByVendorId(BPUtility.getDecodedString(filterJsonStr))));
    }

	@RemoteAction
    global static String getCreditHistory(String rvoId) {
        return BPUtility.getEncodedString(System.JSON.serialize(ReturnVOService.getCreditHistory(BPUtility.getDecodedString(rvoId))));
    }
}