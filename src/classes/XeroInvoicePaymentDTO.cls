public without sharing class XeroInvoicePaymentDTO {
    public String PaymentID;
    public String Type;
	public String SFId;
    public XeroInvoiceDTO Invoice;
    public XeroCreditNoteDTO CreditNote;
    public XeroAccountDTO Account;
    public String InvDate;
    public Decimal Amount;
    public String Reference;
    public String Status;
    
    public XeroInvoicePaymentDTO(AccountingCustomerInvoice customerInvoiceRecord, CO_Invoice_Header__c coInvoiceRecObj) {
        this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount('Customer Deposits'));
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceDate, 'yyyy-MM-dd');
        this.Amount = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.totalPaymentExcludingChargeAccount;
        this.Reference = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber +
        					';' + customerInvoiceRecord.AccountingCOInvoiceHeaderRec.customer.Name +
        					';' + customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COHeaderNumber +
        					';';
        if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
            this.Type = 'CreditNote';
            this.CreditNote = new XeroCreditNoteDTO(coInvoiceRecObj.Xero_Accounting_Id__c);
            this.Reference += 'Refund';
			this.Amount *= -1;
        } else {
            this.Type = 'Invoice';
            this.Invoice = new XeroInvoiceDTO(coInvoiceRecObj.Xero_Accounting_Id__c);
            this.Reference += 'Payment';
        }
        this.Status = 'AUTHORISED';
    }
    
    public XeroInvoicePaymentDTO(AccountingARPayment arPaymentRecord) {
		this.SFId = arPaymentRecord.Id;
        this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount('Customer Deposits'));
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(arPaymentRecord.PaymentDate, 'yyyy-MM-dd');
        this.Amount = arPaymentRecord.AmountPaid;
        this.Reference = arPaymentRecord.Name +
        					';' + arPaymentRecord.Customer.Name +
        					';' + arPaymentRecord.PaymentMethod +
        					';' + 'Payment on Account' +
        					';';
        if(arPaymentRecord.OriginalAmount < 0) {
            this.CreditNote = new XeroCreditNoteDTO(arPaymentRecord.InvoiceAccountingId);
			this.Amount *= -1;
        } else {
            this.Invoice = new XeroInvoiceDTO(arPaymentRecord.InvoiceAccountingId);
        }
        this.Status = 'AUTHORISED';
    }

    public XeroInvoicePaymentDTO(SObject arcrTxnRec) {
		String objName = String.valueOf(arcrTxnRec.getSObjectType());
        if(objName == Constants.NAMESPACE + 'CO_Deposit__c') {
            setARCRDepositData((CO_Deposit__c)arcrTxnRec);
        } else if(objName == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
            setARCRPaymentData((CO_Invoice_Payment__c)arcrTxnRec);
        }
    }

    private void setARCRDepositData(CO_Deposit__c depositRec) {
        this.SFId = depositRec.Id;
        this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount('Customer Deposits'));
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(depositRec.Payment_Date__c), 'yyyy-MM-dd');
        this.Amount = depositRec.Amount__c != null ? depositRec.Amount__c : 0;
        String arCreditNumber = depositRec.AR_Credit_Number__c != null ? depositRec.AR_Credit_Number__c : '';
        this.Reference = 'AR credit ' + arCreditNumber + ' used as deposit on ' + depositRec.CO_Header__r.Name;
        this.CreditNote = new XeroCreditNoteDTO(depositRec.AR_Credit_Accounting_Id__c);
        this.Status = 'AUTHORISED';
    }

    private void setARCRPaymentData(CO_Invoice_Payment__c coInvPaymentRec) {
        this.SFId = coInvPaymentRec.Id;
        this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount('Customer Deposits'));
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(coInvPaymentRec.Payment_Date__c), 'yyyy-MM-dd');
        this.Amount = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c : 0;
        String arCreditNumber = coInvPaymentRec.AR_Credit_Number__c != null ? coInvPaymentRec.AR_Credit_Number__c : '';
        this.Reference = 'AR credit ' + arCreditNumber + ' used as payment on ' + coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name;
        this.CreditNote = new XeroCreditNoteDTO(coInvPaymentRec.AR_Credit_Accounting_Id__c);
        this.Status = 'AUTHORISED';
    }
}