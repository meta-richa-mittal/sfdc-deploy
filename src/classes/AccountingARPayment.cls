/**
 * Author: Nidhi Sharma
 * Since: July 18, 2019
 * Name: AccountingARPayment
 * Description: 
**/
public without sharing class AccountingARPayment {
    
    public String Id;
    public String Name;
    public Date PaymentDate;
    public CustomerWrapper Customer;
    public String PaymentMethod;
    public Decimal AmountPaid;
    public Decimal OriginalAmount;
    public String InvoiceAccountingId;
    public String TxnType;
    
    public AccountingARPayment(AR_Payment__c  arPaymentRec) { 
        this.Id = arPaymentRec.Id;
        this.Name = arPaymentRec.Name;
        this.PaymentDate = arPaymentRec.Payment_on_Account__r.Payment_Date__c;
        this.OriginalAmount = arPaymentRec.Original_Amount__c;
        this.Customer = new CustomerWrapper(arPaymentRec.Payment_on_Account__r.Customer__r);
        this.PaymentMethod = arPaymentRec.Payment_on_Account__r.Payment_Method__c;
        this.AmountPaid = arPaymentRec.Amount_Paid__c != null ? arPaymentRec.Amount_Paid__c : 0;
        this.InvoiceAccountingId = arPaymentRec.Invoice_Accounting_Id__c;
        this.TxnType = arPaymentRec.Txn_Type__c;
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        return new List<String>{'Name',
                                'Payment_on_Account__r.Payment_Date__c',
                                'Payment_on_Account__r.Payment_Method__c',
                                'Original_Amount__c',
                                'Amount_Paid__c',
                                'Txn_Type__c',
                                'Payment_on_Account__r.Customer__c',
                                'Payment_on_Account__r.Customer__r.Name',
                                'Payment_on_Account__r.Customer__r.AccountingId__c',
                                'Payment_on_Account__r.Customer__r.Xero_Customer_Accounting_Id__c',
                                'Invoice_Accounting_Id__c',
                                'Xero_Accounting_Id__c'
                                /**'Accounting_Sync_Token__c',
                                'Available_For_QB_Sync__c',
                                'Available_For_Xero_Sync__c',
                                'CO_Invoice_Header__c',
                                'QB_Accounting_Id__c',
                                'Xero_Accounting_Id__c'**/
                             };
    }
    
    public class CustomerWrapper{
    	public String Id;
        public String AccountingId;
        public String Name;
        
        public CustomerWrapper(Account customerRec) {
        	this.Id = customerRec.Id;
	    this.AccountingId = customerRec.AccountingId__c != null ? customerRec.AccountingId__c : customerRec.Xero_Customer_Accounting_Id__c;
            this.Name = customerRec.Name;
        }
    }
}