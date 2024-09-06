/**
 * Author: Tarun Khandelwal
 * Since: April 22, 2021
 * Name: MergeAndPostToSOMScheduler
 * Description: Scheduler class to schedule posting of files to SOM Server
**/
global without sharing class MergeAndPostToSOMScheduler implements Schedulable {
    
    global MergeAndPostToSOMScheduler() {}
    
    global void execute(SchedulableContext sc) {
        BP_Configurations__c BPConfigurations = BP_Configurations__c.getOrgDefaults();
        BPConfigurations.SOM_File_Posting_Retry_Count__c = 0;
		upsert BPConfigurations;
        System.enqueueJob(new MergeAndPostToSOMQueueable());
    }
}