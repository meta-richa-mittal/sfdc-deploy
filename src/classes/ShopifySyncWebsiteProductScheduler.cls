/**
 * Author: Balveer Choudhary
 * Since: AUG 03, 2022
 * Name: ShopifySyncWebsiteProductScheduler
 * Description: Scheduler class for ShopifySyncWebsiteProductQueueable
**/
global without sharing class ShopifySyncWebsiteProductScheduler implements Schedulable {
    
    public List<Website_Product__c> productList = new List<Website_Product__c>();
    public Integer retryAttemptNumber;
    
    global ShopifySyncWebsiteProductScheduler(List<Website_Product__c> productListToSync, Integer retryAttemptNumber){
        this.productList = productListToSync;
        this.retryAttemptNumber = retryAttemptNumber;
    }
    
    global void execute(SchedulableContext sc) {
		system.enqueueJob(new ShopifySyncWebsiteProductQueueable(this.productList, this.retryAttemptNumber));
	}
}