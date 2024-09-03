@isTest
public class VendorDetailWrapperTest {
	
	@testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();
    	Account vendorRec = TestDataFactory.createVendor('Test Vendor');
    }
    
    @isTest
    private static void vendorDetailWrapperTest() {
    	List<Account> vendorList = [SELECT Id, Name, Preferred_Email__c, Work_Email__c, Other_Email__c, AccountNumber, 
                                    Default_Export_Format__c, Default_Export_Format__r.File_Name__c, Country__c,
                                    Country__r.Name__c, Country__r.Default__c, Country__r.Visible__c,Country__r.Currency_Code__c,
                                    Country__r.Active__c, Country__r.Currency_Name__c, Country__r.Currency_Symbol__c, Country__r.Formatted_FX_Currency_Code__c,
                                    Country__r.Flag_Encoded__c, Country__r.Conversion_Rate__c, Country__r.Conversion_Rate_With_Markup__c, 
                                    Is_Foreign_Vendor__c FROM Account];
    	VendorDetailWrapper vendorDetailWrapper = new VendorDetailWrapper(vendorList[0], false);
    	system.assertEquals(vendorDetailWrapper.VendorId, vendorList[0].Id);
    }
    
    @isTest
    private static void vendorDetailWrapperConstructorTest() {
    	VendorDetailWrapper vendorDetailWrapper = new VendorDetailWrapper();
    	system.assertEquals(vendorDetailWrapper.VendorId, null);
    }
    
    @isTest
    private static void fieldsListTest() {
    	List<String> fieldsList = VendorDetailWrapper.fieldsList();
    	system.assertEquals(fieldsList.size(), 21);
    }
}