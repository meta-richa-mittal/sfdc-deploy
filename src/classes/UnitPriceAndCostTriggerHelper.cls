public class UnitPriceAndCostTriggerHelper {
	
	public static List<Unit_Price_Cost__c> unitPriceAndCostNewList = new List<Unit_Price_Cost__c>();
    public static List<Unit_Price_Cost__c> unitPriceAndCostOldList = new List<Unit_Price_Cost__c>();
    public static Map<Id, Unit_Price_Cost__c> unitPriceAndCostNewMap = new Map<Id, Unit_Price_Cost__c>();
    public static Map<Id, Unit_Price_Cost__c> unitPriceAndCostOldMap = new Map<Id, Unit_Price_Cost__c>();
    
    private static Set<Id> unitIdSet = new Set<Id>();
    
    public static final String TYPE_BASE = 'Base';
    public static final String TYPE_DEALER = 'Dealer';
    public static final String TYPE_FACTORY = 'Factory';
    
    private static final Integer UNIT_ID_NUMBER_OF_DIGITS = 6;
    
   private static BaseIntegrationService integrationRec;
    
    // Trigger run boolean (QB Integration)
    public static Boolean preventOnAccountingSync = false;
    
	public static void beforeInsertCalculation() {
		populateDefaultValues();
		populatesAccountingSyncFields();
	}
	
	public static void afterInsertCalculation() {
		getUnitIdListToUpdate(unitPriceAndCostNewList);
		createDealUPC();
	}
	
	public static void afterDeleteCalculation() {
		getUnitIdListToUpdate(unitPriceAndCostOldList);
	}
	
	public static void afterUpdateCalculation() {
		getUnitIdListToUpdate(unitPriceAndCostNewList);
	}
	
	private static void createDealUPC() {
		set<String> skuIdSet = new Set<String>();
		for(Unit_Price_Cost__c unitPriceAndCostRec : unitPriceAndCostNewList){
			if(unitPriceAndCostRec.Unit_Type__c == 'STOCK' && unitPriceAndCostRec.Type__c != TYPE_BASE) {
				skuIdSet.add(unitPriceAndCostRec.Customer_Owned_Unit__c);
			}
		}
		
		if(skuIdSet.size() > 0) {
			List<Deal_Item__c> dealItemList = [Select Id, Deal__r.Status__c from Deal_Item__c where Type__c = 'Unit' AND Customer_Owned_Unit__c IN: skuIdSet];
			if(dealItemList.size() > 0) {
				List<Deal_Unit_Price_Cost__c> dupcListToInsert = new List<Deal_Unit_Price_Cost__c>();
				for(Unit_Price_Cost__c unitPriceAndCostRec : unitPriceAndCostNewList) {
					if(unitPriceAndCostRec.Type__c != TYPE_BASE) {
						for(Deal_Item__c dealItemRec : dealItemList) {
							Deal_Unit_Price_Cost__c dupcRec = DealService.setFieldsToDealUnitPriceCost(unitPriceAndCostRec, dealItemRec.Id);
							if(dealItemRec.Deal__r.Status__c == 'Approved' || dealItemRec.Deal__r.Status__c == 'Sold') {
								dupcRec.Price__c = 0;
							}
							dupcListToInsert.add(dupcRec);
						}
					}
				}
				if(dupcListToInsert.size() > 0) {
					DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dupcListToInsert);
				}
			}
		}
	}
	
	private static void populateDefaultValues() {
		if(unitPriceAndCostNewList.size() > 0) {
			Integer countValue = generateCount() + 1;
			
			Set<String> skuIdSet = new Set<String>();
			for(Unit_Price_Cost__c unitPriceAndCostRec : unitPriceAndCostNewList){
				if(String.isBlank(unitPriceAndCostRec.Ref_No__c) && unitPriceAndCostRec.Unit_Type__c == 'STOCK') {
					unitPriceAndCostRec.Max_Count__c = countValue;
					unitPriceAndCostRec.Ref_No__c = 'UA-' +  CustomerOwnedUnitTriggerHelper.trailingZero(UNIT_ID_NUMBER_OF_DIGITS, countValue).trim();
					countValue++;
				}
				if(unitPriceAndCostRec.Unit_Type__c == 'STOCK' && String.isNotBlank(unitPriceAndCostRec.Type__c) && 
								unitPriceAndCostRec.Type__c.equalsIgnoreCase(TYPE_DEALER)) {
					skuIdSet.add(unitPriceAndCostRec.Customer_Owned_Unit__c);
				}
			}
			if(skuIdSet.size() > 0) {
				Map<String, Customer_Owned_Unit__c> soldUnitIdToRecMap = new Map<String, Customer_Owned_Unit__c>([Select Id, Status__c from Customer_Owned_Unit__c 
																								where Id IN: skuIdSet AND Status__c = 'Sold']);
				for(Unit_Price_Cost__c unitPriceAndCostRec : unitPriceAndCostNewList){
					if(unitPriceAndCostRec.Unit_Type__c == 'STOCK' && String.isNotBlank(unitPriceAndCostRec.Type__c) && 
									unitPriceAndCostRec.Type__c.equalsIgnoreCase(TYPE_DEALER) && soldUnitIdToRecMap.containsKey(unitPriceAndCostRec.Customer_Owned_Unit__c)) {
						unitPriceAndCostRec.Total_Price__c = unitPriceAndCostRec.Price__c = 0;
					}
				}
			}
		}	
	}
	
	private static Integer generateCount(){
		Integer countOfAdjstmntRec = 0;
		List<AggregateResult> maxCountList = [Select MAX(Max_Count__c) from Unit_Price_Cost__c WHERE Unit_Type__c = 'STOCK'];
		
		if(maxCountList !=null && maxCountList.size() > 0 && maxCountList[0].get('expr0') != null){
			countOfAdjstmntRec = Integer.valueOf(maxCountList[0].get('expr0'));
		}
		return countOfAdjstmntRec;
	}
	
	public static void getUnitIdListToUpdate(List<Unit_Price_Cost__c> unitPriceAndCostList) {
		for(Unit_Price_Cost__c unitPriceAndCostObj : unitPriceAndCostList) {
			if(unitPriceAndCostObj.Customer_Owned_Unit__c != null) {
				unitIdSet.add(unitPriceAndCostObj.Customer_Owned_Unit__c);	
			}
			if(trigger.isUpdate) {
				Unit_Price_Cost__c oldUnitPriceAndCost = unitPriceAndCostOldMap.get(unitPriceAndCostObj.Id);
				if(oldUnitPriceAndCost.Customer_Owned_Unit__c != null && oldUnitPriceAndCost.Customer_Owned_Unit__c != unitPriceAndCostObj.Customer_Owned_Unit__c) {
					unitIdSet.add(oldUnitPriceAndCost.Customer_Owned_Unit__c);
				}
			}
		}
		updateUnitList();
	}
	
	public static void updateUnitList() {
		List<Customer_Owned_Unit__c> couList = [Select Id, Total_Base_Unit_Price__c, Total_Base_Units_Cost__c, Total_Dealer_Options_Cost__c, Total_Dealer_Options_Price__c, Total_Factory_Options_Cost__c, Unit_Purchase_Tax__c, Unit_Purchase_Tax__r.Rate__c,
					Total_Factory_Options_Price__c, Total_Cost__c, Total_Price__c, Vendor__r.Purchase_Tax__r.Rate__c, Tax_Amount__c, Unit_Type__c, (Select Type__c, Total_Cost__c, Total_Price__c from Unit_Prices_Costs__r) from Customer_Owned_Unit__c where Id In :unitIdSet];
		
		for(Customer_Owned_Unit__c couRec : couList) {
			Decimal baseUnitsCost = 0;
			Decimal baseUnitsPrice = 0;
			Decimal factoryOptionsCost = 0;
			Decimal factoryOptionsPrice = 0;
			Decimal dealerOptionsCost = 0;
			Decimal dealerOptionsPrice = 0;
			Decimal totalCost = 0;
			Decimal totalPrice = 0;
			for(Unit_Price_Cost__c unitPriceAndCost : couRec.Unit_Prices_Costs__r) {
				if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == TYPE_BASE) {
					baseUnitsCost += (unitPriceAndCost.Total_Cost__c == null) ? 0 : unitPriceAndCost.Total_Cost__c;
					baseUnitsPrice += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
				} else if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == TYPE_DEALER) {
					dealerOptionsCost += (unitPriceAndCost.Total_Cost__c == null) ? 0 : unitPriceAndCost.Total_Cost__c;
					dealerOptionsPrice += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
				} else if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == TYPE_FACTORY) {
					factoryOptionsCost += (unitPriceAndCost.Total_Cost__c == null) ? 0 : unitPriceAndCost.Total_Cost__c;
					factoryOptionsPrice += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
				} 
			}
			
			totalCost = baseUnitsCost + factoryOptionsCost + dealerOptionsCost;
			totalPrice = baseUnitsPrice + factoryOptionsPrice + dealerOptionsPrice;
			//system.assert(false, 'totalCost  ' +totalCost+ '  totalPrice  ' +totalPrice + '  baseUnitsCost '+ baseUnitsCost );
			couRec.Total_Base_Units_Cost__c = baseUnitsCost;
			couRec.Total_Base_Unit_Price__c = baseUnitsPrice;
			
			couRec.Total_Dealer_Options_Cost__c = dealerOptionsCost;
			couRec.Total_Dealer_Options_Price__c = dealerOptionsPrice;
			
			couRec.Total_Factory_Options_Cost__c = factoryOptionsCost;
			couRec.Total_Factory_Options_Price__c = factoryOptionsPrice;
			
			couRec.Total_Cost__c = totalCost;
			couRec.Total_Price__c = totalPrice;
			
            Decimal totalTaxAmount = 0;
            if(!TaxCalculation.IsEnhancedTaxCalculationApplicable) {
				// Tac calculation based on unit purchase tax for ordered units
				if(couRec.Unit_Type__c == 'ORDU' && couRec.Unit_Purchase_Tax__c != null && couRec.Unit_Purchase_Tax__r.Rate__c != null) {
					totalTaxAmount = (totalCost * couRec.Unit_Purchase_Tax__r.Rate__c) / 100;
				} else if(couRec.Vendor__r.Purchase_Tax__r.Rate__c != null) {
            		totalTaxAmount = (totalCost * couRec.Vendor__r.Purchase_Tax__r.Rate__c) / 100;
            	}
			} else {
				List<Applicable_Taxes__c> applicableTaxList = TaxManagementSOQLUtil.getApplicableTaxListBySalesTaxIdList(new List<Id>{((couRec.Unit_Type__c == 'ORDU' && couRec.Unit_Purchase_Tax__c != null) ? couRec.Unit_Purchase_Tax__c : couRec.Vendor__r.Purchase_Tax__c)});
				for(Applicable_Taxes__c appTaxRec : applicableTaxList) {
					if(appTaxRec.Sales_Tax_Item__r.Rate_Type__c == TaxManagementService.FIXED_RATE) {
						totalTaxAmount += (totalCost * appTaxRec.Sales_Tax_Item__r.Rate__c) / 100;
					} else {
						totalTaxAmount += TaxCalculation.getEnhancedTaxAmount(totalCost, appTaxRec.Sales_Tax_Item__r);
					}
		        }
			}
            couRec.Tax_Amount__c = totalTaxAmount;
			// To set default purchase tax on ordered units based on vendor purchase tax
			if(couRec.Unit_Type__c == 'ORDU' && couRec.Vendor__r.Purchase_Tax__c != null && couRec.Unit_Purchase_Tax__c == null) {
				couRec.Unit_Purchase_Tax__c = couRec.Vendor__r.Purchase_Tax__c;
			}
		}
		
		update couList;
	}
	
	public static void populatesAccountingSyncFields() {
        if(QBUtil.isQBEnabled()) {
            QBSyncFlagService.manageAdjustmentSyncFlag(unitPriceAndCostNewList);
        } else {
	        try {
	            integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
	                if(integrationRec != null) {
	                    IntegrationSyncFlagService.manageAdjustmentSyncFlag(new List<BaseIntegrationService>{integrationRec}, unitPriceAndCostNewList);
	                }
	        } catch(exception e){
	        }    
    	}
	}
	
    public static void setUnitPriceAndCostDataForAccountSync(){
        Set<Id> unitPriceAndCostIdSet = new Set<Id>();
        for(Unit_Price_Cost__c unitPriceAndCost : unitPriceAndCostNewList){ 
        	if(QBUtil.isQBEnabled()) {  	
	        	if(unitPriceAndCost.availForQBSync__c) {
	        		unitPriceAndCostIdSet.add(unitPriceAndCost.Id);
	        	}
	        	} else if(integrationRec != null) {
    	    		if(unitPriceAndCost.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.UNIT_PRICE_COST).Sync_Flag_API_Name__c) != null && 
    	    			Boolean.valueOf(unitPriceAndCost.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.UNIT_PRICE_COST).Sync_Flag_API_Name__c))) {
    	        		unitPriceAndCostIdSet.add(unitPriceAndCost.Id);
    	    	}
        	}	
        }
        if(unitPriceAndCostIdSet.size() > 0) {
        	if(QBUtil.isQBEnabled()) {
            	UnitPriceAndCostService.syncUnitPriceAndCosts(unitPriceAndCostIdSet);
        	} else {
    			IntegrationBatchService.initiateBatch(unitPriceAndCostIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.UNIT_PRICE_COST);
    		}
        }
    }
}