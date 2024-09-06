/** 
* Author: Manoj Sharma
* Since: Sept 28, 2021
* Name: MergeAndPostToBRPScheduler 
* Description: Apex Scheduler class to call BRP file posting queueable.
**/
global without sharing class MergeAndPostToBRPScheduler implements Schedulable {
    public String exportType;
    public Set<String> attachmentIdList;
    DateTime dateTimeValue;
    Boolean isRetryFilePosting;

    public MergeAndPostToBRPScheduler(String exportType, Set<String> attIdList, DateTime dateTimeValue, Boolean retryFilePosting) {
        this.exportType = exportType;
        this.attachmentIdList = attIdList;
        this.dateTimeValue = dateTimeValue;
        this.isRetryFilePosting = retryFilePosting;
    }

    global void execute(SchedulableContext sc) {
        System.enqueueJob(new MergeAndPostToBRPQueueable(this.exportType, this.attachmentIdList, this.dateTimeValue, this.isRetryFilePosting));
    }
}
