/** 
* Author: Nidhi Sharma
* Since: Nov 19, 2020
* Name: SMSTemplateSOQLUtil 
* Description: Apex class which contains SMS message soql methods.
**/
public without sharing class SMSTemplateSOQLUtil {
    
    public static List<Text_Message_Template__c> getSMSTemplates(Map<String, String> fieldNameToFieldValueMap) { 
        String query = 'SELECT ' + String.join(SMSTemplateWrapper.getFieldList(), ', ') + ' FROM Text_Message_Template__c ';
        query += SOQLUtility.getWhereClause(fieldNameToFieldValueMap, false);
        query += ' ORDER BY Name DESC LIMIT ' + Limits.getLimitDMLRows();
        if(AccessControl.ifObjectFieldIsAccessible('Text_Message_Template__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query); 
    }
}