/**
 * Author: Tarun Khandelwal
 * Since: Nov 07, 2020
 * Name: DP360InventoryBatch
 * Description: Batch to sync inventory to DP360
**/
public without sharing class DP360LeadBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    private Set<Id> dealIds;
    public DP360LeadBatch(Set<Id> dealIds) {
        this.dealIds = dealIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT DP360_Lead_Id__c FROM Deal__c WHERE Available_For_DP360_Sync__c = TRUE';
        if(dealIds != null) {
            query += ' AND Id IN: dealIds';
        }
        return Database.getQueryLocator(query); 
    }
    
    public void execute(Database.batchableContext bc, List<Deal__c> dealList) {
        for(Deal__c deal : dealList) {
            DP360LeadService.closeLeadInDP360(Integer.valueOf(deal.DP360_Lead_Id__c), deal.Id);
        }
    }
    
    public void finish(Database.batchableContext bc) {
        
    }
}