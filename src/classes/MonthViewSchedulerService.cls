public without sharing class MonthViewSchedulerService {
 	
 	public static Integer NumberOfDaysToView = 31;
 	public static final String Month_VIEW = 'Month';
 	public static final String Date_Format = 'dd/MM/YYYY';
 	
 	public static Map<String, Time> weekDayToShopFromTimeMap = new Map<String, Time>();
    public static Map<String, Time> weekDayToShopToTimeMap = new Map<String, Time>();
    
 	public static MonthViewSchedulerWrapper getSchedulerDataForDateRange(String fromDateStr, String toDateStr) {
        if(AccessControl.ifObjectFieldIsAccessible('Shop_Settings__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Shop_Settings__c> shopSettingList = [Select Name, Day__c, From_Time__c, To_Time__c, Is_Working__c from Shop_Settings__c 
        			WHERE Name != null AND Is_Working__c = true order by Order_Number__c];
        for(Shop_Settings__c shopDay : shopSettingList) {
    		weekDayToShopFromTimeMap.put(shopDay.Day__c.toLowerCase(), DateTimeUtility.getTimeFromString(shopDay.From_Time__c));
    		weekDayToShopToTimeMap.put(shopDay.Day__c.toLowerCase(), DateTimeUtility.getTimeFromString(shopDay.To_Time__c));
        }
        
        DateTime fromDateTime = HomeSearchFilterInterface.getDateFromString(fromDateStr);
        DateTime toDateTime = HomeSearchFilterInterface.getDateFromString(toDateStr);
        
        Date viewStartDate = date.newinstance(fromDateTime.year(), fromDateTime.month(), fromDateTime.day());
      	Date viewEndDate = date.newinstance(toDateTime.year(), toDateTime.month(), toDateTime.day());
      	
      	MonthViewSchedulerWrapper monthViewWrapperObj = new MonthViewSchedulerWrapper(viewStartDate, viewEndDate);

		//Get Technician with leave
        List<Technician__c> technicianRecList = SOQLUtil.getTechniciansWithLeaveWithinTimePeriod(null, fromDateTime, toDateTime);
        
        //Get Appointment
        Map<String, List<String>> queryParamMap = new Map<String, List<String>>();
        queryParamMap.put('Technician__c', new List<String>{'<>', null});
        List<Event_Scheduling__c> assignedAppRecList = SchedulerSOQLUtil.getEventSchedulingListWithinPeriodWithFilter(queryParamMap, fromDateTime, toDateTime);

        Map<String, Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>> techIdToDayToMultiDayEventListMap = 
        	new Map<String, Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>>();
        
        Map<String, Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>> techIdToDayToSingleDayEventListMap = 
        					new Map<String, Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>>();
        					
        Map<String, Map<String, Decimal>> techIdToDayToBookedHoursMap = new Map<String, Map<String, Decimal>>();
        
        Map<String, List<Event_Scheduling__c>> techIdToMultiDayAppListMap = new Map<String, List<Event_Scheduling__c>>();
        Map<String, List<Event_Scheduling__c>> techIdToSingleDayAppListMap = new Map<String, List<Event_Scheduling__c>>();
        for(Event_Scheduling__c appRec : assignedAppRecList) {
			if(appRec.Event__r.Is_MultiDay__c) {
				if(!techIdToMultiDayAppListMap.containsKey(appRec.Technician__c)) {
					techIdToMultiDayAppListMap.put(appRec.Technician__c, new List<Event_Scheduling__c>{appRec});
				} else {
					techIdToMultiDayAppListMap.get(appRec.Technician__c).add(appRec);
				}
			} else {
				if(!techIdToSingleDayAppListMap.containsKey(appRec.Technician__c)) {
					techIdToSingleDayAppListMap.put(appRec.Technician__c, new List<Event_Scheduling__c>{appRec});
				} else {
					techIdToSingleDayAppListMap.get(appRec.Technician__c).add(appRec);
				}
			}
		}
		Set<String> conflictedAppIdSet = new Set<String>();
		if(techIdToSingleDayAppListMap.size() != 0 && techIdToMultiDayAppListMap.size() != 0) {
			for(String techId : techIdToSingleDayAppListMap.keySet()) {
				for(Event_Scheduling__c singleDayAppRec : techIdToSingleDayAppListMap.get(techId)) {
					if(singleDayAppRec.Start_Date_Time__c != null && singleDayAppRec.End_Date_Time__c != null && techIdToMultiDayAppListMap.containsKey(techId)) {
						for(Event_Scheduling__c multidayAppRec : techIdToMultiDayAppListMap.get(techId)) {
							if(multidayAppRec.Start_Date_Time__c != null && multidayAppRec.End_Date_Time__c != null) {
								if(singleDayAppRec.Start_Date_Time__c < multidayAppRec.End_Date_Time__c && multidayAppRec.Start_Date_Time__c < singleDayAppRec.End_Date_Time__c) {
									conflictedAppIdSet.add(singleDayAppRec.Id);
									conflictedAppIdSet.add(multidayAppRec.Id);
								}
							}
						}
					}
				}
			}
		}

		techIdToMultiDayAppListMap = techIdToSingleDayAppListMap = null;
        for(Event_Scheduling__c appRec : assignedAppRecList) {
        	DateTime eventFromDateTime = (appRec.Start_Date_Time__c < fromDateTime) ? fromDateTime : appRec.Start_Date_Time__c;
	    	DateTime eventToDateTime = (toDateTime < appRec.End_Date_Time__c) ? toDateTime : appRec.End_Date_Time__c;
        	
        	Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>> dayToEventListMap = new Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>();
        	if(appRec.Event__r.Is_MultiDay__c) {
        		if(!techIdToDayToMultiDayEventListMap.containsKey(appRec.Technician__c)) {
        			techIdToDayToMultiDayEventListMap.put(appRec.Technician__c, new Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>());
        		}
    			dayToEventListMap = techIdToDayToMultiDayEventListMap.get(appRec.Technician__c);
        	} else {
        		if(!techIdToDayToSingleDayEventListMap.containsKey(appRec.Technician__c)) {
        			techIdToDayToSingleDayEventListMap.put(appRec.Technician__c, new Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>());
        		}
        		
        		dayToEventListMap = techIdToDayToSingleDayEventListMap.get(appRec.Technician__c);
        	}
        	
        	Integer appLastsFor = getEventLastFor(eventFromDateTime, eventToDateTime);
        	
        	Boolean isConflicted = conflictedAppIdSet.contains(appRec.Id) ? true : false;
        	if(!dayToEventListMap.containsKey(eventFromDateTime.format(Date_Format))) {
        		dayToEventListMap.put(eventFromDateTime.format(Date_Format), new List<MonthViewSchedulerWrapper.BlockWrapper>());
        	}
        	dayToEventListMap.get(eventFromDateTime.format(Date_Format)).add(new MonthViewSchedulerWrapper.BlockWrapper(appRec, appLastsFor, isConflicted));
        	
        	Map<String, Decimal> dayToBookedHoursMap = new Map<String, Decimal>();
        	if(techIdToDayToBookedHoursMap.containsKey(appRec.Technician__c)) {
        		dayToBookedHoursMap = techIdToDayToBookedHoursMap.get(appRec.Technician__c);
        	}
        	
    		getDayToNumberOfHoursCoveredMap(appRec.Start_Date_Time__c, appRec.End_Date_Time__c, dayToBookedHoursMap, appRec.Event__r.Is_MultiDay__c);
        	techIdToDayToBookedHoursMap.put(appRec.Technician__c, dayToBookedHoursMap);
        }
        assignedAppRecList = null;
        
        Decimal totalBookedHrs = 0;
        Decimal totalScheduledHrs = 0;
        for(Technician__c techRec : technicianRecList) {
        	Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>> dayToLeaveBlockListMap = new Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>();
        	Map<String, Decimal> dayToLeaveHoursMap = new Map<String, Decimal>();
        	
        	for(Leave__c leaveRec : techRec.Leaves__r) {
        		DateTime leaveFromDateTime = (leaveRec.From__c < fromDateTime) ? fromDateTime : leaveRec.From__c;
		    	DateTime leaveToDateTime = (toDateTime < leaveRec.To__c) ? toDateTime : leaveRec.To__c;
		    	
		    	if(!dayToLeaveBlockListMap.containsKey(leaveFromDateTime.format(Date_Format))) {
		    		dayToLeaveBlockListMap.put(leaveFromDateTime.format(Date_Format), new List<MonthViewSchedulerWrapper.BlockWrapper>());
		    	}
		    	Integer leaveLastFor = getEventLastFor(leaveFromDateTime, leaveToDateTime);
		    	dayToLeaveBlockListMap.get(leaveFromDateTime.format(Date_Format)).add(new MonthViewSchedulerWrapper.BlockWrapper(leaveRec, leaveLastFor));
		    	
            	getDayToNumberOfHoursCoveredMap(leaveFromDateTime, leaveToDateTime, dayToLeaveHoursMap, true);
        	} 

        	Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>> dayToMultiDayAppListMap = new Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>();
        	if(techIdToDayToMultiDayEventListMap.containsKey(techRec.Id)) {
        		dayToMultiDayAppListMap = techIdToDayToMultiDayEventListMap.get(techRec.Id);
        	}
        	
        	Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>> dayToSingleDayAppListMap = new Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>>();
        	if(techIdToDayToSingleDayEventListMap.containsKey(techRec.Id)) {
        		dayToSingleDayAppListMap = techIdToDayToSingleDayEventListMap.get(techRec.Id);
        	}
        	
        	Map<String, Decimal> dayToBookedHoursMap = new Map<String, Decimal>();
        	if(techIdToDayToBookedHoursMap.containsKey(techRec.Id)) {
        		dayToBookedHoursMap = techIdToDayToBookedHoursMap.get(techRec.Id);
        	}
        	
        	MonthViewSchedulerWrapper.TechnicianMonthViewWrapper techWrapperObj = new MonthViewSchedulerWrapper.TechnicianMonthViewWrapper(fromDateTime, techRec, 
        		dayToLeaveBlockListMap, dayToLeaveHoursMap, dayToMultiDayAppListMap, dayToSingleDayAppListMap, dayToBookedHoursMap);
        		
        	if(techWrapperObj.HoursBooked != null) totalBookedHrs += techWrapperObj.HoursBooked;
        	if(techWrapperObj.HoursScheduledToWork != null) totalScheduledHrs += techWrapperObj.HoursScheduledToWork;
        	
        	techWrapperObj.HoursBooked = techWrapperObj.HoursScheduledToWork = null;
        	monthViewWrapperObj.TechnicianDetailList.add(techWrapperObj);
        }
        
        monthViewWrapperObj.TotalScheduledHours = totalScheduledHrs;
        monthViewWrapperObj.TotalBookedHours = totalBookedHrs;
        
        system.debug('== getCpuTime ==' + Limits.getCpuTime());
        system.debug('== getHeapSize ==' + Limits.getHeapSize());
        system.debug('== getQueries ==' + Limits.getQueries());
        return monthViewWrapperObj;
    }
    
    private static Integer getEventLastFor(DateTime eventStartDateTime, DateTime eventEndDateTime) {
    	Date startDate = Date.newInstance(eventStartDateTime.year(), eventStartDateTime.month(), eventStartDateTime.day());
    	Date endDate = Date.newInstance(eventEndDateTime.year(), eventEndDateTime.month(), eventEndDateTime.day());
	    Integer leaveLastFor = startDate.daysBetween(endDate) + 1;
        
        return leaveLastFor;
    } 
    
    private static void getDayToNumberOfHoursCoveredMap(DateTime eventStartDateTime, DateTime eventEndDateTime, Map<String, Decimal> dayToHoursMap, Boolean isMultiDayEvent) {
    	Date eventStartDate = Date.newinstance(eventStartDateTime.year(), eventStartDateTime.month(), eventStartDateTime.day());
      	Date eventEndDate = Date.newinstance(eventEndDateTime.year(), eventEndDateTime.month(), eventEndDateTime.day());
	            
	    if(dayToHoursMap == null) {
	    	dayToHoursMap = new Map<String, Decimal>();
	    }
	    for(Date appDate = eventStartDate; appDate <= eventEndDate;) {
	    	DateTime appDateTime = Datetime.newInstance(appDate.year(), appDate.month(), appDate.day());
	    	String weekDay = appDateTime.format('EEEE');

	    	if(weekDayToShopFromTimeMap.containsKey(weekDay.toLowerCase())) {
		    	
		    	Time shopFromTime = weekDayToShopFromTimeMap.get(weekDay.toLowerCase());
		    	Time shopToTime = weekDayToShopToTimeMap.get(weekDay.toLowerCase());
		    		
		    	Time eventFromTime = DateTimeUtility.getTimeFromString2(eventStartDateTime.format('h:mma'));
		    	Time eventToTime = DateTimeUtility.getTimeFromString2(eventEndDateTime.format('h:mma'));
		    	
		    	Time fromTimeForThisDay, toTimeForThisDay;
		    	
	    		fromTimeForThisDay = shopFromTime;
	    		toTimeForThisDay = shopToTime;
	    		
	    		if(!isMultiDayEvent) {
	    			fromTimeForThisDay = eventFromTime;
	    			toTimeForThisDay = eventToTime;
	    		} else {
			    	if(appDateTime.isSameDay(eventStartDateTime) && shopFromTime < eventFromTime) {
		    			fromTimeForThisDay = eventFromTime;
			    	} 
			    	if(appDateTime.isSameDay(eventEndDateTime) && shopToTime > eventToTime) {
		    			toTimeForThisDay = eventToTime;
			    	}
	    		}
				
		    	if(!isMultiDayEvent || (fromTimeForThisDay < shopToTime && toTimeForThisDay > shopFromTime)) {
		    		DateTime fromDateTimeForThisDay = Datetime.newInstance(appDate, fromTimeForThisDay);
		    								
		    		DateTime toDateTimeForThisDay = Datetime.newInstance(appDate, toTimeForThisDay);
		    								
		    		String fromTimeForThisDayStr = fromDateTimeForThisDay.format('h:mma');
		    		String toTimeForThisDayStr = toDateTimeForThisDay.format('h:mma');
		    								
		    		String formattedDate = fromDateTimeForThisDay.format(Date_Format);
		    		if(!dayToHoursMap.containsKey(formattedDate)) {
		    			dayToHoursMap.put(formattedDate, 0);
		    		}
		    		Decimal hrsCovered = dayToHoursMap.get(formattedDate);
		    		
		    		hrsCovered += (DateTimeUtility.getTimeBySegment('AM', fromTimeForThisDayStr, toTimeForThisDayStr));
	                hrsCovered += (DateTimeUtility.getTimeBySegment('PM', fromTimeForThisDayStr, toTimeForThisDayStr));
	                
	                dayToHoursMap.put(formattedDate, hrsCovered);
		    	}
	    	}
	    	appDate = appDate.addDays(1);
	    }  
    }   
}