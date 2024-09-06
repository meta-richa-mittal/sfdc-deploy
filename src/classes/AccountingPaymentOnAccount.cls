/**
 * Author: Richa Mittal
 * Since: July 18, 2019
 * Name: AccountingPaymentOnAccount
 * Description: Apex class to handle JSON related oprations of paymnet on account for Accounting.
**/
public without sharing class AccountingPaymentOnAccount {
    public String Id;
    public String Name;
    public Date PaymentDate;
    public CustomerWrapper Customer;
    public String PaymentMethod;
    public Decimal TotalPayment;
    public String QBAccountingId;
	public String XeroAccountingId;
    public String AccountingSyncToken;
    public String QBARPaymentAccountingId;
    public String QBARPaymentSyncToken;
    
    // AR Payments
    public List<AccountingARPayment> AccountingARPaymentsRecs;
    
    public AccountingPaymentOnAccount(Payment_on_Account__c  paymentOnAccountRec) { 
        this.Id = paymentOnAccountRec.Id;
        this.Name = paymentOnAccountRec.Name;
        this.PaymentDate = paymentOnAccountRec.Payment_Date__c;
        this.Customer = new CustomerWrapper(paymentOnAccountRec.Customer__r);
        this.PaymentMethod = paymentOnAccountRec.Payment_Method__c;
        this.TotalPayment = paymentOnAccountRec.Total_Payment__c != null ? paymentOnAccountRec.Total_Payment__c : 0;
        this.QBAccountingId = paymentOnAccountRec.QB_Accounting_Id__c;
		this.XeroAccountingId = paymentOnAccountRec.Xero_Accounting_Id__c;
        this.AccountingSyncToken = paymentOnAccountRec.Accounting_Sync_Token__c;
        this.AccountingARPaymentsRecs = new List<AccountingARPayment>();
        
        for(AR_Payment__c arPaymentRec: paymentOnAccountRec.AR_Payments__r) {
        	this.AccountingARPaymentsRecs.add(new AccountingARPayment(arPaymentRec));
        }
        
        this.QBARPaymentAccountingId = paymentOnAccountRec.QB_AR_Payment_Accounting_Id__c;
        this.QBARPaymentSyncToken = paymentOnAccountRec.QB_AR_Payment_Sync_Token__c;
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        return new List<String>{'Name',
                                'Payment_Date__c',
                                'Customer__r.Id',
                                'Customer__r.Name',
                                'Customer__r.AccountingId__c',
                                'Payment_Method__c',
                                'Total_Payment__c',
                                'QB_Accounting_Id__c',
                                'Accounting_Sync_Token__c',
                                'QB_AR_Payment_Accounting_Id__c',
                                'QB_AR_Payment_Sync_Token__c',
                                'Xero_Accounting_Id__c'
                             };
    }
    
    public class CustomerWrapper {
    	public String Id;
        public String AccountingId;
        public String Name;
        
        public CustomerWrapper(Account customerRec) {
        	this.Id = customerRec.Id;
            this.AccountingId = customerRec.AccountingId__c != null ? customerRec.AccountingId__c : null;
            this.Name = customerRec.Name;
        }
    }
}