/**
 * Author: Manoj Sharma
 * Since: April 12, 2021
 * Name: PopulateScheduledDateOnServiceJobBatch
 * Description: Batch class to populate scheduled date
**/
global without sharing class PopulateScheduledDateOnServiceJobBatch implements Database.Batchable<sobject>{
    
    global Database.QueryLocator start(Database.BatchableContext bc){
    	String strQuery = 'Select id, Start_DateTime__c, Service_Order_Header__c, Service_Order_Header__r.Scheduled_Date__c from Event__c where Service_Order_Header__c != null AND Start_DateTime__c != null';
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<Event__c> eventList) {
        Map<String, Service_Order_Header__c> soIdToSORecMap = new Map<String, Service_Order_Header__c>();
        for(Event__c eventRec : eventList) {
            eventRec.Service_Order_Header__r.Scheduled_Date__c = (eventRec.Start_DateTime__c).date();
            if(!soIdToSORecMap.containsKey(eventRec.Service_Order_Header__c)) {
                soIdToSORecMap.put(eventRec.Service_Order_Header__c, eventRec.Service_Order_Header__r);
            }
        }

        SOTriggerHelper.isForceStopTrigger = true;
        update soIdToSORecMap.values();
        SOTriggerHelper.isForceStopTrigger = false;
    }

    global void finish(Database.batchableContext bc){}
}
