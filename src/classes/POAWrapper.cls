/**
 * Author: Nidhi Sharma
 * Since: July 18, 2019
 * Name: ARPaymentWrapper
 * Description: 
**/
public without sharing class POAWrapper {
	
	public String CustomerId;
    public String CashDrawerId;
    public String PaymentMethod;
    public String PaymentDate;
    public List<ARPaymentWrapper> ARPaymentList;
    public String ReferenceNumber;
    public Decimal ARActivityListTotal;
    public String PreferredPaymentTerminalId;
    public String PaymentProcessorToken;
    
    public POAWrapper() {}
}