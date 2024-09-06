@isTest
private class ConfigurationScriptTest {
	
	@testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   	}
    
    static testMethod void testRunAll() {
        ConfigurationScript.runAll();
        
        List<SearchConfigurations__c> searchConfigurations = [Select id From SearchConfigurations__c];
        System.assertEquals(true, searchConfigurations.size() > 0);
        
        List<General_Configurations__c> generalConfigurations = [Select id, Related_List_Page_Size__c From General_Configurations__c];
        //System.assertEquals(10, generalConfigurations[0].Related_List_Page_Size__c);
        
        List<Widget__c> widgets = [Select id From Widget__c];
        System.assertEquals(8, widgets .size());
        
        List<Transaction_Type__c> transactionTypes = [Select id From Transaction_Type__c];
        System.assertEquals(7, transactionTypes.size());
        
        ConfigurationScript.deleteConfigurations();
    }
}