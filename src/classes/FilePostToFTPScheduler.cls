/**
 * Author: Richa Mittal
 * Since: Feb 27, 2021
 * Name: FilePostToFTPScheduler
 * Description: Scheduler class to schedule posting of files to FTP
**/
global without sharing class FilePostToFTPScheduler implements Schedulable {
    
    private String exportType;
    private String attachmentIdsString;
    
    global FilePostToFTPScheduler(String exportType, String attachmentIdsString) {
        this.exportType = exportType;
        this.attachmentIdsString = attachmentIdsString;
    }
    
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new FilePostToFTPQueueable(this.exportType, this.attachmentIdsString));
        
    }
}