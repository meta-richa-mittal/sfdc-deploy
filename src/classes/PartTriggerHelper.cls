/**
 * Author: Tarun Khandelwal
 * Since: Nov. 29, 2014
 * Name: PartTriggerHelper
 * Description: Helper class for triggers on Part object
**/
global without sharing class PartTriggerHelper {

    global static Boolean isForceStopTrigger = false;
    // List to store trigger new list
    public static List<Part__c> PartNewList = new List<Part__c>();
    
    // List to store trigger old list
    public static List<Part__c> PartOldList = new List<Part__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Part__c> PartNewMap = new Map<Id, Part__c>();

    // Map to store Old Trigger Map
    public static Map<Id, Part__c> PartOldMap = new Map<Id, Part__c>();
    
    public static Boolean isTriggerExecuted = false;
    public static Boolean isPartFromImport = true;
    public static Boolean isCoToQuoteAction = false;
    
    // Trigger run boolean: QB Integration
    public static Boolean preventOnAccountingSync = false;
    public static Boolean isDisableTriggerForSetQtyAndAvgCostOnFIFOBktAndLIBatch = false;
    public static Boolean isPreventOnDataLoad = false;
    public static Boolean isRunningFromFinalizeCountSessionAction = false;
    private static Integer DEFAULT_INTEXT_PART_INDEX = 5;
    
    private static BaseIntegrationService integrationRec;
    public static List<Price_Level__c> defaultPriceLevel;
    public static Boolean isBulkPartProcess = false;
    
    /**
     * Name: populateDefaults
     * Desc: populates default fields of part
     * @param: 
     * @return: 
    **/
    public static void populateDefaults() {
        setPartIdText();
        
        for(Part__c partRec : partNewList) { // populated old category of part for Accounting purpose: QB Integration
            if(partRec.Id != null && PartOldMap.get(partRec.Id).Category__c != partRec.Category__c && partRec.Total_Cost__c != null && partRec.Total_Cost__c != 0) {
                partRec.Old_Category__c = PartOldMap.get(partRec.Id).Category__c;
            }
            partRec.MSRP__c = (partRec.MSRP__c != null) ? partRec.MSRP__c.setScale(2, RoundingMode.HALF_UP) : null;
            partRec.Retail_Price__c = (partRec.Retail_Price__c != null) ? partRec.Retail_Price__c.setScale(2, RoundingMode.HALF_UP) : null;
            partRec.Sale_Price__c = (partRec.Sale_Price__c != null) ? partRec.Sale_Price__c.setScale(2, RoundingMode.HALF_UP) : null;
        }
        if(!Test.isRunningTest()) {
            populateVendorDefaultForPart();
        }
    }
    
    public static void beforeInsert() {}
    
    public static void beforeUpdate() {
        populateSparseUpdateFields(PartNewList, PartOldMap);
        if(ShopifyUtil.isIntegrationActive && isBulkPartProcess) {  
        populateShopifySyncFlag();
    }
    }
    
    public static void afterUpdate() {
    	AfterUpdateOperation();
        updateKitLineItemsBasedOnPriceLevel();
        if(!(system.isBatch() || System.isFuture())) {
            if(!preventOnAccountingSync){
                preventOnAccountingSync = true;
                setPartDataForAccountSync();
            }
        }
        syncToShopify();
        updateFIFOBucketItems();
    }
    
    private static void populateShopifySyncFlag() {
            List<Website_Product__c> webProductUpdateList = new List<Website_Product__c>();
            String skuMappedTo = Shopify_Configuration__c.getOrgDefaults().Product_Sku_Mapping_Field__c;
            for(Part__c partRec : PartNewList) {
                if(String.isNotBlank(partRec.Shopify_Product__c) && PartOldMap != null && 
                        (PartOldMap.get(partRec.Id).AvailableParts__c != partRec.AvailableParts__c || PartOldMap.get(partRec.Id).Last_Cost__c != partRec.Last_Cost__c || 
                        PartOldMap.get(partRec.Id).Retail_Price__c != partRec.Retail_Price__c || PartOldMap.get(partRec.Id).Sale_Price__c != partRec.Sale_Price__c || 
                        PartOldMap.get(partRec.Id).Description__c != partRec.Description__c || isShopifySkuMappedFieldChanged(partRec, PartOldMap.get(partRec.Id), skuMappedTo))) {
                    partRec.Available_For_Shopify_Sync__c = true;
                }
            }
    }

    private static Boolean isShopifySkuMappedFieldChanged(Part__c newPartRec, Part__c oldPartRec, String skuMappedTo) {
        if(String.isNotBlank(skuMappedTo)) {
            if(skuMappedTo.equalsIgnoreCase('SKU_Number__c') && oldPartRec.SKU_Number__c != newPartRec.SKU_Number__c) {
                return true;
            } else if(skuMappedTo.equalsIgnoreCase('Part_Number__c') && oldPartRec.Part_Number__c != newPartRec.Part_Number__c) {
                return true;
            }
        }
        return false;
    }
    
    private static void syncToShopify() {
    	if(ShopifyUtil.isIntegrationActive && !system.isBatch() && !System.isFuture() && !isBulkPartProcess) {  
    		List<Website_Product__c> webProductUpdateList = new List<Website_Product__c>();
            String skuMappedTo = Shopify_Configuration__c.getOrgDefaults().Product_Sku_Mapping_Field__c;
	    	for(Part__c partRec : PartNewList) {
	    		if(String.isNotBlank(partRec.Shopify_Product__c) && PartOldMap != null && 
	    				(PartOldMap.get(partRec.Id).AvailableParts__c != partRec.AvailableParts__c || PartOldMap.get(partRec.Id).Last_Cost__c != partRec.Last_Cost__c || 
	    				PartOldMap.get(partRec.Id).Retail_Price__c != partRec.Retail_Price__c || PartOldMap.get(partRec.Id).Sale_Price__c != partRec.Sale_Price__c || 
	    				PartOldMap.get(partRec.Id).Description__c != partRec.Description__c || isShopifySkuMappedFieldChanged(partRec, PartOldMap.get(partRec.Id), skuMappedTo))) {
	    			webProductUpdateList.add(new Website_Product__c(Id = partRec.Shopify_Product__c, Status__c = WebsiteProductManagementUtil.STATUS_SYNCING));
	    		}
	        }
	        DMLUtility.updateSobjectList('Website_Product__c', webProductUpdateList);
	    	if(webProductUpdateList.size() > 0) {
                system.enqueueJob(new ShopifySyncWebsiteProductQueueable(webProductUpdateList));
	    	}
    	}
    }
    
    private static void setPartIdText() {
        for(Part__c part : PartNewList) {
            part.Part_Id_Text__c = part.Part_Number__c + Part.Vendor_Code__c;
        }
    }
    
    public static void setIntextDefaultPartIndex() {
	    for(Part__c partRec : PartNewList) {
	    	if(partRec.Publish_In_Feeds__c && PartOldMap.get(partRec.Id).Publish_In_Feeds__c != partRec.Publish_In_Feeds__c && partRec.Intext_Part_Index__c == null) {
	    		partRec.Intext_Part_Index__c = DEFAULT_INTEXT_PART_INDEX;
	    	}
	    }
    }
    	
    public static void setSOMDefaultPartIndex() {
        if(String.isNotBlank(SOM_Configuration__c.getOrgDefaults().Org_Code__c)) {
            for(Part__c partRec : PartNewList) {
                    partRec.Part_Index__c = DEFAULT_INTEXT_PART_INDEX;
            }
    	}
    }
    
    private static List<Category__c> getDefaultPartCategoryList() {
        return [SELECT Id FROM Category__c WHERE Type__c = 'Part' AND Default__c = true];
    }
    
    public static void populateVendorDefaultForPart() {
        Set<Id> vendorIdSet = new Set<Id>();
        for(Part__c partRec : partNewList) {
            if(String.isBlank(partRec.Part_Type__c) || partRec.Category__c == null) {
                vendorIdSet.add(partRec.Vendor__c);
            }
        }
        if(vendorIdSet.size() == 0) {
            return;
        }
        
        Map<Id, Account> vendorMap = new Map<Id, Account>([SELECT Part_Purchases__c, Merchandise_Purchases__c, Merchandise_Category_Default__c, 
                                            Part_Category_Default__c FROM Account WHERE Id IN: vendorIdSet]);
        List<Category__c> defaultPartCategoryList;
        for(Part__c partRec : partNewList) {
            if(vendorMap.containsKey(partRec.Vendor__c)) {
                Account vendor = vendorMap.get(partRec.Vendor__c);
                if(String.isBlank(partRec.Part_Type__c)) {
                    partRec.Part_Type__c = (vendor.Part_Purchases__c ? 'Part' : (vendor.Merchandise_Purchases__c ? 'Merchandise' : 'Part') );
                }
                
                if(partRec.Category__c == null) {
                    if(vendor.Part_Purchases__c || vendor.Merchandise_Purchases__c) {
                        partRec.Category__c = (partRec.Part_Type__c == 'Part' ? vendor.Part_Category_Default__c : vendor.Merchandise_Category_Default__c);
                    }
                    if(partRec.Category__c == null) {
                        if(defaultPartCategoryList == null) {
                            defaultPartCategoryList = getDefaultPartCategoryList();
                        }
                        partRec.Category__c = (defaultPartCategoryList.size() > 0 ? defaultPartCategoryList[0].Id : vendor.Part_Category_Default__c);
                    }
                }
            }
        }
    }
    
    /**
     * Name: AfterInsertOperation
     * Desc: When Part record is inserted this method executes 
     * @param: 
     * @return: 
    **/
    public static void AfterInsertOperation() {
        if(!isTriggerExecuted) {
            AfterUpdateOperation();
            isTriggerExecuted = true;
        }
        // Create bucket for the parts after insert.
        if(isPartFromImport){
            FIFOTransaction.createFIFOBucketForPartImport(PartNewList);
        }        
    }
    
    public static void updateFIFOBucketItems() {
    	if(!isRunningFromFinalizeCountSessionAction && GeneralConfiguration.getIsDataLoadFlag() && !isTriggerExecuted) {
    		isTriggerExecuted = true;
    		Map<Id, PartFIFOAdjustmentService.PartCountAjustmentWrapper> partIdToCountAdjustmentWrapperMap = new Map<Id, PartFIFOAdjustmentService.PartCountAjustmentWrapper>();
    		for(Part__c partRec : PartNewList) {
    			if(PartOldMap.get(partRec.Id).Qty_In_Stock__c != partRec.Qty_In_Stock__c) {
    				partIdToCountAdjustmentWrapperMap.put(partRec.Id, new PartFIFOAdjustmentService.PartCountAjustmentWrapper(partRec.Id, PartOldMap.get(partRec.Id).Qty_In_Stock__c, PartOldMap.get(partRec.Id).Last_Cost__c));
    			}
    		}
    		PartFIFOAdjustmentService.adjustPartQty(partIdToCountAdjustmentWrapperMap);
    	}
    }
    
    /**
     * Name: PartUpdateOperation
     * Desc: When Part record is updated this method executes 
     * @param: 
     * @return: 
    **/
    public static void AfterUpdateOperation() {
        // Entry Condition for Trigger
        List<Part__c> partListToCalculateNeed = new List<Part__c>();
        if(Trigger.isInsert) {
        	partListToCalculateNeed = PartNewList;
        } else if(Trigger.isUpdate) {
	        for(Part__c partRec : PartNewList) {
	            if(PartNewMap.get(partRec.Id).AvailableParts__c != PartOldMap.get(partRec.Id).AvailableParts__c 
	                    || PartNewMap.get(partRec.Id).Auto_reorder_Min__c != PartOldMap.get(partRec.Id).Auto_reorder_Min__c 
	                    || PartNewMap.get(partRec.Id).Auto_reorder_Max__c != PartOldMap.get(partRec.Id).Auto_reorder_Max__c 
	                    || PartNewMap.get(partRec.Id).Qty_On_Order__c != PartOldMap.get(partRec.Id).Qty_On_Order__c)  {
	                partListToCalculateNeed.add(partRec);
	            } 
	        }
        }

        // If Not Valid Entry Condition, return from trigger
        if(partListToCalculateNeed.size() == 0) {
            return;
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Vendor_Order_Line_Item__c> voLineItemsToUpsert = new List<Vendor_Order_Line_Item__c>();
        List<Vendor_Order_Line_Item__c> voLineItemsToDelete = new List<Vendor_Order_Line_Item__c>();
        // #Changes 03/06
        List<Vendor_Order_Line_Item__c> existingVOLineItemList = [select Id, part__c, Qty_Needed__c, Received__c, Vendor_Order_Line_Item_Group__c,Vendor_Order_Header__c,Vendor_Order_Header__r.Status__c from 
                                                                 Vendor_Order_Line_Item__c where Part__c IN : partListToCalculateNeed AND Is_required_For_Customer__c = false AND Is_Service__c = false AND Is_Excess__c = false 
                                                                 AND Is_From_Search__c = false AND (Vendor_Order_Header__c= null OR Vendor_Order_Header__r.Status__c ='Open' OR Vendor_Order_Header__r.Status__c ='Locked') AND Vendor_Order_Line_Item_Group__c = null];
        system.debug('####'+existingVOLineItemList);                                                                                                                    
        
        // Map to check if there is already VOLineItem is present for same part.
        Map<Id, Vendor_Order_Line_Item__c> partIdToVOLineItemRecMap = new Map<Id, Vendor_Order_Line_Item__c>();
        for(Vendor_Order_Line_Item__c voLineItemRec : existingVOLineItemList) {
            voLineItemRec.Received__c = (voLineItemRec.Received__c == null) ? 0 : voLineItemRec.Received__c;
            if(voLineItemRec.Qty_Needed__c > voLineItemRec.Received__c) {
                if(!partIdToVOLineItemRecMap.containsKey(voLineItemRec.Part__c)) {
                    partIdToVOLineItemRecMap.put(voLineItemRec.Part__c, voLineItemRec);
                } else {
                    voLineItemsToDelete.add(voLineItemRec);
                }
            } 
        }
        
        for(Part__c partRec : partListToCalculateNeed) {
            Decimal need = 0;
            need = toppingUpCalculationWithoutPackage(partRec);
            if((partRec.AvailableParts__c + partRec.Qty_On_Order__c) <= partRec.Auto_reorder_Min__c && partRec.Auto_reorder_Min__c <= partRec.Auto_reorder_Max__c 
               && partRec.Auto_reorder_Max__c > 0 && need > 0){
                   
                Vendor_Order_Line_Item__c voLineItemRec = new Vendor_Order_Line_Item__c();
                if(partIdToVOLineItemRecMap.containsKey(partRec.Id) && partIdToVOLineItemRecMap.get(partRec.Id).Vendor_Order_Line_Item_Group__c == null ) {
                    voLineItemRec.Id =  partIdToVOLineItemRecMap.get(partRec.Id).Id;
                    voLineItemRec.Qty_Needed__c = need; 
                    voLineItemRec.Line_Item_Cost__c = partRec.Calculated_Cost__c;
                    voLineItemsToUpsert.add(voLineItemRec);
                } else {
                    voLineItemRec.Qty_Needed__c = need;
                    voLineItemRec.Part__c = partRec.Id;
                    voLineItemRec.Line_Item_Cost__c = partRec.Calculated_Cost__c;
                    voLineItemRec.Is_required_For_Customer__c = false;
                    voLineItemsToUpsert.add(voLineItemRec);
                }
            } else if((partRec.AvailableParts__c + partRec.Qty_On_Order__c) > partRec.Auto_reorder_Min__c || (partRec.Auto_reorder_Min__c == partRec.Auto_reorder_Max__c)) {
                if(partIdToVOLineItemRecMap.containsKey(partRec.Id)) {
                    Vendor_Order_Line_Item__c voLineItemRec = partIdToVOLineItemRecMap.get(partRec.Id);
                    if(voLineItemRec.Vendor_Order_Line_Item_Group__c == null) {
                        voLineItemsToDelete.add(voLineItemRec);
                    }
                }
            }
        }
        
        if(voLineItemsToUpsert.size() > 0 ){
            DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voLineItemsToUpsert);
        }
        if(voLineItemsToDelete.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete voLineItemsToDelete;
        }
    }
    
    /**
     * Name: toppingUpCalculationWithoutPackage
     * Desc: Topping Up Calculation in case of packaged Part.
     * @param: 
     * @return: 
    **/
    private static Decimal toppingUpCalculationWithoutPackage(Part__c partRec) {
        Decimal need = 0;
        need = partRec.Auto_reorder_Max__c - (partRec.AvailableParts__c + partRec.Qty_On_Order__c); 
        return need;
    }
    /**
     * Name: toppingUpCalculation
     * Desc: Topping Up Calculation in case of packaged Part.
     * @param: 
     * @return: 
    **/
    private static Decimal toppingUpCalculation(Part__c partRec) {
        Decimal need = 0;
        need = partRec.Auto_reorder_Max__c - (partRec.AvailableParts__c + partRec.Qty_On_Order__c); 
        
        if(partRec.Packaged_Part__c) {
            Long packagedPartInNeed = (need / partRec.Package_Qty__c).longValue();
            if(packagedPartInNeed * partRec.Package_Qty__c < need) {
                packagedPartInNeed += 1;
            }
            need = packagedPartInNeed * partRec.Package_Qty__c;
        }
        
        if(partRec.Order_Lots__c > 1) {
            Long orderLotPartInNeed = (need / partRec.Order_Lots__c).longValue();
            if(orderLotPartInNeed * partRec.Order_Lots__c < need) {
                orderLotPartInNeed += 1;
            }
            need = orderLotPartInNeed * partRec.Order_Lots__c;
        }
        return need;
    }
    
    /**
     * Name: updateKitLineItems
     * Desc: Update Kit Line Item if Retail Price of Part is changed.
     * @param: 
     * @return: 
    **/
    public static void updateKitLineItems() {
        if(system.isBatch()) {
            return;
        }
        List<Id> partIdList = new List<Id>();
        for(Part__c partRec : PartNewList) {
            if(PartNewMap.get(partRec.Id).Retail_Price__c != PartOldMap.get(partRec.Id).Retail_Price__c) {
                partIdList.add(partRec.Id);
            }
        }
        //system.assert(false, partIdList);
        if(partIdList.size() > 0) {
            KitLineItemtriggerHelper.updateRetailofKitLineItems('Part__c', partIdList);
        }
    }

    public static void updateKitLineItemsBasedOnPriceLevel() {
        Set<String> partIdSet = new Set<String>();
        List<Kit_Header_Line_Item__c> kitLineItemList;
        try {
            String partPriceBaseAPIValue = '';
            for(Part__c partRec : PartNewList) {
                if(partRec.Retail_Price__c != PartOldMap.get(partRec.Id).Retail_Price__c  || partRec.MSRP__c != PartOldMap.get(partRec.Id).MSRP__c ||
                    partRec.Last_Cost__c != PartOldMap.get(partRec.Id).Last_Cost__c || partRec.Average_Cost__c != PartOldMap.get(partRec.Id).Average_Cost__c) {
                    if(defaultPriceLevel == null || defaultPriceLevel.size() == 0) { 
                        defaultPriceLevel = PriceLevelService.getDefaultPriceLevel();
                    }
                    
                    if(String.isBlank(partPriceBaseAPIValue)) {
                        String priceLevel_baseValue = (defaultPriceLevel.size() > 0) ? defaultPriceLevel[0].Part_Price_Base__c : '';
                        if(PriceLevelService.priceLevelFieldToPartFieldAPINameMap.containsKey(priceLevel_baseValue)) {
                            partPriceBaseAPIValue = PriceLevelService.priceLevelFieldToPartFieldAPINameMap.get(priceLevel_baseValue);
                        }
                    }
                   
                    if(String.isNotBlank(partPriceBaseAPIValue) && partRec.get(partPriceBaseAPIValue) != PartOldMap.get(partRec.Id).get(partPriceBaseAPIValue)) {
                        partIdSet.add(partRec.Id);
                    }
                }
            }
            
            if(partIdSet.size() > 0) {
                kitLineItemList = [SELECT Fixed_Price__c, Is_Environmental_Fee__c, Kit_Header__c, Kit_Price__c, Labour_Code__c, Part__c, Retail__c, Fee__c, Retail_Price__c FROM Kit_Header_Line_Item__c WHERE Part__c IN :partIdSet];

                if(kitLineItemList.size() > 0) {
                    if(!System.isBatch() && !System.isQueueable() && !System.isFuture()) {
                		system.enqueueJob(new UpdateKitLineItemRetailPriceQueueable(partIdSet)); 
                	} else {
                		KitLineItemtriggerHelper.setRetailPriceBasedOnDefaultPriceLevel(kitLineItemList);
                        update kitLineItemList;
                	}
                }
            }
        } catch(AsyncException asyncExcep) {
            if(asyncExcep.getMessage().contains('Database.executeBatch cannot be called from a batch start, batch execute, or future method')) {
                try {
                    if(kitLineItemList == null && partIdSet.size() > 0) {
                        kitLineItemList = [SELECT Fixed_Price__c, Is_Environmental_Fee__c, Kit_Header__c, Kit_Price__c, Labour_Code__c, Part__c, Retail__c, Fee__c, Retail_Price__c FROM Kit_Header_Line_Item__c WHERE Part__c IN :partIdSet];
                    }
                    if(kitLineItemList.size() > 0) {
                        KitLineItemtriggerHelper.setRetailPriceBasedOnDefaultPriceLevel(kitLineItemList);
                        update kitLineItemList;
                    }
                } catch(Exception e) { 
                    system.debug('Exception  ::::  ' + e);
                }
            } 
        }    
    }
    
    public static void populatesAccountingSyncFields() {
        IntegrationSyncFlagService.managePartCategorySyncFlag(PartNewList, PartOldMap);
    }
    
    public static void setPartDataForAccountSync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(PartNewList, IntegrationUtility.PART_CATEGORY);
    }

    public static void validatePartDeletion() {
        Map<String, Part__c> partIdToRecMap = new Map<String, Part__c>([Select Id, 
											        					(SELECT Part__c FROM CO_Line_Items__r LIMIT 1), 
											        					(SELECT Part__c FROM Service_Order_Line_Items__r LIMIT 1),
											                            (SELECT Part__c FROM Vendor_Order_Line_Items__r LIMIT 1), 
											                            (SELECT Part__c FROM Vendor_Order_Line_Item_Groups__r LIMIT 1),
											                            (SELECT Part__c FROM Return_VO_Line_Items__r LIMIT 1), 
											                            (SELECT Part__c FROM Count_Session_Line_Items__r LIMIT 1),
											                            (SELECT Part__c FROM Kit_Header_Line_Items__r LIMIT 1),
											                            (SELECT Part__c FROM Options_Fees__r LIMIT 1), 
											                            (SELECT Part__c FROM Vendor_Receiving_Group_Parts__r LIMIT 1), 
											                            (SELECT Part__c FROM Part_Aging_Details__r) 
											                             FROM Part__c WHERE Id IN: PartOldList]);
                             
		for(Part__c partToDelete : PartOldList) {
			Part__c partRec = partIdToRecMap.get(partToDelete.Id);
			if(partRec.CO_Line_Items__r.size() > 0 || partRec.Service_Order_Line_Items__r.size() > 0 || partRec.Vendor_Order_Line_Items__r.size() > 0 
				  || partRec.Vendor_Order_Line_Item_Groups__r.size() > 0 || partRec.Return_VO_Line_Items__r.size() > 0 || partRec.Count_Session_Line_Items__r.size() > 0
				  || partRec.Kit_Header_Line_Items__r.size() > 0 || partRec.Options_Fees__r.size() > 0 || partRec.Vendor_Receiving_Group_Parts__r.size() > 0) {
		  		partToDelete.addError('Cannot delete part as it have linked sales/purchase transactions.');
		    } else if (!partRec.Part_Aging_Details__r.isEmpty()) {
                DMLUtility.deleteSobjectList('Part_Aging_Detail__c', partRec.Part_Aging_Details__r);
		    }
		}	
    }
    
    public static void populateSparseUpdateFields(List<Part__c> newList, Map<Id, Part__c> oldMap) {
        List<String> fieldAPINameList = new List<String>{'AvailableParts__c', 'Description__c', 'SKU_Number__c', 'Part_Number__c'};
        for(Part__c part : newList) {
            if(part.Shopify_Product_Id__c != null) {
                BPUtility.updateSparseFieldForRecord(part, oldMap.get(part.Id), 'Shopify_Sparse_Update_Fields__c', fieldAPINameList);
            }
            part.Last_Cost__c = part.Last_Cost__c != null ? part.Last_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
        }
    }

    public static void setLastPriceUpdate(List<Part__c> newList, Map<Id, Part__c> oldMap) {
        for(Part__c partRec : newList) {
            Part__c oldRec = oldMap.get(partRec.Id);
            Decimal oldMSRP = oldRec.MSRP__c != null ? oldRec.MSRP__c : 0;
            Decimal newMSRP = partRec.MSRP__c != null ? partRec.MSRP__c : 0;
            Decimal oldRetailPrice = oldRec.Retail_Price__c != null ? oldRec.Retail_Price__c : 0;
            Decimal newRetailPrice = partRec.Retail_Price__c != null ? partRec.Retail_Price__c : 0;
            Decimal oldSalePrice = oldRec.Sale_Price__c != null ? oldRec.Sale_Price__c : 0;
            Decimal newSalePrice = partRec.Sale_Price__c != null ? partRec.Sale_Price__c : 0;
            
            if(newMSRP != oldMSRP || newRetailPrice != oldRetailPrice || newSalePrice != oldSalePrice) {
                partRec.Last_Price_Update__c = system.now();
            }
        }
    }

    public static void convertAmountToDecimal(List<Part__c> newList) {
		for(Part__c partRec : newList) {
			partRec.Last_Cost__c = partRec.Last_Cost__c != null ? partRec.Last_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
        }
	}
}