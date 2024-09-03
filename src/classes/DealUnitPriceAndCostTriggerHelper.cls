public without sharing class DealUnitPriceAndCostTriggerHelper {
		
	// List to store trigger new list
	public static List<Deal_Unit_Price_Cost__c> DealUnitPriceAndCostNewList = new List<Deal_Unit_Price_Cost__c>();

	// List to store trigger old list
	public static List<Deal_Unit_Price_Cost__c> DealUnitPriceAndCostOldList = new List<Deal_Unit_Price_Cost__c>();

	// Map to store new Trigger Map
	public static Map<Id, Deal_Unit_Price_Cost__c> DealUnitPriceAndCostNewMap = new Map<Id, Deal_Unit_Price_Cost__c>();

	// Map to store Old Trigger Map
	public static Map<Id, Deal_Unit_Price_Cost__c> DealUnitPriceAndCostOldMap = new Map<Id, Deal_Unit_Price_Cost__c>();
	public static Boolean isCustomerPLUpdate = false;
	public static Boolean isTriggerExecute = true;
	public static Boolean isForceStopTrigger = false;
		
	//Added by nidhi
	public static void afterInsertOperations() {
		salesTaxCalculation(DealUnitPriceAndCostNewList);
		updateRideawayPricingAndStampDutyCalculation(DealUnitPriceAndCostNewList);
		updateTotalOnDeal(DealUnitPriceAndCostNewList);
	}

	public static void afterUpdateOperations() {
		if(isTriggerExecute) {
				if((isCustomerPLUpdate && (COTriggerHelper.isRecalculateTaxes != null && COTriggerHelper.isRecalculateTaxes)) || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
				salesTaxCalculation(DealUnitPriceAndCostNewList);
				isCustomerPLUpdate = false;
			}
			updateTotalOnDeal(DealUnitPriceAndCostNewList);
			updateRideawayPricingAndStampDutyCalculation(DealUnitPriceAndCostNewList);
		}
	}

	public static void afterDeleteOperations() {
		updateTotalOnDeal(DealUnitPriceAndCostOldList);
		updateRideawayPricingAndStampDutyCalculation(DealUnitPriceAndCostOldList);
	}

	public static void updateRideawayPricingAndStampDutyCalculation(List<Deal_Unit_Price_Cost__c> unitPriceAndCostList) {
		if(GeneralConfiguration.getCompanyLocale() == 'Australia') {
			unitPriceAndCostList = getStampDutyEntryCondDUPC(unitPriceAndCostList);

			Set<String> dealItemIdSet = new Set<String>();
			for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : unitPriceAndCostList) {
				dealItemIdSet.add(dealUnitPriceAndCostRec.Deal_Item__c);
			}
			if(!dealItemIdSet.isEmpty()) {
				OptionAndFeeTriggerHelper.updateRideawayPricingAndStampDuty(dealItemIdSet);
			}
		}
	}

	public static List<Deal_Unit_Price_Cost__c> getStampDutyEntryCondDUPC(List<Deal_Unit_Price_Cost__c> unitPriceAndCostNewList) {
		List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostToUpdate = new List<Deal_Unit_Price_Cost__c>();
		if(trigger.isUpdate) {
			Map<Id, Deal_Unit_Price_Cost__c> dealUnitPriceAndCostOldRecMap = (Map<Id, Deal_Unit_Price_Cost__c>)Trigger.oldMap;
			for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : (List<Deal_Unit_Price_Cost__c>)Trigger.new) {
				if(dealUnitPriceAndCostOldRecMap.get(dealUnitPriceAndCostRec.Id).Price_When_Tax_Included__c != dealUnitPriceAndCostRec.Price_When_Tax_Included__c || dealUnitPriceAndCostOldRecMap.get(dealUnitPriceAndCostRec.Id).Price__c != dealUnitPriceAndCostRec.Price__c || 
					dealUnitPriceAndCostOldRecMap.get(dealUnitPriceAndCostRec.Id).Qty__c != dealUnitPriceAndCostRec.Qty__c || dealUnitPriceAndCostOldRecMap.get(dealUnitPriceAndCostRec.Id).Sales_Tax_Percentage__c != dealUnitPriceAndCostRec.Sales_Tax_Percentage__c) {
					dealUnitPriceAndCostToUpdate.add(dealUnitPriceAndCostRec);
				}
			}
		} else {
			dealUnitPriceAndCostToUpdate = unitPriceAndCostNewList;
		}
		return dealUnitPriceAndCostToUpdate;
	}

	public static void updateTotalOnDeal(List<Deal_Unit_Price_Cost__c> unitPriceAndCostList) {
		Set<String> dealIdSet = new Set<String>();
		for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : unitPriceAndCostList) {
			dealIdSet.add(dealUnitPriceAndCostRec.Deal__c);
		}
		if(!COTriggerHelper.isRecalculateCOPLAndTax) {
			OptionAndFeeTriggerHelper.updateDealTotal(dealIdSet);
		}
	}

	public static void salesTaxCalculation(List<Deal_Unit_Price_Cost__c> newList) {
		if(!isTriggerExecute) {
			return;
		}
		isTriggerExecute = false;
		
		List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = 
			[SELECT Deal_Item__r.Deal__c, Deal_Item__r.Deal__r.Is_Tax_Based_On_Customer_Address__c, Deal_Item__r.Is_Rideaway_Pricing_Enabled__c, Price_When_Tax_Included__c, Deal_Item__r.Applicable_Tax__c, Qty__c, 
				Deal_Item__r.Deal__r.CO_Header__r.Customer__c, Price__c, Deal_Item__r.Customer_Owned_Unit__c, Deal_Item__r.Taxable__c, Applicable_Tax__c, 
						Sales_Tax_Percentage__c, Type__c, Deal_Item__c,
					(SELECT Id from Individual_Taxes__r) FROM Deal_Unit_Price_Cost__c WHERE Id IN: newList AND Deal_Item__r.Deal__r.Invoice_Number__c = null];
		TaxEngine.applySalesTaxonDUPCList(dealUnitPriceAndCostList);	
	}

	public static void applyEnhancedTaxOnUnit(Set<String> dealItemIdSet) {
		Decimal totalDUPCTaxableAmount = 0;
		List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = 
			[SELECT Type__c, Qty__c, Price__c, Deal_Item__c, (SELECT Id, Enhanced_Tax_Amount__c, Sales_Tax_Item__c, Sales_Tax_Item__r.Name__c, 
			Sales_Tax_Item__r.Max_Taxable_Amount_Tier_1__c, Sales_Tax_Item__r.Max_Taxable_Amount_Tier_2__c, Sales_Tax_Item__r.Maximum_Tax_Amount__c, 
			Sales_Tax_Item__r.Minimum_Tax_Amount__c, Sales_Tax_Item__r.Rate_Type__c, Sales_Tax_Item__r.Tax_Rate_Tier_1__c, Sales_Tax_Item__r.Tax_Rate_Tier_2__c, 
			Sales_Tax_Item__r.Tax_Rate_Tier_3__c, Sales_Tax_Item__r.Tax_Type__c, Sales_Tax_Item__r.Rate__c, Deal_Unit_Price_Cost__r.Deal_Item__c from Individual_Taxes__r 
			WHERE Sales_Tax_Item__r.Rate_Type__c !=: TaxManagementService.FIXED_RATE) FROM Deal_Unit_Price_Cost__c WHERE Deal_Item__c IN: dealItemIdSet];

		List<Individual_Tax__c> individualTaxListToUpdate = new List<Individual_Tax__c>();
		Map<String, Decimal> dealItemIdToTaxableAmountMap = new Map<String, Decimal>();
		for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : dealUnitPriceAndCostList){
			dealUnitPriceAndCostRec.Qty__c = dealUnitPriceAndCostRec.Qty__c != null ? dealUnitPriceAndCostRec.Qty__c : 1;
			dealUnitPriceAndCostRec.Price__c = dealUnitPriceAndCostRec.Price__c != null ? dealUnitPriceAndCostRec.Price__c : 0;

			if(dealUnitPriceAndCostRec.Type__c == 'Base') {
				individualTaxListToUpdate.addAll(dealUnitPriceAndCostRec.Individual_Taxes__r);
			}
			if(!dealItemIdToTaxableAmountMap.containsKey(dealUnitPriceAndCostRec.Deal_Item__c)) {
				dealItemIdToTaxableAmountMap.put(dealUnitPriceAndCostRec.Deal_Item__c, (dealUnitPriceAndCostRec.Qty__c * dealUnitPriceAndCostRec.Price__c));
			} else {
				dealItemIdToTaxableAmountMap.put(dealUnitPriceAndCostRec.Deal_Item__c, dealItemIdToTaxableAmountMap.get(dealUnitPriceAndCostRec.Deal_Item__c) + (dealUnitPriceAndCostRec.Qty__c * dealUnitPriceAndCostRec.Price__c));
			}
		}
		
		for(Individual_Tax__c individualTaxRec : individualTaxListToUpdate) {
			if(dealItemIdToTaxableAmountMap.containsKey(individualTaxRec.Deal_Unit_Price_Cost__r.Deal_Item__c)) {
				individualTaxRec.Enhanced_Tax_Amount__c = TaxEngine.getEnhancedTaxAmount(dealItemIdToTaxableAmountMap.get(individualTaxRec.Deal_Unit_Price_Cost__r.Deal_Item__c), individualTaxRec.Sales_Tax_Item__r);
			}
		}
	
		if(individualTaxListToUpdate.size() > 0) {
			DMLUtility.updateSobjectList('Individual_Tax__c', individualTaxListToUpdate);
		}
	}
}