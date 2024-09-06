global without sharing class AccountingExportCtrl {
    
    global AccountingExportCtrl (NewHomePageCtrl controller){}
    public AccountingExportCtrl() {}
    
    @remoteAction 
    global static String getPreviousExportDetails() {return '';}
    
    @remoteAction 
    global static String processExport(String exportDataJSON, String selectedFilter, String fromDate, String toDate) {return '';}
    
    @remoteAction 
    global static String getTimePeriodForExport() {return '';}
}