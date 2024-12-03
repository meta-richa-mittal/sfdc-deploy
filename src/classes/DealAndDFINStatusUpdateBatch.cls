/**
 * Author: Nidhi Sharma
 * Since: Dec 26, 2022
 * Name: DealAndDFINStatusUpdateBatch
 * Description: Batch for Populating status fields on deal and deal finance
**/
global without sharing class DealAndDFINStatusUpdateBatch implements Database.Batchable<sobject> {
	global Database.QueryLocator start(Database.BatchableContext bc) {return null;}
    global void execute(Database.batchableContext bc, List<Deal__c> dealRecList) {}
    global void finish(Database.batchableContext bc) {}
}
