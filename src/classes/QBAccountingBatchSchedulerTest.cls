/**
 * Author: Reena Singh
 * Since: Jul 21, 2020
 * Name: QBAccountingBatchSchedulerTest test class
 * Description: test Class for QBAccountingBatchScheduler.
**/

@isTest
public without sharing class QBAccountingBatchSchedulerTest {
	static String CRON_EXP = '0 0 0 * * ? *';	
	
	@testSetup
   	static void setup() {
   		TestUtil.setQuickBooksConfigurations(true);
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Test', '1111111112', null, null, false, true,'Individual','firstname', 'lastname', '9999999999', 'BillingStreet');
        
        CO_Header__c coHeader = TestUtil.createCOHeader(false, customer.Id);
        coHeader.CO_Type__c = 'Customer';
        insert coHeader;
        
        String soHeader = BPUtility.getDecodedString(CustomerOrderCtrl.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(CustomerOrderCtrl.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        
        Technician__c technicianRec = new Technician__c(Technician_Name__c = 'Test Technician', Active__c = true);
        insert technicianRec;
        
        User testUser = TestUtil.createUser(true, 'a@b.c', 'User', 'en_US', 'test.user@abc.com', 'Test');
        
        Hours_Logged__c hoursLoggedRec = new Hours_Logged__c();
        hoursLoggedRec.Technician__c = technicianRec.id;
        hoursLoggedRec.Time_Spent_h__c = 2;
        hoursLoggedRec.Start_Date_Time__c = datetime.newInstance(2019, 6, 14, 10, 30, 0);
        hoursLoggedRec.Work_Performed_Date__c = Date.newInstance(2019, 6, 9);
        hoursLoggedRec.End_Date_Time__c= datetime.newInstance(2017, 6, 14, 12, 30, 0);
        hoursLoggedRec.Available_For_QB_Sync__c = true;
        hoursLoggedRec.Service_Order_Header__c = soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id;

        insert hoursLoggedRec;
	}
   
    static testmethod void accSyncHoursLoggedTest() {
		Test.startTest();
		TestUtil.setQuickBooksConfigurations(false);
		Map<Id, Hours_Logged__c> hoursLoggedIdToRecMap = new Map<Id, Hours_Logged__c>([SELECT Id , Available_For_QB_Sync__c FROM Hours_Logged__c where Available_For_QB_Sync__c = true Order by CreatedDate ASC]);
   		system.assertEquals(true, hoursLoggedIdToRecMap.values()[0].Available_For_QB_Sync__c); 		
   		QBAccountingBatchScheduler hoursLoggedObj = new QBAccountingBatchScheduler(hoursLoggedIdToRecMap.keySet(), 'Hours Logged');
   		hoursLoggedObj.execute(null);
   		system.schedule('QBAccountingBatchSchedulerTest', CRON_EXP, hoursLoggedObj);
   		Test.stopTest();
   		
        system.assertEquals(false, [Select Id, Available_For_QB_Sync__c FROM Hours_Logged__c][0].Available_For_QB_Sync__c);
	}
}