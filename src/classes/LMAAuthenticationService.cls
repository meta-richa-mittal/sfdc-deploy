public without sharing class LMAAuthenticationService {
    public static OAuth2 getAccessToken() {
        String SERVER_URL = LMA_Config__c.getOrgDefaults().End_Point__c; //'https://login.salesforce.com';
        String USERNAME = BPUtility.getDecodedString(LMA_Config__c.getOrgDefaults().Username__c);//'mcube_admin@blackpurl.com';
        String PASSWORD = BPUtility.getDecodedString(LMA_Config__c.getOrgDefaults().Password__c); //'Welcome@12345#';
        String SECURITY_TOKEN = LMA_Config__c.getOrgDefaults().Security_Token__c; //'5nmSgKRcaWa8COTv0bowXJFas';
        String CLIENT_ID = LMA_Config__c.getOrgDefaults().Client_Id__c; //'3MVG9szVa2RxsqBbM1uD0dFuYZ3UKKmTwYlJPav.G5vkeMwf1FzozCajgwn7zCRz.F9htQenvGWQ3IiwRMuTj';
        String CLIENT_SECRET = LMA_Config__c.getOrgDefaults().Client_Secret__c; //'1813374359520083531';
        
        return getAccessToken(CLIENT_ID, CLIENT_SECRET, USERNAME, PASSWORD + SECURITY_TOKEN, SERVER_URL);
    }
    
    private static OAuth2 getAccessToken(String clientId, String clientSecret, String userName, String passwordWithToken, String serverURL) {
        String reqbody = 'grant_type=password&client_id='+clientId+'&client_secret='+clientSecret+'&username='+userName+'&password='+passwordWithToken;
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setBody(reqbody);
        req.setMethod('POST');
        req.setEndpoint(serverURL + '/services/oauth2/token');
        HttpResponse res;
        res = h.send(req);
        //system.assert(false, res.getbody());
        
        OAuth2 objAuthenticationInfo = (OAuth2)JSON.deserialize(res.getbody(), OAuth2.class);
        return objAuthenticationInfo;
    }
    
    public static HttpResponse sendRequest(String reqBody, OAuth2 objAuthenticationInfo, String restApiName) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + objAuthenticationInfo.access_token);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('accept', 'application/json');
        req.setMethod('POST');
        req.setEndpoint(LMA_Config__c.getOrgDefaults().End_Point__c + '/services/apexrest/' + restApiName);
        req.setBody(reqBody);
        HttpResponse res = h.send(req);
        return res;
    }
    
    // To get authentication detail Wrapper
    public class OAuth2 {
        public String id;
        public String issued_at;
        public String instance_url;
        public String signature;
        public String access_token;    
        
        public OAuth2(String id, String instanceUrl, String accessToken) {
            this.id = id;
            this.instance_url = instanceUrl;
            this.access_token = accessToken;
        }
    }
}