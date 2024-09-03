/**
 * @description       : Batch to delete all false Elastic sync log
 * @last modified on  : 09-May-2023
 * @last modified by  : Balveer Choudhary
**/
global without sharing class ElasticSyncLogDeleteBatch extends PostInstallScriptBaseBatch {

    global ElasticSyncLogDeleteBatch() {}
    global override Database.QueryLocator startScript(Database.BatchableContext BC) {return null;}
    global override void executeScript(Database.BatchableContext BC, List<sObject> scope) {}
    global override void finishScript(Database.BatchableContext BC){}
}