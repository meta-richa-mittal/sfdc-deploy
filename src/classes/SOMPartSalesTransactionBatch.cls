/**
* Author: Nidhi Sharma
* Since: Nov 7, 2019
* Name: SOMPartSalesTransactionBatch
* Description:
**/
global without sharing class SOMPartSalesTransactionBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
	
	// This batch is deprecated now, we are instead using SOMPartSalesTransactionBatchScheduler
    global SOMPartSalesTransactionBatch(Date dateValueToFilter) {}

    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery;
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.batchableContext bc, List<CO_Line_Item__c> coliList) {}

    global void finish(Database.batchableContext bc) {}
}