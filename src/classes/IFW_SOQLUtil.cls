public without sharing class IFW_SOQLUtil {
    
    public static List<IFW_IntegrationConfig__c> getIntegrationConfig(Map<String, Object> fieldAPINameToFieldValueMap) {
        String query = 'SELECT Access_Token__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, Consumer_Key__c, ' +
                  'Consumer_Secret__c, Accounting_Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c, ' +
                  'Token_Expiry__c, Token_Type__c, Integration_Type__c, Client_Id__c, Client_Secret__c, Company_Id__c, Client_Secret_Long__c, Client_Id_Long__c FROM IFW_IntegrationConfig__c ';
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
    
    public static List<IFW_IntegrationConfig__c> getIntegrationConfigWithItems(Map<String, Object> fieldAPINameToFieldValueMap) {
        String query = 'SELECT Access_Token__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, Consumer_Key__c, ' +
                  'Consumer_Secret__c, Accounting_Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c, ' +
                  'Token_Expiry__c, Token_Type__c, Integration_Type__c, Client_Id__c, Client_Secret__c, Company_Id__c, Client_Id_Long__c, Client_Secret_Long__c, ' +
                  '(SELECT IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c, Entity_Name__c FROM IFW_IntegrationConfigItems__r) ' + 
                  ' FROM IFW_IntegrationConfig__c ';
        query += getWhereClause(fieldAPINameToFieldValueMap);
        if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static List<IFW_IntegrationConfig__c> getIntegrationConfigWithItems(String integrationName, Map<String, String> integrationEntityNameToActionMap) {
        return getIntegrationConfigWithItems(integrationName, integrationEntityNameToActionMap, true);
    }

    public static List<IFW_IntegrationConfig__c> getIntegrationConfigWithItems(String integrationName, Map<String, String> integrationEntityNameToActionMap, Boolean isFilterXeroAccEnabled) {
    	if(String.isBlank(integrationName)) {
    		throw new BlackpurlException('No active integration');
    	}
    	String query = 'SELECT Client_Id__c, Client_Secret__c, Access_Token__c, Access_Token_Secret__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, ' +
    	    'Consumer_Key__c, Consumer_Secret__c, Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, ' +
			'Username__c, Refresh_Token__c, Timeout__c, Token_Expiry__c, Client_Id_Long__c, Client_Secret_Long__c, Token_Type__c, ' +
    					'(SELECT IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c, Entity_Name__c FROM IFW_IntegrationConfigItems__r ';
    	if(integrationEntityNameToActionMap != null && integrationEntityNameToActionMap.size() > 0) {
    		query += 'WHERE ';
    		for(String xeroEntityName : integrationEntityNameToActionMap.keySet()) {
    			if(integrationEntityNameToActionMap.get(xeroEntityName) == null) {
    				query += '(Entity_Name__c = \'' + xeroEntityName + '\' AND (Entity_Action__c = null)) OR ';
    			} else {
    				query += '(Entity_Name__c = \'' + xeroEntityName + '\' AND (Entity_Action__c includes (\'' + integrationEntityNameToActionMap.get(xeroEntityName) + '\'))) OR ';
    			}
    		}
    		query = query.subString(0, query.length() - 4);
    	} else if(integrationName == QBUtil.QUICKBOOKS_ONLINE) { // considering for QB if integrationEntityNameToActionMap is having no value then we need to query IFW item with HTTP method GET
			query += 'WHERE HTTP_Method__c = \'GET\'';
		}
    	
    	query += ') FROM IFW_IntegrationConfig__c WHERE Integration_Name__c =: integrationName ';
		if(integrationName == XeroUtility.XERO) {
			query += (isFilterXeroAccEnabled ? ' AND Accounting_Enabled__c = true ' : ' AND Enabled__c = true ');
		} else if (integrationName == QBUtil.QUICKBOOKS_ONLINE) {
			query += ' AND Enabled__c = true '; // need to discuss for QB trasactions query do we need to use Accounting_Enabled__c = true ??
		}
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