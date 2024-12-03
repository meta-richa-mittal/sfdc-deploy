/** 
* Author: Gourav Goyal
* Since: Feb 20, 2018
* Name: DealService 
* Description: Apex class which contains deal related methods.
**/
public without sharing class DealService {

    private static final String BLACKPURL_PROFILE_NAME = 'Blackpurl';
    private static final List<String> PROFILE_NAME_LIST = new List<String>{BLACKPURL_PROFILE_NAME};
    public static final String CUSTOMER_ADDR_AUTO_TAX_CALC_ERROR = 'You don\'t collect/remit sales taxes for the state indicated on the customers address';
    
    /**
    * Name: getSalesTaxForDeal 
    * Desc: Method to get deal sales tax
    * @param:   (1)dealId - String - deal id
    * @return: Decimal - Sales Tax Total 
    **/
    public static String getSalesTaxForDeal(String dealId) {
        List<Individual_Tax__c> individualItemList = DealUtil.getDealRelatedIndividualTaxes(dealId);
        Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemList);
        Decimal salesTax = 0;    
        for(String taxName : salesTaxNameToTaxValue.keySet()){
            salesTax += salesTaxNameToTaxValue.get(taxName);
        } 
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeNumberField('SalesTax', salesTax); 
        gen.writeEndObject();
        String jsonString = gen.getAsString();
        return jsonString;
    }
      
    /**
    * Name: updateFinanceStatus 
    * Desc: Method to set deal finance status and update related checkout item
    * @param:   (1)coHeaderId - String - co header id
    * @param:   (1)dealId - String - deal id
    * @param:   (1)dealFinanceObj - DealWrapper.DealFinanceWrapper - deal finance wrapper obj
    * @param:   (1)financeStatus - String - Deal finance status
    * @return: void
    **/
    public static void updateFinanceStatus(String coHeaderId, String dealId, DealWrapper.DealFinanceWrapper dealFinanceObj, String financeStatus) {
        List<SObject> sObjectListToUpdate = new List<SObject>();
        Deal_Finance__c dealFinanceRec = setDealFinanceField(dealFinanceObj);
        dealFinanceRec.Status__c = financeStatus;
        if(financeStatus.equalsIgnoreCase('Approved')) {
            dealFinanceRec.Approved_Amount_Financed__c = dealFinanceObj.ApprovedAmountFinanced;
        }
        sObjectListToUpdate.add(dealFinanceRec);
        if(!GeneralConfiguration.isLoadNewCustomerOrder()) {
            if(financeStatus == 'Submitted') {
                List<CO_Invoice_Item__c> coInvoiceItemListToInsert = new List<CO_Invoice_Item__c>();
                if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<CO_Invoice_Header__c> coInvoiceHeaderList = [Select Id from CO_Invoice_Header__c where CO_Header__c = :coHeaderId AND Invoice_Status__c = 'Active'];
                if(coInvoiceHeaderList.size() == 0) {
                    coInvoiceHeaderList.add(new CO_Invoice_Header__c(CO_Header__c = coHeaderId, Invoice_Status__c = 'Active'));
                    if(AccessControl.ifObjectFieldIsCreateable('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                    insert coInvoiceHeaderList;
                }
                CO_Invoice_Item__c coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeaderList[0].Id, isActive__c = false, Is_Invoiceable__c = false, Deal__c = dealId, Deal_Finance__c = dealFinanceObj.Id);
                coInvoiceItemListToInsert.add(coInvoiceItem);
                if(coInvoiceItemListToInsert.size() > 0){
                    if(AccessControl.ifObjectFieldIsCreateable('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                    insert coInvoiceItemListToInsert;
                }
            } else if(financeStatus == 'Approved') {
                if(AccessControl.ifObjectFieldIsAccessible('Co_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Co_Invoice_Item__c> coInvoiceItemList = [Select Is_Invoiceable__c from Co_Invoice_Item__c where Deal_Finance__c = :dealFinanceObj.Id AND Deal__c = :dealId];
                if(coInvoiceItemList.size() > 0) {
                    coInvoiceItemList[0].Is_Invoiceable__c = true;
                    if(AccessControl.ifObjectFieldIsUpdateable('Co_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                    sObjectListToUpdate.add(coInvoiceItemList[0]);
                }
            }
        }
        
        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Finance__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        update sObjectListToUpdate;
        
        if(GeneralConfiguration.isLoadNewCustomerOrder() && (financeStatus == 'Approved' || financeStatus == 'Funded')) {
            Map<String, Boolean> optionNameToOptionValueMap = isDealInvoiceable(dealId);
            if(optionNameToOptionValueMap.get('Invoiceable')) {
                List<Co_Invoice_Item__c> coInvoiceItemList = [Select Is_Invoiceable__c, IsActive__c from Co_Invoice_Item__c where Deal__c = :dealId AND (IsActive__c = false OR Is_Invoiceable__c = false)];
                if(coInvoiceItemList.size() > 0) {
                    coInvoiceItemList[0].Is_Invoiceable__c = optionNameToOptionValueMap.get('Invoiceable');
                    coInvoiceItemList[0].IsActive__c = optionNameToOptionValueMap.get('Active');
                    if(AccessControl.ifObjectFieldIsUpdateable('Co_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                    update coInvoiceItemList[0];
                }
            }
        } else if(GeneralConfiguration.isLoadNewCustomerOrder() && financeStatus == 'Quotation') {
          List<Co_Invoice_Item__c> coInvoiceItemList = [Select Is_Invoiceable__c, IsActive__c from Co_Invoice_Item__c where Deal__c = :dealId AND (IsActive__c = true OR Is_Invoiceable__c = true)];
          if(coInvoiceItemList.size() > 0) {
            coInvoiceItemList[0].Is_Invoiceable__c = false;
            coInvoiceItemList[0].IsActive__c = false;
            if(AccessControl.ifObjectFieldIsUpdateable('Co_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update coInvoiceItemList[0];
          }
        }
    }
    
    public static void updateDealFinanceDetails(String dealId, String dealFinanceJSON) { 
        DealWrapper.DealFinanceWrapper dealFinanceObj = (DealWrapper.DealFinanceWrapper) System.JSON.deserialize(dealFinanceJSON, DealWrapper.DealFinanceWrapper.class);
        
        Deal_Finance__c dealFinanceRec = setDealFinanceField(dealFinanceObj);
        Decimal totalFinCommission = (dealFinanceRec.Buy_Rate_Commission__c != null ? dealFinanceRec.Buy_Rate_Commission__c : 0) + 
                                        (dealFinanceRec.Finance_Commission__c != null ? dealFinanceRec.Finance_Commission__c : 0);
        List<SObject> sObjectListToUpdate = new List<SObject>{new Deal__c(Id = dealId, Down_Payment__c = dealFinanceRec.Down_Payment__c, Total_Finance_Commission__c = totalFinCommission)};
        if(String.isNotBlank(dealFinanceRec.Id)) {
            if(AccessControl.ifObjectFieldIsUpdateable('Deal_Finance__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            sObjectListToUpdate.add(dealFinanceRec);
        } else {
            if(String.isBlank(dealFinanceRec.Status__c)) {
                dealFinanceRec.Status__c = Constants.QUOTATION;
            }
            dealFinanceRec.Deal__c = dealId;
            DMLUtility.insertSobjectList('Deal_Finance__c', dealFinanceRec);
            
            if(GeneralConfiguration.isLoadNewCustomerOrder()) {
                List<CO_Invoice_Item__c> invItemList = [Select Id, isActive__c, Is_Invoiceable__c from CO_Invoice_Item__c where Deal__c =: dealId AND isActive__c = true AND Is_Invoiceable__c = true];
                if(invItemList.size() > 0) {
                    for(CO_Invoice_Item__c invItemRec : invItemList) {
                        invItemRec.isActive__c = false;
                        invItemRec.Is_Invoiceable__c = false;
                    }
                    sObjectListToUpdate.addAll((List<SObject>) invItemList);
                }
            }
        }
        if(AccessControl.ifObjectFieldIsUpdateable('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        update sObjectListToUpdate;
    }
        
    public static void addMultiplePartsInDeal(List<COService.SearchPartDetailWrapper> partToInsertList, String dealItemId) {
        Map<String, Decimal> partIdTQtyToInsertMap = new Map<String, Decimal>();
        for(COService.SearchPartDetailWrapper partInfoObj : partToInsertList) {
            partIdTQtyToInsertMap.put(partInfoObj.PartId, partInfoObj.Qty);
        }
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Map<Id, Part__c> partIdToPartRecMap = new Map<Id, Part__c>([select Part_Number__c, Description__c, Retail_Price__c, Enviro_Fee__c, 
                                                                    Enviro_Fee_Code__c, 
                                                                    Enviro_Fee_Code__r.Code__c, 
                                                                    Enviro_Fee_Code__r.Description__c 
                                                                    from Part__c 
                                                                    where Id =: partIdTQtyToInsertMap.keySet()]);
        if(partIdToPartRecMap.keySet().size() == 0) {
            return;
        }
            
        List<Option_Fee__c> optionsListToInsert = new List<Option_Fee__c>();
        Option_Fee__c relatedEnvFeeRec;
        Option_Fee__c optionAndeFeeRec;
        
        for(COService.SearchPartDetailWrapper partInfoObj : partToInsertList) {
            optionAndeFeeRec = new Option_Fee__c();
            optionAndeFeeRec.Deal__c = partInfoObj.DealId;
            optionAndeFeeRec.Deal_Item__c = dealItemId;  
            optionAndeFeeRec.Qty__c = (partInfoObj.Qty != null && partInfoObj.Qty != 0) ? partInfoObj.Qty : 1;
            optionAndeFeeRec.Price__c = optionAndeFeeRec.Price_When_Tax_Included__c = partIdToPartRecMap.get(partInfoObj.PartId).Retail_Price__c;
            optionAndeFeeRec.Part__c = partInfoObj.PartId;
            optionAndeFeeRec.Item_Code__c = partIdToPartRecMap.get(partInfoObj.PartId).Part_Number__c;
            optionAndeFeeRec.Item_Description__c = partIdToPartRecMap.get(partInfoObj.PartId).Description__c;
            optionAndeFeeRec.Is_Install__c = true;
            optionsListToInsert.add(optionAndeFeeRec);
            // Create one Extra line for Env Fee
            if(partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee__c != null && partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee_Code__c != null) {
                relatedEnvFeeRec = new Option_Fee__c(Deal__c = partInfoObj.DealId, Deal_Item__c = dealItemId, Qty__c = 1, Is_Environmental_Fee__c = true);
                relatedEnvFeeRec.Fee__c = partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee_Code__c;
                relatedEnvFeeRec.Price__c = relatedEnvFeeRec.Price_When_Tax_Included__c = partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee__c;
                relatedEnvFeeRec.Item_Code__c = partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee_Code__r.Code__c;
                relatedEnvFeeRec.Item_Description__c = partIdToPartRecMap.get(partInfoObj.PartId).Part_Number__c + ' ' + partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee_Code__r.Description__c;
                relatedEnvFeeRec.Price__c = partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee__c;
                optionsListToInsert.add(relatedEnvFeeRec);
            }
        }
        DMLUtility.insertSobjectList('Option_Fee__c', optionsListToInsert);
    }
    
    public static void stockInCOU(String tradeInId, String unitId) {
        List<Deal_Item__c> dealItemList = [Select Id, Deal__c, Deal__r.CO_Header__r.Name, Deal__r.CO_Header__r.Customer__c, Stocked_In_Unit__c, Mileage__c, Mileage_Type__c From Deal_Item__c where Id =: tradeInId];
        if(dealItemList.isEmpty()) {
            throw new BlackPurlException('Invalid trade-in.');
        }
        if(dealItemList[0].Stocked_In_Unit__c != null){
            throw new BlackPurlException('Trade in unit is already Stocked In by some other process. Please Refresh the page.');
        }
        List<Customer_Owned_Unit__c> couList = new List<Customer_Owned_Unit__c>();
        String query = 'Select ';
        for(String fieldName : CustomerOwnedUnit.fieldsList()) {
            query += fieldName + ', ';
        }
        query += '(Select Agreed_Value__c, Category__c, Deal__r.CO_Header__r.Name, Default_Unit_Sales_Tax_Percentage__c, Actual_Cash_Value__c from Deals_Units_Junction__r where Id =:tradeInId)';
        query += ' from Customer_Owned_Unit__c where Id =:unitId';
        
        couList = Database.query(query);
        if(couList.size() == 0) {
            return;
        }
        Customer_Owned_Unit__c stockUnitToInsert = couList[0].clone(false, false, false, false);
        couList[0].Status__c = 'Transferred';
        
        stockUnitToInsert.put('Id', null);
        stockUnitToInsert.put('Unit_Type__c', 'STOCK');
        stockUnitToInsert.put('Status__c', 'Available');
        stockUnitToInsert.put('New_Unit__c', false);
        stockUnitToInsert.put('Account__c', null);
        stockUnitToInsert.put('Plate__c', null);
        stockUnitToInsert.put('Reg_Expiry_Date__c', null);
        stockUnitToInsert.put('Taxable__c',true);
        stockUnitToInsert.put('Applicable_Tax__c', Configurations__c.getInstance().Default_Tax_on_Unit__c);
        stockUnitToInsert.put('Stock_Id__c', null);
        stockUnitToInsert.put('Unit_Id__c', null);
        stockUnitToInsert.put('Date_Stocked_In__c', Date.today());
        stockUnitToInsert.put('Mileage_Value__c', dealItemList[0].Mileage__c);
        stockUnitToInsert.put('Mileage_Type__c', dealItemList[0].Mileage_Type__c);
        stockUnitToInsert.put('How_Acquired__c', 'Trade-in');
        stockUnitToInsert.put('Reference_Number__c', dealItemList[0].Deal__r.CO_Header__r.Name);
        stockUnitToInsert.put('Acquired_From__c', dealItemList[0].Deal__r.CO_Header__r.Customer__c);
        if(couList[0].Deals_Units_Junction__r.size() > 0) {
            if(couList[0].Deals_Units_Junction__r[0].Category__c != null) {
                stockUnitToInsert.put('Category__c', couList[0].Deals_Units_Junction__r[0].Category__c);
            }
            stockUnitToInsert.put('Acquisition_Cost__c', couList[0].Deals_Units_Junction__r[0].Actual_Cash_Value__c);
        } 
        if(GeneralConfiguration.getAccrueTradeTaxUntilUnitSold()) {
            populateTradeInAndSalesTaxOnSku(couList[0].Deals_Units_Junction__r[0], stockUnitToInsert);
        }
        
        couList.add(stockUnitToInsert);
        DMLUtility.upsertSobjectList('Customer_Owned_Unit__c', couList);
        if(!System.isFuture()) Unit_Service.copyUnitImages(new Map<Id, Id>{unitId => stockUnitToInsert.Id});
        
        if(couList.size() > 1 && couList[0].Deals_Units_Junction__r.size() > 0) {
            Unit_Price_Cost__c untPriceCostRec = new Unit_Price_Cost__c(Customer_Owned_Unit__c = couList[1].Id);
            untPriceCostRec.Type__c = 'Base';
            untPriceCostRec.Item_Description__c = 'Customer Trade-In';
            untPriceCostRec.Ref_No__c = couList[0].Deals_Units_Junction__r[0].Deal__r.CO_Header__r.Name;
            untPriceCostRec.Total_Price__c = couList[0].Deals_Units_Junction__r[0].Agreed_Value__c;
            untPriceCostRec.Total_Cost__c = couList[0].Deals_Units_Junction__r[0].Actual_Cash_Value__c;
            DMLUtility.insertSobjectList('Unit_Price_Cost__c', untPriceCostRec);
        }
        
        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        update new Deal_Item__c(Id = tradeInId, Is_Stocked_In__c = true, Stocked_In_Unit__c = stockUnitToInsert.Id);
        if(!System.isFuture()) calculateDealOptionClearingAndStockTrade(dealItemList[0].Deal__c);
    }
    
    public static List<ProfitabilityWrapper.SectionProfitabilityWrapper> getDealProfitability(String coId) {
        List<ProfitabilityWrapper.SectionProfitabilityWrapper> profitabilityWrapperList = new List<ProfitabilityWrapper.SectionProfitabilityWrapper>();
        
        List<Deal__c> dealList = [Select Total_Unit_Cost__c, Total_TradeIn_Cost__c, Total_Part_Cost__c, Total_Merch_Cost__c, Ttoal_Labour_Cost__c, Total_Sublet_Cost__c, 
				Invoice_Number__c, Total_Fee_Cost__c, Total_Warranty_Product_Cost__c, Total_Deal_Product_Cost__c, Total_Financing_Product_Cost__c, Total_Third_Party_Product_Cost__c, 
				Total_Commission_Cost__c, Deal_Commission__c, Type__c, F_I_Total__c, Total_Finance_Commission__c, 
                (Select Qty__c, Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c, Fee__r.Is_Include_In_Profit_Calculation__c,  Product__r.Cost__c, Product__r.Cost_Method__c, 
                    Deal_Kit_Header__c, Status__c, Part__c, Part__r.Part_Type__c, Labour_Code__c, Price__c, Per_Item_Cost__c, Product__r.Type__c, Cost__c, 
                    Co_Line_Item__c, Service_Order_Line_Item__c, 
                    Part__r.Average_Cost__c, Part__r.Last_Cost__c, Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c from Options_Fees__r), 
				(Select Type__c, Agreed_Value__c, Actual_Cash_Value__c, Default_Unit_Sales_Tax_Percentage__c, Stamp_Duty_Total__c, 
                Customer_Owned_Unit__c, Customer_Owned_Unit__r.Unit_Type__c, Customer_Owned_Unit__r.Agreed_Payout__c, Customer_Owned_Unit__r.Total_Cost__c from Deal_Items__r),
                (Select Id, Price__c, Total_Cost__c, Cost_Method__c from F_I_Products__r) 
                from Deal__c where CO_Header__c =: coId];
                                        
        List<Deal_Unit_Price_Cost__c> dupcList = [Select Qty__c, Price__c, Deal_Item__r.Customer_Owned_Unit__c, Unit_Price_Cost__r.Total_Cost__c, Total_Cost__c from Deal_Unit_Price_Cost__c where Deal_Item__r.Deal__r.CO_Header__c =: coId];                  
        
        if(dealList.size() > 0) {
            Decimal unitSales, tradeInSales, partSales, merchSales, labourSales, feeSales, subletSales, warrantyProductSales, thirdPartyProductSales, dealProductSales, financingProductSales, commissionSales;
            Decimal unitCost, tradeInCost, partCost, merchCost, labourCost, feeCost, subletCost, warrantyProductCost, dealProductCost, financingProductCost, thirdPartyProductCost, commissionCost;
            unitCost = tradeInCost = partCost = merchCost = labourCost = feeCost = subletCost = warrantyProductCost = dealProductCost = financingProductCost = thirdPartyProductCost = commissionCost = 0;
            
            commissionCost = (dealList[0].Deal_Commission__c != null) ? dealList[0].Deal_Commission__c.setScale(2, RoundingMode.HALF_UP) : 0;
            commissionSales = (dealList[0].Type__c == Constants.FINANCED && dealList[0].Total_Finance_Commission__c != null) ? dealList[0].Total_Finance_Commission__c.setScale(2, RoundingMode.HALF_UP) : 0;
            if(dealList[0].Type__c == Constants.FINANCED && dealList[0].F_I_Products__r.size() > 0) {
                financingProductSales = 0;
                for(F_I_Product__c fAndIProductRec : dealList[0].F_I_Products__r) {
                    if(String.isNotBlank(fAndIProductRec.Cost_Method__c) && !fAndIProductRec.Cost_Method__c.equalsIgnoreCase('Price withheld')) {
                        financingProductCost += (fAndIProductRec.Total_Cost__c != null ? fAndIProductRec.Total_Cost__c : 0);
                        financingProductSales += (fAndIProductRec.Price__c != null ? fAndIProductRec.Price__c : 0);
                    }
                }
            }
			
            List<Deal_Item__c> skuDealItemList = new List<Deal_Item__c>();
			Decimal defaultTechnicianCostingRate = GeneralConfiguration.getDefaultTechnicianCostingRate();
			for(Deal_Item__c dealItemRec : dealList[0].Deal_Items__r) {
				if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
					tradeInSales = (tradeInSales != null) ? tradeInSales.setScale(2, RoundingMode.HALF_UP) : 0;
					dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c : 0;
					dealItemRec.Actual_Cash_Value__c = (dealItemRec.Actual_Cash_Value__c != null) ? dealItemRec.Actual_Cash_Value__c : 0;
					if(GeneralConfiguration.getTaxIncludingPricing()) {
					dealItemRec.Default_Unit_Sales_Tax_Percentage__c = (dealItemRec.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItemRec.Default_Unit_Sales_Tax_Percentage__c : 0;
						dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100));
					}
					tradeInCost += (dealItemRec.Agreed_Value__c - dealItemRec.Actual_Cash_Value__c).setScale(2, RoundingMode.HALF_UP);
				} else if(dealItemRec.Customer_Owned_Unit__c != null && dealItemRec.Customer_Owned_Unit__r.Unit_Type__c.equalsIgnoreCase('COU') && 
										dealItemRec.Customer_Owned_Unit__r.Agreed_Payout__c != null) {
					unitCost += dealItemRec.Customer_Owned_Unit__r.Agreed_Payout__c.setScale(2, RoundingMode.HALF_UP);
				} else if(dealItemRec.Customer_Owned_Unit__c != null) {
                    skuDealItemList.add(dealItemRec);
				}
			}
			
			for(Deal_Unit_Price_Cost__c dupcRec : dupcList) {
                unitSales = (unitSales != null) ? unitSales.setScale(2, RoundingMode.HALF_UP) : 0;
                dupcRec.Qty__c = (dupcRec.Qty__c != null) ? dupcRec.Qty__c : 1;
                dupcRec.Price__c = dupcRec.Price__c != null ? dupcRec.Price__c : 0;
                unitSales += (dupcRec.Price__c * dupcRec.Qty__c).setScale(2, RoundingMode.HALF_UP);
				unitCost += (dupcRec.Deal_Item__r.Customer_Owned_Unit__c == null) ? dupcRec.Total_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
            }
	        unitCost += getUnitCost(skuDealItemList);
            
            for(Option_Fee__c optionFeeRec : dealList[0].Options_Fees__r) {
                optionFeeRec.Price__c = (optionFeeRec.Price__c != null) ? optionFeeRec.Price__c : 0;
                optionFeeRec.Per_Item_Cost__c = (optionFeeRec.Per_Item_Cost__c != null) ? optionFeeRec.Per_Item_Cost__c : 0;
                optionFeeRec.Qty__c = (optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 1;
                
                if(optionFeeRec.Fee__c != null && optionFeeRec.Fee__r.Is_Include_In_Profit_Calculation__c) {
                    feeSales = (feeSales != null) ? feeSales : 0;
                    feeSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                    if(optionFeeRec.Deal_Kit_Header__c != null && optionFeeRec.Status__c != Constants.UNCOMIITTED) {
                        feeCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                    } else {
                        if(optionFeeRec.Fee__r.Cost_Method__c == 'Fixed Cost' && optionFeeRec.Fee__r.Cost_Rate__c != null) {
                            feeCost += (optionFeeRec.Qty__c * optionFeeRec.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
                        } else if(optionFeeRec.Fee__r.Cost_Method__c == 'Percent Retail' && optionFeeRec.Fee__r.Cost_Rate__c != null) {
                            feeCost += (optionFeeRec.Qty__c * ((optionFeeRec.Price__c * optionFeeRec.Fee__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
                        }
                    }
                    
                } else if(optionFeeRec.Product__c != null ) {
                    if(optionFeeRec.Product__r.Type__c == Constants.SUBLET) {
                        subletSales = (subletSales != null) ? subletSales : 0;
                        subletSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                        if(!isOptionCommitted(optionFeeRec)) {
                        	if(optionFeeRec.Product__r.Cost_Method__c == 'Fixed Cost' && optionFeeRec.Product__r.Cost__c != null) {
	                            subletCost += (optionFeeRec.Qty__c * optionFeeRec.Product__r.Cost__c).setScale(2, RoundingMode.HALF_UP);
	                        } else if(optionFeeRec.Product__r.Cost_Method__c == 'Percent Retail' && optionFeeRec.Product__r.Cost__c != null) {
	                            subletCost += (optionFeeRec.Qty__c * ((optionFeeRec.Price__c * optionFeeRec.Product__r.Cost__c)/100)).setScale(2, RoundingMode.HALF_UP);
	                        }
                        } else {
                            subletCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                        }
                        
                    } else {
                        Decimal cost = 0;
                        if(optionFeeRec.Product__r.Cost_Method__c == 'Fixed Cost' && optionFeeRec.Product__r.Cost__c != null) {
                            cost = (optionFeeRec.Qty__c * optionFeeRec.Product__r.Cost__c).setScale(2, RoundingMode.HALF_UP);
                        } else if(optionFeeRec.Product__r.Cost_Method__c == 'Percent Retail' && optionFeeRec.Product__r.Cost__c != null) {
                            cost = (optionFeeRec.Qty__c * ((optionFeeRec.Price__c * optionFeeRec.Product__r.Cost__c)/100)).setScale(2, RoundingMode.HALF_UP);
                        }
                        if(optionFeeRec.Product__r.Type__c == 'Deal Product') {
                            dealProductSales = (dealProductSales != null) ? dealProductSales : 0;
                            dealProductSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                            dealProductCost += cost;
                        } else if(optionFeeRec.Product__r.Type__c == 'Warranty Plan') {
                            warrantyProductSales = (warrantyProductSales != null) ? warrantyProductSales : 0;
                            warrantyProductSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                            warrantyProductCost += cost;
                        } else if(optionFeeRec.Product__r.Type__c == 'Financing Product') {
                            financingProductSales = (financingProductSales != null) ? financingProductSales : 0;
                            financingProductSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                            financingProductCost += cost;
                        } else if(optionFeeRec.Product__r.Type__c == 'Third Party') {
                            thirdPartyProductSales = (thirdPartyProductSales != null) ? thirdPartyProductSales : 0;
                            thirdPartyProductSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                            thirdPartyProductCost += cost;
                        }
                        cost = null;
                    }
                    
                } else if(optionFeeRec.Labour_Code__c != null) {
                    labourSales = (labourSales != null) ? labourSales : 0;
                    labourSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                    if(!isOptionCommitted(optionFeeRec)) {
                    	if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
                            labourCost += (optionFeeRec.Qty__c * defaultTechnicianCostingRate).setScale(2, RoundingMode.HALF_UP);
                        } else {
                            if(optionFeeRec.Labour_Code__r.Cost_Method__c == 'Fixed Cost' && optionFeeRec.Labour_Code__r.Cost_Rate__c != null) {
	                            labourCost += (optionFeeRec.Qty__c * optionFeeRec.Labour_Code__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
	                        } else if(optionFeeRec.Labour_Code__r.Cost_Method__c == 'Percent Retail' && optionFeeRec.Labour_Code__r.Cost_Rate__c != null) {
	                            labourCost += (optionFeeRec.Qty__c * ((optionFeeRec.Price__c * optionFeeRec.Labour_Code__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
	                        }
                        }
                    } else {
                        labourCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                    }
                    
                } else if(optionFeeRec.Part__c != null) {
                	Decimal partAvgCost = optionFeeRec.Part__r.Average_Cost__c != null && optionFeeRec.Part__r.Average_Cost__c != 0 ? 
                						optionFeeRec.Part__r.Average_Cost__c : (optionFeeRec.Part__r.Last_Cost__c != null ? optionFeeRec.Part__r.Last_Cost__c : 0);
                    if(String.isNotBlank(optionFeeRec.Part__r.Part_Type__c) && optionFeeRec.Part__r.Part_Type__c == 'Merchandise') {
                        merchSales = (merchSales != null) ? merchSales : 0;
                        merchSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                        if(!isOptionCommitted(optionFeeRec) && partAvgCost != null) {
	                    	merchCost += (optionFeeRec.Qty__c * partAvgCost).setScale(2, RoundingMode.HALF_UP);
	                    } else {
                            merchCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                        }
                    } else {
                        partSales = (partSales != null) ? partSales : 0;
                        partSales += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                        if(!isOptionCommitted(optionFeeRec) && partAvgCost != null) {
	                    	partCost += (optionFeeRec.Qty__c * partAvgCost).setScale(2, RoundingMode.HALF_UP);
	                    } else {
                            partCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                        }
                    }
                }
            }			
			
			if(dealList[0].Invoice_Number__c != null) {
				unitCost = dealList[0].Total_Unit_Cost__c;
				tradeInCost = dealList[0].Total_TradeIn_Cost__c;
				partCost = dealList[0].Total_Part_Cost__c;
				merchCost = dealList[0].Total_Merch_Cost__c;
				labourCost = dealList[0].Ttoal_Labour_Cost__c;
				subletCost = dealList[0].Total_Sublet_Cost__c;
				feeCost = dealList[0].Total_Fee_Cost__c;
				warrantyProductCost = dealList[0].Total_Warranty_Product_Cost__c;
				dealProductCost = dealList[0].Total_Deal_Product_Cost__c;
				financingProductCost = dealList[0].Total_Financing_Product_Cost__c;
				thirdPartyProductCost = dealList[0].Total_Third_Party_Product_Cost__c;
				commissionCost = dealList[0].Total_Commission_Cost__c;
			}                       
            List<ProfitabilityWrapper.ProductProfitabilityWrapper> dealProfitabilityObjList = new List<ProfitabilityWrapper.ProductProfitabilityWrapper>();
                
            if(unitSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Units', unitSales, unitCost));
            }
            if(tradeInSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Trade Ins', tradeInSales, tradeInCost));
            }
            if(partSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Parts', partSales, partCost));
            }
            if(merchSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Merchandise', merchSales, merchCost));
            }
            if(labourSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Labor', labourSales, labourCost));
            }
            if(subletSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Sublet', subletSales, subletCost));
            }
            if(feeSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Fees', feeSales, feeCost));
            }
            if(warrantyProductSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Warranty Plans', warrantyProductSales, warrantyProductCost));
            }
            if(dealProductSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Deal Products', dealProductSales, dealProductCost));
            }
            if(financingProductSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Finance Products', financingProductSales, financingProductCost));
            }
            if(thirdPartyProductSales != null) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Third-Party Products', thirdPartyProductSales, thirdPartyProductCost));
            }
            if((commissionSales != null && commissionSales != 0) || (commissionCost != null && commissionCost != 0)) {
                dealProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Commissions', commissionSales, commissionCost));
            }
            if(dealProfitabilityObjList.size() > 0) {
                profitabilityWrapperList.add(new ProfitabilityWrapper.SectionProfitabilityWrapper('Deal Section', dealProfitabilityObjList));
            }
        }
        return profitabilityWrapperList;
    }

    public static void saveDealItemInfo(String dealItemInfoJSON) {
        DealItem dealItemDetailObj = (DealItem) system.JSON.deserialize(dealItemInfoJSON, DealItem.class);
        Deal_Item__c dealItemRec = new Deal_Item__c(Id = dealItemDetailObj.Id, Mileage__c = dealItemDetailObj.Mileage, 
                                                        Mileage_Type__c = dealItemDetailObj.MileageType);
        DMLUtility.updateSobjectList('Deal_Item__c', dealItemRec);
    }
    
    public static ResponseWrapper saveDealTaxInfo(COService.COSectionTaxDetailWrapper sectionTaxDetailObj) {
        ResponseWrapper resObj = new ResponseWrapper('success', 'Customer taxes populated successfully');
        if(GeneralConfiguration.getConfigurations().Automatic_Tax_Rates__c && sectionTaxDetailObj != null && sectionTaxDetailObj.IsTaxBasedOnCustomerAddress != null) {
            List<Deal__c> dealList = [Select Id, CO_Header__r.Customer__c, CO_Header__r.Customer__r.BillingState, Is_Tax_Based_On_Customer_Address__c FROM Deal__c WHERE Id =: sectionTaxDetailObj.DealId LIMIT 1];
            
            if(!dealList.isEmpty() && dealList[0].Is_Tax_Based_On_Customer_Address__c != sectionTaxDetailObj.IsTaxBasedOnCustomerAddress && sectionTaxDetailObj.IsTaxBasedOnCustomerAddress
                && dealList[0].CO_Header__r.Customer__c != null) {
                List<State__c> stateList = [SELECT Id FROM State__c WHERE (Name__c =: dealList[0].CO_Header__r.Customer__r.BillingState OR Short_Code__c =: dealList[0].CO_Header__r.Customer__r.BillingState) AND Auto_Tax_Calc__c = true];
                if(stateList.isEmpty()) {
                    throw new BlackPurlException(CUSTOMER_ADDR_AUTO_TAX_CALC_ERROR);
                }
            }

            for(Deal__c oldDealRec : dealList) {
                if(oldDealRec.Is_Tax_Based_On_Customer_Address__c != sectionTaxDetailObj.IsTaxBasedOnCustomerAddress) {
                    Deal__c dealRec = new Deal__c(Id = sectionTaxDetailObj.DealId, Is_Tax_Based_On_Customer_Address__c = sectionTaxDetailObj.IsTaxBasedOnCustomerAddress);
                    List<Tax_Exemption__c> customerTaxes = [Select Id FROM Tax_Exemption__c WHERE Type__c =: TaxUtility.AUTOMATED_CUSTOMER AND CO_Header__c =: oldDealRec.CO_Header__c LIMIT 1];
                    if(sectionTaxDetailObj.IsTaxBasedOnCustomerAddress && customerTaxes.isEmpty()) {
                        resObj = Customer_Service.populateCustomerTaxesOnCO(oldDealRec.CO_Header__c, oldDealRec.CO_Header__r.Customer__c, true);
                        if(resObj != null && resObj.responseStatus.equalsIgnoreCase('error')) {
                            return resObj;
                        }
                    }
                    DMLUtility.updateSobjectList('Deal__c', dealRec);
                    List<F_I_product__c> fiProdList = [Select Id from F_I_product__c WHERE Deal_Finance__r.Deal__c =: dealRec.Id];
                    if(TaxCalculation.IsEnhancedTaxCalculationApplicable && !fiProdList.isEmpty()) {
                        DMLUtility.updateSobjectList('F_I_product__c', fiProdList);
                    } else {
                        OptionAndFeeTriggerHelper.updateDealTotal(new Set<String>{dealRec.Id});
                    }
                }
            }
        }
        return resObj;
    }
    
    public static void saveDealItemTaxInfo(String dealItemTaxInfoJSON) {
        DealItem.DealItemTaxDetailWrapper dealItemTaxDetailObj = 
                (DealItem.DealItemTaxDetailWrapper) system.JSON.deserialize(dealItemTaxInfoJSON, DealItem.DealItemTaxDetailWrapper.class);
        
        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        List<Deal_Item__c> dealItemList = [SELECT Type__c, Deal__c FROM Deal_Item__c WHERE Id =: dealItemTaxDetailObj.Id];
        if(dealItemList.size() == 0) {
            return;
        }
        
        Deal_Item__c dealItemRec = dealItemList[0];
        dealItemRec.Taxable__c = dealItemTaxDetailObj.IsTaxable;
        if(dealItemRec.Taxable__c) {
            dealItemRec.Applicable_Tax__c = dealItemTaxDetailObj.ApplicableTaxId;
        } else {
            dealItemRec.Applicable_Tax__c = null;
        }
        dealItemRec.Unit_Tax_Applicable_On__c = dealItemTaxDetailObj.UnitTaxApplicableOn;
        DMLUtility.updateSobjectList('Deal_Item__c', dealItemRec);
        
        if(GeneralConfiguration.getAccrueTradeTaxUntilUnitSold()) {
            dealItemList = [SELECT Stocked_In_Unit__c, Agreed_Value__c, Default_Unit_Sales_Tax_Percentage__c FROM Deal_Item__c 
                                                    WHERE Id =: dealItemTaxDetailObj.Id AND Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN
                                                        AND Stocked_In_Unit__c != null];
            if(dealItemList.size() > 0) {
                Customer_Owned_Unit__c skuRecToUpdate = new Customer_Owned_Unit__c(Id = dealItemList[0].Stocked_In_Unit__c);
                populateTradeInAndSalesTaxOnSku(dealItemList[0], skuRecToUpdate);
                update skuRecToUpdate;
            }
        }
    }
    
    /**
    * Name: populateTradeInAndSalesTaxOnSku
    * Desc: Method to populate trade in value and sales tax credit amount on stock in unit
    * @param: dealItemRec - Deal_Item__c - Deal Trade In rec
    * @param: unitRec - SObject - stock In unit
    **/
    public static void populateTradeInAndSalesTaxOnSku(Deal_Item__c dealItemRec, SObject unitRec) {
        Decimal agreedValue = (dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c : 0;
        Decimal salesTaxPercentageOnAgreedValue = (dealItemRec.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItemRec.Default_Unit_Sales_Tax_Percentage__c : 0;
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            unitRec.put('Trade_In_Value__c', (agreedValue / (1 + salesTaxPercentageOnAgreedValue/100)).setScale(2, RoundingMode.HALF_UP));
            unitRec.put('Sales_Tax_Credit__c', (agreedValue - (agreedValue / (1 + salesTaxPercentageOnAgreedValue/100))).setScale(2, RoundingMode.HALF_UP));
        } else {
            unitRec.put('Trade_In_Value__c', agreedValue.setScale(2, RoundingMode.HALF_UP));
            unitRec.put('Sales_Tax_Credit__c', (agreedValue * (salesTaxPercentageOnAgreedValue / 100)).setScale(2, RoundingMode.HALF_UP));
        }
    }
    
    public static List<Deal_Unit_Price_Cost__c> addDealUnitCostPrice(Set<Id> unitIdSet, String dealItemId) {
        return addDealUnitCostPrice(unitIdSet, dealItemId, true);
    }
    
    public static List<Deal_Unit_Price_Cost__c> addDealUnitCostPrice(Set<Id> unitIdSet, String dealItemId, Boolean isBaseOptionNeedsToAdd) {
        Map<String, List<Deal_Unit_Price_Cost__c>> optionTypeToDealUnitPriceCostListMap = new Map<String, List<Deal_Unit_Price_Cost__c>>();
        List<Customer_Owned_Unit__c> unitList = SOQLUtil.getUnitDetails(unitIdSet);
        Map<String, List<Unit_Price_Cost__c>> unitIdToUPCListMap = getUnitIdToUPCListMap(unitIdSet);
        for(Customer_Owned_Unit__c unitRec : unitList) {
            if((unitRec.Unit_Type__c == 'STOCK' || unitRec.Unit_Type__c == 'ORDU') && unitIdToUPCListMap.containsKey(unitRec.Id)) {
	            for(Unit_Price_Cost__c unitPriceCostRec : unitIdToUPCListMap.get(unitRec.Id)) {
	                if(unitPriceCostRec.Type__c != 'Base' || (isBaseOptionNeedsToAdd && !optionTypeToDealUnitPriceCostListMap.containsKey('Base'))) {
	                    Deal_Unit_Price_Cost__c dealUnitPriceCostRec = setFieldsToDealUnitPriceCost(unitPriceCostRec, dealItemId);
	                    if(!optionTypeToDealUnitPriceCostListMap.containsKey(dealUnitPriceCostRec.Type__c)) {
	                        optionTypeToDealUnitPriceCostListMap.put(dealUnitPriceCostRec.Type__c, new List<Deal_Unit_Price_Cost__c>{});
	                    }
	                    optionTypeToDealUnitPriceCostListMap.get(dealUnitPriceCostRec.Type__c).add(dealUnitPriceCostRec);
	                } else if(isBaseOptionNeedsToAdd) {
	                    optionTypeToDealUnitPriceCostListMap.get('Base')[0].Price__c += (unitPriceCostRec.Total_Price__c != null ? unitPriceCostRec.Total_Price__c : 0);
	                    if(GeneralConfiguration.getTaxIncludingPricing()) {
	                		optionTypeToDealUnitPriceCostListMap.get('Base')[0].Price_When_Tax_Included__c += (unitPriceCostRec.Total_Price__c != null ? unitPriceCostRec.Total_Price__c : 0);
	                	}
	                }
	            }
            } else if(unitRec.Unit_Type__c == 'COU') {
        		Deal_Unit_Price_Cost__c dealUnitPriceCostRec = new Deal_Unit_Price_Cost__c();
		        dealUnitPriceCostRec.Item_Description__c = Constants.BASE_UNIT;
		        dealUnitPriceCostRec.Price__c = unitRec.Suggested_Price__c != null ? unitRec.Suggested_Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
		        dealUnitPriceCostRec.Type__c = 'Base';
	            dealUnitPriceCostRec.Qty__c = 1;
	            dealUnitPriceCostRec.Cost__c = unitRec.Agreed_Payout__c != null ? unitRec.Agreed_Payout__c.setScale(2, RoundingMode.HALF_UP) : 0;
	            
		        if(GeneralConfiguration.getTaxIncludingPricing()) {
		            dealUnitPriceCostRec.Price_When_Tax_Included__c = dealUnitPriceCostRec.Price__c;
		        }
		        dealUnitPriceCostRec.Deal_Item__c =  dealItemId;
        		optionTypeToDealUnitPriceCostListMap.put('Base', new List<Deal_Unit_Price_Cost__c>{dealUnitPriceCostRec});
        	}
         }
         List<Deal_Unit_Price_Cost__c> dealUnitPriceCostList = new List<Deal_Unit_Price_Cost__c>();
         for(String optionType : optionTypeToDealUnitPriceCostListMap.keySet()) {
            dealUnitPriceCostList.addAll(optionTypeToDealUnitPriceCostListMap.get(optionType));
         }
         return dealUnitPriceCostList; 
    }
    
    public static Deal_Unit_Price_Cost__c setFieldsToDealUnitPriceCost(Unit_Price_Cost__c unitPriceCostRec, String dealItemId) {
        Deal_Unit_Price_Cost__c dealUnitPriceCostRec = new Deal_Unit_Price_Cost__c();
        
        if(String.isNotBlank(unitPriceCostRec.Item_Description__c) && unitPriceCostRec.Item_Description__c.length() > 80) {
        	dealUnitPriceCostRec.Name = unitPriceCostRec.Item_Description__c.subString(0, 80);
        } else {
        	dealUnitPriceCostRec.Name = unitPriceCostRec.Item_Description__c;
        }
        dealUnitPriceCostRec.Item_Description__c = (unitPriceCostRec.Type__c == 'Base') ? Constants.BASE_UNIT : unitPriceCostRec.Item_Description__c;
        dealUnitPriceCostRec.Price__c = unitPriceCostRec.Price__c;
        dealUnitPriceCostRec.Type__c = unitPriceCostRec.Type__c;
        if(dealUnitPriceCostRec.Type__c == 'Dealer') {
            dealUnitPriceCostRec.Qty__c = unitPriceCostRec.Qty__c;
        } else {
            dealUnitPriceCostRec.Qty__c = 1;
        }
        
        if(dealUnitPriceCostRec.Type__c == 'Factory' || dealUnitPriceCostRec.Type__c == 'Base') {
            dealUnitPriceCostRec.Price__c = (unitPriceCostRec.Total_Price__c != null ? unitPriceCostRec.Total_Price__c : 0);
        }
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            dealUnitPriceCostRec.Price_When_Tax_Included__c = dealUnitPriceCostRec.Price__c;
        }
        dealUnitPriceCostRec.Deal_Item__c =  dealItemId;
        dealUnitPriceCostRec.Unit_Price_Cost__c = unitPriceCostRec.Id;
        return dealUnitPriceCostRec;
    }
    
    public static Boolean checkForRefreshLinkOnDealUnitPriceCost(String dealItemId, String unitId) {
        Boolean isNeedToRefresh = false;
        if(String.isNotBlank(unitId)) {
	        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Price_Cost__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        List<Unit_Price_Cost__c> unitPriceAndCostList = 
	                [Select Id, (SELECT Id FROM Deal_Unit_Prices_Costs__r WHERE Deal_Item__c =: dealItemId) 
	                        FROM Unit_Price_Cost__c 
	                        WHERE Customer_Owned_Unit__c =: unitId AND (Type__c = 'Factory' OR Type__c = 'Dealer')];
	        for(Unit_Price_Cost__c unitPriceAndCostRec : unitPriceAndCostList) {
	            if(unitPriceAndCostRec.Deal_Unit_Prices_Costs__r.size() == 0) {
	                isNeedToRefresh = true;
	                break;
	            }
	        }
        }
        return isNeedToRefresh;
    }
    
    public static void refreshDealUnitPriceCost(String dealItemId, String unitId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Deal_Unit_Price_Cost__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(!AccessControl.ifObjectIsDeletable('Deal_Unit_Price_Cost__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(!AccessControl.ifObjectFieldIsAccessible('Deal_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Deal_Unit_Price_Cost__c> existingDealUnitPriceList = [SELECT Id FROM Deal_Unit_Price_Cost__c WHERE Deal_Item__c =: dealItemId AND Type__c != 'Base'];
        if(existingDealUnitPriceList.size() > 0) {
            delete existingDealUnitPriceList;
        }
        
        // Disable Rideaway If ON - To reset pricing
        List<Deal_Item__c> dealItemList = [SELECT Is_Rideaway_Pricing_Enabled__c from Deal_Item__c where Id =: dealItemId];
        if(dealItemList.size() > 0 && dealItemList[0].Is_Rideaway_Pricing_Enabled__c) {
            dealItemList[0].Is_Rideaway_Pricing_Enabled__c = false;
            if(!AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update dealItemList[0];
        }
        
        List<Deal_Unit_Price_Cost__c> dealUnitPriceListToInsert = addDealUnitCostPrice(new Set<Id>{unitId}, dealItemId, false);
        if(dealUnitPriceListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dealUnitPriceListToInsert);
        }
    }
    
    public static String createDealMerchSection(String dealItemIdSetJson, String coHeaderId) {
        Set<String> dealItemIdSet = (Set<String>) System.JSON.deserialize(dealItemIdSetJson, Set<String>.class);
        List<Deal_Item__c> dealItemList = SOQLUtil.getDealItemDetailsToCommit(dealItemIdSet);
        String dealId;
        Map<Id, Deal_Item__c> dealIdToOptionFeeMap = new Map<Id, Deal_Item__c>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            dealId = dealItemRec.Deal__c;
            dealIdToOptionFeeMap.put(dealItemRec.Id, dealItemRec);
        }
        
        List<Deal_Kit_Header__c> dealKHList = SOQLUtil.getDealKitHeaderDetailsByDealItemId(new Set<Id>(dealIdToOptionFeeMap.keySet()));
        Map<Id, Deal_Kit_Header__c> dealKHIdToDKHMap = new Map<Id, Deal_Kit_Header__c>(dealKHList);
        
        List<Option_Fee__c> merchOptionAndFeeList = new List<Option_Fee__c>();
        List<Deal_Kit_Header__c> dealKitHeaderToAddInMerchList = new List<Deal_Kit_Header__c>();

        for(Deal_Item__c dealItemRec : dealItemList) {
            for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
                if(!optionAndFeeRec.Is_Install__c && isOptionCommitable(optionAndFeeRec) && !isOptionCommitted(optionAndFeeRec)) {
                    merchOptionAndFeeList.add(optionAndFeeRec);
                }
            }
            
            List<Deal_Kit_Header__c> dkhList = new List<Deal_Kit_Header__c>();
            for(Deal_Kit_Header__c dealKitHeaderRec : dealItemRec.Deal_Kit_Headers__r) {
                if(!dealKitHeaderRec.Is_Install__c && dealKHIdToDKHMap.containsKey(dealKitHeaderRec.Id) && 
                (dealKHIdToDKHMap.get(dealKitHeaderRec.Id).Options_Fees__r.size() == 0 || 
                !isOptionCommitted(dealKHIdToDKHMap.get(dealKitHeaderRec.Id).Options_Fees__r[0]))
                ) {
                    dealKitHeaderToAddInMerchList.add(dealKHIdToDKHMap.get(dealKitHeaderRec.Id));
                }
            }
        }
        
        List<CO_Line_Item__c> coLineItemListToInsert = new List<CO_Line_Item__c>();
        
        // Non-kit part
        for(Option_Fee__c optionAndFeeRec : merchOptionAndFeeList) {
            CO_Line_Item__c coliRec = setColiFields(optionAndFeeRec, coHeaderId, null, dealId);
            coLineItemListToInsert.add(coliRec);
        }
        
        if(coLineItemListToInsert.size() > 0) {
            // Add CO Section Detail record for Deal Merchandise section when Deal Merchandise records are creating.
            COSectionDetailService.checkAndCreateCOSection_future(coHeaderId, COSectionDetailService.DEAL_MERCHANDISE);
            DMLUtility.insertSobjectList('CO_Line_Item__c', coLineItemListToInsert);
            
            COService.addDefaultSalespersonToCOSection(coHeaderId, DealUtil.DEAL_MERCH, dealId);
        }
        
        // Insert Kit in Merch grid
        List<CO_Kit_Header__c> cokhList = new List<CO_Kit_Header__c>();
        for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaderToAddInMerchList) {
            cokhList.add(setCOKitHeaderFields(dealKitHeaderRec, coHeaderId, dealId));
        }
        if(cokhList.size() > 0) {
            DMLUtility.insertSobjectList('CO_Kit_Header__c', cokhList);
        }
        
        // Merch grid kit line item
        List<Co_Line_Item__c> coliList = new List<CO_Line_Item__c>();
        for(CO_Kit_Header__c coKitHeaderRec : cokhList) {
            if(dealKHIdToDKHMap.containsKey(coKitHeaderRec.Deal_Kit_Header__c)) {
                for(Option_Fee__c optionAndFeeRec : dealKHIdToDKHMap.get(coKitHeaderRec.Deal_Kit_Header__c).Options_Fees__r) {
                    coliList.add(setColiFields(optionAndFeeRec, coHeaderId, coKitHeaderRec.Id, dealId));
                }
            }
        }
        
        // Insert Kit Deal Merchandise Line item
        if(coliList.size() > 0) {
            COSectionDetailService.checkAndCreateCOSection_future(coHeaderId, COSectionDetailService.DEAL_MERCHANDISE);
            DMLUtility.insertSobjectList('Co_Line_Item__c', coliList);
            
            // Add CO Section Detail record for Deal Merchandise section when Deal Merchandise records are creating.
            if(coLineItemListToInsert.size() == 0) {
                COService.addDefaultSalespersonToCOSection(coHeaderId, DealUtil.DEAL_MERCH, dealId);
            }
        }
        
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            Map<Id, CO_Kit_Header__c> cokhIdToCokhListMap = new Map<Id, CO_Kit_Header__c>();
            for(CO_Line_Item__c coLineItemRec : coliList) {
                
                Decimal price = 0;
                if(cokhIdToCokhListMap.containsKey(coLineItemRec.CO_Kit_Header__c)) {
                    price = (cokhIdToCokhListMap.get(coLineItemRec.CO_Kit_Header__c).Price__c != null) ? cokhIdToCokhListMap.get(coLineItemRec.CO_Kit_Header__c).Price__c : 0;
                }
                coLineItemRec.Price_When_Tax_Included__c = (coLineItemRec.Price_When_Tax_Included__c != null) ? coLineItemRec.Price_When_Tax_Included__c : 0;
                coLineItemRec.Qty__c = (coLineItemRec.Qty__c != null) ? coLineItemRec.Qty__c : 0;
                price += (coLineItemRec.Price_When_Tax_Included__c * coLineItemRec.Qty__c);
                cokhIdToCokhListMap.put(coLineItemRec.CO_Kit_Header__c, new CO_Kit_Header__c(Id = coLineItemRec.CO_Kit_Header__c, Price__c = price));
            }
            
            if(cokhIdToCokhListMap.keySet().size() > 0) {
                update cokhIdToCokhListMap.values();
            }
        }
        
        List<Option_Fee__c> optionFeeUpdateList = new List<Option_Fee__c>();
        for(CO_Line_Item__c coliRec: coLineItemListToInsert) {
            optionFeeUpdateList.add(new Option_Fee__c(Id = coliRec.Option_Fee__c, CO_Line_Item__c = coliRec.Id, Status__c = Constants.COMMITTED));
        }
        
        for(CO_Line_Item__c coliRec: coliList) {
        	optionFeeUpdateList.add(new Option_Fee__c(Id = coliRec.Option_Fee__c, CO_Line_Item__c = coliRec.Id, Status__c = Constants.COMMITTED));
        }
        if(optionFeeUpdateList.size() > 0) {
            BPScriptUtility.disbaleTrigger('OptionAndFeeTrigger');
            update optionFeeUpdateList;
            BPScriptUtility.enableTrigger('OptionAndFeeTrigger');
        }
        return getDealDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('dealMerchandise'));
    }

    public static String createDealServiceSection(String dealItemIdSetJson, String coHeaderId) {
        Set<String> dealItemIdSet = (Set<String>) System.JSON.deserialize(dealItemIdSetJson, Set<String>.class);
    	List<Deal_Item__c> dealItemList = SOQLUtil.getDealItemDetailsToCommit(dealItemIdSet);
        String dealId;
        
        Map<Id, Deal_Item__c> dealIdToOptionFeeMap = new Map<Id, Deal_Item__c>();
        Set<Option_Fee__c> optionFeeList = new Set<Option_Fee__c>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            dealId = dealItemRec.Deal__c;
            dealIdToOptionFeeMap.put(dealItemRec.Id, dealItemRec);
            optionFeeList.addAll(dealItemRec.Options_Fees__r);
        }
        
        List<Deal_Kit_Header__c> dealKHList = SOQLUtil.getDealKitHeaderDetailsByDealItemId(new Set<Id>(dealIdToOptionFeeMap.keySet()));
        Map<Id, Deal_Kit_Header__c> dealKHIdToDKHMap = new Map<Id, Deal_Kit_Header__c>(dealKHList);
        Map<Id, List<Option_Fee__c>> dealItemIdToDealServiceOptionAndFeeListMap = new Map<Id, List<Option_Fee__c>>();
        Map<Id, List<Deal_Kit_Header__c>> dealItemIdToServiceDKHListMap = new Map<Id, List<Deal_Kit_Header__c>>();
        //Map to contain DealItem id to so Header id map
        Map<String, String> dealItemIdToSOHeaderIdMap = new Map<String, String>();
        
        Integer totalExistingDealService = 1;
        Boolean isNonInventoryDealServicePartAvailable = false;
        List<AggregateResult> aggList = [Select Count(Id) TotalDealService From Service_Order_Header__c Where Deal__c != null AND Deal__c = :dealId];
        if(aggList.size() > 0) {
            totalExistingDealService += (Integer) aggList[0].get('TotalDealService');
        }
        Set<String> dealItemIdToInsertDealServiceSet = new Set<String>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            List<Option_Fee__c> installedOptionAndFeeRecList = new List<Option_Fee__c>();
            String activeDSId = getActiveDealServiceId(dealItemRec);
            for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
                if(optionAndFeeRec.Is_Install__c && isOptionCommitable(optionAndFeeRec) && !isOptionCommitted(optionAndFeeRec)) { // Deal Service Section
                    if(optionAndFeeRec.Part__c != null && optionAndFeeRec.Part__r.Non_Inventory_Part__c) {
                        isNonInventoryDealServicePartAvailable = true;
                    }
                    installedOptionAndFeeRecList.add(optionAndFeeRec);
                    if(String.isNotBlank(activeDSId)) {
                        dealItemIdToSOHeaderIdMap.put(dealItemRec.Id, activeDSId);
                    } else  {
                        dealItemIdToInsertDealServiceSet.add(dealItemRec.Id);
                    }
                }
            }
            dealItemIdToDealServiceOptionAndFeeListMap.put(dealItemRec.Id, installedOptionAndFeeRecList);

            List<Deal_Kit_Header__c> dkhList = new List<Deal_Kit_Header__c>();
            for(Deal_Kit_Header__c dealKitHeaderRec : dealItemRec.Deal_Kit_Headers__r) {
                if(dealKitHeaderRec.Is_Install__c && dealKHIdToDKHMap.containsKey(dealKitHeaderRec.Id) && 
                (dealKHIdToDKHMap.get(dealKitHeaderRec.Id).Options_Fees__r.size() == 0 || 
                !isOptionCommitted(dealKHIdToDKHMap.get(dealKitHeaderRec.Id).Options_Fees__r[0]))
                ) {
                    dkhList.add(dealKHIdToDKHMap.get(dealKitHeaderRec.Id));
                    if(String.isNotBlank(activeDSId)) {
                        dealItemIdToSOHeaderIdMap.put(dealItemRec.Id, activeDSId);
                    } else  {
                        dealItemIdToInsertDealServiceSet.add(dealItemRec.Id);
                    }
                }
            }
            dealItemIdToServiceDKHListMap.put(dealItemRec.Id, dkhList);
        }
        
        // Insert Line Items q-4
        List<Service_Order_Header__c> soHeaderListToInsert = new List<Service_Order_Header__c>();
        List<Service_Order_Line_Item__c> soliListToInsert = new List<Service_Order_Line_Item__c>();
        
        // SOHeader for all required deal items
        for(String dealItemRecId : dealItemIdToInsertDealServiceSet) {
            soHeaderListToInsert.add(setSOHeaderFields(dealItemRecId, coHeaderId, totalExistingDealService, dealId, dealIdToOptionFeeMap.get(dealItemRecId).Customer_Owned_Unit__c));
            totalExistingDealService++;
        }
        if(soHeaderListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Service_Order_Header__c', soHeaderListToInsert);
        }       
        
        //Invoice item
        
        for(Service_Order_Header__c soHeaderRec : soHeaderListToInsert) {
            dealItemIdToSOHeaderIdMap.put(soHeaderRec.Deal_Item__c, soHeaderRec.Id);
        }
        
        //Insert invoice item for so and deal
        List<CO_Invoice_Item__c> coInvoiceItemListToInsert = new List<CO_Invoice_Item__c>();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Invoice_Header__c> coInvoiceHeaderList = [Select Id, (Select Id from CO_Invoice_Items__r where Deal__c =: dealId) from CO_Invoice_Header__c where CO_Header__c = :coHeaderId AND Invoice_Status__c = 'Active'];
        if(coInvoiceHeaderList.size() == 0) {
            coInvoiceHeaderList.add(new CO_Invoice_Header__c(CO_Header__c = coHeaderId, Invoice_Status__c = 'Active'));
            if(AccessControl.ifObjectFieldIsCreateable('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert coInvoiceHeaderList;
        }
        
        for(Service_Order_Header__c soHeaderRec :  soHeaderListToInsert){
             CO_Invoice_Item__c coInvoiceItemRec = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeaderList[0].Id, isActive__c = true, Is_Invoiceable__c = false, Service_Order_Header__c = soHeaderRec.Id);
             coInvoiceItemListToInsert.add(coInvoiceItemRec);
        }
        if(coInvoiceItemListToInsert.size() > 0){
            DMLUtility.upsertSobjectList('CO_Invoice_Item__c', coInvoiceItemListToInsert);
        }
        
        List<Service_Order_Kit_Header__c> sokhList = new List<Service_Order_Kit_Header__c>();
        // Non-kit soli and sokit header formation
        for(String dealItemRecId : dealItemIdToSOHeaderIdMap.keySet()) {
            // Non kit soli
            if(dealItemIdToDealServiceOptionAndFeeListMap.containsKey(dealItemRecId)) {
                for(Option_Fee__c optionFeeRec : dealItemIdToDealServiceOptionAndFeeListMap.get(dealItemRecId)) {
                    if(dealItemIdToSOHeaderIdMap.containsKey(dealItemRecId)) {
                        soliListToInsert.add(setSoliFields(optionFeeRec, dealItemIdToSOHeaderIdMap.get(dealItemRecId), null));
                    }
                }
            }
            // so kit header
            if(dealItemIdToServiceDKHListMap.containsKey(dealItemRecId)) {
                for(Deal_Kit_Header__c dealKitHeaderRec : dealItemIdToServiceDKHListMap.get(dealItemRecId)) {
                    if(dealItemIdToSOHeaderIdMap.containsKey(dealItemRecId)) {
                        sokhList.add(setSOKitHeaderFields(dealKitHeaderRec, dealItemIdToSOHeaderIdMap.get(dealItemRecId), dealId)); 
                    }
                }
            }
        }
        if(sokhList.size() > 0) {
            DMLUtility.insertSobjectList('Service_Order_Kit_Header__c', sokhList);
        }
        // so kit line item 
        for(Service_Order_Kit_Header__c soKitHeaderRec : sokhList) {
            if(dealKHIdToDKHMap.containsKey(soKitHeaderRec.Deal_Kit_Header__c)) {
                for(Option_Fee__c optionAndFeeRec : dealKHIdToDKHMap.get(soKitHeaderRec.Deal_Kit_Header__c).Options_Fees__r) {
                    soliListToInsert.add(setSoliFields(optionAndFeeRec, soKitHeaderRec.Service_Order_Header__c, soKitHeaderRec.Id));
                    if(optionAndFeeRec.Part__c != null && optionAndFeeRec.Part__r.Non_Inventory_Part__c) {
                        isNonInventoryDealServicePartAvailable = true;
                    }
                }
            }
        }
        
        if(soliListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliListToInsert);
        }
        
        List<Option_Fee__c> optionFeeUpdateList = new List<Option_Fee__c>();
        for(Service_Order_Line_Item__c soliRec: soliListToInsert) {
            optionFeeUpdateList.add(new Option_Fee__c(Id = soliRec.Option_Fee__c, Service_Order_Line_Item__c = soliRec.Id, Status__c = Constants.COMMITTED));
        }
        
        if(optionFeeUpdateList.size() > 0) {
            BPScriptUtility.disbaleTrigger('OptionAndFeeTrigger');
            update optionFeeUpdateList;
            BPScriptUtility.enableTrigger('OptionAndFeeTrigger');
        }
        
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            Map<Id, Service_Order_Kit_Header__c> sokhIdToSokhListMap = new Map<Id, Service_Order_Kit_Header__c>();
            for(Service_Order_Line_Item__c soLineItemRec : soliListToInsert) {
                if(String.isNotBlank(soLineItemRec.Service_Order_Kit_Header__c)) {
                    Decimal price = 0;
                    if(sokhIdToSokhListMap.containsKey(soLineItemRec.Service_Order_Kit_Header__c)) {
                        price = (sokhIdToSokhListMap.get(soLineItemRec.Service_Order_Kit_Header__c).Fixed_Price__c != null) ? sokhIdToSokhListMap.get(soLineItemRec.Service_Order_Kit_Header__c).Fixed_Price__c : 0;
                    }
                    soLineItemRec.Price_When_Tax_Included__c = (soLineItemRec.Price_When_Tax_Included__c != null) ? soLineItemRec.Price_When_Tax_Included__c : 0;
                    soLineItemRec.Qty_Needed__c = (soLineItemRec.Qty_Needed__c != null) ? soLineItemRec.Qty_Needed__c : 0;
                    price += (soLineItemRec.Price_When_Tax_Included__c * soLineItemRec.Qty_Needed__c);
                    
                    sokhIdToSokhListMap.put(soLineItemRec.Service_Order_Kit_Header__c, new Service_Order_Kit_Header__c(Id = soLineItemRec.Service_Order_Kit_Header__c, Fixed_Price__c = price));
                }
                
            }
            
            if(sokhIdToSokhListMap.keySet().size() > 0) {
                update sokhIdToSokhListMap.values();
            }
        }
        if(isNonInventoryDealServicePartAvailable) {
            COSectionDetailService.setSectionStatus_future(new Set<Id>{coHeaderId}, COSectionDetailService.SERVICE);
        }
        
        return System.JSON.serialize(new ResponseWrapper('success', 'success'));
    }
    
    public static String setStatusForCommitAndInstallAction(String dealId, String coHeaderId) {
        List<Deal_Item__c> dealItemList = SOQLUtil.getDealItemDetailsByFieldName(new Map<String, String>{'Deal__c' => dealId,
                                                                                                        'Type__c' => Constants.DEAL_ITEM_TYPE_UNIT});
        Set<String> couIdSet = new Set<String>();
        List<Option_Fee__c> optionFeeWithoutKitList = new List<Option_Fee__c>();
        List<Deal_Kit_Header__c> dealKitHeaderList = new List<Deal_Kit_Header__c>();

        Deal__c dealRec = new Deal__c(Id = dealId, Unit_Status__c = Constants.COMMITTED);
        for(Deal_Item__c dealItemRec: dealItemList) {
            String optionStatus = Constants.COMMITTED;
            for(Option_Fee__c ofRec : dealItemRec.Options_Fees__r) {
                if(isOptionCommitable(ofRec) && !isOptionCommitted(ofRec)) {
                    optionStatus = Constants.UNCOMIITTED;
                    break;
                }
            }
            dealItemRec.Option_And_Fee_Status__c = optionStatus;
            couIdSet.add(dealItemRec.Customer_Owned_Unit__c);
            optionFeeWithoutKitList.addAll(dealItemRec.Options_Fees__r);
            dealKitHeaderList.addAll(dealItemRec.Deal_Kit_Headers__r);
        }
        
        if(dealItemList.size() > 0) {
    	    update dealItemList;
    	}
        
        //Insert invoice item for so and deal
        List<CO_Invoice_Item__c> coInvoiceItemListToInsert = new List<CO_Invoice_Item__c>();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Invoice_Header__c> coInvoiceHeaderList = [Select Id, (Select Id from CO_Invoice_Items__r where Deal__c =: dealId) from CO_Invoice_Header__c where CO_Header__c = :coHeaderId AND Invoice_Status__c = 'Active'];
        if(coInvoiceHeaderList.size() == 0) {
            coInvoiceHeaderList.add(new CO_Invoice_Header__c(CO_Header__c = coHeaderId, Invoice_Status__c = 'Active'));
            if(AccessControl.ifObjectFieldIsCreateable('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert coInvoiceHeaderList;
        }
        
        CO_Invoice_Item__c coInvoiceItem;
        if(coInvoiceHeaderList[0].CO_Invoice_Items__r.size() > 0) {
            coInvoiceItem = coInvoiceHeaderList[0].CO_Invoice_Items__r[0];
        } else {
            coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeaderList[0].Id, isActive__c = true, Is_Invoiceable__c = false, Deal__c = dealId);
        }
        
        // Changed according to Ticket #6543 - TK
        Map<String, Boolean> optionNameToOptionValueMap = isDealInvoiceable(dealId);
        coInvoiceItem.Is_Invoiceable__c = optionNameToOptionValueMap.get('Invoiceable');
        coInvoiceItem.isActive__c = optionNameToOptionValueMap.get('Active');
        
        
        String dealStatus = Constants.IN_PROGRESS;
        if(optionFeeWithoutKitList.size() == 0 && dealKitHeaderList.size() == 0) {
            dealStatus = Constants.FULFILLED;
        }
        
        coInvoiceItemListToInsert.add(coInvoiceItem);
        if(coInvoiceItemListToInsert.size() > 0){
            DMLUtility.upsertSobjectList('CO_Invoice_Item__c', coInvoiceItemListToInsert);
        }
        if(AccessControl.ifObjectFieldIsUpdateable('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        //List<SObject> sObjectListToUpdate = new List<SObject>((List<SObject>)dealItemList);
        List<SObject> sObjectListToUpdate = new List<SObject>();
        
        if(GeneralConfiguration.isLoadNewCustomerOrder()) {
            dealRec.Is_Deal_Fulfilled__c = dealStatus == Constants.FULFILLED;
        } else {
            dealRec.Status__c = dealStatus;
        }
        sObjectListToUpdate.addAll((List<SObject>)(new List<Deal__c>{dealRec}));
        
        List<Customer_Owned_Unit__c> couList = [SELECT Status__c FROM Customer_Owned_Unit__c WHERE Id IN :couIdSet];
        for(Customer_Owned_Unit__c couRec : couList) {
            if(couRec.Status__c != Constants.ON_ORDER_STATUS) {
                couRec.Status__c = Constants.UNIT_STATUS_RESERVED;
            }
        }
        sObjectListToUpdate.addAll((List<SObject>)couList);
        update sObjectListToUpdate;
        return System.JSON.serialize(new ResponseWrapper('success', 'success'));
    }
    
    public static void populateDealIndividualsCostTotalsAfterFinalize(String coInvoiceId) {
    	List<Deal__c> dealList = [Select Deal_Commission__c, Type__c,
			(Select Qty__c, Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c, Fee__r.Is_Include_In_Profit_Calculation__c,  Product__r.Cost__c, Product__r.Cost_Method__c, Cost__c, 
				Deal_Kit_Header__c, Status__c, Part__c, Part__r.Part_Type__c, Labour_Code__c, Price__c, Per_Item_Cost__c, Product__r.Type__c, Deal_Item__c from Options_Fees__r),
			(Select Agreed_Value__c, Actual_Cash_Value__c, Default_Unit_Sales_Tax_Percentage__c, Customer_Owned_Unit__c, Type__c, 
				Customer_Owned_Unit__r.Unit_Type__c, Customer_Owned_Unit__r.Agreed_Payout__c, Customer_Owned_Unit__r.Total_Cost__c from Deal_Items__r),
			(Select Id, Total_Cost__c from F_I_Products__r) 
			from Deal__c where Invoice_Number__c =: coInvoiceId];
		
	 	
	 	if(dealList.size() > 0) {
    		Decimal unitCost, tradeInCost, partCost, merchCost, labourCost, subletCost, feeCost, warrantyProductCost, dealProductCost, financingProductCost, thirdPartyProductCost, commissionCost;
    		unitCost = tradeInCost = partCost = merchCost = labourCost = subletCost = feeCost = warrantyProductCost = dealProductCost = financingProductCost = thirdPartyProductCost = commissionCost = 0;
    		
            Map<Id, Deal_Item__c> skuDealItemRecMap = new Map<Id, Deal_Item__c>();
            List<Deal_Item__c> dealItemForConsignList = new List<Deal_Item__c>();
	        for(Deal_Item__c dealItemRec : dealList[0].Deal_Items__r) {
	        	if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
					dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c : 0;
					dealItemRec.Actual_Cash_Value__c = (dealItemRec.Actual_Cash_Value__c != null) ? dealItemRec.Actual_Cash_Value__c : 0;
					if(GeneralConfiguration.getTaxIncludingPricing()) {
						dealItemRec.Default_Unit_Sales_Tax_Percentage__c = (dealItemRec.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItemRec.Default_Unit_Sales_Tax_Percentage__c : 0;
						dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100));
					}
					tradeInCost += (dealItemRec.Agreed_Value__c - dealItemRec.Actual_Cash_Value__c).setScale(2, RoundingMode.HALF_UP);
				} else if(dealItemRec.Customer_Owned_Unit__r.Unit_Type__c.equalsIgnoreCase('COU') && 
									dealItemRec.Customer_Owned_Unit__r.Agreed_Payout__c != null) {
					unitCost += dealItemRec.Customer_Owned_Unit__r.Agreed_Payout__c.setScale(2, RoundingMode.HALF_UP);
                    dealItemRec.Unit_Cost__c = unitCost;
                    dealItemForConsignList.add(dealItemRec);
				} else {
                    skuDealItemRecMap.put(dealItemRec.Id, dealItemRec);
				}
			}
			
	        unitCost += getUnitCost(skuDealItemRecMap.values());
			//FINANCING PRODUCT COST
			if(dealList[0].Type__c == Constants.FINANCED && dealList[0].F_I_Products__r.size() > 0) {
				for(F_I_Product__c fAndIProductRec : dealList[0].F_I_Products__r) {
                    financingProductCost += (fAndIProductRec.Total_Cost__c != null ? fAndIProductRec.Total_Cost__c : 0);
				}
			}
			
            Map<Id, List<Option_Fee__c>> dealItemIdToOptionFeeListMap = new Map<Id, List<Option_Fee__c>>();
			for(Option_Fee__c optionFeeRec : dealList[0].Options_Fees__r) {
                if(!dealItemIdToOptionFeeListMap.containsKey(optionFeeRec.Deal_Item__c)) {
                    dealItemIdToOptionFeeListMap.put(optionFeeRec.Deal_Item__c, new List<Option_Fee__c>());
                }
                dealItemIdToOptionFeeListMap.get(optionFeeRec.Deal_Item__c).add(optionFeeRec);
            }
            for(Id dealItemId : dealItemIdToOptionFeeListMap.keyset()) {
                Decimal unitPartCost, unitMerchCost, unitLabourCost, unitSubletCost, unitFeeCost, unitWarrantyProductCost, unitDealProductCost, unitFinancingProductCost, unitThirdPartyProductCost, unitCommissionCost;
                unitPartCost = unitMerchCost = unitLabourCost = unitSubletCost = unitFeeCost = unitWarrantyProductCost = unitDealProductCost = unitFinancingProductCost = unitThirdPartyProductCost = unitCommissionCost = 0;
                
                for(Option_Fee__c optionFeeRec : dealItemIdToOptionFeeListMap.get(dealItemId)) {
				optionFeeRec.Price__c = (optionFeeRec.Price__c != null) ? optionFeeRec.Price__c : 0;
    			optionFeeRec.Per_Item_Cost__c = (optionFeeRec.Per_Item_Cost__c != null) ? optionFeeRec.Per_Item_Cost__c : 0;
    			optionFeeRec.Qty__c = (optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 1;
    			
	            if(optionFeeRec.Fee__c != null && optionFeeRec.Fee__r.Is_Include_In_Profit_Calculation__c) {
	                if(optionFeeRec.Deal_Kit_Header__c != null && optionFeeRec.Status__c != Constants.UNCOMIITTED) {
                            unitFeeCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
	                } else {
	                    if(optionFeeRec.Fee__r.Cost_Method__c == 'Fixed Cost' && optionFeeRec.Fee__r.Cost_Rate__c != null) {
                                unitFeeCost += (optionFeeRec.Qty__c * optionFeeRec.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
	                    } else if(optionFeeRec.Fee__r.Cost_Method__c == 'Percent Retail' && optionFeeRec.Fee__r.Cost_Rate__c != null) {
                                unitFeeCost += (optionFeeRec.Qty__c * ((optionFeeRec.Price__c * optionFeeRec.Fee__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
	                    }
	                }
	            } else if(optionFeeRec.Product__c != null ) {
	                if(optionFeeRec.Product__r.Type__c == Constants.SUBLET && optionFeeRec.Status__c != Constants.UNCOMIITTED) {
                            unitSubletCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
	                } else {
	                	Decimal cost = 0;
	                    if(optionFeeRec.Product__r.Cost_Method__c == 'Fixed Cost' && optionFeeRec.Product__r.Cost__c != null) {
	                        cost = (optionFeeRec.Qty__c * optionFeeRec.Product__r.Cost__c).setScale(2, RoundingMode.HALF_UP);
	                    } else if(optionFeeRec.Product__r.Cost_Method__c == 'Percent Retail' && optionFeeRec.Product__r.Cost__c != null) {
	                        cost = (optionFeeRec.Qty__c * ((optionFeeRec.Price__c * optionFeeRec.Product__r.Cost__c)/100)).setScale(2, RoundingMode.HALF_UP);
	                    }
	                    if(optionFeeRec.Product__r.Type__c == 'Deal Product') {
                                unitDealProductCost += cost;
	                    } else if(optionFeeRec.Product__r.Type__c == 'Warranty Plan') {
                                unitWarrantyProductCost += cost;
	                    } else if(optionFeeRec.Product__r.Type__c == 'Financing Product') {
                                unitFinancingProductCost += cost;
	                    } else if(optionFeeRec.Product__r.Type__c == 'Third Party') {
                                unitThirdPartyProductCost += cost;
	                    }
	                    cost = null;
	                }
	            } else if(optionFeeRec.Labour_Code__c != null) {
                        unitLabourCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
	     	    } else if(optionFeeRec.Part__c != null) {
	            	if(String.isNotBlank(optionFeeRec.Part__r.Part_Type__c) && optionFeeRec.Part__r.Part_Type__c == 'Merchandise') {
                            unitMerchCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
	            	} else {
                            unitPartCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                        }
	            	}
	            }
                unitPartCost = unitPartCost.setScale(2, RoundingMode.HALF_UP);
                unitMerchCost = unitMerchCost.setScale(2, RoundingMode.HALF_UP);
                unitLabourCost = unitLabourCost.setScale(2, RoundingMode.HALF_UP);
                unitSubletCost = unitSubletCost.setScale(2, RoundingMode.HALF_UP);
                unitFeeCost = unitFeeCost.setScale(2, RoundingMode.HALF_UP);
                unitWarrantyProductCost = unitWarrantyProductCost.setScale(2, RoundingMode.HALF_UP);
                unitDealProductCost = unitDealProductCost.setScale(2, RoundingMode.HALF_UP);
                unitThirdPartyProductCost = unitThirdPartyProductCost.setScale(2, RoundingMode.HALF_UP);
                if(skuDealItemRecMap.containsKey(dealItemId)) {
                    Deal_Item__c dealItemRec = skuDealItemRecMap.get(dealItemId);
                    dealItemRec.Unit_Option_Cost__c = (unitPartCost + unitMerchCost + unitLabourCost + unitSubletCost + unitFeeCost + 
                    unitWarrantyProductCost + unitDealProductCost + unitThirdPartyProductCost).setScale(2, RoundingMode.HALF_UP);
	        }
                partCost += unitPartCost;
                merchCost += unitMerchCost;
                labourCost += unitLabourCost;
                subletCost += unitSubletCost;
                feeCost += unitFeeCost;
                warrantyProductCost += unitWarrantyProductCost;
                dealProductCost += unitDealProductCost;
                thirdPartyProductCost += unitThirdPartyProductCost;
            }
	        
	        //COMMISSION COST
	        commissionCost = (dealList[0].Deal_Commission__c != null) ? dealList[0].Deal_Commission__c.setScale(2, RoundingMode.HALF_UP) : 0;
	        
	        dealList[0].Total_Unit_Cost__c = unitCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_TradeIn_Cost__c = tradeInCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Part_Cost__c = partCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Merch_Cost__c = merchCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Ttoal_Labour_Cost__c = labourCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Sublet_Cost__c = subletCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Fee_Cost__c = feeCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Warranty_Product_Cost__c = warrantyProductCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Deal_Product_Cost__c = dealProductCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Financing_Product_Cost__c = financingProductCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Third_Party_Product_Cost__c = thirdPartyProductCost.setScale(2, RoundingMode.HALF_UP);
	        dealList[0].Total_Commission_Cost__c = commissionCost.setScale(2, RoundingMode.HALF_UP);
	        
            DMLUtility.updateSobjectList('Deal__c', dealList);
            DealItemTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Deal_Item__c', skuDealItemRecMap.values());
            DMLUtility.updateSobjectList('Deal_Item__c', dealItemForConsignList);
            DealItemTriggerHelper.isForceStopTrigger = false;
    	}
    }
    
    public static List<COHeader> getDealItemInternalServiceStatus(String dealId) {
    	List<Deal_Item__c> dealItemList = [SELECT Customer_Owned_Unit__c FROM Deal_Item__c WHERE Deal__r.Id =: dealId AND Type__c = 'Unit'];
    	set<Id> customerOwnedUnitIds = new set<Id>();
    	for(Deal_Item__c dealItemRec : dealItemList) {
    		customerOwnedUnitIds.add(dealItemRec.Customer_Owned_Unit__c);
    	}
    	List<Service_Order_Header__c> serviceOrderHeaderList = [SELECT SO_Status__c, Invoice_Number__c, CO_Header__r.Id,CO_Header__r.Name FROM Service_Order_Header__c where Customer_Owned_Unit__r.Id IN: customerOwnedUnitIds AND CO_Header__r.CO_Type__c = 'Internal Service' AND Transaction_Type__r.Type__c != 'Third-Party'];
    	List<COHeader> cOHeaderList = new List<COHeader>();
    	for(Service_Order_Header__c serviceOrderHeaderRec : serviceOrderHeaderList) {
    		if(serviceOrderHeaderRec.Invoice_Number__c == null && serviceOrderHeaderRec.SO_Status__c != ServiceJobUtil.INVOICED) {
    			cOHeaderList.add(new COHeader(serviceOrderHeaderRec.CO_Header__r.Id,serviceOrderHeaderRec.CO_Header__r.Name));
    		}
    	}
    	return cOHeaderList;
    }
    
    private static Decimal getUnitCost(List<Deal_Item__c> dealItemRecList) {
        Decimal totalUnitCost = 0;
        if(dealItemRecList != null && !dealItemRecList.isEmpty()) {
            Set<Id> skuIdSet = new Set<Id>();
            for(Deal_Item__c dealItemRec : dealItemRecList) {
                if(dealItemRec.Customer_Owned_Unit__c != null) skuIdSet.add(dealItemRec.Customer_Owned_Unit__c);
        }
            Map<Id, Decimal> unitIdToJobTotalMap = new Map<Id, Decimal>();
            if(!skuIdSet.isEmpty()) {
                for(Service_Order_Line_Item__c soliRec : [Select Service_Order_Header__r.Customer_Owned_Unit__c, Revenue__c from Service_Order_Line_Item__c 
        							where Service_Order_Header__r.Customer_Owned_Unit__c IN: skuIdSet 
				        			AND Service_Order_Header__r.SO_Status__c != :ServiceJobUtil.INVOICED AND Service_Order_Header__r.Invoice_Number__c = null 
                AND Service_Order_Header__r.Transaction_Type__r.Type__c = 'Stock Unit' 
                AND Revenue__c != null AND Revenue__c != 0]) {

                    if(!unitIdToJobTotalMap.containsKey(soliRec.Service_Order_Header__r.Customer_Owned_Unit__c)) {
                        unitIdToJobTotalMap.put(soliRec.Service_Order_Header__r.Customer_Owned_Unit__c, 0);
		}
                    Decimal total = unitIdToJobTotalMap.get(soliRec.Service_Order_Header__r.Customer_Owned_Unit__c);
                    unitIdToJobTotalMap.put(soliRec.Service_Order_Header__r.Customer_Owned_Unit__c, (total + (soliRec.Revenue__c)));
    }
            }
            for(Deal_Item__c dealItemRec : dealItemRecList) {
                Decimal unitCost = 0;
                if(dealItemRec.Customer_Owned_Unit__c != null) {
                    if(dealItemRec.Customer_Owned_Unit__r.Total_Cost__c != null) {
                        unitCost += dealItemRec.Customer_Owned_Unit__r.Total_Cost__c;
                    }
                    if(unitIdToJobTotalMap.containsKey(dealItemRec.Customer_Owned_Unit__c)) {
                        unitCost += unitIdToJobTotalMap.get(dealItemRec.Customer_Owned_Unit__c);
                    }
                    dealItemRec.Unit_Cost__c = unitCost.setScale(2, RoundingMode.HALF_UP);
                    totalUnitCost += dealItemRec.Unit_Cost__c;
                }
            }
        }
        return totalUnitCost;
    }
    
    public static void createFirstDummyUnit(String dealId) {
        Deal_Item__c dealItemRec = new Deal_Item__c(
        	Deal__c = dealId, 
        	Type__c = 'Unit',
        	Name__c = 'Unit 1', 
        	Option_And_Fee_Status__c = Constants.UNCOMIITTED
    	);
    	if(Configurations__c.getInstance().Default_Tax_on_Unit__c != null) {
            dealItemRec.Taxable__c = true;
            dealItemRec.Applicable_Tax__c = Configurations__c.getInstance().Default_Tax_on_Unit__c;
        } else {
            List<Sales_Tax__c> salesTaxList = [SELECT Id FROM Sales_Tax__c WHERE default__c = true];
            if(salesTaxList.size() > 0) {
                dealItemRec.Taxable__c = true;
                dealItemRec.Applicable_Tax__c = salesTaxList[0].Id;
            }
        }
        if(String.isNotBlank(dealItemRec.Type__c) && dealItemRec.Type__c.equalsIgnoreCase('Unit')) {
            dealItemRec.Unit_Tax_Applicable_On__c = GeneralConfiguration.getConfigurations().Deal_Unit_Options_Taxed_Like_Unit__c;
        }
        if(AccessControl.ifObjectFieldIsCreateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        DealItemTriggerHelper.isForceStopTrigger = true;
        insert dealItemRec;
        DealItemTriggerHelper.isForceStopTrigger = false;
    }
    
    public static String saveTemporaryUnit(String dealId, String jSONString) {
    	return saveTemporaryUnit(dealId, DealItem.parse(jSONString));
    }
    
    public static String saveTemporaryUnit(String dealId, DealItem dealItemObj) {
        dealItemObj.Type = Constants.DEAL_ITEM_TYPE_UNIT;
        
        Deal_Item__c dealItemRec = setDealItemValues(dealItemObj, dealId);
        if(dealItemObj.Make == null && String.isNotBlank(dealItemObj.MakeName)) {
            Unit_Make__c makeRec = new Unit_Make__c(Name = dealItemObj.MakeName);
            DMLUtility.insertSobjectList('Unit_Make__c', makeRec);
            dealItemRec.Unit_Make__c = makeRec.Id;
        }
        if(dealItemObj.Model == null && String.isNotBlank(dealItemObj.ModelName)) { 
            Unit_Model__c modelRec = new Unit_Model__c(Name__c = dealItemObj.ModelName, Unit_Make__c = dealItemRec.Unit_Make__c);
            DMLUtility.insertSobjectList('Unit_Model__c', modelRec);
            dealItemRec.Unit_Model__c = modelRec.Id;
        }
        
        if(dealItemObj.SubModel == null && String.isNotBlank(dealItemObj.SubModelName)) { 
            Unit_Sub_Model__c subModelRec = new Unit_Sub_Model__c(Sub_Model_Name__c = dealItemObj.SubModelName, Unit_Model__c = dealItemRec.Unit_Model__c);
            DMLUtility.insertSobjectList('Unit_Sub_Model__c', subModelRec);
            dealItemRec.Sub_Model__c = subModelRec.Id;
        }

        if(dealItemRec.Sub_Model__c != null) {
            List<Unit_Sub_Model__c> subModelList = [SELECT Description__c FROM Unit_Sub_Model__c WHERE Id = :dealItemRec.Sub_Model__c];
            if(subModelList.size() > 0 && subModelList[0].Description__c != null) {
                dealItemRec.Notes__c = subModelList[0].Description__c;
            }
        } 
    
        if(dealItemRec.Notes__c == null && dealItemRec.Unit_Model__c != null ) {
            List<Unit_Model__c> modelList = [SELECT Description__c FROM Unit_Model__c WHERE  Id = :dealItemRec.Unit_Model__c];
            if(modelList.size() > 0 && modelList[0].Description__c != null) {
                dealItemRec.Notes__c = modelList[0].Description__c;
            }
        }
        
        Boolean isAddLinkedFees = true;
        Boolean isUpdateSalesTax = true;
        List<Deal_Item__c> oldDealItemRecList = new List<Deal_Item__c>();
        if(String.isNotBlank(dealItemRec.Id)) {
            oldDealItemRecList = [Select Id, Customer_Owned_Unit__c, Unit_Make__c, Unit_Model__c, Sub_Model__c from Deal_Item__c where Id =: dealItemRec.Id];
            if(oldDealItemRecList.size() > 0 && (String.isNotBlank(oldDealItemRecList[0].Unit_Make__c) || String.isNotBlank(oldDealItemRecList[0].Customer_Owned_Unit__c))) {
                isAddLinkedFees = false;
                isUpdateSalesTax = false;
            }
        }
        
        dealItemRec.Option_And_Fee_Status__c = Constants.UNCOMIITTED;
        if(isUpdateSalesTax) {
        	if(Configurations__c.getInstance().Default_Tax_on_Unit__c != null) {
	            dealItemRec.Taxable__c = true;
	            dealItemRec.Applicable_Tax__c = Configurations__c.getInstance().Default_Tax_on_Unit__c;
	        } else {
	            List<Sales_Tax__c> salesTaxList = [SELECT Id FROM Sales_Tax__c WHERE default__c = true];
	            if(salesTaxList.size() > 0) {
	                dealItemRec.Taxable__c = true;
	                dealItemRec.Applicable_Tax__c = salesTaxList[0].Id;
	            }
	        }
            if(String.isNotBlank(dealItemRec.Type__c) && dealItemRec.Type__c.equalsIgnoreCase('Unit')) {
                dealItemRec.Unit_Tax_Applicable_On__c = GeneralConfiguration.getConfigurations().Deal_Unit_Options_Taxed_Like_Unit__c;
            }
        }
        DMLUtility.upsertSobjectList('Deal_Item__c', dealItemRec);
        
        Boolean isBaseCostPriceChanged = createBaseOptionForTempUnit(dealItemRec, oldDealItemRecList);
        
        if(isAddLinkedFees && String.isNotBlank(dealItemRec.Unit_Make__c)) {
            List<SObject> sObjectListToInsert = COService.addLinkedFee(dealItemRec.Id, dealId, 'Deal');
            if(sObjectListToInsert != null) {
                if(!AccessControl.ifObjectFieldIsCreateable('CO_Line_Item__c')){throw new BlackPurlException('CO_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                if(!AccessControl.ifObjectFieldIsCreateable('Service_Order_Line_Item__c')){throw new BlackPurlException('Service_Order_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                if(!AccessControl.ifObjectFieldIsCreateable('Option_Fee__c')){throw new BlackPurlException('Option_Fee__c' + DMLUtility.NOT_CREATABLE);}
                insert sObjectListToInsert;
            }
        }
        
        updateStatusForDeal(dealId);
        return  System.JSON.serialize(new Map<String, String> {
                                                                'IsBaseCostPriceChanged' => String.valueOf(isBaseCostPriceChanged),
                                                                'UnitId' =>  dealItemRec.Id,
                                                                'Make' =>  dealItemRec.Unit_Make__c,
                                                                'Model' =>  dealItemRec.Unit_Model__c,
                                                                'SubModel' =>  dealItemRec.Sub_Model__c
                                                            });
    }
    
    public static String getDefaultTaxOnDUPC() {
    	String defaultSalesTaxId = Configurations__c.getInstance().Default_Tax_on_Unit__c;
        if(String.isNotBlank(defaultSalesTaxId)) {
            return defaultSalesTaxId;
        } else {
            List<Sales_Tax__c> defaultSalesTaxList = [select Id, Rate__c from Sales_Tax__c where Default__c = true];
            if(defaultSalesTaxList.size() > 0) {
                return defaultSalesTaxList[0].Id;
            }
        }
        return null;
    }

    private static Boolean createBaseOptionForTempUnit(Deal_Item__c newDealItemRec, List<Deal_Item__c> oldDealItemRecList) {
        Deal_Item__c oldDealItemRec = (oldDealItemRecList!= null && oldDealItemRecList.size() > 0) ? oldDealItemRecList[0] : null;
    	if(String.isBlank(newDealItemRec.Unit_Make__c)) {
    		return false;
    	}
    	
    	Boolean isBaseCostPriceChanged = false;
    	if(isUpdateBasePriceAndCost(newDealItemRec, oldDealItemRec)) {
    		List<Deal_Unit_Price_Cost__c> dupcList = [SELECT Id FROM Deal_Unit_Price_Cost__c WHERE Type__c = 'Base' AND Deal_Item__c =: newDealItemRec.Id];
    		isBaseCostPriceChanged = true;
    		Deal_Unit_Price_Cost__c baseDUPCRec;
    		if(dupcList != null && dupcList.size() > 0) {
    			baseDUPCRec = dupcList[0];
    		} else {
    			baseDUPCRec = new Deal_Unit_Price_Cost__c(Deal_Item__c = newDealItemRec.Id, Item_Description__c = Constants.BASE_UNIT, 
    													Name = Constants.BASE_UNIT, Type__c = 'Base', Qty__c = 1, Cost__c = 0, Price__c = 0,
    													Applicable_Tax__c = getDefaultTaxOnDUPC());
    		}
    													
		    UnitPricingService.UnitPriceAndCostWrapper upcObj = UnitPricingService.getBasePriceAndCostByMMSId(newDealItemRec.Unit_Make__c, newDealItemRec.Unit_Model__c, newDealItemRec.Sub_Model__c);
		    baseDUPCRec.Cost__c = upcObj.Cost != null ? upcObj.Cost : 0;
		    baseDUPCRec.Price__c = upcObj.Price != null ? upcObj.Price : 0;
		    if(GeneralConfiguration.getTaxIncludingPricing()) {
	            baseDUPCRec.Price_When_Tax_Included__c = baseDUPCRec.Price__c;
	        }
	    	
            DMLUtility.upsertSobjectList('Deal_Unit_Price_Cost__c', baseDUPCRec);
    	}
    	return isBaseCostPriceChanged;
    }
    
    private static Boolean isUpdateBasePriceAndCost(Deal_Item__c newDealItemRec, Deal_Item__c oldDealItemRec) {
    	return (oldDealItemRec == null || (oldDealItemRec.Sub_Model__c != newDealItemRec.Sub_Model__c || oldDealItemRec.Unit_Model__c != newDealItemRec.Unit_Model__c || 
    		oldDealItemRec.Unit_Make__c != newDealItemRec.Unit_Make__c));
    }
    
    public static List<DealWrapper.PriceAndCostOptionWrapper> getPriceAndCostOptionsListForTempUnit(String dalItemId) {
    	if(!AccessControl.ifObjectFieldIsAccessible('Deal_Unit_Price_Cost__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
    	List<Deal_Unit_Price_Cost__c> dupcList = [SELECT Id, Type__c, Item_Description__c, Total_Cost__c, Total_Price__c, Factory_Option__c, Sales_Tax_Percentage__c 
    												FROM Deal_Unit_Price_Cost__c WHERE Deal_Item__c =: dalItemId AND (Type__c = 'Base' OR Type__c = 'Factory')];
    	List<DealWrapper.PriceAndCostOptionWrapper> dupcObjList = new List<DealWrapper.PriceAndCostOptionWrapper>();
    	for(Deal_Unit_Price_Cost__c dupcRec: dupcList) {
    		dupcObjList.add(new DealWrapper.PriceAndCostOptionWrapper(dupcRec));
    	}
    	return dupcObjList;
    }
    
    public static String savePriceAndCostOptionForTempUnit(String dealItemId, String jsonString) {
    	List<DealWrapper.PriceAndCostOptionWrapper> dupcObjList = (List<DealWrapper.PriceAndCostOptionWrapper>) System.JSON.deserialize(jsonString, List<DealWrapper.PriceAndCostOptionWrapper>.class);
    	List<Deal_Unit_Price_Cost__c> dupcListToUpsert = new List<Deal_Unit_Price_Cost__c>();
        Map<Id, DealWrapper.PriceAndCostOptionWrapper> mapIdToDealUPCObj = new Map<Id, DealWrapper.PriceAndCostOptionWrapper>();
    	
    	for(DealWrapper.PriceAndCostOptionWrapper dupcObj: dupcObjList) {
            if(dupcObj.Id != null) {
                mapIdToDealUPCObj.put(dupcObj.Id, dupcObj);
            }
        }
    	for(Deal_Unit_Price_Cost__c depcRec : [SELECT Id, Unit_Price_Cost__c, Unit_Price_Cost__r.Customer_Owned_Unit__c FROM Deal_Unit_Price_Cost__c WHERE Id = :mapIdToDealUPCObj.keySet()]) {
            if(depcRec.Unit_Price_Cost__c != null) {
                mapIdToDealUPCObj.get(depcRec.Id).UpcId = depcRec.Unit_Price_Cost__c;
            }
        }
    	for(DealWrapper.PriceAndCostOptionWrapper dupcObj: dupcObjList) {
    		dupcListToUpsert.add(setPriceAndCostOptionFields(dealItemId, dupcObj));
    	}
    	
    	if(dupcListToUpsert.size() > 0) {
            return insertDealUPCAndCreateUPC(dupcListToUpsert, dealItemId);
    	}
    	return null;
    }
    
    private static Deal_Unit_Price_Cost__c setPriceAndCostOptionFields(String dealItemId, DealWrapper.PriceAndCostOptionWrapper dupcObj) {
    	Deal_Unit_Price_Cost__c dupcRec = new Deal_Unit_Price_Cost__c();
    	dupcRec.Deal_Item__c = dealItemId;
    	dupcRec.Id = dupcObj.Id;
    	dupcRec.Type__c = dupcObj.Type;
    	dupcRec.Price__c = dupcObj.TotalPrice;
    	dupcRec.Cost__c = dupcObj.TotalCost;
    	dupcRec.Qty__c = 1;
    	dupcRec.Item_Description__c = dupcObj.ItemDescription;
    	dupcRec.Factory_Option__c = dupcObj.FactoryOptionId;
        dupcRec.Unit_Price_Cost__c = dupcObj.UpcId;
    	if(String.isNotBlank(dupcRec.Item_Description__c) && dupcRec.Item_Description__c.length() > 80) {
        	dupcRec.Name = dupcRec.Item_Description__c.subString(0, 80);
        } else {
        	dupcRec.Name = dupcRec.Item_Description__c;
        }
        
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            dupcRec.Price_When_Tax_Included__c = dupcRec.Price__c;
            if(String.isNotBlank(dupcRec.Id)) {
            	List<Deal_Unit_Price_Cost__c> dupcList = [SELECT Sales_Tax_Percentage__c FROM Deal_Unit_Price_Cost__c WHERE Id = :dupcRec.Id];
            	dupcList[0].Sales_Tax_Percentage__c = dupcList[0].Sales_Tax_Percentage__c != null ? dupcList[0].Sales_Tax_Percentage__c : 0;
            	dupcRec.Price__c = (dupcRec.Price_When_Tax_Included__c / (1 + dupcList[0].Sales_Tax_Percentage__c / 100));
            } else {
            	dupcRec.Applicable_Tax__c = getDefaultTaxOnDUPC();
            }
        }
    	return dupcRec;
    }
    
    public static String deletePriceAndCostOptionForTempUnit(String dupcId) {
    	if(!AccessControl.ifObjectIsDeletable('Deal_Unit_Price_Cost__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
    	List<Deal_Unit_Price_Cost__c> dealUPCList = [SELECT Id, Unit_Price_Cost__c FROM Deal_Unit_Price_Cost__c WHERE Id = :dupcId];
        if(dealUPCList.size() > 0) {
            DMLUtility.deleteSobjectList('Deal_Unit_Price_Cost__c', dealUPCList);
            DMLUtility.deleteSobjectList('Unit_Price_Cost__c', new Unit_Price_Cost__c(Id = dealUPCList[0].Unit_Price_Cost__c));
        }
    	return 'Success';
    }
    
    public static String updateStampDutyWhenRideawayPricingEnabled(String dealItemId, String stampDutyTotal) {
    	Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        List<Deal_Unit_Price_Cost__c> dealUnitPriceList = [SELECT Id, Deal_Item__r.Rideaway_Pricing_Total__c, Deal_Item__r.Stamp_Duty_Total__c, Sales_Tax_Percentage__c,Type__c, Price__c, Total_Price__c, Price_When_Tax_Included__c FROM Deal_Unit_Price_Cost__c where Type__c = 'Base' and Deal_Item__c =: dealItemId Limit 1];
	    if(dealUnitPriceList.size() > 0){
	        if(isTaxIncludingPricing) {
                Decimal stampDutyPrevValue = dealUnitPriceList[0].Deal_Item__r.Stamp_Duty_Total__c != null ? dealUnitPriceList[0].Deal_Item__r.Stamp_Duty_Total__c : 0;
                if(Decimal.valueOf(stampDutyTotal) > dealUnitPriceList[0].Deal_Item__r.Rideaway_Pricing_Total__c || (Decimal.valueOf(stampDutyTotal) - stampDutyPrevValue) > dealUnitPriceList[0].Price_When_Tax_Included__c){ throw new BlackPurlException('Stamp Duty can not be greater than Rideaway Pricing Total and Base Unit Price');}
		        if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		        update new Deal_Item__c(Id = dealItemId, Stamp_Duty_Total__c = Decimal.valueOf(stampDutyTotal), Is_Override_Stamp_Duty__c = true);
		        dealUnitPriceList[0].Price_When_Tax_Included__c -= (Decimal.valueOf(stampDutyTotal) - stampDutyPrevValue);
		        dealUnitPriceList[0].Price__c = (dealUnitPriceList[0].Price_When_Tax_Included__c / (1 + dealUnitPriceList[0].Sales_Tax_Percentage__c / 100));
		        update dealUnitPriceList[0];	
	        }
	    }   
        return getDealItemDetails(dealItemId);
    }
    
    public static String getBillOfSaleFormData(String dealId) {
    	List<Deal__c> dealList = [Select Sales_Tax_Total__c, Deal_Total__c, Status__c, Invoice_Number__c, Invoice_Number__r.Total_Amount_Except_Charge_Account__c, 
                					CO_Header__c, CO_Header__r.Total_Deposit_And_Payment__c, Pre_Tax_Unit_Price_And_Cost_Total__c, Stamp_Duty_Total__c, Lien_Payout_Total__c, 
                					(Select Price__c, Qty__c, Product__c, Product__r.Type__c, Fee__c, Fee__r.Assigned_Tag_1__c, Fee__r.Assigned_Tag_2__c, Fee__r.Code__c 
                						from Options_Fees__r), 
									(Select Type__c, Agreed_Value__c from Deal_Items__r) 
                						from Deal__c where Id =: dealId];
    	if(dealList.size() > 0) {
    		return system.JSON.serialize(new DealWrapper.BillOfSaleFormWrapper(dealList[0]));
    	}
    	return 'Deal not found';
    }
    
    public static void removeDealFinancing(String dealId, String dealFinanceId) {
        List<Sobject> SobjectListToDelete = new List<Sobject>();
        if(String.isNotBlank(dealId) && String.isNotBlank(dealFinanceId)){
            List<Deal__c> dealList = [select Id, Type__c from deal__c where id =: dealId];
            if(dealList.size() == 1){
                dealList[0].Type__c = 'Cash Deal';
                DMLUtility.updateSobjectList('Deal__c', dealList);
            }
            
            Map<String, Boolean> optionNameToOptionValueMap = isDealInvoiceable(dealId);
            if(optionNameToOptionValueMap.get('Invoiceable')) {
                List<CO_Invoice_Item__c> coInvItemList = [Select Id, isActive__c, Is_Invoiceable__c from CO_Invoice_Item__c where Deal__c =: dealId AND isActive__c = false AND Is_Invoiceable__c = false];  
                if(coInvItemList.size() > 0) {
                    coInvItemList[0].isActive__c = optionNameToOptionValueMap.get('Active');
                    coInvItemList[0].Is_Invoiceable__c = optionNameToOptionValueMap.get('Invoiceable');
                }
                DMLUtility.updateSobjectList('CO_Invoice_Item__c', coInvItemList[0]);
            }
            
            List<Deal_Finance__c> dealFinanceList = [SELECT Id,(select Id, deal_finance__C from F_I_Products__r), 
                                                    (Select Id from CO_Forms__r) from deal_finance__c where id =: dealFinanceId];
            if(dealFinanceList.size() == 1){
                 SobjectListToDelete.addAll((List<SObject>) dealFinanceList[0].F_I_Products__r);
                 SobjectListToDelete.addAll((List<SObject>) dealFinanceList[0].CO_Forms__r);
                 SobjectListToDelete.add(dealFinanceList[0]);
                 
                 if(!AccessControl.ifObjectIsDeletable('F_I_Product__c')){throw new BlackPurlException('F_I_Product__c' + DMLUtility.NOT_DELETABLE);}
                 if(!AccessControl.ifObjectIsDeletable('CO_Form__c')){throw new BlackPurlException('CO_Form__c' + DMLUtility.NOT_DELETABLE);}
                 if(!AccessControl.ifObjectIsDeletable('Deal_Finance__c')){throw new BlackPurlException('Deal_Finance__c' + DMLUtility.NOT_DELETABLE);}
                 delete SobjectListToDelete;
            }
        }
    }
    
    public static String getUnitId(Customer_Owned_Unit__c unitRec) {
    	String item = '';
    	if(String.isNotBlank(unitRec.Stock_Id__c)) {
    		item = unitRec.Stock_Id__c;
    	} else if(String.isNotBlank(unitRec.Unit_Id__c)) {
    		item = unitRec.Unit_Id__c;
    	}
    	return item;
    }

    public static Map<String, List<Unit_Price_Cost__c>> getUnitIdToUPCListMap(Set<Id> unitIdSet) {
        Map<String, List<Unit_Price_Cost__c>> unitIdToUPCListMap = new  Map<String, List<Unit_Price_Cost__c>>();
        
        for(Unit_Price_Cost__c unpRec : SOQLUtil.getUnitPriceCostDetailsByUnitIds(unitIdSet)) {
            if(!unitIdToUPCListMap.containsKey(unpRec.Customer_Owned_Unit__c))  {
                unitIdToUPCListMap.put(unpRec.Customer_Owned_Unit__c, new List<Unit_Price_Cost__c>());
            }
            unitIdToUPCListMap.get(unpRec.Customer_Owned_Unit__c).add(unpRec);
        }
    	return unitIdToUPCListMap;
    }

    public static String getUnitStatusByUnitAnddealItemId(String unitId, String dealItemId, String unitType) {
        List<Deal_Item__c> dealItemList = [Select Deal__r.Status__c, Customer_Owned_Unit__r.Status__c FROM Deal_Item__c where Id !=: dealItemId AND Customer_Owned_Unit__c =: unitId];
        String unitStatus = unitType.equalsIgnoreCase(Constants.UNIT_TYPE_COU) ? 'Active' : 'Available';
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(dealItemRec.Deal__r.Status__c == 'In Progress' || dealItemRec.Deal__r.Status__c == 'Approved') {
                unitStatus = 'Reserved';
            } else if (dealItemRec.Deal__r.Status__c == 'Invoiced') {
                unitStatus = unitType.equalsIgnoreCase(Constants.UNIT_TYPE_COU) ? 'Transferred' : 'Sold';
                break;
            }
        }
    	return unitStatus;
    }
	
	public static Boolean hasDealInvoicedPriorToItem(Deal__c dealRec, DateTime itemInvoicedDateTime) {
    	Boolean isDealInvoicedPrior = false;
    	if(dealRec != null) {
    		if(dealRec.Reopen_Invoice_Created_Date__c != null) {
    			isDealInvoicedPrior = dealRec.Reopen_Invoice_Created_Date__c <= itemInvoicedDateTime;
    		} else if(dealRec.Invoice_Number__c != null) {
    			isDealInvoicedPrior = dealRec.Invoice_Number__r.Closed_Invoice_Date__c <= itemInvoicedDateTime;
    		}
		}
		return isDealInvoicedPrior;
    }
    
    public static Boolean hasOptionFulfilledPriorToDeal(Option_Fee__c optionAndFeeRec, DateTime dealInvoicedDateTime) {
    	Boolean isOptionFulfilledPrior = false;
    	if(optionAndFeeRec.CO_Line_Item__c != null) {
    		if(optionAndFeeRec.CO_Line_Item__r.Actual_Invoice_Date_Time__c != null) {
    			isOptionFulfilledPrior = optionAndFeeRec.CO_Line_Item__r.Actual_Invoice_Date_Time__c < dealInvoicedDateTime;
    		} else if(optionAndFeeRec.CO_Line_Item__r.Invoice_Number__c != null) {
    			isOptionFulfilledPrior = optionAndFeeRec.CO_Line_Item__r.Invoice_Number__r.Closed_Invoice_Date__c < dealInvoicedDateTime;
    		}
		} else if(optionAndFeeRec.Service_Order_Line_Item__c != null) {
			if(optionAndFeeRec.Service_Order_Line_Item__r.Service_Order_Header__r.Actual_Invoice_Date_Time__c != null) {
    			isOptionFulfilledPrior = optionAndFeeRec.Service_Order_Line_Item__r.Service_Order_Header__r.Actual_Invoice_Date_Time__c < dealInvoicedDateTime;
    		} else if(optionAndFeeRec.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c != null) {
    			isOptionFulfilledPrior = optionAndFeeRec.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.Closed_Invoice_Date__c < dealInvoicedDateTime;
    		}
		}
    	return isOptionFulfilledPrior;
    }
    
    public static String saveDealNotes(String dealId, List<String> notesList) {
        try {
            if(String.isBlank(dealId)) return System.JSON.serialize(new ResponseWrapper(400, 'Invalid deal Id'));
            Deal__c dealRecToUpdate = new deal__c(Id = dealId, Notes_For_Customer__c = COService.convertListIntoString(notesList));
            DealTriggerHelper.isForceStopTrigger = true;
            update dealRecToUpdate;
            DealTriggerHelper.isForceStopTrigger = false;
            return System.JSON.serialize(new ResponseWrapper(200, 'Success'));
        } catch(Exception e) {
            return System.JSON.serialize(new ResponseWrapper(400, e.getMessage()));
        }
    }

    public static void updateConfirmedSaleDate(List<Deal__c> dealListToUpdate, Map<Id, Deal__c> dealOldMap, Map<String, Decimal> dealIdToDealDepositMap, Boolean isUpdateDeal) {
        for(Deal__c dealRec: dealListToUpdate) {
            if(dealRec.Confirmed_Sale_Date__c == null) {
                if(dealOldMap != null) {
                    if(dealOldMap.get(dealRec.Id).Status__c == 'Quotation' && (dealRec.Status__c == 'In Progress' || dealRec.Status__c == 'Approved')) {
                        dealRec.Confirmed_Sale_Date__c = Date.today();
                    }
                } else {
                    if(dealIdToDealDepositMap.containsKey(dealRec.Id) && dealIdToDealDepositMap.get(dealRec.Id) != 0 && dealRec.CO_Deposits__r != null && 
                        dealRec.CO_Deposits__r.size() > 0) {
                        dealRec.Confirmed_Sale_Date__c = dealRec.CO_Deposits__r[0].Payment_Date__c;
                    }
                }
            } else {
                if(dealRec.Status__c == 'Quotation' && (!dealIdToDealDepositMap.containsKey(dealRec.Id) || (dealIdToDealDepositMap.containsKey(dealRec.Id) && 
                    dealIdToDealDepositMap.get(dealRec.Id) == 0)) && (dealOldMap == null || (dealOldMap != null && 
                    (dealOldMap.get(dealRec.Id).Status__c == 'In Progress' || dealOldMap.get(dealRec.Id).Status__c == 'Approved')))) {
                    dealRec.Confirmed_Sale_Date__c = null;
                }
            }
        }

        if(isUpdateDeal && dealListToUpdate.size() > 0) {
            DealTriggerHelper.isForceStopTrigger = true;
            update dealListToUpdate;
            DealTriggerHelper.isForceStopTrigger = false;
        }
    }

    public static Map<String, Decimal> getDealIdToDepositAmountMap(List<CO_Deposit__c> coDepositList) {
        Map<String, Decimal> dealIdToDepositAmountMap = new Map<String, Decimal>();
        for(CO_Deposit__c coDepositRec: coDepositList) {
            if(!dealIdToDepositAmountMap.containsKey(coDepositRec.Deal__c)) {
                dealIdToDepositAmountMap.put(coDepositRec.Deal__c, 0);
            }
            Decimal totalDeposit = dealIdToDepositAmountMap.get(coDepositRec.Deal__c) + (coDepositRec.Amount__c != null ? coDepositRec.Amount__c : 0);
            dealIdToDepositAmountMap.put(coDepositRec.Deal__c, totalDeposit);
        }
        return dealIdToDepositAmountMap;
	}

    public static Boolean isOptionCommitable(Option_Fee__c optionRec) {
        if(optionRec.Deal_Kit_Header__c != null || optionRec.Part__c != null || optionRec.Labour_Code__c != null || 
        (optionRec.Product__c != null && optionRec.Product__r.Type__c != null && optionRec.Product__r.Type__c.equalsIgnoreCase('Sublet'))) {
            return true;
        }
        return false;
    }

    public static Boolean isOptionCommitted(Option_Fee__c optionRec) {
        if(optionRec != null && (optionRec.CO_Line_Item__c != null || optionRec.Service_Order_Line_Item__c != null || (optionRec.Status__c != null && 
        (optionRec.Status__c.equalsIgnoreCase(Constants.COMMITTED) || optionRec.Status__c.equalsIgnoreCase(Constants.FULFILLED))))) {
            return true;
        }
        return false;
    }

    public static String getActiveDealServiceId(Deal_Item__c dealItem) {
        String activeDSId;
        Set<String> completedSOStatusSet = new Set<String>(ServiceJobUtil.invoiceableStatusSet);
        completedSOStatusSet.add(ServiceJobUtil.INVOICED);
        for(Service_Order_Header__c soRec : dealItem.Service_Order_Headers__r) {
            if((String.isBlank(soRec.SO_Status__c) || !completedSOStatusSet.contains(soRec.SO_Status__c)) && 
            soRec.Invoice_Number__c == null) {
                activeDSId =  soRec.Id;
                break;
            }
        }
        return activeDSId;
    }

    public static String saveTemporaryOrderUnit(String dealItemId, String jSONString) {
        UnitOrderingWrapper.UnitDetailsWrapper unitObj = (UnitOrderingWrapper.UnitDetailsWrapper) System.JSON.deserialize(jSONString, UnitOrderingWrapper.UnitDetailsWrapper.class);    	
        String unitId = unitOrderingService.saveUnitDetails(jSONString);
        List<Customer_Owned_Unit__c> customerOwnedUnitList = [SELECT Unit_Make__c, Unit_Model__c, Sub_Model__c, Unit_Id__c FROM Customer_Owned_Unit__c WHERE Id = :unitId LIMIT 1];
        Boolean isBaseCostPriceChanged = false;
        if(String.isBlank(unitObj.UnitInfo.Id)) {
            isBaseCostPriceChanged = createBaseUPCAndDealUPC(unitId, dealItemId, unitObj);
            List<SObject> sObjectListToInsert = COService.addLinkedFee(dealItemId, unitObj.UnitInfo.DealId, 'Deal');
            if(sObjectListToInsert != null) DMLUtility.insertSobjectList('Option_Fee__c', sObjectListToInsert);
        }
        return  System.JSON.serialize(new Map<String, String> {
            'UnitId' =>  unitId,
            'IsBaseCostPriceChanged' => String.valueOf(isBaseCostPriceChanged),
            'Make' =>  customerOwnedUnitList[0].Unit_Make__c,
            'Model' =>  customerOwnedUnitList[0].Unit_Model__c,
            'SubModel' =>  customerOwnedUnitList[0].Sub_Model__c,
            'UnitNumber' => customerOwnedUnitList[0].Unit_Id__c
        });
    }

    public static Boolean createBaseUPCAndDealUPC(String unitId, String dealItemId, UnitOrderingWrapper.UnitDetailsWrapper unitObj) {
        Boolean isBaseCostPriceChanged = false;
        // Create Base UPC for order unit
        Unit_Price_Cost__c unitPriceAndCostRec = new Unit_Price_Cost__c();
        unitPriceAndCostRec.Id = null;
        unitPriceAndCostRec.Item_Description__c = Constants.BASE_UNIT;
        unitPriceAndCostRec.Type__c = 'Base';
        unitPriceAndCostRec.Qty__c = 1;
        unitPriceAndCostRec.Factory_Option__c = null;
        unitPriceAndCostRec.Taxable__c = true;
        UnitWrapper.PriceAndCostTrackingWrapper priceAndCost = new UnitWrapper.PriceAndCostTrackingWrapper(unitPriceAndCostRec);
        Unit_Price_Cost__c upcRec = unitOrderingService.setUnitPriceAndCostFields(unitId, priceAndCost);
    
        UnitPricingService.UnitPriceAndCostWrapper upcObj = UnitPricingService.getBasePriceAndCostByMMSId(unitObj.UnitInfo.Make, unitObj.UnitInfo.Model, unitObj.UnitInfo.SubModel);
        upcRec.Cost__c = upcObj.Cost != null ? upcObj.Cost : 0;
        upcRec.Price__c = upcObj.Price != null ? upcObj.Price : 0;
        upcRec.Total_Price__c = upcRec.Price__c * upcRec.Qty__c;
        upcRec.Total_Cost__c = upcRec.Cost__c * upcRec.Qty__c;
        DMLUtility.insertSobjectList('Unit_Price_Cost__c', upcRec);
    
        List<Deal_Item__c> dealItemList = [SELECT Customer_Owned_Unit__c FROM Deal_Item__c WHERE Id = :dealItemId LIMIT 1];
        if(dealItemList.size() > 0) {
            // update ordered unit on Deal Item
            dealItemList[0].Customer_Owned_Unit__c = unitId;
            if(unitObj.UnitInfo != null && String.isNotBlank(unitObj.UnitInfo.ApplicableStampDutyCalId)) {
                dealItemList[0].Stamp_Duty_Calculators__c = unitObj.UnitInfo.ApplicableStampDutyCalId;
            }
            DMLUtility.updateSobjectList('Deal_Item__c', dealItemList);

            // Crate Deal UPC
            Deal_Unit_Price_Cost__c baseDUPCRec = new Deal_Unit_Price_Cost__c(Deal_Item__c = dealItemList[0].Id, Item_Description__c = Constants.BASE_UNIT, 
                                                    Name = Constants.BASE_UNIT, Type__c = 'Base', Qty__c = 1, Cost__c = 0, Price__c = 0,
                                                    Applicable_Tax__c = getDefaultTaxOnDUPC(), Unit_Price_Cost__c = upcRec.Id);
            baseDUPCRec.Cost__c = upcObj.Cost != null ? upcObj.Cost : 0;
            baseDUPCRec.Price__c = upcObj.Price != null ? upcObj.Price : 0;
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                baseDUPCRec.Price_When_Tax_Included__c = upcRec.Price__c;
            }
            DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', baseDUPCRec);
            
            isBaseCostPriceChanged = true;
        }
        return isBaseCostPriceChanged;
    }

    public static Map<Id, Unit_Price_Cost__c> createUPCFromDealUPC(List<Deal_Unit_Price_Cost__c> dealUPCList, Id unitId) {
        Map<Id, Unit_Price_Cost__c> dealUPCIdToUPCMap = new Map<Id, Unit_Price_Cost__c>();
        for(Deal_Unit_Price_Cost__c dealUPC : dealUPCList) {
            Unit_Price_Cost__c unitPriceCostRec = new Unit_Price_Cost__c();
            unitPriceCostRec.Id = dealUPC.Unit_Price_Cost__c;
            unitPriceCostRec.Customer_Owned_Unit__c = unitId; 
            unitPriceCostRec.Item_Description__c = dealUPC.Item_Description__c;
            unitPriceCostRec.Type__c = dealUPC.Type__c;
            unitPriceCostRec.Qty__c = dealUPC.Qty__c;
            unitPriceCostRec.Price__c = dealUPC.Price__c;
            unitPriceCostRec.Total_Price__c = dealUPC.Price__c;
            unitPriceCostRec.Cost__c = dealUPC.Cost__c;
            unitPriceCostRec.Total_Cost__c = dealUPC.Cost__c;
            unitPriceCostRec.Factory_Option__c = dealUPC.Factory_Option__c;
            unitPriceCostRec.Applicable_Tax__c = dealUPC.Applicable_Tax__c;
            unitPriceCostRec.Taxable__c = true;
            dealUPCIdToUPCMap.put(dealUPC.Id, unitPriceCostRec);
        }
        return dealUPCIdToUPCMap;
    }

    public static String insertDealUPCAndCreateUPC(List<Deal_Unit_Price_Cost__c> dupcList, String dealItemId) {
        //Insert Deal UPCs
        Map<Id, Unit_Price_Cost__c> dealUPCIdToUPCMap = new Map<Id, Unit_Price_Cost__c>();
        Map<Id, Deal_Unit_Price_Cost__c> dealUPCIdToDealUPCRecMap = new Map<Id, Deal_Unit_Price_Cost__c>();
        DMLUtility.upsertSobjectList('Deal_Unit_Price_Cost__c', dupcList);
        for(Deal_Unit_Price_Cost__c dupcRec: dupcList) {
            dealUPCIdToDealUPCRecMap.put(dupcRec.Id, dupcRec);
        }

        List<Deal_Item__c> dealItemList = [SELECT Customer_Owned_Unit__c FROM Deal_Item__c WHERE Id = :dealItemId LIMIT 1];
        if(dealItemList.size() > 0) {
            // Create UPC from Deal UPC
            dealUPCIdToUPCMap = createUPCFromDealUPC(dupcList, dealItemList[0].Customer_Owned_Unit__c);
            DMLUtility.upsertSobjectList('Unit_Price_Cost__c', dealUPCIdToUPCMap.values());

            // Populate UPC LookUp on Deal UPC
            List<Deal_Unit_Price_Cost__c> dealUPCListToUpdate = new List<Deal_Unit_Price_Cost__c>();
            for(Id dealUPCId : dealUPCIdToUPCMap.keySet()) {
                dealUPCIdToDealUPCRecMap.get(dealUPCId).Unit_Price_Cost__c = dealUPCIdToUPCMap.get(dealUPCId).Id;
                dealUPCListToUpdate.add(dealUPCIdToDealUPCRecMap.get(dealUPCId));
            }
            DMLUtility.updateSobjectList('Deal_Unit_Price_Cost__c', dealUPCListToUpdate);
        }
        return dupcList.size() == 1 ? dupcList[0].Id : null;
    }

    public static String saveUnitStatus(String unitId, String unitStatus) {
        List<Deal_Item__c> dealItemList = [SELECT Id FROM Deal_Item__c WHERE Customer_Owned_Unit__c =: unitId LIMIT 1];
        Customer_Owned_Unit__c unitRec = new Customer_Owned_Unit__c(Id = unitId);
        unitRec.Status__c = unitStatus;
        if(dealItemList.isEmpty()) {
            unitRec.Deal_Item__c = null;
        } else {
            unitRec.Deal_Item__c = ((unitStatus == Constants.REQ_ORDERD_UNIT_STATUS) ? dealItemList[0].Id : 
                                ((unitStatus == Constants.TEMP_ORDERD_UNIT_STATUS) ? null : unitRec.Deal_Item__c));
        }
        if(String.isNotBlank(unitRec.Id)) {
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitRec);
            return 'Success';
       } 
       return 'Error';
    }

    @future
    public static void updateDealFinanceDetails_future(Set<String> dealIdSet) {
        List<Deal_Finance__c> dealFinanceList = [SELECT Id, Interest_Rate__c, Term_Type__c, Loan_Term__c, Payment_Frequency__c, Deal__r.Amount_Financed__c FROM Deal_Finance__c 
                                                    WHERE Deal__c IN :dealIdSet AND Interest_Rate__c != null AND Term_Type__c != null AND Loan_Term__c != null AND Payment_Frequency__c != null];
        for(Deal_Finance__c dealFinanceRec: dealFinanceList) {
            dealFinanceRec.Estimated_Payment__c = getEstimatedPayment(dealFinanceRec);
        }
        DMLUtility.updateSobjectList('Deal_Finance__c', dealFinanceList);
    }
    
    private static Decimal getEstimatedPayment(Deal_Finance__c dealFinanceRec) {
        Decimal intRate =  dealFinanceRec.Interest_Rate__c != null ? dealFinanceRec.Interest_Rate__c : 0;
        Decimal numOfPayments = getNumberOfPayments(dealFinanceRec);
        Decimal loanAmount = dealFinanceRec.Deal__r.Amount_Financed__c != null ? dealFinanceRec.Deal__r.Amount_Financed__c : 0;
        Decimal estimatedPayments = 0;

        if(intRate == 0) {
            estimatedPayments = (loanAmount/numOfPayments).setScale(2);
        } else {
            intRate /= paymentFreqToIntRateMap.get(dealFinanceRec.Payment_Frequency__c);
            estimatedPayments = getPMT((Double)intRate, (Double)numOfPayments, loanAmount);
        }
        return estimatedPayments;
    }

    private static Decimal getPMT(Double interestRate, Double numOfPayments, Decimal presentValue) {
        Decimal futureValue = 0;
        Decimal type = 0;
        Decimal pmt_value = 0;
        if(interestRate == 0) {
            pmt_value = (presentValue + futureValue) / numOfPayments;
        } else {
            interestRate = (interestRate / 100);
            Double pvif = Math.pow(1 + interestRate, numOfPayments);
            pmt_value = -interestRate * presentValue * (pvif + futureValue) / (pvif - 1);
            if (type == 1) {
                pmt_value /= (1 + interestRate);
            }
        }
        pmt_value = (-1 * pmt_value.setScale(2));
        return pmt_value;
    }

    private static Decimal getNumberOfPayments(Deal_Finance__c finRec) {
        finRec.Loan_Term__c = finRec.Loan_Term__c != null ? finRec.Loan_Term__c : 0;
        return (finRec.Loan_Term__c * termTypeToPaymentFreqToValueMap.get(finRec.Term_Type__c).get(finRec.Payment_Frequency__c));
    }

    public static Decimal getActualAmountFinanced(Decimal amountFinanced, DealWrapper.DealFinanceWrapper DealFinanceObj, Boolean isTaxIncludingPricing) {
        Decimal withheldFIProductTotal = 0, commission = 0;
        for (DealWrapper.FIProductWrapper FIProductObj : DealFinanceObj.FIProductList) {
            if(String.isNotBlank(FIProductObj.CostMethod) && FIProductObj.CostMethod.equalsIgnoreCase('Price withheld')) {
                withheldFIProductTotal += (FIProductObj.Price);
                if(!isTaxIncludingPricing) {
                    withheldFIProductTotal += (FIProductObj.SalesTax != null ? FIProductObj.SalesTax : 0);
                }
            } else if(String.isNotBlank(FIProductObj.CostMethod) && FIProductObj.CostMethod.equalsIgnoreCase('Cost withheld')) {
                withheldFIProductTotal += (FIProductObj.Cost);
            }
        }
        if(GeneralConfiguration.getConfigurations().DF_commission_in_FI_company_payments__c && !DealFinanceObj.CommissionsNotInFINPayments) {
            commission = DealFinanceObj.FinanceCommission + DealFinanceObj.BuyRateCommission;
        }
        amountFinanced = amountFinanced != null ? (amountFinanced + commission - withheldFIProductTotal) : 0;
        return amountFinanced;
    }

    public static String toggleLockInUnitPricing(String dealItemId, Boolean IsLockInUnitPricing) {
        Deal_Item__c dealItemRec = new Deal_Item__c(Id = dealItemId, Is_Lock_In_Unit_Pricing__c = IsLockInUnitPricing);
        DMLUtility.updateSobjectList('Deal_Item__c', dealItemRec);
        return 'Success';
    }

    /* Methods moved from CustomerOrderCtrl */
    public static void createDealUnresolvedFulfillment(List<String> lineItemIdList, String DealId, String actionType) {
        List<Deal_Unresolved_Fulfillment__c> dealUnresolvedFulfillmentRecList = new List<Deal_Unresolved_Fulfillment__c>();
        
        if(lineItemIdList == null || lineItemIdList.size() <= 0) {
            return;
        }
        if(String.isBlank(DealId)) {
            return;
        }
        
        Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec; 
        if(actionType == Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED) {
            dealUnresolvedFulfillmentRecList = createUnresolvedFulfillmentWhenAdded(lineItemIdList);
        } else if(actionType == Constants.UNRESOLVED_FULFILLMENT_TYPE_UPDATED) {
            dealUnresolvedFulfillmentRec = createUnresolvedFulfillmentWhenUpdated(lineItemIdList[0]);
        } else if(actionType == Constants.UNRESOLVED_FULFILLMENT_TYPE_REMOVED) {
            dealUnresolvedFulfillmentRec = createUnresolvedFulfillmentWhenRemoved(lineItemIdList[0]);
        }
        
        if(dealUnresolvedFulfillmentRec != null) {
            dealUnresolvedFulfillmentRecList.add(dealUnresolvedFulfillmentRec);
        }
        
        if(dealUnresolvedFulfillmentRecList != null && dealUnresolvedFulfillmentRecList.size() > 0) {
            dealUnresolvedFulfillmentRecList = setFieldsForUnresolvedFulfillment(dealUnresolvedFulfillmentRecList, actionType);
            
            DMLUtility.insertSobjectList('Deal_Unresolved_Fulfillment__c', dealUnresolvedFulfillmentRecList);
            
            //system.assert(false,[Select id from Service_Order_Line_Item__c where Id =: dealUnresolvedFulfillmentRecList[0].Service_Order_Line_Item__c]);
            Set<String> unresolvedRecIdSet = new Set<String>();
            for(Deal_Unresolved_Fulfillment__c unresolvedFulfillmentRec : dealUnresolvedFulfillmentRecList) {
                unresolvedRecIdSet.add(unresolvedFulfillmentRec.Id);
            }
            
            if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Deal_Unresolved_Fulfillment__c> unresolvedFulfillmentList = [Select CO_Line_Item__c, Service_Order_Line_Item__r.Service_Order_Header__c, CO_Kit_Header__c, Service_Order_Kit_Header__r.Service_Order_Header__c from Deal_Unresolved_Fulfillment__c where Id IN :unresolvedRecIdSet];
            if(unresolvedFulfillmentList.size() > 0) { 
                
                if(String.isNotBlank(unresolvedFulfillmentList[0].CO_Line_Item__c)) {
                    
                    Map<String, Boolean> lineItemIdToIsResolvingRecMap = new Map<String, Boolean>();
                    for(Deal_Unresolved_Fulfillment__c unresolvedRec : unresolvedFulfillmentList) {
                        lineItemIdToIsResolvingRecMap.put(unresolvedRec.CO_Line_Item__c, false);
                    }
                    
                    updateUnresolvedCOLIForCheckout(lineItemIdToIsResolvingRecMap);
                } else if(String.isNotBlank(unresolvedFulfillmentList[0].Service_Order_Line_Item__c)) {
                    
                    Map<String, Boolean> lineItemIdToIsResolvingRecMap = new Map<String, Boolean>();
                    for(Deal_Unresolved_Fulfillment__c unresolvedRec : unresolvedFulfillmentList) {
                        lineItemIdToIsResolvingRecMap.put(unresolvedRec.Service_Order_Line_Item__r.Service_Order_Header__c, false);
                    }
                    updateUnresolvedSOHeaderForCheckout(lineItemIdToIsResolvingRecMap);
                    
                } else if(String.isNotBlank(unresolvedFulfillmentList[0].CO_Kit_Header__c)) {
                    Map<String, Boolean> lineItemIdToIsResolvingRecMap = new Map<String, Boolean>();
                    for(Deal_Unresolved_Fulfillment__c unresolvedRec : unresolvedFulfillmentList) {
                        lineItemIdToIsResolvingRecMap.put(unresolvedRec.CO_Kit_Header__c, false);
                    }
                    updateUnresolvedCOKHForCheckout(lineItemIdToIsResolvingRecMap);
                } else if(String.isNotBlank(unresolvedFulfillmentList[0].Service_Order_Kit_Header__c)) {
                    Map<String, Boolean> lineItemIdToIsResolvingRecMap = new Map<String, Boolean>();
                    for(Deal_Unresolved_Fulfillment__c unresolvedRec : unresolvedFulfillmentList) {
                        lineItemIdToIsResolvingRecMap.put(unresolvedRec.Service_Order_Kit_Header__r.Service_Order_Header__c, false);
                    }
                    updateUnresolvedSOKHForCheckout(lineItemIdToIsResolvingRecMap);
                }
                updateDealInvoiceItem(DealId);
            }
        }
    }

    public static String createDeal(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        createDealHeader(coHeaderId);
        
        return getDealDetails(BPUtility.getEncodedString(coHeaderId), null);
    }
    
    public static void createDealHeader(String coHeaderId) {
        Deal__c dealRec = new Deal__c(CO_Header__c = coHeaderId, Status__c = Constants.QUOTATION, Type__c = Constants.CASH_DEAL);
        dealRec.Unit_Status__c = Constants.TEMPORARY;
        dealRec.Deal_Section_Trade_Only__c = false;
        DMLUtility.insertSobjectList('Deal__c', dealRec);
        
        createFirstDummyUnit(dealRec.Id);
        COService.addDefaultSalespersonToCOSection(dealRec.Id);
    }

    private static List<Deal_Unresolved_Fulfillment__c> createUnresolvedFulfillmentWhenAdded(List<String> lineItemIdList) {
        List<Deal_Unresolved_Fulfillment__c> dealUnresolvedFulfillmentRecList = new List<Deal_Unresolved_Fulfillment__c>();
          
        String itemCode = '';
        String itemDesc = '';
        String objectName = (Id.valueOf(lineItemIdList[0])).getSObjectType().getDescribe().getName();
        
        if(objectName == Constants.NAMESPACE + 'CO_Line_Item__c') {
            if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            
            List<CO_Line_Item__c> coLineItemList = [Select Qty__c, Part__c, Part__r.Part_Number__c, Part__r.Description__c, Deal__c from CO_Line_Item__c where Id IN :lineItemIdList];
            
            if(coLineItemList.size() > 0) {
                for(CO_Line_Item__c coliRec : coLineItemList) {
                    Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec = new Deal_Unresolved_Fulfillment__c();
                    itemCode = '';
                    itemDesc = '';
                    if(String.isNotBlank(coliRec.Part__c)) {
                        itemCode = coliRec.Part__r.Part_Number__c;
                        itemDesc = (coliRec.Part__r.Description__c != null) ? coliRec.Part__r.Description__c : '';
                    }
                    dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, coliRec.Deal__c, coliRec.Qty__c, 1);
                    dealUnresolvedFulfillmentRec.CO_Line_Item__c = coliRec.Id;
                    dealUnresolvedFulfillmentRecList.add(dealUnresolvedFulfillmentRec);
    }
    
            }
            
        } else if(objectName == Constants.NAMESPACE + 'Service_Order_Line_Item__c') {
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Line_item__c> soliList = [Select Qty_Needed__c, Part__c, Part__r.Part_Number__c, Part__r.Description__c, Fee__c, Item_Code__c,
                                                            Item_Description__c, Labour_Code__c, Labour_Code__r.Code__c, Labour_Code__r.Description__c, Deal__c, Deal_Item__c, 
                                                            Deal_Item__r.Customer_Owned_Unit__c from Service_Order_Line_Item__c where Id IN :lineItemIdList];

            if(soliList.size() > 0) {
                for(Service_Order_Line_item__c soliRec : soliList) {
                    Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec = new Deal_Unresolved_Fulfillment__c();
                    itemCode = '';
                    itemDesc = '';
                    
                    if(String.isNotBlank(soliRec.Item_Code__c)) {
                        itemCode = soliRec.Item_Code__c;
                    }
                    if(String.isNotBlank(soliRec.Item_Description__c)) {
                        itemDesc = soliRec.Item_Description__c;
                    }
                    dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, soliRec.Deal__c, soliRec.Qty_Needed__c, 1);
                    dealUnresolvedFulfillmentRec.Service_Order_Line_Item__c = soliRec.Id;
                    dealUnresolvedFulfillmentRec.Customer_Owned_Unit__c = soliRec.Deal_Item__r.Customer_Owned_Unit__c;
                    dealUnresolvedFulfillmentRec.Deal_Item__c = soliRec.Deal_Item__c;
                    dealUnresolvedFulfillmentRec.Customer_Owned_Unit__c = soliRec.Deal_Item__r.Customer_Owned_Unit__c;
                    dealUnresolvedFulfillmentRecList.add(dealUnresolvedFulfillmentRec);
                }
            }
        } else if(objectName == Constants.NAMESPACE + 'CO_Kit_Header__c') {
            if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<CO_Kit_Header__c> coKitHeaderList = [Select Kit_Header__c, Kit_Header__r.Kit_Unique_Name__c, Deal__c from CO_Kit_Header__c where Id IN :lineItemIdList];
            
            if(coKitHeaderList.size() > 0) {
                Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec = new Deal_Unresolved_Fulfillment__c();
                if((coKitHeaderList[0].Kit_Header__c != null) && (coKitHeaderList[0].Kit_Header__r.Kit_Unique_Name__c != null)) {
                    List<String> codeDescList = (coKitHeaderList[0].Kit_Header__r.Kit_Unique_Name__c).split(' - ', 2);
                    itemCode = codeDescList[0];
                    itemDesc = codeDescList[1];
                }
                dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, coKitHeaderList[0].Deal__c, 1, 1);
                dealUnresolvedFulfillmentRec.CO_Kit_Header__c = coKitHeaderList[0].Id;
                dealUnresolvedFulfillmentRecList.add(dealUnresolvedFulfillmentRec);
            }
        } else if(objectName == Constants.NAMESPACE + 'Service_Order_Kit_Header__c') {
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Kit_Header__c> soKitHeaderList = [Select Kit_Header__c, Kit_Header__r.Kit_Unique_Name__c, Deal__c, Deal_Item__c, Deal_Item__r.Customer_Owned_Unit__c from Service_Order_Kit_Header__c where Id IN :lineItemIdList];
            if(soKitHeaderList.size() > 0) {
                Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec = new Deal_Unresolved_Fulfillment__c();
                if((soKitHeaderList[0].Kit_Header__c != null) && (soKitHeaderList[0].Kit_Header__r.Kit_Unique_Name__c != null)) {
                    List<String> codeDescList = (soKitHeaderList[0].Kit_Header__r.Kit_Unique_Name__c).split(' - ', 2);
                    itemCode = codeDescList[0];
                    itemDesc = codeDescList[1];
                }
                dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, soKitHeaderList[0].Deal__c, 1, 1);
                dealUnresolvedFulfillmentRec.Service_Order_Kit_Header__c = soKitHeaderList[0].Id;
                dealUnresolvedFulfillmentRec.Deal_Item__c = soKitHeaderList[0].Deal_Item__c;
                dealUnresolvedFulfillmentRec.Customer_Owned_Unit__c = soKitHeaderList[0].Deal_Item__r.Customer_Owned_Unit__c;
                dealUnresolvedFulfillmentRecList.add(dealUnresolvedFulfillmentRec);
            }
        }
        return dealUnresolvedFulfillmentRecList;
    }

    private static Deal_Unresolved_Fulfillment__c setUnresolvedFulfillmentFields(String itemCode, String itemDesc, String dealId, Decimal updatedQty, Decimal actualQty) {
        Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec = new Deal_Unresolved_Fulfillment__c();
        
        dealUnresolvedFulfillmentRec.Item_Code__c = itemCode;
        dealUnresolvedFulfillmentRec.Item_Description__c = itemDesc;
        dealUnresolvedFulfillmentRec.Deal__c = dealId;
        dealUnresolvedFulfillmentRec.Updated_Quantity__c = updatedQty;
        dealUnresolvedFulfillmentRec.Actual_Quantity__c = actualQty;
        
        return dealUnresolvedFulfillmentRec;
    }

    private static Deal_Unresolved_Fulfillment__c createUnresolvedFulfillmentWhenUpdated(String lineItemId) {
        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec = new Deal_Unresolved_Fulfillment__c();
        String itemCode = '';
        String itemDesc = '';
        Decimal actualQty = 0;
        String objectName = (Id.valueOf(lineItemId)).getSObjectType().getDescribe().getName();
        if(objectName == Constants.NAMESPACE + 'CO_Line_Item__c') {
            if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<CO_Line_Item__c> coLineItemList = [Select Qty__c, Related_Option_And_Fees__c, Part__c, Part__r.Part_Number__c, Part__r.Description__c, Deal__c, Option_Fee__c, Option_Fee__r.Deal_Item__c, Option_Fee__r.Qty__c, (Select Id, Qty__c From Options_Fees__r) from CO_Line_Item__c where Id = :lineItemId];
            
            if(coLineItemList.size() > 0) {
                if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Deal_Unresolved_Fulfillment__c> unresolvedFulfillmentList = [Select Id, Type__c, Updated_Quantity__c from Deal_Unresolved_Fulfillment__c where CO_Line_Item__c = :coLineItemList[0].Id AND Is_Resolved__c = false Order By CreatedDate DESC LIMIT 1];
                if(unresolvedFulfillmentList.size() > 0 && String.isBlank(coLineItemList[0].Option_Fee__c)) {
                    dealUnresolvedFulfillmentRec.Id = unresolvedFulfillmentList[0].Id;
                    dealUnresolvedFulfillmentRec.Updated_Quantity__c = coLineItemList[0].Qty__c;
                    DMLUtility.updateSobjectList('Deal_Unresolved_Fulfillment__c', dealUnresolvedFulfillmentRec);
                    return null;
                } else {
                    if(String.isNotBlank(coLineItemList[0].Part__c)) {
                        itemCode = coLineItemList[0].Part__r.Part_Number__c;
                        itemDesc = (coLineItemList[0].Part__r.Description__c != null) ? coLineItemList[0].Part__r.Description__c : '';
                    }
                    if(unresolvedFulfillmentList.size() > 0) { 
                        actualQty = unresolvedFulfillmentList[0].Updated_Quantity__c;
                    } else if(coLineItemList[0].Options_Fees__r.size() > 0) {
                    	for(Option_Fee__c option : coLineItemList[0].Options_Fees__r) {
                    		actualQty += option.Qty__c != null ? option.Qty__c : 0;
                    	}
                    } else if(String.isNotBlank(coLineItemList[0].Option_Fee__c)) {
                    	actualQty = coLineItemList[0].Option_Fee__r.Qty__c;
                    }
                    if(actualQty != coLineItemList[0].Qty__c) {
                        dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, coLineItemList[0].Deal__c, coLineItemList[0].Qty__c, actualQty);
                        dealUnresolvedFulfillmentRec.CO_Line_Item__c = coLineItemList[0].Id;
                        dealUnresolvedFulfillmentRec.Option_Fee__c = coLineItemList[0].Option_Fee__c;
                        dealUnresolvedFulfillmentRec.Related_Option_And_Fees__c = coLineItemList[0].Related_Option_And_Fees__c;
                        dealUnresolvedFulfillmentRec.Deal_Item__c = coLineItemList[0].Option_Fee__r.Deal_Item__c;
                        dealUnresolvedFulfillmentRec.Customer_Owned_unit__c = coLineItemList[0].Option_Fee__r.Deal_Item__c;
                    } else {
                        return null;
                    }
                }
            }
        } else if(objectName == Constants.NAMESPACE + 'Service_Order_Line_Item__c') {
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Line_item__c> soliList = [Select Qty_Needed__c, Part__c, Part__r.Part_Number__c, Part__r.Description__c, Fee__c, Item_Code__c, Item_Description__c,
                                                        Item_Desc__c, Labour_Code__c, Labour_Code__r.Code__c, Labour_Code__r.Description__c, Deal__c, 
                                                        Deal_Item__c, Deal_Item__r.Customer_Owned_Unit__c, Option_Fee__c, Option_Fee__r.Qty__c, 
                                                        Option_Fee__r.Deal_Item__c, (Select Id, Qty__c From Options_Fees__r) from Service_Order_Line_Item__c where Id = :lineItemId];

            if(soliList.size() > 0) {
                if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Deal_Unresolved_Fulfillment__c> unresolvedFulfillmentList = [Select Id, Updated_Quantity__c from Deal_Unresolved_Fulfillment__c where Service_Order_Line_Item__c = :soliList[0].Id AND Is_Resolved__c = false Order By CreatedDate DESC LIMIT 1];
                if(unresolvedFulfillmentList.size() > 0 && String.isBlank(soliList[0].Option_Fee__c)) {
                    dealUnresolvedFulfillmentRec.Id = unresolvedFulfillmentList[0].Id;
                    dealUnresolvedFulfillmentRec.Updated_Quantity__c = soliList[0].Qty_Needed__c;
                    DMLUtility.updateSobjectList('Deal_Unresolved_Fulfillment__c', dealUnresolvedFulfillmentRec);
                    return null;
                } else {
                    if(unresolvedFulfillmentList.size() > 0) {
                        actualQty = unresolvedFulfillmentList[0].Updated_Quantity__c;
                    } else if(soliList[0].Options_Fees__r.size() > 0) {
                    	for(Option_Fee__c option : soliList[0].Options_Fees__r) {
                    		actualQty += option.Qty__c != null ? option.Qty__c : 0;
                    	}
                    } else if(String.isNotBlank(soliList[0].Option_Fee__c)) {
                        actualQty = soliList[0].Option_Fee__r.Qty__c;
                    }
                    if(actualQty != soliList[0].Qty_Needed__c) {
                        if(String.isNotBlank(soliList[0].Item_Code__c)) {
                            itemCode = soliList[0].Item_Code__c;
                        }
                        if(String.isNotBlank(soliList[0].Item_Description__c)) {
                            itemDesc = soliList[0].Item_Description__c;
                        }
                        dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, soliList[0].Deal__c, soliList[0].Qty_Needed__c, actualQty);
                        dealUnresolvedFulfillmentRec.Service_Order_Line_Item__c = soliList[0].Id;
                        dealUnresolvedFulfillmentRec.Option_Fee__c = soliList[0].Option_Fee__c;
                        dealUnresolvedFulfillmentRec.Related_Option_And_Fees__c = soliList[0].Option_Fee__c;
                        dealUnresolvedFulfillmentRec.Deal_Item__c = soliList[0].Deal_Item__c;
                        dealUnresolvedFulfillmentRec.Customer_Owned_Unit__c = soliList[0].Deal_Item__r.Customer_Owned_Unit__c;
                    } else {
                        return null;
                    }
                }
            }
        }
        return dealUnresolvedFulfillmentRec;
    }

    private static Deal_Unresolved_Fulfillment__c createUnresolvedFulfillmentWhenRemoved(String lineItemId) {
        Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec = new Deal_Unresolved_Fulfillment__c();
        String itemCode = '';
        String itemDesc = '';
        String objectName = (Id.valueOf(lineItemId)).getSObjectType().getDescribe().getName();
        if(AccessControl.ifObjectIsDeletable('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Option_fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(objectName == Constants.NAMESPACE + 'CO_Line_Item__c') {
            if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<CO_Line_Item__c> coLineItemList = [Select Qty__c, Part__c, Related_Option_And_Fees__c, (Select Id from Options_Fees__r), Part__r.Part_Number__c, Part__r.Description__c, Deal__c, Option_Fee__c, Option_Fee__r.Deal_Item__c, Option_Fee__r.Qty__c from CO_Line_Item__c where Id = :lineItemId];
            
            if(coLineItemList.size() > 0) {
                List<Deal_Unresolved_Fulfillment__c> unresolvedFulfillmentList = [Select Id from Deal_Unresolved_Fulfillment__c where CO_Line_Item__c = :coLineItemList[0].Id AND Is_Resolved__c = false];
                if(unresolvedFulfillmentList.size() > 0) {
                    delete unresolvedFulfillmentList;
                }
                if(String.isNotBlank(coLineItemList[0].Option_Fee__c)) {
                    if(String.isNotBlank(coLineItemList[0].Part__c)) {
                        itemCode = coLineItemList[0].Part__r.Part_Number__c;
                        itemDesc = (coLineItemList[0].Part__r.Description__c != null) ? coLineItemList[0].Part__r.Description__c : '';
                    }
                    Decimal qtyToDelete = coLineItemList[0].Qty__c;
                    if(String.isNotBlank(coLineItemList[0].Option_Fee__c)) {
                        List<AggregateResult> aggList = [Select Sum(Qty__c)totalQty from Option_fee__c where Id = :coLineItemList[0].Option_Fee__c];
                        if(aggList.size() > 0) {
                            qtyToDelete = (Decimal) aggList[0].get('totalQty');
                        }
                    }
                    dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, coLineItemList[0].Deal__c, qtyToDelete, coLineItemList[0].Option_Fee__r.Qty__c);
                    dealUnresolvedFulfillmentRec.Option_Fee__c = coLineItemList[0].Option_Fee__c;
                    
                    Set<String> relatedOptionAndFeeSet = new Set<String>(coLineItemList[0].Related_Option_And_Fees__c.split(';'));
                    for(Option_Fee__c optionAndFeeRec : coLineItemList[0].Options_Fees__r) {
                        relatedOptionAndFeeSet.add(optionAndFeeRec.Id);
                    }
                    dealUnresolvedFulfillmentRec.Related_Option_And_Fees__c = string.join((new List<String>(relatedOptionAndFeeSet)),';');
                        
                    //dealUnresolvedFulfillmentRec.Related_Option_And_Fees__c = coLineItemList[0].Related_Option_And_Fees__c;
                    dealUnresolvedFulfillmentRec.Deal_Item__c = coLineItemList[0].Option_Fee__r.Deal_Item__c;
                } else {
                    return null;
                }
            }
        } else if(objectName == Constants.NAMESPACE + 'Service_Order_Line_Item__c') {
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Line_item__c> soliList = [Select Item_Code__c, (Select Id from Options_Fees__r), Item_Description__c, Part__c, Part__r.Part_Number__c, Part__r.Description__c, Fee__c, Item_Desc__c, Labour_Code__c, Labour_Code__r.Code__c, Labour_Code__r.Description__c, Deal__c, Deal_Item__c, Deal_Item__r.Customer_Owned_Unit__c, Option_Fee__c, Option_Fee__r.Qty__c, Option_Fee__r.Deal_Item__c from Service_Order_Line_Item__c where Id = :lineItemId];

            if(soliList.size() > 0) {
                List<Deal_Unresolved_Fulfillment__c> unresolvedFulfillmentList = [Select Id from Deal_Unresolved_Fulfillment__c where Service_Order_Line_Item__c = :soliList[0].Id AND Is_Resolved__c = false];
                if(unresolvedFulfillmentList.size() > 0) {
                    delete unresolvedFulfillmentList;
                }
                if(String.isNotBlank(soliList[0].Option_Fee__c)) {
                    itemDesc = '';
                    if(String.isNotBlank(soliList[0].Item_Code__c)) {
                        itemCode = soliList[0].Item_Code__c;
                    }
                    if(String.isNotBlank(soliList[0].Item_Description__c)) {
                        itemDesc = soliList[0].Item_Description__c;
                    }
                    dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, soliList[0].Deal__c, soliList[0].Option_Fee__r.Qty__c, soliList[0].Option_Fee__r.Qty__c);
                    
                    dealUnresolvedFulfillmentRec.Option_Fee__c = soliList[0].Option_Fee__c;
                    
                    
                    Set<String> relatedOptionAndFeeSet = new Set<String>{soliList[0].Option_Fee__c};
                    for(Option_Fee__c optionAndFeeRec : soliList[0].Options_Fees__r) {
                        relatedOptionAndFeeSet.add(optionAndFeeRec.Id);
                    }
                    dealUnresolvedFulfillmentRec.Related_Option_And_Fees__c = string.join((new List<String>(relatedOptionAndFeeSet)),';');
                        
                    //dealUnresolvedFulfillmentRec.Related_Option_And_Fees__c = soliList[0].Option_Fee__c;
                    dealUnresolvedFulfillmentRec.Deal_Item__c = soliList[0].Option_Fee__r.Deal_Item__c;
                    dealUnresolvedFulfillmentRec.Customer_Owned_Unit__c = soliList[0].Deal_Item__r.Customer_Owned_Unit__c;
                } else {
                    return null;
                }
            }
        } else if(objectName == Constants.NAMESPACE + 'CO_Kit_Header__c') {
            if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<CO_Kit_Header__c> cokhList = [Select Deal_Kit_Header__c, Deal_Kit_Header__r.Kit_Header__c, Deal_Kit_Header__r.Kit_Header__r.Kit_Unique_Name__c, Deal__c, Deal_Kit_Header__r.Deal_Item__c from CO_Kit_Header__c where Id = :lineItemId];
            
            if(cokhList.size() > 0) {
                List<Deal_Unresolved_Fulfillment__c> unresolvedFulfillmentList = [Select Id from Deal_Unresolved_Fulfillment__c where CO_Kit_Header__c = :cokhList[0].Id AND Is_Resolved__c = false];
                if(unresolvedFulfillmentList.size() > 0) {
                    delete unresolvedFulfillmentList;
                }
                if(String.isNotBlank(cokhList[0].Deal_Kit_Header__c)) {
                    if((cokhList[0].Deal_Kit_Header__r.Kit_Header__c != null) && (cokhList[0].Deal_Kit_Header__r.Kit_Header__r.Kit_Unique_Name__c != null)) {
                        List<String> codeDescList = (cokhList[0].Deal_Kit_Header__r.Kit_Header__r.Kit_Unique_Name__c).split(' - ', 2);
                        itemCode = codeDescList[0];
                        itemDesc = codeDescList[1];
                    }
                    dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, cokhList[0].Deal__c, 1, 1);
                    dealUnresolvedFulfillmentRec.Deal_Kit_Header__c = cokhList[0].Deal_Kit_Header__c;
                    dealUnresolvedFulfillmentRec.CO_Kit_Header__c = cokhList[0].Id;
                    dealUnresolvedFulfillmentRec.Deal_Item__c = cokhList[0].Deal_Kit_Header__r.Deal_Item__c;
                } else {
                    return null;
                }
            }
        } else if(objectName == Constants.NAMESPACE + 'Service_Order_Kit_Header__c') {
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Kit_Header__c> sokhList = [Select Deal_Kit_Header__c, Deal_Kit_Header__r.Kit_Header__c, Deal_Kit_Header__r.Kit_Header__r.Kit_Unique_Name__c, Deal__c, Deal_Item__c, Deal_Item__r.Customer_Owned_Unit__c, Deal_Kit_Header__r.Deal_Item__c from Service_Order_Kit_Header__c where Id = :lineItemId];

            if(sokhList.size() > 0) {
                List<Deal_Unresolved_Fulfillment__c> unresolvedFulfillmentList = [Select Id from Deal_Unresolved_Fulfillment__c where Service_Order_Kit_Header__c = :sokhList[0].Id AND Is_Resolved__c = false];
                if(unresolvedFulfillmentList.size() > 0) {
                    delete unresolvedFulfillmentList;
                }
                if(String.isNotBlank(sokhList[0].Deal_Kit_Header__c)) {
                    if((sokhList[0].Deal_Kit_Header__r.Kit_Header__c != null) && (sokhList[0].Deal_Kit_Header__r.Kit_Header__r.Kit_Unique_Name__c != null)) {
                        List<String> codeDescList = (sokhList[0].Deal_Kit_Header__r.Kit_Header__r.Kit_Unique_Name__c).split(' - ', 2);
                        itemCode = codeDescList[0];
                        itemDesc = codeDescList[1];
                    }
                    dealUnresolvedFulfillmentRec = setUnresolvedFulfillmentFields(itemCode, itemDesc, sokhList[0].Deal__c, 1, 1);
                    
                    dealUnresolvedFulfillmentRec.Deal_Kit_Header__c = sokhList[0].Deal_Kit_Header__c;
                    dealUnresolvedFulfillmentRec.Service_Order_Kit_Header__c = sokhList[0].Id;
                    dealUnresolvedFulfillmentRec.Deal_Item__c = sokhList[0].Deal_Item__c;
                    dealUnresolvedFulfillmentRec.Customer_Owned_Unit__c = sokhList[0].Deal_Item__r.Customer_Owned_Unit__c;
                } else {
                    return null;
                }
            }
        }
        return dealUnresolvedFulfillmentRec;
    }

    private static List<Deal_Unresolved_Fulfillment__c> setFieldsForUnresolvedFulfillment(List<Deal_Unresolved_Fulfillment__c> unresolvedRecList, String actionType) {
        if(unresolvedRecList.size() > 0) {
            String couId = null;
            String requiredForUnit = '';
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
            if(String.isNotBlank(unresolvedRecList[0].Deal_Item__c)) {
                List<Deal_Item__c> dealItemList = [Select Name__c, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Stock_Id__c from Deal_Item__c where Id =:unresolvedRecList[0].Deal_Item__c];
            if(dealItemList.size() > 0) {
                    couId = dealItemList[0].Customer_Owned_Unit__c;
                    requiredForUnit = dealItemList[0].Name__c + ' - ' + dealItemList[0].Customer_Owned_Unit__r.Stock_Id__c;
            }
        } else {
        
                List<Deal_Item__c> dealItemList = [Select Id, Customer_Owned_Unit__c, Name__c, Customer_Owned_Unit__r.Stock_Id__c from Deal_Item__c where Deal__c = :unresolvedRecList[0].Deal__c];
            if(dealItemList.size() == 1) {
                    couId = dealItemList[0].Customer_Owned_Unit__c;
                    requiredForUnit = dealItemList[0].Name__c + ' - ' + dealItemList[0].Customer_Owned_Unit__r.Stock_Id__c;
                }
            }
        
            for(Deal_Unresolved_Fulfillment__c unresolvedRec : unresolvedRecList) {
                unresolvedRec.Action_Required__c = Constants.actionTypeToActionNameMap.get(actionType);
                unresolvedRec.User__c = UserInfo.getUserId();
                unresolvedRec.Type__c = actionType;
                unresolvedRec.Is_Resolved__c = false;
                unresolvedRec.Customer_Owned_unit__c = couId;
                unresolvedRec.Required_For_Unit__c =requiredForUnit;
            }
        }
        
        return unresolvedRecList;
    }

    private static void updateUnresolvedCOLIForCheckout(String coliId, Boolean isResolving) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        CO_Line_Item__c coliRec = new CO_Line_Item__c(Id = coliId);
        if(isResolving) {
            List<CO_Line_Item__c> coliList = [Select Is_Unresolved_Fulfillment_Exists__c, (Select Is_Resolved__c from Deal_Unresolved_Fulfillments__r) from CO_Line_Item__c where Id = :coliId];
            if(coliList.size() > 0) {
                for(Deal_Unresolved_Fulfillment__c unresolvedFulfillment : coliList[0].Deal_Unresolved_Fulfillments__r) {
                    if(!unresolvedFulfillment.Is_Resolved__c) {
                        return;
                    }
                }
            }
            coliRec.Is_Unresolved_Fulfillment_Exists__c = false;
        } else {
            coliRec.Is_Unresolved_Fulfillment_Exists__c = true;
        }
        DMLUtility.updateSobjectList('CO_Line_Item__c', coliRec);
    }

    private static void updateUnresolvedCOLIForCheckout(Map<String, Boolean> coliIdToIsResolvingMap) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<CO_Line_Item__c> coliList = [Select Is_Unresolved_Fulfillment_Exists__c, (Select Is_Resolved__c from Deal_Unresolved_Fulfillments__r) from CO_Line_Item__c where Id IN :coliIdToIsResolvingMap.keySet()];
        List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();
        for(CO_Line_Item__c coliRec : coliList) {
            if(coliIdToIsResolvingMap.containsKey(coliRec.Id) && coliIdToIsResolvingMap.get(coliRec.Id)) {
                 Boolean isUnresolvedFulfillmentExists = false;
                 for(Deal_Unresolved_Fulfillment__c unresolvedFulfillment : coliRec.Deal_Unresolved_Fulfillments__r) {
                    if(!unresolvedFulfillment.Is_Resolved__c) {
                        isUnresolvedFulfillmentExists = true;
                        break;
                    }
                }
                if(!isUnresolvedFulfillmentExists) {
                    coliRec.Is_Unresolved_Fulfillment_Exists__c = false;
                }
            } else {
                coliRec.Is_Unresolved_Fulfillment_Exists__c = true;
            }
            coliListToUpdate.add(coliRec);
        }
        
        if(coliListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('CO_Line_Item__c', coliListToUpdate);
        }
    }

    private static void updateUnresolvedSOHeaderForCheckout(Map<String, Boolean> soHeaderIdToIsResolvingMap) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

        Map<String, List<Service_Order_Line_Item__c>> soIdToSOLIRecMap = new Map<String, List<Service_Order_Line_Item__c>>();
        for(Service_Order_Line_Item__c soliRec : [Select Id, Service_Order_Header__c, (Select Is_Resolved__c from Deal_Unresolved_Fulfillments__r) 
                                                from Service_Order_Line_Item__c where Service_Order_Header__c In :soHeaderIdToIsResolvingMap.keySet()]) {
            if(!soIdToSOLIRecMap.containsKey(soliRec.Service_Order_Header__c)) {
                soIdToSOLIRecMap.put(soliRec.Service_Order_Header__c, new List<Service_Order_Line_Item__c>());
            }
            soIdToSOLIRecMap.get(soliRec.Service_Order_Header__c).add(soliRec);
        }
        
        List<Service_Order_Header__c> soHeaderListToUpdate = new List<Service_Order_Header__c>();
        for(String soHeaderId : soHeaderIdToIsResolvingMap.keySet()) {
            if(soHeaderIdToIsResolvingMap.get(soHeaderId)) {
                Boolean isUnresolvedFulfillmentExists = false;
                if(soIdToSOLIRecMap.containsKey(soHeaderId)) {
                    for(Service_Order_Line_Item__c soliRec : soIdToSOLIRecMap.get(soHeaderId)) {
                        for(Deal_Unresolved_Fulfillment__c unresolvedFulfillment : soliRec.Deal_Unresolved_Fulfillments__r) {
                            if(!unresolvedFulfillment.Is_Resolved__c) {
                                isUnresolvedFulfillmentExists = true;
                                break;
                            }
                        }
                    }
                }
                if(!isUnresolvedFulfillmentExists) {
                    soHeaderListToUpdate.add(new Service_Order_Header__c(Id = soHeaderId, Is_Unresolved_Fulfillment_Exists__c = false));
                }
            } else {
                soHeaderListToUpdate.add(new Service_Order_Header__c(Id = soHeaderId, Is_Unresolved_Fulfillment_Exists__c = true));
            }
        }
        
        if(soHeaderListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderListToUpdate);
        }
    }

    private static void updateUnresolvedCOKHForCheckout(Map<String, Boolean> cokhIdToIsResolvingMap) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<SObject> sObjectListToUpdate = new List<SObject>(); 
        
        Map<String, CO_Kit_Header__c> cokhIdToCOKHRecMap = new Map<String, CO_Kit_Header__c>([Select Id, Is_Unresolved_Fulfillment_Exists__c, 
                                (Select Is_Resolved__c from Deal_Unresolved_Fulfillments__r), (Select Id, Is_Unresolved_Fulfillment_Exists__c from CO_Line_Items__r) from CO_Kit_Header__c where Id IN :cokhIdToIsResolvingMap.keySet()]);
        
        for(String cokhId : cokhIdToIsResolvingMap.keySet()) {
            
            Boolean isUnresolvedFulfillmentExists = false;
            if(cokhIdToIsResolvingMap.get(cokhId)) {
                if(cokhIdToCOKHRecMap.containsKey(cokhId)) {
                    for(Deal_Unresolved_Fulfillment__c unresolvedFulfillment : cokhIdToCOKHRecMap.get(cokhId).Deal_Unresolved_Fulfillments__r) {
                        if(!unresolvedFulfillment.Is_Resolved__c) {
                            isUnresolvedFulfillmentExists = true;
                            break;
                        }
                    }
                }
                if(!isUnresolvedFulfillmentExists) {
                    sObjectListToUpdate.add(new CO_Kit_Header__c(Id = cokhId, Is_Unresolved_Fulfillment_Exists__c = false));
                }
            } else {
                sObjectListToUpdate.add(new CO_Kit_Header__c(Id = cokhId, Is_Unresolved_Fulfillment_Exists__c = true));
                isUnresolvedFulfillmentExists = true;
            }
            if(cokhIdToCOKHRecMap.containsKey(cokhId)) {
                for(CO_Line_Item__c coliRec : cokhIdToCOKHRecMap.get(cokhId).CO_Line_Items__r) {
                    coliRec.Is_Unresolved_Fulfillment_Exists__c = isUnresolvedFulfillmentExists;
                    sObjectListToUpdate.add((SObject) coliRec);
                }
            }
        }
        
        if(sObjectListToUpdate.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update sObjectListToUpdate;
        }
    }

    private static void updateUnresolvedSOHeaderForCheckout(String soHeaderId, Boolean isResolving) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        Service_Order_Header__c soHeaderRec = new Service_Order_Header__c(Id = soHeaderId);
        if(isResolving) {
            List<Service_Order_Line_Item__c> soliList = [Select Id, (Select Is_Resolved__c from Deal_Unresolved_Fulfillments__r) from Service_Order_Line_Item__c where Service_Order_Header__c = :soHeaderId];
            for(Service_Order_Line_Item__c soliRec : soliList) {
                for(Deal_Unresolved_Fulfillment__c unresolvedFulfillment : soliRec.Deal_Unresolved_Fulfillments__r) {
                    if(!unresolvedFulfillment.Is_Resolved__c) {
                        return;
                    }
                }
            }
            soHeaderRec.Is_Unresolved_Fulfillment_Exists__c = false;
        } else {
            soHeaderRec.Is_Unresolved_Fulfillment_Exists__c = true;
        }
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);
    }
    
    private static void updateUnresolvedCOKHForCheckout(String cokhId, Boolean isResolving) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        CO_Kit_Header__c cokhRec = new CO_Kit_Header__c(Id = cokhId); 
        List<CO_Kit_Header__c> cokhList = [Select Is_Unresolved_Fulfillment_Exists__c, (Select Id, Is_Unresolved_Fulfillment_Exists__c from CO_Line_Items__r), (Select Is_Resolved__c from Deal_Unresolved_Fulfillments__r) from CO_Kit_Header__c where Id = :cokhId];
        if(isResolving) {
            if(cokhList.size() > 0) {
                for(Deal_Unresolved_Fulfillment__c unresolvedFulfillment : cokhList[0].Deal_Unresolved_Fulfillments__r) {
                    if(!unresolvedFulfillment.Is_Resolved__c) {
                        return;
                    }
                }
            }
            cokhRec.Is_Unresolved_Fulfillment_Exists__c = false;
        } else {
            cokhRec.Is_Unresolved_Fulfillment_Exists__c = true;
        }
        
        for(CO_Line_Item__c coliRec : cokhList[0].CO_Line_Items__r) {
            coliRec.Is_Unresolved_Fulfillment_Exists__c = cokhRec.Is_Unresolved_Fulfillment_Exists__c;
        }
        if(AccessControl.ifObjectFieldIsCreateable('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        List<SObject> sObjectListToUpdate =  new List<SObject>((List<SObject>) cokhList[0].CO_Line_Items__r);
        sObjectListToUpdate.add(cokhRec);
        update sObjectListToUpdate;
    }
    
    private static void updateUnresolvedSOKHForCheckout(String soHeaderId, Boolean isResolving) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Service_Order_Header__c soHeaderRec = new Service_Order_Header__c(Id = soHeaderId);
        if(isResolving) {
            List<Service_Order_Kit_Header__c> sokhList = [Select Id, (Select Is_Resolved__c from Deal_Unresolved_Fulfillments__r) from Service_Order_Kit_Header__c where Service_Order_Header__c = :soHeaderId];
            for(Service_Order_Kit_Header__c sokhRec : sokhList) {
                for(Deal_Unresolved_Fulfillment__c unresolvedFulfillment : sokhRec.Deal_Unresolved_Fulfillments__r) {
                    if(!unresolvedFulfillment.Is_Resolved__c) {
                        return;
                    }
                }
            }
            soHeaderRec.Is_Unresolved_Fulfillment_Exists__c = false;
        } else {
            soHeaderRec.Is_Unresolved_Fulfillment_Exists__c = true;
        }
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);
    }

    private static void updateUnresolvedSOKHForCheckout(Map<String, Boolean> soHeaderIdToIsResolvingMap) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

        Map<String, List<Service_Order_Kit_Header__c>> soIdToSOKHRecMap = new Map<String, List<Service_Order_Kit_Header__c>>();
        for(Service_Order_Kit_Header__c sokhRec : [Select Id, Service_Order_Header__c, (Select Is_Resolved__c from Deal_Unresolved_Fulfillments__r) from Service_Order_Kit_Header__c 
                                                        where Service_Order_Header__c In :soHeaderIdToIsResolvingMap.keySet()]) {
            if(!soIdToSOKHRecMap.containsKey(sokhRec.Service_Order_Header__c)) {
                soIdToSOKHRecMap.put(sokhRec.Service_Order_Header__c, new List<Service_Order_Kit_Header__c>());
            }
            soIdToSOKHRecMap.get(sokhRec.Service_Order_Header__c).add(sokhRec);
        }
        
        List<Service_Order_Header__c> soHeaderListToUpdate = new List<Service_Order_Header__c>();
        
        for(String soHeaderId : soHeaderIdToIsResolvingMap.keySet()) {
            if(soHeaderIdToIsResolvingMap.get(soHeaderId)) {
                Boolean isUnresolvedFulfillmentExists = false;
                if(soIdToSOKHRecMap.containsKey(soHeaderId)) {
                    for(Service_Order_Kit_Header__c sokhRec : soIdToSOKHRecMap.get(soHeaderId)) {
                        for(Deal_Unresolved_Fulfillment__c unresolvedFulfillment : sokhRec.Deal_Unresolved_Fulfillments__r) {
                            if(!unresolvedFulfillment.Is_Resolved__c) {
                                isUnresolvedFulfillmentExists = true;
                                break;
                            }
                        }
                    }
                }
                if(!isUnresolvedFulfillmentExists) {
                    soHeaderListToUpdate.add(new Service_Order_Header__c(Id = soHeaderId, Is_Unresolved_Fulfillment_Exists__c = false));
                }
            } else {
                soHeaderListToUpdate.add(new Service_Order_Header__c(Id = soHeaderId, Is_Unresolved_Fulfillment_Exists__c = true));
            }
        }
        
        if(soHeaderListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderListToUpdate);
        }
    }

    private static void updateDealInvoiceItem(String dealId) {
        List<CO_Invoice_Item__c> dealInvoiceItemList = [SELECT isActive__c, Is_Invoiceable__c FROM CO_Invoice_Item__c 
                                                            WHERE Deal__c =: dealId AND Deal_Finance__c = null];
	    Map<String, Boolean> optionNameToOptionValueMap = isDealInvoiceable(dealId);
	    dealInvoiceItemList[0].Is_Invoiceable__c = optionNameToOptionValueMap.get('Invoiceable');
	    dealInvoiceItemList[0].isActive__c = optionNameToOptionValueMap.get('Active');
	    update dealInvoiceItemList[0];
    }

    public static Map<String, Boolean> isDealInvoiceable(String dealId) {
        Map<String, Boolean> optionNameToOptionValueMap = new Map<String, Boolean>{'Invoiceable' => false, 'Active' => false};
        List<Deal__c> dealList = [SELECT Status__c,Deal_Section_Trade_Only__c, Is_Deal_Fulfilled__c, Type__c, (SELECT Id, Status__c from Deal_Finances__r), 
                                        (SELECT Id from CO_Invoice_Items__r), (SELECT Id from Deal_Unresolved_Fulfillments__r WHERE Is_Resolved__c = false)
                                        FROM Deal__c WHERE Id =: dealId];    
        Boolean isInvoiceable = false;
        if(dealList.size() > 0 && dealList[0].Status__c == 'Approved' && (dealList[0].Type__c == 'Cash Deal' || (dealList[0].Deal_Finances__r.size() > 0 && dealList[0].Deal_Finances__r[0].Status__c == 'Funded'))) {
            // Check for commit install options
	        List<Deal_Item__c> dealItemList = [SELECT Option_And_Fee_Status__c, (SELECT Id, CO_Line_Item__c, Service_Order_Line_Item__c, Status__c 
	        													from Options_Fees__r WHERE (Part__c != null OR 
	                                                            Labour_Code__c != null OR (Product__c != null AND Product__r.Type__c = 'Sublet'))), 
	                                                      (SELECT Id from Deal_Kit_Headers__r)
	                                            FROM Deal_Item__c 
	                                            WHERE Deal__c =: dealId AND Type__c =: Constants.DEAL_ITEM_TYPE_UNIT];
	        
	        if(dealItemList.size() > 0) {
	            if(isDealInstallOptionExist(dealItemList)) {
		            for(Deal_Item__c dealItemRec : dealItemList) {
			            for(Option_Fee__c ofRec : dealItemRec.Options_Fees__r) {
				            if(!DealService.isOptionCommitted(ofRec)) {
			            		optionNameToOptionValueMap.put('Invoiceable', false);
			            		optionNameToOptionValueMap.put('Active', false);
			            		return optionNameToOptionValueMap;
			            	}
			            }
		            }
	                if(!isUnresolvedFulfillmentExist(dealList)) {
		                optionNameToOptionValueMap.put('Invoiceable', true);
		                if(dealList[0].Is_Deal_Fulfilled__c) {
		                    optionNameToOptionValueMap.put('Active', true);
		                }
	                }
	            } else {
	                optionNameToOptionValueMap.put('Invoiceable', true);
	                optionNameToOptionValueMap.put('Active', true);
	            }
	        } else {
	        	if(dealList[0].Deal_Section_Trade_Only__c) {
	        		List<Deal_Item__c> dealItemTradeInList = [SELECT Id FROM Deal_Item__c 
	                                            WHERE Deal__c =: dealId AND Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN];
	        		if(dealItemTradeInList.size() > 0) {
	        			optionNameToOptionValueMap.put('Invoiceable', true);
	                	optionNameToOptionValueMap.put('Active', true);
	        }
        }
        }
        }
        return optionNameToOptionValueMap;
    }

    private static Boolean isDealInstallOptionExist(List<Deal_Item__c> dealItemList) {
        Boolean isDealOptionExist = false;
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(dealItemRec.Deal_Kit_Headers__r.size() > 0 || dealItemRec.Options_Fees__r.size() > 0) {
                isDealOptionExist = true;
                break;
            }
        }
        return isDealOptionExist;
    }

    private static Boolean isUnresolvedFulfillmentExist(List<Deal__c> dealList) {
        Boolean isUnresolvedFulfillmentExist = false;
        for(Deal__c dealRec : dealList) {
            if(dealRec.Deal_Unresolved_Fulfillments__r.size() > 0) {
                isUnresolvedFulfillmentExist = true;
                break;
            }
        }
        return isUnresolvedFulfillmentExist;
    }

    public static List<Unit_Price_Cost__c> createPriceAndCostLineItem(String unitId, List<Service_Order_Line_Item__c> soliItems, String InvoiceId){
        List<Unit_Price_Cost__c> unitPriceAndCostList = new List<Unit_Price_Cost__c>();
        Unit_Price_Cost__c unitPriceAndCost;
        for(Service_Order_Line_Item__c soli : soliItems) {
            unitPriceAndCost = new Unit_Price_Cost__c();
            unitPriceAndCost.Type__c = 'Dealer';
            unitPriceAndCost.CO_Invoice_Header__c = InvoiceId;
            
            String itemCode = (soli.Item_Code__c != null) ? soli.Item_Code__c : '';
            String itemDescription = (soli.Item_Description__c != null) ? soli.Item_Description__c : '';
            unitPriceAndCost.Item_Description__c = itemCode + ' - ' + itemDescription;
            unitPriceAndCost.Item_Description__c = (unitPriceAndCost.Item_Description__c != null && unitPriceAndCost.Item_Description__c.length() > 255) ? unitPriceAndCost.Item_Description__c.abbreviate(255) : unitPriceAndCost.Item_Description__c;
            
            /*if(soli.Fee__c != null){
                unitPriceAndCost.Item_Description__c = soli.Fee__r.Description__c;
            }else if(soli.Part__c != null){
                unitPriceAndCost.Item_Description__c = soli.Part__r.Description__c;
            }else if(soli.Labour_Code__c != null){
                unitPriceAndCost.Item_Description__c = soli.Labour_Code__r.Description__c;
            }*/
            unitPriceAndCost.Qty__c = soli.Qty_Needed__c;
            unitPriceAndCost.Price__c = soli.Retail_Price__c;
            unitPriceAndCost.Total_Price__c = (soli.Qty_Needed__c != null && soli.Retail_Price__c != null) ? (soli.Qty_Needed__c * soli.Retail_Price__c).setScale(2, RoundingMode.HALF_UP) : 0;
            unitPriceAndCost.Cost__c = soli.Kit_Price__c;
            unitPriceAndCost.Total_Cost__c = (soli.Qty_Needed__c != null && soli.Kit_Price__c != null) ? (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP) : 0;
            unitPriceAndCost.Service_Order_Line_Item__c = soli.id;
            unitPriceAndCost.Customer_Owned_Unit__c = unitId;
            unitPriceAndCost.Adjustment_Date__c = System.now();
            unitPriceAndCostList.add(unitPriceAndCost);
        }
        return unitPriceAndCostList;
    }

    public static List<Option_Fee__c> UpdateOptionFeeInvoice(List<CO_Line_Item__c> coLineItemDealservice, List<Service_Order_Line_Item__c> soLineItemDealservice, 
        List<Option_Fee__c> optionAndFeeRecListWithDoNotInvOption) {
        List<Option_Fee__c>  optionFeeListToUpdate = new List<Option_Fee__c>();
        String dealId;
        Set<String> optionAndFeeIdSet = new Set<String>();
        for(CO_Line_Item__c coliRec :  coLineItemDealservice) {
            if(String.isNotBlank(coliRec.Related_Option_And_Fees__c)) {
                dealId = coliRec.Deal__c;
                List<String> OptionFeeIdList =  coliRec.Related_Option_And_Fees__c.split(';');
                for(String optionFeeId : OptionFeeIdList){
                    if(String.isNotBlank(optionFeeId) && !optionAndFeeIdSet.contains(optionFeeId)){
                        Option_Fee__c optionfeeItem = new Option_Fee__c();
                        optionfeeItem.Id = optionFeeId;
                        optionfeeItem.Per_Item_Cost__c = coliRec.Price__c;
                        optionfeeItem.status__c = 'Fulfilled';
                        optionFeeListToUpdate.add(optionfeeItem);
                        optionAndFeeIdSet.add(optionFeeId);
                    }
                }
            }
        }
        for(Service_Order_Line_Item__c soliRec : soLineItemDealservice) {
            dealId = soliRec.Service_Order_Header__r.Deal__c;
            if(String.isNotBlank(soliRec.Option_Fee__c) && !optionAndFeeIdSet.contains(soliRec.Option_Fee__c)) {
                Option_Fee__c optionfeeItem = new Option_Fee__c(Id = soliRec.Option_Fee__c);
                optionfeeItem.Per_Item_Cost__c = soliRec.Kit_Price__c;
                optionfeeItem.status__c = 'Fulfilled';
                optionFeeListToUpdate.add(optionfeeItem);
                optionAndFeeIdSet.add(soliRec.Option_Fee__c);
            }
        }
        
        for(Option_Fee__c optionfeeItem : optionAndFeeRecListWithDoNotInvOption) {
            if(!optionAndFeeIdSet.contains(optionfeeItem.Id)) {
                optionfeeItem.Per_Item_Cost__c = optionfeeItem.Service_Order_Line_Item__r.Kit_Price__c;
                optionfeeItem.status__c = 'Fulfilled';
                optionFeeListToUpdate.add(optionfeeItem);
                optionAndFeeIdSet.add(optionfeeItem.Id);
            }
        }
        if(String.isNotBlank(dealId) && !System.isFuture()) calculateDealOptionClearingAndStockTrade(dealId); 
        return optionFeeListToUpdate;
    }

    public static List<Customer_Owned_Unit__c> calculateDealOptionsWIPCost(Id coInvoiceId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Invoice_Header__c> coInvoiceList = [SELECT Name, (SELECT CO_Line_Item__c, Service_Order_Header__c, CO_Kit_Header__c, 
                                                            CO_Line_Item__r.Deal__c, Service_Order_Header__r.Deal__c, CO_Kit_Header__r.Deal__c,
                                                            CO_Line_Item__r.Related_Option_And_Fees__c
                                                            FROM CO_Invoice_Items__r)
                                                    FROM CO_Invoice_Header__c WHERE Id =: coInvoiceId ];
        
        List<Customer_Owned_Unit__c> unitListToUpdate = new List<Customer_Owned_Unit__c>();
        if(coInvoiceList.size() == 0) { return unitListToUpdate; }                                                    
        Set<Id> dealIdSet = new Set<Id>();
        // find whether the item invoiced is a deal merch or deal service
        for(CO_Invoice_Item__c coInvoiceItem : coInvoiceList[0].CO_Invoice_Items__r) {
            if(coInvoiceItem.CO_Line_Item__c != null && coInvoiceItem.CO_Line_Item__r.Deal__c != null) { 
                dealIdSet.add(coInvoiceItem.CO_Line_Item__r.Deal__c);
            } else if(coInvoiceItem.Service_Order_Header__c != null && coInvoiceItem.Service_Order_Header__r.Deal__c != null) {
                dealIdSet.add(coInvoiceItem.Service_Order_Header__r.Deal__c);
            } else if(coInvoiceItem.CO_Kit_Header__c != null && coInvoiceItem.CO_Kit_Header__r.Deal__c != null) {
                dealIdSet.add(coInvoiceItem.CO_Kit_Header__r.Deal__c);
            }
        }
        if(dealIdSet.size() == 0) { return unitListToUpdate; }
        
        Map<Id, Decimal> skuIdToDealOptionsWIPCostMap = new Map<Id, Decimal>();
        calculateDealMerchOptionsWIPCost(dealIdSet, skuIdToDealOptionsWIPCostMap);
        calculateDealServiceOptionsWIPCost(dealIdSet, skuIdToDealOptionsWIPCostMap);
        
        if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        
        for(Id skuId : skuIdToDealOptionsWIPCostMap.keySet()) {
            Customer_Owned_Unit__c unitRec = new Customer_Owned_Unit__c(Id = skuId, Deal_Options_WIP__c = skuIdToDealOptionsWIPCostMap.get(skuId));
            unitListToUpdate.add(unitRec);
        }
        return unitListToUpdate;
    }
    
    // get all option and fees to find option and fees which belong to deal merch and are invoiced then add price for deal merch option and fees
    private static void calculateDealMerchOptionsWIPCost(Set<Id> dealIdSet, Map<Id, Decimal> skuIdToDealOptionsWIPCostMap) {
        if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Option_Fee__c> optionFeeList = [Select Status__c, Is_Install__c, Deal_Kit_Header__c, Deal_Kit_Header__r.Is_Install__c, Qty__c, Per_Item_Cost__c, Deal_Item__r.Customer_Owned_Unit__c from Option_Fee__c where Deal__c IN : dealIdSet];
        
        for(Option_Fee__c optionFeeRec: optionFeeList) {
            Decimal cost = 0;
            if(String.isNotBlank(optionFeeRec.Status__c) && optionFeeRec.Status__c.equalsIgnoreCase(Constants.FULFILLED) && 
                ((optionFeeRec.Deal_Kit_Header__c != null && !optionFeeRec.Deal_Kit_Header__r.Is_Install__c) ||
                (optionFeeRec.Deal_Kit_Header__c == null && !optionFeeRec.Is_Install__c)) && 
                String.isNotBlank(optionFeeRec.Deal_Item__r.Customer_Owned_Unit__c)) 
            {
                optionFeeRec.Per_Item_Cost__c = (optionFeeRec.Per_Item_Cost__c != null ? (optionFeeRec.Per_Item_Cost__c).setScale(2, RoundingMode.HALF_UP) : 0);
                optionFeeRec.Qty__c = (optionFeeRec.Qty__c != null ? optionFeeRec.Qty__c : 0);
                cost = (optionFeeRec.Per_Item_Cost__c * optionFeeRec.Qty__c).setScale(2, RoundingMode.HALF_UP);
            }
            String skuId = optionFeeRec.Deal_Item__r.Customer_Owned_Unit__c;
            if(skuIdToDealOptionsWIPCostMap.containsKey(skuId)) {
                skuIdToDealOptionsWIPCostMap.put(skuId, skuIdToDealOptionsWIPCostMap.get(skuId) + cost);
            } else {
                skuIdToDealOptionsWIPCostMap.put(skuId, cost);
            }
        }
    }
    
    // get all solis realted to deal services which are invoiced then add price for deal merch service items
    private static void calculateDealServiceOptionsWIPCost(Set<Id> dealIdSet, Map<Id, Decimal> skuIdToDealOptionsWIPCostMap) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Line_Item__c> soLineItemList = 
              [SELECT Kit_Price__c, Qty_Needed__c, Deal_Item__r.Customer_Owned_Unit__c FROM Service_Order_Line_Item__c 
                   WHERE Service_Order_Header__r.Deal__c IN: dealIdSet AND Service_Order_Header__r.SO_Status__c = 'Invoiced'];
                   
        for(Service_Order_Line_Item__c soliRec: soLineItemList) {
            Decimal cost = 0;
            if(String.isNotBlank(soliRec.Deal_Item__r.Customer_Owned_Unit__c)) {
                soliRec.Kit_Price__c = (soliRec.Kit_Price__c != null ? (soliRec.Kit_Price__c).setScale(2, RoundingMode.HALF_UP) : 0);
                soliRec.Qty_Needed__c = (soliRec.Qty_Needed__c != null ? soliRec.Qty_Needed__c : 0);
                cost = (soliRec.Kit_Price__c*soliRec.Qty_Needed__c).setScale(2, RoundingMode.HALF_UP);
            }
            String skuId = soliRec.Deal_Item__r.Customer_Owned_Unit__c;
            if(skuIdToDealOptionsWIPCostMap.containsKey(soliRec.Deal_Item__r.Customer_Owned_Unit__c)) {
                skuIdToDealOptionsWIPCostMap.put(skuId, skuIdToDealOptionsWIPCostMap.get(skuId) + cost);
            } else {
                skuIdToDealOptionsWIPCostMap.put(skuId, cost);
            }
        }
    }

    @future
    private static void createDUPCFromUPCForSKU_future(Map<String, String> skuIdToDealItemIdMap) {
    	if(skuIdToDealItemIdMap.size() > 0) {
	    	List<Unit_Price_Cost__c> upcList = [Select Id, Customer_Owned_Unit__c, Item_Description__c, Price__c, Total_Price__c, Qty__c, Type__c 
	    				from Unit_Price_Cost__c where Customer_Owned_Unit__c IN: skuIdToDealItemIdMap.keySet() AND Type__c != 'Base' AND 
	    				Id NOT IN (Select Unit_Price_Cost__c from Deal_Unit_Price_Cost__c where Deal_Item__c IN: skuIdToDealItemIdMap.values() AND Type__c != 'Base')];		
	    	
	    	List<Unit_Price_Cost__c> upcListToUpdate = new List<Unit_Price_Cost__c>();
	    	List<Deal_Unit_Price_Cost__c> dupcListToInsert = new List<Deal_Unit_Price_Cost__c>();
	    	for(Unit_Price_Cost__c unitPriceCostRec : upcList) {
				String dealItemId = skuIdToDealItemIdMap.get(unitPriceCostRec.Customer_Owned_Unit__c);
				if(dealItemId == null) {
					continue;	
				}
				unitPriceCostRec.Total_Price__c =  unitPriceCostRec.Price__c = 0;
				upcListToUpdate.add(unitPriceCostRec);
				
		        Deal_Unit_Price_Cost__c dealUnitPriceCostRec = new Deal_Unit_Price_Cost__c(Unit_Price_Cost__c = unitPriceCostRec.Id, Deal_Item__c =  dealItemId);
                	
                if(String.isNotBlank(unitPriceCostRec.Item_Description__c) && unitPriceCostRec.Item_Description__c.length() > 80) {
                    dealUnitPriceCostRec.Name = unitPriceCostRec.Item_Description__c.subString(0, 80);
                } else {
		        	dealUnitPriceCostRec.Name = unitPriceCostRec.Item_Description__c;
		        }
		        dealUnitPriceCostRec.Item_Description__c = unitPriceCostRec.Item_Description__c;
		        dealUnitPriceCostRec.Price__c = 0;
		        dealUnitPriceCostRec.Type__c = unitPriceCostRec.Type__c;
		        dealUnitPriceCostRec.Qty__c = 1;
		        if(dealUnitPriceCostRec.Type__c == 'Dealer') {
		            dealUnitPriceCostRec.Qty__c = unitPriceCostRec.Qty__c;
		        }
		        if(GeneralConfiguration.getTaxIncludingPricing()) {
		            dealUnitPriceCostRec.Price_When_Tax_Included__c = 0;
		        }
				dupcListToInsert.add(dealUnitPriceCostRec);
			}
			DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = true;
            DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dupcListToInsert);
			DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = false;
            DMLUtility.updateSobjectList('Unit_Price_Cost__c', upcListToUpdate);
    	}
    }

    /**
     * Name: getDealDetails
     * Desc: Method which gives deal rec using co header id
     * @param:  (1) coHeaderId - String - CO header id
     * @return: String - JSON String of deal
    **/
    public static String getDealDetails(String objectId, String gridName) {
        objectId = BPUtility.getDecodedString(objectId);
        gridName = BPUtility.getDecodedString(gridName);
        
        if(AccessControl.ifObjectFieldIsAccessible('User') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        if(String.isBlank(objectId)){
            return BPUtility.getEncodedString('{}');
        }
        List<Deal__c> dealList = new List<Deal__c>();
        
        String objectName = (Id.valueOf(objectId)).getSObjectType().getDescribe().getName();
        if(objectName == Constants.NAMESPACE + 'CO_Header__c') {
            dealList = SOQLUtil.getDealDetails(new Map<String, String>{'CO_Header__c' => objectId});
        } else if(objectName == Constants.NAMESPACE + 'Deal__c') {
            dealList = SOQLUtil.getDealDetails(new Map<String, String>{'Id' => objectId});
        } 
        
        if(dealList.size() == 0) {
            return BPUtility.getEncodedString('{}');
        } 
        
        String jsonString;
        if(gridName == null || gridName == 'dealInfoWithDealItem') {
        Set<Id> dealItemIds = new Set<Id>();
        
        for(Deal_Item__c dealItemRec : dealList[0].Deal_Items__r) {
            dealItemIds.add(dealItemRec.Id);
        }
        List<Deal_Item__c> dealItemList = SOQLUtil.getDealItemDetails(new Set<Id>(dealItemIds));
        
            Map<Id, List<Deal_Kit_Header__c>> dealItemIdToDKHListMap = new Map<Id, List<Deal_Kit_Header__c>>();
            List<Deal_Kit_Header__c> dealKitHeaderList = SOQLUtil.getDealKitHeaderDetailsByDealItemId(new Set<Id>(dealItemIds));
            for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaderList) {
                if(dealItemIdToDKHListMap.containsKey(dealKitHeaderRec.Deal_Item__c)) {
                    List<Deal_Kit_Header__c> dealKitHeaders = dealItemIdToDKHListMap.get(dealKitHeaderRec.Deal_Item__c);
                    dealKitHeaders.add(dealKitHeaderRec);
                    dealItemIdToDKHListMap.put(dealKitHeaderRec.Deal_Item__c, dealKitHeaders);
                } else {
                    dealItemIdToDKHListMap.put(dealKitHeaderRec.Deal_Item__c, new List<Deal_Kit_Header__c>{dealKitHeaderRec});
                }
            }
            DealWrapper dealWrapperObj;
            if(gridName != 'dealInfoWithDealItem') {
            List<CO_Line_Item__c> coliList = SOQLUtil.getCOLineItemByFieldValue(new Map<String, String>{'Deal__c' => dealList[0].Id, 'CO_Kit_Header__c' => null
                                                                                        , 'Service_Order_Line_Item__c' => null});
            List<CO_Kit_Header__c> cokhList = SOQLUtil.getCOKHByFieldValue(new Map<String, String>{'Deal__c' => dealList[0].Id});
            
	            
            List<Vendor_Order_Line_Item__c> specialOrders = SOQLUtil.getSpecialOrderByCOHeaderId(dealList[0].CO_Header__c);
            List<Deal_Unresolved_Fulfillment__c> dealUnresolvedFulfillmentList = SOQLUtil.getDealUnresolvedFulfillment(new Map<String, String>{'Deal__c' => dealList[0].Id});
            List<Profile> ProfilesList = [Select Id from Profile where Name IN: PROFILE_NAME_LIST]; // Added by richa #1972
            List<User> userList = [Select Name, Email from User where isActive = true and ProfileId IN :ProfilesList]; // and ProfileId IN :ProfilesList Added by richa #1972
            List<Deal_Finance__c> dealFinanceList = SOQLUtil.getDealFinanceRecord(new Map<String, String>{'Deal__c' => dealList[0].Id});
            if(!(dealFinanceList.size() > 0)) {
                dealFinanceList.add(new Deal_Finance__c());
            }
	            dealWrapperObj = new DealWrapper(dealList[0], dealItemList, coliList, cokhList, specialOrders, userList, dealUnresolvedFulfillmentList, dealFinanceList[0], dealItemIdToDKHListMap);
            } else {
            	dealWrapperObj = new DealWrapper(dealList[0], dealItemList, dealItemIdToDKHListMap);
            }
            jsonString = System.JSON.serialize(dealWrapperObj);
        } else if(gridName.contains('dealInfo')) {
            DealWrapper.DealInfoWrapper dealWrapperInfoObj = new DealWrapper.DealInfoWrapper(dealList[0]);
            jsonString = System.JSON.serialize(dealWrapperInfoObj);
            
        } else if(gridName.contains('dealWithDealItems')) {
            Set<Id> dealItemIds = new Set<Id>();
            for(Deal_Item__c dealItemRec : dealList[0].Deal_Items__r) {
                dealItemIds.add(dealItemRec.Id);
            }
            List<Deal_Item__c> dealItemList = SOQLUtil.getDealItemDetails(new Set<Id>(dealItemIds));
            jsonString = System.JSON.serialize(new DealWrapper(dealList[0], dealItemList), true);
            
        } else if(gridName.contains('dealMerchandise')) {
            List<CO_Line_Item__c> coliList = SOQLUtil.getCOLineItemByFieldValue(new Map<String, String>{'Deal__c' => dealList[0].Id, 'CO_Kit_Header__c' => null
                                                                                        , 'Service_Order_Line_Item__c' => null});
            List<CO_Kit_Header__c> cokhList = SOQLUtil.getCOKHByFieldValue(new Map<String, String>{'Deal__c' => dealList[0].Id});
             
            List<Vendor_Order_Line_Item__c> specialOrders = SOQLUtil.getSpecialOrderByCOHeaderId(dealList[0].CO_Header__c);
            DealWrapper.DealFulfillmentSectionWrapper DealFulfillmentSectionObj = new DealWrapper.DealFulfillmentSectionWrapper(coliList, cokhList, specialOrders); 
            jsonString = System.JSON.serialize(DealFulfillmentSectionObj);
            
        }  else if(gridName.contains('dealUnresolvedFulfillmentAndDealFulfillment')) {
            List<CO_Line_Item__c> coliList = SOQLUtil.getCOLineItemByFieldValue(new Map<String, String>{'Deal__c' => dealList[0].Id, 'CO_Kit_Header__c' => null
                                                                                        , 'Service_Order_Line_Item__c' => null});
            List<CO_Kit_Header__c> cokhList = SOQLUtil.getCOKHByFieldValue(new Map<String, String>{'Deal__c' => dealList[0].Id});
            
            List<Vendor_Order_Line_Item__c> specialOrders = SOQLUtil.getSpecialOrderByCOHeaderId(dealList[0].CO_Header__c);
            List<Deal_Unresolved_Fulfillment__c> dealUnresolvedFulfillmentList = SOQLUtil.getDealUnresolvedFulfillment(new Map<String, String>{'Deal__c' => dealList[0].Id});
            DealWrapper DealWrapperObj = new DealWrapper(dealUnresolvedFulfillmentList, coliList, cokhList, specialOrders); 
            jsonString = System.JSON.serialize(DealWrapperObj);
            
        } else if(gridName.contains('dealUnresolvedFulfillmentSection')) {
            List<Deal_Unresolved_Fulfillment__c> dealUnresolvedFulfillmentList = SOQLUtil.getDealUnresolvedFulfillment(new Map<String, String>{'Deal__c' => dealList[0].Id});
            List<DealWrapper.DealUnresolvedFulfillmentWrapper> DealUnresolvedFulfillmentWrapperList = new List<DealWrapper.DealUnresolvedFulfillmentWrapper>();
            if((dealUnresolvedFulfillmentList.size() == 0) && (COService.error != null)) {
                if(COService.error.ResponseCode == '300') {
                jsonString = System.JSON.serialize(new DealWrapper.DealUnresolvedFulfillmentWrapper());
                } else if((COService.error.ResponseCode == '200') && (objectName == Constants.NAMESPACE + 'CO_Header__c')) {
                    return ServiceJobService.getSOHeaderDetails(BPUtility.getEncodedString(objectId), BPUtility.getEncodedString('soHeader,soItemGrid,checkOut,specialOrder'));
                }
            }
            for(Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec : dealUnresolvedFulfillmentList){
                DealUnresolvedFulfillmentWrapperList.add(new DealWrapper.DealUnresolvedFulfillmentWrapper(dealUnresolvedFulfillmentRec));
            jsonString = System.JSON.serialize(DealUnresolvedFulfillmentWrapperList);
            }
        } else if(gridName.contains('dealFinanceSection')) {
            List<Deal_Finance__c> dealFinanceList = SOQLUtil.getDealFinanceRecord(new Map<String, String>{'Deal__c' => dealList[0].Id});
            if(!(dealFinanceList.size() > 0)) {
                dealFinanceList.add(new Deal_Finance__c());
            }
            DealWrapper.DealFinanceWrapper dealFinanceSectionObj = new DealWrapper.DealFinanceWrapper(dealFinanceList[0]);
            jsonString = System.JSON.serialize(dealFinanceSectionObj);
        } else if(gridName.contains('dealFAndIProductSection')) {
            List<F_I_Product__c> dealFAndIProductList = SOQLUtil.getDealFAndIProductRecord(new Map<String, String>{'Deal__c' => dealList[0].Id});
            if(dealFAndIProductList.size() == 0) {
                dealFAndIProductList.add(new F_I_Product__c());
            }
            
            DealWrapper.FIProductWrapper dealFAndISectionObj = new DealWrapper.FIProductWrapper(dealFAndIProductList[dealFAndIProductList.size() -1]);
            jsonString = System.JSON.serialize(dealFAndISectionObj);
        }
        
        return BPUtility.getEncodedString(jsonString);
    }

    /**
     * Name: updateDealStatus
     * Desc: Method to update deal status
     * @param:  (1) dealId - String - deal id
     * @param:  (2) dealStatus - String - deal status
     * @return: String - JSON String of deal info section
    **/
    public static String updateDealStatus(String dealId, String dealStatus) {
        dealId = BPUtility.getDecodedString(dealId);
        dealStatus = BPUtility.getDecodedString(dealStatus);
        
        if(String.isBlank(dealId)) {
            return BPUtility.getEncodedString('{}');
        }

        List<SObject> sObjectListToUpdate = new List<SObject>();
        
        Deal__c dealRec = new Deal__c(Id = dealId, Status__c = dealStatus);
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Deal_Item__c> dealItemList = [Select Deal__r.Status__c, Deal__r.Is_Deal_Fulfilled__c, Unit_Make__c, Customer_Owned_unit__r.Unit_Type__c, 
			        	Customer_Owned_unit__c, Customer_Owned_unit__r.Status__c, Customer_Owned_unit__r.Deal_Item__c, Deal__r.CO_Header__c from Deal_Item__c 
			        	where Deal__c = :dealId AND Type__c = :Constants.DEAL_ITEM_TYPE_UNIT];
        
        String dealCurrentStatus;
        String coHeaderId;
        if(dealItemList.size() > 0) { 
            coHeaderId = dealItemList[0].Deal__r.CO_Header__c;
            dealCurrentStatus =  dealItemList[0].Deal__r.Status__c;
        } else { //When deal has Trade in only
            List<Deal__c> dealList = [Select Id, Status__c, CO_Header__c From Deal__c where Id =: dealId];
            coHeaderId = dealList[0].CO_Header__c;
            dealCurrentStatus = dealList[0].Status__c;
        }
        if(dealCurrentStatus.equalsIgnoreCase('Invoiced')){
            throw new BlackPurlException('Deal had modified by some other process, please refresh the page');
        }

        String skuStatus = (dealStatus == 'Quotation') ? 'Available' : 'Reserved';
        String couStatus = (dealStatus == 'Quotation') ? 'Active' : 'Reserved';
        Boolean isOrduCommittedOnDeal = (dealStatus != 'Quotation');
        
		if(dealItemList.size() > 0 && dealStatus != 'Quotation') {
			if(dealCurrentStatus == 'Quotation') {
                Map<String, String> dealItemIdToCOUIdMap = new Map<String, String>();
	        	for(Deal_Item__c dealItemRec : dealItemList) {
					if(dealItemRec.Customer_Owned_Unit__c != null && dealItemRec.Customer_Owned_unit__r.Status__c != 'Available' && 
                        dealItemRec.Customer_Owned_unit__r.Status__c != 'Active') {
                        if(dealItemRec.Customer_Owned_unit__r.Status__c != 'On Order') {
                            return BPUtility.getEncodedString('SoldUnits');
                        } else if(dealItemRec.Customer_Owned_unit__r.Unit_Type__c.equalsIgnoreCase('ORDU') && dealItemRec.Customer_Owned_unit__r.Deal_Item__c != null) {
                            dealItemIdToCOUIdMap.put(dealItemRec.Id, dealItemRec.Customer_Owned_Unit__c);
                        }
					}
				}
                if(!dealItemIdToCOUIdMap.isEmpty()) {
                    List<Deal_Item__c> dealItemRecList = [Select Id, Customer_Owned_Unit__c from Deal_Item__c where Id NOT IN: dealItemIdToCOUIdMap.keySet() AND 
                                                            Customer_Owned_Unit__c IN: dealItemIdToCOUIdMap.values() AND 
                                                            Type__c = :Constants.DEAL_ITEM_TYPE_UNIT LIMIT 1];
                    if(!dealItemRecList.isEmpty()) {
                        return BPUtility.getEncodedString('SoldUnits');
                    }
                }
			} 
			if(dealStatus == 'Approved' && dealStatus != dealCurrentStatus) {
				Set<String> couIdSet = new Set<String>();
				for(Deal_Item__c dealItem : dealItemList) {
					if(dealItem.Customer_Owned_unit__r.Unit_Type__c != null && dealItem.Customer_Owned_Unit__r.Unit_Type__c.equalsIgnoreCase(Constants.UNIT_TYPE_COU)) {
						couIdSet.add(dealItem.Customer_Owned_Unit__c);
					}
				}
				if(couIdSet.size() > 0) {
					List<Service_Order_Header__c> activeSOList = [Select Id from Service_Order_Header__c where Customer_Owned_Unit__c IN: couIdSet AND 
						Invoice_Number__c = null AND Deal__c !=: dealId LIMIT 1];
					if(activeSOList.size() > 0) {
						throw new BlackpurlException('{"HasError" : true, "ErrorMsg" : "Consignment customer has active service jobs on this unit"}');
					}
				}
			}
        }
		
        if(dealStatus == 'Quotation' || (dealItemList.size() > 0 && dealCurrentStatus == 'Quotation' && (dealStatus == 'In progress' || dealStatus == 'Approved'))) {
            for(Deal_Item__c dealItemRec : dealItemList) {
                if(dealItemRec.Customer_Owned_unit__c != null) {
                    //changes made for on ordered units 
                    Customer_Owned_unit__c unitRec  = new Customer_Owned_unit__c(Id = dealItemRec.Customer_Owned_unit__c);
                    if(dealItemRec.Customer_Owned_unit__r.Status__c == Constants.ON_ORDER_STATUS || dealItemRec.Customer_Owned_unit__r.Unit_Type__c.equalsIgnoreCase('ORDU')) {
                        unitRec.Status__c = Constants.ON_ORDER_STATUS;
                        if(dealStatus != 'Quotation') {
                            unitRec.Deal_Item__c = dealItemRec.Id;
                        } else {
                            unitRec.Deal_Item__c = null;
                        }
                    } else if(dealItemRec.Customer_Owned_unit__r.Unit_Type__c != null && dealItemRec.Customer_Owned_unit__r.Unit_Type__c.equalsIgnoreCase(Constants.UNIT_TYPE_COU)) {
                        unitRec.Status__c =  couStatus;
                    } else {
                        unitRec.Status__c = skuStatus;
                    }
                    if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                    sObjectListToUpdate.add(unitRec);
                }
            }
        }
        
        if((dealStatus == 'Quotation' || dealStatus == 'In progress') && (( dealItemList.size() > 0 && dealCurrentStatus == 'Approved'))) {
            List<CO_Invoice_Item__c> invItemList = [Select Id, isActive__c, Is_Invoiceable__c from CO_Invoice_Item__c where Deal__c =: dealId];
            if(invItemList.size() > 0) {
                for(CO_Invoice_Item__c invItemRec : invItemList) {
                    //invItemRec.isActive__c = false;
                    invItemRec.Is_Invoiceable__c = false;
                }
                sObjectListToUpdate.addAll((List<SObject>) invItemList);
            }
        }
        
        if(dealStatus != 'Quotation') {
        	dealRec.Unit_Status__c = Constants.COMMITTED;
        } else if(dealItemList.size() > 0 && dealCurrentStatus != 'Quotation') {
        	dealRec.Unit_Status__c = Constants.UNCOMIITTED;
        } else {
        	dealRec.Unit_Status__c = getDealWithUpdatedStatus(dealId, dealItemList).Unit_Status__c;
        }
        
        
        sObjectListToUpdate.add(dealRec);
        if(AccessControl.ifObjectFieldIsUpdateable('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        update sObjectListToUpdate;
        
        if(dealStatus == 'Approved') {
            List<CO_Invoice_Header__c> activeCOInvHeaderList = [Select Id, (Select Id, isActive__c, Is_Invoiceable__c from CO_Invoice_Items__r where Deal__c =: dealId) 
                    from CO_Invoice_Header__c where CO_Header__c =: coHeaderId AND Invoice_Status__c = 'Active'];  
                
            if(!(activeCOInvHeaderList.size() > 0 && activeCOInvHeaderList[0].CO_Invoice_Items__r.size() > 0 && activeCOInvHeaderList[0].CO_Invoice_Items__r[0].Is_Invoiceable__c && 
                activeCOInvHeaderList[0].CO_Invoice_Items__r[0].isActive__c)) {
                
                CO_Invoice_Item__c invItem = new CO_Invoice_Item__c(isActive__c = true, Is_Invoiceable__c = true, Deal__c = dealId);
                        
                if(activeCOInvHeaderList.size() == 0) {
                    CO_Invoice_Header__c invHeaderRec = new CO_Invoice_Header__c(CO_Header__c = coHeaderId, Invoice_Status__c = 'Active');
                    if(AccessControl.ifObjectFieldIsCreateable('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                    insert invHeaderRec;
                    invItem.CO_Invoice_Header__c = invHeaderRec.Id;
                } else {
                    invItem.CO_Invoice_Header__c = activeCOInvHeaderList[0].Id;
                    if(activeCOInvHeaderList[0].CO_Invoice_Items__r.size() > 0) {
                        invItem.Id = activeCOInvHeaderList[0].CO_Invoice_Items__r[0].Id;
                    }
                }
                Map<String, Boolean> optionNameToOptionValueMap = isDealInvoiceable(dealId);
                invItem.Is_Invoiceable__c = optionNameToOptionValueMap.get('Invoiceable');
                invItem.isActive__c = optionNameToOptionValueMap.get('Active');
                DMLUtility.upsertSobjectList('CO_Invoice_Item__c', invItem);
            }
        }
        return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealInfo'));
    }

    public static String addUnitToDeal(String dealItemId, String unitId, String dealId) {
        unitId = BPUtility.getDecodedString(unitId);
        dealItemId = BPUtility.getDecodedString(dealItemId);
        dealId = BPUtility.getDecodedString(dealId);   
        String result = addUnitToDealOnly(dealItemId, unitId, dealId);
        if(result != 'Success'){
            return result;
        }
        return getDealDetails(BPUtility.getEncodedString(dealId), null);
    }

    public static String addUnitToDealOnly(String dealItemId, String unitId, String dealId) {
        if(AccessControl.ifObjectIsDeletable('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        List<Customer_Owned_Unit__c> unitListToUpdate = new List<Customer_Owned_Unit__c>();
        List<Customer_Owned_Unit__c> unitList = [SELECT Unit_Type__c, Applicable_Tax__c, Stamp_Duty_Calculators__c, Taxable__c,Status__c, Mileage_Value__c, Mileage_Type__c from Customer_Owned_Unit__c WHERE Id =: unitId];
        if(unitList.size() > 0 && (unitList[0].Status__c == 'Reserved' || unitList[0].Status__c == 'Sold')) {
            return BPUtility.getEncodedString('{"HasError" : true, "ErrorMessage" : "Sold units cannot be sell again"}');
        }
        Boolean isAutoEnableTaxNotApplicable = false;
        if(GeneralConfiguration.getConfigurations().Auto_Enable_Tax_On_Deal_By_Customer_Addr__c) {
            List<Deal_Item__c> dealItemList = [Select Id from Deal_Item__c where Deal__c =: dealId AND Customer_Owned_Unit__c != null];
            if(dealItemList.isEmpty()) {
                COService.COSectionTaxDetailWrapper coSectionTaxDetailObj = new COService.COSectionTaxDetailWrapper();
                coSectionTaxDetailObj.DealId = dealId;
                coSectionTaxDetailObj.IsTaxBasedOnCustomerAddress = true;
                try {
                    saveDealTaxInfo(coSectionTaxDetailObj);
                } catch(Exception e) {
                    isAutoEnableTaxNotApplicable = true;
                }
            }
        }
        if(String.isBlank(dealItemId)) {
            Deal_Item__c dealItemRec = new Deal_Item__c(Deal__c = dealId, Customer_Owned_Unit__c = unitId, Type__c = Constants.DEAL_ITEM_TYPE_UNIT, Option_And_Fee_Status__c = Constants.UNCOMIITTED);
            
            if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(unitList.size() > 0) {
                dealItemRec.Mileage__c = unitList[0].Mileage_Value__c;
                dealItemRec.Mileage_Type__c = unitList[0].Mileage_Type__c;
                if(!unitList[0].Unit_Type__c.equalsIgnoreCase(Constants.UNIT_TYPE_COU)) {
                    dealItemRec.Taxable__c = !isAutoEnableTaxNotApplicable ? unitList[0].Taxable__c : false;
                    dealItemRec.Applicable_Tax__c = unitList[0].Applicable_Tax__c;
                }
                dealItemRec.Stamp_Duty_Calculators__c = unitList[0].Stamp_Duty_Calculators__c;
            } else {
            	dealItemRec.Taxable__c = !isAutoEnableTaxNotApplicable;
                dealItemRec.Applicable_Tax__c = DealService.getDefaultTaxOnDUPC();
            }
            DMLUtility.insertSobjectList('Deal_Item__c', dealItemRec);
            
            List<SObject> sObjectListToInsert = COservice.addLinkedFee(dealItemRec.Id, dealId, 'Deal');
            if(sObjectListToInsert != null) {
                if(!AccessControl.ifObjectFieldIsCreateable('CO_Line_Item__c')){throw new BlackPurlException('CO_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                if(!AccessControl.ifObjectFieldIsCreateable('Service_Order_Line_Item__c')){throw new BlackPurlException('Service_Order_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                if(!AccessControl.ifObjectFieldIsCreateable('Option_Fee__c')){throw new BlackPurlException('Option_Fee__c' + DMLUtility.NOT_CREATABLE);}
                insert sObjectListToInsert;
            }
            List<Deal_Unit_Price_Cost__c> dealUnitPriceListToInsert = DealService.addDealUnitCostPrice(new Set<Id>{unitId}, dealItemRec.Id);
            if(dealUnitPriceListToInsert.size() > 0) {
                DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dealUnitPriceListToInsert);
            }
            dealItemId = dealItemRec.Id;
        } else {
            List<Deal_Item__c> dealItemRecList = [SELECT Deal__r.Status__c, Customer_Owned_Unit__c, Unit_Make__c, Customer_Owned_Unit__r.Unit_Type__c, 
            Customer_Owned_Unit__r.Status__c, (Select Id, SO_Status__c, Invoice_Number__c from Service_Order_Headers__r) 
            from Deal_Item__c WHERE Id =: dealItemId];
            if(dealItemRecList.size() > 0) {
                if(dealItemRecList[0].Service_Order_Headers__r.size() > 0) {
                    for(Service_Order_Header__c soRec : dealItemRecList[0].Service_Order_Headers__r) {
                        if(soRec.SO_Status__c == ServiceJobUtil.INVOICED || soRec.Invoice_Number__c != null) {
                            throw new BlackpurlException('Unit cannot be replaced when related deal service is invoiced');
                        } else {
                            soRec.Customer_Owned_Unit__c = unitId;
                        }
                    }
                    update dealItemRecList[0].Service_Order_Headers__r;
                }
                if(String.isBlank(dealItemRecList[0].Unit_Make__c) && String.isBlank(dealItemRecList[0].Customer_Owned_Unit__c)) {
                    List<SObject> sObjectListToInsert = COservice.addLinkedFee(dealItemId, dealId, 'Deal');
                    if(sObjectListToInsert != null) {
                        if(!AccessControl.ifObjectFieldIsCreateable('CO_Line_Item__c')){throw new BlackPurlException('CO_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                        if(!AccessControl.ifObjectFieldIsCreateable('Service_Order_Line_Item__c')){throw new BlackPurlException('Service_Order_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                        if(!AccessControl.ifObjectFieldIsCreateable('Option_Fee__c')){throw new BlackPurlException('Option_Fee__c' + DMLUtility.NOT_CREATABLE);}
                        insert sObjectListToInsert;
                    }
                } else if(String.isNotBlank(dealItemRecList[0].Customer_Owned_Unit__c) && dealItemRecList[0].Customer_Owned_Unit__r.Status__c != 'Sold' 
                			 && String.isNotBlank(unitId) && dealItemRecList[0].Customer_Owned_Unit__c != unitId) {
                    //For changing unit-1 to unit-2
                    if(dealItemRecList[0].Customer_Owned_Unit__r.Unit_Type__c.equalsIgnoreCase('ORDU')) {
                        if(dealItemRecList[0].Customer_Owned_Unit__r.Status__c == Constants.ON_ORDER_STATUS && !dealItemRecList[0].Deal__r.Status__c.equalsIgnoreCase('Quotation')) {
                            unitListToUpdate.add(new Customer_Owned_Unit__c(Id = dealItemRecList[0].Customer_Owned_Unit__c, Deal_Item__c = null));
                        } else if(dealItemRecList[0].Customer_Owned_Unit__r.Status__c == Constants.TEMP_ORDERD_UNIT_STATUS || dealItemRecList[0].Customer_Owned_Unit__r.Status__c == Constants.REQ_ORDERD_UNIT_STATUS) {
                            List<SObject> sobjDeleteList = new List<SObject>{dealItemRecList[0].Customer_Owned_Unit__r};
                            sobjDeleteList.addAll((List<SObject>)[Select Id FROM Unit_Price_Cost__c WHERE Customer_Owned_Unit__c =: dealItemRecList[0].Customer_Owned_Unit__c]);
                            delete sobjDeleteList;
                        }
                    } else {
                    	unitListToUpdate.add(new Customer_Owned_Unit__c(Id = dealItemRecList[0].Customer_Owned_Unit__c, Status__c = DealService.getUnitStatusByUnitAnddealItemId(dealItemRecList[0].Customer_Owned_Unit__c, dealItemRecList[0].Id, dealItemRecList[0].Customer_Owned_Unit__r.Unit_Type__c)));
                    }
                }
            }
            
            Deal_Item__c dealItemRec = new Deal_Item__c(Id = dealItemId, Customer_Owned_Unit__c = unitId, Type__c = Constants.DEAL_ITEM_TYPE_UNIT,
                                                Is_Rideaway_Pricing_Enabled__c = false, Rideaway_Pricing_Total__c = 0);
            if(unitId != null) {
                dealItemRec.Colour__c = null;
                dealItemRec.Unit_Make__c = null;
                dealItemRec.Unit_Model__c = null;
                dealItemRec.Year__c = null;
                dealItemRec.Sub_Model__c = null; 
            }
            
            if(unitList.size() > 0) {
                dealItemRec.Mileage__c = unitList[0].Mileage_Value__c;
                dealItemRec.Mileage_Type__c = unitList[0].Mileage_Type__c;
                if(!unitList[0].Unit_Type__c.equalsIgnoreCase(Constants.UNIT_TYPE_COU)) {
                    dealItemRec.Taxable__c = !isAutoEnableTaxNotApplicable ? unitList[0].Taxable__c : false;
                    dealItemRec.Applicable_Tax__c = unitList[0].Applicable_Tax__c;
                }
                dealItemRec.Stamp_Duty_Calculators__c = unitList[0].Stamp_Duty_Calculators__c;
            } else {
            	dealItemRec.Taxable__c = !isAutoEnableTaxNotApplicable;
                dealItemRec.Applicable_Tax__c = DealService.getDefaultTaxOnDUPC();
            }
            DMLUtility.updateSobjectList('Deal_Item__c', dealItemRec);
            
            if(AccessControl.ifObjectFieldIsAccessible('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Deal_Unit_Price_Cost__c>  DealUnitPriceCostTodelete = [select Id  from Deal_Unit_Price_Cost__c where Deal_Item__c =:dealItemId];
            DMLUtility.deleteSObjectList('Deal_Unit_Price_Cost__c', DealUnitPriceCostTodelete);
            set<Id> unitIds =  new set<Id>{unitId };
            List<Deal_Unit_Price_Cost__c> dealUnitPriceListToinsert = DealService.addDealUnitCostPrice(unitIds, dealItemRec.Id);
            if(dealUnitPriceListToinsert.size() > 0) {
                DealUnitPriceAndCostTriggerHelper.isTriggerExecute = true;
                DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dealUnitPriceListToinsert);
            }
        }
        updateStatusForDeal(dealId);
        
        if(String.isNotBlank(unitId)) {
            List<Deal_Item__c> dealItemList = [Select Id, Deal__r.Status__c,Customer_Owned_Unit__r.Status__c from Deal_Item__c where Id =: dealItemId];
            if(dealItemList.size() > 0) {
                if(dealItemList[0].Deal__r.Status__c == 'In Progress' && dealItemList[0].Customer_Owned_Unit__r.Status__c != Constants.ON_ORDER_STATUS) {
                unitListToUpdate.add(new Customer_Owned_Unit__c(Id = unitId, Status__c = 'Reserved'));
                } else if(dealItemList[0].Customer_Owned_Unit__r.Status__c == Constants.ON_ORDER_STATUS && !dealItemList[0].Deal__r.Status__c.equalsIgnoreCase('Quotation')) {
                    unitListToUpdate.add(new Customer_Owned_Unit__c(Id = unitId, Deal_Item__c = dealItemList[0].Id));
            	}
        	}
        }
        DMLUtility.updateSObjectList('Customer_Owned_Unit__c', unitListToUpdate);
        return 'Success';
    }

    public static String updateDealUnitCostPrice(String DealUnitCostPriceItemjson, String dealId, String dealItemId) { 
        dealItemId = BPUtility.getDecodedString(dealItemId); 
        dealId = BPUtility.getDecodedString(dealId);   
        DealUnitCostPriceItemjson = BPUtility.getDecodedString(DealUnitCostPriceItemjson);
        List<DealWrapper.FactoryOption>  DealUnitCostPriceList = (List<DealWrapper.FactoryOption>) System.JSON.deserialize(DealUnitCostPriceItemjson, List<DealWrapper.FactoryOption>.class);
        //List<Deal_Unit_Price_Cost__c> DealUnitPriceCostList = new List<Deal_Unit_Price_Cost__c>();
        
        List<Deal_Unit_Price_Cost__c> dealUnitPriceCostListToInsert = new List<Deal_Unit_Price_Cost__c>();
        List<Deal_Unit_Price_Cost__c> dealUnitPriceCostListToUpdate = new List<Deal_Unit_Price_Cost__c>();
        
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        for(DealWrapper.FactoryOption unitPriceCostRec : DealUnitCostPriceList) {
            Deal_Unit_Price_Cost__c dealUnitPriceCostRec = new Deal_Unit_Price_Cost__c();
            dealUnitPriceCostRec.Id = unitPriceCostRec.Id;
            dealUnitPriceCostRec.Deal_Item__c = dealItemId;
            dealUnitPriceCostRec.Type__c = unitPriceCostRec.Type;
            dealUnitPriceCostRec.Price__c = unitPriceCostRec.Price;
            dealUnitPriceCostRec.Qty__c = unitPriceCostRec.Qty;
            dealUnitPriceCostRec.Price_When_Tax_Included__c = unitPriceCostRec.Price; 
            if(isTaxIncludingPricing) {
                if(unitPriceCostRec.Price == null) {
                    unitPriceCostRec.Price = 0;
                }
                if(unitPriceCostRec.SalesTaxPercentage == null) {
                    unitPriceCostRec.SalesTaxPercentage = 0;
                }
                if(String.isNotBlank(unitPriceCostRec.Id)) {
                    dealUnitPriceCostRec.Price__c = (unitPriceCostRec.Price / (1 + unitPriceCostRec.SalesTaxPercentage / 100));
                    dealUnitPriceCostListToUpdate.add(dealUnitPriceCostRec);
                } else {
                    if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                    List<Deal_Item__c> dealItemList = [Select Customer_Owned_Unit__c, Customer_Owned_Unit__r.Applicable_Tax__r.Rate__c from Deal_Item__c where Id =: dealItemId];
                    if(dealItemList.size() > 0 && dealItemList[0].Customer_Owned_Unit__c != null) {
                        if(dealItemList[0].Customer_Owned_Unit__r.Applicable_Tax__r.Rate__c != null) {
                        unitPriceCostRec.SalesTaxPercentage = dealItemList[0].Customer_Owned_Unit__r.Applicable_Tax__r.Rate__c;
                    }
                    }  else {
                        String defaultSalesTaxId = Configurations__c.getInstance().Default_Tax_on_Unit__c;
                        if(String.isNotBlank(defaultSalesTaxId)) {
                            List<Sales_Tax__c> defaultSalesTaxList = [select Id, Rate__c from Sales_Tax__c where Id =: defaultSalesTaxId];
                            unitPriceCostRec.SalesTaxPercentage = defaultSalesTaxList[0].Rate__c;
                        } else {
                            List<Sales_Tax__c> defaultSalesTaxList = [select Id, Rate__c from Sales_Tax__c where Default__c = true];
                            if(defaultSalesTaxList.size() > 0) {
                                unitPriceCostRec.SalesTaxPercentage = defaultSalesTaxList[0].Rate__c;
                            }
                        }
                    }
                    dealUnitPriceCostRec.Price__c = (unitPriceCostRec.Price * (1 + unitPriceCostRec.SalesTaxPercentage / 100));
                    dealUnitPriceCostListToInsert.add(dealUnitPriceCostRec);
                }
            } else {
                if(String.isNotBlank(unitPriceCostRec.Id)) {
                    dealUnitPriceCostListToUpdate.add(dealUnitPriceCostRec);
                } else {
                     dealUnitPriceCostListToInsert.add(dealUnitPriceCostRec);
                }
            }
        }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        if(dealUnitPriceCostListToInsert.size() > 0){
            DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dealUnitPriceCostListToInsert);
            if(isTaxIncludingPricing) {
                Set<String> idList = new Set<String>();
                for(Deal_Unit_Price_Cost__c unitPriceCostRec : dealUnitPriceCostListToInsert) {
                    idList.add(unitPriceCostRec.Id);
                }
                dealUnitPriceCostListToInsert.clear();
                dealUnitPriceCostListToInsert =  [Select Price__c, Sales_Tax_Percentage__c from Deal_Unit_Price_Cost__c where Id In :idList];
                for(Deal_Unit_Price_Cost__c unitPriceCostRec : dealUnitPriceCostListToInsert) {
                    if(unitPriceCostRec.Price__c == null) {
                        unitPriceCostRec.Price__c = 0;
                    }
                    if(unitPriceCostRec.Sales_Tax_Percentage__c == null) {
                        unitPriceCostRec.Sales_Tax_Percentage__c = 0;
                    }
                    unitPriceCostRec.Price__c = (unitPriceCostRec.Price__c / (1 + unitPriceCostRec.Sales_Tax_Percentage__c / 100));
                    dealUnitPriceCostListToUpdate.add(unitPriceCostRec);
                }
            }
        }
        if(dealUnitPriceCostListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Deal_Unit_Price_Cost__c', dealUnitPriceCostListToUpdate);
        }
        //OptionAndFeeTriggerHelper.updateDealTotal(new Set<String>{dealId});
        return getDealItemDetails(dealItemId);  
    }

    public static String toggleRideawayPricingEnabled(String dealItemId, Decimal totalEnforceRideawayPrice, Boolean IsRideawayPricingEnabled) {
        try {
            dealItemId = BPUtility.getDecodedString(dealItemId);
            
            Deal_Item__c dealItemRec = new Deal_Item__c(Id = dealItemId);
            dealItemRec.Is_Rideaway_Pricing_Enabled__c = IsRideawayPricingEnabled;
            dealItemRec.Rideaway_Pricing_Total__c = totalEnforceRideawayPrice.setScale(2, RoundingMode.HALF_UP);
            DMLUtility.updateSobjectList('Deal_Item__c', dealItemRec);
            
            return getDealItemDetails(dealItemId);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    public static String updateStampDuty(String dealItemId, String stampDutyTotal) {
        dealItemId = BPUtility.getDecodedString(dealItemId);
        stampDutyTotal = BPUtility.getDecodedString(stampDutyTotal); 
        DMLUtility.updateSobjectList('Deal_Item__c', new Deal_Item__c(Id = dealItemId, Stamp_Duty_Total__c = Decimal.valueOf(stampDutyTotal), Is_Override_Stamp_Duty__c = true));
        return getDealItemDetails(dealItemId);
    }


    public static String updateStampDutyCalAndDutiableValue(String dealItemId, String stampDutyCalId, String dutiableValue, string tempUnitId) {
        dealItemId = BPUtility.getDecodedString(dealItemId);
        stampDutyCalId = BPUtility.getDecodedString(stampDutyCalId); 
        dutiableValue = BPUtility.getDecodedString(dutiableValue); 
        List<Deal_Item__c> dealItemList = [SELECT Id, Deal__c FROM Deal_Item__c WHERE Id =: dealItemId];
        if(dealItemList.isEmpty()) { throw new BlackPurlException('No unit found.'); } 
        DMLUtility.updateSobjectList('Deal_Item__c', new Deal_Item__c(Id = dealItemId, Dutiable_Value__c = (String.isNotBlank(dutiableValue) ? Decimal.valueOf(dutiableValue) : null), Stamp_Duty_Calculators__c = stampDutyCalId));
        
        // This will assign same stamp duty calculator to the temp unit as we have for the deal item.
        if(String.isNotBlank(tempUnitId)) {
            tempUnitId = BPUtility.getDecodedString(tempUnitId); 
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', new Customer_Owned_Unit__c(Id = tempUnitId, Stamp_Duty_Calculators__c = stampDutyCalId));
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
        }
        OptionAndFeeTriggerHelper.updateRideawayPricingAndStampDuty(new Set<String> {dealItemId}); 
        OptionAndFeeTriggerHelper.updateDealTotal(new Set<String> {dealItemList[0].deal__c}); 
        
        return getDealItemDetails(dealItemId);
    }

    public static String updateRideawayPricing(String dealItemId, String unitJsonString) {
        try {
            dealItemId = BPUtility.getDecodedString(dealItemId);
            unitJsonString = BPUtility.getDecodedString(unitJsonString);
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            
            DealWrapper.UnitSectionWrapper unitSectionObj = (DealWrapper.UnitSectionWrapper) System.JSON.deserialize(unitJsonString, DealWrapper.UnitSectionWrapper.class);
            List<Deal_Item__c>  dealItemList = [Select Stamp_Duty_Total__c, Is_Override_Stamp_Duty__c, Rideaway_Pricing_Total__c, Dutiable_Value__c, Stamp_Duty_Calculators__c, Stamp_Duty_Calculators__r.Calculation_Method__c, 
                                                Stamp_Duty_Calculators__r.L1_Per__c, Stamp_Duty_Calculators__r.L1_Rate__c, Stamp_Duty_Calculators__r.L1_Value__c, Stamp_Duty_Calculators__r.L2_Per__c, Stamp_Duty_Calculators__r.L2_Rate__c, 
                                                Stamp_Duty_Calculators__r.L2_Value__c, Stamp_Duty_Calculators__r.L3_Per__c, Stamp_Duty_Calculators__r.L3_Rate__c, Stamp_Duty_Calculators__r.L3_Value__c, Stamp_Duty_Calculators__r.L4_Per__c, 
                                                Stamp_Duty_Calculators__r.L4_Rate__c, Stamp_Duty_Calculators__r.L4_Value__c, Stamp_Duty_Calculators__r.Maximum__c, Stamp_Duty_Calculators__r.Minimum__c, 
                                                    (Select Id, Price__c, Price_When_Tax_Included__c, Qty__c, Type__c, Sales_Tax_Percentage__c from Deal_Unit_Prices_Costs__r where Type__c = 'Base') 
                                                FROM Deal_Item__c where Id =: dealItemId];          
            if(dealItemList.size() > 0){
                Deal_Item__c dealItemRec = dealItemList[0];
                if(unitSectionObj.IsRideawayPricingEnabled) {                   
                                        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                    
                    Decimal subTotal = (unitSectionObj.TotalEnforceRideawayPrice != null ? unitSectionObj.TotalEnforceRideawayPrice : 0) - unitSectionObj.TotalFee;
                    Decimal stampDutyTotal = StampDutyService.getCalculatedStampDuty(dealItemRec, (dealItemRec.Dutiable_Value__c != null ? dealItemRec.Dutiable_Value__c : subTotal));
                    
                    Decimal totalBasePrice = (unitSectionObj.TotalEnforceRideawayPrice != null ? unitSectionObj.TotalEnforceRideawayPrice : 0) - 
                                            (stampDutyTotal + 
                                            (unitSectionObj.TotalFactoryOption != null ? unitSectionObj.TotalFactoryOption : 0) 
                                            + (unitSectionObj.TotalDealerInstalledOption != null ? unitSectionObj.TotalDealerInstalledOption : 0)
                                            + (unitSectionObj.TotalPartAndLabor != null ? unitSectionObj.TotalPartAndLabor : 0)
                                            + unitSectionObj.TotalFee + unitSectionObj.TotalSublet);
                    
                    dealItemRec.Rideaway_Pricing_Total__c = (unitSectionObj.TotalEnforceRideawayPrice != null ? unitSectionObj.TotalEnforceRideawayPrice : 0);
                    dealItemRec.Stamp_Duty_Total__c = stampDutyTotal;
                    DMLUtility.updateSobjectList('Deal_Item__c', dealItemRec);

                    List<Deal_Unit_Price_Cost__c> dealUnitPriceCostList = new List<Deal_Unit_Price_Cost__c>();
                    if(dealItemRec.Deal_Unit_Prices_Costs__r.size() > 0)    {
                        for(Deal_Unit_Price_Cost__c dealUnitpriceCostRec : dealItemRec.Deal_Unit_Prices_Costs__r) {
                                if(isTaxIncludingPricing) {
                                    dealUnitpriceCostRec.Price_When_Tax_Included__c = (totalBasePrice/((DealUnitpriceCostRec.Qty__c != null||DealUnitpriceCostRec.Qty__c == 0) ? DealUnitpriceCostRec.Qty__c : 1));
                                    dealUnitpriceCostRec.Price__c = (dealUnitpriceCostRec.Price_When_Tax_Included__c / (1 + dealUnitpriceCostRec.Sales_Tax_Percentage__c / 100));
                                } else {
                                    dealUnitpriceCostRec.Price__c = (totalBasePrice/((DealUnitpriceCostRec.Qty__c != null||DealUnitpriceCostRec.Qty__c == 0) ? DealUnitpriceCostRec.Qty__c : 1));
                                }
                                dealUnitPriceCostList.add(dealUnitpriceCostRec);
                        }
                        if(dealUnitPriceCostList.size() > 0) {
                            DMLUtility.updateSobjectList('Deal_Unit_Price_Cost__c', dealUnitPriceCostList);
                        }
                        
                    } else {
                        List<DealWrapper.BaseUnitPrice> baseUnitPriceList = new List<DealWrapper.BaseUnitPrice>();
                        DealWrapper.BaseUnitPrice baseUnitPrice = new DealWrapper.BaseUnitPrice();
                        baseUnitPrice.Type = 'Base';
                        baseUnitPrice.Qty = 1;
                        baseUnitPrice.Price = totalBasePrice;
                        
                        baseUnitPriceList.add(baseUnitPrice);
                        String baseUnitPriceJsonString = System.JSON.serialize(baseUnitPriceList);
                        
                        // TO Do - Improve Performace.
                        updateDealUnitCostPrice(BPUtility.getEncodedString(baseUnitPriceJsonString), BPUtility.getEncodedString(unitSectionObj.DealItemObj.Deal), BPUtility.getEncodedString(unitSectionObj.DealItemObj.Id));
                    }
                }
            }
            return getDealItemDetails(dealItemId);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    /**
     * Name: getDealItemDetails
     * Desc: Method which gives deal item rec using deal item id
     * @param:  (1) dealItemId - String - deal item id
     * @return: String - JSON String of deal item
    **/
    public static String getDealItemDetails(String dealItemId) {
        List<Deal_Item__c> dealItemList = SOQLUtil.getDealItemDetails(new Set<Id>{dealItemId});
        /*
        DealWrapper.UnitSectionWrapper unitSectionObj = new DealWrapper.UnitSectionWrapper(new Deal_Item__c());
        if(dealItemList.size() > 0) {
            unitSectionObj = new DealWrapper.UnitSectionWrapper(dealItemList[0]);
        }
        return BPUtility.getEncodedString(System.JSON.serialize(unitSectionObj));
        */
        //START: Added by Nidhi - 26-11-2016
        if(dealItemList.size() > 0) {
            if(String.isNotBlank(dealItemList[0].Type__c) && dealItemList[0].Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                DealItem tradeInObj = new DealItem(dealItemList[0]);
                return BPUtility.getEncodedString(System.JSON.serialize(tradeInObj));
            } else {
                Map<Id, List<Deal_Kit_Header__c>> dealItemIdToDKHListMap = new Map<Id, List<Deal_Kit_Header__c>>();
                List<Deal_Kit_Header__c> dealKitHeaderList = SOQLUtil.getDealKitHeaderDetailsByDealItemId(new Set<Id>{dealItemId});
                
                DealWrapper.UnitSectionWrapper unitSectionObj = new DealWrapper.UnitSectionWrapper(dealItemList[0], dealKitHeaderList);
                
                return BPUtility.getEncodedString(System.JSON.serialize(unitSectionObj));
            }
        }
        return BPUtility.getEncodedString('{}');
        //END: Added by Nidhi - 26-11-2016
    }

    public static void updateStatusForDeal(String dealId) {
        updateStatusForDeal(dealId, true);
    }

    public static Deal__c updateStatusForDeal(String dealId, Boolean isUpdate) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Deal_Item__c> dealItemList = [Select Id, Deal__r.Status__c, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Unit_Type__c, Customer_Owned_Unit__r.Status__c, Unit_Make__c, Customer_Owned_Unit__r.Deal_Item__c from Deal_Item__c where Deal__c = :dealId AND Type__c = :Constants.DEAL_ITEM_TYPE_UNIT];
        
        Deal__c dealRec = getDealWithUpdatedStatus(dealId, dealItemList);
        if(isUpdate != null && isUpdate) {
            DMLUtility.updateSobjectList('Deal__c', dealRec);
        }
        return dealRec;
    }

    /**
    * Name: saveOptionFeesLineItem
    * Desc: Method Which saves Option & Fees Line Items in Database 
    * @param:   (1) dealId - String - Deal id   
    * @param:   (2) jSONString - String - JSON String of Option & Fees Line Items
    * @return: String - JSON String of Option & Fees Record
    **/
    public static String saveOptionFeesLineItem(String dealId, String dealItemId, String jSONString) {
        dealId = BPUtility.getDecodedString(dealId);
        dealItemId = BPUtility.getDecodedString(dealItemId);
        jSONString = BPUtility.getDecodedString(jSONString);
        COService.validateSectionStatus(dealId);
    
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
       
        Decimal price = 0.00;
        Boolean isNewOptionAndFee = false;
        Boolean previousIsInstall;
        DealWrapper.OptionAndFeeInfo optionAndFeeInfoObjRec = (DealWrapper.OptionAndFeeInfo) System.JSON.deserialize(jSONString, DealWrapper.OptionAndFeeInfo.class);
        Option_Fee__c envFeeLineItemRec = new Option_Fee__c();
        if(optionAndFeeInfoObjRec.Id == null) {
            if(String.isNotBlank(optionAndFeeInfoObjRec.KitHeaderId)) {
                Id DealKitHeaderId = insertDealKitHeaderInGrid(optionAndFeeInfoObjRec.KitHeaderId, dealItemId, dealId, null, optionAndFeeInfoObjRec.UUID);
            } else if(String.isNotBlank(optionAndFeeInfoObjRec.FeeId)) {
                if(AccessControl.ifObjectFieldIsAccessible('Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Fee__c> feeList = [Select Code__c, Description__c, Price__c from Fee__c where Id = :optionAndFeeInfoObjRec.FeeId];
                if(feeList.size() > 0) {
                    price = feeList[0].Price__c;
                    optionAndFeeInfoObjRec.ItemCode = feeList[0].Code__c;
                    optionAndFeeInfoObjRec.ItemDescription = feeList[0].Description__c;
                }
            } else if(String.isNotBlank(optionAndFeeInfoObjRec.LabourId)) {
                if(AccessControl.ifObjectFieldIsAccessible('Labour_Code__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Labour_Code__c> labourList = [Select Code__c, Description__c, Rate__c, Hours__c from Labour_Code__c where Id = :optionAndFeeInfoObjRec.LabourId];
                if(labourList.size() > 0) {
                    price = labourList[0].Rate__c;
                    optionAndFeeInfoObjRec.ItemCode = labourList[0].Code__c;
                    optionAndFeeInfoObjRec.ItemDescription = labourList[0].Description__c;
                    //Start: Ticket#1841: Added By Pooja 10 Apr. 2017
                    if(optionAndFeeInfoObjRec.Id == null)   {
                        optionAndFeeInfoObjRec.Qty = labourList[0].Hours__c;
                    }
                    //End: Ticket#1841: Added By Pooja 10 Apr. 2017
                }
            } else if(String.isNotBlank(optionAndFeeInfoObjRec.ProductId)) {
                if(AccessControl.ifObjectFieldIsAccessible('Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Product__c> productList = [Select Code__c, Description__c, Price__c from Product__c where Id = :optionAndFeeInfoObjRec.ProductId];
                if(productList.size() > 0) {
                    price = productList[0].Price__c;
                    optionAndFeeInfoObjRec.ItemCode = productList[0].Code__c;
                    optionAndFeeInfoObjRec.ItemDescription = productList[0].Description__c;
                }
            } else if(String.isNotBlank(optionAndFeeInfoObjRec.PartId)){
                if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Part__c> partList = [Select Part_Number__c, Description__c from Part__c where Id = :optionAndFeeInfoObjRec.PartId];
                if(partList.size() > 0) {
                    optionAndFeeInfoObjRec.ItemCode = partList[0].Part_Number__c;
                    optionAndFeeInfoObjRec.ItemDescription = partList[0].Description__c;
                }
                price = optionAndFeeInfoObjRec.Price;
                
                // Create one Extra line for Env Fee
                if(optionAndFeeInfoObjRec.Id == null) {
                    envFeeLineItemRec = createEnvFeeLineItemInDealSection(optionAndFeeInfoObjRec.PartId, dealId, dealItemId, optionAndFeeInfoObjRec.UUID);
                }
            }
            if(optionAndFeeInfoObjRec.IsInstall == true){
                for(Deal__c dealRec : [Select Id, Is_Commit_And_Install_Action_Initiated__c, Is_Deal_Fulfilled__c from Deal__c 
                where Id =: dealId AND (Is_Commit_And_Install_Action_Initiated__c = true OR Is_Deal_Fulfilled__c = true)]) {
                    dealRec.Is_Commit_And_Install_Action_Initiated__c = false;
                    dealRec.Is_Deal_Fulfilled__c = false;
                    DealTriggerHelper.isForceStopTrigger = true;
                    DMLUtility.updateSobjectList('Deal__c', dealRec);
                    DealTriggerHelper.isForceStopTrigger = false;
                }
            }
            if(String.isNotBlank(optionAndFeeInfoObjRec.KitHeaderId)) {
                return getDealItemDetails(dealItemId);
            }
        } else {
            price = optionAndFeeInfoObjRec.Price;
        }
        if(price == null) {
            price = 0;
        }
        if(isTaxIncludingPricing) {
            if(optionAndFeeInfoObjRec.SalesTaxPercentage == null) {
                optionAndFeeInfoObjRec.SalesTaxPercentage = 0;
            } 
            price = (price / (1 + (optionAndFeeInfoObjRec.SalesTaxPercentage / 100))).setScale(2, RoundingMode.HALF_UP);
        } 
        Option_Fee__c optionAndFeeInfoRecToUpsert = setOptionAndFeeRecord(dealId, optionAndFeeInfoObjRec, price);
        Option_Fee__c prevRec;
        if(String.isBlank(optionAndFeeInfoRecToUpsert.Id)) {
            optionAndFeeInfoRecToUpsert.Status__c = Constants.UNCOMIITTED;
            isNewOptionAndFee = true;
            List<Option_Fee__c> optionFeeListToInsert = new List<Option_Fee__c>();
            optionFeeListToInsert.add(optionAndFeeInfoRecToUpsert);
            if(envFeeLineItemRec.Fee__c != null) {
                optionFeeListToInsert.add(envFeeLineItemRec);
            }
            DMLUtility.insertSobjectList('Option_Fee__c', optionFeeListToInsert);
            if(optionAndFeeInfoRecToUpsert.Product__c != null) {
                COFormService.insertDefaultCOForms(null, dealId, optionAndFeeInfoRecToUpsert.Product__c);
            }
        } else {
            if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Option_fee__c> optionAndFeeList =  [Select Is_Install__c, CO_Line_Item__c, Service_Order_Line_Item__c from Option_Fee__c where Id = :optionAndFeeInfoRecToUpsert.Id];
            if(optionAndFeeList.size() > 0) {
                prevRec = optionAndFeeList[0];
                List<Deal_Item__c> dealItemList = [Select Option_And_Fee_Status__c, Deal__r.Status__c, Deal__r.Unit_Status__c, Deal__r.CO_Header__c from Deal_Item__c where Deal__c = :dealId];
                if(!isNewOptionAndFee && (prevRec.CO_Line_Item__c != null || prevRec.Service_Order_Line_Item__c != null) 
                && prevRec.Is_Install__c != optionAndFeeInfoRecToUpsert.Is_Install__c && dealItemList.size() > 0 && (dealItemList[0].Deal__r.Status__c == Constants.IN_PROGRESS || dealItemList[0].Deal__r.Status__c == 'Approved') && dealItemList[0].Option_And_Fee_Status__c == Constants.COMMITTED) {
                    OptionAndFeeTriggerHelper.isForceStopTrigger = true;
                    DMLUtility.updateSobjectList('Option_Fee__c', optionAndFeeInfoRecToUpsert);
                    OptionAndFeeTriggerHelper.isForceStopTrigger = false;
                    return moveDealMerchAndServiceLineItems(BPUtility.getEncodedString(optionAndFeeInfoRecToUpsert.Id), BPUtility.getEncodedString(dealItemList[0].Deal__r.CO_Header__c));
                } else {
                    DMLUtility.updateSobjectList('Option_Fee__c', optionAndFeeInfoRecToUpsert);
                }
            }
        }
        return getDealItemDetails(dealItemId);
    }

    public static String moveDealMerchAndServiceLineItems(String optionFeeRecId, String coHeaderId) {
        optionFeeRecId = BPUtility.getDecodedString(optionFeeRecId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        Savepoint sp = Database.setSavepoint();
        try {
            String objectName = (Id.valueOf(optionFeeRecId)).getSObjectType().getDescribe().getName();
            if(objectName == Constants.NAMESPACE + 'Deal_Kit_Header__c') {
                moveDealKit(optionFeeRecId, coHeaderId);
            } else if(objectName == Constants.NAMESPACE + 'Option_Fee__c') {
                moveOptionAndFeeLineItem(optionFeeRecId, coHeaderId);
            }
        } catch(Exception e) {
            Database.rollback(sp);
            system.assert(false, e);
        }
        return '';
    }

    public static String removeOptionFeesLineItem(String dealItemId, String lineItemId) {
        dealItemId = BPUtility.getDecodedString(dealItemId);
        lineItemId = BPUtility.getDecodedString(lineItemId);
        COService.validateSectionStatus(dealItemId);
    
        String dealId = '';
        String objectName = (Id.valueOf(lineItemId)).getSObjectType().getDescribe().getName();
        if(objectName == CONSTANTS.NAMESPACE + 'Option_Fee__c') {
        if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Option_Fee__c> optionFeeRecordToDelete = [select Deal__r.Status__c, Deal__c from Option_Fee__c where Id =: lineItemId];
            dealId = optionFeeRecordToDelete[0].Deal__c;
            if(optionFeeRecordToDelete.size() > 0 && optionFeeRecordToDelete[0].Deal__r.Status__c != 'Invoiced') {
            if(AccessControl.ifObjectIsDeletable('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete optionFeeRecordToDelete[0];
        }
        } else if(objectName == CONSTANTS.NAMESPACE + 'Deal_Kit_Header__c') {
            dealId = removeDealKHItems(lineItemId);
        }
        //OptionAndFeeTriggerHelper.updateDealTotal(new Set<String>{dealId});
        return getDealItemDetails(dealItemId);
    }

    private static String removeDealKHItems(String lineItemId) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable('Deal_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        
        lineItemId = BPUtility.escapeSingleQuotes(lineItemId);

        List<Deal_Kit_Header__c> dealKHList = [select Id, Deal_Item__r.Deal__c, Deal_Item__r.Deal__r.Status__c, 
                                                    (Select Id from Options_Fees__r) from Deal_Kit_Header__c where Id =: lineItemId];
        String dealId = dealKHList[0].Deal_Item__r.Deal__c;
        if(dealKHList[0].Deal_Item__r.Deal__r.Status__c != 'Invoiced') {
        List<SObject> sObjectListToDelete = new List<SObject>();
        sObjectListToDelete.addAll((List<SObject>) dealKHList);
        for(Deal_Kit_Header__c dealKHRec : dealKHList) {
            if(dealKHRec.Options_Fees__r != null && dealKHRec.Options_Fees__r.size() > 0) {
                sObjectListToDelete.addAll((List<SObject>) dealKHRec.Options_Fees__r);
            }
        }
        if(sObjectListToDelete.size() > 0) {
            delete sObjectListToDelete;
        }
        }
        return dealId;
    }

    private static Id insertDealKitHeaderInGrid(String lineItemId, String dealItemId, String dealId, String coHeaderId, String UUID) {
        Savepoint sp = Database.setSavepoint();
        try {
            
            if(AccessControl.ifObjectFieldIsAccessible('Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Kit_Header__c> kitHeaderList = SOQLUtil.getKitHeaderRec(new Map<String, String>{ 'Id' => lineItemId });
            if(kitHeaderList.size() == 0) {
                return null;
            }
            
            Deal_Kit_Header__c dkhRec = setDealKitHeaderFields(kitHeaderList[0]);
            dkhRec.Deal_Item__c = dealItemId;
            dkhRec.UUID__c = UUID;
            if(kitHeaderList[0].Service_Kit__c != null && kitHeaderList[0].Service_Kit__c) {
                dkhRec.Is_Install__c = true;
            } else {
                dkhRec.Is_Install__c = false;
            }
            DMLUtility.insertSobjectList('Deal_Kit_Header__c', dkhRec);
            
            insertAllKitLineItemsInDeal(lineItemId, dealItemId, dealId, dkhRec.Id, Constants.UNCOMIITTED, null, null);
            
            DealKH_Recalculation.calculatePriceForDealKitInsertion(dkhRec.Id, dealItemId);
            return dkhRec.Id;
        } catch(Exception e) {
            Database.rollback(sp);
            system.assert(false, e);
        }
        
        return null;
    }

    public static String resolveFulfillment(String dealId, String unresolvedFulfillmentObjJSON, String chargeMethod, String selectedUnitId) {
        dealId = BPUtility.getDecodedString(dealId);
        unresolvedFulfillmentObjJSON = BPUtility.getDecodedString(unresolvedFulfillmentObjJSON);
        chargeMethod = BPUtility.getDecodedString(chargeMethod);
        selectedUnitId = BPUtility.getDecodedString(selectedUnitId);
        DealWrapper.DealUnresolvedFulfillmentWrapper unresolvedFulfillmentObj = (DealWrapper.DealUnresolvedFulfillmentWrapper) System.JSON.deserialize(unresolvedFulfillmentObjJSON, DealWrapper.DealUnresolvedFulfillmentWrapper.class);
        unresolvedFulfillmentObj.ChargeMethod = chargeMethod;
        //Update Unresolved fulfillment record
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Unresolved_Fulfillment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(String.isNotBlank(selectedUnitId)) {
            List<Deal_Item__c> dealItemList = [Select Id from Deal_Item__c where Deal__c = :unresolvedFulfillmentObj.DealId And Customer_Owned_Unit__c = :selectedUnitId];
            if(dealItemList.size() > 0) {
                unresolvedFulfillmentObj.DealItemId = dealItemList[0].Id;
            }
        }
        if(unresolvedFulfillmentObj.Type == Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED) {
            resolveFulfillmentWithAddAction(unresolvedFulfillmentObj, chargeMethod);
        } else if(unresolvedFulfillmentObj.Type == Constants.UNRESOLVED_FULFILLMENT_TYPE_REMOVED) {
            resolveFulfillmentWithRemoveAction(unresolvedFulfillmentObj);
        } else if(unresolvedFulfillmentObj.Type == Constants.UNRESOLVED_FULFILLMENT_TYPE_UPDATED) {
            resolveFulfillmentWithUpdateAction(unresolvedFulfillmentObj);
        }
        
        Deal_Unresolved_Fulfillment__c dealUnresolvedFulfillmentRec = new Deal_Unresolved_Fulfillment__c();
        
        dealUnresolvedFulfillmentRec.Id = unresolvedFulfillmentObj.Id;
        dealUnresolvedFulfillmentRec.Charge_Method__c = chargeMethod;
        dealUnresolvedFulfillmentRec.Customer_Owned_Unit__c = selectedUnitId;
        dealUnresolvedFulfillmentRec.Is_Resolved__c = true;
        dealUnresolvedFulfillmentRec.Deal_Item__c = unresolvedFulfillmentObj.DealItemId;
        
        DMLUtility.updateSobjectList('Deal_Unresolved_Fulfillment__c', dealUnresolvedFulfillmentRec);
        
        List<Deal_Unresolved_Fulfillment__c> unresolvedFulfillmentList = [Select Deal__r.CO_Header__c, CO_Line_Item__c, Service_Order_Line_Item__r.Service_Order_Header__c, 
                                                                            CO_Kit_Header__c, Service_Order_Kit_Header__c, Service_Order_Kit_Header__r.Service_Order_Header__c from 
                                                                            Deal_Unresolved_Fulfillment__c where Id = :dealUnresolvedFulfillmentRec.Id];
        if(unresolvedFulfillmentList.size() > 0) {
            if(String.isNotBlank(unresolvedFulfillmentList[0].CO_Line_Item__c)) {
                updateUnresolvedCOLIForCheckout(unresolvedFulfillmentList[0].CO_Line_Item__c, true);
            } else if(String.isNotBlank(unresolvedFulfillmentList[0].Service_Order_Line_Item__r.Service_Order_Header__c)) {
                updateUnresolvedSOHeaderForCheckout(unresolvedFulfillmentList[0].Service_Order_Line_Item__r.Service_Order_Header__c, true);
            } else if(String.isNotBlank(unresolvedFulfillmentList[0].CO_Kit_Header__c)) {
                updateUnresolvedCOKHForCheckout(unresolvedFulfillmentList[0].CO_Kit_Header__c, true);
            } else if(String.isNotBlank(unresolvedFulfillmentList[0].Service_Order_Kit_Header__c)) {
                updateUnresolvedSOKHForCheckout(unresolvedFulfillmentList[0].Service_Order_Kit_Header__r.Service_Order_Header__c, true);
            }
            UpdateOptionFeeStatus(unresolvedFulfillmentList[0].Deal__r.CO_Header__c);
        }
        
        //OptionAndFeeTriggerHelper.updateDealTotal(new Set<String>{dealId});
        return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString(null));
    }

    private static void resolveFulfillmentWithAddAction(DealWrapper.DealUnresolvedFulfillmentWrapper unresolvedFulfillmentObj, String chargeMethod) {
        String lineItemId = null;
        if(String.isNotBlank(unresolvedFulfillmentObj.DealMerchandiseLineItemId)) {
            lineItemId = unresolvedFulfillmentObj.DealMerchandiseLineItemId;
        } else if(String.isNotBlank(unresolvedFulfillmentObj.DealServiceLineItemId)) {
            lineItemId = unresolvedFulfillmentObj.DealServiceLineItemId;
        }
        Option_Fee__c optionAndFeeRec;
        if(String.isNotBlank(lineItemId)) {
            optionAndFeeRec = setOptionAndFeeLineItem(lineItemId, unresolvedFulfillmentObj.DealItemId);
            optionAndFeeRec.Status__c = String.isNotBlank(optionAndFeeRec.Status__c) ? optionAndFeeRec.Status__c : Constants.COMMITTED;
            if(String.isNotBlank(chargeMethod) && chargeMethod.equalsIgnoreCase(Constants.CHARGE_METHOD_DO_NOT_INVOICE)) {
                optionAndFeeRec.Price__c = optionAndFeeRec.Price_When_Tax_Included__c = 0;
                
                OptionAndFeeTriggerHelper.isTriggerExecute = true;
            }
            DMLUtility.insertSobjectList('Option_Fee__c', optionAndFeeRec);
        }
        
        //update existed coli or soli
        if(String.isNotBlank(unresolvedFulfillmentObj.DealMerchandiseLineItemId)) {
            if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<CO_Line_Item__c> coliList = [Select Option_Fee__c, Related_Option_And_Fees__c from CO_Line_Item__c where Id = :unresolvedFulfillmentObj.DealMerchandiseLineItemId];
            if(coliList.size() > 0) {
                coliList[0].Option_Fee__c = optionAndFeeRec.Id;
                if(coliList[0].Related_Option_And_Fees__c == null) {
                    coliList[0].Related_Option_And_Fees__c = '';
                }
                coliList[0].Related_Option_And_Fees__c += ';' + optionAndFeeRec.Id;
                DMLUtility.updateSobjectList('CO_Line_Item__c', coliList[0]);
            }
            
        } else if(String.isNotBlank(unresolvedFulfillmentObj.DealServiceLineItemId)) {
            DMLUtility.updateSobjectList('Service_Order_Line_Item__c', new Service_Order_Line_Item__c(Id = unresolvedFulfillmentObj.DealServiceLineItemId, Option_Fee__c = optionAndFeeRec.Id));
        } else if(String.isNotBlank(unresolvedFulfillmentObj.COKitHeaderId)) {
            
            String dkhId = insertDealKHByCOKH(unresolvedFulfillmentObj.KitHeaderId, unresolvedFulfillmentObj.DealItemId, unresolvedFulfillmentObj.DealId, chargeMethod, false, unresolvedFulfillmentObj.COKitHeaderId);
            
            DMLUtility.updateSobjectList('CO_Kit_Header__c', new CO_Kit_Header__c(Id = unresolvedFulfillmentObj.COKitHeaderId, Deal_Kit_Header__c = dkhId));
        } else if(String.isNotBlank(unresolvedFulfillmentObj.SOKitHeaderId)) {
            
            String dkhId = insertDealKHByCOKH(unresolvedFulfillmentObj.KitHeaderId, unresolvedFulfillmentObj.DealItemId, unresolvedFulfillmentObj.DealId, chargeMethod, true, unresolvedFulfillmentObj.SOKitHeaderId);
            
            DMLUtility.updateSobjectList('Service_Order_Kit_Header__c', new Service_Order_Kit_Header__c(Id = unresolvedFulfillmentObj.SOKitHeaderId, Deal_Kit_Header__c = dkhId));
        }
    }
    
    private static void resolveFulfillmentWithRemoveAction(DealWrapper.DealUnresolvedFulfillmentWrapper unresolvedFulfillmentObj) {
        List<String> optionAndFeeIdList;
        List<SObject> sObjectList = new List<SObject>();
        if(unresolvedFulfillmentObj.DealKitHeaderId != null) {
            optionAndFeeIdList = new List<String>{unresolvedFulfillmentObj.DealKitHeaderId};
            
            if(AccessControl.ifObjectFieldIsAccessible('Deal_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Deal_Kit_Header__c> dealKHList = [Select Id, (Select Id from Options_Fees__r), (Select Id from Service_Order_Kit_Headers__r), (Select Id from CO_Kit_Headers__r) from Deal_Kit_Header__c where Id In :optionAndFeeIdList];
            optionAndFeeIdList.clear();
            if(dealKHList.size() > 0) {
                for(Deal_Kit_Header__c dkhRec : dealKHList) {
                    sObjectList.addAll((List<SObject>)dkhRec.CO_Kit_Headers__r);
                    sObjectList.addAll((List<SObject>)dkhRec.Service_Order_Kit_Headers__r);
                    sObjectList.add((SObject)dkhRec);
                    for(Option_Fee__c optionAndFeeRec : dkhRec.Options_Fees__r) {
                        optionAndFeeIdList.add(optionAndFeeRec.Id);
                    }
                }
            }
        } else {
            optionAndFeeIdList = unresolvedFulfillmentObj.RelatedOptionAndFeeIdList;
        }
        if(optionAndFeeIdList.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            
            List<Option_Fee__c> optionAndFeeList;
            String query = 'Select Id, CO_Line_Item__c, Service_Order_Line_Item__c, (Select Id from CO_Line_Items__r), (Select Id from Service_Order_Line_Items__r) from '+
                'Option_Fee__c where (Id IN: optionAndFeeIdList)';
                
            query += String.isNotBlank(unresolvedFulfillmentObj.DealMerchandiseLineItemId) ? 
                    ' OR (Do_Not_Invoice__c = true AND (CO_Line_Item__c =: unresolvedFulfillmentObj.DealMerchandiseLineItemId) '
                : (String.isNotBlank(unresolvedFulfillmentObj.DealMerchandiseLineItemId) ? ' OR (Do_Not_Invoice__c = true AND (Service_Order_Line_Item__c =: unresolvedFulfillmentObj.DealServiceLineItemId))' : '');
            optionAndFeeList = Database.query(query);
            if(optionAndFeeList.size() > 0) {
                for(Option_Fee__c optionAndFeeRec : optionAndFeeList) {
                    if(String.isNotBlank(optionAndFeeRec.CO_Line_Item__c)) {
                        sObjectList.add((SObject) new CO_Line_Item__c(Id = optionAndFeeRec.CO_Line_Item__c));
                    }
                    if(String.isNotBlank(optionAndFeeRec.Service_Order_Line_Item__c)) {
                        sObjectList.add((SObject) new Service_Order_Line_Item__c(Id = optionAndFeeRec.Service_Order_Line_Item__c));
                    }
                    sObjectList.addAll((List<SObject>)optionAndFeeRec.CO_Line_Items__r);
                    sObjectList.addAll((List<SObject>)optionAndFeeRec.Service_Order_Line_Items__r);
                    sObjectList.add((SObject)optionAndFeeRec);
                }
            }
        }
        if(AccessControl.ifObjectIsDeletable('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Deal_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete sObjectList;
    }
    
    private static void resolveFulfillmentWithUpdateAction(DealWrapper.DealUnresolvedFulfillmentWrapper unresolvedFulfillmentObj) {
        String lineItemId = null;
        Boolean isMerchandise = false;
        if(String.isNotBlank(unresolvedFulfillmentObj.DealMerchandiseLineItemId)) {
            isMerchandise = true;
            lineItemId = unresolvedFulfillmentObj.DealMerchandiseLineItemId;
        } else if(String.isNotBlank(unresolvedFulfillmentObj.DealServiceLineItemId)) {
            isMerchandise = false;
            lineItemId = unresolvedFulfillmentObj.DealServiceLineItemId;
        }
        if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Co_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Option_Fee__c optionAndFeeRec = null;
        List<CO_Line_Item__c> coLineItemList = [Select Option_Fee__c, Related_Option_And_Fees__c from Co_Line_Item__c where Id = :lineItemId];
        Set<String> optionAndFeeIdSet = null;
        if(unresolvedFulfillmentObj.ChargeMethod == Constants.CHARGE_METHOD_INVOICE) {
            List<Option_Fee__c> optionAndFeeList = new List<Option_Fee__c>();
            if(isMerchandise) {
                if(coLineItemList.size() > 0) {
                if(String.isNotBlank(coLineItemList[0].Related_Option_And_Fees__c)) {
                    optionAndFeeIdSet = new Set<String>(coLineItemList[0].Related_Option_And_Fees__c.split(';'));
                    optionAndFeeList = [Select Id, Qty__c, Deal_Item__c from Option_Fee__c where Id In :optionAndFeeIdSet And Deal_Item__c = :unresolvedFulfillmentObj.DealItemId];
                }
                }
            } else {
                optionAndFeeList = [Select Id, Qty__c, Deal_Item__c from Option_Fee__c where Id = :unresolvedFulfillmentObj.OptionAndFeeId];
            }
            if(optionAndFeeList.size() > 0) {
                optionAndFeeList[0].Qty__c += (unresolvedFulfillmentObj.UpdatedQty - unresolvedFulfillmentObj.ActualQty);
                optionAndFeeList[0].Deal_Item__c = unresolvedFulfillmentObj.DealItemId;
                if(optionAndFeeList[0].Qty__c != 0) {
                    DMLUtility.updateSobjectList('Option_Fee__c', optionAndFeeList[0]);
                    return;
                } else {
                    if(AccessControl.ifObjectIsDeletable('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                    delete optionAndFeeList[0];
                    if(isMerchandise) {
                        if(optionAndFeeIdSet != null) {
                            optionAndFeeIdSet.remove(optionAndFeeList[0].Id);
                            coLineItemList[0].Related_Option_And_Fees__c = string.join((new List<String>(optionAndFeeIdSet)),';');
                        }
                        DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemList[0]);
                    }
                }
            } else {
                optionAndFeeRec = setOptionAndFeeLineItem(lineItemId, unresolvedFulfillmentObj.DealItemId);
                optionAndFeeRec.Qty__c = (unresolvedFulfillmentObj.UpdatedQty - unresolvedFulfillmentObj.ActualQty);
                DMLUtility.insertSobjectList('Option_Fee__c', optionAndFeeRec);
                if(isMerchandise) {
                    if(optionAndFeeIdSet == null) {
                        optionAndFeeIdSet = new Set<String>();
                    }
                    optionAndFeeIdSet.add(optionAndFeeRec.Id);
                    coLineItemList[0].Related_Option_And_Fees__c = string.join((new List<String>(optionAndFeeIdSet)),';');
                    coLineItemList[0].Option_Fee__c = optionAndFeeRec.Id;
                    DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemList[0]);
                } else {
                    DMLUtility.updateSobjectList('Service_Order_Line_Item__c', new Service_Order_Line_Item__c(Id = lineItemId, Option_Fee__c = optionAndFeeRec.Id));
                }
            }
        } else if(unresolvedFulfillmentObj.ChargeMethod == Constants.CHARGE_METHOD_DO_NOT_INVOICE) {
            optionAndFeeRec = setOptionAndFeeLineItem(lineItemId, unresolvedFulfillmentObj.DealItemId);
            optionAndFeeRec.Do_Not_Invoice__c = true;
            optionAndFeeRec.Price__c = optionAndFeeRec.Price_When_Tax_Included__c = 0;
            optionAndFeeRec.Qty__c = (unresolvedFulfillmentObj.UpdatedQty - unresolvedFulfillmentObj.ActualQty);
            optionAndFeeRec.CO_Line_Item__c = String.isNotBlank(unresolvedFulfillmentObj.DealMerchandiseLineItemId) ? unresolvedFulfillmentObj.DealMerchandiseLineItemId : null;
            optionAndFeeRec.Service_Order_Line_Item__c = String.isNotBlank(unresolvedFulfillmentObj.DealServiceLineItemId) ? unresolvedFulfillmentObj.DealServiceLineItemId : null;
            OptionAndFeeTriggerHelper.isTriggerExecute = true;
            DMLUtility.insertSobjectList('Option_Fee__c', optionAndFeeRec);
            if(isMerchandise) {
                optionAndFeeIdSet = new Set<String>(coLineItemList[0].Related_Option_And_Fees__c.split(';'));
                optionAndFeeIdSet.add(optionAndFeeRec.Id);
                coLineItemList[0].Related_Option_And_Fees__c = string.join((new List<String>(optionAndFeeIdSet)),';');
                coLineItemList[0].Option_Fee__c = optionAndFeeRec.Id;
                DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemList[0]);
            } else {
                //update new Service_Order_Line_Item__c(Id = lineItemId, Option_Fee__c = optionAndFeeRec.Id);
            }
        }
        
    }

    public static Option_Fee__c setOptionAndFeeLineItem(String unresolvedFulfillmentId, String dealItemId) {
        Option_Fee__c optionAndFeeRec = new Option_Fee__c();
        
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        String objectName = (Id.valueOf(unresolvedFulfillmentId)).getSObjectType().getDescribe().getName();
        if(objectName == Constants.NAMESPACE + 'CO_Line_Item__c') {
            List<CO_Line_Item__c> coliList = [Select Deal__c, Closed_CO_Invoice_link__c, Qty__c, Part__c,Item_Code__c, Item_Description__c, Part__r.Part_Number__c, Part__r.Description__c, Part__r.Retail_Price__c, Price__c from CO_Line_Item__c where Id = :unresolvedFulfillmentId];
            if(coliList.size() > 0) {
				optionAndFeeRec.CO_Line_Item__c = coliList[0].Id;
                optionAndFeeRec.Part__c = coliList[0].Part__c;
                optionAndFeeRec.Deal__c = coliList[0].Deal__c;
                optionAndFeeRec.Price__c = coliList[0].Part__r.Retail_Price__c;
                optionAndFeeRec.Qty__c = coliList[0].Qty__c;
                optionAndFeeRec.Is_Install__c = false;
                optionAndFeeRec.Item_Code__c = coliList[0].Part__r.Part_Number__c;
                optionAndFeeRec.Item_Description__c = coliList[0].Part__r.Description__c;
                optionAndFeeRec.Per_Item_Cost__c = coliList[0].Price__c;
                if(String.isNotBlank(coliList[0].Closed_CO_Invoice_link__c)) {
                    optionAndFeeRec.Status__c = 'Fulfilled';
                }
            }
        } else if(objectName == Constants.NAMESPACE + 'Service_Order_Line_Item__c') {
            List<Service_Order_Line_Item__c> soliList = [Select Item_Code__c, Service_Order_Header__r.SO_Status__c, CO_Line_Item__r.Closed_CO_Invoice_link__c, Item_Description__c, Deal__c, Kit_Price__c, Qty_Needed__c, Part__c, Part__r.Retail_Price__c, Fee__c, Fee__r.Price__c, Labour_Code__c, Labour_Code__r.Rate__c, Sublet__c, Sublet__r.Price__c from Service_Order_Line_Item__c where Id = :unresolvedFulfillmentId];
            if(soliList.size() > 0) {
				optionAndFeeRec.Service_Order_Line_Item__c = soliList[0].Id;
                optionAndFeeRec.Part__c = soliList[0].Part__c;
                if(String.isNotBlank(soliList[0].Part__c)) {
                    optionAndFeeRec.Price__c = soliList[0].Part__r.Retail_Price__c;
                } else if(String.isNotBlank(soliList[0].Labour_Code__c)) {
                    optionAndFeeRec.Price__c = soliList[0].Labour_Code__r.Rate__c;
                } else if(String.isNotBlank(soliList[0].Fee__c)) {
                    optionAndFeeRec.Price__c = soliList[0].Fee__r.Price__c;
                } else if(String.isNotBlank(soliList[0].Sublet__c)) {
                    optionAndFeeRec.Price__c = soliList[0].Sublet__r.Price__c;
                }
                optionAndFeeRec.Item_Code__c = soliList[0].Item_Code__c;
                optionAndFeeRec.Item_Description__c = soliList[0].Item_Description__c;
                optionAndFeeRec.Labour_Code__c = soliList[0].Labour_Code__c;
                optionAndFeeRec.Is_Install__c = true;
                optionAndFeeRec.Qty__c = soliList[0].Qty_Needed__c;
                optionAndFeeRec.Deal__c = soliList[0].Deal__c;
                //optionAndFeeRec.Price__c = soliList[0].Kit_Price__c;
                optionAndFeeRec.Fee__c = soliList[0].Fee__c;
                optionAndFeeRec.Product__c = soliList[0].Sublet__c;
                optionAndFeeRec.Per_Item_Cost__c = soliList[0].Kit_Price__c;
                if(String.isNotBlank(soliList[0].CO_Line_Item__r.Closed_CO_Invoice_link__c)) {
                    optionAndFeeRec.Status__c = 'Fulfilled';
                } else {
                    if(String.isNotBlank(soliList[0].Service_Order_Header__r.SO_Status__c) && soliList[0].Service_Order_Header__r.SO_Status__c == ServiceJobUtil.INVOICED) {
                        optionAndFeeRec.Status__c = 'Fulfilled';
                    }
                }
            }
        }
        optionAndFeeRec.Deal_Item__c = dealItemId;
        return optionAndFeeRec;
    }

    /**
     * Name: setDealItemValues
     * Desc: Method which convert DealItem wrapper obj value into Deal_Item__c customer object rec
     * @param:  (1) dealItemObj - DealItem - Deal Item wrapper obj
     * @param:  (2) dealId - String - Deal Id
     * @return: Deal_Item__c - Deal Item object
    **/
    public static Deal_Item__c setDealItemValues(DealItem dealItemObj, String dealId) {
        Deal_Item__c dealItemRec = new Deal_Item__c(); 
        dealItemRec.Id = dealItemObj.Id;
        dealItemRec.Customer_Owned_Unit__c = dealItemObj.UnitId;
        dealItemRec.Deal__c = dealId;
        dealItemRec.Type__c = dealItemObj.Type;
        if(String.isNotBlank(dealItemObj.Type) && dealItemObj.Type == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
            dealItemRec.Agreed_Value__c = dealItemObj.AgreedValue;
            if(GeneralConfiguration.getTaxIncludingPricing() || !GeneralConfiguration.isTradeTaxCreditCanNotExceedUnitTax()) {
                dealItemRec.Agreed_Value_Taxable_Amount__c = dealItemRec.Agreed_Value__c;
            }
            dealItemRec.Actual_Cash_Value__c = dealItemObj.ActualCashValue;
            dealItemRec.Appraisal_Method__c = dealItemObj.AppraisalMethod;
            dealItemRec.Appraisal_Notes__c = dealItemObj.AppraisalNotes;
            dealItemRec.Appraisal_Status__c = String.isBlank(dealItemObj.Id) ? Constants.APPRAISAL_STATUS_PENDING_APPRAISAL :
                                                            dealItemObj.AppraisalStatus;
            dealItemRec.Approved_By__c = dealItemObj.ApprovedBy;
            dealItemRec.Lien_Payout__c = dealItemObj.LienPayout;
            dealItemRec.Finance_Company__c = dealItemObj.FinanceCompanyId;
            dealItemRec.Category__c = dealItemObj.CategoryId;
            dealItemRec.Transfer_Plate_Reg_to_New_Unit__c = dealItemObj.TransferPlateRegToNewUnit != null ? dealItemObj.TransferPlateRegToNewUnit : false;
            dealItemRec.Transfer_To__c = dealItemObj.TransferToUnitId;
            dealItemRec.Mileage__c = dealItemObj.Mileage;
            dealItemRec.Mileage_Type__c = dealItemObj.MileageType;
        } else if(String.isNotBlank(dealItemObj.Type) && dealItemObj.Type == Constants.DEAL_ITEM_TYPE_UNIT){
            dealItemRec.Unit_Make__c = dealItemObj.Make;
            dealItemRec.Unit_Model__c = dealItemObj.Model;
            dealItemRec.Sub_Model__c = dealItemObj.SubModel;
            dealItemRec.Year__c = dealItemObj.Year;
            dealItemRec.Colour__c = dealItemObj.ExteriorColour;
            dealItemRec.Option_And_Fee_Status__c = Constants.UNCOMIITTED;
        }
        return dealItemRec;
    }

    private static Deal_Kit_Header__c setDealKitHeaderFields(Kit_Header__c kitHeaderRec) {
        Deal_Kit_Header__c dkhRec = new Deal_Kit_Header__c();
        
        dkhRec.Kit_Header__c = kitHeaderRec.Id;
        dkhRec.Can_Split__c = kitHeaderRec.Can_Split__c;
        dkhRec.Code__c = kitHeaderRec.Code__c;
        dkhRec.Description__c = kitHeaderRec.Description__c;
        dkhRec.Is_Fixed_Price__c = kitHeaderRec.Fixed_Price_Flag__c;
        dkhRec.Service_Kit__c = kitHeaderRec.Service_Kit__c;
        dkhRec.Fixed_Price__c = kitHeaderRec.Fixed_Price__c;
        dkhRec.Actual_Kit_Price__c = kitHeaderRec.Fixed_Price__c;
        return dkhRec;
    }

    private static List<Option_Fee__c> insertAllKitLineItemsInDeal(String lineItemId, String dealItemId, String dealId, String dkhRecId, String status, String chargeMethod, 
            List<SObject> sObjectListToUpdate) {
        if(AccessControl.ifObjectFieldIsAccessible('Kit_Header_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Option_Fee__c> optionAndFeeListToInsert = new List<Option_Fee__c>();
        
        List<Kit_Header_Line_Item__c> khLineItemList = SOQLUtil.getKHLineItemRec(new Map<String, String>{ 'Kit_Header__c' => lineItemId });
        if(khLineItemList.size() == 0) {
            return null;
        }
        
        for(Kit_Header_Line_Item__c khliRec : khLineItemList) {
            Option_Fee__c optionAndFeeRec = new Option_Fee__c(Kit_Header_Line_Item__c = khliRec.Id);
            optionAndFeeRec.Deal__c = dealId;
            optionAndFeeRec.Deal_Item__c = dealItemId;
            optionAndFeeRec.Deal_Kit_Header__c = dkhRecId;
            optionAndFeeRec.Fixed_Price__c = khliRec.Kit_Price__c;
            optionAndFeeRec.Is_Fixed_Price__c = khliRec.Fixed_Price__c;
            optionAndFeeRec.Is_Fixed_Kit_Line_Item_CO__c = false;
            optionAndFeeRec.Part__c = khliRec.Part__c;
            optionAndFeeRec.Status__c = (status != null) ? status : Constants.COMMITTED;
            optionAndFeeRec.Labour_Code__c = khliRec.Labour_Code__c;
            optionAndFeeRec.Fee__c = khliRec.Fee__c;
            optionAndFeeRec.Price__c = (khliRec.Kit_Price__c != null) ? khliRec.Kit_Price__c : 0;
            optionAndFeeRec.Qty__c = (khliRec.Qty_Needed__c == null) ? 1 : khliRec.Qty_Needed__c;
            if(optionAndFeeRec.Fee__c != null) {
                optionAndFeeRec.Price__c = khliRec.Kit_Price__c;
                optionAndFeeRec.Qty__c = (khliRec.Qty_Needed__c == null) ? 1 : khliRec.Qty_Needed__c;
            }
            optionAndFeeRec.Actual_Kit_Price__c = khliRec.Kit_Price__c;
            optionAndFeeRec.Price_When_Tax_Included__c = optionAndFeeRec.Price__c;
            optionAndFeeRec.Item_Code__c = khliRec.Item_Code__c;
            optionAndFeeRec.Item_Description__c = khliRec.Item_Description__c;
            if(chargeMethod != null && chargeMethod == Constants.CHARGE_METHOD_DO_NOT_INVOICE) {
                optionAndFeeRec.Price__c = optionAndFeeRec.Price_When_Tax_Included__c = 0;
            }
            if(sObjectListToUpdate != null) {
                for(SObject sObjRec : sObjectListToUpdate) {
                    if(sObjRec.get('Kit_Header_Line_Item__c') == khliRec.Id) {
                        if((Id.valueOf(string.valueOf(sObjRec.get('Id')))).getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Service_Order_Line_Item__c') {
                            optionAndFeeRec.Per_Item_Cost__c = Decimal.valueOf(String.valueOf(sObjRec.get('Kit_Price__c')) != null ? String.valueOf(sObjRec.get('Kit_Price__c')) : 
                                String.valueOf(sObjRec.get('Price_When_Tax_Included__c')));
                        	optionAndFeeRec.Service_Order_Line_Item__c = String.valueOf(sObjRec.get('Id')) != null ? String.valueOf(sObjRec.get('Id')) : null;
                        } else {
                            optionAndFeeRec.Per_Item_Cost__c = Decimal.valueOf(String.valueOf(sObjRec.get('Price__c')) != null ? String.valueOf(sObjRec.get('Price__c')) : 
                                String.valueOf(sObjRec.get('Price_When_Tax_Included__c')));
                       		optionAndFeeRec.CO_Line_Item__c = String.valueOf(sObjRec.get('Id')) != null ? String.valueOf(sObjRec.get('Id')) : null;
                        }
                    }
                }
            }
            optionAndFeeListToInsert.add(optionAndFeeRec);
        }
        
        if(optionAndFeeListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Option_Fee__c', optionAndFeeListToInsert);
        }
        
        return optionAndFeeListToInsert;
    }

    private static void moveDealKit(String dealKHId, String coHeaderId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Deal_Kit_Header__c> dealkhList = SOQLUtil.getDealKitHeaderByFieldName(new Map<String, String>{'Id' => dealKHId});
        if(dealkhList.size() == 0) {
            return;
        }
        List<Sobject> sobjectList = new List<Sobject>();
        Set<Id> soIdSet = new Set<Id>();
            
        if((dealkhList[0].CO_Kit_Headers__r).size() > 0) {
            List<CO_Kit_Header__c> cokhList = [Select Id, (Select Id from CO_Line_Items__r), (select Id from CO_Invoice_Items__r) from CO_Kit_Header__c where Deal_Kit_Header__c =: dealKHId];
            if(cokhList.size() > 0) {
                for(CO_Kit_Header__c cokhRec : cokhList) {
                    sobjectList.addAll((List<Sobject>) cokhRec.CO_Line_Items__r);
                    sobjectList.addAll((List<Sobject>) cokhRec.CO_Invoice_Items__r);
                }
            }
            sobjectList.addAll((List<Sobject>) cokhList);
        }
        if((dealkhList[0].Service_Order_Kit_Headers__r).size() > 0) {
            List<Service_Order_Kit_Header__c> sokhList = [Select Id, Service_Order_Header__c, (Select Id from Service_Order_Line_Items__r) from Service_Order_Kit_Header__c where Deal_Kit_Header__c =: dealKHId];
            if(sokhList.size() > 0) {
                for(Service_Order_Kit_Header__c sokhRec : sokhList) {
                    soIdSet.add(sokhRec.Service_Order_Header__c);
                    sobjectList.addAll((List<Sobject>) sokhRec.Service_Order_Line_Items__r);
                }
                sobjectList.addAll((List<Sobject>) sokhList);
            }
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Header__c> soHeaderList = [select Deal_Item__c, (select Id from Service_Order_Line_Items__r where Service_Order_Kit_Header__c = null), (select Id from Service_Order_Kit_Headers__r)  
                                                            from Service_Order_Header__c where Id IN: soIdSet];
            
            if(soHeaderList.size() > 0) {
                for(Service_Order_Header__c soHeaderRec : soHeaderList) {
                    if(soHeaderRec.Service_Order_Kit_Headers__r.size() == 1 && soHeaderRec.Service_Order_Line_Items__r.size() == 0) {
                        sobjectList.add((SObject) soHeaderRec);
                    }
                }
            }
        }
        
        if(sobjectList.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete sobjectList;
        }
        
        if(!dealkhList[0].Is_Install__c) {
            CO_Kit_Header__c cokhRec = setCOKitHeaderFields(dealkhList[0], coHeaderId, dealkhList[0].Deal_Item__r.Deal__c);
            
            if(cokhRec != null) {
                Boolean dealMerchSectionExists = [Select Id FROM CO_Line_Item__c WHERE CO_Header__c = :coHeaderId AND Deal__c = :dealkhList[0].Deal_Item__r.Deal__c AND Service_Order_Line_Item__c = null LIMIT 1].size() > 0;
                if(!dealMerchSectionExists) COService.addDefaultSalespersonToCOSection(coHeaderId, DealUtil.DEAL_MERCH, dealkhList[0].Deal_Item__r.Deal__c);
                DMLUtility.insertSobjectList('CO_Kit_Header__c', cokhRec);
            }
            List<Co_Line_Item__c> coliList = new List<CO_Line_Item__c>();
            for(Option_Fee__c optionAndFeeRec : dealkhList[0].Options_Fees__r) {
                coliList.add(setColiFields(optionAndFeeRec, coHeaderId, cokhRec.Id, dealkhList[0].Deal_Item__r.Deal__c));
            }
            if(coliList.size() > 0) {
                DMLUtility.insertSobjectList('Co_Line_Item__c', coliList);

                List<Option_Fee__c> ofUpdateList = new List<Option_Fee__c>();
                for(Co_Line_Item__c coli : coliList) {
                    if(coli.Option_Fee__c != null) {
                        ofUpdateList.add(new Option_Fee__c(Id = coli.Option_Fee__c, Co_Line_Item__c = coli.Id, Status__c = Constants.COMMITTED));
                    }
                }
                update ofUpdateList;
            }
            //COKH_Recalcualtion.CoKitInsert(cokhRec.Id, coHeaderId);
            COKH_Recalcualtion.calculatePriceForCOKitInsertion(cokhRec.Id, coHeaderId);
        } else {
            COSectionDetailService.checkAndDeleteCOSection_future(coHeaderId, COSectionDetailService.DEAL_MERCHANDISE);
            
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Header__c> soHeaderList = [select Deal_Item__c from Service_Order_Header__c where Deal__c =: dealkhList[0].Deal_Item__r.Deal__c];
            Map<Id, Service_Order_Header__c> dealItemIdToSOHeaderRecMap = new Map<Id, Service_Order_Header__c>();
            for(Service_Order_Header__c soHeaderRec : soHeaderList) {
                dealItemIdToSOHeaderRecMap.put(soHeaderRec.Deal_Item__c, soHeaderRec);
            }
            dealItemIdToSOHeaderRecMap.remove(null);
            
            Service_Order_Header__c soHeaderRec;
            if(!dealItemIdToSOHeaderRecMap.containsKey(dealkhList[0].Deal_Item__c)) {
                soHeaderRec = setSOHeaderFields(dealkhList[0].Deal_Item__c, coHeaderId, dealItemIdToSOHeaderRecMap.keySet().size() + 1, dealkhList[0].Deal_Item__r.Deal__c,
                                                dealkhList[0].Deal_Item__r.Customer_Owned_Unit__c);
                DMLUtility.insertSobjectList('Service_Order_Header__c', soHeaderRec);
            } else {
                soHeaderRec = dealItemIdToSOHeaderRecMap.get(dealkhList[0].Deal_Item__c);
            }
            
            Service_Order_Kit_Header__c sokhRec = setSOKitHeaderFields(dealkhList[0], soHeaderRec.Id, dealkhList[0].Deal_Item__r.Deal__c); 
            
            if(sokhRec != null) {
                DMLUtility.insertSobjectList('Service_Order_Kit_Header__c', sokhRec);
                
                List<Service_Order_Line_Item__c> soliList = new List<Service_Order_Line_Item__c>();
                for(Option_Fee__c optionAndFeeRec : dealkhList[0].Options_Fees__r) {
                    soliList.add(setSoliFields(optionAndFeeRec, soHeaderRec.Id, sokhRec.Id));
                }
                if(soliList.size() > 0) {
                    DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliList);

                    List<Option_Fee__c> ofUpdateList = new List<Option_Fee__c>();
                    for(Service_Order_Line_Item__c soli : soliList) {
                        if(soli.Option_Fee__c != null) {
                            ofUpdateList.add(new Option_Fee__c(Id = soli.Option_Fee__c, Service_Order_Line_Item__c = soli.Id, Status__c = Constants.COMMITTED));
                        }
                    }
                    update ofUpdateList;
                }
                //SO_KLI_Recalculation.SOPriceCalcultaionByPriceLevelForSOKitHeaders(dealkhList[0].Deal_Item__r.Deal__r.CO_Header__r.Customer__c, coHeaderId, new List<Id>{sokhRec.Id}, soHeaderRec.Id);
            	SO_KLI_Recalculation.soKitPriceCalculation(new Set<Id>{sokhRec.Id}, new Set<Id>{soHeaderRec.Id}, coHeaderId);
            }
        }
    }

    private static void moveOptionAndFeeLineItem(String optionFeeRecId, String coHeaderId) {
        List<Option_Fee__c> optionAndFeeList = SOQLUtil.getOptionAndFeeRecord(new Map<String, String>{'Id' => optionFeeRecId});
        if(optionAndFeeList.size() == 0) {
            return;
        }
        List<Sobject> sobjectList = new List<Sobject>();
        Option_Fee__c optionFeeRec = optionAndFeeList[0];
        List<CO_Line_Item__c> coliMoveList = new List<CO_Line_Item__c>();
        List<CO_Line_Item__c> coliToUpsert = new List<CO_Line_Item__c>();

        if(optionFeeRec.CO_Line_Items__r.size() > 0 ) {
            sobjectList.add(optionFeeRec.CO_Line_Items__r);
            coliMoveList.add(optionFeeRec.CO_Line_Items__r);
        }

        if(optionFeeRec.Service_Order_Line_Items__r.size() > 0 ) {
            sobjectList.add(optionFeeRec.Service_Order_Line_Items__r);
            Set<Id> soIdSet = new Set<Id>();
            for(Service_Order_Line_Item__c soliRec : optionFeeRec.Service_Order_Line_Items__r) {
                soIdSet.add(soliRec.Service_Order_Header__c);
                coliMoveList.add(soliRec.CO_Line_Item__r);
            }
            
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Header__c> soHeaderList = [select Deal_Item__c, (select Id from Service_Order_Line_Items__r) 
                                                            from Service_Order_Header__c where Id IN: soIdSet];
            
            if(soHeaderList.size() > 0) {
                for(Service_Order_Header__c soHeaderRec : soHeaderList) {
                    if(soHeaderRec.Service_Order_Line_Items__r.size() == 1) {
                        sobjectList.add(soHeaderRec);
                    }
                }
            } 
        }
        List<Vendor_Order_Line_Item__c> voliListToUpsert = [Select Id, Vendor_Order_Line_Item_Group__c, Is_Received__c, CO_Line_Item__c From Vendor_Order_Line_Item__c Where CO_Line_Item__c In: coliMoveList AND Vendor_Order_Header__c != null AND Vendor_Order_Header__r.Status__c != 'Open'];
        if(voliListToUpsert.size() > 0) {
            COLineItemTriggerHelper.isMoveLineItem = true;
        }
        if(sobjectList.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete sobjectList;
        }
        
        if(optionFeeRec.Part__c != null || optionFeeRec.Labour_Code__c != null) {
            if(!optionFeeRec.Is_Install__c) {
                Boolean dealMerchSectionExists = ([Select Id FROM CO_Line_Item__c WHERE CO_Header__c = :coHeaderId AND Deal__c = :optionAndFeeList[0].Deal__c AND Service_Order_Line_Item__c = null LIMIT 1].size() > 0);
                if(!dealMerchSectionExists) COService.addDefaultSalespersonToCOSection(coHeaderId, DealUtil.DEAL_MERCH, optionAndFeeList[0].Deal__c);
                CO_Line_Item__c coliRec = setColiFields(optionFeeRec, coHeaderId, null, optionAndFeeList[0].Deal__c);
                DMLUtility.insertSobjectList('CO_Line_Item__c', coliRec);
                coliToUpsert.add(coliRec);
                update new Option_Fee__c(Id = optionFeeRec.Id, CO_Line_Item__c = coliRec.Id);
            } else {
                COSectionDetailService.checkAndDeleteCOSection_future(coHeaderId, COSectionDetailService.DEAL_MERCHANDISE);
                if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Service_Order_Header__c> soHeaderList = [select Deal_Item__c from Service_Order_Header__c where Deal__c =: optionFeeRec.Deal_Item__r.Deal__c];
                Map<Id, Service_Order_Header__c> dealItemIdToSOHeaderRecMap = new Map<Id, Service_Order_Header__c>();
                for(Service_Order_Header__c soHeaderRec : soHeaderList) {
                    dealItemIdToSOHeaderRecMap.put(soHeaderRec.Deal_Item__c, soHeaderRec);
                }
                dealItemIdToSOHeaderRecMap.remove(null);
                
                Service_Order_Header__c soHeaderRec;
                if(!dealItemIdToSOHeaderRecMap.containsKey(optionFeeRec.Deal_Item__c)) {
                    soHeaderRec = setSOHeaderFields(optionFeeRec.Deal_Item__c, coHeaderId, dealItemIdToSOHeaderRecMap.keySet().size() + 1, optionFeeRec.Deal_Item__r.Deal__c,
                                                    optionFeeRec.Deal_Item__r.Customer_Owned_Unit__c);
                    DMLUtility.insertSobjectList('Service_Order_Header__c', soHeaderRec);
                } else {
                    soHeaderRec = dealItemIdToSOHeaderRecMap.get(optionFeeRec.Deal_Item__c);
                }
                Service_Order_Line_Item__c soliRec = setSoliFields(optionFeeRec, soHeaderRec.Id, null);
                DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliRec);
                update new Option_Fee__c(Id = optionFeeRec.Id, Service_Order_Line_Item__c = soliRec.Id);
                coliToUpsert.add([Select Id, Service_Order_Line_Item__c From CO_Line_Item__c WHERE Service_Order_Line_Item__c =: soliRec.Id]);
            } 
        }
        if(coliToUpsert.size() > 0 && coliMoveList.size() > 0 && voliListToUpsert.size() > 0) {
            COLineItemTriggerHelper.isMoveLineItem = false;
            updateVOLIANDCOLIOnPartMove(voliListToUpsert, coliToUpsert, coliMoveList);
        }
    }

    private static CO_Kit_Header__c setCOKitHeaderFields(Deal_Kit_Header__c dkhRec, String coHeaderId, String dealId) {
        CO_Kit_Header__c cokhRec = new CO_Kit_Header__c();
        cokhRec.CO_Header__c = coHeaderId;
        cokhRec.Deal__c = dealId;
        cokhRec.Kit_Header__c = dkhRec.Kit_Header__r.Id;
        cokhRec.Price__c = dkhRec.Fixed_Price__c;
        cokhRec.Actual_Kit_Price__c = dkhRec.Actual_Kit_Price__c;
        cokhRec.Can_Split__c = dkhRec.Can_Split__c;
        cokhRec.Fixed_Price_Flag__c = dkhRec.Is_Fixed_Price__c;
        cokhRec.Service_Kit__c = dkhRec.Service_Kit__c;
        cokhRec.Deal_Kit_Header__c = dkhRec.Id;
        cokhRec.CO_Fixed_KitHeader__c = dkhRec.Is_Fixed_Kit_Header_CO__c;
        
        return cokhRec;
    }

    private static CO_Line_Item__c setColiFields(Option_Fee__c optionAndFeeRec, String coHeaderId, String cokhId, String dealId) {
        CO_Line_Item__c coliRec = new CO_Line_Item__c();
        coliRec.Qty__c = (optionAndFeeRec.Qty__c == null) ? 1 : optionAndFeeRec.Qty__c;
        coliRec.Item_Code__c = optionAndFeeRec.Item_Code__c;
        coliRec.Item_Description__c = optionAndFeeRec.Item_Description__c;
        coliRec.Deal__c = dealId;
        coliRec.Kit_Header_Line_Item__c = optionAndFeeRec.Kit_Header_Line_Item__c;
        coliRec.Option_Fee__c = optionAndFeeRec.Id;
        coliRec.Part__c = optionAndFeeRec.Part__c;
        coliRec.CO_Header__c = coHeaderId;
        coliRec.Fee__c = optionAndFeeRec.Fee__c;
        coliRec.Related_Option_And_Fees__c = optionAndFeeRec.Id;
        coliRec.Price__c = optionAndFeeRec.Price__c;
        coliRec.Price_When_Tax_Included__c = optionAndFeeRec.Price__c;
        coliRec.Actual_Kit_Price__c = optionAndFeeRec.Price__c;
        
        if(cokhId != null) {
            coliRec.CO_Kit_Header__c = cokhId;
            coliRec.Fixed_Price__c = optionAndFeeRec.Is_Fixed_Price__c;
            coliRec.Actual_Kit_Price__c = optionAndFeeRec.Actual_Kit_Price__c;
            coliRec.Price__c = optionAndFeeRec.Kit_Header_Line_Item__r.Kit_Price__c;
            coliRec.Price_When_Tax_Included__c = null;
        }            
        return coliRec;
    }

    private static Service_Order_Header__c setSOHeaderFields(String dealItemRecId, String coHeaderId, Integer counter, String dealId, String unitId) {
        Service_Order_Header__c soHeaderToInsert = new Service_Order_Header__c();
        soHeaderToInsert.Name__c = 'Deal Service ' + counter;
        soHeaderToInsert.CO_Header__c = coHeaderId;
        soHeaderToInsert.Status__c = 'New';
        soHeaderToInsert.SO_Status_Ref__c = ServiceJobUtil.getSOStatusConfigByName(ServiceJobUtil.NEW_JOB).Id;
        soHeaderToInsert.SO_Concern__c = CONSTANTS.INSTALL_DEAL_OPTION;
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Header__c> coHeaderList = [Select CO_Type__c, Selling_Group__c from CO_Header__c where Id = :coHeaderId];
        String coType;
        if(coHeaderList.size() > 0) {
            soHeaderToInsert.SO_Type__c = coHeaderList[0].CO_Type__c;
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Transaction_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Transaction_Type__c> ttList = [Select Code__c, Code_Label__c from Transaction_Type__c where Type__c = 'Deal Service' AND Default__c = true];
        if(ttList.size() > 0) {
            soHeaderToInsert.Transaction_Type__c = ttList[0].Id;
        }
        
        soHeaderToInsert.Customer_Owned_Unit__c = unitId;
        soHeaderToInsert.Deal__c = dealId;
        soHeaderToInsert.Deal_Item__c = dealItemRecId;
        soHeaderToInsert.SO_Type__c = 'Deal';
        return soHeaderToInsert;
    }
    
    private static Service_Order_Line_Item__c setSoliFields(Option_Fee__c optionAndFeeRec, String soHeaderId, String sokhRecId) {
        Service_Order_Line_Item__c soliToInsert = new Service_Order_Line_Item__c();
        soliToInsert.Qty_Needed__c = optionAndFeeRec.Qty__c;
        soliToInsert.Item_Code__c = optionAndFeeRec.Item_Code__c;
        soliToInsert.Item_Description__c = optionAndFeeRec.Item_Description__c;
        soliToInsert.Deal__c = optionAndFeeRec.Deal__c;
        soliToInsert.Kit_Header_Line_Item__c = optionAndFeeRec.Kit_Header_Line_Item__c;
        soliToInsert.Deal_Item__c = optionAndFeeRec.Deal_Item__c;
        soliToInsert.Option_Fee__c = optionAndFeeRec.Id;
        soliToInsert.Part__c = optionAndFeeRec.Part__c;
        soliToInsert.Labour_Code__c = optionAndFeeRec.Labour_Code__c;
        soliToInsert.Service_Order_Header__c = soHeaderId;
        soliToInsert.Kit_Price__c = optionAndFeeRec.Price__c;
        soliToInsert.Price_When_Tax_Included__c = optionAndFeeRec.Price__c;
        soliToInsert.Sublet__c = optionAndFeeRec.Product__c;
        soliToInsert.Commit_Order_Controls__c = CONSTANTS.COMMIT_AND_ORDER;
        
        if(sokhRecId != null) {
            soliToInsert.Service_Order_Kit_Header__c = sokhRecId;
            soliToInsert.Fixed_Price__c = optionAndFeeRec.Is_Fixed_Price__c;
            soliToInsert.Is_Fixed_Kit_LineItem_SO__c = optionAndFeeRec.Is_Fixed_Kit_Line_Item_CO__c;
            soliToInsert.Fee__c = optionAndFeeRec.Fee__c;
            soliToInsert.Tax_Percent__c = (optionAndFeeRec.Sales_Tax_Percentage__c != null) ? optionAndFeeRec.Sales_Tax_Percentage__c : 0;
            soliToInsert.Actual_Kit_Price__c = optionAndFeeRec.Actual_Kit_Price__c;
            soliToInsert.Price_When_Tax_Included__c = null;
        }
        return soliToInsert;
    }
    
    private static Service_Order_Kit_Header__c setSOKitHeaderFields(Deal_Kit_Header__c dkhRec, String soHeaderId, String dealId) {
        Service_Order_Kit_Header__c sokhRec = new Service_Order_Kit_Header__c();
        sokhRec.Service_Order_Header__c = soHeaderId;
        sokhRec.Kit_Header__c = dkhRec.Kit_Header__r.Id;
        sokhRec.Can_Split__c = dkhRec.Can_Split__c;
        sokhRec.Code__c = dkhRec.Code__c;
        sokhRec.Description__c = dkhRec.Description__c;
        sokhRec.Fixed_Price__c = dkhRec.Fixed_Price__c;
        sokhRec.Fixed_Price_Flag__c = dkhRec.Is_Fixed_Price__c;
        sokhRec.Is_Fixed_Kit_Header_SO__c = dkhRec.Is_Fixed_Kit_Header_CO__c;
        sokhRec.Service_Kit__c = dkhRec.Service_Kit__c;
        sokhRec.Actual_Kit_Price__c = dkhRec.Fixed_Price__c;
        sokhRec.Deal_Kit_Header__c = dkhRec.Id;
        sokhRec.Deal_Item__c = dkhRec.Deal_Item__c;
        sokhRec.Deal__c = dealId;
        
        return sokhRec;
    }

    private static Deal_Finance__c setDealFinanceField(DealWrapper.DealFinanceWrapper dealFinanceObj) {
        Deal_Finance__c dealFinanceRec = new Deal_Finance__c();
        
        dealFinanceRec.Id = dealFinanceObj.Id;
        dealFinanceRec.Finance_Company__c = dealFinanceObj.FinanceCompanyId;
        dealFinanceRec.Deal__c = dealFinanceObj.DealId;
        dealFinanceRec.Down_Payment__c = dealFinanceObj.DownPayment;
        dealFinanceRec.Interest_Rate__c = dealFinanceObj.InterestRate;
        dealFinanceRec.Loan_Term__c = dealFinanceObj.LoanTerm;
        dealFinanceRec.Term_Type__c = dealFinanceObj.TermType;
        dealFinanceRec.Payment_Frequency__c = dealFinanceObj.PaymentFrequency;
        dealFinanceRec.Estimated_Payment__c = dealFinanceObj.EstimatedPayment;
        dealFinanceRec.Finance_Commission__c = dealFinanceObj.FinanceCommission;
        dealFinanceRec.Buy_Rate__c = dealFinanceObj.BuyRate;
        dealFinanceRec.Buy_Rate_Commission__c = dealFinanceObj.BuyRateCommission;
        return dealFinanceRec;
    }

    /**
     * Name: saveDealInfoDetails
     * Desc: Method which gives provide deal rec using co header id
     * @param:  (1) dealId - String - deal id
     * @param:  (2) json - String - deal info json
     * @return: String - JSON String of deal
    **/
    public static String saveDealInfoDetails(String coHeaderId, String dealId, String json) {
        dealId = BPUtility.getDecodedString(dealId);
        json = BPUtility.getDecodedString(json);
        
        if(String.isBlank(dealId)) {
            return BPUtility.getEncodedString('{}');
        }
        DealWrapper.DealInfoWrapper dealObj = (DealWrapper.DealInfoWrapper) System.JSON.deserialize(json, DealWrapper.DealInfoWrapper.class);
        Deal__c dealRec = setDealValues(dealObj);
        dealRec.Id = dealId;
        DMLUtility.updateSobjectList('Deal__c', dealRec);
        return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealInfo'));
    }

    public static String createDealMerchAndServiceSetion(String dealId, String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        dealId = BPUtility.getDecodedString(dealId);
        List<Deal_Item__c> dealItemList = SOQLUtil.getDealItemDetailsByFieldName(new Map<String, String>{'Deal__c' => dealId,
                                                                                                        'Type__c' => Constants.DEAL_ITEM_TYPE_UNIT});
        Map<Id, Deal_Item__c> dealIdToOptionFeeMap = new Map<Id, Deal_Item__c>();
        Set<String> couIdSet = new Set<String>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            dealIdToOptionFeeMap.put(dealItemRec.Id, dealItemRec);
            couIdSet.add(dealItemRec.Customer_Owned_Unit__c);
        }
        
        List<Deal_Kit_Header__c> dealKHList = SOQLUtil.getDealKitHeaderDetailsByDealItemId(new Set<Id>(dealIdToOptionFeeMap.keySet()));
        Map<Id, Deal_Kit_Header__c> dealKHIdToDKHMap = new Map<Id, Deal_Kit_Header__c>(dealKHList);
        
        //Map<Id, Option_Fee__c> partIdToDealMerchOptionFeeRecMap = new Map<Id, Option_Fee__c>();
        //Map<Id, String> partIdToSimilarOptionFeeRecMap = new Map<Id, String>();
        List<Option_Fee__c> merchOptionAndFeeList = new List<Option_Fee__c>();
        Map<Id, List<Option_Fee__c>> dealItemIdToDealServiceOptionAndFeeListMap = new Map<Id, List<Option_Fee__c>>();
        
        List<Deal_Kit_Header__c> dealKitHeaderToAddInMerchList = new List<Deal_Kit_Header__c>();
        Map<Id, List<Deal_Kit_Header__c>> dealItemIdToServiceDKHListMap = new Map<Id, List<Deal_Kit_Header__c>>();

        Set<String> dealItemIdToInsertDealServiceSet = new Set<String>();
        Boolean isNonInventoryDealServicePartAvailable = false;
        for(Deal_Item__c dealItemRec : dealItemList) {
            List<Option_Fee__c> installedOptionAndFeeRecList = new List<Option_Fee__c>();
            for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
                if(optionAndFeeRec.Part__c != null || optionAndFeeRec.Labour_Code__c != null || (optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Type__c == 'Sublet')) {
                    if(!optionAndFeeRec.Is_Install__c) { // Deal Merch Section
                        merchOptionAndFeeList.add(optionAndFeeRec);
                    } else { // Deal Service Section
                        if(optionAndFeeRec.Part__c != null && optionAndFeeRec.Part__r.Non_Inventory_Part__c) {
                            isNonInventoryDealServicePartAvailable = true;
                        }
                        installedOptionAndFeeRecList.add(optionAndFeeRec);
                        dealItemIdToDealServiceOptionAndFeeListMap.put(dealItemRec.Id, installedOptionAndFeeRecList);
                        dealItemIdToInsertDealServiceSet.add(dealItemRec.Id);
                    }
                }
            }
            
            List<Deal_Kit_Header__c> dkhList = new List<Deal_Kit_Header__c>();
            for(Deal_Kit_Header__c dealKitHeaderRec : dealItemRec.Deal_Kit_Headers__r) {
                if(dealKitHeaderRec.Is_Install__c) {
                    if(dealKHIdToDKHMap.containsKey(dealKitHeaderRec.Id)) {
                        dkhList.add(dealKHIdToDKHMap.get(dealKitHeaderRec.Id));
                        dealItemIdToServiceDKHListMap.put(dealItemRec.Id, dkhList);
                        dealItemIdToInsertDealServiceSet.add(dealItemRec.Id);
                    }
                } else {
                    if(dealKHIdToDKHMap.containsKey(dealKitHeaderRec.Id)) {
                        dealKitHeaderToAddInMerchList.add(dealKHIdToDKHMap.get(dealKitHeaderRec.Id));
                    }
                }
            }
            dealItemRec.Option_And_Fee_Status__c = Constants.COMMITTED;
        }
        
        // Insert Line Items q-4
        List<CO_Line_Item__c> coLineItemListToInsert = new List<CO_Line_Item__c>();
        List<Service_Order_Header__c> soHeaderListToInsert = new List<Service_Order_Header__c>();
        List<Service_Order_Line_Item__c> soliListToInsert = new List<Service_Order_Line_Item__c>();
        
        //Non-kit part
        for(Option_Fee__c optionAndFeeRec : merchOptionAndFeeList) {
            CO_Line_Item__c coliRec = setColiFields(optionAndFeeRec, coHeaderId, null, dealId);
            coLineItemListToInsert.add(coliRec);
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Header__c> coHeaderList = [Select CO_Type__c, Selling_Group__c from CO_Header__c where Id = :coHeaderId];
        String coType;
        if(coHeaderList.size() > 0) {
            coType = coHeaderList[0].CO_Type__c;
        }
        Integer counter = 1;
        /*
        for(String dealItemRecId : dealItemIdToDealServiceOptionAndFeeListMap.keySet()) {
            soHeaderListToInsert.add(setSOHeaderFields(dealItemRecId, coHeaderId, counter, dealId, dealIdToOptionFeeMap.get(dealItemRecId).Customer_Owned_Unit__c));
            counter++;
        }*/
        //SOHeader for all required deal items
        for(String dealItemRecId : dealItemIdToInsertDealServiceSet) {
            soHeaderListToInsert.add(setSOHeaderFields(dealItemRecId, coHeaderId, counter, dealId, dealIdToOptionFeeMap.get(dealItemRecId).Customer_Owned_Unit__c));
            counter++;
        }
        //q-7
        if(coLineItemListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('CO_Line_Item__c', coLineItemListToInsert);
        }
        if(soHeaderListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Service_Order_Header__c', soHeaderListToInsert);
        }       
        //q-19
        //Invoice item
        
        //Map to contain DealItem id to so Header id map
        Map<String, String> dealItemIdToSOHeaderIdMap = new Map<String, String>();
        for(Service_Order_Header__c soHeaderRec : soHeaderListToInsert) {
            dealItemIdToSOHeaderIdMap.put(soHeaderRec.Deal_Item__c, soHeaderRec.Id);
        }
        
        //Insert Kit in Merch grid
        List<CO_Kit_Header__c> cokhList = new List<CO_Kit_Header__c>();
        for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaderToAddInMerchList) {
            cokhList.add(setCOKitHeaderFields(dealKitHeaderRec, coHeaderId, dealId));
        }
        //q-19
        if(cokhList.size() > 0) {
            DMLUtility.insertSobjectList('CO_Kit_Header__c', cokhList);
        }
        
        //Insert invoice item for so and deal
        List<CO_Invoice_Item__c> coInvoiceItemListToInsert = new List<CO_Invoice_Item__c>();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Invoice_Header__c> coInvoiceHeaderList = [Select Id, (Select Id from CO_Invoice_Items__r where Deal__c =: dealId) from CO_Invoice_Header__c where CO_Header__c = :coHeaderId AND Invoice_Status__c = 'Active'];
        if(coInvoiceHeaderList.size() == 0) {
            coInvoiceHeaderList.add(new CO_Invoice_Header__c(CO_Header__c = coHeaderId, Invoice_Status__c = 'Active'));
            if(AccessControl.ifObjectFieldIsCreateable('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert coInvoiceHeaderList;
        }
        
        Boolean isLoadingNewCO = GeneralConfiguration.isLoadNewCustomerOrder();
        
        String dealStatus = Constants.IN_PROGRESS;
        CO_Invoice_Item__c coInvoiceItem;
        if(coInvoiceHeaderList[0].CO_Invoice_Items__r.size() > 0) {
            coInvoiceItem = coInvoiceHeaderList[0].CO_Invoice_Items__r[0];
        } else {
            coInvoiceItem = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeaderList[0].Id, isActive__c = true, Is_Invoiceable__c = false, Deal__c = dealId);
        }
        
        // Changed according to Ticket #6543 - TK
        Map<String, Boolean> optionNameToOptionValueMap = isDealInvoiceable(dealId);
        coInvoiceItem.Is_Invoiceable__c = optionNameToOptionValueMap.get('Invoiceable');
        coInvoiceItem.isActive__c = optionNameToOptionValueMap.get('Active');
        
        if(coLineItemListToInsert.size() == 0 && soHeaderListToInsert.size() == 0 && cokhList.size() == 0) {
            dealStatus = Constants.FULFILLED; 
            /*if(!isLoadingNewCO || dealItemList[0].Deal__r.Status__c == 'Approved') {
                coInvoiceItem.isActive__c = true;
                coInvoiceItem.Is_Invoiceable__c = true;
            }*/
        }
        coInvoiceItemListToInsert.add(coInvoiceItem);
        for(Service_Order_Header__c soHeaderRec :  soHeaderListToInsert){
             CO_Invoice_Item__c coInvoiceItemRec = new CO_Invoice_Item__c(CO_Invoice_Header__c = coInvoiceHeaderList[0].Id, isActive__c = true, Is_Invoiceable__c = false, Service_Order_Header__c = soHeaderRec.Id);
             coInvoiceItemListToInsert.add(coInvoiceItemRec);
        }
        if(coInvoiceItemListToInsert.size() > 0){
            DMLUtility.upsertSobjectList('CO_Invoice_Item__c', coInvoiceItemListToInsert);
        }
        
        //q-20
        //Merch grid kit line item
        List<Co_Line_Item__c> coliList = new List<CO_Line_Item__c>();
        for(CO_Kit_Header__c coKitHeaderRec : cokhList) {
            if(dealKHIdToDKHMap.containsKey(coKitHeaderRec.Deal_Kit_Header__c)) {
                for(Option_Fee__c optionAndFeeRec : dealKHIdToDKHMap.get(coKitHeaderRec.Deal_Kit_Header__c).Options_Fees__r) {
                    coliList.add(setColiFields(optionAndFeeRec, coHeaderId, coKitHeaderRec.Id, dealId));
                }
            }
        }
        //q-20
        if(coliList.size() > 0) {
            DMLUtility.insertSobjectList('Co_Line_Item__c', coliList);
        }
        
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            Map<Id, CO_Kit_Header__c> cokhIdToCokhListMap = new Map<Id, CO_Kit_Header__c>();
            for(CO_Line_Item__c coLineItemRec : coliList) {
                
                Decimal price = 0;
                if(cokhIdToCokhListMap.containsKey(coLineItemRec.CO_Kit_Header__c)) {
                    price = (cokhIdToCokhListMap.get(coLineItemRec.CO_Kit_Header__c).Price__c != null) ? cokhIdToCokhListMap.get(coLineItemRec.CO_Kit_Header__c).Price__c : 0;
                }
                coLineItemRec.Price_When_Tax_Included__c = (coLineItemRec.Price_When_Tax_Included__c != null) ? coLineItemRec.Price_When_Tax_Included__c : 0;
                coLineItemRec.Qty__c = (coLineItemRec.Qty__c != null) ? coLineItemRec.Qty__c : 0;
                price += (coLineItemRec.Price_When_Tax_Included__c * coLineItemRec.Qty__c);
                cokhIdToCokhListMap.put(coLineItemRec.CO_Kit_Header__c, new CO_Kit_Header__c(Id = coLineItemRec.CO_Kit_Header__c, Price__c = price));
            }
            
            if(cokhIdToCokhListMap.keySet().size() > 0) {
                update cokhIdToCokhListMap.values();
            }
        }
        
        
        //q-34
        
        List<Service_Order_Kit_Header__c> sokhList = new List<Service_Order_Kit_Header__c>();
        
        //Non-kit soli and sokit header formation
        for(String dealItemRecId : dealItemIdToInsertDealServiceSet) {
            //Non kit soli
            if(dealItemIdToDealServiceOptionAndFeeListMap.containsKey(dealItemRecId)) {
                for(Option_Fee__c optionFeeRec : dealItemIdToDealServiceOptionAndFeeListMap.get(dealItemRecId)) {
                    if(dealItemIdToSOHeaderIdMap.containsKey(dealItemRecId)) {
                        soliListToInsert.add(setSoliFields(optionFeeRec, dealItemIdToSOHeaderIdMap.get(dealItemRecId), null));
                    }
                }
            }
            //so kit header
            if(dealItemIdToServiceDKHListMap.containsKey(dealItemRecId)) {
                for(Deal_Kit_Header__c dealKitHeaderRec : dealItemIdToServiceDKHListMap.get(dealItemRecId)) {
                    if(dealItemIdToSOHeaderIdMap.containsKey(dealItemRecId)) {
                        sokhList.add(setSOKitHeaderFields(dealKitHeaderRec, dealItemIdToSOHeaderIdMap.get(dealItemRecId), dealId)); 
                    }
                }
            }
        }
        //q-71
        if(sokhList.size() > 0) {
            DMLUtility.insertSobjectList('Service_Order_Kit_Header__c', sokhList);
        }
        //q-71
        //so kit line item 
        for(Service_Order_Kit_Header__c soKitHeaderRec : sokhList) {
            if(dealKHIdToDKHMap.containsKey(soKitHeaderRec.Deal_Kit_Header__c)) {
                for(Option_Fee__c optionAndFeeRec : dealKHIdToDKHMap.get(soKitHeaderRec.Deal_Kit_Header__c).Options_Fees__r) {
                    soliListToInsert.add(setSoliFields(optionAndFeeRec, soKitHeaderRec.Service_Order_Header__c, soKitHeaderRec.Id));
                }
            }
        }
        
        if(soliListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliListToInsert);
        }
        
        List<Option_Fee__c> optionFeeRecUpdateList = new List<Option_Fee__c>();
        for(CO_Line_Item__c coliRec: coLineItemListToInsert) {
            optionFeeRecUpdateList.add(new Option_Fee__c(Id = coliRec.Option_Fee__c, CO_Line_Item__c = coliRec.Id));
            
        }
        
        List<Option_Fee__c> optionFeeUpdateList = new List<Option_Fee__c>();
        for(CO_Line_Item__c coliRec: coLineItemListToInsert) {
            optionFeeUpdateList.add(new Option_Fee__c(Id = coliRec.Option_Fee__c, CO_Line_Item__c = coliRec.Id, Status__c = Constants.COMMITTED));
        }
        for(Service_Order_Line_Item__c soliRec: soliListToInsert) {
            optionFeeUpdateList.add(new Option_Fee__c(Id = soliRec.Option_Fee__c, Service_Order_Line_Item__c = soliRec.Id, Status__c = Constants.COMMITTED));
        }
        
        if(optionFeeUpdateList.size() > 0) {
            BPScriptUtility.disbaleTrigger('OptionAndFeeTrigger');
            update optionFeeUpdateList;
            BPScriptUtility.enableTrigger('OptionAndFeeTrigger');
        }
        
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            Map<Id, Service_Order_Kit_Header__c> sokhIdToSokhListMap = new Map<Id, Service_Order_Kit_Header__c>();
            for(Service_Order_Line_Item__c soLineItemRec : soliListToInsert) {
                if(String.isNotBlank(soLineItemRec.Service_Order_Kit_Header__c)) {
                    Decimal price = 0;
                    if(sokhIdToSokhListMap.containsKey(soLineItemRec.Service_Order_Kit_Header__c)) {
                        price = (sokhIdToSokhListMap.get(soLineItemRec.Service_Order_Kit_Header__c).Fixed_Price__c != null) ? sokhIdToSokhListMap.get(soLineItemRec.Service_Order_Kit_Header__c).Fixed_Price__c : 0;
                    }
                    soLineItemRec.Price_When_Tax_Included__c = (soLineItemRec.Price_When_Tax_Included__c != null) ? soLineItemRec.Price_When_Tax_Included__c : 0;
                    soLineItemRec.Qty_Needed__c = (soLineItemRec.Qty_Needed__c != null) ? soLineItemRec.Qty_Needed__c : 0;
                    price += (soLineItemRec.Price_When_Tax_Included__c * soLineItemRec.Qty_Needed__c);
                    
                    sokhIdToSokhListMap.put(soLineItemRec.Service_Order_Kit_Header__c, new Service_Order_Kit_Header__c(Id = soLineItemRec.Service_Order_Kit_Header__c, Fixed_Price__c = price));
                }
                
            }
            
            if(sokhIdToSokhListMap.keySet().size() > 0) {
                update sokhIdToSokhListMap.values();
            }
        }
        
        if(AccessControl.ifObjectFieldIsUpdateable('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<SObject> sObjectListToUpdate = new List<SObject>((List<SObject>)dealItemList);
        
        Deal__c dealRec = new Deal__c(Id = dealId, Unit_Status__c = Constants.COMMITTED);
        
        if(isLoadingNewCO) {
            dealRec.Is_Deal_Fulfilled__c = (dealStatus == Constants.FULFILLED) ? true : false;
        } else {
            dealRec.Status__c = dealStatus;
        }
        sObjectListToUpdate.addAll((List<SObject>)(new List<Deal__c>{dealRec}));
        
        List<Customer_Owned_Unit__c> couList = [Select Status__c from Customer_Owned_Unit__c where Id In :couIdSet];
        for(Customer_Owned_Unit__c couRec : couList) {
            if(couRec.Status__c != Constants.ON_ORDER_STATUS) {
                couRec.Status__c = Constants.UNIT_STATUS_RESERVED;
            }
        }
        sObjectListToUpdate.addAll((List<SObject>)couList);
        update sObjectListToUpdate;
        
        if(isNonInventoryDealServicePartAvailable) {
            COSectionDetailService.setSectionStatus_future(new Set<Id>{coHeaderId}, COSectionDetailService.SERVICE);
        }
        
        //OptionAndFeeTriggerHelper.updateDealTotal(new Set<String>{dealId});
        return getDealDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('dealMerchandise'));
    }

    public static String updateTradeIn(String dealId, String jsonString) {
        dealId = BPUtility.getDecodedString(dealId);
        jsonString = BPUtility.getDecodedString(jsonString);
        
        DealItem dealItemObj = DealItem.parse(jsonString);
        if(dealItemObj != null && dealItemObj.FinanceCompanyId != null && ForeignExchangeUtil.isForeignVendor(dealItemObj.FinanceCompanyId)) {
            throw new BlackPurlException(Constants.restrictionErrorForForeignVendor);
        }
        dealItemObj.Type = Constants.DEAL_ITEM_TYPE_TRADE_IN;
        Deal_Item__c dealItemRec = setDealItemValues(dealItemObj, dealId);
        
        if(dealItemObj.Id == null) {
            String defaultUnitSalesTaxId = Configurations__c.getInstance().Default_Tax_on_Unit__c;
            if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Sales_Tax__c> salesTaxList = [Select Id, Rate__c from Sales_Tax__c WHERE Id = :defaultUnitSalesTaxId];
            if(salesTaxList.size() > 0) {
                dealItemRec.Default_Unit_Sales_Tax_Percentage__c = salesTaxList[0].Rate__c;
                dealItemRec.Applicable_Tax__c = salesTaxList[0].Id;
                dealItemRec.Taxable__c = true;
            }
        }
        DMLUtility.upsertSobjectList('Deal_Item__c', dealItemRec);
        
        if(GeneralConfiguration.getAccrueTradeTaxUntilUnitSold()) {
            List<Deal_Item__c> dealItemRecList = [SELECT Id, Stocked_In_Unit__c, Agreed_Value__c, Default_Unit_Sales_Tax_Percentage__c FROM Deal_Item__c 
                                                    WHERE Id =: dealItemRec.Id AND Stocked_In_Unit__c != null];
            if(dealItemRecList.size() > 0) {
                Customer_Owned_Unit__c skuRecToUpdate = new Customer_Owned_Unit__c(Id = dealItemRecList[0].Stocked_In_Unit__c);
                DealService.populateTradeInAndSalesTaxOnSku(dealItemRecList[0], skuRecToUpdate);
                update skuRecToUpdate;
            }
        }
        //OptionAndFeeTriggerHelper.updateDealTotal(new Set<String>{dealId});
        return getDealItemDetails(dealItemRec.Id);
    }

    public static void finalizeDeal(String dealId, String coInvoiceNumber, String invNumber, DateTime invoiceDate) {
        if(String.isNotBlank(dealId)) {
            if(AccessControl.ifObjectFieldIsCreateable('Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Deal_Unit_Price_Cost__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Deal__c> dealList = [Select Id, CO_Header__r.Customer__c, CO_Header__r.Name,
                                        (Select CO_Invoice_Header__r.Invoice_Number__c FROM CO_Invoice_Items__r), 
                                        (Select Id, Finance_Company__r.Commissions_not_in_finance_payments__c FROM Deal_Finances__r), 
                                        (Select Id, Type__c, Agreed_value__c, Category__c, Default_Unit_Sales_Tax_Percentage__c, 
                                            Actual_Cash_Value__c, Is_Stocked_In__c, Customer_Owned_Unit__c, Customer_Owned_Unit__r.Status__c, 
                                            Stocked_In_Unit__c,Stocked_In_Unit__r.Category__c, Transfer_Plate_Reg_to_New_Unit__c, 
                                            Transfer_To__c, Mileage__c, Mileage_Type__c, Unit_Price__c from Deal_Items__r) from Deal__c where Id = :dealId];
            
            if(dealList.size() > 0) {
                Map<Id, Deal_Item__c> couIdToDealItemRecMap = new Map<Id, Deal_Item__c>();
                Map<Id, Deal_Item__c> skuIdToDealItemRecMap = new Map<Id, Deal_Item__c>();
                Map<Id, Customer_Owned_Unit__c> couIdToRelatedCOUMap = new Map<Id, Customer_Owned_Unit__c>();
                List<Customer_Owned_Unit__c> unitListToUpdateStatus = new List<Customer_Owned_Unit__c>();
                List<String> unitIdList = new List<String>();
                List<String> dealItemIdList = new List<String>();
                List<Unit_Price_Cost__c> unitPriceAndCostList = new List<Unit_Price_Cost__c>();
                Map<Id, Id> dealItemIdToStockedInUnitIdMap = new Map<Id, Id>();
                Map<Id, Deal_Item__c> stockedInUnitIdToDealItemRecMap = new Map<Id, Deal_Item__c>();
                
                Map<String, String> skuIdToDealItemIdMap = new Map<String, String>();
                Map<String, String> transferToUnitIdToTradeInUnitIdMap = new Map<String, String>();
                
                Boolean isTradeOnlyDeal = true;
                for(Deal_Item__c dealItemRec : dealList[0].Deal_Items__r) {
                    if(String.isNotBlank(dealItemRec.Customer_Owned_Unit__c) && !dealItemRec.Is_Stocked_In__c) {
                        unitIdList.add(dealItemRec.Customer_Owned_Unit__c);
                    }
                    
                    if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT) {
                        isTradeOnlyDeal = false;
                        dealItemIdList.add(dealItemRec.Id);
                        skuIdToDealItemIdMap.put(dealItemRec.Customer_Owned_Unit__c, dealItemRec.Id);
                        skuIdToDealItemRecMap.put(dealItemRec.Customer_Owned_Unit__c, dealItemRec);
                    } else if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN && !dealItemRec.Is_Stocked_In__c) {
                        couIdToDealItemRecMap.put(dealItemRec.Customer_Owned_Unit__c, dealItemRec);
                        if(dealItemRec.Transfer_Plate_Reg_to_New_Unit__c && dealItemRec.Transfer_To__c != null) transferToUnitIdToTradeInUnitIdMap.put(dealItemRec.Transfer_To__c, dealItemRec.Customer_Owned_Unit__c);
                    } else if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN && dealItemRec.Is_Stocked_In__c) {
                        stockedInUnitIdToDealItemRecMap.put(dealItemRec.Stocked_In_Unit__c, dealItemRec);
                        if(dealItemRec.Transfer_Plate_Reg_to_New_Unit__c && dealItemRec.Transfer_To__c != null) transferToUnitIdToTradeInUnitIdMap.put(dealItemRec.Transfer_To__c, dealItemRec.Customer_Owned_Unit__c);
                    }
                }

                Map<String, Customer_Owned_Unit__c> tradeInUnitIdToRecMap;
                if(transferToUnitIdToTradeInUnitIdMap.size() > 0) {
                    tradeInUnitIdToRecMap = new Map<String, Customer_Owned_Unit__c>([SELECT Plate__c, Reg_Expiry_Date__c FROM Customer_Owned_Unit__c WHERE Id IN :transferToUnitIdToTradeInUnitIdMap.values()]);
                }
                
                if(unitIdList.size() > 0) {
                    String query = 'Select ';
                    for(String fieldName : CustomerOwnedUnit.fieldsList()) {
                        query += fieldName + ', ';
                    }
                    query += '(Select ';
                    for(String fieldName : UNitWrapper.fieldsListForUnitPriceAndCostTracking()) {
                        query += fieldName + ', ';
                    }
                    
                    query = query.substring(0, query.length()-2);
                    query += ' from Unit_Prices_Costs__r where Type__c = \'Base\')';
                    query += ' from Customer_Owned_Unit__c where Id In :unitIdList';
                    
                    unitListToUpdateStatus = Database.query(query);
                }
                
                Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
                if(dealItemIdList.size() > 0) {
                    String query = 'Select ';
                    for(String fieldName : DealWrapper.getDealUnitPriceCost()) {
                        query += fieldName + ', ';
                    }
                    
                    query = query.substring(0, query.length()-2);
                    query += ' from Deal_Unit_Price_Cost__c where Deal_Item__c In :dealItemIdList';
                    
                    List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = Database.query(query);
                    
                    List<Unit_Price_Cost__c> unitPriceAndCostListToUpsert = new List<Unit_Price_Cost__c>();
                    Map<String, Unit_Price_Cost__c> unitIdToBaseUPCRecToInsertMap = new Map<String, Unit_Price_Cost__c>();
                    Map<String, Unit_Price_Cost__c> priceAndCostIdToRecMap = new Map<String, Unit_Price_Cost__c>();
                    
                    for(Deal_Unit_Price_Cost__c dealUnitPriceAndCostRec : dealUnitPriceAndCostList) {
                    	Decimal price = isTaxIncludingPricing ? dealUnitPriceAndCostRec.Price_When_Tax_Included__c : dealUnitPriceAndCostRec.Price__c;
                    	price = price != null ? price : 0;
                    	
                        Unit_Price_Cost__c unitPriceAndCostRec = new Unit_Price_Cost__c(Id = dealUnitPriceAndCostRec.Unit_Price_Cost__c, Price__c = price);
                        if(dealUnitPriceAndCostRec.Type__c == 'Base' || dealUnitPriceAndCostRec.Type__c == 'Factory') {
                            unitPriceAndCostRec.Total_Price__c = price;
                        } else {
                        	dealUnitPriceAndCostRec.Qty__c = (dealUnitPriceAndCostRec.Qty__c != null && dealUnitPriceAndCostRec.Qty__c != 0) ? dealUnitPriceAndCostRec.Qty__c : 1;
                        	dealUnitPriceAndCostRec.Price__c = price;
                        	unitPriceAndCostRec.Total_Price__c = (price.setScale(2, RoundingMode.HALF_UP) * dealUnitPriceAndCostRec.Qty__c);
                        }
                        if(dealUnitPriceAndCostRec.Type__c == 'Base' && String.isBlank(unitPriceAndCostRec.Id)) {
                        	unitPriceAndCostRec.Customer_Owned_Unit__c = dealUnitPriceAndCostRec.Deal_Item__r.Customer_Owned_Unit__c;
                        	unitPriceAndCostRec.Type__c = dealUnitPriceAndCostRec.Type__c;
                        	unitIdToBaseUPCRecToInsertMap.put(dealUnitPriceAndCostRec.Deal_Item__r.Customer_Owned_Unit__c, unitPriceAndCostRec);
                        } else {
	                        unitPriceAndCostListToUpsert.add(unitPriceAndCostRec);
	                        priceAndCostIdToRecMap.put(unitPriceAndCostRec.Id, unitPriceAndCostRec);
                        }
                    }
                    if(unitPriceAndCostListToUpsert.size() > 0 || unitIdToBaseUPCRecToInsertMap.size() > 0) {
                        for(Customer_Owned_Unit__c unitRec : unitListToUpdateStatus) {
                            if(unitRec.Unit_Type__c.toLowerCase() == 'stock') {
                                for(Unit_Price_Cost__c priceAndCostRec : unitRec.Unit_Prices_Costs__r) {
                    				if(priceAndCostRec.Type__c == 'Base' && !priceAndCostIdToRecMap.containsKey(priceAndCostRec.Id)) {
                    					if(unitIdToBaseUPCRecToInsertMap.containsKey(unitRec.Id) && String.isBlank(unitIdToBaseUPCRecToInsertMap.get(unitRec.Id).Id)) {
                    						unitIdToBaseUPCRecToInsertMap.get(unitRec.Id).Id = priceAndCostRec.Id;
                    					} else {
                                        priceAndCostRec.Total_Price__c = priceAndCostRec.Price__c = 0;
                    						unitPriceAndCostListToUpsert.add(priceAndCostRec);
                    					}
                                    }
                                }
                            }
                        }
                        if(unitIdToBaseUPCRecToInsertMap.size() > 0) {
                        	unitPriceAndCostListToUpsert.addAll(unitIdToBaseUPCRecToInsertMap.values());
                        }
                        DMLUtility.upsertSobjectList('Unit_Price_Cost__c', unitPriceAndCostListToUpsert);
                    }
                }
                String defaultUnitSalesTaxId = Configurations__c.getInstance().Default_Tax_on_Unit__c;

                for(CO_Invoice_Item__c dealInvItemRec: dealList[0].CO_Invoice_Items__r) {
                    invNumber = dealInvItemRec.CO_Invoice_Header__r.Invoice_Number__c;
                    break;
                }
                Integer consignmentUnitCounter = 1;
                for(Customer_Owned_Unit__c unitRec : unitListToUpdateStatus) {
                    SObject unitToInsert = unitRec.clone(false, false, false, false);
                    if(unitRec.Unit_Type__c != null && (unitRec.Unit_Type__c.equalsIgnoreCase(Constants.UNIT_TYPE_STOCK) || 
                    		(unitRec.Unit_Type__c.equalsIgnoreCase(Constants.UNIT_TYPE_COU) && unitRec.Consignment__c))) {
                        unitRec.Date_Stocked_Out__c = date.newinstance(invoiceDate.year(), invoiceDate.month(), invoiceDate.day());
                        if(unitRec.Unit_Type__c.equalsIgnoreCase(Constants.UNIT_TYPE_COU)) {
                    		unitRec.Status__c = 'Transferred';
                    		unitRec.Credit_Note_Number__c = String.isNotBlank(invNumber) ? invNumber.replace('INV', 'CONS') + '_' + consignmentUnitCounter++ : null;
                            unitRec.Date_Stocked_In__c = unitRec.Date_Stocked_Out__c;
                            unitRec.Reference_Number__c = dealList[0].CO_Header__r.Name;
                        } else {
                            unitRec.Status__c = 'Sold';
                    	}
                        unitRec.Sale_Number__c = dealList[0].CO_Header__r.Name;
                        unitRec.Sold_To__c = dealList[0].CO_Header__r.Customer__c;
                        unitRec.Sold_Price__c = skuIdToDealItemRecMap.get(unitRec.Id).Unit_Price__c;

                        unitToInsert.put('Id',null);
                        unitToInsert.put('Unit_Type__c',Constants.UNIT_TYPE_COU);
                        unitToInsert.put('Status__c','Active');
                        unitToInsert.put('Account__c', dealList[0].CO_Header__r.Customer__c);
                        
                        unitToInsert.put('Stock_Id__c',null);
                        unitToInsert.put('Unit_Id__c',null);
                        unitToInsert.put('New_Unit__c',false);
                        unitToInsert.put('Category__c',null);
                        unitToInsert.put('Date_Stocked_In__c', null);
                        unitToInsert.put('Date_Stocked_Out__c',null);
                        unitToInsert.put('Location__c',null);
                        
                        unitToInsert.put('Total_Base_Unit_Price__c',null);
                        unitToInsert.put('Total_Base_Units_Cost__c',null);
                        unitToInsert.put('Total_Dealer_Options_Cost__c',null);
                        unitToInsert.put('Total_Dealer_Options_Price__c', null);
                        unitToInsert.put('Total_Factory_Options_Cost__c',null);
                        unitToInsert.put('Total_Factory_Options_Price__c',null);
                        unitToInsert.put('Manufactured_Date__c',null);
                        unitToInsert.put('Total_Cost__c',null);
                        unitToInsert.put('Total_Price__c',null);
                        
                        unitToInsert.put('Consignment__c', false);
                        unitToInsert.put('Agreed_Payout__c', null);
                        unitToInsert.put('Suggested_Price__c', null);
                        unitToInsert.put('Mileage_Value__c', skuIdToDealItemRecMap.get(unitRec.Id).Mileage__c);
                        unitToInsert.put('Mileage_Type__c', skuIdToDealItemRecMap.get(unitRec.Id).Mileage_Type__c);
                        if(transferToUnitIdToTradeInUnitIdMap.containsKey(unitRec.Id) && tradeInUnitIdToRecMap != null && tradeInUnitIdToRecMap.containsKey(transferToUnitIdToTradeInUnitIdMap.get(unitRec.Id))) {
                            Customer_Owned_Unit__c tradeInUnitRec = tradeInUnitIdToRecMap.get(transferToUnitIdToTradeInUnitIdMap.get(unitRec.Id));
                            unitToInsert.put('Plate__c', tradeInUnitRec.Plate__c);
                            unitToInsert.put('Reg_Expiry_Date__c', tradeInUnitRec.Reg_Expiry_Date__c);
                        }
                    } 
                    else if(unitRec.Unit_Type__c != null && unitRec.Unit_Type__c.equalsIgnoreCase(Constants.UNIT_TYPE_COU)) {
                        unitRec.Status__c = 'Transferred';
                        
                        unitToInsert.put('Id',null);
                        unitToInsert.put('Unit_Type__c', Constants.UNIT_TYPE_STOCK);
                        unitToInsert.put('Status__c','Available');
                        unitToInsert.put('New_Unit__c',false);
                        unitToInsert.put('Account__c', null);
                        unitToInsert.put('Plate__c', null);
                        unitToInsert.put('Reg_Expiry_Date__c', null);
                        
                        unitToInsert.put('Taxable__c',true);
                        unitToInsert.put('Applicable_Tax__c', defaultUnitSalesTaxId);
                        
                        unitToInsert.put('Stock_Id__c',null);
                        unitToInsert.put('Unit_Id__c',null);
                        unitToInsert.put('Date_Stocked_In__c', date.newinstance(invoiceDate.year(), invoiceDate.month(), invoiceDate.day()));
                        unitToInsert.put('Category__c', couIdToDealItemRecMap.get(unitRec.Id).Category__c);
                        unitToInsert.put('Mileage_Value__c', couIdToDealItemRecMap.get(unitRec.Id).Mileage__c);
                        unitToInsert.put('Mileage_Type__c', couIdToDealItemRecMap.get(unitRec.Id).Mileage_Type__c);
                        unitToInsert.put('How_Acquired__c', 'Trade-in');
                        unitToInsert.put('Reference_Number__c', dealList[0].CO_Header__r.Name);
                        unitToInsert.put('Acquired_From__c', dealList[0].CO_Header__r.Customer__c);
                        
                        if(GeneralConfiguration.getAccrueTradeTaxUntilUnitSold()) {
                            DealService.populateTradeInAndSalesTaxOnSku(couIdToDealItemRecMap.get(unitRec.Id), unitToInsert);
                        }
                    }
                    couIdToRelatedCOUMap.put(unitRec.Id, (Customer_Owned_Unit__c)unitToInsert);
                }
				
				if(!Test.isRunningTest()) {
					createDUPCFromUPCForSKU_future(skuIdToDealItemIdMap);
				}
                if(couIdToRelatedCOUMap.values().size() > 0) {
                    if(AccessControl.ifObjectFieldIsCreateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                    insert couIdToRelatedCOUMap.values();
                    Map<Id, Id> unitIdToRelatedCOUIdMap = new Map<Id, Id>();
                    for(Id couId : couIdToRelatedCOUMap.keySet()) {
                        if(couIdToRelatedCOUMap.get(couId) != null) {
                            unitIdToRelatedCOUIdMap.put(couId, couIdToRelatedCOUMap.get(couId).Id);
                        }
                    }
                    if(!System.isFuture()) Unit_Service.copyUnitImages(unitIdToRelatedCOUIdMap);
                }
                
                if(unitListToUpdateStatus.size() > 0) {
                    DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitListToUpdateStatus);
                }
                
                List<Deal_Item__c> tradeInUpdateList = new List<Deal_Item__c>();
                List<Customer_Owned_Unit__c> stockedUnitListToUpdate = new List<Customer_Owned_Unit__c>();
                for(String unitId : couIdToDealItemRecMap.keySet()) {
                    Deal_Item__c tradeInRec = couIdToDealItemRecMap.get(unitId);
                    if(isTradeOnlyDeal) {
                        Decimal agreedValue = tradeInRec.Agreed_value__c != null ? tradeInRec.Agreed_value__c.setScale(2, RoundingMode.HALF_UP) : 0;
                        Decimal taxRate = tradeInRec.Default_Unit_Sales_Tax_Percentage__c != null ? tradeInRec.Default_Unit_Sales_Tax_Percentage__c : 0;
                        Decimal newValue = (isTaxIncludingPricing ? (agreedValue / (1 + (taxRate / 100))) : agreedValue).setScale(2, RoundingMode.HALF_UP);
                        if(tradeInRec.Actual_Cash_Value__c != newValue) {
                            tradeInRec.Actual_Cash_Value__c = newValue;
                            tradeInUpdateList.add(tradeInRec);
                        }
                    }

                    Customer_Owned_Unit__c unitRec = couIdToRelatedCOUMap.get(unitId);
                    Unit_Price_Cost__c untPriceCostRec = new Unit_Price_Cost__c(Customer_Owned_Unit__c = unitRec.Id);
                    untPriceCostRec.Type__c = 'Base';
                    untPriceCostRec.Item_Description__c = Constants.CUSTOMER_TRADE_IN;
                    // added by subhrant 
                    untPriceCostRec.CO_Invoice_Header__c = coInvoiceNumber;
                    untPriceCostRec.Ref_No__c = coInvoiceNumber;
                    untPriceCostRec.Total_Price__c = tradeInRec.Agreed_Value__c;
                    untPriceCostRec.Total_Cost__c = tradeInRec.Actual_Cash_Value__c;
                    stockedUnitListToUpdate.add(new Customer_Owned_Unit__c(Id = unitRec.Id, Acquisition_Cost__c = tradeInRec.Actual_Cash_Value__c));
                    unitPriceAndCostList.add(untPriceCostRec);
                    
                    dealItemIdToStockedInUnitIdMap.put(couIdToDealItemRecMap.get(unitId).Id, couIdToRelatedCOUMap.get(unitId).Id);
                }
                DealItemTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('Deal_Item__c', tradeInUpdateList);
                DealItemTriggerHelper.isForceStopTrigger = false;

                CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('Customer_Owned_Unit__c', stockedUnitListToUpdate);
                CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
                
                if(unitPriceAndCostList.size() > 0) {
                    DMLUtility.insertSobjectList('Unit_Price_Cost__c', unitPriceAndCostList);
                }
                
                List<Deal_Item__c> dealItemToUpdateList = new List<Deal_Item__c>();
                for(Id dealItemId: dealItemIdToStockedInUnitIdMap.keySet()) {
                    dealItemToUpdateList.add(new Deal_Item__c(Id = dealItemId, Stocked_In_Unit__c = dealItemIdToStockedInUnitIdMap.get(dealItemId)));
                }
                
                if(dealItemToUpdateList.size() > 0) {
                    DMLUtility.updateSobjectList('Deal_Item__c', dealItemToUpdateList);
                }
                
                dealList[0].Status__c = Constants.DEAL_STATUS_INVOICED;
                dealList[0].Invoice_Number__c = coInvoiceNumber;
                DMLUtility.updateSobjectList('Deal__c', dealList);

                if(!dealList[0].Deal_Finances__r.isEmpty()) {
                    Deal_Finance__c dealFinanceRec = dealList[0].Deal_Finances__r[0];
                    dealFinanceRec.DF_Commission_in_FI_company_payments__c = (GeneralConfiguration.getConfigurations().DF_commission_in_FI_company_payments__c && !dealList[0].Deal_Finances__r[0].Finance_Company__r.Commissions_not_in_finance_payments__c);
                    DMLUtility.updateSobjectList('Deal_Finance__c', dealFinanceRec);
                }
            }
            if(!System.isFuture()) calculateDealOptionClearingAndStockTrade(dealId);
        }
    }

    public static String removeFAndIProductLineItem(String dealId, String fAndIProductId) {
        dealId = BPUtility.getDecodedString(dealId);
        fAndIProductId = BPUtility.getDecodedString(fAndIProductId);
        if(AccessControl.ifObjectFieldIsAccessible('F_I_Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<F_I_Product__c> fAndIproductRecordToDelete = [select Id from F_I_Product__c where Id =: fAndIProductId];
        
        if(fAndIproductRecordToDelete.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('F_I_Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete fAndIproductRecordToDelete[0];
        }
        return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealFinanceSection'));
    }
    
    public static String saveDealFAndIProduct(String dealId, String dealFAndIProductJSON) {
        dealId = BPUtility.getDecodedString(dealId);
        dealFAndIProductJSON = BPUtility.getDecodedString(dealFAndIProductJSON);
        DealWrapper.FIProductWrapper dealFAndIProductObj = (DealWrapper.FIProductWrapper) System.JSON.deserialize(dealFAndIProductJSON, DealWrapper.FIProductWrapper.class);
         
        if(String.isBlank(dealFAndIProductObj.Id)) {
            if(AccessControl.ifObjectFieldIsAccessible('Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Product__c> productList = [Select Price__c, Code__c, Description__c from Product__c where Id = :dealFAndIProductObj.ProductId];
            if(productList.size() > 0) {
                dealFAndIProductObj.Price = productList[0].Price__c;
                dealFAndIProductObj.ItemDescription =  productList[0].Code__c + ' - ' + productList[0].Description__c;
            }
        }
        
        F_I_Product__c dealFAndIProductRec = setDealFAndIProductField(dealFAndIProductObj);
        if(dealFAndIProductRec.Id == null) {
            COFormService.insertDefaultCOForms(null, dealFAndIProductRec.Deal_Finance__c, dealFAndIProductRec.Vendor_Product__c);
        }
        DMLUtility.upsertSobjectList('F_I_Product__c', dealFAndIProductRec);
        return BPUtility.getEncodedString(getFAndIProductDetails(dealFAndIProductRec.Id));
    }
        
    private static String getFAndIProductDetails(String fAndIProductId) {
        List<F_I_Product__c> dealFAndIProductList = SOQLUtil.getDealFAndIProductRecord(new Map<String, String>{'Id' => fAndIProductId});
        if(dealFAndIProductList.size() == 0) {
            return '{}';
        }       
        DealWrapper.FIProductWrapper dealFAndISectionObj = new DealWrapper.FIProductWrapper(dealFAndIProductList[0]);
        return System.JSON.serialize(dealFAndISectionObj);
    }
    
    private static F_I_Product__c setDealFAndIProductField(DealWrapper.FIProductWrapper dealFAndIProductObj) {
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        dealFAndIProductObj.SalesTaxPercentage = (dealFAndIProductObj.SalesTaxPercentage == null) ? 0 : dealFAndIProductObj.SalesTaxPercentage;
        dealFAndIProductObj.Price = (dealFAndIProductObj.Price == null) ? 0 : dealFAndIProductObj.Price;
        
        F_I_Product__c dealFAndIProductRec = new F_I_Product__c();
        if(isTaxIncludingPricing) {
            dealFAndIProductRec.Price_When_Tax_Included__c = dealFAndIProductObj.Price;
            dealFAndIProductObj.Price = (dealFAndIProductObj.Price / (1 + (dealFAndIProductObj.SalesTaxPercentage / 100))).setScale(2, RoundingMode.HALF_UP);
            dealFAndIProductObj.SalesTax = (dealFAndIProductObj.Price * dealFAndIProductObj.SalesTaxPercentage / 100);
        } 
        
        dealFAndIProductRec.Id = dealFAndIProductObj.Id;
        dealFAndIProductRec.Price__c = dealFAndIProductObj.Price;
        dealFAndIProductRec.Sales_Tax__c = dealFAndIProductObj.SalesTax;
        dealFAndIProductRec.Vendor_Product__c = dealFAndIProductObj.ProductId;
        dealFAndIProductRec.Item_Description__c = dealFAndIProductObj.ItemDescription;
        dealFAndIProductRec.Deal_Finance__c = dealFAndIProductObj.DealFinanceId;
        dealFAndIProductRec.Deal__c = dealFAndIProductObj.DealId;
        dealFAndIProductRec.UUID__c = dealFAndIProductObj.UUID;
        dealFAndIProductRec.Cost__c = dealFAndIProductObj.Cost;
        
        return dealFAndIProductRec;
    }

    public static String recalculationOfDealKHLineItems(String dealKHJSON, String dealKHLineItemJSON) {
        dealKHJSON = BPUtility.getDecodedString(dealKHJSON);
        dealKHLineItemJSON = BPUtility.getDecodedString(dealKHLineItemJSON);
        
        DealWrapper.DealKitHeader dealKHObj = (DealWrapper.DealKitHeader) System.JSON.deserialize(dealKHJSON, DealWrapper.DealKitHeader.class);
        String resultStr;
        
        if(dealKHLineItemJSON != 'null') {
            DealWrapper.OptionAndFeeInfo dealKHLineItemObj = (DealWrapper.OptionAndFeeInfo) System.JSON.deserialize(dealKHLineItemJSON, DealWrapper.OptionAndFeeInfo.class);            
            if(String.isNotBlank(dealKHLineItemObj.FeeId) || String.isNotBlank(dealKHLineItemObj.LabourId)) {
                if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Option_Fee__c> optionFeeList = [select Item_Description__c from Option_Fee__c where Id =: dealKHLineItemObj.Id];
                if(optionFeeList.size() > 0 && optionFeeList[0].Item_Description__c != dealKHLineItemObj.ItemDescription) {
                    Option_Fee__c optionFeeToUpdate = new Option_Fee__c(Id = dealKHLineItemObj.Id);
                    optionFeeToUpdate.Item_Description__c = dealKHLineItemObj.ItemDescription;
                    DMLUtility.updateSobjectList('Option_Fee__c', optionFeeToUpdate);
                }
            }
            
            if(!dealKHLineItemObj.IsFixedPrice) {
                resultStr = DealKH_Recalculation.updateDealKitLineItem(dealKHObj, dealKHLineItemObj);
            } 
        } else if(!dealKHObj.IsFixedPrice){
            resultStr = DealKH_Recalculation.updateDealKitHeader(dealKHObj);  
        } else {
            if(AccessControl.ifObjectFieldIsAccessible('Deal_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Deal_Kit_Header__c> dealKHList = [Select Is_Install__c, Deal_Item__r.Option_And_Fee_Status__c, Deal_Item__r.Deal__r.Status__c, (SELECT Status__c FROM Options_Fees__r LIMIT 1), (SELECT Id FROM CO_Kit_Headers__r LIMIT 1), (SELECT Id FROM Service_Order_Kit_Headers__r LIMIT 1) from Deal_Kit_Header__c where Id =: dealKHObj.Id];
            if(dealKHList.size() > 0) {
                if(dealKHList[0].Is_Install__c != dealKHObj.IsInstall) {
                    dealKHList[0].Is_Install__c = dealKHObj.IsInstall;
                    DMLUtility.updateSobjectList('Deal_Kit_Header__c', dealKHList);
                    if((dealKHList[0].Deal_Item__r.Deal__r.Status__c == Constants.IN_PROGRESS || dealKHList[0].Deal_Item__r.Deal__r.Status__c == 'Approved') && (dealKHList[0].CO_Kit_Headers__r.size() > 0 || dealKHList[0].Service_Order_Kit_Headers__r.size() > 0 || (dealKHList[0].Options_Fees__r.size() > 0 && dealKHList[0].Options_Fees__r[0].Status__c == Constants.COMMITTED))) {
                        CustomerOrderCtrl.moveDealMerchAndServiceLineItems(BPUtility.getEncodedString(dealKHObj.Id), BPUtility.getEncodedString(dealKHObj.CoHeaderId));
                    }
                    resultStr = 'Success';
                }
            }
        }
        if(String.isNotBlank(resultStr) && resultStr == 'Success') {
            COService.error = new SO_KLI_Recalculation.Errorhandler('200', 'Saved Successfully');
        } else if(String.isNotBlank(resultStr)){
            COService.error = new SO_KLI_Recalculation.Errorhandler('300', resultStr);
        }        
         return getDealItemDetails(dealKHObj.DealItemId);
    }

    public static String insertOptionAndFeeLineItems(String partId, String coHeaderId, String dealId, String dealItemId, String jSONString, Boolean isSuppress, Boolean isDuplicateCheck) {
        partId = BPUtility.getDecodedString(partId);    
        String resultStr = '{}';
        if(isSuppress || String.isBlank(partId)) {
            if(isSuppress) {
                COservice.insertSuppressLineItem(BPUtility.getDecodedString(coHeaderId), partId);
            }
            resultStr = saveOptionFeesLineItem(dealId, dealItemId, jSONString);
        } else if(String.isNotBlank(partId)) {
            coHeaderId = BPUtility.getDecodedString(coHeaderId);
            if(isDuplicateCheck && !COservice.isSuppressLineItemOnCO(coHeaderId, partId) && COservice.isDuplicatePartOnCO(coHeaderId, partId)) {
                resultStr = BPUtility.getEncodedString('{"DuplicatePart" : true}');
            } else { 
                resultStr = saveOptionFeesLineItem(dealId, dealItemId, jSONString);
            }
        }
        return resultStr;
    }

    public static String removeDeal(String dealId) {
        dealId = BPUtility.getDecodedString(dealId);    
        String coHeaderId;
        String coHeaderStatus = '';
        
        List<SObject> sObjectListToDelete = new List<SObject>{new Deal__c(Id = dealId)};
        if(String.isNotBlank(dealId)) {
            List<Deal__c> dealList = [Select Id, CO_Header__c, (Select Id from Deal_Items__r), (Select Id from Options_Fees__r), (Select Id from CO_Invoice_Items__r) From Deal__c where Id =: dealId];
            if(dealList.size() > 0) {
                coHeaderId = dealList[0].CO_Header__c;
                if(dealList[0].Options_Fees__r.size() > 0) {
                    return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'First remove option and fee to remove deal')));
                }
                
                if(dealList[0].Deal_Items__r.size() > 0) {
                    List<Deal_Item__c> dealItemList = [Select Type__c, Customer_Owned_Unit__c From Deal_Item__c where Id In: dealList[0].Deal_Items__r];
                    for(Deal_Item__c dealItemRec : dealItemList) {
                        if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'First remove trade-In to remove deal')));
                        } else if(dealItemRec.Customer_Owned_Unit__c != null) {
                            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'First remove unit to remove deal')));
                        }else {
                            sObjectListToDelete.add(dealItemRec);
                        }
                    }
                }
				
				if(dealList[0].CO_Invoice_Items__r.size() > 0) {
                	sObjectListToDelete.add(dealList[0].CO_Invoice_Items__r);
                }
                COService.removeAllCOSalespersonBySectionId(dealList[0].Id);
                if(AccessControl.ifObjectIsDeletable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                delete sObjectListToDelete;
                coHeaderStatus = COService.validateAndCloseCO(coHeaderId);
            }
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('success', coHeaderStatus)));
    }

    /**
    * Name: getDealFinanceMasterData
    * Desc: Method to get json string related to Service Header Order
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    * @return: String - JSON String of SO Header Detail Record
    **/
    public static String getDealFinanceMasterData() {
        try{
            List<Account> financeCompanyList = SOQLUtil.getFinanceCompanyList();
            List<SOHeaderWrapper.VendorAsProvider> financeCompanyObjList = new List<SOHeaderWrapper.VendorAsProvider>();
            for(Account financeCompanyRec : financeCompanyList) {
                financeCompanyObjList.add(new SOHeaderWrapper.VendorAsProvider(financeCompanyRec));
            }
            return BPUtility.getEncodedString(System.JSON.serialize(financeCompanyObjList));  
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    /**
     * Name: UpdateOptionFeeStatus
     * Desc: set Status of deal and dealitems
     * @param:  
     *          (2) coHeaderId -String - id of coHeader
     * @return:  String - JSON String of CO Invoice History List
    **/
    public static String UpdateOptionFeeStatus(String coHeaderId) {
        List<CO_Invoice_Item__c> DealInvoiceListToUpdate = new List<CO_Invoice_Item__c>();
        Boolean isDealFullFilled = updateOptionFeeStatusAndDealStatus(coHeaderId);
        if(isDealFullFilled){
            List<CO_Invoice_Item__c> DealInvoiceItemList = new List<CO_Invoice_Item__c>([select Id, Deal__r.Status__c, isActive__c,Is_Invoiceable__c from CO_Invoice_Item__c where 
                                                            Deal__c  = : dealIdToDealMap.KeySet() AND Deal_Finance__c = null]);
            for(CO_Invoice_Item__c InvoiceItem : DealInvoiceItemList) {
                if(GeneralConfiguration.isLoadNewCustomerOrder()) {
                    if(String.isNotBlank(InvoiceItem.Deal__r.Status__c) && InvoiceItem.Deal__r.Status__c == 'Approved') {
                        InvoiceItem.isActive__c = true;
                        InvoiceItem.Is_Invoiceable__c = true;
                        DealInvoiceListToUpdate.add(InvoiceItem);
                    }
                } else {
                    InvoiceItem.isActive__c = true;
                    InvoiceItem.Is_Invoiceable__c = true;
                    DealInvoiceListToUpdate.add(InvoiceItem);
                }
            }                                                           
        } else {
            if(dealIdToDealMap.size() > 0) {
                String dealId;
                for(String dealRecordId : dealIdToDealMap.keyset()) {
                    dealId = dealRecordId;
                }
                List<CO_Invoice_Item__c> dealInvoiceItemList = [SELECT Deal__r.Status__c, isActive__c, Is_Invoiceable__c FROM CO_Invoice_Item__c 
                                                            WHERE Deal__c =: dealId AND Deal_Finance__c = null];
	            Map<String, Boolean> optionNameToOptionValueMap = isDealInvoiceable(dealId);
	            dealInvoiceItemList[0].Is_Invoiceable__c = optionNameToOptionValueMap.get('Invoiceable');
	            dealInvoiceItemList[0].isActive__c = optionNameToOptionValueMap.get('Active');
	            dealInvoiceListToUpdate.add(dealInvoiceItemList[0]);
            }
        }
        
        if(DealInvoiceListToUpdate.size() > 0 ){
            DMLUtility.updateSobjectList('CO_Invoice_Item__c', DealInvoiceListToUpdate);
        } 
        return 'success';
    }

    private static Map<Id, Deal__c> dealIdToDealMap; 
     
    public static Boolean updateOptionFeeStatusAndDealStatus(String coHeaderId) {
        if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Finance__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }   
        
        dealIdToDealMap = new Map<Id,Deal__c>([select Id, Status__c, Is_Deal_Fulfilled__c, Is_Commit_And_Install_Action_Initiated__c, 
        				(Select Id, Option_And_Fee_Status__c from Deal_Items__r where Option_And_Fee_Status__c !=: Constants.UNCOMIITTED), 
	    				(Select Id from CO_Line_Items__r Limit 1), (Select Id from Service_Order_Headers__r Limit 1),
	    				(Select Id, Deal_Item__c from Deal_Unresolved_Fulfillments__r where Is_Resolved__c = false) 
	    				From Deal__c where  CO_Header__c =: coHeaderId]);
    
        List<Deal_Item__c> DealItemList = [select Id, Deal__c, Option_And_Fee_Status__c, Type__c, (select Id, Status__c, Part__c, Labour_Code__c, Product__c, Product__r.Type__c 
            from Options_Fees__r where Labour_Code__c != null OR Part__c != null OR (Product__c != null AND Product__r.Type__c = 'Sublet')) From Deal_Item__c where  Deal__c =: dealIdToDealMap.KeySet()];
    
        Map<String, Deal_Item__c> dealItemIdToRecMapToUpdate = new Map<String, Deal_Item__c>();
        List<Deal__c> DealListToUpdate = new List<Deal__c>(); 
            
        for(Deal_Item__c dealItemRec : DealItemList ){
            boolean isFullFilled = true;
            if(dealItemRec.Type__c != 'Trade In') {
            	for(Option_Fee__c  optionFeeRec  : dealItemRec.Options_Fees__r){
	                if(optionFeeRec.Status__c != 'Fulfilled'){
	                    isFullFilled = false;
	                    break;
	                }
	            }
            }
            
            if(isFullFilled && dealIdToDealMap.get(dealItemRec.Deal__c).Deal_Unresolved_Fulfillments__r.size() == 0) {
                dealItemRec.Option_And_Fee_Status__c= 'Fulfilled';
                dealItemIdToRecMapToUpdate.put(dealItemRec.Id, dealItemRec);
            } else if(dealItemRec.Option_And_Fee_Status__c == 'Fulfilled') {
                dealItemRec.Option_And_Fee_Status__c = 'Committed';
                dealItemIdToRecMapToUpdate.put(dealItemRec.Id, dealItemRec);
            }
        }
            
        Boolean isDealFullFilled = false;
        for(Deal_Item__c DealItemRec: DealItemList){
            if(DealItemRec.Option_And_Fee_Status__c !='Fulfilled'){
                isDealFullFilled = false;
                break;
            }else{
                isDealFullFilled =true;
            }
        }
            
        if(isDealFullFilled && !GeneralConfiguration.isLoadNewCustomerOrder()) {
        	Map<Id, Deal__c> dealIdToFinanceStatus = new Map<Id,Deal__c>([Select Id, Type__c, (Select Status__c from Deal_Finances__r) from Deal__c where Id In :dealIdToDealMap.keySet()]);
            for( Deal__c dealRec : dealIdToDealMap.values() ){
                if(dealIdToFinanceStatus.containsKey(dealRec.Id) && dealIdToFinanceStatus.get(dealRec.Id).Type__c == 'Financed' && dealIdToFinanceStatus.get(dealRec.Id).Deal_Finances__r.size() > 0 && dealIdToFinanceStatus.get(dealRec.Id).Deal_Finances__r[0].Status__c != 'Paid') {        //If condition added by nidhi -09/12-2016
                isDealFullFilled = false;
                }
            }
        }
            
	    for( Deal__c dealRec : dealIdToDealMap.values() ){
	    	Boolean isUpdateDeal = false;
	    	if(dealRec.Deal_Unresolved_Fulfillments__r.size() > 0) {
	    		isDealFullFilled = false;
	    	} else if(dealRec.CO_Line_Items__r.size() == 0 && dealRec.Service_Order_Headers__r.size() == 0) {
	            isDealFullFilled = false;
	        	for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
	        		Deal_Item__c dealItemRecToUpdate = new Deal_Item__c(Id = dealItemRec.Id);
	        		if(dealItemIdToRecMapToUpdate.containsKey(dealItemRec.Id)) {
	        			dealItemRecToUpdate = dealItemIdToRecMapToUpdate.get(dealItemRec.Id);
	        		}
	        		dealItemRecToUpdate.Option_And_Fee_Status__c = Constants.UNCOMIITTED;
	        		dealItemIdToRecMapToUpdate.put(dealItemRecToUpdate.Id, dealItemRecToUpdate);
				}
				if(dealRec.Is_Commit_And_Install_Action_Initiated__c) {
        			isUpdateDeal = true;
        			dealRec.Is_Commit_And_Install_Action_Initiated__c = false;
        		}
    		}
		    
	        if(GeneralConfiguration.isLoadNewCustomerOrder()) {
	            if(isDealFullFilled) {
	                dealRec.Is_Deal_Fulfilled__c = true;
	                DealListToUpdate.add(dealRec);
	            } else if(dealRec.Is_Deal_Fulfilled__c) {
	                dealRec.Is_Deal_Fulfilled__c = false;
	                DealListToUpdate.add(dealRec);
	            } else if(isUpdateDeal) {	//To avoid duplicate Id in list
	            	DealListToUpdate.add(dealRec);
	            }
	        } else {
	            if(isDealFullFilled) {
	                dealRec.status__c = 'Fulfilled';
	                DealListToUpdate.add(dealRec);
	            } else if(dealRec.status__c == 'Fulfilled') {
	                dealRec.status__c = 'In Progress';
	                DealListToUpdate.add(dealRec);
	            }
	        }
        }
        
        if(dealItemIdToRecMapToUpdate.Size() > 0 ){
            DealItemTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Deal_Item__c', dealItemIdToRecMapToUpdate.values());
            DealItemTriggerHelper.isForceStopTrigger = false;
        }
        
        if(DealListToUpdate.size() > 0){
           	 DealTriggerHelper.isForceStopTrigger = true;
             DMLUtility.updateSobjectList('Deal__c', DealListToUpdate);
             DealTriggerHelper.isForceStopTrigger = true;
        }
        
        return isDealFullFilled;
    }

    public static String insertDealKHByCOKH(String kitHeaderId, String dealItemId, String dealId, String chargeMethod, Boolean isInstall, String fullfilmentRecId) {
        if(dealItemId == null) {
            return null;
        }
        if(AccessControl.ifObjectFieldIsAccessible('Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Kit_Header__c> kitHeaderList = SOQLUtil.getKitHeaderRec(new Map<String, String>{ 'Id' => kitHeaderId });
        String status = Constants.COMMITTED;
        List<SObject> sObjectListToUpdate = new List<SObject>();
        if(isInstall) {
            List<Service_Order_Kit_Header__c> sokitHeaderList = [Select Id, Service_Order_Header__r.SO_Status__c, (Select Id, Kit_Price__c, Price_When_Tax_Included__c, Kit_Header_Line_Item__c from Service_Order_Line_Items__r) from Service_Order_Kit_Header__c where Id =: fullfilmentRecId];
            if(sokitHeaderList.size() > 0) {
                status = ((sokitHeaderList[0].Service_Order_Header__r.SO_Status__c != null) && (sokitHeaderList[0].Service_Order_Header__r.SO_Status__c == ServiceJobUtil.INVOICED)) ?
                                                 Constants.FULFILLED : null;
                sObjectListToUpdate.addAll((List<SObject>)sokitHeaderList[0].Service_Order_Line_Items__r);
            }
        } else {
            List<CO_Kit_Header__c> cokitHeaderList = [Select Id,(Select Id, Closed_CO_Invoice_link__c, Price__c, Price_When_Tax_Included__c, Kit_Header_Line_Item__c from CO_Line_Items__r) from CO_Kit_Header__c where Id =: fullfilmentRecId];
            if(cokitHeaderList.size() > 0 && cokitHeaderList[0].CO_Line_Items__r.size() > 0) {
                status = (cokitHeaderList[0].CO_Line_Items__r[0].Closed_CO_Invoice_link__c != null) ? Constants.FULFILLED : null;
                sObjectListToUpdate.addAll((List<SObject>)cokitHeaderList[0].CO_Line_Items__r);
            }
        }
        
        if(kitHeaderList.size() == 0) {
            return null;
        }
        
        Deal_Kit_Header__c dkhRec = setDealKitHeaderFields(kitHeaderList[0]);
        dkhRec.Deal_Item__c = dealItemId;
        if(chargeMethod == Constants.CHARGE_METHOD_DO_NOT_INVOICE) {
            dkhRec.Fixed_Price__c = 0;
            dkhRec.Actual_Kit_Price__c = 0;
        }
        
        dkhRec.Is_Install__c = isInstall;
        DMLUtility.insertSobjectList('Deal_Kit_Header__c', dkhRec);
        
        List<Option_Fee__c> optionAndFeeList = insertAllKitLineItemsInDeal(kitHeaderId, dealItemId, dealId, dkhRec.Id, status, chargeMethod, sObjectListToUpdate);
        for(SObject sObjRec : sObjectListToUpdate) {
            for(Option_Fee__c oandFRec : optionAndFeeList) {
                if(oandFRec.Kit_Header_Line_Item__c == sObjRec.get('Kit_Header_Line_Item__c')) {
                    sObjRec.put('Option_Fee__c', oandFRec.Id);
                    if(!isInstall) {
                        sObjRec.put('Related_Option_And_Fees__c', oandFRec.Id);
                    }
                    break;
                }
            }
        }
        update sObjectListToUpdate;
        
        if(chargeMethod != Constants.CHARGE_METHOD_DO_NOT_INVOICE) {
            DealKH_Recalculation.calculatePriceForDealKitInsertion(dkhRec.Id, dealItemId);
        }
        
        return dkhRec.Id;
    }

    private static void updateVOLIANDCOLIOnPartMove(List<Vendor_Order_Line_Item__c> voliRecListToUpdate, List<CO_Line_Item__c> coliToUpsert, 
    															List<CO_Line_Item__c> coliToMovelist) {
    	for(Vendor_Order_Line_Item__c voliRec : voliRecListToUpdate) {
    		voliRec.CO_Line_Item__c = coliToUpsert[0].Id;
    	
        	if(coliToUpsert[0].Service_Order_Line_Item__c != null){
                voliRec.Is_Service__c = true;
                voliRec.Is_required_For_Customer__c = false;
            } else {
                voliRec.Is_required_For_Customer__c = true;
                voliRec.Is_Service__c = false;
            }
    	}
    	
    	coliToUpsert[0].Status__c = coliToMovelist[0].Status__c;
    	coliToUpsert[0].Vendor_Order_Header__c = coliToMovelist[0].Vendor_Order_Header__c;
    	coliToUpsert[0].VO_Number__c = coliToMovelist[0].VO_Number__c;
    	coliToUpsert[0].VO_Status__c =  coliToMovelist[0].VO_Status__c;
    	coliToUpsert[0].Expected_Delivery_Date__c = coliToMovelist[0].Expected_Delivery_Date__c;
    	coliToUpsert[0].Pulled__c = coliToMovelist[0].Pulled__c;
		
        DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voliRecListToUpdate);
        DMLUtility.upsertSobjectList('CO_Line_Item__c', coliToUpsert);
    }

    private static Option_Fee__c setOptionAndFeeRecord(String dealId, DealWrapper.OptionAndFeeInfo optionAndFeeInfoObjRec, Decimal price) {
        Option_Fee__c optionAndFeeInfoRecToUpsert = new Option_Fee__c();
        optionAndFeeInfoRecToUpsert.Deal__c = dealId;
        optionAndFeeInfoRecToUpsert.Deal_Item__c = optionAndFeeInfoObjRec.DealItemId;  
        optionAndFeeInfoRecToUpsert.Qty__c = (optionAndFeeInfoObjRec.Qty != null) ? optionAndFeeInfoObjRec.Qty : 1;
        optionAndFeeInfoRecToUpsert.Price__c = price;
        optionAndFeeInfoRecToUpsert.Part__c = (optionAndFeeInfoObjRec.PartId != '') ? optionAndFeeInfoObjRec.PartId : null;
        optionAndFeeInfoRecToUpsert.Fee__c = (optionAndFeeInfoObjRec.FeeId != '') ? optionAndFeeInfoObjRec.FeeId : null;
        optionAndFeeInfoRecToUpsert.Labour_Code__c = (optionAndFeeInfoObjRec.LabourId != '') ? optionAndFeeInfoObjRec.LabourId : null;
        optionAndFeeInfoRecToUpsert.Product__c = (optionAndFeeInfoObjRec.ProductId != '') ? optionAndFeeInfoObjRec.ProductId : null;
        optionAndFeeInfoRecToUpsert.Item_Code__c = optionAndFeeInfoObjRec.ItemCode;
        optionAndFeeInfoRecToUpsert.Item_Description__c = optionAndFeeInfoObjRec.ItemDescription;
        optionAndFeeInfoRecToUpsert.Price_When_Tax_Included__c = optionAndFeeInfoObjRec.Price;
        //optionAndFeeInfoRecToUpsert.Kit_Header__c = (optionAndFeeInfoObjRec.KitId != '') ? optionAndFeeInfoObjRec.KitId : null;
        if(String.isNotBlank(optionAndFeeInfoObjRec.LabourId)) {
            optionAndFeeInfoRecToUpsert.Is_Install__c = true;
        } else {
            optionAndFeeInfoRecToUpsert.Is_Install__c = optionAndFeeInfoObjRec.IsInstall;
        }
        if(String.isNotBlank(optionAndFeeInfoObjRec.Id)) {
            optionAndFeeInfoRecToUpsert.Id = optionAndFeeInfoObjRec.Id;
        }
        optionAndFeeInfoRecToUpsert.UUID__c = optionAndFeeInfoObjRec.UUID;
        return optionAndFeeInfoRecToUpsert;
    }

    private static Option_Fee__c createEnvFeeLineItemInDealSection(String partId, String dealId, String dealItemId, String UUID) {
        Option_Fee__c envFeeLineItemRec = new Option_Fee__c();
        List<Part__c> partList = [select Part_Number__c, Enviro_Fee__c, Enviro_Fee_Code__c, Enviro_Fee_Code__r.Code__c, 
                                            Enviro_Fee_Code__r.Description__c from Part__c where Id =: partId];
        if(partList.size() > 0 && partList[0].Enviro_Fee__c != null && partList[0].Enviro_Fee_Code__c != null) {
            envFeeLineItemRec.Fee__c = partList[0].Enviro_Fee_Code__c;
            envFeeLineItemRec.Deal__c = dealId;
            envFeeLineItemRec.Deal_Item__c = dealItemId;  
            envFeeLineItemRec.Price__c = partList[0].Enviro_Fee__c;
            envFeeLineItemRec.Qty__c = 1;
            envFeeLineItemRec.Price_When_Tax_Included__c = envFeeLineItemRec.Price__c;
            envFeeLineItemRec.Item_Code__c = partList[0].Enviro_Fee_Code__r.Code__c;
            envFeeLineItemRec.Item_Description__c = partList[0].Part_Number__c + ' ' + partList[0].Enviro_Fee_Code__r.Description__c;
            envFeeLineItemRec.Price__c = partList[0].Enviro_Fee__c;
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                envFeeLineItemRec.Price_When_Tax_Included__c = partList[0].Enviro_Fee__c;
            }
            envFeeLineItemRec.Is_Environmental_Fee__c = true;
            envFeeLineItemRec.UUID__c = UUID;
        }
        return envFeeLineItemRec;
    }

    private static Deal__c getDealWithUpdatedStatus(String dealId, List<Deal_Item__c> dealItemList) {
        String dealStatus = (dealItemList.size() == 0) ? 'Quotation' : dealItemList[0].Deal__r.Status__c;
        String status = (dealItemList.size() == 0 || dealItemList[0].Deal__r.Status__c == 'Quotation') ? Constants.TEMPORARY : Constants.COMMITTED;
        List<Customer_Owned_Unit__c> unitUpdateList = new List<Customer_Owned_Unit__c>();
        if(dealItemList.size() > 0) {
        	Boolean isTempUnitExist = false;
	        for(Deal_Item__c dealItemRec : dealItemList) {
        		if(String.isBlank(dealItemRec.Customer_Owned_Unit__c)) {
	        		isTempUnitExist = true;
	        	} else { // Fixed issue related to add unit to deal mentioned under ticket #13499
                    if(dealItemRec.Customer_Owned_Unit__r.Status__c == 'Reserved' && dealItemRec.Customer_Owned_Unit__r.Unit_Type__c == 'STOCK') {
                        unitUpdateList.add(new Customer_Owned_Unit__c (Id = dealItemRec.Customer_Owned_Unit__c, Status__c = 'Available'));
                    } else if(dealItemRec.Customer_Owned_Unit__r.Status__c == 'Reserved' && dealItemRec.Customer_Owned_Unit__r.Unit_Type__c == 'COU') {
                        unitUpdateList.add(new Customer_Owned_Unit__c (Id = dealItemRec.Customer_Owned_Unit__c, Status__c = 'Active'));
                    } else if(dealStatus != 'Quotation' && dealItemRec.Customer_Owned_Unit__r.Unit_Type__c == 'ORDU' && dealItemRec.Customer_Owned_Unit__r.Deal_Item__c != null) {
                        unitUpdateList.add(new Customer_Owned_Unit__c (Id = dealItemRec.Customer_Owned_Unit__c, Deal_Item__c = null));
                    }
                }
	        }
	        
	        if(isTempUnitExist) {
	            dealStatus = 'Quotation';
                status = Constants.TEMPORARY;
                DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitUpdateList);
	        } else if(dealItemList[0].Deal__r.Status__c == 'Quotation') {
	        	status = Constants.UNCOMIITTED;
	        }
        }
        
        Deal__c dealRec = new Deal__c(Id = dealId, Status__c = dealStatus, Unit_Status__c = status);
        if(dealItemList.size() == 0) {
        	dealRec.Deal_Section_Trade_Only__c = true;
        } else {
        	dealRec.Deal_Section_Trade_Only__c = false;
        }
        return dealRec; 
    }

    /**
     * Name: setDealValues
     * Desc: Method which convert DealInfoWrapper obj value into Deal__c object rec
     * @param:  (1) dealObj - DealWrapper.DealInfoWrapper - Deal Info wrapper obj
     * @return: Deal__c - Deal object
    **/
    private static Deal__c setDealValues(DealWrapper.DealInfoWrapper dealObj) {
        Deal__c dealRec = new Deal__c();
        dealRec.Id = dealObj.Id;
        dealRec.Status__c = dealObj.DealStatus;
        dealRec.Type__c = dealObj.DealType;
        dealRec.Delivery_Date__c = String.isNotBlank(dealObj.DeliveryDate) ? DateTimeUtility.parseDate(dealObj.DeliveryDate) : null;
        dealRec.Down_Payment__c = dealObj.DownPayment;
        dealRec.Total__c = dealObj.Total;
        dealRec.CO_Header__c = dealObj.CoHeaderId;
        dealRec.Deal_Commission__c = dealObj.DealCommission;
        dealRec.Insurance_Provider__c = dealObj.InsuranceProvider;
        dealRec.Insurance_Policy__c = dealObj.InsurancePolicy;
        dealRec.Co_Buyer__c = String.isNotBlank(dealObj.CoBuyerId) ? dealObj.CoBuyerId : null;
        return dealRec;
    }

    public static void setOptionFeeInstallFlag(String dealId) {
        List<Option_Fee__c> serviceOptionFeeList = [SELECT Id FROM Option_Fee__c WHERE Deal__c =: dealId AND (Labour_Code__c != null OR Product__r.Type__c = 'Sublet' OR Deal_Kit_Header__r.Service_Kit__c = true)];
        if(serviceOptionFeeList.isEmpty()) {
            List<Option_Fee__c> optionFeeList = [SELECT Id, Is_Install__c FROM Option_Fee__c WHERE Deal__c =: dealId AND Is_Install__c = true];
            for(Option_Fee__c optionFeeRec : optionFeeList) {
                optionFeeRec.Is_Install__c = false;
            }
            OptionAndFeeTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Option_Fee__c', optionFeeList);
            OptionAndFeeTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    @future
    public static void calculateDealOptionClearingAndStockTrade(String dealId) {
        List<Deal__c> dealList = [SELECT Id, Invoice_Number__c, Option_Clearing__c, Stocked_Trades__c, Reopen_Invoice_Created_Date__c, (SELECT Id, Actual_Cash_Value__c FROM Deal_Items__r WHERE Is_Stocked_In__c = true) FROM Deal__c WHERE Id =: dealId];
        if(dealList.isEmpty()) return;

        if(dealList[0].Invoice_Number__c != null) {
            dealList[0].Stocked_Trades__c = 0;
            Decimal optionClearing = 0;
            List<CO_Line_Item__c> coliList = [SELECT Revenue__c FROM CO_Line_Item__c WHERE Deal__c =: dealId AND Service_Order_Line_Item__c = null AND Invoice_Number__c = null];
            for(CO_Line_Item__c coliRec : coliList) {
                optionClearing += coliRec.Revenue__c != null ? coliRec.Revenue__c.setScale(2, RoundingMode.HALF_UP) : 0;
            }

            List<Service_Order_Header__c> soList = [SELECT Total__c FROM Service_Order_Header__c WHERE Deal__c =: dealId AND Invoice_Number__c = null];
            for(Service_Order_Header__c soRec : soList) {
                optionClearing += soRec.Total__c != null ? soRec.Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
            }
            dealList[0].Option_Clearing__c = optionClearing;
        } else {
            Decimal optionClearing = 0;
            if(dealList[0].Reopen_Invoice_Created_Date__c != null) {
                List<CO_Line_Item__c> coliList = [SELECT Revenue__c, Actual_Invoice_Date_Time__c, Invoice_Number__c, Invoice_Number__r.Closed_Invoice_Date__c FROM CO_Line_Item__c WHERE Deal__c =: dealId AND Service_Order_Line_Item__c = null];
                for(CO_Line_Item__c coliRec : coliList) {
                    if(coliRec.Actual_Invoice_Date_Time__c != null) {
                        if(coliRec.Actual_Invoice_Date_Time__c > dealList[0].Reopen_Invoice_Created_Date__c) {
                            optionClearing -= coliRec.Revenue__c != null ? coliRec.Revenue__c.setScale(2, RoundingMode.HALF_UP) : 0;
                        }
                    } else if(coliRec.Invoice_Number__c != null) {
                        if(coliRec.Invoice_Number__r.Closed_Invoice_Date__c > dealList[0].Reopen_Invoice_Created_Date__c) {
                            optionClearing -= coliRec.Revenue__c != null ? coliRec.Revenue__c.setScale(2, RoundingMode.HALF_UP) : 0;
                        }
                    }
                }

                List<Service_Order_Header__c> soList = [SELECT Total__c, Actual_Invoice_Date_Time__c, Invoice_Number__c, Invoice_Number__r.Closed_Invoice_Date__c FROM Service_Order_Header__c WHERE Deal__c =: dealId];
                for(Service_Order_Header__c soRec : soList) {
                    if(soRec.Actual_Invoice_Date_Time__c != null) {
                        if(soRec.Actual_Invoice_Date_Time__c > dealList[0].Reopen_Invoice_Created_Date__c) {
                            optionClearing -= soRec.Total__c != null ? soRec.Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
                        }
                    } else if(soRec.Invoice_Number__c != null) {
                        if(soRec.Invoice_Number__r.Closed_Invoice_Date__c > dealList[0].Reopen_Invoice_Created_Date__c) {
                            optionClearing -= soRec.Total__c != null ? soRec.Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
                        }
                    }
                }

            }
            dealList[0].Option_Clearing__c = optionClearing;

            Decimal stockTrade = 0;
            for(Deal_Item__c dealItemRec : dealList[0].Deal_Items__r) {
                stockTrade += dealItemRec.Actual_Cash_Value__c.setScale(2, RoundingMode.HALF_UP);
            }
            dealList[0].Stocked_Trades__c = stockTrade;
        }
        DealTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal__c', dealList);
        DealTriggerHelper.isForceStopTrigger = false;
    }

    public static String getDealSalesTaxAmount(String dealId) {
        List<PrintCustomerOrderInvoiceCtrl.TaxDetail> taxDetails;
        if(!GeneralConfiguration.getTaxIncludingPricing()) {
            List<Individual_Tax__c> individualTaxList = [SELECT Deal__c, Taxable_Amount_for_Section_Header__c, CO_Line_Item__c, Tax_Rate__c, 
                                                            Form_Label__c, Sales_Tax_Item__r.Name__c, Tax_Amount__c, Tax_Amount_To_Invoice__c, 
                                                            Enhanced_Tax_Amount__c, Taxable_Amount__c, Taxable_Amount_To_Invoice__c, 
                                                            Sales_Tax_Item__r.Is_Automated__c, Sales_Tax_Item_Name__c,
                                                            Applicable_Tax__c, List_Tax_items_on_forms__c, SO_Payment_Role__c, Sales_Tax_Item__r.Forms_Label__c  
                                                            FROM Individual_Tax__c WHERE (Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c =: dealId 
                                                            OR F_I_Product__r.Deal_Finance__r.Deal__c =: dealId
                                                            OR Option_Fee__r.Deal_Item__r.Deal__c =: dealId
                                                            OR (Deal_Item__r.Deal__c =: dealId AND Deal_Item__r.Type__c = 'Trade In')
                                                            OR Deal__c =: dealId)];

            Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithIndividualFormLabel(individualTaxList, true);
            taxDetails = TaxEngine.setTaxDetails(salesTaxNameToTaxValue);
        }
        return System.JSON.serialize(taxDetails);
    }

    /* Methods moved from CustomerOrderCtrl */

    public static Decimal weekInYear = 52;
    public static Decimal biWeekInYear = 26;
    public static Decimal monthsInYear = 12;

    private static Map<String, Map<String, Decimal>> termTypeToPaymentFreqToValueMap = new Map<String, Map<String, Decimal>>{
        'Months' => new Map<String, Decimal>{
            'Monthly' => 1,
            'Semi-Monthly' => 2,
            'Weekly' => (weekInYear/monthsInYear),
            'Bi-Weekly' => (biWeekInYear/monthsInYear),
            'Annual' => 12,
            'Bi-annual' => 24
        },
        'Years' => new Map<String, Decimal>{
            'Monthly' => 12,
            'Semi-Monthly' => 24,
            'Weekly' => 52,
            'Bi-Weekly' => 26,
            'Annual' => 1,
            'Bi-annual' => 2
        }
    };

    private static Map<String, Decimal> paymentFreqToIntRateMap = new Map<String, Decimal>{
        'Monthly' => 12,
        'Semi-Monthly' => 24,
        'Weekly' => 52,
        'Bi-Weekly' => 26,
        'Annual' => 1,
        'Bi-annual' => 2
    };
}