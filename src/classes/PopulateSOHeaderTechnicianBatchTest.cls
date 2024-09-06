
@isTest
private without sharing class PopulateSOHeaderTechnicianBatchTest {

    @TestSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        
        Account accRec = TestDataFactory.createVendor('newacc');

        CO_Header__c customerOrderRec = TestDataFactory.createCoHeader(accRec.Id);
        
        Service_Order_Header__c soHeaderRec = TestDataFactory.createSOHeader(customerOrderRec.Id);
        soHeaderRec.Work_Status__c = ServiceJobUtil.NEW_JOB;
        soHeaderRec.Total_Hours_Billed__c = 3;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);

        Task__c task = TestDataFactory.createTask();
        Technician__c technician = TestDataFactory.createTechnician();
        Hours_Logged__c hrsLogged = TestDataFactory.createHoursLogged(technician.Id, soHeaderRec.Id, task.Id);
        hrsLogged.Is_Removed__c = false;
        DMLUtility.updateSobjectList('Hours_Logged__c', hrsLogged);
    }

    @isTest
    private static void PopulateSOHeaderTechnicianMethodsTest(){
        Service_Order_Header__c soHeaderRec = [Select Id,Technician_Name__c From Service_Order_Header__c];
        System.assertEquals(null,soHeaderRec.Technician_Name__c);
        Test.startTest();
        Id batchprocessid =Database.executeBatch(new PopulateSOHeaderTechnicianNameBatch());
        Test.stopTest();

        Service_Order_Header__c soHeaderRec1 = [Select Id,Technician_Name__c From Service_Order_Header__c];
        System.assertEquals('Test Name',soHeaderRec1.Technician_Name__c);
        
        }
    
}