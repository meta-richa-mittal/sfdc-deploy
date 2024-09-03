public without sharing class BRPIntegrationExceptionHandler {
    
    private String entityName;
    
    public BRPIntegrationExceptionHandler(String entityName) {
        this.entityName = entityName;
    }
    
    // Call the Batch class to resync the failed entities. 
    public void doRetry(Set<Id> entitySFIdSet, Integer retryRequestNumber) {
        Integer retryAttemptNumber = retryRequestNumber == null ? 2 : (retryRequestNumber + 1);
        BRPUtility.initiateBatch(entitySFIdSet, this.entityName, retryAttemptNumber);
    }

    public void doRetryWithScheduledJob(Set<Id> entitySFIdSet, Integer timeIntervalInSec, Integer retryRequestNumber) {
        if(entitySFIdSet.size() > 0) {
            BRPUtility.SchedulerTimeInterval = timeIntervalInSec;
            Integer retryAttemptNumber = retryRequestNumber == null ? 2 : (retryRequestNumber + 1);
            BRPScriptUtil.scheduleBatchJobs(new List<Id>(entitySFIdSet), 25, 60, this.entityName, retryAttemptNumber);
        }
    }
}