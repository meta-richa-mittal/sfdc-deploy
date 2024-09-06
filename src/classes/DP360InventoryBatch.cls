/**
 * Author: Tarun Khandelwal
 * Since: Nov 05, 2020
 * Name: DP360InventoryBatch
 * Description: Batch to sync inventory to DP360
**/
global without sharing class DP360InventoryBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    private Set<Id> unitIds;
    global DP360InventoryBatch(){}
    global DP360InventoryBatch(Set<Id> unitIds) {
        this.unitIds = unitIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c IN (\'STOCK\', \'ORDU\') AND Available_For_DP360_Sync__c = TRUE AND Status__c != \'Received\'';
        if(unitIds != null) {
            query += ' AND Id IN: unitIds';
        }
        return Database.getQueryLocator(query); 
    }
    
    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> unitList) {
        Set<Id> unitIdSet = new Set<Id>();
        for(Customer_Owned_Unit__c unit : unitList) {
            unitIdSet.add(unit.Id);
        }
        DP360InventoryService.createUnitsInDP360(unitIdSet);
    }
    
    global void finish(Database.batchableContext bc) {
        
    }
}