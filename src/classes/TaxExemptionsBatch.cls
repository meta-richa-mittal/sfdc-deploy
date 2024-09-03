/** 
* Author: Yash Sharma
* Since: Oct 23, 2018
* Name: TaxExemptionsBatch
* Description: Batch class to do the data updation for Sprint_75 release.
* Populating TaxExemptions on all existing Open CustomerOrders from their' Customer's AccountType. Similarly for ServiceOrderHeader as well.
**/
global without sharing class TaxExemptionsBatch implements Database.Batchable<sobject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        String baseQuery = 'Select Id, Customer__c, Order_Status__c, (select Id, Provider__c from Service_Order_Headers__r) from CO_Header__c';
        return Database.getQueryLocator(baseQuery); 
    }

    global void execute(Database.batchableContext bc, List<CO_Header__c> coHeaderList) {
        
        // Populate TaxExemptions for COHeader
        setAccountTypeOnCO(coHeaderList);
        COTriggerHelper.populateTaxExemptions(coHeaderList, true);
        
        // Populate TaxExemptions for SOHeader for CO
        List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
        for(CO_Header__c coHeaderRec : coHeaderList) {
            soHeaderList.addAll(coHeaderRec.Service_Order_Headers__r);
        }
        SOTriggerHelper.populateTaxExemptions(soHeaderList);
    }  
    
    global void finish(Database.batchableContext bc) {}
    
    public static void setAccountTypeOnCO(List<CO_Header__c> coList) {
        Boolean isCashSale = false;
        Set<Id> customersIdSet = new Set<Id>();
        for(CO_Header__c coHeaderRec : coList) {
            if(coHeaderRec.Customer__c != null) {
                customersIdSet.add(coHeaderRec.Customer__c);
            } else if(String.isNotBlank(coHeaderRec.CO_Type__c) && coHeaderRec.CO_Type__c.equalsIgnoreCase(Constants.CASH_SALE)) {
                isCashSale = true;
            }
        }
        Map<Id, Account> customerIdToAccountTypeMap = new Map<ID, Account>();
        if(customersIdSet.size() > 0) {
            if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            customerIdToAccountTypeMap = new Map<ID, Account>([select Id, Account_Type__c from Account Where Id IN :customersIdSet AND Account_Type__c != null]);
        }

        Id defaultAccountTypeId = AccountTypeService.getDefaultAccoutTypeRecId('Customers');
        
        for(CO_Header__c coHeaderRec : coList) {
            if(coHeaderRec.Customer__c != null && customerIdToAccountTypeMap.containsKey(coHeaderRec.Customer__c)) {
                coHeaderRec.Account_Type__c = customerIdToAccountTypeMap.get(coHeaderRec.Customer__c).Account_Type__c;
            } else if(coHeaderRec.Customer__c != null || (String.isNotBlank(coHeaderRec.CO_Type__c) && coHeaderRec.CO_Type__c.equalsIgnoreCase(Constants.CASH_SALE))) {
                coHeaderRec.Account_Type__c = defaultAccountTypeId;
            }
        }
    }
}