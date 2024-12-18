/**
 * Author: Tarun Khandelwal
 * Since: Aug. 04, 2014
 * Name: VendorOrderLineItemTriggerHelper
 * Description: Helper class for triggers on VOLI.
**/
public without sharing class VendorOrderLineItemTriggerHelper {
    
    // List to store trigger new list
    public static List<Vendor_Order_Line_Item__c> voliNewList = new List<Vendor_Order_Line_Item__c>();
    
    // List to store trigger old list
    public static List<Vendor_Order_Line_Item__c> voliOldList = new List<Vendor_Order_Line_Item__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Vendor_Order_Line_Item__c> voliNewMap = new Map<Id, Vendor_Order_Line_Item__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Vendor_Order_Line_Item__c> voliOldMap = new Map<Id, Vendor_Order_Line_Item__c>();
    
    public static Boolean isTriggerExecute = true;
    public static Boolean shouldTriggerRunStop = false;
    public static Boolean isCommitReceivingAction = false;
    public static String dealerName;
    
    public static void afterInsertCalculation() {
        setSpecialOrderStatusOnCO(voliNewList);
    }
    
    public static void afterDeleteCalculation() {
        setSpecialOrderStatusOnCO(voliOldList);
    }
    
    public static void setSpecialOrderStatusOnCO(List<Vendor_Order_Line_Item__c> voliList) {
        Set<Id> coHeaderIdSet = new Set<Id>();
        for(Vendor_Order_Line_Item__c voli : voliList) {
            if(voli.CO_Header__c != null) {
                coHeaderIdSet.add(voli.CO_Header__c);
            }
        }
        coHeaderIdSet.remove(null);
        if(coHeaderIdSet.size() > 0 && !Test.isRunningTest()) {
            if(system.isBatch()){
                COSectionDetailService.setSectionStatus(coHeaderIdSet,COSectionDetailService.MERCHANDISE);
            } else {
                COSectionDetailService.setSectionStatus_future(coHeaderIdSet);
            }
        }
    }
    
    private static void setSpecialOrderStatusOnCOWhenQtyReceiving() {
    	if(voliNewList != null) {
	        Set<Id> coHeaderIdSet = new Set<Id>();
	        for(Vendor_Order_Line_Item__c voli : voliNewList) {
	            if(voli.CO_Header__c != null && voli.Is_Received__c && voli.Is_Received__c != voliOldMap.get(voli.Id).Is_Received__c) {
	                coHeaderIdSet.add(voli.CO_Header__c);
	            }
	        }
	        coHeaderIdSet.remove(null);
	        if(coHeaderIdSet.size() > 0 && !Test.isRunningTest()) {
	            COSectionDetailService.setSectionStatus_future(coHeaderIdSet);
	        }
	    }
    }
    
    public static Boolean isUpdatePartOrderedQty = false;
    
    private static void updatePartOrderedQtyWhenStockVOLIisCreatedFromSpecialOrder() {
        if(isUpdatePartOrderedQty) {
           return; 
        }
        isUpdatePartOrderedQty = true;
        
        Set<Id> partIdSet = new Set<Id>();
        List<Vendor_Order_Line_Item__c> validVOLIList = new List<Vendor_Order_Line_Item__c>();
        for(Vendor_Order_Line_Item__c voli : voliNewList) {
            if(voli.Part__c != null && !voli.Is_Received__c && ((!voli.Is_required_For_Customer__c && voliOldMap.get(voli.Id).Is_required_For_Customer__c) || 
                                            (!voli.Is_Service__c && voliOldMap.get(voli.Id).Is_Service__c)) ) {
                partIdSet.add(voli.Part__c);
                validVOLIList.add(voli);
            }
        }
        partIdSet.remove(null);
        PartService.updatePartOnOrderQty(partIdSet);
    }
    
    /**
     * Name: afterUpdateCalculation
     * Desc: Update Special order field of COLI in case of require for customer VOLI.
     * @param: 
     * @return: 
    **/
    public static void afterUpdateCalculation() {
        Set<Id> specialOrderCOLineItemIdSet = new Set<Id>();
        Set<Id> notSpecialOrderCOLineItemIdSet = new Set<Id>();
        
        Set<Id> specialOrderSOLIIdSet = new Set<Id>();
        Set<Id> notSpecialOrderSOLIIdSet = new Set<Id>();
        
        for(Vendor_Order_Line_Item__c voliRec : voliNewList) {
            if(voliRec.Vendor_Order_Header__c != null && (voliRec.Is_required_For_Customer__c || voliRec.Is_Service__c) && (voliRec.CO_Line_Item__c != null || voliRec.Service_Order_Line_Item__c != null)) {
                if(voliRec.CO_Line_Item__c != null) {
                    specialOrderCOLineItemIdSet.add(voliRec.CO_Line_Item__c);
                } else if(voliRec.Service_Order_Line_Item__c != null) {
                    specialOrderSOLIIdSet.add(voliRec.Service_Order_Line_Item__c);
                }
            } else if(voliOldMap.get(voliRec.Id).Vendor_Order_Header__c != null && voliRec.Vendor_Order_Header__c == null && (voliRec.Is_required_For_Customer__c || voliRec.Is_Service__c)) {
                if(voliRec.CO_Line_Item__c != null) {
                    notSpecialOrderCOLineItemIdSet.add(voliRec.CO_Line_Item__c);
                } else if(voliRec.Service_Order_Line_Item__c != null) {
                    notSpecialOrderSOLIIdSet.add(voliRec.Service_Order_Line_Item__c);
                }
            }
        }
        updatePartOrderedQtyWhenStockVOLIisCreatedFromSpecialOrder();
        if(!isCommitReceivingAction) {
            setSpecialOrderStatusOnCO(voliOldList); //to put on condition
        }
        if(specialOrderCOLineItemIdSet.size() == 0 && notSpecialOrderCOLineItemIdSet.size() == 0 && specialOrderSOLIIdSet.size() == 0 && notSpecialOrderSOLIIdSet.size() == 0) {
            return;
        }
        
        if(specialOrderCOLineItemIdSet.size() > 0 || notSpecialOrderCOLineItemIdSet.size() > 0) {
            List<CO_Line_Item__c> coLineItemListToUpdate = new List<CO_Line_Item__c>();
            
            if(AccessControl.ifObjectIsAccessible('CO_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
                List<CO_Line_Item__c> colIneItemList = [select Id, Special_Order__c from CO_Line_Item__c where Id IN :specialOrderCOLineItemIdSet OR Id IN :notSpecialOrderCOLineItemIdSet];
            for(CO_Line_Item__c coLineItemRec : colIneItemList) {
                coLineItemRec.Special_Order__c = specialOrderCOLineItemIdSet.contains(coLineItemRec.Id) ? true : false;
                coLineItemListToUpdate.add(coLineItemRec);
            }
        
            if(coLineItemListToUpdate.size() > 0 && isTriggerExecute) {
                COLineItemTriggerHelper.isTriggerExecute = true;
                if(!COLineItemTriggerHelper.isVOLIRecToChange)
                DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemListToUpdate);
            }
        }
        /*
        if(specialOrderSOLIIdSet.size() > 0 || notSpecialOrderSOLIIdSet.size() > 0) {
            List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
        
            if(AccessControl.ifObjectIsAccessible('CO_Line_Item__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
            List<Service_Order_Line_Item__c> soliList = [select Id, Special_Order__c from Service_Order_Line_Item__c where Id IN :specialOrderSOLIIdSet OR Id IN :notSpecialOrderSOLIIdSet];
            for(Service_Order_Line_Item__c soLineItemRec : soliList) {
                soLineItemRec.Special_Order__c = specialOrderSOLIIdSet.contains(soLineItemRec.Id) ? true : false;
                soliListToUpdate.add(soLineItemRec);
            }
            
            if(soliListToUpdate.size() > 0 && isTriggerExecuted) {
                ServiceOrderLineItemTriggerHelper.isTriggerExecuted = true;
                if(!ServiceOrderLineItemTriggerHelper.isVOLIRecToChange)
                update soliListToUpdate;
            }
        }*/
        
        // To calculate VOG Need column
        updateRelatedVOLIGroup();
        updateRelatedSubmittedVOLIGroup();
        if(!isCommitReceivingAction) {
            setSpecialOrderStatusOnCOWhenQtyReceiving();
        }
    }
    
    public static void updateCOLIStatus() {
        List<CO_Line_Item__c> coLineItemList = new List<CO_Line_Item__c>();
        List<Service_Order_Line_Item__c> soLineItemList = new List<Service_Order_Line_Item__c>();
        for(Vendor_Order_Line_Item__c voliRec : voliNewList) {
            if(voliRec.CO_Line_Item__c != null) {
                CO_Line_Item__c coliRec = new CO_Line_Item__c(Id = voliRec.CO_Line_Item__c);
                if(voliRec.Vendor_Order_Line_Item_Group__c != null) {
                    coliRec.Status__c = 'Ordered';
                } else {
                    coliRec.Status__c = 'Required';
                }
                coLineItemList.add(coliRec);
            } else if(voliRec.Service_Order_Line_Item__c != null) {
                Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c(Id = voliRec.Service_Order_Line_Item__c);
                if(voliRec.Vendor_Order_Line_Item_Group__c != null) {
                    soliRec.Status__c = 'Ordered';
                } else {
                    soliRec.Status__c = 'Required';
                }
                soLineItemList.add(soliRec);
            }
        }
        if(coLineItemList.size() > 0 && isTriggerExecute) {
            COLineItemTriggerHelper.isTriggerExecute = true;
            isTriggerExecute = false;
            DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemList);
        }
        if(soLineItemList.size() > 0 && isTriggerExecute) {
            ServiceOrderLineItemTriggerHelper.isTriggerExecuted = true;
            isTriggerExecute = false;
            DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soLineItemList);
        }
    }
    
    /**
     * Name: beforeTriggerCalculation
     * Desc: Update Need for all group records for all line items
     * @param: 
     * @return: 
    **
    public static void beforeTriggerCalculation() {
        Boolean isValidEntry = false;
        Set<Id> voliGroupIdSet = new Set<Id>(); 
        List<Vendor_Order_Line_Item__c> triggerRecsList = (Trigger.isDelete) ? voliOldList : voliNewList;
        
        for(Vendor_Order_Line_Item__c voliRec : triggerRecsList) {
            if(trigger.isDelete && voliRec.Vendor_Order_Line_Item_Group__c != null){
                voliGroupIdSet.add(voliRec.Vendor_Order_Line_Item_Group__c);
                isValidEntry = true;
            } else if(voliOldMap.get(voliRec.Id).Vendor_Order_Line_Item_Group__c != voliNewMap.get(voliRec.Id).Vendor_Order_Line_Item_Group__c
                    || voliOldMap.get(voliRec.Id).Qty_Needed__c != voliNewMap.get(voliRec.Id).Qty_Needed__c ) {
                
                if(voliNewMap.get(voliRec.Id).Vendor_Order_Line_Item_Group__c != null){
                    voliGroupIdSet.add(voliNewMap.get(voliRec.Id).Vendor_Order_Line_Item_Group__c);
                }
                if(voliOldMap.get(voliRec.Id).Vendor_Order_Line_Item_Group__c != null){
                    voliGroupIdSet.add(voliOldMap.get(voliRec.Id).Vendor_Order_Line_Item_Group__c);
                }
                isValidEntry = true;
            }
        }
        
        System.debug('@@@@@@ Inside VOLITrigger ' + isValidEntry);
        if(isValidEntry) {
            VendorOrderLineItemTriggerHelper.updateNeedForVOGRecords(voliGroupIdSet);
        }
    }
    
    /**
     * Name: updateNeedForVOGRecords
     * Desc: Update "Need" on vendor order group records: total of needs of all vendor order line items
     * @param: Set<Id> vonder order group record Ids
     * @return: 
    **
    @future
    public static void updateNeedForVOGRecords(Set<Id> vogIds){
        List<Vendor_Order_Line_Item_Group__c> voliGroupList = [select Need__c, (select Id, Qty_Needed__c from Vendor_Order_Line_Items__r) from Vendor_Order_Line_Item_Group__c where Id IN: vogIds];
        for(Vendor_Order_Line_Item_Group__c voliGrpRec : voliGroupList) {
            Decimal need = 0;
            for(Vendor_Order_Line_Item__c voliRec : voliGrpRec.Vendor_Order_Line_Items__r) {
                need += voliRec.Qty_Needed__c;
            }
            voliGrpRec.Need__c = need;
        }
        
        if(voliGroupList.size() > 0) {
            update voliGroupList;
        }
    }*/
    
    public static void beforeTriggerCalculation() {
        populateDealerName();
    }
   
    private static void populateDealerName() {
        for(Vendor_Order_Line_Item__c voliRec : voliNewList) {
            if(voliRec.Is_required_For_Customer__c != null && !voliRec.Is_required_For_Customer__c && String.isBlank(voliRec.Dealer_Name__c)) {
                voliRec.Dealer_Name__c = getDealerName();
            }  
        }
    }

    private static String getDealerName() {
        if(String.isBlank(dealerName)) {
            for(Business_Profile__c businessProfileRec : [Select Business_Name__c from Business_Profile__c LIMIT 1]) {
                dealerName = businessProfileRec.Business_Name__c;
            }
        }
        return dealerName;
    }
    
    public static Boolean isUpdateQtyOnGroup = false; 
    
    private static Set<Id> getVOLIGroupIdSet() {
        Set<Id> voligGroupIdSet = new Set<Id>();
        for(Vendor_Order_Line_Item__c voliRec : voliOldList) {
            if(voliRec.Vendor_Order_Line_Item_Group__c != null) {
                voligGroupIdSet.add(voliRec.Vendor_Order_Line_Item_Group__c);
            }
        }
        voligGroupIdSet.remove(null);
        return voligGroupIdSet;
    }
    
    public static Boolean shouldTriggerRun = false;
    public static void beforeDeleteOperation() {
        if(!shouldTriggerRun) {
            return;
        }
        isUpdateQtyOnGroup = true;
        updateRelatedVOLIGroup();
    }
    
    public static void updateRelatedVOLIGroup() {
        if(AccessControl.ifObjectIsDeletable('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Vendor_Order_Line_Item_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        
        if(!isUpdateQtyOnGroup) {
            return;
        }
        isUpdateQtyOnGroup = false;
        Set<Id> voligGroupIdSet = getVOLIGroupIdSet();
        Set<Id> partIdSet = new Set<Id>();
        if(voligGroupIdSet.size() > 0) {
	        List<Vendor_Order_Line_Item_Group__c> voliGroupList = [select Part__c, Sublet__c, Is_Packaged_Part__c, Package_Qty__c, Order_Lots__c, 
	        						Vendor_Order_Header__c, Part__r.Qty_On_Order__c, Is_Order_As_Individual_Item__c, 
	                                (select Qty_Needed__c, Is_Excess__c, Is_required_For_Customer__c, Is_Service__c from Vendor_Order_Line_Items__r) 
	                                from Vendor_Order_Line_Item_Group__c where Id IN :voligGroupIdSet]; 
	    
	        List<sObject> sObjToDel = new List<sObject>();
	        List<sObject> sObjToUpdate = new List<sObject>();
	        List<Vendor_Order_Line_Item__c> voliListToUpsert = new List<Vendor_Order_Line_Item__c>();
	        for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
	            if(voliGroupRec.Vendor_Order_Line_Items__r.size() == 1 && voliOldMap.containsKey(voliGroupRec.Vendor_Order_Line_Items__r[0].Id) 
	                && trigger.isDelete) {
	                    sObjToDel.add(voliGroupRec);
	            } else if(voliGroupRec.Vendor_Order_Line_Items__r.size() == 2 && trigger.isDelete) {
	                Boolean isNotToBeAddedInList = false;
	                Vendor_Order_Line_Item__c excessRec;
	                for(Vendor_Order_Line_Item__c voliRec : voliGroupRec.Vendor_Order_Line_Items__r) {
	                    if(voliOldMap.containsKey(voliRec.Id) || (!voliOldMap.containsKey(voliRec.Id) && voliRec.Is_Excess__c)) {
	                        isNotToBeAddedInList = false;
	                        if(voliRec.Is_Excess__c) {
	                            excessRec = voliRec;
	                        }
	                    } else {
	                        isNotToBeAddedInList = true;
	                        break;
	                    }
	                }
	                if(!isNotToBeAddedInList) {
	                    sObjToDel.add(voliGroupRec);
	                    sObjToDel.add(excessRec);
	                    
	                    // Update Parts Qty On Order 
                        partIdSet.add(voliGroupRec.Part__c);
	                } else {
	                    excessRec = recalculateNeedOnGroup(new List<Vendor_Order_Line_Item_Group__c> {voliGroupRec});
                        partIdSet.add(voliGroupRec.Part__c);
	                    if(excessRec.Qty_Needed__c != 0) {
	                        voliListToUpsert.add(excessRec);
	                    } else if(excessRec.Qty_Needed__c == 0 && excessRec.Id != null) {
	                        sObjToDel.add(excessRec);
	                    }
	                    sObjToUpdate.add(voliGroupRec);
	                } 
	            } else {
	                Vendor_Order_Line_Item__c excessRec = recalculateNeedOnGroup(new List<Vendor_Order_Line_Item_Group__c> {voliGroupRec});
                    partIdSet.add(voliGroupRec.Part__c);
	                if(excessRec != null) {
	                    if(excessRec.Qty_Needed__c != 0) {
	                        voliListToUpsert.add(excessRec);
	                    } else if(excessRec.Qty_Needed__c == 0 && excessRec.Id != null) {
	                        sObjToDel.add(excessRec);
	                    }
	                }
	                sObjToUpdate.add(voliGroupRec);
	            }
	        }        
	        if(sObjToDel.size() > 0) {
	            shouldTriggerRun = false;
	            delete sObjToDel;
	        }
	        if(voliListToUpsert.size() > 0) {
                DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voliListToUpsert);
	        }
	        if(sObjToUpdate.size() > 0) {
	            Map<Id, sObject> sobjIdToSobjectRecMap = new Map<Id, Sobject>();
	            for(sObject sobj : sObjToUpdate) {
	                sobjIdToSobjectRecMap.put(sobj.Id, sobj);
	            }
	            update sobjIdToSobjectRecMap.values();
	        }
            partIdSet.remove(null);
            PartService.updatePartOnOrderQty(partIdSet);
        }
    }
    
    public static Boolean isUpdateQtyOnSubmittedGroup = false; 
    private static void updateRelatedSubmittedVOLIGroup() {
        if(AccessControl.ifObjectIsDeletable('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(!isUpdateQtyOnSubmittedGroup) {
            return;
        }
        isUpdateQtyOnSubmittedGroup = false;
        Set<Id> voligGroupIdSet = getVOLIGroupIdSet();
        List<Vendor_Order_Line_Item_Group__c> voliGroupList = [select Part__c, Is_Packaged_Part__c, Package_Qty__c, Order_Lots__c, Part__r.Qty_On_Order__c,
                                                                (select Qty_Needed__c, Is_Excess__c, Part__c, Received__c, Is_required_For_Customer__c, CO_Line_Item__c, 
                                                                    CO_Header__c, Is_Service__c, Vendor_Order_Header__c, Vendor_Receiving_Group__c,
                                                                 Vendor_Order_Line_Item_Group__c, Cost__c, Line_Item_Cost__c from Vendor_Order_Line_Items__r WHERE Part__c != null) 
                                                                from Vendor_Order_Line_Item_Group__c where Id IN :voligGroupIdSet AND Part__c != null];
        Set<Id> coLineItemIdSet = new Set<Id>();
        for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
            for(Vendor_Order_Line_Item__c voliRec : voliGroupRec.Vendor_Order_Line_Items__r) {
                if(voliNewMap.containsKey(voliRec.Id)) {
                    coLineItemIdSet.add(voliRec.CO_Line_Item__c);
                }
            }
            if(voliGroupRec.Part__r.Qty_On_Order__c == null) {
                voliGroupRec.Part__r.Qty_On_Order__c = 0;
            }
        }
    
        Map<Id, Boolean> coLineItemIdToHasAdditionalVOLineItemMap = new Map<Id, Boolean>();
        Map<Id, List<Vendor_Order_Line_Item__c>> coLineItemIdToVOLineItemsMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
        if(coLineItemIdSet.size() > 0) {
            List<CO_Line_Item__c> coLineItems = [select Id, (select Qty_Needed__c, Vendor_Order_Line_Item_Group__c, Vendor_Order_Header__c, 
                                                                Vendor_Receiving_Group__c 
                                                                from Vendor_Order_Line_Items__r where Vendor_Receiving_Group__c = null
                                                                order by CreatedDate ASC) 
                                                                from CO_Line_Item__c where Id IN: coLineItemIdSet];
            for(CO_Line_Item__c coliRec : coLineItems) {
                if(coliRec.Vendor_Order_Line_Items__r.size() == 2 && coliRec.Vendor_Order_Line_Items__r[1].Vendor_Order_Line_Item_Group__c == null) {
                    coLineItemIdToHasAdditionalVOLineItemMap.put(coliRec.Id, true);
                } else {
                    coLineItemIdToHasAdditionalVOLineItemMap.put(coliRec.Id, false);
                }
                coLineItemIdToVOLineItemsMap.put(coliRec.Id, coliRec.Vendor_Order_Line_Items__r);
            }                                           
        }
        
        Set<Id> partIdSet = new Set<Id>();
        
        List<sObject> sObjToInsert = new List<sObject>();
        List<sObject> sObjToUpdate = new List<sObject>();
        List<sObject> sObjToDelete = new List<sObject>();
        
        for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
            Vendor_Order_Line_Item__c alreadyExcessRec = new Vendor_Order_Line_Item__c();
            for(Vendor_Order_Line_Item__c voliRec : voliGroupRec.Vendor_Order_Line_Items__r) {
                if(voliRec.Is_Excess__c) {
                    alreadyExcessRec = voliRec;
                }   
            } 
            
            Decimal qtyNeeded = 0;
            for(Vendor_Order_Line_Item__c voliRec : voliGroupRec.Vendor_Order_Line_Items__r) {
                if(voliNewMap.containsKey(voliRec.Id)) {
                    Decimal qtyDifference = (voliOldMap.get(voliRec.Id).Qty_Needed__c - voliNewMap.get(voliRec.Id).Qty_Needed__c);
                    Decimal qtyDifferenceFromUI = -qtyDifference;
                        if(coLineItemIdToHasAdditionalVOLineItemMap.containsKey(voliRec.CO_Line_Item__c) && 
                            coLineItemIdToHasAdditionalVOLineItemMap.get(voliRec.CO_Line_Item__c)) {
                          qtyDifferenceFromUI = -(qtyDifference + coLineItemIdToVOLineItemsMap.get(voliRec.CO_Line_Item__c)[1].Qty_Needed__c);
                    }
                    if(qtyDifferenceFromUI < 0) {
                        if(coLineItemIdToHasAdditionalVOLineItemMap.containsKey(voliRec.CO_Line_Item__c)) {
                            Decimal qtyDifferenceFromUI_Mod = -(qtyDifferenceFromUI);
                            if(coLineItemIdToHasAdditionalVOLineItemMap.get(voliRec.CO_Line_Item__c)) {
                                Vendor_Order_Line_Item__c alreadyBuildAdditionalVOLIRec = coLineItemIdToVOLineItemsMap.get(voliRec.CO_Line_Item__c)[1];
                                if(qtyDifferenceFromUI_Mod < alreadyBuildAdditionalVOLIRec.Qty_Needed__c) {
                                    alreadyBuildAdditionalVOLIRec.Qty_Needed__c = alreadyBuildAdditionalVOLIRec.Qty_Needed__c - qtyDifferenceFromUI_Mod;
                                    sObjToUpdate.add(alreadyBuildAdditionalVOLIRec);
                                    // 
                                    voliRec.Qty_Needed__c = voliRec.Qty_Needed__c + qtyDifference;
                                    sObjToUpdate.add(voliRec);
                                } else if(qtyDifferenceFromUI_Mod == alreadyBuildAdditionalVOLIRec.Qty_Needed__c){
                                    sObjToDelete.add(alreadyBuildAdditionalVOLIRec);
                                    // 
                                    voliRec.Qty_Needed__c = voliRec.Qty_Needed__c + qtyDifference;
                                    sObjToUpdate.add(voliRec);
                                
                                } else {
                                    if(alreadyBuildAdditionalVOLIRec.Qty_Needed__c != null) {
                                        qtyDifferenceFromUI_Mod -= alreadyBuildAdditionalVOLIRec.Qty_Needed__c;
                                        sObjToDelete.add(alreadyBuildAdditionalVOLIRec);
                                    }
                                    if(qtyDifferenceFromUI_Mod > 0) {
                                        if(alreadyExcessRec.Id == null) {
                                            Vendor_Order_Line_Item__c cloneStockVOLIRec = voliRec.clone(false, false, false);
                                            cloneStockVOLIRec.Is_Service__c = false;
                                            cloneStockVOLIRec.Is_required_For_Customer__c = false;
                                            cloneStockVOLIRec.Is_Excess__c = true;
                                            cloneStockVOLIRec.CO_Line_Item__c = null;
                                            cloneStockVOLIRec.CO_Header__c = null;
                                            cloneStockVOLIRec.Received__c = 0;
                                            cloneStockVOLIRec.Qty_Needed__c = qtyDifferenceFromUI_Mod;
                                            sObjToInsert.add(cloneStockVOLIRec);
                                        } else {
                                            alreadyExcessRec.Qty_Needed__c = (alreadyExcessRec.Qty_Needed__c + qtyDifferenceFromUI_Mod);
                                            sObjToUpdate.add(alreadyExcessRec);
                                        }
                                        sObjToUpdate.add(voliRec);
                                    }
                                }
                            } else {
                                if(qtyDifferenceFromUI_Mod > 0) {
                                    if(alreadyExcessRec.Id == null) {
                                        Vendor_Order_Line_Item__c cloneStockVOLIRec = voliRec.clone(false, false, false);
                                        cloneStockVOLIRec.Is_Service__c = false;
                                        cloneStockVOLIRec.Is_required_For_Customer__c = false;
                                        cloneStockVOLIRec.Is_Excess__c = true;
                                        cloneStockVOLIRec.CO_Line_Item__c = null;
                                        cloneStockVOLIRec.CO_Header__c = null;
                                        cloneStockVOLIRec.Received__c = 0;
                                        cloneStockVOLIRec.Qty_Needed__c = qtyDifferenceFromUI_Mod;
                                        sObjToInsert.add(cloneStockVOLIRec);
                                    } else {
                                        alreadyExcessRec.Qty_Needed__c = (alreadyExcessRec.Qty_Needed__c + qtyDifferenceFromUI_Mod);
                                        sObjToUpdate.add(alreadyExcessRec);
                                    }
                                    sObjToUpdate.add(voliRec);
                                }
                            }
                            // Update Part Qty On Order -
                            partIdSet.add(voliRec.Part__c);   
                        }
                    }
                    else if(qtyDifferenceFromUI > 0) {
                        if(coLineItemIdToHasAdditionalVOLineItemMap.containsKey(voliRec.CO_Line_Item__c)) {
                            if(coLineItemIdToHasAdditionalVOLineItemMap.get(voliRec.CO_Line_Item__c)) {
                                Vendor_Order_Line_Item__c alreadyBuildAdditionalVOLIRec = coLineItemIdToVOLineItemsMap.get(voliRec.CO_Line_Item__c)[1];
                                alreadyBuildAdditionalVOLIRec.Qty_Needed__c += qtyDifferenceFromUI;
                                sObjToUpdate.add(alreadyBuildAdditionalVOLIRec);
                            } else {
                                Vendor_Order_Line_Item__c cloneRFCVOLIRec = voliRec.clone(false, false, false);
                                cloneRFCVOLIRec.Vendor_Order_Line_Item_Group__c = null;
                                cloneRFCVOLIRec.Vendor_Receiving_Group__c = null;
                                cloneRFCVOLIRec.Vendor_Order_Header__c = null;
                                cloneRFCVOLIRec.Received__c = 0;
                                cloneRFCVOLIRec.Qty_Needed__c = -(qtyDifference);
                                sObjToInsert.add(cloneRFCVOLIRec);
                            }
                            // Update the Existing Record - Not to be changed.
                            voliRec.Qty_Needed__c = voliRec.Qty_Needed__c + qtyDifference;
                            sObjToUpdate.add(voliRec);
                        }
                    }
                }
            }
        }
        //system.assert(false, sObjToUpdate + ' \n\n ' + sObjToDelete + '\n\n' + sObjToInsert);
        
        if(sObjToInsert.size() > 0) {
            insert sObjToInsert;
        }
        if(sObjToUpdate.size() > 0) {
            update sObjToUpdate;
        }
        
        if(sObjToDelete.size() > 0) {
            delete sObjToDelete;
        }
        partIdSet.remove(null);
        PartService.updatePartOnOrderQty(partIdSet);
    }
    
    
    private static Vendor_Order_Line_Item__c recalculateNeedOnGroup(List <Vendor_Order_Line_Item_Group__c> voliGroupRecList) {
        Vendor_Order_Line_Item_Group__c voliGroupRec;
        if(voliGroupRecList.size() > 0){
            voliGroupRec = voliGroupRecList[0];
        }
        
        Decimal needForVOLineItem = 0;
        Decimal previousExcessNeed = 0;
        Vendor_Order_Line_Item__c excessRec = new Vendor_Order_Line_Item__c();
        for(Vendor_Order_Line_Item__c voliRec : voliGroupRec.Vendor_Order_Line_Items__r) {
            if(trigger.isUpdate || (trigger.isDelete && !voliOldMap.containsKey(voliRec.Id))) {
                if(!voliRec.Is_Excess__c) {
                    needForVOLineItem += voliRec.Qty_Needed__c;
                } else {
                    excessRec = voliRec;
                    previousExcessNeed += voliRec.Qty_Needed__c;
                }
            }
        }
        if(voliGroupRec.Sublet__c != null) {
            voliGroupRec.Need__c = needForVOLineItem;
            return null;
        } else if(voliGroupRec.Part__c != null) {
            //Topping Up In case of Packaged Part or Order Lots
            Decimal need = VendorOrderCtrl.toppingUpNeed(voliGroupRecList, needForVOLineItem, voliGroupRec.Is_Order_As_Individual_Item__c);
            voliGroupRec.Need__c = need;

            if(excessRec.Id == null) {  
                excessRec = new Vendor_Order_Line_Item__c();
                excessRec.Part__c = voliGroupRec.Part__c;
                excessRec.Is_Excess__c = true; 
                excessRec.Vendor_Order_Header__c = voliGroupRec.Vendor_Order_Header__c;
                excessRec.Vendor_Order_Line_Item_Group__c = voliGroupRec.Id;
            } 
            excessRec.Qty_Needed__c = need - needForVOLineItem;
        }
        return excessRec;
    }
}