public without sharing class JobSchedulerService {
    
    public static List<TechnicianDetailWrapper> getTechnicianListForSpecificDay(String dateStr) {
        DateTime selectedDate = HomeSearchFilterInterface.getDateFromString(dateStr);
        List<Technician__c> technicianList = SchedulerSOQLUtil.getTechnicianList(selectedDate);
        
        Date dateFromDateTime = Date.newinstance(selectedDate.year(), selectedDate.month(), selectedDate.day());
        String day = AccountSettingService.getDayNameFromDate(dateFromDateTime);
        
        if(AccessControl.ifObjectFieldIsAccessible('Shop_Settings__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Shop_Settings__c> shopSettingList = [Select Id, From_Time__c, To_Time__c, Is_Working__c from Shop_Settings__c where Day__c =: day];
        
        List<TechnicianDetailWrapper> techObjList = new List<TechnicianDetailWrapper>();
        for(Technician__c techRec : technicianList) {
            techObjList.add(new TechnicianDetailWrapper(techRec, day, shopSettingList, selectedDate));
        }
        return techObjList;
    }
    
    public static List<UnassignedAppointmentPulloutWrapper.DatewiseUnassignedAppWrapper> getAllUnassignedAppointmentsForPullOut() {
        Map<String, List<String>> queryParamMap = new Map<String, List<String>>{
                       'Event_Scheduling_Count__c' => new List<String>{'= 0', ''},
                       'Service_Order_Header__r.Invoice_Number__c' => new List<String>{'=', null},
                       'CO_Header__r.Order_Status__c' => new List<String>{'!=', 'Closed'}
           };
        List<Event__c> appointmentList = SchedulerSOQLUtil.getAppoitmentList(queryParamMap, null);
        UnassignedAppointmentPulloutWrapper pulloutWrapperObj = new UnassignedAppointmentPulloutWrapper(appointmentList);
        return pulloutWrapperObj.DaywiseUnassignedAppointmentList;
    }
    
    /**
    public static List<AppointmentWrapper> getUnassignedAppointmentForSpecificDay(String dateStr) {
        DateTime selectedDate = HomeSearchFilterInterface.getDateFromString(dateStr);
        Map<String, List<String>> queryParamMap = new Map<String, List<String>>{
                        'Technician__c' => new List<String>{'=', null}
           };
        List<Event__c> appointmentList = SchedulerSOQLUtil.getAppoitmentList(queryParamMap, selectedDate);
        
        List<AppointmentWrapper> appointmentObjList = new List<AppointmentWrapper>();
        for(Event__c appointmentRec : appointmentList) {
            if(selectedDate.isSameDay(appointmentRec.Start_DateTime__c)) {
        		AppointmentWrapper appointmentObj = new AppointmentWrapper(appointmentRec, true, selectedDate);
	            if(String.isNotBlank(appointmentRec.Service_Order_Header__c)) {
	                AppointmentService.populateSOKitConcernsOnAppointment(appointmentObj, appointmentRec.Service_Order_Header__c);
	            }
	            
	            appointmentObjList.add(appointmentObj);
        	}
        }
        return appointmentObjList;
    }**/
    
    public static Map<String, List<AppointmentWrapper>> getAssignedAppointmentForSpecificDay(String dateStr, String techId) {
        DateTime selectedDate = HomeSearchFilterInterface.getDateFromString(dateStr);
        String selectedDayName = AccountSettingService.getDayNameFromDate(Date.newinstance(selectedDate.year(), selectedDate.month(), selectedDate.day()));
        List<ShopSettingWrapper> shopSettingList = AccountSettingService.getShopSettingDataForParticularDay(selectedDayName);
        ShopSettingWrapper seletedDayShopSettingRec;
        if(shopSettingList != null && shopSettingList.size() > 0) {
        	if(!shopSettingList[0].IsWorking) {
        		return new Map<String, List<AppointmentWrapper>>();
        	}
    	} else {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage('Shop setting config is not defined for ' + selectedDayName, 'Error'));
    	}
        //system.assert(false, selectedDate);
        Map<String, List<String>> queryParamMap = new Map<String, List<String>>{
                        'Event__r.CO_Header__c' => new List<String>{'<>', null}
        };
        if(techId != null) {
            queryParamMap.put('Technician__c', new List<String>{'=', techId});
        } else {
            queryParamMap.put('Technician__c', new List<String>{'<>', null});
        }
        List<Event_Scheduling__c> appointmentList = SchedulerSOQLUtil.getEventSchedulingListByQueryParam(queryParamMap, selectedDate);
        
        Map<String, List<AppointmentWrapper>> techIdToAppointmentListMap = new Map<String, List<AppointmentWrapper>>();
        for(Event_Scheduling__c appointmentRec : appointmentList) {
            if(!techIdToAppointmentListMap.containsKey(appointmentRec.Technician__c)) {
                techIdToAppointmentListMap.put(appointmentRec.Technician__c, new List<AppointmentWrapper>());
            }
            
            AppointmentWrapper appointmentObj = new AppointmentWrapper(appointmentRec, true, selectedDate);
            if(String.isNotBlank(appointmentRec.Event__r.Service_Order_Header__c)) {
                AppointmentService.populateSOKitConcernsOnAppointment(appointmentObj, appointmentRec.Event__r.Service_Order_Header__c);
            }
            /*if(String.isNotBlank(appointmentRec.Event_Concern__c)) {
                NotesService.populateNotesOnAppointment(appointmentObj, appointmentRec.Event_Concern__c);
            }*/
            techIdToAppointmentListMap.get(appointmentRec.Technician__c).add(appointmentObj);
        }
        
        for(String technicianId: techIdToAppointmentListMap.keyset()) {
        	setIsSameSOTypeAppOverlappedField(techIdToAppointmentListMap.get(technicianId));
        }
        return techIdToAppointmentListMap;
    }
    
    private static void setIsSameSOTypeAppOverlappedField(List<AppointmentWrapper> appointmentList) {
    	List<AppointmentWrapper> singleDayAppList = new List<AppointmentWrapper>();
		List<AppointmentWrapper> multiDayAppList = new List<AppointmentWrapper>();
		for(AppointmentWrapper appObj: appointmentList) {
			if(appObj.IsMultiday) {
				multiDayAppList.add(appObj);
			} else {
				singleDayAppList.add(appObj);
			}
		}
		if(multiDayAppList.size() == 0 || singleDayAppList.size() == 0) {
			return;
		} else {
			for(AppointmentWrapper singleDayAppObj: singleDayAppList) {
				Time singleDayAppStartTime = DateTimeUtility.getTimeFromString(singleDayAppObj.ActualStartTime);
				Time singleDayAppEndTime = DateTimeUtility.getTimeFromString(singleDayAppObj.ActualEndTime);
				for(AppointmentWrapper multidayAppObj: multiDayAppList) {
					Time multiDayAppStartTime = DateTimeUtility.getTimeFromString(multidayAppObj.StartTime);
					Time multiDayAppEndTime = DateTimeUtility.getTimeFromString(multidayAppObj.EndTime);
					if(singleDayAppStartTime < multiDayAppEndTime && singleDayAppEndTime > multiDayAppStartTime) {
						singleDayAppObj.IsAppointmentOverlapped = true;
						multidayAppObj.IsAppointmentOverlapped = true;
						if(singleDayAppObj.TransactionType == multidayAppObj.TransactionType) {
							singleDayAppObj.IsSameSOTypeAppointmentOverlapped = true;
						}
					}
				}
			}
		}
		appointmentList = new List<AppointmentWrapper>();
		appointmentList.addAll(singleDayAppList);
		appointmentList.addAll(multiDayAppList);
    }
    
    public static void updateAppointment(String appointmentObjStr) {
        if(!AccessControl.ifObjectFieldIsUpdateable('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        List<AppointmentWrapper> appObjList = (List<AppointmentWrapper>) system.JSON.deserialize(appointmentObjStr, List<AppointmentWrapper>.class);
        List<Event__c> eventListToUpdate = new List<Event__c>();
        for(AppointmentWrapper appObj : appObjList) {
            eventListToUpdate.add(updateAppointment(appObj));
        }
        if(eventListToUpdate.size() > 0) {
            update eventListToUpdate;
        }
    }
    
    private static Event__c updateAppointment(AppointmentWrapper appointmentObj) {
        Event__c eventRec = new Event__c(Id = appointmentObj.Id);
        eventRec.Technician__c = appointmentObj.TechnicianId;
        /*if(appointmentObj.IsMultiday) {
        	Map<String, List<String>> queryParamMap = new Map<String, List<String>>{
	                        'Technician__c' => new List<String>{'=', appointmentObj.TechnicianId}
	        };
	        List<Event> conflictedAppointmentList = SchedulerSOQLUtil.getAppoitmentList(queryParamMap, HomeSearchFilterInterface.getDateFromString(appointmentObj.ActualStartDate));
	        
	        for(Event conflictAppointmentRec : conflictedAppointmentList) {
	        	if(conflictAppointmentRec.IsMultiDayEvent__c) {
	        		throw new BlackpurlException('This multiday is conflicting with another multiday event');
	        	}
	        }
        }*/
        String result = AppointmentService.setStartEndDate(eventRec, appointmentObj, false);
        if(result != 'Success') {
        	throw new BlackPurlException(result);
        }
        
        if(String.isNotBlank(appointmentObj.StartTime)) {
            if(appointmentObj.StartTime.toLowerCase().contains('am')) {
                eventRec.Appointment_Day_Segment__c = 'Morning'; 
            } else if(appointmentObj.StartTime.toLowerCase().contains('pm')){
                eventRec.Appointment_Day_Segment__c = 'Afternoon';
            }
        }
        return eventRec;
    }
    
    public static String createCOWithServiceJob(String appointmentObjStr) {
        AppointmentWrapper appointmentObj = (AppointmentWrapper) system.JSON.deserialize(appointmentObjStr, AppointmentWrapper.class);
        String coHeaderId;
        if(appointmentObj.COId == null) {
            CO_Header__c coHeaderRec = setCOHeaderFields(appointmentObj.CustomerId, 'Customer', null);
            DMLUtility.insertSobjectList('CO_Header__c', coHeaderRec);
            coHeaderId = coHeaderRec.Id;
            Customer_Service.populateStoreTaxesOnCO(coHeaderId);
            ServiceJobService.createServiceJob(coHeaderRec.Id);
            // Set Appointment related to CO Header
            Event__c eventRec = new Event__c(Id = appointmentObj.Id, CO_Header__c = coHeaderRec.Id);
            
            List<Service_Order_Header__c> soHeaderList = [Select Id from Service_Order_Header__c where CO_Header__c =: coHeaderRec.Id];
            if(soHeaderList.size() > 0) {
                soHeaderList[0].Customer_Owned_Unit__c = appointmentObj.COUId;
                soHeaderList[0].SO_Concern__c = BPUtility.convertListIntoString(appointmentObj.Concern);
                soHeaderList[0].Transaction_Type__c = appointmentObj.TransactionTypeId;
                soHeaderList[0].Name__c = appointmentObj.Title;
                List<Transaction_Type__c> ttList = [SELECT Type__c FROM Transaction_Type__c WHERE Id =: appointmentObj.TransactionTypeId];
                if(ttList.size() > 0 && ttList[0].Type__c == 'Third-Party') {
                    soHeaderList[0].Claim_Status__c = 'Unsubmitted';
                }
                update soHeaderList[0];
                
                // Set Appointment related to SO Header
                eventRec.Service_Order_Header__c = soHeaderList[0].Id;
            }
            DMLUtility.updateSobjectList('Event__c', eventRec);
            AppointmentService.updateRelatedSORecord(eventRec.Id);
        } else {
            coHeaderId = appointmentObj.COId;
        }
        return coHeaderId;
    }
    
    private static CO_Header__c setCOHeaderFields(String customerId, String coType, String sellingGroup) {
        CO_Header__c coHeaderRec = new CO_Header__c();
        coHeaderRec.Order_status__c = 'Open';
        coHeaderRec.Owner__c = UserInfo.getUserId();
        coHeaderRec.Selling_Group__c = sellingGroup;
        coHeaderRec.CO_Type__c = coType;
        coHeaderRec.Customer__c = customerId;
        coHeaderRec.Hide_Merchandise_Section__c = true;
        return coHeaderRec;
    }
    
    public static void updateSchedulings(String appointmentObjStr) {
        List<AppointmentWrapper> appObjList = (List<AppointmentWrapper>) system.JSON.deserialize(appointmentObjStr, List<AppointmentWrapper>.class);
        List<Event_Scheduling__c> schedulingUpsertList = new List<Event_Scheduling__c>();
        for(AppointmentWrapper schedulingObj : appObjList) {
            schedulingUpsertList.add(setSchedulingRec(schedulingObj));
        }
        if(schedulingUpsertList.size() > 0) {
            DMLUtility.upsertSobjectList('Event_Scheduling__c', schedulingUpsertList);
        }
    }
    
    private static Event_Scheduling__c setSchedulingRec(AppointmentWrapper schedulingObj) {
    	Event_Scheduling__c schedulingRec = new Event_Scheduling__c(Id = schedulingObj.Id);
        String result = EventSchedulingService.setStartEndDate(null, schedulingRec, schedulingObj.StartDate, schedulingObj.StartTime, 
        								schedulingObj.EstimatedHours, schedulingObj.IsMultiday, false);
        								
        if(!result.equalsIgnoreCase('Success')) {
            throw new BlackpurlException(result);
        }
        schedulingRec.Event__c = schedulingObj.EventId;
        schedulingRec.Technician__c = schedulingObj.TechnicianId;
        schedulingRec.Hours__c = schedulingObj.EstimatedHours;
        return schedulingRec;
    }
}