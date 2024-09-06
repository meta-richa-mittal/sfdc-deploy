@IsTest
private class BPWebServiceManagerTest {
    
    @TestSetup
    static void makeData(){
        TestDataFactory.disableFLSChecks();
        Account customerRec = TestDataFactory.createCustomer('Test Customer', 'Individual', 'Test', 'Customer');
    	CO_Header__c newCOHeader = TestDataFactory.createCoHeader(customerRec.Id);
        CO_Invoice_Header__c newCOInvoiceHeader = TestDataFactory.createCOInvoiceHeader(String.valueOf(newCOHeader.Id),'Invoiced');  
        TestDataFactory_V2.createTestDataForServiceJobStatus();

        String invoicedStatusId;
        String inProgressStatusId;
        for(SO_Status__c soStatus: [SELECT id, Name__c FROM SO_Status__c WHERE Name__c IN (:ServiceJobUtil.INVOICED, :ServiceJobUtil.IN_PROGRESS) LIMIT 2]) {
            if(soStatus.Name__c == ServiceJobUtil.INVOICED) {
                invoicedStatusId = soStatus.Id;
            } else if(soStatus.Name__c == ServiceJobUtil.IN_PROGRESS) {
                inProgressStatusId = soStatus.Id;
            }
        }
        Service_Order_Header__c newServiceOrderHeader = TestDataFactory.createSOHeader(String.valueOf(newCOHeader.Id));
        newServiceOrderHeader.Work_Status__c='Invoiced';
        newServiceOrderHeader.SO_Status_Ref__c = invoicedStatusId;
        upsert newServiceOrderHeader;
        Service_Order_Header__c newServiceOrderHeader2 = TestDataFactory.createSOHeader(String.valueOf(newCOHeader.Id));
 		newServiceOrderHeader2.Work_Status__c='InProgress';
        newServiceOrderHeader2.SO_Status_Ref__c = inProgressStatusId;
        upsert newServiceOrderHeader2;      
        Claim__c newClaim = new Claim__c();
        newClaim.Service_Order_Header__c = String.valueOf(newServiceOrderHeader2.Id);
        insert newClaim;
    }
    
    @IsTest
    private static void testForUnsubmittingClaim(){
        Service_Order_Header__c serviceOrderHeader = [SELECT Id,Work_Status__c from Service_Order_Header__c where Work_Status__c = 'Invoiced'];
        String soId  = String.valueOf(serviceOrderHeader.Id);     
        Test.startTest();
        String result = BPWebServiceManager.unsubmitClaimBySOId(soId);
        Test.stopTest();   
        System.assertEquals('Unsubmitting claim for an invoiced job is not allowed', result);     
    }
    
    @IsTest
    private static void testForDeleteClaim(){       
        Service_Order_Header__c serviceOrderHeader = [SELECT Id,Work_Status__c,SO_Status__c,Claim_Status__c, (Select Id from Claims__r) from Service_Order_Header__c where Work_Status__c = 'InProgress'];
        String soId  = String.valueOf(serviceOrderHeader.Id);             
        Test.startTest();
        String result = BPWebServiceManager.unsubmitClaimBySOId(soId);
        Test.stopTest();    
        Service_Order_Header__c newServiceOrderHeader = [SELECT Id,Work_Status__c,Claim_Status__c from Service_Order_Header__c where Work_Status__c = 'InProgress'];
        System.assertEquals('Unsubmitted',newServiceOrderHeader.Claim_Status__c);
    }
    
    @IsTest
    private static void testForNoServiceJobFound(){
        Service_Order_Header__c serviceOrderHeader = [SELECT Id,Work_Status__c from Service_Order_Header__c where Work_Status__c = 'InProgress'];
        String soId = 'a2C5f000001Kgf3EAC';      
        Test.startTest();
        String result = BPWebServiceManager.unsubmitClaimBySOId(soId);
        Test.stopTest();    
        System.assertEquals('No Service job found with id ' + soId ,result );
    }
    
    @IsTest
    private static void testForServiceJobIdBlank(){
        Service_Order_Header__c serviceOrderHeader = [SELECT Id,Work_Status__c from Service_Order_Header__c where Work_Status__c = 'InProgress'];
        String soId = '';    
        Test.startTest();
        String result = BPWebServiceManager.unsubmitClaim(soId);
        Test.stopTest();    
        System.assertEquals('Service job id cannot be blank',result );     
    }

}