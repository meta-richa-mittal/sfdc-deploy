/**
 * Author: Nidhi Sharma
 * Since: July 18, 2019
 * Name: ARPaymentWrapper
 * Description: 
**/
public without sharing class ARPaymentWrapper implements Comparable {
	
	public String InvoiceAccountingId;
    public String InvoiceNumber;
    public String InvoiceDate;
    public String DueDate;
    public Decimal OriginalAmount;
    public Decimal BalanceDue;
    public Decimal AmountPaid = 0.00;
	public String FormattedName;
	public Boolean isUnappliedPayment = false;
    
    public ARPaymentWrapper(QuickBookQueryService.QuickBooksEntity qbInvoice, String entityName) {
    	this.InvoiceAccountingId = qbInvoice.Id;
    	this.InvoiceDate = qbInvoice.TxnDate;
    	this.OriginalAmount = Decimal.valueOf(qbInvoice.TotalAmt);
    	if(entityName == 'Invoice') {
			this.InvoiceNumber = qbInvoice.DocNumber;
    		this.OriginalAmount = Decimal.valueOf(qbInvoice.TotalAmt);
    		this.BalanceDue = Decimal.valueOf(qbInvoice.Balance);
			this.DueDate = qbInvoice.DueDate;
    	} else if(entityName == 'CreditMemo') {
			this.InvoiceNumber = qbInvoice.DocNumber;
    		this.OriginalAmount = (Decimal.valueOf(qbInvoice.TotalAmt) * -1);
    		this.BalanceDue = (Decimal.valueOf(qbInvoice.RemainingCredit) * -1);
			this.FormattedName = qbInvoice.DocNumber + ' - $' + qbInvoice.RemainingCredit;
			this.DueDate = qbInvoice.DueDate;
    	} else if(entityName == 'Payment') {
    		this.OriginalAmount = (Decimal.valueOf(qbInvoice.TotalAmt) * -1);
    		this.BalanceDue = (Decimal.valueOf(qbInvoice.UnappliedAmt) * -1);
			this.FormattedName = qbInvoice.PaymentRefNum + ' - $' + qbInvoice.UnappliedAmt;
			this.DueDate = qbInvoice.TxnDate;
			this.InvoiceNumber = qbInvoice.PaymentRefNum;
			this.isUnappliedPayment = true;
    	}
    }
    
    public ARPaymentWrapper(XeroInvoiceDTO xeroInvoice) {
    	this.InvoiceAccountingId = xeroInvoice.InvoiceID;
		this.InvoiceNumber = xeroInvoice.InvoiceNumber;
    	this.InvoiceDate = String.isNotBlank(xeroInvoice.DateString) ? getFormattedDateStr('YYYY-MM-dd', xeroInvoice.DateString) : null;
    	this.DueDate = String.isNotBlank(xeroInvoice.DueDateString) ? getFormattedDateStr('YYYY-MM-dd', xeroInvoice.DueDateString) : null;
    	this.OriginalAmount = xeroInvoice.Total;
		this.BalanceDue = xeroInvoice.AmountDue;
    }
    
    public ARPaymentWrapper(XeroCreditNoteDTO xeroCreditNote) {
    	this.InvoiceAccountingId = xeroCreditNote.CreditNoteID;
		this.InvoiceNumber = xeroCreditNote.CreditNoteNumber;
    	this.InvoiceDate = String.isNotBlank(xeroCreditNote.DateString) ? getFormattedDateStr('YYYY-MM-dd', xeroCreditNote.DateString) : null;
    	this.DueDate = String.isNotBlank(xeroCreditNote.DueDateString) ? getFormattedDateStr('YYYY-MM-dd', xeroCreditNote.DueDateString) : null;
    	this.OriginalAmount = xeroCreditNote.Total * -1;
		this.BalanceDue = xeroCreditNote.RemainingCredit * -1;
		this.FormattedName = xeroCreditNote.CreditNoteNumber + ' - $' + xeroCreditNote.RemainingCredit;
    }
    
    private String getFormattedDateStr(String dateFormat, String dateStr) {
    	DateTime tempDate = Date.valueOf(dateStr);
    	return tempDate.format(dateFormat);
    }
    
    public Integer compareTo(Object compareToObj) {
    	ARPaymentWrapper compareToWrapper = (ARPaymentWrapper)compareToObj;
    	Date thisInvoiceDate = String.isNotBlank(this.InvoiceDate) ? DateTimeUtility.getDateFromFormattedDateStr(this.InvoiceDate, 'YYYY-MM-DD') : null;
    	Date compareToInvoiceDate = String.isNotBlank(compareToWrapper.InvoiceDate) ? DateTimeUtility.getDateFromFormattedDateStr(compareToWrapper.InvoiceDate, 'YYYY-MM-DD') : null;
    	
    	if(thisInvoiceDate > compareToInvoiceDate){
    		return 1;
    	} else if(thisInvoiceDate == compareToInvoiceDate){
    		return 0;
    	}
       return -1;  
    }
}