public class CopyEventsBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT WhatId, Title__c, Type, Subject, Technician__c, Transaction_Type__c, StartDateTime, Customer__c, ' +
            'EndDateTime, Notes__c, AdditionalNotes__c, Appointment_Concern__c, Appointment_Day_Segment__c, CO_Header__c, Customer_Owned_Unit__c, '+
            'Estimated_Hours__c, Event_Concern__r.Description__c, IsMultiDayEvent__c, Job_Type__c, Service_Order_Header__c FROM Event' 
        );
    }
    
    public void execute(Database.BatchableContext bc, List<Event> eventList) {
        List<Event__c> eventListToInsert = new List<Event__c>();
        Event__c eventRec;
        for(Event event : eventList) {
            eventRec = new Event__c();
            eventRec.Technician__c = event.Technician__c;
            eventRec.Appointment_Day_Segment__c = event.Appointment_Day_Segment__c;
            eventRec.CO_Header__c = event.CO_Header__c;
            eventRec.Customer__c = event.Customer__c;
            eventRec.Customer_Owned_Unit__c = event.Customer_Owned_Unit__c;
            eventRec.End_DateTime__c = event.EndDateTime;
            eventRec.Estimated_Hours__c = event.Estimated_Hours__c;
            eventRec.Is_MultiDay__c = event.IsMultiDayEvent__c;
            eventRec.Job_Type__c = event.Job_Type__c;
            eventRec.Title__c = event.Title__c;
            eventRec.Service_Order_Header__c = event.Service_Order_Header__c;
            eventRec.Start_DateTime__c = event.StartDateTime;
            eventRec.Transaction_Type__c = event.Transaction_Type__c;
            eventRec.Type__c = event.Type;
            eventRec.Name__c = event.Subject;
            eventRec.Old_Event__c = event.Id;
            
            if(event.Event_Concern__r.Description__c != null) {
                eventRec.Appointment_Concern__c = event.Event_Concern__r.Description__c;
            } else {
                eventRec.Appointment_Concern__c = event.Appointment_Concern__c;
            }
            if(event.WhatId != null) {
                eventRec.CO_Header__c = event.WhatId;
            }
            if(event.Notes__c != null) {
                eventRec.Appointment_Concern__c = event.Notes__c;
                if(event.AdditionalNotes__c != null) {
                    eventRec.Appointment_Concern__c += event.AdditionalNotes__c;
                }
            }
            eventListToInsert.add(eventRec);
        }
        if(eventListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Event__c', eventListToInsert, false);
        }
    }   
    
    public void finish(Database.BatchableContext bc){}    
}