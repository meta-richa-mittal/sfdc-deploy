@isTest
private class XeroAccountDTOTest {
    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
    }

    @isTest
    private static void testXeroAccountDTO() {
        Test.startTest();     
        String Code = 'Test code';
        XeroAccountDTO result = new XeroAccountDTO(Code);
        system.assertEquals('Test code', result.code);
        Test.stopTest();
    }
}