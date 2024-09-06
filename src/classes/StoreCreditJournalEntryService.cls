public without sharing class StoreCreditJournalEntryService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncStoreCredits(Set<Id> StoreCreditIds){
        AccSync_StoreCreditJournalEntry_Batch.runStoreCreditsForSync(StoreCreditIds, 10);
    }
    
    public static QBUtil.BatchResultWrapper syncAccountingServer(AccountingStoreCredit StoreCreditRecord, List<Store_Credit__c> StoreCreditListToUpdate){
    	List<Log__c> errorLogToInsert = new List<Log__c>();
    	if(QBUtil.isQBEnabled()) {
        	 errorLogToInsert = syncToQuickBooks(StoreCreditRecord, StoreCreditListToUpdate);
    	}
    	return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    
    public static List<Log__c> syncToQuickBooks(AccountingStoreCredit StoreCreditRecord, List<Store_Credit__c> StoreCreditListToUpdate){
        Store_Credit__c StoreCredit = new Store_Credit__c();
        StoreCredit.Id = StoreCreditRecord.StoreCreditId;
        List<Log__c> errorLogList = new List<Log__c>();
        try{
            if(StoreCreditRecord.JournalEntrySyncToken != null){
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks('journalentry', StoreCreditRecord.JournalEntryAccountingId);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('journalentry', StoreCreditRecord.JournalEntryAccountingId);
				HttpResponse getResponse = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200){ 
                    QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry StoreCreditJEGetResponce = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(getResponse.getBody(), QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    StoreCreditRecord.JournalEntrySyncToken = StoreCreditJEGetResponce.JournalEntry.SyncToken;
                } else {
                	errorLogList.add(new LogService().createErrorLog('StoreCreditJournalEntryService', 'syncToQuickBooks() - Get sync token Request From QuickBooks Online', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              StoreCreditRecord + LogService.METHOD_PARAM_SEPERATOR + StoreCreditListToUpdate, LogService.QUICKBOOKS, false));
                }
            }
            QBJournalEntryServiceHelper.QuickBooksJournalEntry QStoreCreditJE = new QBJournalEntryServiceHelper.QuickBooksJournalEntry(StoreCreditRecord);
            String StoreCreditJEJSONBody = System.JSON.serialize(QStoreCreditJE);
            //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks('journalentry', StoreCreditJEJSONBody);
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB('journalentry', StoreCreditJEJSONBody);
			HttpResponse res = responseObj.Response;
			refreshToken = responseObj.RefreshToken;
			refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
            System.debug(res);
            String response = StoreCreditJEJSONBody;
            if(res.getStatusCode() == 200){ 
                String resParams = res.getBody();
                QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry StoreCreditJEPostResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(resParams, QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                
                StoreCredit.AccountingId__c = StoreCreditJEPostResponse.JournalEntry.Id;
                StoreCredit.SyncToken__c = StoreCreditJEPostResponse.JournalEntry.SyncToken;
                response += '\n\n' + resParams;
                StoreCredit.availForQBSync__c = false;
                StoreCredit.accountingLastSyncTime__c = System.now(); 
            } else {
                response += res.getBody() + '\n\n' + res.getStatus();
                errorLogList.add(new LogService().createErrorLog('StoreCreditJournalEntryService', 'syncToQuickBooks() -  post request to save', res.getBody(), res.getStatusCode(), null, 
                                              StoreCreditRecord + LogService.METHOD_PARAM_SEPERATOR + StoreCreditListToUpdate, LogService.QUICKBOOKS, false));
            }
            StoreCredit.AccountingResponse__c = QBUtil.truncateString(response, 32768);
        } catch(Exception e) {
            StoreCredit.availForQBSync__c = true;
            StoreCredit.AccountingResponse__c = e.getMessage();
            errorLogList.add(new LogService().createErrorLog('StoreCreditJournalEntryService', 'syncToQuickBooks() - exception', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
        	                                  StoreCreditRecord + LogService.METHOD_PARAM_SEPERATOR + StoreCreditListToUpdate, LogService.QUICKBOOKS, false));
        }
        if(StoreCreditListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT){
            AccSync_StoreCreditJournalEntry_Batch.updateStoreCredits(StoreCreditListToUpdate);
            StoreCreditListToUpdate = new List<Store_Credit__c>();
        }
        StoreCreditListToUpdate.add(StoreCredit); 
        
        return errorLogList;
     }
}