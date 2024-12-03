public without sharing class ReportsToEmail {

    @readonly
    @remoteAction
    public static void getOrgReports(){}
    
    @readonly
    @remoteAction
    public static  Map<String , Integer> getTotalRecords(List<String> objectName){
    	return new Map<String , Integer>();
    }
}