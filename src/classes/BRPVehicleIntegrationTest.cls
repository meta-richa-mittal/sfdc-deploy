@isTest
private class BRPVehicleIntegrationTest {
    static string vin = 'xyz12345';
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        IFW_IntegrationConfig__c IFWConfigObj = TestDataFactory.createIFWConfigForBRP();
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemBRP('GetVehicleSpecification', IFWConfigObjList[0].Id);
        IFWConfigItemObj.Endpoint_URL__c = 'https://qa-api.brp.com/facade/star/services/VehicleSpecifications?VehicleID=' + vin;
        IFWConfigItemObj.HTTP_Method__c = 'GET';
        update IFWConfigItemObj;
        insert new BRP_Settings__c(Dealer_Id__c = '0000691784', Radius_Measure__c = 'mile', Radius__c = 100);
    }
    @isTest
    private static void testBRPVehicleIntegration() {
        Test.setMock(HttpCalloutMock.class, new BRPVehicleIntegrationMockTest('Exist'));
        Test.startTest();
        String res = BRPVehicleIntegration.getVehicleSpecification(vin);
        List<IFW_IntegrationConfigItem__c> IFWIntegrationConfigList = [Select Id, name from IFW_IntegrationConfigItem__c];
        system.assertEquals(1, IFWIntegrationConfigList.size());
        Test.stopTest();
    }
    @isTest
    private static void testBRPVehicleIntegration1() {
        Test.setMock(HttpCalloutMock.class, new BRPVehicleIntegrationMockTest('Not Exist'));
        Test.startTest();
        String res = BRPVehicleIntegration.getVehicleSpecification(vin);
        List<IFW_IntegrationConfigItem__c> IFWIntegrationConfigList = [Select Id, name from IFW_IntegrationConfigItem__c];
        system.assertEquals(1, IFWIntegrationConfigList.size());
        Test.stopTest();
    }
}