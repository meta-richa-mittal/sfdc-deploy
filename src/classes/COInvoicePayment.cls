/**
 * Author: Tarun Khandelwal
 * Since: April 30, 2015
 * Name: COInvoiceItem
 * Description: Apex class to handle JSON related oprations of CO Invoice Header object.
**/
public without sharing class COInvoicePayment {
    
    // CO Invoice Header Id
    public String COInvoiceHeaderId {get; set;}
    
    // Amount
    public Decimal Amount {get; set;}
    
    // CO Invoice Payment Number
    public String COInvoicePaymentNumber {get; set;}
    
    // CO Invoice Payment Id
    public String COInvoicePaymentId {get; set;}
    
    // Reverse Link
    public String ReverseLink {get; set;}
    
    // Payment Method
    public String PaymentMethod {get; set;}
    
    // Created Date
    public String CreatedDate {get; set;}
    
    // Is Reverse Payment
    public Boolean IsReverse {get; set;} // 05/11/2016
    
    // Deal Id 
    public String DealId {get;set;}
              
    public String CashDrawerId {get;set;}
    
    public String PaymentDate {get;set;}
    
    public String ARCRInvoiceAccId;
    public String ARCreditAccId;
    public String ARCreditNumber;
    public String UnappliedPaymentType;
    
    public String CustomerId;
    public String ReferenceNumber;
    public String PaymentTerminalId;
    public String PreferredPaymentTerminalId;
    public String PaymentProcessorToken;
    public String DepositPaymentMethod;
    public String RelatedPaymentId;
    
    // Constructor
    public COInvoicePayment(CO_Invoice_Payment__c  coInvoicePaymentRec) { 
        this.COInvoiceHeaderId = coInvoicePaymentRec.CO_Invoice_Header__c;
        this.COInvoicePaymentId = coInvoicePaymentRec.Id;
        this.Amount = (coInvoicePaymentRec.Amount__c != null) ? coInvoicePaymentRec.Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.COInvoicePaymentNumber = coInvoicePaymentRec.Name;
        this.ReverseLink = coInvoicePaymentRec.Reverse_Link__c;
        this.PaymentMethod = coInvoicePaymentRec.Payment_Method__c;
        this.CreatedDate = String.valueOf(Date.valueOf(coInvoicePaymentRec.CreatedDate).format());
        this.IsReverse = (coInvoicePaymentRec.Is_Reverse__c != null) ? coInvoicePaymentRec.Is_Reverse__c : false; // 05/11/2016 
        this.CashDrawerId = coInvoicePaymentRec.Cash_Drawer__c;
    	this.PaymentDate = (coInvoicePaymentRec.Payment_Date__c != null) ? BPUtility.getFormatedDateTime(Date.valueOf(coInvoicePaymentRec.Payment_Date__c)) :  BPUtility.getFormatedDateTime(date.today());
        this.ReferenceNumber = coInvoicePaymentRec.Reference__c != null ? coInvoicePaymentRec.Reference__c : '';
        this.PaymentTerminalId = coInvoicePaymentRec.Payment_Terminal__c;
        this.DepositPaymentMethod = coInvoicePaymentRec.Deposit_Payment_Method__c;
        this.RelatedPaymentId = coInvoicePaymentRec.Cash_Rounding_Payment__c;
    }
    
    /**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: COLineItem - Class Object
    **/ 
    public static List<COInvoicePayment> parse(String json) {
        return (List<COInvoicePayment>) System.JSON.deserialize(json, List<COInvoicePayment>.class);
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> coInvoiceItemFields = new List<String>{ 'Id',
                                                        'Name', 
                                                        'CO_Invoice_Header__c',
                                                        'Payment_Method__c',
                                                        'Amount__c',
                                                        'Reverse_Link__c',
                                                        'CreatedDate',
                                                        'Is_Reverse__c', // 05/11/2016
                                                        'Cash_Drawer__c',
                                                        'Payment_Date__c',
                                                        'Reference__c',
                            							'Payment_Terminal__c',
                                                        'Deposit_Payment_Method__c',
                                                        'Cash_Rounding_Payment__c'
                                               		 };
        return coInvoiceItemFields;
    }
}