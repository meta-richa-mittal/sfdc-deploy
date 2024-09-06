public without sharing class QBHoursLoggedService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncHoursLogged(Set<Id> hoursLoggedIds) {
        AccSync_HoursLogged_Batch.runHoursLoggedForSync(hoursLoggedIds, 10);
    }
    
    public static QBUtil.BatchResultWrapper syncAccountingServer(AccountingHoursLogged hoursLoggedRecord, List<Hours_Logged__c> hoursLoggedListToUpdate) {
        List<Log__c> errorLogToInsert = new List<Log__c>();
        if(QBUtil.isQBEnabled()) {
            errorLogToInsert = syncToQuickBooks(hoursLoggedRecord, hoursLoggedListToUpdate);
        }
        return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    public static List<Log__c> syncToQuickBooks(AccountingHoursLogged hoursLoggedRecord, List<Hours_Logged__c> hoursLoggedListToUpdate) {
        Hours_Logged__c hoursLoggedRecToUpdate = new Hours_Logged__c();
        hoursLoggedRecToUpdate.Id = hoursLoggedRecord.Id;
        List<Log__c> errorLogList = new List<Log__c>();
        try{
            if(hoursLoggedRecord.AccountingSyncToken != null) {
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks('journalentry', hoursLoggedRecord.QBAccountingId);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('journalentry', hoursLoggedRecord.QBAccountingId);
				HttpResponse getResponse = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200){ 
                    QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry journalEntryGetResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(getResponse.getBody(), QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    hoursLoggedRecord.AccountingSyncToken = journalEntryGetResponse.JournalEntry.SyncToken;
                } else {
                    errorLogList.add(new LogService().createErrorLog('QBHoursLoggedService', 'syncToQuickBooks()', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              hoursLoggedRecord + LogService.METHOD_PARAM_SEPERATOR + hoursLoggedListToUpdate, LogService.QUICKBOOKS, false));
                }
            }
            QBJournalEntryServiceHelper.QuickBooksJournalEntry qbJournalEntry = new QBJournalEntryServiceHelper.QuickBooksJournalEntry(hoursLoggedRecord);
            String hoursLoggedJSONBody = System.JSON.serialize(qbJournalEntry);
            String response  = hoursLoggedJSONBody;
            //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks('journalentry', hoursLoggedJSONBody);
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB('journalentry', hoursLoggedJSONBody);
			HttpResponse res = responseObj.Response;
			refreshToken = responseObj.RefreshToken;
			refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
            if(res.getStatusCode() == 200) { 
                String resParams = res.getBody();
                QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry journalEntryPostResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(resParams, QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                hoursLoggedRecToUpdate.QB_Accounting_Id__c = journalEntryPostResponse.JournalEntry.Id;
                hoursLoggedRecToUpdate.Accounting_Sync_Token__c = journalEntryPostResponse.JournalEntry.SyncToken;
                response += '\n\n'+resParams; 
                hoursLoggedRecToUpdate.Available_For_QB_Sync__c = false;
                hoursLoggedRecToUpdate.Accounting_Last_Sync_Time__c = System.now(); 
            } else {
                response += '\n\n'+res.getBody();
                response += '\n\n'+res.getStatus();
                errorLogList.add(new LogService().createErrorLog('QBHoursLoggedService', 'syncToQuickBooks()', res.getBody(), res.getStatusCode(), null, 
                                              hoursLoggedRecord + LogService.METHOD_PARAM_SEPERATOR + hoursLoggedListToUpdate, LogService.QUICKBOOKS, false));
            }
            hoursLoggedRecToUpdate.Accounting_Response__c = QBUtil.truncateString(response, 10000);
        } catch(Exception e) {
            hoursLoggedRecToUpdate.Available_For_QB_Sync__c = true;
            hoursLoggedRecToUpdate.Accounting_Response__c = e.getMessage();
            errorLogList.add(new LogService().createErrorLog('QBHoursLoggedService', 'syncToQuickBooks()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              hoursLoggedRecord + LogService.METHOD_PARAM_SEPERATOR + hoursLoggedListToUpdate, LogService.QUICKBOOKS, false));
        }
        if(hoursLoggedListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT) {
            AccSync_HoursLogged_Batch.updateHoursLogged(hoursLoggedListToUpdate);
            hoursLoggedListToUpdate = new List<Hours_Logged__c>();
        }
        hoursLoggedListToUpdate.add(hoursLoggedRecToUpdate);
        
        return errorLogList;
    }
}