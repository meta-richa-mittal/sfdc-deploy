/** 
* Author: Manoj Sharma
* Since: May 13, 2020 
* Name: DashboardCtrl 
* Description: Apex class which contains all remoted methods related to dashboard page.
**/
global class DashboardCtrl {
    global DashboardCtrl(NewHomePageCtrl controller){} 
    public DashboardCtrl() {}

    @RemoteAction
    global static String getServiceJobs(String filterJson) {
        filterJson = BPUtility.getDecodedString(filterJson);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(DashboardService.getServiceJobList(filterJson), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    } 

    @RemoteAction
    global static String getRefreshMinutes() { 
        try {
            return BPUtility.getEncodedString(String.valueOf(General_Configurations__c.getOrgDefaults().Dashboard_Refresh_Minutes__c));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getFormattedTodaysDate() { 
        try {
            return BPUtility.getEncodedString(DashboardService.getFormattedTodaysDate());
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getJobTypeList() { 
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(DashboardService.getJobTypeList(), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
}