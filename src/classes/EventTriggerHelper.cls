/**
 * Author: Nidhi Sharma
 * Since: November 11, 2020
 * Name: EventTriggerHelper
 * Description: Helper class for triggers on Event object
**/
public without sharing class EventTriggerHelper {
    public static Boolean isForceStopTrigger = false;
    public static final String Estimated_Hours_Error_Message = 'Estimated hours cannot be less than scheduled hours';
    public static final String Multiday_Error_Message = 'This appointment cannot be converted to single day appointment as it contains one or more multi day scheduling';
    
    public static void beforeInsertOperation(List<Event__c> eventNewList) {
    	validateStockUnitTypeForDealService(eventNewList);
		updateSchdulingDateOnServiceJob(eventNewList, new Map<Id, Event__c>());
    }
    
    public static void beforeUpdateOperation(List<Event__c> eventNewList, Map<Id, Event__c> newMap, Map<Id, Event__c> oldMap) {
    	validateEventFields(newMap, oldMap);
    	setStartDateTime(eventNewList, oldMap);
    	validateStockUnitTypeForDealService(eventNewList);
		updateSchdulingDateOnServiceJob(eventNewList, oldMap);
    }
    
    public static void afterDelete(List<Event__c> oldList) {
		removeScheduledDateFromServiceJob(oldList);
	}

	public static void beforeDeleteOperation(List<Event__c> oldList) {
		deleteTechnicianOnServiceJob(oldList);
	}
    
    private static void validateEventFields(Map<Id, Event__c> newMap, Map<Id, Event__c> oldMap) {
    	Set<String> eventIdSet = new Set<String>();
        for(Event__c eventRec : newMap.values()) {
    		if(eventRec.Estimated_Hours__c != null && oldMap.get(eventRec.Id).Estimated_Hours__c != null &&
            		eventRec.Estimated_Hours__c < oldMap.get(eventRec.Id).Estimated_Hours__c) {
                eventIdSet.add(eventRec.Id);
            } else if((eventRec.Is_MultiDay__c == null || !eventRec.Is_MultiDay__c) && oldMap.get(eventRec.Id).Is_MultiDay__c != null && 
            			oldMap.get(eventRec.Id).Is_MultiDay__c) {
                eventIdSet.add(eventRec.Id);
            }
		}
		if(eventIdSet.size() > 0) {
	    	List<Event_Scheduling__c> eventSchedulingList = [SELECT Id, Event__c, Start_Date_Time__c, End_Date_Time__c, Hours__c 
	    				FROM Event_Scheduling__c WHERE Event__c IN: eventIdSet];
			for(Event_Scheduling__c eventSchedulingRec : eventSchedulingList) {
	            if(eventSchedulingRec.Hours__c != null && oldMap.get(eventSchedulingRec.Event__c).Estimated_Hours__c != null && 
	            		newMap.get(eventSchedulingRec.Event__c).Estimated_Hours__c < eventSchedulingRec.Hours__c) {
	                throw new BlackpurlException(Estimated_Hours_Error_Message);
	                
	            } else if(eventSchedulingRec.Start_Date_Time__c != null && eventSchedulingRec.End_Date_Time__c != null && 
	            				!eventSchedulingRec.Start_Date_Time__c.isSameDay(eventSchedulingRec.End_Date_Time__c) && 
	            				 (newMap.get(eventSchedulingRec.Event__c).Is_MultiDay__c == null || !newMap.get(eventSchedulingRec.Event__c).Is_MultiDay__c)) {
            		throw new BlackpurlException(Multiday_Error_Message);
	            }
			}
		}
    }
    
    private static void setStartDateTime(List<Event__c> eventNewList, Map<Id, Event__c> oldMap) {
    	Set<String> eventIdSet = new Set<String>();
        for(Event__c eventRec : eventNewList) {
    		if(eventRec.Start_DateTime__c != null && eventRec.Start_DateTime__c != oldMap.get(eventRec.Id).Start_DateTime__c) {
                eventIdSet.add(eventRec.Id);
            }
		}
		if(eventIdSet.size() > 0) {
	    	Map<String, Event__c> eventIdToRecMap = new Map<String, Event__c>([SELECT Id, Start_DateTime__c, Estimated_Hours__c, Is_MultiDay__c, 
	    		(SELECT Start_Date_Time__c FROM Event_Schedulings__r ORDER BY Start_Date_Time__c ASC LIMIT 1) FROM Event__c WHERE Id IN: eventIdSet]);
	    	if(eventIdToRecMap.size() > 0) {
	    		List<Event__c> eventUpdateList = new List<Event__c>();
	    		for(Event__c eventUpdateRec : eventNewList) {
	    			Event__c eventRec = eventIdToRecMap.get(eventUpdateRec.Id);
	    			if(eventRec.Event_Schedulings__r.size() > 0 && eventUpdateRec.Start_DateTime__c != eventRec.Event_Schedulings__r[0].Start_Date_Time__c) {
	    				String startDate =  BPUtility.getFormatedDateTime(eventRec.Event_Schedulings__r[0].Start_Date_Time__c);
	        			String startTime = eventRec.Event_Schedulings__r[0].Start_Date_Time__c.format('h:mma');
	                            
	    				EventSchedulingService.setStartEndDate(eventUpdateRec, null, startDate, startTime,  eventRec.Estimated_Hours__c, eventRec.Is_MultiDay__c, false);
	    			}
	    		}
	    	}			
		}
    }
    
    private static void validateStockUnitTypeForDealService(List<Event__c> eventNewList) {
        Set<String> soIdSet = new Set<String>();
        for(Event__c eventRec : eventNewList) {
            if(eventRec.Service_Order_Header__c != null && eventRec.Service_Job_Type__c == Constants.DEAL_SERVICE_TT) {
                soIdSet.add(eventRec.Service_Order_Header__c);
            }
        }
        if(soIdSet.size() > 0) {
        	Map<String, Service_Order_Header__c> dealServiceJobIdToRecMap = new Map<String, Service_Order_Header__c>([Select Id, Customer_Owned_Unit__c from Service_Order_Header__c 
        							WHERE Id IN: soIdSet AND Deal__c != null]);
        	if(dealServiceJobIdToRecMap.size() > 0) {
        		for(Event__c eventRec : eventNewList) {
		            if(eventRec.Service_Order_Header__c != null && dealServiceJobIdToRecMap.containsKey(eventRec.Service_Order_Header__c)) {
		                eventRec.Customer_Owned_Unit__c = dealServiceJobIdToRecMap.get(eventRec.Service_Order_Header__c).Customer_Owned_Unit__c;
		            }
        		}
        	}
        }
    }
	 
	private static void updateSchdulingDateOnServiceJob(List<Event__c> eventNewList, Map<Id, Event__c> oldMap) {
		List<Service_Order_Header__c> serviceJobUpdateList = new List<Service_Order_Header__c>();
		
		Map<String, Service_Order_Header__c> soIdToRecMap = new Map<String, Service_Order_Header__c>();
        for(Event__c eventRec : eventNewList) {
        	if(eventRec.Service_Order_Header__c != null && eventRec.Start_DateTime__c != null) {
        		Date scheduledDate = Date.newInstance(eventRec.Start_DateTime__c.year(), eventRec.Start_DateTime__c.month(), eventRec.Start_DateTime__c.day());
        		soIdToRecMap.put(eventRec.Service_Order_Header__c, 
        							new Service_Order_Header__c(Id = eventRec.Service_Order_Header__c, Scheduled_Date__c = scheduledDate));
        	}
            if(Trigger.isUpdate && oldMap.get(eventRec.Id).Service_Order_Header__c != null && 
            			eventRec.Service_Order_Header__c != oldMap.get(eventRec.Id).Service_Order_Header__c) {
        		soIdToRecMap.put(oldMap.get(eventRec.Id).Service_Order_Header__c, 
        							new Service_Order_Header__c(Id = oldMap.get(eventRec.Id).Service_Order_Header__c, Scheduled_Date__c = null));
            }
		}
        if(soIdToRecMap.size() > 0) {
			SOTriggerHelper.isForceStopTrigger = true;
			update soIdToRecMap.values();
			SOTriggerHelper.isForceStopTrigger = false;
        }
	}

	private static void removeScheduledDateFromServiceJob(List<Event__c> oldList){
		List<Service_Order_Header__c> serviceJobUpdateList = new List<Service_Order_Header__c>();
        for(Event__c eventRec : oldList) {
			if(eventRec.Service_Order_Header__c != null) {
				Service_Order_Header__c soUpdateRec  = new Service_Order_Header__c(Id = eventRec.Service_Order_Header__c, Scheduled_Date__c = null);
				serviceJobUpdateList.add(soUpdateRec);
			}
		}
        if(serviceJobUpdateList.size() > 0) {
			SOTriggerHelper.isForceStopTrigger = true;
			update serviceJobUpdateList;
			SOTriggerHelper.isForceStopTrigger = false;
        }
	}

	private static void deleteTechnicianOnServiceJob(List<Event__c> eventList) {    
		List<Event_Scheduling__c> eventSchedulingList = [Select Event__c, Event__r.Service_Order_Header__c, Technician__c from Event_Scheduling__c where Event__c IN : eventList];	
		Set<String> technicianIdSet = new Set<String>();
		Map<String, Set<String>> eventIdToTechIdSetOldMap = new Map<String, Set<String>>();
		Map<String, Set<String>> serviceOrderIdToTechIdSetOldMap = new Map<String, Set<String>>();

		for(Event_Scheduling__c eventSchedulingRec : eventSchedulingList) {
			if(!eventIdToTechIdSetOldMap.containsKey(eventSchedulingRec.Event__c)){
				eventIdToTechIdSetOldMap.put(eventSchedulingRec.Event__c, new Set<String>());
			}
			eventIdToTechIdSetOldMap.get(eventSchedulingRec.Event__c).add(eventSchedulingRec.Technician__c);
			technicianIdSet.add(eventSchedulingRec.Technician__c);
		}
		
		for(Event__c eventRec : eventList) {
			if(eventRec.Service_Order_Header__c != null) {
				if(!serviceOrderIdToTechIdSetOldMap.containsKey(eventRec.Service_Order_Header__c)){
					serviceOrderIdToTechIdSetOldMap.put(eventRec.Service_Order_Header__c, new Set<String>());
				}
				if(eventIdToTechIdSetOldMap.containsKey(eventRec.Id)) {
					serviceOrderIdToTechIdSetOldMap.get(eventRec.Service_Order_Header__c).addAll(eventIdToTechIdSetOldMap.get(eventRec.Id));
				}
			}
		}

		List<Hours_Logged__c> hoursLogDeleteList = new  List<Hours_Logged__c>();

		List<Hours_Logged__c> serviceOrderHoursLoggedList = [Select id, Start_Date_Time__c, Technician__c, Service_Order_Header__c from Hours_Logged__c 
				where Service_Order_Header__c IN : serviceOrderIdToTechIdSetOldMap.keySet() AND Start_Date_Time__c = null];
				
		for(Hours_Logged__c hoursLogRec : serviceOrderHoursLoggedList) {
			if(serviceOrderIdToTechIdSetOldMap.containsKey(hoursLogRec.Service_Order_Header__c) && 
					serviceOrderIdToTechIdSetOldMap.get(hoursLogRec.Service_Order_Header__c).contains(hoursLogRec.Technician__c)) {
				hoursLogDeleteList.add(hoursLogRec);
			}
		} 

		if(hoursLogDeleteList.size() > 0) {
            DMLUtility.deleteSobjectList('Hours_Logged__c', hoursLogDeleteList);
		}
    }
}