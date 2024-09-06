public without sharing class IFW_SOQLUtil {
    
    public static List<IFW_IntegrationConfig__c> getIntegrationConfig(Map<String, Object> fieldAPINameToFieldValueMap) {
        String query = 'SELECT Access_Token__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, Consumer_Key__c, ' +
                  'Consumer_Secret__c, Accounting_Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c, ' +
                  'Token_Expiry__c, Token_Type__c, Integration_Type__c, Client_Id__c, Client_Secret__c, Company_Id__c FROM IFW_IntegrationConfig__c ';
        query += getWhereClause(fieldAPINameToFieldValueMap);
        if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static List<IFW_IntegrationConfigItem__c> getIntegrationConfigItem(Map<String, Object> fieldAPINameToFieldValueMap) {
        String query = 'SELECT IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c FROM IFW_IntegrationConfigItem__c ';
        query += getWhereClause(fieldAPINameToFieldValueMap);
        if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfigItem__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }
    
    public static String getWhereClause(Map<String, Object> fieldsMap) {
        String whereClause = '';
        for(String fieldName : fieldsMap.keySet()) {
            whereClause += ((whereClause.length() == 0) ? 'WHERE ' : 'AND ') + getConditionBasedOnDataType(fieldName, fieldsMap.get(fieldName));
        }
        return whereClause;
    }
    
    private static String getConditionBasedOnDataType(String fieldName, Object fieldValue) {
        String condition;
        if(fieldValue == null || fieldValue instanceOf BOOLEAN) {
            condition = fieldName + ' = ' + fieldValue + ' ';
        } else if(fieldValue instanceOf STRING || fieldValue instanceOf ID) {
            condition = fieldName + ' = \'' + fieldValue + '\' ';
        }
        return condition;
    }
}