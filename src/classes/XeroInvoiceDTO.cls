public without sharing class XeroInvoiceDTO extends XeroBaseInvoiceDTO {
    public String InvoiceNumber;
    public String InvoiceID;
    public Decimal AmountDue;
    
    public XeroInvoiceDTO(String invoiceId) {
    	this.InvoiceID = invoiceId;
    }
    
    public XeroInvoiceDTO(AccountingCustomerInvoice customerInvoiceRecord) {
    	super(customerInvoiceRecord);
    	this.InvoiceNumber = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber;
    }
    
    public XeroInvoiceDTO(AccountingVendorInvoice voInvoice) {
        super(voInvoice);
        this.InvoiceNumber = voInvoice.AccountingVIHeaderRec.InvoiceNumber;
    }
    
    public XeroInvoiceDTO(AccountingUnit unitInvoiceRecord) {
        super(unitInvoiceRecord);
        this.InvoiceNumber = unitInvoiceRecord.InvoiceNumber;
    }
    
    public XeroInvoiceDTO(AccountingUnitPriceAndCost unitPriceAndCostRecord) {
        super(unitPriceAndCostRecord);
        if(unitPriceAndCostRecord.VendorId != null) {
            this.InvoiceNumber = unitPriceAndCostRecord.VendorReferenceNumber;
        } else if(unitPriceAndCostRecord.CustomerId != null) {
            this.InvoiceNumber = unitPriceAndCostRecord.CustomerReferenceNumber;
        }
    }

    public XeroInvoiceDTO(CO_Invoice_Payment__c coInvPaymentRec) {
        super(coInvPaymentRec);
        this.InvoiceNumber = coInvPaymentRec.AR_Credit_Number__c != null ? (coInvPaymentRec.AR_Credit_Number__c + '_USED') : '';
    }
}