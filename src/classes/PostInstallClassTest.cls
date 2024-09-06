@isTest
private class PostInstallClassTest {

    @isTest
    static void testInstallScript() {
        PostInstallClass postinstall = new PostInstallClass();
        Test.testInstall(postinstall, null);
        List<Accounting_Data_Migration__c> admList = [SELECT id, name from Accounting_Data_Migration__c limit 20];
        System.assert(admList.size() > 0, 'Filter not found');
    }

    @isTest
    static void testPostInstallWithScript() {
      PostInstallService.getInstance().startService();
      List<Post_Install_Log__c> logList = [SELECT Id FROM Post_Install_Log__c LIMIT 1];
      System.assertEquals(logList.size(), 1);
    }
}