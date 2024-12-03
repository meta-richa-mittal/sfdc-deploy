public without sharing class SyncAccountingTransactionsQueueable implements Queueable {
    public List<String> failedEntityNameList;
    public SyncAccountingTransactionsQueueable(List<String> failedEntityNames) {
        this.failedEntityNameList = failedEntityNames;
    }
    
    public void execute(QueueableContext context) {
        Database.executeBatch(new SyncAccountingTransactionsScheduler(this.failedEntityNameList));
    }  
}