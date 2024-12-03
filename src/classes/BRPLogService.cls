/**
 * Author: Richa Mittal
 * Since: June 19, 2020
 * Name: BRPLogService
 * Description: Apex class to insert BRP log.
**/
public without sharing class BRPLogService {
	public String entityName;
	public String requestParams;
	public String requestBODId;
	public String responseBODId;
	public String responseCode;
	public String errorMessages;
	public String logType;
	public String apexClass;
	public String method;
	
	public BRPLogService() {}
	
	public BRPLogService(String entityName, String requestParams, String requestBODId, String responseBODId, String responseCode, String errorMessages, String logType, 
							String apexClass, String method) {
		this.entityName = entityName;
		this.requestParams = requestParams;
		this.requestBODId = requestBODId;
		this.responseBODId = responseBODId;
		this.responseCode = responseCode;
		this.errorMessages = errorMessages;
		this.logType = logType;
		this.apexClass = apexClass;
		this.method = method;
	}
	
	public BRP_Log__c sampleLog() {
		BRP_Log__c logRec = setLogFields();
        return logRec;
    }
	
    public BRP_Log__c sampleLog(String entityName, String requestParams, String requestBODId, String responseBODId, String responseCode, String errorMessages, String logType, 
									String apexClass, String method, String coInvoiceHeaderId) {
		BRP_Log__c logRec = setLogFields(entityName, requestParams, requestBODId, responseBODId, responseCode, errorMessages, logType, apexClass, method, coInvoiceHeaderId);
        return logRec;
    }
    
    public BRP_Log__c createLog() {
    	BRP_Log__c logRec = sampleLog();
    	try {
			DMLUtility.insertSobjectList('BRP_Log__c', logRec);
        } catch(Exception e) {
        	system.debug('Exception while inserting BRP logs' + logRec + ' with exception ' + e.getMessage());
        }
		return logRec;
    }
    
    public BRP_Log__c createLog(String entityName, String requestParams, String requestBODId, String responseBODId, String responseCode, String errorMessages, String logType, 
									String apexClass, String method, String coInvoiceHeaderId) {
		BRP_Log__c logRec = setLogFields(entityName, requestParams, requestBODId, responseBODId, responseCode, errorMessages, logType, apexClass, method, coInvoiceHeaderId);
        DMLUtility.insertSobjectList('BRP_Log__c', logRec);
        return logRec;
    }
    
    private BRP_Log__c setLogFields() {
    	BRP_Log__c logRec = new BRP_Log__c();
    	logRec.Entity_Name__c = entityName;
    	logRec.Request_Params__c = (requestParams != null && requestParams.length() > 131072) ? requestParams.subString(0, 131072) : requestParams;
		logRec.Request_BOD_Id__c = requestBODId;
        logRec.Response_BOD_Id__c = responseBODId;
        logRec.Response_Code__c = responseCode;
        logRec.Error_Messages__c = (errorMessages != null && errorMessages.length() > 131072) ? errorMessages.subString(0, 131072) : errorMessages;
        logRec.Type__c = logType != null ? logType : 'Error';
        logRec.Apex_Class__c = apexClass;
        return logRec;
    }
    
    private BRP_Log__c setLogFields(String entityName, String requestParams, String requestBODId, String responseBODId, String responseCode, String errorMessages, String logType, 
										String apexClass, String method, String coInvoiceHeaderId) {
    	BRP_Log__c logRec = new BRP_Log__c();
    	logRec.Entity_Name__c = entityName;
    	logRec.Request_Params__c = (requestParams != null && requestParams.length() > 131072) ? requestParams.subString(0, 131072) : requestParams;
		logRec.Request_BOD_Id__c = requestBODId;
        logRec.Response_BOD_Id__c = responseBODId;
        logRec.Response_Code__c = responseCode;
        logRec.Error_Messages__c = (errorMessages != null && errorMessages.length() > 131072) ? errorMessages.subString(0, 131072) : errorMessages;
        logRec.Type__c = logType != null ? logType : 'Error';
        logRec.CO_Invoice_Header__c = coInvoiceHeaderId;
        logRec.Apex_Class__c = apexClass;
        logRec.Method__c = method;
        return logRec;
    }
}