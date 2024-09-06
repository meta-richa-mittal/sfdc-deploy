public without sharing class QBResponseWrapper {
    public QBVendorBillDTO Bill;
    public QBVendorCreditDTO VendorCredit;
    public QBCreditMemoDTO CreditMemo;
    public QBInvoiceDTO Invoice;
    public QBPaymentDTO Payment;
    public QBItemDTO Item;
    public QBJournalEntryDTO JournalEntry;
    public QBCustomerDTO Customer;
    public QBVendorDTO Vendor;
    public QBInvoiceDTO SalesReceipt;
    public QBInvoiceDTO RefundReceipt;
    public QBCompanyInfoDTO CompanyInfo;
    public QBPreferencesDTO Preferences;

    public class QBCompanyInfoDTO {
        public String CompanyName;
        public String Country;
        public List<QBInnerEntityWrapper> nameValue;
    }
}