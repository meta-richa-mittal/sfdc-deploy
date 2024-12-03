
@isTest
private with sharing class IntegrityCheckForBRPSchedulerTest {

    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        CO_Header__c coHeader = TestUtil.createCOHeader(true, null);
        CO_Invoice_Header__c coinvoiceHeader1 = TestUtil.createCOInvoiceHeader(false, coHeader.Id, 'Active'); 
        coinvoiceHeader1.Available_For_BRP_Parts_Invoice_Sync__c = true;
        coinvoiceHeader1.Available_For_BRP_Repair_Order_Sync__c = true;
        coinvoiceHeader1.Available_For_BRP_RDR_Sync__c = true;
        DMLUtility.insertSobjectList('CO_Invoice_Header__c', coinvoiceHeader1);
    }
    
    @isTest
    private static void testIntegrityCheckForBRPSchMethods() {
        String coInvoiceHeaderQueryStr = 'SELECT ';
        for(String fieldName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            coInvoiceHeaderQueryStr += fieldName + ', ';
        }
        coInvoiceHeaderQueryStr = coInvoiceHeaderQueryStr.substring(0, coInvoiceHeaderQueryStr.length()-2);
        coInvoiceHeaderQueryStr += ' from CO_Invoice_Header__c where Available_For_BRP_Parts_Invoice_Sync__c = true OR Available_For_BRP_RDR_Sync__c = true OR Available_For_BRP_Repair_Order_Sync__c = true';
        List<CO_Invoice_Header__c> coInvoiceHeaderList =  Database.query(coInvoiceHeaderQueryStr);

        Test.setMock(HttpCalloutMock.class, new IntegrityCheckMockResponseGenerator());
        
        Test.startTest();     
        Datetime dateTimeNow = Datetime.now();
        dateTimeNow.addMinutes(1);
        String hour = String.valueOf(dateTimeNow.hour());
        String min = String.valueOf(dateTimeNow.minute()); 
        String ss = String.valueOf(dateTimeNow.second());
        String CRON_EXP = ss + ' ' + min + ' ' + hour + ' * * ?';
        String jobId = System.schedule('Test check', CRON_EXP, new IntegrityCheckForBRPScheduler());
        
        IntegrityCheckForBRPScheduler testobj = new IntegrityCheckForBRPScheduler();
        testobj.executeEmailScheduler();
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