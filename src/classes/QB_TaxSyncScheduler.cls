global without sharing class QB_TaxSyncScheduler implements Schedulable {
    
    global String syncType;
    global QB_TaxSyncScheduler() {}
    global QB_TaxSyncScheduler(String syncType){
        this.syncType = syncType;
    }
    
    global void execute(SchedulableContext sc) {
        
    }
}