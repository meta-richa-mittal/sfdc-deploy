/**
* Author: Ankit Jain
* Since: June 30, 2016
* Name: UserSettingCtrl 
* Description: Apex class which contains all remoted methods related to UserSetting Page.
**/
 
global without sharing class UserSettingCtrl {
    
    global UserSettingCtrl (NewHomePageCtrl controller){}
    public UserSettingCtrl() {}
    
    public Boolean IsTrialOrg { get{return GeneralConfiguration.isTrialOrg();} private set;}
    public String communityURL { get{return GeneralConfiguration.communityLink();} private set;}
    public String communityquestionURL { get{return GeneralConfiguration.communityLink();} private set;}
    public String communitycaseURL { get{return GeneralConfiguration.communityLink();} private set;}
    private static final String BLACKPURL_PROFILE_NAME = 'Blackpurl';
    public static final List<String> PROFILE_NAME_LIST = new List<String>{BLACKPURL_PROFILE_NAME};
    private static final Integer MAX_TRAIL_USERS = (Integer)((GeneralConfiguration.getMaxNumberOfUsers() != null) ? GeneralConfiguration.getMaxNumberOfUsers() : 5);
    public Integer maxNoOfTechnicians { get{return (Integer)((GeneralConfiguration.getMaxNumberOfTechnicians() != null) ? GeneralConfiguration.getMaxNumberOfTechnicians() : 0);} private set;}
    private static final String DUPLICATE_USERNAME = 'Duplicate Username';
    private static final String LICENSE_LIMIT_EXCEEDED = 'License Limit Exceeded';
    public static final String ENABLE_MFA = 'Enable_MFA';
    private static final String TAX_MANAGEMENT_TILE_AVAILABLE = 'Tax Management Tile Available';

    /**
     * Name: getMaxTrailUsers
     * Desc: Method which gives Maximum Number of Trail users
       @param:    
     * @return: String - JSON String of Maximum Number of Trail users
    **/
    @RemoteAction
    global static String getMaxTrailUsers(){
    	Integer maxTrailUsers = MAX_TRAIL_USERS;
    	return BPUtility.getEncodedString(System.JSON.serialize(maxTrailUsers));
    }
    
    /**
     * Name: getAllUsers
     * Desc: Method which gives  List of Users which have ChatterFree profile in the org
       @param:    
     * @return: String - JSON String of list of Users which have ChatterFree profile in the org
    **/
    @RemoteAction
    global static String getAllUsers(){
        if(AccessControl.ifObjectFieldIsAccessible('Profile') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('User') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Profile> ProfilesList = [Select Id from Profile where Name IN: PROFILE_NAME_LIST];
        List<User> userList = [Select Name, FirstName, LastName, Email, CreatedDate, LastModifiedDate, (SELECT PermissionSet.Name FROM PermissionSetAssignments WHERE PermissionSet.Name = :ENABLE_MFA Limit 1) from User where isActive = true and ProfileId IN :ProfilesList order by Name Limit : MAX_TRAIL_USERS];
        List<UserWrapper> userWrapperList = new List<UserWrapper>();
        for(User userRecord : userList){
            //UserWrapper userWrapperRecord = new UserWrapper(userRecord.Name,userRecord.Email,false,userRecord.Id);
            List<Technician__c> techList = [Select Id, Type__c from Technician__c where User__c =: userRecord.Id];
            Boolean isTech = false;
            if(techList.size() > 0) {
                isTech = techList[0].Type__c == Constants.TECHNICIAN ? true : false;
            }
            UserWrapper userWrapperRecord = new UserWrapper(userRecord, false, isTech);
            if(techList.size() > 0) {
                userWrapperRecord.isTechnician = techList[0].Type__c == Constants.TECHNICIAN ? true : false;
            } else {
                userWrapperRecord.isTechnician = false;
            }
            userWrapperList.add(userWrapperRecord);
        }
        return BPUtility.getEncodedString(System.JSON.serialize(userWrapperList));
    }
    /**
     * Name: createUsers
     * Desc: Method which gives  creates new users of the Org
     * @param:  (1) JSONString - String - JSON String of UserWrapperList
     * @return: None
    **/

    @RemoteAction
    global static String createUsers(String userWrapperString){
        UserService.checkLicenseLimit();
        if(!AccessControl.ifObjectFieldIsCreateable('User')){throw new BlackPurlException('User' + DMLUtility.NOT_CREATABLE);}
        if(!AccessControl.ifObjectFieldIsCreateable('Organization')){throw new BlackPurlException('Organization' + DMLUtility.NOT_ACCESSIBLE);}
        userWrapperString = BPUtility.getDecodedString(userWrapperString);
        UserWrapper userWrapperRecord = (UserWrapper)System.JSON.deserialize(userWrapperString,UserWrapper.class);
        if(AccessControl.ifObjectFieldIsAccessible('Profile') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Profile> ProfilesList = [Select id from Profile where name =: BLACKPURL_PROFILE_NAME];
        List<Organization> orgDetailList = [Select TimeZoneSidKey, DefaultLocaleSidKey, LanguageLocaleKey From Organization LIMIT 1];  
        if(!String.isBlank(userWrapperRecord.firstName) && !String.isBlank(userWrapperRecord.lastName) && !String.isBlank(userWrapperRecord.email)){
            User newUserRecord = new User();
            newUserRecord.FirstName = userWrapperRecord.firstName;
            newUserRecord.LastName = userWrapperRecord.lastName;
            newUserRecord.Email = userWrapperRecord.email;
            String usrname = userWrapperRecord.firstName + ' ' + userWrapperRecord.lastName;
            if(userWrapperRecord.firstName.length() > 6){
                newUserRecord.Alias = userWrapperRecord.firstName.substring(0,6);
            }
            else{
                newUserRecord.Alias = userWrapperRecord.firstName;
            }
            newUserRecord.Username = userWrapperRecord.email;
            //newUserRecord.Username = newUserRecord.Email.split('@').get(0)+ Math.random()+'@blackpurl.com';
            newUserRecord.CommunityNickname = (usrname.substring(0,3) + Math.random()).substring(0,8);
            if(orgDetailList.size() > 0) {
                newUserRecord.TimeZoneSidKey = String.isNotBlank(orgDetailList[0].TimeZoneSidKey) ? orgDetailList[0].TimeZoneSidKey : 'GMT';
                newUserRecord.LocaleSidKey = String.isNotBlank(orgDetailList[0].DefaultLocaleSidKey) ? orgDetailList[0].DefaultLocaleSidKey : 'en_US';
                newUserRecord.LanguageLocaleKey = String.isNotBlank(orgDetailList[0].LanguageLocaleKey) ? orgDetailList[0].LanguageLocaleKey : 'en_US';
            }
            newUserRecord.ProfileID = ProfilesList.get(0).id;
            newUserRecord.EmailEncodingKey = 'UTF-8';
            
            List<User> userList = [Select Name from User where isActive = true and ProfileId IN :ProfilesList Limit : MAX_TRAIL_USERS];
            for(User userRec: userList) {
                if(userRec.Name == usrname) {
                    throw new BlackPurlException('User with this name already exists.');
                }
            }
            
            Database.DMLOptions dlo = new Database.DMLOptions(); 
            dlo.EmailHeader.triggerUserEmail   = true; 
            if(!AccessControl.ifObjectFieldIsCreateable(new User())){throw new BlackPurlException('User' + DMLUtility.NOT_CREATABLE);}
                
            Database.SaveResult MySaveResult = Database.insert(newUserRecord, dlo);
            if(!MySaveResult.isSuccess()){
                String err = MySaveResult.getErrors()[0].getMessage();
                if(err.contains(DUPLICATE_USERNAME)){
                    throw new BlackPurlException('Username already registered.');
                } else if(err.contains(LICENSE_LIMIT_EXCEEDED)){
                    throw new BlackPurlException('You have reached the adding user limit.');
                } else{
                    throw new BlackPurlException(err);
                }
            }
            List<Technician__c> techList = [Select Id from Technician__c where User__c =: newUserRecord.Id];
            Technician__c clockingStaffObj = new Technician__c();
            if(!techList.isEmpty()) clockingStaffObj.Id = techList[0].Id;
            clockingStaffObj.First_Name__c = userWrapperRecord.firstName;
            clockingStaffObj.Last_Name__c = userWrapperRecord.lastName;
            clockingStaffObj.Technician_Name__c = clockingStaffObj.First_Name__c + ' ' + clockingStaffObj.Last_Name__c;
            if(userWrapperRecord.IsTechnician) {
                clockingStaffObj.Type__c = Constants.TECHNICIAN;
            	clockingStaffObj.Role__c = Constants.TECHNICIAN;
            	clockingStaffObj.Working_Days__c = AccountSettingService.getShopWorkingDaysString();
            }
			clockingStaffObj.Labour_Cost_Per_Hour__c = GeneralConfiguration.getDefaultTechnicianCostingRate();
            clockingStaffObj.Active__c = true;
            List<Technician__c> clockingStaffList = SOQLUtil.getTechnicianListByFieldName(new Map<String, String>());
            for(Technician__c staff: clockingStaffList) {
                if(clockingStaffObj.Technician_Name__c == staff.Technician_Name__c) {
                    clockingStaffObj = staff;
                    break;
                }
            }
            
            clockingStaffObj.User__c = newUserRecord.Id;
            DMLUtility.upsertSobjectList('Technician__c', clockingStaffObj);
            List<User> newUserList = [Select Id, Name, FirstName, LastName, Email, CreatedDate, LastModifiedDate, (SELECT PermissionSet.Name FROM PermissionSetAssignments WHERE PermissionSet.Name = :ENABLE_MFA Limit 1) from User where Id =: newUserRecord.Id];
            if(newUserList.size() > 0) {
            	newUserRecord = newUserList[0];
            	return BPUtility.getEncodedString(System.JSON.serialize(new UserWrapper(newUserRecord, false, userWrapperRecord.IsTechnician)));
            }
            
        }
        return BPUtility.getEncodedString('{}');
    }
    
    /**
     * Name: editUsers
     * Desc: Method which edits user of the Org
     * @param:  (1) JSONString - String - JSON String of UserWrapperList
     * @return: None
    **/

    @RemoteAction
    global static String editUsers(String userWrapperJson){
        userWrapperJson = BPUtility.getDecodedString(userWrapperJson);
        UserWrapper userWrapperRecord = (UserWrapper)System.JSON.deserialize(userWrapperJson,UserWrapper.class);
        User updateUserRecord = new User();
        updateUserRecord.FirstName = userWrapperRecord.firstName;
        updateUserRecord.LastName = userWrapperRecord.lastName;
        updateUserRecord.Email = userWrapperRecord.email;
        updateUserRecord.Id = userWrapperRecord.Id;
        String usrname = userWrapperRecord.firstName + ' ' + userWrapperRecord.lastName;
        
        List<Profile> ProfilesList = [Select id from Profile where name =: BLACKPURL_PROFILE_NAME];
        List<Id> userToEditIdList = new List<Id>{userWrapperRecord.Id};
        List<User> otherUsersList = [Select Name, Email from User where isActive = true and ProfileId IN :ProfilesList and Id NOT IN :userToEditIdList Limit : MAX_TRAIL_USERS];
        for(User userRec: otherUsersList) {
            if(usrname == userRec.Name) {
                throw new BlackPurlException('User with this name already exists.');
            }
            if(userWrapperRecord.email == userRec.Email) {
            	throw new BlackPurlException('User with this email already exists.');
            }
        }
         try{
            DMLUtility.updateSobjectList('User', updateUserRecord);
            
        }
        catch(Exception e){
            if(e.getMessage().contains('DUPLICATE_USERNAME')){
                throw new BlackPurlException('Username already registered.');
            }else{
                throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
            }
        }
        
        List<User> newUserList = [Select Id, Name, FirstName, LastName, Email, CreatedDate, LastModifiedDate, (SELECT PermissionSet.Name FROM PermissionSetAssignments WHERE PermissionSet.Name = :ENABLE_MFA Limit 1) from User where Id =: updateUserRecord.Id];
        if(newUserList.size() > 0) {
        	updateUserRecord = newUserList[0];
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new UserWrapper(updateUserRecord, false, userWrapperRecord.IsTechnician)));
    }
    
    /**
     * Name: deleteUser
     * Desc: Method to deactive user
       @param:    
     * @return: String - id of user to be deactivated
    **/
    @RemoteAction
    global static String deleteUser(String userId){
        userId = BPUtility.getDecodedString(userId);
        
        User userToDel = new User();
        userToDel.Id = userId;
        userToDel.isActive = false;
        DMLUtility.updateSobjectList('User', userToDel);
        
        return getAllUsers();
    }

    public static void updateTechnicianOnUserDelete(Set<String> userIdSet) {
        List<Technician__c> techList = [Select Id from Technician__c where User__c IN: userIdSet];
        String query = 'SELECT ';  
        for(String fieldsName : SOHeaderWrapper.getHoursLoggedFieldsList()) {
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';  
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Hours_Logged__c WHERE Technician__c IN: techList ';

        Map<String,List<Hours_Logged__c>> techIdTohoursLoggedListMap = new Map<String,List<Hours_Logged__c>>();
        for(Hours_Logged__c hoursLoggedRec : Database.query(query)) {
            if(!techIdTohoursLoggedListMap.containsKey(hoursLoggedRec.Technician__c)) {
                techIdTohoursLoggedListMap.put(hoursLoggedRec.Technician__c, new List<Hours_Logged__c>());
            }
            techIdTohoursLoggedListMap.get(hoursLoggedRec.Technician__c).add(hoursLoggedRec);
        }      

        List<Id> idListToDel = new List<Id>();
        List<Id> techIdListToInactive = new List<Id>();
        for(Technician__c techRec : techList) {
            List<Hours_Logged__c> hoursLoggedList = techIdTohoursLoggedListMap.containsKey(techRec.Id) ? techIdTohoursLoggedListMap.get(techRec.Id) : new List<Hours_Logged__c>();
            Boolean isCurrentlyClocked = false;
            Boolean isPreviouslyClocked = false;
            if(hoursLoggedList.size() == 0) {            
                idListToDel.add(techRec.Id);
            } else if(hoursLoggedList.size() > 0) {
            	List<Id> hoursLoggedToDel = new List<Id>();
                for(Hours_Logged__c hrsLogged: hoursLoggedList) {
                    if(!isCurrentlyClocked && hrsLogged.Start_Date_Time__c != null && hrsLogged.End_Date_Time__c == null) {
                        isCurrentlyClocked = true;
                    }
                    if(!isPreviouslyClocked && hrsLogged.Start_Date_Time__c != null && hrsLogged.End_Date_Time__c != null) {
                        isPreviouslyClocked = true;
                    }
                    if(hrsLogged.Start_Date_Time__c == null && hrsLogged.End_Date_Time__c == null) { // !isAssigedButNotClocked && 
	                    //isAssigedButNotClocked = true;
	                    hoursLoggedToDel.add(hrsLogged.Id);
	                }
                }
                
                if(isCurrentlyClocked) {
                    throw new BlackPurlException('Technician is currently clocked on some service job');
                } else if(isPreviouslyClocked) {                    
                    techRec.Active__c = false;
                    techIdListToInactive.add(techRec.Id);
                } else if(hoursLoggedToDel.size() > 0) {	
                    idListToDel.add(techRec.Id);                
	                idListToDel.addAll(hoursLoggedToDel);	                
	                //delete hoursLoggedToDel;
	                
	            } else {            
                    idListToDel.add(techRec.Id);
                }
            }
        }
        if(!idListToDel.isEmpty())deleteTechnician(idListToDel);
        if(!techIdListToInactive.isEmpty())inactiveTechnician(techIdListToInactive);
    }

    @future
    private static void deleteTechnician(List<Id> idListToDel) {
    	for(Id idValue: idListToDel) {
    		if(idValue.getSobjectType().getDescribe().getName() == Constants.Namespace + 'Technician__c') {
    			Technician__c techToDel = new Technician__c();
        		techToDel.Id = idValue;
        		if(AccessControl.ifObjectIsDeletable('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        		delete techToDel;
    		} else if(idValue.getSobjectType().getDescribe().getName() == Constants.Namespace + 'Hours_Logged__c') {
    			Hours_Logged__c hoursLoggedToDel = new Hours_Logged__c();
		        hoursLoggedToDel.Id = idValue;
		        if(AccessControl.ifObjectIsDeletable('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
		        delete hoursLoggedToDel;
    		}
    	}
    }
    
    @future
    private static void inactiveTechnician(List<Id> techIdListToInactive) {
        List<Technician__c> techListToInactive = new List<Technician__c>();
        for(Id techId : techIdListToInactive) {
            Technician__c techRec = new Technician__c();
            techRec.Id = techId;
            techRec.Active__c = false;
            techListToInactive.add(techRec);
        }
        DMLUtility.updateSobjectList('Technician__c', techListToInactive);
    }
    
    /**
     * Name: getPriceAndTaxMasterData
     * Desc: Method that provides List of all sales tax and price levels
       @param:  
     * @return: String - JSON String of lists of both sales tax and price levels
    **/
    @RemoteAction
    global static String getPriceAndTaxMasterData() {
        List<Price_Level__c> priceLevelList = SOQLUtil.getPriceLevel(new List<Id>());
        List<Country__c> countryList = SOQLUtil.getAllCountry();
        List<Country__c> countryWrapperList = SOQLUtil.getAllCountryWrapper();

        /*List<Fee__c> feeList = new List<Fee__c>();
        String defaultEnvFeeId = Configurations__c.getOrgDefaults().Default_Environmental_Fee__c;
        if(String.isNotBlank(defaultEnvFeeId)) {
        	feeList = SOQLUtil.getFeeByFieldName(new Map<String, String>{'Id' => defaultEnvFeeId});
        }*/
        PriceAndTaxMasterData priceAndTaxMasterDataObj = new PriceAndTaxMasterData(priceLevelList,countryList,countryWrapperList);
        return BPUtility.getEncodedString(System.Json.serialize(priceAndTaxMasterDataObj));
    }
    
    @RemoteAction
    global static String getActiveFeeList() {
    	return BPUtility.getEncodedString(ViewFeeCtrl.getActiveFeeList('Env Fee'));
    }
    
    @RemoteAction
    global static String getAllActiveFeeList(String feeType) {
    	feeType = BPUtility.getDecodedString(feeType);
    	return BPUtility.getEncodedString(ViewFeeCtrl.getActiveFeeList(feeType));
    }
    
    /**
     * Name: getCurrentConfiguration
     * Desc: Method that provides current configuration data to show on user setting - price and tax section
       @param:  
     * @return: String - JSON String of current configuration data
    **/
    @RemoteAction
    global static String getCurrentConfiguration() {
        List<Price_Level__c> priceLevelList = [Select Id, Name__c from Price_Level__c where Default__c = true];
        Price_Level__c defaultPriceLevelRec;
        if(priceLevelList.size() > 0) {
            defaultPriceLevelRec = priceLevelList[0];
        } else {
            defaultPriceLevelRec = new Price_Level__c();
        }
        List<Business_Profile__c> businessProfiles = SOQLUtil.getBusinessProfileData(new List<id>());
        List<Organization> companyInfoList = [SELECT TimeZoneSidKey FROM Organization limit 1];
        PriceAndTaxWrapper priceAndTaxWrapperObj;
        if(businessProfiles.size() > 0) {
        	priceAndTaxWrapperObj = new PriceAndTaxWrapper(defaultPriceLevelRec, businessProfiles[0]);
        } else{
        	priceAndTaxWrapperObj = new PriceAndTaxWrapper(defaultPriceLevelRec, new Business_Profile__c());
        }
    	priceAndTaxWrapperObj.shopSettingConfiguration = AccountSettingService.getShopSettingData();
    	priceAndTaxWrapperObj.PaymentMethodConfig = AccountSettingService.getPaymentMethodsData();
        priceAndTaxWrapperObj.ServiceJobStatusConfig = AccountSettingService.getServiceJobStatusConfiguration();
        if(companyInfoList.size() > 0) priceAndTaxWrapperObj.TimeZone = companyInfoList[0].TimeZoneSidKey;
        priceAndTaxWrapperObj.TimeZoneList = Schema.SObjectType.User.fields.TimeZoneSidKey.picklistValues; 

        return BPUtility.getEncodedString(System.JSON.serialize(priceAndTaxWrapperObj));
    }
    
    /**
     * Name: savePriceAndTax
     * Desc: Method to save new configuration for sales tax and price level
       @param:  
    **/
    @RemoteAction
    global static string savePriceAndTax(String priceAndTaxJsonData){
        priceAndTaxJsonData = BPUtility.getDecodedString(priceAndTaxJsonData);
        PriceAndTaxWrapper priceAndTaxWrapperObj = (PriceAndTaxWrapper) System.JSON.deserialize(priceAndTaxJsonData, PriceAndTaxWrapper.class);
        if(String.isNotBlank(priceAndTaxWrapperObj.TimeZone)) AdminConfigService.updateOrgTimezone(priceAndTaxWrapperObj.TimeZone);

        //system.assert(false, priceAndTaxWrapperObj);
        DMLUtility.updateSobjectList('Price_Level__c', new Price_Level__c(Id = priceAndTaxWrapperObj.defaultPriceLevel, Default__c = true));
        //List<Sobject> sobjList = new List<Sobject>();
           
        Configurations__c configurationSettingObj = Configurations__c.getOrgDefaults();
        configurationSettingObj.Technician_Hours_Method_On_Jobs__c = priceAndTaxWrapperObj.TechnicianHoursMethodOnJobs;
        configurationSettingObj.Country_Id__c = priceAndTaxWrapperObj.regionId;
        configurationSettingObj.State_Id__c = priceAndTaxWrapperObj.stateId;
        configurationSettingObj.Time_Zone__c = priceAndTaxWrapperObj.TimeZone;
        configurationSettingObj.Dealer_Number__c = priceAndTaxWrapperObj.DealerNumber;
        configurationSettingObj.Default_Odometer_Type__c = priceAndTaxWrapperObj.DefaultOdometerType;
        
        configurationSettingObj.Default_Price_Level_on_Internal_Service__c = priceAndTaxWrapperObj.DefaultPriceLevelOnInternalService;
        configurationSettingObj.Default_Environmental_Fee__c = priceAndTaxWrapperObj.DefaultEnvironmentalFee;
        configurationSettingObj.Stamp_Duty_Rate__c = priceAndTaxWrapperObj.StampDutyRate;
        configurationSettingObj.Default_Technician_Cost_Rate__c = priceAndTaxWrapperObj.DefaultTechnicianCostingRate;  
		configurationSettingObj.Hide_Hours_Rate_On_Service_Documents__c = priceAndTaxWrapperObj.IsHideHoursRateOnServiceJob;
		configurationSettingObj.Hide_Part_Numbers_On_Documents__c = priceAndTaxWrapperObj.IsHidePartNumbersOnDocuments;
        configurationSettingObj.Hide_Kit_Details_On_Documents__c = priceAndTaxWrapperObj.IsHideKitDetailsOnDocuments;
        configurationSettingObj.Is_Ready_To_Invoice_Required_To_Finalize__c = priceAndTaxWrapperObj.IsReadyToInvoiceRequiredToFinalize;
        configurationSettingObj.Include_Zero_Priced_Deal_Options_On_Doc__c = priceAndTaxWrapperObj.IsIncludeZeroPricesDealOptionOnDoc;
        configurationSettingObj.Include_MSRP_and_Discount_on_Part_Lines__c = priceAndTaxWrapperObj.IsIncludeMSRPAndDiscountOnPartLines;
		configurationSettingObj.Enforce_Payroll_PIN__c = priceAndTaxWrapperObj.IsEnforcePayrollPIN;
        configurationSettingObj.Enforce_Technician_PIN__c = priceAndTaxWrapperObj.IsEnforceTechnicianPIN;      
        configurationSettingObj.Show_TBD_On_Invoice_Previews__c = priceAndTaxWrapperObj.ShowTBDOnInvoicePreviews;
        configurationSettingObj.Record_Tracking_Numbers__c = priceAndTaxWrapperObj.IsRecordTrackingNumbers;
        configurationSettingObj.Shopify_TT_Id__c = priceAndTaxWrapperObj.ShopifyTTId;
        configurationSettingObj.Allow_Customer_Service_Job_Without_Unit__c = priceAndTaxWrapperObj.AllowCustomerServiceJobWithoutUnit;
        if(configurationSettingObj.Allow_Customer_Service_Job_Without_Unit__c) { BPScriptManager.createGenericCOU(); }
        if(configurationSettingObj.Shopify_Payment_Method_Id__c != priceAndTaxWrapperObj.ShopifyPaymentMethodId) {
            configurationSettingObj.Shopify_Payment_Method_Id__c = priceAndTaxWrapperObj.ShopifyPaymentMethodId;
            AccountSettingService.setUndepositFundGLOnShopifyPaymentMethod(priceAndTaxWrapperObj.PaymentMethodConfig, priceAndTaxWrapperObj.ShopifyPaymentMethodId);
        }
        configurationSettingObj.Shopify_Fee_Id__c = priceAndTaxWrapperObj.ShopifyFeeId;
        configurationSettingObj.Shopify_Discount_Fee_Id__c = priceAndTaxWrapperObj.ShopifyDiscountFeeId;
        configurationSettingObj.Shopify_Shipping_Fee_Id__c = priceAndTaxWrapperObj.ShopifyShippingFeeId;
        configurationSettingObj.Auto_Select_Orders_In_Part_Receiving__c = priceAndTaxWrapperObj.IsAutoSelectOrdersInPartReceiving;
        configurationSettingObj.Always_obey_publish_in_feeds__c = priceAndTaxWrapperObj.AlwaysObeyPublishInFeeds;
        configurationSettingObj.Acceptable_Part_Cost_Variance__c = priceAndTaxWrapperObj.AcceptablePartCostVariance;
        configurationSettingObj.Include_Prices_On_Part_Labels__c = priceAndTaxWrapperObj.IsIncludePricesOnPartLabels;

        configurationSettingObj.Automatically_Archive_Quotes__c = (priceAndTaxWrapperObj.IsAutomaticallyArchiveQuotes != null && priceAndTaxWrapperObj.IsAutomaticallyArchiveQuotes);
        configurationSettingObj.Automatically_Archive_After_Days__c = 
        (configurationSettingObj.Automatically_Archive_Quotes__c ? ((priceAndTaxWrapperObj.AutomaticallyArchiveAfter != null && 
        priceAndTaxWrapperObj.AutomaticallyArchiveAfter > 0) ? priceAndTaxWrapperObj.AutomaticallyArchiveAfter : 180) : null);

        configurationSettingObj.Automatically_Delete_Quotes__c = (priceAndTaxWrapperObj.IsAutomaticallyDeleteQuotes != null && priceAndTaxWrapperObj.IsAutomaticallyDeleteQuotes);
        configurationSettingObj.Automatically_Delete_After_Days__c = 
        (configurationSettingObj.Automatically_Delete_Quotes__c ? ((priceAndTaxWrapperObj.AutomaticallyDeleteAfter != null && 
        priceAndTaxWrapperObj.AutomaticallyDeleteAfter > 0) ? priceAndTaxWrapperObj.AutomaticallyDeleteAfter : 180) : null);

        if(configurationSettingObj.DF_commission_in_FI_company_payments__c != priceAndTaxWrapperObj.DFCommissionInFICompanyPayments) {
            if(!priceAndTaxWrapperObj.DFCommissionInFICompanyPayments) {
                List<Account> vendorRecList = [Select Id FROM Account WHERE Commissions_not_in_finance_payments__c = true];
                for(Account vendorRec : vendorRecList) {
                    vendorRec.Commissions_not_in_finance_payments__c = false;
                }
                DMLUtility.updateSobjectList('Account', vendorRecList);
            }
            configurationSettingObj.DF_commission_in_FI_company_payments__c = priceAndTaxWrapperObj.DFCommissionInFICompanyPayments;
        }
        configurationSettingObj.Is_Charge_On_Account_Restricted__c = priceAndTaxWrapperObj.IsChargeOnAccountRestricted;
        configurationSettingObj.Allow_Pause_Of_Job_Clocking__c = priceAndTaxWrapperObj.AllowPauseOfJobClocking;
        configurationSettingObj.Enable_Automatic_Payment_Surcharges__c = priceAndTaxWrapperObj.isAutomaticPaymentSurchargeEnabled;
        configurationSettingObj.Allow_fulfilling_of_deal_unit_options__c = priceAndTaxWrapperObj.AllowQuickFulfillingDealUnitOptions;
        configurationSettingObj.Form_Id_To_Include_On_Deal_Documents__c = priceAndTaxWrapperObj.FormIdToIncludeOnDealDocuments;
        
        Part_Aging_Period__c partAgingObj = Part_Aging_Period__c.getOrgDefaults();
        Boolean isValueChangedForAgeing = false;
        if(priceAndTaxWrapperObj.Period1 != partAgingObj.Period_1__c || priceAndTaxWrapperObj.Period2 != partAgingObj.Period_2__c ||
            priceAndTaxWrapperObj.Period3 != partAgingObj.Period_3__c || priceAndTaxWrapperObj.Period4 != partAgingObj.Period_4__c) {
            isValueChangedForAgeing = true;
        }
        partAgingObj.Period_1__c = priceAndTaxWrapperObj.Period1;
        partAgingObj.Period_2__c = priceAndTaxWrapperObj.Period2;
        partAgingObj.Period_3__c = priceAndTaxWrapperObj.Period3;
        partAgingObj.Period_4__c = priceAndTaxWrapperObj.Period4;
        
        Shop_Supplies__c shopSuppliesObj = Shop_Supplies__c.getOrgDefaults();
        shopSuppliesObj.Applicable_Fee__c = priceAndTaxWrapperObj.ApplicableFee;
        shopSuppliesObj.Calculation_Method__c = priceAndTaxWrapperObj.CalculationMethod;
        shopSuppliesObj.Itemized_by_labor_code__c = priceAndTaxWrapperObj.ItemizedByLaborCode;
        shopSuppliesObj.Maximum_Per_Invoice__c = priceAndTaxWrapperObj.MaximumPerInvoice;
        shopSuppliesObj.Supplies_Rate__c = priceAndTaxWrapperObj.SuppliesRate;
        DMLUtility.upsertSobjectList('Shop_Supplies__c', shopSuppliesObj);
        DMLUtility.upsertSobjectList('Configurations__c', configurationSettingObj);
        DMLUtility.upsertSobjectList('Part_Aging_Period__c', partAgingObj);
        
        if(isValueChangedForAgeing) {
            Database.executeBatch(new PartSyncAgeBatch_Schedular(), 200); 
        }
        
        List<Business_Profile__c> businessProfiles = SOQLUtil.getBusinessProfileData(new List<id>());
        if(businessProfiles.size() > 0) {
        	Business_Profile__c businessProfileRec =  businessProfiles[0];
        	if(AccessControl.ifObjectFieldIsUpdateable('Business_Profile__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
	        
	        businessProfileRec.Customer_Invoice_Warranty_Text__c = priceAndTaxWrapperObj.CustomerInvoiceWarrantyText;
	        businessProfileRec.Service_Job_Warranty_Text__c = priceAndTaxWrapperObj.ServiceJobWarrantyText;
	        businessProfileRec.Order_Deposit_Warranty_Text__c = priceAndTaxWrapperObj.OrderDepositWarrantyText;
	        businessProfileRec.Deal_Documents_Warranty_Text__c = priceAndTaxWrapperObj.DealDocumentsWarrantyText;
	        businessProfileRec.Sales_Receipt_Warranty_Text__c = priceAndTaxWrapperObj.SalesReceiptWarrantyText;
	         
	        businessProfileRec.is_Signature_Line_for_Customer_Invoice__c = priceAndTaxWrapperObj.IsSignatureLineforCustomerInvoice;
	        businessProfileRec.is_Signature_Line_for_Service_Job__c = priceAndTaxWrapperObj.IsSignatureLineforServiceJob;
	        businessProfileRec.is_Signature_Line_for_Order_Deposit__c = priceAndTaxWrapperObj.IsSignatureLineforOrderDeposit;
	        businessProfileRec.Is_Signature_Line_for_Deal_Documents__c = priceAndTaxWrapperObj.IsSignatureLineforDealDocuments;
	        businessProfileRec.Is_Signature_Line_for_Sales_Receipt__c = priceAndTaxWrapperObj.IsSignatureLineforSalesReceipt;
	        
            DMLUtility.updateSobjectList('Business_Profile__c', businessProfileRec);
        }
        List<Shop_Settings__c> shopSettingList = new List<Shop_Settings__c>();
        if(priceAndTaxWrapperObj.shopSettingConfiguration != null) {
        	shopSettingList = AccountSettingService.setShopSettingConfigRec(priceAndTaxWrapperObj.shopSettingConfiguration);
            DMLUtility.updateSobjectList('Shop_Settings__c', shopSettingList);
        }
        
        List<Payment_Method__c> paymentMethodRecList = new List<Payment_Method__c>();
        if(priceAndTaxWrapperObj.PaymentMethodConfig != null) {
        	paymentMethodRecList = AccountSettingService.setPaymentMethodConfiguration(priceAndTaxWrapperObj.PaymentMethodConfig);
            DMLUtility.updateSobjectList('Payment_Method__c', paymentMethodRecList);
        }
        AccountSettingService.saveServiceJobStatusConfiguration(priceAndTaxWrapperObj.ServiceJobStatusConfig);
        return getCurrentConfiguration();
    }
    
    /**
     * Name: getBusinessProfileMasterData
     * Desc: Method that provides master data for business profile section
       @param:  
     * @return: String - JSON String of lists of countries and states along with business profile warpper object
    **/
    @RemoteAction
    global static String getBusinessProfileMasterData(){
        List<Country__c> countryWrapperList = SOQLUtil.getAllCountryWrapper();
        List<Business_Profile__c> businessProfiles = SOQLUtil.getBusinessProfileData(new List<id>());
        BusinessProfileMasterData businessProfileMasterDataObj = new BusinessProfileMasterData(countryWrapperList, businessProfiles);
        
        return BPUtility.getEncodedString(System.JSON.serialize(businessProfileMasterDataObj));
    }
    
     /**
     * Name: getBillingProfile
     * Desc: Method that provides master data for business profile section
       @param:  
     * @return: String - JSON String of lists of countries and states along with business profile warpper object
    **/
     @RemoteAction 
     global static Integer getBillingProfile(){
        if(AccessControl.ifObjectFieldIsAccessible('User') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<User> userList = [Select id, createddate from user ORDER BY createddate ASC LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
        String namespace = [Select NamespacePrefix, Name, Id From ApexClass where Name = 'Constants'].NamespacePrefix;

        List<PackageLicense> packLicRec = [SELECT Id,Status,Expirationdate, NamespacePrefix FROM PackageLicense WHERE
                             NamespacePrefix = :namespace];
         Integer noOfDays = 0;
         if(packLicRec.size() > 0 && packLicRec[0].Expirationdate != null){
            Date startDate = Date.valueOf(packLicRec[0].Expirationdate);  
            noOfDays = (Date.today().daysBetween(startDate));
         }
        return noOfDays;
    }
    
    
    /**
     * Name: saveBusinessProfile
     * Desc: Method to save new configuration for business profile
       @param:  
    **/
    @RemoteAction
    global static string saveBusinessProfile(String BusinessProfileJsonData){
        BusinessProfileJsonData = BPUtility.getDecodedString(BusinessProfileJsonData);
        
        BusinessProfileWrapper businessProfileObj = (BusinessProfileWrapper) System.JSON.deserialize(BusinessProfileJsonData, BusinessProfileWrapper.class);
        Business_Profile__c businessProfile = new Business_Profile__c();
          
        if(businessProfileObj.Id != null) {
            businessProfile.Id = businessProfileObj.Id;
        }
        
        businessProfile.Business_Name__c = businessProfileObj.BusinessName;
        businessProfile.Business_Phone__c = businessProfileObj.BusinessPhone;
        businessProfile.Business_Email__c = businessProfileObj.BusinessEmail;
        businessProfile.Abbreviated_Business_Name__c = businessProfileObj.AbbreviatedBusinessName;
        businessProfile.Business_Street_Address1__c = businessProfileObj.BusinessStreetAddress1;
        businessProfile.Business_Street_Address2__c = businessProfileObj.BusinessStreetAddress2;
        businessProfile.Business_City__c = businessProfileObj.BusinessCity;
        businessProfile.Business_Postal_Code__c = businessProfileObj.BusinessZipCode;
        businessProfile.Business_Country__c = businessProfileObj.BusinessCountryId;
        businessProfile.Business_State__c = businessProfileObj.BusinessStateId;
        
        businessProfile.Same_As_Business_Address__c = businessProfileObj.IsSameAsBusinessAddress;
        
        if(businessProfileObj.isSameAsBusinessAddress == true){
            businessProfile.Shipping_Street_Address1__c = businessProfileObj.BusinessStreetAddress1;
            businessProfile.Shipping_Street_Address2__c = businessProfileObj.BusinessStreetAddress2;
            businessProfile.Shipping_City__c = businessProfileObj.BusinessCity;
            businessProfile.Shipping_Postal_Code__c = businessProfileObj.BusinessZipCode;
            businessProfile.Shipping_Country__c = businessProfileObj.BusinessCountryId;
            businessProfile.Shipping_State__c = businessProfileObj.BusinessStateId;
        }else{
            businessProfile.Company_Name_Optional__c = businessProfileObj.ShippingCompanyName;
            businessProfile.Shipping_Street_Address1__c = businessProfileObj.ShippingStreetAddress1;
            businessProfile.Shipping_Street_Address2__c = businessProfileObj.ShippingStreetAddress2;
            businessProfile.Shipping_City__c = businessProfileObj.ShippingCity;
            businessProfile.Shipping_Postal_Code__c = businessProfileObj.ShippingZipCode;
            businessProfile.Shipping_Country__c = businessProfileObj.ShippingCountryId;
            businessProfile.Shipping_State__c = businessProfileObj.ShippingStateId;
        }
       
        DMLUtility.upsertSobjectList('Business_Profile__c', businessProfile);
        
        return getBusinessProfileMasterData();
    }
    
    
    
    /**
     * Name: sendEmail
     * Desc: Method to send Email for support and contact
       @param:  
    **/
    @RemoteAction
    global static String sendEmail(String subjectKey){
        subjectKey = BPUtility.getDecodedString(subjectKey);
        
        List<Business_Profile__c> businessProfiles = SOQLUtil.getBusinessProfileData(new List<id>());
        Business_Profile__c businessProfileObj = businessProfiles.size() > 0 ? businessProfiles[0] : null;
        String companyName = businessProfileObj != null ? businessProfileObj.Business_Name__c : '';
        String subject = getMailSubject(subjectKey, companyName);
        String htmlBody = getEmailTemplateBody(subjectKey, businessProfileObj);
        
        String defaultEmail = GeneralConfiguration.getSupportEmail();
        List<String> emailStrList = new List<String>{defaultEmail};
        try{
            SendEmail.sendSupportMail(emailStrList, subject, htmlBody); 
        }catch(Exception e){
            throw new BlackPurlException(Label.NewHomePage_Mail_error);
        }
        
        return BPUtility.getEncodedString(Label.NewHomePage_Conatct_Support);
    }
    
    
    /* deprecated */
    global static string sendEmail(String subject, String htmlBody){
        /*subject = BPUtility.getDecodedString(subject);
        htmlBody = BPUtility.getDecodedString(htmlBody);
        String defaultEmail = 'hitesh.gupta@metacube.com';
        List<String> emailStrList = new List<String>{defaultEmail};
        try{
            SendEmail.sendSupportMail(emailStrList, subject, htmlBody); 
        }catch(Exception e){
            throw new BlackPurlException(Label.NewHomePage_Mail_error);
        }
        */
        return BPUtility.getEncodedString('');
    }
    
    public static String getMailSubject(String subjectKey, String companyName) {
        if(subjectKey == 'Add Licences'){
             return '[License Request] : Add user license request for '+ companyName;
        }
        else if(subjectKey == 'Buy More Licenses'){
             return '[License Request] : Add user license request for '+ companyName;
        }
        else if(subjectKey == 'Upgrade Your Account'){
             return ' [Account Upgrade Request] : Upgrade Account status for '+companyName;
        }
        else if(subjectKey == 'Cancel Your Licenses'){
             return '[License Cancel Request] : Cancel user license request for '+companyName;
        }else{
            return '';          
        }
    }
    
    public static String getEmailTemplateBody(String subjectKey, Business_Profile__c businessProfileObj) {
        String htmlBody = '';
        Boolean IsTrialOrg = GeneralConfiguration.isTrialOrg();
        Boolean IsSystemSettingVisited = GeneralConfiguration.isSystemSettingVisited();
        String LicenseStatus = IsTrialOrg ? (IsSystemSettingVisited ? 'Trial with own data' : 'Trial with Demo data') : 'Licensed';
        if(businessProfileObj == null){
            htmlBody = 'No information provided';
        }else{
            if(subjectKey == 'Add Licences'){
                htmlBody += '<p>A request has been sent to add more users licences by </p>';
                htmlBody += '<p>Company Name :-   '+ BusinessProfileObj.Business_Name__c +'</p>';
                htmlBody += '<p>Org ID :-         '+ UserInfo.getOrganizationId() +'</p>';
                htmlBody += '<p>License Status :- '+ LicenseStatus +'</p>';
                htmlBody += '<p>Contact Number :- '+ BusinessProfileObj.Business_Phone__c +'</p>';
                htmlBody += '<p>Email :-          '+ BusinessProfileObj.Business_Email__c +'</p>';
            }
            else if(subjectKey == 'Buy More Licenses'){
                htmlBody += '<p>A request has been sent to add more users licences by </p>';
                htmlBody += '<p>Company Name :-   '+ BusinessProfileObj.Business_Name__c +'</p>';
                htmlBody += '<p>Org ID :-         '+ UserInfo.getOrganizationId() +'</p>';
                htmlBody += '<p>License Status :- '+ LicenseStatus +'</p>';
                htmlBody += '<p>Contact Number :- '+ BusinessProfileObj.Business_Phone__c +'</p>';
                htmlBody += '<p>Email :-          '+ BusinessProfileObj.Business_Email__c +'</p>';
            }
            else if(subjectKey == 'Upgrade Your Account'){
                htmlBody += '<p>A request has been sent to upgrade account status by </p>';
                htmlBody += '<p>Company Name :-   '+ BusinessProfileObj.Business_Name__c +'</p>';
                htmlBody += '<p>Org ID :-         '+ UserInfo.getOrganizationId() +'</p>';
                htmlBody += '<p>License Status :- '+ LicenseStatus +'</p>';
                htmlBody += '<p>Contact Number :- '+ BusinessProfileObj.Business_Phone__c +'</p>';
                htmlBody += '<p>Email :-          '+ BusinessProfileObj.Business_Email__c +'</p>';
            }
            else if(subjectKey == 'Cancel Your Licenses'){
                htmlBody += '<p>A request has been sent to cancel/reduce user licences status by </p>';
                htmlBody += '<p>Company Name :-   '+ BusinessProfileObj.Business_Name__c +'</p>';
                htmlBody += '<p>Org ID :-         '+ UserInfo.getOrganizationId() +'</p>';
                htmlBody += '<p>License Status :- '+ LicenseStatus +'</p>';
                htmlBody += '<p>Contact Number :- '+ BusinessProfileObj.Business_Phone__c +'</p>';
                htmlBody += '<p>Email :-          '+ BusinessProfileObj.Business_Email__c +'</p>';
            }
        }
        return htmlBody;
    }
    
    
    /**
     * Name: upgradeAccount
     * Desc: Method to send Email for upgrade Account
       @param:  
    **/
    @RemoteAction
    global static string upgradeAccount(String billingInfo){
        billingInfo = BPUtility.getDecodedString(billingInfo);
        
        BillingWrapper billingInfoObj = (BillingWrapper)System.JSON.deserialize(billingInfo, BillingWrapper.class);
       //system.assert(false, billingInfoObj);
        List<String> monthNames = new List<String>{'','Jan', 'Feb', 'Mar','Apr', 'May', 'Jun', 'Jul','Aug', 'Sep', 'Oct','Nov', 'Dec'};
       	String dateFormat = BPUtility.getDateFormat();
        String UpgradeDate = '';
        if(billingInfoObj.UpgradeDate != null){
        	List<String> dateFormatList = dateFormat.Split('/');
        	List<String> formattedDate = billingInfoObj.UpgradeDate.split('/');
            if(dateFormatList[0].equals('mm')){
            	formattedDate[0] = monthNames[Integer.valueof(formattedDate[0])];
            }else if(dateFormatList[1].equals('mm')){
            	formattedDate[1] = monthNames[Integer.valueof(formattedDate[1])];
            }
            
            UpgradeDate = formattedDate[0] +'-'+formattedDate[1] +'-'+formattedDate[2];
        }
        Boolean IsTrialOrg = GeneralConfiguration.isTrialOrg();
        Boolean IsSystemSettingVisited = GeneralConfiguration.isSystemSettingVisited();
        String LicenseStatus = IsTrialOrg ? (IsSystemSettingVisited ? 'Trial with own data' : 'Trial with Demo data') : 'Licensed';
        List<Business_Profile__c> businessProfiles = SOQLUtil.getBusinessProfileData(new List<id>());
        Business_Profile__c businessProfileObj = businessProfiles.size() > 0 ? businessProfiles[0] : null;
        String companyName = businessProfileObj != null ? businessProfileObj.Business_Name__c : '';
        String subject = '[Upgrade Account Request] : Upgrade Account request for '+companyName;
        String htmlBody = '';
        
        if(businessProfileObj == null){
            htmlBody = 'No information provided';
        }else{
            htmlBody += '<p>A request has been sent to upgrade Account by </p>';
            htmlBody += '<p>Phone No:-    '+ billingInfoObj.IDDCode+'-'+billingInfoObj.Phone+'</p>';
            htmlBody += '<p>Date :-   '+ UpgradeDate +'</p>';
            htmlBody += '<p>Time :-   '+ billingInfoObj.UpgradeTime +'</p>';
            htmlBody += '<p style="font-weight: bold;">Business Information :-</p>';
            htmlBody += '<p>Company Name :-   '+ BusinessProfileObj.Business_Name__c +'</p>';
            htmlBody += '<p>Org ID :-         '+ UserInfo.getOrganizationId() +'</p>';
            htmlBody += '<p>License Status :- '+ LicenseStatus +'</p>';
            htmlBody += '<p>Contact Number :- '+ BusinessProfileObj.Business_Phone__c +'</p>';
            htmlBody += '<p>Email :-          '+ BusinessProfileObj.Business_Email__c +'</p>';
        }
        
        String defaultEmail = GeneralConfiguration.getSupportEmail();
        List<String> emailStrList = new List<String>{defaultEmail};
        try{
            SendEmail.sendSupportMail(emailStrList, subject, htmlBody); 
        }catch(Exception e){
            throw new BlackPurlException(Label.NewHomePage_Mail_error);
        }
        
        return BPUtility.getEncodedString(Label.NewHomePage_Conatct_Support);
    }
    
    
    /**
     * Name: setSystemSettingVisited
     * Desc: Method to set system setting visited flag to true
       @param:  
    **/
    @RemoteAction
    global static void setSystemSettingVisited(){
        Boolean IsSystemSettingVisited = GeneralConfiguration.isSystemSettingVisited();
        if(!IsSystemSettingVisited){
            General_Configurations__c GCObj = General_Configurations__c.getOrgDefaults();
            GCObj.Is_System_Setting_Visited__c = true;
            DMLUtility.upsertSobjectList('General_Configurations__c', GCObj);
        }
    }
    
    /* MYOB related methods */
    @RemoteAction
    global static string getExportFiles(){return null;}
    
    @RemoteAction
    global static string exportData(){return null;}

    public class UserWrapper{
        private String name;
        private String firstName;
        private String lastName;
        private String email;
        private Boolean isNew;
        private String id;
        private Boolean isTechnician;
        private String createdDate;
        private String lastModifiedDate;
        private Boolean isMFAEnabled;
        private String userSFUrl;
        
        public UserWrapper(String name,String email,Boolean isNew,String id){
            this.name = name;
            this.email = email;
            this.isNew = isNew;
            this.id = id;
        }
        
        public UserWrapper(User userRec, Boolean isNew, Boolean IsTechnician){
            this.name = userRec.Name;
            this.firstName = userRec.FirstName;
            this.lastName = userRec.LastName;
            this.email = userRec.Email;
            this.isNew = isNew;
            this.id = userRec.Id;
            this.isTechnician = IsTechnician;
            String userLocale = UserInfo.getLocale();
            this.createdDate = userRec.CreatedDate != null ? userRec.CreatedDate.format(Constants.localeToDateTimeFmtMap.get(userLocale)) : null;
            this.lastModifiedDate = userRec.LastModifiedDate != null ? userRec.LastModifiedDate.format(Constants.localeToDateTimeFmtMap.get(userLocale)) : null;
            this.isMFAEnabled = (userRec.PermissionSetAssignments != null && !userRec.PermissionSetAssignments.isEmpty());
            this.userSFUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' +  this.id + '?noredirect=1';
        }
    }
    
    public class PriceAndTaxMasterData{
        public List<RecordItem> priceLevelList;
        public List<Country> countryList;
        public List<CountryWrapper> stateList;
        
        public PriceAndTaxMasterData(List<Price_Level__c> priceLevelList, List<Country__c> countryList, 
        									List<Country__c> countryWrapperList){  
            this.countryList = new List<Country>();
            this.stateList = new List<CountryWrapper>();
            this.priceLevelList = new List<RecordItem>();
            for(Price_Level__c priceLevelObj : priceLevelList){
                this.priceLevelList.add(new RecordItem(priceLevelObj.Name__c, priceLevelObj.Id));
            }
            for(Country__c countryObj : countryWrapperList){
                this.countryList.add(new Country(countryObj));
            }
        }
    }
    
    public class BusinessProfileMasterData{
        public List<Country> CountryList;
        public BusinessProfileWrapper BusinessProfileObj;
        
        public BusinessProfileMasterData(List<Country__c> countryWrapperList, List<Business_Profile__c> businessProfiles){  
            
            if(businessProfiles.size() > 0){
                BusinessProfileObj = new BusinessProfileWrapper(businessProfiles[0]);
            }else{
                BusinessProfileObj = new BusinessProfileWrapper(new Business_Profile__c());
            }
            
            this.countryList = new List<Country>();
            for(Country__c countryObj : countryWrapperList){
                this.countryList.add(new Country(countryObj));
            }
        }
    }
    
    
    public class BillingWrapper{
        private String IDDCode;
        private String UpgradeTime;
        private String Phone;
        private String UpgradeDate;
        public BillingWrapper(){
            
        }
    }
    
    public Static Map<String, List<String>> BUSINESS_PROFILE_FIELDS_TO_JSON_MAPPING = 
                                                                    new Map<String, List<String>>{'Business_Profile__c' => new List<String>{'id',
                                                                                                                                            'Business_Name__c',
                                                                                                                                            'Business_Phone__c',
                                                                                                                                            'Business_Email__c','Business_Street_Address1__c',
                                                                                                                                            'Abbreviated_Business_Name__c',
                                                                                                                                            'Business_Street_Address2__c','Business_City__c',
                                                                                                                                            'Business_Postal_Code__c',
                                                                                                                                            'Business_Country__c',
                                                                                                                                            'Business_Country__r.Name__c',
                                                                                                                                            'Business_State__c',
                                                                                                                                            'Business_State__r.Name__c',
                                                                                                                                            'Business_State__r.Display_Name__c',
                                                                                                                                            'Same_As_Business_Address__c',
                                                                                                                                            'Company_Name_Optional__c',
                                                                                                                                            'Shipping_Street_Address1__c',
                                                                                                                                            'Shipping_Street_Address2__c',
                                                                                                                                            'Shipping_City__c',
                                                                                                                                            'Shipping_Postal_Code__c',
                                                                                                                                            'Shipping_Country__c',
                                                                                                                                            'Shipping_State__c',
                                                                                                                                            'Formatted_Business_Number__c',
                                                                                                                                            'Customer_Invoice_Warranty_Text__c',
                                                                                                                                            'Service_Job_Warranty_Text__c',
                                                                                                                                            'Order_Deposit_Warranty_Text__c',
                                                                                                                                            'Deal_Documents_Warranty_Text__c',
                                                                                                                                            'Sales_Receipt_Warranty_Text__c',
                                                                                                                                            'Is_Signature_Line_for_Customer_Invoice__c',
                                                                                                                                            'Is_Signature_Line_for_Service_Job__c',
                                                                                                                                            'Is_Signature_Line_for_Order_Deposit__c',
                                                                                                                                            'Is_Signature_Line_for_Deal_Documents__c',
                                                                                                                                            'Is_Signature_Line_for_Sales_Receipt__c',
                                                                                                                                            'Part_Label_Template__c',
                                                                                                                                            'Part_Label_Template_Small__c',
                                                                                                                                            'Dymo_Connect_Large_Label__c',
                                                                                                                                            'Dymo_Connect_Small_Label__c',
                                                                                                                                            'Logo_Height__c',
                                                                                                                                            'Logo_Width__c' }};
    
    public class RecordItem{  
        private String id;
        private String name;
        public RecordItem(String name, String id){
            this.name = name;
            this.id = id.substring(0, 15);
        }
    }
    
     
	@RemoteAction
  	global static String getUserGroupPermission(String userGroupId) {   
	  	userGroupId = BPUtility.getDecodedString(userGroupId);
	    List<User_Group__c> userGroupList = SOQLUtil.getUserGroupList(new Map<String, String>{'Id' => userGroupId});
	    UserGroupWrapper UserGroupPermissionRecord = new UserGroupWrapper(userGroupList[0]);
	    //system.assert(false, System.JSON.serialize(UserGroupPermissionRecord ));
	    return BPUtility.getEncodedString(System.JSON.serialize(UserGroupPermissionRecord ));
    
 	}
    
  	@RemoteAction
  	global static String getAllUserPermissionGroup() {   
  		List<User_Group__c> userGroupList = SOQLUtil.getAllUserGroup();
  		List<UserGroupWrapper.UserPermissionGroup> userPermissionRecList = new List<UserGroupWrapper.UserPermissionGroup>();
  		for(User_Group__c userGroupRec : userGroupList){
  			userPermissionRecList.add(new UserGroupWrapper.UserPermissionGroup(userGroupRec));
  		}
  		return BPUtility.getEncodedString(System.JSON.serialize(userPermissionRecList));
  	}
  
	@RemoteAction
  	global static String createUserGroup(String userGroupJson) { 
  		userGroupJson = BPUtility.getDecodedString(userGroupJson);
  		UserGroupWrapper.UserPermissionGroup userGroupRec = (UserGroupWrapper.UserPermissionGroup)System.JSON.deserialize(userGroupJson, UserGroupWrapper.UserPermissionGroup.class);
  	
  		List<User_Group__c> userGroupToInsert = new List<User_Group__c>();
  	
  		if(userGroupRec.CopyGroupId == null){
	  		User_Group__c usrGroupObj = new User_Group__c();
	  		usrGroupObj.Name = userGroupRec.UserGroupName;
	  		usrGroupObj.Colour_Code__c    = userGroupRec.ColorCode;
	  		userGroupToInsert.add(usrGroupObj);
  		}else{
  			String copyId = userGroupRec.CopyGroupId;
	  		Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
	        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(Constants.NAMESPACE + 'User_Group__c').getDescribe().fields.getMap();
	        Map<String, String> oppFieldAPINametoFieldTypeMap = new Map<String, String>();
	        List<String> fieldAPIList = new List<String>();
	        for(Schema.SObjectField sfield : fieldMap.Values()){
	            schema.describefieldresult dfield = sfield.getDescribe();
	            fieldAPIList.add(dfield.getname());
  		}
  	
	        String query = 'SELECT Id';
	        for(String fieldname : fieldAPIList) {
	        	if(fieldname.toLowerCase() != 'id') {
	        		query += ', ' + fieldname;
	        	}
	        }
	        query += ' FROM User_Group__c WHERE Id = :copyId';
	        List<User_Group__c> userGroupList = (List<User_Group__c>) Database.query(query);
	        
	        if(userGroupList.size() > 0){
	        	User_Group__c usrGroupObj = userGroupList[0].clone(false, true, false, false);
		  		usrGroupObj.Name = userGroupRec.UserGroupName;
		  		usrGroupObj.Colour_Code__c = userGroupRec.ColorCode;
		  		usrGroupObj.Is_System_Created__c = false;
		  		userGroupToInsert.add(usrGroupObj);
	        }
  		}
  		
  		
	  	if(userGroupToInsert.size() > 0){
            DMLUtility.insertSobjectList('User_Group__c', userGroupToInsert);
	  		return userGroupToInsert[0].Id;
	  	}
	  	
  	
  		return '[]';
  	} 
  	
  	@RemoteAction
  	global static String getuserListByGroupId(String groupId) {
  		groupId = BPUtility.getDecodedString(groupId);
  		List<User_To_Group__c> userTogroupJunctionList = 
            SOQLUtil.getUserToGroupList(new Map<String, String>{'User_Group__c' => groupId, 'User__r.Profile.Name' => 'Blackpurl'});
  		List<UserGroupWrapper.UserGroupJunctionWrapper> userGroupJunctionList = new List<UserGroupWrapper.UserGroupJunctionWrapper>();
  		for(User_To_Group__c userToGroupJunctionRec : userTogroupJunctionList){
  			userGroupJunctionList.add(new UserGroupWrapper.UserGroupJunctionWrapper(userToGroupJunctionRec));
  		}
  		return BPUtility.getEncodedString(System.JSON.serialize(userGroupJunctionList));
  	}   
  	 
  	@RemoteAction
  	global static String assignUserToGroup(String usersIdList, String groupId ) {
  	
  		usersIdList = BPUtility.getDecodedString(usersIdList);
  		groupId = BPUtility.getDecodedString(groupId);
		List<String> userIdList = (List<String>)System.JSON.deserialize(usersIdList, List<String>.class);
		
  		Map<String, User_To_Group__c> userIdToUserGroupJunctionMap = new Map<String, User_To_Group__c>();
  		List<User_To_Group__c>  userTogroupList = [SELECT Id, User__c,User_Group__c from User_To_Group__c where User__c IN : userIdList ];
  		
  		List<User_To_Group__c> userJunctionListToDelete = new List<User_To_Group__c>();
  		List<User_To_Group__c> userJunctionListToInsert = new List<User_To_Group__c>();
  		
  		for(User_To_Group__c userGroupJunctionRec : userTogroupList){
  			userJunctionListToDelete.add(userGroupJunctionRec);
  		}
  		if(userJunctionListToDelete.size() > 0){
  			if(AccessControl.ifObjectIsDeletable('User_To_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
  			delete userJunctionListToDelete;
  		}
  		
  		for(String userIdRec : userIdList){
  			User_To_Group__c userToGroupRec = new User_To_Group__c();
  			userToGroupRec.User__c = userIdRec;
  			userToGroupRec.User_Group__c = groupId;
  			userJunctionListToInsert.add(userToGroupRec);
  				
  		}
  		
  		if(userJunctionListToInsert.size() > 0){
            DMLUtility.insertSobjectList('User_To_Group__c', userJunctionListToInsert);
  			
  		}
  		
  		return getuserListByGroupId(BPUtility.getEncodedString(groupId));
  	}
  	
  	
  	@RemoteAction
    global static String getSearchResults(String JSONString) {
    	List<User> usersList = SOQLUtil.getUserListWithGroup();
  		List<UserGroupWrapper.UserGroupJunctionWrapper> userGroupJunctionList = new List<UserGroupWrapper.UserGroupJunctionWrapper>();
  		for(User userObj : usersList){
  			userGroupJunctionList.add(new UserGroupWrapper.UserGroupJunctionWrapper(userObj));
  		}
  		return BPUtility.getEncodedString(System.JSON.serialize(userGroupJunctionList));
    }
    
    @RemoteAction
  	global static String deleteUserGroup(String groupId ) {
  		groupId = BPUtility.getDecodedString(groupId);
  		
  		User_Group__c userGroupRec = new User_Group__c();
  		userGroupRec.Id = groupId;
  		if(AccessControl.ifObjectIsDeletable('User_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
  		delete userGroupRec;
  		
  		return getAllUserPermissionGroup();
  		
    }
    
  	@RemoteAction 
  	global static String updateUserGroup(String UserGroupPermissionJson ) {
	
  		UserGroupPermissionJson = BPUtility.getDecodedString(UserGroupPermissionJson);
  		UserGroupWrapper.UserGroupPermissionList UserGroupPermissionRecord  = (UserGroupWrapper.UserGroupPermissionList)System.JSON.deserialize(UserGroupPermissionJson, UserGroupWrapper.UserGroupPermissionList.class);
		Boolean CheckSystemSetting = false; 
		String UserSettingPermission ='';
		try{  		
	  		List<User_Group__c> userGroupToUpdate = new List<User_Group__c>();
	  		User_Group__c userGroupRec = new User_Group__c();
	  		String CurrentLoggedInUser = UserInfo.getUserId();
	  		if(UserGroupPermissionRecord.UserPermissionGroupDetails.UserGroupId != null){
	  			List<User_To_Group__c>	CurrentUserGroupList = [select User_Group__c,User_Group__r.System_Settings__c from User_To_Group__c where User__c =: CurrentLoggedInUser ];
		  		for(User_To_Group__c   userGroupItem :  CurrentUserGroupList){
		  			if(userGroupItem.User_Group__c ==  UserGroupPermissionRecord.UserPermissionGroupDetails.UserGroupId){
		  				CheckSystemSetting = true;
		  				UserSettingPermission = userGroupItem.User_Group__r.System_Settings__c;
		  				break;
		  			} 
		  		}
		  		userGroupRec.Id = UserGroupPermissionRecord.UserPermissionGroupDetails.UserGroupId;
		  		userGroupRec.Name = UserGroupPermissionRecord.UserPermissionGroupDetails.UserGroupName;
		  		userGroupRec.Colour_Code__c = UserGroupPermissionRecord.UserPermissionGroupDetails.ColorCode;
		  		for(Map<String, UserGroupWrapper.Permission> systemSettingMap : UserGroupPermissionRecord.userGroupPermissions){
		  			for(String  userSetting : systemSettingMap.keySet()){
		  				if(Constants.permissionTypeToFieldAPINameMap.get(userSetting) ==  Constants.permissionTypeToFieldAPINameMap.get('System Settings') && CheckSystemSetting == true){
		  				}
		  				else{
		  					userGroupRec.put(Constants.permissionTypeToFieldAPINameMap.get(userSetting), getPermissionValues(systemSettingMap.get(userSetting).Primary, systemSettingMap.get(userSetting).Secondary));
		  				}
		  			}
		  		}
		  		userGroupToUpdate.add(userGroupRec);
	  		}
	  		//system.assert(false,userGroupRec);
	  		if(userGroupToUpdate.size() > 0){
                DMLUtility.updateSobjectList('User_Group__c', userGroupToUpdate);
	  		}
		 }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
            //return BPUtility.getEncodedString('Sucess');
        }
  		if(CheckSystemSetting){
  			return BPUtility.getEncodedString(UserSettingPermission);
  		}else{
  			return BPUtility.getEncodedString('Sucess');
  		}
  		//getUserGroupPermission(BPUtility.getEncodedString((UserGroupPermissionRecord.UserPermissionGroupDetails.UserGroupId)));
  	}
  	
  	
  	private static string getPermissionValues(boolean Primary , boolean Secondary){
  			String value = '';
  			if(Primary == null){
  				Primary = false;
  			}
  			if(Secondary == null){
  				Secondary = false;
  			}
  			if(!Primary  &&  !Secondary ) {
                value = 'None';
            } else if(Primary  &&  !Secondary ) {
                value = 'Primary';
            } else if(Primary  &&  Secondary ) {
                value = 'Secondary';
            }
  		return value;
  	}
  	
    /**
     * Name: getBusinessInfo
     * Desc: Method that provides data for business profile section 
       @param:  
     * @return: String - JSON String of with business profile warpper object
    **/
    @RemoteAction
    global static String getBusinessInfo(){
        List<Business_Profile__c> businessProfiles = SOQLUtil.getBusinessProfileData(new List<id>());
        if(businessProfiles.size() > 0){
        String businessInfoJson = System.JSON.serialize(new BusinessProfileWrapper(businessProfiles[0]));
        return BPUtility.getEncodedString(businessInfoJson);
        }else{
           	 Business_Profile__c businessProfileWithNoData = new Business_Profile__c();
    		String businessInfoJson = System.JSON.serialize(new BusinessProfileWrapper(businessProfileWithNoData));
            return BPUtility.getEncodedString(businessInfoJson);
        }
    }
    
    /**
     * Name: getUserPermissions
     * Desc: Method that provides data for user permissions by user id 
       @param: String groupId 
     * @return: String - JSON String of with user permissions warpper object
    **/
    @RemoteAction
    global static String getUserPermissions(String userId){
    	userId = BPUtility.getDecodedString(userId);
        String permissionStr = NewHomePageCtrl.getUserPermissions(userId);
        return BPUtility.getEncodedString(permissionStr);
    }
    
    /**
     * Name: createClockingStaff
     * Desc: Method which creates clocking Staff of the dealership
     * @param:  (1) JSONString - String - JSON String of ClockingStaffWrapperList
     * @return: None
    **/

    @RemoteAction
    global static String createClockingStaff(String clockingStaffJson){
        clockingStaffJson = BPUtility.getDecodedString(clockingStaffJson);
        ClockingStaffWrapper clockingStaffWrapperRec = (ClockingStaffWrapper)System.JSON.deserialize(clockingStaffJson,ClockingStaffWrapper.class);
        Technician__c clockingStaffObj = new Technician__c();
        clockingStaffObj.First_Name__c = clockingStaffWrapperRec.FirstName;
        clockingStaffObj.Last_Name__c = clockingStaffWrapperRec.LastName;
        clockingStaffObj.Technician_Name__c = clockingStaffObj.First_Name__c + ' ' + clockingStaffObj.Last_Name__c;
        if(clockingStaffWrapperRec.IsTechnician) {
            clockingStaffObj.Type__c = Constants.TECHNICIAN;
            clockingStaffObj.Role__c = Constants.TECHNICIAN;
            clockingStaffObj.Working_Days__c = AccountSettingService.getShopWorkingDaysString();
        } else {
            clockingStaffObj.Type__c = null;
        }
		clockingStaffObj.Labour_Cost_Per_Hour__c = GeneralConfiguration.getDefaultTechnicianCostingRate();
        clockingStaffObj.Active__c = true;
        if(clockingStaffWrapperRec.Id != null) {
            clockingStaffObj.Id = clockingStaffWrapperRec.Id;
            
        }
        if(clockingStaffWrapperRec.Id == null) {
            List<Technician__c> clockingStaffList = SOQLUtil.getTechnicianListByFieldName(new Map<String, String>());
            for(Technician__c staff: clockingStaffList) {
                if(clockingStaffObj.Technician_Name__c == staff.Technician_Name__c) {
                    throw new BlackPurlException('Clocking Staff already registered.');
                }
            }
        }
        
        try{
            DMLUtility.upsertSobjectList('Technician__c', clockingStaffObj);
            List<Technician__c> newClockingStaffList = SOQLUtil.getTechnicianListByFieldName(new Map<String, String>{'Id' => clockingStaffObj.Id});
            if(newClockingStaffList.size() > 0) {
            	clockingStaffObj = newClockingStaffList[0];
            }
        }
        catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new ClockingStaffWrapper(clockingStaffObj)));
    }
    
    /**
     * Name: editClockingStaff
     * Desc: Method which edits clocking Staff of the dealership
     * @param:  (1) JSONString - String - JSON String of ClockingStaffWrapperList
     * @return: None
    **/

    @RemoteAction
    global static String editClockingStaff(String clockingStaffJson){
        clockingStaffJson = BPUtility.getDecodedString(clockingStaffJson);
        ClockingStaffWrapper clockingStaffWrapperRec = (ClockingStaffWrapper)System.JSON.deserialize(clockingStaffJson,ClockingStaffWrapper.class);
        
        Technician__c techToUpdate = new Technician__c();
        List<User> userList = new List<User>();
        List<SObject> sObjectListToUpdate = new List<SObject>();
        techToUpdate.Id = clockingStaffWrapperRec.Id;
        techToUpdate.First_Name__c = clockingStaffWrapperRec.FirstName;
        techToUpdate.Last_Name__c = clockingStaffWrapperRec.LastName;
        techToUpdate.Technician_Name__c = techToUpdate.First_Name__c + ' ' + techToUpdate.Last_Name__c;
        if(clockingStaffWrapperRec.IsTechnician) {
            techToUpdate.Type__c = Constants.TECHNICIAN;
            techToUpdate.Role__c = Constants.TECHNICIAN;
        	techToUpdate.Working_Days__c = AccountSettingService.getShopWorkingDaysString();
        } else {
            techToUpdate.Type__c = null;
        }
        sObjectListToUpdate.add(techToUpdate);
        
        List<Id> techToEditIdList = new List<Id>{clockingStaffWrapperRec.Id};
        List<Technician__c> otherTechnicianList = [Select Id, Technician_Name__c from Technician__c where Id NOT IN : techToEditIdList AND Active__c = true];
        for(Technician__c staff: otherTechnicianList) {
            if(techToUpdate.Technician_Name__c == staff.Technician_Name__c) {
                throw new BlackPurlException('Clocking Staff with this name already exists.');
            }
        }
        
        if(clockingStaffWrapperRec.Id != null) {
            List<Technician__c> techList = [Select Id, User__c from Technician__c where Id = :clockingStaffWrapperRec.Id];
            if(techList.size() > 0) {
            	if(techList[0].User__c != null) {
	                userList = [Select Id, Name from User where Id = :techList[0].User__c];
	            }
            }
        }
        
        if(userList.size() > 0) {
            userList[0].FirstName = clockingStaffWrapperRec.FirstName;
            userList[0].LastName = clockingStaffWrapperRec.LastName;
            //String usrname = clockingStaffWrapperRec.FirstName + ' ' + clockingStaffWrapperRec.LastName;
            /*if(clockingStaffWrapperRec.FirstName.length() > 6){
                userList[0].Alias = clockingStaffWrapperRec.FirstName.substring(0,6);
            }
            else{
                userList[0].Alias = clockingStaffWrapperRec.FirstName;
            }
            userList[0].CommunityNickname = (usrname.substring(0,3) + Math.random()).substring(0,8);*/
            sObjectListToUpdate.add(userList[0]);
        }
        try{
            if(AccessControl.ifObjectFieldIsUpdateable('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('User') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update sObjectListToUpdate;
            List<Technician__c> newClockingStaffList = SOQLUtil.getTechnicianListByFieldName(new Map<String, String>{'Id' => techToUpdate.Id});
            if(newClockingStaffList.size() > 0) {
            	techToUpdate = newClockingStaffList[0];
            }
        }
        catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        //return getAllClockingStaff();
        return BPUtility.getEncodedString(System.JSON.serialize(new ClockingStaffWrapper(techToUpdate)));
    }
    
    /**
     * Name: getAllClockingStaff
     * Desc: Method which gives  List of Clocking Staff
       @param:    
     * @return: String - JSON String of list of Clocking Staff
    **/
    @RemoteAction
    global static String getAllClockingStaff(){
        if(AccessControl.ifObjectFieldIsAccessible('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Technician__c> clockingStaffList = SOQLUtil.getTechnicianListByFieldName(new Map<String, String>()); //[Select Id, First_Name__c, Last_Name__c, Technician_Name__c, Type__c from Technician__c where Active__c = true];
        List<ClockingStaffWrapper> clockingStaffWrapperList = new List<ClockingStaffWrapper>();
        for(Technician__c clockingStaffRecord : clockingStaffList){
            ClockingStaffWrapper clockingStaffWrapperRecord = new ClockingStaffWrapper(clockingStaffRecord);
            clockingStaffWrapperList.add(clockingStaffWrapperRecord);
        }
        return BPUtility.getEncodedString(System.JSON.serialize(clockingStaffWrapperList));
    }
    
    /**
     * Name: deleteClockingStaff
     * Desc: Method which delete a Clocking Staff
       @param:    
     * @return: String - Id of Clocking Staff to be deleted
    **/
    @RemoteAction
    global static String deleteClockingStaff(String clockingStaffId) {
        clockingStaffId = BPUtility.getDecodedString(clockingStaffId);
        
        Technician__c clockingStaff = new Technician__c();
        clockingStaff.Id = clockingStaffId;
        String query;    
        query = 'SELECT ';  
        for(String fieldsName : SOHeaderWrapper.getHoursLoggedFieldsList()) {
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';  
        }
         
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Hours_Logged__c WHERE Technician__c =: clockingStaffId ';
        if(AccessControl.ifObjectFieldIsAccessible('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Hours_Logged__c> hoursLoggedList = Database.query(query);
        Boolean isCurrentlyClocked = false;
        Boolean isAssigedButNotClocked = false;
        if(hoursLoggedList.size() == 0) {
            clockingStaff.Active__c = false;
            DMLUtility.updateSobjectList('Technician__c', clockingStaff);
        } else if(hoursLoggedList.size() > 0) {
        	Hours_Logged__c hoursLoggedToDel = new Hours_Logged__c();
            for(Hours_Logged__c hrsLogged: hoursLoggedList) {
                if(!isCurrentlyClocked && hrsLogged.Start_Date_Time__c != null && hrsLogged.End_Date_Time__c == null) {
                    isCurrentlyClocked = true;
                    //throw new BlackPurlException('Technician is currently clocked on some service job');
                }
                if(!isAssigedButNotClocked && hrsLogged.Start_Date_Time__c == null && hrsLogged.End_Date_Time__c == null) {
                    isAssigedButNotClocked = true;
                    hoursLoggedToDel = hrsLogged;
                }
            }
            
            if(isCurrentlyClocked) {
                throw new BlackPurlException('Technician is currently clocked on some service job');
            } else {
                clockingStaff.Active__c = false;
                DMLUtility.updateSobjectList('Technician__c', clockingStaff);
                if(isAssigedButNotClocked){
                    DMLUtility.deleteSobjectList('Hours_Logged__c', hoursLoggedToDel);
                }
            }
        }
        return getAllClockingStaff();
    }
  	
    @RemoteAction
    public static List<CategoryService.CategoryWrapper> getTaxCategoryList() {
    	try {
	        return CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => 'Tax'});
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    } 
    
    @RemoteAction
    public static String getAllActiveSalesTax() { 
    	try {
	        return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.getAllActiveSalesTax()));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    public static String saveAccountType(String accountTypeJsonStr) { 
		try {
    		accountTypeJsonStr  = BPUtility.getDecodedString(accountTypeJsonStr);
			return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.addEditAccountType(accountTypeJsonStr)));
		} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    } 
    
    @RemoteAction
    public static String getRecForAccountType(String accTypeId) { 
    	try { 
    		accTypeId  = BPUtility.getDecodedString(accTypeId);
	        return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.getRecForAccountType(accTypeId)));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    } 
    public class ClockingStaffWrapper{
        private String FirstName;
        private String LastName;
        private Boolean IsTechnician;
        private String Id;
        private String createdDate;
        private String lastModifiedDate;
        private Boolean isLicensedUser;
        private String TechnicianName;
        
        public ClockingStaffWrapper(Technician__c staffRecord){
            this.FirstName = staffRecord.First_Name__c;
            this.LastName = staffRecord.Last_Name__c;
            if(staffRecord.Type__c == Constants.TECHNICIAN) {
                this.IsTechnician = true;
            } else {
                this.IsTechnician = false;
            }
            this.Id = staffRecord.Id; 
            this.TechnicianName = staffRecord.Technician_Name__c;
            String userLocale = UserInfo.getLocale();
            this.createdDate = staffRecord.CreatedDate != null ? staffRecord.CreatedDate.format(Constants.localeToDateTimeFmtMap.get(userLocale)) : null;
            this.lastModifiedDate = staffRecord.LastModifiedDate != null ? staffRecord.LastModifiedDate.format(Constants.localeToDateTimeFmtMap.get(userLocale)) : null;
            this.isLicensedUser = staffRecord.User__c != null ? staffRecord.User__r.IsActive : false;
            
        }
    }
    
    @RemoteAction
    public static String getAllPriceLevel() {
    	try {
	        return BPUtility.getEncodedString(System.JSON.serialize(PriceLevelService.getAllPriceLevel()));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    public static String savePriceLevelRecList(String priceLevelRecJson) {
    	priceLevelRecJson = BPUtility.getDecodedString(priceLevelRecJson);
    	try {
    		PriceLevelService.savePriceLevel(priceLevelRecJson);
	        return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    public static String deletePriceLevelById(String priceLevelId) {
    	priceLevelId = BPUtility.getDecodedString(priceLevelId);
    	try {
    		PriceLevelService.deletePriceLevelById(priceLevelId);
	        return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getPriceLevelPriceBookPicklistValues(){
        return BPUtility.getEncodedString(Utility.getPicklistValues('Price_Level__c.Part_Price_Base__c'));
    }

    @RemoteAction
    global static String getTransactionTypeLabelList() { 
        try {
            List<Transaction_Type__c> ttList = [SELECT Id, Code_Label__c, Default__c FROM Transaction_Type__c WHERE Type__c = 'Part Sale' AND Active__c = true Order by Code_Label__c ASC];
            List<MerchandiseService.TransactionTypeLabelWrapper> ttLabelWrapperList = new List<MerchandiseService.TransactionTypeLabelWrapper>();
            for(Transaction_Type__c ttRec : ttList) {
                ttLabelWrapperList.add(new MerchandiseService.TransactionTypeLabelWrapper(ttRec));
            }
            return BPUtility.getEncodedString(System.JSON.serialize(ttLabelWrapperList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        } 
    }

    @RemoteAction
    global static String enableFXCostSetting() {
        QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
        if(String.isNotBlank(qbConfig.Home_Currency__c)) {
            ForeignExchangeUtil.HOME_CURRENCY = qbConfig.Home_Currency__c;
        } else {
            ForeignExchangeUtil.HOME_CURRENCY = UserInfo.getDefaultCurrency();
        }

        //get latest FX currency rate conversion 
        FXCurrencyConversionScheduler.getConversionRateFromXE();

        // get Currencies and markup detail and update latest currency conversion rate 
        ForeignExchangeUtil.FXDetailWrapper fxDetailWrapperObj = ForeignExchangeUtil.getForeignExchangeDetail();
        String response = System.JSON.serialize(ForeignExchangeUtil.updateConversionRate(fxDetailWrapperObj));
        
        // Update home currency
        if(String.isBlank(qbConfig.Home_Currency__c)) {
            qbConfig.Home_Currency__c = ForeignExchangeUtil.HOME_CURRENCY;
            DMLUtility.upsertSobjectList('QuickBooks_Configurations__c', qbConfig);
        }

        // Enable foreign exchange costing
        General_Configurations__c generalConfig = GeneralConfiguration.getGeneralConfigurations();
        generalConfig.Enable_Foreign_Exchange_Costing__c = true;
        DMLUtility.updateSobjectList('General_Configurations__c', generalConfig);

        // Update Conversion Rate on countries
        DMLUtility.updateSobjectList('Country__c', ForeignExchangeUtil.countryListToUpdate);
        if(BaseIntegration.webServiceLogs != null) {
            // Create webservice log
            DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        }

        //Schedule currency conversion rate scheduler 
        ScheduleJobService.scheduleJobs(new Set<String>{ScheduleJobService.XE_CURRENCY_CONVERSION_SCH});

        // Return Currencies and markup detail
        return BPUtility.getEncodedString(response);
    }

    @RemoteAction
    global static void createFXIntegrationConfigs() {
        ForeignExchangeUtil.createIFWConfigAndConfigItemsForXE();
    }

    @RemoteAction
    global static String getForeignExchangeDetail() {
        // Return Currencies and markup detail
        return BPUtility.getEncodedString(System.JSON.serialize(ForeignExchangeUtil.getForeignExchangeDetail()));
    }

    @RemoteAction
    global static void saveExchangeRateMarkup(Decimal markupValue, Boolean isMarkupEnabled) {
        Configurations__c config = GeneralConfiguration.getConfigurations();
        config.Is_Exchange_Rate_Markup_Enable__c = isMarkupEnabled;
        config.Exchange_Rate_Markup__c = markupValue != null ? markupValue.setScale(4, RoundingMode.HALF_UP) : 0;
        DMLUtility.updateSobjectList('Configurations__c', config);
    }

    @RemoteAction
    public static void saveCurrencyDetail(String currencyJSON) {
        List<ForeignExchangeUtil.CurrencyWrapper> currencyWrapperList = (List<ForeignExchangeUtil.CurrencyWrapper>) System.JSON.deserialize(BPUtility.getDecodedString(currencyJSON), List<ForeignExchangeUtil.CurrencyWrapper>.class);
        if(currencyWrapperList.isEmpty() || String.isBlank(currencyWrapperList[0].Id)) throw new BlackpurlException('Required perameters are not found.');

        List<Country__c> countryListToUpdate = new List<Country__c>();
        for(ForeignExchangeUtil.CurrencyWrapper currencyWrapperObj : currencyWrapperList) {
            countryListToUpdate.add(new Country__c(Id = currencyWrapperObj.Id, Active__c = currencyWrapperObj.Active));
        }
        DMLUtility.updateSobjectList('Country__c', countryListToUpdate);
    }

    @RemoteAction
    public static Boolean isMultiCurrencyEnabled() {
        Boolean isMultiCurrencyEnabled = AccountingUtil.isMultiCurrencyEnabled();
        
        if(!isMultiCurrencyEnabled) {
            if(IntegrationServiceFactory.getActiveAccountingIntegrationName() != null) {
                BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
                QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
                
                if(integrationRec != null || integrationRec.integrationConfigRec == null) throw new BlackpurlException('Error communicating with the accounting package, try again later');

                if(integrationRec.integrationConfigRec.Integration_Name__c == QBUtil.QUICKBOOKS_ONLINE) {
                    try {
                        // get multi currency information
                        QBUtil.setCurrencyRef(qbConfig, integrationRec.integrationConfigRec);
                    } catch(Exception e) {
                        // added to create the log records inserted in QBCalloutManager
                    }
                } else if(integrationRec.integrationConfigRec.Integration_Name__c == XeroUtility.XERO) {
                    Map<String, Object> fieldsMap = new Map<String, Object>{'HTTP_Method__c' => 'GET', 'IFW_IntegrationConfig__c' => integrationRec.integrationConfigRec.Id, 'Entity_Name__c' => IntegrationUtility.ORGANISATION};
                    List<IFW_IntegrationConfigItem__c> configItemList = IFW_SOQLUtil.getIntegrationConfigItem(fieldsMap);
                    if(configItemList.size() == 0) throw new BlackpurlException('Config item for Organization not defined');
                    
                    HttpResponse response = BaseIntegration.performCallout(integrationRec.integrationConfigRec, configItemList[0], '', new List<customHttpHeaderWrapper>());
                    if(response.getStatusCode() == 200) {
                      XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
                      if(!xeroResponseWrapper.Organisations.isEmpty()) qbConfig.Home_Currency__c = xeroResponseWrapper.Organisations[0].BaseCurrency;
                    }

                    configItemList[0].Endpoint_URL__c = configItemList[0].Endpoint_URL__c + 's/Actions';
                    XeroUtility.setCurrencyRef(qbConfig, integrationRec.integrationConfigRec, configItemList[0]);
                }
                isMultiCurrencyEnabled = qbConfig.Multi_Currency_Enabled__c;
                
                // Update records
                if(integrationRec != null && integrationRec.integrationConfigRec != null) QBCalloutManager.updateRecords(integrationRec.integrationConfigRec);
                DMLUtility.upsertSobjectList('QuickBooks_Configurations__c', qbConfig);
            }
        }
        return isMultiCurrencyEnabled;
    }

	/** Not in use, These remote actions moved in AdminConfigCtrl **/
    @RemoteAction
    public static String getGeneralInfoConfig() {
        return null;
    }

    @RemoteAction
    public static void setCompanyGeneralInfo(string companyGeneralInfoJsonStr) {
    }

    @RemoteAction
    public static void enableDisableMFA(String userId, Boolean isEnable) {
        if(isEnable) {
            MFAService.enableMFA(BPUtility.getDecodedString(userId));
        } else {
            MFAService.disableMFA(BPUtility.getDecodedString(userId));
        }
    }

    @RemoteAction
    public static Boolean isMFAVerificationMethodRegistered(String userId) {
        return MFAService.isMFAVerificationMethodRegistered(BPUtility.getDecodedString(userId));
    }

    @RemoteAction
    public static void deregisterMFAVerificationMethod(String userId) {
        MFAService.deregisterMFAVerificationMethod(BPUtility.getDecodedString(userId));
    }

    @RemoteAction
    global static String resetAllUsersTimeZone(String timeZone) {
        return BPUtility.getEncodedString(AdminConfigService.resetAllUsersTimezone(BPUtility.getDecodedString(timeZone)));
    }

 
    @RemoteAction
    global static void saveServiceJobStatusConfiguration(String statusConfigJsonStr) {
        statusConfigJsonStr = BPUtility.getDecodedString(statusConfigJsonStr);
        List<ServiceJobStatusWrapper> statusConfigList = (List<ServiceJobStatusWrapper>) System.JSON.deserialize(statusConfigJsonStr, List<ServiceJobStatusWrapper>.class);
        AccountSettingService.saveServiceJobStatusConfiguration(statusConfigList);     
    }

    @RemoteAction
    global static Integer getActiveJobCountBySOStatusId(String statusId) {
        if(String.isNotBlank(statusId)) {
            statusId = BPUtility.getDecodedString(statusId);
            return Integer.valueOf([Select Count(Id) Total FROM Service_Order_Header__c WHERE SO_Status_Ref__c =: statusId][0].get('Total'));
        }
        return null;
    }

    @RemoteAction
    global static String validateAutoPaymentMethodSurcharges() {
        return BPUtility.getEncodedString(String.isNotBlank(Accounting_Default_Accounts__c.getOrgDefaults().Payment_Method_Surcharges__c) ? 'Success' : 'Error');
    }
    @RemoteAction
    global static String getTaxManagementTileAvailability() {
        return BPUtility.getEncodedString(GeneralConfiguration.getConfigurationByName(TAX_MANAGEMENT_TILE_AVAILABLE));
    }

    @RemoteAction
    global static String getActiveFormsListBasedOnGroup(String groupingName) {
        return BPUtility.getEncodedString(system.JSON.serialize(FormRepositoryService.getActiveFormsListBasedOnGroup(BPUtility.getDecodedString(groupingName)), true));
    }

    @RemoteAction
    global static void deleteImagesForForm(String formId) {
        FormRepositoryService.deleteImagesForForm(BPUtility.getDecodedString(formId));
    }

    @RemoteAction
    global static String getProductTypes(String productTypeId) {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitProductTypeService.getProductTypes(BPUtility.getDecodedString(productTypeId))));
    }

    @RemoteAction
    global static void saveProductType(String productTypeJSON) {
        UnitProductTypeService.saveProductType(BPUtility.getDecodedString(productTypeJSON));
    }

    @RemoteAction
    global static String getNewProductTypeDefaultData() {
        return BPUtility.getEncodedString(system.JSON.serialize(UnitProductTypeService.getNewProductTypeDefaultData()));
    }

    @RemoteAction
    global static Boolean isUnitTypeActiveFTPFeedAvailable() {
        List<GE_File_Config__c> unitGEFileConfig = [SELECT Id FROM GE_File_Config__c WHERE Object_API_Name__c = 'Customer_Owned_Unit__c' AND Send_to_FTP__c = true Limit 1];
        return !unitGEFileConfig.isEmpty();
    }

    @RemoteAction
    public static String getAllStampDutyList() {
    	try {
	        return BPUtility.getEncodedString(System.JSON.serialize(StampDutyService.getAllStampDutyList()));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String deleteStampDutyById(String recordId) {
        recordId = BPUtility.getDecodedString(recordId);
    	try {
    		StampDutyService.deleteStampDutyById(recordId);
	        return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    public static String saveStampDutyRecord(String stampDutyRecJson) {
    	stampDutyRecJson = BPUtility.getDecodedString(stampDutyRecJson);
    	try {
    		StampDutyService.saveStampDutyRecord(stampDutyRecJson);
	        return BPUtility.getEncodedString(System.JSON.serialize(StampDutyService.getAllStampDutyList()));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getStampDutyCalcMethodPickListValues(){
        return BPUtility.getEncodedString(Utility.getPicklistValues('Stamp_duty_calculators__c.Calculation_method__c'));
    }

    @RemoteAction
    global static void applyDefaultStampDutyOnUnits(){
        Database.executeBatch(new PopulateDefaultStampDutyOnUnitsBatch(), 2000);
    }
}