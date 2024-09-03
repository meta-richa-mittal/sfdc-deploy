public without sharing class AccountingCashReconciliation {
    public String CashReconName{get; set;}
    public String CashReconId{get; set;}
    public String OptionalNote{get; set;}
    public Date ReconciliationDate {get; set;}
    public String Id {get; set;} // Created for generalised error response handling in XeroService
    public String AccountingId;
    public String SyncToken;
    public String AccountingResponse;
    public Decimal TotalVariance;
    public Decimal TotalProcessedAmount; 
    public List<CashReconciliationPaymentWrapper> ReconPaymentList;   
    
    
    // Constructor
    public AccountingCashReconciliation(Cash_Reconciliation__c cashReconRec) {
        this.CashReconName = cashReconRec.Name;
        this.OptionalNote = String.isNotBlank(cashReconRec.Optional_Note__c) ? cashReconRec.Optional_Note__c : '';
        if(cashReconRec.Id != null) {
            this.Id = this.CashReconId = cashReconRec.Id;
            this.ReconciliationDate = cashReconRec.Reconciliation_Date__c;
        }  

        
        this.AccountingId = cashReconRec.Accounting_Id__c;
        this.SyncToken = cashReconRec.Sync_Token__c;
        this.AccountingResponse = cashReconRec.Accounting_Response__c;
        this.TotalVariance = this.TotalProcessedAmount = 0;
        this.ReconPaymentList = new List<CashReconciliationPaymentWrapper>();
        Set<String> cashPaymentMethodTypeSet = CashReconciliationService.getCashCreditPaymentSet();
        if(!cashReconRec.Cash_Reconciliation_Payments__r.isEmpty()) {
            for(Cash_Reconciliation_Payment__c paymentRec : cashReconRec.Cash_Reconciliation_Payments__r) {
                if(cashPaymentMethodTypeSet.contains(paymentRec.Payment_Method__c)) {
                    this.ReconPaymentList.add(new CashReconciliationPaymentWrapper(paymentRec));
                    this.TotalVariance += (paymentRec.Variance__c != null ? paymentRec.Variance__c.setScale(2, RoundingMode.HALF_UP): 0);
                    this.TotalProcessedAmount += (paymentRec.Processed_Amount__c != null ? paymentRec.Processed_Amount__c.setScale(2, RoundingMode.HALF_UP): 0);
                }
            }
        }
    }     
    
    /**
     * Name: fieldsList
    * Desc: Method Which contains all the field list to be quried
    * @param:  
    * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> cashReconFields = new List<String>{ 'Id',
                            'Name', 
                            'Optional_Note__c',
                            'Reconciliation_Date__c',
                            'Accounting_Id__c',
                            'Sync_Token__c',
                            'Accounting_Response__c', 
                            '(SELECT Payment_Method__c, Cash_Drawer_Reconciliation__c, Actual_Amount__c, Variance__c, Processed_Amount__c, Cash_Drawer_Reconciliation__r.Cash_Drawer__c, Cash_Drawer_Reconciliation__r.Cash_Drawer__r.Name FROM Cash_Reconciliation_Payments__r ORDER BY Payment_Method__c ASC LIMIT 1000)'
                        };
        return cashReconFields;
    }

    public class CashReconciliationPaymentWrapper {
        public String PaymentName;
        public String CashDrawerName;
        public Decimal ActualAmount;

        public CashReconciliationPaymentWrapper(Cash_Reconciliation_Payment__c paymentRec) {
            this.PaymentName = paymentRec.Payment_Method__c;
            this.CashDrawerName = (paymentRec.Cash_Drawer_Reconciliation__c != null && paymentRec.Cash_Drawer_Reconciliation__r.Cash_Drawer__c != null)? paymentRec.Cash_Drawer_Reconciliation__r.Cash_Drawer__r.Name : '';
            this.ActualAmount = paymentRec.Actual_Amount__c;

        }
    }
     
}