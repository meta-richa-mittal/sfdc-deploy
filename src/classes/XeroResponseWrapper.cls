public without sharing class XeroResponseWrapper {
    public List<XeroItemDTO>  Items;
    public List<XeroJournalEntryDTO>  ManualJournals;
    public List<XeroContactDTO>  Contacts;
    public List<XeroOrganisationDTO> Organisations;
    public List<XeroAccountDTO> Accounts;
    public List<XeroTaxRateDTO> TaxRates;
    public List<XeroInvoiceDTO> Invoices;
    public List<XeroCreditNoteDTO> CreditNotes;
    public List<XeroInvoicePaymentDTO> Payments;
    public List<XeroLienPayoutDTO> LienPayout;
    public List<XeroReportWrapper> Reports;
    public List<XeroOrganisationDTO.ActionDTO> Actions;
    public List<XeroUnappliedPaymentDTO> Overpayments;
    public List<XeroUnappliedPaymentDTO> Prepayments;
    public List<XeroCurrencyDTO> Currencies;
}