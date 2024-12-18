/**
 * Author: Richa Mittal
 * Since: Oct 16, 2017 
 * Name: JobClockingWrapper
 * Description: Used to handle all JSON related work related to Job Clocking
**/
public without sharing class JobClockingWrapper implements Comparable {
    public String Id;
    public String ServiceJobStatus;
    public String ServiceJobStatusRefId;
    public String COName;
    public String COHeaderId;
    public String ServiceJobType;
    public String UnitName;
    public String CustomerName;
    public List<TechnicianInfo> TechnicianList;
    public Boolean IsServiceJobClocked;
    public Boolean IsServiceJobPaused;
    public String CurrentlyClocked;
    public Integer CurrentlyClockedDays;
    public Integer CurrentlyClockedHours;
    public Integer CurrentlyClockedMinutes;
    public String TimeSpent;
    public Integer TimeSpentDays;
    public Integer TimeSpentHours;
    public Integer TimeSpentMinutes;
    public DateTime COCreatedDate;
    public String ServiceJobName;
    public String ConcernList{get; set;}
    
    public String TechnicianViewTechId;
    
    public JobClockingWrapper(Service_Order_Header__c serviceJobRec, Id techicianId) {
        this.Id = serviceJobRec.Id;
        this.ServiceJobStatus = serviceJobRec.SO_Status__c;
        this.ServiceJobStatusRefId = serviceJobRec.SO_Status_Ref__c;
        this.ServiceJobName = serviceJobRec.Name__c;
        this.COName = serviceJobRec.CO_Header__r.Name;
        this.COHeaderId = serviceJobRec.CO_Header__c;
        this.ConcernList = (serviceJobRec.SO_Concern__c != null) ? serviceJobRec.SO_Concern__c.replaceAll('\n', ', ') : '';
        this.ServiceJobType = serviceJobRec.Transaction_Type__r.Code_Label__c;
        String vinNumber = String.isNotBlank(serviceJobRec.Customer_Owned_Unit__r.VIN_Number__c) ? serviceJobRec.Customer_Owned_Unit__r.VIN_Number__c : 'VIN Unknown';
        this.UnitName = serviceJobRec.Customer_Owned_Unit__r.Formatted_Name__c + ', ' + vinNumber;
        this.CustomerName = serviceJobRec.CO_Header__r.Customer_Name__c;
        
        this.TimeSpentDays = 0;
        this.TimeSpentHours = 0;
        this.TimeSpentMinutes = 0;
        
        Map<Id, List<Hours_Logged__c>> technicianIdtoHoursLoggedMap = new Map<Id, List<Hours_Logged__c>>();
        for(Hours_Logged__c hoursLogged: serviceJobRec.Hours_Logged__r) {
            this.TimeSpentDays += hoursLogged.Time_Spent_d__c != null ? hoursLogged.Time_Spent_d__c.intValue() : 0;
            this.TimeSpentHours += hoursLogged.Time_Spent_h__c!= null ? hoursLogged.Time_Spent_h__c.intValue() : 0;
            this.TimeSpentMinutes += hoursLogged.Time_Spent_m__c!= null ? hoursLogged.Time_Spent_m__c.intValue() : 0;
            
            if(hoursLogged.Technician__c != null) {
                if(!technicianIdtoHoursLoggedMap.containsKey(hoursLogged.Technician__c)) {
                    List<Hours_Logged__c> hoursLoggedList = new List<Hours_Logged__c>();
                    hoursLoggedList.add(hoursLogged);
                    technicianIdtoHoursLoggedMap.put(hoursLogged.Technician__c, hoursLoggedList);
                } else {
                    technicianIdtoHoursLoggedMap.get(hoursLogged.Technician__c).add(hoursLogged);
                }
            }
        }
        
        Long TotalTimeSpentMinutes = this.TimeSpentMinutes + (this.TimeSpentHours*60) + (this.TimeSpentDays*24*60);
        Long spentHours = TotalTimeSpentMinutes / 60;
        Long spentDdays = spentHours / 24;
        this.TimeSpentDays = 0;
        this.TimeSpentHours = spentHours.intValue();
        this.TimeSpentMinutes = (math.mod(TotalTimeSpentMinutes, 60)).intValue();
        
        this.TechnicianList = new List<TechnicianInfo>();
        for(Id techId: technicianIdtoHoursLoggedMap.keySet()) {
            for(Hours_Logged__c hrsLogged: technicianIdtoHoursLoggedMap.get(techId)) {
                if(hrsLogged.Technician__r.Active__c && !hrsLogged.Is_Removed__c) {
                    this.TechnicianList.add(new TechnicianInfo(technicianIdtoHoursLoggedMap.get(techId)));
                }
                break;
            }
        }
        
        this.IsServiceJobClocked = false;
        this.CurrentlyClockedDays = 0;
        this.CurrentlyClockedHours = 0;
        this.CurrentlyClockedMinutes = 0;
        
        DateTime currentDateTime = System.now();
        for(TechnicianInfo tech: this.TechnicianList) {
            if(tech.IsClocked) {
                DateTime startDateTime = tech.StartTime;
                
                Long dt1Long = startDateTime.getTime();
                Long dt2Long = currentDateTime.getTime();
                Long currentMilliseconds = dt2Long - dt1Long;
                Long currentSeconds = currentMilliseconds / 1000;
                Long currentMinutes = (currentSeconds / 60);
                Long currentHours = currentMinutes / 60;
                Long currentDays = currentHours / 24;
                    
                if(techicianId == null || (techicianId != null && tech.TechnicianId == techicianId)) {
                    this.IsServiceJobClocked = true;
                    this.CurrentlyClockedHours += currentHours.intValue();
                    this.CurrentlyClockedMinutes += (math.mod(currentMinutes, 60)).intValue();
                    
                }
                this.TimeSpentHours += currentHours.intValue();
                this.TimeSpentMinutes += (math.mod(currentMinutes, 60)).intValue();
            }
            if(tech.IsPaused && (techicianId == null || (techicianId != null && tech.TechnicianId == techicianId))) {
                this.IsServiceJobPaused = true;
            }
        }
        
        this.CurrentlyClocked = (String.valueOf(this.CurrentlyClockedHours).length() < 2 ? '0' + String.valueOf(this.CurrentlyClockedHours) + 'h' : String.valueOf(this.CurrentlyClockedHours) + 'h') + (String.valueOf(this.CurrentlyClockedMinutes).length() < 2 ? '0' + String.valueOf(this.CurrentlyClockedMinutes) + 'min' : String.valueOf(this.CurrentlyClockedMinutes) + 'min');
        
        Long TotalPlusCurrentMinutes = this.TimeSpentMinutes + (this.TimeSpentHours*60) + (this.TimeSpentDays*24*60);
        
        Long spentHoursTotalPlusCurrent = TotalPlusCurrentMinutes / 60;
        Long spentDdaysTotalPlusCurrent = spentHoursTotalPlusCurrent / 24;
        this.TimeSpentHours = spentHoursTotalPlusCurrent.intValue();
        this.TimeSpentMinutes = (math.mod(TotalPlusCurrentMinutes, 60)).intValue();
        
        this.TimeSpent = (String.valueOf(this.TimeSpentHours).length() < 2 ? '0' + String.valueOf(this.TimeSpentHours) + 'h' : String.valueOf(this.TimeSpentHours) + 'h') + (String.valueOf(this.TimeSpentMinutes).length() < 2 ? '0' + String.valueOf(this.TimeSpentMinutes) + 'min' : String.valueOf(this.TimeSpentMinutes) + 'min');
        
        this.TechnicianViewTechId = techicianId;
        this.COCreatedDate = serviceJobRec.CO_Header__r.CreatedDate;
    }
    
    public class TechnicianInfo {
        public String TechnicianId;
        public String FirstName;
        public String LastName;
        public Boolean IsClocked;
        public DateTime StartTime;
        public Boolean IsPaused;
        
        public TechnicianInfo(List<Hours_Logged__c> hoursLoggedList) {
            this.TechnicianId = hoursLoggedList[0].Technician__c;
            this.FirstName = hoursLoggedList[0].Technician__r.First_Name__c;
            this.LastName = hoursLoggedList[0].Technician__r.Last_Name__c;
            this.IsClocked = false;
            this.IsPaused = false;
            for(Hours_Logged__c hoursLogRec: hoursLoggedList) {
                if(hoursLogRec.Start_Date_Time__c != null && hoursLogRec.End_Date_Time__c == null && !this.IsClocked) {
                    this.IsClocked = true;
                    this.StartTime = hoursLogRec.Start_Date_Time__c;
                }
                if(hoursLogRec.Paused_Date_Time__c != null && !this.IsPaused) {
                    this.IsPaused = true;
                }
            }
        }
    }
    
    public class HoursLoggedInfo {
        public String Id;
        public String TechnicianFirstName;
        public String TechnicianLastName;
        public String Activity;
        public String Notes;
        
        public HoursLoggedInfo(Hours_Logged__c hoursLogged) {
            this.Id = hoursLogged.Id;
            this.TechnicianFirstName = hoursLogged.Technician__r.First_Name__c;
            this.TechnicianLastName = hoursLogged.Technician__r.Last_Name__c;
            String userLocale = UserInfo.getLocale();
            String CurrentLoggedInUser = UserInfo.getUserId();
            String formattedDate = hoursLogged.Start_Date_Time__c.format(Constants.localeToDateMonthFmt.get(userLocale));
            String formattedTime = hoursLogged.Start_Date_Time__c.format('h:mm a');
            String technicianName = '';
            if(hoursLogged.Technician__c == CurrentLoggedInUser) {
                technicianName = 'You';
            } else {
                technicianName = hoursLogged.Technician__r.Technician_Name__c;
            }
            
            if(Date.today() == hoursLogged.Start_Date_Time__c.date()) {
                formattedDate = 'today';
            } else if(Date.today().addDays(-1) == hoursLogged.Start_Date_Time__c.date()) {
                formattedDate = 'yesterday';
            } else {
                formattedDate = 'on ' + formattedDate;
            }
            
            this.Activity = '<strong>' + technicianName + '</strong>';
            if(hoursLogged.End_Date_Time__c != null) {
                this.Activity += ' logged ';
            } else {
                this.Activity += ' clocked ';
            }
            
            if(hoursLogged.End_Date_Time__c != null) {
                Decimal hoursSpentForDays = hoursLogged.Time_Spent_d__c != null ? hoursLogged.Time_Spent_d__c*24 : 0;
                Decimal hoursSpentTotal = hoursLogged.Time_Spent_h__c != null ? (hoursSpentForDays + hoursLogged.Time_Spent_h__c) : hoursSpentForDays;
                this.Activity += hoursSpentTotal != 0 ? (hoursSpentTotal == 1 ? hoursSpentTotal + ' hour ' : hoursSpentTotal + ' hours ') : '';
                this.Activity += hoursLogged.Time_Spent_m__c != null? (hoursLogged.Time_Spent_m__c == 1 ? hoursLogged.Time_Spent_m__c + ' minute ' : hoursLogged.Time_Spent_m__c + ' minutes ') : ''; // && hoursLogged.Time_Spent_m__c != 0
            }
            this.Activity += formattedDate + ' at ' + formattedTime;
            this.Notes = String.isNotBlank(hoursLogged.Notes__c) ? '<strong>Notes: </strong>' + hoursLogged.Notes__c: '';
        }
    }
    
    public Integer compareTo(Object compareToObj) {
        JobClockingWrapper compareToWrapper = (JobClockingWrapper)compareToObj;
        if(this.TechnicianViewTechId == null && this.IsServiceJobClocked) {
            Integer TotalCurrentlyClockedMinutes = (((this.CurrentlyClockedDays*24) + this.CurrentlyClockedHours)*60) + this.CurrentlyClockedMinutes;
            Integer TotalCurrentlyClockedMinutesForCmp = (((compareToWrapper.CurrentlyClockedDays*24) + compareToWrapper.CurrentlyClockedHours)*60) + compareToWrapper.CurrentlyClockedMinutes;
            
            if(TotalCurrentlyClockedMinutes > TotalCurrentlyClockedMinutesForCmp) {
                return -1;
            } else if(TotalCurrentlyClockedMinutes < TotalCurrentlyClockedMinutesForCmp) {
                return 1;
            } else {
                Integer TotalTimeSpentMinutes = (((this.TimeSpentDays*24) + this.TimeSpentHours)*60) + this.TimeSpentMinutes;
                Integer TotalTimeSpentMinutesForCmp = (((compareToWrapper.TimeSpentDays*24) + compareToWrapper.TimeSpentHours)*60) + compareToWrapper.TimeSpentMinutes;
                if(TotalTimeSpentMinutes > TotalTimeSpentMinutesForCmp) {
                    return -1;
                } else if(TotalTimeSpentMinutes < TotalTimeSpentMinutesForCmp) {
                    return 1;
                } else {
                    return 0;
                }
            }
        } else {
            if(JobClockingService.serviceJobStatusToSortingOrderMap.get(this.ServiceJobStatus) > JobClockingService.serviceJobStatusToSortingOrderMap.get(compareToWrapper.ServiceJobStatus)) {
                return 1;
            } else if(JobClockingService.serviceJobStatusToSortingOrderMap.get(this.ServiceJobStatus) < JobClockingService.serviceJobStatusToSortingOrderMap.get(compareToWrapper.ServiceJobStatus)) {
                return -1;
            } else {
                if(this.COCreatedDate > compareToWrapper.COCreatedDate) {
                    return 1;
                } else if(this.COCreatedDate < compareToWrapper.COCreatedDate) {
                    return -1;
                } else {
                    return 0;
                }
            }
        }
    }
}