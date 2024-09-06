public without sharing class XeroCreditNoteDTO extends XeroBaseInvoiceDTO {
    public String CreditNoteNumber;
    public String CreditNoteID;
    public Decimal RemainingCredit;
    
    public XeroCreditNoteDTO(String creditNoteId) {
    	this.CreditNoteID = creditNoteId;
    }
    
    public XeroCreditNoteDTO(AccountingUnit consignmentUnitRecord) {
    	super(consignmentUnitRecord, true);
    	this.CreditNoteID = consignmentUnitRecord.XeroConsignmentAccId;
    	this.CreditNoteNumber = consignmentUnitRecord.InvoiceNumber;
    }
    
    public XeroCreditNoteDTO(AccountingCustomerInvoice customerInvoiceRecord) {
    	super(customerInvoiceRecord);
    	this.CreditNoteNumber = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber;
    }

    public XeroCreditNoteDTO(AccountingVendorReturn vendorReturnRecord) {
        super(vendorReturnRecord);
        this.CreditNoteID = vendorReturnRecord.XeroAccountingId;
        this.CreditNoteNumber = vendorReturnRecord.Name;
    }
    
    public XeroCreditNoteDTO(AccountingUnitPriceAndCost unitPriceAndCostRecord) {
        super(unitPriceAndCostRecord);
        if(unitPriceAndCostRecord.VendorId != null) {
            this.CreditNoteNumber = unitPriceAndCostRecord.VendorReferenceNumber;
        } else if(unitPriceAndCostRecord.CustomerId != null) {
            this.CreditNoteNumber = unitPriceAndCostRecord.CustomerReferenceNumber;
        }
    }
    
    public XeroCreditNoteDTO(AccountingVendorInvoice voInvoice) {
    	super(voInvoice);
    	this.CreditNoteNumber = voInvoice.AccountingVIHeaderRec.InvoiceNumber;
    }
}