global without sharing class SyncBulkCustomerBatch extends BaseSyncingBatch {
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Account', AccountingCustomer.fieldsList(), IntegrationUtility.BATCH_CUSTOMER));
    }
    
    global void execute(Database.batchableContext bc, List<Account> listCustomers) {
        Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
        if(QBUtil.isQBEnabled()) {
            integrationEntityNameToActionMap.put(IntegrationUtility.BATCH, IntegrationUtility.UPDATE_ACTION);
            QBBatchDTO batchObj = new QBBatchDTO();
            List<QBBatchDTO.BatchItemRequest> batchItemReqObjList = new List<QBBatchDTO.BatchItemRequest>();
            for(Account customerRec : listCustomers){
                QBBatchDTO.BatchItemRequest batchItemRequest = new QBBatchDTO.BatchItemRequest(customerRec, (String.isBlank(customerRec.AccountingId__c) ? 'create' : 'update'), IntegrationUtility.BATCH_CUSTOMER);
                batchItemReqObjList.add(batchItemRequest);
            }
            batchObj.BatchItemRequest = batchItemReqObjList;
            this.webserviceLogs = (integrationInstanceList[0].sync(new List<QBBatchDTO>{batchObj}, (List<SObject>) sobjctListToUpdate, 
                    IntegrationUtility.BATCH_CUSTOMER, integrationEntityNameToActionMap));
        }
    }
        
    global override void finish(Database.batchableContext bc){
        finishAction();
    }
}