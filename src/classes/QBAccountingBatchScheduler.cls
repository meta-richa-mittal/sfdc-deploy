global without sharing class QBAccountingBatchScheduler implements Schedulable {
    global Set<Id> recordIdSet;
    global QBAccountingBatchScheduler(Set<Id> recordIdSet, String entityName){}
    
    global void execute(SchedulableContext sc) {}
}