public without sharing class COInvoicePaymentService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    public static final String AR_PAYMENT = 'AR Payment';
    public static final String UNAPPLIED_PAYMENT = 'Unapplied Payment';
    
    public static CO_Invoice_Header__c syncAccountingServer(List<AccountingCustomerInvoice> COInvoiceRecordList, CO_Invoice_Header__c coInvoiceHeader) {
        return syncToQuickBooks(COInvoiceRecordList, coInvoiceHeader);
    }  
    
    public static CO_Invoice_Header__c syncToQuickBooks(List<AccountingCustomerInvoice> COInvoiceRecordList, CO_Invoice_Header__c coInvoiceHeader) {
        if(COInvoiceRecordList == null || COInvoiceRecordList.size() == 0) {
        	return new CO_Invoice_Header__c();
        }
        coInvoiceHeader.Id = COInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.COInvoiceHeaderId;
        List<Log__c> errorLogList = new List<Log__c>();
        try{
            if(COInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.COInvoicePaymentSyncToken != null) {
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks('payment', COInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.COInvoicePaymentAccountingId);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('payment', COInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.COInvoicePaymentAccountingId);
				HttpResponse getResponse = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200) { 
                    ResponseQuickBooksCOInvoicePayment COInvoicePaymentGetResponce = (ResponseQuickBooksCOInvoicePayment)System.JSON.deserialize(getResponse.getBody(), ResponseQuickBooksCOInvoicePayment.class);
                    COInvoiceRecordList[0].AccountingCOInvoiceHeaderRec.COInvoicePaymentSyncToken = COInvoicePaymentGetResponce.Payment.SyncToken;
                } else {
                	errorLogList.add(new LogService().createErrorLog('COInvoicePaymentService', 'syncToQuickBooks() - Get sync token Request From QuickBooks Online', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              COInvoiceRecordList[0] + LogService.METHOD_PARAM_SEPERATOR + coInvoiceHeader, LogService.QUICKBOOKS, false));
                }
            }
            QuickBooksCOInvoicePayment QCOInvPayment = new QuickBooksCOInvoicePayment(COInvoiceRecordList[0]);
            String COInvoicePaymentJSONBody = System.JSON.serialize(QCOInvPayment);
            if(decimal.valueOf(QCOInvPayment.TotalAmt) > 0) {
            	//HttpResponse res = QuickbookConnector.sendRequestToQuickBooks('payment', COInvoicePaymentJSONBody);
            	QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB('payment', COInvoicePaymentJSONBody);
				HttpResponse res = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
	            System.debug(res);
	            String response = COInvoicePaymentJSONBody;
	            if(res.getStatusCode() == 200) { 
	                String resParams = res.getBody();
	                ResponseQuickBooksCOInvoicePayment COInvoicePaymentPostResponse = (ResponseQuickBooksCOInvoicePayment)System.JSON.deserialize(resParams, ResponseQuickBooksCOInvoicePayment.class);
	                
	                coInvoiceHeader.AccountingIdForCOInvoicePayment__c = COInvoicePaymentPostResponse.Payment.Id;
	                coInvoiceHeader.SyncTokenForCOInvoicePayment__c = COInvoicePaymentPostResponse.Payment.SyncToken;
	                response += '\n\n' + resParams;
	                coInvoiceHeader.availForQBCOInvoicePayment__c = false;
	                coInvoiceHeader.accountingLastSyncTimeForCOInvPayment__c = System.now();
	            } else {
	                response += res.getBody() + '\n\n' + res.getStatus();
	                errorLogList.add(new LogService().createErrorLog('COInvoicePaymentService', 'syncToQuickBooks() -  post request to save', res.getBody(), res.getStatusCode(), null, 
                                              COInvoiceRecordList[0] + LogService.METHOD_PARAM_SEPERATOR + coInvoiceHeader, LogService.QUICKBOOKS, false));
	            }
	            coInvoiceHeader.AccountingResponseForCOInvoicePayment__c = QBUtil.truncateString(response, 131072);
            } else {
            	coInvoiceHeader.availForQBCOInvoicePayment__c = false;
	            coInvoiceHeader.accountingLastSyncTimeForCOInvPayment__c = System.now();
            }
            
        } catch(Exception e) {
            coInvoiceHeader.AccountingResponseForCOInvoicePayment__c = e.getMessage();
            errorLogList.add(new LogService().createErrorLog('COInvoicePaymentService', 'syncToQuickBooks() - exception', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              COInvoiceRecordList[0] + LogService.METHOD_PARAM_SEPERATOR + coInvoiceHeader, LogService.QUICKBOOKS, false));
        }
        
		if(errorLogList.size() > 0) {
            DMLUtility.insertSobjectList('Log__c', errorLogList);
        }
        if(refreshToken !=  null) {
			QBUtil.saveRefreshToken(refreshToken, refreshTokenExpiresIn);
		}
        return coInvoiceHeader;
        
     }

    /*
     *   START : Quickbooks Customer wrapper
     */
     public class QuickBooksCOInvoicePayment {
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
        
        public QuickBooksCOInvoicePayment(AccountingCustomerInvoice COInvoiceRecord) {
            this.Id = COInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoicePaymentAccountingId;
            this.SyncToken = COInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoicePaymentSyncToken;
            this.TxnDate = DateTimeUtility.getDateFromFormattedDateStr(COInvoiceRecord.AccountingCOInvoiceHeaderRec.ClosedInvoiceDate); 
            
            Decimal TotalInvoicePayment = 0;
            for(AccountingCOInvoicePayment coInvoicePaymentRec: COInvoiceRecord.AccountingCOInvoicePaymentsRecs) {
            	if(coInvoicePaymentRec.PaymentMethod != 'Charge Account') {
            		TotalInvoicePayment += coInvoicePaymentRec.Amount;
            	}
            }
            
            
            
            this.Line = new List<QuickBooksLineWrapper>();
            this.Line.add(new QuickBooksLineWrapper(COInvoiceRecord, TotalInvoicePayment));
            
            this.CustomerRef = new QuickBooksCustomerRefWrapper(COInvoiceRecord.AccountingCOInvoiceHeaderRec.customer);
            
            String customerDepositAccount = Accountingutil.getChartofAccount('Customer Deposits');
            this.DepositToAccountRef  = new DepositToAccountRefWrapper(customerDepositAccount);
            
            this.TotalAmt = String.valueOf(TotalInvoicePayment);
        }
        
        public QuickBooksCOInvoicePayment(AccountingPaymentOnAccount accPaymentOnAccountRecord) {
            this.Id = accPaymentOnAccountRecord.QBARPaymentAccountingId;
            this.SyncToken = accPaymentOnAccountRecord.QBARPaymentSyncToken;
            this.TxnDate = accPaymentOnAccountRecord.PaymentDate; 
            
            this.Line = new List<QuickBooksLineWrapper>();
            for(AccountingARPayment accountingARPaymentRec: accPaymentOnAccountRecord.AccountingARPaymentsRecs) {
            	if(accountingARPaymentRec.AmountPaid != 0) {
            		this.Line.add(new QuickBooksLineWrapper(accountingARPaymentRec));
            	}
            }
            
            this.CustomerRef = new QuickBooksCustomerRefWrapper(accPaymentOnAccountRecord.Customer.AccountingId);
            this.DepositToAccountRef  = new DepositToAccountRefWrapper(Accountingutil.getChartofAccount('Customer Deposits'));
            this.TotalAmt = String.valueOf(accPaymentOnAccountRecord.TotalPayment);
        }

        public QuickBooksCOInvoicePayment(SOBject arcrTxnRec) {
            String objName = String.valueOf(arcrTxnRec.getSObjectType());
            if(objName == Constants.NAMESPACE + 'CO_Deposit__c') {
                setARCRDepositData((CO_Deposit__c)arcrTxnRec);
            } else if(objName == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
                setARCRPaymentData((CO_Invoice_Payment__c)arcrTxnRec);
            }
        }

        private void setARCRDepositData(CO_Deposit__c depositRec) {
            this.TxnDate = depositRec.Payment_Date__c;
            depositRec.Amount__c = depositRec.Amount__c != null ? depositRec.Amount__c : 0;
            this.Line = new List<QuickBooksLineWrapper>();
            if(depositRec.Unapplied_Payment_Type__c == AR_PAYMENT) {
                this.Line.add(new QuickBooksLineWrapper(depositRec.Amount__c, depositRec.AR_Credit_Accounting_Id__c, 'Payment'));
            } else {
                this.Line.add(new QuickBooksLineWrapper(depositRec.Amount__c, depositRec.AR_Credit_Accounting_Id__c, 'CreditMemo'));
            }
            this.Line.add(new QuickBooksLineWrapper(depositRec.Amount__c, depositRec.AR_Credit_Invoice_Accounting_Id__c, 'Invoice'));

            this.CustomerRef = new QuickBooksCustomerRefWrapper(depositRec.CO_Header__r.Customer__r.AccountingId__c);
            this.DepositToAccountRef  = new DepositToAccountRefWrapper(Accountingutil.getChartofAccount('Customer Deposits'));
            this.TotalAmt = '0';
        }
    
        private void setARCRPaymentData(CO_Invoice_Payment__c coInvPaymentRec) {
            this.TxnDate = coInvPaymentRec.Payment_Date__c;
            coInvPaymentRec.Amount__c = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c : 0;
            this.Line = new List<QuickBooksLineWrapper>();
            if(coInvPaymentRec.Unapplied_Payment_Type__c == AR_PAYMENT) {
                this.Line.add(new QuickBooksLineWrapper(coInvPaymentRec.Amount__c, coInvPaymentRec.AR_Credit_Accounting_Id__c, 'Payment'));
            } else {
                this.Line.add(new QuickBooksLineWrapper(coInvPaymentRec.Amount__c, coInvPaymentRec.AR_Credit_Accounting_Id__c, 'CreditMemo'));
            }
            this.Line.add(new QuickBooksLineWrapper(coInvPaymentRec.Amount__c, coInvPaymentRec.AR_Credit_Invoice_Accounting_Id__c, 'Invoice'));

            this.CustomerRef = new QuickBooksCustomerRefWrapper(coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Customer__r.AccountingId__c);
            this.DepositToAccountRef  = new DepositToAccountRefWrapper(Accountingutil.getChartofAccount('Customer Deposits'));
            this.TotalAmt = '0';
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
     
     public class ResponseQuickBooksCOInvoicePayment{
        public QuickBooksCOInvoicePayment payment;
     }
     
     public class DepositToAccountRefWrapper{
        public String value;
        
        public DepositToAccountRefWrapper(String value){
        	this.value = value;
        }
     }
}