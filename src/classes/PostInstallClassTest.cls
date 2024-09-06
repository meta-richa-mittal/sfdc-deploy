@isTest
private class PostInstallClassTest {
	
  	@testSetup
  	private static void setupTestData() {
  		TestDataFactory.disableFLSChecks();
 	}

    @isTest
    static void testInstallScript() {
        PostInstallClass postinstall = new PostInstallClass();
        Test.testInstall(postinstall, null);
        List<Post_Install_Log__c> logList = [SELECT Id FROM Post_Install_Log__c LIMIT 1];
      	System.assertEquals(logList.size(), 0);
    }

    @isTest
    static void testPostInstallWithScript() {
      	PostInstallService.getInstance().startService();
      	List<Post_Install_Log__c> logList = [SELECT Id FROM Post_Install_Log__c LIMIT 1];
      	System.assertEquals(logList.size(), 1);
    }
}