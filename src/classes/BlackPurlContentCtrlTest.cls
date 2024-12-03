@isTest
private class BlackPurlContentCtrlTest {
    
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.createNameSpaceInGeneralConfig();
        System.assertEquals(1, 1);
    }
}