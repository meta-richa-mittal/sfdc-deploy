
public without sharing abstract class BaseIntegration {
    
    public static List<WebService_Log__c> webServiceLogs;
  	public static Integer DEFAULT_TIMEOUT = 120000;
  	
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
            if((parent.Integration_Name__c == BRPUtility.BRP || parent.Integration_Name__c == BRPUtility.BRP_2)&& (res.getStatusCode() == 401 || res.getStatus() == 'Unauthorized')) {
                if(isBRPOAuth2API(child)) {
                    res = BRPAPIManager.refreshBRPAccessTokenAndPerformCallout(parent, child, body, headerList, parameters);
                }
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
        	if(parent.Integration_Name__c == QBUtil.QUICKBOOKS_ONLINE) {
                child.Endpoint_URL__c = child.Endpoint_URL__c.replace('{{company_id}}', tenantId);
            }
            
            System.debug('HTTP Method = ' + child.HTTP_Method__c);
            System.debug('Request Body = ' + body);
            System.debug('Access Token = ' + accessToken);
            System.debug('tenantId = ' + tenantId);
            System.debug('End Point URL = ' + child.Endpoint_URL__c);
            System.debug('parameters = ' + parameters);
            System.debug('headerList = ' + headerList);
            
        	res = OAuthUtility.executeOauth2Callout(child.HTTP_Method__c, body, accessToken, tenantId, child.Endpoint_URL__c, parameters, DEFAULT_TIMEOUT, headerList);
           System.debug('Response Status Code' + res.getStatusCode());
            System.debug('Response Body' + res.getBody());
            
            if(res.getStatusCode() == 401 || res.getBody().contains('TokenExpired') || res.getBody().contains('TokenInvalidSignature')) {
                if(parent.Integration_Name__c == BRPUtility.BRP_DMS_OAUTH2 || parent.Integration_Name__c == BRPUtility.BRP_2) {
                    parent.Access_Token__c = accessToken = BRPAuthorizationService.refreshAccessTokenForBRP(new List<IFW_IntegrationConfig__c>{parent});
                } else {
                    try {
                        res = refreshAccessToken(parent);
                        accessToken = getAccessTokenFromResponse(res, parent);
                        //create web service log for refresh access token
                        createWebServiceLogForRefreshAccessToken(parent);
                        System.debug('Refeshed Access Token' + accessToken);
                    } catch(HttpRequestException e) {
                        accessToken = null;
                    }
                }
                if(accessToken != null) res = OAuthUtility.executeOauth2Callout(child.HTTP_Method__c, body, accessToken, tenantId, child.Endpoint_URL__c, parameters, DEFAULT_TIMEOUT, headerList);
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
        return [SELECT IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c, Entity_Name__c FROM IFW_IntegrationConfigItem__c WHERE Id =: childId];
    }
    
    public static List<IFW_IntegrationConfigItem__c> getChild(Map<String, String> fieldNameToFieldValueMap) {
        String query = 'SELECT IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c, Entity_Name__c FROM IFW_IntegrationConfigItem__c ';
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
                  Consumer_Secret__c, Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c, Dealer_Group_Id__c,
                  Token_Expiry__c, Token_Type__c, Client_Id__c, Client_Secret__c, Company_Id__c, Client_Id_Long__c, Client_Secret_Long__c FROM IFW_IntegrationConfig__c WHERE Id =: parentId];
    }
    
    public static List<IFW_IntegrationConfig__c> getParentByName(String integrationName) {
        return [SELECT Access_Token__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, Consumer_Key__c, Accounting_Enabled__c, 
                  Consumer_Secret__c, Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c,
                  Token_Expiry__c, Token_Type__c, Client_Id__c, Client_Secret__c, Public_Key__c, Client_Id_Long__c, Client_Secret_Long__c FROM IFW_IntegrationConfig__c WHERE Integration_Name__c =: integrationName AND Enabled__c = true];
    }

    public static List<IFW_IntegrationConfig__c> getIFWConfigByName(List<String> integrationNameList) {
        return [SELECT Access_Token__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, Consumer_Key__c, Accounting_Enabled__c, 
                  Consumer_Secret__c, Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c,
                  Token_Expiry__c, Token_Type__c, Client_Id__c, Client_Secret__c, Public_Key__c, Client_Id_Long__c, Client_Secret_Long__c, 
                  (SELECT Id FROM IFW_IntegrationConfigItems__r) FROM IFW_IntegrationConfig__c WHERE Integration_Name__c IN: integrationNameList];
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

    public static String getAccessTokenFromResponse(HttpResponse httpRes, IFW_IntegrationConfig__c parent) { // parent will be used to set the updated tokens
        if(httpRes.getStatusCode() == 200) {
            Map<String, Object> response_Map = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());
            parent.Access_Token__c = (String)response_Map.get('access_token');
            parent.Refresh_Token__c = (String)response_Map.get('refresh_token');
            return (String)response_Map.get('access_token');
        } else {
            throw new HttpRequestException(httpRes.getBody());
        }
    }
    
    public static HttpResponse refreshAccessToken(IFW_IntegrationConfig__c parent) {
		String encodedString = EncodingUtil.base64Encode(Blob.valueOf(parent.Client_Id__c+':'+parent.Client_Secret__c));
		String endPoint = '';
		if(parent.Integration_Name__c == 'Xero') {
			endPoint = 'https://identity.xero.com/connect/token';
		} else if(parent.Integration_Name__c == QBUtil.QUICKBOOKS_ONLINE) {
            endPoint = 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer';
            encodedString = EncodingUtil.base64Encode(Blob.valueOf(parent.Client_Id_Long__c+':'+parent.Client_Secret_Long__c));
        }    

		String requestBody = 'grant_type=refresh_token&refresh_token='+parent.Refresh_Token__c;
		system.debug('endpoint********'+endPoint);
		HttpRequest httpReq = new HttpRequest();
		Http http = new Http();
		httpReq.setMethod('POST');
		httpReq.setEndPoint(endPoint);
		httpReq.setHeader('Authorization', 'Basic '+encodedString);
		httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		httpReq.setHeader('Accept', 'application/json');
		httpReq.setBody(requestBody);
        httpReq.setTimeout(BaseIntegration.DEFAULT_TIMEOUT);
        return http.send(httpReq);
 	}

    private static void createWebServiceLogForRefreshAccessToken(IFW_IntegrationConfig__c parent) {
        WebService_Log__c wsLog = new WebService_Log__c();
        wsLog.IFW_IntegrationConfig__c = parent.Id;
        wsLog.Name = parent.Integration_Name__c + ' ' + String.valueOf(Datetime.now());
        wsLog.Response_Body__c = ('Access Token - ' + parent.Access_Token__c + '\nRefresh Token - ' + parent.Refresh_Token__c).abbreviate(32768);
        wsLog.Entity_Name__c = 'Refresh Access Token';

        if(webServiceLogs != null) {
            webServiceLogs.add(wsLog);
        } else {
        	webServiceLogs = new List<WebService_Log__c>{wsLog};
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

    private static Boolean isBRPOAuth2API(IFW_IntegrationConfigItem__c child) {
        return (child.Endpoint_URL__c != null && (child.Endpoint_URL__c.contains('PartsOrder') || child.Endpoint_URL__c.contains('parts/order') || child.Endpoint_URL__c.contains('parts/orders')));
    }
    
    public class applicationException extends Exception {}
    
}