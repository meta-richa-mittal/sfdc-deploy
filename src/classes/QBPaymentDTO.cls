public with sharing class QBPaymentDTO {
    public String SFId;
    public String Id;
    public String SyncToken;
    public Date TxnDate;
    public String TxnStatus;
    public String PaymentRefNum;
    public String TotalAmt;
    public Decimal UnappliedAmt;
    public List<QuickBooksLineWrapper> Line;
    public QuickBooksCustomerRefWrapper CustomerRef;
    public DepositToAccountRefWrapper DepositToAccountRef;
    public QBInnerEntityWrapper CurrencyRef;
    public Decimal ExchangeRate = 1;
    public String PrivateNote;

    public class DepositToAccountRefWrapper{
        public String value;
        
        public DepositToAccountRefWrapper(String value){
        	this.value = value;
        }
    }

    public class QuickBooksCustomerRefWrapper{
        
        public String value;
        public String name;
        
        public QuickBooksCustomerRefWrapper(AccountingCustomerInvoice.CustomerWrapper customerRecord) {
            this.value = customerRecord.AccountingId;
            this.name = customerRecord.Name;
        }
        
        public QuickBooksCustomerRefWrapper(String accountingId) {
            this.value = accountingId;
        }
     }
     public class QuickBooksLinkedTxnWrapper{
        
        public String TxnId;
        public String TxnType;
        
        public QuickBooksLinkedTxnWrapper(AccountingCustomerInvoice COInvoiceRecord) {
            this.TxnId = COInvoiceRecord.AccountingCOInvoiceHeaderRec.AccountingId;
            this.TxnType = 'Invoice'; 
        }
        
        public QuickBooksLinkedTxnWrapper(AccountingARPayment accARPaymentRecord) {
            this.TxnId = accARPaymentRecord.InvoiceAccountingId;
            if(String.isNotBlank(accARPaymentRecord.TxnType)) {
                this.TxnType = accARPaymentRecord.TxnType;
            } else {
            	this.TxnType = accARPaymentRecord.AmountPaid > 0 ? 'CreditMemo' : 'Invoice';
            }
        }

        public QuickBooksLinkedTxnWrapper(String txnId, String txnType) {
            this.TxnId = txnId;
            this.TxnType = txnType; 
        }

     }

    public class QuickBooksLineWrapper{
        
        public Decimal Amount;
        
        public List<QuickBooksLinkedTxnWrapper> LinkedTxn; 
        
        public QuickBooksLineWrapper(AccountingCustomerInvoice COInvoiceRecord, Decimal TotalInvoicePayment) {
            this.Amount = TotalInvoicePayment;  
            
            this.LinkedTxn = new List<QuickBooksLinkedTxnWrapper>();
            this.LinkedTxn.add(new QuickBooksLinkedTxnWrapper(COInvoiceRecord));          
        }
        
        public QuickBooksLineWrapper(AccountingARPayment accARPaymentRecord) {
        	if(accARPaymentRecord.AmountPaid > 0) {
            	this.Amount = accARPaymentRecord.AmountPaid;
            } else {
            	this.Amount = accARPaymentRecord.AmountPaid * -1;
            }
            this.LinkedTxn = new List<QuickBooksLinkedTxnWrapper>();
            this.LinkedTxn.add(new QuickBooksLinkedTxnWrapper(accARPaymentRecord));          
        }

        public QuickBooksLineWrapper(Decimal amount, String txnId, String txnType) {
            this.Amount = amount;  
            
            this.LinkedTxn = new List<QuickBooksLinkedTxnWrapper>();
            this.LinkedTxn.add(new QuickBooksLinkedTxnWrapper(txnId, txnType));          
        }
    }
    
    public QBPaymentDTO(AccountingPaymentOnAccount accPaymentOnAccountRecord) {
        this.SFId = accPaymentOnAccountRecord.Id;
        this.Id = accPaymentOnAccountRecord.QBARPaymentAccountingId;
        this.SyncToken = accPaymentOnAccountRecord.QBARPaymentSyncToken;
        this.TxnDate = accPaymentOnAccountRecord.PaymentDate;
        this.PaymentRefNum = accPaymentOnAccountRecord.Name;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        
        this.Line = new List<QuickBooksLineWrapper>();
        for(AccountingARPayment accountingARPaymentRec: accPaymentOnAccountRecord.AccountingARPaymentsRecs) {
            if(accountingARPaymentRec.AmountPaid != 0) {
                this.Line.add(new QuickBooksLineWrapper(accountingARPaymentRec));
            }
        }
        
        this.CustomerRef = new QuickBooksCustomerRefWrapper(accPaymentOnAccountRecord.Customer.AccountingId);
        if(AccountingUtil.isNewPaymentAccountingApplicable(accPaymentOnAccountRecord.PaymentDate)){
            this.DepositToAccountRef  = new DepositToAccountRefWrapper(Accountingutil.getChartofAccount('Checkout Clearing'));
        } else {
            this.DepositToAccountRef  = new DepositToAccountRefWrapper(Accountingutil.getChartofAccount('Customer Deposits'));
        }
        this.TotalAmt = String.valueOf(accPaymentOnAccountRecord.TotalPayment);
        this.PrivateNote = accPaymentOnAccountRecord.Name +
                            ';' + accPaymentOnAccountRecord.Customer.Name +
                            ';' + accPaymentOnAccountRecord.PaymentMethod +
                            ';' + 'Payment on Account' +
                            ';';
    }

    public QBPaymentDTO(AccountingCustomerInvoice COInvoiceRecord) {
        this.SFId = COInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderId;
        this.Id = COInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoicePaymentAccountingId;
        this.SyncToken = COInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoicePaymentSyncToken;
        this.TxnDate = DateTimeUtility.getDateFromFormattedDateStr(COInvoiceRecord.AccountingCOInvoiceHeaderRec.ClosedInvoiceDate);
        this.PaymentRefNum = COInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        Decimal TotalInvoicePayment = COInvoiceRecord.AccountingCOInvoiceHeaderRec.totalPaymentExcludingChargeAccount;
        if(COInvoiceRecord.AccountingCOInvoiceHeaderRec.WithheldCostAmount != null) {
            TotalInvoicePayment += COInvoiceRecord.AccountingCOInvoiceHeaderRec.WithheldCostAmount;
        }
        if(COInvoiceRecord.AccountingCOInvoiceHeaderRec.WithheldPriceAmount != null) {
            TotalInvoicePayment += COInvoiceRecord.AccountingCOInvoiceHeaderRec.WithheldPriceAmount;
        }
        
        this.Line = new List<QuickBooksLineWrapper>();
        this.Line.add(new QuickBooksLineWrapper(COInvoiceRecord, TotalInvoicePayment));
        
        this.CustomerRef = new QuickBooksCustomerRefWrapper(COInvoiceRecord.AccountingCOInvoiceHeaderRec.customer);
        String accountName ='';
        if(AccountingUtil.isNewPaymentAccountingApplicable(COInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceDate.date())){
            accountName = Accountingutil.getChartofAccount('Checkout Clearing');
        } else{
            accountName = Accountingutil.getChartofAccount('Customer Deposits'); 
        }
        this.DepositToAccountRef  = new DepositToAccountRefWrapper(accountName);
        this.TotalAmt = String.valueOf(TotalInvoicePayment);
        this.PrivateNote = COInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber +
        					';' + COInvoiceRecord.AccountingCOInvoiceHeaderRec.customer.Name +
        					';' + COInvoiceRecord.AccountingCOInvoiceHeaderRec.COHeaderNumber +
        					';' + (COInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0 ? 'Refund' : 'Payment');
    }

    public QBPaymentDTO(SOBject arcrTxnRec) {
        String objName = String.valueOf(arcrTxnRec.getSObjectType());
        if(objName == Constants.NAMESPACE + 'CO_Deposit__c') {
            setARCRDepositData((CO_Deposit__c)arcrTxnRec);
        } else if(objName == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
            setARCRPaymentData((CO_Invoice_Payment__c)arcrTxnRec);
        }
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
    }

    private void setARCRDepositData(CO_Deposit__c depositRec) {
        this.TxnDate = depositRec.Payment_Date__c;
        this.PaymentRefNum = depositRec.Name;
        depositRec.Amount__c = depositRec.Amount__c != null ? depositRec.Amount__c : 0;
        this.Line = new List<QuickBooksLineWrapper>();
        if(depositRec.Unapplied_Payment_Type__c == COPaymentService.AR_PAYMENT) {
            this.Line.add(new QuickBooksLineWrapper(depositRec.Amount__c, depositRec.AR_Credit_Accounting_Id__c, 'Payment'));
        } else {
            this.Line.add(new QuickBooksLineWrapper(depositRec.Amount__c, depositRec.AR_Credit_Accounting_Id__c, 'CreditMemo'));
        }
        this.Line.add(new QuickBooksLineWrapper(depositRec.Amount__c, depositRec.AR_Credit_Invoice_Accounting_Id__c, 'Invoice'));

        this.CustomerRef = new QuickBooksCustomerRefWrapper(depositRec.CO_Header__r.Customer__r.AccountingId__c);
        this.DepositToAccountRef  = new DepositToAccountRefWrapper(Accountingutil.getChartofAccount(AccountingUtil.isNewPaymentAccountingApplicable(depositRec.Payment_Date__c) ? 'Checkout Clearing': 'Customer Deposits'));
        this.TotalAmt = '0';
        String arCreditNumber = depositRec.AR_Credit_Number__c != null ? depositRec.AR_Credit_Number__c : '';
        this.PrivateNote = 'AR credit ' + arCreditNumber + ' used as deposit on ' + depositRec.CO_Header__r.Name;
    }

    private void setARCRPaymentData(CO_Invoice_Payment__c coInvPaymentRec) {
        this.TxnDate = coInvPaymentRec.Payment_Date__c;
        this.PaymentRefNum = coInvPaymentRec.Name;
        coInvPaymentRec.Amount__c = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c : 0;
        this.Line = new List<QuickBooksLineWrapper>();
        if(coInvPaymentRec.Unapplied_Payment_Type__c == COPaymentService.AR_PAYMENT) {
            this.Line.add(new QuickBooksLineWrapper(coInvPaymentRec.Amount__c, coInvPaymentRec.AR_Credit_Accounting_Id__c, 'Payment'));
        } else {
            this.Line.add(new QuickBooksLineWrapper(coInvPaymentRec.Amount__c, coInvPaymentRec.AR_Credit_Accounting_Id__c, 'CreditMemo'));
        }
        this.Line.add(new QuickBooksLineWrapper(coInvPaymentRec.Amount__c, coInvPaymentRec.AR_Credit_Invoice_Accounting_Id__c, 'Invoice'));

        this.CustomerRef = new QuickBooksCustomerRefWrapper(coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Customer__r.AccountingId__c);
        this.DepositToAccountRef  = new DepositToAccountRefWrapper(Accountingutil.getChartofAccount(AccountingUtil.isNewPaymentAccountingApplicable(coInvPaymentRec.Payment_Date__c) ? 'Checkout Clearing': 'Customer Deposits'));
        this.TotalAmt = '0';
        String arCreditNumber = coInvPaymentRec.AR_Credit_Number__c != null ? coInvPaymentRec.AR_Credit_Number__c : '';
        this.PrivateNote = 'AR credit ' + arCreditNumber + ' used as payment on ' + coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name;
    }
}