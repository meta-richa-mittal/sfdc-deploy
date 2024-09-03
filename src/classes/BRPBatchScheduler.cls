global without sharing class BRPBatchScheduler implements Schedulable {
    
    global Set<Id> recordIdSet;
    private String entityName;
    public Integer retryAttemptNumber;

    global BRPBatchScheduler(Set<Id> recordIdSet, String entityName) {
        this.recordIdSet = recordIdSet;
        this.entityName = entityName;
    }

    global BRPBatchScheduler(Set<Id> recordIdSet, String entityName, Integer retryAttemptNumber){
        this.recordIdSet = recordIdSet;
        this.entityName = entityName;
        this.retryAttemptNumber = retryAttemptNumber;
    }
    
    global void execute(SchedulableContext sc) {
        if(BRPUtility.isBRPEnabled()) {
            BRPUtility.initiateBatch(recordIdSet, entityName, retryAttemptNumber);
        }
    }
}