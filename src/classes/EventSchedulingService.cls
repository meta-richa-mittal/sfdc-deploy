/** 
* Author: Nidhi Sharma
* Since: Feb 26, 2020 
* Name: EventSchedulingService
* Description: Apex class which contains all Event scheduling service methods
**/
public without sharing class EventSchedulingService {
    
    public static void saveEventSchedulingRecord(String eventId, String schedulingDetailJSON) {
        EventSchedulingWrapper eventSchedulingObj = (EventSchedulingWrapper)System.JSON.deserialize(schedulingDetailJSON, EventSchedulingWrapper.class);
        if(eventSchedulingObj != null) {
    		if(eventSchedulingObj.Hours > 0) {
	    		Event_Scheduling__c schedulingRec = setSchedulingFields(eventId, eventSchedulingObj);
	    		
	    		if(eventSchedulingObj.isConflictExists != null && eventSchedulingObj.isConflictExists) {
	    			List<Event_Scheduling__c> conflictedAppointmentUpdateList = reshuffleConflictedSchedulings(schedulingRec, eventSchedulingObj.IsMultiDay, 
	    									eventSchedulingObj.ActualStartDate);
		    		if(conflictedAppointmentUpdateList.size() > 0) {
                        DMLUtility.updateSobjectList('Event_Scheduling__c', conflictedAppointmentUpdateList);
		    		}
	    		}
	    		AppointmentService.createCOForEvent(eventId);
                DMLUtility.upsertSobjectList('Event_Scheduling__c', schedulingRec);
    		}
    	}
    }
    
    private static Event_Scheduling__c setSchedulingFields(String eventId, EventSchedulingWrapper schedulingObj) {
    	Event_Scheduling__c schedulingRec = new Event_Scheduling__c(Id = schedulingObj.Id);
        String result = setStartEndDate(null, schedulingRec, schedulingObj.ActualStartDate, schedulingObj.ActualStartTime, 
        								schedulingObj.Hours, schedulingObj.IsMultiday, true);
        if(!result.equalsIgnoreCase('Success')) {
            throw new BlackpurlException(result);
        }
        schedulingRec.Event__c = String.isNotBlank(eventId) ? eventId : schedulingObj.EventId;
        schedulingRec.Technician__c = schedulingObj.TechnicianId;
        schedulingRec.Hours__c = schedulingObj.Hours;
        return schedulingRec;
    }
    
    public static String setStartEndDate(Event__c eventRec, Event_Scheduling__c eventSchedulingRec, String startDate, String startTime, Decimal hours, 
    										Boolean isMultiday, Boolean isFromAddEditAppointment) {
        AppointmentService.setShopWorkingDaysMap(); // Map for shop settings data for working days
        DateTime startDateTime;
        DateTime endDateTime;
        if(String.isNotBlank(startDate) && String.isNotBlank(startTime)) {
	        startDateTime = DateTimeUtility.getConvertedDateTime(startDate, startTime);
            
            String startDayName = AccountSettingService.getDayNameFromDate(Date.newinstance(startDateTime.year(), startDateTime.month(), startDateTime.day()));
            String errorMsg = AppointmentService.isValidStartTime(startDayName, startTime);
            if(String.isNotBlank(errorMsg)) {
                return errorMsg;
            }
            if(hours != null && hours > 0) {
                Integer totalApointmentMinutes = (Integer)(hours * 60);
                
                if(isMultiday) {
                    endDateTime = AppointmentService.setEndDateWhenWorkLateDisabled(startDayName, startTime, totalApointmentMinutes, startDateTime);
                } else {
                    if(isFromAddEditAppointment) {
                        endDateTime = startDateTime.addMinutes(totalApointmentMinutes);
                        if(!startDateTime.isSameDay(endDateTime)) {
                            return 'Appointment start date and end date should be same for single-day appointment.';
                        }
                    } else {
                        endDateTime = startDateTime.addMinutes(totalApointmentMinutes);
                        DateTime maxEndTime = DateTime.newInstance(startDateTime.date(), AppointmentService.MAX_ALLOWED_TIME_FOR_WORK_LATE);
                        if(endDateTime > maxEndTime) {
                            endDateTime = maxEndTime;
                        }
                    }
                }
            }
        }
        if(eventRec != null) {
        	eventRec.Start_DateTime__c = startDateTime;
        	eventRec.End_DateTime__c = endDateTime;
        } else if(eventSchedulingRec != null) {
        	eventSchedulingRec.Start_Date_Time__c = startDateTime;
        	eventSchedulingRec.End_Date_Time__c = endDateTime;
        }
        return 'Success'; 
    }
    
    //Reshuffle single scheduling records
    public static List<Event_Scheduling__c> reshuffleConflictedSchedulings(Event_Scheduling__c activeSchedulingRec, Boolean isMultiDayEvent, String schedulingDate) {
        DateTime selectedDate = HomeSearchFilterInterface.getDateFromString(schedulingDate);
        Map<String, List<String>> queryParamMap = new Map<String, List<String>>{'Technician__c' => new List<String>{'=', activeSchedulingRec.Technician__c}};
        List<Event_Scheduling__c> conflictedAppointmentList = SchedulerSOQLUtil.getEventSchedulingListByQueryParam(queryParamMap, selectedDate);
        
        DateTime updatedSchedulingStartTime = activeSchedulingRec.Start_Date_Time__c;
        DateTime updatedSchedulingEndTime = (activeSchedulingRec.End_Date_Time__c != null) ? activeSchedulingRec.End_Date_Time__c : 
                                                    updatedSchedulingStartTime.addMinutes((Integer) (activeSchedulingRec.Hours__c * 60));
        
        List<Event_Scheduling__c> conflictedSchedulingUpdateList = new List<Event_Scheduling__c>();
        isMultiDayEvent = isMultiDayEvent != null ? isMultiDayEvent : false;
        
        for(Event_Scheduling__c conflictedSchedulingRec : conflictedAppointmentList) {
            if(conflictedSchedulingRec.Event__r.Is_MultiDay__c && isMultiDayEvent) {
                throw new BlackpurlException('This multiday is conflicting with another multiday event');
            }
            if(!conflictedSchedulingRec.Event__r.Is_MultiDay__c && !isMultiDayEvent && 
                updatedSchedulingStartTime <= conflictedSchedulingRec.Start_Date_Time__c && conflictedSchedulingRec.Start_Date_Time__c < updatedSchedulingEndTime) {
                
                updatedSchedulingStartTime = conflictedSchedulingRec.Start_Date_Time__c = updatedSchedulingEndTime;
                updatedSchedulingEndTime = conflictedSchedulingRec.End_Date_Time__c = 
                                conflictedSchedulingRec.Start_Date_Time__c.addMinutes((Integer) (conflictedSchedulingRec.Hours__c * 60));
                conflictedSchedulingUpdateList.add(conflictedSchedulingRec);
            }
        }
        return conflictedSchedulingUpdateList;
    }
    
    public static void deleteEventScheduling(String eventSchedulingRecId) {
    	if(String.isNotBlank(eventSchedulingRecId)) {
            DMLUtility.deleteSobjectList('Event_Scheduling__c', new Event_Scheduling__c(Id = eventSchedulingRecId));
    	}
    }
    
    public static List<EventSchedulingWrapper> getEventSchedulingListByEventId(String eventId) {
    	Map<String, List<String>> queryParamMap = new Map<String, List<String>>{'Event__c' => new List<String>{'=', eventId}};
        List<Event_Scheduling__c> eventSchedulingList = SchedulerSOQLUtil.getEventSchedulingListByQueryParam(queryParamMap, null);
        
        List<EventSchedulingWrapper> eventSchedulingObjList = new List<EventSchedulingWrapper>();
        for(Event_Scheduling__c eventSchedulingRec : eventSchedulingList) {
        	eventSchedulingObjList.add(new EventSchedulingWrapper(eventSchedulingRec));
        }
    	return eventSchedulingObjList;	
    }
    
    public static Boolean isMultiDayScheduling(Event_Scheduling__c eventSchedulingRec) {
		if(eventSchedulingRec != null && eventSchedulingRec.Event__r.Is_MultiDay__c != null) {
    		return eventSchedulingRec.Event__r.Is_MultiDay__c;
		}
		return false;
    }
}