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
	public String UnappliedPaymentType = 'AR Credit';
	public String AccountingUrl;
    
	public ARPaymentWrapper(QBInvoiceDTO qbInvoice, String entityName) {
    	this.InvoiceAccountingId = qbInvoice.Id;
    	this.InvoiceDate = String.valueOf(qbInvoice.TxnDate);
    	if(entityName == 'Invoice') {
			this.InvoiceNumber = qbInvoice.DocNumber;
    		this.OriginalAmount = qbInvoice.TotalAmt;
    		this.BalanceDue = qbInvoice.Balance;
			this.DueDate = qbInvoice.DueDate;
    	} else if(entityName == 'CreditMemo') {
			this.InvoiceNumber = qbInvoice.DocNumber;
    		this.OriginalAmount = (qbInvoice.TotalAmt * -1);
    		this.BalanceDue = (Decimal.valueOf(qbInvoice.RemainingCredit) * -1);
			this.FormattedName = qbInvoice.DocNumber + ' - $' + qbInvoice.RemainingCredit;
			this.DueDate = qbInvoice.DueDate;
    	}
		this.AccountingUrl = 'https://app.qbo.intuit.com/app/' + entityName.toLowerCase() + '?txnId=' + qbInvoice.Id;
    }

	public ARPaymentWrapper(QBPaymentDTO qbPayment) {
    	this.InvoiceAccountingId = qbPayment.Id;
    	this.InvoiceDate = String.valueOf(qbPayment.TxnDate);
		this.OriginalAmount = (Decimal.valueOf(qbPayment.TotalAmt) * -1);
		this.BalanceDue = (qbPayment.UnappliedAmt * -1);
		this.FormattedName = qbPayment.PaymentRefNum + ' - $' + qbPayment.UnappliedAmt;
		this.DueDate = String.valueOf(qbPayment.TxnDate);
		this.InvoiceNumber = qbPayment.PaymentRefNum;
		this.UnappliedPaymentType = 'AR Payment';
    	}
    
    public ARPaymentWrapper(XeroInvoiceDTO xeroInvoice) {
    	this.InvoiceAccountingId = xeroInvoice.InvoiceID;
		this.InvoiceNumber = xeroInvoice.InvoiceNumber;
    	this.InvoiceDate = String.isNotBlank(xeroInvoice.DateString) ? getFormattedDateStr('YYYY-MM-dd', xeroInvoice.DateString) : null;
    	this.DueDate = String.isNotBlank(xeroInvoice.DueDateString) ? getFormattedDateStr('YYYY-MM-dd', xeroInvoice.DueDateString) : null;
    	this.OriginalAmount = xeroInvoice.Total;
		this.BalanceDue = xeroInvoice.AmountDue;
		this.AccountingUrl = 'https://go.xero.com/AccountsReceivable/View.aspx?invoiceid=' + xeroInvoice.InvoiceID;
    }
    
    public ARPaymentWrapper(XeroCreditNoteDTO xeroCreditNote) {
    	this.InvoiceAccountingId = xeroCreditNote.CreditNoteID;
		this.InvoiceNumber = xeroCreditNote.CreditNoteNumber;
    	this.InvoiceDate = String.isNotBlank(xeroCreditNote.DateString) ? getFormattedDateStr('YYYY-MM-dd', xeroCreditNote.DateString) : null;
    	this.DueDate = String.isNotBlank(xeroCreditNote.DueDateString) ? getFormattedDateStr('YYYY-MM-dd', xeroCreditNote.DueDateString) : null;
    	this.OriginalAmount = xeroCreditNote.Total * -1;
		this.BalanceDue = xeroCreditNote.RemainingCredit * -1;
		this.FormattedName = xeroCreditNote.CreditNoteNumber + ' - $' + xeroCreditNote.RemainingCredit;
		this.AccountingUrl = 'https://go.xero.com/AccountsReceivable/ViewCreditNote.aspx?creditNoteID=' + xeroCreditNote.CreditNoteID;
    }

	public ARPaymentWrapper(XeroUnappliedPaymentDTO xeroUnappliedPayment) {
    	this.InvoiceAccountingId = String.isNotBlank(xeroUnappliedPayment.PrepaymentID) ? xeroUnappliedPayment.PrepaymentID : xeroUnappliedPayment.OverpaymentID;
		this.InvoiceNumber = xeroUnappliedPayment.Reference;
    	this.InvoiceDate = this.DueDate = String.isNotBlank(xeroUnappliedPayment.DateString) ? getFormattedDateStr('YYYY-MM-dd', xeroUnappliedPayment.DateString) : null;
    	this.OriginalAmount = xeroUnappliedPayment.Total * -1;
		this.BalanceDue = xeroUnappliedPayment.RemainingCredit * -1;
		this.FormattedName = xeroUnappliedPayment.Reference + ' - $' + xeroUnappliedPayment.RemainingCredit;
		this.UnappliedPaymentType = String.isNotBlank(xeroUnappliedPayment.PrepaymentID) ? 'Prepayment' : 'Overpayment';
    }

	public ARPaymentWrapper(CO_Invoice_Header__c coInvoiceRec) {
		Boolean isQBEnabled = QBUtil.isQBEnabled();
    	this.InvoiceAccountingId = isQBEnabled ? coInvoiceRec.AccountingId__c : coInvoiceRec.Xero_Accounting_Id__c;
    	this.InvoiceDate = (coInvoiceRec.Invoice_Date__c != null) ? BPUtility.getFormatedDateTime(coInvoiceRec.Invoice_Date__c) : '';
		this.InvoiceNumber = coInvoiceRec.Invoice_Number__c;
		this.OriginalAmount = coInvoiceRec.Total__c != null ? coInvoiceRec.Total__c : 0;
		this.BalanceDue = 0;
		this.DueDate = '';
		if(isQBEnabled) {
			this.AccountingUrl = 'https://app.qbo.intuit.com/app/' + (this.OriginalAmount > 0 ? 'invoice' : 'creditmemo') + '?txnId=' + this.InvoiceAccountingId;
		} else {
			this.AccountingUrl = 'https://go.xero.com/AccountsReceivable/' + (this.OriginalAmount > 0 ? 'View.aspx?invoiceid=' : 'ViewCreditNote.aspx?creditNoteID=') + this.InvoiceAccountingId;
		}
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