public class UnitPriceAndCostTriggerHelper {
	
    public static Boolean isForceStopTrigger = false;
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
		validateUnitStatus();
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
			List<Deal_Item__c> dealItemList = [Select Id, Deal__r.Status__c, Is_Lock_In_Unit_Pricing__c from Deal_Item__c where Type__c = 'Unit' AND Customer_Owned_Unit__c IN: skuIdSet];
			if(dealItemList.size() > 0) {
				List<Deal_Unit_Price_Cost__c> dupcListToInsert = new List<Deal_Unit_Price_Cost__c>();
				Set<Id> dealIdSetToUpdateCost = new Set<Id>();
				for(Unit_Price_Cost__c unitPriceAndCostRec : unitPriceAndCostNewList) {
					if(unitPriceAndCostRec.Type__c != TYPE_BASE) {
						for(Deal_Item__c dealItemRec : dealItemList) {
							if(dealItemRec.Deal__r.Status__c == 'Invoiced') {
								dealIdSetToUpdateCost.add(dealItemRec.Deal__c);
							}
							Deal_Unit_Price_Cost__c dupcRec = DealService.setFieldsToDealUnitPriceCost(unitPriceAndCostRec, dealItemRec.Id);
							if(dealItemRec.Deal__r.Status__c == 'Approved' || dealItemRec.Deal__r.Status__c == 'Invoiced' || dealItemRec.Is_Lock_In_Unit_Pricing__c) {
								dupcRec.Price__c = 0;
							}
							dupcListToInsert.add(dupcRec);
						}
					}
				}
				if(dupcListToInsert.size() > 0) {
					DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dupcListToInsert);
				}

				if(!dealIdSetToUpdateCost.isEmpty()) {
					List<Deal__c> invoicedDealList = [SELECT Total_Unit_Cost__c, Invoice_Number__c, Invoice_Number__r.Deal_Cost__c, 
																Invoice_Number__r.Invoice_Cost__c, 
																(SELECT Customer_Owned_Unit__r.Total_Cost__c FROM Deal_Items__r WHERE Type__c = 'Unit') 
																FROM Deal__c WHERE Id IN: dealIdSetToUpdateCost];
					
					List<Deal__c> dealListToUpdateUnitCost = new List<Deal__c>();
					List<Deal_Item__c> dealItemUpdateList = new List<Deal_Item__c>();
					List<CO_Invoice_Header__c> coInvListToUpdateUnitCost = new List<CO_Invoice_Header__c>();
					for(Deal__c dealRec: invoicedDealList) {
						Decimal unitCost = 0;
						for(Deal_Item__c dealItemRec: dealRec.Deal_Items__r) {
							dealItemRec.Unit_Cost__c = (dealItemRec.Customer_Owned_Unit__r.Total_Cost__c != null ? dealItemRec.Customer_Owned_Unit__r.Total_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0);
							unitCost += dealItemRec.Unit_Cost__c;
						}
						dealItemUpdateList.addAll(dealRec.Deal_Items__r);

						if(dealRec.Invoice_Number__c != null) {
							Decimal updatedDealCost = (dealRec.Invoice_Number__r.Deal_Cost__c != null ? dealRec.Invoice_Number__r.Deal_Cost__c : 0) - 
														(dealRec.Total_Unit_Cost__c != null ? dealRec.Total_Unit_Cost__c : 0) + // old unit cost
														unitCost; // new unit cost
							Decimal updatedInvCost = (dealRec.Invoice_Number__r.Invoice_Cost__c != null ? dealRec.Invoice_Number__r.Invoice_Cost__c : 0) - 
														(dealRec.Total_Unit_Cost__c != null ? dealRec.Total_Unit_Cost__c : 0) + // old unit cost
														unitCost; // new unit cost
							coInvListToUpdateUnitCost.add(new CO_Invoice_Header__c(Id = dealRec.Invoice_Number__c, Deal_Cost__c = updatedDealCost, Invoice_Cost__c = updatedInvCost));
							dealListToUpdateUnitCost.add(new Deal__c(Id = dealRec.Id, Total_Unit_Cost__c = unitCost));
						}
					}
					if(!dealItemUpdateList.isEmpty()) {
						DealItemTriggerHelper.isForceStopTrigger = true;
						DMLUtility.updateSobjectList('Deal_Item__c', dealItemUpdateList);
						DealItemTriggerHelper.isForceStopTrigger = false;
					}
					if(!dealListToUpdateUnitCost.isEmpty()) {
						DealTriggerHelper.isForceStopTrigger = true;
						DMLUtility.updateSobjectList('Deal__c', dealListToUpdateUnitCost);
						DealTriggerHelper.isForceStopTrigger = false;
					}
					if(!coInvListToUpdateUnitCost.isEmpty()) {
						COInvoiceTriggerHelper.isForceStopTrigger = true;
						DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvListToUpdateUnitCost);
						COInvoiceTriggerHelper.isForceStopTrigger = false;
					}
				}
			}
		}
	}

	private static void validateUnitStatus() {
		for(Unit_Price_Cost__c unitPriceAndCostRec: unitPriceAndCostNewList) {
			if(unitPriceAndCostRec.Unit_Type__c == 'STOCK' && unitPriceAndCostRec.Unit_Status__c == 'Inactive') {
				unitPriceAndCostRec.addError('Can not add adjustments on an inactive unit.');
			}
		}
	}
	
	private static void populateDefaultValues() {
		if(unitPriceAndCostNewList.size() > 0) {
			Integer countValue = generateCount() + 1;
			
			Set<String> skuIdSet = new Set<String>();
			for(Unit_Price_Cost__c unitPriceAndCostRec: unitPriceAndCostNewList) {
				if(unitPriceAndCostRec.Unit_Type__c == 'STOCK') {
					if(unitPriceAndCostRec.Adjustment_Date__c == null) unitPriceAndCostRec.Adjustment_Date__c = System.now();
					if(String.isBlank(unitPriceAndCostRec.Ref_No__c)) {
						unitPriceAndCostRec.Max_Count__c = countValue;
						unitPriceAndCostRec.Ref_No__c = 'UA-' +  CustomerOwnedUnitTriggerHelper.trailingZero(UNIT_ID_NUMBER_OF_DIGITS, countValue).trim();
						countValue++;
					}
					if(String.isNotBlank(unitPriceAndCostRec.Type__c) && unitPriceAndCostRec.Type__c.equalsIgnoreCase(TYPE_DEALER)) {
						skuIdSet.add(unitPriceAndCostRec.Customer_Owned_Unit__c);
					}
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
		List<Unit_Price_Cost__c> upcList = [SELECT Max_Count__c FROM Unit_Price_Cost__c WHERE Unit_Type__c = 'STOCK' AND Max_Count__c != null order by Max_Count__c desc limit 1];
		return !upcList.isEmpty() ? (Integer)upcList[0].Max_Count__c : 0;
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
		if(unitIdSet.size() > 0) {
			updateUnitList(unitIdSet);
		}
	}
	
	public static void updateUnitList(Set<Id> unitIdSet) {
		List<Customer_Owned_Unit__c> couList = [Select Id, Total_Base_Unit_Price__c, Total_Base_Units_Cost__c, Total_Dealer_Options_Cost__c, Total_Dealer_Options_Price__c, Total_Factory_Options_Cost__c, Unit_Purchase_Tax__c, Unit_Purchase_Tax__r.Rate__c,
					Total_Factory_Options_Price__c, Total_Cost__c, Total_Price__c, Vendor__r.Purchase_Tax__r.Rate__c, Tax_Amount__c, Unit_Type__c, (Select Type__c, Total_Cost__c, Total_Price__c, Taxable__c from Unit_Prices_Costs__r) from Customer_Owned_Unit__c where Id In :unitIdSet];
		
		for(Customer_Owned_Unit__c couRec : couList) {
			Decimal baseUnitsCost = 0;
			Decimal baseUnitsPrice = 0;
			Decimal factoryOptionsCost = 0;
			Decimal factoryOptionsPrice = 0;
			Decimal dealerOptionsCost = 0;
			Decimal dealerOptionsPrice = 0;
			Decimal totalCost = 0;
			Decimal totalPrice = 0;
			couRec.Taxable_Cost__c = 0;
			for(Unit_Price_Cost__c unitPriceAndCost : couRec.Unit_Prices_Costs__r) {
				Decimal cost = (unitPriceAndCost.Total_Cost__c == null) ? 0 : unitPriceAndCost.Total_Cost__c.setScale(2, RoundingMode.HALF_UP);
				if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == TYPE_BASE) {
					baseUnitsCost += cost;
					baseUnitsPrice += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
				} else if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == TYPE_DEALER) {
					dealerOptionsCost += cost;
					dealerOptionsPrice += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
				} else if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == TYPE_FACTORY) {
					factoryOptionsCost += cost;
					factoryOptionsPrice += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
				} 
				if(unitPriceAndCost.Taxable__c) {
					couRec.Taxable_Cost__c += cost;
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
					totalTaxAmount = (couRec.Taxable_Cost__c * couRec.Unit_Purchase_Tax__r.Rate__c) / 100;
				} else if(couRec.Vendor__r.Purchase_Tax__r.Rate__c != null) {
            		totalTaxAmount = (couRec.Taxable_Cost__c * couRec.Vendor__r.Purchase_Tax__r.Rate__c) / 100;
            	}
			} else {
				List<Applicable_Taxes__c> applicableTaxList = TaxManagementSOQLUtil.getApplicableTaxListBySalesTaxIdList(new List<Id>{((couRec.Unit_Type__c == 'ORDU' && couRec.Unit_Purchase_Tax__c != null) ? couRec.Unit_Purchase_Tax__c : couRec.Vendor__r.Purchase_Tax__c)});
				for(Applicable_Taxes__c appTaxRec : applicableTaxList) {
					if(appTaxRec.Sales_Tax_Item__r.Rate_Type__c == TaxManagementService.FIXED_RATE) {
						totalTaxAmount += (couRec.Taxable_Cost__c * appTaxRec.Sales_Tax_Item__r.Rate__c) / 100;
					} else {
						totalTaxAmount += TaxEngine.getEnhancedTaxAmount(couRec.Taxable_Cost__c, appTaxRec.Sales_Tax_Item__r);
					}
		        }
			}
            couRec.Tax_Amount__c = totalTaxAmount;
			// To set default purchase tax on ordered units based on vendor purchase tax
			if(couRec.Unit_Type__c == 'ORDU' && couRec.Vendor__r.Purchase_Tax__c != null && couRec.Unit_Purchase_Tax__c == null) {
				couRec.Unit_Purchase_Tax__c = couRec.Vendor__r.Purchase_Tax__c;
			}
		}
		DMLUtility.updateSobjectList('Customer_Owned_Unit__c', couList);
	}
	
	public static void populatesAccountingSyncFields() {
	    IntegrationSyncFlagService.manageAdjustmentSyncFlag(unitPriceAndCostNewList);
	}
	
    public static void setUnitPriceAndCostDataForAccountSync() {
		IntegrationSyncFlagService.checkAndInitiateSyncBatch(unitPriceAndCostNewList, IntegrationUtility.UNIT_PRICE_COST);
    }
}