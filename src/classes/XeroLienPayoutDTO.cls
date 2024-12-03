public without sharing class XeroLienPayoutDTO {
    public String Id;
    public String Type;
    public String InvDate;
    public String DueDate;
    public String InvoiceNumber;
    public String Status;
	public String LineAmountTypes;
	public List<XeroLineItemDTO> LineItems;
	public XeroContactDTO Contact;
	public String SFId;
	public String Url;
	
    public XeroLienPayoutDTO(AccountingLienPayout accountingLienPayoutRec) {
		this.SFId = accountingLienPayoutRec.Id;
		this.Type= 'ACCPAY';
		this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(accountingLienPayoutRec.InvoiceDateTime, 'yyyy-MM-dd'); 
		this.DueDate = accountingLienPayoutRec.DueDate != null ? DateTimeUtility.getFormttedDateFromDateTime(accountingLienPayoutRec.DueDate, 'yyyy-MM-dd') : null;
		this.InvoiceNumber = accountingLienPayoutRec.InvoiceNumber;
		this.Status = 'AUTHORISED';
		if(QBUtil.isQBTaxCodesEnabled) {
			this.LineAmountTypes = 'Exclusive';
		} else {
			this.LineAmountTypes = 'NoTax';
		}
		this.LineItems = new List<XeroLineItemDTO>{new XeroLineItemDTO(accountingLienPayoutRec)};
		this.Contact = new XeroContactDTO(accountingLienPayoutRec.FinanceCompany.AccountingId);
		this.Url = AccountingUtil.getURL(accountingLienPayoutRec.CoHeaderId, 'CustomerOrder_V2');
    }
    
}