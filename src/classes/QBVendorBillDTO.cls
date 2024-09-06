public without sharing class QBVendorBillDTO extends QBBaseVendorInvoiceDTO {
    public Date DueDate;
    
    public QBVendorBillDTO(AccountingVendorInvoice vendorInvoiceRecord) {
        super(vendorInvoiceRecord);
    }

    public QBVendorBillDTO(AccountingUnitPriceAndCost adjstmentRec) {
        super(adjstmentRec);
    }
}