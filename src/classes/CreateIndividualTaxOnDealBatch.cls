/**
 * Author: Nidhi Sharma
 * Since: 29 March, 2023
 * Name: CreateIndividualTaxOnDealBatch
 * Description: Batch for Populating individual taxes on deal when enhanced tax calculation is enabled
**/
global without sharing class CreateIndividualTaxOnDealBatch extends PostInstallScriptBaseBatch {

    global CreateIndividualTaxOnDealBatch() {
        this.scriptName = 'executeCreateIndividualTaxOnDealBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Id from Deal__c';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealList) {
        if(!GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c) {
            if(AccessControl.ifObjectFieldIsAccessible('Individual_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            Map<Id, Map<Id, Individual_Tax__c>> dealIdToTaxRateIdToIndividualTaxRecMap = new Map<Id, Map<Id, Individual_Tax__c>>();
            Map<Id, List<Individual_Tax__c>> dealIdToIndividualTaxesMap = getDealIdToIndividualTaxesMap(dealList, dealIdToTaxRateIdToIndividualTaxRecMap);
            
            
            List<Individual_Tax__c> individualTaxInsertList = new List<Individual_Tax__c>();
            List<Individual_Tax__c> individualTaxDeleteList = new List<Individual_Tax__c>();
            for(Id dealId : dealIdToIndividualTaxesMap.keyset()) {
                Map<Id, Individual_Tax__c> taxRateIdToIndividualTaxRecMap = new Map<Id, Individual_Tax__c>();
                if(dealIdToTaxRateIdToIndividualTaxRecMap.get(dealId) != null) {
                    taxRateIdToIndividualTaxRecMap = dealIdToTaxRateIdToIndividualTaxRecMap.get(dealId);
                }
                for(Individual_Tax__c individualTaxRec : dealIdToIndividualTaxesMap.get(dealId)) {
                    if(!taxRateIdToIndividualTaxRecMap.containsKey(individualTaxRec.Sales_Tax_Item__c)) {
                        Individual_Tax__c individualTaxInsertRec = new Individual_Tax__c(Deal__c = dealId);
                        individualTaxInsertRec.Sales_Tax_Item__c = individualTaxRec.Sales_Tax_Item__c;
                        individualTaxInsertRec.Sales_Tax_Item_Name__c = individualTaxRec.Sales_Tax_Item__r.Name__c;
                        individualTaxInsertRec.Taxable_Amount_for_Section_Header__c = 0;
                        if(individualTaxRec.Sales_Tax_Item__r.Rate_Type__c == TaxManagementService.FIXED_RATE) {
                            individualTaxInsertRec.Tax_Rate__c = individualTaxRec.Tax_Rate__c;
                        }
                        taxRateIdToIndividualTaxRecMap.put(individualTaxRec.Sales_Tax_Item__c, individualTaxInsertRec);
                    }
                    Individual_Tax__c individualTaxRecToUpdate = taxRateIdToIndividualTaxRecMap.get(individualTaxRec.Sales_Tax_Item__c);
                    individualTaxRecToUpdate.Taxable_Amount_for_Section_Header__c += (individualTaxRec.Taxable_Amount__c != null ? individualTaxRec.Taxable_Amount__c : 0);
                    if(individualTaxRec.Enhanced_Tax_Amount__c != null) {
                        (individualTaxRecToUpdate.Enhanced_Tax_Amount__c = individualTaxRecToUpdate.Enhanced_Tax_Amount__c != null ? individualTaxRecToUpdate.Enhanced_Tax_Amount__c : 0);
                        individualTaxRecToUpdate.Enhanced_Tax_Amount__c += (individualTaxRec.Enhanced_Tax_Amount__c != null ? individualTaxRec.Enhanced_Tax_Amount__c : 0);
                    }
                }
                individualTaxInsertList.addAll(taxRateIdToIndividualTaxRecMap.values());
                individualTaxDeleteList.addAll(dealIdToIndividualTaxesMap.get(dealId));
            }
            
            delete individualTaxDeleteList;
            upsert individualTaxInsertList;
        }
    }
    
    global override void finishScript(Database.BatchableContext bc) {}

    private static Map<Id, List<Individual_Tax__c>> getDealIdToIndividualTaxesMap(List<Deal__c> dealList, Map<Id, Map<Id, Individual_Tax__c>> dealIdToTaxRateIdToIndividualTaxRecMap) {
        Map<Id, List<Individual_Tax__c>> dealIdToIndividualTaxesMap = new Map<Id, List<Individual_Tax__c>>();
        if(dealList != null && !dealList.isEmpty()) {
            List<Individual_Tax__c> individualTaxList = [select Sales_Tax_Item__c, Taxable_Amount__c, Tax_Rate__c, Option_Fee__r.Deal_Item__c, Option_Fee__r.Deal__c, 
                Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c, Deal_Unit_Price_Cost__r.Deal_Item__c, Deal_Item__r.Deal__c, F_I_Product__r.Deal__c, 
                Form_Label__c, Applicable_Tax__c, List_Tax_items_on_forms__c, Taxable_Amount_for_Section_Header__c, Deal__c, 
                Enhanced_Tax_Amount__c, Sales_Tax_Item__r.Rate_Type__c, Sales_Tax_Item__r.Name__c, SO_Payment_Role__c, SO_Payment_Role__r.Applicable_Tax_Name__c  
                from Individual_Tax__c
                where Option_Fee__r.Deal__c IN: dealList
                OR Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c IN: dealList
                OR (Deal_Item__r.Deal__c IN: dealList AND Deal_Item__r.Type__c = 'Trade In')
                OR F_I_Product__r.Deal__c IN: dealList
                OR Deal__c IN: dealList];

            for(Individual_Tax__c taxRec : individualTaxList) {
                String dealId;
                if(taxRec.Option_Fee__c != null && taxRec.Option_Fee__r.Deal__c != null) {
                    dealId = taxRec.Option_Fee__r.Deal__c;
                } else if(taxRec.Deal_Unit_Price_Cost__c != null && taxRec.Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c != null) {
                    dealId = taxRec.Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c;
                } else if(taxRec.Deal_Item__c != null && taxRec.Deal_Item__r.Deal__c != null) {
                    dealId = taxRec.Deal_Item__r.Deal__c;
                } else if(taxRec.F_I_Product__c != null && taxRec.F_I_Product__r.Deal__c != null) {
                    dealId = taxRec.F_I_Product__r.Deal__c;
                } else if(taxRec.Deal__c != null) {
                    if(!dealIdToTaxRateIdToIndividualTaxRecMap.containsKey(taxRec.Deal__c)) {
                        dealIdToTaxRateIdToIndividualTaxRecMap.put(taxRec.Deal__c, new Map<Id, Individual_Tax__c>());
                    }
                    dealIdToTaxRateIdToIndividualTaxRecMap.get(taxRec.Deal__c).put(taxRec.Sales_Tax_Item__c, taxRec);
                }
                if(String.isNotBlank(dealId)) {
                    if(!dealIdToIndividualTaxesMap.containsKey(dealId)) {
                        dealIdToIndividualTaxesMap.put(dealId, new List<Individual_Tax__c>());
                    }
                    dealIdToIndividualTaxesMap.get(dealId).add(taxRec);
                }
            }
        }
        return dealIdToIndividualTaxesMap;
    }

}