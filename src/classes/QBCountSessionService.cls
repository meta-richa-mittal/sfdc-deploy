public without sharing class QBCountSessionService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncCountSession(Set<Id> countSessionIds) {
        AccSync_CountSession_Batch.runCountSessionForSync(countSessionIds, 10);
    }
    
    public static QBUtil.BatchResultWrapper syncAccountingServer(AccountingCountSession countSessionRecord, List<Count_Session__c> countSessionListToUpdate) {
        List<Log__c> errorLogToInsert = new List<Log__c>();
        if(QBUtil.isQBEnabled()) {
            errorLogToInsert = syncToQuickBooks(countSessionRecord, countSessionListToUpdate);
        }
        return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    public static List<Log__c> syncToQuickBooks(AccountingCountSession countSessionRecord, List<Count_Session__c> countSessionListToUpdate) {
        Count_Session__c countSessionToUpdate = new Count_Session__c();
        countSessionToUpdate.Id = countSessionRecord.Id;
        List<Log__c> errorLogList = new List<Log__c>();
        try{
            if(countSessionRecord.AccountingSyncToken != null) {
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks('journalentry', countSessionRecord.QBAccountingId);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('journalentry', countSessionRecord.QBAccountingId);
				HttpResponse getResponse = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200){ 
                    QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry journalEntryGetResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(getResponse.getBody(), QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    countSessionRecord.AccountingSyncToken = journalEntryGetResponse.JournalEntry.SyncToken;
                } else {
                    errorLogList.add(new LogService().createErrorLog('QBCountSessionService', 'syncToQuickBooks()', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              countSessionRecord + LogService.METHOD_PARAM_SEPERATOR + countSessionListToUpdate, LogService.QUICKBOOKS, false));
                }
            }
            QBJournalEntryServiceHelper.QuickBooksJournalEntry qbJournalEntry = new QBJournalEntryServiceHelper.QuickBooksJournalEntry(countSessionRecord);
            String countSessionJSONBody = System.JSON.serialize(qbJournalEntry);
            String response  = countSessionJSONBody;
            //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks('journalentry', countSessionJSONBody);
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB('journalentry', countSessionJSONBody);
			HttpResponse res = responseObj.Response;
			refreshToken = responseObj.RefreshToken;
			refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
            if(res.getStatusCode() == 200) { 
                String resParams = res.getBody();
                QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry journalEntryPostResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(resParams, QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                countSessionToUpdate.QB_Accounting_Id__c = journalEntryPostResponse.JournalEntry.Id;
                countSessionToUpdate.Accounting_Sync_Token__c = journalEntryPostResponse.JournalEntry.SyncToken;
                response += '\n\n'+resParams; 
                countSessionToUpdate.Available_For_QB_Sync__c = false;
                countSessionToUpdate.Accounting_Last_Sync_Time__c = System.now(); 
            } else {
                response += '\n\n'+res.getBody();
                response += '\n\n'+res.getStatus();
                errorLogList.add(new LogService().createErrorLog('QBCountSessionService', 'syncToQuickBooks()', res.getBody(), res.getStatusCode(), null, 
                                              countSessionRecord + LogService.METHOD_PARAM_SEPERATOR + countSessionListToUpdate, LogService.QUICKBOOKS, false));
            }
            countSessionToUpdate.Accounting_Response__c = response.length() > 32768 ?  response.subString(response.length() - 32768,  response.length()) : response;

        } catch(Exception e) {
            countSessionToUpdate.Available_For_QB_Sync__c = true;
            countSessionToUpdate.Accounting_Response__c = e.getMessage();
            errorLogList.add(new LogService().createErrorLog('QBCountSessionService', 'syncToQuickBooks()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              countSessionRecord + LogService.METHOD_PARAM_SEPERATOR + countSessionListToUpdate, LogService.QUICKBOOKS, false));
        }
        if(countSessionListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT) {
            AccSync_CountSession_Batch.updateCountSession(countSessionListToUpdate);
            countSessionListToUpdate = new List<Count_Session__c>();
        }
        countSessionListToUpdate.add(countSessionToUpdate);
        
        return errorLogList;
    }
}