public without sharing class QBUnitNITCJEService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
    public static Decimal refreshTokenExpiresIn;
    
    public static void syncUnitNITCJE(Set<Id> unitIds){
        AccSync_UnitNITCJE_Batch.runUnitNITCJEForSync(unitIds, 10);
    }
    
    public static QBUtil.BatchResultWrapper syncAccountingServer(AccountingUnit unitRecord, List<Customer_Owned_Unit__c> unitListToUpdate){
        List<Log__c> errorLogToInsert = new List<Log__c>();
        if(QBUtil.isQBEnabled()){
            errorLogToInsert = syncToQuickBooks(unitRecord, unitListToUpdate);
        }
        return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    public static List<Log__c> syncToQuickBooks(AccountingUnit unitRecord, List<Customer_Owned_Unit__c> unitListToUpdate){
        Customer_Owned_Unit__c skuRec = new Customer_Owned_Unit__c();
        skuRec.Id = unitRecord.Id;
        Boolean isAnyLineItemAvailableTOPostJEToQB = true;
        List<Log__c> errorLogList = new List<Log__c>();
        try {
            if(unitRecord.SyncTokenForUnitNITCJE != null){
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('journalentry', unitRecord.QBUnitNITCJEAccountingId);
                HttpResponse getResponse = responseObj.Response;
                refreshToken = responseObj.RefreshToken;
                refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200) { 
                    QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry unitNITCJEGetResponce = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(getResponse.getBody(), QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    unitRecord.SyncTokenForUnitNITCJE = unitNITCJEGetResponce.JournalEntry.SyncToken;
                } else {
                    errorLogList.add(new LogService().createErrorLog('QBUnitNITCJEService', 'syncToQuickBooks() - Get sync token Request From QuickBooks Online', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              unitRecord + LogService.METHOD_PARAM_SEPERATOR + unitListToUpdate, LogService.QUICKBOOKS, false));
                }
            }
            QBJournalEntryServiceHelper.QuickBooksJournalEntry QCIJE = new QBJournalEntryServiceHelper.QuickBooksJournalEntry(unitRecord, IntegrationUtility.UNIT_NITC_JE);
            if(QCIJE.line != null && QCIJE.line.size() == 0) {
                isAnyLineItemAvailableTOPostJEToQB = false;
                skuRec.Accounting_Response_NITC_JE__c = QBUtil.CO_INVOICE_NO_JE_MSG;
                skuRec.Available_For_QB_NITC_JE_Sync__c = false;
            } else {
                String unitNITCJEJSONBody = system.JSON.serialize(QCIJE);
                system.debug('*************'); 
                system.debug(unitNITCJEJSONBody);
                String response = unitNITCJEJSONBody;
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB('journalentry', unitNITCJEJSONBody);
                HttpResponse res = responseObj.Response;
                refreshToken = responseObj.RefreshToken;
                refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                System.debug(res);
                if(res.getStatusCode() == 200) { 
                    String resParams = res.getBody();
                    QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry unitNITCJEPostResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(resParams, QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    skuRec.QB_NITC_JE_Accounting_Id__c = unitNITCJEPostResponse.JournalEntry.Id;
                    skuRec.Sync_Token_For_NITC_JE__c = unitNITCJEPostResponse.JournalEntry.SyncToken;
                    response += '\n\n'+resParams; 
                    skuRec.Available_For_QB_NITC_JE_Sync__c = false;
                    skuRec.Accounting_Last_Sync_Time_NITC_JE__c = System.now(); 
                } else {
                    response += '\n\n'+res.getBody();
                    response += '\n\n'+res.getStatus();
                    errorLogList.add(new LogService().createErrorLog('QBUnitNITCJEService', 'syncToQuickBooks() -  post request to save', res.getBody(), res.getStatusCode(), null, 
                                                  unitRecord + LogService.METHOD_PARAM_SEPERATOR + unitListToUpdate, LogService.QUICKBOOKS, false));
                }
                skuRec.Accounting_Response_NITC_JE__c = QBUtil.truncateString(response, 131072); 
            }
        } catch(Exception e) {
            if(isAnyLineItemAvailableTOPostJEToQB) {
                skuRec.Available_For_QB_NITC_JE_Sync__c = true;
                skuRec.Accounting_Response_NITC_JE__c = e.getMessage();
                errorLogList.add(new LogService().createErrorLog('QBUnitNITCJEService', 'syncToQuickBooks() - exception', e.getMessage(),LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                  unitRecord + LogService.METHOD_PARAM_SEPERATOR + unitListToUpdate, LogService.QUICKBOOKS, false));
            } else {
                skuRec.Accounting_Response_NITC_JE__c = QBUtil.CO_INVOICE_NO_JE_MSG;
                skuRec.Available_For_QB_NITC_JE_Sync__c = false;
            }
        }
        if(unitListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT){
            AccSync_UnitNITCJE_Batch.updateUnitInvoices(unitListToUpdate);
            unitListToUpdate = new List<Customer_Owned_Unit__c>();
        }
        unitListToUpdate.add(skuRec); 
        
        return errorLogList;
    }
}