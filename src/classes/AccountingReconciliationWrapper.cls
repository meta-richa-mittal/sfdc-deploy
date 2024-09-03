/**
 * Author: Nidhi Sharma
 * Since: August 24, 2022
 * Name: AccountingReconciliationWrapper
**/
public class AccountingReconciliationWrapper {
    
    public String ReconciliationDateTime;
    public String RecordLink;
    public String Type;
    public String GLName;
    public Decimal BPRecords;
    public Decimal BPBalance;
    public Decimal GLBalance;
    public Decimal Variance;
    public Decimal VarianceChange;

    public AccountingReconciliationWrapper(Accounting_Reconciliation__c accReconcilicationRec) {
        if(accReconcilicationRec != null) {
            this.RecordLink = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + accReconcilicationRec.Id;
            this.ReconciliationDateTime = accReconcilicationRec.Reconciliation_Date__c != null ? BPUtility.getFormatedDateAndTime(accReconcilicationRec.Reconciliation_Date__c) : '';
            this.Type = accReconcilicationRec.Type__c != null ? accReconcilicationRec.Type__c : '';
            this.GLName = accReconcilicationRec.GL_Account_Name__c != null ? accReconcilicationRec.GL_Account_Name__c : '';
            this.BPRecords = accReconcilicationRec.Number_of_BP_records__c;
            this.BPBalance = accReconcilicationRec.Blackpurl_Balance__c;
            this.GLBalance = accReconcilicationRec.GL_Balance__c;
            this.Variance = accReconcilicationRec.Variance__c;
            this.VarianceChange = accReconcilicationRec.Variance_Change__c != null ? accReconcilicationRec.Variance_Change__c : 0;
        }
    }
}