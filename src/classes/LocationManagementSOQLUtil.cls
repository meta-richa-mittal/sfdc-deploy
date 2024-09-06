/** 
* Author: Tarun Khandelwal
* Since: Aug 26, 2019 
* Name: LocationManagementSOQLUtil 
* Description: Apex class which contains all soql methods related to Location management Page.
**/
public without sharing class LocationManagementSOQLUtil {
    
    public static List<Location__c> getLocationList() {
        return getLocationList(new Map<String, Object>());
    }
    
    public static List<Location__c> getLocationList(Map<String, Object> fieldsMap) {
        String query = 'SELECT ' + String.join(LocationWrapper.getLocationFieldList(), ','); 
        query += ' FROM Location__c '; 
        query += SOQLUtil.getWhereClause(fieldsMap);
        query += ' ORDER BY CreatedDate DESC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Location__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        return Database.query(query);
    }

    public static List<Location__c> getPaginatedLocationList(LocationWrapper.PaginatedLocation locationObj) {
        String query = 'SELECT ' + String.join(LocationWrapper.getLocationFieldList(), ','); 
        query += ' FROM Location__c WHERE Name__c LIKE \'%' + BPUtility.escapeSingleQuotes(locationObj.LocationSearchStr) + '%\'';
        query += ' ORDER BY ' + locationObj.SortBy + ' ' + (locationObj.Reverse == true ? 'DESC ' : 'ASC ') + SOQLUtility.getLimitClause(locationObj.StartIndex, locationObj.RecordCount);
        
        if(AccessControl.ifObjectFieldIsAccessible('Location__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        List<SObject> sobjList = SOQLUtility.getQueryResults('Location__c', query);

        if(locationObj.StartIndex != null && locationObj.StartIndex > 2000 && locationObj.RecordCount != null) {
    		sobjList = SOQLUtility.getLimitRecordsBasedOnRecordCount(sobjList, locationObj.StartIndex);
    	}
        return sobjList;
    }

    public static Integer getTotalLocationCount() {
        String query = 'SELECT COUNT() FROM Location__c LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Location__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        return Database.countQuery(query);
    }
}