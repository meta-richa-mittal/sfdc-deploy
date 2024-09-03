/**
 * Author: Balveer Choudhary
 * Since: Dec 8, 2023
 * Name: SOQLToFileScheduler
 * Description: Scheduler class for FTP/FTPs/SFTP file posting
**/
global without sharing class SOQLToFileScheduler implements Schedulable {

    public string exportType;

    global SOQLToFileScheduler(String exportType) {
        this.exportType = exportType;
    }

    global void execute(SchedulableContext sc) {   
        doFilePost(this.exportType);
    }
    
    @future (callout=true)
    public static void doFilePost(String exportType) {  
        SOQLToFileService.doFilePost(exportType);
    }
}