public without sharing class FilePostToFTPQueueable implements Queueable, Database.AllowsCallouts {
    
    public String exportType;
    public String attachmentIdsString;
    
    public FilePostToFTPQueueable(String exportType, String attachmentIdsString) {
        this.exportType = exportType;
        this.attachmentIdsString = attachmentIdsString;
    }
    
    public void execute(QueueableContext context) {
        if(String.isNotBlank(this.attachmentIdsString)){
            GenericExportService.sendFileToFTP(this.exportType, this.attachmentIdsString);
        }
    }   
}