public without sharing class AppointmentService {
    
    private static final String CONST_APPOINTMENT = 'Appointment';
    private static Map<String, ShopSettingWrapper> workingDayNameToShopSettingRecMap = new Map<String, ShopSettingWrapper>();
    private static Map<Integer, String> orderNumberToDayNameMap = new Map<Integer, String>();
    private static Integer MAX_SHOP_WORKING_DAY_ORDER_NUMBER = 7;
    private static Integer noOfDaysToAdd = 0;
    private static Integer MAX_NO_OF_DAYS_FOR_MULTI_DAY_APP = 14;
    
    public static Time MAX_ALLOWED_TIME_FOR_WORK_LATE = Time.newInstance(23, 45, 0, 0);
    
    /**
    * Name: saveAppointment
    * Desc: Method to save a appointment
    * @param: Appointment data
    **/
    public static ResponseWrapper saveAppointment(String appointmentDetailJSON) {
    	AppointmentWrapper eventObj = (AppointmentWrapper)System.JSON.deserialize(appointmentDetailJSON, AppointmentWrapper.class);
        Event__c eventRec = new Event__c(Id = eventObj.Id);
        eventRec.Type__c = CONST_APPOINTMENT;
        eventRec.Customer__c = eventObj.CustomerId;
        eventRec.Customer_Owned_Unit__c = eventObj.COUId;
        eventRec.Estimated_Hours__c = eventObj.EstimatedHours;
        eventRec.Transaction_Type__c = eventObj.TransactionTypeId;
        eventRec.Title__c = String.isNotBlank(eventObj.Title) ? eventObj.Title : 'Untitled appointment';
        eventRec.Name__c = String.isNotBlank(eventObj.Title) ? eventObj.Title : 'no title';
        if(String.isNotBlank(eventObj.COId)) {
        	eventRec.CO_Header__c = eventObj.COId;
        }
        if(String.isNotBlank(eventObj.SOHeaderId)) {
        	eventRec.Service_Order_Header__c = eventObj.SOHeaderId;
        }
        eventRec.Unit_Arrived__c = eventObj.IsUnitArrived != null ? eventObj.IsUnitArrived : false;
        eventRec.Is_MultiDay__c = eventObj.IsMultiday != null ? eventObj.IsMultiday : false;//TBD
        
        if(eventRec.Unit_Arrived__c && String.isNotBlank(eventObj.UnitLocation) ) {
    		if(eventObj.UnitLocation.length() > 25) {
                throw new BlackpurlException('Unit Location cannot be greater than 25 characters.');
            }
            eventRec.Unit_Location__c = eventObj.UnitLocation;
        } else {
            eventRec.Unit_Location__c = null;
        }
        if(String.isNotBlank(eventObj.StartTime)) {
            if(eventObj.StartTime.toLowerCase().contains('am')) {
                eventRec.Appointment_Day_Segment__c = 'Morning'; 
            } else if(eventObj.StartTime.toLowerCase().contains('pm')){
                eventRec.Appointment_Day_Segment__c = 'Afternoon';
            }
        }
        
        String concern = BPUtility.convertListIntoString(eventObj.Concern);
        String result = setStartEndDate(eventRec, eventObj, true);
        if(result != 'Success') {
            return new ResponseWrapper('Error', result);
        }

        eventRec.Appointment_Concern__c = concern;
        eventRec = (Event__c)(ServiceJobService.validateDueInAndPromisedDateTime(eventRec, null, eventObj.DueInDate, eventObj.DueInTime, 
    									eventObj.PromisedByDate, eventObj.PromiseByTime));
        try {
        	upsert eventRec;
        } catch(Exception e) {
        	if(e.getMessage().contains(EventTriggerHelper.Estimated_Hours_Error_Message)) {
        		throw new BlackpurlException(EventTriggerHelper.Estimated_Hours_Error_Message);
        	} else if(e.getMessage().contains(EventTriggerHelper.Multiday_Error_Message)) {
        		throw new BlackpurlException(EventTriggerHelper.Multiday_Error_Message);
        	}
        }
    	updateRelatedSORecord(eventRec.Id);
        return new ResponseWrapper('Success', eventRec.Id);
    }
    
    public static List<Event__c> reshuffleConflictedAppointments(String appointmentId, Event__c bookedAppointment, String appointmentDate) {
            DateTime selectedDate = HomeSearchFilterInterface.getDateFromString(appointmentDate);
            Map<String, List<String>> queryParamMap = new Map<String, List<String>>{
                            'Technician__c' => new List<String>{'=', bookedAppointment.Technician__c}
               };
            List<Event__c> conflictedAppointmentList = SchedulerSOQLUtil.getAppoitmentList(queryParamMap, selectedDate);
            
            DateTime updatedAppointmentStartTime = bookedAppointment.Start_DateTime__c;
            DateTime updatedAppointmentEndTime = (bookedAppointment.End_DateTime__c != null) ? bookedAppointment.End_DateTime__c : 
                                                        updatedAppointmentStartTime.addMinutes((Integer) (bookedAppointment.Estimated_Hours__c * 60));
            
            List<Event__c> conflictedAppointmentToUpdateList = new List<Event__c>();
            for(Event__c conflictAppointmentRec : conflictedAppointmentList) {
                if(conflictAppointmentRec.Is_MultiDay__c && bookedAppointment.Is_MultiDay__c) {
                    throw new BlackpurlException('This multiday is conflicting with another multiday event');
                }
                if(!conflictAppointmentRec.Is_MultiDay__c && !bookedAppointment.Is_MultiDay__c && 
                    updatedAppointmentStartTime <= conflictAppointmentRec.Start_DateTime__c && conflictAppointmentRec.Start_DateTime__c < updatedAppointmentEndTime) {
                    
                    updatedAppointmentStartTime = conflictAppointmentRec.Start_DateTime__c = updatedAppointmentEndTime;
                    updatedAppointmentEndTime = conflictAppointmentRec.End_DateTime__c = 
                                    conflictAppointmentRec.Start_DateTime__c.addMinutes((Integer) (conflictAppointmentRec.Estimated_Hours__c * 60));
                    conflictedAppointmentToUpdateList.add(conflictAppointmentRec);
                }
            } 
            return conflictedAppointmentToUpdateList;
    }
    
    public static String setStartEndDate(Event__c eventRec, AppointmentWrapper appointmentDetailObj, Boolean isFromAddEditAppointment) {
    	return EventSchedulingService.setStartEndDate(eventRec, null, appointmentDetailObj.StartDate, appointmentDetailObj.StartTime, appointmentDetailObj.EstimatedHours, 
    									 appointmentDetailObj.IsMultiday, isFromAddEditAppointment);
            }
            
    public static void setShopWorkingDaysMap() {
        for(ShopSettingWrapper shopSettingRec: AccountSettingService.getShopSettingData()) {
            if(shopSettingRec.IsWorking) {
                workingDayNameToShopSettingRecMap.put(shopSettingRec.Day, shopSettingRec);
                orderNumberToDayNameMap.put(shopSettingRec.OrderNumber, shopSettingRec.Day);
            }
        }
    }
    
    public static String isValidStartTime(String startDayName, String startTime) {
        if(workingDayNameToShopSettingRecMap.containsKey(startDayName)) {
            Time appointmentStartTime = DateTimeUtility.getTimeFromString(startTime);
            Time shopStartTimeForDay = DateTimeUtility.getTimeFromString(workingDayNameToShopSettingRecMap.get(startDayName).FromTime);
            //Time shopEndTimeForDay = DateTimeUtility.getTimeFromString(workingDayNameToShopSettingRecMap.get(startDayName).ToTime);
            if(appointmentStartTime < shopStartTimeForDay) {
                return 'Appointment start time can\'t be less than shop\'s start time.';
            } else {
                return '';
            }
        }
        return 'Appointment can\'t be scheduled for shop\'s non working day.';
    }
    
    public static DateTime setEndDateWhenWorkLateDisabled(String dayName, String appointmentStartTimeStr, Integer apointmentMinutes, DateTime tempDateTime) {
        Time appointmentStartTime = DateTimeUtility.getTimeFromString(appointmentStartTimeStr);
        Time shopEndTimeForDay = DateTimeUtility.getTimeFromString(workingDayNameToShopSettingRecMap.get(dayName).ToTime);
        Integer availableMinutesOnDay = ((shopEndTimeForDay.hour() - appointmentStartTime.hour())*60) + (shopEndTimeForDay.minute() - appointmentStartTime.minute());
        if(apointmentMinutes > availableMinutesOnDay) {
            Integer orderNumber = workingDayNameToShopSettingRecMap.get(dayName).OrderNumber;
            ShopSettingWrapper shopRecForNextDay = getShopRecForNextDay(orderNumber);
            apointmentMinutes = apointmentMinutes - availableMinutesOnDay;
            tempDateTime = DateTime.newInstance(tempDateTime.date().addDays(noOfDaysToAdd), DateTimeUtility.getTimeFromString(shopRecForNextDay.FromTime));
            noOfDaysToAdd = 0;
            return setEndDateWhenWorkLateDisabled(shopRecForNextDay.Day, shopRecForNextDay.FromTime, apointmentMinutes, tempDateTime);
        } else {
            return tempDateTime.addMinutes(apointmentMinutes);
        }
    }
    
    private static ShopSettingWrapper getShopRecForNextDay(Integer orderNumber) {
        if(orderNumber == MAX_SHOP_WORKING_DAY_ORDER_NUMBER) {
            orderNumber = 0;
        }
        orderNumber++;
        noOfDaysToAdd++;
        if(orderNumberToDayNameMap.containsKey(orderNumber)) {
            return workingDayNameToShopSettingRecMap.get(orderNumberToDayNameMap.get(orderNumber));
        } else {
            return getShopRecForNextDay(orderNumber);
        }
    }
    
    public static CustomerWrapper getCustomerRecByCustomerId(String customerId) {
        List<Account> customerRecList = SOQLUtil.getCustomer(customerId, 'Customer', false, null);
        List<Customer_Owned_Unit__c> couRecords = SOQLUtil.geCOUList(customerId, new Map<String, String>{'Status__c' => 'Active'});
        CustomerWrapper customerWrapperObj;
        if(customerRecList.size() > 0) {
            customerWrapperObj = new CustomerWrapper(customerRecList[0], couRecords);
        }
        return customerWrapperObj;
    }
    
    public static CustomerOwnedUnit getUnitById(String couId) {
        List<Sobject> unitRecList = SOQLUtil.getCOUListByFieldName('Id', couId);
        CustomerOwnedUnit unitObj;
        if(unitRecList.size() > 0) {
            unitObj = new CustomerOwnedUnit((Customer_Owned_Unit__c) unitRecList[0]);
        }
        return unitObj;
    }
    
    public static String deleteAppointmentById(String appointmentRecId){
        if(!AccessControl.ifObjectIsDeletable('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete new Event__c(Id = appointmentRecId);
        return 'SUCCESS';
    }
    
    public static List<ServiceOrderWrapper.TTType> getJobTypeList(){
        List<Transaction_Type__c> ttList = SOQLUtil.getTransactionTypesWithProvider(new List<Id>());
        ttList = ServiceJobTypeService.sortJobTypes(ttList);
        List<ServiceOrderWrapper.TTType> jobTypeList = new List<ServiceOrderWrapper.TTType>();
        for(Transaction_Type__c ttRec: ttList) {
            jobTypeList.add(new ServiceOrderWrapper.TTType(ttRec));
        }
        return jobTypeList;
    }
    
    public static void updateRelatedSORecord(String appointmentRecId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Event__c> eventList = [SELECT Promised_By_DateTime__c, Unit_Arrived__c, Unit_Location__c, Due_In_DateTime__c, Due_In_Time__c, Promised_By_Time__c, 
        	Service_Order_Header__c, Customer__c, Customer_Owned_Unit__c, Name__c, Transaction_Type__c, Appointment_Concern__c 
            FROM Event__c WHERE ID =: appointmentRecId AND Service_Order_Header__c != null];
        List<Service_Order_Header__c> soListToUpdate = new List<Service_Order_Header__c>();
        for(Event__c eventRec : eventList) {
            Service_Order_Header__c soRec = new Service_Order_Header__c(Id = eventRec.Service_Order_Header__c);
            soRec.Name__c = eventRec.Name__c;
            soRec.SO_Concern__c = eventRec.Appointment_Concern__c;
            
            soRec.Promised_By_DateTime__c = eventRec.Promised_By_DateTime__c;
            soRec.Due_In_DateTime__c = eventRec.Due_In_DateTime__c;
            soRec.Promised_By_Time__c = eventRec.Promised_By_Time__c;
            soRec.Due_In_Time__c = eventRec.Due_In_Time__c;
            soRec.Unit_Arrived__c = eventRec.Unit_Arrived__c;
            soRec.Unit_Location__c = eventRec.Unit_Location__c;
            
            /*if(String.isNotBlank(eventRec.Event_Concern__c)) {
                NotesService.populateConcernsOnSO(soRec, eventRec.Event_Concern__c);
            }*/
            soRec.Customer_Owned_Unit__c = eventRec.Customer_Owned_Unit__c;
            soListToUpdate.add(soRec);
        }
        
        if(soListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Service_Order_Header__c', soListToUpdate);
        }
    }
    
    public static void populateSOKitConcernsOnAppointment(AppointmentWrapper appointmentObj, String soHeaderId) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Kit_Header__c> soKitHeaderList = [SELECT Id, Kit_Header__c, Kit_Header__r.Concern__c FROM Service_Order_Kit_Header__c WHERE Service_Order_Header__c =: soHeaderId];
        for(Service_Order_Kit_Header__c soKitHeaderRec : soKitHeaderList) {
            if(soKitHeaderRec.Kit_Header__c != null && soKitHeaderRec.Kit_Header__r.Concern__c != null) {
                appointmentObj.SOKitConcern.addAll(soKitHeaderRec.Kit_Header__r.Concern__c.split('\n'));
            }
        }
    }
    
    public static Map<String, List<String>> getSOKitConcernsByAppointments(List<Event__c> eventList) {
    	Map<String, Event__c> soIdToEventRecMap = new Map<String, Event__c>();
    	for(Event__c eventRec : eventList) {
    		if(eventRec.Service_Order_Header__c != null) {
    			soIdToEventRecMap.put(eventRec.Service_Order_Header__c, eventRec);
    		}
    	}
    	Map<String, List<String>> eventIdToSOKitConcernList = new Map<String, List<String>>();
    	if(soIdToEventRecMap.size() > 0) {
	        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        List<Service_Order_Kit_Header__c> soKitHeaderList = [SELECT Id, Service_Order_Header__c, Kit_Header__r.Concern__c FROM Service_Order_Kit_Header__c 
	        			WHERE Service_Order_Header__c IN: soIdToEventRecMap.keySet() AND Kit_Header__c != null LIMIT: SOQLUtil.getAvailableQueryRowsLimit()];
	        
	        for(Service_Order_Kit_Header__c soKitHeaderRec : soKitHeaderList) {
	            if(soKitHeaderRec.Kit_Header__r.Concern__c != null && soIdToEventRecMap.containsKey(soKitHeaderRec.Service_Order_Header__c)) {
	            	String eventId = soIdToEventRecMap.get(soKitHeaderRec.Service_Order_Header__c).Id;
	            	if(String.isNotBlank(eventId)) {
		            	if(!eventIdToSOKitConcernList.containsKey(eventId)) {
		            		eventIdToSOKitConcernList.put(eventId, new List<String>());
		            	}
		                eventIdToSOKitConcernList.get(eventId).addAll(soKitHeaderRec.Kit_Header__r.Concern__c.split('\n'));
	            	}
	            }
	        }
    	}
    	return eventIdToSOKitConcernList;
    }
    
    public static List<TechnicianDetailWrapper> getTechnicianListWithAvailableHours(String appointmentDetailJSON) {
        AppointmentWrapper appointmentDetailObj = (AppointmentWrapper)System.JSON.deserialize(appointmentDetailJSON, AppointmentWrapper.class);
        DateTime selectedDate = HomeSearchFilterInterface.getDateFromString(appointmentDetailObj.StartDate);
        List<Technician__c> technicianList = SchedulerSOQLUtil.getTechnicianList(selectedDate);
        
        Date dateFromDateTime = Date.newinstance(selectedDate.year(), selectedDate.month(), selectedDate.day());
        String day = AccountSettingService.getDayNameFromDate(dateFromDateTime);
        
        if(AccessControl.ifObjectFieldIsAccessible('Shop_Settings__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Shop_Settings__c> shopSettingList = [Select Id, From_Time__c, To_Time__c from Shop_Settings__c where Day__c =: day AND Is_Working__c = true];
        
        List<TechnicianDetailWrapper> techObjList = new List<TechnicianDetailWrapper>();
        for(Technician__c techRec : technicianList) {
            techObjList.add(new TechnicianDetailWrapper(techRec, day, shopSettingList, selectedDate, appointmentDetailObj.EstimatedHours));
        }
        
        //system.assert(false, techObjList);
        return sortTechnicianList(techObjList, appointmentDetailObj.EstimatedHours, appointmentDetailObj.AppointmentDaySegment);
    }
    
    private static List<TechnicianDetailWrapper> sortTechnicianList(List<TechnicianDetailWrapper> techObjList, Decimal estimatedHours, String appointmentDaySegment) {
        List<TechnicianDetailWrapper> technicianListWithEnoughAvailableHoursInSameSegment = new List<TechnicianDetailWrapper>();
        List<TechnicianDetailWrapper> technicianListWithEnoughAvailableHoursInOppositeSegment = new List<TechnicianDetailWrapper>();
        List<TechnicianDetailWrapper> technicianListWithMostAvailableHours = new List<TechnicianDetailWrapper>();
        for(TechnicianDetailWrapper techObjRec: techObjList) {
            if(appointmentDaySegment == 'Morning') {
                if(techObjRec.AvailableHoursMorning >= EstimatedHours) {
                    techObjRec.HoursForSorting = techObjRec.AvailableHoursMorning;
                    technicianListWithEnoughAvailableHoursInSameSegment.add(techObjRec);
                } else if(techObjRec.AvailableHoursAfternoon >= EstimatedHours) {
                    techObjRec.HoursForSorting = techObjRec.AvailableHoursAfternoon;
                    technicianListWithEnoughAvailableHoursInOppositeSegment.add(techObjRec);
                } else {
                    techObjRec.HoursForSorting = (techObjRec.AvailableHoursMorning + techObjRec.AvailableHoursAfternoon);
                    technicianListWithMostAvailableHours.add(techObjRec);
                }
            } else if(appointmentDaySegment == 'Afternoon') {
                if(techObjRec.AvailableHoursAfternoon >= EstimatedHours) {
                    techObjRec.HoursForSorting = techObjRec.AvailableHoursAfternoon;
                    technicianListWithEnoughAvailableHoursInSameSegment.add(techObjRec);
                } else if(techObjRec.AvailableHoursMorning >= EstimatedHours) {
                    techObjRec.HoursForSorting = techObjRec.AvailableHoursMorning;
                    technicianListWithEnoughAvailableHoursInOppositeSegment.add(techObjRec);
                } else {
                    techObjRec.HoursForSorting = (techObjRec.AvailableHoursMorning + techObjRec.AvailableHoursAfternoon);
                    technicianListWithMostAvailableHours.add(techObjRec);
                }
            }
        }
        
        List<TechnicianDetailWrapper> sortedTechObjList = new List<TechnicianDetailWrapper>();
        
        technicianListWithEnoughAvailableHoursInSameSegment.sort();
        sortedTechObjList.addAll(technicianListWithEnoughAvailableHoursInSameSegment);
        
        technicianListWithEnoughAvailableHoursInOppositeSegment.sort();
        sortedTechObjList.addAll(technicianListWithEnoughAvailableHoursInOppositeSegment);
        
        technicianListWithMostAvailableHours.sort();
        sortedTechObjList.addAll(technicianListWithMostAvailableHours);
        return sortedTechObjList;
    }
    
    public static AppointmentWrapper getAppointmentById(String appId) {
    	List<Event__c> appList = SchedulerSOQLUtil.getAppointmentListByIds(new List<String>{appId});
    	if(appList.size() > 0) {
    		return new AppointmentWrapper(appList[0], true);
    	} else {
    		throw new BlackpurlException('No appointment found with Id - ' + appId);
    	}
    }
    
    public static void createCOForEvent(String eventId) {
        Map<String, List<String>> queryParamMap = new Map<String, List<String>>{'Id' => new List<String>{'=', eventId}, 'Service_Order_Header__c' => new List<String>{'=', null}};
        List<Event__c> eventList = SchedulerSOQLUtil.getAppoitmentList(queryParamMap, null);
        
    	if(eventList.size() > 0) {
    		JobSchedulerService.createCOWithServiceJob(system.Json.serialize(new AppointmentWrapper(eventList[0])));
    	}
    }
    
    public static String getTimeSlotAndStateForTechnician(String timeSlotJson) {
    	TimeSlotWrapper timeSlotObj = (TimeSlotWrapper)System.JSON.deserialize(timeSlotJson, TimeSlotWrapper.class);
        String appDay = timeSlotObj.AppointmentDate != null ? HomeSearchFilterInterface.getDateFromString(timeSlotObj.AppointmentDate).format('EEEE') : timeSlotObj.AppointmentDay;
        List<ShopSettingWrapper> shopSettingData= AccountSettingService.getShopSettingDataForParticularDay(appDay);
        Time shopFromTime, shopEndTime, startTime, endTime ;
        
        ShopSettingWrapper shopSettingDayObj;
        for(Integer i = 0; i < shopSettingData.size(); i++) {
            if(shopSettingData[i].Day == appDay) {
                shopSettingDayObj = shopSettingData[i];
                shopFromTime = DateTimeUtility.getTimeFromString(shopSettingData[i].FromTime);
                shopEndTime = DateTimeUtility.getTimeFromString(shopSettingData[i].ToTime);
                break;
            }
        }
        shopSettingData = null;
        
        List<TimeSlotWrapper> timeSlotWrapper = new List<TimeSlotWrapper>();
        while(shopFromTime <= shopEndTime) {
            timeSlotWrapper.add(new TimeSlotWrapper( shopFromTime, 'Available'));
            shopFromTime = shopFromTime.addMinutes(15);
        }
        
        DateTime selectedDate = HomeSearchFilterInterface.getDateFromString(timeSlotObj.AppointmentDate);
        Map<String, List<String>> queryParamMap = new Map<String, List<String>>{
                        'Technician__c' => new List<String>{'=', timeSlotObj.TechnicianId}
           };
        List<Event_Scheduling__c> eventSchedulingList = SchedulerSOQLUtil.getEventSchedulingListByQueryParam(queryParamMap, selectedDate); 
        
        Integer noOfMinutes = Integer.ValueOf((timeSlotObj.EstimatedHours * 60  * -1) + 15);
        Set<Time> notAvailableRecSet = new Set<Time>();
        Set<Time> pushedRecSet = new Set<Time>();
        
        for(Event_Scheduling__c eventSchedulingRec : eventSchedulingList) {
        	Boolean isMultidayScheduling = EventSchedulingService.isMultiDayScheduling(eventSchedulingRec);
            if(timeSlotObj.AppointmentId != null && eventSchedulingRec.Id == timeSlotObj.AppointmentId) {
                continue;
            } else if((timeSlotObj.IsMultiDay == null || !timeSlotObj.IsMultiDay) && isMultidayScheduling) {
                continue;
            } else if(timeSlotObj.IsMultiDay != null && timeSlotObj.IsMultiDay && !isMultidayScheduling) {
                continue;
            }
            
            startTime = Time.newInstance(eventSchedulingRec.Start_Date_Time__c.hour(), eventSchedulingRec.Start_Date_Time__c.minute(), eventSchedulingRec.Start_Date_Time__c.second(), eventSchedulingRec.Start_Date_Time__c.millisecond());
        	endTime = Time.newInstance(eventSchedulingRec.End_Date_Time__c.hour(), eventSchedulingRec.End_Date_Time__c.minute(), eventSchedulingRec.End_Date_Time__c.second(), eventSchedulingRec.End_Date_Time__c.millisecond());
            if(isMultidayScheduling && shopSettingDayObj != null) {
                startTime =  (eventSchedulingRec.Start_Date_Time__c.isSameDay(selectedDate)) ? startTime : DateTimeUtility.getTimeFromString(shopSettingDayObj.FromTime);
                endTime =  (eventSchedulingRec.End_Date_Time__c.isSameDay(selectedDate)) ? endTime : DateTimeUtility.getTimeFromString(shopSettingDayObj.ToTime);
            }

            Time startTimeToCompare = startTime;
            while(startTimeToCompare < endTime) {
            	notAvailableRecSet.add(startTimeToCompare);
                startTimeToCompare = startTimeToCompare.addMinutes(15);
            }
                
            Time pushTimeInterval = startTime.addMinutes(noOfMinutes);
            while(pushTimeInterval < startTime) {
                pushedRecSet.add(pushTimeInterval);
                pushTimeInterval = pushTimeInterval.addMinutes(15);
            }
        }
        
        for(TimeSlotWrapper timeslots : timeSlotWrapper) {
            if(notAvailableRecSet.contains(timeslots.TimeSlot)) {
                timeslots.availabiltyStatus = 'Booked';
            } else if(!notAvailableRecSet.contains(timeslots.TimeSlot) && pushedRecSet.contains(timeslots.TimeSlot)) {
                timeslots.availabiltyStatus = 'Push';
            } else {
                timeslots.availabiltyStatus = 'Available';
            }
            
            Datetime timeSlotRecord = Datetime.newInstance(Date.newinstance(selectedDate.year(), selectedDate.month(), selectedDate.day()), timeslots.TimeSlot);
            timeslots.TimeSlotRec = timeSlotRecord.format('h:mm a');
            timeslots.TimeSlot = null;
        } 
        
        return system.json.serialize(timeSlotWrapper,true);
    }

    public class TimeSlotWrapper{
        public String AppointmentDate;
        public String TechnicianId;
        public String availabiltyStatus;
        public Decimal EstimatedHours;
        public Time TimeSlot;
        public String TimeSlotRec;
        public String AppointmentDay;
        public String AppointmentId;
        public Boolean IsMultiDay;
        
        public TimeSlotWrapper(Time timeSlot, String status) {
            this.availabiltyStatus = status;
            this.TimeSlot = timeSlot;
        }
    }
}