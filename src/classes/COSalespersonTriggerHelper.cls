/**
 * Author: Nidhi Sharma
 * Since: June 25, 2023
 * Name: COSalespersonTriggerHelper
**/
public without sharing class COSalespersonTriggerHelper {

    public static Boolean isForceStopTrigger = false;

    public static void afterInsert(List<CO_Salesperson__c> newList) {
        setSalespersonNameOnCO(newList);
    }

    public static void afterUpdate(List<CO_Salesperson__c> newList) {
        setSalespersonNameOnCO(newList);
    }

    public static void afterDelete(List<CO_Salesperson__c> oldList) {
        setSalespersonNameOnCO(oldList);
    }

    public static void setSalespersonNameOnCO(List<CO_Salesperson__c> coSalespersonList) {
        if(coSalespersonList != null && !coSalespersonList.isEmpty()) {
            Set<Id> dealIds = new Set<Id>();
            Set<Id> soIds = new Set<Id>();
            Set<Id> coIds = new Set<Id>();
            Set<Id> coInvIds = new Set<Id>();
            Set<Id> coHeaderToUpdateIds = new Set<Id>();
            for(CO_Salesperson__c sp : coSalespersonList) {
                if(sp.Deal__c != null && sp.CO_Header__c == null) dealIds.add(sp.Deal__c);
                if(sp.Service_Order_Header__c != null) soIds.add(sp.Service_Order_Header__c);
                if(sp.CO_Header__c != null && sp.Deal__c == null) coIds.add(sp.CO_Header__c);
                if(sp.CO_Header__c != null && sp.Deal__c != null) coHeaderToUpdateIds.add(sp.CO_Header__c);
                if(sp.CO_Invoice_Header__c != null) coInvIds.add(sp.CO_Invoice_Header__c);
            }

            Map<Id, SObject> sobjUpdateMap = new Map<Id, SObject>();
            if(!coIds.isEmpty()) {
                for(CO_Header__c coRec : [Select Salesperson_Names__c, (Select Technician__r.Technician_Name__c FROM CO_Salespersons__r WHERE Technician__c != null AND Deal__c = null Order By CreatedDate) FROM CO_Header__c WHERE Id IN: coIds]) {
                    coRec.Salesperson_Names__c = getNewSalespersonNames(coRec.Salesperson_Names__c, coRec.CO_Salespersons__r);
                    if(coRec.Salesperson_Names__c != null) sobjUpdateMap.put(coRec.Id, coRec);
                    coHeaderToUpdateIds.add(coRec.Id);
                }
            }
            if(!dealIds.isEmpty()) {
                for(Deal__c dealRec : [Select Salesperson_Names__c, CO_Header__c, (Select Technician__r.Technician_Name__c FROM CO_Salespersons__r WHERE Technician__c != null Order By CreatedDate) FROM Deal__c WHERE Id IN: dealIds]) {
                    dealRec.Salesperson_Names__c = getNewSalespersonNames(dealRec.Salesperson_Names__c, dealRec.CO_Salespersons__r);
                    if(dealRec.Salesperson_Names__c != null) sobjUpdateMap.put(dealRec.Id, dealRec);
                    coHeaderToUpdateIds.add(dealRec.CO_Header__c);
                }
            }
            if(!soIds.isEmpty()) {
                for(Service_Order_Header__c soRec : [Select Salesperson_Names__c, CO_Header__c, (Select Technician__r.Technician_Name__c FROM CO_Salespersons__r WHERE Technician__c != null Order By CreatedDate) FROM Service_Order_Header__c WHERE Id IN: soIds]) {
                    soRec.Salesperson_Names__c = getNewSalespersonNames(soRec.Salesperson_Names__c, soRec.CO_Salespersons__r);
                    if(soRec.Salesperson_Names__c != null) sobjUpdateMap.put(soRec.Id, soRec);
                    coHeaderToUpdateIds.add(soRec.CO_Header__c);
                }
            }
            if(!coInvIds.isEmpty()) {
                for(CO_Invoice_Header__c coInvRec : [Select Salesperson__c, (Select Technician__r.Technician_Name__c FROM CO_Salespersons__r WHERE Technician__c != null Order By CreatedDate) FROM CO_Invoice_Header__c WHERE Id IN: coInvIds]) {
                    coInvRec.Salesperson__c = getNewSalespersonNames(coInvRec.Salesperson__c, coInvRec.CO_Salespersons__r);
                    if(coInvRec.Salesperson__c != null) sobjUpdateMap.put(coInvRec.Id, coInvRec);
                }
            }

            updateCOHeaderSalespersonNames(coHeaderToUpdateIds, sobjUpdateMap);
            if(!sobjUpdateMap.isEmpty()) {
                COInvoiceTriggerHelper.isForceStopTrigger = COTriggerHelper.isForceStopTrigger = DealTriggerHelper.isForceStopTrigger = SOTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectListWithRetry(sobjUpdateMap.values());
                COInvoiceTriggerHelper.isForceStopTrigger = COTriggerHelper.isForceStopTrigger = DealTriggerHelper.isForceStopTrigger = SOTriggerHelper.isForceStopTrigger = false;
            }
        }
    }

    public static String getNewSalespersonNames(String prevNames, List<CO_Salesperson__c> coSalespersonList) {
        Map<Id, String> techIdToNameMap = new Map<Id, String>();
        for(CO_Salesperson__c sp : coSalespersonList) {
            if(String.isNotBlank(sp.Technician__r.Technician_Name__c)) techIdToNameMap.put(sp.Technician__c, sp.Technician__r.Technician_Name__c);
        }
        if(!String.join(techIdToNameMap.values(), ',').equalsIgnoreCase(prevNames)) {
            return String.join(techIdToNameMap.values(), ',');
        }
        return null;
    }

    public static void updateCOHeaderSalespersonNames(Set<Id> coHeaderToUpdateIds, Map<Id, SObject> sobjUpdateMap) {
        Map<Id, List<CO_Salesperson__c>> coIdToSalesPersonListMap = new Map<Id, List<CO_Salesperson__c>>();
        if(!coHeaderToUpdateIds.isEmpty()) {
            for(CO_Salesperson__c sp: [Select Technician__r.Technician_Name__c, CO_Header__c, Service_Order_Header__r.CO_Header__c, 
                                        Deal__r.CO_Header__c FROM CO_Salesperson__c WHERE 
                                        (CO_Header__c IN: coHeaderToUpdateIds OR 
                                        Service_Order_Header__r.CO_Header__c IN: coHeaderToUpdateIds OR 
                                        Deal__r.CO_Header__c IN: coHeaderToUpdateIds) 
                                        AND Technician__c != null Order By CreatedDate]) {
                String coId = sp.CO_Header__c != null ? sp.CO_Header__c : (sp.Service_Order_Header__r.CO_Header__c != null ? sp.Service_Order_Header__r.CO_Header__c : sp.Deal__r.CO_Header__c);  
                if(!coIdToSalesPersonListMap.containsKey(coId)) {
                    coIdToSalesPersonListMap.put(coId, new List<CO_Salesperson__c>());
                }
                coIdToSalesPersonListMap.get(coId).add(sp);
            }
        }

        for(Id coId: coHeaderToUpdateIds) { // for adding co when there the last salesperson is deleted
            if(!coIdToSalesPersonListMap.containsKey(coId)) coIdToSalesPersonListMap.put(coId, new List<CO_Salesperson__c>());
        }

        for(Id coId: coIdToSalesPersonListMap.keySet()) {
            CO_Header__c coRecToUpdate = new CO_Header__c(Id = coId);
            if(sobjUpdateMap.containsKey(coId)) {
                coRecToUpdate = (CO_Header__c)sobjUpdateMap.get(coId);
            }
            coRecToUpdate.CO_Salesperson_Names__c = getNewSalespersonNames(null, coIdToSalesPersonListMap.get(coId));
            if(coRecToUpdate.CO_Salesperson_Names__c != null) sobjUpdateMap.put(coRecToUpdate.Id, coRecToUpdate);
        }
    }
}