/**
 * Author: Tarun Khandelwal
 * Since: March 27, 2014
 * Name: TaxCalculation
 * Description: Used for Calculation of all type of taxes.
**/
public without sharing class TaxCalculation {
    
    public static Map<String, String> partPriceFieldLabelToFieldAPINameMap = new Map<String, String>{'Price' => 'Retail_Price__c', 'MSRP' => 'MSRP__c', 
                                                                                                    'Cost' => 'Last_Cost__c', 'Average Cost' => 'Average_Cost__c'};
    public static String PART_PRICE_FIELD_API_NAME = 'Retail_Price__c';
    public static String COLI_TAX_FIELD_API_NAME = 'Tax__c'; 
    public static Set<String> COST_FIELDS_SET = new Set<String>{'Last_Cost__c', 'Average_Cost__c'};
    
    public static String getPricingFieldByPLBaseValueField(String priceLevel_baseValueField) {
        String pricingField = partPriceFieldLabelToFieldAPINameMap.containsKey(priceLevel_baseValueField) ? 
                            partPriceFieldLabelToFieldAPINameMap.get(priceLevel_baseValueField) : '';
        return pricingField;
    }
    
    public static Boolean IsEnhancedTaxCalculationApplicable {get
    	{
    		return (GeneralConfiguration.IsEnhancedTaxCalculation() && !GeneralConfiguration.getTaxIncludingPricing());
    		} set;
    	}
    
    /**
     * Name: partPriceCalculation
     * Desc: Calculate Tax accroding to Tax logic
     * @param:  (1) priceLevel_baseValueField - String - Picklist Value of Part Price Base field of Price Level
                (2) priceLevel_discountMarkup - Decimal - Discount Markup field value of Price Level
                (3) COLineItemRecords - List<CO_Line_Item__c> - List of CO Line Items records.
                (4) partIdToPartRecordMap -  Map<Id, Part__c> - Map of Id and Part Object
     * @return: List<CO_Line_Item__c>
    **/
    public static List<CO_Line_Item__c> partPriceCalculation(String priceLevel_baseValueField, Decimal priceLevel_discountMarkup, 
                        List<CO_Line_Item__c> COLineItemRecords, Map<Id, Part__c> partIdToPartRecordMap, Map<Id, Fee__c> feeIdToFeeRecordMap) {
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        String pricingField = getPricingFieldByPLBaseValueField(priceLevel_baseValueField);
        
        for(CO_Line_Item__c COlineItem : COLineItemRecords) {
            if(COlineItem.Part__c == null && COTriggerHelper.isRetainItemPrices) {
                continue;
            }
            if(COlineItem.Part__c != null) {
        		Decimal appTaxRate;
	            if(!pricingField.containsIgnoreCase('Average_Cost__c') && partIdToPartRecordMap.get(COlineItem.Part__c).get(pricingField) == null) {
	                partIdToPartRecordMap.get(COlineItem.Part__c).put(pricingField, 0);
	                COlineItem.Retail__c = 0;
	            } else {
                    Decimal baseValue;
                    if(pricingField.containsIgnoreCase('Average_Cost__c') && (partIdToPartRecordMap.get(coLineItem.Part__c).Average_Cost__c == null || partIdToPartRecordMap.get(coLineItem.Part__c).Average_Cost__c == 0)) {
                        baseValue = partIdToPartRecordMap.get(coLineItem.Part__c).Last_Cost__c != null ? partIdToPartRecordMap.get(coLineItem.Part__c).Last_Cost__c : 0;
                    } else {
                        baseValue = Decimal.valueOf(String.valueOf(partIdToPartRecordMap.get(coLineItem.Part__c).get(pricingField)));
                    }
                    if(isTaxIncludingPricing && ((COTriggerHelper.isRecalculateCOPLAndTax && COTriggerHelper.isResetPricing) || COTriggerHelper.isRetainItemPrices)) {
                        if(priceLevel_discountMarkup == 0 && !COST_FIELDS_SET.contains(pricingField)) {
                            COlineItem.Price_When_Tax_Included__c = baseValue.setScale(2, RoundingMode.HALF_UP);
                        } else {
                            COlineItem.Price_When_Tax_Included__c = null;
                        }
                    }
	                if(COlineItem.CO_Kit_Header__c != null || COlineItem.Kit_Header_Line_Item__c != null) {
	                    COlineItem.Retail__c = baseValue;
	                } else {
	                    if(isTaxIncludingPricing && !COST_FIELDS_SET.contains(pricingField) && partIdToPartRecordMap.get(coLineItem.Part__c).Applicable_Tax__c != null) {
	                        appTaxRate = partIdToPartRecordMap.get(coLineItem.Part__c).Applicable_Tax__r.Rate__c;
	                        if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
	                            appTaxRate = 0;
	                        }
	                        baseValue = baseValue / (1 + (appTaxRate / 100));
	                    }
	                    COlineItem.Retail__c = (baseValue + (baseValue * priceLevel_discountMarkup / 100)).setScale(2, RoundingMode.HALF_UP);
	                }
	            }
	            
	            COlineItem.Price__c = COlineItem.Retail__c;
	            Decimal price = getPartPrice(COlineItem.Price__c, partIdToPartRecordMap.get(coLineItem.Part__c).Sale_Price__c, appTaxRate);
	            if(price != COlineItem.Price__c) {
	            	COlineItem.Price__c = price;
	            	COlineItem.Price_When_Tax_Included__c = null;
	            }

	            if(partIdToPartRecordMap.get(coLineItem.Part__c).get(PART_PRICE_FIELD_API_NAME) != null) {
                    COlineItem.Actual_Retail_Price__c = Decimal.valueOf(String.valueOf(partIdToPartRecordMap.get(coLineItem.Part__c).get(PART_PRICE_FIELD_API_NAME)));
                }

            } else if(COlineItem.Fee__c != null && feeIdToFeeRecordMap.containsKey(COlineItem.Fee__c)) {
                COlineItem.Price_When_Tax_Included__c = null;
	            COlineItem.Retail__c = ((coLineItem.Price__c != null) ? coLineItem.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
            }
        }
        return COLineItemRecords;
    }
    
    public static Decimal getPartPrice(Decimal preTaxPrice, Decimal salePrice, Decimal appTaxRate) {
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        preTaxPrice = preTaxPrice != null ? preTaxPrice.setScale(2, RoundingMode.HALF_UP) : 0;
        salePrice = salePrice != null ? salePrice.setScale(2, RoundingMode.HALF_UP) : 0;
        
        if(salePrice != null && salePrice != 0) {
            if(isTaxIncludingPricing) {
                if(appTaxRate == null || appTaxRate == -100) { // To handle divide by zero error
                    appTaxRate = 0;
                }
	            Decimal preSalePrice = (salePrice / (1 + (appTaxRate / 100))).setScale(2, RoundingMode.HALF_UP);
	            if(preSalePrice < preTaxPrice) {
	                return preSalePrice;
	            }
            } else if(salePrice < preTaxPrice) {
                return salePrice;
            }
        }
        return preTaxPrice;
    }
    
    /**
     * Name: partPriceCalculation1
     * Desc: Calculate Tax accroding to Tax logic
     * @param:  (1) priceLevel_baseValueField - String - Picklist Value of Part Price Base field of Price Level
                (2) priceLevel_discountMarkup - Decimal - Discount Markup field value of Price Level
                (3) COlineItem - CO_Line_Item__c - CO Line Items record.
                (4) partIdToPartRecordMap -  Map<Id, Part__c> - Map of Id and Part Object
     * @return: void
    **/
    public static void partPriceCalculation1(String priceLevel_baseValueField, Decimal priceLevel_discountMarkup, CO_Line_Item__c COlineItem, 
                                                Map<Id, Part__c> partIdToPartRecordMap, Map<Id, Fee__c> feeIdToFeeRecordMap) {
        
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        String pricingField = getPricingFieldByPLBaseValueField(priceLevel_baseValueField);
        
        if(coLineItem.Part__c != null) {
            if(!pricingField.containsIgnoreCase('Average_Cost__c') && partIdToPartRecordMap.get(coLineItem.Part__c).get(pricingField) == null) {
                partIdToPartRecordMap.get(coLineItem.Part__c).put(pricingField, 0);
                COlineItem.Retail__c = 0;
            } else {
                Decimal baseValue;
                if(pricingField.containsIgnoreCase('Average_Cost__c') && (partIdToPartRecordMap.get(coLineItem.Part__c).Average_Cost__c == null || partIdToPartRecordMap.get(coLineItem.Part__c).Average_Cost__c == 0)) {
                    baseValue = partIdToPartRecordMap.get(coLineItem.Part__c).Last_Cost__c != null ? partIdToPartRecordMap.get(coLineItem.Part__c).Last_Cost__c : 0;
                } else {
                    baseValue = Decimal.valueOf(String.valueOf(partIdToPartRecordMap.get(coLineItem.Part__c).get(pricingField)));
                }
                
                if(trigger.isInsert && isTaxIncludingPricing) {
                    if(priceLevel_discountMarkup == 0 && !COST_FIELDS_SET.contains(pricingField)) {
                        COlineItem.Price_When_Tax_Included__c = baseValue.setScale(2, RoundingMode.HALF_UP);
                    } else {
                        COlineItem.Price_When_Tax_Included__c = null;
                    }
                }
                
                if(COlineItem.CO_Kit_Header__c != null || COlineItem.Kit_Header_Line_Item__c != null) {
                    COlineItem.Retail__c = baseValue;
                } else {
                    if(isTaxIncludingPricing && !COST_FIELDS_SET.contains(pricingField) && partIdToPartRecordMap.get(coLineItem.Part__c).Applicable_Tax__c != null) {
                        Decimal appTaxRate = partIdToPartRecordMap.get(coLineItem.Part__c).Applicable_Tax__r.Rate__c;
                        if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
                            appTaxRate = 0;
                        }
                        baseValue = baseValue / (1 + (appTaxRate / 100));
                    }
                    COlineItem.Retail__c = (baseValue + (baseValue * priceLevel_discountMarkup / 100)).setScale(2, RoundingMode.HALF_UP);
                }
            }        
            if(trigger.isInsert && partIdToPartRecordMap.get(coLineItem.Part__c).get(PART_PRICE_FIELD_API_NAME) != null) {
                COlineItem.Actual_Retail_Price__c = Decimal.valueOf(String.valueOf(partIdToPartRecordMap.get(coLineItem.Part__c).get(PART_PRICE_FIELD_API_NAME))).setScale(2, RoundingMode.HALF_UP);
            }
            
        } else if(COlineItem.Fee__c != null) {
            Decimal feePrice;
            if(COlineItem.Is_Environmental_Fee__c || COlineItem.Is_Linked_Fee__c || COlineItem.Type__c == Constants.SHOP_SUPPLY) {
                if(isTaxIncludingPricing) {
                    feePrice = (coLineItem.Price_When_Tax_Included__c != null) ? coLineItem.Price_When_Tax_Included__c : 0;
                } else {
                    feePrice = (coLineItem.Price__c != null) ? coLineItem.Price__c : 0;
                }
            } else {
                feePrice = feeIdToFeeRecordMap.get(coLineItem.Fee__c).Price__c;
            }
            if(isTaxIncludingPricing) {
                Decimal appTaxRate = feeIdToFeeRecordMap.get(coLineItem.Fee__c).Applicable_Tax__r.Rate__c;
                if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
                    appTaxRate = 0;
                }
                if(trigger.isInsert) {
                    COlineItem.Price_When_Tax_Included__c = feePrice;
                }
                feePrice = feePrice / (1 + (appTaxRate / 100));
            }
            COlineItem.Retail__c = feePrice.setScale(2, RoundingMode.HALF_UP);
        }         
        if(trigger.isInsert) {
        	COlineItem.Price__c = COlineItem.Actual_Kit_Price__c = COlineItem.Retail__c = 
        					(COlineItem.Retail__c != null ? COlineItem.Retail__c.setScale(2, RoundingMode.HALF_UP) : 0);
        					
        	if(COlineItem.Part__c != null) {
        		Decimal appTaxRate;
        	    if(partIdToPartRecordMap.get(coLineItem.Part__c).Applicable_Tax__c != null) {
        	        appTaxRate = partIdToPartRecordMap.get(coLineItem.Part__c).Applicable_Tax__r.Rate__c;
        	    }
        	    if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
                    appTaxRate = 0;
                }
        		Decimal price = getPartPrice(COlineItem.Price__c, partIdToPartRecordMap.get(coLineItem.Part__c).Sale_Price__c, appTaxRate);
	            if(price != COlineItem.Price__c) {
	            	COlineItem.Price__c = price;
	            	COlineItem.Price_When_Tax_Included__c = null;
	            }
        	}
        }
    }
    /**
     * Name: salesTaxCalculation
     * Desc: Calculate Sales Tax accroding to logic
     * @param:  (1) salesTaxIdList - List<Id> - List of sales tax records Ids
                (2) partIdToSalesTaxItemIdsMap - Map<Id, Set<Id>> - Map of part Id and sales tax item records
                                                     Key -          Part Record Id
                                                     Value -        Set of sales tax item ids
                (3) COHeaderList - List<CO_Header__c> - List of CO Header records.
                (4) COHeaderIdToCOLineItemRecordsMap - Map<Id, List<Sobject>> - Map of Id and Sobject
                                                               Key - Id - CO Header Id
                                                               Value - SObject - Corresponding CO line item records
                (5) defaultSalesTax - List<Sales_Tax__c> - Default sales tax                                               
     * @return: List<CO_Line_Item__c>
    **/
    public static List<CO_Line_Item__c> salesTaxCalculation(List<Id> salesTaxIdList, Map<Id, Set<Id>> partIdToSalesTaxItemIdsMap, List<CO_Header__c> COHeaderList, Map<Id, List<Sobject>> COHeaderIdToCOLineItemRecordsMap, List<Sales_Tax__c> defaultSalesTax ) {
        if(AccessControl.ifObjectFieldIsAccessible('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Applicable_Taxes__c> applicableTaxList = [select Sales_Tax_Item__c, Sales_Tax__c, Sales_Tax_Item__r.Tax_Parts__c, Sales_Tax_Item__r.Rate__c from Applicable_Taxes__c where Sales_Tax__c IN : salesTaxIdList];
        Map<Id, List<Applicable_Taxes__c>> salesTaxIdToAppTaxRecordsMap = new Map<Id, List<Applicable_Taxes__c>>();
        
        for(Applicable_Taxes__c appTax : applicableTaxList) {
            List<Applicable_Taxes__c> appTaxRecordList = new List<Applicable_Taxes__c>();
            if(!appTax.Sales_Tax_Item__r.Tax_Parts__c) {
                continue;
            }
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
        
        List<Sobject> coLineItemToUpdate = new List<Sobject>();
        for(CO_Header__c COHeaderRec : COHeaderList) {
            Id salesTaxId;
            if(COHeaderRec.Customer__r.Sales_Tax__c == null) {
                salesTaxId = defaultSalesTax[0].Id;
            } else {
                salesTaxId = COHeaderRec.Customer__r.Sales_Tax__c;
            }
            if(COHeaderIdToCOLineItemRecordsMap.containsKey(COHeaderRec.Id)) {
                for(Sobject coLineItem : COHeaderIdToCOLineItemRecordsMap.get(COHeaderRec.Id)) {
                    if(coLineItem.get('Part__c') == null) {
                        continue;
                    }
                    Id partId = Id.valueOf(String.valueOf(coLineItem.get('Part__c')));
                    Decimal exemptionRate = 0;
                    if(salesTaxIdToAppTaxRecordsMap.containsKey(salesTaxId)) {
                        for(Applicable_Taxes__c appTax : salesTaxIdToAppTaxRecordsMap.get(salesTaxId)) {
                            if(partIdToSalesTaxItemIdsMap.get(partId).contains(appTax.Sales_Tax_Item__c)) {
                                exemptionRate += appTax.Sales_Tax_Item__r.Rate__c;
                            }
                        } 
                    }
                    Decimal rate = 0;
                    if(salesTaxIdToTaxRateMap.containsKey(salesTaxId)) {
                        rate = salesTaxIdToTaxRateMap.get(salesTaxId);
                    }
                    coLineItem.put(COLI_TAX_FIELD_API_NAME, rate - exemptionRate);
                    coLineItemToUpdate.add(coLineItem);
                }
            }
        }
        //system.assert(false, coLineItemToUpdate);
        return coLineItemToUpdate;
    }
    
    public static void setTotalForMerchSection(String coHeaderId) {
        CO_Header__c coHeaderRec = populateOrderTotal(coHeaderId, true);
    }
    
    public static void populateOrderTotal(Map<Id, CO_Header__c> coHeaderIdToRecMap) {
    	if(coHeaderIdToRecMap.size() == 0) {
    		return;
    	}
    	List<CO_Header__c> coHeaderList = [select Id,
                                            (select Qty__c, Price__c, Price_When_Tax_Included__c, Tax_Amount__c from CO_Line_Items__r where Is_In_Merch_Section__c = true AND Closed_CO_Invoice_link__c = null),
                                            (select Total__c from Service_Order_Headers__r where SO_Status__c != 'Invoiced' AND Deal__c = null),
                                            (select F_I_Total__c, F_I_Tax_Total__c, Type__c, Subtotal__c from Deals__r where Status__c != 'Invoiced'),
                                            (select Total__c, SalesTax_Total__c, Deductible_Total__c 
                                                            from CO_Invoice_Headers__r 
                                                            where Invoice_Status__c = 'Closed'
                                                                AND (Checkout_Type__c = 'Customer' OR Checkout_Type__c = 'Third-Party' OR Checkout_Type__c = 'Internal'))
                                         from CO_Header__c
                                         where Id IN :coHeaderIdToRecMap.keySet()];
        
        Set<Id> coLineItemIds = new Set<Id>();
        Set<Id> serviceOrderHeaderIds = new Set<Id>();
        Set<Id> dealIds = new Set<Id>();
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Map<Id, List<Individual_Tax__c>> coHeaderIdToIndividualTaxListMap = new Map<Id, List<Individual_Tax__c>>();
        if(!isTaxIncludingPricing) {
            for(CO_Header__c coHeader : coHeaderList) {
	            for(CO_Line_Item__c coli : coHeader.CO_Line_Items__r) {
	                coLineItemIds.add(coli.Id);
	            }
	            for(Service_Order_Header__c soHeader : coHeader.Service_Order_Headers__r) {
	                serviceOrderHeaderIds.add(soHeader.Id);
	            }
	            for(Deal__c dealRec : coHeader.Deals__r) {
	                dealIds.add(dealRec.Id);
	            }
            }
            
            List<Individual_Tax__c> individualTaxList = [select Deal__c, Taxable_Amount_for_Section_Header__c, Deal__r.CO_Header__c, Taxable_Amount__c, Tax_Rate__c,
                                                            Enhanced_Tax_Amount__c, Sales_Tax_Item__r.Name__c, SO_Payment_Role__c, SO_Payment_Role__r.Applicable_Tax_Name__c,
                                                            Form_Label__c, Applicable_Tax__c,
                                                            CO_Line_Item__r.CO_Header__c, Service_Order_Line_Item__r.Service_Order_Header__r.CO_Header__c,
                                                            Option_Fee__r.Deal__r.CO_Header__c, Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.CO_Header__c, 
                                                            F_I_Product__r.Deal_Finance__r.Deal__r.CO_Header__c, Deal_Item__r.Deal__r.CO_Header__c, Deal_Item__r.Type__c 
                                                        from Individual_Tax__c
                                                        where CO_Line_Item__c IN :coLineItemIds
                                                            OR Service_Order_Line_Item__r.Service_Order_Header__c IN :serviceOrderHeaderIds
                                                            OR Option_Fee__r.Deal__c IN: dealIds
                                                            OR Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c IN: dealIds
                                                            OR F_I_Product__r.Deal_Finance__r.Deal__c IN: dealIds
                                                            OR (Deal_Item__r.Deal__c IN: dealIds AND Deal_Item__r.Type__c = 'Trade In')
                                                            OR (Deal__c IN: dealIds)];
                                                            
            for(Individual_Tax__c individualTaxRec: individualTaxList) {
            	Id coHeaderId;
            	if(individualTaxRec.Deal__c != null) {
            		coHeaderId = individualTaxRec.Deal__r.CO_Header__c;
            	} else if(individualTaxRec.CO_Line_Item__c != null) {
            		coHeaderId = individualTaxRec.CO_Line_Item__r.CO_Header__c;
            	} else if(individualTaxRec.Service_Order_Line_Item__c != null) {
            		coHeaderId = individualTaxRec.Service_Order_Line_Item__r.Service_Order_Header__r.CO_Header__c;
            	} else if(individualTaxRec.Option_Fee__c != null) {
            		coHeaderId = individualTaxRec.Option_Fee__r.Deal__r.CO_Header__c;
            	} else if(individualTaxRec.Deal_Unit_Price_Cost__c != null) {
            		coHeaderId = individualTaxRec.Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.CO_Header__c;
            	} else if(individualTaxRec.F_I_Product__c != null) {
            		coHeaderId = individualTaxRec.F_I_Product__r.Deal_Finance__r.Deal__r.CO_Header__c;
            	} else if(individualTaxRec.Deal_Item__c != null && individualTaxRec.Deal_Item__r.Type__c == 'Trade In') {
            		coHeaderId = individualTaxRec.Deal_Item__r.Deal__r.CO_Header__c;
            	}
            	if(coHeaderId != null) {
            		if(!coHeaderIdToIndividualTaxListMap.containsKey(coHeaderId)) {
	            		coHeaderIdToIndividualTaxListMap.put(coHeaderId, new List<Individual_Tax__c>());
	            	}
	            	coHeaderIdToIndividualTaxListMap.get(coHeaderId).add(individualTaxRec);
            	}
            }
        }
                                        
        List<Sales_Tax_Item__c> salesTaxItemList = [select Forms_Label__c, Name__c from Sales_Tax_Item__c limit: SOQLUtil.getAvailableQueryRowsLimit()];
        for(CO_Header__c coHeaderRec : coHeaderList) {
        	Decimal invoicedTotal = 0;
	        Decimal deductibleTotal = 0;
	        for(CO_Invoice_Header__c coInvHeaderRec : coHeaderRec.CO_Invoice_Headers__r) {
	            deductibleTotal += (coInvHeaderRec.Deductible_Total__c != null ? coInvHeaderRec.Deductible_Total__c : 0);
	            invoicedTotal += (coInvHeaderRec.Total__c != null ? coInvHeaderRec.Total__c : 0);
	        }
	        
	        List<Individual_Tax__c> indTaxList = coHeaderIdToIndividualTaxListMap.containsKey(coHeaderRec.Id) ? coHeaderIdToIndividualTaxListMap.get(coHeaderRec.Id) : new List<Individual_Tax__c>();
	        Decimal nonInvoicedTotal = getNonInvoicedAmount(coHeaderRec, indTaxList, salesTaxItemList) - deductibleTotal;
	        if(coHeaderIdToRecMap.containsKey(coHeaderRec.Id)) {
	        	coHeaderIdToRecMap.get(coHeaderRec.Id).Invoiced_Amount__c = invoicedTotal;
	        	coHeaderIdToRecMap.get(coHeaderRec.Id).Uninvoiced_Amount__c = nonInvoicedTotal;
	        }
        }
        COTriggerHelper.isForceStopTrigger = true;
        update coHeaderIdToRecMap.values();
        COTriggerHelper.isForceStopTrigger = false;
    }
    
    public static void populateOrderTotal(String coHeaderId) {
        populateOrderTotal(coHeaderId, true);
    }
    
    public static CO_Header__c populateOrderTotal(String coHeaderId, Boolean isUpdate) {
        // Sum of Invoiced Amount and Uninvoiced Amount
        List<CO_Invoice_Header__c> coInvoiceHeaderList = [select Total__c, SalesTax_Total__c, Deductible_Total__c 
                                                            from CO_Invoice_Header__c 
                                                            where CO_Header__c = :coHeaderId
                                                                AND Invoice_Status__c = 'Closed'
                                                                AND (Checkout_Type__c = 'Customer' OR Checkout_Type__c = 'Third-Party' OR Checkout_Type__c = 'Internal')];
        
        Decimal invoicedTotal = 0;
        
        for(CO_Invoice_Header__c COIH : coInvoiceHeaderList) {
            invoicedTotal += (COIH.Total__c != null ? COIH.Total__c : 0);
        }
        Decimal nonInvoicedTotal = getNonInvoicedAmount(coHeaderId);
        
        CO_Header__c coHeaderRec = new CO_Header__c(Id = coHeaderId, Invoiced_Amount__c = invoicedTotal, Uninvoiced_Amount__c = nonInvoicedTotal);
        if(isUpdate) {
        	COTriggerHelper.isForceStopTrigger = true;
	        update coHeaderRec;
	        COTriggerHelper.isForceStopTrigger = false;
        }
        return coHeaderRec;
    }
    
    private static Decimal getNonInvoicedAmount(CO_Header__c coHeader, List<Individual_Tax__c> individualTaxList, List<Sales_Tax_Item__c> salesTaxItemList) {
    	Decimal subTotal = 0;
        Decimal nonInvoicedTotalTax = 0;
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal nonInvoicedTotal = 0;
        
        if(!isTaxIncludingPricing) {
            for(CO_Line_Item__c coli : coHeader.CO_Line_Items__r) {
                subTotal += (coli.Qty__c != null ? coli.Qty__c : 0) * (coli.Price__c != null ? coli.Price__c : 0);
            }
            for(Service_Order_Header__c soHeader : coHeader.Service_Order_Headers__r){
                subTotal += (soHeader.Total__c != null ? soHeader.Total__c : 0);
            }
            for(Deal__c dealRec : coHeader.Deals__r) {
                subTotal += (dealRec.Subtotal__c != null ? dealRec.Subtotal__c : 0);
                if(dealRec.Type__c == 'Financed') {
                    subTotal += (dealRec.F_I_Total__c != null ? dealRec.F_I_Total__c : 0);
                }
            }
        
            Map<String, Decimal> salesTaxNameToTaxValue = getTaxAmountWithFormLabel(individualTaxList, salesTaxItemList);
            for(String taxName : salesTaxNameToTaxValue.keySet()) {
                nonInvoicedTotalTax += salesTaxNameToTaxValue.get(taxName); 
            }
            nonInvoicedTotal = subTotal + nonInvoicedTotalTax;
        } else {
            for(CO_Line_Item__c coli : coHeader.CO_Line_Items__r) {
                coli.Qty__c = (coli.Qty__c != null) ? coli.Qty__c : 0;
                Decimal price = (coli.Price_When_Tax_Included__c != null) ? coli.Price_When_Tax_Included__c : (coli.Price__c + coli.Tax_Amount__c);
                subTotal += (coli.Qty__c * price);
            }
            for(Service_Order_Header__c soHeaderRec : coHeader.Service_Order_Headers__r) {
                subTotal += (soHeaderRec.Total__c != null) ? soHeaderRec.Total__c : 0;
            }
            for(Deal__c dealRec : coHeader.Deals__r) {
                subTotal += (dealRec.Subtotal__c != null) ? dealRec.Subtotal__c : 0;
                if(dealRec.Type__c == 'Financed') {
                    subTotal += (dealRec.F_I_Total__c != null ? dealRec.F_I_Total__c : 0);
                    subTotal += (dealRec.F_I_Tax_Total__c != null ? dealRec.F_I_Tax_Total__c : 0);
                }
            }
            nonInvoicedTotal = subTotal;
        }
        
        return nonInvoicedTotal.setScale(2, RoundingMode.HALF_UP);
    }
    
    private static Decimal getNonInvoicedAmount(String coHeaderId) {
        List<CO_Header__c> coHeaderList = [select Id,
                                            (select Qty__c, Price__c, Price_When_Tax_Included__c, Tax_Amount__c from CO_Line_Items__r where Is_In_Merch_Section__c = true AND Closed_CO_Invoice_link__c = null),
                                            (select Total__c, Transaction_Type__r.Type__c from Service_Order_Headers__r where SO_Status__c != 'Invoiced' AND Deal__c = null),
                                            (select F_I_Total__c, F_I_Tax_Total__c, Type__c, Subtotal__c from Deals__r where Status__c != 'Invoiced')
                                         from CO_Header__c
                                         where Id = :coHeaderId];
        Decimal subTotal = 0;
        Decimal nonInvoicedTotalTax = 0;
        Set<Id> coLineItemIds = new Set<Id>();
        Set<Id> serviceOrderHeaderIds = new Set<Id>();
        Set<Id> dealIds = new Set<Id>();
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal nonInvoicedTotal = 0;
        List<String> thirdPartySOHeaderIdList = new List<String>();
        
        if(!isTaxIncludingPricing) {
            for(CO_Header__c coHeader : coHeaderList) {
                for(CO_Line_Item__c coli : coHeader.CO_Line_Items__r){
                    coLineItemIds.add(coli.Id);
                    subTotal += (coli.Qty__c != null ? coli.Qty__c : 0) * (coli.Price__c != null ? coli.Price__c : 0);
                }
                for(Service_Order_Header__c soHeader : coHeader.Service_Order_Headers__r){
                    serviceOrderHeaderIds.add(soHeader.Id);
                    if(soHeader.Transaction_Type__r.Type__c == 'Third-Party') {
                        thirdPartySOHeaderIdList.add(soHeader.Id);
                    }
                    subTotal += (soHeader.Total__c != null ? soHeader.Total__c : 0);
                }
                for(Deal__c dealRec : coHeader.Deals__r) {
                    dealIds.add(dealRec.Id);
                    subTotal += (dealRec.Subtotal__c != null ? dealRec.Subtotal__c : 0);
                    if(dealRec.Type__c == 'Financed') {
                        subTotal += (dealRec.F_I_Total__c != null ? dealRec.F_I_Total__c : 0);
                    }
                }
            }
        
            List<Individual_Tax__c> individualTaxList = [select Taxable_Amount__c, Tax_Rate__c, Enhanced_Tax_Amount__c, Sales_Tax_Item__r.Name__c, SO_Payment_Role__r.Applicable_Tax_Name__c,
                                                            Form_Label__c, Applicable_Tax__c, Deal__c, Taxable_Amount_for_Section_Header__c, SO_Payment_Role__c
                                                        from Individual_Tax__c
                                                        where CO_Line_Item__c IN :coLineItemIds
                                                            OR Service_Order_Line_Item__r.Service_Order_Header__c IN :serviceOrderHeaderIds
                                                            OR Option_Fee__r.Deal__c IN: dealIds
                                                            OR Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c IN: dealIds
                                                            OR F_I_Product__r.Deal_Finance__r.Deal__c IN: dealIds
                                                            OR (Deal_Item__r.Deal__c IN: dealIds AND Deal_Item__r.Type__c = 'Trade In')
                                                            OR (Deal__c IN: dealIds)];
            
            Map<String, Decimal> salesTaxNameToTaxValue = getTaxAmountWithFormLabel(individualTaxList);
            
            for(String taxName : salesTaxNameToTaxValue.keySet()) {
                nonInvoicedTotalTax += salesTaxNameToTaxValue.get(taxName); 
            }
            nonInvoicedTotal = subTotal + nonInvoicedTotalTax;
        } else {
            for(CO_Header__c coHeader : coHeaderList) {
                for(CO_Line_Item__c coli : coHeader.CO_Line_Items__r){
                    coli.Qty__c = (coli.Qty__c != null) ? coli.Qty__c : 0;
                    Decimal price = (coli.Price_When_Tax_Included__c != null) ? coli.Price_When_Tax_Included__c : (coli.Price__c + coli.Tax_Amount__c);
                    subTotal += (coli.Qty__c * price);
                }
                for(Service_Order_Header__c soHeaderRec : coHeader.Service_Order_Headers__r) {
                    subTotal += (soHeaderRec.Total__c != null) ? soHeaderRec.Total__c : 0;
                    if(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party') {
                        thirdPartySOHeaderIdList.add(soHeaderRec.Id);
                    }
                }
                for(Deal__c dealRec : coHeader.Deals__r) {
                    subTotal += (dealRec.Subtotal__c != null) ? dealRec.Subtotal__c : 0;
                    if(dealRec.Type__c == 'Financed') {
                        subTotal += (dealRec.F_I_Total__c != null ? dealRec.F_I_Total__c : 0);
                        subTotal += (dealRec.F_I_Tax_Total__c != null ? dealRec.F_I_Tax_Total__c : 0);
                    }
                }
            }
            nonInvoicedTotal = subTotal;
        }
        
        List<SO_Payment_Role__c> soPaymentRolesList = new List<SO_Payment_Role__c>();
        if(!thirdPartySOHeaderIdList.isEmpty()) {
            soPaymentRolesList = [SELECT Total_Amount__c, Tax_Amount__c FROM SO_Payment_Role__c WHERE Status__c = 'Invoiced' AND RecordType.DeveloperName='Deductible' AND Service_Order_Header__c IN: thirdPartySOHeaderIdList];
        }

        for(SO_Payment_Role__c soPaymentRec: soPaymentRolesList) {
            nonInvoicedTotal -= (soPaymentRec.Total_Amount__c != null ? soPaymentRec.Total_Amount__c : 0);
            if(!isTaxIncludingPricing) {
                nonInvoicedTotal -= (soPaymentRec.Tax_Amount__c != null ? soPaymentRec.Tax_Amount__c : 0);
            }
        }
        return nonInvoicedTotal.setScale(2, RoundingMode.HALF_UP);
    }
    
    public static Boolean isInvoiced = true;

    public static Map<String, Decimal> getTaxAmountWithFormLabel(List<Individual_Tax__c> individualTaxList) {
        return getFormLabelToTaxAmountMap(individualTaxList, '', true);
    }
    // Added by TK --- To get TaxAmount when needed to show with form Label.
    public static Map<String, Decimal> getTaxAmountWithFormLabel(List<Individual_Tax__c> individualTaxList, String invoiceType) {
        return getFormLabelToTaxAmountMap(individualTaxList, invoiceType, true);
    }
    
    // Overrided getTaxAmountWithFormLabel for avoiding querying of salesTaxItemList in for loop when this function is called for bulk records
    public static Map<String, Decimal> getTaxAmountWithFormLabel(List<Individual_Tax__c> individualTaxList, List<Sales_Tax_Item__c> salesTaxItemList) {
        return getFormLabelToTaxAmountMap(individualTaxList, '', false);
    }

    private static Map<String, Decimal> getFormLabelToTaxAmountMap(List<Individual_Tax__c> individualTaxList, String invoiceType, Boolean handleSOPaymentRole) {
        Map<Id, Individual_Tax__c> taxItemIdToIndTaxRecMap = new Map<Id, Individual_Tax__c>();
        for(Individual_Tax__c indTaxRec: individualTaxList) {
            taxItemIdToIndTaxRecMap.put(indTaxRec.Sales_Tax_Item__c, indTaxRec);
        }
        Map<String, Decimal> taxItemIdToTaxAmountMap = getTaxItemIdToTaxAmountMap(individualTaxList, 
        getTaxFormattedNameToTaxRateMap(individualTaxList), invoiceType, handleSOPaymentRole);

        Map<String, Decimal> taxLabelToTaxAmtMap = new Map<String, Decimal>();  // The Map which is to be return after calculation.
        for(String taxItemId : taxItemIdToTaxAmountMap.keySet()) {
            String taxId = TaxUtility.getExtractedSTINameFromFormattedName(taxItemId);
            String taxLabel = taxItemIdToIndTaxRecMap.get(taxId).Form_Label__c;
            if(!GeneralConfiguration.getConfigurations().Group_Individual_Taxes_On_Sales__c) {
                Decimal taxRate = TaxUtility.getExtractedTaxRateFromFormattedName(taxItemId);
                if((taxRate == null || taxRate == 0) && taxItemIdToIndTaxRecMap.get(taxId).Tax_Rate__c != null && taxItemIdToIndTaxRecMap.get(taxId).Tax_Rate__c != 0) {
                    taxRate = taxItemIdToIndTaxRecMap.get(taxId).Tax_Rate__c;
                }
                if(taxRate != null && taxRate != 0) {
                    taxLabel += ' - ' + taxRate.stripTrailingZeros().toPlainString() + '%';
                }
            }
            if(!taxLabelToTaxAmtMap.containsKey(taxLabel)) {
                taxLabelToTaxAmtMap.put(taxLabel, taxItemIdToTaxAmountMap.get(taxItemId));
            } else {
                taxLabelToTaxAmtMap.put(taxLabel, taxLabelToTaxAmtMap.get(taxLabel) + taxItemIdToTaxAmountMap.get(taxItemId));
            }
        }
        return taxLabelToTaxAmtMap;
    }

    private static Map<String, Decimal> getTaxFormattedNameToTaxRateMap(List<Individual_Tax__c> individualTaxList){
        Map<String, Decimal> taxItemToTaxRateMap = new Map<String, Decimal>();
        for(Individual_Tax__c taxItem : individualTaxList) {
            Decimal taxRate = taxItem.Tax_Rate__c != null ? taxItem.Tax_Rate__c : 0;
            taxItemToTaxRateMap.put(TaxUtility.getFormattedSalesTaxItemName(taxItem.Sales_Tax_Item__c, taxRate), taxRate);
        }
        return taxItemToTaxRateMap;
    }

    private static Map<String, Decimal> getTaxItemIdToTaxAmountMap(List<Individual_Tax__c> individualTaxList, Map<String, Decimal> taxFormattedNameToTaxRateMap, 
    String invoiceType, Boolean handleSOPaymentRole) {
        List<Id> soPaymentRolesIdList = new List<Id>();
        Map<Id, SO_Payment_Role__c> soPaymentRoleIdToRecMap = new Map<Id, SO_Payment_Role__c>();
        if(handleSOPaymentRole != null && handleSOPaymentRole) {
            for(Individual_Tax__c taxItem : individualTaxList) {
                if(taxItem.SO_Payment_Role__c != null) soPaymentRolesIdList.add(taxItem.SO_Payment_Role__c);
            }
            if(!soPaymentRolesIdList.isEmpty()) {
                soPaymentRoleIdToRecMap = new Map<Id, SO_Payment_Role__c>([SELECT Id, Total_Amount__c, Tax_Amount__c, Tax__c FROM SO_Payment_Role__c WHERE Id IN :soPaymentRolesIdList]);
            }
        }
        
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Map<String, Decimal> taxFormattedNameToTaxableAmountMap = new Map<String, Decimal>();
        Map<String, Decimal> taxIdToEnhTaxAmountMap = new Map<String, Decimal>();
        
        for(Individual_Tax__c taxItem : individualTaxList) {
            String formattedSTIName = TaxUtility.getFormattedSalesTaxItemName(taxItem.Sales_Tax_Item__c, taxItem.Tax_Rate__c);
        	if(IsEnhancedTaxCalculationApplicable && taxItem.Enhanced_Tax_Amount__c != null) {
                if(!taxIdToEnhTaxAmountMap.containsKey(formattedSTIName)){
                    taxIdToEnhTaxAmountMap.put(formattedSTIName, 0);
                }
                Decimal enhTaxAmount = (String.isNotBlank(invoiceType) && invoiceType == 'Third-Party' && taxItem.SO_Payment_Role__c != null) ? taxItem.Enhanced_Tax_Amount__c*-1 : taxItem.Enhanced_Tax_Amount__c;
        		taxIdToEnhTaxAmountMap.put(formattedSTIName, taxIdToEnhTaxAmountMap.get(formattedSTIName) + enhTaxAmount);
        	} else if(String.isNotBlank(formattedSTIName)) {
                if(!taxFormattedNameToTaxableAmountMap.containsKey(formattedSTIName)){
                    taxFormattedNameToTaxableAmountMap.put(formattedSTIName, 0);
                }
                Decimal taxableAmount = 0;
                if(handleSOPaymentRole != null && handleSOPaymentRole && taxItem.SO_Payment_Role__c != null) {
                    if(!isTaxIncludingPricing) {
                        taxableAmount = soPaymentRoleIdToRecMap.get(taxItem.SO_Payment_Role__c).Total_Amount__c;
                    } else if(soPaymentRoleIdToRecMap.get(taxItem.SO_Payment_Role__c).Tax__c != 0) {
                        taxableAmount = (soPaymentRoleIdToRecMap.get(taxItem.SO_Payment_Role__c).Tax_Amount__c*(taxItem.Tax_Rate__c/soPaymentRoleIdToRecMap.get(taxItem.SO_Payment_Role__c).Tax__c)).setScale(2, RoundingMode.HALF_UP);
                    }
                    if(String.isNotBlank(invoiceType) && invoiceType == 'Third-Party') {
                        taxableAmount *= -1;
                    }
                } else {
                    if(!isTaxIncludingPricing) {
                        if(taxItem.Deal__c != null) {
                            taxableAmount = taxItem.Taxable_Amount_for_Section_Header__c;
                        } else {
                            taxableAmount = (isInvoiced ? taxItem.Taxable_Amount__c : taxItem.Taxable_Amount_To_Invoice__c);   //Tax amount before invoice - when coli is in multiple status
                        }
                    } else {
                        taxableAmount = (isInvoiced ? taxItem.Tax_Amount__c : taxItem.Tax_Amount_To_Invoice__c);   //Tax amount before invoice - when coli is in multiple status
                    }
                }
                taxFormattedNameToTaxableAmountMap.put(formattedSTIName, taxFormattedNameToTaxableAmountMap.get(formattedSTIName) + taxableAmount);
            }
        }
        
        // Iteration for Form label type Individual Items.
        Map<String, Decimal> taxIdToTaxAmountMap = new Map<String, Decimal>();
        for(String taxFormtName : taxFormattedNameToTaxableAmountMap.keySet()) {
            Decimal taxAmount = 0;
            if(taxFormattedNameToTaxRateMap.containsKey(taxFormtName) && taxFormattedNameToTaxRateMap.get(taxFormtName) != null) {
                if(!isTaxIncludingPricing) {
                    taxAmount += (taxFormattedNameToTaxRateMap.get(taxFormtName) * taxFormattedNameToTaxableAmountMap.get(taxFormtName) / 100).setScale(2, RoundingMode.HALF_UP);
                } else {
                    taxAmount += taxFormattedNameToTaxableAmountMap.get(taxFormtName).setScale(2, RoundingMode.HALF_UP);
                }
            }
            if(taxAmount != null && taxAmount != 0) {
                if(taxIdToTaxAmountMap.containsKey(taxFormtName)) {
                    taxIdToTaxAmountMap.put(taxFormtName, taxIdToTaxAmountMap.get(taxFormtName) + taxAmount);
                } else {
                    taxIdToTaxAmountMap.put(taxFormtName, taxAmount);
                }
            }
        }
        
        for(String taxId : taxIdToEnhTaxAmountMap.keySet()) {
            Decimal taxAmount = taxIdToEnhTaxAmountMap.get(taxId);
            if(taxAmount != null && taxAmount != 0) {
                if(taxIdToTaxAmountMap.containsKey(taxId)) {
                    taxIdToTaxAmountMap.put(taxId, taxIdToTaxAmountMap.get(taxId) + taxAmount);
                } else {
                    taxIdToTaxAmountMap.put(taxId, taxAmount);
                }
            }
        }

        return taxIdToTaxAmountMap;
    }

    //Used in calculate section wise tax amount in merch and service sections
    public static Decimal getTaxAmount(List<Individual_Tax__c> individualTaxList) {
        Decimal totalTaxAmount = 0;
        if(!GeneralConfiguration.getTaxIncludingPricing()) {
            Map<String, Decimal> taxItemIdToTaxAmountMap = getTaxItemIdToTaxAmountMap(individualTaxList, getTaxFormattedNameToTaxRateMap(individualTaxList), '', false);
            for(Decimal taxAmt : taxItemIdToTaxAmountMap.values()) {
                totalTaxAmount += (taxAmt != null ? taxAmt : 0);
            }
        }
        return totalTaxAmount;
    }

    public static Decimal getTaxAmount_V2(List<Individual_Tax__c> individualTaxList) {
        Decimal totalTaxAmount = 0;
        Map<String, Decimal> taxItemIdToTaxAmountMap = getTaxItemIdToTaxAmountMap(individualTaxList, getTaxFormattedNameToTaxRateMap(individualTaxList), '', false);
        for(Decimal taxAmt : taxItemIdToTaxAmountMap.values()) {
            totalTaxAmount += (taxAmt != null ? taxAmt : 0);
        }
        return totalTaxAmount;
    }

    public class TaxDetail{
        public String TaxName;
        public Decimal TaxAmount;
        
        public TaxDetail(String taxName, Decimal taxableAmount, Decimal taxRate){
            if(taxableAmount == null){
                taxableAmount = 0;
            }
            if(taxRate == null){
                taxRate = 0;
            }
            this.TaxName = taxName;
            this.TaxAmount = (taxableAmount * taxRate).setScale(2, RoundingMode.HALF_UP);
        }
    }
    
    public static Map<Id, Set<Id>> getCOHeaderIdToTaxExemptionsIds(Set<Id> coHeaderIds) {
        if(!AccessControl.ifObjectFieldIsAccessible('Tax_Exemption__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

        List<Tax_Exemption__c> taxExemptionsList = [SELECT CO_Header__r.Customer__c, Sales_Tax_Item__r.Rate__c from Tax_Exemption__c where CO_Header__c IN: coHeaderIds];
        Map<Id, Set<Id>> coHeaderIdToSalesTaxItemIdsMap = new Map<Id, Set<Id>>();
        for(Id coHeaderId : coHeaderIds) {
            Set<Id> salesTaxItemIdSet = new Set<Id>();
            for(Tax_Exemption__c taxExemptionRec : taxExemptionsList) {
                if(taxExemptionRec.CO_Header__c == coHeaderId) {
                    salesTaxItemIdSet.add(taxExemptionRec.Sales_Tax_Item__c);
                }
            }
            coHeaderIdToSalesTaxItemIdsMap.put(coHeaderId, salesTaxItemIdSet);
        }
        return coHeaderIdToSalesTaxItemIdsMap;
    }

    public static List<Individual_Tax__c> getConditionalIndividualTaxList(List<CO_Line_Item__c> coliList, 
                            List<CO_Kit_Header__c> coKitHeadersList, List<Service_Order_Header__c> soHeaderList, List<Deal__c> dealList) {
        List<Id> coliIds = new List<Id>();
        List<Id> cokhIds = new List<Id>();
        Set<Id> soIds = new Set<Id>();
        List<Id> dealIds = new List<Id>();
        for(CO_Line_Item__c coli : coliList) {
            coliIds.add(coli.Id);
        }
        for(CO_Kit_Header__c cokh : coKitHeadersList) {
            cokhIds.add(cokh.Id);
        }
        for(Service_Order_Header__c soRec : soHeaderList) {
            soIds.add(soRec.Id);
        }
        for(Deal__c dealRec : dealList) {
            dealIds.add(dealRec.Id);
        }   
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();      
        return COService.getConditionalIndividualTaxList(isTaxIncludingPricing, TaxCalculation.isInvoiced, coliIds, cokhIds, soIds, dealIds);
    }
}