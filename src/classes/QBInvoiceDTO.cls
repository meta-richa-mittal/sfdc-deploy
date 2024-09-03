public without sharing class QBInvoiceDTO extends QBBaseInvoiceDTO {
    public QBInvoiceDTO(AccountingUnitPriceAndCost adjstmentRec) {
        super(adjstmentRec);
    }
    
    public QBInvoiceDTO(SObject arcrTxnRec, String categoryAccId) {
        super(arcrTxnRec, categoryAccId);
    }

    public QBInvoiceDTO(AccountingCustomerInvoice customerInvoiceRecord) {
        super(customerInvoiceRecord);
    }

    public QBInvoiceDTO(String id, String syncToken, String docNumber) {
        super(id, syncToken, docNumber);
    }
}