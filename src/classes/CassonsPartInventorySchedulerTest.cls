@isTest
private class CassonsPartInventorySchedulerTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
    }

    @isTest
    private static void testCassonsPartInventorySchedulerTestMethods() {
        Test.setMock(HttpCalloutMock.class, new CassonsHerokuMockResponseGenerator());
        Test.startTest();
        Datetime dateTimeNow = Datetime.now();
        dateTimeNow.addMinutes(1);
        String hour = String.valueOf(dateTimeNow.hour());
        String min = String.valueOf(dateTimeNow.minute()); 
        String ss = String.valueOf(dateTimeNow.second());
        String CRON_EXP = ss + ' ' + min + ' ' + hour + ' * * ?';
        String jobId = System.schedule('Test check', CRON_EXP, new CassonsPartInventoryScheduler());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
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