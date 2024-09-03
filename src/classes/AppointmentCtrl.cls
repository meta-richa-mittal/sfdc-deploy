/** 
* Author: Nidhi Sharma<nidhi.sharma@metacube.com>
* Since: May 16, 2018 
* Name: AppointmentCtrl 
* Description: Apex class which contains all remoted methods related to Schedule Appointment
**/
global without sharing class AppointmentCtrl {
    
    global AppointmentCtrl(NewHomePageCtrl controller){} 
    public AppointmentCtrl() {}
    
    /**
    * Name:saveAppointment
    * Desc:to save a appointment
    * @param:Appointment data
    **/
    @remoteAction
    global static String saveAppointment(String appointmentDetailJSON) {
        try{
            if(!AccessControl.ifObjectFieldIsCreateable('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            appointmentDetailJSON = BPUtility.getDecodedString(appointmentDetailJSON);
            ResponseWrapper result = AppointmentService.saveAppointment(appointmentDetailJSON);
    		return BPUtility.getEncodedString(system.JSON.serialize(result));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
    * Name: getCustomerRecByCustomerId
    * Desc: get Appointment Data For A Customer
    * @param: Customer Id
    **/
    @remoteAction
    global static String getCustomerRecByCustomerId(String customerId) {
        customerId = BPUtility.getDecodedString(customerId);
        try{
            CustomerWrapper customerObj = AppointmentService.getCustomerRecByCustomerId(customerId);
            return BPUtility.getEncodedString(System.JSON.serialize(customerObj, true)); 
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
    * Name: getUnitById
    * Desc: get Appointment Data For A Customer
    * @param:Customer id
    **/
    @remoteAction
    global static String getUnitById(String couId) {
        couId = BPUtility.getDecodedString(couId);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(AppointmentService.getUnitById(couId), true)); 
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
    * Name: deleteAppointmentById
    * Desc: Delete Appointment for unassignned appointment
    * @param:Status 
    **/
    @remoteAction
    global static String deleteAppointmentById(String eventRecId) {
        eventRecId = BPUtility.getDecodedString(eventRecId);
        try {
            return BPUtility.getEncodedString(AppointmentService.deleteAppointmentById(eventRecId));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
    * Name: getJobTypeList
    * Desc: Get all job type list from master data
    * @param:
    * @return: TTList 
    **/
    @remoteAction
    global static String getJobTypeList() {
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(AppointmentService.getJobTypeList(), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
    * Name: getTechnicianListWithAvailableHours
    * Desc: Get all technician list with hours available in AM/PM
    * @param: appointmentJson
    * @return: TechnicianList 
    **/
    @remoteAction
    global static String getTechnicianListWithAvailableHours(String appointmentDetailJSON) {
        appointmentDetailJSON = BPUtility.getDecodedString(appointmentDetailJSON);
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(AppointmentService.getTechnicianListWithAvailableHours(appointmentDetailJSON), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
    * Depricated
    * Name: updateRelatedSORecord
    * Desc:to update a SO Record
    * @param: 
    **/
    @remoteAction
    global static String updateRelatedSORecord(String appointmentRecId) {
        return '';
    }
    
    @remoteAction
    global static String getTimeSlotAndStateForTechnician(String timeSlotJson) {
    	timeSlotJson = BPUtility.getDecodedString(timeSlotJson);
    	try {
    		return BPUtility.getEncodedString(AppointmentService.getTimeSlotAndStateForTechnician(timeSlotJson)); 
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getEventSchedulingListByEventId(String eventId) {
    	eventId = BPUtility.getDecodedString(eventId);
        return BPUtility.getEncodedString(system.JSON.serialize(EventSchedulingService.getEventSchedulingListByEventId(eventId), true));
    }
    
    //To create/update event scheduling record
    @RemoteAction
    global static String updateEventSchedulingRecord(String eventId, String eventSchedulingJson) {
    	eventId = BPUtility.getDecodedString(eventId);
    	eventSchedulingJson = BPUtility.getDecodedString(eventSchedulingJson);
        EventSchedulingService.saveEventSchedulingRecord(eventId, eventSchedulingJson);
        return 'Success';
    }
    
    @RemoteAction
    global static String deleteEventScheduling(String eventSchedulingRecId) {
    	eventSchedulingRecId = BPUtility.getDecodedString(eventSchedulingRecId);
        EventSchedulingService.deleteEventScheduling(eventSchedulingRecId);
        return 'Success';
    }
    
    //Not in use
    @RemoteAction 
    global static String reshuffleSchedulingsForNewEvent(String eventSchedulingListJson) { return ''; }
}