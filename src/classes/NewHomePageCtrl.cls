/**
 * Author: Hitesh Gupta
 * Since: Jul 25, 2016
 * Name: NewHomePageCtrl
 * Description: Apex class to handle JSON related oprations of NewHomePage
 **/
global without sharing class NewHomePageCtrl {
      
    public Boolean IsTrialOrg { get{return GeneralConfiguration.isTrialOrg();} private set;}
    public Integer trailOrgDays {get {return GeneralConfiguration.getTrialOrgDays();}}
    
    public Boolean ShowHelpIcon { get {return BP_Configurations__c.getOrgDefaults().Show_Help_Icon__c;} set;}
    public String communityURL { get{return GeneralConfiguration.communityLink();} private set;}
    public String communityquestionURL { get{return GeneralConfiguration.communityLink();} private set;}
    public String communitycaseURL { get{return GeneralConfiguration.communityLink();} private set;}
    public String dateFormat { get{ return BPUtility.getDateFormat();}private set;}
    public string ExtendedDateFormat  { get{return Constants.localeToDateTimeExtendedMonthFmt.containsKey(UserInfo.getLocale())? Constants.localeToDateTimeExtendedMonthFmt.get(UserInfo.getLocale()): Constants.localeToDateTimeExtendedMonthFmt.get('en_AU'); } private set;}
    public Boolean IsSystemSettingVisited{get{return GeneralConfiguration.isSystemSettingVisited();} private set;}
    public String userGroupName{get{return GeneralConfiguration.getCurrentUserGroupName();} private set;} 
    public String userGroupId{get{return GeneralConfiguration.getCurrentUserGroupId();} private set;} 
    public String userGroupColor{get{return GeneralConfiguration.getCurrentUserGroupColor();} private set;}
    public String companyLocale{get{return GeneralConfiguration.getCompanyLocale();} private set;}  
    public static String Permission{get;}
    public Boolean IsLoadNewCustomerOrder {get{return GeneralConfiguration.isLoadNewCustomerOrder();} set;}
    public Boolean IsLoadTechScheduling {get{return GeneralConfiguration.isLoadTechnicianScheduling();} set;}
    public Boolean IsLoadNewHeader {get{return GeneralConfiguration.IsLoadNewHeader();} set;}
    public Boolean IsFusionMappingEnabled {get{return GeneralConfiguration.isFusionMappingEnabled();} set;}
 	public Boolean isTaxIncludingPricing {get{return GeneralConfiguration.getTaxIncludingPricing();} set;}
 	public Boolean IsEnhancedTaxCalculation {get{return GeneralConfiguration.IsEnhancedTaxCalculation();} set;}
    public Boolean IsQBEnabled {get{return QBUtil.isQBEnabled();} set;}
    public Boolean isBrandingLocationEnabled {get{return GeneralConfiguration.isBrandingLocationEnabled();} set;}
	public Boolean IsSalesTaxTaxUntilUnitSold {get{return GeneralConfiguration.getAccrueTradeTaxUntilUnitSold();} set;}
	public Boolean isEnableTaxAccrualOnOrderUnits {get{return GeneralConfiguration.isEnableTaxAccrualOnOrderUnits();} set;}
    public Boolean isTechnicianHoursCostingEnabled {get{return GeneralConfiguration.isTechnicianHoursCostingEnabled();} set;}
    public Boolean IsARIPartSmartEnabled {get{return GeneralConfiguration.isARIPartSmartEnabled();} set;}
    public Boolean IsDP360SyncEnabled {get{return (String.isNotBlank(GeneralConfiguration.getDP360DealerId()) ? true : false);} set;}
    public Boolean IsHondaAPIEnabled {get{return HondaUtility.isHondaIntegrationEnabled();} set;}
    public static string UserLanguage{get{ return UserInfo.getLanguage();} private set; }    
    public String currentUserTZSIDKey {get{return BPUtility.getCurrentUserTZSIDKey();} set;}
    public Decimal HomeSearchGridPageSize { get{return GeneralConfiguration.getHomeSearchGridPageSize();} private set;}
    public String HondaVONumber {get {return Honda_Configuration__c.getOrgDefaults().VO_Number__c;} set;}
    public Boolean IsYamahaVOExportEnabled {get {return String.isNotBlank(Yamaha_Australia_Config__c.getOrgDefaults().Dealer_Code__c);} set;}
    public String BarCodeLabeSize { get{return GeneralConfiguration.getBarCodeLabelSize();} private set;}
    public String DefaultOdometerType { get{return GeneralConfiguration.getDefaultOdometerType();} private set;}
    public Boolean IsSMSPhoneNumberConfigured { get {return GeneralConfiguration.isSMSPhoneNumberConfigured();} set;}
    public Boolean IsRecordTrackingNumber { get {return GeneralConfiguration.isRecordTrackingNumber();} set;}
    public Integer cacheExpiresIn {get {return 86400;} set;}
    public Boolean IsTwoWayTextEnabled { get {return General_Configurations__c.getOrgDefaults().Enable_Two_Way_Text__c;} set;}
    public Boolean EnforeTechnicianPIN { get {return GeneralConfiguration.enforceTechnicianPIN();} set;}
    public Boolean EnforePayrollPIN { get {return GeneralConfiguration.enforcePayrollPIN();} set;}
    public Boolean IsCassonsAPIEnabled { get {return GeneralConfiguration.isCassonsEnabled();} set;}
    public Boolean IsShopifyEnabled { get {return GeneralConfiguration.isShopifyIntegrationEnabled();} set;}
    public Boolean IsShopifyActivated { get {return ShopifyUtil.isIntegrationActive;} set;}
    public Boolean IsARIPartSmart10Enabled {get{return GeneralConfiguration.isARIPartSmart10Enabled();} set;}
    public String VendorAvailabilityIds { get {return GeneralConfiguration.getActiveVendorAvailabilityIds();} set;}
    public String UnitIconTitle { get {return GeneralConfiguration.getConfigurationByName(GeneralConfiguration.UNIT_ICON_TITLE);} set;}
    public Boolean IsUsingDymoConnect {get{return GeneralConfiguration.isUsingDymoConnect();} set;}
    public String CompanyLogoURL { get {return GeneralConfiguration.getCompanyLogoUrl();} set;}
    public String CompanyLogoHeightAndWidthMap { get {return GeneralConfiguration.getCompanyLogoHeightAndWidth();} set;}
    public Boolean IsPreferredPaymentEnabled {get{return GeneralConfiguration.isPreferredPaymentIntegrationEnabled();} set;}

    public  Boolean IsSampleDataAvailable { get{
                                                if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                                                List<Category__c> categoryList = [select id from Category__c limit : Limits.getLimitDMLRows()];
                                                if(categoryList.size() == 0){
                                                    return false;
                                                }else{
                                                    return true;
                                                }
                                            } 
                                            
                                            private set;
                                        }
                                        
    public static String Application{get;}
    public static String Assests{get;} 
    public static String Application_Images{get;}
    public static String Locale{get;} 
    public static String lastUpdatedTimeStamp{get;}
    
    public NewHomePageCtrl(){
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
        Locale = GlobalController.GetResourceURL('Locale');
        lastUpdatedTimeStamp = GlobalController.lastUpdatedTimeStamp;
        Permission = getUserPermissions(UserInfo.getUserId());
    }
    
    @remoteAction
    global static boolean IsSystemvisted(){
        if(AccessControl.ifObjectFieldIsUpdateable('User') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        String userId = UserInfo.getUserId();
        //List<LoginHistory> loginRec = [Select Id,UserId from LoginHistory where UserId =: userId ]; //Commented by Anurag 28 Jun 2017
        List<user> userList = [Select Id,Is_Email_Notified__c from user where Id =: userId ];
            
        // Start: Commented and Added by Anurag 28 Jun 2017 
        //if(( loginRec.size() == 1 && userList[0].Is_Email_Notified__c == false) || Test.isRunningTest()){
        if((userList[0].Is_Email_Notified__c == false) || Test.isRunningTest()){
        // End: Commented and Added by Anurag 28 Jun 2017
        
            List<Id> ids  = new List<Id>();
            ids.add(UserInfo.getUserId());
            //EmailSchedule.executeDataScheduler(ids);
            //EmailSchedule.executeDataScheduler();
            EmailSchedule emlScheduler = new EmailSchedule();
            DateTime d = System.now().addMinutes(2);
            String sch = String.valueOf(d.second())+' '+String.valueOf(d.minute())+' '+ String.valueOf(d.hour())+' '+ String.valueOf(d.day())+' '+ String.valueOf(d.month())+' ? '+ String.valueOf(d.year());
            system.debug('sch ' + sch);
            String jobID = system.schedule('Email Notification' + userId , sch, emlScheduler); 
            if(jobID != null){
                user userRec = new user();
                userRec.Id = UserInfo.getUserId(); 
                userRec.Is_Email_Notified__c = true;
                update userRec;
             }
           return true;
        }
        return false;
    }
    
    @remoteAction
    global static String getSummaryCardsDetails(String summaryCardsDefultJson){
        NewHomePageCtrl hmpg = new NewHomePageCtrl();
        summaryCardsDefultJson = BPUtility.getDecodedString(summaryCardsDefultJson);
        //System.assert(false, summaryCardsDefultJson);
        List<SummaryCard> summaryCardsList = (List<SummaryCard>)System.JSON.deserialize(summaryCardsDefultJson, List<SummaryCard>.class);
        List<SummaryCard> summaryCardsResultList = new List<SummaryCard>();
        try {
            List<Summary_Card__mdt> summaryCardWithAllFiltersList; 
            if(summaryCardsList != null && summaryCardsList.size() == 1) {
                summaryCardWithAllFiltersList = getSummaryCardCustomMetadataTypeSettings(summaryCardsList[0].Name);
            } else if(summaryCardsList != null && summaryCardsList.size() > 1) {
                summaryCardWithAllFiltersList = getSummaryCardCustomMetadataTypeSettings(null);
            }
            
            Map<String, Summary_Card__mdt> cardNameToCardRecordMap = new Map<String, Summary_Card__mdt>();
            for(Summary_Card__mdt cardMDTObj: summaryCardWithAllFiltersList) {
                if(!cardNameToCardRecordMap.containsKey(cardMDTObj.Label)) {
                    cardNameToCardRecordMap.put(cardMDTObj.Label, cardMDTObj);
                }
            }
            
            for(SummaryCard card: summaryCardsList) {
                String filterValue = '';
                if(card.BlockList != null && card.BlockList.size() > 0) {
                    filterValue = card.BlockList[0].FilterName;
                }
                
                Summary_Card__mdt cardToFetchObj = cardNameToCardRecordMap.get(card.Name);
                SummaryCard cardObj = new SummaryCard(cardToFetchObj, Application_Images, filterValue);
                summaryCardsResultList.add(cardObj);
            }
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        
        //system.assert(false, summaryCardsResultList);
        return BPUtility.getEncodedString(System.JSON.serialize(summaryCardsResultList));
    }    
    
    @RemoteAction
    global static void syncLeadWithDP360() {
        DP360IntegrationCtrl.createLeadInBlackpurl();
        DP360IntegrationCtrl.upsertLeadInDP360(null);   //Create new Lead
        updateLastSynchedDate();
    }
    
    private static void updateLastSynchedDate() {
        DP360_Configuration__c configObj = DP360_Configuration__c.getOrgDefaults();
        configObj.Last_Synched_Date__c = system.now();
        DMLUtility.updateSobjectList('DP360_Configuration__c', configObj);
    }
    
    @RemoteAction
    public static String getActivityHistoryList(String historyTypeJSON) {
        historyTypeJSON = BPUtility.getDecodedString(historyTypeJSON);
        return BPUtility.getEncodedString(ActivityHistory.getActivityHistoryList(historyTypeJSON));
    }

    //Added by Nikhil 04/09/2017 for Redirecting and validating the Session by calling a dummy RemoteAction 
    @RemoteAction
    public static String validateLoginSession() {
        
        return '' ;
	}
	
	@RemoteAction
    global static String getActiveIntegrationList() {
        if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Integration_Name__c FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true];
        
        Set<String> activeIntegrationSet = new Set<String>();
        for(IFW_IntegrationConfig__c configRec : configList) {
            activeIntegrationSet.add(configRec.Integration_Name__c);
        }
        return BPUtility.getEncodedString(system.JSON.serialize(activeIntegrationSet));
    }
    
    @RemoteAction
    global static String getBRPVendorsList() {
        return BPUtility.getEncodedString(system.JSON.serialize(BRPUtility.getAllBRPVendorsIdSet()));
    }
    
    @RemoteAction
    global static String getBusinessCustomizationData() {
        if(!AccessControl.ifObjectFieldIsAccessible('Business_Customization__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Business_Customization__c> businessCustomizationList = [SELECT Business_Name__c, Customize_MMS_Labels__c FROM Business_Customization__c LIMIT 1];
        Map<String, BusinessCustomization> businessNameToFeatureCustomizationMap = new Map<String, BusinessCustomization>();
        for(Business_Customization__c customizationRec: businessCustomizationList) {
            businessNameToFeatureCustomizationMap.put(customizationRec.Business_Name__c, new BusinessCustomization(customizationRec));
        }
        return BPUtility.getEncodedString(system.JSON.serialize(businessNameToFeatureCustomizationMap));
    }
    
    @RemoteAction
    global static Boolean isUpdateAvailableForPriceFiles() {
        return AutomatedPriceFileService.isUpdateAvailableForPriceFiles(); 
    }
    
    /**
     * Name: getSummaryCardCustomMetadataTypeSettings
     * Description: Method to get the summary card custom metadata type setting based on object name
     * @Param:  1) String cardName - card name for home page
     * @Return: List<Summary_Card__mdt> - Custom Metadata type records
    **/
    private static List<Summary_Card__mdt> getSummaryCardCustomMetadataTypeSettings(String cardName) {
        String query = '';
        query = 'SELECT ';
        for(String fieldName : SummaryCard.summaryCardFieldsList()) {
            query += fieldName + ', ';
        }
        
        // Child Query
        query += '(SELECT '; 
        for(String fieldName : SummaryCard.summaryBlockFieldsList()){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Summary_Blocks__r';
        query += ' WHERE Active__c = true)';
        
        //query = query.substring(0, query.length()-2);
        
        query += ' FROM Summary_Card__mdt';
        query += ' WHERE Active__c = true';
        
        String objectName = '';
        if(cardName != null) {
            objectName = BPUtility.escapeSingleQuotes(cardName);
            query += ' AND Label =: objectName';
        }
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        
        if(AccessControl.ifObjectFieldIsAccessible('Summary_Card__mdt') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Summary_Block__mdt') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        //system.assert(false, query);
        return Database.query(query);
    }
    
    public static String getUserPermissions(String userId) {
        String permissionStr = '{}';
        List<User_To_Group__c> userToGroupList = SOQLUtil.getUserToGroupList(new Map<String, String>{'User__c' => userId});
        if(userToGroupList.size() > 0 && userToGroupList[0].User_Group__c != null) {
            String groupId = userToGroupList[0].User_Group__c;
            List<User_Group__c> userGroupList = SOQLUtil.getUserGroupList(new Map<String, String>{'Id' => groupId});
            if(userGroupList.size() > 0) {
                permissionStr = System.JSON.serialize(new UserGroupWrapper(userGroupList[0], true));
            }
        }
        return permissionStr;
    }
}