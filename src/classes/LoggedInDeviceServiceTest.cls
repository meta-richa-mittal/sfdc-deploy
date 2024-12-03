
@isTest
private without sharing class LoggedInDeviceServiceTest {
     @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
    @isTest
    private static void saveDeviceInfoTest(){

        Branding_Location__c brandingLocationobj =TestDataFactory.createBrandingLocationobj();

        Cash_Drawer__c cashDrawerobj = TestDataFactory.createCashDrawer('CashDrawerName');

        Logged_In_Device__c loggedInDevice = TestDataFactory.createNewLoggedInDevice('LoggedInDeviceName',brandingLocationobj.Id,cashDrawerobj.Id);
        
        Test.startTest();
        LoggedInDeviceWrapper loggedInDeviceWrapperObj = LoggedInDeviceService.getDeviceInfoByDeviceUUID(loggedInDevice.Name);
        LoggedInDeviceService.saveDeviceInfo(System.JSON.serialize(loggedInDeviceWrapperObj));
        Test.stopTest();
        System.assertEquals(loggedInDeviceWrapperObj.Id, loggedInDevice.Id);

    }
}
