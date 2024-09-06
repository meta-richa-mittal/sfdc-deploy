public without sharing class QBUnitConsignmentService {
    
    public static final Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static List<Log__c> errorLogToInsert;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncUnitConsignment(Set<Id> consUnitIds) {
        AccSync_UnitConsignment_Batch.runConsignmentsForSync(consUnitIds, new Set<Id>(), 10);
    }
    
   	public static QBUtil.BatchResultWrapper syncAccountingServer(List<AccountingUnit> consUnitRecordList, List<Customer_Owned_Unit__c> consUnitListToUpdate) {
        errorLogToInsert = new List<Log__c>();
        if(QBUtil.isQBEnabled()) {
            syncToQuickBooks(consUnitRecordList, consUnitListToUpdate);
        }
        return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    public static void syncToQuickBooks(List<AccountingUnit> consUnitRecordList, List<Customer_Owned_Unit__c> consUnitListToUpdate) {
        if(consUnitRecordList == null || consUnitRecordList.size() == 0) {
            return;
        }
        
        Customer_Owned_Unit__c unitRec = new Customer_Owned_Unit__c();
        unitRec.Id = consUnitRecordList[0].Id;
        try {
        	String syncingObjectType = QBUtil.CREDIT_MEMO;
            if(String.isNotBlank(consUnitRecordList[0].SyncTokenForCons)) {
                String updatedSyncToken = getUpdatedSyncToken(syncingObjectType, consUnitRecordList[0].QBConsAccountingId);
                consUnitRecordList[0].SyncTokenForCons = updatedSyncToken;
            }
            
            String reqJSONBody = getConsJSONString(syncingObjectType, consUnitRecordList[0]);
            if(String.isBlank(reqJSONBody)) {
            	throw new BlackPurlException('No line item in Consignment.');
            }
            unitRec = syncConsToQB(consUnitRecordList, new List<Customer_Owned_Unit__c>{unitRec}, syncingObjectType, reqJSONBody);
        } catch(Exception e) {
            unitRec.Available_For_QB_Consignment_Sync__c = true;
            unitRec.Accounting_Response_Consignment__c = e.getMessage();
            errorLogToInsert.add(new LogService().createErrorLog('VendorInvoiceService', 'syncToQuickBooks() - exception', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              consUnitRecordList + LogService.METHOD_PARAM_SEPERATOR + consUnitListToUpdate, LogService.QUICKBOOKS, false));
        }
        
        if(consUnitListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT){
            AccSync_UnitConsignment_Batch.updateConsUnits(consUnitListToUpdate);
            consUnitListToUpdate = new List<Customer_Owned_Unit__c>();
        }
        consUnitListToUpdate.add(unitRec); 
    }
    
    private static Customer_Owned_Unit__c syncConsToQB(List<AccountingUnit> consUnitRecordList, List<Customer_Owned_Unit__c> unitRecList,
                                                         String syncingObjectType, String reqJSONBody) {
        if(consUnitRecordList == null  || unitRecList == null || consUnitRecordList.size() == 0 || unitRecList.size() == 0) {
        	return new Customer_Owned_Unit__c();
        }
        
        Customer_Owned_Unit__c unitRec = unitRecList[0];
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB(syncingObjectType, reqJSONBody);
		HttpResponse res = responseObj.Response;
		refreshToken = responseObj.RefreshToken;
		refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
        
        if(res.getStatusCode() == 200) { 
            String consResonseObj = res.getBody();
            if(syncingObjectType == QBUtil.CREDIT_MEMO) {
                QBResponseWrapper consPostResponse = (QBResponseWrapper)System.JSON.deserialize(consResonseObj, QBResponseWrapper.class);
                unitRec.QB_Consignment_Accounting_Id__c = consPostResponse.CreditMemo.Id;
		        unitRec.Sync_Token_For_Consignment__c = consPostResponse.CreditMemo.SyncToken;
		        unitRec.Available_For_QB_Consignment_Sync__c = false;
		        unitRec.Accounting_Last_Sync_Time_Consignment__c = system.now(); 
            }
        } else {
          errorLogToInsert.add(new LogService().createErrorLog('QBUnitConsignmentService', 'syncConsToQB() ' + syncingObjectType, res.getBody(), res.getStatusCode(), null, 
                                          consUnitRecordList[0] + LogService.METHOD_PARAM_SEPERATOR + unitRec + LogService.METHOD_PARAM_SEPERATOR + reqJSONBody, LogService.QUICKBOOKS, false));
        }
        String response = reqJSONBody + '\n\n\n' + res.getBody() + 
                                                    ((res.getStatusCode() != 200) ? ('\n\n'+ res.getStatus()) : '');
        unitRec.Accounting_Response_Consignment__c = QBUtil.truncateString(response, 131072);
        return unitRec;
    }
    
    private static String getConsJSONString(String syncingObjectType, AccountingUnit consUnitRecord) {
        String consUnitJSONBody = '';
        if(syncingObjectType == QBUtil.CREDIT_MEMO) {
            QBCreditMemoDTO dtoObj = new QBCreditMemoDTO(consUnitRecord);
            if(dtoObj.line != null && dtoObj.line.size() == 0){
                return null;
            }
            consUnitJSONBody = system.JSON.serialize(dtoObj);
        }
        return consUnitJSONBody;
    }
    
    private static String getUpdatedSyncToken(String syncingObjectType, String consAccId) {
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB(syncingObjectType, consAccId);
        HttpResponse consObj = responseObj.Response;
        refreshToken = responseObj.RefreshToken;
        refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
        String updatedSyncToken;
        if(consObj.getStatusCode() == 200) { 
             if(syncingObjectType == QBUtil.CREDIT_MEMO) {
                QBResponseWrapper getResponse = (QBResponseWrapper)System.JSON.deserialize(consObj.getBody(), QBResponseWrapper.class);
                updatedSyncToken = getResponse.CreditMemo.SyncToken;
            }
        } else {
            errorLogToInsert.add(new LogService().createErrorLog('QBUnitConsignmentService', 'getUpdatedSyncToken()', consObj.getBody(), consObj.getStatusCode(), null, 
                                              syncingObjectType + LogService.METHOD_PARAM_SEPERATOR + consAccId, LogService.QUICKBOOKS, false));
        }
        return updatedSyncToken;
    }
}