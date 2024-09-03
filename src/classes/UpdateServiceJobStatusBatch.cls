/**
 * Author: Balveer Choudhary
 * Since: Dec 08, 2022
 * Name: UpdateServiceJobStatusBatch
**/
global without sharing class UpdateServiceJobStatusBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Work_Status__c FROM Service_Order_Header__c';
        return Database.getQueryLocator(query);
    } 

    global void execute(Database.BatchableContext bc, List<Service_Order_Header__c> soHeaderList) {
        for(Service_Order_Header__c soHeaderRec : soHeaderList) {
            if(oldSOStatusToNewStatusMap.containsKey(soHeaderRec.Work_Status__c)) {
                soHeaderRec.Work_Status__c = oldSOStatusToNewStatusMap.get(soHeaderRec.Work_Status__c);
            }
        }
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderList);
    }

    global void finish(Database.batchableContext bc) {}

    public static Map<String, String> oldSOStatusToNewStatusMap = new Map<String, String> {
                                                                                        'New' => ServiceJobUtil.NEW_JOB,
                                                                                        'Ready' => ServiceJobUtil.READY_TO_START,
                                                                                        'In Progress' => ServiceJobUtil.IN_PROGRESS,
                                                                                        'On Hold' => ServiceJobUtil.WAIT_FOR_PARTS,
                                                                                        'Complete' => ServiceJobUtil.JOB_COMPLETE,
                                                                                        'Reviewed' => ServiceJobUtil.READY_TO_INVOICE
                                                                                    };
}
