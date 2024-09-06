public without sharing class IntegrationExceptionHandler {
    
    private String entityName;
    
    public IntegrationExceptionHandler(String entityName) {
        this.entityName = entityName;
    }
    
    // Call the Batch class to resync the failed entities. 
    // No scheduled Job needed
    public void doRetry(Set<Id> entitySFIdSet, BaseIntegrationService integrationRec, Boolean GETCallRequired) {
        Integer retryAttemptNumber = (integrationRec.retryRequestNumber == null ? 2 : (integrationRec.retryRequestNumber + 1));
        AccountingBatchScheduler batchObj = new AccountingBatchScheduler(entitySFIdSet, this.entityName);
        batchObj.executeBatch(retryAttemptNumber, GETCallRequired);
    }
        
    public void doRetryWithScheduledJob(BaseIntegrationService integrationRec, Integer timeIntervalInSec, String errorType) {
        Map<String, Integration_Entity__mdt> integrationEntityNameToRecMap = integrationRec.integrationEntityNameToRecMap;
        List<sObject> sObjectList = Database.query(XeroUtility.getQueryByEntityName(this.entityName, integrationEntityNameToRecMap));
        
        List<sObject> sObjectSyncList = new List<sObject>();
        if(integrationEntityNameToRecMap.keyset().size() > 0) {
            for(sObject sObjectRec : sObjectList) {
                String response = (String)(sObjectRec.get(integrationEntityNameToRecMap.get(this.entityName).Accounting_Response_API_Name__c));
                if(String.isNotBlank(response) && response.contains(errorType)) {
                    sObjectSyncList.add(sObjectRec);
                }
            }
            if(sObjectSyncList.size() > 0) {
                System.debug('Test schedule time cycle');
                XeroScriptUtil.scheduleJobs(sObjectSyncList, 25, 60, 25, this.entityName, timeIntervalInSec);
            }
        }    
    }
}