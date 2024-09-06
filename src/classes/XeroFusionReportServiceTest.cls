@isTest
private class XeroFusionReportServiceTest {
    @TestSetup
    private static void setup(){
        insert new General_Configurations__c();
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
        List<IFW_IntegrationConfigItem__c> configItemsToInsert = new List<IFW_IntegrationConfigItem__c>();
        configItemsToInsert.add(createIFWConfigItem('ProfitAndLoss', IFWConfigObj.Id, 'https://api.xero.com/api.xro/2.0/Reports/ProfitAndLoss'));
        insert configItemsToInsert;
    }
    private static IFW_IntegrationConfigItem__c createIFWConfigItem(String entityName, String IFWConfigId, String endpoint) {
    	IFW_IntegrationConfigItem__c IFWConfigItemObj = new IFW_IntegrationConfigItem__c();
        IFWConfigItemObj.HTTP_Method__c = 'GET';
        IFWConfigItemObj.Timeout__c = 5000;
        IFWConfigItemObj.IFW_IntegrationConfig__c = IFWConfigId;
        IFWConfigItemObj.Entity_Name__c = entityName;
     	IFWConfigItemObj.Endpoint_URL__c = endpoint;
     	return IFWConfigItemObj;
    }
    @isTest
    private static void testXeroFusionReportService() {
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        Test.startTest();   
        String startDate = system.now().addDays(-7).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String endDate = system.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        XeroFusionReportService.getReportData(startDate, endDate, 'ProfitAndLoss', new Set<String>());
        Test.stopTest();
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
    }

    public class MockResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"Id":"bd4f0b6f-66f9-455d-b8ce-f8ea12896beb","Status":"OK","ProviderName":"API Explorer","DateTimeUTC":"\\/Date(1616583266085)\\/","Reports":[{"ReportID":"ProfitAndLoss","ReportName":"Profit and Loss","ReportType":"ProfitAndLoss","ReportTitles":["Profit & Loss","Metacube 24th March","1 March 2021 to 31 March 2021"],"ReportDate":"24 March 2021","UpdatedDateUTC":"\\/Date(1616583266085)\\/","Fields":[],"Rows":[{"RowType":"Header","Cells":[{"Value":""},{"Value":"31 Mar 21"}]},{"RowType":"Section","Title":"","Rows":[{"RowType":"Row","Cells":[{"Value":"Gross Profit"},{"Value":"0.00"}]}]},{"RowType":"Section","Title":"","Rows":[{"RowType":"Row","Cells":[{"Value":"Net Profit"},{"Value":"0.00"}]}]}]}]}');
            return res;
        }
    }
}