public without sharing class QBVendorBillDTO extends QBBaseVendorInvoiceDTO {
    public Date DueDate;
    
    public QBVendorBillDTO(AccountingVendorInvoice vendorInvoiceRecord) {
        super(vendorInvoiceRecord);
    }

    public QBVendorBillDTO(AccountingUnitPriceAndCost adjstmentRec) {
        super(adjstmentRec);
    }

    public QBVendorBillDTO(AccountingVendorReturn vendorReturnRecord) {
        super(vendorReturnRecord);
    }

    public QBVendorBillDTO(AccountingLienPayout dealItemRecord) {
        super(dealItemRecord);
        this.DueDate = dealItemRecord.DueDate;
    }

    public QBVendorBillDTO(AccountingUnit couRecord) {
        super(couRecord);
        this.DueDate = couRecord.DueDate;
    }
}