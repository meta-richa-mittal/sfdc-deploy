global without sharing class PopulatedStoreAutomatedTaxRatesScheduler implements Schedulable {
    global void execute(SchedulableContext sc) { 
        if(Configurations__c.getOrgDefaults().Automatic_tax_rates__c) {
            populateStoreAutomatedTaxRates();
        }
    }

    @future (callout=true)
    public static void populateStoreAutomatedTaxRates() {
        ZipTaxService.populateStoreAutomatedTaxRates();
        
        List<Business_Profile__c> businessProfileList = [SELECT Id, Business_State__c FROM Business_Profile__c WHERE Business_State__r.Auto_Tax_Calc__c = false LIMIT 1];
        if(!businessProfileList.isEmpty()) {
            State__c stateRec = new State__c(Id = businessProfileList[0].Business_State__c, Auto_Tax_Calc__c = true);
            DMLUtility.updateSobjectList('State__c', stateRec);
        }
    }
}