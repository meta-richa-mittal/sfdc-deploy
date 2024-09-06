public without sharing class QBPaymentOnAccountService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncPaymentsOnAccount(Set<Id> paymentOnAccountIds) {
        AccSync_PaymentOnAccount_Batch.runPaymentOnAccountForSync(paymentOnAccountIds, 10);
    }
    
    public static QBUtil.BatchResultWrapper syncAccountingServer(AccountingPaymentOnAccount paymentOnAccountRecord, List<Payment_on_Account__c> paymentOnAccountListToUpdate) {
        List<Log__c> errorLogToInsert = new List<Log__c>();
        if(QBUtil.isQBEnabled()) {
            errorLogToInsert = syncToQuickBooks(paymentOnAccountRecord, paymentOnAccountListToUpdate);
        }
        return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    public static List<Log__c> syncToQuickBooks(AccountingPaymentOnAccount paymentOnAccountRecord, List<Payment_on_Account__c> paymentOnAccountListToUpdate) {
        Payment_on_Account__c paymentOnAccountToUpdate = new Payment_on_Account__c();
        paymentOnAccountToUpdate.Id = paymentOnAccountRecord.Id;
        List<Log__c> errorLogList = new List<Log__c>();
        try{
            if(paymentOnAccountRecord.AccountingSyncToken != null) {
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks('journalentry', paymentOnAccountRecord.QBAccountingId);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('journalentry', paymentOnAccountRecord.QBAccountingId);
				HttpResponse getResponse = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200){ 
                    QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry journalEntryGetResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(getResponse.getBody(), QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    paymentOnAccountRecord.AccountingSyncToken = journalEntryGetResponse.JournalEntry.SyncToken;
                } else {
                    errorLogList.add(new LogService().createErrorLog('QBPaymentOnAccountService', 'syncToQuickBooks()', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              paymentOnAccountRecord + LogService.METHOD_PARAM_SEPERATOR + paymentOnAccountListToUpdate, LogService.QUICKBOOKS, false));
                }
            }
            QBJournalEntryServiceHelper.QuickBooksJournalEntry qbJournalEntry = new QBJournalEntryServiceHelper.QuickBooksJournalEntry(paymentOnAccountRecord);
            String paymentOnAccountJSONBody = System.JSON.serialize(qbJournalEntry);
            String response  = paymentOnAccountJSONBody;
            //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks('journalentry', paymentOnAccountJSONBody);
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB('journalentry', paymentOnAccountJSONBody);
			HttpResponse res = responseObj.Response;
			refreshToken = responseObj.RefreshToken;
			refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
            if(res.getStatusCode() == 200) { 
                String resParams = res.getBody();
                QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry journalEntryPostResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(resParams, QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                paymentOnAccountToUpdate.QB_Accounting_Id__c = journalEntryPostResponse.JournalEntry.Id;
                paymentOnAccountToUpdate.Accounting_Sync_Token__c = journalEntryPostResponse.JournalEntry.SyncToken;
                response += '\n\n'+resParams; 
                paymentOnAccountToUpdate.Available_For_QB_Sync__c = false;
                paymentOnAccountToUpdate.Accounting_Last_Sync_Time__c = System.now(); 
            } else {
                response += '\n\n'+res.getBody();
                response += '\n\n'+res.getStatus();
                errorLogList.add(new LogService().createErrorLog('QBPaymentOnAccountService', 'syncToQuickBooks()', res.getBody(), res.getStatusCode(), null, 
                                              paymentOnAccountRecord + LogService.METHOD_PARAM_SEPERATOR + paymentOnAccountListToUpdate, LogService.QUICKBOOKS, false));
            }
            paymentOnAccountToUpdate.Accounting_Response__c = QBUtil.truncateString(response, 10000);
        } catch(Exception e) {
            paymentOnAccountToUpdate.Available_For_QB_Sync__c = true;
            paymentOnAccountToUpdate.Accounting_Response__c = e.getMessage();
            errorLogList.add(new LogService().createErrorLog('QBPaymentOnAccountService', 'syncToQuickBooks()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              paymentOnAccountRecord + LogService.METHOD_PARAM_SEPERATOR + paymentOnAccountListToUpdate, LogService.QUICKBOOKS, false));
        }
        if(paymentOnAccountListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT) {
            AccSync_PaymentOnAccount_Batch.updatePaymentOnAccount(paymentOnAccountListToUpdate);
            paymentOnAccountListToUpdate = new List<Payment_on_Account__c>();
        }
        paymentOnAccountListToUpdate.add(paymentOnAccountToUpdate);
        
        return errorLogList;
    }
}