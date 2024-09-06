public class SchDummyTest {
	
    public static void doCall() {
        AuthWrapper authObj = new AuthWrapper();
        String reqBody = system.JSON.serialize(authObj);
       
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setBody(reqBody);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('Accept-Language', 'en-US');
        req.setHeader('Connection', 'Keep-Alive');
        req.setHeader('accept', 'application/json');
        req.setEndpoint('https://ita1-dev-ed.my.salesforce-sites.com/services/apexrest/SOMService');
        HttpResponse res;
        res = h.send(req);
        system.Assert(false, res.getBody());
    }
    
    public class AuthWrapper {
        public String token;
        public String baseURL;
        
        public AuthWrapper() {
            this.token = UserInfo.getSessionId();
            this.baseURL = System.Url.getSalesforceBaseUrl().toExternalForm();
        }
    }
}