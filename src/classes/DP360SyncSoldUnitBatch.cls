/**
 * Author: Manoj Sharma
 * Since: Oct 26, 2022
 * Name: DP360SyncSoldUnitBatch
 * Description: Batch class to sync all sold units to DP360 and make their status inactive.
**/
global without sharing class DP360SyncSoldUnitBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = \'STOCK\' AND Status__c = \'Sold\' AND DP360_Inventory_Id__c != Null Order By Name ASC ';
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
