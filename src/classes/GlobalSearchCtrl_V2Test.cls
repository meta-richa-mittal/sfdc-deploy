@isTest
public with sharing class GlobalSearchCtrl_V2Test {

    @TestSetup
    static void setupTestData() {
        TestDataFactory.disableFLSChecks();
        TestUtil.createNameSpaceInGeneralConfig();
		User testUser = TestUtil.createUser(true, 'a@b.c', 'Sharma', 'en_US', 'Shantanu.Sharma@metacube.com', 'sshar');
		User_Group__c userGroup = new User_Group__c(name='testing user group',OwnerId =testUser.id, Colour_Code__c='rgba(255,100,88,1)',Accounting_settings_export__c='Primary',
                                           Costs__c='Primary',Customer_invoicing__c='Primary',customers__c='Primary',Deal__c='Primary',fees__c='Primary',Internal_Service__c='Primary',
                                           kits__c='Secondary',labor__c='Secondary',Merchandise__c='Primary',Override_price__c='Primary',Oversell_inventory__c='Primary',parts__c='Primary',
                                           Price_file_import__c='Secondary',Price_Levels__c='Secondary',quick_sale__c='Secondary',Returns__c='Secondary',Sales_Taxes__c='Secondary',Service_job__c='Secondary',
                                           Special_order__c='None',stock_units__c='Secondary',System_Settings__c='Primary',Vendor_invoicing__c='Primary',Vendor_order__c='Primary',
                                           vendor_products__c='Primary',Vendor_receiving__c='Primary',vendors__c='Primary');
		insert userGroup;
  		List<User_Group__c> userGroupList = [select Id from User_Group__c];
  		String userId = UserInfo.getUserId();
  		List<String> usersList = new List<String>{userId};
  		UserSettingCtrl.assignUserToGroup(BPUtility.getEncodedString(System.JSON.serialize(usersList)), BPUtility.getEncodedString(userGroupList[0].Id));
    }

    static void testData() {
        List<Account_Type__c> accountTypeList = TestDataFactory_V2.createTestDataForAccountType(true);
        List<Category__c> categoryList = TestDataFactory_V2.createTestDataForCategory(true);
        List<Price_Level__c> priceLevelList = TestDataFactory_V2.createTestDataForPriceLevel(true);
        List<Account> accountList = TestDataFactory_V2.createTestDataForCustomer(accountTypeList, priceLevelList, true);
        List<Account> vendorList = TestDataFactory_V2.createTestDataForVendor(true);
        List<Sales_Tax_Item__c> salesTaxItemList = TestDataFactory_V2.createTestDataForSalesTaxItem(categoryList, true);
        List<Sales_Tax__c> salesTaxList = TestDataFactory_V2.createTestDataForSalesTax(true);
        List<Tax_Exemption__c> taxExemptionList = TestDataFactory_V2.createTestDataForTaxExemption(accountTypeList, salesTaxItemList, true);
        List<Applicable_Taxes__c> applicableTaxList = TestDataFactory_V2.createTestDataForApplicableTax(salesTaxList, salesTaxItemList, true);
        List<Fee__c> feeList = TestDataFactory_V2.createTestDataForFee(salesTaxList, categoryList, true);
        List<Part__c> partList = TestDataFactory_V2.createTestDataForPart(categoryList, vendorList, salesTaxList, false); 
        partList[0].Active__c = true;    
        insert partList;
    }

    private static void enableSOSL() {
        insert new Configuration_List__c(Name = GeneralConfiguration.ENABLE_SOSL_SEARCH, Value__c = 'true');
    }

    private static Boolean isSOSLEnabled() {
        String performSOSLStr = GeneralConfiguration.getConfigurationByName(GeneralConfiguration.ENABLE_SOSL_SEARCH);
        return String.isNotBlank(performSOSLStr) ? Boolean.valueOf(performSOSLStr) : false;
    }
    
    @IsTest
    static void testPartSearchWithSOSL() {
        enableSOSL();
        testPartSearch();
    }

    @isTest
    public static void testCustomerSearch() {
        testData();
        String searchQueryJson = '{"GlobalSearchText":"test0","GlobalSearchKeyword":"Customers","GlobalSearchKeywordKey":"Customer"}';
        
        Test.startTest();
        String searchResults = GlobalSearchCtrl.getGlobalSearchResult(BPUtility.getEncodedString(searchQueryJson));
        GlobalSearchResultsWrapper actualResults = (GlobalSearchResultsWrapper)JSON.deserialize(BPUtility.getDecodedString(searchResults), GlobalSearchResultsWrapper.class);
        Test.stopTest();

        // Assertion
        System.assertEquals(1, actualResults.TotalRecords); 
        System.assertEquals('test0', actualResults.searchRecords[0].ItemName);    
        System.assertEquals(1, actualResults.searchRecords[0].Type);    
        System.assertEquals('Customer', actualResults.searchRecords[0].ObjectName);    
        System.assertEquals('Phone', actualResults.searchRecords[0].AdditionalInfoLabel2);    
        System.assertEquals([SELECT Id FROM Account LIMIT 1].Id, actualResults.searchRecords[0].Id);          
    } 

    @isTest
    public static void testPartSearch() {
        testData();
        Part__c part =  [SELECT id FROM part__c WHERE Part_Number__c = 'test0' AND active__c = true LIMIT 1];
        List<Id> fixedSearchResults= new List<Id>{part.Id};
        Test.setFixedSearchResults(fixedSearchResults);
        String searchQueryJson = '{"GlobalSearchText":"test0","GlobalSearchKeyword":"Parts","GlobalSearchKeywordKey":"Part", "FromIndex":0, "ToIndex":20}';
        Test.startTest();
        String searchResults = GlobalSearchCtrl.getGlobalSearchResult(BPUtility.getEncodedString(searchQueryJson));
        GlobalSearchResultsWrapper actualResults = (GlobalSearchResultsWrapper)JSON.deserialize(BPUtility.getDecodedString(searchResults), GlobalSearchResultsWrapper.class);
        Test.stopTest();

        System.assertEquals(1, actualResults.TotalRecords); 
        System.assertEquals('test0 - test0', actualResults.searchRecords[0].ItemName);    
        System.assertEquals(3, actualResults.searchRecords[0].Type);    
        System.assertEquals('Part', actualResults.searchRecords[0].ObjectName);    
        System.assertEquals('available', actualResults.searchRecords[0].AdditionalInfoLabel2);    
        System.assertEquals([SELECT Id FROM Part__c LIMIT 1].Id, actualResults.searchRecords[0].Id);     
    }

}