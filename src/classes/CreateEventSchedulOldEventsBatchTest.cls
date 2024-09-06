@isTest
private class CreateEventSchedulOldEventsBatchTest {
    @TestSetup
    private static void setup(){
        Technician__c technician = new Technician__c(Type__c = 'Technician');
        insert technician;
        Event__c Event = new Event__c(Technician__c = technician.id);
        insert Event;
    }

    @isTest
    private static void testCreateEventSchedulingForOldEventsBatchMethods() {
        Test.startTest();
        Database.executebatch(new CreateEventSchedulingForOldEventsBatch());
        Test.stopTest();
        list<Event__c> Event = [SELECT id from Event__c limit 1];
        system.assertEquals(1, Event.size());
    }
}