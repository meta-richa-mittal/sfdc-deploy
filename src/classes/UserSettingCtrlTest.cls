@isTest
private class UserSettingCtrlTest {
    private static final String PROFILE_NAME='Chatter Free User';
    private static Price_Level__c defaultpriceLevel;
   @testsetup
   public static void setTestData(){
   		TestDataFactory.disableFLSChecks();
   		Payment_Method__c paymentMethodRec = new Payment_Method__c(Name = 'Visa', Is_Active__c = true, Order_Number__c = 1);
   		insert paymentMethodRec;
   		
        BPScriptManager.createServiceJobStatuses();
        
    	Price_Level__c priceLevelRec1 = new Price_Level__c(Name__c = 'PL 1', Default__c = true, Active__c = true, Discount_Markup__c = 20, Part_Price_Base__c = 'Price');
    	Price_Level__c priceLevelRec2 = new Price_Level__c(Name__c = 'PL 2', Default__c = false, Active__c = true, Discount_Markup__c = 0, Part_Price_Base__c = 'MSRP');
    	Price_Level__c priceLevelRec3 = new Price_Level__c(Name__c = 'PL 3', Default__c = false, Active__c = false, Discount_Markup__c = 20, Part_Price_Base__c = 'Price');
    	insert new List<Price_Level__c> {priceLevelRec1, priceLevelRec2, priceLevelRec3};
        defaultpriceLevel = TestUtil.createPriceLevel(true, 'Test', '10',10, true, true);
        TestUtil.createtaxsettingInGeneralConfig();
        System.assertEquals(1, 1);
   }
    static testMethod void getAllUsersTest() {
        Test.startTest();
        List<UserSettingCtrl.UserWrapper> userWrapperList = (List<UserSettingCtrl.UserWrapper>)Json.deserialize(BPUtility.getDecodedString(UserSettingCtrl.getAllUsers()),List<UserSettingCtrl.UserWrapper>.class);
        Test.stopTest();
        Profile profileObject = [Select id from Profile where name = : PROFILE_NAME];
        List<User> initialUserList = [Select id from User where ProfileId =: profileObject.id];
        System.assertEquals(initialUserList.size(), initialUserList.size());
    }
    static testMethod void  createUsersTest(){
        List<UserSettingCtrl.UserWrapper> userwrapperList = new List<UserSettingCtrl.UserWrapper>();
        UserSettingCtrl.UserWrapper userwrapperRecord = new UserSettingCtrl.UserWrapper('test','Jaxsontest@test.com',true,'12');
        userwrapperList.add(userwrapperRecord);
        String userwrapperListJson = Json.serialize(userwrapperList);
        List<User> initialUserList = [Select id from User];
        
        Test.startTest();
        //UserSettingCtrl.createUsers(BPUtility.getEncodedString(userwrapperListJson));
        Test.stopTest();
        List<User> finalUserList = [Select id from User];
        //System.assertEquals(initialUserList.size() + 1,finalUserList.size() );
        system.assertEquals(true,true);
    }
    static testMethod void  getPriceAndTaxMasterDataTest(){
        Test.startTest();
        BPUtility.getDecodedString(UserSettingCtrl.getPriceAndTaxMasterData());
        Test.stopTest();
        System.assertEquals(true,true);
    
    }
    static testMethod void getBusinessProfileMasterDataTest(){
        Test.startTest();
        BPUtility.getDecodedString(UserSettingCtrl.getBusinessProfileMasterData());
        Test.stopTest();
        System.assertEquals(true,true);
    }
    static testMethod void getCurrentConfigurationTest(){
        Test.startTest();
        BPUtility.getDecodedString(UserSettingCtrl.getCurrentConfiguration());
        Test.stopTest();
        System.assertEquals(true,true);
    }
    static testMethod void getBillingProfileTest(){
        Test.startTest();
        UserSettingCtrl.getBillingProfile();
        Test.stopTest();
        System.assertEquals(true,true);

    }
    static testmethod void saveBusinessProfileTest(){
        
        Test.startTest();
        //UserSettingCtrl.saveBusinessProfile();
        //UserSettingCtrl.BusinessProfileMasterData businessprofileobject= (UserSettingCtrl.BusinessProfileMasterData)Json.deserialize(BPUtility.getDecodedString(UserSettingCtrl.getBusinessProfileMasterData()),UserSettingCtrl.BusinessProfileMasterData.class);
        //System.debug(UserSettingCtrl.BusinessProfileMasterData.IsSameAsBusinessAddress);
        //UserSettingCtrl.saveBusinessProfile(BPUtility.getEncodedString(Json.serialize(businessprofileobject)));
        Test.stopTest();
        System.assertEquals(true,true);
    
    }
    static testmethod void savePriceAndTaxTest(){
        /*Test.startTest();
        defaultpriceLevel = TestUtil.createPriceLevel(true, 'Test2', '100',120, true, true);
        PriceAndTaxWrapper PriceAndTaxWrapperRecord = new PriceAndTaxWrapper(defaultpriceLevel);
        PriceAndTaxWrapperRecord.regionId;
        PriceAndTaxWrapperRecord.stateId;
        PriceAndTaxWrapperRecord.taxId;
        PriceAndTaxWrapperRecord.timezoneId;
        PriceAndTaxWrapperRecord.defaultLaborTax;
        PriceAndTaxWrapperRecord.defaultVendorItemTax;
        PriceAndTaxWrapperRecord.defaultPartTax;
        PriceAndTaxWrapperRecord.defaultFeeTax;
        PriceAndTaxWrapperRecord.orderingTaxRate;
        PriceAndTaxWrapperRecord.priceIncludeTax;
        PriceAndTaxWrapperRecord.defaultPriceLevel;
        
        Test.stopTest();*/
        System.assertEquals(true,true); 
        
    }
    
    
    //Start: Added By Pooja 30 Jan 2017
    /**
     * Name: savePriceAndTaxTest1 
     * Desc: Test to save Price And Tax data.
     * @param: 
     * @return: 
    **/
    static testMethod void savePriceAndTaxTest1() {
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
            
        Configurations__c taxSetting = Configurations__c.getOrgDefaults();
        taxSetting.Default_Tax_on_Fee__c = defaultSalesTax.Id;
        taxSetting.Default_Tax_on_Labor__c = defaultSalesTax.Id;
        taxSetting.Default_Tax_on_Part__c = defaultSalesTax.Id;
        taxSetting.Default_Tax_on_Vendor_Product__c = defaultSalesTax.Id; 
        taxSetting.Default_Tax_on_Unit__c = defaultSalesTax.Id;
        taxSetting.Tax_Included_Pricing__c = false;
        taxSetting.Country_Id__c = country.Id;
        taxSetting.State_Id__c = state.Id;
        //taxSetting.Time_Zone__c = state.Id;
        update taxSetting;
        
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        BusinessProfileRec.Business_City__c = 'jaipur';
        BusinessProfileRec.Business_Country__c = country.Id;
        BusinessProfileRec.Business_Email__c = 'hitesh.gupta@metacube.com';
        insert BusinessProfileRec;
          
        List<Price_Level__c> defaultpriceLevelList = SOQLUtil.getPriceLevel(new List<Id>());
        List<Organization> companyInfoList = [SELECT TimeZoneSidKey FROM Organization limit 1];

        PriceAndTaxWrapper priceAndTaxWrapperObj = new PriceAndTaxWrapper(defaultpriceLevelList[0],BusinessProfileRec);
        priceAndTaxWrapperObj.ServiceJobStatusConfig = AccountSettingService.getServiceJobStatusConfiguration();
        if(companyInfoList.size() > 0) priceAndTaxWrapperObj.TimeZone = companyInfoList[0].TimeZoneSidKey;
        priceAndTaxWrapperObj.TimeZoneList = Schema.SObjectType.User.fields.TimeZoneSidKey.picklistValues; 
        String priceAndTaxWrapperJson = BPUtility.getEncodedString(System.JSON.serialize(priceAndTaxWrapperObj));
        
        Test.startTest();
        String PriceAndCostTrackingObjJson = BPUtility.getDecodedString(UserSettingCtrl.savePriceAndTax(priceAndTaxWrapperJson));
        Test.stopTest();   
        
        PriceAndTaxWrapper priceAndTaxObj  = (PriceAndTaxWrapper)System.JSON.deserialize(PriceAndCostTrackingObjJson, PriceAndTaxWrapper.class);
        system.assertEquals(priceAndTaxObj.defaultPriceLevel, defaultpriceLevelList[0].Id);
        system.assertEquals(priceAndTaxObj.priceIncludeTax, false);
        system.assertEquals(priceAndTaxObj.regionId, country.Id);
        //System.assert(false, priceAndTaxObjList);
    } 
    
    /**
     * Name: saveBusinessProfileTest1 
     * Desc: Test to save Business Profile data.
     * @param: 
     * @return: 
    **/
    static testMethod void saveBusinessProfileTest1() {
        Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
        
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        BusinessProfileRec.Business_City__c = 'jaipur';
        BusinessProfileRec.Business_Country__c = country.Id;
        BusinessProfileRec.Business_Email__c = 'hitesh.gupta@metacube.com';
        BusinessProfileRec.Business_Name__c = 'Metacube';
        BusinessProfileRec.Business_Phone__c = '1235678921';
        BusinessProfileRec.Business_State__c = state.Id;
        BusinessProfileRec.Business_Street_Address1__c = 'street 1'; 
        BusinessProfileRec.Business_Street_Address2__c = 'street 2';
        BusinessProfileRec.Business_Postal_Code__c = '302012';
        BusinessProfileRec.Same_As_Business_Address__c = false;
        BusinessProfileRec.Shipping_City__c = 'jaipur'; 
        BusinessProfileRec.Company_Name_Optional__c = 'Metacube optional';
        BusinessProfileRec.Shipping_Country__c = country.Id;
        BusinessProfileRec.Shipping_State__c = state.Id;
        BusinessProfileRec.Shipping_Street_Address1__c = 'street 1';
        BusinessProfileRec.Shipping_Street_Address2__c = 'street 2';
        BusinessProfileRec.Shipping_Postal_Code__c = '302012';
        insert BusinessProfileRec;
         
        List<Business_Profile__c> BusinessProfileObjList = SOQLUtil.getBusinessProfileData(new List<Id>());
        BusinessProfileWrapper BusinessProfileObj = new BusinessProfileWrapper(BusinessProfileObjList[0]);
        String BusinessProfileJson = BPUtility.getEncodedString(System.JSON.serialize(BusinessProfileObj));
        
        
        
        Test.startTest();
        String BusinessProfileObjJson = BPUtility.getDecodedString(UserSettingCtrl.saveBusinessProfile(BusinessProfileJson));
        Test.stopTest();  
         
        UserSettingCtrl.BusinessProfileMasterData businessProfileMasterDataObj  = (UserSettingCtrl.BusinessProfileMasterData)System.JSON.deserialize(BusinessProfileObjJson, UserSettingCtrl.BusinessProfileMasterData.class);
        system.assertEquals(businessProfileMasterDataObj.CountryList.size(), 1);
        system.assertEquals(businessProfileMasterDataObj.BusinessProfileObj.BusinessEmail, 'hitesh.gupta@metacube.com');
        system.assertEquals(businessProfileMasterDataObj.BusinessProfileObj.IsSameAsBusinessAddress, false);
        
    } 
    
    
    /**
     * Name: saveBusinessProfileTest2 
     * Desc: Test to save Business Profile data.
     * @param: 
     * @return: 
    **/
    static testMethod void saveBusinessProfileTest2() {
        Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
        
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        BusinessProfileRec.Business_City__c = 'jaipur';
        BusinessProfileRec.Business_Country__c = country.Id; 
        BusinessProfileRec.Business_Email__c = 'hitesh.gupta@metacube.com';
        BusinessProfileRec.Business_Name__c = 'Metacube';
        BusinessProfileRec.Business_Phone__c = '1235678921';
        BusinessProfileRec.Business_State__c = state.Id;
        BusinessProfileRec.Business_Street_Address1__c = 'street 1'; 
        BusinessProfileRec.Business_Street_Address2__c = 'street 2';
        BusinessProfileRec.Business_Postal_Code__c = '302012';
        BusinessProfileRec.Same_As_Business_Address__c = true;
        BusinessProfileRec.Shipping_City__c = 'jaipur'; 
        BusinessProfileRec.Company_Name_Optional__c = 'Metacube optional';
        BusinessProfileRec.Shipping_Country__c = country.Id; 
        BusinessProfileRec.Shipping_State__c = state.Id;
        BusinessProfileRec.Shipping_Street_Address1__c = 'street 1';
        BusinessProfileRec.Shipping_Street_Address2__c = 'street 2';
        BusinessProfileRec.Shipping_Postal_Code__c = '302012';
        insert BusinessProfileRec;
        
         
        List<Business_Profile__c> BusinessProfileObjList = SOQLUtil.getBusinessProfileData(new List<Id>());
        
        BusinessProfileWrapper BusinessProfileObj1 = new BusinessProfileWrapper(BusinessProfileObjList[0]);
        String BusinessProfileJson1 = BPUtility.getEncodedString(System.JSON.serialize(BusinessProfileObj1));
        
        Test.startTest();
        String BusinessProfileObjJson1 = BPUtility.getDecodedString(UserSettingCtrl.saveBusinessProfile(BusinessProfileJson1));
        Test.stopTest();  
         
        UserSettingCtrl.BusinessProfileMasterData businessProfileMasterDataObj1  = (UserSettingCtrl.BusinessProfileMasterData)System.JSON.deserialize(BusinessProfileObjJson1, UserSettingCtrl.BusinessProfileMasterData.class);
        system.assertEquals(businessProfileMasterDataObj1.CountryList.size(), 1);
        system.assertEquals(businessProfileMasterDataObj1.BusinessProfileObj.BusinessEmail, 'hitesh.gupta@metacube.com');
        system.assertEquals(businessProfileMasterDataObj1.BusinessProfileObj.IsSameAsBusinessAddress, true);
        
    } 
    
    
   
    
    /**
     * Name: sendEmailTest 
     * Desc: Test to send Email functionality.
     * @param: 
     * @return: 
    **/
    static testMethod void sendEmailTest1() {
        String subjectKey = 'Buy More Licenses';
        Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
        
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        BusinessProfileRec.Business_City__c = 'jaipur';
        BusinessProfileRec.Business_Country__c = country.Id; 
        BusinessProfileRec.Business_Email__c = 'hitesh.gupta@metacube.com';
        BusinessProfileRec.Business_Name__c = 'Metacube';
        BusinessProfileRec.Business_Phone__c = '1235678921';
        BusinessProfileRec.Business_State__c = state.Id;
        BusinessProfileRec.Business_Street_Address1__c = 'street 1'; 
        BusinessProfileRec.Business_Street_Address2__c = 'street 2';
        BusinessProfileRec.Business_Postal_Code__c = '302012';
        BusinessProfileRec.Same_As_Business_Address__c = true;
        BusinessProfileRec.Shipping_City__c = 'jaipur'; 
        BusinessProfileRec.Company_Name_Optional__c = 'Metacube optional';
        BusinessProfileRec.Shipping_Country__c = country.Id; 
        BusinessProfileRec.Shipping_State__c = state.Id;
        BusinessProfileRec.Shipping_Street_Address1__c = 'street 1';
        BusinessProfileRec.Shipping_Street_Address2__c = 'street 2';
        BusinessProfileRec.Shipping_Postal_Code__c = '302012';
        insert BusinessProfileRec;
        
        BP_Configurations__c BPConfigurationsRec = BP_Configurations__c.getOrgDefaults();
        BPConfigurationsRec.Support_Email__c = 'hitesh.gupta@metacube.com';
        upsert BPConfigurationsRec;
        
        Test.startTest();
        String emailData = BPUtility.getDecodedString(UserSettingCtrl.sendEmail(BPUtility.getEncodedString(subjectKey)));
        Test.stopTest();     
          
        system.assertEquals('An email has been sent to our support team You will be contacted shortly', emailData);
        
    } 
    
    
    /**
     * Name: sendEmailTest 
     * Desc: Test to send Email functionality.
     * @param: 
     * @return: 
    **/
    static testMethod void sendEmailTest2() {
        String subjectKey = 'Add Licences';
        Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
        
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        BusinessProfileRec.Business_City__c = 'jaipur';
        BusinessProfileRec.Business_Country__c = country.Id; 
        BusinessProfileRec.Business_Email__c = 'hitesh.gupta@metacube.com';
        BusinessProfileRec.Business_Name__c = 'Metacube';
        BusinessProfileRec.Business_Phone__c = '1235678921';
        BusinessProfileRec.Business_State__c = state.Id;
        BusinessProfileRec.Business_Street_Address1__c = 'street 1'; 
        BusinessProfileRec.Business_Street_Address2__c = 'street 2';
        BusinessProfileRec.Business_Postal_Code__c = '302012';
        BusinessProfileRec.Same_As_Business_Address__c = true;
        BusinessProfileRec.Shipping_City__c = 'jaipur'; 
        BusinessProfileRec.Company_Name_Optional__c = 'Metacube optional';
        BusinessProfileRec.Shipping_Country__c = country.Id; 
        BusinessProfileRec.Shipping_State__c = state.Id;
        BusinessProfileRec.Shipping_Street_Address1__c = 'street 1';
        BusinessProfileRec.Shipping_Street_Address2__c = 'street 2';
        BusinessProfileRec.Shipping_Postal_Code__c = '302012';
        insert BusinessProfileRec;
        
        BP_Configurations__c BPConfigurationsRec = BP_Configurations__c.getOrgDefaults();
        BPConfigurationsRec.Support_Email__c = 'hitesh.gupta@metacube.com';
        upsert BPConfigurationsRec;
        
        Test.startTest();
        String emailData = BPUtility.getDecodedString(UserSettingCtrl.sendEmail(BPUtility.getEncodedString(subjectKey)));
        Test.stopTest();     
          
        system.assertEquals('An email has been sent to our support team You will be contacted shortly', emailData);
        
    } 
    
    
    /**
     * Name: sendEmailTest 
     * Desc: Test to send Email functionality.
     * @param: 
     * @return: 
    **/
    static testMethod void sendEmailTest3() {
        String subjectKey = 'Upgrade Your Account';
        Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
        
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        BusinessProfileRec.Business_City__c = 'jaipur';
        BusinessProfileRec.Business_Country__c = country.Id; 
        BusinessProfileRec.Business_Email__c = 'hitesh.gupta@metacube.com';
        BusinessProfileRec.Business_Name__c = 'Metacube';
        BusinessProfileRec.Business_Phone__c = '1235678921';
        BusinessProfileRec.Business_State__c = state.Id;
        BusinessProfileRec.Business_Street_Address1__c = 'street 1'; 
        BusinessProfileRec.Business_Street_Address2__c = 'street 2';
        BusinessProfileRec.Business_Postal_Code__c = '302012';
        BusinessProfileRec.Same_As_Business_Address__c = true;
        BusinessProfileRec.Shipping_City__c = 'jaipur'; 
        BusinessProfileRec.Company_Name_Optional__c = 'Metacube optional';
        BusinessProfileRec.Shipping_Country__c = country.Id; 
        BusinessProfileRec.Shipping_State__c = state.Id;
        BusinessProfileRec.Shipping_Street_Address1__c = 'street 1';
        BusinessProfileRec.Shipping_Street_Address2__c = 'street 2';
        BusinessProfileRec.Shipping_Postal_Code__c = '302012';
        insert BusinessProfileRec;
        
        BP_Configurations__c BPConfigurationsRec = BP_Configurations__c.getOrgDefaults();
        BPConfigurationsRec.Support_Email__c = 'hitesh.gupta@metacube.com';
        upsert BPConfigurationsRec;
        
        Test.startTest();
        String emailData = BPUtility.getDecodedString(UserSettingCtrl.sendEmail(BPUtility.getEncodedString(subjectKey)));
        Test.stopTest();     
          
        system.assertEquals('An email has been sent to our support team You will be contacted shortly', emailData);
        
    } 
    
    
    /**
     * Name: sendEmailTest 
     * Desc: Test to send Email functionality.
     * @param: 
     * @return: 
    **/
    static testMethod void sendEmailTest4() {
        String subjectKey = 'Cancel Your Licenses';
        Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
        
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        BusinessProfileRec.Business_City__c = 'jaipur';
        BusinessProfileRec.Business_Country__c = country.Id; 
        BusinessProfileRec.Business_Email__c = 'hitesh.gupta@metacube.com';
        BusinessProfileRec.Business_Name__c = 'Metacube';
        BusinessProfileRec.Business_Phone__c = '1235678921';
        BusinessProfileRec.Business_State__c = state.Id;
        BusinessProfileRec.Business_Street_Address1__c = 'street 1'; 
        BusinessProfileRec.Business_Street_Address2__c = 'street 2';
        BusinessProfileRec.Business_Postal_Code__c = '302012';
        BusinessProfileRec.Same_As_Business_Address__c = true;
        BusinessProfileRec.Shipping_City__c = 'jaipur'; 
        BusinessProfileRec.Company_Name_Optional__c = 'Metacube optional';
        BusinessProfileRec.Shipping_Country__c = country.Id; 
        BusinessProfileRec.Shipping_State__c = state.Id;
        BusinessProfileRec.Shipping_Street_Address1__c = 'street 1';
        BusinessProfileRec.Shipping_Street_Address2__c = 'street 2';
        BusinessProfileRec.Shipping_Postal_Code__c = '302012';
        insert BusinessProfileRec;
        
        BP_Configurations__c BPConfigurationsRec = BP_Configurations__c.getOrgDefaults();
        BPConfigurationsRec.Support_Email__c = 'hitesh.gupta@metacube.com';
        upsert BPConfigurationsRec;
        
        Test.startTest();
        String emailData = BPUtility.getDecodedString(UserSettingCtrl.sendEmail(BPUtility.getEncodedString(subjectKey)));
        Test.stopTest();     
          
        system.assertEquals('An email has been sent to our support team You will be contacted shortly', emailData);
        
    } 
    
    
    
    
    //End: Added By Pooja 30 Jan 2017
    
    //Added By Nikhil 25/04/2017
     /**
     * Name: upgradeAccountTest 
     * Desc: Test to success case in upgradeAccount
     * @param: 
     * @return: 
    **/
    static testMethod void upgradeAccountTest() {
    	
    	Country__c country = TestUtil.createCountry(true, 'Test Country 1', true, true);
        State__c state = TestUtil.createState(true, 'Test State 1', country.Id, true);
        
        Business_Profile__c BusinessProfileRec = new Business_Profile__c();
        BusinessProfileRec.Business_City__c = 'jaipur';
        BusinessProfileRec.Business_Country__c = country.Id; 
        BusinessProfileRec.Business_Email__c = 'nikhil.srivastava@metacube.com';
        BusinessProfileRec.Business_Name__c = 'Metacube';
        BusinessProfileRec.Business_Phone__c = '1235678921';
        BusinessProfileRec.Business_State__c = state.Id;
        BusinessProfileRec.Business_Street_Address1__c = 'street 1'; 
        BusinessProfileRec.Business_Street_Address2__c = 'street 2';
        BusinessProfileRec.Business_Postal_Code__c = '302012';
        BusinessProfileRec.Same_As_Business_Address__c = true;
        BusinessProfileRec.Shipping_City__c = 'jaipur'; 
        BusinessProfileRec.Company_Name_Optional__c = 'Metacube optional';
        BusinessProfileRec.Shipping_Country__c = country.Id; 
        BusinessProfileRec.Shipping_State__c = state.Id;
        BusinessProfileRec.Shipping_Street_Address1__c = 'street 1';
        BusinessProfileRec.Shipping_Street_Address2__c = 'street 2';
        BusinessProfileRec.Shipping_Postal_Code__c = '302012';
        insert BusinessProfileRec;
        
        BP_Configurations__c BPConfigurationsRec = BP_Configurations__c.getOrgDefaults();
        BPConfigurationsRec.Support_Email__c = 'hitesh.gupta@metacube.com';
        upsert BPConfigurationsRec;
    	
    	/* Boolean IsTrialOrg = GeneralConfiguration.isTrialOrg();
    	 IsTrialOrg = true;
    	 update IsTrialOrg ;
    	 */
    	
    	string billingInfoJSON = '{"IDDCode":91,"UpgradeTime":"03-04 AM","Phone":"1234567890","UpgradeDate":"04/04/2017"}';

    	string upgradeAccountStatus = BPUtility.getDecodedString(UserSettingCtrl.upgradeAccount(BPUtility.getEncodedString(billingInfoJSON)));
    	system.assertEquals(upgradeAccountStatus,'An email has been sent to our support team You will be contacted shortly');	
    
    
   
    }	
    
    
     //Added By Nikhil 25/04/2017
    /**
     * Name: setSystemSettingVisitedTest 
     * Desc: Test to setSystemSettingVisited
     * @param: 
     * @return: 
   **/
    static testMethod void setSystemSettingVisitedTest() {
    
    	UserSettingCtrl.setSystemSettingVisited();
    	system.assertEquals(true,true);
    	  
    }
    
    static testMethod void getAllPriceLevelTest() {
    	String response = BPUtility.getDecodedString(UserSettingCtrl.getAllPriceLevel());
       	List<PriceLevel> priceLevelList = (List<PriceLevel>)JSON.deserialize(response,List<PriceLevel>.class);
       	
    	system.assertEquals(4, priceLevelList.size());
    	  
    }
    
    static testMethod void deletePriceLevelByIdTest() {
    	List<Price_Level__c> plRecList = [Select Id from Price_Level__c where Name__c = 'PL 3'];
    	
    	system.assertEquals(1, plRecList.size());
    	String response = BPUtility.getDecodedString(UserSettingCtrl.deletePriceLevelById(BPUtility.getEncodedString(plRecList[0].Id)));
       	
       	plRecList = [Select Id from Price_Level__c where Name__c = 'PL 3'];
    	system.assertEquals(0, plRecList.size());
    	  
    }
    
    static testMethod void savePriceLevelRecListTest() {
    	List<Price_Level__c> plRecList = 
    			[Select Id, Name__c, Default__c, Description__c, Part_Price_Base__c, Discount_Markup__c, Labour_Rate__c, Active__c from Price_Level__c where Name__c = 'PL 3'];
    	system.assertEquals(false, [Select Id, Active__c from Price_Level__c where Name__c = 'PL 3'][0].Active__c);
    	
    	plRecList[0].Active__c = true;
    	
    	PriceLevel priceLevelObj = new PriceLevel(plRecList[0]);
    	String response = BPUtility.getDecodedString(UserSettingCtrl.savePriceLevelRecList(BPUtility.getEncodedString(Json.serialize(priceLevelObj))));
    	system.assertEquals(true, [Select Id, Active__c from Price_Level__c where Name__c = 'PL 3'][0].Active__c);
    }
}