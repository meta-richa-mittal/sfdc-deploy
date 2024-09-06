@isTest
private class CassonsHerokuServiceTest {
    @TestSetup
    private static void setup(){
        
    }

    @isTest
    private static void testCassonsHerokuServiceMethods() {
        Test.setMock(HttpCalloutMock.class, new CassonsHerokuMockResponseGenerator());
        Test.startTest();     
        CassonsHerokuService.fetchPartsFromHeroku(1);
        CassonsHerokuService.sendPartInventoryRequest();
        Test.stopTest();
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
    }

    public class CassonsHerokuMockResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String JSONstr = '{"OrgId":"00D41000000cs2I","FileGenerated":true,"CassonsPartList":[{"PartNo":"yajsdghf","Description":"yes i am","SOH":"sdfsdf"}],"PartsPerRequest":10,"StartIndex":1}';
            JSONstr = BPUtility.getEncodedString(JSONstr);
            res.setBody(JSONstr);
            res.setStatusCode(200);
            return res;
        }
    }
}