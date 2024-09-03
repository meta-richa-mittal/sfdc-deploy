/**
 * Author: Nidhi Sharma
 * Since: Oct 10, 2017 
 * Name: PrintCashReconciliationCtrl
 * Description: Used to handle all print related work related to Cash Reconciliation
**/
global without sharing class PrintCashReconciliationCtrl {
	
    global PrintCashReconciliationCtrl (NewHomePageCtrl controller){
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    public String dateFormat { get{ return BPUtility.getDateFormat();}private set;}
    public static String Application{get;set;}
    public static String Assests{get;set;}
    public static String Application_Images{get;set;}
    public String reconciledDateStr {get;private set;}
    public String cashDrawerId {get;private set;}
    public CashReconciliationDetail CashReconciliationObj{get; private set;}
    
    public PrintCashReconciliationCtrl() {
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    @RemoteAction
    global static String getCashReconciliationDetailsForTransactionView(String dateStr) {
		dateStr = BPUtility.getDecodedString(dateStr);
    	try {
	    	DateTime dtValue = DateTimeUtility.getGMTDateTimeFromFormattedDateStr(dateStr);
	    	List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
    		List<CashReconciliationTTWrapper> reconciliatioTTObjList = CashReconciliationService.getTransactionTypeDetails(dtValue);
    		CashReconciliationDetail reconciliationObj = new CashReconciliationDetail(dtValue, businessProfileList, null, reconciliatioTTObjList);
	        return BPUtility.getEncodedString(system.JSON.serialize(reconciliationObj));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
	}
    
    @RemoteAction
    global static String getCashReconciliationDetails(String dateStr, String cashDrawerId) {
		dateStr = BPUtility.getDecodedString(dateStr);
    	cashDrawerId = BPUtility.getDecodedString(cashDrawerId);
    	try {
	    	DateTime dtValue = DateTimeUtility.getGMTDateTimeFromFormattedDateStr(dateStr);
	    	List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
	        ReconciliationWrapper reconciliationWrapperObj = CashReconciliationService.getReconciliationDetails(dtValue, cashDrawerId, true);
	        CashReconciliationDetail reconciliationObj = new CashReconciliationDetail(dtValue, businessProfileList, reconciliationWrapperObj, null);
            return BPUtility.getEncodedString(system.JSON.serialize(reconciliationObj));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
	}
    
     public class CashReconciliationDetail {
     	public String ReconciliationDate{get; private set;}
     	public CustomerDetail.Company CompanyInfo {get; set;}
     	public ReconciliationWrapper ReconciliationObj{get; private set;}
     	public List<CashReconciliationTTWrapper> ReconciliatioTTObjList{get; private set;}
     	
     	public CashReconciliationDetail(DateTime dtValue, List<Business_Profile__c> businessProfileList, ReconciliationWrapper reconciliationWrapperObj, List<CashReconciliationTTWrapper> reconciliatioTTObjList) {
     		this.ReconciliationDate = (dtValue != null) ? (dtValue.formatGMT('EEEE') + ' ' + dtValue.formatGMT('dd MMMM YYYY')) : '';
     		if(businessProfileList.size() > 0) {
                this.CompanyInfo = new CustomerDetail.Company(businessProfileList[0]);
            } else {
                this.CompanyInfo = new CustomerDetail.Company(new Business_Profile__c());
            }
            this.CompanyInfo.BusinessPhone = this.CompanyInfo.FormattedBusinessPhone != null ? this.CompanyInfo.FormattedBusinessPhone: '';
            this.ReconciliationObj = (reconciliationWrapperObj != null ? reconciliationWrapperObj: null);
            this.ReconciliatioTTObjList = (reconciliatioTTObjList != null ? reconciliatioTTObjList: null);
     	}
     }
}