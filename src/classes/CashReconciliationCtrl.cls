/**
 * Author: Tarun Khandelwal
 * Since: Oct 10, 2017 
 * Name: CashReconciliationCtrl
 * Description: Used to handle all business logic related to Cash Reconciliation
**/
global without sharing class CashReconciliationCtrl {
    
    public string schedulingDateFormat { 
        get {
            return Constants.localeToschedulingDateFmtMap.containsKey(UserInfo.getLocale())? 
                    Constants.localeToschedulingDateFmtMap.get(UserInfo.getLocale()) : 
                    Constants.localeToschedulingDateFmtMap.get('en_AU'); 
            } 
        private set;
    }
    global CashReconciliationCtrl (NewHomePageCtrl controller){}
    public CashReconciliationCtrl() {}
	
    @RemoteAction
	global static String getCashDrawerReconciliationByDrawerId(String reconciledDateStr, String cashDrawerId) {
		reconciledDateStr = BPUtility.getDecodedString(reconciledDateStr);
    	cashDrawerId = BPUtility.getDecodedString(cashDrawerId);
    	try{
	    	DateTime dtValue = DateTimeUtility.getGMTDateTimeFromFormattedDateStr(reconciledDateStr);
	        ReconciliationWrapper reconciliationWrapperRec = CashReconciliationService.getReconciliationDetails(dtValue, cashDrawerId, true);
	        return BPUtility.getEncodedString(system.JSON.serialize(reconciliationWrapperRec));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
	}
    
    @RemoteAction
    global static String getReconciliationList(String reconciledDateStr, String viewName) {
    	reconciledDateStr = BPUtility.getDecodedString(reconciledDateStr);
    	viewName = BPUtility.getDecodedString(viewName);
	    try {
	        DateTime dtValue = DateTimeUtility.getGMTDateTimeFromFormattedDateStr(reconciledDateStr);
	    	if(viewName == 'Drawer') {
	    		return BPUtility.getEncodedString(system.JSON.serialize(CashReconciliationService.getReconciliationDetails(dtValue, null, false)));
	    	} else if(viewName == 'Transaction Type') {
	    		return BPUtility.getEncodedString(system.JSON.serialize(CashReconciliationService.getTransactionTypeDetails(dtValue)));
	    	}
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return '{}';
    }
    
    @RemoteAction
    global static String getMinicalenderData(String selectedJSONStr) {
        return '{}';
    }
    
    @RemoteAction
	global static String getCashDrawerReconciliationPaymentsByDrawerId(String reconciledDateStr, String cashDrawerId) {
		reconciledDateStr = BPUtility.getDecodedString(reconciledDateStr);
    	cashDrawerId = BPUtility.getDecodedString(cashDrawerId);
    	try{
	    	DateTime dtValue = DateTimeUtility.getGMTDateTimeFromFormattedDateStr(reconciledDateStr);
	        return BPUtility.getEncodedString(system.JSON.serialize(CashReconciliationService.getCashDrawerReconciliationPaymentsByDrawerId(dtValue, cashDrawerId)));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
	}
    
    @RemoteAction
    global static String getMiniCalenderDataByDrawerId(String selectedJSONStr, String cashDrawerId) {
    	selectedJSONStr = BPUtility.getDecodedString(selectedJSONStr);
    	cashDrawerId = BPUtility.getDecodedString(cashDrawerId);
		List<ReconciliationWrapper.ReconciliationInfo> reconciliationInfoList = CashReconciliationService.getMiniCalenderData(selectedJSONStr, cashDrawerId);
		return BPUtility.getEncodedString(system.JSON.serialize(reconciliationInfoList));
    }
       
    @RemoteAction
    global static String saveReconciliation(String jsonStr, String gridName) {
    	jsonStr = BPUtility.getDecodedString(jsonStr);
    	try {
    		CashReconciliationService.saveReconciliation(jsonStr);
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    	return 'Success';
    }

	@RemoteAction
    global static String validateReopening(String cashReconId) {
        try {
        	return BPUtility.getEncodedString(System.JSON.serialize(new ReopenCashReconciliationService().validateReopening(BPUtility.getDecodedString(cashReconId))));
        } catch(Exception e) {
            ReopenCOValidationWrapper reopenValidationWrapperObj = new ReopenCOValidationWrapper();
        	reopenValidationWrapperObj.ErrorMsg = e.getMessage();
            return BPUtility.getEncodedString(System.JSON.serialize(reopenValidationWrapperObj, true));
        }
    }

    @RemoteAction
    global static String reopenCashReconciliation(String cashReconId) {
        cashReconId = BPUtility.getDecodedString(cashReconId);
        try {
        	return BPUtility.getEncodedString(System.JSON.serialize(new ReopenCashReconciliationService().reopenCashReconciliation(cashReconId), true));
        } catch(Exception e) {
            new LogService().createErrorLog('CashReconciliationCtrl', 'reopenCashReconciliation()', e.getMessage(), null, e.getStackTraceString(), 
            cashReconId, LogService.REOPEN_INVOICE, true, 'Info');
            return 'error';
        }
    }

	@RemoteAction
    global static String getCashReconciliationJE(String cashReconId) {
		return BPUtility.getEncodedString(System.JSON.serialize(CashReconciliationService.getCashReconciliationJE(BPUtility.getDecodedString(cashReconId)), true));
    }

    @RemoteAction
    global static Boolean isNewPaymentAccountingApplicable(String cashReconId) {
		return CashReconciliationService.isNewPaymentAccountingApplicable(BPUtility.getDecodedString(cashReconId));
    }
}