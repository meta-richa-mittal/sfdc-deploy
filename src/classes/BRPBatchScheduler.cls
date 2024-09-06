global without sharing class BRPBatchScheduler implements Schedulable {
    
    global Set<Id> recordIdSet;
    private String entityName;

    global BRPBatchScheduler(Set<Id> recordIdSet, String entityName){
        this.recordIdSet = recordIdSet;
        this.entityName = entityName;
    }
    
    global void execute(SchedulableContext sc) {
        if(BRPUtility.isBRPEnabled()) {
            BRPUtility.initiateBatch(recordIdSet, entityName);
        }
    }
}