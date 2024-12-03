/**
 * Author: Nidhi Sharma
 * Since: August 2, 2024
 * Name: CreateIndividualTaxesUnderUPCBatch
 * Description: 
**/
global without sharing class CreateIndividualTaxesUnderUPCBatch extends PostInstallScriptBaseBatch {

    global CreateIndividualTaxesUnderUPCBatch() {
        this.scriptName = 'executeCreateIndividualTaxesUnderUPCBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id FROM Unit_Price_Cost__c WHERE Applicable_Tax__c != null AND (Customer__c != null OR Vendor__c != null) AND Unit_Type__c = \'STOCK\'';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> upcList) {
        List<Unit_Price_Cost__c> upcListToProcess = new List<Unit_Price_Cost__c>();
        for(Unit_Price_Cost__c upcRec : [SELECT Total_Cost__c, Applicable_Tax__c, Customer__c, (Select Id FROM Individual_Taxes__r LIMIT 1) FROM Unit_Price_Cost__c WHERE Id IN: upcList]) {
            if(upcRec.Individual_Taxes__r.isEmpty()) upcListToProcess.add(upcRec);
        }
        createIndividualTaxes(upcListToProcess);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}

    private void createIndividualTaxes(List<Unit_Price_Cost__c> upcList) {
        Set<Id> salesTaxIds = new Set<Id>();
        for(Unit_Price_Cost__c upcRec : upcList) {
            if(upcRec.Applicable_Tax__c != null) salesTaxIds.add(upcRec.Applicable_Tax__c);
        }
        if(!salesTaxIds.isEmpty()) {
            Map<Id, List<Applicable_Taxes__c>> salesTaxIdToAppTaxRecordsMap = new Map<Id, List<Applicable_Taxes__c>>();
            List<Applicable_Taxes__c> applicableTaxList = TaxManagementSOQLUtil.getApplicableTaxListBySalesTaxIdList(new List<Id>(salesTaxIds));
            for(Applicable_Taxes__c appTax : applicableTaxList) {
                if(!salesTaxIdToAppTaxRecordsMap.containsKey(appTax.Sales_Tax__c)) {
                    salesTaxIdToAppTaxRecordsMap.put(appTax.Sales_Tax__c, new List<Applicable_Taxes__c>());
                } 
                salesTaxIdToAppTaxRecordsMap.get(appTax.Sales_Tax__c).add(appTax);
            }
            List<Individual_Tax__c> individualTaxInsertList = new List<Individual_Tax__c>();
            List<Unit_Price_Cost__c> upcUpdateList = new List<Unit_Price_Cost__c>();
            for(Unit_Price_Cost__c upcRec : upcList) {
                Decimal taxRate = 0;
                if(upcRec.Individual_Taxes__r.isEmpty() && upcRec.Applicable_Tax__c != null && salesTaxIdToAppTaxRecordsMap.get(upcRec.Applicable_Tax__c) != null) {
                    for(Applicable_Taxes__c appTax : salesTaxIdToAppTaxRecordsMap.get(upcRec.Applicable_Tax__c)) {
                        Sales_Tax_Item__c stiRec = appTax.Sales_Tax_Item__r;
                        Individual_Tax__c individualTaxRec = new Individual_Tax__c();
                        individualTaxRec.Unit_Price_Cost__c = upcRec.Id;
                        individualTaxRec.Sales_Tax_Item__c = stiRec.Id;
                        individualTaxRec.Sales_Tax_Item_Name__c = stiRec.Name__c;
                        individualTaxRec.Taxable_Amount_for_Section_Header__c = upcRec.Total_Cost__c;
                        if(stiRec.Rate_Type__c == TaxManagementService.FIXED_RATE) {
                            individualTaxRec.Tax_Rate__c = stiRec.Rate__c;
                        } else {
                            individualTaxRec.Enhanced_Tax_Amount__c = TaxEngine.getEnhancedTaxAmount(individualTaxRec.Taxable_Amount_for_Section_Header__c, stiRec);
                        }
                        if((stiRec.Rate__c != null && stiRec.Rate__c != 0) || (individualTaxRec.Enhanced_Tax_Amount__c != null && individualTaxRec.Enhanced_Tax_Amount__c != 0)) {
                            individualTaxInsertList.add(individualTaxRec);
                        }
                        if(stiRec.Rate__c != null) taxRate += stiRec.Rate__c;
                    }
                    
                }
                if(GeneralConfiguration.getTaxIncludingPricing()) {
                    upcRec.Tax__c = taxRate;
                    upcUpdateList.add(upcRec);
                }
            }
            DMLUtility.insertSobjectList('Individual_Tax__c', individualTaxInsertList);
            if(!upcUpdateList.isEmpty()) {
                UnitPriceAndCostTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('Unit_Price_Cost__c', upcUpdateList);
            }
        }
    }
}