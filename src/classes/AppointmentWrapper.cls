/** 
* Author: Rajat Jain <rajat.jain@metacube.com>
* Since: May 17, 2018 
* Name: AppointmentWrapper
* Description: Apex class which contains all Appointment Data Wrapper
**/
public without sharing class AppointmentWrapper {
    public String Id;
    public String CustomerId;
    public String COUId;
    public List<String> Concern;
    public List<String> SOKitConcern;
    public Decimal EstimatedHours;
    public String TransactionTypeLabel;
    public String TransactionTypeId;
    public String TransactionType;
    public String Title;
    
    public Boolean isConflictExists;
    public String EventId;
    
    public String StartDate;
    public String EndDate;
    public String StartTime;
    public String EndTime;
    public String FormattedStartDate;
    
    public String ActualStartDate;
    public String ActualEndDate;
    public String ActualStartTime;
    public String ActualEndTime;
    
    public String DueInTime;
    public String DueInDate;
    public String PromiseByTime;
    public String PromisedByDate;
    public Boolean IsUnitArrived;
    public String UnitLocation;

    public Boolean IsMultiday;
    public Boolean IsSelectedDayIsStartDay;
    public Boolean IsSelectedDayIsEndDay;
    public Boolean IsSameSOTypeAppointmentOverlapped;
    public Boolean IsAppointmentOverlapped;
    
    public String CustomerName;
    public String COId;
    public String CONumber;
    public String UnitFormattedName;
    public String AppointmentDaySegment;
    public String TechnicianId;
    public String TechnicianName;
    public String SOHeaderId;
    public Boolean IsWorkLate;
    public String ServiceJobStatus;
    public Boolean IsMultiTechnicianAssigned;
    public Decimal AppointmentEstimatedHours;
    
	public List<EventSchedulingWrapper> EventSchedulingList;
    
    public AppointmentWrapper(Event__c eventRec) {
    	this.Id = eventRec.Id;
        populateDefaultFields(eventRec);
    }
    
    public AppointmentWrapper(Event__c eventRec, Boolean needUnitDetail) {
    	this.Id = this.EventId = eventRec.Id;
        populateDefaultFields(eventRec);
        populateOtherFields(eventRec);
        populateEventScheduling(eventRec.Event_Schedulings__r);
        populateDateTimeFields(eventRec);
        if(eventRec.Technician__c != null) {
            this.TechnicianId = (eventRec.Technician__c != null) ? eventRec.Technician__c : null;
            this.TechnicianName = (eventRec.Technician__c != null) ? eventRec.Technician__r.Technician_Name__c : null;
        } else if(IsMultiTechnicianAssigned) {
            this.TechnicianName = 'Multiple technicians';
        }
    }
    
    public AppointmentWrapper(Event__c eventRec, Boolean needUnitDetail, DateTime selectedDateTime) {
    	this.Id = this.EventId = eventRec.Id;
        populateDefaultFields(eventRec);
        populateOtherFields(eventRec);
        populateDateTimeFields(eventRec);
        if(eventRec.Technician__c != null) {
            this.TechnicianId = (eventRec.Technician__c != null) ? eventRec.Technician__c : null;
            this.TechnicianName = (eventRec.Technician__c != null) ? eventRec.Technician__r.Technician_Name__c : null;
        } else if(IsMultiTechnicianAssigned) {
            this.TechnicianName = 'Multiple technicians';
        }
        
        ShopSettingWrapper seletedDayShopSettingRec;
        this.IsSelectedDayIsStartDay = selectedDateTime.isSameDay(eventRec.Start_DateTime__c);
        //system.assert(eventRec.Id != '00U2M00000NmRNz', selectedDateTime + '\n' + eventRec.StartDateTime + 'isSameDay' + '\n' + selectedDateTime.isSameDay(eventRec.StartDateTime));
        this.IsSelectedDayIsEndDay = selectedDateTime.isSameDay(eventRec.End_DateTime__c);
        
        if(!this.IsSelectedDayIsStartDay || !this.IsSelectedDayIsEndDay) {
            String selectedDayName = AccountSettingService.getDayNameFromDate(Date.newinstance(selectedDateTime.year(), selectedDateTime.month(), selectedDateTime.day()));
            List<ShopSettingWrapper> shopSettingList = AccountSettingService.getShopSettingDataForParticularDay(selectedDayName);
            if(shopSettingList.size() > 0) {
                seletedDayShopSettingRec = shopSettingList[0];
            } else {
                throw new BlackPurlException(BlackPurlException.getErrorMessage('Shop setting config is not defined for ' + selectedDayName, 'Error'));
            }
        }
        
        this.StartDate = (eventRec.Start_DateTime__c != null) ? (this.IsSelectedDayIsStartDay ? 
                            BPUtility.getFormatedDateTime(eventRec.Start_DateTime__c) : BPUtility.getFormatedDateTime(selectedDateTime)) : null;
        this.EndDate = (eventRec.End_DateTime__c != null) ? (this.IsSelectedDayIsEndDay ? 
                            BPUtility.getFormatedDateTime(eventRec.End_DateTime__c) : BPUtility.getFormatedDateTime(selectedDateTime)) : null;
        this.StartTime = (eventRec.Start_DateTime__c != null) ? (this.IsSelectedDayIsStartDay ? 
                            eventRec.Start_DateTime__c.format('h:mma') : seletedDayShopSettingRec.FromTime) : null;
        this.EndTime = (eventRec.End_DateTime__c != null) ? (this.IsSelectedDayIsEndDay ? 
                            eventRec.End_DateTime__c.format('h:mma') : seletedDayShopSettingRec.ToTime) : null;
                            
        this.IsSameSOTypeAppointmentOverlapped = this.IsSameSOTypeAppointmentOverlapped != null ? this.IsSameSOTypeAppointmentOverlapped : false;
        this.IsAppointmentOverlapped = this.IsAppointmentOverlapped != null ? this.IsAppointmentOverlapped : false;
    }
    
    public AppointmentWrapper(Event_Scheduling__c schedulingRec, Boolean needUnitDetail, DateTime selectedDateTime) {
    	this.Id = schedulingRec.Id;
    	this.EventId = schedulingRec.Event__c;
        populateDefaultFields(schedulingRec.Event__r);
        populateOtherFields(schedulingRec.Event__r);
        populateDateTimeFields(schedulingRec);
        if(schedulingRec.Technician__c != null) {
            this.TechnicianId = (schedulingRec.Technician__c != null) ? schedulingRec.Technician__c : null;
            this.TechnicianName = (schedulingRec.Technician__c != null) ? schedulingRec.Technician__r.Technician_Name__c : null;
        } else if(IsMultiTechnicianAssigned) {
            this.TechnicianName = 'Multiple technicians';
        }
        
        ShopSettingWrapper seletedDayShopSettingRec;
        this.IsSelectedDayIsStartDay = selectedDateTime.isSameDay(schedulingRec.Start_Date_Time__c);
        //system.assert(schedulingRec.Id != '00U2M00000NmRNz', selectedDateTime + '\n' + schedulingRec.StartDateTime + 'isSameDay' + '\n' + selectedDateTime.isSameDay(schedulingRec.StartDateTime));
        this.IsSelectedDayIsEndDay = selectedDateTime.isSameDay(schedulingRec.End_Date_Time__c);
        
        if(!this.IsSelectedDayIsStartDay || !this.IsSelectedDayIsEndDay) {
            String selectedDayName = AccountSettingService.getDayNameFromDate(Date.newinstance(selectedDateTime.year(), selectedDateTime.month(), selectedDateTime.day()));
            List<ShopSettingWrapper> shopSettingList = AccountSettingService.getShopSettingDataForParticularDay(selectedDayName);
            if(shopSettingList.size() > 0) {
                seletedDayShopSettingRec = shopSettingList[0];
            } else {
                throw new BlackPurlException(BlackPurlException.getErrorMessage('Shop setting config is not defined for ' + selectedDayName, 'Error'));
            }
        }
        
        this.StartDate = (schedulingRec.Start_Date_Time__c != null) ? (this.IsSelectedDayIsStartDay ? 
                            BPUtility.getFormatedDateTime(schedulingRec.Start_Date_Time__c) : BPUtility.getFormatedDateTime(selectedDateTime)) : null;
        this.EndDate = (schedulingRec.End_Date_Time__c != null) ? (this.IsSelectedDayIsEndDay ? 
                            BPUtility.getFormatedDateTime(schedulingRec.End_Date_Time__c) : BPUtility.getFormatedDateTime(selectedDateTime)) : null;
        this.StartTime = (schedulingRec.Start_Date_Time__c != null) ? (this.IsSelectedDayIsStartDay ? 
                            schedulingRec.Start_Date_Time__c.format('h:mma') : seletedDayShopSettingRec.FromTime) : null;
        this.EndTime = (schedulingRec.End_Date_Time__c != null) ? (this.IsSelectedDayIsEndDay ? 
                            schedulingRec.End_Date_Time__c.format('h:mma') : seletedDayShopSettingRec.ToTime) : null;
                            
        this.IsSameSOTypeAppointmentOverlapped = this.IsSameSOTypeAppointmentOverlapped != null ? this.IsSameSOTypeAppointmentOverlapped : false;
        this.IsAppointmentOverlapped = this.IsAppointmentOverlapped != null ? this.IsAppointmentOverlapped : false;
    }
    
    private void populateDefaultFields(Event__c eventRec) {
    	this.CustomerId = eventRec.Customer__c;
        this.Concern = (eventRec.Appointment_Concern__c != null) ? eventRec.Appointment_Concern__c.split('\n') : new List<String>();
        this.SOKitConcern = new List<String>();
        this.COUId = eventRec.Customer_Owned_Unit__c;
        this.TransactionTypeLabel = eventRec.Transaction_Type__r.Code_Label__c;
        this.TransactionTypeId = eventRec.Transaction_Type__c;
        this.TransactionType = eventRec.Transaction_Type__r.Type__c;
        this.Title = eventRec.Name__c;
        //this.IsWorkLate = eventRec.Is_Work_Late__c;
        this.IsMultiday = eventRec.Is_MultiDay__c;

        this.DueInTime = (String.isNotBlank(eventRec.Due_In_Time__c) && eventRec.Due_In_DateTime__c != null) ? 
        				eventRec.Due_In_DateTime__c.format('h:mm a') : '';
        this.PromiseByTime = (String.isNotBlank(eventRec.Promised_By_Time__c) && eventRec.Promised_By_DateTime__c != null) ? 
        				eventRec.Promised_By_DateTime__c.format('h:mm a') : '';
        				
        this.DueInDate = eventRec.Due_In_DateTime__c != null ?
            eventRec.Due_In_DateTime__c.format(Constants.localeToDateTimeFmtMap.get(UserInfo.getLocale())) : '';
        this.PromisedByDate = eventRec.Promised_By_DateTime__c != null ?
            eventRec.Promised_By_DateTime__c.format(Constants.localeToDateTimeFmtMap.get(UserInfo.getLocale())) : '';
        this.IsUnitArrived = eventRec.Unit_Arrived__c != null ? eventRec.Unit_Arrived__c : false;
        this.UnitLocation = eventRec.Unit_Location__c != null ? eventRec.Unit_Location__c : '';
        this.IsMultiTechnicianAssigned = eventRec.Event_Scheduling_Count__c > 1 ? true : false;
    }
    
    private void populateOtherFields(Event__c eventRec) {
        this.CustomerName = (eventRec.Customer__r.Name != null) ? eventRec.Customer__r.Name : null;
        this.UnitFormattedName = eventRec.Customer_Owned_Unit__r.Formatted_Name__c;
        this.AppointmentDaySegment = eventRec.Appointment_Day_Segment__c;
        this.CONumber = (eventRec.CO_Header__r.Name != null) ? eventRec.CO_Header__r.Name : null;
        this.COId = (eventRec.CO_Header__c != null) ? eventRec.CO_Header__c : null;
        this.SOHeaderId = (eventRec.Service_Order_Header__c != null) ? eventRec.Service_Order_Header__c : null;
        this.ServiceJobStatus = (eventRec.Service_Order_Header__c != null) ? eventRec.Service_Order_Header__r.Work_Status__c : null;
    }

    private void populateDateTimeFields(Event__c eventRec) {
        this.AppointmentEstimatedHours = eventRec.Estimated_Hours__c;
        this.EstimatedHours= eventRec.Estimated_Hours__c;
        this.ActualStartDate = (eventRec.Start_DateTime__c != null) ? BPUtility.getFormatedDateTime(eventRec.Start_DateTime__c) : null;
        this.ActualEndDate = (eventRec.End_DateTime__c != null) ? BPUtility.getFormatedDateTime(eventRec.End_DateTime__c) : null;
        this.ActualStartTime = (eventRec.Start_DateTime__c != null) ? eventRec.Start_DateTime__c.format('h:mma') : null;
        this.ActualEndTime = (eventRec.End_DateTime__c != null) ? eventRec.End_DateTime__c.format('h:mma') : null;
        this.FormattedStartDate = null;
        if(eventRec.Start_DateTime__c != null) {
            this.FormattedStartDate = eventRec.Start_DateTime__c.format('MMMM dd, yyyy');
        }
    }

    private void populateDateTimeFields(Event_Scheduling__c schedulingRec) {
    	this.EventId = schedulingRec.Event__c;
        this.EstimatedHours= schedulingRec.Hours__c;
        this.AppointmentEstimatedHours = schedulingRec.Event__r.Estimated_Hours__c;
        this.ActualStartDate = (schedulingRec.Start_Date_Time__c != null) ? BPUtility.getFormatedDateTime(schedulingRec.Start_Date_Time__c) : null;
        this.ActualEndDate = (schedulingRec.End_Date_Time__c != null) ? BPUtility.getFormatedDateTime(schedulingRec.End_Date_Time__c) : null;
        this.ActualStartTime = (schedulingRec.Start_Date_Time__c != null) ? schedulingRec.Start_Date_Time__c.format('h:mma') : null;
        this.ActualEndTime = (schedulingRec.End_Date_Time__c != null) ? schedulingRec.End_Date_Time__c.format('h:mma') : null;
        this.FormattedStartDate = null;
        if(schedulingRec.Start_Date_Time__c != null) {
            this.FormattedStartDate = schedulingRec.Start_Date_Time__c.format('MMMM dd, yyyy');
        }
    }

    private void populateEventScheduling(List<Event_Scheduling__c> eventSchedulingList) {
    	this.EventSchedulingList = new List<EventSchedulingWrapper>();
    	for(Event_Scheduling__c schedulingRec : eventSchedulingList) {
    		this.EventSchedulingList.add(new EventSchedulingWrapper(schedulingRec));
        }
    }

    public static List<String> getAppointmentFieldsList() {
       return new List<String>{'Technician__c', 
       							'Technician__r.Technician_Name__c',
                                'Name__c', 
                                'Appointment_Day_Segment__c',
                                'Transaction_Type__c',
                                'Transaction_Type__r.Code_Label__c',
                                'Transaction_Type__r.Type__c',
                                'Estimated_Hours__c', 
                                'Start_DateTime__c',
                                'End_DateTime__c', 
                                'Customer_Owned_Unit__c',
                                'Customer__c',
                                'CO_Header__c',
                                'CO_Header__r.Name',
                                'Appointment_Concern__c',
                                'Customer__r.Name',
                                'Customer_Owned_Unit__r.Formatted_Name__c',
                                'Service_Order_Header__c',
                                //'Is_Work_Late__c',
                                'Is_MultiDay__c',
                                'Promised_By_Time__c',
                                'Due_In_Time__c',
                                'Promised_By_DateTime__c',
                                'Due_In_DateTime__c',
                                'Unit_Arrived__c',
                                'Service_Order_Header__r.Work_Status__c',
                                'Unit_Location__c',
                                'Event_Scheduling_Count__c'
                            };
    }
}