/**
 * Author: Nidhi Sharma
 * Since: April 10, 2023
 * Name: BusinessProfileTriggerHelper
 * Description: Trigger helper for Business_Profile__c object
**/
public without sharing class BusinessProfileTriggerHelper {

    public static Boolean isForceStopTrigger = false;

    public static void afterInsert(List<Business_Profile__c> newList) {
        populateCountryInBPConfig(newList, null);
        populateAutomatedTaxRates(newList, null);
    }

    public static void afterUpdate(List<Business_Profile__c> newList, Map<Id, Business_Profile__c> oldMap) {
        populateCountryInBPConfig(newList, oldMap);
        populateAutomatedTaxRates(newList, oldMap);
    }

    private static void populateCountryInBPConfig(List<Business_Profile__c> newList, Map<Id, Business_Profile__c> oldMap) {
        Id countryId;
        Boolean isCountryUpdated = false;
        for(Business_Profile__c businessProfileRec : newList) {
            if((oldMap == null || oldMap.get(businessProfileRec.Id).Business_Country__c != businessProfileRec.Business_Country__c)) {
                countryId = businessProfileRec.Business_Country__c;
                isCountryUpdated = true;
            }
        }
        BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        if(isCountryUpdated) {
            if(String.isNotBlank(countryId)) {
                for(Country__c countryRec : [Select Name__c From Country__c WHERE Id =: countryId]) {
                    bpConfig.Dealership_Country__c = countryRec.Name__c;
                }
            } else {
                bpConfig.Dealership_Country__c = null;
            }
        }
        upsert bpConfig;
    }

    private static void populateAutomatedTaxRates(List<Business_Profile__c> newList, Map<Id, Business_Profile__c> oldMap) {
        if(Configurations__c.getOrgDefaults().Automatic_tax_rates__c) {
            if(Trigger.isInsert) {
                PopulatedStoreAutomatedTaxRatesScheduler.populateStoreAutomatedTaxRates();
            } else {
                for(Business_Profile__c businessProfileRec : newList) {
                    if(oldMap.get(businessProfileRec.Id).Business_Street_Address1__c != businessProfileRec.Business_Street_Address1__c ||
                        oldMap.get(businessProfileRec.Id).Business_Street_Address2__c != businessProfileRec.Business_Street_Address2__c ||
                        oldMap.get(businessProfileRec.Id).Business_Postal_Code__c != businessProfileRec.Business_Postal_Code__c ||
                        oldMap.get(businessProfileRec.Id).Business_City__c != businessProfileRec.Business_City__c ||
                        oldMap.get(businessProfileRec.Id).Business_State__c != businessProfileRec.Business_State__c) {
                        PopulatedStoreAutomatedTaxRatesScheduler.populateStoreAutomatedTaxRates();
                        break;
                    }
                }
            }
        }
    }
}