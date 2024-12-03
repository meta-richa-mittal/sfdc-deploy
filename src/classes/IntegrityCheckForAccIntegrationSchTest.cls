
@isTest
private without sharing class IntegrityCheckForAccIntegrationSchTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
    @isTest
    private static void testIntegrityCheckForAccIntegrationSchMethods() {
        Test.setMock(HttpCalloutMock.class, new IntegrityCheckMockResponseGenerator());
        DMLUtility.insertSobjectList('General_Configurations__c', new General_Configurations__c(Enable_Xero_Accounting__c = true));
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
        List<IFW_IntegrationConfig__c> configList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Type__c' => 'Accounting',
                                                                                                                'Accounting_Enabled__c' => true});
        
        Test.startTest();     
        IntegrityCheckForAccIntegrationSch integrationObj = new IntegrityCheckForAccIntegrationSch();
        integrationObj.executeEmailScheduler();
        Datetime dateTimeNow = Datetime.now();
        dateTimeNow.addMinutes(1);
        String hour = String.valueOf(dateTimeNow.hour());
        String min = String.valueOf(dateTimeNow.minute()); 
        String ss = String.valueOf(dateTimeNow.second());
        String CRON_EXP = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        String jobId = System.schedule('Test check', CRON_EXP, new IntegrityCheckForAccIntegrationSch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();

    }

    public class IntegrityCheckMockResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String JSONstr = '{"OrgId":"00D41000000cs2I","FileGenerated":true,"IntegrityCheck":[{"Description":"yes i am","SOH":"sdfsdf"}],"StartIndex":1}';
            JSONstr = BPUtility.getEncodedString(JSONstr);
            res.setBody(JSONstr);
            res.setStatusCode(200);
            return res;
        }
    }
}