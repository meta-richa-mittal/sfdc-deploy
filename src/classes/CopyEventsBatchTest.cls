@IsTest
private class CopyEventsBatchTest {
    
    @TestSetup 
    static void setup() {
        List<Event> eventList = new List<Event>();
        for(Integer i=0;i<10;i++) {
            eventList.add(new Event(Title__c = 'Event ' + i, DurationInMinutes = 1, ActivityDateTime = System.today()));
        }
        insert eventList;
    }
    
    @IsTest
    private static void testCopyEvent() {
        Test.startTest();
        Database.executeBatch(new CopyEventsBatch());
        Test.stopTest();
        
        System.assertEquals(10, [SELECT count() FROM Event__c]);
    }
}