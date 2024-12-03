/**
 * Author: Tarun Khandelwal
 * Since: May 8, 2015
 * Name: InvoiceHistory
 * Description: Apex class to handle JSON related oprations of Invoice History.
**/
public without sharing class InvoiceHistory {
	
	// Invoice Header Number
	public String InvoiceNumber {get; set;}
	
	// Closed Invoice Date
	public String ClosedInvoiceDate {get; set;}
	
	// Number Of CO Invoice Items
	public Decimal NumberOfItems {get; set;}
	
	// SubTotal (Without Tax)
	public Decimal SubTotal {get; set;}
	
	// Tax Included
	public Decimal Tax {get; set;}
	
	// Total
	public Decimal Total {get; set;}
	
	// Invoice id
	public String COInvoiceHeaderId {get; set;}
	
	public String CheckoutType;
	
	public Boolean HasLineItemFromMerchSection;
	public Boolean HasCustomerPayServiceJob;
	public Boolean IsDealInvoiced;
	public String ARBalance;
	
	// List of CO Invoice History Record
    public List<COInvoicePayment> COInvoiceHeaderPaymentRecs {get; set;}
	
	// Constructor
    public InvoiceHistory(CO_Invoice_Header__c  coInvoiceHeaderRec) {
    	this.InvoiceNumber = coInvoiceHeaderRec !=null ? coInvoiceHeaderRec.Invoice_Number__c : '';	
    	this.ClosedInvoiceDate = (coInvoiceHeaderRec.Invoice_Date__c != null) ? BPUtility.getFormatedDateTime(coInvoiceHeaderRec.Invoice_Date__c) : '';
    	this.COInvoiceHeaderPaymentRecs =  new List<COInvoicePayment>();
    	
    	Decimal noOfItems = 0;
    	Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
     	
     	for(CO_Invoice_Payment__c coInvoicePaymentRec : coInvoiceHeaderRec.CO_Invoice_Payments__r) {
    		COInvoiceHeaderPaymentRecs.add(new COInvoicePayment(coInvoicePaymentRec));
     	}
     	this.NumberOfItems = coInvoiceHeaderRec.CO_Invoice_Items__r.size();
 		this.SubTotal = (coInvoiceHeaderRec.Sub_Total__c != null ? coInvoiceHeaderRec.Sub_Total__c.setScale(2, RoundingMode.HALF_UP) : 0);
 		this.Tax = (coInvoiceHeaderRec.SalesTax_Total__c != null ? coInvoiceHeaderRec.SalesTax_Total__c.setScale(2, RoundingMode.HALF_UP) : 0);
 		this.Total = (coInvoiceHeaderRec.Total__c != null ? coInvoiceHeaderRec.Total__c.setScale(2, RoundingMode.HALF_UP) : 0);
		this.IsDealInvoiced = coInvoiceHeaderRec.Is_Deal_Invoiced__c;
		this.ARBalance = (coInvoiceHeaderRec.Total_Charge_On_Account__c == null || coInvoiceHeaderRec.Total_Charge_On_Account__c == 0) ? 'N/A' : null;
     	
    	/*if(!isTaxIncludingPricing) {
	    	this.SubTotal = totalPrice;
	    	this.Tax = totalTax;
	    	this.Total = totalPrice + totalTax;
    	} else {
    		this.Total = this.SubTotal = totalPrice + totalTax;
    		this.Tax = totalTax;
    	}*/
    	
    	this.COInvoiceHeaderId = coInvoiceHeaderRec.Id;
    	this.CheckoutType = coInvoiceHeaderRec.Checkout_Type__c;
    	this.HasLineItemFromMerchSection = false;
    	this.HasCustomerPayServiceJob = false;
    	
    	for(CO_Invoice_Item__c coInvoiceItemRec : coInvoiceHeaderRec.CO_Invoice_Items__r) {
    	    if(coInvoiceItemRec.CO_Line_Item__c != null && coInvoiceItemRec.CO_Line_Item__r.Deal__c == null) {
    	        this.HasLineItemFromMerchSection = true;
    	        break;
    	    } else if(!this.HasCustomerPayServiceJob && coInvoiceItemRec.Service_Order_Header__c != null && coInvoiceHeaderRec.Checkout_Type__c == Constants.CHECKOUT_TYPE_CUSTOMER) {
    	    	this.HasCustomerPayServiceJob = true;
    	    }
    	}
    } 
    
    /**
     * Name: coInvoiceHeaderFieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> coInvoiceHeaderFieldsList(){
        List<String> COInvoiceHeaderFields = new List<String>{ 'Id',
                                                        	'Name', 
                                                        	'CO_Header__c',
                                                        	'Invoice_Date__c',
                                                        	'Invoice_Status__c',
                                                        	'Checkout_Type__c',
                                                        	'Invoice_Number__c',
                                                        	'Sub_Total__c',
                                                        	'Total__c',
                                                        	'SalesTax_Total__c',
															'Is_Deal_Invoiced__c',
															'Total_Charge_On_Account__c'
                                               			 };
        return COInvoiceHeaderFields;
    }
    
    /**
     * Name: coInvoiceItemsFieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> coInvoiceItemsFieldsList(){
        List<String> COInvoiceHeaderFields = new List<String>{ 'Id',
                                                        	'Name', 
                                                        	'CO_Line_Item__r.Tax__c',
                                                        	'CO_Line_Item__r.Price__c',
                                                        	'CO_Line_Item__r.Qty__c',
                                                        	'CO_Line_Item__r.Deal__c',
                                                        	'Service_Order_Header__c',
                                                        	'Service_Order_Header__r.Total__c',
                                                        	'Service_Order_Header__r.Tax_Amount__c',
                                                        	'CO_Kit_Header__c',
                                                        	'CO_Kit_Header__r.Price__c',
                                                        	'CO_Kit_Header__r.Tax_Amount__c',
                                                        	'SO_Payment_Role__r.Total_Amount__c',
                                                        	'SO_Payment_Role__r.Tax_Amount__c',
                                                        	'Service_Order_Header__r.Transaction_Type__r.Type__c',
                                                        	'Service_Order_Header__r.Transaction_Type__c',
                                                        	'Deal__c',
                                                        	'Deal__r.Total__c',
                                                        	'Deal_Finance__c',
                                                        	'Deal_Finance__r.F_I_Total__c',
                                                        	'Deal_Finance__r.Down_Payment__c',
                                                        	'Deal__r.Total_Deposit_And_Payment__c',
                                                        	'Deal_Finance__r.F_I_Product_Tax_Total__c',
                                                        	'Deal__r.Deal_Tax_Total__c'
                                               			 };
        return COInvoiceHeaderFields;
    }
}