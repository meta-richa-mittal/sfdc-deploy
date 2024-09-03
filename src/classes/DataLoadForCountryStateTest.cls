@isTest
private class DataLoadForCountryStateTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }

    static testMethod void myUnitTest() {
        DataLoadForCountryState DataLoadForCountryStateCtrl = new DataLoadForCountryState();
        List<Country__c> countryList = [select Id from Country__c];
        system.assertEquals(true, countryList.size() > 0);
    }
}