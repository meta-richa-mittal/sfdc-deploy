public without sharing class FIProductTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    public static List<F_I_Product__c> FIProductNewList = new List<F_I_Product__c>();
    public static List<F_I_Product__c> FIProductOldList = new List<F_I_Product__c>();
    public static Map<Id, F_I_Product__c> FIProductNewMap = new Map<Id, F_I_Product__c>();
    public static Map<Id, F_I_Product__c> FIProductOldMap = new Map<Id, F_I_Product__c>();
    public static Set<String> dealIdSet = new Set<String>();
    public static Boolean isTriggerExecute = false;
    public static Boolean isCustomerPLUpdate = false;
    
    public static void beforeInsertCalculation() {
    	priceLevelCalculation();
    }
    
    public static void beforeUpdateCalculation() {
    	priceLevelCalculation();
        if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c && isCustomerPLUpdate && (COTriggerHelper.isRecalculateTaxes == null || !COTriggerHelper.isRecalculateTaxes)) {
            for(F_I_Product__c fAndIProductRec : FIProductNewList) {
                if(fAndIProductRec.Price__c != null && fAndIProductRec.Sales_Tax_Percentage__c != null) {
					fAndIProductRec.Price_When_Tax_Included__c = (fAndIProductRec.Price__c * (1 + fAndIProductRec.Sales_Tax_Percentage__c/100));
    }
            }
        }
    }
    
    public static void afterInsertCalculation() {
    	salesTaxCalculation();
        updateDealFinanceTotal(getDealFinanceIdSet(FIProductNewList));
    }
    
    public static void afterUpdateCalculation() {
        if(!isTriggerExecute){ 
            if((isCustomerPLUpdate && COTriggerHelper.isRecalculateTaxes != null && COTriggerHelper.isRecalculateTaxes) || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
                salesTaxCalculation();
            }
            updateDealFinanceTotal(getDealFinanceIdSet(FIProductNewList));
        }
    }
    
    public static void afterDeleteCalculation() {
    	updateDealFinanceTotal(getDealFinanceIdSet(FIProductOldList));
    }
    
    private static Set<String> getDealFinanceIdSet(List<F_I_Product__c> fAndIProductList) {
        Set<String> dealFinanceIdSet = new Set<String>();
        for(F_I_Product__c fAndIProductRec : fAndIProductList) {
            dealFinanceIdSet.add(fAndIProductRec.Deal_Finance__c);
        }
        return dealFinanceIdSet;
    }
    
    private static void updateDealFinanceTotal(Set<String> dealFinanceObjIdSet) {
    	if(!AccessControl.ifObjectFieldIsAccessible('F_I_Product__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(!AccessControl.ifObjectFieldIsAccessible('Deal_Finance__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Deal_Finance__c> dealFinanceList = [SELECT Deal__c, (SELECT Cost_Method__c, Price__c, Price_When_Tax_Included__c, Sales_Tax__c, Sales_Tax_Percentage__c FROM F_I_Products__r) 
                                                        FROM Deal_Finance__c WHERE Id IN: dealFinanceObjIdSet];
        Decimal totalTax, totalPrice, totalWithheldPrice;
        Set<String> dealIdSet = new Set<String>();
        for(Deal_Finance__c dealFinanceRec : dealFinanceList) {
        	dealIdSet.add(dealFinanceRec.Deal__c);
            totalTax = totalPrice = totalWithheldPrice = 0.00;
            for(F_I_Product__c fAndIProductRec : dealFinanceList[0].F_I_Products__r) {
                fAndIProductRec.Price__c = (fAndIProductRec.Price__c == null) ? 0 : fAndIProductRec.Price__c;
                fAndIProductRec.Sales_Tax_Percentage__c = (fAndIProductRec.Sales_Tax_Percentage__c == null) ? 0 : fAndIProductRec.Sales_Tax_Percentage__c;
                Decimal taxAmount = 0;
                if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
                    taxAmount = fAndIProductRec.Sales_Tax__c != null ? fAndIProductRec.Sales_Tax__c : 0;
                } else {
                    taxAmount = (fAndIProductRec.Price__c * fAndIProductRec.Sales_Tax_Percentage__c / 100).setScale(2, RoundingMode.HALF_UP);
                }
                totalTax += taxAmount;
                if(GeneralConfiguration.getTaxIncludingPricing() && fAndIProductRec.Price_When_Tax_Included__c != null) {
                    totalPrice += (fAndIProductRec.Price_When_Tax_Included__c - taxAmount);
                } else {
                    totalPrice += fAndIProductRec.Price__c;
                }
                if(String.isNotBlank(fAndIProductRec.Cost_Method__c) && fAndIProductRec.Cost_Method__c.equalsIgnoreCase('Price withheld')) {
                    totalWithheldPrice += fAndIProductRec.Price__c;
                }
            }
            system.debug('== totalTax == ' + totalTax);
            dealFinanceRec.F_I_Product_Tax_Total__c = totalTax;
            dealFinanceRec.F_I_Total__c = totalPrice;
            dealFinanceRec.Withheld_F_I_Total__c = totalWithheldPrice;
        }
        DMLUtility.updateSobjectList('Deal_Finance__c', dealFinanceList);
    	
    	if(!COTriggerHelper.isRecalculateCOPLAndTax) {
    		OptionAndFeeTriggerHelper.updateDealTotal(dealIdSet);
    	}
    }
    
    private static void priceLevelCalculation() {
        if(AccessControl.ifObjectFieldIsAccessible('Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	 
        Set<Id> productIdSet = new Set<Id>();
        for(F_I_Product__c fAndIProductRec : FIProductNewList) {
        	dealIdSet.add(fAndIProductRec.Deal__c);
            if(fAndIProductRec.Vendor_Product__c != null) {
            	productIdSet.add(fAndIProductRec.Vendor_Product__c);
            }
        }
        
        productIdSet.remove(null);
        
    	Map<Id, Product__c> productIdToProductRecordMap = new Map<Id, Product__c>();
        if(AccessControl.ifObjectFieldIsAccessible('Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(productIdSet.size() > 0) {
        	productIdToProductRecordMap = new Map<Id, Product__c>([select Price__c, Taxable__c, Applicable_Tax__c, Applicable_Tax__r.Rate__c,
                                                                    Cost_Method__c, Cost__c from Product__c where Id IN: productIdSet]);
        }
    	
    	if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Map<Id, Deal__c> dealItemIdTodealItemRecMap = new Map<Id, Deal__c>([select CO_Header__r.Discount_Markup_From_Prive_Level__c, CO_Header__r.Part_Price_Base_From_Price_Level__c
                                                                                            from Deal__c Where Id IN : dealIdSet]);
                                                                                            
        Decimal discount;
        String partPriceBase; 
		for(F_I_Product__c fAndIproductRec : FIProductNewList) {
        	discount = (dealItemIdTodealItemRecMap.get(fAndIproductRec.Deal__c).CO_Header__r.Discount_Markup_From_Prive_Level__c == null) ? 0 : dealItemIdTodealItemRecMap.get(fAndIproductRec.Deal__c).CO_Header__r.Discount_Markup_From_Prive_Level__c;
        	partPriceBase = dealItemIdTodealItemRecMap.get(fAndIproductRec.Deal__c).CO_Header__r.Part_Price_Base_From_Price_Level__c;
        	
            priceLevelCalculation(partPriceBase, discount, fAndIproductRec, productIdToProductRecordMap);
        }                                                                                  	
    }
    
    
    private static void priceLevelCalculation(String priceLevel_baseValueField, Decimal priceLevel_discountMarkup, F_I_Product__c fAndIproductRec, 
    											Map<Id, Product__c> productIdToProductRecordMap) {
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal price = 0;
        if(fAndIproductRec.Vendor_Product__c != null) {
        	Decimal productPrice = productIdToProductRecordMap.get(fAndIproductRec.Vendor_Product__c).Price__c;
        	if(isTaxIncludingPricing) {
        		Decimal appTaxRate = productIdToProductRecordMap.get(fAndIproductRec.Vendor_Product__c).Applicable_Tax__r.Rate__c;
                if(appTaxRate == -100 || appTaxRate == null) { // To handle divide by zero error
                    appTaxRate = 0;
                }
                Decimal preTaxPricing = productPrice / (1 + (appTaxRate / 100));
                price = preTaxPricing;
        	} else {
        		price = productPrice;
        	}
        }
        
        if((trigger.isInsert || (isCustomerPLUpdate && (COTriggerHelper.isResetPricing != null && COTriggerHelper.isResetPricing))) && fAndIproductRec.Vendor_Product__c != null) {
            fAndIproductRec.Price__c = (price != null ? price : 0);
            Product__c productRec = productIdToProductRecordMap.get(fAndIproductRec.Vendor_Product__c);
            fAndIproductRec.Cost_Method__c = productRec.Cost_Method__c;
            fAndIproductRec.Cost__c = (productRec.Cost__c != null ? productRec.Cost__c : 0).setScale(2, RoundingMode.HALF_UP);
            if(fAndIproductRec.Cost_Method__c == 'Percent Retail') {
                fAndIproductRec.Cost_Rate__c = fAndIproductRec.Cost__c;
                fAndIproductRec.Cost__c = ((fAndIproductRec.Price__c * fAndIproductRec.Cost_Rate__c)/100).setScale(2, RoundingMode.HALF_UP);
            }
        }
    }
    
    public static void salesTaxCalculation() {
        isTriggerExecute = true;
        
        // Tax Exemption List
        List<F_I_Product__c> fAndIProductList = [SELECT Applicable_Tax__c, Vendor_Product__c, Vendor_Product__r.Applicable_Tax__c, Vendor_Product__r.Applicable_Tax__r.Rate__c,
        												Deal__r.CO_Header__c, Deal__r.CO_Header__r.Customer__c, Price__c, Price_When_Tax_Included__c, Deal__r.Is_Tax_Based_On_Customer_Address__c, 
        												(SELECT Id FROM Individual_Taxes__r) 
    												FROM F_I_Product__c where Id IN: trigger.new];
    	
        TaxEngine.applySalesTaxonFIProdList(fAndIProductList);
    }
}