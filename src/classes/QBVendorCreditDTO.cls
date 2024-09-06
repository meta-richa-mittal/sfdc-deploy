public without sharing class QBVendorCreditDTO extends QBBaseVendorInvoiceDTO {
    public QBVendorCreditDTO(AccountingVendorInvoice vendorInvoiceRecord) {
    	super(vendorInvoiceRecord);
    }
    public QBVendorCreditDTO(AccountingVendorReturn vendorReturnRecord) {
    	super(vendorReturnRecord);
    }
    public QBVendorCreditDTO(AccountingUnitPriceAndCost upcRecord) {
    	super(upcRecord);
    }
}