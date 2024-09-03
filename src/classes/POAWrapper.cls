/**
 * Author: Nidhi Sharma
 * Since: July 18, 2019
 * Name: ARPaymentWrapper
 * Description: 
**/
public without sharing class POAWrapper {
	
    public String Id;
	public String CustomerId;
    public String CashDrawerId;
    public String PaymentMethod;
    public String PaymentDate;
    public List<ARPaymentWrapper> ARPaymentList;
    public String ReferenceNumber;
    public Decimal ARActivityListTotal;
    public String PreferredPaymentTerminalId;
    public String PaymentProcessorToken;
    public String PaymentNumber;
    public Decimal TransactionsPaid;
    
    public POAWrapper() {}

    public POAWrapper(Payment_on_Account__c poaRec) {
        this.Id = poaRec.Id;
        this.PaymentNumber = poaRec.Name;
        this.PaymentDate = String.valueOf(poaRec.Payment_Date__c);
        this.PaymentMethod = poaRec.Payment_Method__c;
        this.ReferenceNumber = poaRec.Reference__c;
        this.TransactionsPaid = poaRec.AR_Payments__r != null ? poaRec.AR_Payments__r.size() : 0;
        this.ARActivityListTotal = poaRec.Total_Payment__c != null ? poaRec.Total_Payment__c : 0.00;
    }
}