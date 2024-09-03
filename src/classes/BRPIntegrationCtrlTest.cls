@isTest
private class BRPIntegrationCtrlTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForBRP();
        List<IFW_IntegrationConfig__c> IFWConfigObjList = [Select Id from IFW_IntegrationConfig__c];
        IFW_IntegrationConfigItem__c IFWConfigItemObj = TestDataFactory.createIFWConfigItemForBRP('Dealer', IFWConfigObjList[0].Id);
        insert new BRP_Settings__c(Dealer_Id__c = '0000691784');
        Account customer = TestUtil.createCustomer(false, 'test customer', 'customer@gmail.com', 'Jaipur', '8058704475');
        customer.Is_Customer__c = true;
        insert customer;
    }
    @isTest
    private static void testBRPIntegrationCtrl() {
        Test.setMock(HttpCalloutMock.class, new BRPMockResponseGenerator());
        Test.startTest();
        BRPIntegrationCtrl BRPIntegrationCtrlObj = new BRPIntegrationCtrl();
        BRPIntegrationCtrlObj.getDealerLocator();
        Account testCustomer = [Select Id, name from Account where Name = 'test customer'];

        system.assertEquals('test customer', testCustomer.name);
        Test.stopTest();
    }
    
}