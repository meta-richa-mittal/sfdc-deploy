/**
 * Author: Nidhi Sharma
 * Since: Jan 03, 2017
 * Name: DealKH_Recalculation
 * Description: Apex class to handle Deal Kit Header 
**/
public without sharing class DealKH_Recalculation {
    
    public static String PART_PRICE_FIELD_API_NAME = 'Retail_Price__c';
    
    public static String calculatePriceForDealKitInsertion(String dealKHId, String dealItemId) {
        String result = DealKHPriceCalculation(dealKHId, dealItemId, null);
        return result; 
    }
    
    public static void changePriceWhenCustomerIsChanged(String customerId, String coHeaderId){
         List<Deal_Item__c> dealItemList;
         if(coHeaderId != null) {
            dealItemList = [select Id from Deal_Item__c where Deal__r.CO_Header__c =: coHeaderId AND Deal__r.Invoice_Number__c = null];
            for(Deal_Item__c dealItemRec : dealItemList) {
                DealKHPriceCalculation(null, dealItemRec.Id, customerId);
            }
         }
    }
    
    /**
     * Name: DealKHPriceCalculation
     * Desc: Deal kit header and line items price related calculation
     * @param:  (1) dealKHId - String - Deal Kit Header Id
     *          (2) dealItemId - String - Deal Item Id
     * @return: void
    **/
    public static String DealKHPriceCalculation(String dealKHId, String dealItemId, String customerId) { 
        List<Deal_Kit_Header__c> dealKHList;
        if(dealKHId != null) {
            dealKHList = SOQLUtil.getDealKitHeaderDetailsByFieldName(new Map<String, String>{'Id'=> dealKHId});
        } else {
            dealKHList = SOQLUtil.getDealKitHeaderDetailsByFieldName(new Map<String, String>{'Deal_Item__c'=> dealItemId});
        }
        if(!dealKHList.isEmpty()) {
            if(!CustomerOrderCtrl_V2.isRefreshCOKit || (COTriggerHelper.isResetPricing != null && COTriggerHelper.isResetPricing)) {
                dealKHList = applyPriceLevel(dealKHList);
            }
            dealKHList = applySalesTax(dealKHList, customerId);
            List<Sobject> sobjListToUpdate = new List<Sobject>(); 
            if(!dealKHList.isEmpty()) {
                sobjListToUpdate.addAll((List<Sobject>)dealKHList);
                for(Deal_Kit_Header__c dealKHRec : dealKHList) {
                    if(dealKHRec.Options_Fees__r != null) {
                        sobjListToUpdate.addAll((List<Sobject>)dealKHRec.Options_Fees__r);
                    }
                }
                update sobjListToUpdate;
            }
        }
        return 'Success';
    }
    
    /**
     * Name: applyPriceLevel
     * Desc: Apply price level
    **/
    public static List<Deal_Kit_Header__c> applyPriceLevel(List<Deal_Kit_Header__c> dealKHList) {
        
        Set<String> partIdSet = new Set<String>();
        Set<String> labourIdSet = new Set<String>();
        Set<String> feeIdSet = new Set<String>();
        Set<Id> dealItemIdSet = new Set<Id>();
        
        for(Deal_Kit_Header__c dealKHRec : dealKHList) {
            for(Option_Fee__c optionFeeRec : dealKHRec.Options_Fees__r) {
                if(optionFeeRec.Part__c != null) {
                    partIdSet.add(optionFeeRec.Part__c);
                    dealItemIdSet.add(dealKHRec.Deal_Item__c);
                } else if(optionFeeRec.Labour_Code__c != null) {
                    labourIdSet.add(optionFeeRec.Labour_Code__c);
                    dealItemIdSet.add(dealKHRec.Deal_Item__c);
                } else if(optionFeeRec.Fee__c != null) {
                    feeIdSet.add(optionFeeRec.Fee__c);
                    dealItemIdSet.add(dealKHRec.Deal_Item__c);
                }
            }
        }
        
        
        partIdSet.remove(null);
        labourIdSet.remove(null);
        feeIdSet.remove(null);
        Map<Id, Part__c> partIdToPartRecordMap = new Map<Id, Part__c>();
        Map<Id, Labour_Code__c> labourIdToLabourRecordMap = new Map<Id, Labour_Code__c>();
        Map<Id, Fee__c> feeIdToFeeRecordMap = new Map<Id, Fee__c>();
        
        if(partIdSet.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            partIdToPartRecordMap = new Map<Id, Part__c>([select Taxable__c, Applicable_Tax__c, Average_Cost__c, Last_Cost__c, 
            														MSRP__c, Retail_Price__c, Applicable_Tax__r.Rate__c, Sale_Price__c
                                                                        from Part__c where Id IN: partIdSet]);
        }
        
        if(labourIdSet.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Labour_Code__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            labourIdToLabourRecordMap = new Map<Id, Labour_Code__c>([select Rate__c, Taxable__c, Applicable_Tax__c, Applicable_Tax__r.Rate__c,
                                                                        Fixed_Rate__c
                                                                        from Labour_Code__c where Id IN: labourIdSet]);
        }
        
        if(feeIdSet.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            feeIdToFeeRecordMap = new Map<Id, Fee__c>([select Price__c, Taxable__c, Applicable_Tax__c, Applicable_Tax__r.Rate__c
                                                                        from Fee__c where Id IN: feeIdSet]);
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Map<Id, Deal_Item__c> dealItemIdTodealItemRecMap = new Map<Id, Deal_Item__c>([select Discount_Markup_From_Prive_Level__c, Part_Price_Base_From_Price_Level__c,
                                                                                            Labour_Rate_From_Price_Level__c
                                                                                            from Deal_Item__c Where Id IN : dealItemIdSet]);
        Decimal discount;
        String partPriceBase; 
        Decimal laborRate;                                              
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        
        for(Deal_Kit_Header__c dealKHRec : dealKHList) {
            if(dealKHRec.Is_Fixed_Price__c) {
                continue;
            }
            for(Option_Fee__c optionFeeRec : dealKHRec.Options_Fees__r) {
                if(optionFeeRec.Is_Fixed_Price__c || (COTriggerHelper.isRetainItemPrices && optionFeeRec.Part__c == null && optionFeeRec.Labour_Code__c == null)) {
                    continue;
                }
                partPriceBase = dealItemIdTodealItemRecMap.get(dealKHRec.Deal_Item__c).Part_Price_Base_From_Price_Level__c;
                laborRate = (dealItemIdTodealItemRecMap.get(dealKHRec.Deal_Item__c).Labour_Rate_From_Price_Level__c == null) ? 0 : dealItemIdTodealItemRecMap.get(dealKHRec.Deal_Item__c).Labour_Rate_From_Price_Level__c;
                discount = (dealItemIdTodealItemRecMap.get(dealKHRec.Deal_Item__c).Discount_Markup_From_Prive_Level__c == null) ? 0 : dealItemIdTodealItemRecMap.get(dealKHRec.Deal_Item__c).Discount_Markup_From_Prive_Level__c;
                
                if(optionFeeRec.Part__c != null) {
                
                	String pricingField = TaxCalculation.getPricingFieldByPLBaseValueField(partPriceBase);
                	
                	Part__c partRec = partIdToPartRecordMap.get(optionFeeRec.Part__c);
                	if(pricingField == 'Average_Cost__c' && (partRec.Average_Cost__c == null || partRec.Average_Cost__c == 0)) {
                        optionFeeRec.Retail__c = partRec.Last_Cost__c != null ? partRec.Last_Cost__c : 0;
                    } else {
                        optionFeeRec.Retail__c = (partRec.get(pricingField) != null) ? Decimal.valueOf(String.valueOf(partRec.get(pricingField))) : 0;
                    }
                    optionFeeRec.Price__c = optionFeeRec.Actual_Kit_Price__c = (optionFeeRec.Retail__c != null) ? 
                								optionFeeRec.Retail__c.setScale(2, RoundingMode.HALF_UP) : 0;
                	optionFeeRec.Price_When_Tax_Included__c = isTaxIncludingPricing ? optionFeeRec.Price__c : 0;
                	
                    Decimal appTaxRate;
                    if(isTaxIncludingPricing && !TaxCalculation.COST_FIELDS_SET.contains(pricingField) && partRec.Applicable_Tax__c != null) {
                        appTaxRate = partRec.Applicable_Tax__r.Rate__c;
                        if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
                            appTaxRate = 0;
                        }
                        optionFeeRec.Price__c = optionFeeRec.Price__c / (1 + (appTaxRate / 100));
                    }
                    
                    Decimal preTaxPrice = optionFeeRec.Price__c;
                    optionFeeRec.Price__c = optionFeeRec.Price__c + (optionFeeRec.Price__c * discount / 100);
                    optionFeeRec.Price__c = TaxCalculation.getPartPrice(optionFeeRec.Price__c, partRec.Sale_Price__c, appTaxRate);
                    if(isTaxIncludingPricing && preTaxPrice != optionFeeRec.Price__c) {
                    	optionFeeRec.Price_When_Tax_Included__c = null;
                    }
                } else if(optionFeeRec.Labour_Code__c != null) {
    
                	Labour_Code__c laborRec = labourIdToLabourRecordMap.get(optionFeeRec.Labour_Code__c);
    				if(laborRec.Fixed_Rate__c || (laborRate == null || laborRate == 0)) {
                        optionFeeRec.Price__c = laborRec.Rate__c;
                        } else {
                            optionFeeRec.Price__c = laborRate;
                        }
                    if(isTaxIncludingPricing) {
                        Decimal appTaxRate = laborRec.Applicable_Tax__r.Rate__c;
                        if(appTaxRate == -100 || appTaxRate == null) {
                            appTaxRate = 0;
                        }
                        optionFeeRec.Price__c = (optionFeeRec.Price__c / (1 + (appTaxRate / 100)));
                    }
                    
                } else if(optionFeeRec.Fee__c != null) {
                	optionFeeRec.Price__c = feeIdToFeeRecordMap.get(optionFeeRec.Fee__c).Price__c;
                	optionFeeRec.Price__c = optionFeeRec.Price__c != null ? optionFeeRec.Price__c : 0;
                    if(isTaxIncludingPricing && !optionFeeRec.Is_Fixed_Price__c) {
                        Decimal appTaxRate = feeIdToFeeRecordMap.get(optionFeeRec.Fee__c).Applicable_Tax__r.Rate__c;
                        if(appTaxRate == -100 || appTaxRate == null) {
                            appTaxRate = 0;
                        }
                        optionFeeRec.Price__c = optionFeeRec.Price__c / (1 + (appTaxRate / 100));
                    }
                }
                optionFeeRec.Actual_Kit_Price__c = optionFeeRec.Price__c;
            }
        }
        return dealKHList;
    }
    
    /**
     * Name: applySalesTax
     * Desc: Apply Sales Tax
    **/
    public static List<Deal_Kit_Header__c> applySalesTax(List<Deal_Kit_Header__c> dealKHList, String customerId) {
        Boolean isRecalculateTaxes = !CustomerOrderCtrl_V2.isRefreshCOKit || (COTriggerHelper.isRecalculateTaxes != null && COTriggerHelper.isRecalculateTaxes);
        Map<Id, Id> recIdToApplicableTaxIdMap = new Map<Id, Id>();
        
        if(isRecalculateTaxes) {
            TaxEngine.populateExemptionMap(TaxEngine.getSectionIdsForExemptions(TaxEngine.DKH, dealKHList));
            TaxEngine.setApplicableTaxes(TaxEngine.DKH, dealKHList, null, recIdToApplicableTaxIdMap);
        }

        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal taxAmount = 0;
        Decimal dealKHTotal = 0;
        
        //List<Option_Fee__c> unfixedLineItemList = new List<Option_Fee__c>();
        List<Individual_Tax__c> individualTaxToInsert = new List<Individual_Tax__c>();
        for(Deal_Kit_Header__c dealKHRec : dealKHList) {
        	taxAmount = 0;
        	dealKHTotal = 0;
            for(Option_Fee__c optionFeeRec : dealKHRec.Options_Fees__r) {
                Boolean isTaxChange = false;
                String optionFeeOldTaxId, entityTaxId;
                Id salesTaxId;
                Decimal exemptionRate = 0;
                Decimal rate = 0;
                Decimal enhancedTaxAmount = 0;
                if(isRecalculateTaxes) {
                    optionFeeOldTaxId = optionFeeRec.Applicable_Tax__c;
                    salesTaxId = optionFeeRec.Applicable_Tax__c = recIdToApplicableTaxIdMap.get(optionFeeRec.Id);
                    entityTaxId = DealUtil.getApplicableTaxOnEntity(optionFeeRec);
                    if(salesTaxId != null) {
                        exemptionRate = TaxEngine.getExemptionAndIndividualTaxes(TaxEngine.DKH, dealKHRec, optionFeeRec, salesTaxId, individualTaxToInsert);
                        if(TaxEngine.salesTaxIdToTaxRateMap.containsKey(salesTaxId)) {
                            rate = TaxEngine.salesTaxIdToTaxRateMap.get(salesTaxId);
                        }
                    }
                    isTaxChange = (isRecalculateTaxes && optionFeeRec.Sales_Tax_Percentage__c != rate - exemptionRate);
                    optionFeeRec.Sales_Tax_Percentage__c = rate - exemptionRate;
                } else {
                    isTaxChange = COTriggerHelper.isResetPricing;
                }
                optionFeeRec.Price__c = optionFeeRec.Price__c.setScale(2, RoundingMode.HALF_UP);
                if(isTaxIncludingPricing) {
                    if(dealKHRec.Is_Fixed_Price__c || optionFeeRec.Is_Fixed_Price__c) {
                    	if(optionFeeRec.Price_When_Tax_Included__c != null) {
                    		optionFeeRec.Price__c = (optionFeeRec.Price_When_Tax_Included__c / (1 + (optionFeeRec.Sales_Tax_Percentage__c / 100))).setScale(2, RoundingMode.HALF_UP);
                    	} else {
                    		optionFeeRec.Price__c = (optionFeeRec.Price__c / (1 + (optionFeeRec.Sales_Tax_Percentage__c / 100))).setScale(2, RoundingMode.HALF_UP);
                    		optionFeeRec.Price_When_Tax_Included__c = (optionFeeRec.Price__c * (1 + (optionFeeRec.Sales_Tax_Percentage__c / 100))).setScale(2, RoundingMode.HALF_UP);
                    	}
                    } else if(COTriggerHelper.isRetainItemPrices && optionFeeRec.Part__c == null && optionFeeRec.Labour_Code__c == null && optionFeeRec.Price_When_Tax_Included__c != null) {
                        optionFeeRec.Price__c = (optionFeeRec.Price_When_Tax_Included__c / (1 + (optionFeeRec.Sales_Tax_Percentage__c / 100))).setScale(2, RoundingMode.HALF_UP);
                    } else if(isTaxChange || optionFeeRec.Price_When_Tax_Included__c == null || exemptionRate > 0 || (optionFeeOldTaxId != optionFeeRec.Applicable_Tax__c) || (entityTaxId != optionFeeRec.Applicable_Tax__c)) {
                    	optionFeeRec.Price_When_Tax_Included__c = (optionFeeRec.Price__c * (1 + (optionFeeRec.Sales_Tax_Percentage__c / 100))).setScale(2, RoundingMode.HALF_UP);
                    }
                    dealKHTotal += (optionFeeRec.Price_When_Tax_Included__c * optionFeeRec.Qty__c);
                    taxAmount += ((optionFeeRec.Price__c * optionFeeRec.Qty__c * optionFeeRec.Sales_Tax_Percentage__c) / 100);
                } else {
                    // Deal Kit Header
                    dealKHTotal += (optionFeeRec.Price__c * optionFeeRec.Qty__c);
                    taxAmount += ((optionFeeRec.Price__c * optionFeeRec.Qty__c * optionFeeRec.Sales_Tax_Percentage__c) / 100) + enhancedTaxAmount;
                }
                
                optionFeeRec.Fixed_Price__c = optionFeeRec.Price__c;
            }
            dealKHRec.Tax_Amount__c = taxAmount.setScale(2, RoundingMode.HALF_UP);
            dealKHRec.Fixed_Price__c = dealKHTotal.setScale(2, RoundingMode.HALF_UP);
        }
		if(isRecalculateTaxes) {
            if(AccessControl.ifObjectFieldIsAccessible('Individual_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            DMLUtility.deleteSObjectList('Individual_Tax__c', [select Id from Individual_Tax__c where Option_Fee__r.Deal_Kit_Header__c IN :dealKHList]);
            DMLUtility.insertSobjectList('Individual_Tax__c', individualTaxToInsert);
        }
        return dealKHList;
    }
    
    public static String updateDealKitHeader(DealWrapper.DealKitHeader dealKitObj){
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Deal_Kit_Header__c> dealKHList = [Select Fixed_Price__c, Deal_Item__r.Deal__r.Status__c, Deal_Item__r.Option_And_Fee_Status__c, Is_Install__c, Tax_Amount__c, (SELECT Status__c FROM Options_Fees__r LIMIT 1), (SELECT Id FROM CO_Kit_Headers__r LIMIT 1), (SELECT Id FROM Service_Order_Kit_Headers__r LIMIT 1) from Deal_Kit_Header__c where Id =: dealKitObj.Id];
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        if(dealKHList.size() > 0) {
            if(dealKHList[0].Is_Install__c != dealKitObj.IsInstall) {
                dealKHList[0].Is_Install__c = dealKitObj.IsInstall;
                DMLUtility.updateSobjectList('Deal_Kit_Header__c', dealKHList);
                if(dealKHList[0].Deal_Item__r.Deal__r.Status__c == Constants.IN_PROGRESS && (dealKHList[0].CO_Kit_Headers__r.size() > 0 || dealKHList[0].Service_Order_Kit_Headers__r.size() > 0 || (dealKHList[0].Options_Fees__r.size() > 0 && dealKHList[0].Options_Fees__r[0].Status__c == Constants.COMMITTED))) {
                    DealService.moveDealMerchAndServiceLineItems(BPUtility.getEncodedString(dealKitObj.Id), BPUtility.getEncodedString(dealKitObj.CoHeaderId));
                }
                return 'Success';
            }
            
            if(dealKHList[0].Fixed_Price__c == null) {
                dealKHList[0].Fixed_Price__c = 0;
            }
            Decimal prePrice = dealKHList[0].Fixed_Price__c;
            Decimal updatedPrice = (dealKitObj.Price).setScale(2, RoundingMode.HALF_UP);
            /*
            if(isTaxIncludingPricing) {
                if(dealKHList[0].Tax_Amount__c == null) {
                    dealKHList[0].Tax_Amount__c = 0;
                }
                prePrice = (prePrice + dealKHList[0].Tax_Amount__c).setScale(2, RoundingMode.HALF_UP);
            }*/
            if(updatedPrice == prePrice) {
                return 'Success';
            }
        }
        
        Decimal fixedTotal = 0.00;
        Decimal unfixedTotal = 0.00;
        for(DealWrapper.OptionAndFeeInfo optionFeeObj : dealKitObj.OptionAndFeeList){
            if(optionFeeObj.IsFixedPrice || optionFeeObj.IsFixedPriceForCO) {
                fixedTotal +=(optionFeeObj.Qty * optionFeeObj.Price) ;
            } else{
                unfixedTotal += (optionFeeObj.Qty * optionFeeObj.Price);
            }
        }
        if(dealKitObj.Price < fixedTotal) {
            return 'Kit Header Total cannot Less than Line Item Total';
        } else if(unfixedTotal == 0) {
            return 'Kit Header Line Item price cannot be updated because no unfixed line item with price greater than 0 is present to adjust the total price';
        } else {
            Decimal adjustment = (dealKitObj.Price - fixedTotal) / unfixedTotal;
            adjustment = (adjustment < 0) ? (adjustment * -1) : adjustment;
            Decimal counter = 1;
            Decimal subTotal = 0;
            for(DealWrapper.OptionAndFeeInfo optionFeeObj : dealKitObj.OptionAndFeeList) {
                if(!(optionFeeObj.IsFixedPrice || optionFeeObj.IsFixedPriceForCO)){
                    optionFeeObj.Price = (adjustment * optionFeeObj.Price).setScale(2, RoundingMode.HALF_UP);
                } 
            }
        }
        
        Decimal totalPrice = 0;
        Decimal totalTaxAmount = 0;
        Option_Fee__c unfixedQtyOneKitLi;
        List<SObject> sObjectListToUpdate = new List<SObject>();
        for(DealWrapper.OptionAndFeeInfo optionFeeObj : dealKitObj.OptionAndFeeList) {
        	Decimal price  = optionFeeObj.Price.setScale(2, RoundingMode.HALF_UP);
        	if(isTaxIncludingPricing){
                optionFeeObj.Price = (optionFeeObj.Price / (1 + (optionFeeObj.SalesTaxPercentage / 100))).setScale(2, RoundingMode.HALF_UP);
            }
            if(!optionFeeObj.IsFixedPrice && !optionFeeObj.IsFixedPriceForCO) {
                Option_Fee__c optionFeeRec = new Option_Fee__c(Id = optionFeeObj.Id);
                optionFeeRec.Price__c = optionFeeObj.Price.setScale(2, RoundingMode.HALF_UP);
                if(isTaxIncludingPricing) {
                	optionFeeRec.Price_When_Tax_Included__c = price;
                }
                sObjectListToUpdate.add(optionFeeRec);
                if(unfixedQtyOneKitLi == null && optionFeeObj.Qty == 1) {
                    unfixedQtyOneKitLi = optionFeeRec;
                }
            }
            totalPrice += (price * optionFeeObj.Qty).setScale(2, RoundingMode.HALF_UP);
            totalTaxAmount +=  (optionFeeObj.Qty * ((optionFeeObj.Price * optionFeeObj.SalesTaxPercentage)/100)); 
        }
        
        if(dealKitObj.Id != null) {
            totalPrice = totalPrice.setScale(2, RoundingMode.HALF_UP);
            dealKitObj.Price = (dealKitObj.Price).setScale(2, RoundingMode.HALF_UP);
            if(unfixedQtyOneKitLi != null && (totalPrice - dealKitObj.Price != 0) && (dealKitObj.IsFixedPriceForCO || dealKitObj.IsFixedPrice)) {
                if(isTaxIncludingPricing){    
                    ((Option_Fee__c)sObjectListToUpdate[sObjectListToUpdate.indexOf(unfixedQtyOneKitLi)]).Price_When_Tax_Included__c += dealKitObj.Price - totalPrice;
                } else{
                    ((Option_Fee__c)sObjectListToUpdate[sObjectListToUpdate.indexOf(unfixedQtyOneKitLi)]).Price__c += dealKitObj.Price - totalPrice;
                }
                totalPrice = dealKitObj.Price;
            }
            if(totalPrice < 0){
                return 'Kit total price cannot be negative.';
            }
            Deal_Kit_Header__c dealKitHeaderRec = new Deal_Kit_Header__c(Id = dealKitObj.Id, Fixed_Price__c = totalPrice, 
                                                                            Tax_Amount__c = totalTaxAmount.setScale(2, RoundingMode.HALF_UP),
                                                                            Is_Fixed_Kit_Header_CO__c = true);
            sObjectListToUpdate.add(dealKitHeaderRec);
        }
        if(sObjectListToUpdate.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Deal_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update sObjectListToUpdate;
        }
        return 'Success'; 
    }
    
    public static String updateDealKitLineItem(DealWrapper.DealKitHeader dealKitObj, DealWrapper.OptionAndFeeInfo optionFeeItemObj) {
        if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Option_Fee__c> optionFeeList = [Select Price__c, Sales_Tax_Percentage__c from Option_Fee__c where Id =: optionFeeItemObj.Id];
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        if(optionFeeList.size() > 0) {
            if(optionFeeList[0].Price__c == null) {
                optionFeeList[0].Price__c = 0;
            }
            Decimal prePrice = optionFeeList[0].Price__c;
            Decimal UpdatedPrice = optionFeeItemObj.Price;
            
            if(isTaxIncludingPricing) {
                if(optionFeeList[0].Sales_Tax_Percentage__c == null) {
                    optionFeeList[0].Sales_Tax_Percentage__c = 0;
                }
                prePrice = (prePrice * (1 + optionFeeList[0].Sales_Tax_Percentage__c /100)).setScale(2, RoundingMode.HALF_UP);
            }
            if(UpdatedPrice == prePrice) {
                return 'Success';
            }
        } 
            
        if(dealKitObj.IsFixedPrice || dealKitObj.IsFixedPriceForCO) {
            Decimal fixedTotal = 0.00;
            Decimal unfixedTotal = 0.00;
            for(DealWrapper.OptionAndFeeInfo optionFeeObj : dealKitObj.OptionAndFeeList){
                if(optionFeeObj.IsFixedPrice || optionFeeObj.IsFixedPriceForCO || optionFeeObj.Id == optionFeeItemObj.Id) {
                    fixedTotal +=(optionFeeObj.Qty * optionFeeObj.Price) ;
                } else{
                    unfixedTotal  += (optionFeeObj.Qty * optionFeeObj.Price);
                }
            }
            if(dealKitObj.Price < fixedTotal) {
                return 'Kit Header Total cannot Less than Line Item Total';
            } else if(unfixedTotal == 0) {
                return 'Kit Header Line Item price cannot be updated because no unfixed line item with price greater than 0 is present to adjust the total price';
            } else {
                Decimal adjustment = (dealKitObj.Price - fixedTotal) / unfixedTotal;
                adjustment = (adjustment < 0) ? (adjustment * -1) : adjustment;
                for(DealWrapper.OptionAndFeeInfo optionFeeObj : dealKitObj.OptionAndFeeList) {
                    if(optionFeeObj.Id == optionFeeItemObj.Id) {
                        optionFeeObj.IsFixedPriceForCO = true;
                    } else if(!(optionFeeObj.IsFixedPrice || optionFeeObj.IsFixedPriceForCO)) {
                        optionFeeObj.Price = (adjustment * optionFeeObj.Price);
                    } 
                    if(isTaxIncludingPricing && optionFeeObj.Id == optionFeeItemObj.Id){
                        optionFeeObj.Price = (optionFeeObj.Price / (1 + (optionFeeObj.SalesTaxPercentage / 100))).setScale(2, RoundingMode.HALF_UP);
                    }
                    
                }
            }
        } else {
            for(DealWrapper.OptionAndFeeInfo optionFeeObj : dealKitObj.OptionAndFeeList) {
            	
            	if(isTaxIncludingPricing && optionFeeObj.Id == optionFeeItemObj.Id) {
                    optionFeeObj.Price = (optionFeeObj.Price / (1 + (optionFeeObj.SalesTaxPercentage / 100))).setScale(2, RoundingMode.HALF_UP);
                }
                if(optionFeeObj.Id == optionFeeItemObj.Id) {
                    optionFeeObj.IsFixedPriceForCO =true;
                }
            }
        }
            
        Decimal totalTaxAmount = 0;
        Decimal totalPrice = 0;
        List<SObject> sObjectListToUpdate = new List<SObject>();
        Option_Fee__c unfixedQtyOneKitLi;
        for(DealWrapper.OptionAndFeeInfo optionFeeObj : dealKitObj.OptionAndFeeList) {
        	Decimal price  = (isTaxIncludingPricing && optionFeeObj.Id == optionFeeItemObj.Id) ? (optionFeeObj.Price * (1 + (optionFeeObj.SalesTaxPercentage / 100))).setScale(2, RoundingMode.HALF_UP) : optionFeeObj.Price.setScale(2, RoundingMode.HALF_UP);
        	if(isTaxIncludingPricing && optionFeeObj.Id != optionFeeItemObj.Id){
                optionFeeObj.Price = (optionFeeObj.Price / (1 + (optionFeeObj.SalesTaxPercentage / 100))).setScale(2, RoundingMode.HALF_UP);
            }
            if(!(optionFeeObj.IsFixedPrice || optionFeeObj.IsFixedPriceForCO) || optionFeeObj.Id == optionFeeItemObj.Id) {
                Option_Fee__c optionFeeRec = new Option_Fee__c(Id = optionFeeObj.Id);
                optionFeeRec.Price__c = optionFeeObj.Price.setScale(2, RoundingMode.HALF_UP);
                if(isTaxIncludingPricing) {
                	optionFeeRec.Price_When_Tax_Included__c = price;
                }
                optionFeeRec.Is_Fixed_Kit_Line_Item_CO__c = optionFeeObj.IsFixedPriceForCO;
                sObjectListToUpdate.add(optionFeeRec);
                if(unfixedQtyOneKitLi == null && optionFeeObj.Qty == 1 && optionFeeObj.Id != optionFeeItemObj.Id) {
                    unfixedQtyOneKitLi = optionFeeRec;
                }
            }
            
            totalPrice += (price * optionFeeObj.Qty).setScale(2, RoundingMode.HALF_UP);
            totalTaxAmount += (optionFeeObj.Qty * ((optionFeeObj.Price * optionFeeObj.SalesTaxPercentage)/100)); 
        }
        
        if(dealKitObj.Id != null) {
            totalPrice = totalPrice.setScale(2, RoundingMode.HALF_UP);
            dealKitObj.Price = (dealKitObj.Price).setScale(2, RoundingMode.HALF_UP);
            if(unfixedQtyOneKitLi != null && (totalPrice - dealKitObj.Price != 0) && (dealKitObj.IsFixedPriceForCO || dealKitObj.IsFixedPrice)) {
                if(isTaxIncludingPricing){    
                    ((Option_Fee__c)sObjectListToUpdate[sObjectListToUpdate.indexOf(unfixedQtyOneKitLi)]).Price_When_Tax_Included__c += dealKitObj.Price - totalPrice;
                } else{
                    ((Option_Fee__c)sObjectListToUpdate[sObjectListToUpdate.indexOf(unfixedQtyOneKitLi)]).Price__c += dealKitObj.Price - totalPrice;
                }
                totalPrice = dealKitObj.Price;
            }
            if(totalPrice < 0){
                return 'Kit total price cannot be negative.';
            }
            Deal_Kit_Header__c dealKitHeaderRec = new Deal_Kit_Header__c(Id = dealKitObj.Id, Fixed_Price__c = totalPrice, Tax_Amount__c = totalTaxAmount.setScale(2, RoundingMode.HALF_UP));
            sObjectListToUpdate.add(dealKitHeaderRec);
        }
        
        if(sObjectListToUpdate.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Deal_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update sObjectListToUpdate;
        }
        
        if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
            List<Deal_Kit_Header__c> dealKHList = SOQLUtil.getDealKitHeaderDetailsByFieldName(new Map<String, String>{'Id'=> dealKitObj.Id});
            dealKHList = applySalesTax(dealKHList, null);
            List<Sobject> sobjListWithTaxToUpdate = new List<Sobject>(); 
            if(dealKHList.size() > 0) {
                sobjListWithTaxToUpdate.addAll((List<Sobject>)dealKHList);
                for(Deal_Kit_Header__c dealKHRec : dealKHList) {
                    if(dealKHRec.Options_Fees__r != null) {
                        sobjListWithTaxToUpdate.addAll((List<Sobject>)dealKHRec.Options_Fees__r);
                    }
                }
            }    
            if(sobjListWithTaxToUpdate.size() > 0) {
                update sobjListWithTaxToUpdate;
            }    
        }
        
        
        return 'Success'; 
    }
    
    // Round Off Adjusting - Added by TK
    @TestVisible
    private static List<Option_Fee__c> resolveRoundOffIssue(List<Option_Fee__c> optionFeeList, Decimal unFixedKitHeaderPrice,
    																Boolean isTaxIncludingPricing) {
        Decimal total = 0;
    	for(Option_Fee__c optionFeeRec : optionFeeList) {
    		if(!optionFeeRec.Is_Fixed_Price__c) {
	    		if(!isTaxIncludingPricing) {
	    			total += (optionFeeRec.Price__c * optionFeeRec.Qty__c);
	    		} else {
	    			total += (optionFeeRec.Price_When_Tax_Included__c * optionFeeRec.Qty__c);
	    		}
    		}
    	}
    	
    	if(total - unFixedKitHeaderPrice != 0) {
    		if(optionFeeList.size() > 0) {
    			if(!isTaxIncludingPricing) {
	    			optionFeeList[optionFeeList.size() - 1].Price__c -= ((total - unFixedKitHeaderPrice) / optionFeeList[optionFeeList.size() - 1].Qty__c).setScale(2, RoundingMode.HALF_UP);
	    		} else {
	    			optionFeeList[optionFeeList.size() - 1].Price_When_Tax_Included__c -= ((total - unFixedKitHeaderPrice)/ optionFeeList[optionFeeList.size() - 1].Qty__c).setScale(2, RoundingMode.HALF_UP);
	    		}
    		}
    	}
    	return optionFeeList;
    }
    
}