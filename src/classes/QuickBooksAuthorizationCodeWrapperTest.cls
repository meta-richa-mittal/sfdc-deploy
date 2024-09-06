/**
 * Author: Namarta Gocher
 * Since: Feb 28, 2022
 * Name: QuickBooksAuthorizationCodeWrapperTest
 * Description: Test class of QuickBooksAuthorizationCodeWrapper 
**/
@isTest
private without sharing class QuickBooksAuthorizationCodeWrapperTest {
    @testSetup
    private static void setup() {
        TestDataFactory.disableFLSChecks();
        IFW_IntegrationConfig__c integrationConfig = TestDataFactory.createIFWConfigForDTO();
        integrationConfig.Client_Id_Long__c = 'ClientID';
        integrationConfig.Client_Secret_Long__c = 'Clientsecret';
        update integrationConfig;
   	    System.assert(true,true);
    }
   @istest
   private static void constructorTest(){
        IFW_IntegrationConfig__c integrationConfig = [Select Client_Id_Long__c,Client_Secret_Long__c From IFW_IntegrationConfig__c Where Subscriber_Rec_Id__c='6001'];
        Test.startTest();
        QuickBooksAuthorizationCodeWrapper obj = new QuickBooksAuthorizationCodeWrapper();
        QuickBooksAuthorizationCodeWrapper testobj = new QuickBooksAuthorizationCodeWrapper(integrationConfig);
        Test.stopTest();
        System.assertEquals('ClientID' , testobj.ClientId);
        System.assertEquals('Clientsecret' , testobj.ClientSecret);
    }
}