/**
 * Author: Nidhi Sharma
 * Since: Feb 02, 2022
 * Name: PreferredPaymentIntegrationService
 * Description: Preferred payment integration service class.
**/
global without sharing class PreferredPaymentIntegrationService {

    private static IFW_IntegrationConfig__c parent; 
    private static String errorMessage; 
    public final static String PAYMENT_TERMINAL = 'Payment Terminal';
    public final static String SALE_TRANSACTION = 'Sale Transaction';
    public final static String VOID_TRANSACTION = 'Void Transaction';
    public final static String REFUND_TRANSACTION = 'Refund Transaction';
    public final static String CREDIT_TRANSACTION = 'Credit Transaction';
    public final static String integrationName = 'Preferred Payments'; //same as IFW config Integration name
    public final static String STATUS_DELETED = 'Deleted';
    public static List<Log__c> errorLogs = new List<Log__c>();

    //Validation error messages
    public final static String REQUIRED_PARAM_MISSING = 'Required parameters are missing.';
    public final static String AMOUNT_MUST_BE_GREATER_THAN_ZERO = 'Amount must be greater than zero.';
    public final static String TXN_CANT_BE_BLANK = 'Transaction Id cannot be blank, please authorize the payment before capturing it.';
    public final static String INVALID_TERMINAL_AND_TOKEN = 'Invalid terminal Id and token.';
    public final static String INTEGRATION_DISABLED = 'Preferred payment integration is disabled.';
    public final static String INTEGRATION_CONFIG_MISSING = 'Integration configurations are missing.';
    public final static String INVALID_PREFERRED_PAYMENT_ID = 'Invalid Preferred Payment Id';
    public final static String REFUND_AMOUNT_EXCEEDS_THE_LIMIT = 'Refund amount exceeds the limit set for Preferred Payments';
    
    webservice static String syncTerminal(String terminalId) {
        return postTerminal(terminalId);
    }

    webservice static String disconnectTerminal(String terminalId) {
        return deleteTerminal(terminalId);
    }

    public static String postTerminal(String paymentTerminalId) {
        if(String.isNotBlank(paymentTerminalId)) {
            for(Payment_Terminal__c terminal : [Select Id, Registration_Code__c, Nickname__c from Payment_Terminal__c where Id =: paymentTerminalId]) {
                IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(PAYMENT_TERMINAL, 'POST', integrationName);
                Map<String, String> payloadMap = new Map<String, String> {
                    'nickname' => terminal.Nickname__c,
                    'registration_code' => terminal.Registration_Code__c
                };
                HTTPResponse response = doCallout(child, System.JSON.serialize(payloadMap));
                handlePostTerminalResponse(terminal, response);
                updateValues();
            }
        }
        return errorMessage;
    }
	
	public static List<PreferredPaymentResponseWrapper.Terminal> getAllTerminals() {
        List<PreferredPaymentResponseWrapper.Terminal> terminals = getAllTerminalsAPICall();
    	updateValues();
    	return terminals;
    }
    
    public static List<PreferredPaymentResponseWrapper.Terminal> getAllTerminalsAPICall() {
    	IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(PAYMENT_TERMINAL, 'GET', integrationName);
        return handleGetAllTerminalsResponse(doCallout(child, null, true));
    }
    
    private static List<PreferredPaymentResponseWrapper.Terminal> handleGetAllTerminalsResponse(HTTPResponse response) {
    	if(response != null) {
            if((response.getStatusCode() == 200 || response.getStatusCode() == 201) && response.getBody() != null) {
                PreferredPaymentResponseWrapper responseObj = (PreferredPaymentResponseWrapper) System.JSON.deserialize(response.getBody(), PreferredPaymentResponseWrapper.class);
                if(responseObj.terminals.size() > 0) {
                    return responseObj.terminals;
                }
            } else {
                errorMessage = response.getBody();
            }
        }
        return new List<PreferredPaymentResponseWrapper.Terminal>();
    }
    
    private static void handlePostTerminalResponse(Payment_Terminal__c terminalRec, HTTPResponse response) {
        if(response != null) {
            PreferredPaymentResponseWrapper.Terminal terminalObj;
            if((response.getStatusCode() == 200 || response.getStatusCode() == 201) && response.getBody() != null && terminalRec != null) {
                PreferredPaymentResponseWrapper responseObj = (PreferredPaymentResponseWrapper) System.JSON.deserialize(response.getBody(), PreferredPaymentResponseWrapper.class);
                if(responseObj.terminals.size() > 0) {
                    saveTerminalDetail(responseObj.terminals[0], terminalRec);
                }
            } else if(response.getStatusCode() == 400 || response.getStatusCode() == 500) {
            	List<PreferredPaymentResponseWrapper.Terminal> terminals = getAllTerminalsAPICall();
            	
            	// Find terminal based On Nickname
            	for(PreferredPaymentResponseWrapper.Terminal terminal : terminals) {
            		if(terminal.nickname == terminalRec.Nickname__c) {
            			terminalObj = terminal;
            			break;
            		}
            	}
            	
            	// Save details if terminal found
            	if(terminalObj != null) {
            		saveTerminalDetail(terminalObj, terminalRec);
            	}
            	
            } else {
                errorMessage = (response.getStatusCode() == 401) ? 'Unauthorized. Please check public and private keys.' : response.getBody();
            }
        }
    }
    
    private static void saveTerminalDetail(PreferredPaymentResponseWrapper.Terminal terminalObj, Payment_Terminal__c terminal) {
        terminal.Preferred_Payment_Id__c = terminalObj.id;
        terminal.Serial_Number__c = terminalObj.serial_number;
        terminal.Status__c = terminalObj.status;
        terminal.Make__c = terminalObj.make;
        terminal.Model__c = terminalObj.model;
        DMLUtility.updateSobjectList('Payment_Terminal__c', terminal);
    }

    private static String deleteTerminal(String paymentTerminalId) {
        if(String.isNotBlank(paymentTerminalId)) {
            Payment_Terminal__c terminalRec = [Select Preferred_Payment_Id__c from Payment_Terminal__c where Id =: paymentTerminalId];
            if(String.isBlank(terminalRec.Preferred_Payment_Id__c)) return INVALID_PREFERRED_PAYMENT_ID;

            IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(PAYMENT_TERMINAL, 'DELETE', integrationName);
            if(child == null) return INTEGRATION_CONFIG_MISSING;
            child.Endpoint_URL__c = child.Endpoint_URL__c.replace('{{terminal_id}}', terminalRec.Preferred_Payment_Id__c);
            
            HTTPResponse response = doCallout(child, null);
            if(response != null) {
                if(response.getStatusCode() == 200 && terminalRec != null) {
                    handleDeleteTerminalResponse(terminalRec, response);
                } else {
                    errorMessage = INVALID_PREFERRED_PAYMENT_ID;
                }
            }
            updateValues();
        }
        return errorMessage;
    }

    private static void handleDeleteTerminalResponse(Payment_Terminal__c terminalRec, HTTPResponse response) {
        terminalRec.Preferred_Payment_Id__c = null;
        terminalRec.Serial_Number__c = null;
        terminalRec.Status__c = STATUS_DELETED;
        terminalRec.Make__c = null;
        terminalRec.Model__c = null;
        DMLUtility.updateSobjectList('Payment_Terminal__c', terminalRec);
    }

    public static String saleTransaction(PreferredPaymentService.PaymentDetail paymentDetailObj) {
        validateSaleTxnRequestParameters(paymentDetailObj);
        PreferredPaymentRequestWrapper.ProcessPaymentWrapper saleRequestObj = new PreferredPaymentRequestWrapper.ProcessPaymentWrapper(paymentDetailObj);
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(SALE_TRANSACTION, 'POST', integrationName);
        HttpResponse response = doCallout(child, System.JSON.serialize(saleRequestObj));
        return handlePaymentResponse(response);
    }

    private static void validateSaleTxnRequestParameters(PreferredPaymentService.PaymentDetail paymentDetailObj) {
        if(paymentDetailObj == null) {
            throw new BlackPurlException(REQUIRED_PARAM_MISSING);
        } else if(paymentDetailObj.Amount == null || paymentDetailObj.Amount <= 0) {
            throw new BlackPurlException(AMOUNT_MUST_BE_GREATER_THAN_ZERO);
        } else if(String.isBlank(paymentDetailObj.TerminalId) && String.isBlank(paymentDetailObj.Token)) {
            throw new BlackPurlException(INVALID_TERMINAL_AND_TOKEN);
        }
    }

    private static void validateAuthorizeTxnRequestParameters(PreferredPaymentService.PaymentDetail paymentDetailObj) {
        if(paymentDetailObj == null) {
            throw new BlackPurlException(REQUIRED_PARAM_MISSING);
        } else if(paymentDetailObj.Amount == null || paymentDetailObj.Amount <= 0) {
            throw new BlackPurlException(AMOUNT_MUST_BE_GREATER_THAN_ZERO);
        } else if(String.isBlank(paymentDetailObj.TerminalId) && String.isBlank(paymentDetailObj.Token)) {
            throw new BlackPurlException(INVALID_TERMINAL_AND_TOKEN);
        }
    }

    public static String refundTransaction(PreferredPaymentService.PaymentDetail paymentDetailObj) {
        validateTxnRequestParameters(paymentDetailObj);
        PreferredPaymentRequestWrapper.RefundTransactionWrapper refundRequestObj = new PreferredPaymentRequestWrapper.RefundTransactionWrapper(paymentDetailObj);
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(REFUND_TRANSACTION, 'POST', integrationName);
        HttpResponse response = doCallout(child, System.JSON.serialize(refundRequestObj));
        return handlePaymentResponse(response);
    }

    public static String voidTransaction(PreferredPaymentService.PaymentDetail paymentDetailObj) {
        validateTxnRequestParameters(paymentDetailObj);
        PreferredPaymentRequestWrapper.VoidTransactionWrapper voidRequestObj = new PreferredPaymentRequestWrapper.VoidTransactionWrapper(paymentDetailObj);
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(VOID_TRANSACTION, 'POST', integrationName);
        HttpResponse response = doCallout(child, System.JSON.serialize(voidRequestObj));
        return handlePaymentResponse(response);
    }

    public static String creditTransaction(PreferredPaymentService.PaymentDetail paymentDetailObj) {
        validateAuthorizeTxnRequestParameters(paymentDetailObj);
        if(paymentDetailObj.Amount > PreferredPaymentService.getRefundMaxCreditAmount()) {
            throw new BlackPurlException(REFUND_AMOUNT_EXCEEDS_THE_LIMIT);
        }
        PreferredPaymentRequestWrapper.ProcessPaymentWrapper creditRequestObj = new PreferredPaymentRequestWrapper.ProcessPaymentWrapper(paymentDetailObj);
        IFW_IntegrationConfigItem__c child = IntegrationServiceFactory.getIFWConfigItemByEntityName(CREDIT_TRANSACTION, 'POST', integrationName);
        HttpResponse response = doCallout(child, System.JSON.serialize(creditRequestObj));
        return handlePaymentResponse(response);
    }

    private static void validateTxnRequestParameters(PreferredPaymentService.PaymentDetail paymentDetailObj) {
        if(paymentDetailObj == null) {
            throw new BlackPurlException(REQUIRED_PARAM_MISSING);
        } else if(paymentDetailObj.Amount == null || paymentDetailObj.Amount <= 0) {
            throw new BlackPurlException(AMOUNT_MUST_BE_GREATER_THAN_ZERO);
        } else if(String.isBlank(paymentDetailObj.TxnId)) {
            throw new BlackPurlException(TXN_CANT_BE_BLANK);
        }
    }

    private static String handlePaymentResponse(HTTPResponse response) {
        String txnId;
        if(response != null && (response.getStatusCode() == 200 || response.getStatusCode() == 201)) {
            PreferredPaymentResponseWrapper.PaymentResponseWrapper responseObj = (PreferredPaymentResponseWrapper.PaymentResponseWrapper) System.JSON.deserialize(response.getBody(), PreferredPaymentResponseWrapper.PaymentResponseWrapper.class);   
            if(String.isNotBlank(responseObj.response_code) && responseObj.response_code.equalsIgnoreCase('APPROVED') && String.isNotBlank(responseObj.transaction_id)) {
                txnId = responseObj.transaction_id;
            } else {
                String apiErrorMessage = responseObj.response_text;
                List<String> errorMessageList = new List<String>();
                if(responseObj.errors != null && responseObj.errors.size() > 0) {
                    for(PreferredPaymentResponseWrapper.ErrorWrapper errorObj : responseObj.errors) {
                        errorMessageList.add(errorObj.message);
                    }
                    apiErrorMessage = String.join(errorMessageList, '\n');
                }
                apiErrorMessage = String.isBlank(apiErrorMessage) ? responseObj.metadata.somestuff : apiErrorMessage;
                throw new BlackPurlException(apiErrorMessage);
            }
        } else {
            throw new BlackPurlException(response != null ? response.getBody() : errorMessage);
        }
        return txnId;
    }
	
	private static HttpResponse doCallout(IFW_IntegrationConfigItem__c child, String body) {
		return doCallout(child, body, false);
	}
	
    private static HttpResponse doCallout(IFW_IntegrationConfigItem__c child, String body, Boolean byPassIntegrationEnableState) {
        HttpResponse response;
        errorMessage = null;
    	try {
            if(!byPassIntegrationEnableState && !GeneralConfiguration.isPreferredPaymentIntegrationEnabled()) {
                throw new BlackPurlException(INTEGRATION_DISABLED);
            }
	        if(parent == null) parent = IntegrationServiceFactory.getIFWConfigByIntegrationName(integrationName); 
            if(parent == null || child == null)  throw new BlackPurlException(INTEGRATION_CONFIG_MISSING);
            // Perform callout
            response = BaseIntegration.performCallout(parent, child, body, getHeaderList());
        } catch (Exception e) {
            errorMessage = e.getMessage();
            errorLogs.add(new LogService().createErrorLog('PreferredPaymentIntegrationService', 'doCallout()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
				String.valueOf(child) + body, integrationName, false, 'Error'));
        }
		return response;
    }

    private static List<CustomHttpHeaderWrapper> getHeaderList() {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(new CustomHttpHeaderWrapper('X-API-Key', parent.Bearer_Token__c));
        headerList.add(new CustomHttpHeaderWrapper('Content-Type', 'application/json'));
        return headerList;
    }

    public static void updateValues() {
        if(BaseIntegration.webServiceLogs != null && BaseIntegration.webServiceLogs.size() > 0) {
			DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        }
        if(errorLogs != null && errorLogs.size() > 0) {
			DMLUtility.insertSobjectList('Log__c', errorLogs);
        }
    }
}