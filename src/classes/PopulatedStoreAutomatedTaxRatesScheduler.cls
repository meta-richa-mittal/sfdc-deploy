global without sharing class PopulatedStoreAutomatedTaxRatesScheduler implements Schedulable {
    global void execute(SchedulableContext sc) { 
        if(Configurations__c.getOrgDefaults().Automatic_tax_rates__c) {
            populateStoreAutomatedTaxRates();
        }
    }

    @future (callout=true)
    public static void populateStoreAutomatedTaxRates() {
        ZipTaxService.populateStoreAutomatedTaxRates();
    }
}