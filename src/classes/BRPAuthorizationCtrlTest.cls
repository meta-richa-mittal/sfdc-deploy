@IsTest
private class BRPAuthorizationCtrlTest {
    
    @IsTest
    private static void testClass(){
        BRPAuthorizationCtrl newInstance = new BRPAuthorizationCtrl();
        Pagereference result = newInstance.authorizeBRP();
        System.assertNotEquals(Null,result);
    }
    
   @IsTest
    private static void saveAccessTokensTest(){
        String jsonStr = '{"oauth_token":"your_oauth_token","oauth_verifier":"your_oauth_verifier","org":"your_org","code":"your_code","scope":"your_scope"}';
        String encodedUrlParams = BPUtility.getEncodedString(jsonStr);
        Test.startTest();
        String result = BRPAuthorizationCtrl.saveAccessToken(encodedUrlParams);
        Test.stopTest();
        System.assertNotEquals(Null,result);
    }
}