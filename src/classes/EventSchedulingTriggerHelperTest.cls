@isTest
private class EventSchedulingTriggerHelperTest {
    
    static testMethod void eventSchedulingTest() {
        TestDataFactory.createShopSettings('Monday');
        TestDataFactory.createShopSettings('Tuesday');
        TestDataFactory.createShopSettings('Wednesday');
        TestDataFactory.createShopSettings('Thursday');
        TestDataFactory.createShopSettings('Friday');
        TestDataFactory.createShopSettings('Saturday');
        TestDataFactory.createShopSettings('Sunday');
        
        Event__c eventRec = new Event__c();
        eventRec.Estimated_Hours__c = 1;
        insert eventRec;
        
        Event_Scheduling__c schedulingRec = new Event_Scheduling__c(Event__c = eventRec.Id);
        schedulingRec.Start_Date_Time__c = DateTime.newInstance(2020, 01, 28, 8, 0, 0);
        schedulingRec.End_Date_Time__c = schedulingRec.Start_Date_Time__c.addHours(1);
        schedulingRec.Hours__c = 1;
        insert schedulingRec;
        
        eventRec = [Select Id, Start_DateTime__c from Event__c where Id =: eventRec.Id];
        system.assertEquals(schedulingRec.Start_Date_Time__c, eventRec.Start_DateTime__c);
        
        schedulingRec.Start_Date_Time__c = schedulingRec.End_Date_Time__c;
        schedulingRec.End_Date_Time__c = schedulingRec.Start_Date_Time__c.addHours(1);
        update schedulingRec;
        
        eventRec = [Select Id, Start_DateTime__c from Event__c where Id =: eventRec.Id];
        system.assertEquals(schedulingRec.Start_Date_Time__c, eventRec.Start_DateTime__c);
        
        delete schedulingRec;
        
        Event__c afterDeleteEventRec = [Select Id, Start_DateTime__c from Event__c where Id =: eventRec.Id];
        system.assertEquals(eventRec.Start_DateTime__c, afterDeleteEventRec.Start_DateTime__c);
    }
}