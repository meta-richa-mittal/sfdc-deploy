/**
 * Author: Manoj Sharma
 * Since: Dec 23, 2022
 * Name: MFAAuthServiceTest
 * Description: Controller test Class of MFAAuthService.
**/
@isTest
private class MFAServiceTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.createUser(true, 'a@b.c', 'Sharma', 'en_US', 'manoj1.Sharma@metacube.com', 'sshar');
    }
    
    static testMethod void testMFAMethods() {
        User testUser = [Select Id from User Where Email = 'a@b.c'][0];
        Test.startTest();
        try{
			UserSettingCtrl.enableDisableMFA(BPUtility.getEncodedString(testUser.Id), true);
        } catch(Exception e){}
        system.assertEquals(false, UserSettingCtrl.isMFAVerificationMethodRegistered(BPUtility.getEncodedString(testUser.Id)));
        UserSettingCtrl.deregisterMFAVerificationMethod(BPUtility.getEncodedString(testUser.Id));
        UserSettingCtrl.enableDisableMFA(BPUtility.getEncodedString(testUser.Id), false);
        system.assertEquals(true, [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id AND PermissionSet.Name = :UserSettingCtrl.ENABLE_MFA].isEmpty());
        Test.stopTest();
    }
}