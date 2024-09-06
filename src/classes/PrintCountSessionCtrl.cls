/**
 * Author: Nikhil Kumar Srivastava
 * Since: September 11, 2019
 * Name: PrintCountSessionCtrl
 * Description: Used to handle all print related work related to Count Session
**/
global without sharing class PrintCountSessionCtrl {
    public static Integer QUERY_LIMIT_RECORDS = 2000;
	global PrintCountSessionCtrl (NewHomePageCtrl controller){
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    public String dateFormat { get{ return BPUtility.getDateFormat();}private set;}
    public static String Application{get;}
    public static String Assests{get;}
    public static String Application_Images{get;}
    public String countSessionId;
    
    public PrintCountSessionCtrl() {
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
    }

    @RemoteAction
    global static String getAllCountSessionLIBySessionIdAndTabName(String countSessionId, String tabName) {
        return '{}';
    }

    @RemoteAction
    global static String getAllCountSessionLIBySessionIdAndTabName_Update(String countSessionId, String tabName, String lastRecUniqueNameValue) {
    	countSessionId = BPUtility.getDecodedString(countSessionId);
    	tabName = BPUtility.getDecodedString(tabName);
        lastRecUniqueNameValue = BPUtility.getDecodedString(lastRecUniqueNameValue);
    	try {
			List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
			CountSessionWrapper countSessionObj = PartCountService.getCountSessionDetailById(countSessionId);
			CountSessionLineItemWrapper countSessionLineItemWrapperObj = PartCountService.getAllCountSessionLIBySessionIdAndTabName(countSessionId, tabName, lastRecUniqueNameValue, QUERY_LIMIT_RECORDS);
			if(countSessionLineItemWrapperObj.CountSessionLineItems.size() > 0) {
				lastRecUniqueNameValue = String.valueOf(countSessionLineItemWrapperObj.CountSessionLineItems[countSessionLineItemWrapperObj.CountSessionLineItems.size() - 1].Name);
			}
			CountSessionDetail countSessionDetailObj = new CountSessionDetail(businessProfileList, countSessionObj, countSessionLineItemWrapperObj, lastRecUniqueNameValue, countSessionLineItemWrapperObj.CountSessionLineItems.size() < QUERY_LIMIT_RECORDS);
			return BPUtility.getEncodedString(system.JSON.serialize(countSessionDetailObj));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    	return '{}';	
    }
    
    public class CountSessionDetail {
		public CustomerDetail.Company CompanyInfo;
		public CountSessionWrapper CountSessionObj;  
		public CountSessionLineItemWrapper CountSessionLineItemWrapperObj;
		public Boolean IsProcessComplete;
        public String LastRecUniqueNameValue;
		public CountSessionDetail(List<Business_Profile__c> businessProfileList, CountSessionWrapper countSessionObj, CountSessionLineItemWrapper countSessionLineItemWrapperObj, String lastRecUniqueNameValue, Boolean isProcessComplete) {
			if(businessProfileList.size() > 0) {
                this.CompanyInfo = new CustomerDetail.Company(businessProfileList[0]);
            } else {
                this.CompanyInfo = new CustomerDetail.Company(new Business_Profile__c());
            }
            this.CompanyInfo.BusinessPhone = this.CompanyInfo.FormattedBusinessPhone != null ? this.CompanyInfo.FormattedBusinessPhone: '';
            this.CountSessionObj = countSessionObj;
            this.CountSessionLineItemWrapperObj = countSessionLineItemWrapperObj;
            this.IsProcessComplete = isProcessComplete;
            this.LastRecUniqueNameValue = lastRecUniqueNameValue;
		}
    }
}