/**
 * Author: Ashish Garg
 * Since: Aug 20, 2015
 * Name: VendorReceivingGroupTriggerHelper
 * Description: Trigger Helper
**/
public without sharing class VendorReceivingGroupTriggerHelper {
	
	public static Boolean isForceStopTrigger = false;
    // List to store trigger new list
    public static List<Vendor_Receiving_Group__c> newList = new List<Vendor_Receiving_Group__c>();
    
    // List to store trigger old list
    public static List<Vendor_Receiving_Group__c> oldList = new List<Vendor_Receiving_Group__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Vendor_Receiving_Group__c> newMap = new Map<Id, Vendor_Receiving_Group__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Vendor_Receiving_Group__c> oldMap = new Map<Id, Vendor_Receiving_Group__c>();
    
    // Static variable to hold context run
    public static boolean isProcessed = false;
    
    /** 
     * Name: updateLineItemsReceivedQty
     * Desc: Update the Qty Received for line items received in case Vendor Receiving group insert/update/delete 
     * @param: 
     * @return: 
    **/
    public static void updateLineItemsReceivedQty(){
        if(AccessControl.ifObjectIsUpdateable('Vendor_Receiving_Stock_Excess__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE);}
        if(AccessControl.ifObjectIsUpdateable('Vendor_Order_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE);}
        boolean isValidTriggerEntry = false;
        if( Trigger.isInsert || Trigger.isDelete ){
            isValidTriggerEntry = true;
        } else if(Trigger.isUpdate){
            for(Vendor_Receiving_Group__c vrg : newList){
                if( newMap.get(vrg.Id).Recieved__c != oldMap.get(vrg.Id).Recieved__c ){
                    isValidTriggerEntry = true;
                    break;
                }
            }
            isValidTriggerEntry = true;
        }
        
        if(!isValidtriggerEntry || isProcessed){
            return;
        }
        isProcessed = true;
        
        List<Vendor_Receiving_Group__c> recsList = (Trigger.isDelete) ? oldList : newList;
        Map<Id, Vendor_Receiving_Group__c> recsMap = (Trigger.isDelete) ? oldMap : newMap;
        
        if(AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Vendor_Order_Line_Item__c> volis = [Select Id, 
                                                        Vendor_Order_Line_Item_Group__c,
                                                        Vendor_Order_Line_Item_Group__r.Vendor_Order_Header__c,
                                                        Vendor_Order_Line_Item_Group__r.Need__c,
                                                        Vendor_Order_Line_Item_Group__r.Cost__c,
                                                        Vendor_Receiving_Group__r.Vendor_Receiving_Header__c,
                                                        Vendor_Order_Line_Item_Group__r.Vendor_Order_Header__r.Name,
                                                        Vendor_Receiving_Group__c,
                                                        Received__c,
                                                        Qty_Needed__c,
                                                        Is_Service__c,
                                                        Is_required_For_Customer__c,
                                                        Is_From_Search__c,
                                                        Is_Excess__c,
                                                        LastModifiedDate
                                                        from Vendor_Order_Line_Item__c 
                                                        where Vendor_Receiving_Group__c IN: recsList
                                                        order by Vendor_Order_Line_Item_Group__r.Vendor_Order_Header__r.Name
                                                ];
        
        if(AccessControl.ifObjectIsAccessible('Vendor_Receiving_Stock_Excess__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Vendor_Receiving_Stock_Excess__c> stockExcesses = [Select  Id, 
                                                                        Vendor_Order_Line_Item_Group__c,
                                                                        Vendor_Receiving_Group__c,
                                                                        Received_Qty__c,
                                                                        Order_Desc__c
                                                                        from Vendor_Receiving_Stock_Excess__c 
                                                                        where Vendor_Receiving_Group__c IN: recsMap.keySet()];                                      
                                                
        // Map for receiving header Id + order group Id => Stock Excess record
        Map<String, Vendor_Receiving_Stock_Excess__c> receivingGroupToStockExcessMap = new Map<String, Vendor_Receiving_Stock_Excess__c>();
        
        // Map of receiving group to total need of groups in receiving
        Map<Id, decimal> receivingGroupIdToTotalNeedMap = new Map<Id, decimal>();
        
        for(Vendor_Receiving_Stock_Excess__c stockExcess : stockExcesses){
            String mapKey = stockExcess.Vendor_Receiving_Group__c + '-' + stockExcess.Vendor_Order_Line_Item_Group__c;
            receivingGroupToStockExcessMap.put(mapKey, stockExcess);
        }
        
        if(volis.size() == 0 && Trigger.isUpdate){
            for(Vendor_Receiving_Group__c vrg : recsList){
                receivingGroupIdToTotalNeedMap.put(vrg.Id, 0);
            }
        }
        
        // Map of all the receiving group ids to related line items
        Map<Id, List<Vendor_Order_Line_Item__c>> receivingGroupToLineItemsMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
        
        // Map to hold vendor receiving group Id to list of Vendor line item groups Id
        // Used to update received qty field on vendor line item group record
        Map<Id, Set<Id>> receivingGroupIdToVOGroupIdMap = new Map<Id, Set<Id>>();
        
        for(Vendor_Order_Line_Item__c voli : volis){
            Set<Id> vogIdsList = (receivingGroupIdToVOGroupIdMap.containsKey(voli.Vendor_Receiving_Group__c)) ? receivingGroupIdToVOGroupIdMap.get(voli.Vendor_Receiving_Group__c) : new Set<Id>();
            vogIdsList.add(voli.Vendor_Order_Line_Item_Group__c);
            receivingGroupIdToVOGroupIdMap.put(voli.Vendor_Receiving_Group__c, vogIdsList);
            
            // Populate total need for vendor receiving need
            Decimal totalNeed = (receivingGroupIdToTotalNeedMap.containsKey(voli.Vendor_Receiving_Group__c)) ? receivingGroupIdToTotalNeedMap.get(voli.Vendor_Receiving_Group__c) : 0;
            totalNeed += (voli.Qty_Needed__c != null) ? voli.Qty_Needed__c : 0;
            receivingGroupIdToTotalNeedMap.put(voli.Vendor_Receiving_Group__c, totalNeed);
            
            // populate map Map<Id, List<Vendor_Order_Line_Item__c>> receivingGroupToLineItemsMap
            List<Vendor_Order_Line_Item__c> receivingGroupVOLIs = (receivingGroupToLineItemsMap.containsKey(voli.Vendor_Receiving_Group__c)) ? receivingGroupToLineItemsMap.get(voli.Vendor_Receiving_Group__c) : new List<Vendor_Order_Line_Item__c>();
            receivingGroupVOLIs.add(voli);
            receivingGroupToLineItemsMap.put(voli.Vendor_Receiving_Group__c, receivingGroupVOLIs);
        }
        
        // Line items list to update after all calculations and assignments
        List<Vendor_Order_Line_Item__c> volisToUpdate = new List<Vendor_Order_Line_Item__c>();
        
        // Stock excess records need to be inserted/updated
        List<Vendor_Receiving_Stock_Excess__c> stockExcessRecordsToUpsert = new List<Vendor_Receiving_Stock_Excess__c>();
        // Stock excesses to delete in case received quantity is decreased and there is any stock excess record available
        List<Vendor_Receiving_Stock_Excess__c> stockExcessRecordsToDelete = new List<Vendor_Receiving_Stock_Excess__c>();
        
        // In case of update of received quantity in receiving group:
        // Update line items received quantity in order
        for(Id receivingId : recsMap.keySet()){
            Vendor_Receiving_Group__c vrg = recsMap.get(receivingId);
            List<Vendor_Order_Line_Item__c> receivingVolis = (receivingGroupToLineItemsMap.containsKey(vrg.Id)) ? receivingGroupToLineItemsMap.get(vrg.Id) : new List<Vendor_Order_Line_Item__c>();
            
            // If received qty is updated to 0, then remove the line items from receiving and update receiving to 0
            if(vrg.Recieved__c == 0){
                for(Vendor_Order_Line_Item__c voli : receivingVolis){
                    voli.Received__c = 0;
                    voli.Vendor_Receiving_Group__c = null;
                }
                volisToUpdate.addAll(receivingVolis);
            } else {
                Id vogId = (receivingVolis != null && receivingVolis.size() > 0) ? receivingVolis[0].Vendor_Order_Line_Item_Group__c : null;
                decimal differenceQty = vrg.Recieved__c - (receivingGroupIdToTotalNeedMap.get(vrg.Id) == null ? 0 :  receivingGroupIdToTotalNeedMap.get(vrg.Id));
                String mapKey = vrg.Id + '-' + vogId;
                
                // There are 2 cases need to handled here:
                // 1. If Quantity received is more than Quantity ordered
                // 2. If Quantity received is less than or equal to Quantity ordered
                if(differenceQty > 0 && vrg.Part__c != null) {
                    Vendor_Receiving_Stock_Excess__c stockExcess;
                    
                    if( !receivingGroupToStockExcessMap.containsKey(mapKey) ){
                        stockExcess = new Vendor_Receiving_Stock_Excess__c( Vendor_Receiving_Group__c = vrg.Id,
                                                                            Vendor_Order_Line_Item_Group__c = vogId,
                                                                            Received_Qty__c = differenceQty);
                    } else {
                        stockExcess = receivingGroupToStockExcessMap.get(mapKey);
                        stockExcess.Received_Qty__c = differenceQty;
                    }
                    stockExcessRecordsToUpsert.add(stockExcess);
                    
                    // Now make the differenceQty equal to 0 so as to fullfill all line items in further steps
                    differenceQty = 0;
                }
                
                // If Quantity received is less than or equal to Quantity ordered
                if(differenceQty <= 0 && receivingVolis != null) {
                    // ToDo: Fullfill the related line items in an ordered way
                    if( vrg.Recieved__c <= receivingGroupIdToTotalNeedMap.get(vrg.Id) && receivingGroupToStockExcessMap.containsKey(mapKey) ){
                        stockExcessRecordsToDelete.add(receivingGroupToStockExcessMap.get(mapKey));
                    }
                    
                    // Create a list of "VendorReceivingLineItem" records with line item records so as to sort the list and fullfill their demands in order
                    List<VendorReceivingLineItem> vrlis = new List<VendorReceivingLineItem>();
                    for(Vendor_Order_Line_Item__c voli : receivingVolis){
                        vrlis.add( new VendorReceivingLineItem(voli) );
                    }
                    vrlis.sort();
                    
                    if(vrg.Is_Packaged_Part__c) {
                        Map<String, List<VendorReceivingLineItem>> vogIdToVRLIListMap = new Map<String, List<VendorReceivingLineItem>>();
                        for(VendorReceivingLineItem vrliObj : vrlis){
                            if(!vogIdToVRLIListMap.containsKey(vrliObj.voli.Vendor_Order_Line_Item_Group__c)){
                                vogIdToVRLIListMap.put(vrliObj.voli.Vendor_Order_Line_Item_Group__c, new List<VendorReceivingLineItem>());
                        }                            
                            vogIdToVRLIListMap.get(vrliObj.voli.Vendor_Order_Line_Item_Group__c).add(vrliObj);
                    }

                        List<VendorReceivingLineItem> newVRLIList = new List<VendorReceivingLineItem>();
                        for(String vogRecId : vogIdToVRLIListMap.keySet()) {
                            for(VendorReceivingLineItem voliObj : vogIdToVRLIListMap.get(vogRecId)){
                                newVRLIList.add(voliObj);
                        }
                    }
                        vrlis = newVRLIList;
                    }
                    
                    // Now loop through vrlis list and fill received quantity for line items
                    decimal availQty = vrg.Recieved__c;
                    
                    if(Trigger.isUpdate && vrg.Part__c != null) {
                        for(VendorReceivingLineItem vrli : vrlis){
                            Vendor_Order_Line_Item__c voli = vrli.voli;
                            
                            decimal qtyToFullfill = (availQty == 0) 
                                                    ? 0 
                                                    :(
                                                        (availQty >= voli.Qty_Needed__c) ? voli.Qty_Needed__c : availQty
                                                    );
                            voli.Received__c = qtyToFullfill;
                            
                            availQty = (availQty >= voli.Qty_Needed__c) ? (availQty - qtyToFullfill) : 0;
                            volisToUpdate.add(voli);
                        }
                        
                    } else if(Trigger.isDelete) {
                        for(Integer i = vrlis.size() - 1; i >= 0; i--) {
                            Vendor_Order_Line_Item__c voli = vrlis[i].voli;
                            Decimal QtyToReduce = 0;
                            if(availQty > 0) {
                                qtyToReduce = ((availQty > voli.Received__c) ? voli.Received__c : availQty);
                                availQty = availQty - voli.Received__c;
                            }
                            voli.Received__c = voli.Received__c - qtyToReduce;
                            volisToUpdate.add(voli);
                        }
                    }
                }
            }
        }
        
        
        if(volisToUpdate.size() > 0){
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', volisToUpdate, false);
        }
        
        if(stockExcessRecordsToUpsert.size() > 0){
            DMLUtility.upsertSobjectList('Vendor_Receiving_Stock_Excess__c', stockExcessRecordsToUpsert, false);
        }
        
        if(stockExcessRecordsToDelete.size() > 0){
            if(AccessControl.ifObjectIsDeletable('Vendor_Receiving_Stock_Excess__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
            Database.DeleteResult[] res = database.delete(stockExcessRecordsToDelete,false);
        }
        
    }
    
    public static void afterDeleteOperation() {
        updateVRTotalByVRLIG(oldList);
    }
    
    public static void afterUpdateOperation() {
        updateVRTotalByVRLIG(newList);
    }
    public static void afterInsertOperation() {
        updateVRTotalByVRLIG(newList);
    }
    
    public static void beforeUpdateOperation() {
        for(Vendor_Receiving_Group__c vrgRec : newList) {
            if(vrgRec.Cost__c != null && vrgRec.Recieved__c != null) {
                Decimal discount = vrgRec.Discount__c != null ? vrgRec.Discount__c : 0;
                if(vrgRec.Is_Packaged_Part__c && !vrgRec.Is_Order_As_Individual_Item__c && vrgRec.Per_Unit_Cost__c != null) {
                    vrgRec.Total__c = (((vrgRec.Per_Unit_Cost__c * (1 - discount/100)).setScale(2, RoundingMode.HALF_UP)) * (vrgRec.Recieved__c/vrgRec.Package_Qty__c)).setScale(2, RoundingMode.HALF_UP);
                } else {
                    vrgRec.Total__c = (((vrgRec.Cost__c * (1 - discount/100)).setScale(2, RoundingMode.HALF_UP)) * vrgRec.Recieved__c).setScale(2, RoundingMode.HALF_UP);
                }
            } else {
                vrgRec.Total__c = 0;
            }
        }
    }
    
    public static void updateVRTotalByVRLIG(List<Vendor_Receiving_Group__c> vrgList) {
    	Set<Id> vrHeaderIdSet = new Set<Id>();
        for(Vendor_Receiving_Group__c vrgRec : vrgList) {
    		vrHeaderIdSet.add(vrgRec.Vendor_Receiving_Header__c);
    	}
    	vrHeaderIdSet.remove(null);
    	
    	if(vrHeaderIdSet.size() > 0) {
	    	if(AccessControl.ifObjectIsAccessible('Vendor_Receiving_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
	    	List<Vendor_Receiving_Group__c> vrgRecList = [Select Vendor_Receiving_Header__c, Cost__c, Recieved__c, Total__c, Part__c, Sublet__c, Package_Qty__c, Is_Packaged_Part__c, Is_Order_As_Individual_Item__c  
                                                    From Vendor_Receiving_Group__c where Vendor_Receiving_Header__c IN : vrHeaderIdSet];                                                    
	    												
	    	Map<String, Vendor_Receiving_Header__c>	vrHeaderIdToRecMap = new Map<String, Vendor_Receiving_Header__c>();
	    	for(Vendor_Receiving_Group__c vrgRec : vrgRecList) {
	    		if(!vrHeaderIdToRecMap.containsKey(vrgRec.Vendor_Receiving_Header__c)) {
	    			vrHeaderIdToRecMap.put(vrgRec.Vendor_Receiving_Header__c, 
	    										new Vendor_Receiving_Header__c(Id = vrgRec.Vendor_Receiving_Header__c, Receiving_Total__c = 0, Total_Received_Qty__c = 0));
	    		}
	    		
	    		if(vrgRec.Total__c != null) {
	                vrHeaderIdToRecMap.get(vrgRec.Vendor_Receiving_Header__c).Receiving_Total__c += vrgRec.Total__c.setScale(2, RoundingMode.HALF_UP);
	            }
                if(vrgRec.Recieved__c != null) {
                    vrHeaderIdToRecMap.get(vrgRec.Vendor_Receiving_Header__c).Total_Received_Qty__c += getReceivedQuantity(vrgRec);
                }
	    	}
	    	if(vrHeaderIdToRecMap.size() > 0) {
	    		if(AccessControl.ifObjectIsUpdateable('Vendor_Receiving_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE);}
		        update vrHeaderIdToRecMap.values();
	    	}
		}
    }
    
    
    public static Decimal getReceivedQuantity(Vendor_Receiving_Group__c vrgRec) {												
        Decimal receivedQuantity = 0;
        if(vrgRec.Part__c != null) { 
            if(vrgRec.Is_Packaged_Part__c && !vrgRec.Is_Order_As_Individual_Item__c) {
                receivedQuantity = (vrgRec.Recieved__c / vrgRec.Package_Qty__c);
            } else {
                receivedQuantity = vrgRec.Recieved__c;
            }
        } else if(vrgRec.Sublet__c != null) {
            receivedQuantity = vrgRec.Recieved__c;
        }
        return receivedQuantity.setScale(2, RoundingMode.HALF_UP);    
    }
}