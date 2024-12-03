/** 
* Author: Tarun Khandelwal
* Since: May 16, 2018 
* Name: SchedulerSOQLUtil 
* Description: Apex class which contains all SOQL related operation for Scheduler
**/
public without sharing class SchedulerSOQLUtil {
	
	public static List<Event__c> getAppointmentWithinPeriodWithFilter(Map<String, List<String>> fieldValueToOperatorAndFieldValueListMap, 
				DateTime fromDate, DateTime toDate) {
    	String query = 'SELECT ';
        for(String fieldsName : AppointmentWrapper.getAppointmentFieldsList()) {
            query += fieldsName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event__c WHERE Start_DateTime__c < :toDate AND End_DateTime__c > :fromDate';
        
        if(fieldValueToOperatorAndFieldValueListMap != null) {
	        for(String fieldName : fieldValueToOperatorAndFieldValueListMap.keySet()) {
	            List<String> fieldList = fieldValueToOperatorAndFieldValueListMap.get(fieldName);
	            if(fieldList.size() == 2) {
	                if(fieldList[1] == null) {
	                    query += ' AND ' + fieldName + fieldList[0] + ' null ';
	                } else {
	                    query += ' AND ' + fieldName + fieldList[0] + '\'' + fieldList[1] + '\'';
	                }
	            }
	        }
        }
        
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
	
    public static List<Event__c> getAppointmentWithinPeriod(DateTime fromDate, DateTime toDate) {
    	String query = 'SELECT ';
        for(String fieldsName : AppointmentDayWrapper.getAppointmentFieldsList()) {
            query += fieldsName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event__c WHERE Start_DateTime__c < :toDate AND End_DateTime__c > :fromDate';
        
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<Technician__c> getTechnicianList(DateTime toDateTime) {
        Date toDate = date.newinstance(toDateTime.year(), toDateTime.month(), toDateTime.day());
        DateTime nextDate = toDateTime.addDays(1);
        String query = 'SELECT ';  
        for(String fieldsName : TechnicianDetailWrapper.getTechnicianFieldsList()) {
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';  
        }
        
        // Leaves Child Query
        query += '(SELECT ';  
        for(String fieldName : LeaveWrapper.getLeaveFieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Leaves__r WHERE (From_Date__c <= : toDate AND To_Date__c >=: toDate) Order BY From__c ASC), ' ;
        
        // Event Child Query
        query += '(SELECT ';
        for(String fieldName : EventSchedulingWrapper.getFieldList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event_Schedulings1__r WHERE Start_Date_Time__c < :nextDate AND End_Date_Time__c > :toDateTime AND Hours__c > 0 Order By Start_Date_Time__c)'; 
        
        query += ' From Technician__c WHERE Type__c = \'Technician\' AND Active__c = true ORDER BY Technician_Name__c';
        if(AccessControl.ifObjectFieldIsAccessible('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<Event__c> getAppoitmentList(Map<String, List<String>> fieldValueToOperatorAndFieldValueListMap, DateTime currentDateTime) {
        String query = 'SELECT ';  
        for(String fieldName : AppointmentWrapper.getAppointmentFieldsList()) {
            query += BPUtility.escapeSingleQuotes(fieldName) + ', ';  
        }
        query = query.substring(0, query.length()-2);
        if(currentDateTime != null) {
	        DateTime nextDate = currentDateTime.addDays(1);
	        query += ' From Event__c WHERE Start_DateTime__c < :nextDate AND End_DateTime__c > :currentDateTime ';
        } else {
        	query += ' From Event__c';
        }
        
        String whereOrAndStr = query.contains('WHERE') ? ' AND ' : ' WHERE ';
        for(String fieldName : fieldValueToOperatorAndFieldValueListMap.keySet()) {
            List<String> fieldList = fieldValueToOperatorAndFieldValueListMap.get(fieldName);
            if(fieldList.size() == 2) {
                if(fieldList[1] == null) {
                    query += whereOrAndStr + BPUtility.escapeSingleQuotes(fieldName) + BPUtility.escapeSingleQuotes(fieldList[0]) + ' null ';
                } else {
                    query += whereOrAndStr + BPUtility.escapeSingleQuotes(fieldName) + BPUtility.escapeSingleQuotes(fieldList[0]) + (String.isNotBlank(fieldList[1]) ? '\'' + BPUtility.escapeSingleQuotes(fieldList[1]) + '\'' : '');
                }
                whereOrAndStr = ' AND ';
            }
            
        }
        query += ' ORDER BY Start_DateTime__c ASC';
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<Event__c> getAppointmentListBySOId(List<Id> sectionIdList) {
        String query = 'SELECT ';
        for(String fieldName : AppointmentWrapper.getAppointmentFieldsList()) {
            query += fieldName + ', ';  
        }
        query += '(SELECT ';
        for(String fieldName : EventSchedulingWrapper.getFieldList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event_Schedulings__r Order By Start_Date_Time__c)';
        
        query += ' FROM Event__c WHERE Service_Order_Header__c IN: sectionIdList';
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<Event__c> getAppointmentListByIds(List<Id> appIdList) {
        String query = 'SELECT ';
        for(String fieldName : AppointmentWrapper.getAppointmentFieldsList()) {
            query += fieldName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event__c WHERE Id IN: appIdList';
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<Event_Scheduling__c> getEventSchedulingListByQueryParam(Map<String, List<String>> fieldValueToOperatorAndFieldValueListMap, DateTime currentDateTime) {
        String query = 'SELECT ' + String.join(EventSchedulingWrapper.getFieldList(), ',');  
        if(currentDateTime != null) {
	        DateTime nextDate = currentDateTime.addDays(1);
	        query += ' From Event_Scheduling__c WHERE Start_Date_Time__c < :nextDate AND End_Date_Time__c > :currentDateTime ';
        } else {
        	query += ' From Event_Scheduling__c';
        }
        
        String whereOrAndStr = query.contains('WHERE') ? ' AND ' : ' WHERE ';
        for(String fieldName : fieldValueToOperatorAndFieldValueListMap.keySet()) {
            List<String> fieldList = fieldValueToOperatorAndFieldValueListMap.get(fieldName);
            if(fieldList.size() == 2) {
                query += whereOrAndStr + BPUtility.escapeSingleQuotes(fieldName) + BPUtility.escapeSingleQuotes(fieldList[0]) + (fieldList[1] == null ? ' null ' : '\'' + BPUtility.escapeSingleQuotes(fieldList[1]) + '\'');
                whereOrAndStr = ' AND ';
            }
        }
        query += ' ORDER BY Start_Date_Time__c ASC';
        if(!AccessControl.ifObjectFieldIsAccessible('Event_Scheduling__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static List<Event_Scheduling__c> getEventSchedulingListWithinPeriodWithFilter(Map<String, List<String>> fieldValueToOperatorAndFieldValueListMap, 
				DateTime fromDate, DateTime toDate) {
    	String query = 'SELECT ';
        for(String fieldsName : EventSchedulingWrapper.getFieldList()) {
            query += fieldsName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event_Scheduling__c WHERE Start_Date_Time__c < :toDate AND End_Date_Time__c > :fromDate';
        
        if(fieldValueToOperatorAndFieldValueListMap != null) {
	        for(String fieldName : fieldValueToOperatorAndFieldValueListMap.keySet()) {
	            List<String> fieldList = fieldValueToOperatorAndFieldValueListMap.get(fieldName);
	            if(fieldList.size() == 2) {
	                if(fieldList[1] == null) {
	                    query += ' AND ' + fieldName + fieldList[0] + ' null ';
	                } else {
	                    query += ' AND ' + fieldName + fieldList[0] + '\'' + fieldList[1] + '\'';
	                }
	            }
	        }
        }
        
        if(!AccessControl.ifObjectFieldIsAccessible('Event_Scheduling__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static List<Event_Scheduling__c> getEventSchedulingListWithinPeriod(DateTime fromDate, DateTime toDate) {
    	String query = 'SELECT ';
        for(String fieldsName : EventSchedulingWrapper.getFieldList()) {
            query += fieldsName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event_Scheduling__c WHERE Start_Date_Time__c < :toDate AND End_Date_Time__c > :fromDate AND ( Technician__c = Null OR (Technician__c != Null AND Technician__r.Active__c = True ))';
        
        if(!AccessControl.ifObjectFieldIsAccessible('Event_Scheduling__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
}