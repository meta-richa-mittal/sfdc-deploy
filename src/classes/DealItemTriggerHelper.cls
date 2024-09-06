public without sharing class DealItemTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
     // List to store trigger new list
    public static List<Deal_Item__c> dealItemNewList = new List<Deal_Item__c>();
    
    // List to store trigger old list
    public static List<Deal_Item__c> dealItemOldList = new List<Deal_Item__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Deal_Item__c> dealItemNewMap = new Map<Id, Deal_Item__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Deal_Item__c> dealItemOldMap = new Map<Id, Deal_Item__c>();
    
    public static Set<String> dealIdSet = new Set<String>();
    
    // Accounting boolean
    public static Boolean preventOnAccountingSync = false;
    public static Boolean isTriggerExecute = true;
    public static Boolean isCustomerPLUpdate = false;
    public static Boolean isRecaclTaxesOnFeesAndNonSubletProducts = false;
    
    private static BaseIntegrationService integrationRec;
    
    public static void onBeforeUpdate() {
        populatesAccountingSyncFields();
    }
    
    public static void populatesAccountingSyncFields() {
        IntegrationSyncFlagService.manageDealItemSyncFlag( dealItemNewList, dealItemOldMap);
    }
    
    public static void setDealItemDataForAccountSync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(dealItemNewList, IntegrationUtility.STOCK_TRADE_IN);
    }
    
    public static void beforeInsertOperations(){
        updateDealItemName(dealItemNewList);
    }
    
    public static void afterInsertOperations() {
        salesTaxCalculation(dealItemNewList);
        updateTotalOnDeal(dealItemNewList);
    }
    
    public static void afterUpdateOperations() {
        if(!isTriggerExecute) {
            return;
        }
        isTriggerExecute = false;
        recalculateTaxOnRelatedItems(dealItemNewList, dealItemOldMap);
        
        if((isCustomerPLUpdate && (COTriggerHelper.isRecalculateTaxes != null && COTriggerHelper.isRecalculateTaxes)) || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
            salesTaxCalculation(dealItemNewList);
        }
        updateTotalOnDeal(dealItemNewList);
    }
    
    public static void beforeDeleteOperation() {
        deleteRelatedChildRecords();
    }
    
    public static void afterDeleteOperation() {
        updateDealItemName(dealItemOldList);
        updateTotalOnDeal(dealItemOldList);
    }
    
    public static void recalculateTaxOnRelatedItems(List<Deal_Item__c> dealItemNewList, Map<Id, Deal_Item__c> dealItemOldMap) {
        Set<Id> unitTypeDealItemIdSet = new Set<Id>();
        Set<Id> tradeInTypeDealItemIdSet = new Set<Id>();
        Set<String> entitiesToRecalculatePriceSet = new Set<String>();
        for(Deal_Item__c dealItemRec : dealItemNewList) {
            if(dealItemRec.Taxable__c != dealItemOldMap.get(dealItemRec.Id).Taxable__c || 
                dealItemRec.Applicable_Tax__c != dealItemOldMap.get(dealItemRec.Id).Applicable_Tax__c || 
                dealItemRec.Unit_Tax_Applicable_On__c != dealItemOldMap.get(dealItemRec.Id).Unit_Tax_Applicable_On__c) {
                if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                    tradeInTypeDealItemIdSet.add(dealItemRec.Id);
                } else if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT){
                    unitTypeDealItemIdSet.add(dealItemRec.Id);
                }
                if(dealItemRec.Unit_Tax_Applicable_On__c != dealItemOldMap.get(dealItemRec.Id).Unit_Tax_Applicable_On__c || 
                    dealItemRec.Taxable__c != dealItemOldMap.get(dealItemRec.Id).Taxable__c || 
                    (dealItemRec.Taxable__c && dealItemRec.Applicable_Tax__c != dealItemOldMap.get(dealItemRec.Id).Applicable_Tax__c)
                ) {
                    if(dealItemOldMap.get(dealItemRec.Id).Unit_Tax_Applicable_On__c != null) {
                        entitiesToRecalculatePriceSet.addAll(dealItemOldMap.get(dealItemRec.Id).Unit_Tax_Applicable_On__c.split(DealUtil.delimitor));
                    }
                    if(dealItemRec.Unit_Tax_Applicable_On__c != null) {
                        entitiesToRecalculatePriceSet.addAll(dealItemRec.Unit_Tax_Applicable_On__c.split(DealUtil.delimitor));
                    }
                }
            }
        }
        
        if(!unitTypeDealItemIdSet.isEmpty()) {
            if(AccessControl.ifObjectFieldIsAccessible('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = [SELECT Id from Deal_Unit_Price_Cost__c WHERE Deal_Item__c IN: unitTypeDealItemIdSet];
            
            // Deal Unit Price and Cost
            // This variable needs to set true before execution of trigger
            DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate = true; 
            DealUnitPriceAndCostTriggerHelper.salesTaxCalculation(dealUnitPriceAndCostList);
            
            // Again Resetting flag so that there will no conflict.
            DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate = false; 
            
            // Option and Fee
            List<Option_Fee__c> optionAndFeeList = getOptionAndFeesToRecalculatePrices(unitTypeDealItemIdSet, entitiesToRecalculatePriceSet);
            
            Map<Id, Option_Fee__c> optionAndFeeWithoutDealKitIdToRecordMap = new Map<Id, Option_Fee__c>();
            Map<String, String> dealItemWithKitIdToCustomerIdMap = new Map<String, String>();
            for(Option_Fee__c optionAndFee: optionAndFeeList) {
            	if(optionAndFee.Deal_Kit_Header__c != null) {
            		if(!dealItemWithKitIdToCustomerIdMap.containsKey(optionAndFee.Deal_Item__c)) {
            			dealItemWithKitIdToCustomerIdMap.put(optionAndFee.Deal_Item__c, optionAndFee.Deal__r.CO_Header__r.Customer__c);
            		}
            	} else {
            		if(!optionAndFeeWithoutDealKitIdToRecordMap.containsKey(optionAndFee.Id)) {
            			optionAndFeeWithoutDealKitIdToRecordMap.put(optionAndFee.Id, optionAndFee);
            		}
            	}
            }
            if(optionAndFeeWithoutDealKitIdToRecordMap.size() > 0) {
            	OptionAndFeeTriggerHelper.isCustomerPLUpdate = true;
            	OptionAndFeeTriggerHelper.OptionAndFeeNewMap = optionAndFeeWithoutDealKitIdToRecordMap;
            	OptionAndFeeTriggerHelper.salesTaxCalculation(optionAndFeeWithoutDealKitIdToRecordMap.values());
            	OptionAndFeeTriggerHelper.isCustomerPLUpdate = false;
            }
            for(String dealItemId: dealItemWithKitIdToCustomerIdMap.keyset()) {
            	List<Deal_Kit_Header__c> dealKHList = SOQLUtil.getDealKitHeaderDetailsByFieldName(new Map<String, String>{'Deal_Item__c'=> dealItemId});
            	dealKHList = DealKH_Recalculation.applySalesTax(dealKHList, dealItemWithKitIdToCustomerIdMap.get(dealItemId));
		        List<Sobject> sobjListToUpdate = new List<Sobject>(); 
		        if(dealKHList.size() > 0) {
		            sobjListToUpdate.addAll((List<Sobject>)dealKHList);
		            for(Deal_Kit_Header__c dealKHRec : dealKHList) {
		                if(dealKHRec.Options_Fees__r != null) {
		                    sobjListToUpdate.addAll((List<Sobject>)dealKHRec.Options_Fees__r);
		                }
		            }
		            update sobjListToUpdate;
		        }
            }
        
        } else if(!isCustomerPLUpdate) {
            salesTaxCalculation(dealItemNewList);   
        }
    }

    private static List<Option_Fee__c> getOptionAndFeesToRecalculatePrices(Set<Id> unitTypeDealItemIdSet, Set<String> entitiesToRecalculatePriceSet) {
        List<Option_Fee__c> optionAndFeesList = new List<Option_Fee__c>();
        if(unitTypeDealItemIdSet != null && !unitTypeDealItemIdSet.isEmpty() && entitiesToRecalculatePriceSet != null && !entitiesToRecalculatePriceSet.isEmpty()) {
            String query = 'SELECT Id, Price__c, Deal_Kit_Header__c, Deal_Item__c, Deal__r.CO_Header__r.Customer__c, Applicable_Tax__c from Option_Fee__c WHERE Deal_Item__c IN: unitTypeDealItemIdSet AND (';
            if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_PARTS)) query += ' Part__c != null OR';
            if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_LABOR)) query += ' Labour_Code__c != null OR';
            if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_SUBLET)) query += ' (Product__c != null AND Product__r.Type__c = \'Sublet\') OR';
            if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_FEES)) query += ' Fee__c != null OR';
            if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_WARRANTY_PRODUCTS)) query += ' (Product__c != null AND Product__r.Type__c = \'Warranty Plan\') OR';
            if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_OTHER_PRODUCTS)) query += ' (Product__c != null AND Product__r.Type__c NOT IN (\'Sublet\',\'Warranty Plan\')) OR';
        
            query = (query.substringBeforeLast(' OR') + ')');
            optionAndFeesList = Database.query(query);
        }
        return optionAndFeesList;
    }
    
    public static void updateTotalOnDeal(List<Deal_Item__c> dealItemList) {
        Set<String> dealIdSet = new Set<String>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            dealIdSet.add(dealItemRec.Deal__c);
        }
        
        if(!COTriggerHelper.isRecalculateCOPLAndTax) {
        	OptionAndFeeTriggerHelper.updateDealTotal(dealIdSet);
    	}
    }
    
    public static void deleteRelatedChildRecords() {
        Set<String> dealItemIdSet = new Set<String>();
        for(Deal_Item__c dealItemRec : dealItemOldList) {
            dealItemIdSet.add(dealItemRec.Id);
        }
        List<Deal_Item__c> dealItemList = [Select Id, (Select Id from Options_Fees__r), (Select Id from Deal_Unit_Prices_Costs__r) from Deal_Item__c where Id IN :dealItemIdSet AND Type__c = :Constants.DEAL_ITEM_TYPE_UNIT ORDER BY CreatedDate ASC];
        
        List<SObject> sObjectListToDelete = new List<SObject>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            sObjectListToDelete.addAll((List<SObject>) dealItemList[0].Options_Fees__r);
            sObjectListToDelete.addAll((List<SObject>) dealItemList[0].Deal_Unit_Prices_Costs__r);
        }
        
        if(AccessControl.ifObjectIsDeletable('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete sObjectListToDelete;
    }
    
    public static void updateDealItemName(List<Deal_Item__c> dealItemList) {
        for(Deal_Item__c dealItemRec : dealItemList) {
            dealIdSet.add(dealItemRec.Deal__c);
        }
        List<Deal__c> dealList = [Select Id, (Select Id, Name__c from Deal_Items__r where Type__c = :Constants.DEAL_ITEM_TYPE_UNIT ORDER BY CreatedDate ASC) from Deal__c where Id In :dealIdSet];
        Map<Id, Integer> dealIdToDealItemCounter = new Map<Id, Integer>();
        for(Deal__c dealRec : dealList) {
            dealIdToDealItemCounter.put(dealRec.Id, (dealRec.Deal_Items__r).size());
        }
        
        if(trigger.isInsert) {
            for(Deal_Item__c dealItemRec : dealItemList) {
                Integer counter = dealIdToDealItemCounter.get(dealItemRec.Deal__c);
                dealIdToDealItemCounter.put(dealItemRec.Deal__c, ++counter);
                dealItemRec.Name__c = 'Unit' + dealIdToDealItemCounter.get(dealItemRec.Deal__c); 
            }
            
        } else if(trigger.isDelete) {
            Integer counter = 0;
            List<Deal_Item__c> dealItemListToUpdate = new List<Deal_Item__c>();
            for(Deal__c dealRec : dealList) {
                counter = 1;
                for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
                    dealItemRec.Name__c = 'Unit' + counter++;
                    dealItemListToUpdate.add(dealItemRec);
                }
            }
            
            DMLUtility.updateSobjectList('Deal_Item__c', dealItemListToUpdate);
        }
    }
    
    public static void salesTaxCalculation(List<Deal_Item__c> dealItemNewList) {
        List<Deal_Item__c> dealItemList = [SELECT Agreed_Value__c, Deal__r.Is_Tax_Based_On_Customer_Address__c, Type__c, Is_Stocked_In__c, Default_Unit_Sales_Tax_Percentage__c, Deal__r.CO_Header__r.Customer__c,
                                                    Applicable_Tax__c, Taxable__c, (SELECT Id FROM Individual_Taxes__r)
                                                    FROM Deal_Item__c where Id IN: dealItemNewList AND Type__c = :Constants.DEAL_ITEM_TYPE_TRADE_IN AND Deal__r.Invoice_Number__c = null];
        
        TaxEngine.applySalesTaxonDealItemList(dealItemList);
    }
}