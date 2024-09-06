/**
 * Author: Nidhi Sharma
 * Since: Feb 26, 2021
 * Name: EventSchedulingTrigger
 * Description: Trigger executes on Event_Scheduling__c object
**/
public without sharing class EventSchedulingTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    
    public static void afterInsert(List<Event_Scheduling__c> newList) {
		calculateEventStartEndDateTime(newList);
		insertTechnicianOnServiceJob(newList);
    }
    
    public static void afterUpdate(Map<Id, Event_Scheduling__c> eventSchedulingOldMap, List<Event_Scheduling__c> newList) {
		calculateEventStartEndDateTime(newList);
		updateTechnicianOnServiceJob(eventSchedulingOldMap, newList);
    }
    
    public static void afterDelete(List<Event_Scheduling__c> oldList) {
		calculateEventStartEndDateTime(oldList);
		deleteTechnicianOnServiceJob(oldList);
    }
    
    private static void calculateEventStartEndDateTime(List<Event_Scheduling__c> eventSchedulingList) {
    	Set<String> eventIdSet = new Set<String>();
    	for(Event_Scheduling__c eventSchedulingRec : eventSchedulingList) {
    		eventIdSet.add(eventSchedulingRec.Event__c);
    	}
    	List<Event__c> eventList = [SELECT Id, Start_DateTime__c, Estimated_Hours__c, Is_MultiDay__c, 
    		(SELECT Start_Date_Time__c FROM Event_Schedulings__r ORDER BY Start_Date_Time__c ASC LIMIT 1) FROM Event__c WHERE Id IN: eventIdSet];
    	if(eventList.size() > 0) {
    		List<Event__c> eventUpdateList = new List<Event__c>();
    		for(Event__c eventRec : eventList) {
    			if(eventRec.Event_Schedulings__r.size() > 0 && eventRec.Start_DateTime__c != eventRec.Event_Schedulings__r[0].Start_Date_Time__c) {
    				String startDate =  BPUtility.getFormatedDateTime(eventRec.Event_Schedulings__r[0].Start_Date_Time__c);
        			String startTime = eventRec.Event_Schedulings__r[0].Start_Date_Time__c.format('h:mma');
                            
    				EventSchedulingService.setStartEndDate(eventRec, null, startDate, startTime,  eventRec.Estimated_Hours__c, eventRec.Is_MultiDay__c, false);
    				eventUpdateList.add(eventRec);
    			}
    		}
    		if(eventUpdateList.size() > 0) {
    			EventTriggerHelper.isForceStopTrigger = true;
    			update eventUpdateList;
    			EventTriggerHelper.isForceStopTrigger = false;
    		}
    	}							
	}
	
	private static void insertTechnicianOnServiceJob(List<Event_Scheduling__c> eventSchedulingList) {

		Set<String> eventIdSet = new Set<String>();
    	for(Event_Scheduling__c eventSchedulingRec : eventSchedulingList) {
    		eventIdSet.add(eventSchedulingRec.Event__c);
		}
		
		List<Event_Scheduling__c> availableEventSchedulingList = [Select id, Event__r.Service_Order_Header__c, Technician__c from Event_Scheduling__c where Event__c IN :eventIdSet];
		
		Map<String, Set<String>> serviceOrderIdToTechIdSetMap = new Map<String, Set<String>>();

    	for(Event_Scheduling__c eventSchedulingRec : availableEventSchedulingList) {
			if(!serviceOrderIdToTechIdSetMap.containsKey(eventSchedulingRec.Event__r.Service_Order_Header__c)){
				serviceOrderIdToTechIdSetMap.put(eventSchedulingRec.Event__r.Service_Order_Header__c, new Set<String>());
			}
			serviceOrderIdToTechIdSetMap.get(eventSchedulingRec.Event__r.Service_Order_Header__c).add(eventSchedulingRec.Technician__c);
		}
		List<Hours_Logged__c> hoursLogInsertList = new  List<Hours_Logged__c>();		

		Map<String, List<Hours_Logged__c>> serviceOrderIdToHoursLogListMap = new Map<String, List<Hours_Logged__c>>();
		List<Hours_Logged__c> serviceOrderHoursLoggedList = [Select id, Start_Date_Time__c, Technician__c, Service_Order_Header__c from Hours_Logged__c where Service_Order_Header__c IN : serviceOrderIdToTechIdSetMap.keySet()];
		for(Hours_Logged__c hoursLogRec : serviceOrderHoursLoggedList) {
			if(serviceOrderIdToTechIdSetMap.containsKey(hoursLogRec.Service_Order_Header__c)){
				if((serviceOrderIdToTechIdSetMap.get(hoursLogRec.Service_Order_Header__c)).contains(hoursLogRec.Technician__c)) {
					(serviceOrderIdToTechIdSetMap.get(hoursLogRec.Service_Order_Header__c)).remove(hoursLogRec.Technician__c);
				} 
			} 
		}
		
		for(String soId : serviceOrderIdToTechIdSetMap.keySet()) {
			for(String techId : serviceOrderIdToTechIdSetMap.get(soId)) {
				Hours_Logged__c hoursLogged = new Hours_Logged__c();
				hoursLogged.Technician__c = techId;
				hoursLogged.Service_Order_Header__c = soId;
				hoursLogInsertList.add(hoursLogged);
			}
		}

		if(hoursLogInsertList.size() > 0) {
            DMLUtility.insertSobjectList('Hours_Logged__c', hoursLogInsertList);
		}
	}
	
	private static void updateTechnicianOnServiceJob(Map<Id, Event_Scheduling__c> eventSchedulingOldMap, List<Event_Scheduling__c> eventSchedulingNewList) {    	
		Set<String> oldTechnicianIdSet = new Set<String>();
		Map<String, Set<String>> eventIdToTechIdSetNewMap = new Map<String, Set<String>>();
		Map<String, Set<String>> eventIdToTechIdSetOldMap = new Map<String, Set<String>>();
		
		for(Event_Scheduling__c eventSchedulingRec : eventSchedulingNewList) {
			if(String.isNotBlank(eventSchedulingRec.Technician__c) && eventSchedulingRec.Technician__c != eventSchedulingOldMap.get(eventSchedulingRec.Id).Technician__c) {
				if(!eventIdToTechIdSetNewMap.containsKey(eventSchedulingRec.Event__c)) {
					eventIdToTechIdSetNewMap.put(eventSchedulingRec.Event__c, new Set<String>());
				}
				eventIdToTechIdSetNewMap.get(eventSchedulingRec.Event__c).add(eventSchedulingRec.Technician__c);
				
				String previousEventId = eventSchedulingOldMap.get(eventSchedulingRec.Id).Event__c;
				if(!eventIdToTechIdSetOldMap.containsKey(previousEventId)) {
					eventIdToTechIdSetOldMap.put(previousEventId, new Set<String>());
				}
				eventIdToTechIdSetOldMap.get(previousEventId).add(eventSchedulingOldMap.get(eventSchedulingRec.Id).Technician__c);
				oldTechnicianIdSet.add(eventSchedulingOldMap.get(eventSchedulingRec.Id).Technician__c);
			}
		}
		
		if(eventIdToTechIdSetNewMap.size() > 0) {
			List<Event__c> eventList = [Select id, Service_Order_Header__c from Event__c 
											where Id IN :eventIdToTechIdSetNewMap.keySet() OR Id IN: eventIdToTechIdSetOldMap.keySet()];
											
			Map<String, Set<String>> soIdToTechIdSetNewMap = new Map<String, Set<String>>();
			Map<String, Set<String>> soIdToTechIdSetOldMap = new Map<String, Set<String>>();
			for(Event__c eventRec : eventList) {
				if(eventIdToTechIdSetNewMap.containsKey(eventRec.Id)) {
					if(!soIdToTechIdSetNewMap.containsKey(eventRec.Service_Order_Header__c)){
						soIdToTechIdSetNewMap.put(eventRec.Service_Order_Header__c, new Set<String>());
					}
					soIdToTechIdSetNewMap.get(eventRec.Service_Order_Header__c).addAll(eventIdToTechIdSetNewMap.get(eventRec.Id));
				}
				
				if(eventIdToTechIdSetOldMap.containsKey(eventRec.Id)) {
					if(!soIdToTechIdSetOldMap.containsKey(eventRec.Service_Order_Header__c)){
						soIdToTechIdSetOldMap.put(eventRec.Service_Order_Header__c, new Set<String>());
					}
					soIdToTechIdSetOldMap.get(eventRec.Service_Order_Header__c).addAll(eventIdToTechIdSetOldMap.get(eventRec.Id));
				}
			} 
			
			List<Event_Scheduling__c> availableEventSchedulingList = [Select id, Event__r.Service_Order_Header__c, Technician__c from Event_Scheduling__c 
					where Event__c IN :eventIdToTechIdSetOldMap.keySet() AND Technician__c IN: oldTechnicianIdSet];	
	
	    	for(Event_Scheduling__c eventSchedulingRec : availableEventSchedulingList) {
				if(soIdToTechIdSetOldMap.containsKey(eventSchedulingRec.Event__r.Service_Order_Header__c) && 
					soIdToTechIdSetOldMap.get(eventSchedulingRec.Event__r.Service_Order_Header__c).contains(eventSchedulingRec.Technician__c)) {
					soIdToTechIdSetOldMap.get(eventSchedulingRec.Event__r.Service_Order_Header__c).remove(eventSchedulingRec.Technician__c);
				}
			}
						
			List<Hours_Logged__c> hoursLoggedList = [Select id, Start_Date_Time__c, Technician__c, Service_Order_Header__c from Hours_Logged__c 
							where Service_Order_Header__c IN: soIdToTechIdSetNewMap.keySet()];

			List<Hours_Logged__c> hoursLogDeleteList = new  List<Hours_Logged__c>();
			
			for(Hours_Logged__c hoursLogRec : hoursLoggedList) {
				if(soIdToTechIdSetNewMap.containsKey(hoursLogRec.Service_Order_Header__c)) {
					if(soIdToTechIdSetNewMap.get(hoursLogRec.Service_Order_Header__c).contains(hoursLogRec.Technician__c)) {
						soIdToTechIdSetNewMap.get(hoursLogRec.Service_Order_Header__c).remove(hoursLogRec.Technician__c);
					} else if(soIdToTechIdSetOldMap.get(hoursLogRec.Service_Order_Header__c).contains(hoursLogRec.Technician__c) && hoursLogRec.Start_Date_Time__c == null) {
						hoursLogDeleteList.add(hoursLogRec);
					}
				} else if(soIdToTechIdSetOldMap.containsKey(hoursLogRec.Service_Order_Header__c)) {
					if(soIdToTechIdSetOldMap.get(hoursLogRec.Service_Order_Header__c).contains(hoursLogRec.Technician__c) && hoursLogRec.Start_Date_Time__c == null) {
						hoursLogDeleteList.add(hoursLogRec);
					}
				}
			}
			
			if(hoursLogDeleteList.size() > 0) {
                DMLUtility.deleteSobjectList('Hours_Logged__c', hoursLogDeleteList);
			}
			
			List<Hours_Logged__c> hoursLogInsertList = new  List<Hours_Logged__c>();
			
			for(String soId : soIdToTechIdSetNewMap.keySet()) {
				for(String techId : soIdToTechIdSetNewMap.get(soId)) {
					Hours_Logged__c hoursLogged = new Hours_Logged__c();
					hoursLogged.Technician__c = techId;
					hoursLogged.Service_Order_Header__c = soId;
					hoursLogInsertList.add(hoursLogged);
				}
			}
	
			if(hoursLogInsertList.size() > 0) {
                DMLUtility.insertSobjectList('Hours_Logged__c', hoursLogInsertList);
			}
		}
	}
	
	private static void deleteTechnicianOnServiceJob(List<Event_Scheduling__c> eventSchedulingOldList) {    
		
		Set<String> technicianIdSet = new Set<String>();
		Map<String, Set<String>> eventIdToTechIdSetOldMap = new Map<String, Set<String>>();
		Map<String, Set<String>> serviceOrderIdToTechIdSetOldMap = new Map<String, Set<String>>();

		for(Event_Scheduling__c eventSchedulingRec : eventSchedulingOldList) {
			if(!eventIdToTechIdSetOldMap.containsKey(eventSchedulingRec.Event__c)){
				eventIdToTechIdSetOldMap.put(eventSchedulingRec.Event__c, new Set<String>());
			}
			eventIdToTechIdSetOldMap.get(eventSchedulingRec.Event__c).add(eventSchedulingRec.Technician__c);
			technicianIdSet.add(eventSchedulingRec.Technician__c);
		}

		List<Event__c> eventList = [Select id, Service_Order_Header__c from Event__c where Id IN :eventIdToTechIdSetOldMap.keySet()];
		
		for(Event__c eventRec : eventList) {
			if(!serviceOrderIdToTechIdSetOldMap.containsKey(eventRec.Service_Order_Header__c)){
				serviceOrderIdToTechIdSetOldMap.put(eventRec.Service_Order_Header__c, new Set<String>());
			}
			serviceOrderIdToTechIdSetOldMap.get(eventRec.Service_Order_Header__c).addAll(eventIdToTechIdSetOldMap.get(eventRec.Id));
		} 

		List<Event_Scheduling__c> availableEventSchedulingList = [Select id, Event__r.Service_Order_Header__c, Technician__c from Event_Scheduling__c 
				where Event__c IN :eventIdToTechIdSetOldMap.keySet() AND Technician__c IN: technicianIdSet];	

		Map<String, Set<String>> serviceOrderIdToTechIdSetNewMap = new Map<String, Set<String>>();

    	for(Event_Scheduling__c eventSchedulingRec : availableEventSchedulingList) {
			if(serviceOrderIdToTechIdSetOldMap.containsKey(eventSchedulingRec.Event__r.Service_Order_Header__c) && 
				serviceOrderIdToTechIdSetOldMap.get(eventSchedulingRec.Event__r.Service_Order_Header__c).contains(eventSchedulingRec.Technician__c)) {
				serviceOrderIdToTechIdSetOldMap.get(eventSchedulingRec.Event__r.Service_Order_Header__c).remove(eventSchedulingRec.Technician__c);
			}
		}

		List<Hours_Logged__c> hoursLogDeleteList = new  List<Hours_Logged__c>();

		Map<String, List<Hours_Logged__c>> serviceOrderIdToHoursLogListMap = new Map<String, List<Hours_Logged__c>>();
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