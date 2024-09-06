/**
 * Author: Tarun Khandelwal
 * Since: Sept 23, 2019
 * Name: AccountingBatchScheduler
 * Description: Scheduler class for all Accounting batch classes
**/
global without sharing class AccountingBatchScheduler implements Schedulable {
    
    global Set<Id> recordIdSet;
    global Integer batchSize;
    private String entityName;
    private List<String> relatedEntitiesList;
    Boolean isSendRequestRequiredForPOST;
    
    public AccountingBatchScheduler(Set<Id> recordIdSet, String entityName){
        this.recordIdSet = recordIdSet;
        this.batchSize = null;
        this.entityName = entityName;
        this.relatedEntitiesList = new List<String>();
    }
    
    global AccountingBatchScheduler(Set<Id> recordIdSet, Integer batchSize, String entityName){
        this.recordIdSet = recordIdSet;
        this.batchSize = batchSize;
        this.entityName = entityName;
        this.relatedEntitiesList = new List<String>();
    }
    
    global AccountingBatchScheduler(Set<Id> recordIdSet, Integer batchSize, String entityName, List<String> relatedEntitiesList) {
        this.recordIdSet = recordIdSet;
        this.batchSize = batchSize;
        this.entityName = entityName;
        this.relatedEntitiesList = relatedEntitiesList;
    }
    global AccountingBatchScheduler(Set<Id> recordIdSet, Integer batchSize, String entityName,Boolean isSendRequestRequiredForPOST) {
        this.recordIdSet = recordIdSet;
        this.batchSize = batchSize;
        this.entityName = entityName;
        this.relatedEntitiesList = new List<String>();
        this.isSendRequestRequiredForPOST = isSendRequestRequiredForPOST;
    }
    
    global void execute(SchedulableContext sc) {
        executeBatch();
    }
    
    public void executeBatch() {
        executeBatch(null, true);
    }
    
    public void executeBatch(Integer retryAttemptNumber, Boolean GETCallRequired) {
        BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
        integrationRec.isSendRequestRequiredForGET = GETCallRequired; //Since it will called from only script at the moment and before syncing we require a GET call for checking the previously created data 
        integrationRec.isSendRequestRequiredForPOST = this.isSendRequestRequiredForPOST != null ? this.isSendRequestRequiredForPOST : false;
        if(retryAttemptNumber != null) {
            integrationRec.retryRequestNumber = retryAttemptNumber;
        }
        if(integrationRec != null) {
            if(relatedEntitiesList.size() == 0) {
                new IntegrationUtility().getIntegrationEntityMetadata(new List<BaseIntegrationService>{integrationRec}, new List<String>{entityName});
            } else {
                new IntegrationUtility().getIntegrationEntityMetadata(new List<BaseIntegrationService>{integrationRec}, relatedEntitiesList);
            }
            IntegrationBatchService.initiateBatch(recordIdSet, new List<BaseIntegrationService>{integrationRec}, entityName, retryAttemptNumber);
        }
    }
}