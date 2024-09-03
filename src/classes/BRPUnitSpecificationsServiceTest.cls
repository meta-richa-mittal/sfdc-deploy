@isTest
private class BRPUnitSpecificationsServiceTest {
    public class BRPUnitSpecificationsServicePositiveRespone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"serial_no": "3JBLGAR15GJ000100", "model_year": 2016,"model_number": "0002WGB00","model_name": "ATV OUTLANDER L DPS 450EFI Y 16 EUR","model_code": "","brands": [ "CANAM"],"product_line": "ATV","product_type": "10","manufacturer_name": "BRP MEXICO S.A. DE C.V.","color_code_description": "","max_no_of_passengers": null, "engine_code": "","engine_code_description": "", "engine_displacement": 427,"engine_power": null,"no_of_cylinders": 1, "gross_weight_vehicle_rating": null, "net_weight": 330.669,"weight_unit": "KG"}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }

    public class BRPUnitSpecificationsServiceNegativeRespone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "400","id": "rrt-074faba1d0796ac77-c-ea-24394-1768654-1","title": "bad_request","meta": { "service": "00","detail": "Path not found."}}');
            res.setStatusCode(400);
            res.setStatus('error');
            return res;
        }
    }

    @testSetup
    private static void testSetup() {
        TestDataFactory.disableFLSChecks(); 
        IFW_IntegrationConfig__c ifwConfigBRP = TestDataFactory.createIFWConfigForBRP();
        IFW_IntegrationConfig__c ifwConfigBRP2 = TestDataFactory.createIFWConfigForBRP2();
        IFW_IntegrationConfigItem__c ifwConfigItem = TestDataFactory.createIFWConfigItemForBRP2('GetUnitSpecification', ifwConfigBRP2.Id);
        IFW_IntegrationConfigItem__c ifwConfigItem1 = TestDataFactory.createIFWConfigItemForBRP2('Token', ifwConfigBRP2.Id);
        BRP_Settings__c brpConfig = TestDataFactory.createBRPConfig();
    }

    @isTest
    private static void testUnitSpecificationsForPositiveRes() { 
        Test.setMock(HttpCalloutMock.class, new BRPUnitSpecificationsServicePositiveRespone());
        Test.startTest();
        String result = BRPUnitSpecificationsService.getUnitSpecification('3JBLGAR15GJ000100');
        Test.stopTest();
        BRPVehicleResponseWrapper.Vehicle vehicleObj = (BRPVehicleResponseWrapper.Vehicle) 
                                    System.JSON.deserialize(result, BRPVehicleResponseWrapper.Vehicle.class);
        List<WebService_Log__c> webServiceList = [SELECT Id FROM WebService_Log__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'BRP 2.0'];
        List<BRP_log__c> brpLogList = [SELECT Id FROM BRP_log__c WHERE Apex_Class__c = 'BRPUnitSpecificationsService'];
        System.assertEquals(0, brpLogList.size());
        System.assertEquals(1, webServiceList.size());
        System.assertEquals('BRP MEXICO S.A. DE C.V.', vehicleObj.Make);
    }

    @isTest
    private static void testUnitSpecificationsForNegativeRes() { 
        Test.setMock(HttpCalloutMock.class, new BRPUnitSpecificationsServiceNegativeRespone());
        Test.startTest();
        String result = BRPUnitSpecificationsService.getUnitSpecification('3JBLGAR15GJ000100');
        Test.stopTest();
        ResponseWrapper responseObj = (ResponseWrapper) System.JSON.deserialize(result, ResponseWrapper.class);
        List<WebService_Log__c> webServiceList = [SELECT Id FROM WebService_Log__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'BRP 2.0'];
        System.assertEquals(1, webServiceList.size());
        System.assertEquals('No such vehicle found', responseObj.response);
    }

    @isTest
    private static void testUnitSpecificationsForWrongVin() { 
        Test.startTest();
        String result = BRPUnitSpecificationsService.getUnitSpecification(null);
        Test.stopTest();
        ResponseWrapper responseObj = (ResponseWrapper) System.JSON.deserialize(result, ResponseWrapper.class);
        System.assertEquals('No such vehicle found', responseObj.response);
    }

}