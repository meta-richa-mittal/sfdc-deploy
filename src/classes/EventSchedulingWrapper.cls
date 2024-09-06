/** 
* Author: Nidhi Sharma
* Since: Feb 25, 2020 
* Name: EventSchedulingWrapper
* Description: Apex class which contains all Event scheduling Data Wrapper
**/
public without sharing class EventSchedulingWrapper {
	public String Id;
	public String EventId;
	public String TechnicianId;
	public String TechnicianName;
	public String TechNameInitials;
	public Decimal Hours;
	public String ActualStartDate;
	public String ActualStartTime;
	public String FormattedEndDateTime;
    public String FormattedStartDateTime;
	public Boolean IsMultiday;
	
	public String EventStartDate;//To show updated event start date time
    public String EventStartSegment;//To show updated event start date time
    public String EventStartTime;//To show updated event start date time
    
	//Day View Fields
	public String StartDate;
    public String StartTime;
    
    public Boolean IsSelectedDayIsStartDay;
    public Boolean IsSelectedDayIsEndDay;
    public Boolean IsSameSOTypeAppointmentOverlapped;
    public Boolean IsAppointmentOverlapped;
    public Boolean IsConflictExists;
    public Boolean IsInProcess;
    public Boolean IsMultipleScheduling;
	
    public EventSchedulingWrapper(Event_Scheduling__c eventSchedulingRec){
    	setBasicFields(eventSchedulingRec);
    }
    
	public EventSchedulingWrapper(Event_Scheduling__c eventSchedulingRec, DateTime selectedDateTime, ShopSettingWrapper seletedDayShopSettingRec) {
		setBasicFields(eventSchedulingRec);
		setDayViewFields(eventSchedulingRec, selectedDateTime, seletedDayShopSettingRec);
	}
    
    private void setBasicFields(Event_Scheduling__c eventSchedulingRec) {
    	this.Id = eventSchedulingRec.Id;
		this.EventId = eventSchedulingRec.Event__c;
		this.TechnicianId = eventSchedulingRec.Technician__c;
		
		if(String.isNotBlank(eventSchedulingRec.Id) && String.isNotBlank(eventSchedulingRec.Technician__c)) {
			this.TechnicianName = eventSchedulingRec.Technician__r.Technician_Name__c;
			
			eventSchedulingRec.Technician__r.First_Name__c = String.isNotBlank(eventSchedulingRec.Technician__r.First_Name__c) ? eventSchedulingRec.Technician__r.First_Name__c : '';
			eventSchedulingRec.Technician__r.Last_Name__c = String.isNotBlank(eventSchedulingRec.Technician__r.Last_Name__c) ? eventSchedulingRec.Technician__r.Last_Name__c : '';
			
			this.TechNameInitials = ((eventSchedulingRec.Technician__r.First_Name__c.length() > 0) ? eventSchedulingRec.Technician__r.First_Name__c.subString(0, 1) : '') +
	                            ((eventSchedulingRec.Technician__r.Last_Name__c.length() > 0) ? eventSchedulingRec.Technician__r.Last_Name__c.subString(0, 1) : '');
		}
		this.Hours = eventSchedulingRec.Hours__c;
		this.IsMultiday = EventSchedulingService.isMultiDayScheduling(eventSchedulingRec);
		
		if(eventSchedulingRec.Event__r.Start_DateTime__c != null) {
            this.EventStartDate = (eventSchedulingRec.Event__r.Start_DateTime__c != null) ? BPUtility.getFormatedDateTime(eventSchedulingRec.Event__r.Start_DateTime__c) : null;
	        this.EventStartTime = (eventSchedulingRec.Event__r.Start_DateTime__c != null) ? eventSchedulingRec.Event__r.Start_DateTime__c.format('h:mma') : null;
        	if(this.EventStartTime.toLowerCase().contains('am')) {
                this.EventStartSegment = 'Morning'; 
            } else if(this.EventStartTime.toLowerCase().contains('pm')){
                this.EventStartSegment = 'Afternoon';
            }
        }
        
		if(eventSchedulingRec.Start_Date_Time__c != null) {
            this.ActualStartDate = (eventSchedulingRec.Start_Date_Time__c != null) ? BPUtility.getFormatedDateTime(eventSchedulingRec.Start_Date_Time__c) : null;
	        this.ActualStartTime = (eventSchedulingRec.Start_Date_Time__c != null) ? eventSchedulingRec.Start_Date_Time__c.format('h:mma') : null;
            this.FormattedStartDateTime = (eventSchedulingRec.Start_Date_Time__c != null) ? BPUtility.getFormatedDateAndTime(eventSchedulingRec.Start_Date_Time__c) : null;
        }
        if(eventSchedulingRec.End_Date_Time__c != null) {
            this.FormattedEndDateTime = (eventSchedulingRec.End_Date_Time__c != null) ? BPUtility.getFormatedDateAndTime(eventSchedulingRec.End_Date_Time__c) : null;
        }      
    }
    
    private void setDayViewFields(Event_Scheduling__c eventSchedulingRec, DateTime selectedDateTime, ShopSettingWrapper seletedDayShopSettingRec) {
    	this.IsMultipleScheduling = eventSchedulingRec.Event__r.Event_Scheduling_Count__c > 1;
    	this.IsSelectedDayIsStartDay = selectedDateTime.isSameDay(eventSchedulingRec.Start_Date_Time__c);
        this.IsSelectedDayIsEndDay = selectedDateTime.isSameDay(eventSchedulingRec.End_Date_Time__c);
        
		this.StartDate = (eventSchedulingRec.Start_Date_Time__c != null) ? (this.IsSelectedDayIsStartDay ? 
                        BPUtility.getFormatedDateTime(eventSchedulingRec.Start_Date_Time__c) : BPUtility.getFormatedDateTime(selectedDateTime)) : null;
        this.StartTime = (eventSchedulingRec.Start_Date_Time__c != null) ? (this.IsSelectedDayIsStartDay ? 
                            eventSchedulingRec.Start_Date_Time__c.format('h:mma') : seletedDayShopSettingRec.FromTime) : null;
    }
    
    public static List<String> getFieldList() {
       return new List<String>{'Id', 
       							'Event__c',
       							'Event__r.Is_MultiDay__c',
                                'Event__r.Event_Scheduling_Count__c',
                                'Hours__c',
                                'Start_Date_Time__c',
                                'End_Date_Time__c',
                                'Technician__c', 
                                'Technician__r.Technician_Name__c',
                                'Technician__r.First_Name__c',
                                'Technician__r.Last_Name__c',
                                'Event__r.Id',
                                'Event__r.Transaction_Type__r.Type__c',
                                'Event__r.Customer__r.Name',
                                'Event__r.CO_Header__c',
                                'Event__r.CO_Header__r.Name',
                                'Event__r.Customer_Owned_Unit__r.Formatted_Name__c',
                                'Event__r.Name__c',
                                'Event__r.Appointment_Concern__c',
                                'Event__r.Due_In_Time__c',
                                'Event__r.Due_In_DateTime__c',
                                'Event__r.Promised_By_Time__c',
                                'Event__r.Promised_By_DateTime__c',
                                'Event__r.Unit_Arrived__c',
                                'Event__r.Service_Order_Header__c',
                                'Event__r.Service_Order_Header__r.Work_Status__c',
                                'Event__r.Unit_Location__c',
                                'Event__r.Transaction_Type__r.Code_Label__c',
                                'Event__r.Appointment_Day_Segment__c',
                                'Event__r.Transaction_Type__c',
                                'Event__r.Estimated_Hours__c', 
                                'Event__r.Start_DateTime__c',
                                'Event__r.End_DateTime__c', 
                                'Event__r.Customer_Owned_Unit__c',
                                'Event__r.Customer__c'
                            };
    }
}