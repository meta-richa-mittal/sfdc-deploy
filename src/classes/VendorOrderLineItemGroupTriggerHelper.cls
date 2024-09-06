/** 
 * Author: Ashish Garg
 * Since: Aug 21, 2015 
 * Name: VendorOrderLineItemGroupTriggerHelper
 * Description: Trigger Helper
**/
public without sharing class VendorOrderLineItemGroupTriggerHelper {

	public static Boolean isForceStopTrigger = false;

	public static Boolean isByPassVOLIUpdate = false;

	// List to store trigger new list
    public static List<Vendor_Order_Line_Item_Group__c> newList = new List<Vendor_Order_Line_Item_Group__c>();
    
    // List to store trigger old list
    public static List<Vendor_Order_Line_Item_Group__c> oldList = new List<Vendor_Order_Line_Item_Group__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Vendor_Order_Line_Item_Group__c> newMap = new Map<Id, Vendor_Order_Line_Item_Group__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Vendor_Order_Line_Item_Group__c> oldMap = new Map<Id, Vendor_Order_Line_Item_Group__c>();
    
	/**
     * Name: updateLineItemsReceivedQty
     * Desc: Update the Qty Received for line items received in case Vendor Receiving group insert/update/delete 
     * @param: 
     * @return: 
    **/
    public static void updateLineItemsReceivedQty(){
    	boolean isValidUpdateTrigger = false;
    	Set<Id> validGroupIdsSet = new Set<Id>();
    	
    	List<Id> partIdList = new List<Id>();
        List<Id> subletIdList = new List<Id>();
		for(Vendor_Order_Line_Item_Group__c volig : newList){
    		if(volig.Part__c != null) {
                partIdList.add(volig.Part__c);
            }
            if(volig.Sublet__c != null) {
                subletIdList.add(volig.Sublet__c);
            }
		}
		
		if(AccessControl.ifObjectIsAccessible('Part__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
		Map<Id, Part__c> partIdToPartRecordMap = new Map<Id, Part__c>();
		Map<Id, Product__c> subletIdToSubletRecordMap = new Map<Id, Product__c>();
		if(!partIdList.isEmpty()) {
			partIdToPartRecordMap = new Map<Id, Part__c>([select Last_Cost__c, Calculated_Cost__c, Packaged_Part__c, Package_Qty__c, Calculated_Package_Cost__c from Part__c where Id IN: partIdList]);
		}
		if(!subletIdList.isEmpty()) {
			subletIdToSubletRecordMap = new Map<Id, Product__c>([select Cost__c, Price__c, Cost_Method__c from Product__c where Id IN: subletIdList]);
		}
    	
        for(Vendor_Order_Line_Item_Group__c volig : newList){
    		if(volig.Received_Qty__c == 0){
    			validGroupIdsSet.add(volig.Id);
    			isValidUpdateTrigger = true;
    		}
			Part__c partRec;
			Boolean isPkgPart = false;
            if(volig.Part__c != null) {
				partRec = partIdToPartRecordMap.get(volig.Part__c);
				isPkgPart = Trigger.isInsert ? (partRec.Packaged_Part__c && !volig.Is_Order_As_Individual_Item__c) : (volig.Is_Packaged_Part__c && !volig.Is_Order_As_Individual_Item__c);
			}
			if(trigger.isInsert) {
				if(volig.Part__c != null) {
					if(volig.Received_Qty__c == null || volig.Received_Qty__c == 0) {
						if(volig.Cost__c == null || volig.Cost__c == 0) {
							volig.Cost__c = partRec.Calculated_Cost__c;
							volig.Per_Unit_Cost__c = isPkgPart ? partRec.Calculated_Package_Cost__c : partRec.Calculated_Cost__c;

						} else if(volig.Per_Unit_Cost__c == null || volig.Per_Unit_Cost__c == 0) {
							volig.Per_Unit_Cost__c = isPkgPart ? volig.Cost__c * partRec.Package_Qty__c : volig.Cost__c;
						}
					}	
				} else {
					volig.Per_Unit_Cost__c = volig.Cost__c;
				}
			}
			if(volig.Per_Unit_Cost__c != null && volig.Need__c != null) {
				Decimal unitsOrdered = isPkgPart ? (volig.Need__c / (Trigger.isInsert ? partRec.Package_Qty__c : volig.Package_Qty__c)) : volig.Need__c;
				volig.Total__c = unitsOrdered * volig.Per_Unit_Cost__c;
			}
    	}   	
    	if(!isByPassVOLIUpdate && isValidUpdateTrigger){
			validGroupIdsSet.remove(null);
    		if(AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
    		List<Vendor_Order_Line_Item__c> volis = [Select Id, Received__c from Vendor_Order_Line_Item__c where Vendor_Order_Line_Item_Group__c IN: validGroupIdsSet];
    		for(Vendor_Order_Line_Item__c voli : volis){
    			voli.Received__c = 0;
    		}
    		DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', volis);
    	}
    }
    
    public static void beforeDeleteOperation() {
    	updateVOTotalByVOLIG(oldList);
    }
    
    public static void afterUpdateOperation() {
    	updateVOTotalByVOLIG(newList);
    }
    public static void afterInsertOperation() {
    	updateVOTotalByVOLIG(newList);
    }
    
   
    
    private static void updateVOTotalByVOLIG(List<Vendor_Order_Line_Item_Group__c> voligList) {
    	if(AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item_Group__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
    	List<Vendor_Order_Line_Item_Group__c> voligRecList = [Select Vendor_Order_Header__c From Vendor_Order_Line_Item_Group__c where Id IN: voligList];
    	Set<Id> voHeaderIdSet = new Set<Id>();
    	Set<Id> deletedVOLIGSet = new Set<Id>();
    	
    	for(Vendor_Order_Line_Item_Group__c voligRec : voligRecList){
    		voHeaderIdSet.add(voligRec.Vendor_Order_Header__c);
    		if(trigger.isDelete){
    			deletedVOLIGSet.add(voligRec.Id);
    		}
    	}
    	
    	if(AccessControl.ifObjectIsAccessible('Vendor_Order_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
    	List<Vendor_Order_Header__c> voHeaderList = [Select Total__c, Total_Recieved__c, (select Status__c, Total__c, Received_Qty__c, Cost__c, 
														Part__r.Packaged_Part__c, Part__r.Package_Qty__c, Part__r.Package_Cost__c, Is_Order_As_Individual_Item__c 
														from Vendor_Order_Line_Item_Groups__r),
														(select Vendor_Order_Line_Item_Group__c, Line_Item_Cost__c, Vendor_Receiving_Group__r.Per_Unit_Cost__c, Received__c 
														from Vendor_Order_Line_Items__r WHERE Is_Received__c = true)
														 from Vendor_Order_Header__c 
    													WHERE Id IN : voHeaderIdSet];
    																
		Map<String, List<Vendor_Order_Line_Item__c>> vogToVoliListMap = new Map<String, List<Vendor_Order_Line_Item__c>>();
		for(Vendor_Order_Header__c voHeaderRec : voHeaderList) {
			for(Vendor_Order_Line_Item__c voliRec : voHeaderRec.Vendor_Order_Line_Items__r) {
				if(!vogToVoliListMap.containsKey(voliRec.Vendor_Order_Line_Item_Group__c)) {
					vogToVoliListMap.put(voliRec.Vendor_Order_Line_Item_Group__c, new List<Vendor_Order_Line_Item__c>());
				}
				vogToVoliListMap.get(voliRec.Vendor_Order_Line_Item_Group__c).add(voliRec);
			}
		}
		
		for(Vendor_Order_Header__c voHeaderRec : voHeaderList) {
    		Decimal total = 0;
    		Decimal recieved = 0;
    		for(Vendor_Order_Line_Item_Group__c voligRec : voHeaderRec.Vendor_Order_Line_Item_Groups__r) {
    			if(Trigger.isDelete && deletedVoligSet.contains(voligRec.Id)) {
    				total -= voligRec.Total__c;
    			}
    			if(voligRec.Total__c != null && voligRec.Status__c != 'Cancelled') {
    				total += voligRec.Total__c;
    			}
    			
				if(voligRec.Part__c != null && voligRec.Part__r.Packaged_Part__c && !voligRec.Is_Order_As_Individual_Item__c && voligRec.Received_Qty__c != null) {
					if(vogToVoliListMap.containsKey(voligRec.Id)) {
						for(Vendor_Order_Line_Item__c voliRec: vogToVoliListMap.get(voligRec.Id)) {
							if(voliRec.Vendor_Receiving_Group__r.Per_Unit_Cost__c != null) {
								recieved += (voliRec.Vendor_Receiving_Group__r.Per_Unit_Cost__c*(voliRec.Received__c/voligRec.Part__r.Package_Qty__c)).setScale(2, RoundingMode.HALF_UP);
							} else {
								recieved += (voliRec.Line_Item_Cost__c * voliRec.Received__c);
							}
						}
					} else if(!vogToVoliListMap.containsKey(voligRec.Id) && voligRec.Part__r.Package_Cost__c != null) {
						recieved += (voligRec.Part__r.Package_Cost__c*(voligRec.Received_Qty__c/voligRec.Part__r.Package_Qty__c)).setScale(2, RoundingMode.HALF_UP);
					} else {
						recieved += voligRec.Received_Qty__c * voligRec.Cost__c;
					}
				} else if(voligRec.Received_Qty__c != null && voligRec.Cost__c != null) {
    				recieved += voligRec.Received_Qty__c * voligRec.Cost__c;
    			}
    		}
    		
    		voHeaderRec.Total__c = total; 
    		voHeaderRec.Total_Recieved__c = recieved;
    	}														
    	
    	if(voHeaderList.size() > 0) {
    		if(AccessControl.ifObjectIsUpdateable('Vendor_Order_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE);}
    		update voHeaderList;
    	}
    }
}