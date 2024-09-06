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
    
    public static List<Sales_Tax__c> defaultSalesTax;
    
    //Added by nidhi
    public static void afterInsertOperations() {
    	salesTaxCalculation(DealUnitPriceAndCostNewList);
    	updateStampDutyTotal(DealUnitPriceAndCostNewList);
    	updateTotalOnDeal(DealUnitPriceAndCostNewList);
    }
    
    public static void afterUpdateOperations() {
    	if(isTriggerExecute) {
    		if(isCustomerPLUpdate || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
	    		salesTaxCalculation(DealUnitPriceAndCostNewList);
                isCustomerPLUpdate = false;
	    	}
    		updateTotalOnDeal(DealUnitPriceAndCostNewList);
	    	updateStampDutyTotal(DealUnitPriceAndCostNewList);
	    	updateRideawayPricing();
    	}
    }
    
    public static void afterDeleteOperations() {
    	updateTotalOnDeal(DealUnitPriceAndCostOldList);
    	updateStampDutyTotal(DealUnitPriceAndCostOldList);
    }
    
    public static void updateStampDutyTotal(List<Deal_Unit_Price_Cost__c> unitPriceAndCostList) {
    	if(GeneralConfiguration.getCompanyLocale() == 'Australia') {
			unitPriceAndCostList = getStampDutyEntryCondDUPC(unitPriceAndCostList);

	    	Set<String> dealItemIdSet = new Set<String>();
	    	for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : unitPriceAndCostList) {
	    		dealItemIdSet.add(dealUnitPriceAndCostRec.Deal_Item__c);
	    	}
	    	if(dealItemIdSet.size() == 0) { 
	    		return;
	    	} 
	    	Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
	    	Decimal stampDutyRate = GeneralConfiguration.getStampDutyRate();
	    	List<Deal_Item__c> dealItemList = 
					[Select Id, Stamp_Duty_Total__c, Is_Override_Stamp_Duty__c, Is_Rideaway_Pricing_Enabled__c, (Select Id, Price__c, Price_When_Tax_Included__c, Qty__c, Sales_Tax_Percentage__c from Deal_Unit_Prices_Costs__r) from Deal_Item__c where Id IN: dealItemIdSet];
			
			List<Deal_Item__c> dealItemListToUpdate = new List<Deal_Item__c>();
			for(Deal_Item__c dealItemRec : dealItemList) {
				if(!dealItemRec.Is_Rideaway_Pricing_Enabled__c) {
					Decimal unitCostPriceTotal = 0;
					for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : dealItemRec.Deal_Unit_Prices_Costs__r) {
						if(!isTaxIncludingPricing) {
							unitCostPriceTotal += (((dealUnitPriceAndCostRec.Price__c != null) ? dealUnitPriceAndCostRec.Price__c : 0) * ((dealUnitPriceAndCostRec.Qty__c != null) ? dealUnitPriceAndCostRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
						} else {
							unitCostPriceTotal += (((dealUnitPriceAndCostRec.Price_When_Tax_Included__c != null) ? dealUnitPriceAndCostRec.Price_When_Tax_Included__c : ((dealUnitPriceAndCostRec.Price__c * (1 + dealUnitPriceAndCostRec.Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP)) * 
										((dealUnitPriceAndCostRec.Qty__c != null) ? dealUnitPriceAndCostRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
						}
					}
                    
					if(unitCostPriceTotal > 100) {
						Decimal roundedUpAmount = ((Math.ceil((unitCostPriceTotal) / 100) * 100) * (stampDutyRate / 100));
						dealItemRec.Stamp_Duty_Total__c = roundedUpAmount;
					} else {
						dealItemRec.Stamp_Duty_Total__c = 0;
					}
					dealItemListToUpdate.add(dealItemRec);
				}
			}
			DMLUtility.updateSobjectList('Deal_Item__c', dealItemListToUpdate);
    	}
    }
    
	public static List<Deal_Unit_Price_Cost__c> getStampDutyEntryCondDUPC(List<Deal_Unit_Price_Cost__c> unitPriceAndCostNewList) {
		List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostToUpdate = new List<Deal_Unit_Price_Cost__c>();
		if(trigger.isUpdate) {
			for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : unitPriceAndCostNewList) {
				if(DealUnitPriceAndCostOldMap.get(dealUnitPriceAndCostRec.Id).Price_When_Tax_Included__c != dealUnitPriceAndCostRec.Price_When_Tax_Included__c || DealUnitPriceAndCostOldMap.get(dealUnitPriceAndCostRec.Id).Price__c != dealUnitPriceAndCostRec.Price__c || 
						DealUnitPriceAndCostOldMap.get(dealUnitPriceAndCostRec.Id).Qty__c != dealUnitPriceAndCostRec.Qty__c || DealUnitPriceAndCostOldMap.get(dealUnitPriceAndCostRec.Id).Sales_Tax_Percentage__c != dealUnitPriceAndCostRec.Sales_Tax_Percentage__c) {
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
        
    	Set<Id> customerIdSet = new Set<Id>();
        Set<Id> coHeaderIds = new Set<Id>();
    	Set<String> dealIdSet = new Set<String>();
		Set<String> dealItemIdSet = new Set<String>();
    	List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = 
    	   [SELECT Deal_Item__r.Deal__c, Deal_Item__r.Is_Rideaway_Pricing_Enabled__c, Price_When_Tax_Included__c, Deal_Item__r.Applicable_Tax__c, Qty__c, 
        	   Deal_Item__r.Deal__r.CO_Header__r.Customer__c, Price__c, Deal_Item__r.Customer_Owned_Unit__c, Deal_Item__r.Taxable__c, Applicable_Tax__c, 
        	   		Sales_Tax_Percentage__c, Type__c, Deal_Item__c,
    		      (SELECT Id from Individual_Taxes__r) FROM Deal_Unit_Price_Cost__c WHERE Id IN: newList AND Deal_Item__r.Deal__r.Invoice_Number__c = null];
    		
    	for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : dealUnitPriceAndCostList) {
    		if(dealUnitPriceAndCostRec.Deal_Item__r.Deal__r.CO_Header__r.Customer__c != null) {
    			customerIdSet.add(dealUnitPriceAndCostRec.Deal_Item__r.Deal__r.CO_Header__r.Customer__c);
                coHeaderIds.add(dealUnitPriceAndCostRec.Deal_Item__r.Deal__r.CO_Header__c);
    		}
    		dealIdSet.add(dealUnitPriceAndCostRec.Deal_Item__r.Deal__c);
			dealItemIdSet.add(dealUnitPriceAndCostRec.Deal_Item__c);
    	}
    	customerIdSet.remove(null);
    	dealIdSet.remove(null);
		dealItemIdSet.remove(null);
    	
        // Get list of Tax Exemptions for given coHeader ids
        Map<Id, Set<Id>> coHeaderIdToSalesTaxItemIdsMap = TaxCalculation.getCOHeaderIdToTaxExemptionsIds(coHeaderIds);
        
        // Entity Tax Rate
        List<Id> salesTaxIdList = new List<Id>();
        for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : dealUnitPriceAndCostList) {
        	if(dealUnitPriceAndCostRec.Deal_Item__r.Applicable_Tax__c != null) {
                salesTaxIdList.add(dealUnitPriceAndCostRec.Deal_Item__r.Applicable_Tax__c);
        	} else if(Configurations__c.getInstance().Default_Tax_on_Unit__c != null) {
            	salesTaxIdList.add(Configurations__c.getInstance().Default_Tax_on_Unit__c);
            } else {
                if(defaultSalesTax == null) {
                    populateDefaultSalesTax();
                }
		    	if(defaultSalesTax != null) {
		    		salesTaxIdList.add(defaultSalesTax[0].Id);
		    	}
            }
        }
        
        List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostListToUpdate = new List<Deal_Unit_Price_Cost__c>();
        dealUnitPriceAndCostListToUpdate.addAll(calculateSalesTax(salesTaxIdList, coHeaderIdToSalesTaxItemIdsMap, dealUnitPriceAndCostList));
        if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
			applyEnhancedTaxOnUnit(dealItemIdSet);
		}
        if(dealUnitPriceAndCostListToUpdate.size() > 0) {
			DMLUtility.updateSobjectList('Deal_Unit_Price_Cost__c', dealUnitPriceAndCostListToUpdate);
        }
        
        dealIdSet.remove(null);
    }
    
    private static void populateDefaultSalesTax() {
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Sales_Tax__c> salesTaxList = [SELECT Rate__c FROM Sales_Tax__c WHERE default__c = true];
        if(salesTaxList.size() > 0) {
            defaultSalesTax = salesTaxList;
        }
    }
    
    private static List<Deal_Unit_Price_Cost__c> calculateSalesTax(List<Id> salesTaxIdList, Map<Id, Set<Id>> coHeaderIdToSalesTaxItemIdsMap, List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList) {
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
        
        List<Sobject> dealUnitPriceAndCostListToUpdate = new List<Sobject>();
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        List<Individual_Tax__c> individualTaxToInsert = new List<Individual_Tax__c>();
        
        String defaultSalesTaxId = Configurations__c.getInstance().Default_Tax_on_Unit__c;
        
        if(String.isBlank(defaultSalesTaxId)) {
	        for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : dealUnitPriceAndCostList) {
	        	if(dealUnitPriceAndCostRec.Deal_Item__r.Applicable_Tax__c == null) {
	        		List<Sales_Tax__c> defaultSalesTaxList = [Select Id from Sales_Tax__c where Default__c = true];
	        		if(defaultSalesTaxList.size() > 0) {
		        		defaultSalesTaxId = defaultSalesTaxList[0].Id;
		        	}
		        	break;
	        	}
	        }
        }
		
        List<Individual_Tax__c> individualTaxList = new List<Individual_Tax__c>();
        for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : dealUnitPriceAndCostList) {
        	individualTaxList.addAll(dealUnitPriceAndCostRec.Individual_Taxes__r);
        	
			Id salesTaxId;
			if(dealUnitPriceAndCostRec.Deal_Item__r.Taxable__c) {
				if(dealUnitPriceAndCostRec.Deal_Item__r.Applicable_Tax__c != null) {
					salesTaxId = dealUnitPriceAndCostRec.Deal_Item__r.Applicable_Tax__c;
				} else {
					salesTaxId = defaultSalesTaxId;
				}
			}
            
            if(salesTaxId == null) {
            	dealUnitPriceAndCostRec.Applicable_Tax__c = null;
            	dealUnitPriceAndCostRec.Sales_Tax_Percentage__c = 0;
            	if(isTaxIncludingPricing && dealUnitPriceAndCostRec.Price__c != null) {
            		dealUnitPriceAndCostRec.Price_When_Tax_Included__c = dealUnitPriceAndCostRec.Price__c;
            	}
            		dealUnitPriceAndCostListToUpdate.add(dealUnitPriceAndCostRec);
            	continue;
            }
            Boolean isTaxChange = false;
            if((dealUnitPriceAndCostRec.Applicable_Tax__c != null && salesTaxId == null) || 
            		(dealUnitPriceAndCostRec.Applicable_Tax__c == null && salesTaxId != null) || dealUnitPriceAndCostRec.Applicable_Tax__c != salesTaxId) {
            	isTaxChange = true;
            }  
            dealUnitPriceAndCostRec.Applicable_Tax__c = salesTaxId;
            
            Decimal exemptionRate = 0;
            if(salesTaxIdToAppTaxRecordsMap.containsKey(salesTaxId)) {
                for(Applicable_Taxes__c appTax : salesTaxIdToAppTaxRecordsMap.get(salesTaxId)) {
                    if(dealUnitPriceAndCostRec.Deal_Item__r.Deal__r.CO_Header__r.Customer__c != null && 
                        coHeaderIdToSalesTaxItemIdsMap.get(dealUnitPriceAndCostRec.Deal_Item__r.Deal__r.CO_Header__c).contains(appTax.Sales_Tax_Item__c)) {
                        exemptionRate += appTax.Sales_Tax_Item__r.Rate__c;
                    } else { 
                    	Individual_Tax__c individualTaxRec = new Individual_Tax__c();
                    	individualTaxRec.Deal_Unit_Price_Cost__c = dealUnitPriceAndCostRec.Id;
						individualTaxRec.Sales_Tax_Item__c = appTax.Sales_Tax_Item__c;
                    	if(!TaxCalculation.IsEnhancedTaxCalculationApplicable || appTax.Sales_Tax_Item__r.Rate_Type__c == TaxManagementService.FIXED_RATE) {
                    		individualTaxRec.Tax_Rate__c = appTax.Sales_Tax_Item__r.Rate__c; 
                    	} else {
                    		individualTaxRec.Enhanced_Tax_Amount__c = 0;
                    	}
                    	individualTaxRec.Sales_Tax_Item__c = appTax.Sales_Tax_Item__c; 
                    	individualTaxToInsert.add(individualTaxRec);
                    } 
                } 
            }
            
            Decimal rate = 0;
            if(salesTaxIdToTaxRateMap.containsKey(salesTaxId)) {
                rate = salesTaxIdToTaxRateMap.get(salesTaxId) != null ? salesTaxIdToTaxRateMap.get(salesTaxId) : 0;
            }
            dealUnitPriceAndCostRec.Sales_Tax_Percentage__c = rate - exemptionRate;
            
            if(isTaxIncludingPricing) {
            	if(dealUnitPriceAndCostRec.Deal_Item__r.Is_Rideaway_Pricing_Enabled__c) {
        			dealUnitPriceAndCostRec.Price__c = (dealUnitPriceAndCostRec.Price_When_Tax_Included__c / (1 + (dealUnitPriceAndCostRec.Sales_Tax_Percentage__c / 100))).setScale(2, RoundingMode.HALF_UP);
            	} else {
	            	dealUnitPriceAndCostRec.Price__c = (dealUnitPriceAndCostRec.Price__c != null) ? dealUnitPriceAndCostRec.Price__c : 0;
	            	if(!isCustomerPLUpdate) {
	            		dealUnitPriceAndCostRec.Price__c = (dealUnitPriceAndCostRec.Price__c / (1 + (rate / 100))).setScale(2, RoundingMode.HALF_UP);
	            	}
	            	if(exemptionRate != 0 || isTaxChange) {
	            		dealUnitPriceAndCostRec.Price_When_Tax_Included__c = (dealUnitPriceAndCostRec.Price__c * (1 + dealUnitPriceAndCostRec.Sales_Tax_Percentage__c/100)).setScale(2, RoundingMode.HALF_UP);
	            	}
            	}
            }
            dealUnitPriceAndCostListToUpdate.add(dealUnitPriceAndCostRec);
        }
        if((isCustomerPLUpdate || TaxCalculation.IsEnhancedTaxCalculationApplicable) && individualTaxList.size() > 0) {
        	if(AccessControl.ifObjectIsDeletable('Individual_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
    		delete individualTaxList;
    	}
        if(individualTaxToInsert.size() > 0) {
			DMLUtility.insertSobjectList('Individual_Tax__c', individualTaxToInsert);
        }
        return dealUnitPriceAndCostListToUpdate;
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
				individualTaxRec.Enhanced_Tax_Amount__c = TaxCalculation.getEnhancedTaxAmount(dealItemIdToTaxableAmountMap.get(individualTaxRec.Deal_Unit_Price_Cost__r.Deal_Item__c), individualTaxRec.Sales_Tax_Item__r);
			}
		}
	
		if(individualTaxListToUpdate.size() > 0) {
			DMLUtility.updateSobjectList('Individual_Tax__c', individualTaxListToUpdate);
		}
	}
    
    public static void updateRideawayPricing() {
    	Set<String> dealItemIdSet = new Set<String>();
    	for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : DealUnitPriceAndCostNewList) {
    		if(dealUnitPriceAndCostRec.Type__c != 'Base' && 
    			(dealUnitPriceAndCostRec.Price__c != DealUnitPriceAndCostOldMap.get(dealUnitPriceAndCostRec.Id).Price__c ||
    			 dealUnitPriceAndCostRec.Price_When_Tax_Included__c != DealUnitPriceAndCostOldMap.get(dealUnitPriceAndCostRec.Id).Price_When_Tax_Included__c
    			)) {
    			dealItemIdSet.add(dealUnitPriceAndCostRec.Deal_Item__c);
    		}
    	}
    	if(dealItemIdSet.size() > 0) {
    		OptionAndFeeTriggerHelper.updateRideawayPricingCalculation(dealItemIdSet);
    	}
    }
}