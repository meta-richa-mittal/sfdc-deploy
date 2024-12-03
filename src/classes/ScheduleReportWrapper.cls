public without sharing class ScheduleReportWrapper {

    public String ReportName;
    public String ReportFormat;
    public String EmailListStr;
    public String Frequency;
    public String ScheduleOn;
    public String ScheduleAt;
    public String FilterId;
    public Boolean IsReportScheduled;
    public Boolean IsReportSchedulable;

    public ScheduleReportWrapper(Filter__c filterRec) {
        this.ReportName = filterRec.Filter_Label__c;
        this.ReportFormat = filterRec.Report_Format__c;
        this.EmailListStr = filterRec.Email_Addresses__c;
        this.Frequency = filterRec.Report_Frequency__c;
        this.ScheduleOn = filterRec.Schedule_On__c;
        this.ScheduleAt = filterRec.Schedule_At__c;
        this.FilterId = filterRec.Id;
        this.IsReportScheduled = filterRec.Is_Report_Scheduled__c;
        this.IsReportSchedulable = HSReportSchedulingService.isReportSchedulable(filterRec);
    }
}