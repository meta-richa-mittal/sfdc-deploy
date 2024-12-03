
@isTest
private without sharing class NotesServiceTest {

    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        
        Account accRec = TestDataFactory.createCustomer('customerName', 'customerType', 'firstName', 'lastName');

        Notes__c notesRec = TestDataFactory.createNotes(); 
    }

    @isTest
    private static void deleteNotesTest(){
        List<Notes__c> notesRecList = [Select Id,Description__c From Notes__c];
        Set<Id> notesIdSet = new Set<Id>();

        for(Notes__c notesRec: notesRecList){
            notesIdSet.add(notesRec.Id);
        }

        Test.startTest();
        NotesService.deleteNotesRecords(notesIdSet);
        List<Notes__c> afterDeteteNotesRecList = [Select Id,Description__c From Notes__c];
        Test.stopTest();
        System.assertEquals(notesRecList.size()-1, afterDeteteNotesRecList.size());
        
    }

    @isTest
    private static void populateNotesLookupTest(){
        Event eventRec = TestDataFactory.createNewEvent();

        Test.startTest();
        Event newEventRec = NotesService.populateNotesLookup(eventRec, 'This is a concern');
        System.assertEquals(eventRec.Id, newEventRec.Id); 
        Test.stopTest();
    }

    @isTest
    private static void populateConcernsOnSOTest(){
        Notes__c notesRec=[Select Id,Description__c from Notes__c];
        Account accRec = [Select Id,Name from Account Limit 1];

        CO_Header__c customerOrderRec = TestDataFactory.createCoHeader(accRec.Id);

        Service_Order_Header__c soHeaderRec = TestDataFactory.createSOHeader(customerOrderRec.Id);
        soHeaderRec.Work_Status__c = 'New';
        soHeaderRec.Total_Hours_Billed__c = 3;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);

        Test.startTest();
        NotesService.populateConcernsOnSO(soHeaderRec, notesRec.Id);
        System.assertEquals('Test Description', soHeaderRec.SO_Concern__c);
        Test.stopTest();
    }

    @isTest
    private static void populateNotesOnAppointmentTest(){
        Account accRec = [Select Id,Name from Account Limit 1];
        Notes__c notesRec = [Select Id,Description__c From Notes__c];

        Event__c eventRec = TestDataFactory.createNewEventc();
        eventRec.Appointment_Concern__c = 'Appointment_Concern\nAppointment_Concern';
        eventRec.Customer__c = accRec.Id;
        DMLUtility.updateSobjectList('Event__c', eventRec);
        
        Test.startTest();
        AppointmentWrapper testWrapperObj = new AppointmentWrapper(eventRec);
        NotesService.populateNotesOnAppointment(testWrapperObj, notesRec.Id);
        System.assertEquals(3, testWrapperObj.Concern.size());
        Test.stopTest();
    }

    @isTest
    private static void saveNotesTest(){
        Account accRec = [Select Id,Name from Account Limit 1];
        Notes__c notesRec = [Select Id,Description__c From Notes__c];
        
        NotesService.NotesWrapper newWrapper = new NotesService.NotesWrapper(accRec.Id, notesRec.Description__c);
        String jsonString = System.JSON.serialize(newWrapper);
        
        Test.startTest();
        NotesService.saveNotes(jsonString);
        Test.stopTest();
    }
}