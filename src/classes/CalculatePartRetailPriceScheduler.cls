/**
 * Author: Nidhi Sharma
 * Since: April 03, 2023
 * Name: CalculatePartRetailPriceScheduler
 * Description: Scheduler class to schedule CalculatePartRetailPrice_Batch
**/
global without sharing class CalculatePartRetailPriceScheduler implements Schedulable {

    Set<Id> vendorIdSet = new Set<Id>();
    global CalculatePartRetailPriceScheduler(Set<Id> vendorIdSet) {
        this.vendorIdSet = vendorIdSet;
    }

    global void execute(SchedulableContext sc) {
        CalculatePartRetailPrice_Batch batchObj = new CalculatePartRetailPrice_Batch(this.vendorIdSet, 50);
    }
}