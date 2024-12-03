/**
 * Author: Tarun Khandelwal
 * Since: Oct 21, 2016
 * Name: OptionAndFeeTriggerHelper
 * Description: Trigger executes on after insert event of Option & Fee object
**/
public without sharing class OptionAndFeeTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    public static Boolean isRunningScript = false;
    public static List<Option_Fee__c> OptionAndFeeNewList = new List<Option_Fee__c>();
    public static List<Option_Fee__c> OptionAndFeeOldList = new List<Option_Fee__c>();
    public static Map<Id, Option_Fee__c> OptionAndFeeNewMap = new Map<Id, Option_Fee__c>();
    public static Map<Id, Option_Fee__c> OptionAndFeeOldMap = new Map<Id, Option_Fee__c>();
    
    public static Boolean isTriggerExecute = false;
    public static Boolean isCalculatePriceLevel = true;
    public static Boolean isCalculateTotalOnDeal = true;
    public static Boolean isCustomerPLUpdate = false;
    
    public static void beforeInsertCalculation() {
		setOptionStatus();
    	if(isTriggerExecute) {
    		return;
    	}
    	priceLevelCalculation();
    }
    
    public static void beforeUpdateCalculation() {
    	if(isCalculatePriceLevel && (COTriggerHelper.isResetPricing != null && COTriggerHelper.isResetPricing) && !isTriggerExecute) {
    		priceLevelCalculation();
    	}
		if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c && isCustomerPLUpdate && (COTriggerHelper.isRecalculateTaxes == null || !COTriggerHelper.isRecalculateTaxes)) {
			for(Option_Fee__c optionFeeRec : OptionAndFeeNewList) {
				if(optionFeeRec.Price__c != null && optionFeeRec.Sales_Tax_Percentage__c != null) {
					optionFeeRec.Price_When_Tax_Included__c = (optionFeeRec.Price__c * (1 + optionFeeRec.Sales_Tax_Percentage__c/100)).setScale(2, RoundingMode.HALF_UP);
				}
    		}
		}
    }
    
    public static void afterInsertCalculation() {
    	salesTaxCalculation(Trigger.new);
    }
    
    public static void afterUpdateCalculation() {
    	if((isCustomerPLUpdate && (COTriggerHelper.isRecalculateTaxes != null && COTriggerHelper.isRecalculateTaxes)) || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
    		salesTaxCalculation(Trigger.new);
    		isCustomerPLUpdate = false;
    	}
    	updateTotalOnDeal(OptionAndFeeNewList);
    	updateRideawayPricingAndStampDutyCalculation(OptionAndFeeNewList);
    }
    
    public static void afterDeleteCalculation() {
    	updateTotalOnDeal(OptionAndFeeOldList);
    	updateRideawayPricingAndStampDutyCalculation(OptionAndFeeOldList);
    }
        
	private static void setOptionStatus() {
		for(Option_Fee__c optionFeeRec : OptionAndFeeNewList) {
			if(String.isBlank(optionFeeRec.Status__c)) {
				if(optionFeeRec.Deal_Kit_Header__c != null || optionFeeRec.Part__c != null || optionFeeRec.Labour_Code__c != null
				|| (optionFeeRec.Product__c != null && optionFeeRec.Product__r.Type__c == 'Sublet')) {
					if(optionFeeRec.CO_Line_Item__c != null || optionFeeRec.Service_Order_Line_Item__c != null) {
						optionFeeRec.Status__c = Constants.COMMITTED;
					} else {
						optionFeeRec.Status__c = Constants.UNCOMIITTED;
					}
				} else {
					optionFeeRec.Status__c = Constants.COMMITTED;
				}
			}
        }
	}

    public static void updateTotalOnDeal(List<Option_Fee__c> optionAndFeeList) {
    	Set<String> dealIdSet = new Set<String>();
    	for(Option_Fee__c optionAndFeeRec : optionAndFeeList) {
    		dealIdSet.add(optionAndFeeRec.Deal__c);
    	}
    	if(!COTriggerHelper.isRecalculateCOPLAndTax){
          updateDealTotal(dealIdSet);
      	}
    }
    
    private static void priceLevelCalculation() {
    	Set<Id> partIdSet = new Set<Id>();
        
        Set<Id> dealItemIdSet = new Set<Id>();
        Set<Id> feeIdSet = new Set<Id>();
        Set<Id> labourIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        for(Option_Fee__c optionFeeRec : OptionAndFeeNewList) {
        	if(optionFeeRec.Deal_Kit_Header__c != null) {
                continue;
            }
            dealItemIdSet.add(optionFeeRec.Deal_Item__c); 
            if(optionFeeRec.Part__c != null) {
            	partIdSet.add(optionFeeRec.Part__c);
            } else if(!COTriggerHelper.isRetainItemPrices && optionFeeRec.Fee__c != null) {
            	feeIdSet.add(optionFeeRec.Fee__c);
            } else if(optionFeeRec.Labour_Code__c != null) {
            	labourIdSet.add(optionFeeRec.Labour_Code__c);
            } else if(!COTriggerHelper.isRetainItemPrices && optionFeeRec.Product__c != null) {
            	productIdSet.add(optionFeeRec.Product__c);
            }
        }
        
        partIdSet.remove(null);
        feeIdSet.remove(null);
        dealItemIdSet.remove(null);
        labourIdSet.remove(null);
        productIdSet.remove(null);
        
        Map<Id, Part__c> partIdToPartRecordMap = new Map<Id, Part__c>();
        if(partIdSet.size() > 0) {
        	if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        partIdToPartRecordMap = new Map<Id, Part__c>([select Id, Average_Cost__c, Last_Cost__c, MSRP__c, Retail_Price__c, Sale_Price__c, 
        																Part_Number__c, Description__c, 
        																AvailableParts__c, Qty_Committed__c, Applicable_Tax__c, Applicable_Tax__r.Rate__c
	        																from Part__c where Id IN : partIdSet]);
        }
    	    	        
        Map<Id, Fee__c> feeIdToFeeRecordMap = new Map<Id, Fee__c>();
        if(feeIdSet.size() > 0) {
        	if(AccessControl.ifObjectFieldIsAccessible('Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        	feeIdToFeeRecordMap = new Map<Id, Fee__c>([select Price__c, Taxable__c, Applicable_Tax__c, Applicable_Tax__r.Rate__c
        																from Fee__c where Id IN: feeIdSet]); 
        }
        
        Map<Id, Labour_Code__c> labourIdToLabourRecordMap = new Map<Id, Labour_Code__c>();
        if(labourIdSet.size() > 0) {
        	if(AccessControl.ifObjectFieldIsAccessible('Labour_Code__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            labourIdToLabourRecordMap = new Map<Id, Labour_Code__c>([select Rate__c, Taxable__c, Applicable_Tax__c, Applicable_Tax__r.Rate__c,
                                                                        Fixed_Rate__c
                                                                        from Labour_Code__c where Id IN: labourIdSet]);
    	}
    
    	Map<Id, Product__c> productIdToProductRecordMap = new Map<Id, Product__c>();
        if(productIdSet.size() > 0) {
        	if(AccessControl.ifObjectFieldIsAccessible('Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            productIdToProductRecordMap = new Map<Id, Product__c>([select Price__c, Taxable__c, Applicable_Tax__c, Applicable_Tax__r.Rate__c
        																from Product__c where Id IN: productIdSet]); 
        }
        
    	Map<Id, Deal_Item__c> dealItemIdTodealItemRecMap = new Map<Id, Deal_Item__c>();
        if(dealItemIdSet.size() > 0) {
        	if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        	dealItemIdTodealItemRecMap = new Map<Id, Deal_Item__c>([select Discount_Markup_From_Prive_Level__c, Part_Price_Base_From_Price_Level__c,
        																					Labour_Rate_From_Price_Level__c
                                                                                            from Deal_Item__c Where Id IN : dealItemIdSet]);
        }
        
        Decimal discount;
        String partPriceBase; 
        Decimal laborRate;                                                                                  
		for(Option_Fee__c optionFeeRec : OptionAndFeeNewList) {
            if(optionFeeRec.Deal_Kit_Header__c != null || (COTriggerHelper.isRetainItemPrices && optionFeeRec.Part__c == null && optionFeeRec.Labour_Code__c == null)) {
                continue;
            }
        	discount = (dealItemIdTodealItemRecMap.get(optionFeeRec.Deal_Item__c).Discount_Markup_From_Prive_Level__c == null) ? 0 : dealItemIdTodealItemRecMap.get(optionFeeRec.Deal_Item__c).Discount_Markup_From_Prive_Level__c;
        	partPriceBase = dealItemIdTodealItemRecMap.get(optionFeeRec.Deal_Item__c).Part_Price_Base_From_Price_Level__c;
        	laborRate = (dealItemIdTodealItemRecMap.get(optionFeeRec.Deal_Item__c).Labour_Rate_From_Price_Level__c == null) ? 0 : dealItemIdTodealItemRecMap.get(optionFeeRec.Deal_Item__c).Labour_Rate_From_Price_Level__c;
        	
            priceLevelCalculation(partPriceBase, discount, optionFeeRec, partIdToPartRecordMap, feeIdToFeeRecordMap, labourIdToLabourRecordMap, productIdToProductRecordMap, laborRate);
        }                                                                                            	
    }
    
    private static void priceLevelCalculation(String priceLevel_baseValueField, Decimal priceLevel_discountMarkup, Option_Fee__c optionFeeRec, 
    											Map<Id, Part__c> partIdToPartRecordMap, Map<Id, Fee__c> feeIdToFeeRecordMap,
    											Map<Id, Labour_Code__c> labourIdToLabourRecordMap, Map<Id, Product__c> productIdToProductRecordMap, Decimal laborRate) {
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal appTaxRate;
        if(optionFeeRec.Part__c != null) {
	        String pricingField = TaxCalculation.getPricingFieldByPLBaseValueField(priceLevel_baseValueField);
	        
	        if(!pricingField.containsIgnoreCase('Average_Cost__c') && partIdToPartRecordMap.get(optionFeeRec.Part__c).get(pricingField) == null) {
	            partIdToPartRecordMap.get(optionFeeRec.Part__c).put(pricingField, 0);
	            optionFeeRec.Retail__c = 0;
	        } else {
				Decimal baseValue;
				if(pricingField.containsIgnoreCase('Average_Cost__c') && (partIdToPartRecordMap.get(optionFeeRec.Part__c).Average_Cost__c == null || partIdToPartRecordMap.get(optionFeeRec.Part__c).Average_Cost__c == 0)) {
					baseValue = partIdToPartRecordMap.get(optionFeeRec.Part__c).Last_Cost__c != null ? partIdToPartRecordMap.get(optionFeeRec.Part__c).Last_Cost__c : 0;
				} else {
					baseValue = Decimal.valueOf(String.valueOf(partIdToPartRecordMap.get(optionFeeRec.Part__c).get(pricingField)));
				}
				if((Trigger.isInsert || isCustomerPLUpdate) && isTaxIncludingPricing) {
                    if(priceLevel_discountMarkup == 0 && !TaxCalculation.COST_FIELDS_SET.contains(pricingField)) {
                        optionFeeRec.Price_When_Tax_Included__c = baseValue.setScale(2, RoundingMode.HALF_UP);
                    } else {
                        optionFeeRec.Price_When_Tax_Included__c = null;
                    }
                } 
                if(optionFeeRec.Deal_Kit_Header__c != null) {
                    optionFeeRec.Retail__c = baseValue;
                } else {
		            if(isTaxIncludingPricing && !TaxCalculation.COST_FIELDS_SET.contains(pricingField) && partIdToPartRecordMap.get(optionFeeRec.Part__c).Applicable_Tax__c != null) {
		                appTaxRate = partIdToPartRecordMap.get(optionFeeRec.Part__c).Applicable_Tax__r.Rate__c;
		                if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
		                    appTaxRate = 0;
		                }
		                Decimal preTaxPricing = baseValue / (1 + (appTaxRate / 100));
                        optionFeeRec.Retail__c = preTaxPricing + (preTaxPricing * priceLevel_discountMarkup / 100);
		            } else {
                        optionFeeRec.Retail__c = baseValue + (baseValue * priceLevel_discountMarkup / 100);
		            }
	            }
	        }
        
        } else if(optionFeeRec.Fee__c != null) {
        	Decimal feePrice;
			if(optionFeeRec.Is_Environmental_Fee__c || optionFeeRec.Is_Linked_Fee__c) { 
				if(isTaxIncludingPricing) {
					feePrice = optionFeeRec.Price_When_Tax_Included__c;
				} else {
				feePrice = optionFeeRec.Price__c;
					}
			} else {
				feePrice = feeIdToFeeRecordMap.get(optionFeeRec.Fee__c).Price__c;
			}

			if(COTriggerHelper.isRecalculateCOPLAndTax) {
				feePrice = optionFeeRec.Price__c != null ? optionFeeRec.Price__c : 0;
				optionFeeRec.Price_When_Tax_Included__c = null;
				optionFeeRec.Retail__c = feePrice;
			} else if(isTaxIncludingPricing) {
        		appTaxRate = feeIdToFeeRecordMap.get(optionFeeRec.Fee__c).Applicable_Tax__r.Rate__c;
                if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
                    appTaxRate = 0;
                }
                Decimal preTaxPricing = feePrice / (1 + (appTaxRate / 100));
                optionFeeRec.Retail__c = preTaxPricing;
				if(Trigger.isInsert || isCustomerPLUpdate) {
                    optionFeeRec.Price_When_Tax_Included__c = feePrice;
                }
        	} else {
        		optionFeeRec.Retail__c = feePrice;
        	}
        } else if(optionFeeRec.Labour_Code__c != null) {
        	Decimal rate = laborRate;
        	if(labourIdToLabourRecordMap.get(optionFeeRec.Labour_Code__c).Fixed_Rate__c) {
                optionFeeRec.Retail__c = labourIdToLabourRecordMap.get(optionFeeRec.Labour_Code__c).Rate__c;
            	rate = labourIdToLabourRecordMap.get(optionFeeRec.Labour_Code__c).Rate__c;
            } else {
            	if(laborRate == null || laborRate == 0) {
            		optionFeeRec.Retail__c = labourIdToLabourRecordMap.get(optionFeeRec.Labour_Code__c).Rate__c;
            		rate = labourIdToLabourRecordMap.get(optionFeeRec.Labour_Code__c).Rate__c;
                } else {
                	optionFeeRec.Retail__c = laborRate;
            	}
            }
			optionFeeRec.Retail__c = rate = (optionFeeRec.Retail__c != null ? optionFeeRec.Retail__c : 0);
            if(isTaxIncludingPricing) {
            	appTaxRate = labourIdToLabourRecordMap.get(optionFeeRec.Labour_Code__c).Applicable_Tax__r.Rate__c;
            	if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
                    appTaxRate = 0;
        		} 
                Decimal preTaxPricing = optionFeeRec.Retail__c / (1 + (appTaxRate / 100));
                optionFeeRec.Retail__c = preTaxPricing;
                if(Trigger.isInsert || isCustomerPLUpdate) {
                    optionFeeRec.Price_When_Tax_Included__c = rate;
                }
            }
        } else if(optionFeeRec.Product__c != null) {
        	Decimal productPrice = productIdToProductRecordMap.get(optionFeeRec.Product__c).Price__c;
        	if(isTaxIncludingPricing) {
        		appTaxRate = productIdToProductRecordMap.get(optionFeeRec.Product__c).Applicable_Tax__r.Rate__c;
                if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
                    appTaxRate = 0;
                }
                Decimal preTaxPricing = productPrice / (1 + (appTaxRate / 100));
                optionFeeRec.Retail__c = preTaxPricing;
                if(Trigger.isInsert || isCustomerPLUpdate) {
                    optionFeeRec.Price_When_Tax_Included__c = productPrice;
                }
        	} else {
        		optionFeeRec.Retail__c = productPrice;
        	}
        }

		optionFeeRec.Retail__c = (optionFeeRec.Retail__c != null) ? optionFeeRec.Retail__c.setScale(2, RoundingMode.HALF_UP) : 0;
        if((trigger.isInsert || isCustomerPLUpdate) && (optionFeeRec.Fee__c != null || optionFeeRec.Part__c != null || optionFeeRec.Labour_Code__c != null || optionFeeRec.Product__c != null)) {
	        
	        optionFeeRec.Price__c = optionFeeRec.Retail__c;
	        if(optionFeeRec.Part__c != null) {
	        	Decimal price = TaxCalculation.getPartPrice(optionFeeRec.Price__c, partIdToPartRecordMap.get(optionFeeRec.Part__c).Sale_Price__c, appTaxRate);
	        	if(price != optionFeeRec.Price__c) {
                	optionFeeRec.Price__c = price;
                	optionFeeRec.Price_When_Tax_Included__c = null;
                }
        	}
        }
    }
    
    public static void salesTaxCalculation(List<Option_Fee__c> optionAndFeeIdList) {
    	if(isTriggerExecute) {
    		return;
    	}
        isTriggerExecute = true;
        // Tax Exemption List
        List<Option_Fee__c> optionAndFeeList = [SELECT Applicable_Tax__c, Part__c, Part__r.Taxable__c, Part__r.Applicable_Tax__c, Part__r.Applicable_Tax__r.Rate__c, Deal_Kit_Header__c,
        												Fee__c, Fee__r.Taxable__c, Fee__r.Applicable_Tax__c, Fee__r.Applicable_Tax__r.Rate__c, Qty__c, Deal_Item__r.Deal__r.Is_Tax_Based_On_Customer_Address__c, 
        												Labour_Code__c, Labour_Code__r.Taxable__c, Labour_Code__r.Applicable_Tax__c, Labour_Code__r.Applicable_Tax__r.Rate__c,
        												Product__c, Product__r.Type__c, Product__r.Taxable__c, Product__r.Applicable_Tax__c, Product__r.Applicable_Tax__r.Rate__c, Price_When_Tax_Included__c,
        												Deal_Item__r.Deal__r.CO_Header__c, Deal_Item__r.Deal__r.CO_Header__r.Customer__c, Price__c, Deal_Item__r.Deal__c,
        												Deal_Item__r.Applicable_Tax__c, Deal_Item__r.Applicable_Tax__r.Rate__c, Deal_Item__r.Taxable__c, Deal_Item__r.Unit_Tax_Applicable_On__c, 
        												Deal_Item__r.Discount_Markup_From_Prive_Level__c, Sales_Tax_Percentage__c, 
        												(Select Id from Individual_Taxes__r)  
    													FROM Option_Fee__c where Id IN: optionAndFeeIdList AND Deal_Kit_Header__c = null AND Deal__r.Invoice_Number__c = null];
    	
    	
		TaxEngine.applySalesTaxonOptionFeeList(optionAndFeeList);
    }
    
    public static void updateDealTotal(Set<String> dealIdSet) {
    	if(dealIdSet.size() == 0) { 
    		return;
    	}
    	Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
    	
    	List<Deal__c> dealList = [Select Deal_Section_Trade_Only__c, Total__c, Type__c, Deal_Tax_Total__c, CO_Header__r.Deal_Total__c, F_I_Total__c, F_I_Tax_Total__c, Sales_Tax_Total__c, 
    									Is_Tax_Based_On_Customer_Address__c, 
                                        (Select Price__c, Cost__c, Qty__c, Product__r.Type__c, Price_When_Tax_Included__c, Sales_Tax_Percentage__c,
										Applicable_Tax__c, Deal_Item__r.Unit_Tax_Applicable_On__c, Part__r.Average_Cost__c, Part__r.Last_Cost__c, Labour_Code__r.Cost_Method__c, Deal_Kit_Header__c, 
										Labour_Code__r.Cost_Rate__c, Product__r.Cost__c, Product__r.Cost_Method__c, Fee__r.Cost_Method__c, Fee__r.Is_Include_In_Profit_Calculation__c, 
										CO_Line_Item__c, Service_Order_Line_Item__c, Status__c, Fee__r.Cost_Rate__c from Options_Fees__r), 
    									(Select Taxable__c, Applicable_Tax__c, Type__c, Agreed_Value__c, Actual_Cash_Value__c, Customer_Owned_Unit__r.Total_Cost__c,
                                        Default_Unit_Sales_Tax_Percentage__c, Stamp_Duty_Total__c, Customer_Owned_Unit__r.Consignment__c, Customer_Owned_Unit__r.Agreed_Payout__c, Lien_Payout__c from Deal_Items__r),
    									(select Taxable_Amount_for_Section_Header__c, Tax_Rate__c, Sales_Tax_Item__r.Name__c from Individual_Taxes__r), 
										(select Id, Price__c, Applicable_Tax__c from F_I_Products__r WHERE Applicable_Tax__c != null), 
    									(Select Id, F_I_Product_Tax_Total__c, F_I_Total__c, Withheld_F_I_Total__c, Total_Commission__c from Deal_Finances__r)
    								from Deal__c where Id IN: dealIdSet];
    	Map<String, List<Deal_Unit_Price_Cost__c>> dealIdToDealUnitPriceCostListMap = getDealIdToDealUnitPriceCostListMap(dealList);							
		populateTotalsOnDeal(dealList, dealIdToDealUnitPriceCostListMap);
    }
    
    public static Map<String, List<Deal_Unit_Price_Cost__c>> getDealIdToDealUnitPriceCostListMap(List<Deal__c> dealList) {
    	Set<String> dealItemIdSet = new Set<String>();
    	for(Deal__c dealRec : dealList) {
    		for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
    			if(dealItemRec.Type__c == 'Unit') {
    				dealItemIdSet.add(dealItemRec.Id);
    			}
			}
    	}
		
		List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = 
				[Select Applicable_Tax__c, Deal_Item__r.Deal__c, Total_Price__c, Type__c, Deal_Item__c, Tax_Amount__c, Price_When_Tax_Included__c, Qty__c, Price__c, Sales_Tax_Percentage__c,	
				    (select Taxable_Amount__c, Tax_Rate__c, Form_Label__c, Sales_Tax_Item__r.Name__c
							from Individual_Taxes__r) from Deal_Unit_Price_Cost__c where Deal_Item__c IN: dealItemIdSet];
							
    	Map<String, List<Deal_Unit_Price_Cost__c>> dealIdToDealUnitPriceCostListMap = new Map<String, List<Deal_Unit_Price_Cost__c>>();
		for(Deal_Unit_Price_Cost__c dealUnitPriceCostRec : dealUnitPriceAndCostList) {
			if(dealUnitPriceCostRec.Deal_Item__r.Deal__c != null) {
	    		if(!dealIdToDealUnitPriceCostListMap.containsKey(dealUnitPriceCostRec.Deal_Item__r.Deal__c)) {
	    			dealIdToDealUnitPriceCostListMap.put(dealUnitPriceCostRec.Deal_Item__r.Deal__c, new List<Deal_Unit_Price_Cost__c>());
	    		}
				dealIdToDealUnitPriceCostListMap.get(dealUnitPriceCostRec.Deal_Item__r.Deal__c).add(dealUnitPriceCostRec);
			}
		}
		return dealIdToDealUnitPriceCostListMap;
    }
    
    private static void populateTotalsOnDeal(List<Deal__c> dealList, Map<String, List<Deal_Unit_Price_Cost__c>> dealIdToDealUnitPriceCostListMap) {
    	if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
    	List<Deal__c> dealListToUpdate = new List<Deal__c>();
		Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
		
		Map<String, List<Individual_Tax__c>> dealIdToRelatedIndividualTaxListMap = new Map<String, List<Individual_Tax__c>>();
		if(!isTaxIncludingPricing) {
			List<Individual_Tax__c> individualTaxList = TaxEngine.calculateDealTaxesByInvoice(dealList, dealIdToDealUnitPriceCostListMap);
			
	    	for(Individual_Tax__c individualTaxRec : individualTaxList) {
	    		if(!dealIdToRelatedIndividualTaxListMap.containsKey(individualTaxRec.Deal__c)) {
	    			dealIdToRelatedIndividualTaxListMap.put(individualTaxRec.Deal__c, new List<Individual_Tax__c>{individualTaxRec});
	    		} else {
	    			dealIdToRelatedIndividualTaxListMap.get(individualTaxRec.Deal__c).add(individualTaxRec);
	    		}
	    	}
		}
        
        Map<String, Deal_Item__c> dealItemIdToRecMap = new Map<String, Deal_Item__c>();
        List<Sales_Tax_Item__c> salesTaxItemList = [select Forms_Label__c, Name__c from Sales_Tax_Item__c limit: SOQLUtil.getAvailableQueryRowsLimit()];
        for(Deal__c dealRec : dealList) {
    		//Decimal total = 0;
    		dealRec.Sales_Tax_Total__c = dealRec.Withheld_F_I_Total__c = 0;
    		Decimal totalSalesTax = 0;
    		Decimal partTotal = 0;
    		Decimal laborTotal = 0;
    		Decimal feeTotal = 0;
    		Decimal warrantyProductTotal = 0;
    		Decimal subletTotal = 0;
    		Decimal otherProductTotal = 0;
    		Decimal productTotal = 0;
    		Decimal unitTotal = 0;
            Decimal fAndITotal = 0;
    		Decimal fAndITaxTotal = 0;
    		Decimal stampDutyTotal = 0;
    		Decimal tradeInTotal = 0;
    		Decimal tradeInTaxTotal = 0;
    		Decimal lienPayoutTotal = 0;
			Decimal financeCommissionTotal = 0;
    		
    		//Pre Tax Deal Totals
    		Decimal preTaxUnitTotal = 0; 
    		Decimal preTaxTradeInTotal = 0;
    		Decimal preTaxPartTotal = 0;
    		Decimal preTaxLaborTotal = 0;
    		Decimal preTaxOtherProductTotal = 0;
    		Decimal preTaxFeeTotal = 0;
    		
			for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
				Deal_Item__c dealItem;
				if(dealItemRec.Type__c == 'Unit') {
					dealItem = new Deal_Item__c(Id = dealItemRec.Id, Part_Total__c = 0, Fee_Total__c = 0, 
					Labour_Total__c = 0, Warranty_Product_Total__c = 0, Sublet_Total__c = 0, Other_Product_Total__c = 0, Base_Price__c = 0, 
					Factory_Option_Total__c = 0, Dealer_Option_Total__c = 0, Unit_Cost__c = (dealItemRec.Customer_Owned_Unit__r.Consignment__c) ? dealItemRec.Customer_Owned_Unit__r.Agreed_Payout__c : dealItemRec.Customer_Owned_Unit__r.Total_Cost__c,
					Unit_Option_Cost__c = 0, Fee_Total_Included_In_Profitability__c = 0);
				} else if(dealItemRec.Actual_Cash_Value__c != null) {
					dealItem = new Deal_Item__c(Id = dealItemRec.Id, Unit_Cost__c = (dealItemRec.Actual_Cash_Value__c * -1));
				}
				if(dealItem != null) dealItemIdToRecMap.put(dealItemRec.Id, dealItem);
			}

    		for(Option_Fee__c optionFeeRec : dealRec.Options_Fees__r) {
    			optionFeeRec.Price__c = (optionFeeRec.Price__c != null) ? optionFeeRec.Price__c : 0;
    			optionFeeRec.Price_When_Tax_Included__c = (optionFeeRec.Price_When_Tax_Included__c != null) ? optionFeeRec.Price_When_Tax_Included__c : 0;
    			optionFeeRec.Qty__c = (optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 0;
    			optionFeeRec.Sales_Tax_Percentage__c = (optionFeeRec.Sales_Tax_Percentage__c != null) ? optionFeeRec.Sales_Tax_Percentage__c : 0;
    			
				Deal_Item__c dealItemRec = dealItemIdToRecMap.get(optionFeeRec.Deal_Item__c);
				dealItemRec.Unit_Option_Cost__c += getOptionAndFeeCost(optionFeeRec);
    			if(!isTaxIncludingPricing) {
		    		if(optionFeeRec.Part__c != null) {
		    			partTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			preTaxPartTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			dealItemRec.Part_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    		} else if(optionFeeRec.Labour_Code__c != null) {
		    			laborTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			preTaxLaborTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			dealItemRec.Labour_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    		} else if(optionFeeRec.Fee__c != null) {
		    			feeTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			preTaxFeeTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			dealItemRec.Fee_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
						dealItemRec.Fee_Total_Included_In_Profitability__c += (optionFeeRec.Fee__r.Is_Include_In_Profit_Calculation__c ? (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP) : 0);	
		    		} else if(optionFeeRec.Product__c != null) {
		    			if(optionFeeRec.Product__r.Type__c == Constants.WARRANTY_PLAN) {
		    				warrantyProductTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    				dealItemRec.Warranty_Product_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			} else if(optionFeeRec.Product__r.Type__c == Constants.SUBLET) {
		    				subletTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    				dealItemRec.Sublet_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			} else {
		    				otherProductTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    				dealItemRec.Other_Product_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			}
		    			//It will include all 4 type of products for home search
		    			preTaxOtherProductTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			productTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    		} 
    				totalSalesTax += (optionFeeRec.Qty__c * optionFeeRec.Price__c * optionFeeRec.Sales_Tax_Percentage__c)/100;
    			} else {
    				if(optionFeeRec.Part__c != null) {
		    			partTotal += (optionFeeRec.Qty__c * optionFeeRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
		    			preTaxPartTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			dealItemRec.Part_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);

		    		} else if(optionFeeRec.Labour_Code__c != null) {
		    			laborTotal += (optionFeeRec.Qty__c * optionFeeRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
		    			preTaxLaborTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			dealItemRec.Labour_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			
		    		} else if(optionFeeRec.Fee__c != null) {
		    			feeTotal += (optionFeeRec.Qty__c * optionFeeRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
		    			preTaxFeeTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			dealItemRec.Fee_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
						dealItemRec.Fee_Total_Included_In_Profitability__c += (optionFeeRec.Fee__r.Is_Include_In_Profit_Calculation__c ? (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP) : 0);	
		    			
		    		} else if(optionFeeRec.Product__c != null) {
		    			if(optionFeeRec.Product__r.Type__c == Constants.WARRANTY_PLAN) {
		    				warrantyProductTotal += (optionFeeRec.Qty__c * optionFeeRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
		    				dealItemRec.Warranty_Product_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			} else if(optionFeeRec.Product__r.Type__c == Constants.SUBLET) {
		    				subletTotal += (optionFeeRec.Qty__c * optionFeeRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
		    				dealItemRec.Sublet_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			}  else {
		    				otherProductTotal += (optionFeeRec.Qty__c * optionFeeRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
		    				dealItemRec.Other_Product_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			}
		    			//It will include all 4 type of products for home search
		    			preTaxOtherProductTotal += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
		    			productTotal += (optionFeeRec.Qty__c * optionFeeRec.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
		    		} 
	    			dealRec.Sales_Tax_Total__c += (optionFeeRec.Qty__c * optionFeeRec.Price__c * optionFeeRec.Sales_Tax_Percentage__c)/100;
    			}
    		}
    		
    		if(dealIdToDealUnitPriceCostListMap.containsKey(dealRec.Id)) {
    			for(Deal_Unit_Price_Cost__c dupcRec : dealIdToDealUnitPriceCostListMap.get(dealRec.Id)) {
    				Deal_Item__c dealItemRec = dealItemIdToRecMap.get(dupcRec.Deal_Item__c);
	    			
    				dupcRec.Price__c = (dupcRec.Price__c != null) ? dupcRec.Price__c : 0;
	    			dupcRec.Price_When_Tax_Included__c = (dupcRec.Price_When_Tax_Included__c != null) ? dupcRec.Price_When_Tax_Included__c : 0;
	    			dupcRec.Qty__c = (dupcRec.Qty__c != null) ? dupcRec.Qty__c : 0;
	    			dupcRec.Sales_Tax_Percentage__c = (dupcRec.Sales_Tax_Percentage__c != null) ? dupcRec.Sales_Tax_Percentage__c : 0;
    				
    				Decimal preTaxTotalPrice = (((dupcRec.Price__c != null) ? dupcRec.Price__c : 0) * ((dupcRec.Qty__c != null) ? dupcRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
	    			
                    if(dupcRec.Type__c == 'Base') {
	    				dealItemRec.Base_Price__c += preTaxTotalPrice;
	    			} else if(dupcRec.Type__c == 'Factory') {
	    				dealItemRec.Factory_Option_Total__c += preTaxTotalPrice;
	    			} else if(dupcRec.Type__c == 'Dealer') {
	    				dealItemRec.Dealer_Option_Total__c += preTaxTotalPrice;
	    			}
	    			
    				if(!isTaxIncludingPricing) {
	    				unitTotal += (((dupcRec.Price__c != null) ? dupcRec.Price__c : 0) * ((dupcRec.Qty__c != null) ? dupcRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
    					totalSalesTax += (dupcRec.Qty__c * dupcRec.Price__c * dupcRec.Sales_Tax_Percentage__c)/100;
    				} else {
    					unitTotal += (((dupcRec.Price_When_Tax_Included__c != null) ? dupcRec.Price_When_Tax_Included__c : ((dupcRec.Price__c * (1 + dupcRec.Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP)) * 
	    							((dupcRec.Qty__c != null) ? dupcRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
		    			dealRec.Sales_Tax_Total__c += (dupcRec.Qty__c * dupcRec.Price__c * dupcRec.Sales_Tax_Percentage__c)/100;
    				}
    				preTaxUnitTotal += (((dupcRec.Price__c != null) ? dupcRec.Price__c : 0) * ((dupcRec.Qty__c != null) ? dupcRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
    			}
    		}
    		
    		for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
    			if(dealItemRec.Type__c == 'Trade In') {
    				dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c.setScale(2, RoundingMode.HALF_UP) : 0;
    				dealItemRec.Actual_Cash_Value__c = (dealItemRec.Actual_Cash_Value__c != null) ? dealItemRec.Actual_Cash_Value__c.setScale(2, RoundingMode.HALF_UP) : 0;
    				dealItemRec.Default_Unit_Sales_Tax_Percentage__c = (dealItemRec.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItemRec.Default_Unit_Sales_Tax_Percentage__c : 0;
    				tradeInTotal += dealItemRec.Agreed_Value__c;
    				
    				Decimal tradeInTax = 0;
                    if(!isTaxIncludingPricing) {
    					preTaxTradeInTotal -= dealItemRec.Agreed_Value__c;
    					tradeInTax = ((dealItemRec.Agreed_Value__c * dealItemRec.Default_Unit_Sales_Tax_Percentage__c)/100).setScale(2, RoundingMode.HALF_UP);
    					totalSalesTax -= tradeInTax;
                    } else {
    					preTaxTradeInTotal -= (dealItemRec.Agreed_Value__c / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100)).setScale(2, RoundingMode.HALF_UP);
    					tradeInTax = (dealItemRec.Agreed_Value__c - (dealItemRec.Agreed_Value__c / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP);
    					dealRec.Sales_Tax_Total__c -= tradeInTax;
                    }
    				tradeInTaxTotal += tradeInTax;
                    
    				lienPayoutTotal += (dealItemRec.Lien_Payout__c != null) ? dealItemRec.Lien_Payout__c : 0;
    			} else {
    				stampDutyTotal += (dealItemRec.Stamp_Duty_Total__c != null) ? dealItemRec.Stamp_Duty_Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
    			}
    		}
    		
    		for(Deal_Finance__c dealFinanceRec : dealRec.Deal_Finances__r) {
				fAndITotal += (dealFinanceRec.F_I_Total__c != null) ? dealFinanceRec.F_I_Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
				if(isTaxIncludingPricing) {
					fAndITaxTotal += (dealFinanceRec.F_I_Product_Tax_Total__c != null) ? dealFinanceRec.F_I_Product_Tax_Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
				}
				dealRec.Withheld_F_I_Total__c += (dealFinanceRec.Withheld_F_I_Total__c != null) ? dealFinanceRec.Withheld_F_I_Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
				financeCommissionTotal += (dealFinanceRec.Total_Commission__c != null) ? dealFinanceRec.Total_Commission__c.setScale(2, RoundingMode.HALF_UP) : 0;
			}
    		
    		if(!isRunningScript && !isTaxIncludingPricing) {
	    		totalSalesTax = 0;
		    	if(dealIdToRelatedIndividualTaxListMap.containsKey(dealRec.Id)) {
					Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(dealIdToRelatedIndividualTaxListMap.get(dealRec.Id), salesTaxItemList);
					for(String taxName : salesTaxNameToTaxValue.keySet()) {
						totalSalesTax += salesTaxNameToTaxValue.get(taxName); 
					}
				}
			}
		
    		dealRec.Deal_Tax_Total__c = (isRunningScript ? dealRec.Deal_Tax_Total__c : totalSalesTax);
    		dealRec.Sales_Tax_Total__c = ((isTaxIncludingPricing ? (dealRec.Sales_Tax_Total__c) : dealRec.Deal_Tax_Total__c) + fAndITaxTotal).setScale(2, RoundingMode.HALF_UP);
    		dealRec.Fee_Total__c = feeTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Labour_Total__c = laborTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Part_Total__c = partTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Product_Total__c = productTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Warranty_Product_Total__c = warrantyProductTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Sublet_Total__c = subletTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Other_Product_Total__c = otherProductTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Unit_Price_And_Cost_Total__c = unitTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Trade_In_Total__c = -tradeInTotal.setScale(2, RoundingMode.HALF_UP);
    		dealRec.Trade_In_Tax_Total__c = -tradeInTaxTotal.setScale(2, RoundingMode.HALF_UP);
    		
    		dealRec.Stamp_Duty_Total__c = stampDutyTotal.setScale(2, RoundingMode.HALF_UP);
            dealRec.F_I_Total__c = fAndITotal.setScale(2, RoundingMode.HALF_UP);
            dealRec.F_I_Tax_Total__c = fAndITaxTotal.setScale(2, RoundingMode.HALF_UP);
            dealRec.Lien_Payout_Total__c = lienPayoutTotal.setScale(2, RoundingMode.HALF_UP);
			dealRec.Total_Finance_Commission__c = financeCommissionTotal.setScale(2, RoundingMode.HALF_UP);
            
            // Pre Tax Deal totals
            dealRec.Pre_Tax_Unit_Price_And_Cost_Total__c = preTaxUnitTotal.setScale(2, RoundingMode.HALF_UP);
            dealRec.Pre_Tax_Trade_In_Total__c = preTaxTradeInTotal.setScale(2, RoundingMode.HALF_UP);
            dealRec.Pre_Tax_Part_Total__c = preTaxPartTotal.setScale(2, RoundingMode.HALF_UP);
            dealRec.Pre_Tax_Labour_Total__c = preTaxLaborTotal.setScale(2, RoundingMode.HALF_UP);
            dealRec.Pre_Tax_Other_Product_Total__c = preTaxOtherProductTotal.setScale(2, RoundingMode.HALF_UP);
            dealRec.Pre_Tax_Fee_Total__c = preTaxFeeTotal.setScale(2, RoundingMode.HALF_UP);
            
    		dealListToUpdate.add(dealRec);
    	}
    	if(dealListToUpdate.size() > 0) {
			DMLUtility.updateSobjectList('Deal__c', dealListToUpdate);
    		
    		if(!dealItemIdToRecMap.isEmpty()) {
    			DealItemTriggerHelper.isForceStopTrigger = true;
				DMLUtility.updateSobjectList('Deal_Item__c', dealItemIdToRecMap.values());
	    		DealItemTriggerHelper.isForceStopTrigger = false;
	    	}
    	}
    	if(isRunningScript) return;
    	Map<Id, CO_Header__c> coHeaderIdToRecMapToUpdate = new Map<Id, CO_Header__c>();
    	Decimal subtotal = 0;
    	for(Deal__c dealRec : dealListToUpdate) {
    		// Update totals on CO Header
    		subtotal = dealRec.Fee_Total__c + dealRec.Labour_Total__c + dealRec.Part_Total__c + dealRec.Product_Total__c 
    									+ dealRec.Unit_Price_And_Cost_Total__c + dealRec.Trade_In_Total__c + dealRec.Stamp_Duty_Total__c + dealRec.Lien_Payout_Total__c;
    									
    		CO_Header__c coHeaderRec = new CO_Header__c(Id = dealRec.CO_Header__c, Deal_Subtotal__c = subTotal);
    		coHeaderRec.Deal_Total__c = subTotal.setScale(2, RoundingMode.HALF_UP);
    		
    		
    		if(!isTaxIncludingPricing) {
				coHeaderRec.Deal_Total__c += dealRec.Deal_Tax_Total__c.setScale(2, RoundingMode.HALF_UP);
    			if(dealRec.Type__c == 'Financed') {
	    			coHeaderRec.Deal_Subtotal__c += (dealRec.F_I_Total__c);
    			 	coHeaderRec.Deal_Total__c += (dealRec.F_I_Total__c + dealRec.F_I_Tax_Total__c);
	    		}
    		} else if(dealRec.Type__c == 'Financed') {
    			coHeaderRec.Deal_Subtotal__c += (dealRec.F_I_Total__c + dealRec.F_I_Tax_Total__c);
    			coHeaderRec.Deal_Total__c += (dealRec.F_I_Total__c + dealRec.F_I_Tax_Total__c);
			 	
    		}
    		
    		//coHeaderRec.Deal_Tax_Amount__c = dealRec.Deal_Tax_Total__c;
    		
    		if(!coHeaderIdToRecMapToUpdate.containsKey(coHeaderRec.Id)) {
    			coHeaderIdToRecMapToUpdate.put(coHeaderRec.Id, coHeaderRec);
    		}
    	}
    	
    	TaxCalculation.populateOrderTotal(coHeaderIdToRecMapToUpdate);
    }
    
    public static void updateRideawayPricingAndStampDutyCalculation(List<Option_Fee__c> optionFeeList) {
    	Set<String> dealItemIdSet = new Set<String>();
    	for(Option_Fee__c optionFeeRec : optionFeeList) {
    		dealItemIdSet.add(optionFeeRec.Deal_Item__c);
    	}
    	updateRideawayPricingAndStampDuty(dealItemIdSet);
    }
    
    public static void updateRideawayPricingAndStampDuty(Set<String> dealItemIdSet) {
    	if(GeneralConfiguration.getCompanyLocale() == 'Australia') {
	    	if(dealItemIdSet.size() > 0) { 
		    	Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
		    	List<Deal_Item__c> dealItemList = [Select Is_Rideaway_Pricing_Enabled__c, Rideaway_Pricing_Total__c,Stamp_Duty_Total__c, Dutiable_Value__c, Stamp_Duty_Calculators__c, Stamp_Duty_Calculators__r.Calculation_Method__c, 
													Stamp_Duty_Calculators__r.L1_Per__c, Stamp_Duty_Calculators__r.L1_Rate__c, Stamp_Duty_Calculators__r.L1_Value__c, Stamp_Duty_Calculators__r.L2_Per__c, Stamp_Duty_Calculators__r.L2_Rate__c, 
													Stamp_Duty_Calculators__r.L2_Value__c, Stamp_Duty_Calculators__r.L3_Per__c, Stamp_Duty_Calculators__r.L3_Rate__c, Stamp_Duty_Calculators__r.L3_Value__c, Stamp_Duty_Calculators__r.L4_Per__c, 
													Stamp_Duty_Calculators__r.L4_Rate__c, Stamp_Duty_Calculators__r.L4_Value__c, Stamp_Duty_Calculators__r.Maximum__c, Stamp_Duty_Calculators__r.Minimum__c, 
    												(Select Price__c, Price_When_Tax_Included__c, Qty__c, Sales_Tax_Percentage__c, Fee__c, Product__c from Options_Fees__r 
    													WHERE Part__c != null OR Labour_Code__c != null OR Fee__c != null OR (Product__c != null AND Product__r.Type__c = 'Sublet')),
    												(Select Price__c, Price_When_Tax_Included__c, Qty__c, Sales_Tax_Percentage__c, Total_Price__c, Type__c from Deal_Unit_Prices_Costs__r)
    											FROM Deal_Item__c where Id IN: dealItemIdSet];
    											
				List<Sobject> sobjectlistToUpdate = new List<Sobject>();
				for(Deal_Item__c dealItemRec : dealItemList) {
					Decimal partsAndLaborTotal = 0;
					Decimal feeTotal = 0;
					Decimal subletTotal = 0;
					for(Option_Fee__c optionFeeRec : dealItemRec.Options_Fees__r) {
						if(!isTaxIncludingPricing) {
							if(optionFeeRec.Fee__c != null) {
								feeTotal += (((optionFeeRec.Price__c != null) ? optionFeeRec.Price__c : 0) * ((optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
							} else if(optionFeeRec.Product__c != null) {
								subletTotal += (((optionFeeRec.Price__c != null) ? optionFeeRec.Price__c : 0) * ((optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
							} else {
								partsAndLaborTotal += (((optionFeeRec.Price__c != null) ? optionFeeRec.Price__c : 0) * ((optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
							}
						} else {
							if(optionFeeRec.Fee__c != null) {
								feeTotal += (((optionFeeRec.Price_When_Tax_Included__c != null) ? optionFeeRec.Price_When_Tax_Included__c : ((optionFeeRec.Price__c * (1 + optionFeeRec.Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP)) * 
										((optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
							} else if(optionFeeRec.Product__c != null) {
								subletTotal += (((optionFeeRec.Price_When_Tax_Included__c != null) ? optionFeeRec.Price_When_Tax_Included__c : ((optionFeeRec.Price__c * (1 + optionFeeRec.Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP)) *
										((optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
							} else {
								partsAndLaborTotal += (((optionFeeRec.Price_When_Tax_Included__c != null) ? optionFeeRec.Price_When_Tax_Included__c : ((optionFeeRec.Price__c * (1 + optionFeeRec.Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP)) * 
										((optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 0)).setScale(2, RoundingMode.HALF_UP);
							}
						}
					}
					sobjectlistToUpdate.add(dealItemRec);
					Deal_Unit_Price_Cost__c basePriceRec = updateBasePriceAndStampDuty(dealItemRec, partsAndLaborTotal, feeTotal, subletTotal, isTaxIncludingPricing);
					if(basePriceRec != null && basePriceRec.Id != null) {
						sobjectlistToUpdate.add(basePriceRec);
					}
				}
				
				if(!sobjectlistToUpdate.isEmpty()) {
					sobjectlistToUpdate.sort();
					if(!AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c')) { throw new BlackPurlException('Deal_Item__c' + DMLUtility.NOT_UPDATABLE); }
					if(!AccessControl.ifObjectFieldIsUpdateable('Deal_Unit_Price_Cost__c')) { throw new BlackPurlException('Deal_Unit_Price_Cost__c' + DMLUtility.NOT_UPDATABLE); }
					update sobjectlistToUpdate;
				}
	    	}
    	}
    }
    
    private static Deal_Unit_Price_Cost__c updateBasePriceAndStampDuty(Deal_Item__c dealItemRec, Decimal partsAndLaborTotal, Decimal feeTotal, Decimal subletTotal, Boolean isTaxIncludingPricing) {
		Decimal totalFactoryOption = 0;
		Decimal totalDealerInstalledOption = 0;
		Decimal totalBasePrice = 0;
		Deal_Unit_Price_Cost__c basePriceRec;
		
		for(Deal_Unit_Price_Cost__c dealUnitPriceCostRec : dealItemRec.Deal_Unit_Prices_Costs__r) {
			if(dealUnitPriceCostRec.Type__c == 'Factory'){
				totalFactoryOption += (dealUnitPriceCostRec.Total_Price__c != null) ? dealUnitPriceCostRec.Total_Price__c : 0;
			} else if(dealUnitPriceCostRec.Type__c == 'Dealer') {
				totalDealerInstalledOption += (dealUnitPriceCostRec.Total_Price__c != null) ? dealUnitPriceCostRec.Total_Price__c : 0;
			} else if(dealUnitPriceCostRec.Type__c == 'Base') {
				totalBasePrice += (dealUnitPriceCostRec.Total_Price__c != null) ? dealUnitPriceCostRec.Total_Price__c : 0;
				basePriceRec = dealUnitPriceCostRec;
			}
		}
		Decimal minStampDuty = StampDutyService.getCalculatedStampDuty(dealItemRec, (dealItemRec.Dutiable_Value__c != null ? dealItemRec.Dutiable_Value__c : (totalFactoryOption + totalDealerInstalledOption + partsAndLaborTotal + subletTotal)));
		
    	Decimal minRideawayPricingTotal = totalFactoryOption + totalDealerInstalledOption + partsAndLaborTotal + feeTotal + subletTotal + minStampDuty;
    	dealItemRec.Rideaway_Pricing_Total__c = (dealItemRec.Rideaway_Pricing_Total__c != null) ? dealItemRec.Rideaway_Pricing_Total__c : 0;
    	if(dealItemRec.Is_Rideaway_Pricing_Enabled__c && minRideawayPricingTotal > dealItemRec.Rideaway_Pricing_Total__c) {
    		dealItemRec.Rideaway_Pricing_Total__c = minRideawayPricingTotal;
    		dealItemRec.Stamp_Duty_Total__c = minStampDuty;
    	} else {
			Decimal subTotal = dealItemRec.Is_Rideaway_Pricing_Enabled__c ? (dealItemRec.Rideaway_Pricing_Total__c - feeTotal) : (totalBasePrice + totalFactoryOption + totalDealerInstalledOption + partsAndLaborTotal + subletTotal);
			dealItemRec.Stamp_Duty_Total__c = StampDutyService.getCalculatedStampDuty(dealItemRec, (dealItemRec.Dutiable_Value__c != null ? dealItemRec.Dutiable_Value__c : subTotal));
    	}
		
   		if(dealItemRec.Is_Rideaway_Pricing_Enabled__c && basePriceRec != null) {
			totalBasePrice = dealItemRec.Rideaway_Pricing_Total__c - (dealItemRec.Stamp_Duty_Total__c + totalFactoryOption + totalDealerInstalledOption + partsAndLaborTotal + feeTotal + subletTotal);
			if(isTaxIncludingPricing) {
				basePriceRec.Price_When_Tax_Included__c = (totalBasePrice/((basePriceRec.Qty__c != null || basePriceRec.Qty__c == 0) ? basePriceRec.Qty__c : 1));
				basePriceRec.Price__c = (basePriceRec.Price_When_Tax_Included__c/(1 + (basePriceRec.Sales_Tax_Percentage__c/100)));
			} else {
				basePriceRec.Price__c = (totalBasePrice/((basePriceRec.Qty__c != null || basePriceRec.Qty__c == 0) ? basePriceRec.Qty__c : 1));
			}
			return basePriceRec;
		}
		return null;
    }

	public static Decimal getOptionAndFeeCost(Option_Fee__c ofRec) {
		ofRec.Qty__c = (ofRec.Qty__c != null) ? ofRec.Qty__c : 0;				
		Decimal cost = (ofRec.Cost__c != null) ? ofRec.Cost__c : 0;
		if(ofRec.Part__c != null && !DealService.isOptionCommitted(ofRec)) {
			cost = ofRec.Part__r.Average_Cost__c != null && ofRec.Part__r.Average_Cost__c != 0 ? 
								ofRec.Part__r.Average_Cost__c : (ofRec.Part__r.Last_Cost__c != null ? ofRec.Part__r.Last_Cost__c : 0);
		} else if(ofRec.Labour_Code__c != null && !DealService.isOptionCommitted(ofRec)) {
			if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
				cost = GeneralConfiguration.getDefaultTechnicianCostingRate();
			} else {
				if(ofRec.Labour_Code__r.Cost_Method__c == 'Fixed Cost' && ofRec.Labour_Code__r.Cost_Rate__c != null) {
					cost = ofRec.Labour_Code__r.Cost_Rate__c;
				} else if(ofRec.Labour_Code__r.Cost_Method__c == 'Percent Retail' && ofRec.Labour_Code__r.Cost_Rate__c != null) {
					cost = ((ofRec.Price__c * ofRec.Labour_Code__r.Cost_Rate__c)/100);
				}
			}
		} else if(ofRec.Product__c != null) {
			if(ofRec.Product__r.Type__c != Constants.SUBLET || !DealService.isOptionCommitted(ofRec)) {
				if(ofRec.Product__r.Cost_Method__c == 'Fixed Cost' && ofRec.Product__r.Cost__c != null) {
					cost = ofRec.Product__r.Cost__c;
				} else if(ofRec.Product__r.Cost_Method__c == 'Percent Retail' && ofRec.Product__r.Cost__c != null) {
					cost = ((ofRec.Price__c * ofRec.Product__r.Cost__c)/100);
				}
			}
		} else if(ofRec.Fee__c != null) {
			if(!ofRec.Fee__r.Is_Include_In_Profit_Calculation__c) {
				cost = 0;
			}
			if(ofRec.Deal_Kit_Header__c == null || ofRec.Status__c == Constants.UNCOMIITTED) {
				if(ofRec.Fee__r.Cost_Method__c == 'Fixed Cost' && ofRec.Fee__r.Cost_Rate__c != null) {
					cost = ofRec.Fee__r.Cost_Rate__c;
				} else if(ofRec.Fee__r.Cost_Method__c == 'Percent Retail' && ofRec.Fee__r.Cost_Rate__c != null) {
					cost = ((ofRec.Price__c * ofRec.Fee__r.Cost_Rate__c)/100);
				}
			}
		}
		return (ofRec.Qty__c * cost).setScale(2, RoundingMode.HALF_UP);
	}
}
