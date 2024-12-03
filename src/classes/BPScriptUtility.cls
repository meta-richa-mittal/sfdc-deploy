/**
 * Author: Tarun Khandelwal
 * Since: May 21, 2018
 * Name: BPScriptUtility
 * Description: Apex class for all scripts
**/
global class BPScriptUtility {
    global static void updateStatusAndTotalsForMerchSectionOnCOHeader() {
        disbaleTrigger('COTrigger');
        List<CO_Line_Item__c> coliList = [Select Id, CO_Header__c from CO_Line_Item__c where CO_Header__r.Parts_And_Accessories_Tax_Amount__c = null AND Is_In_Merch_Section__c = true limit: SOQLUtil.getAvailableQueryRowsLimit()];
        Set<Id> coHeaderIdSet = new Set<Id>();
        for(CO_Line_Item__c coliRec : coliList) {
            coHeaderIdSet.add(coliRec.CO_Header__c);
        }
        List<CO_Header__c> coHeaderListToUpdate = COLineItemTriggerHelper.updateStatusAndTotalsForMerchSectionOnCOHeader(coHeaderIdSet);
        if(coHeaderListToUpdate.size() > 0) {
            Database.update(coHeaderListToUpdate, false);
        }
        enableTrigger('COTrigger');
    }
    
    global void populateFieldsOnInvoice() {
        disbaleTrigger('COInvoiceTrigger');
        List<CO_Invoice_Header__c> coInvoiceList = [Select Id from CO_Invoice_Header__c limit: SOQLUtil.getAvailableQueryRowsLimit()];
        for(CO_Invoice_Header__c coInvoiceRec : coInvoiceList) {
            populateFieldsOnInvoiceById(coInvoiceRec.Id);
        }
        enableTrigger('COInvoiceTrigger');
    }
    
    global static void populateTotalFieldsOnDealAndDealItem() {
    	populateTotalFieldsOnDealAndDealItem(null);
    }
    
    global static void populateTotalFieldsOnDealAndDealItem(Integer recLimit) {
    	recLimit = (recLimit != null ? recLimit : SOQLUtil.getAvailableQueryRowsLimit());
    	OptionAndFeeTriggerHelper.isRunningScript = true;
        List<Deal__c> dealList = [Select Id from Deal__c where Sales_Tax_Total__c = null OR Pre_Tax_Unit_Price_And_Cost_Total__c = null limit: recLimit];
        Set<String> dealIdSet = new Set<String>();
        for(Deal__c dealRec : dealList) {
            dealIdSet.add(dealRec.Id);
        }
        BPScriptUtility.disbaleTrigger('DealTrigger');
        OptionAndFeeTriggerHelper.updateDealTotal(dealIdSet);
        BPScriptUtility.enableTrigger('DealTrigger');
    }
    
    global void populateFieldsOnInvoiceById(Id customerInvoiceId) {
        COService.populateFieldsOnInvoice_future(customerInvoiceId);
    }
    
    global static void shopSettingConfigScript() {
        List<Shop_Settings__c> shopSettingConfigList = new List<Shop_Settings__c>();
        
        shopSettingConfigList.add(new Shop_Settings__c(Name = 'Sunday', Day__c = 'Sunday', Is_Working__c = false, From_Time__c = '8:00AM', To_Time__c = '5:00PM'));
        shopSettingConfigList.add(new Shop_Settings__c(Name = 'Monday', Day__c = 'Monday', Is_Working__c = true, From_Time__c = '8:00AM', To_Time__c = '5:00PM'));
        shopSettingConfigList.add(new Shop_Settings__c(Name = 'Tuesday', Day__c = 'Tuesday', Is_Working__c = true, From_Time__c = '8:00AM', To_Time__c = '5:00PM'));
        shopSettingConfigList.add(new Shop_Settings__c(Name = 'Wednesday', Day__c = 'Wednesday', Is_Working__c = true, From_Time__c = '8:00AM', To_Time__c = '5:00PM'));
        shopSettingConfigList.add(new Shop_Settings__c(Name = 'Thursday', Day__c = 'Thursday', Is_Working__c = true, From_Time__c = '8:00AM', To_Time__c = '5:00PM'));
        shopSettingConfigList.add(new Shop_Settings__c(Name = 'Friday', Day__c = 'Friday', Is_Working__c = true, From_Time__c = '8:00AM', To_Time__c = '5:00PM'));
        shopSettingConfigList.add(new Shop_Settings__c(Name = 'Saturday', Day__c = 'Saturday', Is_Working__c = false, From_Time__c = '8:00AM', To_Time__c = '5:00PM'));
        
        DMLUtility.upsertSobjectList('Shop_Settings__c', shopSettingConfigList);
    }
    
    // Trigger Disable
    global static void disbaleTrigger(String triggerName) {
        Trigger_Soft_Disable__c triggerToDisable = new Trigger_Soft_Disable__c();
        triggerToDisable.Name = triggerName;
        triggerToDisable.Disable_Delete__c = triggerToDisable.Disable_Insert__c = triggerToDisable.Disable_Undelete__c = true;
        triggerToDisable.Disable_Update__c = true;
        DMLUtility.insertSobjectList('Trigger_Soft_Disable__c', triggerToDisable);
    }
    
    global static void enableTrigger(String triggerName) {
        if(AccessControl.ifObjectIsDeletable('Trigger_Soft_Disable__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete [Select Id from Trigger_Soft_Disable__c where Name =: triggerName];
    }
    
    global void populateDealOptionsWIPCostOnUnit() {
        disbaleTrigger('CustomerOwnedUnitTrigger');
        List<Customer_Owned_Unit__c> unitList = [SELECT Id FROM Customer_Owned_Unit__c limit: SOQLUtil.getAvailableQueryRowsLimit()];
        for(Customer_Owned_Unit__c unitRec: unitList) {
            unitRec.Deal_Options_WIP__c = 0;
        }
        if(unitList.size() > 0) {
            update unitList;
        }
        enableTrigger('CustomerOwnedUnitTrigger');
    }
    
    @future
    global static void updateUnitPricesAndCostsForInvoiceDeal() {
        String query = 'Select Id, Customer_Owned_Unit__c, (Select Id,Item_Description__c, Qty__c, '+
                                                            'Price__c, Total_Price__c, Type__c,Tax_Percent__c, '+
                                                            'Sales_Tax_Percentage__c, Unit_Price_Cost__c, '+
                                                            'Price_When_Tax_Included__c from Deal_Unit_Prices_Costs__r) from Deal_Item__c '+
                                                             'where Deal__r.Status__c = \'Invoiced\' AND Type__c = \'Unit\'';
        List<Deal_Item__c> dealItemList = Database.query(query); 
        updateUnitPriceAndCost(dealItemList);
    }
    
    global static void updateUnitPricesAndCostsForInvoiceDeal(Set<String> dealItemIdSet) {
        String query = 'Select Id, Customer_Owned_Unit__c, (Select Id,Item_Description__c, Qty__c, '+
                                                            'Price__c, Total_Price__c, Type__c,Tax_Percent__c, '+
                                                            'Sales_Tax_Percentage__c, Unit_Price_Cost__c, '+
                                                            'Price_When_Tax_Included__c from Deal_Unit_Prices_Costs__r) from Deal_Item__c '+
                                                             'where Deal__r.Status__c = \'Invoiced\' AND Type__c = \'Unit\'';
        query += ((dealItemIdSet != null && dealItemIdSet.size() > 0) ? ' AND Id IN: dealItemIdSet' : '');
        List<Deal_Item__c> dealItemList = Database.query(query);
        updateUnitPriceAndCost(dealItemList);
    }
    
    public static void updateUnitPriceAndCost(List<Deal_Item__c> dealItemList) {
        Map<String, Unit_Price_Cost__c> idTounitPriceAndCostRecMap = new Map<String, Unit_Price_Cost__c>();
        Map<String, Decimal> skuIdToBasePriceMap = new Map<String, Decimal>();
        
        for(Deal_Item__c dealItem : dealItemList) {
            for(Deal_Unit_Price_Cost__c rec : dealItem.Deal_Unit_Prices_Costs__r) {
                if(rec.Type__c == 'Base') {
                    skuIdToBasePriceMap.put(dealItem.Customer_Owned_Unit__c , rec.Price__c);
                    continue;
                }
                Unit_Price_Cost__c unitPriceAndCostRec = new Unit_Price_Cost__c(Id = rec.Unit_Price_Cost__c, Price__c = rec.Price__c);
            
                if(rec.Type__c == 'Base' || rec.Type__c == 'Factory') {
                    unitPriceAndCostRec.Total_Price__c = rec.Price__c;
                } else {
                    rec.Qty__c = (rec.Qty__c != null && rec.Qty__c != 0) ? rec.Qty__c : 1;
                    rec.Price__c = (rec.Price__c != null) ? rec.Price__c : 0;
                    unitPriceAndCostRec.Total_Price__c = (rec.Price__c.setScale(2, RoundingMode.HALF_UP) * rec.Qty__c);
                }
                idTounitPriceAndCostRecMap.put(unitPriceAndCostRec.Id, unitPriceAndCostRec);
            }
        }
        
        List<Customer_Owned_Unit__c> skuList = [Select Id,(Select Id, Total_Price__c, Price__c from Unit_Prices_Costs__r where Type__c = 'Base' Order By CreatedDate ASC) from Customer_Owned_Unit__C where Id IN: skuIdToBasePriceMap.keySet()];
        
        for(Customer_Owned_Unit__C skuRec : skuList) {
            for(Integer i = 0; i < skuRec.Unit_Prices_Costs__r.size(); i++) {
                if(i == 0) {
                    skuRec.Unit_Prices_Costs__r[i].Total_Price__c = skuRec.Unit_Prices_Costs__r[i].Price__c = (skuIdToBasePriceMap.containsKey(skuRec.Id) ? 
                                    skuIdToBasePriceMap.get(skuRec.Id) : 0);
                    idTounitPriceAndCostRecMap.put(skuRec.Unit_Prices_Costs__r[i].Id, skuRec.Unit_Prices_Costs__r[i]);
                } else {
                    skuRec.Unit_Prices_Costs__r[i].Total_Price__c = skuRec.Unit_Prices_Costs__r[i].Price__c = 0;
                    idTounitPriceAndCostRecMap.put(skuRec.Unit_Prices_Costs__r[i].Id, skuRec.Unit_Prices_Costs__r[i]);
                }
            }
        }
        
        update idTounitPriceAndCostRecMap.values(); 
    }
    
    global static void populateRetailPriceOnKitLineItems() {
        disbaleTrigger('KitLineItemtrigger');
        List<Kit_Header_Line_Item__c> khliList = [Select Part__c, Labour_Code__c, Fee__c, Retail_Price__c from Kit_Header_Line_Item__c limit: SOQLUtil.getAvailableQueryRowsLimit()];
        KitLineItemtriggerHelper.setRetailPriceBasedOnDefaultPriceLevel(khliList);
        if(khliList.size() > 0) {
            update khliList;
        }
        enableTrigger('KitLineItemtrigger');
    }
    
    global static void updateUnitInvServiceJobTransactionType() {
        disbaleTrigger('SOTrigger');
        
        List<Co_Header__c> coHeaderList = [Select Id, (Select Id from Service_Order_Headers__r) from Co_Header__c where CO_Type__c = 'Internal Service'];
        List<Transaction_Type__c> ttList = [Select Id from Transaction_Type__c where Type__c = 'Stock Unit'];
        if(ttList.size() != 1) {
            ttList.add(new Transaction_Type__c(Code__c = 'Unit Inventory', Type__c = 'Stock Unit', Code_Label__c = 'Unit Inventory', Default__c = true, Active__c = true));
            DMLUtility.insertSobjectList('Transaction_Type__c', ttList);
        }
        List<Service_Order_Header__c> soList = new List<Service_Order_Header__c>();
        for(Co_Header__c coRec : coHeaderList) {
            for(Service_Order_Header__c soRec : coRec.Service_Order_Headers__r) {
                soRec.Transaction_Type__c = ttList[0].Id;
                soList.add(soRec);
            }
        }
        update soList;
        enableTrigger('SOTrigger');
    }
    
    global static void upsertTransactionTypes() {
        List<Transaction_Type__c> ttList  = [Select Id, Type__c, Active__c, Default__c from Transaction_Type__c limit :SOQLUtil.getAvailableQueryRowsLimit()];
        Boolean isStockUnitExists = false;
        for(Transaction_Type__c tt : ttList) {
            tt.Active__c = true;
            tt.Default__c = true;
            if(tt.Type__c == 'Stock Unit') {
                isStockUnitExists = true;
                continue;
            }
            if(tt.Type__c == 'Customer') {
                tt.Code_Label__c = 'Customer Pay';
            } else if(tt.Type__c == 'Third-Party') {
                tt.Code_Label__c = 'Third-Party';
            } else if(tt.Type__c == 'Internal') {
                tt.Code_Label__c = 'Internal Expense';
            } else if(tt.Type__c == 'Deal') {
                tt.Code_Label__c = 'Deal';
                tt.Type__c = 'Deal Service';
            }
        }
        if(!isStockUnitExists) {
            ttList.add(new Transaction_Type__c(Code__c = 'Unit Inventory', Type__c = 'Stock Unit', Code_Label__c = 'Unit Inventory', Default__c = true, Active__c = true));
        }
        DMLUtility.upsertSobjectList('Transaction_Type__c', ttList);
    }
    
    global static void insertFusionLineItems() {
        new FusionBenchMarking().insertLineItems(true);
    }
    
    global static void updateTradeInActualCashValue() {
        disbaleTrigger('DealItemTrigger');
        List<Deal_Item__c> tradeInList = [SELECT Id, Agreed_Value__c, Actual_Cash_Value__c FROM Deal_Item__c WHERE Type__c = 'Trade In' AND Actual_Cash_Value__c = null];
        for(Deal_Item__c dealItemRec: tradeInList) {
            dealItemRec.Actual_Cash_Value__c = dealItemRec.Agreed_Value__c;
        }
        update tradeInList;
        enableTrigger('DealItemTrigger');
    }
    
    global static void updateTradeInActualCashValueForAusOn() {
        disbaleTrigger('DealItemTrigger');
        List<Deal_Item__c> tradeInList = [SELECT Id, Agreed_Value__c, Actual_Cash_Value__c, Default_Unit_Sales_Tax_Percentage__c FROM Deal_Item__c WHERE Type__c = 'Trade In' AND Actual_Cash_Value__c = null];
        for(Deal_Item__c dealItemRec: tradeInList) {
            Decimal taxPercentage = (dealItemRec.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItemRec.Default_Unit_Sales_Tax_Percentage__c : 0;
            if(dealItemRec.Agreed_Value__c != null) {
                dealItemRec.Actual_Cash_Value__c = (dealItemRec.Agreed_Value__c / (1 + (taxPercentage / 100))).setScale(2, RoundingMode.HALF_UP);
            }
        }
        update tradeInList;
        enableTrigger('DealItemTrigger');
    }
    
    global static void updateSubletSoliAndCreateVoliForOpenCO() {
        disbaleTrigger('ServiceOrderLineItemTrigger');
        disbaleTrigger('VendorOrderLineItemTrigger');
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Line_Item__c> soliList = [SELECT Id, Sublet__c, Service_Order_Header__r.SO_Status__c, CO_Status__c, Qty_Needed__c, Qty_Committed__c, 
                                                        CO_Header_Id__c, Service_Order_Header__r.CO_Header__r.CO_Type__c FROM Service_Order_Line_Item__c 
                                                        WHERE Sublet__c != null AND Sublet__r.Type__c = 'Sublet' AND Service_Order_Header__r.SO_Status__c Not IN :ServiceJobUtil.invoiceableStatusSet 
                                                        AND Service_Order_Header__r.SO_Status__c != :ServiceJobUtil.INVOICED]; 
        for(Service_Order_Line_Item__c soliRec : soliList) {
            soliRec.Status__c = 'Required';
            soliRec.Qty_Committed__c = 0;
        } 
        if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Database.update(soliList, false);
        insertVOLIForOpenCO(soliList);
        enableTrigger('ServiceOrderLineItemTrigger');
        enableTrigger('VendorOrderLineItemTrigger');
    }
    
    private static void insertVOLIForOpenCO(List<Service_Order_Line_Item__c> soliList) {
        if(AccessControl.ifObjectFieldIsAccessible('Product__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Set<Id> subletIdSet = new Set<Id>();
        for(Service_Order_Line_Item__c soLineItemRec : soliList) {
            if(soLineItemRec.Sublet__c != null) {
                subletIdSet.add(soLineItemRec.Sublet__c);
            } 
        }
        
        Map<Id, Product__c> subletIdToSubletRecordMap = new Map<Id, Product__c>([SELECT Id, Code__c, Cost_Method__c, Cost__c, Applicable_Tax__c, 
                                                                        CreatedDate__c, Deductible__c, 
                                                                        Description__c, Price__c, Product_Unique_Name__c, Status__c, Vendor__r.Name
                                                                        from Product__c where Id IN : subletIdSet]);
        
        List<Vendor_Order_Line_Item__c> voLineItemsToUpsert = new List<Vendor_Order_Line_Item__c>();
        Vendor_Order_Line_Item__c voLineItemRec;
        List<Service_Order_Line_Item__c> soLineItemListToUpdate = new List<Service_Order_Line_Item__c>();
        for(Service_Order_Line_Item__c soLineItemRec : soliList) {
            voLineItemRec = new Vendor_Order_Line_Item__c();
            if(soLineItemRec.Sublet__c != null && soLineItemRec.Qty_Needed__c > soLineItemRec.Qty_Committed__c) {
                voLineItemRec.CO_Header__c = soLineItemRec.CO_Header_Id__c;
                voLineItemRec.Service_Order_Line_Item__c = soLineItemRec.Id;
                voLineItemRec.Sublet__c = soLineItemRec.Sublet__c;
                voLineItemRec.Qty_Needed__c = soLineItemRec.Qty_Needed__c - soLineItemRec.Qty_Committed__c;
                voLineItemRec.Is_Service__c = true;
                
                if(subletIdToSubletRecordMap.containsKey(soLineItemRec.Sublet__c)) {
                    if(subletIdToSubletRecordMap.get(voLineItemRec.Sublet__c).Cost_Method__c == 'Fixed Cost' && subletIdToSubletRecordMap.get(voLineItemRec.Sublet__c).Cost__c != null){
                        voLineItemRec.Line_Item_Cost__c = subletIdToSubletRecordMap.get(voLineItemRec.Sublet__c).Cost__c.setScale(2, RoundingMode.HALF_UP);
                    } else if(subletIdToSubletRecordMap.get(voLineItemRec.Sublet__c).Cost_Method__c == 'Percent Retail' && subletIdToSubletRecordMap.get(voLineItemRec.Sublet__c).Cost__c != null) {
                        soLineItemRec.Kit_Price__c = (soLineItemRec.Kit_Price__c != null) ? soLineItemRec.Kit_Price__c : 0;
                        voLineItemRec.Line_Item_Cost__c = ((soLineItemRec.Kit_Price__c *  subletIdToSubletRecordMap.get(voLineItemRec.Sublet__c).Cost__c)/100).setScale(2, RoundingMode.HALF_UP);
                    }
                }
                voLineItemsToUpsert.add(voLineItemRec);
            }
        }
        
        if(voLineItemsToUpsert.size() > 0) {
            DMLUtility.insertSobjectList('Vendor_Order_Line_Item__c', voLineItemsToUpsert);
        }
    }
    
    global static void updateTaxAndTotalForDealWithTradeIn() {
        Set<Id> dealIdSet = new Set<Id>();
        List<Deal_Item__c> dealItemList = [SELECT Id, Deal__c FROM Deal_Item__c WHERE Type__c = 'Trade In' AND Deal__r.Status__c = 'Invoiced'];
        for(Deal_Item__c dealItemRec: dealItemList) {
            dealIdSet.add(dealItemRec.Deal__c);
        }
        
        List<CO_Invoice_Header__c> coInvList = [SELECT SalesTax_Total__c, Part_Total__c, Labour_Total__c, Fee_Total__c, Stamp_Duty_Total__c, Unit_Total__c, Shop_Supplies_Total__c, Trade_In_Total__c, Product_Total__c, F_I_Total__c, Deductible_Total__c, Total__c, Name, Total_Payment__c, CO_Header__r.Customer__r.Total_Store_Credit__c, Invoice_Status__c, CO_Header__r.Order_Status__c,
                                                  (SELECT CO_invoice_Header__c,isActive__c, CO_Line_Item__c, Service_Order_Header__c, CO_Kit_Header__c, Deal__c, SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName 
                                                    FROM CO_Invoice_Items__r WHERE isActive__c = true AND (Deal__c != null) AND Deal__c IN :dealIdSet) FROM CO_invoice_Header__C where Id IN (SELECT CO_invoice_Header__c 
                                                    FROM CO_Invoice_Item__c where Deal__c != null AND Deal__c IN : dealIdSet)];
        
        Boolean IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Map<Id, Id> dealIdToCOInvIdMap = new Map<Id, Id>();
        for(CO_Invoice_Header__c coInvoice: coInvList) {
            if(coInvoice.CO_Invoice_Items__r.size() > 0) {
                dealIdToCOInvIdMap.put(coInvoice.CO_Invoice_Items__r[0].Deal__c, coInvoice.Id);
            }
        }
        
        Map<Id, List<Individual_Tax__c>> coInvIdToIndividualTaxListMap = new Map<Id, List<Individual_Tax__c>>();
        String query = 'SELECT CO_Line_Item__c, Tax_Rate__c, Form_Label__c, Tax_Amount__c, Taxable_Amount__c, ' +
                        'Deal__c, Enhanced_Tax_Amount__c, Sales_Tax_Item__r.Name__c, SO_Payment_Role__c, SO_Payment_Role__r.Applicable_Tax_Name__c,' +
                        'Applicable_Tax__c, List_Tax_items_on_forms__c, Option_Fee__c, Option_Fee__r.Deal__c, Deal_Unit_Price_Cost__c, Deal_Unit_Price_Cost__r.Deal_Item__c, ' +
                        'Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c, F_I_Product__c, F_I_Product__r.Deal_Finance__c, F_I_Product__r.Deal_Finance__r.Deal__c, ' +
                        'Deal_Item__c, Deal_Item__r.Deal__c from Individual_Tax__c' + 
                        ' WHERE Option_Fee__r.Deal__c IN: dealIdSet OR ' +
                        'Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c IN: dealIdSet OR F_I_Product__r.Deal_Finance__r.Deal__c IN: dealIdSet '+
                        'OR (Deal_Item__r.Deal__c IN: dealIdSet AND Deal_Item__r.Type__c = \'Trade In\') OR Deal__c IN: dealIdSet';
            
        List<Individual_Tax__c> individualTaxItemsList = Database.query(query);
        for(Individual_Tax__c idividualTaxItem: individualTaxItemsList) {
            Id coInvId;
            if(idividualTaxItem.Deal__c != null) {
                coInvId = dealIdToCOInvIdMap.get(idividualTaxItem.Deal__c);
            } else if(idividualTaxItem.Option_Fee__c != null) {
                coInvId = dealIdToCOInvIdMap.get(idividualTaxItem.Option_Fee__r.Deal__c);
            } else if(idividualTaxItem.Deal_Unit_Price_Cost__c != null && idividualTaxItem.Deal_Unit_Price_Cost__r.Deal_Item__c != null) {
                coInvId = dealIdToCOInvIdMap.get(idividualTaxItem.Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c);
            } else if(idividualTaxItem.F_I_Product__c != null && idividualTaxItem.F_I_Product__r.Deal_Finance__c != null) {
                coInvId = dealIdToCOInvIdMap.get(idividualTaxItem.F_I_Product__r.Deal_Finance__r.Deal__c);
            } else if(idividualTaxItem.Deal_Item__c != null) {
                coInvId = dealIdToCOInvIdMap.get(idividualTaxItem.Deal_Item__r.Deal__c);
            }
            
            if(!coInvIdToIndividualTaxListMap.ContainsKey(coInvId)) {
                coInvIdToIndividualTaxListMap.Put(coInvId,new List<Individual_Tax__c>());
            }
            coInvIdToIndividualTaxListMap.get(coInvId).add(idividualTaxItem);
        }
        for(CO_Invoice_Header__c coInvoice: coInvList) {
            List<Id> dealIds = new List<Id>();
            for(CO_Invoice_Item__c coInvoiceItem : coInvoice.CO_Invoice_Items__r) {
                if(coInvoiceItem.Deal__c != null) {
                    dealIds.add(coInvoiceItem.Deal__c);
                }
            }
            
            Decimal salesTaxTotal = 0;
            Boolean isInvoiced = (coInvoice.Invoice_Status__c == 'Active') ? false : true;
            List<Individual_Tax__c> individualItemsList = coInvIdToIndividualTaxListMap.containsKey(coInvoice.Id) ? coInvIdToIndividualTaxListMap.get(coInvoice.Id) : new List<Individual_Tax__c>();
            Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList);    
            for(String taxName : salesTaxNameToTaxValue.keySet()) {
                salesTaxTotal += salesTaxNameToTaxValue.get(taxName); 
            }
            coInvoice.SalesTax_Total__c = salesTaxTotal.setScale(2, RoundingMode.HALF_UP);
            
            if(!isTaxIncludingPricing) {
                coInvoice.Part_Total__c = coInvoice.Part_Total__c != null ? coInvoice.Part_Total__c : 0;
                coInvoice.Labour_Total__c = coInvoice.Labour_Total__c != null ? coInvoice.Labour_Total__c : 0;
                coInvoice.Fee_Total__c = coInvoice.Fee_Total__c != null ? coInvoice.Fee_Total__c : 0;
                coInvoice.Stamp_Duty_Total__c = coInvoice.Stamp_Duty_Total__c != null ? coInvoice.Stamp_Duty_Total__c : 0;
                coInvoice.Unit_Total__c = coInvoice.Unit_Total__c != null ? coInvoice.Unit_Total__c : 0;
                coInvoice.Shop_Supplies_Total__c = coInvoice.Shop_Supplies_Total__c != null ? coInvoice.Shop_Supplies_Total__c : 0;
                
                coInvoice.Trade_In_Total__c = coInvoice.Trade_In_Total__c != null ? coInvoice.Trade_In_Total__c : 0;
                coInvoice.Product_Total__c = coInvoice.Product_Total__c != null ? coInvoice.Product_Total__c : 0;
                
                coInvoice.F_I_Total__c = coInvoice.F_I_Total__c != null ? coInvoice.F_I_Total__c : 0;
                coInvoice.Deductible_Total__c = coInvoice.Deductible_Total__c != null ? coInvoice.Deductible_Total__c : 0;
                
                coInvoice.Total__c = coInvoice.Part_Total__c + coInvoice.Labour_Total__c + coInvoice.Fee_Total__c + coInvoice.Unit_Total__c + coInvoice.Trade_In_Total__c 
                                            + coInvoice.Product_Total__c + coInvoice.Stamp_Duty_Total__c + coInvoice.Shop_Supplies_Total__c + coInvoice.Deductible_Total__c + coInvoice.F_I_Total__c;
                coInvoice.Total__c += coInvoice.SalesTax_Total__c;
            }
        }
        update coInvList;
    }
    
    global static void populateSOHeaderOnExistingAppointments() {
        List<Event> coAssignedEventList = [SELECT Id, CO_Header__c, Service_Order_Header__c FROM Event WHERE CO_Header__c != null];
        Map<String, List<Event>> coHeaderIdToEventListMap = new Map<String, List<Event>>();
        List<Event> eventList;
        for(Event eventRec : coAssignedEventList) {
            if(coHeaderIdToEventListMap.containsKey(eventRec.CO_Header__c)) {
                eventList = coHeaderIdToEventListMap.get(eventRec.CO_Header__c);
                eventList.add(eventRec);
            } else {
                eventList = new List<Event>();
                eventList.add(eventRec);
            }
            coHeaderIdToEventListMap.put(eventRec.CO_Header__c, eventList);
        }
        
        List<CO_Header__c> listOfCOHavingEventList = [SELECT Id, (SELECT Id FROM Service_Order_Headers__r ORDER by CreatedDate ASC LIMIT 1) FROM CO_Header__c WHERE Id IN: coHeaderIdToEventListMap.keySet()];
        List<Event> eventListToUpdate = new List<Event>();
        for(CO_Header__c coRec : listOfCoHavingEventList) {
            if(coHeaderIdToEventListMap.containsKey(coRec.Id) && coRec.Service_Order_Headers__r.size() > 0) {
                for(Event eventRec : coHeaderIdToEventListMap.get(coRec.Id)) {
                    eventRec.Service_Order_Header__c = coRec.Service_Order_Headers__r[0].Id;
                    eventListToUpdate.add(eventRec);
                }
            }
        }
        update eventListToUpdate;
     }
     
     global static void deleteNonDefaultSpecialCategories() {
        List<String> specialCategoryTypeList = new List<String>{'Trade-in', 'Deductible', 'Stamp Duty', 'Lien Payout'};
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Category__c> nonDefaultCategoryList = [SELECT Id FROM Category__c WHERE Default__c = false AND Type__c IN :specialCategoryTypeList];
        if(nonDefaultCategoryList.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete nonDefaultCategoryList;
        }
     }
     
     global static void createDefaultSpecialCategories() {
        Map<String, String> categoryNameToTypeMap = new Map<String, String>{'Trade-in' => 'TradeIn Default',
                                                                                'Deductible' => 'Claim Deductible Default',
                                                                                'Stamp Duty' => 'Stamp Duty Default',
                                                                                'Stocked Trade' => 'Stocked Trade Default',
                                                                                'Lien Payout' => 'Lien Payout'
                                                                            };
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Category__c> defaultCategoryList = [SELECT Id, Type__c FROM Category__c WHERE Default__c = true AND Active__c = true AND Type__c IN :categoryNameToTypeMap.keySet()];
        
        Set<String> existingSpecialCategorySet = new Set<String>();
        for(Category__c catRec: defaultCategoryList) {
            existingSpecialCategorySet.add(catRec.Type__c);
        }
        
        List<Category__c> categoryListToInsert = new List<Category__c>();
        for(String categoryType: categoryNameToTypeMap.keySet()) {
            if(!existingSpecialCategorySet.contains(categoryType)) {
                categoryListToInsert.add(new Category__c(
                                                    Name=categoryNameToTypeMap.get(categoryType),Description__c=categoryNameToTypeMap.get(categoryType),
                                                    Type__c=categoryType,Default__c=true,Active__c=true
                                                ));
            }
        }
        if(categoryListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Category__c', categoryListToInsert);
        }
    }
    
    global static void populatePurchaseTaxOnVendorInvoice() {
        disbaleTrigger('VendorInvoicingHeaderTrigger');
        List<Vendor_Invoicing_Header__c> vendorInvoiceList = [Select Vendor__r.Purchase_Tax__r.Name__c from Vendor_Invoicing_Header__c
                                WHERE Status__c = 'Invoiced'];
        for(Vendor_Invoicing_Header__c vendorInvoiceRec : vendorInvoiceList) {
            vendorInvoiceRec.Applicable_Purchase_Tax_Name__c = vendorInvoiceRec.Vendor__r.Purchase_Tax__r.Name__c;
        }
        if(vendorInvoiceList.size() > 0) {
            update vendorInvoiceList;
        }
        enableTrigger('VendorInvoicingHeaderTrigger');
    }
    
    global static void populateDefaultTTypeOnExistingAppointmentsAndSOUsingJobType() {
        if(AccessControl.ifObjectFieldIsAccessible('Event') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Transaction_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Event> eventList = [SELECT Id, Job_Type__c, Service_Order_Header__c FROM Event limit: SOQLUtil.getAvailableQueryRowsLimit()];
        List<Transaction_Type__c> defaultTTList = [SELECT Id, Type__c, Internal_Category__r.Id, Internal_Category__r.Name, 
                                                    Third_Party_Customer__r.Id, Third_Party_Customer__r.Name 
                                                    FROM Transaction_Type__c WHERE Active__c = true AND Default__c = true];
        Map<String, Transaction_Type__c> ttTypeToTTRecMap = new Map<String, Transaction_Type__c>();
        for(Transaction_Type__c ttRec : defaultTTList) {
            ttTypeToTTRecMap.put(ttRec.Type__c, ttRec);
        }
        List<Category__c> defaultInternalCategory = [SELECT Id, Name, Active__c, Type__c, Default__c FROM Category__c 
                                                    WHERE Type__c =: 'Internal Expense' AND Active__c = true AND Default__c = true];
        List<Service_Order_Header__c> soListToUpdate = new List<Service_Order_Header__c>();
        Set<Id> soIdSet = new Set<Id>();
        Service_Order_Header__c soRec;
        for(Event eventRec : eventList) { 
            soRec = new Service_Order_Header__c(Id = eventRec.Service_Order_Header__c);
            soRec.Provider__c = null;
            soRec.Category__c = null;
            if(eventRec.Job_Type__c == 'Customer Pay') {
                eventRec.Transaction_Type__c = ttTypeToTTRecMap.containsKey('Customer') ? ttTypeToTTRecMap.get('Customer').Id : null;
                soRec.Transaction_Type__c = ttTypeToTTRecMap.containsKey('Customer') ? ttTypeToTTRecMap.get('Customer').Id : null;
            } else if(eventRec.Job_Type__c == 'Internal Expense') {
                eventRec.Transaction_Type__c = ttTypeToTTRecMap.containsKey('Internal') ? ttTypeToTTRecMap.get('Internal').Id : null;
                soRec.Transaction_Type__c = ttTypeToTTRecMap.containsKey('Internal') ? ttTypeToTTRecMap.get('Internal').Id : null;
                soRec.Category__c = ttTypeToTTRecMap.containsKey('Internal') ? ttTypeToTTRecMap.get('Internal').Internal_Category__r.Id : null;
                soRec.Category__c = (soRec.Category__c != null) ? soRec.Category__c : (defaultInternalCategory.size() > 0 ? defaultInternalCategory[0].Id : null);
            } else if(eventRec.Job_Type__c == 'Third-Party') {
                eventRec.Transaction_Type__c = ttTypeToTTRecMap.containsKey('Third-Party') ? ttTypeToTTRecMap.get('Third-Party').Id : null;
                soRec.Transaction_Type__c = ttTypeToTTRecMap.containsKey('Third-Party') ? ttTypeToTTRecMap.get('Third-Party').Id : null;
                soRec.Provider__c = ttTypeToTTRecMap.containsKey('Third-Party') ? ttTypeToTTRecMap.get('Third-Party').Third_Party_Customer__r.Id : null;
            } else if(eventRec.Job_Type__c == 'Deal') {
                eventRec.Transaction_Type__c = ttTypeToTTRecMap.containsKey('Deal Service') ? ttTypeToTTRecMap.get('Deal Service').Id : null;
            } else { 
                eventRec.Transaction_Type__c = ttTypeToTTRecMap.containsKey('Customer') ? ttTypeToTTRecMap.get('Customer').Id : null;
            }
            soListToUpdate.add(soRec);
            soIdSet.add(eventRec.Service_Order_Header__c);
        }
        
        if(eventList.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Event') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update eventList;
        }
        
        /**if(soListToUpdate.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update soListToUpdate;
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Line_Item__c> soLineItemListToUpdate = [SELECT Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c IN: soIdSet];
        
        if(soLineItemListToUpdate.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update soLineItemListToUpdate;
        }*/
     }
     
     global static void resetVINField() {
        disbaleTrigger('CustomerOwnedUnitTrigger');
        List<Customer_Owned_Unit__c> unitList = [SELECT Id FROM Customer_Owned_Unit__c WHERE VIN_Number__c = 'VIN Unknown'];
        for(Customer_Owned_Unit__c unitRec: unitList) {
            unitRec.VIN_Number__c = null;
        }
        update unitList;
        enableTrigger('CustomerOwnedUnitTrigger');
    }
    
    global static void setCOInvoiceJEFlagForInvoicedDeals() {
        disbaleTrigger('COInvoiceTrigger');
        List<Deal__c> dealList = [SELECT Id, Invoice_Number__c from Deal__c where Status__c = 'Invoiced' AND Invoice_Number__c != null];
        List<CO_Invoice_Header__c> coInvoiceList = new List<CO_Invoice_Header__c>();
        for(Deal__c dealRec: dealList) {
            coInvoiceList.add(new CO_Invoice_Header__c(Id=dealRec.Invoice_Number__c, availForQBJournalEntrySync__c=true));
        }
        update coInvoiceList;
        enableTrigger('COInvoiceTrigger');
    }
    
    global static void executeBatchJobs(List<sObject> recordList, Integer maxNumberOfRecord, String entityType) {
        for(Integer i = 0; i < Math.ceil(recordList.size() / Decimal.valueOf(maxNumberOfRecord)) && i < 100; i++) {
            Set<Id> recordIdSet = new Set<Id>();
            for(Integer j = (i * maxNumberOfRecord); (j < ((i + 1) * maxNumberOfRecord) && j < recordList.size()); j++) {
                recordIdSet.add(recordList[j].Id);
            }
            if(entityType == 'PartRetail') {
                CalculatePartRetailPrice_Batch batchObj = new CalculatePartRetailPrice_Batch(recordIdSet, maxNumberOfRecord);
            }
        }
    }
    
    global static void insertDefaultAccountTypes() {
        List<Account_Type__c> deafultAccountTypesToBeAdded = [Select Id from Account_Type__c];
        if(deafultAccountTypesToBeAdded.size() == 0) {
            deafultAccountTypesToBeAdded.add(new Account_Type__c(Name='Retail Customer',Applies_To__c='Customers', Active__c=true, Default__c=true));
            deafultAccountTypesToBeAdded.add(new Account_Type__c(Name='Supplier',Applies_To__c='Vendors', Active__c=true, Default__c=true));
            DMLUtility.insertSobjectList('Account_Type__c', deafultAccountTypesToBeAdded);
        }
    }
    
    global static void populateTaxFieldsOnDealItem() {
        disbaleTrigger('DealItemTrigger');
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Deal_Item__c> dealItemList = [SELECT Id, Type__c, Applicable_Tax__c, Customer_Owned_Unit__r.Taxable__c, Customer_Owned_Unit__r.Applicable_Tax__c 
                                              FROM Deal_Item__c];
        List<Sales_Tax__c> defaultUnitSalesTaxList = [Select Id from Sales_Tax__c where Id =: Configurations__c.getInstance().Default_Tax_on_Unit__c];
        
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT && dealItemRec.Customer_Owned_Unit__c != null && dealItemRec.Applicable_Tax__c == null) {
                dealItemRec.Taxable__c = dealItemRec.Customer_Owned_Unit__r.Taxable__c;
                dealItemRec.Applicable_Tax__c = (dealItemRec.Customer_Owned_Unit__r.Taxable__c) ? dealItemRec.Customer_Owned_Unit__r.Applicable_Tax__c : null;
            } else {
                dealItemRec.Taxable__c = (defaultUnitSalesTaxList.size() > 0);
                dealItemRec.Applicable_Tax__c = (defaultUnitSalesTaxList.size() > 0 != null) ? defaultUnitSalesTaxList[0].Id : null;
            } 
        }
        if(dealItemList.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update dealItemList;
        }
        enableTrigger('DealItemTrigger');
    }
    
    global static void populateIndividualTaxesOnVendorInvoices() {
        Set<Id> invoiceHeaderIdSet = (new Map<Id, Vendor_Invoicing_Header__c>([SELECT Id FROM Vendor_Invoicing_Header__c limit: SOQLUtil.getAvailableQueryRowsLimit()])).keySet();
        if(invoiceHeaderIdSet.size() > 0) {
            populateIndividualTaxesOnVendorInvoices(invoiceHeaderIdSet);
        }
    }
    
    global static void populateIndividualTaxesOnVendorInvoices(Set<Id> vendorInvoicingHeaderIdSet) {
        VendorInvoicingCtrl.populateIndividualTaxesOnVendorInvoices(vendorInvoicingHeaderIdSet);
    }
    global static void executeAccountTypeBatch() {
        Database.executeBatch(new AccountTypeBatch());
    }

    global static void populateTaxExemptions() {
        Database.executeBatch(new TaxExemptionsBatch());
    }
    
    global static void createUniqueMakeModelSubmodel() {
        List<Unit_Make__c> makeList = [Select Id, Name, (Select Id, Name__c, Unit_Make__c from Unit_Models__r), (Select Id, Unit_Make__c from Deal_Items__r), (Select Id, Unit_Make__c from Customer_Owned_Units__r), (Select Id, Make__c from Kit_Headers__r) from Unit_Make__c];
        //To Delete
        List<Unit_Make__c> makeListToDelete = new List<Unit_Make__c>();
        List<Unit_Model__c> modelListToDelete = new List<Unit_Model__c>();
        
        //To Insert
        List<Unit_Model__c> modelListToInsert = new List<Unit_Model__c>();
        
        Map<String, String> makeNameToMakeIdMap = new Map<String, String>();
        Map<String, Map<String, String>> makeNameToModelNameToIdMap = new Map<String, Map<String, String>>();
        
        for(Unit_Make__c makeRec : makeList) {
            Map<String, String> modelNameToIdMap = makeNameToModelNameToIdMap.containsKey((makeRec.Name).toLowerCase()) ? 
                        makeNameToModelNameToIdMap.get((makeRec.Name).toLowerCase()) : new Map<String, String>();
            if(!makeNameToMakeIdMap.containsKey((makeRec.Name).toLowerCase())) {
                makeNameToMakeIdMap.put((makeRec.Name).toLowerCase(), makeRec.Id);
                
                
                for(Unit_Model__c modelRec : makeRec.Unit_Models__r) {
                    if(!modelNameToIdMap.containsKey((modelRec.Name__c).toLowerCase())) {
                        modelNameToIdMap.put((modelRec.Name__c).toLowerCase(), modelRec.Id);
                    } else {
                        modelListToDelete.add(modelRec);
                    }
                }
                
            } else {
                for(Unit_Model__c modelRec : makeRec.Unit_Models__r) {
                    if(!modelNameToIdMap.containsKey((modelRec.Name__c).toLowerCase())) {
                        Unit_Model__c newModelRec = modelRec.clone(false, false, false, false);
                        newModelRec.Unit_Make__c = makeNameToMakeIdMap.get((makeRec.Name).toLowerCase());
                        modelListToInsert.add(newModelRec);
                        
                        modelNameToIdMap.put((modelRec.Name__c).toLowerCase(), null);
                    }
                }
                modelListToDelete.addAll(makeRec.Unit_Models__r);
                makeListToDelete.add(makeRec);
            }
            
            makeNameToModelNameToIdMap.put((makeRec.Name).toLowerCase(), modelNameToIdMap);
        }
        if(modelListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Unit_Model__c', modelListToInsert);
            List<Unit_Model__c> modelList = [Select Id, Name__c, Unit_Make__r.Name from Unit_Model__c where Id IN: modelListToInsert];
            for(Unit_Model__c modelRec : modelList) {
                if(makeNameToModelNameToIdMap.containsKey((modelRec.Unit_Make__r.Name).toLowerCase()) && 
                    makeNameToModelNameToIdMap.get((modelRec.Unit_Make__r.Name).toLowerCase()).containsKey((modelRec.Name__c).toLowerCase()) &&
                    makeNameToModelNameToIdMap.get((modelRec.Unit_Make__r.Name).toLowerCase()).get((modelRec.Name__c).toLowerCase()) == null) {
                    makeNameToModelNameToIdMap.get((modelRec.Unit_Make__r.Name).toLowerCase()).put((modelRec.Name__c).toLowerCase(), modelRec.Id);
                }
            }
        }
        updateAllRelatedRecords(makeNameToMakeIdMap, makeNameToModelNameToIdMap);
        createUniqueSubmodel();
        //At the end
        delete modelListToDelete;
        delete makeListToDelete;
    }
    
    private static void updateAllRelatedRecords(Map<String, String> makeNameToMakeIdMap, Map<String, Map<String, String>> makeNameToModelNameToIdMap) {
        List<Deal_Item__c> dealItemList = [Select Id, Unit_Make__r.Name, Unit_Model__r.Name__c from Deal_Item__c where (Unit_Make__c != null OR Unit_Model__c != null)];
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(dealItemRec.Unit_Make__c != null) {
                dealItemRec.Unit_Make__c = makeNameToMakeIdMap.get((dealItemRec.Unit_Make__r.Name).toLowerCase()); 
                if(dealItemRec.Unit_Model__c != null) {
                    dealItemRec.Unit_Model__c = makeNameToModelNameToIdMap.get((dealItemRec.Unit_Make__r.Name).toLowerCase()).get((dealItemRec.Unit_Model__r.Name__c).toLowerCase());
                }              
            }
        }
        
        List<Customer_Owned_Unit__c> unitList = [Select Id, Unit_Make__r.Name, Unit_Model__r.Name__c from Customer_Owned_Unit__c where (Unit_Make__c != null OR Unit_Model__c != null)];
        for(Customer_Owned_Unit__c unitRec : unitList) {
            if(unitRec.Unit_Make__c != null) {
                unitRec.Unit_Make__c = makeNameToMakeIdMap.get((unitRec.Unit_Make__r.Name).toLowerCase()); 
                if(unitRec.Unit_Model__c != null) {
                    unitRec.Unit_Model__c = makeNameToModelNameToIdMap.get((unitRec.Unit_Make__r.Name).toLowerCase()).get((unitRec.Unit_Model__r.Name__c).toLowerCase());
                }
            }
        }
        
        List<Kit_Header__c> kitHeaderList = [Select Id, Make__r.Name, Model__r.Name__c from Kit_Header__c where (Make__c != null OR Model__c != null)];
        for(Kit_Header__c kitRec : kitHeaderList) {
            if(kitRec.Make__c != null) {
                kitRec.Make__c = makeNameToMakeIdMap.get((kitRec.Make__r.Name).toLowerCase());
                if(kitRec.Model__c != null) {
                    kitRec.Model__c = makeNameToModelNameToIdMap.get((kitRec.Make__r.Name).toLowerCase()).get((kitRec.Model__r.Name__c).toLowerCase());
                }
            }
        }
        
        List<Unit_Sub_Model__c> subModelList = [Select Id, Sub_Model_Name__c, Unit_Model__r.Unit_Make__r.Name, Unit_Model__r.Name__c from Unit_Sub_Model__c];
        for(Unit_Sub_Model__c subModelRec : subModelList) {
            if(subModelRec.Unit_Model__c != null) {
                subModelRec.Unit_Model__c = makeNameToModelNameToIdMap.get((subModelRec.Unit_Model__r.Unit_Make__r.Name).toLowerCase()).get((subModelRec.Unit_Model__r.Name__c).toLowerCase());
            }
        }
    
        update dealItemList;
        update unitList;
        update kitHeaderList;
        update subModelList;
    }
    
    public static void createUniqueSubmodel() {
        List<Unit_Model__c> modelList = [Select Id, Name__c, Unit_Make__r.Name, (Select Id, Sub_Model_Name__c, Unit_Model__c from Unit_Sub_Models__r) from Unit_Model__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
        Map<String, Unit_Sub_Model__c> subModelIdToRecMap = new Map<String, Unit_Sub_Model__c>([Select Id, Sub_Model_Name__c, Unit_Model__r.Name__c, (Select Id, Unit_Model__c from Deals_Items__r), (Select Id, Unit_Model__c from Customer_Owned_Units__r), (Select Id, Model__c from Kit_Headers__r) from Unit_Sub_Model__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()]);
        
        List<Deal_Item__c> dealItemListToUpdate = new List<Deal_Item__c>();
        List<Customer_Owned_Unit__c> unitListToUpdate = new List<Customer_Owned_Unit__c>();
        List<Kit_Header__c> kitHeaderListToUpdate = new List<Kit_Header__c>();
        
        //To Delete
        List<Unit_Sub_Model__c> subModelListToDelete = new List<Unit_Sub_Model__c>();
        
        for(Unit_Model__c modelRec : modelList) {
            Map<String, String> submodelNameToIdMap = new Map<String, String>();
            for(Unit_Sub_Model__c submodelObj : modelRec.Unit_Sub_Models__r) {
                if(String.isBlank(submodelObj.Sub_Model_Name__c)) {
                    subModelListToDelete.add(submodelObj);
                    continue;
                }
				
                if(!submodelNameToIdMap.containsKey((submodelObj.Sub_Model_Name__c).toLowerCase())) {
                    submodelNameToIdMap.put((submodelObj.Sub_Model_Name__c).toLowerCase(), submodelObj.Id);
                } else {
                    Unit_Sub_Model__c submodelRec = subModelIdToRecMap.get(submodelObj.Id);
                    for(Deal_Item__c dealItemRec : submodelRec.Deals_Items__r) {
                        dealItemListToUpdate.add(new Deal_Item__c(Id = dealItemRec.Id, Sub_Model__c = submodelNameToIdMap.get((submodelRec.Sub_Model_Name__c).toLowerCase())));
                    }
                    for(Customer_Owned_Unit__c unitRec : submodelRec.Customer_Owned_Units__r) {
                        unitListToUpdate.add(new Customer_Owned_Unit__c(Id = unitRec.Id, Sub_Model__c = submodelNameToIdMap.get((submodelRec.Sub_Model_Name__c).toLowerCase())));
                    }
                    for(Kit_Header__c kitRec : submodelRec.Kit_Headers__r) {
                        kitHeaderListToUpdate.add(new Kit_Header__c(Id = kitRec.Id, Sub_Model__c = submodelNameToIdMap.get((submodelRec.Sub_Model_Name__c).toLowerCase())));
                    }
                    subModelListToDelete.add(submodelRec);
                }
            }
        }
        
        update dealItemListToUpdate;
        update unitListToUpdate;
        update kitHeaderListToUpdate;
        
        DMLUtility.deleteSobjectList('Unit_Sub_Model__c ', subModelListToDelete);
    }
    
    @future
    global static void changesStatusOfInvoicedVRs() {
        Map<Id, Vendor_Invoicing_Header__c> viHeaderMap = new Map<Id, Vendor_Invoicing_Header__c>([Select Id from Vendor_Invoicing_Header__c WHERE Status__c = 'Invoiced']);
        if(viHeaderMap.size() > 0) {
            List<Vendor_Receiving_Header__c> vrHeaderList = [SELECT Id from Vendor_Receiving_Header__c WHERE In_Progress_VI__c IN: viHeaderMap.keyset()];
            for(Vendor_Receiving_Header__c vrHeaderRec : vrHeaderList) {
                vrHeaderRec.Status__c = 'Invoiced';
            }
            update vrHeaderList;
        }
    }
    
    global static void updateTradeInDefaultCategory() {
        List<Category__c> categoryRecs = [SELECT Inventory_GL__c, Type__c from Category__c WHERE (Type__c ='Unit' OR Type__c ='Trade-in') AND Default__c = true];
        Category__c unitDefault;
        Category__c tradeinDefault; 
        for(Category__c categoryRec : categoryRecs) {
            if(categoryRec.Type__c == 'Unit'){
                unitDefault = categoryRec;
            } else if(categoryRec.Type__c == 'Trade-in') {
                tradeinDefault = categoryRec;
            }       
        }
        if(unitDefault!=null) {
            tradeinDefault = tradeinDefault==null? new Category__c(Active__c=true, Type__c='Trade-in', Default__c=true, Name='Trade-in Default', Description__c='Default category for trade ins') : tradeinDefault;
            tradeinDefault.Income_GL__c = unitDefault.Inventory_GL__c;
            update tradeinDefault;
        }
    }
    
    //Added by nidhi
    global static void populateCashDrawerReconciliationForExistingCashReconciliationRec() {
        List<Cash_Reconciliation__c> cashReconRecList = [Select Id, (Select Id from Cash_Reconciliation_Payments__r) 
            from Cash_Reconciliation__c where Id Not In (Select Cash_Reconciliation__c from Cash_Drawer_Reconciliation__c) limit: SOQLUtil.getAvailableQueryRowsLimit()];
        
        Cash_Drawer__c drawer = [Select id from Cash_Drawer__c where Name = 'Main Cash Drawer' AND Active__c = true][0];
        Map<String, Cash_Drawer_Reconciliation__c> cashReconIdToCashDraweReconRecMap = new Map<String, Cash_Drawer_Reconciliation__c>();
        for(Cash_Reconciliation__c cashReconRec : cashReconRecList) {
            Cash_Drawer_Reconciliation__c cashDraweReconRec = new Cash_Drawer_Reconciliation__c(Cash_Reconciliation__c = cashReconRec.Id);
            cashDraweReconRec.Cash_Drawer__c = drawer.Id;
            cashReconIdToCashDraweReconRecMap.put(cashReconRec.Id, cashDraweReconRec);  
        }
        
        DMLUtility.insertSobjectList('Cash_Drawer_Reconciliation__c', cashReconIdToCashDraweReconRecMap.values());
        List<Cash_Reconciliation_Payment__c> cashReconPaymentListToUpdate = new List<Cash_Reconciliation_Payment__c>();
        for(Cash_Reconciliation__c cashReconRec : cashReconRecList) {
            for(Cash_Reconciliation_Payment__c payment : cashReconRec.Cash_Reconciliation_Payments__r) {
                payment.Cash_Drawer_Reconciliation__c = cashReconIdToCashDraweReconRecMap.get(cashReconRec.id).Id;      
            }   
            
            cashReconPaymentListToUpdate.addAll(cashReconRec.Cash_Reconciliation_Payments__r);  
        }
        update cashReconPaymentListToUpdate;
    }
    
    //Update Cash Drawer on Payments
    global static void populateCashDrawerOnPayments() {
        List<Co_Invoice_Payment__c>  coInvPaymentList = [Select Id, Cash_Drawer__c from Co_Invoice_Payment__c where Cash_Drawer__c = null limit: SOQLUtil.getAvailableQueryRowsLimit()];
        Cash_Drawer__c drawer = [Select id from Cash_Drawer__c where Name = 'Main Cash Drawer' AND Active__c = true][0];
        
        for(Co_Invoice_Payment__c invPaymentRec : coInvPaymentList) {
            invPaymentRec.Cash_Drawer__c = drawer.Id;
        }
        update coInvPaymentList;
    }
    
    //Update Cash Drawer on Deposits
    global static void populateCashDrawerOnDeposits() {
        List<Co_Deposit__c>  coDepositList = [Select Id, Cash_Drawer__c from Co_Deposit__c where Cash_Drawer__c = null limit: SOQLUtil.getAvailableQueryRowsLimit()];
        Cash_Drawer__c drawer = [Select id from Cash_Drawer__c where Name = 'Main Cash Drawer' AND Active__c = true][0];
        
        for(Co_Deposit__c depositRec : coDepositList) {
            depositRec.Cash_Drawer__c = drawer.Id;
        }
        update coDepositList;
    }
    
    global static void populateMerchandiseTransactionTypeOnHistoricalRecords() {
		List<CO_Header__c> coHeaderRecList = [Select Merchandise_Transaction_Type__c, Merchandise_Commit_Order_controls__c from CO_Header__c where Merchandise_Transaction_Type__c = null OR Merchandise_Commit_Order_controls__c = null limit: SOQLUtil.getAvailableQueryRowsLimit()];
		if(coHeaderRecList.size() > 0) {
			for(CO_Header__c coHeaderRec : coHeaderRecList) {
				coHeaderRec.Merchandise_Transaction_Type__c = 'Part sale';
				coHeaderRec.Merchandise_Commit_Order_controls__c = 'Commit and order';
			}
			update coHeaderRecList;
		}
    }
    
    global static void deleteDuplicateCashReconciliationPaymentRecords() {
        if(AccessControl.ifObjectFieldIsAccessible('Cash_Drawer_Reconciliation__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Cash_Reconciliation_Payment__C') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Cash_Drawer_Reconciliation__c> cashDrawerReconciliationList = [SELECT Id, (SELECT Id, Payment_Method__c  FROM Cash_Reconciliation_Payments__r ORDER 
        																		by CreatedDate DESC) FROM Cash_Drawer_Reconciliation__c ORDER BY Name ASC 
        																		LIMIT: CashDrawerSOQLUtil.getAvailableQueryRowsLimit()]; 
        
        Map<Id, Map<String, List<Cash_Reconciliation_Payment__C>>> cdrIdToPaymentMethodNameToPaymentRecListMap = new Map<Id, Map<String, List<Cash_Reconciliation_Payment__C>>>();
        for(Cash_Drawer_Reconciliation__c cdrRec : cashDrawerReconciliationList) {
        	cdrIdToPaymentMethodNameToPaymentRecListMap.put(cdrRec.Id, new Map<String, List<Cash_Reconciliation_Payment__C>>());
        	
        	for(Cash_Reconciliation_Payment__c cdrpRec : cdrRec.Cash_Reconciliation_Payments__r) {
        		if(!cdrIdToPaymentMethodNameToPaymentRecListMap.get(cdrRec.Id).containsKey(cdrpRec.Payment_Method__c)) {
        			cdrIdToPaymentMethodNameToPaymentRecListMap.get(cdrRec.Id).put(cdrpRec.Payment_Method__c, new List<Cash_Reconciliation_Payment__C>());
        		} 
        		cdrIdToPaymentMethodNameToPaymentRecListMap.get(cdrRec.Id).get(cdrpRec.Payment_Method__c).add(cdrpRec);
        	}
        }
        
        Set<Id> deletablePaymentRecIdSet = new Set<Id>();
        for(Id cdrRecId : cdrIdToPaymentMethodNameToPaymentRecListMap.keySet()) {
        	for(String paymentMethodName : cdrIdToPaymentMethodNameToPaymentRecListMap.get(cdrRecId).keySet()) {
        		for(Integer i=1; i<cdrIdToPaymentMethodNameToPaymentRecListMap.get(cdrRecId).get(paymentMethodName).size(); i++) {
        			deletablePaymentRecIdSet.add(cdrIdToPaymentMethodNameToPaymentRecListMap.get(cdrRecId).get(paymentMethodName)[i].Id);
        		}
        	}
        }
        List<Cash_Reconciliation_Payment__c> deletablePaymentRecordList = new List<Cash_Reconciliation_Payment__c>();
    	for(Id paymentId : deletablePaymentRecIdSet) {
    		deletablePaymentRecordList.add(new Cash_Reconciliation_Payment__c(Id = paymentId));
    	}
   		if(AccessControl.ifObjectIsDeletable('Cash_Reconciliation_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
   		delete deletablePaymentRecordList;
    }
	
	global static void updatePaymentDateOnCODeposit() {
		disbaleTrigger('CODepositTrigger');
		List<CO_Deposit__c> coDepositList = [Select Id, CreatedDate__c, Payment_Date__c from CO_Deposit__c Where Payment_Date__c = null limit: SOQLUtil.getAvailableQueryRowsLimit()];
		
		for(CO_Deposit__c coDepositRec : coDepositList) {
			coDepositRec.Payment_Date__c = coDepositRec.CreatedDate__c;
		}
		update coDepositList;
		enableTrigger('CODepositTrigger');
	}

	global static void updatePaymentDateOnCOInvoicePayment() {
		disbaleTrigger('COInvoicePaymentTrigger');
		List<CO_Invoice_Payment__c> coInvoicePaymentList = [Select Id, CreatedDate__c, Payment_Date__c from CO_Invoice_Payment__c Where Payment_Date__c = null limit: SOQLUtil.getAvailableQueryRowsLimit()];
		
		for(CO_Invoice_Payment__c coInvoicePaymentRec : coInvoicePaymentList) {
			coInvoicePaymentRec.Payment_Date__c = coInvoicePaymentRec.CreatedDate__c;
		}
		update coInvoicePaymentList;
		enableTrigger('COInvoicePaymentTrigger');
	}
	
    global static void setOrderLotsWhenIsOrderLotFlagDisabled() {
	    List<Part__c> partListToUpdate = [Select Id, Order_Lots__c From Part__c Where Is_OrderLot__c = false AND Order_Lots__c != 1];
	    for(Part__c partRec : partListToUpdate) {
	    	partRec.Order_Lots__c = 1;
	    }
        DMLUtility.upsertSobjectList('Part__c', partListToUpdate);
    }
    global static void finalizeInvoice(List<String> recIdList, String coHeaderId) {
    }

    global static void populateDealOptionClearingControlAccount() {
	    List<Category__c> categories = [Select Id,Income_GL__c FROM Category__c WHERE Type__c = 'Stocked Trade' AND Default__c = true];
	    Accounting_Default_Accounts__c defaultAccounts = Accounting_Default_Accounts__c.getOrgDefaults(); 
	    if(categories.size() > 0) {
	        defaultAccounts.Deal_Option_Clearing__c = categories[0].Income_GL__c;
            DMLUtility.upsertSobjectList('Accounting_Default_Accounts__c', defaultAccounts);
	    }
    }

	global static void populateClosedDateOnInvoice() {
		disbaleTrigger('COInvoiceTrigger');
		List<CO_Invoice_Header__c> coInvoiceHeaderRecList = [select Closed_Invoice_Date__c, Invoice_Date__c from CO_Invoice_Header__c where Closed_Invoice_Date__c = null AND Invoice_Date__c != null Limit 10000];
		
		for(CO_Invoice_Header__c coInvRec : coInvoiceHeaderRecList) {
			coInvRec.Closed_Invoice_Date__c = coInvRec.Invoice_Date__c;
		}
		update coInvoiceHeaderRecList;
		enableTrigger('COInvoiceTrigger');
	}
	
   	global static void changeFinancedToFinancingForDeal(){
   		if(AccessControl.ifObjectIsUpdateable('CO_Deposit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
   		List<CO_Deposit__c> coDepositRecList = [SELECT Payment_Method__c FROM CO_Deposit__c WHERE Payment_Method__c = 'Financed'];
   		for(CO_Deposit__c coDeposit : coDepositRecList){
   			coDeposit.Payment_Method__c = 'Financing';
   		}
   		update coDepositRecList;
   	}
   	
	global static void updateUnitPriceAndCostAdjustments() {
   		List<Category__c> adjustCategoryList = [Select Id from Category__c where Type__c = 'Adjustment' AND Default__c = true];
   		
   		Category__c catRec;
		if(adjustCategoryList.size() > 0) {
			catRec = adjustCategoryList[0];
		} else {
			String invGL = Accounting_Default_Accounts__c.getOrgDefaults().Inventory_Adjustments__c;
			catRec = new Category__c(Type__c = 'Adjustment', Default__c = true , Name = 'Stock Adjustment', Description__c = 'Stock Adjustment', 
									Active__c = true, Income_GL__c = invGL);
            DMLUtility.insertSobjectList('Category__c', catRec);
		}
		   		
		List<Unit_Price_Cost__c> upList = [Select Id,Category__c, CreatedDate from Unit_Price_Cost__c where Ref_No__c LIKE 'UA-%' AND 
								(Category__c = null OR Adjustment_Date__c = null) AND Type__c != 'Dealer' AND Unit_Type__c = 'STOCK' LIMIT :SOQLUtil.getAvailableQueryRowsLimit()];
		
		if(upList.size() > 0) {
			for(Unit_Price_Cost__c upcRec : upList) {
				upcRec.Adjustment_Date__c = upcRec.CreatedDate;
				upcRec.Category__c = catRec.Id;
			}
			BPScriptUtility.disbaleTrigger('UnitPriceAndCostTrigger');
			update upList;
			BPScriptUtility.enableTrigger('UnitPriceAndCostTrigger');
		}
   	}
   	
   	global static void populateLabourCostingOnSOLIBasedOnTechHoursCosting() {
   		if(!GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
			return;
		}
   		List<Service_Order_Header__c> soHeaderRecList = [select Id, 
                                                            (select Qty_Needed__c, Total_Cost__c, Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c 
                                                            from Service_Order_Line_Items__r
                                                            where Labour_Code__c != NULL),
                                                            (select Total_Cost__c from Hours_Logged__r where Is_Removed__c = false)  
                                                            from Service_Order_Header__c where Is_Technician_Hours_Costing_Enabled__c = true 
                                                            AND (SO_Status__c IN: ServiceJobUtil.invoiceableStatusSet OR SO_Status__c =: ServiceJobUtil.INVOICED)];
                                                            
    	List<Service_Order_Line_Item__c> soliListToUpdate = ServiceJobService.populateCostOnLaborSOLI(soHeaderRecList);
    	
    	if(soliListToUpdate != null && soliListToUpdate.size() > 0) {
			ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
			update soliListToUpdate;
			ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
		}
   	}
   	
   	public static Boolean isSyncHoursLoggedOldRecords = false;
   	global static void updateCostingRateOnOldHoursLogged(Boolean isSyncRec) {
   		List<Technician__c> technicianList = [Select Id, Labour_Cost_Per_Hour__c, 
   							(Select Id, Available_For_QB_Sync__c, Costing_Rate__c from Hours_Logged__r where Costing_Rate__c = null AND Is_Removed__c = false) from 
   							Technician__c where Labour_Cost_Per_Hour__c != null AND 
   							Id IN (Select Technician__c from Hours_Logged__c where Costing_Rate__c = null AND Is_Removed__c = false) 
   							LIMIT :SOQLUtil.getAvailableQueryRowsLimit()];
   							
   		Set<Id> hrsLoggedIdSet = new Set<Id>();		
   		List<Hours_Logged__c> hrsLoggedListToUpdate = new List<Hours_Logged__c>();
   		for(Technician__c techRec : technicianList) {
   			for(Hours_Logged__c hrsLoggedRec : techRec.Hours_Logged__r) {
   				hrsLoggedRec.Costing_Rate__c = techRec.Labour_Cost_Per_Hour__c;
   				hrsLoggedRec.Available_For_QB_Sync__c = true;
   				hrsLoggedIdSet.add(hrsLoggedRec.Id);
   			}
   			hrsLoggedListToUpdate.addAll(techRec.Hours_Logged__r);
   		}
   		HoursLoggedTriggerHelper.isForceStopTrigger = true;
   		update hrsLoggedListToUpdate;
   		HoursLoggedTriggerHelper.isForceStopTrigger = false;
   		if(isSyncRec && QBUtil.isQBEnabled()) {
   			BPScriptUtility.isSyncHoursLoggedOldRecords = true;
            //QBHoursLoggedService.syncHoursLogged(hrsLoggedIdSet);
        }
   	}
	
	global static void updateCostingRateOnHoursLogged() {
   		List<Technician__c> technicianList = [Select Id, Labour_Cost_Per_Hour__c, (Select Id, Costing_Rate__c from Hours_Logged__r) from 
   							Technician__c where Labour_Cost_Per_Hour__c != null LIMIT :SOQLUtil.getAvailableQueryRowsLimit()];
   		List<Hours_Logged__c> hrsLoggedListToUpdate = new List<Hours_Logged__c>();
   		for(Technician__c techRec : technicianList) {
   			for(Hours_Logged__c hrsLoggedRec : techRec.Hours_Logged__r) {
   				hrsLoggedRec.Costing_Rate__c = techRec.Labour_Cost_Per_Hour__c;
   			}
   			hrsLoggedListToUpdate.addAll(techRec.Hours_Logged__r);
   		}
   		update hrsLoggedListToUpdate;
   	}
   	
   	global static void updateLaborCostingControlAccounts() {
   		List<Category__c> defaultLaborCategoryList = [select Inventory_GL__c from Category__c
                									where Type__c = 'Labour' AND Active__c = true AND Default__c = true];
   		
   		if(defaultLaborCategoryList.size() > 0) {
   			Accounting_Default_Accounts__c accDefaultConfig = Accounting_Default_Accounts__c.getOrgDefaults();
   			accDefaultConfig.WIP_Labor_Inventory__c = accDefaultConfig.WIP_Labor_Expense__c = defaultLaborCategoryList[0].Inventory_GL__c;
            DMLUtility.upsertSobjectList('Accounting_Default_Accounts__c', accDefaultConfig);
   		}
   	}
   	
   	global static void updateDealAndTradeInPreTaxTotalOnInvoice() {
        disbaleTrigger('COInvoiceTrigger');
        if(!GeneralConfiguration.getTaxIncludingPricing()) {
            List<CO_Invoice_Header__c> coInvoiceHeaderList = [SELECT Trade_In_Total__c FROM CO_Invoice_Header__c WHERE Invoice_Status__c = 'Closed' AND 
                        Id IN (SELECT CO_Invoice_Header__c FROM CO_Invoice_Item__c WHERE Deal__c != null)];
            
	        for(CO_Invoice_Header__c coInvoice : coInvoiceHeaderList) {
	            coInvoice.Pre_Tax_Trade_In_Total__c = coInvoice.Trade_In_Total__c;
	        }
            update coInvoiceHeaderList;
        }
        enableTrigger('COInvoiceTrigger');
    }
    
    global static void updateExpectedDateOnVendorOrders() {
    	disbaleTrigger('VendorOrderHeaderTrigger');
    	List<Vendor_Order_Header__c> voHeadersList = [SELECT Id, Ordered_Date__c, Purchase_Order_Type__r.Lead_Time__c 
    													FROM Vendor_Order_Header__c 
    													WHERE (Status__c = 'On Order' OR Status__c = 'Partially Received' OR Status__c = 'Received') AND Expected_Date__c = null 
    													limit: SOQLUtil.getAvailableQueryRowsLimit()];
		for(Vendor_Order_Header__c voHeaderRec: voHeadersList) {
			Integer leadTime = Integer.valueOf((voHeaderRec.Purchase_Order_Type__c != null && voHeaderRec.Purchase_Order_Type__r.Lead_Time__c != null) ? voHeaderRec.Purchase_Order_Type__r.Lead_Time__c : 0);
			voHeaderRec.Expected_Date__c = voHeaderRec.Ordered_Date__c.addDays(leadTime);
		}
		update voHeadersList;
    	enableTrigger('VendorOrderHeaderTrigger');
    }
    
    global static void syncQBTerms() {
        if(QBUtil.isQBEnabled()) {
            QBTermService.pullTerms(null);
        }
    }
    
    global static void createLocations() {
        Database.executeBatch(new CreateLocationsBasedOnPartLocationBatch());
    }
    
    global static void setFeeTypeOnDefaultFee() {
        List<Fee__c> feeList = [SELECT Type__c FROM Fee__c WHERE Type__c = null];
        for(Fee__c feeRec : feeList) {
            feeRec.Type__c = 'Selling';
        }
        if(feeList.size() > 0) {
        	update feeList;
        }
    }
    
    global static void resyncMerchQBJE(DateTime dt, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceList = 
            [SELECT availForQBJournalEntrySync__c from CO_Invoice_Header__c where Closed_Invoice_Date__c >: dt AND Invoice_Status__c = 'Closed' 
                AND JournalEntryAccountingId__c != null AND Checkout_Type__c = 'Customer' AND Id IN 
                    (SELECT CO_Invoice_Header__c from CO_Invoice_Item__c WHERE CO_Line_Item__c != null)];
        
        for(CO_Invoice_Header__c coInvoiceRec : coInvoiceList) {
            coInvoiceRec.availForQBJournalEntrySync__c = true;
        }
    }

    global static void setMaxNumberOfTechniciansInConfig() {
    	List<Technician__c> technicianList = [SELECT Id FROM Technician__c WHERE Type__c = 'Technician' AND Active__c = true];
    	General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
    	generalConfig.Max_Number_of_Technicians__c = technicianList.size();
        DMLUtility.upsertSobjectList('General_Configurations__c', generalConfig);
    }
    
    global static void populateNameSpaceInConfig() {}

    global static void fixAccountingSettingsNameForQB() {
    	if(QBUtil.isQBEnabled()) {
    		Accounting_Settings__c accountingSetting = Accounting_Settings__c.getOrgDefaults();
    		if(accountingSetting.Provider_Name__c == 'Quickbooks Online') {
    			accountingSetting.Provider_Name__c = 'QuickBooks Online';
    			update accountingSetting;
    		}
    	}
    }
    
    global static void setFusionReportLineItemSource() {}
    
    global static void resyncQBJERelatedToDeal(DateTime dt, Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {
        List<CO_Invoice_Header__c> coInvoiceList = [SELECT availForQBJournalEntrySync__c from CO_Invoice_Header__c where Closed_Invoice_Date__c >: dt AND Invoice_Status__c = 'Closed' 
	                AND JournalEntryAccountingId__c != null AND Checkout_Type__c = 'Customer' AND Id IN 
	                    (SELECT CO_Invoice_Header__c from CO_Invoice_Item__c WHERE Deal__c != null)];
        
        coInvoiceList.addAll([SELECT availForQBJournalEntrySync__c from CO_Invoice_Header__c where Closed_Invoice_Date__c >: dt AND Invoice_Status__c = 'Closed' 
	                AND JournalEntryAccountingId__c != null AND Checkout_Type__c = 'Deal']);
        
        for(CO_Invoice_Header__c coInvoiceRec : coInvoiceList) {
            coInvoiceRec.availForQBJournalEntrySync__c = true;
        }
        /*
        QBScriptUtil.disbaleTrigger('COInvoiceTrigger');
        update coInvoiceList;
        QBScriptUtil.enableTrigger('COInvoiceTrigger');
        
        QBScriptUtil.scheduleJobs(coInvoiceList, maxNumberOfRecord, timeIntervalForJobsInSec, maxNumberOfRecord, 'Customer Invoice Journal Entry');
        */
    }
    
    global static void updateAppointmentEndTime() {
    	if(GeneralConfiguration.isLoadTechnicianScheduling()) {
    		List<Event> appointmentsList = [SELECT Id, Estimated_Hours__c, StartDateTime, EndDateTime FROM Event WHERE Type = 'Appointment'];
	    	if(appointmentsList.size() > 0) {
		    	for(Event appRec: appointmentsList) {
		    		appRec.IsMultiDayEvent__c = false;
		    		appRec.Estimated_Hours__c = appRec.Estimated_Hours__c != null ? appRec.Estimated_Hours__c : 0;
		    		if(appRec.StartDateTime != null) {
		    			appRec.EndDateTime = appRec.StartDateTime.addMinutes((Integer)(appRec.Estimated_Hours__c * 60));
		    			DateTime maxEndTime = DateTime.newInstance(appRec.StartDateTime.date(), Time.newInstance(23, 45, 0, 0));
		    			if(appRec.EndDateTime > maxEndTime) {
			        		appRec.EndDateTime = maxEndTime;
			        	}
		    		}
		    	}
		    	update appointmentsList;
	    	}
    	}
    }
    
    global static void copyEvents() {
        Database.executeBatch(new CopyEventsBatch());
    }
    
    global static void createConfigurationForUnitDataFields() {
        List<Unit_Data_Field_Config__c> unitDataFieldConfigList = new List<Unit_Data_Field_Config__c>();
        for(Integer i=1; i<=15; i++) {
        	Unit_Data_Field_Config__c unitDataFieldConfigRec = new Unit_Data_Field_Config__c();
        	unitDataFieldConfigRec.Name = 'Unit Data ' + (i < 10 ? '0' + i : '' + i);
        	unitDataFieldConfigList.add(unitDataFieldConfigRec);
        }
        
        DMLUtility.insertSobjectList('Unit_Data_Field_Config__c', unitDataFieldConfigList);
    }
    
    global static void createDUPfromUPCForSoldUnits() {
    	List<Unit_Price_Cost__c> upcList = [Select Id, Customer_Owned_Unit__c, Item_Description__c, Price__c, Total_Price__c, Qty__c, Type__c from Unit_Price_Cost__c 
					where Id NOT IN (Select Unit_Price_Cost__c from Deal_Unit_Price_Cost__c where (Deal_Item__r.Deal__r.Status__c = 'Invoiced' OR 
					Deal_Item__r.Deal__r.Invoice_Number__c != null)) AND Type__c != 'Base' AND Customer_Owned_Unit__r.Unit_Type__c = 'STOCK' AND 
					Customer_Owned_Unit__r.Status__c = 'Sold'];
		
		Set<String> unitIdSet = new Set<String>();
		for(Unit_Price_Cost__c upcRec : upcList) {
			unitIdSet.add(upcRec.Customer_Owned_Unit__c);
		}
		
		List<Unit_Price_Cost__c> upcListToUpdate = new List<Unit_Price_Cost__c>();
		unitIdSet.remove(null);
		Map<String, String> unitIdToDealItemIdMap = new Map<String, String>();
		List<Deal_Item__c> dealItemList = [Select Id, Customer_Owned_Unit__c from Deal_Item__c where Type__c = 'Unit' AND 
					(Deal__r.Status__c = 'Invoiced' OR Deal__r.Invoice_Number__c != null) AND Customer_Owned_Unit__c IN: unitIdSet];
		for(Deal_Item__c dealItemRec : dealItemList) {
			unitIdToDealItemIdMap.put(dealItemRec.Customer_Owned_Unit__c, dealItemRec.Id);
		}
		
		List<Deal_Unit_Price_Cost__c> dealUPCListToInsert = new List<Deal_Unit_Price_Cost__c>();	
				
		for(Unit_Price_Cost__c unitPriceCostRec : upcList) {
			Deal_Unit_Price_Cost__c dealUnitPriceCostRec = new Deal_Unit_Price_Cost__c(Unit_Price_Cost__c = unitPriceCostRec.Id);
		        
			if(String.isNotBlank(unitPriceCostRec.Item_Description__c) && unitPriceCostRec.Item_Description__c.length() > 80) {
				dealUnitPriceCostRec.Name = unitPriceCostRec.Item_Description__c.subString(0, 80);
			} else {
				dealUnitPriceCostRec.Name = unitPriceCostRec.Item_Description__c;
			}
			dealUnitPriceCostRec.Item_Description__c = unitPriceCostRec.Item_Description__c;
			dealUnitPriceCostRec.Price__c = 0;
			dealUnitPriceCostRec.Type__c = unitPriceCostRec.Type__c;
			if(dealUnitPriceCostRec.Type__c == 'Dealer') {
				dealUnitPriceCostRec.Qty__c = unitPriceCostRec.Qty__c != null ? unitPriceCostRec.Qty__c : 1;
			} else {
				dealUnitPriceCostRec.Qty__c = 1;
			}
			if(GeneralConfiguration.getTaxIncludingPricing()) {
	            dealUnitPriceCostRec.Price_When_Tax_Included__c = 0;
	        }
			if(unitIdToDealItemIdMap.containsKey(unitPriceCostRec.Customer_Owned_Unit__c)) {
				dealUnitPriceCostRec.Deal_Item__c =  unitIdToDealItemIdMap.get(unitPriceCostRec.Customer_Owned_Unit__c);
				dealUPCListToInsert.add(dealUnitPriceCostRec);
				
				if(unitPriceCostRec.Total_Price__c != 0 || unitPriceCostRec.Price__c != 0) {
					unitPriceCostRec.Total_Price__c =  unitPriceCostRec.Price__c = 0;
					upcListToUpdate.add(unitPriceCostRec);
				}
			}
		}
		DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = true;
        DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dealUPCListToInsert);
		DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = false;
		update upcListToUpdate;
	}

    global static void setFTPFileStorageName() {
        if(!AccessControl.ifObjectFieldIsAccessible('File_Storage__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<File_Storage__c> fileStorageList = [SELECT Id FROM File_Storage__c LIMIT 1];
        
        if(fileStorageList.size() > 0) {
            fileStorageList[0].Name__c = 'FTP';
            update fileStorageList;
        }
    }

    global static void updateBRPVendorListType() {
        List<BRP_Vendors_List__c> brpVendorList = [SELECT Id, Name, Type__c FROM BRP_Vendors_List__c WHERE Type__c = null];
        for(BRP_Vendors_List__c brpVendorRec : brpVendorList) {
            brpVendorRec.Type__c = 'Vendor';
        }

        if(brpVendorList.size() > 0){
            update brpVendorList;
        }
    }

    global static void createPartSaleTransactionType() {
        
        Transaction_Type__c otcPartSales = new Transaction_Type__c();
        otcPartSales.Code__c = 'Part Sale';
        otcPartSales.Code_Label__c = 'OTC Part Sales';
        otcPartSales.Type__c = 'Part Sale';
        otcPartSales.Active__c = true;
        otcPartSales.Default__c = true;

        Transaction_Type__c internetSales = new Transaction_Type__c();
        internetSales.Code__c = 'Part Sale';
        internetSales.Code_Label__c = 'Internet Sales';
        internetSales.Type__c = 'Part Sale';
        internetSales.Active__c = true;

        Transaction_Type__c layaway = new Transaction_Type__c();
        layaway.Code__c = 'Part Sale';
        if(SOQLUtil.getBussinessCountryName() == 'Australia') {
            layaway.Code_Label__c = 'Layby';
        } else {
            layaway.Code_Label__c = 'Layaway';
        }
        layaway.Type__c = 'Part Sale';
        layaway.Active__c = true;

        List<Transaction_Type__c> ttList = new List<Transaction_Type__c>{otcPartSales, internetSales, layaway};
        DMLUtility.insertSobjectList('Transaction_Type__c', ttList);
    }

	global static void updateQuoteTransactionType() {
        List<Transaction_Type__c> ttList = [SELECT Id FROM Transaction_Type__c WHERE Type__c = 'Quote' AND Code_Label__c = 'Quote' limit 1];
        if(ttList.size() > 0) {
            ttList[0].Code_Label__c = 'Quote Customer';
            ttList[0].Code__c = 'Quote Customer';
            update ttList[0];
        }
        List<Transaction_Type__c> ttListForThirdPartyQuote = [SELECT Id FROM Transaction_Type__c WHERE Type__c = 'Quote' AND Code_Label__c = 'Quote Third-Party' limit 1];
        if(ttListForThirdPartyQuote.size() == 0) {
            DMLUtility.insertSobjectList('Transaction_Type__c', new Transaction_Type__c(Code__c = 'Quote Third-Party', Type__c = 'Quote', Code_Label__c = 'Quote Third-Party', Default__c = false, Active__c = true));
        }
    } 

    global static void turnOffSyncFlagForTask() {
        
        List<Hours_Logged__c> hoursLoggedList = [SELECT Id, Available_For_Xero_Sync__c, Available_For_QB_Sync__c FROM Hours_Logged__c WHERE Task__c != NULL AND (Available_For_Xero_Sync__c = true OR Available_For_QB_Sync__c = true) LIMIT: SOQLUtil.getAvailableQueryRowsLimit()]; 
        for (Hours_Logged__c hoursLoggedRec : hoursLoggedList) {
            if(hoursLoggedRec.Available_For_Xero_Sync__c) {
                hoursLoggedRec.Available_For_Xero_Sync__c = false;
            }
            if(hoursLoggedRec.Available_For_QB_Sync__c) {
                hoursLoggedRec.Available_For_QB_Sync__c = false;
            }
        }
        if(hoursLoggedList.size() > 0) { 
            update hoursLoggedList;
        }
    }

    global static void enablePublishInFeedsOnStockUnit () {
        List<Customer_Owned_Unit__c> customerOwnedUnitList = [SELECT ID, Publish_in_feeds__c FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' AND Publish_in_feeds__c = false ];
        
        for(Customer_Owned_Unit__c customerOwnedUnitRec : customerOwnedUnitList) {
            customerOwnedUnitRec.Publish_in_feeds__c = true;
        }
        
        if (customerOwnedUnitList.size() > 0) {
            update customerOwnedUnitList;
        }
    }
    
    global static void updateSpecialOrderStatusOnSOHeader() {}
    
    global static void updateHerokuEndPointInFTPConfig() {
    	List<FTP_Config__c> ftpConfigList = [SELECT FTP_URL__c, FTP_Username__c, FTP_Password__c, Org_Name__c, Heroku_End_Point_URL__c FROM FTP_Config__c];
    	for(FTP_Config__c configRec: ftpConfigList) {
    		configRec.Heroku_End_Point_URL__c = 'https://blackpurl-som.herokuapp.com/FTPAPI/fetchAndPostFileToFTP';
    	}
    	if(ftpConfigList.size() > 0) {
    		update ftpConfigList;
    	}
    }

    global static void updateCheckoutTypeOnInvToThirdParty() {
    	List<CO_Invoice_Item__c> invItemList =[SELECT Id, CO_Invoice_Header__c, CO_Invoice_Header__r.AccountingId__c, CO_Invoice_Header__r.availForQBSync__c, 
    		CO_Invoice_Header__r.Xero_Accounting_Id__c, CO_Invoice_Header__r.Available_For_Xero_Sync__c, 
    		CO_Invoice_Header__r.Closed_Invoice_Date__c,CO_Invoice_Header__r.Checkout_Type__c, 
    		Is_Invoiceable__c, SO_Payment_Role__c, isActive__c FROM CO_Invoice_Item__c where CO_Invoice_Header__r.Status__c = 'Closed' and 
    		SO_Payment_Role__r.RecordType.DeveloperName = 'Third_Party' AND CO_Invoice_Header__r.Checkout_Type__c != 'Third-Party'];

		List<CO_Invoice_Header__c> inHeaderListToUpdate = new List<CO_Invoice_Header__c>();
		for(CO_Invoice_Item__c invItemRec : invItemList) {
			CO_Invoice_Header__c invRec = new CO_Invoice_Header__c(Id = invItemRec.CO_Invoice_Header__c);
			invRec.Checkout_Type__c = 'Third-Party';
			if(QBUtil.isQBEnabled() && invItemRec.CO_Invoice_Header__r.AccountingId__c != null) {
				invRec.availForQBSync__c = true;
			} else if(XeroUtility.isXeroEnabled() && invItemRec.CO_Invoice_Header__r.Xero_Accounting_Id__c != null) {
				invRec.Available_For_Xero_Sync__c = true;
			}
			inHeaderListToUpdate.add(invRec);
		}
		
		update inHeaderListToUpdate;
    }

    global static void setBaseTypeDUPCDescription() {
        List<Deal_Unit_Price_Cost__c> dupcList = [Select Id, Item_Description__c FROM Deal_Unit_Price_Cost__c Where Type__c = 'Base' AND Item_Description__c != null AND Item_Description__c != 'Base - Unit' AND Item_Description__c != 'Base Unit'];
        for(Deal_Unit_Price_Cost__c dupcRec : dupcList) {
            dupcRec.Item_Description__c = Constants.BASE_UNIT;
        }
        
        if(dupcList.size() > 0) {
            DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = true;
            update dupcList;
            DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = false;
        }
    }
	
    global static void updateCompletedFlagOnCountSession() {
    	List<Count_Session__c> countSessionList =[SELECT Id, Is_Creation_Completed__c FROM Count_Session__c ];

		for(Count_Session__c csRec : countSessionList) {
			csRec.Is_Creation_Completed__c = true;
		}
        if(countSessionList.size() > 0) {
            CountSessionTriggerHelper.isForceStopTrigger = true;
            update countSessionList;
            CountSessionTriggerHelper.isForceStopTrigger = false;
        }
    }
    
	global static void cleanUpMakeModelSubmodel() {
        Database.executeBatch(new CleanUpMakeModelSubmodelBatch(), 1);
	}
	
    global static void updatePaymentMethodUndepositedFunds() {
        String updepositedFunds = Accounting_Default_Accounts__c.getOrgDefaults().Undeposited_Funds__c;
        if(String.isNotBlank(updepositedFunds)) {
            List<Payment_Method__c> paymentMethodList = [SELECT Id, Undeposited_Funds__c FROM Payment_Method__c];
            for(Payment_Method__c paymentMethodRec : paymentMethodList) {
                paymentMethodRec.Undeposited_Funds__c = updepositedFunds;
            }
            if(paymentMethodList.size() > 0) {
                update paymentMethodList;
            }
        }
    }
    
    global static void enableIncomingMessageFeature() {
    	//Update Message History
    	List<Message_History__c> messageHistoryList = [SELECT Id, SMS_Direction__c, SMS_Sent_From__c from Message_History__c WHERE Activity__c = 'Text Message' AND 
    													SMS_Direction__c = null LIMIT: SOQLUtil.getAvailableQueryRowsLimit()];
    	for(Message_History__c msgRec : messageHistoryList) {
    		msgRec.SMS_Direction__c = 'Sent';
    		msgRec.SMS_Sent_From__c = 'Customer';
    	}
    	
    	update messageHistoryList;
    	enableSpecifiedPermissionForAdminGroup(new Map<String, String>{'View_Incoming_Text_Messages__c' => 'Primary'});
    }
    
    global static void enableSpecifiedPermissionForAdminGroup(Map<String, String> permissionNameToValueMap) {
    	String query = 'SELECT Id FROM User_Group__c WHERE Is_System_Created__c = true ';
    	if(permissionNameToValueMap != null) {
	    	for(String permissionName : permissionNameToValueMap.keySet()) {
	    		query += ' AND ' + permissionName + ' = null ';
	    	}
    	}
    	List<User_Group__c> userGroupList = Database.query(query);
        if(userGroupList.size() > 0) {
        	for(String permissionName : permissionNameToValueMap.keySet()) {
	    		userGroupList[0].put(permissionName, permissionNameToValueMap.get(permissionName));
	    	}
            update userGroupList;
        }
    } 

    global static void setOrderUnitDates() {
    	List<Customer_Owned_Unit__c> orduList = [SELECT Id, CreatedDate, Status__c, Stocked_In_DateTime__c from Customer_Owned_Unit__c 
													WHERE Unit_Type__c = 'ORDU' AND (Date_Ordered__c = null OR Date_Expected__c = null)];
    	for(Customer_Owned_Unit__c orduRec : orduList) {
    		orduRec.Date_Expected__c = orduRec.Date_Ordered__c = orduRec.CreatedDate.date();
    		if((String.isNotBlank(orduRec.Status__c) && orduRec.Status__c == 'Received') && orduRec.Stocked_In_DateTime__c != null) {
    			orduRec.Date_Expected__c = orduRec.Stocked_In_DateTime__c.date();
    		}
    	}
    	if(orduList.size() > 0) {
    		update orduList;
    	}
    }

    global static void reSyncLaborDealJE() {
        Set<String> invoiceIdSet = new Set<String>();
    	List<Option_Fee__c> laborOptionFeeList = [Select Deal__r.Invoice_Number__c, Deal__r.Invoice_Number__r.CreatedDate, Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.CreatedDate from Option_Fee__c where Labour_Code__c != null AND Deal__r.Invoice_Number__c != null AND Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c != null limit: SOQLUtil.getAvailableQueryRowsLimit()];
        for(Option_Fee__c optionFeeRec : laborOptionFeeList) {
            if(optionFeeRec.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.CreatedDate < optionFeeRec.Deal__r.Invoice_Number__r.CreatedDate) {
                invoiceIdSet.add(optionFeeRec.Deal__r.Invoice_Number__r.Id);
            }
        }

        List<CO_Invoice_Header__c> dealInvoiceList = new List<CO_Invoice_Header__c>();
        for(String invId : invoiceIdSet) {
            if(QBUtil.isQBEnabled()) {
                dealInvoiceList.add(new CO_Invoice_Header__c(Id = invId, availForQBJournalEntrySync__c = true));
            } else if(XeroUtility.isXeroEnabled()) {
                dealInvoiceList.add(new CO_Invoice_Header__c(Id = invId, Available_For_Xero_CO_Invoice_JE_Sync__c = true));
            }
        }

        if(dealInvoiceList.size() > 0) {
            update dealInvoiceList;
        }
    }

    global static CO_Invoice_Header__c calculateInvoiceTotals(String coInvoiceId, Boolean isUpdate) {
        CO_Invoice_Header__c coInvoice = COService.getInvoiceRec(coInvoiceId);
        coInvoice = COService.calculateInvoiceTotals(new List<CO_Invoice_Header__c>{coInvoice}, false);        
        if(isUpdate) {
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvoice);
        }
        return coInvoice; 
    }
                        
    global static void setShopifyConfiguration() {
    	String baseURL = 'https://store.myshopify.com/admin/';
    	Shopify_Configuration__c config = Shopify_Configuration__c.getOrgDefaults();
    	config.Audience__c = 'https://api.super-connectors.com';
    	config.Product_Base_URL__c = baseURL + 'products/';
    	config.Customer_Base_URL__c = baseURL + 'customers/';
    	config.Order_Base_URL__c = baseURL + 'orders/';
        config.Product_Sku_Mapping_Field__c	= 'SKU_Number__c';
        DMLUtility.upsertSobjectList('Shopify_Configuration__c', config);
    }
    
    global static void populateTradeInTaxTotalOnDealAndInvoiceHeader() {
    	Map<String, Deal__c> dealIdToRecMap = new Map<String, Deal__c>([Select Id, Invoice_Number__c, 
    			(Select Type__c, Deal__c, Agreed_Value__c, Default_Unit_Sales_Tax_Percentage__c from Deal_Items__r where Type__c = 'Trade In') 
    			from Deal__c where Trade_In_Tax_Total__c = null limit: Limits.getLimitDMLRows()]);
	   
		List<CO_Invoice_header__c> coInvList = new List<CO_Invoice_header__c>();   
		for(String dealId : dealIdToRecMap.keySet()) {
			Decimal tradeInTaxTotal = 0;
			for(Deal_Item__c dealItemRec : dealIdToRecMap.get(dealId).Deal_Items__r) {
				dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c.setScale(2, RoundingMode.HALF_UP) : 0;
				dealItemRec.Default_Unit_Sales_Tax_Percentage__c = (dealItemRec.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItemRec.Default_Unit_Sales_Tax_Percentage__c : 0;
				
				Decimal tradeInTax = 0;
				if(!GeneralConfiguration.getTaxIncludingPricing()) {
					tradeInTax = ((dealItemRec.Agreed_Value__c * dealItemRec.Default_Unit_Sales_Tax_Percentage__c)/100).setScale(2, RoundingMode.HALF_UP);
				} else {
					tradeInTax = (dealItemRec.Agreed_Value__c - (dealItemRec.Agreed_Value__c / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP);
				}
				tradeInTaxTotal += tradeInTax;
			}
			dealIdToRecMap.get(dealId).Trade_In_Tax_Total__c = tradeInTaxTotal.setScale(2, RoundingMode.HALF_UP);
			if(dealIdToRecMap.get(dealId).Invoice_Number__c != null) {
				coInvList.add(new CO_Invoice_header__c(Id = dealIdToRecMap.get(dealId).Invoice_Number__c, Trade_In_Tax_Total__c = tradeInTaxTotal.setScale(2, RoundingMode.HALF_UP)));
			}
		}
		
		DealTriggerHelper.isForceStopTrigger = true;
		COInvoiceTriggerHelper.isForceStopTrigger = true;
		update coInvList;
		update dealIdToRecMap.values();
		DealTriggerHelper.isForceStopTrigger = false;
		COInvoiceTriggerHelper.isForceStopTrigger = false;
	}
	
    global static void createVendorMasterRecordForBRP() {
        String brpVendorId = BRPUtility.getBRPVendorIdForPartsMaster();
        Vendor_Master__c vendorMasterToInsert = new Vendor_Master__c();
        if(brpVendorId != null) {
            vendorMasterToInsert.Blackpurl_Vendor__c = brpVendorId;
            vendorMasterToInsert.Vendor_Name__c = 'Integrated BRP parts master';
            vendorMasterToInsert.Vendor_Master_Type__c = 'BRP Parts Master';
            vendorMasterToInsert.Part_Num__c = true;
            vendorMasterToInsert.Description_EN__c = true;
            vendorMasterToInsert.Price_New__c = 'MSRP';
            vendorMasterToInsert.Cost_New__c = 'Dealer Invoice';
            vendorMasterToInsert.Pkg_Qty__c = true;
            vendorMasterToInsert.Replaced_By__c = true;
            vendorMasterToInsert.Category__c = 'vehicle,engine,parts,accessories,clothing,licensing & play,trailer,rebuilt,oils & chemicals';
            DMLUtility.insertSobjectList('Vendor_Master__c', vendorMasterToInsert);
        } else {
            throw new BlackPurlException('Parts Master vendor is not defined.');
        }
    }

    global static void updateCategoryListForBRPVendorMaster() {
        List<Vendor_Master__c> vmList = [SELECT Id FROM Vendor_Master__c WHERE Vendor_Name__c = 'Integrated BRP parts master'];
        if(!vmList.isEmpty()) {
            vmList[0].Category__c = 'vehicle,engine,parts,accessories,clothing,licensing & play,trailer,rebuilt,oils & chemicals';
            DMLUtility.updateSobjectList('Vendor_Master__c', vmList);
        }
    }
	
	global static void populateClaimSubmitedDate() {
        List<Service_Order_Header__c> soList = [Select Claim_Submitted_At__c, (Select CreatedDate from Claims__r) from Service_Order_Header__c 
        		where Id IN (Select Service_Order_Header__c from Claim__c) AND Claim_Submitted_At__c = null LIMIT: SOQLUtil.getAvailableQueryRowsLimit()];
		
		for(Service_Order_Header__c soRec : soList) {
			soRec.Claim_Submitted_At__c = soRec.Claims__r[0].CreatedDate;
		}
		SOTriggerHelper.isForceStopTrigger = true;
		update soList;
		SOTriggerHelper.isForceStopTrigger = false;
	}
	
	global static void syncChartOfAccounts(String activeAccIntegrationName) {
		if(String.isBlank(activeAccIntegrationName)) {
    		activeAccIntegrationName = AccountingUtil.activeAccIntegrationName;
		}
    	if(String.isNotBlank(activeAccIntegrationName)) {
    		if(activeAccIntegrationName.containsIgnoreCase('QuickBooks')) {
    			AccountingIntegrationSettingsCtrl.syncAccounts();
    		} else if(activeAccIntegrationName.containsIgnoreCase('Xero')) {
    			AccountingIntegrationSettingsCtrl.getChartOfAccounts(BPUtility.getEncodedString('Xero'));
    		}
    	}
    }
    
    private static Map<String, Map<String, Set<String>>> integrationNameToFieldNameToValueMap = 
		new Map<String, Map<String, Set<String>>>{
			 QBUtil.QUICKBOOKS_ONLINE => new Map<String, Set<String>>{'Account Type' => new Set<String>{'Accounts receivable', 'Accounts payable', 'Credit Card'}, 
														'Detail Type' => new Set<String>{'AccumulatedDepreciation', 'Chequing', 'Checking', 
																'Savings', 'MoneyMarket', 'TrustAccounts'}
			 },
			 XeroUtility.XERO => new Map<String, Set<String>>{'Account Type' => new Set<String>{'Bank', 'Inventory'}, 
													'Account Name' => new Set<String>{'Accounts Receivable', 'Accounts Payable', 'Retained Earnings'}
			}											
	};
    		
	global static void createCOARestrictedConfigs() {
		List<COA_Restriction_Config__c> coaRestrictionConfigList = new List<COA_Restriction_Config__c>();
    		
		for(String integrationName : integrationNameToFieldNameToValueMap.keySet()) {
			for(String fieldName : integrationNameToFieldNameToValueMap.get(integrationName).keySet()) {
				for(String fieldValue : integrationNameToFieldNameToValueMap.get(integrationName).get(fieldName)) {
	    			coaRestrictionConfigList.add(createCOARestrictionConfig(integrationName, fieldName, fieldValue));
				}
	        }
		}
		if(coaRestrictionConfigList.size() > 0) {
            DMLUtility.insertSobjectList('COA_Restriction_Config__c', coaRestrictionConfigList);
		}
    }
    
    public static COA_Restriction_Config__c createCOARestrictionConfig(String integrationName, String fieldName, String fieldValue) {
    	COA_Restriction_Config__c coaConfig = new COA_Restriction_Config__c();
    	coaConfig.Integration_Name__c = integrationName;
		coaConfig.Field_Name__c = fieldName;
		coaConfig.Field_Value__c = fieldValue;
		return coaConfig;
    }

    global static void updateVRTotalReceivedQuantity() {
        Database.executeBatch(new UpdateVRTotalReceivedQuantityBatch(), 1);
    }

    global static void addDealUnitCostPriceForOrderedUnits(Integer limitNumber) {
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        if(limitNumber == 0) {
            dealItemList  = [SELECT Id, Customer_Owned_Unit__r.Id FROM Deal_Item__c WHERE Deal__r.Invoice_Number__c = null AND Customer_Owned_Unit__r.Unit_Type__c = 'ORDU' AND Id NOT IN (SELECT Deal_Item__c FROM Deal_Unit_Price_Cost__c  Where Deal_Item__r.Deal__r.Invoice_Number__c = null AND  Deal_Item__r.Customer_Owned_Unit__r.Unit_Type__c = 'ORDU') ];
        } else {
            dealItemList  = [SELECT Id, Customer_Owned_Unit__r.Id FROM Deal_Item__c WHERE Deal__r.Invoice_Number__c = null AND Customer_Owned_Unit__r.Unit_Type__c = 'ORDU' AND Id NOT IN (SELECT Deal_Item__c FROM Deal_Unit_Price_Cost__c Where Deal_Item__r.Deal__r.Invoice_Number__c = null AND  Deal_Item__r.Customer_Owned_Unit__r.Unit_Type__c = 'ORDU') ORDER by LastModifiedDate ASC Limit :limitNumber];
        }
        Set<Id> unitIdSet = new Set<Id>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            unitIdSet.add(dealItemRec.Customer_Owned_Unit__r.Id);
        }
        Map<String, List<Deal_Unit_Price_Cost__c>> optionTypeToDealUnitPriceCostListMap = new Map<String, List<Deal_Unit_Price_Cost__c>>();
        Map<String, List<Unit_Price_Cost__c>> unitIdToUPCListMap = DealService.getUnitIdToUPCListMap(unitIdSet);
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(unitIdToUPCListMap.containsKey(dealItemRec.Customer_Owned_Unit__r.Id)) {
	            for(Unit_Price_Cost__c unitPriceCostRec : unitIdToUPCListMap.get(dealItemRec.Customer_Owned_Unit__r.Id)) {
	                if(unitPriceCostRec.Type__c != 'Base' || !optionTypeToDealUnitPriceCostListMap.containsKey('Base')) {
	                    Deal_Unit_Price_Cost__c dealUnitPriceCostRec = DealService.setFieldsToDealUnitPriceCost(unitPriceCostRec, dealItemRec.Id);
	                    if(!optionTypeToDealUnitPriceCostListMap.containsKey(dealUnitPriceCostRec.Type__c)) {
	                        optionTypeToDealUnitPriceCostListMap.put(dealUnitPriceCostRec.Type__c, new List<Deal_Unit_Price_Cost__c>{});
	                    }
	                    optionTypeToDealUnitPriceCostListMap.get(dealUnitPriceCostRec.Type__c).add(dealUnitPriceCostRec);
	                } else {
	                    optionTypeToDealUnitPriceCostListMap.get('Base')[0].Price__c += (unitPriceCostRec.Total_Price__c != null ? unitPriceCostRec.Total_Price__c : 0);
	                    if(GeneralConfiguration.getTaxIncludingPricing()) {
	                		optionTypeToDealUnitPriceCostListMap.get('Base')[0].Price_When_Tax_Included__c += (unitPriceCostRec.Total_Price__c != null ? unitPriceCostRec.Total_Price__c : 0);
	                	}
	                }
	            }
            } 
        }
        List<Deal_Unit_Price_Cost__c> dealUnitPriceCostList = new List<Deal_Unit_Price_Cost__c>();
        for(String optionType : optionTypeToDealUnitPriceCostListMap.keySet()) {
        dealUnitPriceCostList.addAll(optionTypeToDealUnitPriceCostListMap.get(optionType));
        }

         if(dealUnitPriceCostList.size() > 0) {
            DMLUtility.insertSobjectList('Deal_Unit_Price_Cost__c', dealUnitPriceCostList);
        } 
    }

    global static void createIFWConfigForBRPAuth2() {
        if(BRPUtility.isBRPEnabled()) { 
            IFW_IntegrationConfig__c IFWIntegrationConfigObj = new IFW_IntegrationConfig__c();
            IFWIntegrationConfigObj.Integration_Name__c = 'BRP OAuth2.0';
            IFWIntegrationConfigObj.Auth_Scheme__c = 'OAuth2.0';
            IFWIntegrationConfigObj.Enabled__c = true;
            DMLUtility.insertSobjectList('IFW_IntegrationConfig__c', IFWIntegrationConfigObj);
        }
    }
    
    global static void createCustomerDepositsSpecialCategory() {
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Category__c> defaultCategoryList = [SELECT Id, Type__c FROM Category__c WHERE Default__c = true AND Active__c = true AND Type__c = 'Customer Deposits'];
        
        if(defaultCategoryList.size() == 0) {
            DMLUtility.insertSobjectList('Category__c', new Category__c(Name = 'Customer Deposits Default', Description__c = 'Customer Deposits Default',
                                    Type__c = 'Customer Deposits', Default__c = true, Active__c = true, 
                                                                        Income_GL__c = Accounting_Default_Accounts__c.getOrgDefaults().Customer_Deposits__c));
        }
    }

    global static void recalculateKitDistribution() {
        List<Kit_Header__c> kitHeaderList = [Select Fixed_Price_Flag__c, Fixed_Price__c From Kit_Header__c Where Fixed_Price_Flag__c = true];
        if(kitHeaderList.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            KitHeaderTriggerHelper.IsForceKitDistributionCalculation = true;
            update kitHeaderList;
            KitHeaderTriggerHelper.IsForceKitDistributionCalculation = false;
        }
    }

    global static void updateWIPLaborGLForDisabledTechCosting() {
        if(!GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
            Accounting_Default_Accounts__c accDefaultConfigRec = Accounting_Default_Accounts__c.getOrgDefaults();
            accDefaultConfigRec.WIP_Labor_Inventory__c = accDefaultConfigRec.WIP_Labor_Expense__c;
            update accDefaultConfigRec;
        }
    }
    
    global static void createPreferredPaymentMaxCreditAmountConfig() {
        if(GeneralConfiguration.isPreferredPaymentIntegrationEnabled()) {
            List<Configuration_List__c> maxCreditAmountConfigList = [Select Id From Configuration_List__c Where Name = 'Max Credit Amount' Limit 1];
            if(maxCreditAmountConfigList.size() == 0) {
                insert new Configuration_List__c (Name = 'Max Credit Amount', Value__c = '1000');
            }
        }
    }

    global static void convertBRPIFWConfigs() {}

    global static void createBRP2IFWConfigs() {
        String brp2IFWConfigRecId; 
        List<IFW_IntegrationConfig__c> brp2IFWConfigList = BaseIntegration.getIFWConfigByName(new List<String>{BRPUtility.BRP_2});
        if(brp2IFWConfigList.isEmpty()) {
            List<IFW_IntegrationConfig__c> brpDMSOauth2IFWConfigList = BaseIntegration.getIFWConfigByName(new List<String>{BRPUtility.BRP_DMS_OAUTH2});
            if(brpDMSOauth2IFWConfigList.size() > 0) {
                IFW_IntegrationConfig__c brp2IFWConfigRec = brpDMSOauth2IFWConfigList[0].clone(false, true, false, false);
                brp2IFWConfigRec.Integration_Name__c = BRPUtility.BRP_2;
                insert brp2IFWConfigRec;
                brp2IFWConfigRecId = brp2IFWConfigRec.Id;
            }
        } else {
            brp2IFWConfigRecId = brp2IFWConfigList[0].Id;
        }
        
        List<IFW_IntegrationConfigItem__c> configItemList = [SELECT Entity_Name__c, Endpoint_URL__c from IFW_IntegrationConfigItem__c WHERE IFW_IntegrationConfig__c =: brp2IFWConfigRecId];
        delete configItemList;
        
        List<IFW_IntegrationConfigItem__c> ifwItemListToInsert = new List<IFW_IntegrationConfigItem__c>();
        Map<String, Map<String, String>> entityNameToIFWItemMap = BRPUtility.entityNameToFieldNameToValueMapForOAUth2IFW;
        for(String entityName: entityNameToIFWItemMap.keySet()) {
            IFW_IntegrationConfigItem__c ifwConfigItem = new IFW_IntegrationConfigItem__c(IFW_IntegrationConfig__c = brp2IFWConfigRecId);
            Map<String, String> fieldNameToValueMap = entityNameToIFWItemMap.get(entityName);
            for(String fieldName: fieldNameToValueMap.keySet()) {
                String fieldValue = fieldNameToValueMap.get(fieldName);
                if(fieldName.contains('Endpoint_URL__c') && (Constants.NAMESPACE).equalsIgnoreCase('BlackPurlCore__')) {
                    if(entityName == 'GetArticle' || entityName == 'GetCampaigns') {
                        fieldValue = fieldValue.replace('ms-brp-proxy-5niqfavtya-uc', 'ms-brp-proxy-zu6w3drdfa-uc');
                    } else {
                        fieldValue = fieldValue.replace('qa-', '');
                    }
                }
                ifwConfigItem.put(fieldName, fieldValue);
            }
            ifwItemListToInsert.add(ifwConfigItem);
        }
        insert ifwItemListToInsert;
    }

    global static void createBRPDealerAuthConfigs() {
        String brpDealerIFWConfigRecId; 
        List<IFW_IntegrationConfig__c> brpDealerIFWConfigList = BaseIntegration.getIFWConfigByName(new List<String>{BRPUtility.BRP_DEALER_AUTH});
        if(brpDealerIFWConfigList.isEmpty()) {
            List<IFW_IntegrationConfig__c> brpOauth2IFWConfigList = BaseIntegration.getIFWConfigByName(new List<String>{BRPUtility.BRP_OAUTH2});
            if(brpOauth2IFWConfigList.size() > 0) {
                IFW_IntegrationConfig__c brpDealerIFWConfigRec = brpOauth2IFWConfigList[0].clone(false, true, false, false);
                brpDealerIFWConfigRec.Integration_Name__c = BRPUtility.BRP_DEALER_AUTH;
                insert brpDealerIFWConfigRec;
                brpDealerIFWConfigRecId = brpDealerIFWConfigRec.Id;
            }
        } else {
            brpDealerIFWConfigRecId = brpDealerIFWConfigList[0].Id;
        }
        
        List<IFW_IntegrationConfigItem__c> configItemList = [SELECT Entity_Name__c, Endpoint_URL__c from IFW_IntegrationConfigItem__c WHERE IFW_IntegrationConfig__c =: brpDealerIFWConfigRecId];
        delete configItemList;
        
        List<IFW_IntegrationConfigItem__c> ifwItemListToInsert = new List<IFW_IntegrationConfigItem__c>();
        Map<String, Map<String, String>> entityNameToIFWItemMap = BRPUtility.entityNameToFieldNameToValueMapForDealerAuth;
        for(String entityName: entityNameToIFWItemMap.keySet()) {
            IFW_IntegrationConfigItem__c ifwConfigItem = new IFW_IntegrationConfigItem__c(IFW_IntegrationConfig__c = brpDealerIFWConfigRecId);
            Map<String, String> fieldNameToValueMap = entityNameToIFWItemMap.get(entityName);
            for(String fieldName: fieldNameToValueMap.keySet()) {
                String fieldValue = fieldNameToValueMap.get(fieldName);
                ifwConfigItem.put(fieldName, fieldValue);
            }
            ifwItemListToInsert.add(ifwConfigItem);
        }
        insert ifwItemListToInsert;
    }
    
    global static void createBRP2QAIFWConfigs() {
        List<IFW_IntegrationConfig__c> brp2QAIFWConfigList = BaseIntegration.getIFWConfigByName(new List<String>{BRPUtility.BRP_2_QA});
        if(!brp2QAIFWConfigList.isEmpty()) {
            DMLUtility.deleteSobjectList('IFW_IntegrationConfig__c', brp2QAIFWConfigList);
        } 
        IFW_IntegrationConfig__c brp2QAIFWConfigRec = new IFW_IntegrationConfig__c();
        brp2QAIFWConfigRec.Integration_Name__c = BRPUtility.BRP_2_QA;
        brp2QAIFWConfigRec.Enabled__c = true;
        brp2QAIFWConfigRec.Auth_Scheme__c = 'OAuth2.0';
        brp2QAIFWConfigRec.Client_Id__c = 'K60mYH8mcbsYxxzKomIJTKt11uhGNwUz';
        brp2QAIFWConfigRec.Client_Secret__c = 'EQVTDmAWVNC3aP2K';
        DMLUtility.insertSobjectList('IFW_IntegrationConfig__c', brp2QAIFWConfigRec);

        List<IFW_IntegrationConfigItem__c> ifwItemListToInsert = new List<IFW_IntegrationConfigItem__c>();
        IFW_IntegrationConfigItem__c retailTransactionIFWItem = new IFW_IntegrationConfigItem__c();
        retailTransactionIFWItem.IFW_IntegrationConfig__c = brp2QAIFWConfigRec.Id;
        retailTransactionIFWItem.Entity_Name__c = BRPUtility.RETAIL_TRANSACTIONS;
        retailTransactionIFWItem.HTTP_Method__c = 'POST';
        retailTransactionIFWItem.Endpoint_URL__c = 'https://qa-cloud-api.brp.com/dcp/v4/dealer/{{dealer_no}}/retail-transactions';
        ifwItemListToInsert.add(retailTransactionIFWItem);

        IFW_IntegrationConfigItem__c tokenIFWItemToInsert = new IFW_IntegrationConfigItem__c();
        tokenIFWItemToInsert.IFW_IntegrationConfig__c = brp2QAIFWConfigRec.Id;
        tokenIFWItemToInsert.Entity_Name__c = 'Token';
        tokenIFWItemToInsert.HTTP_Method__c = 'POST';
        tokenIFWItemToInsert.Endpoint_URL__c = 'https://qa-cloud-api.brp.com/dcp/authentication/app/token';
        ifwItemListToInsert.add(tokenIFWItemToInsert);

        DMLUtility.insertSobjectList('IFW_IntegrationConfigItem__c', ifwItemListToInsert);
    }
}