global without sharing class SyncDataToElasticSearchBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    global SyncDataToElasticSearchBatch() {}
    global Database.QueryLocator start(Database.BatchableContext bc){return  null;}
    global void execute(Database.batchableContext bc, List<Sync_Error_Log__c> errorLogList) {}
    global void finish(Database.batchableContext bc) {}
}