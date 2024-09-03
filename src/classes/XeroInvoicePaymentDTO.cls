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
    public XeroUnappliedPaymentDTO Overpayment;
    public XeroUnappliedPaymentDTO Prepayment;
    
    public XeroInvoicePaymentDTO(AccountingCustomerInvoice customerInvoiceRecord, CO_Invoice_Header__c coInvoiceRecObj) {
        this.SFId = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderId;
        this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount(AccountingUtil.isNewPaymentAccountingApplicable(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceDate.date()) ? 'Checkout Clearing' :'Customer Deposits'));
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceDate, 'yyyy-MM-dd');
        this.Amount = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.totalPaymentExcludingChargeAccount;
        if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.WithheldCostAmount != null) {
            this.Amount += customerInvoiceRecord.AccountingCOInvoiceHeaderRec.WithheldCostAmount;
        }
        if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.WithheldPriceAmount != null) {
            this.Amount += customerInvoiceRecord.AccountingCOInvoiceHeaderRec.WithheldPriceAmount;
        }
        this.Reference = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber +
        					';' + customerInvoiceRecord.AccountingCOInvoiceHeaderRec.customer.Name +
        					';' + customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COHeaderNumber +
        					';';
        
        if(coInvoiceRecObj != null) customerInvoiceRecord.AccountingCOInvoiceHeaderRec.XeroAccountingId = coInvoiceRecObj.Xero_Accounting_Id__c;
        if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
            this.Type = 'CreditNote';
            this.CreditNote = new XeroCreditNoteDTO(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.XeroAccountingId);
            this.Reference += 'Refund';
			this.Amount *= -1;
        } else {
            this.Type = 'Invoice';
            this.Invoice = new XeroInvoiceDTO(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.XeroAccountingId);
            this.Reference += 'Payment';
        }
        this.Status = 'AUTHORISED';
    }
    
    public XeroInvoicePaymentDTO(AccountingARPayment arPaymentRecord) {
		this.SFId = arPaymentRecord.Id;
        if(AccountingUtil.isNewPaymentAccountingApplicable(arPaymentRecord.PaymentDate)){
            this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount('Checkout Clearing'));
        } else {
            this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount('Customer Deposits'));
        }
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(arPaymentRecord.PaymentDate, 'yyyy-MM-dd');
        this.Amount = arPaymentRecord.AmountPaid;
        this.Reference = arPaymentRecord.Name +
        					';' + arPaymentRecord.Customer.Name +
        					';' + arPaymentRecord.PaymentMethod +
        					';' + 'Payment on Account' +
        					';';
        if(arPaymentRecord.OriginalAmount < 0) {
            if(arPaymentRecord.TxnType == 'Overpayment') {
                this.Overpayment = new XeroUnappliedPaymentDTO(arPaymentRecord.TxnType, arPaymentRecord.InvoiceAccountingId);
            } else if(arPaymentRecord.TxnType == 'Prepayment') {
                this.Prepayment = new XeroUnappliedPaymentDTO(arPaymentRecord.TxnType, arPaymentRecord.InvoiceAccountingId);
            } else {
            	this.CreditNote = new XeroCreditNoteDTO(arPaymentRecord.InvoiceAccountingId);
            }
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
        this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount(AccountingUtil.isNewPaymentAccountingApplicable(depositRec.Payment_Date__c) ? 'Checkout Clearing': 'Customer Deposits'));
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(depositRec.Payment_Date__c), 'yyyy-MM-dd');
        this.Amount = depositRec.Amount__c != null ? depositRec.Amount__c : 0;
        String arCreditNumber = depositRec.AR_Credit_Number__c != null ? depositRec.AR_Credit_Number__c : '';
        this.Reference = 'AR credit ' + arCreditNumber + ' used as deposit on ' + depositRec.CO_Header__r.Name;
        if(depositRec.Unapplied_Payment_Type__c == 'Prepayment') {
            this.Prepayment = new XeroUnappliedPaymentDTO(depositRec.Unapplied_Payment_Type__c, depositRec.AR_Credit_Accounting_Id__c);
        } else if(depositRec.Unapplied_Payment_Type__c == 'Overpayment') {
            this.Overpayment = new XeroUnappliedPaymentDTO(depositRec.Unapplied_Payment_Type__c, depositRec.AR_Credit_Accounting_Id__c);
        } else {
            this.CreditNote = new XeroCreditNoteDTO(depositRec.AR_Credit_Accounting_Id__c);
        }
        this.Status = 'AUTHORISED';
    }

    private void setARCRPaymentData(CO_Invoice_Payment__c coInvPaymentRec) {
        this.SFId = coInvPaymentRec.Id;
        this.Account = new XeroAccountDTO(AccountingUtil.getChartofAccount(AccountingUtil.isNewPaymentAccountingApplicable(coInvPaymentRec.Payment_Date__c) ? 'Checkout Clearing': 'Customer Deposits'));
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(coInvPaymentRec.Payment_Date__c), 'yyyy-MM-dd');
        this.Amount = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c : 0;
        String arCreditNumber = coInvPaymentRec.AR_Credit_Number__c != null ? coInvPaymentRec.AR_Credit_Number__c : '';
        this.Reference = 'AR credit ' + arCreditNumber + ' used as payment on ' + coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name;
        if(coInvPaymentRec.Unapplied_Payment_Type__c == 'Prepayment') {
            this.Prepayment = new XeroUnappliedPaymentDTO(coInvPaymentRec.Unapplied_Payment_Type__c, coInvPaymentRec.AR_Credit_Accounting_Id__c);
        } else if(coInvPaymentRec.Unapplied_Payment_Type__c == 'Overpayment') {
            this.Overpayment = new XeroUnappliedPaymentDTO(coInvPaymentRec.Unapplied_Payment_Type__c, coInvPaymentRec.AR_Credit_Accounting_Id__c);
        } else {
            this.CreditNote = new XeroCreditNoteDTO(coInvPaymentRec.AR_Credit_Accounting_Id__c);
        }
        this.Status = 'AUTHORISED';
    }
}