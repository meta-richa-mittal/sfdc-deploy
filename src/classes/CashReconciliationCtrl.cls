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
    	return '{}';
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
    	/*selectedJSONStr = BPUtility.getDecodedString(selectedJSONStr);
    	try {
    		List<ReconciliationWrapper.ReconciliationInfo> reconciliationInfoList = CashReconciliationService.getMinicalenderData(selectedJSONStr, null);
    		return BPUtility.getEncodedString(system.JSON.serialize(reconciliationInfoList));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }*/
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
    	return '{}';
	}
    
    @RemoteAction
    global static String getMiniCalenderDataByDrawerId(String selectedJSONStr, String cashDrawerId) {
    	selectedJSONStr = BPUtility.getDecodedString(selectedJSONStr);
    	cashDrawerId = BPUtility.getDecodedString(cashDrawerId);
    	//try {
    		List<ReconciliationWrapper.ReconciliationInfo> reconciliationInfoList = CashReconciliationService.getMiniCalenderData(selectedJSONStr, cashDrawerId);
    		return BPUtility.getEncodedString(system.JSON.serialize(reconciliationInfoList));
    	/*} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return '{}';*/
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
}