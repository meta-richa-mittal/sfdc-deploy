/**
 * Author: Nidhi Sharma
 * Since: Nov. 30, 2022
 * Name: ServiceJobStatusWrapper
**/
public without sharing class ServiceJobStatusWrapper {
	
    public String Id;
    public String Name;
    public String ShortName;
    public Boolean IsActive;
    public Boolean IsRequired;
    public Integer OrderNo;
    public String TextColor;
    public String BgColor;
    public Boolean IsTechClockJobStatus;

    public ServiceJobStatusWrapper(SO_Status__c soStatusRec) {
        if(soStatusRec != null) {
            Id = soStatusRec.Id;
            Name = soStatusRec.Name__c;
            ShortName = soStatusRec.Short_Name__c;
            IsActive = soStatusRec.Is_Active__c;
            IsRequired = soStatusRec.Is_Required__c;
            OrderNo = soStatusRec.Order_No__c != null ? Integer.valueOf(soStatusRec.Order_No__c) : 10;
            TextColor = soStatusRec.Text_Color__c;
            BgColor = soStatusRec.Background_Color__c;
            IsTechClockJobStatus = soStatusRec.Is_Active__c && soStatusRec.Default_Clock_ON_Status__c;
        }
    }
}