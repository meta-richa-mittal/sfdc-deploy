/**
* Author: Manoj Sharma
* Since: May 13, 2020
* Name: DashboardSOQLUtil
* Description: Apex class which contains all the queries and gives result for dashboard operations.
**/
public without sharing class DashboardSOQLUtil {
    
    /**
    * Name: getSOHeaderByIdSet
    * Desc: To get SO header list based on set of id
    * @param:  Set<Id> so header id set
    * @return: soHeaderList records list
    **/
    public static List<Service_Order_Header__c> getSOHeaderByIdSet(Set<Id> soHeaderIdSet) {
        String query = 'SELECT ' + String.join(DashboardServiceJobWrapper.getSOHeaderFieldsList(), ', ') + ' FROM Service_Order_Header__c';
        query += ' WHERE Id In : soHeaderIdSet ORDER BY CO_Header__r.Customer_Name__c ASC';
        if(!AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    /**
    * Name: getAppointmentList
    * Desc: To get Appointment list based on filter type
    * @param:  Map<String, List<String>> record fieldNameToFieldValueListMap
    * @return: Appointment records list
    **/
    public static List<Event__c> getAppointmentList(Map<String, List<String>> fieldNameToFieldValueListMap) {
        return getAppointmentList(getWhereClause(fieldNameToFieldValueListMap));
    }

    public static List<Event__c> getAppointmentList(String whereClause) {
        String query = 'SELECT ' + String.join(DashboardServiceJobWrapper.getEventFieldsList(), ', ') + ' FROM Event__c';
        query += (String.isNotBlank(whereClause) ? whereClause : '');
        query += ' AND Type__c = \'Appointment\' AND Start_DateTime__c <= TODAY ';
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    /**
    * Name: getHoursLogList
    * Desc: To get hours log list based on filter type
    * @param:  Map<String, List<String>> record fieldNameToFieldValueListMap
    * @return:  hours log records list
    **/
    public static List<Hours_Logged__c> getHoursLogList(Map<String,List<String>> fieldNameToFieldValueListMap) {
        return getHoursLogList(getWhereClause(fieldNameToFieldValueListMap));
    }

    public static List<Hours_Logged__c> getHoursLogList(String whereClause) {
        String query = 'SELECT ' + String.join(DashboardServiceJobWrapper.getHoursLogFieldsList(), ', ') + ' FROM Hours_Logged__c';
        query += (String.isNotBlank(whereClause) ? whereClause : '');
        query += ' AND Is_Removed__c = false ';
        if(!AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    /**
    * Name: getWhereClause
    * Desc: To get where clause based on filter type
    * @param:  Map<String, List<String>> record fieldNameToFieldValueListMap
    * @return: where clause string
    **/
    private static String getWhereClause(Map<String, List<String>> fieldNameToFieldValueListMap) {
        String whereClause = '';
        Boolean isWhereClauseAdded = false;
        Boolean isANDCondition = false;
        for(String fieldName : fieldNameToFieldValueListMap.keySet()) {
            whereClause += isWhereClauseAdded ? ' AND ( ' : '';
            
            for(String fieldValue : fieldNameToFieldValueListMap.get(fieldName)) {
                if(isWhereClauseAdded && isANDCondition) {
                    whereClause += fieldName + ' = \'' + fieldValue + '\'';
                    isANDCondition = false;
                } else if(isWhereClauseAdded) {
                    whereClause += ' OR ' + fieldName + ' = \'' + fieldValue + '\'';
                } else {
                    whereClause += ' WHERE (' + fieldName + ' = \'' + fieldValue + '\'';
                    isWhereClauseAdded = true;
                }
            }
            whereClause += ' )';
            isANDCondition = true;
        }
        return whereClause;
    }
}