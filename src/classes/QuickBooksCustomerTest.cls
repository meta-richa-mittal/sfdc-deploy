@isTest
public without sharing class QuickBooksCustomerTest {
	@testSetup
    static void setup() {
        TestDataFactory.disableFLSChecks();
        TestUtil.setQuickBooksConfigurations(false);
    }
	private static Integer uniqueNumber = 1;
	static testmethod void testCreateCustomer() {
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Customer' , IFWConfigObj[0].Id);
   		Account testCustomer = QuickBooksCustomerTest.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123', null, null, false, true, null, null, null, null, null, null, null, null, null, null, null);
   		Test.stopTest();
   		
   		Account customer = [select  AccountingId__c, AccountingResponse__c from Account where ID = :testCustomer.Id];
   		system.assertEquals('149', customer.AccountingId__c);
	}
	
	static testmethod void testUpdateCustomer() {
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QB_MockHttpResponseGenerator());
        List<IFW_IntegrationConfig__c> IFWConfigObj = [Select Id from IFW_IntegrationConfig__c];
		IFW_IntegrationConfigItem__c IFWConfigItemObj = TestUtil.createIFWConfigItemForQB('Customer' , IFWConfigObj[0].Id);
   		Account testCustomer = QuickBooksCustomerTest.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123', null, null, false, true, null, null, null, null, null, null, null, null, null, null, null);
   		testCustomer.Facebook__c = 'abc@facebook.com';
   		update testCustomer;
   		Test.stopTest();
   		
   		Account customer = [select  AccountingId__c, AccountingResponse__c, Facebook__c from Account where ID = :testCustomer.Id];
   		system.assertEquals('149', customer.AccountingId__c);
	}
	
	private static Account createCustomer(boolean isInsert, String customerName, String email, String billingCity, String phoneNumber, String priceLevel, String salesTax, Boolean isVendor, Boolean isCustomer, String customertype, String firstName, String lastName, String Mobile, String BillingStreet, String workEmail, String otherEmail, String workPhone, String facebookUrl, String twitterUrl, String linkedInUrl    ) {
        if(AccessControl.ifObjectFieldIsCreateable('Account') == false) {throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);} //!Test.isRunningTest() && 
        
        Account customer = new Account();
        customer.Name = (customerName == null) ? 'Test Customer' + uniqueNumber : customerName ;
        customer.Email__c = (email == null) ? 'Test' + uniqueNumber + '@gmail.com' : email;
        customer.Phone = (phoneNumber == null) ? '123456' + uniqueNumber : phoneNumber;
        customer.BillingCity = (billingCity == null) ? 'Test Billing City' + uniqueNumber : billingCity;
        customer.Price_Level__c = priceLevel;
        customer.Sales_Tax__c = salesTax;
        customer.Is_Vendor__c = isVendor;
        customer.Is_Customer__c = isCustomer;
        customer.Type__c = customertype;
        customer.FirstName__c = firstName;
        customer.LastName__c = lastName;
        customer.Mobile__c = Mobile;
        customer.BillingStreet = BillingStreet ;
        customer.Work_Email__c = workEmail ;
        customer.Other_Email__c = otherEmail ;
        customer.Work_Number__c = workPhone ;
        customer.Facebook__c = facebookUrl ;
        customer.Twitter__c = twitterUrl ;
        customer.LinkedIn__c = linkedInUrl ;
        
        
        if(isInsert) {
            insert customer;
        }
        
        return customer;
    }
    
    
}