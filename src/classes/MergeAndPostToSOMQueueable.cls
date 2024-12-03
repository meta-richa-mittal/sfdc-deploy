public class MergeAndPostToSOMQueueable implements Queueable, Database.AllowsCallouts {
    
    public void execute(QueueableContext context) {
        String endpoint = SOM_Configuration__c.getOrgDefaults().Blackpurl_Heroku_Endpoint__c;
        String somDetailJSON;
        if(endpoint.contains('fetchAndPostFileToSOM')) {
            somDetailJSON = BPUtility.getEncodedString(System.JSON.serialize(new SOMWrapper()));
            endpoint = endpoint + '/' + somDetailJSON;
        }
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET'); 
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        if(!Test.isRunningTest()) {
            HttpResponse res = h.send(req);
            if(res.getStatusCode() != 200 && res.getStatusCode() != 201  && res.getStatusCode() != 503) {
                new LogService().createErrorLog('MergeAndPostToSOMQueueable', 'execute()', res.getBody(), String.valueOf(res.getStatusCode()), null, 
                                                    'SOM' + LogService.METHOD_PARAM_SEPERATOR + somDetailJSON + ' ' + endpoint, LogService.SOM, true, 'Error');
            }
        }
    }

    public class SOMWrapper {
        public String SFUsername;
        public String SFPassword;
        public String Namespace;
        public String SalesforceBaseUrl;
        public String SessionId;
        
        public SOMWrapper() {
            this.Namespace = (GeneralConfiguration.getPackageNamespace() == null) ? '' : GeneralConfiguration.getPackageNamespace();
            this.SFUsername = BPUtility.getDecodedString(BPConfigurationsService.getSFUsername());
            this.SFPassword = BPUtility.getDecodedString(BPConfigurationsService.getSFPassword());
            this.SessionId = UserInfo.getSessionId();
            this.SalesforceBaseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        }
    }
}