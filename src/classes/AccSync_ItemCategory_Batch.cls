/*
    Apex class to sync Item Category with accounting server
*/
global without sharing class AccSync_ItemCategory_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Category__c> itemCategoryListToUpdate;
    global List<Log__c> errorLogToInsert;
     
    global Database.QueryLocator start(Database.BatchableContext bc){
        return null;
    }

    global void execute(Database.batchableContext bc, List<Category__c> listItemCategories) {}
 
    global void finish(Database.batchableContext bc){}
}