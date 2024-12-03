@isTest
private class HTTPConnectorTest {
    static DateTime sysTime = system.now();
    @TestSetup
    private static void setup(){
    TestDataFactory.disableFLSChecks();
    DP360_Configuration__c dp360Configuration = new DP360_Configuration__c(Dealer_Id__c = '500',Last_Synched_Date__c = sysTime, End_Point_URL__c = 'https://api.dp360crm.com/api/2.0');
    insert dp360Configuration;
    // Integration_Name__c integrationName = new Integration_Name__c(name = 'DP360');
    
    List<String> reservedKeyList = new List<String>{'"class"', '"date"', '"time"','"type"'};
    }

    @isTest
    private static void testHTTPConnectorMethods() {
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        Test.startTest();    
        String endPoint = DP360_Configuration__c.getOrgDefaults().End_Point_URL__c;
        String integrationName = 'DP360';
        String contentType = 'application/json'; 
        new HTTPConnector().doPost(endPoint + '/vendors/token.json', '', contentType);
        string authToken = '';
        String endPointUrl = endPoint.replace('/api', '/service');
        HttpResponse result1 = new HTTPConnector().doGet(endPointUrl, new Map<String, String>{'Authorization'=>'Bearer ' + authToken}, contentType);
        new HTTPConnector().doGetWithBody(endPointUrl, new Map<String, String>{'Authorization'=>'Bearer ' + authToken}, contentType, '');
        new HTTPConnector().doPostWithParam(endPointUrl, '', contentType, new Map<String, String>{'Authorization'=>'Bearer ' + authToken});
        new HTTPConnector().doPutWithParam(endPointUrl, '', contentType, new Map<String, String>{'Authorization'=>'Bearer ' + authToken});
        system.assertnotequals(null, result1);
        Test.stopTest();
    }

    public class MockResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String JSONstr = '{}';
            res.setBody(JSONstr);
            res.setStatusCode(200);
            return res;
        }
    }
}