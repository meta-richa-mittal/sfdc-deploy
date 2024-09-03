/**
 * Author: Richa Mittal
 * Since: Sept 19, 2022
 * Name: QBQueryResponseWrapper
 * Description: Wrapper class for handlign the response received from QB API using query 
**/
public without sharing class QBQueryResponseWrapper {
    public QBResponseWrapper QueryResponse;
    
    public class QBResponseWrapper {
        public List<QBVendorBillDTO> Bill;
        public List<QBVendorCreditDTO> VendorCredit;
        public List<QBInvoiceDTO> SalesReceipt;
        public List<QBInvoiceDTO> RefundReceipt;
        public List<QBInvoiceDTO> Invoice;
        public List<QBInvoiceDTO> CreditMemo;
        public List<QBPaymentDTO> Payment;
        public List<QBItemDTO> Item;
        public List<QBCustomerDTO> Customer;
        public List<QBVendorDTO> Vendor;
        public List<QBTaxCodeWrapper> TaxCode;
        public List<QBTaxRateWrapper> TaxRate;
        public List<AccountWrapper> Account;
        public List<QBJournalEntryDTO> JournalEntry;
        public List<QBTermService.QBTerm> Term;
        public List<CompanyCurrencyWrapper> CompanyCurrency;
        public Decimal TotalCount;
        public Decimal maxResults;
    }

    public class AccountWrapper {
        public String Name;
        public String AccountType;
        public String AcctNum;
        public Boolean Active;
        public String AccountSubType;
        public QBInnerEntityWrapper TaxCodeRef;
        public String Id;
    }

    public class CompanyCurrencyWrapper {
        public String Code; 
        public Boolean Active;
        public String Id;
    }
}