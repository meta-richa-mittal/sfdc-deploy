/** 
* Author: Nidhi Sharma
* Since: Feb 24, 2021
* Name: CreateEventSchedulingForOldEventsBatch 
* Description: Batch class which create event scheduling records for existing events
**/
global without sharing class CreateEventSchedulingForOldEventsBatch implements Database.Batchable<sobject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Id, Technician__c, Start_DateTime__c, Estimated_Hours__c, End_DateTime__c FROM Event__c' +
        	' WHERE Technician__c != null AND Id Not IN (Select Event__c from Event_Scheduling__c) ORDER BY lastmodifiedDate ASC';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Event__c> eventList) {
    	List<Event_Scheduling__c> eventSchedulingInsertList = new List<Event_Scheduling__c>();
        for(Event__c eventRec : eventList) {
        	eventSchedulingInsertList.add(setEventSchedulingRec(eventRec));
        }
        if(eventSchedulingInsertList.size() > 0) {
            DMLUtility.insertSobjectList('Event_Scheduling__c', eventSchedulingInsertList);
        }
    }
    
    global void finish(Database.batchableContext bc) {}
    
    private static Event_Scheduling__c setEventSchedulingRec(Event__c eventRec) {
    	Event_Scheduling__c schedulingRec = new Event_Scheduling__c();
    	schedulingRec.Event__c = eventRec.Id;
    	schedulingRec.Technician__c = eventRec.Technician__c;
    	schedulingRec.Start_Date_Time__c = eventRec.Start_DateTime__c;
    	schedulingRec.End_Date_Time__c = eventRec.End_DateTime__c;
    	schedulingRec.Hours__c = eventRec.Estimated_Hours__c;
    	return schedulingRec;
    }
}