/**
 * Author: Reena Singh
 * Since: Jul 21, 2020
 * Name: QBAccountingBatchScheduler
 * Description: Apex class to schedule QB Accounting Batch.
**/
global without sharing class QBAccountingBatchScheduler implements Schedulable {
    global Set<Id> recordIdSet;
    private String entityName;

    global QBAccountingBatchScheduler(Set<Id> recordIdSet, String entityName){
        this.recordIdSet = recordIdSet;
        this.entityName = entityName;
    }
    
    global void execute(SchedulableContext sc) {
        if(QBUtil.isQBEnabled()) {
            QBUtil.initiateBatch(recordIdSet, entityName);
        }
    }
}