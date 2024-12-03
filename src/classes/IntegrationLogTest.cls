
@isTest
private with sharing class IntegrationLogTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }

    @isTest
    private static void createLogTest(){
        Test.startTest();
        IntegrationLog.createLog('cls', 'method', 'errMsg', 'errorCode', 'stackTrace', 'methodParams');
        IntegrationLog.Error errorObj = new IntegrationLog.Error( 'cls', 'method', 'errMsg', 'errorCode', 'stackTrace', 'methodParams');
        System.assertEquals('cls', errorObj.ApexClass);
        System.assertEquals('errMsg',errorObj.Info);
        Test.stopTest();
    }

    @isTest
    private static void informationConstructorTest(){
        Test.startTest();
        IntegrationLog.Information infoObj = new IntegrationLog.Information( 'cls', 'method', 'recId','msg');
        System.assertEquals('cls', infoObj.ApexClass);
        System.assertEquals('msg',infoObj.Info);
        Test.stopTest();
    }

}
