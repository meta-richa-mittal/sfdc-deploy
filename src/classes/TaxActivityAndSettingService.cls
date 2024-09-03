/**
 * Author: Nidhi Sharma
 * Since: March 26, 2024
 * Name: TaxActivityAndSettingCtrl
 * Description: 
**/
public without sharing class TaxActivityAndSettingService {
    
    public static final String NON_TAXABLE_SALES = 'Non Taxable Sales';
    public static final String NON_TAXABLE_PURCHASES = 'Non Taxable Purchases';
    public static final String CO_INVOICE = 'Customer Invoice';
    public static final String VO_INVOICE = 'Vendor Invoice';
    public static final String UNIT_INVOICE = 'Unit Invoice';
    public static final String VENDOR_CREDIT = 'Vendor Credit';
    public static final String UNIT_ADJUSTMENT = 'Unit Adjustment';

    public static TaxActivityDetailWrapper getTaxActivityReportByEntityName(String filterJson) {
        TaxActivityDetailWrapper taxActivityObj;
        if(String.isNotBlank(filterJson)) {
            TaxActivityDetailWrapper.ActivityReportFilterWrapper filterObj = (TaxActivityDetailWrapper.ActivityReportFilterWrapper) System.JSON.deserialize(filterJson, TaxActivityDetailWrapper.ActivityReportFilterWrapper.class);
            if(String.isNotBlank(filterObj.entityName) && filterObj.entityName.equalsIgnoreCase(CO_INVOICE)) {
                taxActivityObj = getCOInvoiceActivityReport(filterObj);
            }
            if(String.isNotBlank(filterObj.entityName) && filterObj.entityName.equalsIgnoreCase(VO_INVOICE)) {
                taxActivityObj = getVOInvoiceActivityReport(filterObj);
            }
            if(String.isNotBlank(filterObj.entityName) && filterObj.entityName.equalsIgnoreCase(UNIT_INVOICE)) {
                taxActivityObj = getUnitInvoiceActivityReport(filterObj);
            }
            if(String.isNotBlank(filterObj.entityName) && filterObj.entityName.equalsIgnoreCase(VENDOR_CREDIT)) {
                taxActivityObj = getVendorCreditActivityReport(filterObj);
            }
            if(String.isNotBlank(filterObj.entityName) && filterObj.entityName.equalsIgnoreCase(UNIT_ADJUSTMENT)) {
                taxActivityObj = getUnitAdjustmentActivityReport(filterObj);
            }
        }

        return taxActivityObj;
    }

    private static TaxActivityDetailWrapper getVendorCreditActivityReport(TaxActivityDetailWrapper.ActivityReportFilterWrapper filterObj) {
        DateTime fromDate = HomeSearchFilterInterface.getDateFromString(filterObj.startDate);
        DateTime toDate = HomeSearchFilterInterface.getDateFromString(filterObj.endDate);
        toDate = toDate.addDays(1);

        String query = 'Select Credited_Date__c, Credit_Memo__c, Vendor__r.Name, Vendor__r.Purchase_Tax__c, Item_Total__c, Other_Charges_Total__c, ' +
        '(Select Id, Is_Taxable__c, Cost__c FROM Other_Charges__r WHERE Is_Taxable__c = false) ' +
        'from Return_CR_Header__c WHERE Vendor__r.Purchase_Tax__c != null AND Status__c = \'Credited\'';
        query += ' AND Credited_Date__c >= ' + fromDate.format('yyyy-MM-dd') + ' AND Credited_Date__c < ' + toDate.format('yyyy-MM-dd');
        query += ' Order BY Credited_Date__c, Credit_Memo__c';
        Map<Id, Return_CR_Header__c> vendorCreditMap = new Map<Id, Return_CR_Header__c>((List<Return_CR_Header__c>)Database.query(query));

        Set<Id> purchaseTaxIds = new Set<Id>();
        for(Return_CR_Header__c vendorCreditRec : vendorCreditMap.values()) {
            purchaseTaxIds.add(vendorCreditRec.Vendor__r.Purchase_Tax__c);
        }
        Map<Id, List<Sales_Tax_Item__c>> taxCodeIdToRatesMap = getTaxCodeIdToRatesMapByTaxIds(purchaseTaxIds);
        TaxActivityDetailWrapper taxActivityObj = new  TaxActivityDetailWrapper();
        Map<String, TaxActivityDetailWrapper.TaxWrapper> taxWrapperMap = new Map<String, TaxActivityDetailWrapper.TaxWrapper>();
        
        for(Return_CR_Header__c vendorCreditRec : vendorCreditMap.values()) {
            vendorCreditRec.Item_Total__c = (vendorCreditRec.Item_Total__c != null ? vendorCreditRec.Item_Total__c : 0);
            vendorCreditRec.Other_Charges_Total__c = (vendorCreditRec.Other_Charges_Total__c != null ? vendorCreditRec.Other_Charges_Total__c : 0);
            Decimal nonTaxableAmount = 0;
            for(Other_Charges__c otherCharge : vendorCreditRec.Other_Charges__r) {
                if(!otherCharge.Is_Taxable__c) nonTaxableAmount += (otherCharge.Cost__c != null ? otherCharge.Cost__c : 0); 
            }
            Decimal taxableAmount = (vendorCreditRec.Item_Total__c + (vendorCreditRec.Other_Charges_Total__c - nonTaxableAmount));
            Decimal totalTaxAmount = 0;
            if(taxCodeIdToRatesMap.containsKey(vendorCreditRec.Vendor__r.Purchase_Tax__c) && !taxCodeIdToRatesMap.get(vendorCreditRec.Vendor__r.Purchase_Tax__c).isEmpty()) {
                for(Sales_Tax_Item__c taxRate : taxCodeIdToRatesMap.get(vendorCreditRec.Vendor__r.Purchase_Tax__c)) {
                    Decimal taxAmount = ((taxRate.Rate__c * taxableAmount) / 100).setScale(2, RoundingMode.HALF_UP);
                    String taxNameFormatted = taxRate.Name__c.trim().toLowerCase();
                    TaxActivityDetailWrapper.TaxWrapper  taxObj = getTaxWrapperObj(taxWrapperMap.get(taxNameFormatted), taxRate.Name__c, taxableAmount, taxAmount, 0);
                    taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(vendorCreditRec, taxableAmount, taxRate.Rate__c, taxAmount, 0));
                    taxWrapperMap.put(taxNameFormatted, taxObj);
                    totalTaxAmount += taxAmount;
                }
            } else {
                nonTaxableAmount = (vendorCreditRec.Item_Total__c + vendorCreditRec.Other_Charges_Total__c);
            }
            if(nonTaxableAmount != 0) {
                TaxActivityDetailWrapper.TaxWrapper taxObj = getTaxWrapperObj(
                        taxWrapperMap.get(NON_TAXABLE_PURCHASES), NON_TAXABLE_PURCHASES, 0, 0, nonTaxableAmount);
                taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(vendorCreditRec, 0, 0, 0, nonTaxableAmount));
                taxWrapperMap.put(NON_TAXABLE_PURCHASES, taxObj);
            }
            taxActivityObj.PurchaseTaxActivityObj.TaxAmount += totalTaxAmount;
            taxActivityObj.PurchaseTaxActivityObj.TaxableAmount += taxableAmount;
            taxActivityObj.PurchaseTaxActivityObj.NonTaxableAmount += nonTaxableAmount;
        }
        taxActivityObj.PurchaseTaxActivityObj.TaxDetails = taxWrapperMap.values();
        return taxActivityObj;
    }

    private static TaxActivityDetailWrapper getUnitInvoiceActivityReport(TaxActivityDetailWrapper.ActivityReportFilterWrapper filterObj) {
        DateTime fromDate = HomeSearchFilterInterface.getDateFromString(filterObj.startDate);
        DateTime toDate = HomeSearchFilterInterface.getDateFromString(filterObj.endDate);
        toDate = toDate.addDays(1);
        
        String query = 'Select Date_Stocked_In__c, Referenced_Unit__r.Vendor__r.Name, Referenced_Unit__r.Total_Cost__c, ' +
        'Referenced_Unit__r.Invoice_Number__c, Referenced_Unit__r.Unit_Purchase_Tax__c, Referenced_Unit__r.Taxable_Cost__c ' +
        'from Customer_Owned_Unit__c WHERE Referenced_Unit__r.Unit_Purchase_Tax__c != null AND Unit_Type__c = \'STOCK\'';
        query += ' AND Date_Stocked_In__c >= ' + fromDate.format('yyyy-MM-dd') + ' AND Date_Stocked_In__c < ' + toDate.format('yyyy-MM-dd');
        query += ' Order BY Date_Stocked_In__c, Referenced_Unit__r.Invoice_Number__c';
        Map<Id, Customer_Owned_Unit__c> unitMap = new Map<Id, Customer_Owned_Unit__c>((List<Customer_Owned_Unit__c>)Database.query(query));
        
        Set<Id> purchaseTaxIds = new Set<Id>();
        for(Customer_Owned_Unit__c unitRec : unitMap.values()) {
            purchaseTaxIds.add(unitRec.Referenced_Unit__r.Unit_Purchase_Tax__c);
        }
        Map<Id, List<Sales_Tax_Item__c>> taxCodeIdToRatesMap = getTaxCodeIdToRatesMapByTaxIds(purchaseTaxIds);

        TaxActivityDetailWrapper taxActivityObj = new  TaxActivityDetailWrapper();
        Map<String, TaxActivityDetailWrapper.TaxWrapper> taxWrapperMap = new Map<String, TaxActivityDetailWrapper.TaxWrapper>();

        for(Customer_Owned_Unit__c unitRec : unitMap.values()) {
            Decimal taxableAmount = unitRec.Referenced_Unit__r.Taxable_Cost__c != null ? unitRec.Referenced_Unit__r.Taxable_Cost__c : 0;
            Decimal nonTaxableAmount = ((unitRec.Referenced_Unit__r.Total_Cost__c != null ? unitRec.Referenced_Unit__r.Total_Cost__c : 0) - taxableAmount);
            Decimal totalTaxAmount = 0;
            if(taxCodeIdToRatesMap.containsKey(unitRec.Referenced_Unit__r.Unit_Purchase_Tax__c) && !taxCodeIdToRatesMap.get(unitRec.Referenced_Unit__r.Unit_Purchase_Tax__c).isEmpty()) {
                for(Sales_Tax_Item__c taxRate : taxCodeIdToRatesMap.get(unitRec.Referenced_Unit__r.Unit_Purchase_Tax__c)) {
                    Decimal taxAmount = ((taxRate.Rate__c * taxableAmount) / 100).setScale(2, RoundingMode.HALF_UP);

                    String taxNameFormatted = taxRate.Name__c.trim().toLowerCase();
                    TaxActivityDetailWrapper.TaxWrapper  taxObj = getTaxWrapperObj(taxWrapperMap.get(taxNameFormatted), taxRate.Name__c, taxableAmount, taxAmount, 0);
                    taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(unitRec, taxableAmount, taxRate.Rate__c, taxAmount, 0));
                    taxWrapperMap.put(taxNameFormatted, taxObj);

                    totalTaxAmount += taxAmount;
                }
            } else {
                nonTaxableAmount = (unitRec.Referenced_Unit__r.Total_Cost__c != null ? unitRec.Referenced_Unit__r.Total_Cost__c : 0);
            }
            if(nonTaxableAmount != 0) {
                TaxActivityDetailWrapper.TaxWrapper taxObj = getTaxWrapperObj(
                        taxWrapperMap.get(NON_TAXABLE_PURCHASES), NON_TAXABLE_PURCHASES, 0, 0, nonTaxableAmount);
                taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(unitRec, 0, 0, 0, nonTaxableAmount));
                taxWrapperMap.put(NON_TAXABLE_PURCHASES, taxObj);
            }
            taxActivityObj.PurchaseTaxActivityObj.TaxAmount += totalTaxAmount;
            taxActivityObj.PurchaseTaxActivityObj.TaxableAmount += taxableAmount;
            taxActivityObj.PurchaseTaxActivityObj.NonTaxableAmount += nonTaxableAmount;
        }
        taxActivityObj.PurchaseTaxActivityObj.TaxDetails = taxWrapperMap.values();
        return taxActivityObj;
    }

    private static TaxActivityDetailWrapper getVOInvoiceActivityReport(TaxActivityDetailWrapper.ActivityReportFilterWrapper filterObj) {
        DateTime fromDate = HomeSearchFilterInterface.getDateFromString(filterObj.startDate);
        DateTime toDate = HomeSearchFilterInterface.getDateFromString(filterObj.endDate);
        toDate = toDate.addDays(1);
        
        String query = 'Select Taxable_Total__c, Non_Taxable_Total__c, Invoice_Date__c, Vendor_Invoice_Number__c, Vendor__r.Name, Sub_Total__c, ' +
        '(SELECT Tax_Rate__c, Sales_Tax_Item_Name__c, Sales_Tax_Item__r.Name__c FROM Individual_Taxes__r) from Vendor_Invoicing_Header__c WHERE Status__c = \'Invoiced\'';
        query += ' AND Invoice_Date__c >= ' + fromDate.format('yyyy-MM-dd') + ' AND Invoice_Date__c < ' + toDate.format('yyyy-MM-dd');
        query += ' Order BY Invoice_Date__c, Vendor_Invoice_Number__c';
        Map<Id, Vendor_Invoicing_Header__c> viMap = new Map<Id, Vendor_Invoicing_Header__c>((List<Vendor_Invoicing_Header__c>)Database.query(query));

        Map<String, Set<String>> voInvoiceIdToContentsMap = getVOInvoiceIdToContentsMap(viMap.keySet());
        
        TaxActivityDetailWrapper taxActivityObj = new  TaxActivityDetailWrapper();
        Map<String, TaxActivityDetailWrapper.TaxWrapper> taxWrapperMap = new Map<String, TaxActivityDetailWrapper.TaxWrapper>();

        for(Vendor_Invoicing_Header__c viRec : viMap.values()) {
            Decimal nonTaxableAmount = viRec.Non_Taxable_Total__c != null ? viRec.Non_Taxable_Total__c : 0;
            Decimal taxableAmount = viRec.Taxable_Total__c != null ? viRec.Taxable_Total__c : 0;
            Decimal totalTaxAmount = 0;
            if(!viRec.Individual_Taxes__r.isEmpty()) {
                for(Individual_Tax__c individualTax : viRec.Individual_Taxes__r) {
                    Decimal taxAmount = ((individualTax.Tax_Rate__c * taxableAmount) / 100).setScale(2, RoundingMode.HALF_UP);

                    String taxName = String.isNotBlank(individualTax.Sales_Tax_Item_Name__c) ? individualTax.Sales_Tax_Item_Name__c : individualTax.Sales_Tax_Item__r.Name__c;
                    String taxNameFormatted = taxName.trim().toLowerCase();
                    TaxActivityDetailWrapper.TaxWrapper  taxObj = getTaxWrapperObj(taxWrapperMap.get(taxNameFormatted), taxName, taxableAmount, taxAmount, 0);
                    taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(viRec, taxableAmount, individualTax.Tax_Rate__c, taxAmount, 0, voInvoiceIdToContentsMap.get(viRec.Id)));

                    taxWrapperMap.put(taxNameFormatted, taxObj);
                    totalTaxAmount += taxAmount;
                }
            } else {
                nonTaxableAmount = (viRec.Sub_Total__c != null ? viRec.Sub_Total__c : 0);
            }
            if(nonTaxableAmount != 0) {
                TaxActivityDetailWrapper.TaxWrapper taxObj = getTaxWrapperObj(
                        taxWrapperMap.get(NON_TAXABLE_PURCHASES), NON_TAXABLE_PURCHASES, 0, 0, nonTaxableAmount);
                taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(viRec, 0, 0, 0, nonTaxableAmount, voInvoiceIdToContentsMap.get(viRec.Id)));
                taxWrapperMap.put(NON_TAXABLE_PURCHASES, taxObj);
            }
            taxActivityObj.PurchaseTaxActivityObj.TaxAmount += totalTaxAmount;
            taxActivityObj.PurchaseTaxActivityObj.TaxableAmount += taxableAmount;
            taxActivityObj.PurchaseTaxActivityObj.NonTaxableAmount += nonTaxableAmount;
        }
        taxActivityObj.PurchaseTaxActivityObj.TaxDetails = taxWrapperMap.values();
        return taxActivityObj;
    }

    private static TaxActivityDetailWrapper getUnitAdjustmentActivityReport(TaxActivityDetailWrapper.ActivityReportFilterWrapper filterObj) {
        DateTime fromDate = HomeSearchFilterInterface.getDateFromString(filterObj.startDate);
        DateTime toDate = HomeSearchFilterInterface.getDateFromString(filterObj.endDate);
        toDate = toDate.addDays(1);
        
        String query = 'Select Adjustment_Date__c, Applicable_Tax__c, Total_Cost__c, Vendor_Reference_Number__c, Vendor__r.Name, ' +
        'Customer_Reference_Number__c, Customer__r.Name, Customer_Owned_Unit__c from Unit_Price_Cost__c WHERE Applicable_Tax__c != null';
        query += ' AND Adjustment_Date__c >= ' + fromDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' AND Adjustment_Date__c < ' + toDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        query += ' Order BY Adjustment_Date__c, Vendor_Reference_Number__c, Customer_Reference_Number__c';
        Map<Id, Unit_Price_Cost__c> unitAdjustmentMap = new Map<Id, Unit_Price_Cost__c>((List<Unit_Price_Cost__c>)Database.query(query)); 

        Set<Id> upcIdSet = unitAdjustmentMap.keySet();
        String indiQuery = 'SELECT Taxable_Amount__c, Enhanced_Tax_Amount__c, Tax_Amount__c, Tax_Rate__c, Sales_Tax_Item__r.Name__c, '+
            'Sales_Tax_Item_Name__c, Unit_Price_Cost__r.Vendor_Reference_Number__c, Unit_Price_Cost__r.Customer_Reference_Number__c, '+
            'Unit_Price_Cost__r.Tax__c, Unit_Price_Cost__r.Tax_Amount__c FROM Individual_Tax__c WHERE Unit_Price_Cost__c IN: upcIdSet';
        
        Map<Id, Map<String, List<Decimal>>> upcIdToTaxItemDetailMap = new Map<Id, Map<String, List<Decimal>>>();

        for(Individual_Tax__c indiTax : Database.query(indiQuery)) {
            String invoiceId = indiTax.Unit_Price_Cost__c;
            if(String.isNotBlank(indiTax.Unit_Price_Cost__c)) {
                Map<String,List<Decimal>> taxRateNameToDetailMap = new Map<String,List<Decimal>>();
                if(upcIdToTaxItemDetailMap.get(invoiceId) != null) taxRateNameToDetailMap = upcIdToTaxItemDetailMap.get(invoiceId);

                String taxNameFormatted = indiTax.Sales_Tax_Item_Name__c != null ? indiTax.Sales_Tax_Item_Name__c.trim() : indiTax.Sales_Tax_Item__r.Name__c.trim();
                if(!taxRateNameToDetailMap.containsKey(taxNameFormatted)) {
                    taxRateNameToDetailMap.put(taxNameFormatted, new List<Decimal>{0,0,0});
                }
                taxRateNameToDetailMap.get(taxNameFormatted)[0] += indiTax.Taxable_Amount__c;
                
                if(GeneralConfiguration.getTaxIncludingPricing()) {
                    Decimal taxAmount = 0;
                    if(indiTax.Unit_Price_Cost__r.Tax__c != null && indiTax.Unit_Price_Cost__r.Tax__c != 0) {
                        taxAmount = (indiTax.Unit_Price_Cost__r.Tax_Amount__c * (indiTax.Tax_Rate__c/indiTax.Unit_Price_Cost__r.Tax__c)).setScale(2, RoundingMode.HALF_UP);
                    }
                    taxRateNameToDetailMap.get(taxNameFormatted)[1] += taxAmount;
                } else {
                    if(indiTax.Enhanced_Tax_Amount__c != null) {
                        taxRateNameToDetailMap.get(taxNameFormatted)[1] += indiTax.Enhanced_Tax_Amount__c;
                    } else {
                        taxRateNameToDetailMap.get(taxNameFormatted)[1] += (indiTax.Taxable_Amount__c * indiTax.Tax_Rate__c) / 100;
                    }
                }
                taxRateNameToDetailMap.get(taxNameFormatted)[2] = indiTax.Tax_Rate__c;
                upcIdToTaxItemDetailMap.put(invoiceId, taxRateNameToDetailMap);
            }
        }
        return createWrapper(upcIdToTaxItemDetailMap, unitAdjustmentMap);
    }

    private static TaxActivityDetailWrapper createWrapper(Map<Id, Map<String, List<Decimal>>> upcIdToTaxItemDetailMap, Map<Id, Unit_Price_Cost__c> unitAdjustmentMap) {
        TaxActivityDetailWrapper taxActivityObj = new TaxActivityDetailWrapper();
        Map<String, TaxActivityDetailWrapper.TaxWrapper> salesTaxWrapperMap = new Map<String, TaxActivityDetailWrapper.TaxWrapper>();
        Map<String, TaxActivityDetailWrapper.TaxWrapper> purchaseTaxWrapperMap = new Map<String, TaxActivityDetailWrapper.TaxWrapper>();
        
        for(Unit_Price_Cost__c upcRec : unitAdjustmentMap.values()) {
            upcRec.Total_Cost__c = upcRec.Total_Cost__c != null ? upcRec.Total_Cost__c : 0;
            Decimal totalTaxableAmount = 0;
            Decimal nonTaxableAmount = 0;
            Decimal totalTaxAmount = 0;

            if(upcIdToTaxItemDetailMap.get(upcRec.Id) != null && !upcIdToTaxItemDetailMap.get(upcRec.Id).isEmpty()) {
                for(String taxName : upcIdToTaxItemDetailMap.get(upcRec.Id).keySet()) {
                    if(String.isNotBlank(taxName)) {
                        List<Decimal> amounts = upcIdToTaxItemDetailMap.get(upcRec.Id).get(taxName);
                        String taxNameFormatted = taxName.trim().toLowerCase();
                        Decimal taxableAmount = (amounts[0] != null ? amounts[0] : 0).setScale(2, RoundingMode.HALF_UP);
                        Decimal taxAmount = (amounts[1] != null ? amounts[1] : 0).setScale(2, RoundingMode.HALF_UP);
                        Decimal taxRate = amounts[2] != null ? amounts[2] : 0;
                    
                        TaxActivityDetailWrapper.TaxWrapper taxObj = getTaxWrapperObj(
                        (upcRec.Customer__c != null ? salesTaxWrapperMap.get(taxNameFormatted) : purchaseTaxWrapperMap.get(taxNameFormatted)), 
                        taxName, taxableAmount, taxAmount, 0);
                        taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(upcRec, taxableAmount, taxRate, taxAmount, 0));

                        if(upcRec.Customer__c != null) {
                            salesTaxWrapperMap.put(taxNameFormatted, taxObj);
                        } else {
                            purchaseTaxWrapperMap.put(taxNameFormatted, taxObj);
                        }
                        totalTaxAmount += taxAmount;
                    }
                }
                totalTaxableAmount = (upcRec.Total_Cost__c);
            } else {
                nonTaxableAmount = (upcRec.Total_Cost__c);
            }
            if(nonTaxableAmount != 0) {
                TaxActivityDetailWrapper.TaxWrapper taxObj = getTaxWrapperObj(
                        (upcRec.Customer__c != null ? salesTaxWrapperMap.get(NON_TAXABLE_SALES) : purchaseTaxWrapperMap.get(NON_TAXABLE_PURCHASES)), 
                        (upcRec.Customer__c != null ? NON_TAXABLE_SALES : NON_TAXABLE_PURCHASES), 
                        0, 0, nonTaxableAmount);
                taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(upcRec, 0, 0, 0, nonTaxableAmount));
                if(upcRec.Customer__c != null) {
                    salesTaxWrapperMap.put(NON_TAXABLE_SALES, taxObj);
                } else {
                    purchaseTaxWrapperMap.put(NON_TAXABLE_PURCHASES, taxObj);
                }
            }
            if(upcRec.Customer__c != null) {
                taxActivityObj.SalesTaxActivityObj.TaxAmount += totalTaxAmount;
                taxActivityObj.SalesTaxActivityObj.TaxableAmount += totalTaxableAmount;
                taxActivityObj.SalesTaxActivityObj.NonTaxableAmount += nonTaxableAmount;
            } else {
                taxActivityObj.PurchaseTaxActivityObj.TaxAmount += totalTaxAmount;
                taxActivityObj.PurchaseTaxActivityObj.TaxableAmount += totalTaxableAmount;
                taxActivityObj.PurchaseTaxActivityObj.NonTaxableAmount += nonTaxableAmount;
            }
        }
        taxActivityObj.SalesTaxActivityObj.TaxDetails = salesTaxWrapperMap.values();
        taxActivityObj.PurchaseTaxActivityObj.TaxDetails = purchaseTaxWrapperMap.values();

        return taxActivityObj;
    }

    private static TaxActivityDetailWrapper getCOInvoiceActivityReport(TaxActivityDetailWrapper.ActivityReportFilterWrapper filterObj) {
        DateTime fromDate = HomeSearchFilterInterface.getDateFromString(filterObj.startDate);
        DateTime toDate = HomeSearchFilterInterface.getDateFromString(filterObj.endDate);
        toDate = toDate.addDays(1);
        
        String query = 'Select Checkout_Type__c, Taxable_Total__c, Non_Taxable_Total__c, Invoice_Date__c, Invoice_Number__c, CO_Header__r.Customer_Name__c, ' +
        '(Select CO_Invoice_Header__c, SO_Payment_Role__r.Total_Amount__c, SO_Payment_Role__r.Tax_Amount__c, SO_Payment_Role__r.Tax__c ' +
        'FROM CO_Invoice_Items__r WHERE SO_Payment_Role__r.RecordType.DeveloperName = \'Deductible\') from CO_Invoice_Header__c WHERE Status__c = \'Closed\'';
        if(filterObj.excludeInternalInvoices != null && filterObj.excludeInternalInvoices) query += ' AND Checkout_Type__c NOT IN (\'Deal\', \'Internal\')';
        query += ('AND Invoice_Date__c >= ' + fromDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' AND Invoice_Date__c < ' + toDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        query += ' Order BY Invoice_Date__c, Invoice_Number__c';
        Map<Id, CO_Invoice_Header__c> invoiceMap = new Map<Id, CO_Invoice_Header__c>((List<CO_Invoice_Header__c>)Database.query(query));

        Map<Id, CO_Invoice_Item__c> soPaymentRoleIdToInvItemRecMap = new Map<Id, CO_Invoice_Item__c>();
        for(CO_Invoice_Header__c coInvRec : invoiceMap.values()) {
            for(CO_Invoice_Item__c invItem : coInvRec.CO_Invoice_Items__r) {
                soPaymentRoleIdToInvItemRecMap.put(invItem.SO_Payment_Role__c, invItem);
            }
        }
        List<CO_Invoice_Header__c> invoiceList = invoiceMap.values();
        Map<Id, Id> soPaymentRoleIdToTPInvIdMap = HomeSearchResultWrapper.getSOPaymentRoleIdToThirdPartInvoiceIdMap(new List<Id>(invoiceMap.keyset()));
        Map<Id, SO_Payment_Role__c> soPaymentRoleIdToRecMap = HomeSearchResultWrapper.getSOPaymentRoleIdToRecMap(soPaymentRoleIdToTPInvIdMap.keySet());

        List<Id> soPaymentRoleIdList = new List<Id>(soPaymentRoleIdToInvItemRecMap.keySet());
        soPaymentRoleIdList.addAll(new List<Id>(soPaymentRoleIdToTPInvIdMap.KeySet()));

        Map<Id, Map<String,List<Decimal>>> invoiceHeaderIdToTaxItemDetailMap = new Map<Id, Map<String,List<Decimal>>>();
        String indiQuery = 'SELECT SO_Payment_Role__c, Taxable_Amount__c, Enhanced_Tax_Amount__c, Tax_Amount__c, Tax_Rate__c, Deal_Item__r.Deal__r.Invoice_Number__c, '+
            'Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.Invoice_Number__c, F_I_Product__r.Deal_Finance__r.Deal__r.Invoice_Number__c, Sales_Tax_Item_Name__c, '+
            'CO_Line_Item__r.Invoice_Number__c, Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c,'+
            'Option_Fee__r.Deal_Item__r.Deal__r.Invoice_Number__c, Deal__r.Invoice_Number__c, Sales_Tax_Item__r.Name__c '+
            'FROM Individual_Tax__c WHERE (Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.Invoice_Number__c IN: invoiceList ' +
            'OR F_I_Product__r.Deal_Finance__r.Deal__r.Invoice_Number__c IN: invoiceList ' +
            'OR (CO_Line_Item__r.Invoice_Number__c IN: invoiceList AND CO_Line_Item__r.Is_In_Merch_Section__c = true AND Deal__c = null)' +
            'OR (Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c IN: invoiceList AND Deal__c = null)' +
            'OR (Option_Fee__r.Deal_Item__r.Deal__r.Invoice_Number__c IN: invoiceList)' +
            'OR (Deal_Item__r.Deal__r.Invoice_Number__c IN :invoiceList AND Deal_Item__r.Type__c = \'Trade In\')'+
            'OR Deal__r.Invoice_Number__c IN :invoiceList OR SO_Payment_Role__c IN :soPaymentRoleIdList)';
        system.debug( indiQuery);

        for(Individual_Tax__c individualTax : Database.query(indiQuery)) {
            String invoiceId, thirdPartyInvoiceId;
            if(individualTax.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Deal__r.Invoice_Number__c;
            } else if(individualTax.Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.Invoice_Number__c;
            } else if(individualTax.Option_Fee__r.Deal_Item__r.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Option_Fee__r.Deal_Item__r.Deal__r.Invoice_Number__c;
            } else if(individualTax.Deal_Item__r.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Deal_Item__r.Deal__r.Invoice_Number__c;
            } else if(individualTax.F_I_Product__r.Deal_Finance__r.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.F_I_Product__r.Deal_Finance__r.Deal__r.Invoice_Number__c;
            } else if(individualTax.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c;
            } else if(individualTax.CO_Line_Item__r.Invoice_Number__c != null) {
                invoiceId = individualTax.CO_Line_Item__r.Invoice_Number__c;
            } else if(individualTax.SO_Payment_Role__c != null) {
                if(soPaymentRoleIdToInvItemRecMap.containsKey(individualTax.SO_Payment_Role__c)) {
                    invoiceId = soPaymentRoleIdToInvItemRecMap.get(individualTax.SO_Payment_Role__c).CO_Invoice_Header__c;
                } 
                if(soPaymentRoleIdToTPInvIdMap.containsKey(individualTax.SO_Payment_Role__c)) {
                    thirdPartyInvoiceId = soPaymentRoleIdToTPInvIdMap.get(individualTax.SO_Payment_Role__c);
                }
            }
            
            if(String.isNotBlank(invoiceId) || String.isNotBlank(thirdPartyInvoiceId)) {
                Map<String,List<Decimal>> taxRateNameToDetailMap = new Map<String,List<Decimal>>();
                if(invoiceHeaderIdToTaxItemDetailMap.get(invoiceId) != null) taxRateNameToDetailMap = invoiceHeaderIdToTaxItemDetailMap.get(invoiceId);

                Map<String,List<Decimal>> tpTaxRateNameToDetailMap = new Map<String,List<Decimal>>();
                if(String.isNotBlank(thirdPartyInvoiceId)) {
                    if(invoiceHeaderIdToTaxItemDetailMap.get(thirdPartyInvoiceId) != null) tpTaxRateNameToDetailMap = invoiceHeaderIdToTaxItemDetailMap.get(thirdPartyInvoiceId);
                }
                String taxNameFormatted = individualTax.Sales_Tax_Item_Name__c != null ? individualTax.Sales_Tax_Item_Name__c.trim() : individualTax.Sales_Tax_Item__r.Name__c.trim();
                if(!taxRateNameToDetailMap.containsKey(taxNameFormatted)) {
                    taxRateNameToDetailMap.put(taxNameFormatted, new List<Decimal>{0,0,0});
                }
                if(!tpTaxRateNameToDetailMap.containsKey(taxNameFormatted)) {
                    tpTaxRateNameToDetailMap.put(taxNameFormatted, new List<Decimal>{0,0,0});
                }
                if(individualTax.SO_Payment_Role__c != null) {
                    Decimal totalAmount = 0;
                    if(soPaymentRoleIdToInvItemRecMap.containsKey(individualTax.SO_Payment_Role__c)) {
                        totalAmount = soPaymentRoleIdToInvItemRecMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Total_Amount__c;
                    }
                    taxRateNameToDetailMap.get(taxNameFormatted)[0] += totalAmount;
                    
                    if(String.isNotBlank(thirdPartyInvoiceId)) {
                        totalAmount = (soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Total_Amount__c)*-1;
                        tpTaxRateNameToDetailMap.get(taxNameFormatted)[0] += totalAmount;
                    }
                } else {
                    taxRateNameToDetailMap.get(taxNameFormatted)[0] += individualTax.Taxable_Amount__c;
                }
                if(GeneralConfiguration.getTaxIncludingPricing()) {
                    if(individualTax.SO_Payment_Role__c != null) {
                        Decimal taxAmount = 0;
                        if(soPaymentRoleIdToInvItemRecMap.containsKey(individualTax.SO_Payment_Role__c) && soPaymentRoleIdToInvItemRecMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Tax__c != null && soPaymentRoleIdToInvItemRecMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Tax__c != 0) {
                            taxAmount = (soPaymentRoleIdToInvItemRecMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Tax_Amount__c * (individualTax.Tax_Rate__c/soPaymentRoleIdToInvItemRecMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Tax__c)).setScale(2, RoundingMode.HALF_UP);
                        }
                        taxRateNameToDetailMap.get(taxNameFormatted)[1] += taxAmount;
                        if(String.isNotBlank(thirdPartyInvoiceId)) {
                            taxAmount = 0;
                            if(soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Tax__c != null && soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Tax__c != 0) {
                                taxAmount = (soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Tax_Amount__c*(individualTax.Tax_Rate__c/soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Tax__c)).setScale(2, RoundingMode.HALF_UP);
                            }
                            taxAmount *= -1;
                            tpTaxRateNameToDetailMap.get(taxNameFormatted)[1] += taxAmount;
                        }
                    } else {
                        taxRateNameToDetailMap.get(taxNameFormatted)[1] += individualTax.Tax_Amount__c;
                    }
                } else {
                    if(individualTax.Enhanced_Tax_Amount__c != null) {
                        taxRateNameToDetailMap.get(taxNameFormatted)[1] += individualTax.Enhanced_Tax_Amount__c;
                    } else {
                        if(individualTax.SO_Payment_Role__c != null) {
                            Decimal taxAmount = 0;
                            if(soPaymentRoleIdToInvItemRecMap.containsKey(individualTax.SO_Payment_Role__c)) {
                                taxAmount = ((soPaymentRoleIdToInvItemRecMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Total_Amount__c * individualTax.Tax_Rate__c)/100).setScale(2, RoundingMode.HALF_UP);
                            }
                            taxRateNameToDetailMap.get(taxNameFormatted)[1] += taxAmount;
                            if(String.isNotBlank(thirdPartyInvoiceId)) {
                                taxAmount = ((soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Total_Amount__c*individualTax.Tax_Rate__c)/100).setScale(2, RoundingMode.HALF_UP);
                                taxAmount *= -1;
                                tpTaxRateNameToDetailMap.get(taxNameFormatted)[1] += taxAmount;
                            }
                        } else {
                            taxRateNameToDetailMap.get(taxNameFormatted)[1] += (individualTax.Taxable_Amount__c * individualTax.Tax_Rate__c) / 100;
                        }
                    }
                }
                taxRateNameToDetailMap.get(taxNameFormatted)[2] = individualTax.Tax_Rate__c;
                tpTaxRateNameToDetailMap.get(taxNameFormatted)[2] = individualTax.Tax_Rate__c;
                invoiceHeaderIdToTaxItemDetailMap.put(invoiceId, taxRateNameToDetailMap);
                invoiceHeaderIdToTaxItemDetailMap.put(thirdPartyInvoiceId, tpTaxRateNameToDetailMap);
            }
        }
        return createWrapper(invoiceHeaderIdToTaxItemDetailMap, invoiceMap);
    }

    private static TaxActivityDetailWrapper createWrapper(Map<Id, Map<String,List<Decimal>>> invoiceHeaderIdToTaxItemDetailMap, Map<Id, CO_Invoice_Header__c> invoiceMap) {
        Map<String, Set<String>> coInvoiceIdToContentsMap = getCOInvoiceIdToContentsMap(invoiceMap.keySet());
        TaxActivityDetailWrapper taxActivityObj = new  TaxActivityDetailWrapper();
        Map<String, TaxActivityDetailWrapper.TaxWrapper> taxWrapperMap = new Map<String, TaxActivityDetailWrapper.TaxWrapper>();

        for(Id invoiceId : invoiceMap.keySet()) {
            CO_Invoice_Header__c invRec = invoiceMap.get(invoiceId);
            invRec.Taxable_Total__c = invRec.Taxable_Total__c != null ? invRec.Taxable_Total__c : 0;
            Decimal nonTaxableAmount = invRec.Non_Taxable_Total__c != null ? invRec.Non_Taxable_Total__c : 0;
            Decimal totalTaxAmount = 0;

            if(invoiceHeaderIdToTaxItemDetailMap.get(invoiceId) != null && !invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).isEmpty()) {
                for(String taxName : invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).keySet()) {
                    if(String.isNotBlank(taxName)) {
                        List<Decimal> amounts = invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).get(taxName);
                        String taxNameFormatted = taxName.trim().toLowerCase();
                        Decimal taxableAmount = (amounts[0] != null ? amounts[0] : 0).setScale(2, RoundingMode.HALF_UP);
                        Decimal taxAmount = (amounts[1] != null ? amounts[1] : 0).setScale(2, RoundingMode.HALF_UP);
                        Decimal taxRate = amounts[2] != null ? amounts[2] : 0;
                    
                        TaxActivityDetailWrapper.TaxWrapper taxObj = getTaxWrapperObj(taxWrapperMap.get(taxNameFormatted), taxName, taxableAmount, taxAmount, 0);
                        taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(invRec, taxableAmount, taxRate, taxAmount, 0, coInvoiceIdToContentsMap.get(invoiceId)));
                        taxWrapperMap.put(taxNameFormatted, taxObj);

                        totalTaxAmount += taxAmount;
                    }
                }
            } else {
                nonTaxableAmount += (invRec.Taxable_Total__c);
            }
            if(nonTaxableAmount != 0) {
                TaxActivityDetailWrapper.TaxWrapper taxObj = getTaxWrapperObj(
                        taxWrapperMap.get(NON_TAXABLE_SALES), NON_TAXABLE_SALES, 0, 0, nonTaxableAmount);
                taxObj.Activities.add(new TaxActivityDetailWrapper.ActivityWrapper(invRec, 0, 0, 0, nonTaxableAmount, coInvoiceIdToContentsMap.get(invoiceId)));
                taxWrapperMap.put(NON_TAXABLE_SALES, taxObj);
            }
            taxActivityObj.SalesTaxActivityObj.TaxAmount += totalTaxAmount;
            taxActivityObj.SalesTaxActivityObj.TaxableAmount += invRec.Taxable_Total__c;
            taxActivityObj.SalesTaxActivityObj.NonTaxableAmount += nonTaxableAmount;
        }
        taxActivityObj.SalesTaxActivityObj.TaxDetails = taxWrapperMap.values();

        return taxActivityObj;
    }

    private static TaxActivityDetailWrapper.TaxWrapper getTaxWrapperObj(TaxActivityDetailWrapper.TaxWrapper taxObj, String taxName, Decimal taxableAmount, Decimal taxAmount, Decimal nonTaxableAmount) {
        if(taxObj == null) {
            taxObj = new TaxActivityDetailWrapper.TaxWrapper();
            taxObj.TaxName = taxName;
            //taxObj.TxnCount = 0;
            taxObj.TaxableAmount = taxObj.TaxAmount = taxObj.NonTaxableAmount = 0;
            taxObj.Activities = new List<TaxActivityDetailWrapper.ActivityWrapper>();
        }
        taxObj.TaxableAmount += (taxableAmount != null ? taxableAmount : 0);
        taxObj.TaxAmount += (taxAmount != null ? taxAmount : 0);
        taxObj.NonTaxableAmount += (nonTaxableAmount != null ? nonTaxableAmount : 0);
        return taxObj;
    }

    private static Map<Id, List<Sales_Tax_Item__c>> getTaxCodeIdToRatesMapByTaxIds(Set<Id> taxIds) {
        Map<Id, List<Sales_Tax_Item__c>> taxCodeIdToRatesMap = new Map<Id, List<Sales_Tax_Item__c>>();
        if(taxIds != null && !taxIds.isEmpty()) {
            for(Applicable_Taxes__c tax : [Select Name, Sales_Tax__c, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c FROM Applicable_Taxes__c WHERE Sales_Tax__c IN: taxIds]) {
                if(!taxCodeIdToRatesMap.containsKey(tax.Sales_Tax__c)) {
                    taxCodeIdToRatesMap.put(tax.Sales_Tax__c, new List<Sales_Tax_Item__c>());
                }
                taxCodeIdToRatesMap.get(tax.Sales_Tax__c).add(tax.Sales_Tax_Item__r);
            }
        }
        return taxCodeIdToRatesMap;
    }

    private static Map<String, Set<String>> getCOInvoiceIdToContentsMap(Set<Id> coInvoiceIds) {
        Map<String, Set<String>> coInvoiceIdToContentsMap = new Map<String, Set<String>>();
        
        if(!coInvoiceIds.isEmpty()) {
            for(CO_Line_Item__c coli : [Select Invoice_Number__c, Part__c, Fee__c FROM CO_Line_Item__c WHERE Invoice_Number__c IN: coInvoiceIds AND Service_Order_Line_Item__c = null AND (Part__c != null OR Fee__c != null)]) {
                if(!coInvoiceIdToContentsMap.containsKey(coli.Invoice_Number__c)) {
                    coInvoiceIdToContentsMap.put(coli.Invoice_Number__c, new Set<String>());
                }
                coInvoiceIdToContentsMap.get(coli.Invoice_Number__c).add(
                    (coli.Part__c != null ? 'Parts' : 'Fees')
                );
            }
            for(Service_Order_Line_Item__c soli : [Select Service_Order_Header__r.Invoice_Number__c, Part__c, Fee__c, Labour_Code__c, Sublet__c FROM Service_Order_Line_Item__c WHERE Service_Order_Header__r.Invoice_Number__c IN: coInvoiceIds]) {
                if(!coInvoiceIdToContentsMap.containsKey(soli.Service_Order_Header__r.Invoice_Number__c)) {
                    coInvoiceIdToContentsMap.put(soli.Service_Order_Header__r.Invoice_Number__c, new Set<String>());
                }
                coInvoiceIdToContentsMap.get(soli.Service_Order_Header__r.Invoice_Number__c).add(
                    (soli.Part__c != null ? 'Parts' : 
                    (soli.Labour_Code__c != null ? 'Labor' : 
                    (soli.Sublet__c != null ? 'Sublet' : 
                    (soli.Fee__c != null ? 'Fees' : null))))
                );
            }
            for(Deal_Item__c dealItem : [Select Deal__r.Invoice_Number__c, Customer_Owned_Unit__r.Unit_Type__c, Customer_Owned_Unit__r.Unit_Number__c, Customer_Owned_Unit__r.Stock_Id__c FROM Deal_Item__c WHERE Deal__r.Invoice_Number__c IN: coInvoiceIds AND Customer_Owned_Unit__r.Unit_Type__c != null]) {
                if(!coInvoiceIdToContentsMap.containsKey(dealItem.Deal__r.Invoice_Number__c)) {
                    coInvoiceIdToContentsMap.put(dealItem.Deal__r.Invoice_Number__c, new Set<String>());
                }
                coInvoiceIdToContentsMap.get(dealItem.Deal__r.Invoice_Number__c).add(
                    (dealItem.Customer_Owned_Unit__r.Unit_Type__c.equalsIgnoreCase('STOCK') ? dealItem.Customer_Owned_Unit__r.Stock_Id__c : dealItem.Customer_Owned_Unit__r.Unit_Number__c)
                );
            }
            for(CO_Invoice_Item__c coInvItemRec : [Select CO_Invoice_Header__c, SO_Payment_Role__c FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c IN: coInvoiceIds AND SO_Payment_Role__r.RecordType.DeveloperName = 'Deductible']) {
                if(!coInvoiceIdToContentsMap.containsKey(coInvItemRec.CO_Invoice_Header__c)) {
                    coInvoiceIdToContentsMap.put(coInvItemRec.CO_Invoice_Header__c, new Set<String>());
                }
                coInvoiceIdToContentsMap.get(coInvItemRec.CO_Invoice_Header__c).add('Deductible');
            }
        }
        return coInvoiceIdToContentsMap;
    }

    private static Map<String, Set<String>> getVOInvoiceIdToContentsMap(Set<Id> vendorInvoiceIds) {
        Map<String, Set<String>> voInvoiceIdToContentsMap = new Map<String, Set<String>>();
        if(!vendorInvoiceIds.isEmpty()) {
            for(Vendor_Invoicing_Group__c vig : [Select Vendor_Invoicing_Header__c, Vendor_Receiving_Group__r.Part__c, Vendor_Receiving_Group__r.Sublet__c FROM Vendor_Invoicing_Group__c WHERE Vendor_Invoicing_Header__c IN: vendorInvoiceIds AND (Vendor_Receiving_Group__r.Part__c != null OR Vendor_Receiving_Group__r.Sublet__c != null)]) {
                if(!voInvoiceIdToContentsMap.containsKey(vig.Vendor_Invoicing_Header__c)) {
                    voInvoiceIdToContentsMap.put(vig.Vendor_Invoicing_Header__c, new Set<String>());
                }
                voInvoiceIdToContentsMap.get(vig.Vendor_Invoicing_Header__c).add(
                    (vig.Vendor_Receiving_Group__r.Part__c != null ? 'Parts purchase' : 'Sublet purchase')
                );
            }
        }
        return voInvoiceIdToContentsMap;
    }

    public static Map<String, Object> getTaxSettingMasterData() {
        List<Sales_Tax__c> taxList = SOQLUtil.getSalesTax(new List<Id>());
        List<UserSettingCtrl.RecordItem> salesTaxList = new List<UserSettingCtrl.RecordItem>();
        List<UserSettingCtrl.RecordItem> purchaseTaxList = new List<UserSettingCtrl.RecordItem>();
        for(Sales_Tax__c salesTaxRec : taxList){
            if(salesTaxRec.Tax_Type__c != null) {
                if(salesTaxRec.Tax_Type__c.equalsIgnoreCase('Sell')) {
                    salesTaxList.add(new UserSettingCtrl.RecordItem(salesTaxRec.Name__c, salesTaxRec.Id));
                } else if(salesTaxRec.Tax_Type__c.equalsIgnoreCase('Purchase')) {
                    purchaseTaxList.add(new UserSettingCtrl.RecordItem(salesTaxRec.Name__c, salesTaxRec.Id));
                }
            }
        }
        return new Map<String, Object>{
            'SalesTaxList' => salesTaxList,
            'PurchaseTaxList' => purchaseTaxList,
            'CategoryList' => CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => Constants.CATEGORY_TYPE_TAX})
        };
    }

    public static TaxSettingsWrapper.GeneralConfigWrapper getGeneralTaxSettings() {
        return new TaxSettingsWrapper.GeneralConfigWrapper();
    }

    public static List<TaxRateWrapper.TaxRate> getAutomaticTaxRateControls() {
        List<TaxRateWrapper.TaxRate> taxRates = new List<TaxRateWrapper.TaxRate>();
        List<Sales_Tax_Item__c> salesTaxItemList = [Select Id, Name__c, Category__r.Name, Forms_Label__c, Automated_Tax_Rate_Name__c, Rate__c, Tax_Type__c, Is_Automated__c FROM Sales_Tax_Item__c WHERE Is_Automated__c = true AND Is_Removed__c = false AND Active__c = true AND Tax_Type__c = 'Sell' Order by Display_Order__c ASC];
        for(Sales_Tax_Item__c taxRate : salesTaxItemList) {
            TaxRateWrapper.TaxRate taxRateObj = new TaxRateWrapper.TaxRate();
            taxRateObj.Id = taxRate.Id;
            taxRateObj.TaxName = (taxRate.Name__c != null && isAutomatedDistrictTax(taxRate)) ? ZipTaxUtil.DISTRICT_TAX : taxRate.Name__c;
            taxRateObj.CategoryId = taxRate.Category__c;
            taxRateObj.CategoryName = (taxRate.Category__c != null ? taxRate.Category__r.Name : null);
        	taxRateObj.FormsLabel = taxRate.Forms_Label__c;
            taxRateObj.TaxRateStr = String.valueOf(((taxRate.Rate__c != null) ? taxRate.Rate__c.setScale(4, RoundingMode.HALF_UP) : 0)) + '%';
            taxRateObj.AutomatedTaxName = taxRate.Automated_Tax_Rate_Name__c;
            taxRateObj.TaxRate = (taxRate.Rate__c != null) ? taxRate.Rate__c.setScale(4, RoundingMode.HALF_UP) : 0;
            taxRates.add(taxRateObj);
        }
        return taxRates;
    }

    public static TaxSettingsWrapper.AccruedTaxWrapper getAccruedTaxControls() {
        return new TaxSettingsWrapper.AccruedTaxWrapper();
    }

    public static TaxSettingsWrapper.DefaultTaxWrapper getDefaultApplicableTaxSettings() {
        return new TaxSettingsWrapper.DefaultTaxWrapper();
    }

    public static void saveTaxControlsAndSettings(String payload) {
        TaxSettingsWrapper taxControlsAndSettingsObj = (TaxSettingsWrapper) System.Json.deserialize(payload, TaxSettingsWrapper.class);
        Configurations__c configurationObj = Configurations__c.getOrgDefaults();
        if(taxControlsAndSettingsObj.GenConfigObj != null) {
            saveGeneralTaxSettings(configurationObj, taxControlsAndSettingsObj.GenConfigObj);
        }
        if(taxControlsAndSettingsObj.AccruedTaxObj != null) {
            saveAccruedTaxSettings(configurationObj, taxControlsAndSettingsObj.AccruedTaxObj);
        }
        if(taxControlsAndSettingsObj.DefaultTaxObj != null) {
            saveDefaultApplicableTaxSettings(configurationObj, taxControlsAndSettingsObj.DefaultTaxObj);
        }
        if(taxControlsAndSettingsObj.AutomaticTaxRates != null) {
            saveAutomaticTaxRates(taxControlsAndSettingsObj.AutomaticTaxRates);
        }
        upsert configurationObj;
    }

    public static void saveGeneralTaxSettings(Configurations__c configurationObj, TaxSettingsWrapper.GeneralConfigWrapper generalConfig) {
        configurationObj.Tax_Id__c = generalConfig.TaxId;
        configurationObj.Trade_Tax_Credit_Can_Not_Exceed_Unit_Tax__c = !configurationObj.Tax_Included_Pricing__c ? generalConfig.TradeTaxCreditCanNotExceedUnitTax : false;
        configurationObj.Deal_Unit_Options_Taxed_Like_Unit__c = generalConfig.DealUnitOptionsTaxedLikeUnit;
        if(configurationObj.Automatic_tax_rates__c) {
            configurationObj.Group_Individual_Taxes_On_Sales__c = generalConfig.GroupIndividualTaxesOnSales;
            configurationObj.Group_Individual_Sales_Tax_As__c = generalConfig.GroupIndividualSalesTaxAs;
            configurationObj.Group_Individual_Taxes_On_Purchases__c = generalConfig.GroupIndividualTaxesOnPurchase;
            configurationObj.Group_Individual_Purchase_Tax_As__c = generalConfig.GroupIndividualPurchaseTaxAs;
        }
    }

    public static void saveAccruedTaxSettings(Configurations__c configurationObj, TaxSettingsWrapper.AccruedTaxWrapper accruedTaxObj) {
        configurationObj.Accrue_Trade_Tax_Until_Unit_Sold__c = accruedTaxObj.AccrueTradeTaxUntilUnitSold;
        configurationObj.Enable_Tax_Acc_on_Order_Units_By_Default__c = accruedTaxObj.EnableTaxAccrualOnOrderUnitsByDefault;
        configurationObj.Trade_Tax_Pending_Sale_Category__c = accruedTaxObj.NationalInputTaxCategory;
        configurationObj.Trade_Tax_Liability_Category__c = accruedTaxObj.SalesTaxLiabilityCategory;
        configurationObj.Purchase_Tax_Liability_Category__c = accruedTaxObj.PurchaseTaxLiabilityCategory;
        configurationObj.Trade_Tax_Expense_Category__c = accruedTaxObj.NationalInputTaxExpenseCategory;
    }

    public static void saveDefaultApplicableTaxSettings(Configurations__c configurationObj, TaxSettingsWrapper.DefaultTaxWrapper defaultTaxObj) {
        configurationObj.Default_Tax_on_Part__c = defaultTaxObj.PartTax;
        configurationObj.Default_Tax_on_Labor__c = defaultTaxObj.LaborTax;
        configurationObj.Default_Tax_on_Fee__c = defaultTaxObj.FeeTax;
        configurationObj.Default_Tax_on_Unit__c = defaultTaxObj.UnitTax;
        configurationObj.Default_Tax_on_Vendor_Product__c = defaultTaxObj.VendorProductTax;
        configurationObj.Default_Tax_on_Claim_Deductibles__c = defaultTaxObj.ClaimDeductiblesTax;
        configurationObj.Default_Sales_Tax_on_Internal_Service__c = defaultTaxObj.InternalServiceTax;
        configurationObj.Ordering_Tax_Rate__c = defaultTaxObj.VendorPurchaseTax;
    }

    public static void saveAutomaticTaxRates(List<TaxRateWrapper.TaxRate> taxRates) {
        if(taxRates != null) {
            List<Sales_Tax_Item__c> taxRateRecs = new List<Sales_Tax_Item__c>();
            Sales_Tax_Item__c districtSTIRec;
            for(TaxRateWrapper.TaxRate taxRate : taxRates) {
                Sales_Tax_Item__c taxRateRec = new Sales_Tax_Item__c();
                taxRateRec.Id = taxRate.Id;
                taxRateRec.Category__c = taxRate.CategoryId;
                taxRateRec.Forms_Label__c = taxRate.FormsLabel;
                taxRateRecs.add(taxRateRec);

                if(GeneralConfiguration.getConfigurations().Automatic_tax_rates__c && taxRate.TaxName == ZipTaxUtil.DISTRICT_TAX) {
                    districtSTIRec = taxRateRec;
                }
            }
            
            if(districtSTIRec != null) {
                for(Sales_Tax_Item__c stiRec: getAllOtherDistrictTaxRates(districtSTIRec.Id, null)) {
                    stiRec.Category__c = districtSTIRec.Category__c;
                    stiRec.Forms_Label__c = districtSTIRec.Forms_Label__c;
                    taxRateRecs.add(stiRec);
                }
            }
            DMLUtility.updateSobjectList('Sales_Tax_Item__c', taxRateRecs);
        }
    }

    public static List<Sales_Tax_Item__c>  getUpdatedSalesTaxItems(List<Sales_Tax_Item__c> salesTaxItemList) {
        if(!GeneralConfiguration.getConfigurations().Automatic_tax_rates__c) return salesTaxItemList;
        List<Sales_Tax_Item__c> salesTaxItemListUpd = new List<Sales_Tax_Item__c>();
        Boolean isDistrictTaxIncluded = false;
        for(Sales_Tax_Item__c salesTaxItem: salesTaxItemList) {
            if(isAutomatedDistrictTax(salesTaxItem)) {
                if(!isDistrictTaxIncluded) {
                    isDistrictTaxIncluded = true;
                } else {
                    continue;
                }
            }
            salesTaxItemListUpd.add(salesTaxItem);
        }
        return salesTaxItemListUpd;
    }

    public static Boolean isAutomatedDistrictTax(Sales_Tax_Item__c salesTaxItem) {
        return GeneralConfiguration.getConfigurations().Automatic_tax_rates__c && salesTaxItem.Is_Automated__c && salesTaxItem.Name__c.containsIgnoreCase(ZipTaxUtil.DISTRICT_TAX_PREFIX);
    }

    public static List<Sales_Tax_Item__c> getAllOtherDistrictTaxRates(String districtTaxRateId, String accTypeId) {
        String query = 'SELECT Id, Is_Automated__c ';
        if(accTypeId != null) {
            query += ', (SELECT Id FROM Tax_Exemptions__r WHERE Account_Type__c =: accTypeId) ';
        }
        String taxNameStr = ZipTaxUtil.DISTRICT_TAX_PREFIX + '%';
        query += 'FROM Sales_Tax_Item__c WHERE Tax_Type__c = \'Sell\' AND Is_Automated__c = true AND Is_Removed__c = false AND Active__c = true AND Id != :districtTaxRateId AND Name__c LIKE :taxNameStr';
        return Database.query(query);
    }

    @future(callout=true)
    public static void enableAutomaticTaxRates() {
        ZipTaxService.populateStoreAutomatedTaxRates();
        
        Configurations__c config = Configurations__c.getOrgDefaults();
        config.Automatic_tax_rates__c = true;
        DMLUtility.updateSobjectList('Configurations__c', config);

        BPUtility.abortAlreadyScheduleJobs('Populated Store Automated Tax Rates Scheduler');
        System.schedule('Populated Store Automated Tax Rates Scheduler', '0 0 0 1 * ? *', new PopulatedStoreAutomatedTaxRatesScheduler());
    }
}