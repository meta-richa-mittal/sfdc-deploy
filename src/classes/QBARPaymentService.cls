public without sharing class QBARPaymentService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncARPayments(Set<Id> poaIdsForARPayment) {
        AccSync_ARPayment_Batch.runARPaymentForSync(poaIdsForARPayment, 10);
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
            if(paymentOnAccountRecord.QBARPaymentSyncToken != null) {
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks('payment', paymentOnAccountRecord.QBARPaymentAccountingId);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('payment', paymentOnAccountRecord.QBARPaymentAccountingId);
		        HttpResponse getResponse = responseObj.Response;
		        refreshToken = responseObj.RefreshToken;
		        refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200) {
                	COInvoicePaymentService.ResponseQuickBooksCOInvoicePayment coInvoicePaymentGetResponce = (COInvoicePaymentService.ResponseQuickBooksCOInvoicePayment)System.JSON.deserialize(getResponse.getBody(), COInvoicePaymentService.ResponseQuickBooksCOInvoicePayment.class);
                    paymentOnAccountRecord.QBARPaymentSyncToken = coInvoicePaymentGetResponce.Payment.SyncToken;
                } else {
                    errorLogList.add(new LogService().createErrorLog('QBARPaymentService', 'syncToQuickBooks()', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              paymentOnAccountRecord + LogService.METHOD_PARAM_SEPERATOR + paymentOnAccountListToUpdate, LogService.QUICKBOOKS, false));
                }
            }
            
            COInvoicePaymentService.QuickBooksCOInvoicePayment qbPayment = new COInvoicePaymentService.QuickBooksCOInvoicePayment(paymentOnAccountRecord);
            String qbPaymentJSONBody = System.JSON.serialize(qbPayment);
            String response  = qbPaymentJSONBody;
            //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks('payment', qbPaymentJSONBody);
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB('payment', qbPaymentJSONBody);
	        HttpResponse res = responseObj.Response;
	        refreshToken = responseObj.RefreshToken;
	        refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
            if(res.getStatusCode() == 200) { 
                String resParams = res.getBody();
                COInvoicePaymentService.ResponseQuickBooksCOInvoicePayment qbPaymentPostResponse = (COInvoicePaymentService.ResponseQuickBooksCOInvoicePayment)System.JSON.deserialize(resParams, COInvoicePaymentService.ResponseQuickBooksCOInvoicePayment.class);
                paymentOnAccountToUpdate.QB_AR_Payment_Accounting_Id__c = qbPaymentPostResponse.Payment.Id;
                paymentOnAccountToUpdate.QB_AR_Payment_Sync_Token__c = qbPaymentPostResponse.Payment.SyncToken;
                response += '\n\n'+resParams; 
                paymentOnAccountToUpdate.Available_For_QB_AR_Payment_Sync__c = false;
                paymentOnAccountToUpdate.QB_AR_Payment_Last_Sync_Time__c = System.now(); 
            } else {
                response += '\n\n'+res.getBody();
                response += '\n\n'+res.getStatus();
                errorLogList.add(new LogService().createErrorLog('QBARPaymentService', 'syncToQuickBooks()', res.getBody(), res.getStatusCode(), null, 
                                              paymentOnAccountRecord + LogService.METHOD_PARAM_SEPERATOR + paymentOnAccountListToUpdate, LogService.QUICKBOOKS, false));
            }
            paymentOnAccountToUpdate.QB_AR_Payment_Accounting_Response__c = QBUtil.truncateString(response, 10000);
        } catch(Exception e) {
            paymentOnAccountToUpdate.Available_For_QB_AR_Payment_Sync__c = true;
            paymentOnAccountToUpdate.QB_AR_Payment_Accounting_Response__c = e.getMessage();
            errorLogList.add(new LogService().createErrorLog('QBARPaymentService', 'syncToQuickBooks()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              paymentOnAccountRecord + LogService.METHOD_PARAM_SEPERATOR + paymentOnAccountListToUpdate, LogService.QUICKBOOKS, false));
        }
        if(paymentOnAccountListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT) {
            AccSync_ARPayment_Batch.updatePaymentOnAccount(paymentOnAccountListToUpdate);
            paymentOnAccountListToUpdate = new List<Payment_on_Account__c>();
        }
        paymentOnAccountListToUpdate.add(paymentOnAccountToUpdate);
        
        return errorLogList;
    }
}