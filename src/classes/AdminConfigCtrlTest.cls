/**
* Author: Nidhi Sharma
* Since: Sep 17, 2015
* Name: AdminConfigCtrlTest
**/
@isTest
private class AdminConfigCtrlTest {
    
    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        new AdminConfigCtrl();	//for code coverage
        
        Payment_Terminal__c terminalRec = new Payment_Terminal__c();
        terminalRec.Registration_Code__c = 'Test001';
        terminalRec.Nickname__c = 'Terminal 02';
        terminalRec.Preferred_Payment_Id__c = '2342304203';
        terminalRec.Status__c = 'Active';
        DMLUtility.insertSobjectList('Payment_Terminal__c', terminalRec);
        
        General_Configurations__c generalConfig = new General_Configurations__c();
        generalConfig.Home_Search_Grid_Page_Size__c = 10;
        generalConfig.Related_List_Page_Size__c = 20;
        generalConfig.Max_Number_of_Users__c = 5;
        generalConfig.Max_Number_of_Technicians__c = 7;
        generalConfig.Bar_Code_Label_Size__c = 'Large';
        generalConfig.Dashboard_Refresh_Minutes__c = 60;
        DMLUtility.insertSobjectList('General_Configurations__c', generalConfig);
        
        Configurations__c configuration = new Configurations__c();
        configuration.Tax_Included_Pricing__c = true;
        configuration.Cash_Payment_Rounding_Factor__c = 5;
        configuration.Enhanced_Tax_Calculations__c = false;
        DMLUtility.insertSobjectList('Configurations__c', configuration);
        
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile profileRec = [SELECT Id FROM Profile WHERE Name='Blackpurl'];
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profileRec.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        insert userRecord;
 
        IFW_IntegrationConfig__c ifwConfig = new IFW_IntegrationConfig__c(Integration_Name__c='BRP Integration',Enabled__c=false);
        insert ifwConfig;
        
        BRP_Vendors_List__c newBRPVendor = new BRP_Vendors_List__c();
        newBRPVendor.Name='Abhi';
        newBRPVendor.Is_Used_For_Parts_Ordering__c=true;
        insert newBRPVendor;  
        
        Unit_Data_Field_Config__c newDataFieldConfig = new Unit_Data_Field_Config__c();
        newDataFieldConfig.Name = 'Test Name';
        newDataFieldConfig.Display_Label__c = 'Test Label';
        insert newDataFieldConfig;
    }
    
    /*public static void insertPermissionSet(){        
        PermissionSet permSet = new PermissionSet();
        permSet.Name='Password_Never_Expire';
        permSet.Label='Password_Never_Expire';
        insert permset;
        
        PermissionSet passwordExpirePermSet = new PermissionSet();
        passwordExpirePermSet.Name = 'Password_Expire';
        passwordExpirePermSet.Label = 'Password_Expire';
        insert passwordExpirePermSet;
    }*/
    
    @isTest
    private static void testConfig() {
        AdminPreferredPaymentConfigWrapper config = (AdminPreferredPaymentConfigWrapper) System.JSON.deserialize(
            BPUtility.getDecodedString(AdminConfigCtrl.getPreferredPaymentConfig()), 
            AdminPreferredPaymentConfigWrapper.class
        );
        config.PrivateKey = '279349234_private';
        config.PublicKey = '279349234_public';
        AdminConfigCtrl.configurePreferredPaymentIntegration(BPUtility.getEncodedString(System.JSON.serialize(config)));
        system.assertEquals(7, [Select Id FROM IFW_IntegrationConfigItem__c WHERE IFW_IntegrationConfig__r.Integration_Name__c =: PreferredPaymentIntegrationService.integrationName].size());
    }
    
    @isTest
    private static void testGeneralInfoConfig() {
        String orgInfo = AdminConfigCtrl.getGeneralInfoConfig();
        AdminGeneralInformationConfigWrapper config = (AdminGeneralInformationConfigWrapper) System.JSON.deserialize(BPUtility.getDecodedString(orgInfo), AdminGeneralInformationConfigWrapper.class);
        config.LabelSize = 'Small';
        AdminConfigCtrl.setCompanyGeneralInfo(BPUtility.getEncodedString(System.JSON.serialize(config)));
        system.assertEquals('Small', General_Configurations__c.getOrgDefaults().Bar_Code_Label_Size__c);
    }
    
    @isTest
    private static void testCoverage() {
        String url = BPUtility.getDecodedString(AdminConfigCtrl.getAccountingReconciliationTabURL());
        AdminConfigCtrl.getAccountingReconciliationByDate(BPUtility.getEncodedString('1/1/2022'));
        system.assertNotEquals(null, url);
    }
  
    @IsTest
    private static void getAllPPTerminalListTest(){
        String encodedTerminals = BPUtility.getDecodedString(AdminConfigCtrl.getAllPPTerminalList());
        System.assertNotEquals(null,encodedTerminals);
    }
    
    @IsTest
    private static void testGetAllUnitMakes(){
        String getAllUnitMakesResult = BPUtility.getDecodedString(AdminConfigCtrl.getAllUnitMakes());
        System.assertNotEquals(null,getAllUnitMakesResult);
    }
    
    @IsTest
    private static void testSaveBRPConfig(){
        String brpConfigJsonStr =AdminConfigCtrl.getBRPConfig();
        String result = AdminConfigCtrl.saveBRPConfig(brpConfigJsonStr);
        System.assertEquals(BPUtility.getEncodedString(''),result);
    }
    
    @IsTest
    private static void authorizeBRPTest(){
        String result = AdminConfigCtrl.authorizeBRP();
        System.assertNotEquals(null,result);
    }
    
    @IsTest
    private static void syncTerminalDetailsFromPPTest(){
        String existingPPTerminalJson = '{"id":"2342304203","nickname":"Terminal 02"}';
        Test.startTest();
        ResponseWrapper responseObj = AdminConfigService.syncTerminalDetailsFromPP(existingPPTerminalJson);     
        Test.stopTest(); 
        system.assertEquals(200,responseObj.responseCode);
    }
    
    @IsTest
    private static void testGetNextDateForSpecifiedDay(){
        String testDayAfterName = 'Sat';
        String testDayBeforeName = 'Tue';  
        Test.startTest();
        DateTime resultOfNextDay = AdminConfigService.getNextDateForSpecifiedDay(testDayAfterName);
        DateTime resultOfPreviousDay = AdminConfigService.getNextDateForSpecifiedDay(testDayBeforeName);
        Test.stopTest();
        System.assertNotEquals(null, resultOfNextDay);
        System.assertEquals(testDayAfterName, resultOfNextDay.format('E'));
        System.assertEquals(testDayBeforeName, resultOfPreviousDay.format('E'));    
    }
    
    @IsTest
    private static void testResetAllUsersTimezone(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        String timeZone = 'America/Denver'; 
        Test.startTest();
        String result = AdminConfigService.resetAllUsersTimezone(timeZone);
        Test.stopTest();
        List<User> userList = [SELECT Id, Username, TimeZoneSidKey FROM User];
        System.assertNotEquals(null,userList[0].TimeZoneSidKey);   
    }

    @IsTest
    private static void testGetAccountingReconciliationTabURL(){
        String url = BPUtility.getDecodedString(AdminConfigCtrl.getAccountingReconciliationTabURL());
        System.assertNotEquals(null, url);
    }
    
    /*@IsTest
    private static void testCreatePasswordNeverExpirePS(){
        insertPermissionSet(); 
        Test.startTest();
        AdminConfigService.createPasswordNeverExpirePS();
        Test.stopTest();
        List<PermissionSet> permSetListNeverExpire = [SELECT Id,PermissionsPasswordNeverExpires FROM PermissionSet WHERE Name = 'Password_Never_Expire'];
        system.assertEquals(true,permSetListNeverExpire[0].PermissionsPasswordNeverExpires);       
        List<PermissionSet> permSetListExpires = [SELECT Id,PermissionsPasswordNeverExpires FROM PermissionSet WHERE Name = 'Password_Expire'];
        system.assertEquals(false, permSetListExpires[0].PermissionsPasswordNeverExpires);
    }*/
    
    @IsTest
    public static void testDisableBRPPartsOrder(){
        List<BRP_Vendors_List__c> brpIdentifierList = [SELECT Id, Is_Used_For_Parts_Ordering__c FROM BRP_Vendors_List__c WHERE Is_Used_For_Parts_Ordering__c = true];     
        Test.startTest();
        AdminConfigService.disableBRPPartsOrder();
        String result = AdminConfigCtrl.disableBRPPartsOrder();
        Test.stopTest();      
        List<BRP_Vendors_List__c> updatedBRPIdentifierList = [SELECT Id, Is_Used_For_Parts_Ordering__c FROM BRP_Vendors_List__c];
        system.assertEquals(false, updatedBRPIdentifierList[0].Is_Used_For_Parts_Ordering__c);
        System.assertEquals(BPUtility.getEncodedString(''),result);
    }
    
    @isTest
    public static void testSavePPConfigChange() {
        String preferredPaymentConfigJsonStr = BPUtility.getDecodedString(AdminConfigCtrl.getPreferredPaymentConfig());
        String preferredPaymentConfigJsonStr2 = AdminConfigCtrl.getPreferredPaymentConfig();
        Test.startTest();
        AdminConfigService.savePPConfigChange(preferredPaymentConfigJsonStr);
        String savePPConfigCtrlResult = AdminConfigCtrl.savePPConfigChange(preferredPaymentConfigJsonStr2);
        Test.stopTest();
        List<Configuration_List__c> configList = [SELECT Value__c FROM Configuration_List__c WHERE Name = 'Max Credit Amount'];
        System.assertEquals(1, configList.size());
        System.assertEquals('0', configList[0].Value__c);
        System.assertEquals(BPUtility.getEncodedString(''),savePPConfigCtrlResult);
    }
     
    @IsTest
    public static void testToggleConfigurations(){
        String configJson = '{"IsIFWToggle":true,"IntegrationName":"TestIntegration","Enabled":false}';
        Test.startTest();
        AdminConfigService.toggleConfigurations(configJSON);
        Test.stopTest();
        List<IFW_IntegrationConfig__c> updatedIFWConfigs = [select id,Enabled__c from IFW_IntegrationConfig__c where Integration_Name__c = 'BRP Integration'];
        system.assertEquals(false,updatedIFWConfigs[0].Enabled__c);
    }
    @IsTest
    private static void getUnitDataFieldConfigTest(){
        Test.startTest();
        List<AdminConfigWrapper.UnitDataFieldConfigWrapper> resultList = AdminConfigService.getUnitDataFieldConfig();
        Test.stopTest();
        System.assertNotEquals(Null,resultList);
    }
    
    @IsTest
    public static void deleteIFWConfigAndItemsTest(){
        List<IFW_IntegrationConfig__c> IFW_ConfigList = [SELECT Id FROM IFW_IntegrationConfig__c];
        Test.startTest();
        AdminConfigService.deleteIFWConfigAndItems();
        Test.stopTest();
        List<IFW_IntegrationConfig__c> updatedIFW_ConfigList = [SELECT Id FROM IFW_IntegrationConfig__c];
        system.assertEquals(0,updatedIFW_ConfigList.size());
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }    
}