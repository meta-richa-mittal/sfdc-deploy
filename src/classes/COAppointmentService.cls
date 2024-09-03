/**
 * Author: Pooja Kahndelwal
 * Since: Sep 09, 2018
 * Name: COAppointmentService
 * Description: Service Class used to perform CRUD operations on CO Appoinments
**/
public without sharing class COAppointmentService {

   	public static Map<Id, AppointmentWrapper> getAppointmentsBySectionId(String sectionId) {
    	String sectionName = BPUtility.getSectionNameBySectionId(sectionId);
        if(String.isBlank(sectionName)) {
        	return new Map<Id, AppointmentWrapper>();
        }
        
        List<Id> sectionIdList = new List<Id>();
        if(sectionName == 'All') {
        	if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    		List<Service_Order_Header__c> soHeaderList = [SELECT Id FROM Service_Order_Header__c WHERE CO_Header__c =: sectionId];
    		for(Service_Order_Header__c soHeaderRec : soHeaderList) {
        		sectionIdList.add(soHeaderRec.Id);
        	}
        } else {
        	sectionIdList.add(sectionId);
        }
        
        List<Event__c> appointmentList = SchedulerSOQLUtil.getAppointmentListBySOId(sectionIdList);
        Map<Id, AppointmentWrapper> sectionIdToAppointmentRecMap = getSectionIdToAppointmentRecMap(appointmentList);
       	return sectionIdToAppointmentRecMap;
   	}
   	
   	private static Map<Id, AppointmentWrapper> getSectionIdToAppointmentRecMap(List<Event__c> appointmentList) {
   		Map<Id, AppointmentWrapper> sectionIdToAppointmentRecMap = new Map<Id, AppointmentWrapper>();
    	for(Event__c eventRec : appointmentList) {
   			if(String.isNotBlank(eventRec.Service_Order_Header__c)) {
   				AppointmentWrapper appointmentObj = new AppointmentWrapper(eventRec, true);
   				AppointmentService.populateSOKitConcernsOnAppointment(appointmentObj, eventRec.Service_Order_Header__c);
   				/*if(String.isNotBlank(eventRec.Appointment_Concern__c)) {
	   			     //NotesService.populateNotesOnAppointment(appointmentRec, eventRec.Event_Concern__c);
	   			     appointmentObj.Concern.addAll(eventRec.Appointment_Concern__c.split('\n'));
	   			}*/  			
	   			sectionIdToAppointmentRecMap.put(eventRec.Service_Order_Header__c, appointmentObj);
   			}
	   	}
   		return sectionIdToAppointmentRecMap;
   	}
   	
   	public static void updateAppointmentsBySectionId(String sectionId) {
        String sectionName = BPUtility.getSectionNameBySectionId(sectionId);
        if(String.isBlank(sectionName)) {
        	return;
        }
        
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        String query = 'SELECT CO_Header__r.Customer__c, Service_Order_Header__r.Customer_Owned_Unit__c, Service_Order_Header__r.Name__c, Service_Order_Header__r.Transaction_Type__c, Service_Order_Header__r.SO_Concern__c, Appointment_Concern__c FROM Event__c';
        if(sectionName == 'All') {
    		query += ' WHERE CO_Header__c =: sectionId';
        } else {
        	query += ' WHERE Service_Order_Header__c =: sectionId';
        }
        List<Event__c> eventList = Database.query(query);
        Set<Id> deletableNotesIdSet;
        
        for(Event__c eventRec : eventList) {
    		eventRec.Customer__c = eventRec.CO_Header__r.Customer__c;
    		eventRec.Customer_Owned_Unit__c = eventRec.Service_Order_Header__r.Customer_Owned_Unit__c;
    		eventRec.Name__c = eventRec.Service_Order_Header__r.Name__c;
    		eventRec.Transaction_Type__c = eventRec.Service_Order_Header__r.Transaction_Type__c;
    		eventRec.Appointment_Concern__c = eventRec.Service_Order_Header__r.SO_Concern__c;
            
    		/*if(String.isNotBlank(eventRec.Service_Order_Header__r.SO_Concern__c) && eventRec.Service_Order_Header__r.SO_Concern__c.length() > 255) {
            	eventRec.Appointment_Concern__c = '';
            	if(String.isNotBlank(eventRec.Event_Concern__c)) {
            		NotesService.upsertNotesRecord(eventRec.Service_Order_Header__r.SO_Concern__c, eventRec.Event_Concern__c); 
            	} else {
            		eventRec = NotesService.populateNotesLookup(eventRec, eventRec.Service_Order_Header__r.SO_Concern__c);
            	}
	        } else {
	        	if(String.isNotBlank(eventRec.Event_Concern__c)) {
	        		deletableNotesIdSet = new Set<Id>();
	        		deletableNotesIdSet.add(eventRec.Event_Concern__c);
	        	}
	        	eventRec.Appointment_Concern__c = eventRec.Service_Order_Header__r.SO_Concern__c;
	        }*/
    	}
        
        if(eventList.size() > 0) {
        	if(!AccessControl.ifObjectFieldIsUpdateable('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        	update eventList;
        }
        
        /*if(deletableNotesIdSet != null && deletableNotesIdSet.size() > 0) {
        	NotesService.deleteNotesRecords(deletableNotesIdSet);
        }*/
   	}
}