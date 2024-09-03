/**
 * Author: Richa Mittal
 * Since: Jun 10, 2019
 * Name: AccountingHoursLogged
 * Description: Apex class to handle JSON related oprations of hours logged for Accounting.
**/
public without sharing class AccountingHoursLogged {
    public String Id;
    public String Name;
    public DateTime EndDate;
    public String TechnicianName;
    public String CONumber;
    public String COHeaderId;
    public String ServiceJobName;
    public Decimal TotalCost;
    public Decimal TotalHours;
    public Decimal OldTotalCost;
    public Decimal OldTotalHours;
    public String QBAccountingId;
    public String AccountingSyncToken;
    public String XeroAccountingId;
    public Boolean IsRemoved;
    public String TxnDate;
    
    public AccountingHoursLogged(Hours_Logged__c hoursLoggedRec, DateTime accPeriodCloseDate) { 
        this.Id = hoursLoggedRec.Id;
        this.Name = hoursLoggedRec.Name;
        this.EndDate = hoursLoggedRec.End_Date_Time__c;
        this.TxnDate = DateTimeUtility.getFormttedDateFromDateTime(this.EndDate, 'yyyy-MM-dd');
        if(this.EndDate != null && accPeriodCloseDate != null && (this.EndDate <= accPeriodCloseDate)) {
            this.EndDate = accPeriodCloseDate.addDays(1);
            this.TxnDate = DateTimeUtility.getGMTFormttedDateFromDateTime(this.EndDate, 'yyyy-MM-dd');
        }
        this.TechnicianName = hoursLoggedRec.Technician__c != null? hoursLoggedRec.Technician__r.Technician_Name__c : '';
        this.CONumber = hoursLoggedRec.Service_Order_Header__c != null ? hoursLoggedRec.Service_Order_Header__r.CO_Header__r.Name : '';
        this.COHeaderId = hoursLoggedRec.Service_Order_Header__c != null ? hoursLoggedRec.Service_Order_Header__r.CO_Header__c : null;
        this.ServiceJobName = hoursLoggedRec.Service_Order_Header__c != null ? hoursLoggedRec.Service_Order_Header__r.Name__c : '';
        this.TotalCost = hoursLoggedRec.Total_Cost__c != null ? hoursLoggedRec.Total_Cost__c : 0;
        this.TotalHours = hoursLoggedRec.Total_Hours__c != null ? hoursLoggedRec.Total_Hours__c : 0;
        this.OldTotalCost = hoursLoggedRec.Old_Total_Cost__c;
        this.IsRemoved = hoursLoggedRec.Is_Removed__c;
        this.OldTotalHours = hoursLoggedRec.Old_Total_Hours__c != null ? hoursLoggedRec.Old_Total_Hours__c : 0;
        this.QBAccountingId = hoursLoggedRec.QB_Accounting_Id__c;
        this.XeroAccountingId = hoursLoggedRec.Xero_Accounting_Id__c;
        this.AccountingSyncToken = hoursLoggedRec.Accounting_Sync_Token__c;
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        return new List<String>{'Name',
                                'End_Date_Time__c',
                                'Technician__r.Technician_Name__c',
                                'Service_Order_Header__r.CO_Header__c',
                                'Service_Order_Header__r.CO_Header__r.Name',
                                'Service_Order_Header__r.Name__c',
                                'Total_Cost__c',
                                'Total_Hours__c',
                                'QB_Accounting_Id__c',
                                'Accounting_Sync_Token__c',
                                'Xero_Accounting_Id__c',
                                'Old_Total_Cost__c',
                                'Old_Total_Hours__c',
                                'Is_Removed__c'
                             };
    }
}