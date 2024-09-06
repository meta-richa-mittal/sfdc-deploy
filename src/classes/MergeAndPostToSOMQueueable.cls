public class MergeAndPostToSOMQueueable implements Queueable, Database.AllowsCallouts {
    
    public void execute(QueueableContext context) {
        String endpoint = SOM_Configuration__c.getOrgDefaults().Blackpurl_Heroku_Endpoint__c;
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET'); 
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        HttpResponse res;
        if(!Test.isRunningTest()) {
            res = h.send(req);
        }
    }
}