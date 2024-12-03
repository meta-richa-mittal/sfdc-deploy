/**
 * Author: Tarun Khandelwal
 * Since: March 27, 2014
 * Name: COTriggerHelper
 * Description: Helper class for triggers on CO Header object
**/
public without sharing class COTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    // List to store trigger new list
    public static List<CO_Header__c> COHeaderNewList = new List<CO_Header__c>();
    
    // List to store trigger old list
    public static List<CO_Header__c> COHeaderOldList = new List<CO_Header__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, CO_Header__c> COHeaderNewMap = new Map<Id, CO_Header__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, CO_Header__c> COHeaderOldMap = new Map<Id, CO_Header__c>();
    
    // Variable to stop nested looping
    public static Boolean isTriggerExecute = false;
    
    // List to store Default sales tax
    public static List<Sales_Tax__c> defaultSalesTax;
    
    public static List<Price_Level__c> defaultPriceLevel;
    
    public static Boolean isCOInvoiceHeaderUpdated = false;
    public static Boolean isCalculatePLandTax = false;
    public static Boolean isRecalculateCOPLAndTax = false;
    public static Boolean isResetPricing = true;
    public static Boolean isRecalculateTaxes = true;
    public static Boolean isRetainItemPrices = false;
    
     /**
     * Name: beforeInsertOperation
     * Desc: Before Insert Method
     * @param: 
     * @return: 
    **/
    public static void beforeInsertOperation() {
    	setCOClosedDateTime(COHeaderNewList);
        setCOBasicFields(COHeaderNewList);
    }
    
    private static Set<Id> getCustomerIdSet(List<CO_Header__c> coList) {
        Set<Id> customersIdSet = new Set<Id>();
        for(CO_Header__c coHeaderRec : coList) {
            if(coHeaderRec.Customer__c != null) {
                customersIdSet.add(coHeaderRec.Customer__c);
            }
        }
        return customersIdSet;
    }

    private static void setApplicablePriceLevelOnCO(CO_Header__c coHeaderRec, Price_Level__c applicablePriceLevel) {
        if(coHeaderRec != null) {
            if(applicablePriceLevel != null) {
                coHeaderRec.Discount_Markup_From_Prive_Level__c = applicablePriceLevel.Discount_Markup__c;
                coHeaderRec.Part_Price_Base_From_Price_Level__c = applicablePriceLevel.Part_Price_Base__c;
                coHeaderRec.Labour_Rate_From_Price_Level__c = applicablePriceLevel.Labour_Rate__c;
            } else {
                coHeaderRec.Discount_Markup_From_Prive_Level__c = coHeaderRec.Labour_Rate_From_Price_Level__c = 0;
                coHeaderRec.Part_Price_Base_From_Price_Level__c = null;
            }
        }
    }
    
    private static Map<Id, Account> getCustomerIdToRecMap(Set<Id> customersIdSet) {
        Map<Id, Account> customerIdToRecMap = new Map<ID, Account>();
        if(customersIdSet != null && customersIdSet.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            customerIdToRecMap = new Map<ID, Account>([select Id, Account_Type__c, Price_Level__c, Price_Level__r.Discount_Markup__c, Price_Level__r.Part_Price_Base__c, 
            Price_Level__r.Labour_Rate__c from Account Where Id IN :customersIdSet]);
        }
        return customerIdToRecMap;
    }

    private static void setCOBasicFields(List<CO_Header__c> coList) {
        Map<Id, Account> customerIdToRecMap = getCustomerIdToRecMap(getCustomerIdSet(coList));

        Id defaultAccountTypeId;
        Price_Level__c defaultInternalPriceLevel, systemDefaultPriceLevel;

        for(CO_Header__c coHeaderRec : coList) {
            Price_Level__c applicablePriceLevel;
            String applicableAccountTypeId;
            //Set customer's applicable PL and Account type
            if(coHeaderRec.Customer__c != null && customerIdToRecMap.containsKey(coHeaderRec.Customer__c)) {
                applicablePriceLevel = customerIdToRecMap.get(coHeaderRec.Customer__c).Price_Level__r;
                applicableAccountTypeId = customerIdToRecMap.get(coHeaderRec.Customer__c).Account_Type__c;
            }
            //Set Internal Service applicable PL
            if(String.isNotBlank(coHeaderRec.CO_Type__c) && coHeaderRec.CO_Type__c.equalsIgnoreCase(Constants.INTERNAL_SERVICE)) {
                if(defaultInternalPriceLevel == null) {
                    List<Price_Level__c> plList = PriceLevelService.getInternalDefaultPriceLevel();
                    defaultInternalPriceLevel = (plList != null && plList.size() > 0) ? plList[0] : null;
                }
                applicablePriceLevel = defaultInternalPriceLevel;
            } else {
                //Set system Default Customer's Account Type if applicable account type is blank
                if(!isRecalculateCOPLAndTax || (isRecalculateTaxes != null && isRecalculateTaxes)) {
                    if(String.isBlank(applicableAccountTypeId)) {
                        if(String.isBlank(defaultAccountTypeId)) {
                            defaultAccountTypeId = AccountTypeService.getDefaultAccoutTypeRecId('Customers');
                        }
                        applicableAccountTypeId = defaultAccountTypeId;
                    }
                    coHeaderRec.Account_Type__c = applicableAccountTypeId;
                }
            }
            //Set system Default PL if applicable PL is blank
            if(applicablePriceLevel == null) {
                if(systemDefaultPriceLevel == null) {
                    List<Price_Level__c> plList = getDefaultPriceLevel();
                    systemDefaultPriceLevel = plList.size() > 0 ? plList[0] : null;
                }
                applicablePriceLevel = systemDefaultPriceLevel;                
            }
            //Set CO Price Level related fields
            if(!isRecalculateCOPLAndTax || (isResetPricing != null && isResetPricing)) {
                setApplicablePriceLevelOnCO(coHeaderRec, applicablePriceLevel);
            }
        }
    }

    public static void afterInsertOperation() {
        populateTaxExemptions(COHeaderNewList, false);
    }
    
     /**
     * Name: beforeUpdateOperation
     * Desc: Before Update Method
     * @param: 
     * @return: 
    **/
    public static void beforeUpdateOperation() {
        setCOClosedDateTime(COHeaderNewList);
        if(entryConditionForBeforeUpdate() || isCalculatePLandTax) {
            setCOBasicFields(COHeaderNewList);
        }
    }
    
    public static void afterDeleteOperation() {
        Set<Id> customersIdSet = new Set<Id>();
        for(CO_Header__c coHeaderRec : COHeaderOldList) {
            if(coHeaderRec.Customer__c != null) {
                customersIdSet.add(coHeaderRec.Customer__c);
            }
        }
        if(customersIdSet.size() > 0) {
            if(!system.isFuture() && !system.isBatch()) {
                updateAccountFields_future(customersIdSet);
            } else {
                updateAccountFields(customersIdSet);
            }
        }
    }

     /**
     * Name: entryConditionForBeforeUpdate
     * Desc: Before Update Condition
     * @param: 
     * @return: Boolean is ValidEntry or not
    **/
    private static Boolean entryConditionForBeforeUpdate() {
        Boolean isValidEntry = false;
        for(CO_Header__c coHeaderRec : COHeaderNewList) {
            if((COHeaderNewMap.get(coHeaderRec.Id).Customer__c != COHeaderOldMap.get(coHeaderRec.Id).Customer__c)) {
                isValidEntry = true;
            }
        }
        return isValidEntry;
    }
    
    // Search Tag Format - Customer Name, 
    private static void populateSearchTag() {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<CO_Header__c> coHeaderList = [select Customer__r.Name, Search_Tag__c, 
                                                (select Search_Tag__c from CO_Invoice_Headers__r),
                                                (select Search_Tag__c from Service_Order_Headers__r)
                                            from CO_Header__c 
                                            where Id IN: COHeaderNewList];
        Set<Id> accountIdSet = new Set<Id>();
        for(CO_Header__c coHeaderRec : COHeaderNewList) {
            if(coHeaderRec.Customer__c != null ) {
                accountIdSet.add(coHeaderRec.Customer__c);
            }
        }
        Map<Id, Account> customerMap = new Map<Id, Account>([select Id, Name from Account where Id IN: accountIdSet]);
                                                
        List<CO_Invoice_Header__c> coInvoiceHeaderList = new List<CO_Invoice_Header__c>();
        List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
        for(CO_Header__c coHeaderRec : coHeaderList) {
            String newCustomerName = '';
            if(customerMap.get(COHeaderNewMap.get(coHeaderRec.Id).Customer__c) != null) {
                newCustomerName = customerMap.get(COHeaderNewMap.get(coHeaderRec.Id).Customer__c).Name;
            }
            coHeaderRec.Search_Tag__c = (newCustomerName != '') ? newCustomerName + ',' : '';
            for(CO_Invoice_Header__c coInvoiceHeaderRec : coHeaderRec.CO_Invoice_Headers__r) {
                coInvoiceHeaderRec.Search_Tag__c = coHeaderRec.Search_Tag__c;
                coInvoiceHeaderList.add(coInvoiceHeaderRec);
            }
            for(Service_Order_Header__c soHeaderRec : coHeaderRec.Service_Order_Headers__r) {
                soHeaderRec.Search_Tag__c = coHeaderRec.Search_Tag__c;
                soHeaderList.add(soHeaderRec);
            }
        }
        if(isCOInvoiceHeaderUpdated) {
            return;
        }
        if(coInvoiceHeaderList.size() > 0) {
            isCOInvoiceHeaderUpdated = true;
            COInvoiceTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvoiceHeaderList);
            COInvoiceTriggerHelper.isForceStopTrigger = false;
        }
        if(soHeaderList.size() > 0) {
            SOTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderList);
            SOTriggerHelper.isForceStopTrigger = false;
        }
        if(coHeaderList.size() > 0) {
			isForceStopTrigger = true;
            DMLUtility.updateSobjectList('CO_Header__c', coHeaderList);
            isForceStopTrigger = false;
        }
    }
    
     /**
     * Name: setPriceLevelForRelatedCOLIs
     * Desc: Setting Price Level for Related Line Items
     * @param: 
     * @return: 
    **/
    public static void setPriceLevelForRelatedCOLIs() {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Header__c> coHeaderList = [select Customer__c, Discount_Markup_From_Prive_Level__c, Part_Price_Base_From_Price_Level__c,
                            (select Part__c, Fee__c, CO_Kit_Header__c, Kit_Header_Line_Item__c, Id, Deal__c, Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c, 
                            Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c, Service_Order_Line_Item__r.Service_Order_Kit_Header__c, 
                            Service_Order_Line_Item__r.Service_Order_Header__r.Provider__r.Price_Level__r.Discount_Markup__c, Bulk_Discount_Percent__c,
                            Is_Environmental_Fee__c, Is_Linked_Fee__c, Type__c, Price_When_Tax_Included__c, Price__c, Tax__c, Calculated_Customer_Price__c,
                            Service_Order_Line_Item__r.Service_Order_Header__r.Provider__r.Price_Level__r.Part_Price_Base__c from CO_Line_Items__r where 
                            Invoice_Number__c = null AND CO_Kit_Header__c = null AND Service_Order_Line_Item__r.Service_Order_Kit_Header__c = null AND Deal__r.Invoice_Number__c = null) 
                            from CO_Header__c where Id IN : COHeaderNewList];
                                               // AND (Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c != 'Internal' OR Service_Order_Line_Item__r.Service_Order_Header__r.CO_Header__r.CO_Type__c = 'Internal Service')
        setPLForCOLIs(coHeaderList);
    }
    
    public static void setPLforCOLIs(List<CO_Header__c> coHeaderList) {
        Set<Id> partIdSet = new Set<Id>();
        Set<Id> feeIdSet = new Set<Id>();
        
        List<CO_Line_Item__c> merchLIList = new List<CO_Line_Item__c>();
        List<CO_Line_Item__c> dealMerchLIList = new List<CO_Line_Item__c>();
        
        Map<String, List<CO_Line_Item__c>> providerIdToCOLIListMap = new Map<String, List<CO_Line_Item__c>>();
        Map<String, Price_Level__c> providerIdToPriceLevelRecMap = new Map<String, Price_Level__c>();
        
        for(CO_Header__c COHeaderRec : coHeaderList) {
            for(CO_Line_Item__c coLineItemRec : COHeaderRec.CO_Line_Items__r) {
                if(coLineItemRec.CO_Kit_Header__c != null || coLineItemRec.Service_Order_Line_Item__r.Service_Order_Kit_Header__c != null) {
                    continue;
                }
                if(String.isNotBlank(coLineItemRec.Deal__c) || coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c == 'Internal') {
                    dealMerchLIList.add(coLineItemRec);
                } else if(coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c != null) {
                    if(!providerIdToCOLIListMap.containsKey(coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c)){
                        providerIdToCOLIListMap.put(coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c, new List<CO_Line_Item__c>());
                        
                        Price_Level__c plRec = new Price_Level__c(Id = coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__r.Price_Level__c);
                        plRec.Part_Price_Base__c = coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__r.Price_Level__r.Part_Price_Base__c;
                        plRec.Discount_Markup__c = coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__r.Price_Level__r.Discount_Markup__c;
                        providerIdToPriceLevelRecMap.put(coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c, plRec);
                    }
                    providerIdToCOLIListMap.get(coLineItemRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c).add(coLineItemRec);
                } else {
                    merchLIList.add(coLineItemRec); 
                }
                partIdSet.add(coLineItemRec.Part__c);
                feeIdSet.add(coLineItemRec.Fee__c);
            }
        }
        partIdSet.remove(null);
        feeIdSet.remove(null);
                
        Map<Id, Part__c> partIdToPartRecordMap = new Map<Id, Part__c>();
        Map<Id, Fee__c> feeIdToFeeRecordMap = new Map<Id, Fee__c>();
        
        if(partIdSet.size() > 0) {      
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        partIdToPartRecordMap = new Map<Id, Part__c>([SELECT Id, Applicable_Tax__c, Average_Cost__c, Last_Cost__c, Sale_Price__c, 
	                                                      Applicable_Tax__r.Rate__c, MSRP__c, Retail_Price__c from Part__c where Id IN : partIdSet]);
        }
        if(feeIdSet.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            feeIdToFeeRecordMap = new Map<Id, Fee__c>([select Code__c, Description__c, Price__c, Taxable__c, Applicable_Tax__c, Applicable_Tax__r.Rate__c
                                                                        from Fee__c where Id IN: feeIdSet]); 
        }
        
        List<CO_Line_Item__c> coLineItemListToUpdate = new List<CO_Line_Item__c>();
        
        for(CO_Header__c coHeaderRec : coHeaderList) {
            coLineItemListToUpdate.addAll(TaxCalculation.partPriceCalculation(coHeaderRec.Part_Price_Base_From_Price_Level__c, coHeaderRec.Discount_Markup_From_Prive_Level__c, 
                                                        merchLIList, partIdToPartRecordMap, feeIdToFeeRecordMap));
            if(dealMerchLIList.size() > 0) {
                List<Price_Level__c> defaultPriceLevel = SOTriggerHelper.getInternalDefaultPriceLevel();
                if(defaultPriceLevel == null || defaultPriceLevel.size() == 0) {
                    defaultPriceLevel = SOTriggerHelper.getDefaultPriceLevel();
                }
                coLineItemListToUpdate.addAll(TaxCalculation.partPriceCalculation(defaultPriceLevel[0].Part_Price_Base__c, defaultPriceLevel[0].Discount_Markup__c, 
                                                        dealMerchLIList, partIdToPartRecordMap, feeIdToFeeRecordMap));
            }
            
            if(providerIdToCOLIListMap.size() > 0) {
                for(String providerId : providerIdToCOLIListMap.keySet()) { 
                    coLineItemListToUpdate.addAll(TaxCalculation.partPriceCalculation(providerIdToPriceLevelRecMap.get(providerId).Part_Price_Base__c, providerIdToPriceLevelRecMap.get(providerId).Discount_Markup__c, 
                                                        providerIdToCOLIListMap.get(providerId), partIdToPartRecordMap, feeIdToFeeRecordMap));
                }
            }
        }           
        system.debug('setPriceLevelForRelatedCOLIs \n\n\n coLineItemListToUpdate\n --> ' + coLineItemListToUpdate);        
        if(!coLineItemListToUpdate.isEmpty()) {
            for(CO_Line_Item__c coliRec : coLineItemListToUpdate) {
                if(coliRec.Part__c != null) {
                    coliRec.Calculated_Customer_Price__c = null;
                    if(!GeneralConfiguration.getTaxIncludingPricing()) {
                        coliRec.Calculated_Customer_Price__c = coliRec.Price__c;
                        coliRec.Price__c = (coliRec.Calculated_Customer_Price__c * (1 - (coliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c && isRecalculateCOPLAndTax && (isRecalculateTaxes == null || !isRecalculateTaxes)) {
                    Decimal tax = coliRec.Tax__c != null ? coliRec.Tax__c : 0;
                    Decimal price = coliRec.Price__c != null ? coliRec.Price__c : 0;
                    coliRec.Price_When_Tax_Included__c = (price * (1 + tax / 100)).setScale(2, RoundingMode.HALF_UP);
                }
            }

            if(AccessControl.ifObjectFieldIsUpdateable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            COLineItemTriggerHelper.isCalculateSalesTax = false;
            COLineItemTriggerHelper.isCalculatePriceLevel = false;
            update coLineItemListToUpdate;

            if(isRecalculateCOPLAndTax && (isRecalculateTaxes == null || !isRecalculateTaxes)) {
                updatePriceOnRelatedSOLIs(coLineItemListToUpdate);
            }
        }
    }
    
    /** 
     * Name: afterUpdateCalculation
     * Desc: Method to Calculate Part Price tax when co header record is updated
     * @param: 
     * @return: 
    **/
    public static void afterUpdateCalculation() {
        if(isTriggerExecute || !(entryConditionForBeforeUpdate() || isCalculatePLandTax)) {
            return;
        }
        if(!isRecalculateCOPLAndTax || (isRecalculateTaxes != null && isRecalculateTaxes)) {
            refreshTaxExemptions();
        }
        isTriggerExecute = true;
        isCalculatePLandTax = false;
        if(!isRecalculateCOPLAndTax || (isResetPricing != null && isResetPricing)) {
            setPriceLevelForRelatedCOLIs();
        }
        if(!isRecalculateCOPLAndTax || (isRecalculateTaxes != null && isRecalculateTaxes)) {
            salesTaxCalculation(null, null, null);
        }
        // For SOLIs
        setPriceLevelAndSalesTaxForLabourInServiceOrder(null);
        if(!isCalculatePLandTax) {
            populateSearchTag();
        }
        // Update option and fees when click on refreshing customer information or changing customer
        updateDeal();
    }
    
    private static void updateDeal() {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('F_I_Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Deal_Item__c> dealItemList = [Select Id, Deal__c, Type__c, (Select Id from Options_Fees__r), (Select Id from Deal_Unit_Prices_Costs__r) from Deal_Item__c where Deal__r.CO_Header__c IN: COHeaderNewList And Deal__r.Invoice_Number__c = null];
        List<F_I_Product__c> fiProductList = [SELECT Id FROM F_I_Product__c WHERE Deal__r.CO_Header__c IN: COHeaderNewList And Deal__r.Invoice_Number__c = null];
        Set<String> dealIdSet = new Set<String>();
        if(dealItemList.size() > 0) {
            List<Option_Fee__c> optionAndFeeListToUpdate = new List<Option_Fee__c>();
            List<Deal_Unit_Price_Cost__c> dealUPCListToUpdate = new List<Deal_Unit_Price_Cost__c>();
            List<Deal_Item__c> tradeInTypeDealItemListToUpdate = new List<Deal_Item__c>();
            for(Deal_Item__c dealItemRec : dealItemList) {
                optionAndFeeListToUpdate.addAll(dealItemRec.Options_Fees__r);
            	dealUPCListToUpdate.addAll(dealItemRec.Deal_Unit_Prices_Costs__r);
                dealIdSet.add(dealItemRec.Deal__c);
                if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                	tradeInTypeDealItemListToUpdate.add(dealItemRec);
                }
            }
            OptionAndFeeTriggerHelper.isCustomerPLUpdate = true;
            DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate = true;
            if(!AccessControl.ifObjectFieldIsUpdateable('Option_Fee__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('Deal_Unit_Price_Cost__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update optionAndFeeListToUpdate;
            update dealUPCListToUpdate;
            if(tradeInTypeDealItemListToUpdate.size() > 0) {
            	DealItemTriggerHelper.isTriggerExecute = true;
            	DealItemTriggerHelper.isCustomerPLUpdate = true;
            	if(!AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            	update tradeInTypeDealItemListToUpdate;
            }
            
            if(fiProductList.size() > 0) {
	        	FIProductTriggerHelper.isCustomerPLUpdate = true;
	        	if(!AccessControl.ifObjectFieldIsUpdateable('F_I_Product__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
	            update fiProductList;
	        }
	        
	        if(COTriggerHelper.isRecalculateCOPLAndTax) {
	            OptionAndFeeTriggerHelper.updateDealTotal(dealIdSet);
	    	}
        }
    }
    
    public static void salesTaxCalculation(String soId, String coId, List<CO_Line_Item__c> coliList) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Part_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable('Individual_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                
        String query = 'SELECT Part__c, Part__r.Taxable__c, Part__r.Applicable_Tax__c, Part__r.Applicable_Tax__r.Rate__c, Price__c, '+
        'Fee__c, Fee__r.Taxable__c, Fee__r.Applicable_Tax__c, Fee__r.Applicable_Tax__r.Rate__c, Deal__c, Applicable_Tax__c, '+
        'CO_Header__r.Is_Override_Merch_Tax__c, CO_Header__r.Override_Merch_Tax_Applicable_On__c, CO_Header__r.Merch_Applicable_Tax__c, ' +
        'CO_Header__r.Is_Tax_Based_On_Customer_Address__c, Service_Order_Line_Item__r.Service_Order_Header__r.Is_Override_Tax__c, ' +
        'Service_Order_Line_Item__r.Service_Order_Header__r.Override_Tax_Applicable_On__c, ' +
        'Service_Order_Line_Item__r.Service_Order_Header__r.Applicable_Tax__c, Service_Order_Line_Item__r.Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c, ' +
        'Service_Order_Line_Item__r.Part__r.Taxable__c, Service_Order_Line_Item__r.Part__r.Applicable_Tax__c, ' +
        'Service_Order_Line_Item__r.Fee__r.Taxable__c, Service_Order_Line_Item__r.Fee__r.Applicable_Tax__c, ' +
        'Service_Order_Line_Item__r.Service_Order_Header__r.Deal__c, Tax__c, Calculated_Customer_Price__c, Bulk_Discount_Percent__c, ' +
        'Service_Order_Line_Item__r.Labour_Code__r.Taxable__c, Service_Order_Line_Item__r.Sublet__r.Taxable__c, ' + 
        'Service_Order_Line_Item__r.Part__r.Applicable_Tax__r.Rate__c, Service_Order_Line_Item__r.Fee__r.Applicable_Tax__r.Rate__c, ' +
        'Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c, Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c, '+
        'Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c, Type__c, Price_When_Tax_Included__c, ' +
        'CO_Header__c, CO_Header__r.CO_Type__c, CO_Header__r.Customer__c, Service_Order_Line_Item__c, Qty__c from CO_Line_Item__c where '+
        'Invoice_Number__c = null AND CO_Kit_Header__c = null AND Service_Order_Line_Item__r.Service_Order_Kit_Header__c = null AND Deal__r.Invoice_Number__c = null ';
        if(String.isNotBlank(soId)) {
            query += ' AND Service_Order_Line_Item__r.Service_Order_Header__c =: soId AND CO_Header__c =: coId';
        } else if(coliList != null) {
            query += ' AND ID IN: coliList';
        } else {
            query += ' AND CO_Header__c IN: COHeaderNewList';
        }
        calculateSalesTax(Database.query(query));
    }

    public static void calculateSalesTax(List<CO_Line_Item__c> coliList) {       
        if(coliList.isEmpty()) {return;}
        List<CO_Line_Item__c> coLineItemToUpdate = new List<CO_Line_Item__c>();
        coLineItemToUpdate.addAll(TaxEngine.salesTaxCalculationFromCOTrigger(coliList));
        
        if(!coLineItemToUpdate.isEmpty()) {
            COLineItemTriggerHelper.isTotalCalculated = false;
            COLineItemTriggerHelper.isCalculateSalesTax = false;
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                for(CO_Line_Item__c coliRec : coLineItemToUpdate) {
                    if(coliRec.Calculated_Customer_Price__c == null) {
                        coliRec.Calculated_Customer_Price__c = coliRec.Price_When_Tax_Included__c;
                        coliRec.Price_When_Tax_Included__c = (coliRec.Price_When_Tax_Included__c * (1 - (coliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                        coliRec.Price__c = (coliRec.Price__c * (1 - (coliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
            DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemToUpdate);
            
            updatePriceOnRelatedSOLIs(coLineItemToUpdate);
        } else if(!GeneralConfiguration.getTaxIncludingPricing() && COTriggerHelper.isRetainItemPrices) {
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                for(CO_Line_Item__c coliRec : coliList) {
                    if(coliRec.Calculated_Customer_Price__c == null) {
                        coliRec.Calculated_Customer_Price__c = coliRec.Price_When_Tax_Included__c;
                        coliRec.Price_When_Tax_Included__c = (coliRec.Price_When_Tax_Included__c * (1 - (coliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                        coliRec.Price__c = (coliRec.Price__c * (1 - (coliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
            updatePriceOnRelatedSOLIs(coliList);
        }
    }

    private static void updatePriceOnRelatedSOLIs(List<CO_Line_Item__c> coLineItemToUpdate) {
        List<Service_Order_Line_Item__c> relatedSOLIs = [select Kit_Price__c, Actual_Kit_Price__c, Tax_Percent__c, CO_Line_Item__r.Price__c, 
        Price_When_Tax_Included__c, Service_Order_Kit_Header__c, CO_Line_Item__r.Applicable_Tax__c, CO_Line_Item__r.Tax__c, CO_Line_Item__r.Calculated_Customer_Price__c,
        CO_Line_Item__r.Price_When_Tax_Included__c, CO_Line_Item__r.Actual_Retail_Price__c from Service_Order_Line_Item__c
        where CO_Line_Item__c IN: coLineItemToUpdate];
             
        for(Service_Order_Line_Item__c soliRec : relatedSOLIs) {
            soliRec.Applicable_Tax__c = soliRec.CO_Line_Item__r.Applicable_Tax__c;
            soliRec.Actual_Kit_Price__c = soliRec.Kit_Price__c = soliRec.CO_Line_Item__r.Price__c;
            soliRec.Actual_Retail_Price__c = soliRec.CO_Line_Item__r.Actual_Retail_Price__c;
            soliRec.Calculated_Customer_Price__c = soliRec.CO_Line_Item__r.Calculated_Customer_Price__c;
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                soliRec.Price_When_Tax_Included__c = soliRec.CO_Line_Item__r.Price_When_Tax_Included__c;
            }
            soliRec.Tax_Percent__c = soliRec.CO_Line_Item__r.Tax__c;
        }
        if(relatedSOLIs.size() > 0) {
            ServiceOrderLineItemTriggerHelper.isTriggerExecuted = true;
            ServiceOrderLineItemTriggerHelper.isCalculateSalesTax = false;
            update relatedSOLIs;
        }
    }
        
    public static void setPriceLevelAndSalesTaxForLabourInServiceOrder(String soHeaderId) {
        List<Service_Order_Line_Item__c> soliList;
        if(String.isNotBlank(soHeaderId)) {
            soliList = [select Service_Order_Header__c, Fee__c, Labour_Code__c, Sublet__c, Kit_Price__c, Actual_Kit_Price__c, Service_Order_Header__r.Job_Type__c, Price_When_Tax_Included__c,
                                                                Tax_Percent__c, CO_Line_Item__r.Price__c, CO_Line_Item__r.Tax__c, Service_Order_Kit_Header__c, Deal__c, 
                                                Deal_Item__c, Calculated_Customer_Price__c, Bulk_Discount_Percent__c, (Select Id from Individual_Taxes__r)  from Service_Order_Line_Item__c
                                                where (Labour_Code__c != null OR Sublet__c != null) AND (Service_Order_Kit_Header__c = null) AND 
                                                Service_Order_Header__c =: soHeaderId AND Service_Order_Header__r.Invoice_Number__c = null AND Deal__r.Invoice_Number__c = null];
        } else {
            soliList = [select Service_Order_Header__c, Fee__c, Labour_Code__c, Sublet__c, Kit_Price__c, Actual_Kit_Price__c, Service_Order_Header__r.Job_Type__c, 
                                                Tax_Percent__c, CO_Line_Item__r.Price__c, CO_Line_Item__r.Tax__c, Service_Order_Kit_Header__c, Deal__c, Price_When_Tax_Included__c,
                                                Deal_Item__c, Calculated_Customer_Price__c, Bulk_Discount_Percent__c, (Select Id from Individual_Taxes__r)  from Service_Order_Line_Item__c
                                                where (Labour_Code__c != null OR Sublet__c != null) AND (Service_Order_Kit_Header__c = null) AND 
                                                Service_Order_Header__r.CO_Header__c IN: COHeaderNewList AND Service_Order_Header__r.Invoice_Number__c = null AND Deal__r.Invoice_Number__c = null];
        }
        if(!soliList.isEmpty()) {
            ServiceOrderLineItemTriggerHelper.isTriggerExecuted = true;
            ServiceOrderLineItemTriggerHelper.isCalculateSalesTax = false;
                
            if(!isRecalculateCOPLAndTax || (isResetPricing != null && isResetPricing)) {
                soliList = ServiceOrderLineItemTriggerHelper.applyPriceLevel(soliList);
                for(Service_Order_Line_Item__c soli : soliList) {
                    soli.Calculated_Customer_Price__c = null;
                    if(!GeneralConfiguration.getTaxIncludingPricing()) {
                        soli.Calculated_Customer_Price__c = soli.Kit_Price__c;
                        soli.Kit_Price__c = (soli.Calculated_Customer_Price__c * (1 - (soli.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                    }
                if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c && isRecalculateCOPLAndTax && (isRecalculateTaxes == null || !isRecalculateTaxes)) {
                        Decimal tax = soli.Tax_Percent__c != null ? soli.Tax_Percent__c : 0;
                        Decimal price = soli.Kit_Price__c != null ? soli.Kit_Price__c : 0;
                        soli.Price_When_Tax_Included__c = (price * (1 + tax / 100)).setScale(2, RoundingMode.HALF_UP);
                    }
                }
                update soliList;
            }
            if(!isRecalculateCOPLAndTax || (isRecalculateTaxes != null && isRecalculateTaxes)) {
                List<Service_Order_Line_Item__c> nonKitSOLIList = new List<Service_Order_Line_Item__c>();
                //START: Added to delete labor individual taxes when 
                List<Individual_Tax__c> individualTaxList = new List<Individual_Tax__c>();
                for(Service_Order_Line_Item__c soliRec : soliList) {
                    if(String.isBlank(soliRec.Service_Order_Kit_Header__c)) {
                        individualTaxList.addAll(soliRec.Individual_Taxes__r);
                        nonKitSOLIList.add(soliRec);
                    }
                }
                DMLUtility.deleteSobjectList('Individual_Tax__c', individualTaxList);
                ServiceOrderLineItemTriggerHelper.applySalesTax(nonKitSOLIList);
            }

            if(GeneralConfiguration.getTaxIncludingPricing()) {
                List<Service_Order_Line_Item__c> updateSOLIList = new List<Service_Order_Line_Item__c>();
                for(Service_Order_Line_Item__c soli : soliList) {
                    if(String.isBlank(soli.Service_Order_Kit_Header__c) && soli.Calculated_Customer_Price__c == null) {
                        Service_Order_Line_Item__c newSolirec = new Service_Order_Line_Item__c(Id = soli.Id);
                        newSolirec.Calculated_Customer_Price__c = soli.Price_When_Tax_Included__c;
                        newSolirec.Kit_Price__c = (soli.Kit_Price__c * (1 - (soli.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                        newSolirec.Price_When_Tax_Included__c = (soli.Price_When_Tax_Included__c * (1 - (soli.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                        updateSOLIList.add(newSolirec);
                    }
                }
                DMLUtility.updateSobjectList('Service_Order_Line_Item__c', updateSOLIList);
            }
        }
    }
    
    
    /**
     * Name: getDefaultPriceLevel
     * Desc: Method to get Default Price Level In system
     * @param: 
     * @return:  List<Price_Level__c> - List of default price level. Ideally size of list - 1 
    **/
    private static List<Price_Level__c> getDefaultPriceLevel() {
        return getDefaultPriceLevel(null);
    }
    
    private static List<Price_Level__c> getDefaultPriceLevel(Id priceLevelId) {
        String query = 'SELECT Part_Price_Base__c, Discount_Markup__c, Labour_Rate__c FROM Price_Level__c ';
        if(String.isBlank(priceLevelId)) {
            query += 'WHERE Default__c = true';
        } else {
            query += 'WHERE Id =: priceLevelId';
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        defaultPriceLevel = Database.query(query);
        return defaultPriceLevel;
    }
    
    /**
     * Name: getDefaultSalesTax
     * Desc: Method to populate Default Sales Tax In system
     * @param: 
     * @return:   
    **/
    private static void getDefaultSalesTax() {
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        defaultSalesTax = [select Rate__c from Sales_Tax__c where default__c = true];
    }
    
    
    /**
     * Name: updateAccountFieldsOnAfterUpdate
     * Desc: Method to update account fields when CO header is updated.
     * @param: 
     * @return: 
    **/
    public static void updateAccountFieldsOnAfterUpdate() {
    	Boolean isValidEntry = false;
        Set<Id> customersIdList = new Set<Id>();
        for(CO_Header__c coHeaderRec : COHeaderNewList)  {
            if(COHeaderNewMap.get(coHeaderRec.Id).Customer__c != COHeaderOldMap.get(coHeaderRec.Id).Customer__c || COHeaderNewMap.get(coHeaderRec.Id).Order_status__c != COHeaderOldMap.get(coHeaderRec.Id).Order_status__c) {
                if(COHeaderOldMap.get(coHeaderRec.Id).Customer__c != null) {
                    customersIdList.add(COHeaderOldMap.get(coHeaderRec.Id).Customer__c);
                }
                isValidEntry = true;
                break;
            }   
        }
        if(!isValidEntry && !isCalculatePLandTax) {
            return;
        }
        
        for(CO_Header__c coHeaderRec : COHeaderNewList) {
            if(coHeaderRec.Customer__c != null) {
                customersIdList.add(coHeaderRec.Customer__c);
            }
        }
        if(customersIdList.size() > 0) {
            if(!system.isFuture() && !system.isBatch()) {
                updateAccountFields_future(customersIdList);
            } else {
                updateAccountFields(customersIdList);
            }
        }
    }
    
    @future
    private static void updateAccountFields_future(Set<Id> customersIdList) {
    	updateAccountFields(customersIdList);
    }
    
    /**
     * Name: updateAccountFields
     * Desc: Method to update account fields when CO header is updated.
     * @param: 
     * @return: 
    **/
    private static void updateAccountFields(Set<Id> customersIdList) {
        List<User> currentUserList = SOQLUtil.getCurrentUserInfo();
       
        if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Account> customerList = [select Name, Orders_Lifetime__c, Open_Orders__c, Average_Spend_per_Order__c, (select Id, Order_status__c, Order_Total__c,
                                        Total_Order_Value__c, Total_Order_Tax__c from CO_Headers__r) from Account Where Id IN : customersIdList];
        for(Account customerRec : customerList) {
            customerRec.Orders_Lifetime__c =  customerRec.CO_Headers__r.size();
            Integer openOrdersCount = 0;
            Decimal totalSpendOrder = 0;
            Integer totalClosedOrders = 0;
            for(CO_Header__c coHeaderRec : customerRec.CO_Headers__r) {
                if(coHeaderRec.Order_status__c == 'Open') {
                    openOrdersCount++;
                } else if(coHeaderRec.Order_status__c == 'Closed') {
                    totalSpendOrder += coHeaderRec.Order_Total__c;
                    totalClosedOrders += 1;
                }
            }
            customerRec.Average_Spend_per_Order__c = totalClosedOrders > 0 ? totalSpendOrder / totalClosedOrders : totalSpendOrder;
            customerRec.Open_Orders__c = openOrdersCount;
        }
        if(customerList.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            CustomerTriggerHelper.isTriggerRun = true;
            update customerList;
            CustomerTriggerHelper.isTriggerRun = false;
        }
    }
    
    /**
     * Name: refreshTaxExemptions
     * Desc: Refresh TaxExemptions
     * @param: 
     * @return: 
    **/
    private static void refreshTaxExemptions() {
        deleteTaxExemptions();
        populateTaxExemptions(COHeaderNewList, false);
    }
    
    /**
     * Name: deleteTaxExemptions
     * Desc: Delete TaxExemptions
     * @param: 
     * @return: 
    **/
    private static void deleteTaxExemptions() {
        if(AccessControl.ifObjectFieldIsUpdateable('Tax_Exemption__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        
        List<Tax_Exemption__c> taxExemptionsList = [select Id from Tax_Exemption__c where CO_Header__c IN: COHeaderNewList AND Type__c =: TaxUtility.EXEMPTION];
        if(taxExemptionsList.size() > 0) {
            DMLUtility.deleteSobjectList('Tax_Exemption__c', taxExemptionsList);
        }
    }
    
    private static void setCOClosedDateTime(List<CO_Header__c> coList) {
        for(CO_Header__c coRec : coList) {
            if(String.isNotBlank(coRec.Order_status__c) && coRec.Order_status__c.equalsIgnoreCase('Closed') && coRec.Closed_Date_Time__c == null) {
                coRec.Closed_Date_Time__c = system.now();
            } else if((String.isBlank(coRec.Order_status__c) || !coRec.Order_status__c.equalsIgnoreCase('Closed')) && coRec.Closed_Date_Time__c != null) {
                coRec.Closed_Date_Time__c = null;
            }
        }
    }

    private static Set<Id> getAccountTypeIdSet(List<CO_Header__c> coList) {
        Set<Id> accountTypeIdSet = new Set<Id>();
        for(CO_Header__c coHeaderRec : coList) {
            if(coHeaderRec.Account_Type__c != null) {
                accountTypeIdSet.add(coHeaderRec.Account_Type__c);
            }
        }
        return accountTypeIdSet;
    }
    
    /**
     * Name: populateTaxExemptions
     * Desc: Populate TaxExemptions from Customer Object's AccountType lookup
     * @param: COHeaderNewList, isUpdate
     * @return: 
    **/
    public static void populateTaxExemptions(List<CO_Header__c> coList, Boolean isUpdate) {
        Set<Id> accountTypeIdSet = getAccountTypeIdSet(coList);
        if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Account_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Tax_Exemption__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        if(accountTypeIdSet.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Tax_Exemption__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Tax_Exemption__c> taxExemptionsList = [SELECT Id, Account_Type__c, Sales_Tax_Item__r.Rate__c, Rate_Override__c FROM Tax_Exemption__c WHERE Account_Type__c IN :accountTypeIdSet];

            // Step 3 - Create new Tax_Exemption records and set CO_Header__c on them
            List<Tax_Exemption__c> coHeaderTaxExemptionsList = new List<Tax_Exemption__c>();
            for(CO_Header__c coHeaderRec : coList) {
                if(String.isNotBlank(coHeaderRec.Order_Status__c) && coHeaderRec.Order_Status__c != 'Closed' && coHeaderRec.Account_Type__c != null) {
                    List<Tax_Exemption__c> taxExemptions = new List<Tax_Exemption__c>();
                    for(Tax_Exemption__c taxExemption : taxExemptionsList) {
                        if(coHeaderRec.Account_Type__c == taxExemption.Account_Type__c) {
                            Tax_Exemption__c newTaxExemption = taxExemption.clone(false, false, false, false);
                            newTaxExemption.CO_Header__c = coHeaderRec.Id;
                            newTaxExemption.Account_Type__c = null;
                            newTaxExemption.Type__c = TaxUtility.EXEMPTION;
                            coHeaderTaxExemptionsList.add(newTaxExemption);
                        }
                    }
                }
            }
            
            if(isUpdate) {
                if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                isForceStopTrigger = true;
                update COHeaderNewList;
                isForceStopTrigger = false;
            }
            
            // Step 4 - Save Tax_Exemption__c records
            if(!coHeaderTaxExemptionsList.isEmpty()) {
                DMLUtility.insertSobjectList('Tax_Exemption__c', coHeaderTaxExemptionsList);
            }
        }
    }
}