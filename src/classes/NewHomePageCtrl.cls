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
    public Boolean IsAdminGroup {get{return GeneralConfiguration.isAdminGroup();} private set;}
    public String userGroupId{get{return GeneralConfiguration.getCurrentUserGroupId();} private set;} 
    public String userGroupColor{get{return GeneralConfiguration.getCurrentUserGroupColor();} private set;}
    public String companyLocale{get{return GeneralConfiguration.getCompanyLocale();} private set;}  
    public static String Permission{get;set;}
    public Boolean IsLoadNewCustomerOrder {get{return GeneralConfiguration.isLoadNewCustomerOrder();} set;}
    public Boolean IsLoadTechScheduling {get{return GeneralConfiguration.isLoadTechnicianScheduling();} set;}
    public Boolean IsFusionMappingEnabled {get{return GeneralConfiguration.isFusionMappingEnabled();} set;}
 	public Boolean isTaxIncludingPricing {get{return GeneralConfiguration.getTaxIncludingPricing();} set;}
 	public Boolean IsEnhancedTaxCalculation {get{return GeneralConfiguration.IsEnhancedTaxCalculation();} set;}
    public Boolean isReportSchedulingEnabled {get{return GeneralConfiguration.isReportSchedulingEnabled();} set;}
    public Boolean IsWebComponentSTAEnabled {get{return GeneralConfiguration.isWebComponentSTAEnabled();} set;}
    public Boolean IsExcludeHeaderOnARIPartsmart10 {get{return GeneralConfiguration.getBooleanValueOfConfigurationByName(GeneralConfiguration.EXCLUDE_HEADER_ON_ARI_PARTSMART10);} set;}
    public Decimal Home_Search_Grid_Page_Size { get{return GeneralConfiguration.getHomeSearchGridPageSize();} private set;}
    public Decimal Related_List_Page_Size { get{return GeneralConfiguration.getRelatedListPageSize();} private set;}
    
    public Boolean IsQBEnabled {get{return QBUtil.isQBEnabled();} set;}
    public static Boolean IsForeignExchangeCostingEnabled {get{return GeneralConfiguration.getGeneralConfigurations().Enable_Foreign_Exchange_Costing__c;} set;}
    public String HomeCurrencyCode {get{return QuickBooks_Configurations__c.getOrgDefaults().Home_Currency__c;} set;}
    
    public Boolean isBrandingLocationEnabled {get{return GeneralConfiguration.isBrandingLocationEnabled();} set;}
	public Boolean IsSalesTaxTaxUntilUnitSold {get{return GeneralConfiguration.getAccrueTradeTaxUntilUnitSold();} set;}
	public Boolean isEnableTaxAccrualOnOrderUnits {get{return GeneralConfiguration.isEnableTaxAccrualOnOrderUnits();} set;}
    public Boolean isTechnicianHoursCostingEnabled {get{return GeneralConfiguration.isTechnicianHoursCostingEnabled();} set;}
    public Boolean IsUseNewPaymentAccounting {get{return GeneralConfiguration.isUseNewPaymentAccounting();} set;}
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
    public Boolean IsPreferredPaymentEnabled {get{return GeneralConfiguration.isPreferredPaymentIntegrationEnabled();} set;}
    public String CompanyLogoURL { get {return GeneralConfiguration.getCompanyLogoUrl();} set;}
    public String CompanyLogoHeightAndWidthMap { get {return GeneralConfiguration.getCompanyLogoHeightAndWidth();} set;}
    public Boolean IsMESHEnabledOrg {get{return GeneralConfiguration.getGeneralConfigurations().MESH_Enabled_Org__c;} set;}
    public Boolean IsChargeOnAccountRestricted {get{return GeneralConfiguration.getConfigurations().Is_Charge_On_Account_Restricted__c;} set;}
    public Boolean IsDuplicateTabDetectorEnabled {get{return GeneralConfiguration.isDuplicateTabDetectorEnabled();} set;}
    public Boolean AllowPauseOfJobClocking {get{return GeneralConfiguration.getConfigurations().Allow_Pause_Of_Job_Clocking__c;} set;}
    public Boolean IsAutomaticPaymentSurchargeEnabled {get{return GeneralConfiguration.getConfigurations().Enable_Automatic_Payment_Surcharges__c;} set;}
    public Boolean AllowQuickFulfillingDealUnitOptions {get{return GeneralConfiguration.getConfigurations().Allow_fulfilling_of_deal_unit_options__c;} set;}
    public String NewPaymentAccountingEnableDate {get{return (GeneralConfiguration.getGeneralConfigurations().New_Payment_Accounting_Enable_Time__c != null) ? BPUtility.getFormatedDateTime(GeneralConfiguration.getGeneralConfigurations().New_Payment_Accounting_Enable_Time__c) : '';} set;}
    public String ConfigurationsObj {get;set;}

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
                                        
    public static String Application{get;set;}
    public static String Assests{get;set;} 
    public static String Application_Images{get;set;}
    public static String React{get;set;}
    public static String Locale{get;set;} 
    public static String lastUpdatedTimeStamp{get;set;}
    public String orgAuthInfo{get; private set;}
    public String defaultCollective{get; private set;}
    public String allCollectives{get; set;}
    public String brpApiVersion {get{ return BRPUtility.getAPIVersion();}private set;}
    
    public NewHomePageCtrl(){
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
        Locale = GlobalController.GetResourceURL('Locale');
        React = GlobalController.GetResourceURL('React');
        lastUpdatedTimeStamp = GlobalController.lastUpdatedTimeStamp;
        Permission = getUserPermissions(UserInfo.getUserId());
        orgAuthInfo = getOrgAuthDetails();
        populateCollectiveDetails();
        ConfigurationsObj = System.JSON.serialize(getConfigurationsObj());
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
                SummaryCard cardObj = new SummaryCard(cardToFetchObj, filterValue);
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

    @RemoteAction
    global static String getIntegrationVersion() {
        return BPUtility.getEncodedString(AccountingUtil.getIntegrationVersion()); 
    }

    @RemoteAction
    global static String getGeneralConfigurations() {
        General_Configurations__c genConfigRec = General_Configurations__c.getOrgDefaults();
        return BPUtility.getEncodedString('{"UseCOAsyncAction": ' + genConfigRec.Use_CO_Async_Action__c + '}'); 
    }

    global static String getConfigurations() {return null;}
    global static String getOrgAuthInfo() {return '';}
    global static String getCollectiveInfo() {return '';}
	
    public static String getOrgAuthDetails() {
        String id = 'https://login.salesforce.com/id/'+ UserInfo.getOrganizationId() + '/' + UserInfo.getUserId();
        String instanceUrl = URL.getOrgDomainUrl().toExternalForm();
        String accessToken = UserInfo.getSessionId();
        LMAAuthenticationService.OAuth2 orgAuthInfoSeWrapperObj = new LMAAuthenticationService.OAuth2(id, instanceUrl, accessToken);
        String baseURL = getUniversalAPIBaseURL();
        
        Map<String, Object> resObj = new Map<String, Object>{'credentials'=> orgAuthInfoSeWrapperObj, 'graphql_url' => baseURL};
        return BPUtility.getEncodedString(system.JSON.serialize(resObj, true)); 
    }
    
    public static String getUniversalAPIBaseURL() {
        String baseURL = 'https://api.blackpurl.com/graphql';
        List<IFW_IntegrationConfigItem__c> configItemList = [SELECT Endpoint_URL__c FROM IFW_IntegrationConfigItem__c WHERE IFW_IntegrationConfig__r.Integration_Name__c = 'Universal API' AND 
                                                                Entity_Name__c  = 'Connection' limit 1];
        if(configItemList.size() > 0) {
            baseURL = configItemList[0].Endpoint_URL__c;
        }
        return baseURL;
    }

    public void populateCollectiveDetails() {
        if(GeneralConfiguration.getGeneralConfigurations().MESH_Enabled_Org__c) {
            List<CollectiveWrapper> collectiveObjList = new List<CollectiveWrapper>();
            for(Collective__c collective : [SELECT External_Id__c, Name__c, Default__c FROM Collective__c WHERE External_Id__c != null]) {
                if(collective.Default__c) {
                    defaultCollective = system.JSON.serialize(new CollectiveWrapper(collective));
                }
                collectiveObjList.add(new CollectiveWrapper(collective));
            }
            allCollectives = system.JSON.serialize(collectiveObjList);
        }
        if(String.isBlank(defaultCollective)) defaultCollective = '{}';
        if(String.isBlank(allCollectives)) allCollectives = system.JSON.serialize(new List<CollectiveWrapper>());
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

    private static Map<String, Object> getConfigurationsObj() {
        Configurations__c configRec = Configurations__c.getOrgDefaults();
        return new Map<String, Object>{'AcceptablePartCostVariance' => configRec.Acceptable_Part_Cost_Variance__c,
                'IsReadyToInvoiceRequiredToFinalize' => configRec.Is_Ready_To_Invoice_Required_To_Finalize__c,
                'AllowCustomerServiceJobWithoutUnit' => configRec.Allow_Customer_Service_Job_Without_Unit__c,
                'IsAutomaticTaxRates' => configRec.Automatic_tax_rates__c,
                'IsDFCommissionIncludedInFIPayments' => configRec.DF_commission_in_FI_company_payments__c};
    }
}