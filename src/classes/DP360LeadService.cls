public without sharing class DP360LeadService {
    
    public static String getAllOpenLeads() {
        List<SearchLeadResultWrapper.LeadWrapper> openLeadList = DP360Service.getAllOpenLeads();
        if(openLeadList.size() == 0) {
            return System.JSON.serialize(new ResponseWrapper(400, 'No open leads found in the CRM'));
        }
        return createOpenLeadCallResponse(openLeadList);
    }
    
    public static void closeLeadInDP360(Integer leadId, String dealId) {
        UpdateLeadWrapper leadObj = new UpdateLeadWrapper(DP360Service.getDealerId(), leadId, 'Closed', true);
        String response = DP360Service.updateLead(system.JSON.serialize(leadObj), leadId);
        
        Deal__c dealRec = new Deal__c(Id = dealId);
        if(response != null) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
            dealRec.DP360_Sync_Response__c = (responseMap.get('message') != null ? String.valueOf(responseMap.get('message')) : null);
            dealRec.Available_For_DP360_Sync__c = false;
        } else {
            dealRec.DP360_Sync_Response__c = 'Deal cannot be closed in DP360';
        }
        DMLUtility.updateSobjectList('Deal__c', dealRec);
    }
    
    public static String createOpenLeadCallResponse(List<SearchLeadResultWrapper.LeadWrapper> openLeadList) {
        List<LeadInfoWrapper> leadInfoList = new List<LeadInfoWrapper>();
        for(SearchLeadResultWrapper.LeadWrapper leadDataObj : openLeadList) {
            LeadInfoWrapper leadInfo = new LeadInfoWrapper();
            leadInfo.LeadId = (leadDataObj.lead_id != null ? String.valueOf(leadDataObj.lead_id) : '');
            if(String.isBlank(leadDataObj.first_name) && String.isBlank(leadDataObj.last_name)) {
            	leadInfo.ContactName = leadDataObj.dealer_name;
            } else {
                leadInfo.ContactName = leadDataObj.first_name;
                leadInfo.ContactName += (String.isNotBlank(leadDataObj.m_name) ? ' ' + leadDataObj.m_name : '');
                leadInfo.ContactName += ' ' + leadDataObj.last_name;
            }
            
            List<String> stockNumberList = new List<String>();
            for(SearchLeadResultWrapper.LeadUnitsWrapper unitObj : leadDataObj.lead_units) {
                if(String.isNotBlank(unitObj.stock_num)) {
                    stockNumberList.add(unitObj.stock_num);
                }
            }
            leadInfo.Units = String.join(stockNumberList, ', ');
            leadInfo.FormattedLeadName = leadInfo.LeadId + ' - ' + leadInfo.ContactName;
            if(String.isNotBlank(leadInfo.Units)) {
                leadInfo.FormattedLeadName += ' - ' + leadInfo.Units;
            }
            leadInfoList.add(leadInfo);
        }
        return System.JSON.serialize(leadInfoList);
    }
    
    public static String getCustomerInfoByLeadId(String leadId) {
        SearchLeadResultWrapper.LeadWrapper leadObj = getLeadInfoByLeadId(leadId);
        return System.JSON.serialize(setLeadCustomerInfo(leadObj));
    }
    
    public static SearchLeadResultWrapper.LeadWrapper getLeadInfoByLeadId(String leadId) {
        List<SearchLeadResultWrapper.LeadWrapper> leadObjList = DP360Service.searchLead(new Map<String, String>{'lead_id' => leadId});
        if(leadObjList == null || leadObjList.size() == 0) {
            throw new BlackpurlException('No Lead found with selected lead info');
        }
        return leadObjList[0];
    }
    
    public static String createDealFromLead(String leadId, String customerId) {
        SearchLeadResultWrapper.LeadWrapper leadObj = getLeadInfoByLeadId(leadId);
        List<String> internalCommentList = new List<String>();

        // Create CO and deal section
        String coHeaderId = createCO(customerId);
        
        // Delete newly creted deal item and get Deal Id By CO Header Id
        String dealId = getDealIdByCoHeaderId(coHeaderId);
        
        // Primary lead comment
        internalCommentList.add(addPrimaryLeadComment(leadObj));

        // Get VIN Number of all units added in Lead
        Set<String> vinNumberSet = getUnitVINsFromLeadObj(leadObj);
        
        // Get matching sku and trade-in units
        List<Customer_Owned_Unit__c> couList = [SELECT Id, VIN_Number__c, Unit_Type__c, Applicable_Tax__c, Taxable__c, Status__c, Total_Price__c, 
                                                (SELECT Id, Item_Description__c, Type__c, Price__c, Total_Price__c, Qty__c FROM Unit_Prices_Costs__r)
                                                FROM Customer_Owned_Unit__c 
                                        WHERE ((Unit_Type__c = 'COU' AND Account__c =: customerId) 
                                        OR ((Unit_Type__c = 'STOCK' AND Status__c = 'Available') OR ( Unit_Type__c ='ORDU' AND Status__c = 'On Order')))
                                        AND VIN_Number__c IN: vinNumberSet];

        List<Customer_Owned_Unit__c> stockUnitList = new List<Customer_Owned_Unit__c>();
        List<Customer_Owned_Unit__c> tradeInUnitList = new List<Customer_Owned_Unit__c>();
        Set<String> stockVINSet = new Set<String>();
        Set<String> tradeInVINSet = new Set<String>();
        Map<String, Customer_Owned_Unit__c> vinToStockUnitRecMap = new Map<String, Customer_Owned_Unit__c>();

        for(Customer_Owned_Unit__c unitRec : couList) {
            if(unitRec.Unit_Type__c == 'COU') {
                tradeInUnitList.add(unitRec);
                tradeInVINSet.add(unitRec.VIN_Number__c.toLowerCase());
            } else {
                stockUnitList.add(unitRec);
                stockVINSet.add(unitRec.VIN_Number__c.toLowerCase());
                vinToStockUnitRecMap.put(unitRec.VIN_Number__c.toLowerCase(), unitRec);
            }
        }

        Map<String, Decimal> vinToAgreedValueMap = new Map<String, Decimal>();
        for(SearchLeadResultWrapper.LeadUnitsWrapper unit : leadObj.lead_units) {
            if(String.isNotBlank(unit.vin)){
                vinToAgreedValueMap.put(unit.vin.toLowerCase(), unit.sale_price);
            }
        }
        // Add trade-ins as units on deal
       	if(tradeInUnitList.size() > 0) {
            addTradeIns(dealId, customerId, tradeInUnitList, vinToAgreedValueMap);
        }
        
        //Add internal comment for unit not found
        addInternalCommentToCO(coHeaderId, addInternalComments(internalCommentList, leadObj, stockVINSet, tradeInVINSet));
        
        // Update Lead Id on Deal
        updateLeadIdOnDeal(dealId, leadId);
        
        Decimal dp360UnitSalePrice;
        List<LeadSalePriceWrapper> leadSalePriceWrapperList = new List<LeadSalePriceWrapper>();

        for(SearchLeadResultWrapper.LeadUnitsWrapper unit : leadObj.lead_units) {
            if(stockVINSet.contains(unit.vin.toLowerCase())) {
            	Customer_Owned_Unit__c stockUnit = vinToStockUnitRecMap.get(unit.vin.toLowerCase());
                dp360UnitSalePrice = ((unit.sale_price != null && unit.sale_price != 0) ? unit.sale_price : stockUnit.Total_Price__c).setScale(2, RoundingMode.HALF_UP);
                leadSalePriceWrapperList.add(new LeadSalePriceWrapper(dp360UnitSalePrice, stockUnit.Id, coHeaderId, dealId, null));
            }
        }
        
        return (leadSalePriceWrapperList.size() > 0 ? System.JSON.serialize(leadSalePriceWrapperList, true) : coHeaderId);
    }
        
    public static String updateDP360DealSalePrice(String updateUnitPriceJson) {
        String dealId;
        List<LeadSalePriceWrapper> leadSalePriceObjList = (List<LeadSalePriceWrapper>) System.JSON.deserialize(updateUnitPriceJson, List<LeadSalePriceWrapper>.class);        
        if(leadSalePriceObjList.size() > 0) {
            dealId = leadSalePriceObjList[0].DealId;
        }

        List<Deal_Item__c> dealItemList = [SELECT Id, Customer_Owned_Unit__c,
                                         (SELECT Id, Deal__c, Deal_Item__c, Unit_Price_Cost__r.Id, Price__c, Price_When_Tax_Included__c, Total_Price__c, Type__c, Sales_Tax_Percentage__c FROM Deal_Unit_Prices_Costs__r) 
                                         FROM Deal_Item__c WHERE Deal__c = :dealId AND Type__c = 'Unit'];
        
        Map<Id, Decimal> dealItemIdToSalesPriceMap = new Map<Id, Decimal>();
        // Balveer to fix
        for(Deal_Item__c dealItem : dealItemList) { // 10
            for(LeadSalePriceWrapper leadSalePriceObj: leadSalePriceObjList) { //10
                if(dealItem.Customer_Owned_Unit__c == leadSalePriceObj.UnitId) {
                    dealItemIdToSalesPriceMap.put(dealItem.Id, leadSalePriceObj.SalePrice);
                }
            }
        }

        List<Deal_Unit_Price_Cost__c> dealUPCToUpdateList = new List<Deal_Unit_Price_Cost__c>();
        List<Deal_Unit_Price_Cost__c> dealUPCToDeleteList = new List<Deal_Unit_Price_Cost__c>();
        List<Deal_Unit_Price_Cost__c> dealUPCToInsertList = new List<Deal_Unit_Price_Cost__c>();
        
        Decimal totalPrice = 0;
        String unitPriceCostId;
        Deal_Unit_Price_Cost__c baseDealUPCToDelete;
        for(Deal_Item__c dealItemRec : dealItemList) {
            totalPrice = 0;
            for(Deal_Unit_Price_Cost__c dealUPCRec : dealItemRec.Deal_Unit_Prices_Costs__r) {
                totalPrice += dealUPCRec.Total_Price__c != null ? dealUPCRec.Total_Price__c : 0 ;
                if(dealUPCRec.Type__c == 'Base') {
                    baseDealUPCToDelete = dealUPCRec;
                    unitPriceCostId = dealUPCRec.Unit_Price_Cost__r.Id;
                } else {
                    dealUPCRec.Price__c = 0;
                    dealUPCRec.Price_When_Tax_Included__c = 0;
                }
            }
            totalPrice = ((totalPrice != null) ? totalPrice : 0).setScale(2, RoundingMode.HALF_UP);

            if(dealItemRec.Deal_Unit_Prices_Costs__r.size() > 0 && (dealItemIdToSalesPriceMap.get(dealItemRec.Id) != totalPrice)) {
                DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = true;
                dealUPCToUpdateList.addAll(dealItemRec.Deal_Unit_Prices_Costs__r);
                dealUPCToDeleteList.add(baseDealUPCToDelete);
                DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = false;
                dealUPCToInsertList.add(createBaseDUPCForDP360Unit(dealItemIdToSalesPriceMap.get(dealItemRec.Id), unitPriceCostId, dealItemRec.Id));
            }
        }
        
        // Disable trigger
        DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = true;
        if(dealUPCToUpdateList.size() > 0) {
            DMLUtility.updateSobjectList('Deal_Unit_Price_Cost__c', dealUPCToUpdateList);
        }
        if(dealUPCToDeleteList.size() > 0) {
            DMLUtility.deleteSobjectList('Deal_Unit_Price_Cost__c', dealUPCToDeleteList);
        }
        DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = false;
        
        // Not disabling trigger because we need to populate totals on deal
        if(dealUPCToInsertList.size() > 0) {
            DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dealUPCToInsertList);
        }
        return leadSalePriceObjList[0].COHeaderId;
    }

    private static Deal_Unit_Price_Cost__c createBaseDUPCForDP360Unit(Decimal dp360UnitSalePrice, String unitPriceCostId,String dealItemId){
        Deal_Unit_Price_Cost__c dealUnitPriceCostRec = new Deal_Unit_Price_Cost__c();
        dealUnitPriceCostRec.Name = Constants.BASE_UNIT;
        dealUnitPriceCostRec.Item_Description__c = Constants.BASE_UNIT;
        dealUnitPriceCostRec.Type__c = 'Base';
        dealUnitPriceCostRec.Qty__c = 1;
        dealUnitPriceCostRec.Price__c = dp360UnitSalePrice;
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            dealUnitPriceCostRec.Price_When_Tax_Included__c = dealUnitPriceCostRec.Price__c;
        }
        dealUnitPriceCostRec.Deal_Item__c =  dealItemId;
        dealUnitPriceCostRec.Unit_Price_Cost__c = unitPriceCostId;
        return dealUnitPriceCostRec;
    }
    
    private static String getDealIdByCoHeaderId(String coHeaderId) {
        List<Deal_Item__c> dealItemList = [SELECT Deal__c FROM Deal_Item__c WHERE Deal__r.CO_Header__c =: coHeaderId order by CreatedDate ASC limit 1];
        String dealId;
        if(dealItemList.size() > 0) {
            dealId = dealItemList[0].Deal__c;
            delete dealItemList;
        }
        return dealId;
    }

    private static List<String> addInternalComments(List<String> internalCommentList, SearchLeadResultWrapper.LeadWrapper leadObj, 
                                                        Set<String> stockVINSet, Set<String> tradeInVINSet) { 
        for(SearchLeadResultWrapper.LeadUnitsWrapper leadUnit : leadObj.lead_units) {
            if(leadUnit.unit_record_type == 1 && !stockVINSet.contains(leadUnit.vin.toLowerCase())) {
                internalCommentList.add(addUnitNotFoundComment(leadUnit, 'SKU'));
            }
            if(leadUnit.unit_record_type == 2 && !tradeInVINSet.contains(leadUnit.vin.toLowerCase())) {
                internalCommentList.add(addUnitNotFoundComment(leadUnit, 'TradeIn'));
            }
        }
        return internalCommentList;
    }

    private static void updateLeadIdOnDeal(String dealId, String leadId) {
        DealTriggerHelper.isForceStopTrigger = true;
        Deal__c dealRec = new Deal__c(Id = dealId, DP360_Lead_Id__c  = leadId);
        DMLUtility.updateSobjectList('Deal__c', dealRec);
        DealTriggerHelper.isForceStopTrigger = false;
    }
    
    private static void addTradeIns(String dealId, String customerId, List<Customer_Owned_Unit__c> couList, Map<String, Decimal> vinToAgreedValueMap) {
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        for(Customer_Owned_Unit__c cou : couList) {
            Deal_Item__c dealItemRec = new Deal_Item__c();
            dealItemRec.Customer_Owned_Unit__c = cou.Id;
            dealItemRec.Deal__c = dealId;
            // Populate the Agreed Value on the trade-in unit using the trade-in(sales price) value from the DP360 lead
            dealItemRec.Agreed_Value__c = vinToAgreedValueMap.get(cou.VIN_Number__c.toLowerCase());
            dealItemRec.Type__c = Constants.DEAL_ITEM_TYPE_TRADE_IN;
            dealItemList.add(dealItemRec);
        }

        String defaultUnitSalesTaxId = Configurations__c.getInstance().Default_Tax_on_Unit__c;
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Sales_Tax__c> salesTaxList = [Select Id, Rate__c from Sales_Tax__c WHERE Id = :defaultUnitSalesTaxId];
        if(salesTaxList.size() > 0) {
            for(Deal_Item__c dealItemRec : dealItemList) {
                dealItemRec.Default_Unit_Sales_Tax_Percentage__c = salesTaxList[0].Rate__c;
                dealItemRec.Applicable_Tax__c = salesTaxList[0].Id;
                dealItemRec.Taxable__c = true;
            }
        }
        DMLUtility.insertSobjectList('Deal_Item__c', dealItemList);
    }
    
    private static String createCO(String customerId) {
        String customerIdEncoded = BPUtility.getEncodedString(customerId);
        String sellingGroupEncoded = BPUtility.getEncodedString('Unit Deal');
        String coHeaderIdEncoded = BPGlobalHeaderCtrl.createNewCO(customerIdEncoded, sellingGroupEncoded, true);
        MerchandiseService.removeMerchandiseSection(coHeaderIdEncoded, true);
        return BPUtility.getDecodedString(coHeaderIdEncoded);
    }
    
    private static String getDealItemId(String coHeaderId) {
        List<Deal_Item__c> dealItemList = [SELECT Id FROM Deal_Item__c WHERE Deal__r.CO_Header__c =: coHeaderId order by CreatedDate ASC limit 1];
        String dealItemId;
        if(dealItemList.size() > 0) {
            dealItemId = dealItemList[0].Id;
        }
        return dealItemId;
    }
    
    private static Set<String> getUnitVINsFromLeadObj(SearchLeadResultWrapper.LeadWrapper leadObj) {
        List<SearchLeadResultWrapper.LeadUnitsWrapper> leadUnits = 
            leadObj.lead_units != null ? leadObj.lead_units : new List<SearchLeadResultWrapper.LeadUnitsWrapper>();
        Set<String> vinNumberSet = new Set<String>();
        for(SearchLeadResultWrapper.LeadUnitsWrapper unit : leadUnits) {
            if(unit.unit_record_type == 1 && String.isNotBlank(unit.vin)) {
                vinNumberSet.add(unit.vin.toLowerCase());
            } else if(unit.unit_record_type == 2 && String.isNotBlank(unit.vin)) {
                vinNumberSet.add(unit.vin.toLowerCase());
            }
        }
        return vinNumberSet;
    }
    
    private static Set<String> getStockUnitVINFromLeadObj(SearchLeadResultWrapper.LeadWrapper leadObj) {
        List<SearchLeadResultWrapper.LeadUnitsWrapper> leadUnits = 
            leadObj.lead_units != null ? leadObj.lead_units : new List<SearchLeadResultWrapper.LeadUnitsWrapper>();
        Set<String> skuVINList = new Set<String>();
        for(SearchLeadResultWrapper.LeadUnitsWrapper unit : leadUnits) {
            if(unit.unit_record_type == 1 && String.isNotBlank(unit.vin)) {
                skuVINList.add(unit.vin.toLowerCase());
            }
        }
        return skuVINList;
    }
    
    private static Set<String> getTradeInVINFromLeadObj(SearchLeadResultWrapper.LeadWrapper leadObj) {
        List<SearchLeadResultWrapper.LeadUnitsWrapper> leadUnits = 
            leadObj.lead_units != null ? leadObj.lead_units : new List<SearchLeadResultWrapper.LeadUnitsWrapper>();
        Set<String> tradeInVINList = new Set<String>();
        for(SearchLeadResultWrapper.LeadUnitsWrapper unit : leadUnits) {
            if(unit.unit_record_type == 2 && String.isNotBlank(unit.vin)) {
                tradeInVINList.add(unit.vin.toLowerCase());
            }
        }
        return tradeInVINList;
    }
    
    public static LeadCustomerInfoWrapper setLeadCustomerInfo(SearchLeadResultWrapper.LeadWrapper leadDataObj) {
        LeadCustomerInfoWrapper customerInfo = new LeadCustomerInfoWrapper();
        if(String.isBlank(leadDataObj.first_name) && String.isBlank(leadDataObj.last_name)) {
        	customerInfo.BusinessName = leadDataObj.dealer_name;
        	customerInfo.Type = 'Business';
        	customerInfo.WorkNumber = leadDataObj.phone;
        	customerInfo.WorkEmail = leadDataObj.email;
        } else {
        customerInfo.FirstName = leadDataObj.first_name;
        customerInfo.LastName = leadDataObj.last_name;
            customerInfo.MiddleName = leadDataObj.m_name;
        	customerInfo.Type = 'Individual';
        	customerInfo.HomeNumber = leadDataObj.phone;
        customerInfo.HomeEmail = leadDataObj.email;
        }
        
        customerInfo.OtherEmail = leadDataObj.alternate_email;
        customerInfo.OtherPhone = leadDataObj.mobile;
        customerInfo.BillingStreet1 = leadDataObj.address;
        customerInfo.BillingStreet2 = leadDataObj.address2;
        customerInfo.BillingCity = leadDataObj.city;
        customerInfo.BillingPostalCode = leadDataObj.zip;
        customerInfo.Active = true;
        customerInfo.IsCustomer = true;
        customerInfo.IsVendor = false;
        customerInfo.IsBothAddressSame = true;
        
        if(!AccessControl.ifObjectFieldIsAccessible('Account_Type__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Account_Type__c> accTypeList = [SELECT Id FROM Account_Type__c WHERE Applies_To__c = 'Customers' 
                                                AND Active__c = true AND Default__c = true limit 1];
        if(accTypeList.size() > 0) {
            customerInfo.AccountTypeId = accTypeList[0].Id;
        }
        return customerInfo;
    }
    
    private static String addPrimaryLeadComment(SearchLeadResultWrapper.LeadWrapper leadObj) {
        String comment = 'Deal created from DP360 lead: ' + leadObj.lead_id;
        comment += ' for customer ' + (leadObj.first_name != null ? leadObj.first_name + ' ' : '') +
                                    (leadObj.m_name != null ? leadObj.m_name + ' ' : '') +
                                    (leadObj.last_name != null ? leadObj.last_name : '');
        return comment;
    }

    private static String addUnitNotFoundComment(SearchLeadResultWrapper.LeadUnitsWrapper leadUnit, String unitType) {
        String comment = (unitType == 'TradeIn' ? 'No matching customer unit found for VIN: ' : 'No matching unit found for VIN: ');
        comment += ((leadUnit.vin != null ? leadUnit.vin + ' ' : '') + 
                    (leadUnit.unit_year != null ? leadUnit.unit_year + ' ' : '') +
                    (leadUnit.unit_make != null ? leadUnit.unit_make + ' ' : '') +
                    (leadUnit.unit_model != null ? leadUnit.unit_model : '')); 
        comment += ((unitType == 'TradeIn' ? ' Payoff: $' : ' Price: $') + 
                        ((leadUnit.sale_price != null) ? leadUnit.sale_price : 0).setScale(2, RoundingMode.HALF_UP));
        return comment;
    }

    private static void addInternalCommentToCO(String coHeaderId, List<String> commentList) {
        List<Internal_Comment__c> internalCommentToInsertList = new List<Internal_Comment__c>();
        for(String comment: commentList) {
            Internal_Comment__c internalComment = new Internal_Comment__c();
            internalComment.CO_Header__c = coHeaderId;
            internalComment.Comment__c = comment;
            internalCommentToInsertList.add(internalComment);
        }
        DMLUtility.insertSobjectList('Internal_Comment__c', internalCommentToInsertList);
    }
    
    public class LeadInfoWrapper {
        public String LeadId;
        public String ContactName;
        public String Units;
        public String FormattedLeadName;
    }
    
    public class LeadCustomerInfoWrapper {
    	public String BusinessName;
        public String FirstName;
        public String MiddleName;
        public String LastName;
        public String HomeEmail;
        public String OtherEmail;
        public String HomeNumber;
        public String OtherPhone;
        public String WorkNumber;
        public String WorkEmail;
        public String Type;
        public Boolean Active;
        public Boolean IsCustomer;
        public Boolean IsVendor;
        public Boolean IsBothAddressSame;
        public String BillingStreet1;
        public String BillingStreet2;
        public String BillingCity;
        public String BillingPostalCode;
        public String AccountTypeId;
    }
    
    public class UpdateLeadWrapper {
        public Integer dealer_id;
        public LeadObjInfoWrapper lead;
        
        public UpdateLeadWrapper(Integer dealerId, Integer leadId, String leadStatus, Boolean isSold) {
            this.dealer_id = dealerId;
            this.lead = new LeadObjInfoWrapper(leadId, leadStatus, isSold);
        }
    }
    
    public class LeadObjInfoWrapper {
        public Integer lead_id;
        public String lead_status;
        public Integer is_sold;
        
        public LeadObjInfoWrapper(Integer leadId, String leadStatus, Boolean isSold) {
            this.lead_id = leadId;
            this.lead_status = leadStatus;
            this.is_sold = (isSold ? 1 : 0);
        }
    }

    public class LeadSalePriceWrapper {
        public Decimal SalePrice;
        public String COHeaderId;
        public String DealItemId;
        public String DealId;
        public String UnitId;
        
        public LeadSalePriceWrapper(Decimal salePrice, String unitId, String coHeaderId, String dealId, String dealItemId) {
            this.SalePrice = salePrice;
            this.COHeaderId = coHeaderId;
            this.DealItemId = dealItemId;
            this.DealId = dealId;
            this.UnitId = unitId;
        }
    }
}