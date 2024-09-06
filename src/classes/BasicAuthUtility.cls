public class BasicAuthUtility {
  
    public static HttpResponse performCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                List<CustomHttpHeaderWrapper> headerList) {
        return performCallout(parent, child, body, headerList, null);
    }
    
    public static HttpResponse performCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                List<CustomHttpHeaderWrapper> headerList, Map<String, String> params) {
        Http callout = new Http();
        HttpRequest req = generateBasicRequest(parent, child, body, headerList, params);
        if(!(child.Entity_Name__c.equalsIgnoreCase(BRPVehicleIntegration.GET_ARTICLE) || child.Entity_Name__c.equalsIgnoreCase(BRPVehicleIntegration.GET_CAMPAIGNS) || child.Entity_Name__c.equalsIgnoreCase(UniversalAPIUtility.CONNECTION) || child.Entity_Name__c.equalsIgnoreCase(UniversalAPIUtility.JWT_TOKEN))) {
	        Blob authString = Blob.valueOf(parent.Username__c + ':' + parent.Password__c);
	        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(authString));
        }
        
        HttpResponse res = callout.send(req);
        return res;
    }
    
    private static Boolean tokenGenerated = false;
    public static HttpResponse performBasicWithTokenCallout(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                List<CustomHttpHeaderWrapper> headerList, Map<String, String> params) {
        Http callout = new Http();
        HttpRequest req = generateBasicRequest(parent, child, body, headerList, params);
        if(parent.Bearer_Token__c == null) {
        	fetchBearerToken(parent, generatePayloadToFetchToken(parent));
        	tokenGenerated = true;
        }
        System.debug('parent.Bearer_Token__c::::'+parent.Bearer_Token__c);
        req.setHeader('Authorization', 'Bearer ' + parent.Bearer_Token__c);
        
        HttpResponse res = callout.send(req);
        
        if(res.getStatusCode() == 401 && !tokenGenerated) {
        	parent.Bearer_Token__c = null;
        	return performBasicWithTokenCallout(parent, child, body, headerList, params);
        }
        System.debug('Res:::::::'+res);
        return res;                                          
    }
    
    public static String generatePayloadToFetchToken(IFW_IntegrationConfig__c parent) {
    	String body;
    	Map<String, String> keyToValueMap = new Map<String, String>();
    	if(parent.Integration_Name__c == 'DP360') {
        	body = system.JSON.serialize(new TokenWrapper(parent.Username__c, parent.Password__c), true);
        	return body;
        } else {
        	keyToValueMap.put('client_id', parent.Client_Id__c);
        	keyToValueMap.put('client_secret', parent.Client_Secret__c);
        	keyToValueMap.put('audience', Shopify_Configuration__c.getOrgDefaults().Audience__c);
        	keyToValueMap.put('grant_type', 'client_credentials');
        }
        body = system.JSON.serialize(keyToValueMap);
        return body;
    }
    
    public static HttpRequest generateBasicRequest(IFW_IntegrationConfig__c parent, IFW_IntegrationConfigItem__c child, String body, 
                                                List<CustomHttpHeaderWrapper> headerList, Map<String, String> params) {
        HttpRequest req = new HttpRequest();
        req.setTimeout(BaseIntegration.DEFAULT_TIMEOUT);

        for(CustomHttpHeaderWrapper header : headerList){
            req.setHeader(header.headerType, header.headerValue);
        }
        req.setEndPoint(BaseIntegration.addURLParamsToEndPoint(child.endpoint_URL__c, params));
        req.setMethod(child.Http_Method__c); 
        if(body != null && body.length() > 0) {
            req.setBody(body);
        }
        return req;
    }
    
    public static void fetchBearerToken(IFW_IntegrationConfig__c parent) {
        fetchBearerToken(parent, system.JSON.serialize(new TokenWrapper(parent.Username__c, parent.Password__c), true));
    }
    
    public static void fetchBearerToken(IFW_IntegrationConfig__c parent, String body) {
        List<IFW_IntegrationConfigItem__c> ifwItemList = 
            [SELECT Endpoint_URL__c, HTTP_Method__c FROM IFW_IntegrationConfigItem__c WHERE IFW_IntegrationConfig__c =: parent.Id AND Entity_Name__c = 'Token'];
        String endpoint;
        if(ifwItemList.size() > 0) {
            endpoint = ifwItemList[0].Endpoint_URL__c;
        } else {
            throw new BlackpurlException('Token endpoint not found');
        }
        
        Http callout = new Http();
        HttpRequest req = new HttpRequest();
        req.setTimeout(BaseIntegration.DEFAULT_TIMEOUT);
        req.setEndPoint(endpoint);
        req.setMethod(ifwItemList[0].HTTP_Method__c); 
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);
        
        HttpResponse response = callout.send(req);
        if(!Test.isRunningTest() && response.getStatusCode() == 200) {
            TokenWrapper tokenWrapper = (TokenWrapper) System.JSON.deserialize(response.getBody(), TokenWrapper.class);
            if(parent.Integration_Name__c == 'DP360' && tokenWrapper.data != null && tokenWrapper.data.token != null) {
                parent.Bearer_Token__c = tokenWrapper.data.token;
            } else if (parent.Integration_Name__c == ShopifyUtil.integrationName && tokenWrapper.access_token != null) {
                parent.Bearer_Token__c = tokenWrapper.access_token;
            } else {
                throw new BlackpurlException('Token can\'t be generated');
            }
        } else {
            if(Test.isRunningTest()) {
                parent.Bearer_Token__c = 'abcjsdasda.dasdasdada';
            } else {
            throw new BlackpurlException('Error Occured while fetching token - ' + response.getBody());
            }
        }
    }
    
    public class TokenWrapper {
        public String username;
        public String password;
        public String message;
        public dataWrapper data;
        public String access_token;
        
        public TokenWrapper(String username, String password) {
            this.username = username;
            this.password = password;
        }
    }
    
    public class dataWrapper {
        public String token;
    }
    
    public static CustomHttpHeaderWrapper buildCustomHttpHeader(String key, String value) {
        return new CustomHttpHeaderWrapper(key, value);
    }
}