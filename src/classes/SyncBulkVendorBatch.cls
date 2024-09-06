global without sharing class SyncBulkVendorBatch extends BaseSyncingBatch {
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Account', AccountingVendor.fieldsList(), IntegrationUtility.BATCH_VENDOR));
    }
    
    global void execute(Database.batchableContext bc, List<Account> listVendors) {
        Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
        if(QBUtil.isQBEnabled()) {
            integrationEntityNameToActionMap.put(IntegrationUtility.BATCH, IntegrationUtility.UPDATE_ACTION);
            QBBatchDTO batchObj = new QBBatchDTO();
            List<QBBatchDTO.BatchItemRequest> batchItemReqObjList = new List<QBBatchDTO.BatchItemRequest>();
            for(Account vendorRec : listVendors){
                QBBatchDTO.BatchItemRequest batchItemRequest = new QBBatchDTO.BatchItemRequest(vendorRec, (String.isBlank(vendorRec.Vendor_AccountingId__c) ? 'create' : 'update'), IntegrationUtility.BATCH_VENDOR);
                batchItemReqObjList.add(batchItemRequest);
            }
            batchObj.BatchItemRequest = batchItemReqObjList;
            this.webserviceLogs = (integrationInstanceList[0].sync(new List<QBBatchDTO>{batchObj}, (List<SObject>) sobjctListToUpdate, 
                    IntegrationUtility.BATCH_VENDOR, integrationEntityNameToActionMap));
        } else {
           /*  integrationEntityNameToActionMap.put(IntegrationUtility.CONTACTS, IntegrationUtility.UPDATE_ACTION);
            this.webserviceLogs = (integrationInstanceList[0].sync(accountingCustomerList, (List<SObject>) sobjctListToUpdate, 
                                            IntegrationUtility.CUSTOMER, integrationEntityNameToActionMap)); */
        }
    }
        
    global override void finish(Database.batchableContext bc){
        finishAction();
    }
}