/**
 * Author: Nidhi Sharma
 * Since: Dec 19, 2022
 * Name: DFINProductCostFieldsBatch
 * Description: Batch for Populating cost fields on financing products
**/
global without sharing class DFINProductCostFieldsBatch implements Database.Batchable<sobject> {
	global Database.QueryLocator start(Database.BatchableContext bc) {return null;}
    global void execute(Database.batchableContext bc, List<F_I_Product__c> fiProductList) {}
    global void finish(Database.batchableContext bc) {}
}