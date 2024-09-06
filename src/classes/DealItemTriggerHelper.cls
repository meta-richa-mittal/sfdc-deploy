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
    
    private static BaseIntegrationService integrationRec;
    
    public static void onBeforeUpdate() {
        populatesAccountingSyncFields();
    }
    
    public static void populatesAccountingSyncFields() {
        if(QBUtil.isQBEnabled()) {
            QBSyncFlagService.manageDealItemSyncFlag(dealItemNewList, dealItemOldMap);
        } else {
            integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
            if(integrationRec != null) {
                IntegrationSyncFlagService.manageDealItemSyncFlag(new List<BaseIntegrationService>{integrationRec}, dealItemNewList, dealItemOldMap);
            }
        }
    }
    
    public static void setDealItemDataForAccountSync() {
        Set<Id> dealItemIdSet = new Set<Id>();
        for(Deal_Item__c dealItemRec : dealItemNewList) {
            if(dealItemRec.Avail_For_QB_Sync__c)    {
                dealItemIdSet.add(dealItemRec.Id);
            } else if(integrationRec != null) {
                if(dealItemRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.STOCK_TRADE_IN).Sync_Flag_API_Name__c) != null && 
                    Boolean.valueOf(dealItemRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.STOCK_TRADE_IN).Sync_Flag_API_Name__c))) {
                    dealItemIdSet.add(dealItemRec.Id);
                }
            }
        }
        if(dealItemIdSet.size() > 0) {
            if(QBUtil.isQBEnabled()) {
                DealItemService.syncDealItems(dealItemIdSet);
            } else {
                IntegrationBatchService.initiateBatch(dealItemIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.STOCK_TRADE_IN);
            }
        }
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
        
        if(isCustomerPLUpdate || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
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
        for(Deal_Item__c dealItemRec : dealItemNewList) {
            if(dealItemRec.Taxable__c != dealItemOldMap.get(dealItemRec.Id).Taxable__c || 
                dealItemRec.Applicable_Tax__c != dealItemOldMap.get(dealItemRec.Id).Applicable_Tax__c) {
                if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                    tradeInTypeDealItemIdSet.add(dealItemRec.Id);
                } else if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT){
                    unitTypeDealItemIdSet.add(dealItemRec.Id);
                }
            }
        }
        
        if(unitTypeDealItemIdSet.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = [SELECT Id from Deal_Unit_Price_Cost__c WHERE Deal_Item__c IN: unitTypeDealItemIdSet];
            
            // Deal Unit Price and Cost
            // This variable needs to set true before execution of trigger
            DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate = true; 
            DealUnitPriceAndCostTriggerHelper.salesTaxCalculation(dealUnitPriceAndCostList);
            
            // Again Resetting flag so that there will no conflict.
            DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate = false; 
            
            // Option and Fee
            List<Option_Fee__c> optionAndFeeList = [SELECT Id, Price__c, Deal_Kit_Header__c, Deal_Item__c, Deal__r.CO_Header__r.Customer__c from Option_Fee__c WHERE (Deal_Item__c IN: unitTypeDealItemIdSet AND 
            											(Part__c != null OR Labour_Code__c != null OR 
            											(Product__c != null AND Product__r.Type__c = 'Sublet')
            											))];
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
        Set<String> dealIdSet = new Set<String>();
        Map<String, Boolean> dealItemIdToResetACVMap = new Map<String, Boolean>();
        // Check - Actual_Cash_Value__c
        for(Deal_Item__c dealItemRec : dealItemNewList) {
        	if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN && dealItemOldMap != null && (dealItemRec.Agreed_Value__c != dealItemOldMap.get(dealItemRec.Id).Agreed_Value__c || dealItemRec.Applicable_Tax__c != dealItemOldMap.get(dealItemRec.Id).Applicable_Tax__c || isCustomerPLUpdate)) {
        		dealItemIdToResetACVMap.put(dealItemRec.Id, true);
        	}
        }
        
        List<Deal_Item__c> dealItemList = [SELECT Agreed_Value__c, Default_Unit_Sales_Tax_Percentage__c, Deal__r.CO_Header__r.Customer__c,
                                                    Applicable_Tax__c, Taxable__c, (SELECT Id FROM Individual_Taxes__r)
                                                    FROM Deal_Item__c where Id IN: dealItemNewList AND Type__c = :Constants.DEAL_ITEM_TYPE_TRADE_IN AND Deal__r.Invoice_Number__c = null];
        
        //String defaultUnitSalesTaxId = Configurations__c.getInstance().Default_Tax_on_Unit__c;
        Set<Id> coHeaderIds = new Set<Id>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(dealItemRec.Deal__r.CO_Header__c != null) {
                coHeaderIds.add(dealItemRec.Deal__r.CO_Header__c);
            }
            dealIdSet.add(dealItemRec.Deal__c);
        }
        
        // Get list of Tax Exemptions for given coHeader ids
        Map<Id, Set<Id>> coHeaderIdToSalesTaxItemIdsMap = TaxCalculation.getCOHeaderIdToTaxExemptionsIds(coHeaderIds);
        
        // Entity Tax Rate
        List<Id> salesTaxIdList = new List<Id>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(dealItemRec.Taxable__c && dealItemRec.Applicable_Tax__c != null) {
                salesTaxIdList.add(dealItemRec.Applicable_Tax__c);
            }
        }
        
        //Calculation only individual taxes
        calculateSalesTax(salesTaxIdList, coHeaderIdToSalesTaxItemIdsMap, dealItemList, dealItemIdToResetACVMap);
    }
    
    private static void calculateSalesTax(List<Id> salesTaxIdList, Map<Id, Set<Id>> coHeaderIdToSalesTaxItemIdsMap, List<Deal_Item__c> dealItemList, Map<String, Boolean> dealItemIdToResetACVMap) {
        List<Applicable_Taxes__c> applicableTaxList = TaxManagementSOQLUtil.getApplicableTaxListBySalesTaxIdList(salesTaxIdList);
        
        Map<Id, List<Applicable_Taxes__c>> salesTaxIdToAppTaxRecordsMap = new Map<Id, List<Applicable_Taxes__c>>();
        
        for(Applicable_Taxes__c appTax : applicableTaxList) {
            List<Applicable_Taxes__c> appTaxRecordList = new List<Applicable_Taxes__c>();
            if(salesTaxIdToAppTaxRecordsMap.containsKey(appTax.Sales_Tax__c)) {
                appTaxRecordList = salesTaxIdToAppTaxRecordsMap.get(appTax.Sales_Tax__c);
            } 
            appTaxRecordList.add(appTax);
            salesTaxIdToAppTaxRecordsMap.put(appTax.Sales_Tax__c, appTaxRecordList);
        }
        
        Map<Id, Decimal> salesTaxIdToTaxRateMap = new Map<Id, Decimal>();
        for(Id salesTaxId : salesTaxIdToAppTaxRecordsMap.keyset()) {
            Decimal salesTaxRate = 0;
            for(Applicable_Taxes__c appTax : salesTaxIdToAppTaxRecordsMap.get(salesTaxId)) {
                salesTaxRate += appTax.Sales_Tax_Item__r.Rate__c;
            }
            salesTaxIdToTaxRateMap.put(salesTaxId, salesTaxRate);
        }
        
        List<Individual_Tax__c> individualTaxToInsert = new List<Individual_Tax__c>();
        List<Individual_Tax__c> individualTaxListToDelete = new List<Individual_Tax__c>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            individualTaxListToDelete.addAll(dealItemRec.Individual_Taxes__r);
            Decimal taxRate = 0;
            Decimal exemptionRate = 0;
            if(dealItemRec.Taxable__c && salesTaxIdToAppTaxRecordsMap.containsKey(dealItemRec.Applicable_Tax__c)) {
                for(Applicable_Taxes__c appTax : salesTaxIdToAppTaxRecordsMap.get(dealItemRec.Applicable_Tax__c)) {
                    if(coHeaderIdToSalesTaxItemIdsMap.containsKey(dealItemRec.Deal__r.CO_Header__c) && 
                        coHeaderIdToSalesTaxItemIdsMap.get(dealItemRec.Deal__r.CO_Header__c).contains(appTax.Sales_Tax_Item__c)) {
                        exemptionRate += appTax.Sales_Tax_Item__r.Rate__c;
                    } else {
                        Individual_Tax__c individualTaxRec = new Individual_Tax__c();
                        individualTaxRec.Deal_Item__c = dealItemRec.Id;
                        individualTaxRec.Sales_Tax_Item__c = appTax.Sales_Tax_Item__c;
                        
                        if(!TaxCalculation.IsEnhancedTaxCalculationApplicable || appTax.Sales_Tax_Item__r.Rate_Type__c == TaxManagementService.FIXED_RATE) {
                            individualTaxRec.Tax_Rate__c = appTax.Sales_Tax_Item__r.Rate__c; 
                        } else {
                            dealItemRec.Agreed_Value__c = dealItemRec.Agreed_Value__c != null ? dealItemRec.Agreed_Value__c : 0;
                            individualTaxRec.Enhanced_Tax_Amount__c = TaxCalculation.getEnhancedTaxAmount(dealItemRec.Agreed_Value__c, appTax.Sales_Tax_Item__r);
                            individualTaxRec.Enhanced_Tax_Amount__c = (-1 * individualTaxRec.Enhanced_Tax_Amount__c);
                        }
                        individualTaxRec.Sales_Tax_Item__c = appTax.Sales_Tax_Item__c;
                        individualTaxToInsert.add(individualTaxRec);
                        taxRate += (individualTaxRec.Tax_Rate__c != null) ? individualTaxRec.Tax_Rate__c : 0;
                    }
                } 
            }
            dealItemRec.Default_Unit_Sales_Tax_Percentage__c = taxRate;
            if(GeneralConfiguration.getTaxIncludingPricing() && dealItemIdToResetACVMap.containsKey(dealItemRec.Id) && dealItemIdToResetACVMap.get(dealItemRec.Id))  {
                dealItemRec.Actual_Cash_Value__c = ((dealItemRec.Agreed_Value__c != null ? dealItemRec.Agreed_Value__c : 0) / (1 + taxRate / 100)).setScale(2, RoundingMode.HALF_UP);
            }
        }
        
        if(individualTaxListToDelete.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('Individual_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete individualTaxListToDelete;
        }
        if(individualTaxToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Individual_Tax__c', individualTaxToInsert);
        }
        if(dealItemList.size() > 0) {
            DMLUtility.updateSobjectList('Deal_Item__c', dealItemList);
        }
    }
}