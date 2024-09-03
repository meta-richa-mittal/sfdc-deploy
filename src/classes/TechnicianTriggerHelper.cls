public without sharing class TechnicianTriggerHelper {

    public static void afterUpdate(List<Technician__c> newList, Map<Id, Technician__c> oldMap) {
        updateSalespersonNameOnCOs(newList, oldMap);
    }

    public static void updateSalespersonNameOnCOs(List<Technician__c> newList, Map<Id, Technician__c> oldMap) {
        if(!System.isBatch() && !System.isFuture() && newList != null && oldMap != null) {
            Set<Id> techWithUpdatedNameIdSet = new Set<Id>();
            for(Technician__c tech : newList) {
                if(String.isNotBlank(tech.Technician_Name__c) && tech.Technician_Name__c != oldMap.get(tech.Id).Technician_Name__c) {
                    techWithUpdatedNameIdSet.add(tech.Id);
                }
            }
            if(!techWithUpdatedNameIdSet.isEmpty()) {
                List<CO_Salesperson__c> coSalespersonList = [Select Id FROM CO_Salesperson__c WHERE Technician__c IN: techWithUpdatedNameIdSet LIMIT 1];
                if(!coSalespersonList.isEmpty()) {
                    Database.executeBatch(new ResetSalespersonNameOnCOBatch(techWithUpdatedNameIdSet));
                }
            }
        }
    }
}