/**
 * Author: Richa Mittal
 * Since: Jun 14, 2019
 * Name: AccSync_HoursLogged_Batch_Test
 * Description: batch test Class of Hours Logged Journal Entry sync to QuickBooks.
**/
@isTest
public class AccSync_HoursLogged_Batch_Test {
    static PaginationSorting pageSort;
    @testSetup
    static void setup() {
        TestUtil.setQuickBooksConfigurations(false);
    }
    
    private static void createHoursLogged() {
        //Create Customer
        Account customer = TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'Agra', '1111111112', null, null, false, true,'Individual','firstname1', 'lastname', '9999999999', 'BillingStreet');
        
        // Create Customer Order
        CO_Header__c coHeader = TestUtil.createCOHeader(false, customer.Id);
        coHeader.CO_Type__c = 'Customer';
        insert coHeader;
        
        // Create Service Job
        String soHeader = BPUtility.getDecodedString(CustomerOrderCtrl.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
        String SOHeaderDetails = BPUtility.getDecodedString(CustomerOrderCtrl.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
        SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
        
        // Create Technician
        Technician__c technicianRec = new Technician__c(Technician_Name__c = 'Test Technician', Active__c = true, Labour_Cost_Per_Hour__c = 150);
        insert technicianRec;
        
        // Create User
        User testUser = TestUtil.createUser(true, 'a@b.c', 'User', 'en_US', 'test.user@abc.com', 'Test');
        
        // Create Hours Logged on Service Job
        Hours_Logged__c hoursLoggedRec = new Hours_Logged__c();
        hoursLoggedRec.Technician__c = technicianRec.id;
        hoursLoggedRec.Time_Spent_h__c = 2;
        hoursLoggedRec.Start_Date_Time__c = datetime.newInstance(2019, 6, 14, 10, 30, 0);
        hoursLoggedRec.Work_Performed_Date__c = Date.newInstance(2019, 6, 9);
        hoursLoggedRec.End_Date_Time__c= datetime.newInstance(2017, 6, 14, 12, 30, 0);
        hoursLoggedRec.Service_Order_Header__c = soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id;
        insert hoursLoggedRec;
    }
    
    private static testmethod void syncHoursLoggedTest() {
    	General_Configurations__c generalConfig = General_Configurations__c.getInstance();
        generalConfig.Technician_Hours_Costing__c = true;
        upsert generalConfig;
        
        Test.startTest();
        createHoursLogged();
        Test.stopTest();
        
        List<Hours_Logged__c> hoursLoggedList = [Select QB_Accounting_Id__c from Hours_Logged__c];
        system.assertEquals('675', hoursLoggedList[0].QB_Accounting_Id__c); 
    }
}