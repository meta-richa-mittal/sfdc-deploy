@istest
private without sharing class IntegrityChkActAccTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }
    @isTest
    private static void testIntegrityCheckForActiveCtrl() {
        BPScriptUtility.disbaleTrigger('PartTrigger');
        Account accRec = TestDataFactory.createVendor('newacc');

        Category__c catRec = TestDataFactory.createCategory('categoryName');

        Part__c partRec = TestDataFactory.createNewPart(accRec.Id, catRec.Id);

        DMLUtility.insertSobjectList('General_Configurations__c', new General_Configurations__c(Enable_Xero_Accounting__c = true));
        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigForXero();
        
        List<IFW_IntegrationConfig__c> configList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Type__c' => 'Accounting',
                                                                                                                'Accounting_Enabled__c' => true});
		
        Test.startTest();
        IntegrityCheckForActiveAccIntegrtionCtrl testObj = new IntegrityCheckForActiveAccIntegrtionCtrl();
        testObj.sendIntegrityCheckMailToSupportTeam();
        System.assertEquals(1, configList.size());
        Test.stopTest();

    }
}
