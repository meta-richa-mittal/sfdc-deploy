public without sharing class QBCreditMemoDTO extends QBBaseInvoiceDTO{

    public QBCreditMemoDTO(AccountingUnitPriceAndCost adjstmentRec) {
        super(adjstmentRec);
    }
    
    public QBCreditMemoDTO(AccountingUnit consUnitRecord) {
        super(consUnitRecord);
    }

    public QBCreditMemoDTO(AccountingVendorReturn returnVOHeaderRecord) {
        super(returnVOHeaderRecord);
    }
}