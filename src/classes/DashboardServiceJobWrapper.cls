/**
* Author: Manoj Sharma
* Since: May 13, 2020
* Name: DashboardServiceJobWrapper
* Description: Apex class to create wrapper of Service Order
**/
global without sharing class DashboardServiceJobWrapper {
    public String COHeaderId;
    public String CustomerName;
    public String CONumberSOName;
    public String JobType;
    public Decimal EstimateHours;
    public Decimal ClockedHours;
    public Decimal TodayHours;
    public Decimal ProgressPercent;
    public String RemainingTime;
    public Boolean IsTechnicianClocked;

    public DashboardServiceJobWrapper(Service_Order_Header__c soHeaderObj, Map<Id, List<Event__c>> soHeaderIdToEventListMap, Map<Id, List<Hours_Logged__c>> soHeaderIdToHoursLogListMap) {
        this.COHeaderId = soHeaderObj.CO_Header__c;
        this.IsTechnicianClocked = false;
        Decimal appointmentEstimate = 0;
        this.ClockedHours = 0;
        this.TodayHours = 0;
        this.CustomerName = soHeaderObj.CO_Header__r.Customer_Name__c;
        this.CONumberSOName = soHeaderObj.CO_Header__r.Name + ' ' + soHeaderObj.Name__c;
        this.JobType = soHeaderObj.Job_Type__c != null ? soHeaderObj.Job_Type__c : '';
        if(soHeaderIdToEventListMap.containsKey(soHeaderObj.Id)){
            for(Event__c eventRec : soHeaderIdToEventListMap.get(soHeaderObj.Id)) {
                appointmentEstimate += eventRec.Estimated_Hours__c != null ? eventRec.Estimated_Hours__c : 0;
            }
        }
        if(soHeaderIdToHoursLogListMap.containsKey(soHeaderObj.Id)){
            for(Hours_Logged__c hoursLogRec : soHeaderIdToHoursLogListMap.get(soHeaderObj.Id)) {
                this.ClockedHours += hoursLogRec.Calculated_Hours__c != null ? hoursLogRec.Calculated_Hours__c : 0;
                if(hoursLogRec.Start_Date_Time__c != null && date.newinstance(hoursLogRec.Start_Date_Time__c.year(), hoursLogRec.Start_Date_Time__c.month(), hoursLogRec.Start_Date_Time__c.day()) == date.newinstance(System.now().year(), System.now().month(), System.now().day())) {
                    this.TodayHours += hoursLogRec.Calculated_Hours__c != null ? hoursLogRec.Calculated_Hours__c : 0;
                }
                if(!this.IsTechnicianClocked) {
                    this.IsTechnicianClocked = (hoursLogRec.Start_Date_Time__c != null && hoursLogRec.End_Date_Time__c == null) ? true : false;
                }
            }
        }

        this.EstimateHours = appointmentEstimate > (soHeaderObj.Hrs_Billed__c != null ? soHeaderObj.Hrs_Billed__c : 0)? appointmentEstimate : soHeaderObj.Hrs_Billed__c;
        if(this.EstimateHours == 0 && this.ClockedHours == 0) {
            this.ProgressPercent = 0.0;
        } else if (this.EstimateHours == 0) {
            this.ProgressPercent = 100.0;
        } else {
            this.ProgressPercent = ((this.ClockedHours / this.EstimateHours) * 100) > 9999.9 ? 9999.9 : ((this.ClockedHours / this.EstimateHours) * 100).setScale(1, System.RoundingMode.UP);
        } 
        Integer remainingHr = 0;
        Integer remainingMin = 0;
        if(this.ClockedHours == 0) {
            this.RemainingTime = 'not started';
        } else if (this.ClockedHours < this.EstimateHours) {
            remainingHr = (((this.EstimateHours - this.ClockedHours)*60).intValue()) / 60 ;
            remainingMin = math.mod((((this.EstimateHours - this.ClockedHours)*60).intValue()),60 );
            this.RemainingTime = String.valueOf(remainingHr) + 'hr ' + String.valueOf(remainingMin) + 'm remaining';
        } else if(this.ClockedHours == this.EstimateHours) {
            this.RemainingTime = 'no time remaining' ;
        } else {
            remainingHr = (((this.ClockedHours - this.EstimateHours)*60).intValue()) / 60 ;
            remainingMin = math.mod((((this.ClockedHours - this.EstimateHours)*60).intValue()), 60) ;
            this.RemainingTime = String.valueOf(remainingHr) + 'hr ' + String.valueOf(remainingMin) + 'm excess time';
        }
        this.ClockedHours = this.ClockedHours.setScale(1, System.RoundingMode.UP);
        this.EstimateHours = this.EstimateHours.setScale(1, System.RoundingMode.UP);
        this.TodayHours = this.TodayHours.setScale(1, System.RoundingMode.UP);
    }

    public static List<String> getSOHeaderFieldsList(){
        return new List<String>{ 'Name__c',
                                 'CO_Header__c',
                                 'CO_Header__r.Name',
                                 'CO_Header__r.Customer_Name__c',
                                 'Job_Type__c',
                                 'Hrs_Billed__c',
                                 'Hrs_Logged__c',
                                 'Estimated_Hours__c',
                                 'SO_Status__c',
                                 'CreatedDate'
                                };
    }

    public static List<String> getEventFieldsList(){
        return new List<String> { 'Service_Order_Header__c',
                                  'Estimated_Hours__c'
                                };
    }

    public static List<String> getHoursLogFieldsList(){
        return new List<String>{ 'Service_Order_Header__c',
                                 'Calculated_Hours__c',
                                 'Start_Date_Time__c',
                                 'End_Date_Time__c'
                                };
    }

    /**
    * Name: FilterWrapper
    * Description: Apex class to create wrapper of filters
    **/
    public class FilterWrapper {
        public String StatusFilter;
        public List<String> JobTypeFilterList;
    }

    public class JobTypeWrapper {
        public Integer Id;
        public String Name;
        public boolean isSelected;

        public JobTypeWrapper(Integer id, String jobType, boolean isSelected) {
            this.Id = id;
            this.Name = jobType;
            this.isSelected = isSelected;
        }
    }
}