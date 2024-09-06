/**
 * Author: Nidhi Sharma
 * Since: Dec 14, 2022
 * Name: ForeignVendorConversionBatch
 * Description: Batch for updating a local vendor to foreign and calculate related part's foreign cost/pkg cost
**/
global without sharing class ForeignVendorConversionBatch implements Database.Batchable<sobject> {
    
    private Map<Id, String> foreignVendorIdToCurrencyCodeMap = new Map<Id, String>();

    global ForeignVendorConversionBatch(Map<Id, String> vendorIdToCurrencyCodeMap) {
        if(vendorIdToCurrencyCodeMap != null) {
            foreignVendorIdToCurrencyCodeMap = vendorIdToCurrencyCodeMap;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        convertLocalVendorToForeignVendor();
        Set<Id> vendorIdSet = foreignVendorIdToCurrencyCodeMap.keySet();
        String strQuery = 'SELECT Id, Vendor__r.Is_Foreign_Vendor__c, Vendor__r.Country__r.Conversion_Rate_With_Markup__c, Packaged_Part__c, Last_Cost__c, Foreign_Cost__c, Package_Cost__c, Foreign_PKG_Cost__c, Package_Qty__c FROM Part__c WHERE Vendor__c IN: vendorIdSet';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        for(Part__c partRec : partList) {
            if(partRec.Vendor__r.Is_Foreign_Vendor__c) {
                if(partRec.Packaged_Part__c) {
                    partRec.Foreign_PKG_Cost__c = ForeignExchangeUtil.getConvertedAmountInForeignCurrency(partRec.Package_Cost__c, partRec.Vendor__r.Country__r.Conversion_Rate_With_Markup__c);
                    partRec.Foreign_Cost__c = partRec.Foreign_PKG_Cost__c/partRec.Package_Qty__c;
                } else {
                    partRec.Foreign_Cost__c = ForeignExchangeUtil.getConvertedAmountInForeignCurrency(partRec.Last_Cost__c, partRec.Vendor__r.Country__r.Conversion_Rate_With_Markup__c);
                }
            }
        }
        PartTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Part__c', partList);
        PartTriggerHelper.isForceStopTrigger = false;
    }
    
    global void finish(Database.batchableContext bc) {}

    private void convertLocalVendorToForeignVendor() {
        if(foreignVendorIdToCurrencyCodeMap != null && !foreignVendorIdToCurrencyCodeMap.isEmpty()) {
            Map<String, Id> currencyCodeToCountryIdMap = new Map<String, Id>();
            for(Country__c countryRec : [Select Id, Currency_Code__c FROM Country__c WHERE Currency_Code__c != null AND Currency_Code__c IN: foreignVendorIdToCurrencyCodeMap.values()]) {
                currencyCodeToCountryIdMap.put(countryRec.Currency_Code__c, countryRec.Id);
            }
            List<Account> vendorUpdateList = new List<Account>();
            for(Id vendorId : foreignVendorIdToCurrencyCodeMap.keySet()) {
                String countryId = currencyCodeToCountryIdMap.get(foreignVendorIdToCurrencyCodeMap.get(vendorId));
                vendorUpdateList.add(new Account(Id = vendorId, Is_Foreign_Vendor__c = true, Country__c = countryId));
            }
            BPScriptUtility.disbaleTrigger('CustomerTrigger');
            DMLUtility.updateSobjectList('Account', vendorUpdateList);
            BPScriptUtility.enableTrigger('CustomerTrigger');
        }
    }
}