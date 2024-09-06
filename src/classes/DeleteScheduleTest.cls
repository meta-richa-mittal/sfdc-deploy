@isTest
private class DeleteScheduleTest {
    @testSetup
    private static void setupTestData() {
		TestDataFactory.disableFLSChecks();
   }

    static testMethod void executeSchedulerTest() {
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(50);
        DeleteScheduler.executeDataScheduler(dt.second(),dt.minute(),dt.hour(),dt.day(),dt.month(),dt.year());
        Test.StopTest();
        system.assertEquals(0, [select Id from Account limit 1].size());
    }
}