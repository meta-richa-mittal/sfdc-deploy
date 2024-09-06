public without sharing abstract class BaseIntegration {
    
    public static List<WebService_Log__c> webServiceLogs;
  	public static Integer DEFAULT_TIMEOUT = 20000;
  	
    public static String performCallout(Id childId, String body, List<CustomHttpHeaderWrapper> headerList) {
        return performCallout(childId, body, headerList, new Map<String, String>());
    }
    
    public static String performCallout(Id childId, String body, List<CustomHttpHeaderWrapper> headerList, Map<String,String> parameters) {
        IFW_IntegrationConfigItem__c child = getChild(childId);
	    IFW_IntegrationConfig__c parent = getParent(child.IFW_IntegrationConfig__c);
	    if(IFW_IntegrationConfigItem__c.Id == null) {
	        throw new applicationException ('Child not found');
	    }
	    HttpResponse res = performCallout(parent, child, body, headerList, parameters);
	    if(webServiceLogs.size() > 0) {
            DMLUtility.insertSobjectList('WebService_Log__c', webServiceLogs);
	    }
	    return res.getBody();
    }
    
    public static HttpResponse performCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                            List<CustomHttpHeaderWrapper> headerList) {
        return performCallout(parent, child, body, headerList, new Map<String, String>(), null);
    }
    
    public static HttpResponse performCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                            List<CustomHttpHeaderWrapper> headerList, String entityName) {
        return performCallout(parent, child, body, headerList, new Map<String, String>(), entityName);
    }
    
    
    public static HttpResponse performCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                List<CustomHttpHeaderWrapper> headerList, Map<String, String> parameters) {
        return performCallout(parent, child, body, headerList, parameters, null);                                                  
    }
                                                
    public static HttpResponse performCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                List<CustomHttpHeaderWrapper> headerList, Map<String, String> parameters, String entityName) {
        system.debug('Request Body'+ body);
        WebService_Log__c wsLog = new WebService_Log__c();
        wsLog.CalloutStartTime__c = double.valueOf(DateTime.now().GetTime());
        wsLog.IFW_IntegrationConfig__c = parent.Id;
        wsLog.Name = parent.Integration_Name__c + ' ' + String.valueOf(Datetime.now());
        
        HttpResponse res = new HttpResponse();
        if(parent.Auth_Scheme__c == 'Basic') {
            res = BasicAuthUtility.performCallout(parent, child, body, headerList, parameters);
            
            system.debug('=== before token expire res in BaseIntegration === ' + res.getBody() + '  ' + res.getStatusCode());
            
            // this is to refresh the BRP access token because BRP uses this acces token in basic API request
            if(parent.Integration_Name__c == BRPUtility.BRP && (res.getStatusCode() == 401 || res.getStatus() == 'Unauthorized')) {
            	res = BRPAuthorizationService.refreshBRPAccessTokenAndPerformCallout(parent, child, body, headerList, parameters);
            }
            system.debug('=== res in BaseIntegration === ' + res.getBody() + '  ' + res.getStatusCode());
        
        } else if(parent.Auth_Scheme__c == 'Basic with Token') {
            res = BasicAuthUtility.performBasicWithTokenCallout(parent, child, body, headerList, parameters);
        
        } else if(parent.Auth_Scheme__c == 'OAuth1.0') {
            res = OAuthUtility.executeOauth1Callout(child.HTTP_Method__c, body, parent.Consumer_Key__c, child.Endpoint_URL__c, 
                                                      parent.Certificate_Name__c, parameters);
        
        } else if(parent.Auth_Scheme__c == 'OAuth2.0') {
        	String accessToken = parent.Access_Token__c;
        	Integer timeout = parent.timeout__c != null ? Integer.valueOf(parent.timeout__c) : DEFAULT_TIMEOUT;
        	String tenantId = QuickBooks_Configurations__c.getOrgDefaults().Company_Id__c;
        	
        	res = OAuthUtility.executeOauth2Callout(child.HTTP_Method__c, body, accessToken, tenantId, child.Endpoint_URL__c, parameters, timeout, headerList);
            
            if(res.getStatusCode() == 401 || res.getBody().contains('TokenExpired') || res.getBody().contains('TokenInvalidSignature')) {
                if(parent.Integration_Name__c == BRPUtility.BRP_DMS_OAUTH2) {
                    accessToken = BRPAuthorizationService.refreshAccessTokenForBRPDMS(new List<IFW_IntegrationConfig__c>{parent});
                } else {
                    accessToken = refreshAccessToken(parent);
                }
                res = OAuthUtility.executeOauth2Callout(child.HTTP_Method__c, body, accessToken, tenantId, child.Endpoint_URL__c, parameters, timeout, headerList);
            }
        	system.debug('=== res in BaseIntegration === ' + res.getBody() + '  ' + res.getStatusCode());
        } else {
            throw new applicationException ('Unsupported Auth Scheme: '+parent.Auth_Scheme__c);
        }
        
        wsLog.Callout_End_Time__c = Double.valueOf(DateTime.now().getTime());
        wsLog.Request_Body__c = body != null ? body.abbreviate(32768): null;
        wslog.Response_Code__c = String.valueOf(res.getStatusCode());
        if(res.getStatusCode() != 200) {
            Integer resBodyLength = res.getBody().length();
            wsLog.Response_Body__c = resBodyLength > 32768 ?  (res.getBody()).subString(resBodyLength - 32768,  resBodyLength) : res.getBody();
        } else {
        	wsLog.Response_Body__c = res.getBody().abbreviate(32768);
        }
        wslog.Status__c = res.getStatus();
        wsLog.endpoint__c = child.endpoint_URL__c;
        if(parameters != null) {
           wsLog.endpoint__c = BaseIntegration.addURLParamsToEndPoint(child.endpoint_URL__c, parameters);
        }
        wsLog.endpoint__c = wsLog.endpoint__c != null ? wsLog.endpoint__c.abbreviate(255): null;
        wsLog.Entity_Name__c = entityName;
        
        if(wsLog.Response_Code__c != '200') {
            wslog.Response_Description__c = res.getBody().abbreviate(255);
        }
        if(webServiceLogs != null) {
            webServiceLogs.add(wsLog);
        } else {
        	webServiceLogs = new List<WebService_Log__c>{wsLog};
        }
        return res;
    }
    
    public static IFW_IntegrationConfigItem__c getChild(Id childId) {
        return [SELECT IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c FROM IFW_IntegrationConfigItem__c WHERE Id =: childId];
    }
    
    public static List<IFW_IntegrationConfigItem__c> getChild(Map<String, String> fieldNameToFieldValueMap) {
        String query = 'SELECT IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c FROM IFW_IntegrationConfigItem__c ';
        Boolean isWhereClauseAdded = false;
        for(String fieldName : fieldNameToFieldValueMap.keySet()) {
            if(!isWhereClauseAdded) {
                query += ' WHERE ' + fieldName + ' = \'' + fieldNameToFieldValueMap.get(fieldName) + '\'';
                isWhereClauseAdded = true;
            } else {
                query += ' AND ' + fieldName + ' = \'' + fieldNameToFieldValueMap.get(fieldName) + '\'';  
            }
        }
        return Database.query(query);
    }
    
    public static IFW_IntegrationConfig__c getParent(Id parentId) {
        return [SELECT Access_Token__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, Consumer_Key__c,
                  Consumer_Secret__c, Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c,
                  Token_Expiry__c, Token_Type__c, Client_Id__c, Client_Secret__c, Company_Id__c FROM IFW_IntegrationConfig__c WHERE Id =: parentId];
    }
    
    public static List<IFW_IntegrationConfig__c> getParentByName(String integrationName) {
        return [SELECT Access_Token__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, Consumer_Key__c, Accounting_Enabled__c, 
                  Consumer_Secret__c, Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c,
                  Token_Expiry__c, Token_Type__c, Client_Id__c, Client_Secret__c, Public_Key__c FROM IFW_IntegrationConfig__c WHERE Integration_Name__c =: integrationName AND Enabled__c = true];
    }
    
    public static String addURLParamsToEndPoint(String endPoint, Map<String, String> paramsMap) {
        String urlParamString = '';
        for(String param : paramsMap.keySet()) {
            urlParamString += (param + '=' + paramsMap.get(param)) + '&';
        }
        if(String.isNotBlank(endpoint) && paramsMap.size() > 0) {
            endpoint += '?' + urlParamString.subString(0, urlParamString.length() - 1);
        }
        return endpoint;
    }
    
    public static String refreshAccessToken(IFW_IntegrationConfig__c parent) {
		String encodedString = EncodingUtil.base64Encode(Blob.valueOf(parent.Client_Id__c+':'+parent.Client_Secret__c));
		String endPoint = '';
		if(parent.Integration_Name__c == 'Xero') {
			endPoint = 'https://identity.xero.com/connect/token';
		}
		
		String requestBody = 'grant_type=refresh_token&refresh_token='+parent.Refresh_Token__c;
		system.debug('endpoint********'+endPoint);
		HttpRequest httpReq = new HttpRequest();
		HttpResponse httpRes = new HttpResponse();
		Http http = new Http();
		httpReq.setMethod('POST');
		httpReq.setEndPoint(endPoint);
		httpReq.setHeader('Authorization', 'Basic '+encodedString);
		httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		httpReq.setHeader('Accept', 'application/json');
		httpReq.setBody(requestBody);
		try {
			httpRes = http.send(httpReq);
			if(httpRes.getStatusCode() == 200) {
 				Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());
 				parent.Access_Token__c = (String)response_Map.get('access_token');
			    parent.Refresh_Token__c = (String)response_Map.get('refresh_token');
 				return (String)response_Map.get('access_token');
			} else {
				throw new BlackpurlException(httpRes.getBody());
			}
		} catch(System.Exception e) {
			throw new BlackpurlException(e.getMessage());
	 	}
 	}
	
	public static Id getIFWConfigItemByEntityName(String entityName, String methodType, String integrationName) {
        if(AccessControl.ifObjectIsAccessible('IFW_IntegrationConfigItem__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        List<IFW_IntegrationConfigItem__c> configItemList = 
                [SELECT Id from IFW_IntegrationConfigItem__c WHERE Entity_Name__c =: entityName AND HTTP_Method__c =: methodType
                    AND IFW_IntegrationConfig__r.Integration_Name__c =: integrationName];
        Id returnId;
        if(configItemList.size() > 0) {
            returnId = configItemList[0].Id;
        }
        return returnId;
    }
    
    public class applicationException extends Exception {}
    
}