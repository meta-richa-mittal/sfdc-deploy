/**
 * Author: Prakhar Agrawal
 * Since: Jun 14 2016
 * Name: GeneralConfiguration
 * Description: Apex class to return all the custom fields of General Configurations
**/
public without sharing class GeneralConfiguration {
     
	public static String UNIT_ICON_TITLE = 'Unit Icon Title';
 	public static String APF_RECORD_PROCESSING_COUNT = 'APF Record Processing Count';
	public static String ACCOUNTING_RECONCILIATION_EMAIL = 'Accounting Reconciliation Email';
    public static String DELETE_SUPERSESSION_IF_BLANK = 'Delete Supersession If Blank';
    public static String ENABLE_DUPLICATE_TAB_DETECTOR = 'Enable Duplicate Tab Detector';
    public static String EXCLUDE_HEADER_ON_ARI_PARTSMART10 = 'Exclude Header On ARI Partsmart10';
    public static String ENABLE_WEB_COMPONENT_STA = 'Enable Web Component STA';
    public static String ENABLE_REPORT_SCHEDULING = 'Enable Report Scheduling';
    public static String ENABLE_NEW_GLOBAL_SEARCH = 'Enable New Global Search';
    public static String ENABLE_SOSL_SEARCH = 'Perform SOSL';
	public static String SOSL_SEARCH_ONLY = 'SOSL Search Only';
	public static String SYNC_PUBLISH_IN_FEED_UNITS_TO_DP360 = 'Sync Publish In Feed Units To DP360';
    public static String INCLUDE_PRIMARY_IMAGE_IN_FTP_FEED = 'Include Primary Image In FTP Feed';

	public static Configurations__c configurations;
	public static General_Configurations__c genConfig;
    public static String namespace;
    public static BP_Configurations__c bpConfigurations;
    public static List<Unit_Data_Field_Config__c> unitConfigList;

	private static void setConfigurations() {
	    if(AccessControl.ifObjectFieldIsAccessible('Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	    configurations = Configurations__c.getOrgDefaults();
	}

    public static Configurations__c getConfigurations() {
	    if(configurations == null) setConfigurations();
        return configurations;
	}

    private static void setBPConfigurations() {
	    if(AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	    bpConfigurations = BP_Configurations__c.getOrgDefaults();
	}

    public static BP_Configurations__c getBPConfigurations() {
	    if(bpConfigurations == null) setBPConfigurations();
        return bpConfigurations;
	}

    public static General_Configurations__c getGeneralConfigurations() {
	    if(genConfig == null) setGeneralConfigurations();
        return genConfig;
	}
	
	private static void setGeneralConfigurations() {
	    if(!AccessControl.ifObjectFieldIsAccessible('General_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	    genConfig = General_Configurations__c.getOrgDefaults();
	}
	
	public static Boolean alwaysObeyPublishInFeeds() {
	    if(configurations == null) setConfigurations();
	    return configurations.Always_obey_publish_in_feeds__c;
	}
     
    /**
     * Name: getHomeSearchGridPageSize 
     * Desc: To get Home Search Grid Page Size
     * @param: 
     * @return: Decimal
    **/    
    public static Decimal getHomeSearchGridPageSize() {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Home_Search_Grid_Page_Size__c  ;
    }
    
    /**
     * Name: getRelatedListPageSize
     * Desc: To get Related List Page Size
     * @param: 
     * @return: Decimal
    **/
    public static Decimal getRelatedListPageSize() {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Related_List_Page_Size__c  ;
    }
	
    public static Boolean isHideHoursRateOnServiceDocument() {
        if(AccessControl.ifObjectFieldIsAccessible('Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getInstance().Hide_Hours_Rate_On_Service_Documents__c  ;
    }
    
    public static Boolean isHidePartNumbersOnDocuments() {
        if(AccessControl.ifObjectFieldIsAccessible('Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getOrgDefaults().Hide_Part_Numbers_On_Documents__c;
    }
    
    public static Boolean isDuplicateTabDetectorEnabled() {
        String isDuplicateTabDetectorEnabled = getConfigurationByName(ENABLE_DUPLICATE_TAB_DETECTOR);
        return String.isNotBlank(isDuplicateTabDetectorEnabled) ? Boolean.valueOf(isDuplicateTabDetectorEnabled) : false;
    }

    public static Boolean isHideKitDetailsOnDocuments() {
        if(AccessControl.ifObjectFieldIsAccessible('Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getOrgDefaults().Hide_Kit_Details_On_Documents__c;
    }

    public static Boolean isIncludeMSRPAndDiscountOnPartLines() {
        if(AccessControl.ifObjectFieldIsAccessible('Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getOrgDefaults().Include_MSRP_and_Discount_on_Part_Lines__c;
    }
	
    public static Boolean isTechnicianHoursCostingEnabled() {
        if(AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Technician_Hours_Costing__c;
    }
	
    public static Boolean isUseNewPaymentAccounting() {
        return General_Configurations__c.getOrgDefaults().Use_new_payment_accounting__c;
    }

    public static Boolean isARIPartSmartEnabled() {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().ARI_Partsmart__c;
    }
    
    public static Boolean isARIPartSmart10Enabled() {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().ARI_Partsmart10__c;
    }
    
     /**
     * Name: isWidgetRemoveable
     * Desc: To check Widget Removeable 
     * @param: 
     * @return: Decimal
    **/
    
    public static boolean isWidgetRemoveable()    {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Is_Widget_Removeable__c  ;
    }
    
     /**
     * Name: isLoadNewCustomerOrder
     * Desc: To check Load New Customer Order 
     * @param: 
     * @return: boolean
    **/
    
    public static boolean isLoadNewCustomerOrder()    {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Load_New_Customer_Order__c;
    }
    
     /**
     * Name: isLoadTechnicianScheduling
     * Desc: To check whether to Load Technician Scheduling or not 
     * @param: 
     * @return: boolean
    **/
    
    public static boolean isLoadTechnicianScheduling()    {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Technician_Scheduling__c  ;
    }
    
     /**
     * Name: IsFusionMappingEnabled
     * Desc: To check whether to Load Fusion Mapping or not 
     * @param: 
     * @return: boolean
    **/
    
    public static boolean IsFusionMappingEnabled()    {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().H_D_Dealer__c  ;
    }
    
    
       /**
     * Name: isLoadNewViewCustomer
     * Desc: To check Load New View Customer
     * @param: 
     * @return: boolean
    **/  
       
    public static boolean isLoadNewViewCustomer()    {
        return General_Configurations__c.getInstance().Load_New_View_Customer__c  ;
    }
    
    /**
     * Name: getNamespace
     * Desc: To get Namespace
     * @param: 
     * @return: String
    **/ 
    public static String getNamespace() {
        if(ConfigurationScript.isPostInstallRunning) {return PostInstallClass.NAMESPACE;}
        
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('ApexClass') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        if(String.isBlank(nameSpace)) {
        	nameSpace = General_Configurations__c.getInstance().Namespace__c;
	        if(String.isBlank(nameSpace)) {
	            nameSpace = [Select NamespacePrefix, Name, Id From ApexClass where Name = 'Constants'].NamespacePrefix;
	            if(!String.isBlank(nameSpace)){
	                nameSpace += '__';
	            }
	        }
        }
        return (nameSpace == null) ? '' : nameSpace;
    }
    
    public static String getPackageNamespace() {
    	return [Select NamespacePrefix From ApexClass where Name = 'Constants'].NamespacePrefix;
    }
    

    /**
     * Name: getHomeSearchGridPageSize
     * Desc: To get Home Search Grid Page Size
     * @param: 
     * @return: Decimal
    **/
    public static Decimal getAustralianMarketSalesTaxRate() {
        return Australian_Market__c.getInstance().Sales_Tax_Rate__c ;
    }
    
    /**
     * Name: getTaxIncludingPricing
     * Desc: To get if tax Including pricing is true or not
     * @param: 
     * @return: Decimal
    **/
    public static Boolean getTaxIncludingPricing() {
        return Configurations__c.getOrgDefaults().Tax_Included_Pricing__c;
	}
	
	public static Boolean IsEnhancedTaxCalculation() {
        return Configurations__c.getOrgDefaults().Enhanced_Tax_Calculations__c;
	}
    
	public static Decimal getDefaultTechnicianCostingRate() {
		Decimal defaultTechCostingRate = Configurations__c.getOrgDefaults().Default_Technician_Cost_Rate__c;
        return defaultTechCostingRate != null ? defaultTechCostingRate : 0;
	}

    public static String getDefaultTaxOnClaimDeductibles() {
        return Configurations__c.getOrgDefaults().Default_Tax_on_Claim_Deductibles__c;
	}
	
    public static Boolean getCalcTax_Invoice() {
        return Configurations__c.getOrgDefaults().CalcTax_Invoice__c;
    }
    
    public static String getOrderingTaxRate() {
        return Configurations__c.getOrgDefaults().Ordering_Tax_Rate__c;
    }
          
    public static Boolean getCalcTax_LineItem() {
        return Configurations__c.getOrgDefaults().CalcTax_LineItem__c;
    }
     
    public static Decimal getStampDutyRate() {
        return (Configurations__c.getOrgDefaults().Stamp_Duty_Rate__c != null) ? Configurations__c.getOrgDefaults().Stamp_Duty_Rate__c : 0;
    }
    
    public static Boolean getAccrueTradeTaxUntilUnitSold() {
        return Configurations__c.getOrgDefaults().Accrue_Trade_Tax_Until_Unit_Sold__c;
    }
       
	public static Boolean isEnableTaxAccrualOnOrderUnits() {
        return Configurations__c.getOrgDefaults().Enable_Tax_Acc_on_Order_Units_By_Default__c;
	}
	
    /**
     * Name: getIsTrialOrg
     * Desc: To get if trail Org is true or not
     * @param: 
     * @return: Boolean
    **/
    public static Boolean isTrialOrg() {
        String namespace = [Select NamespacePrefix, Name, Id From ApexClass where Name = 'Constants'].NamespacePrefix;

        List<PackageLicense> packLicRec = [SELECT Id,Status,Expirationdate, NamespacePrefix FROM PackageLicense WHERE
                             NamespacePrefix = :namespace];
        if(packLicRec.size()>0){
            if(packLicRec[0].Status.equalsIgnoreCase('trial')){
                return true;
            }           
        }
        return false;
        //return General_Configurations__c.getOrgDefaults().Is_Trial_Org__c; commented by Anurag
    }
    
    
    /**
     * Name: getTrialOrgDays
     * Desc: To get the number of days for trial Org
     * @param: 
     * @return: Integer
    **/
     public static Integer getTrialOrgDays() {
        if(AccessControl.ifObjectFieldIsAccessible('User') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        String namespace = [Select NamespacePrefix, Name, Id From ApexClass where Name = 'Constants'].NamespacePrefix;
        List<PackageLicense> packLicRec = [SELECT Id,Status,Expirationdate, NamespacePrefix FROM PackageLicense WHERE
                                            NamespacePrefix = :namespace];
        Integer noOfDays = 0;
        if(packLicRec.size() == 0){
            //noOfDays = 14;
        }
        if(packLicRec.size() > 0 && packLicRec[0].Status.equalsIgnoreCase('trial') && packLicRec[0].Expirationdate != null){
            Date startDate = Date.valueOf(packLicRec[0].Expirationdate);  
            noOfDays = (Date.today().daysBetween(startDate));
        }
        return noOfDays;
        //return General_Configurations__c.getOrgDefaults().Is_Trial_Org__c; commented by Anurag
    }
    
     /**  
     * Name: getIsSystemSettingVisites
     * Desc: To get if System Setting is visited or not
     * @param: 
     * @return: Boolean
    **/
    public static Boolean isSystemSettingVisited() {
        return General_Configurations__c.getOrgDefaults().Is_System_Setting_Visited__c;
    } 
    
    /**  
     * Name: communityLink
     * Desc: To get communityLink
     * @param: 
     * @return: String
    **/
    public static String communityLink() {
        return BP_Configurations__c.getOrgDefaults().Community_Link__c;
    } 
    
    /**  
     * Name: getSupportEmail
     * Desc: To get SupportEmail
     * @param: 
     * @return: String
    **/
    public static String getSupportEmail() {
        return BP_Configurations__c.getOrgDefaults().Support_Email__c;
    } 
    
    /**  
     * Name: getSupportEmailRecipient
     * Desc: To get SupportEmail for Recipient
     * @param: 
     * @return: String
    **/    
    public static String getSupportEmailRecipient() {
        return BP_Configurations__c.getOrgDefaults().Support_Email_Recipient__c;
    }
    
    /**  
     * Name: getSupportEmail
     * Desc: To get SupportEmail
     * @param: 
     * @return: String
    **/
    public static String getCompanyLogoUrl() {
        return BP_Configurations__c.getOrgDefaults().Company_Logo_URL__c;
    }   
    
    
    /**  
     * Name: getCompanyLogoUrl
     * Desc: To get SupportEmail
     * @param: 
     * @return: String
    **/
    public static boolean getIsDataLoadFlag() {
        return BP_Configurations__c.getOrgDefaults().Is_Data_Load__c;
    } 
    
    public static boolean getLoadFinanceSection() {
        return General_Configurations__c.getOrgDefaults().Load_Financing_Section__c;
    }
    
    /**  
     * Name: getMapAPIKey
     * Desc: To get google map api key
     * @param: 
     * @return: String
    **/
    public static String getMapAPIKey() {
        return BP_Configurations__c.getOrgDefaults().MapAPIKey__c;
    } 
    
    public static String getDefaultPriceLevelOnInternalService() {
        return Configurations__c.getOrgDefaults().Default_Price_Level_on_Internal_Service__c;
    }
    
    public static String getDefaultSalesTaxOnInternalService() {
        return Configurations__c.getOrgDefaults().Default_Sales_Tax_on_Internal_Service__c;
    }
    
    /**  
     * Name: getCashPaymenmtRoundingFactor
     * Desc: To get Cash Paymenmt Rounding Factor
     * @param: 
     * @return: String
    **/
    public static Decimal getCashPaymenmtRoundingFactor() {
        return Configurations__c.getOrgDefaults().Cash_Payment_Rounding_Factor__c;
    }
    
    /**  
     * Name: getCurrentUserGroupName
     * Desc: To get Group Name
     * @param: 
     * @return: String
    **/
    public static String getCurrentUserGroupName() {
        List<User_To_Group__c> userGroupList = [select User_Group__r.Name 
                                                from User_To_Group__c 
                                                where User__c = :UserInfo.getUserId()];
        String groupName = '';
        if(userGroupList.size() > 0 && userGroupList[0].User_Group__r.Name != null){
            groupName = userGroupList[0].User_Group__r.Name;
        }
        return groupName;
    }
    
    public static String getCurrentUserGroupId() {
        List<User_To_Group__c> userGroupList = [select User_Group__c, User_Group__r.Name 
                                                from User_To_Group__c 
                                                where User__c = :UserInfo.getUserId()];
        String groupId = '';
        if(userGroupList.size() > 0 && userGroupList[0].User_Group__r.Name != null){
            groupId = userGroupList[0].User_Group__c;
        }
        return groupId;
    }
    
    public static String getCurrentUserGroupColor() {
        List<User_To_Group__c> userGroupList = [select User_Group__c, User_Group__r.Colour_Code__c 
                                                from User_To_Group__c 
                                                where User__c = :UserInfo.getUserId()];
        String groupColor = '';
        if(userGroupList.size() > 0 && userGroupList[0].User_Group__r.Colour_Code__c != null){
            groupColor = userGroupList[0].User_Group__r.Colour_Code__c;
        }
        return groupColor;
    }
    
    public static Boolean isAdminGroup() {
        List<User_To_Group__c> userGroupList = [select User_Group__r.Is_System_Created__c 
                                                from User_To_Group__c 
                                                where User__c = :UserInfo.getUserId()];
        return (!userGroupList.isEmpty() && userGroupList[0].User_Group__r.Is_System_Created__c);
    }

    /**  
     * Name: getCompanyLocale
     * Desc: To get Country Name of company
     * @param: 
     * @return: String
    **/
    public static String getCompanyLocale() {
        String locale = '';
        if(AccessControl.ifObjectFieldIsAccessible('Business_Profile__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Business_Profile__c> businessProfiles = [select Business_Country__r.Name__c
                                                        from Business_Profile__c 
                                                        limit 1];
        if(businessProfiles.size() > 0 && businessProfiles[0].Business_Country__r.Name__c != null){
            locale = businessProfiles[0].Business_Country__r.Name__c;
        }
        return locale;
    }
    
    /**
     * Name: getShopSuppliesCalculationMethod
     * Desc: Load Custom Settings for Shop Supplies
     * @return: ShopSuppliesCustomSetting
    **/
    public static ShopSuppliesCustomSetting getShopSuppliesCalculationMethod()    {
        if(AccessControl.ifObjectFieldIsAccessible('Shop_Supplies__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Shop_Supplies__c shopSupplies = Shop_Supplies__c.getInstance();
        if(shopSupplies != null) {
            return new ShopSuppliesCustomSetting(shopSupplies);
        }
        return null;
    }
    
    /**
     * Name: isCalculationMethodAvailable
     * Desc: To check if Shop Supplies CalculationMethod is available
     * @return: boolean
    **/
    public static boolean isCalculationMethodAvailable() {
        ShopSuppliesCustomSetting shopSuppliesCustomSetting = GeneralConfiguration.getShopSuppliesCalculationMethod();     
        return !(shopSuppliesCustomSetting == null || shopSuppliesCustomSetting.CalculationMethod == Constants.NOT_CALCULATED);
    }
    
    /**
     * Name: isItemizedByLaborCode
     * Desc: To check if Itemized by labor code for Shop Supplies
     * @return: boolean
    **/
    public static boolean isItemizedByLaborCode() {
        return Shop_Supplies__c.getOrgDefaults().Itemized_by_labor_code__c;
    }
    
    /**
     * Name: isDisplayTaxInvoice
     * Desc: To check if Tax Invoice 
     * @return: boolean
    **/
    public static boolean isDisplayTaxInvoice() {
        return General_Configurations__c.getOrgDefaults().Display_Tax_Invoice__c;
    }
    
    public static Boolean isImagePublicURLCreationEnabled() {
        return BP_Configurations__c.getOrgDefaults().Is_Enable_Image_Public_URL__c ;
    }
    
   /**
     * Name: getDP360DealerId
     * Desc: To get DP360 dealer id
     * @param: 
     * @return: String
    **/  
       
    public static String getDP360DealerId() {
        return DP360_Configuration__c.getInstance().Dealer_Id__c  ;
    }
    
    public static String getTradeTaxExpenseCategory() {
        return Configurations__c.getOrgDefaults().Trade_Tax_Expense_Category__c  ;
    }
    public static String getTradeTaxLiabilityCategory() {
        return Configurations__c.getOrgDefaults().Trade_Tax_Liability_Category__c  ;
    }
    public static String getPurchaseTaxLiabilityCategory() {
        return Configurations__c.getOrgDefaults().Purchase_Tax_Liability_Category__c  ;
    }
    public static String getTradeTaxPendingSaleCategory() {
        return Configurations__c.getOrgDefaults().Trade_Tax_Pending_Sale_Category__c  ;
    }
    
    public static Boolean isAccruTradeTaxUntilUnitSold() {
        return Configurations__c.getOrgDefaults().Accrue_Trade_Tax_Until_Unit_Sold__c ;
    }
    
    public static Boolean isTradeTaxCreditCanNotExceedUnitTax() {
        return Configurations__c.getOrgDefaults().Trade_Tax_Credit_Can_Not_Exceed_Unit_Tax__c ;
    }
    
    public static String getDefaultOdometerType() {
        return Configurations__c.getOrgDefaults().Default_Odometer_Type__c;
    }
    
    /**
     * Name: getDP360LastSynchedDate
     * Desc: To get DP360 last synched date
     * @param: 
     * @return: DateTime
    **/  
       
    public static DateTime getDP360LastSynchedDate() {
        return DP360_Configuration__c.getInstance().Last_Synched_Date__c  ;
    }
    
    public static String getPartAgingPeriod1() {
        return Part_Aging_Period__c.getInstance().Period_1__c  ;
    }
    public static String getPartAgingPeriod2() {
        return Part_Aging_Period__c.getInstance().Period_2__c  ;
    }
    public static String getPartAgingPeriod3() {
        return Part_Aging_Period__c.getInstance().Period_3__c  ;
    }
    
    /**
     * Name: getSchedulerStartDay
     * Desc: get start day for scheduler
     * @return: Decimal
    **/
    public static Decimal getSchedulerStartDay() {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Scheduler_Start_Day__c  ;
    }
    
	/**
     * Name: getMaxNumberOfUsers
     * Desc: get Max Number of Users
     * @return: Decimal
    **/
    public static Decimal getMaxNumberOfUsers() {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Max_Number_of_Users__c  ;
    }
    
    public static String getConfigurationsTaxId() {
     	if(AccessControl.ifObjectFieldIsAccessible('Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getOrgDefaults().Tax_Id__c;
    }
    
     /**
     * Name: isBrandingLocationActive
     * Desc: get Branding Location Settings
     * @return: Boolean
    **/
    
    public static Boolean isBrandingLocationEnabled() {
    	if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getOrgDefaults().Enable_branding_locations__c;
    }

    /**
     * Name: getBarCodeLabelSize
     * Desc: get Bar code label size
     * @return: String
    **/

    public static String getBarCodeLabelSize() {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return String.isNotBlank(General_Configurations__c.getOrgDefaults().Bar_Code_Label_Size__c) ? General_Configurations__c.getOrgDefaults().Bar_Code_Label_Size__c.toLowerCase() : 'large';
    }
    
    /**
     * Name: getMaxNumberOfTechnicians
     * Desc: get Max Number of Technicians
     * @return: Decimal
    **/
    public static Decimal getMaxNumberOfTechnicians() {
        if(AccessControl.ifObjectFieldIsAccessible('General_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getInstance().Max_Number_of_Technicians__c  ;
    }
    
    public static Boolean isSMSPhoneNumberConfigured() {
        if(!AccessControl.ifObjectFieldIsAccessible('SMS_Configuration__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return (SMS_Configuration__c.getOrgDefaults().Source_Number__c != null);
    }
    
    public static List<UnitDataFieldConfigWrapper> getUnitDataFieldsConfig() {
        if(AccessControl.ifObjectFieldIsAccessible('Unit_Data_Field_Config__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(unitConfigList == null) {
            unitConfigList = [Select Name, Display_Label__c from Unit_Data_Field_Config__c 
        			where Name != null AND Display_Label__c != null order by Name];
        }

    	List<UnitDataFieldConfigWrapper> unitDataFieldConfigObjList = new List<UnitDataFieldConfigWrapper>();
    	for(Unit_Data_Field_Config__c unitConfigRec : unitConfigList) {
    		unitDataFieldConfigObjList.add(new UnitDataFieldConfigWrapper(unitConfigRec.Name, unitConfigRec.Display_Label__c));
    	}
    	return unitDataFieldConfigObjList;
    }

    public static Map<String, String> getUnitDataFieldsAPINameToLabelMap() {
        if(!AccessControl.ifObjectFieldIsAccessible('Unit_Data_Field_Config__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(unitConfigList == null) {
            unitConfigList = [Select Name, Display_Label__c from Unit_Data_Field_Config__c 
        			where Name != null AND Display_Label__c != null order by Name];
        }

    	Map<String, String> unitDataFieldsAPINameToLabelMap = new Map<String, String>();
    	for(Unit_Data_Field_Config__c unitConfigRec: unitConfigList) {
    		unitDataFieldsAPINameToLabelMap.put(unitConfigRec.Name.replaceAll(' ', '_') + '__c', unitConfigRec.Display_Label__c);
    	}
    	return unitDataFieldsAPINameToLabelMap;
    }

    public static Integer getHomeSearchReportExportQueryLimit() {
        if(AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return (Integer) BP_Configurations__c.getOrgDefaults().Home_Search_Report_Export_Query_Limit__c;
    }
    
    public static Decimal getDP360OpenLeadFetchingPeriodInDays() {
        if(!AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return BP_Configurations__c.getOrgDefaults().DP360_Lead_Search_Days__c;
    }
    
    public class UnitDataFieldConfigWrapper {
    	public String FieldName;
    	public String DisplayLabel;
    	
    	public UnitDataFieldConfigWrapper(String fieldName, String displayLabel) {
    		this.FieldName = fieldName;
    		this.DisplayLabel = displayLabel;
    	}
    }

    public static Boolean isCassonsEnabled() {
        if(!AccessControl.ifObjectFieldIsAccessible('General_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getOrgDefaults().Enable_Cassons__c;
    }
    
    public static Boolean isShopifyIntegrationEnabled() {
        if(!AccessControl.ifObjectFieldIsAccessible('General_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getOrgDefaults().Enable_Shopify_Integration__c;
    }
	
    public static Boolean isShopifyIntegrationActive() {
        if(!AccessControl.ifObjectFieldIsAccessible('General_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getOrgDefaults().Activate_Shopify_Integration__c;
    }
    
    public static Boolean enforceTechnicianPIN() {
        if(!AccessControl.ifObjectFieldIsAccessible('Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getOrgDefaults().Enforce_Technician_PIN__c;
    }
    
    public static Boolean enforcePayrollPIN() {
        if(!AccessControl.ifObjectFieldIsAccessible('Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getOrgDefaults().Enforce_Payroll_PIN__c;
    }
    
    public static Boolean isTwoWayTextEnabled() {
        if(!AccessControl.ifObjectFieldIsAccessible('General_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getOrgDefaults().Enable_Two_Way_Text__c;
    }

    public static Boolean isRecordTrackingNumber() {
        if(!AccessControl.ifObjectFieldIsAccessible('Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getOrgDefaults().Record_Tracking_Numbers__c;
    }

    public static String getIntextAlertEmailRecipient() {
        if(!AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return BP_Configurations__c.getOrgDefaults().Intext_Alert_Email_Recipient__c;
    }
    
    public static String getActiveVendorAvailabilityIds() {
        List<String> vendorIdList = new List<String>();
        for(Vendor_Availability_Mapping__c vendorMappingRec : Vendor_Availability_Mapping__c.getAll().values()) {
            if(vendorMappingRec.Active__c) {
                vendorIdList.add(vendorMappingRec.Vendor_SF_Id__c);
            }
        }
        return String.join(vendorIdList, ',');
    }

    public static Integer getSyncRetrySchedulerIntervalInMins() {
        if(!AccessControl.ifObjectFieldIsAccessible('BP_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return (BP_Configurations__c.getOrgDefaults().Sync_Retry_Scheduler_Interval__c != null ? (Integer)BP_Configurations__c.getOrgDefaults().Sync_Retry_Scheduler_Interval__c: 20);
    }
    
    public static Boolean isAutoSelectOrdersInPartReceiving() {
        if(!AccessControl.ifObjectFieldIsAccessible('Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Configurations__c.getOrgDefaults().Auto_Select_Orders_In_Part_Receiving__c;
    }
    
    public static Decimal getVRRelatedListPageSize() {
        if(!AccessControl.ifObjectFieldIsAccessible('General_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getOrgDefaults().VR_Related_List_Page_Size__c; 
    }

    public static Integer getShopifyProductRescheduleInternalInMins() {
        if(!AccessControl.ifObjectFieldIsAccessible('Shopify_Configuration__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Integer intervalInMins = (Integer) Shopify_Configuration__c.getOrgDefaults().Reschedule_Interval__c;
        return (intervalInMins != null ? intervalInMins : 30);
    }

    public static Boolean isWebComponentSTAEnabled() {
        String isWebComponentSTAEnabled = getConfigurationByName(ENABLE_WEB_COMPONENT_STA);
        return String.isNotBlank(isWebComponentSTAEnabled) ? Boolean.valueOf(isWebComponentSTAEnabled) : false;
    }

    public static Boolean getBooleanValueOfConfigurationByName(String configName) {
        String configurationValue = getConfigurationByName(configName);
        return String.isNotBlank(configurationValue) ? Boolean.valueOf(configurationValue) : false;    
    }

    public static Boolean isNewGlobalSearchEnabled() {
        String isNewGlobalSearchEnabled = getConfigurationByName(ENABLE_NEW_GLOBAL_SEARCH);
        return String.isNotBlank(isNewGlobalSearchEnabled) ? Boolean.valueOf(isNewGlobalSearchEnabled) : false;
    }
    
    public static Boolean isReportSchedulingEnabled() {
        String isReportSchedulingEnabled = getConfigurationByName(ENABLE_REPORT_SCHEDULING);
        return String.isNotBlank(isReportSchedulingEnabled) ? Boolean.valueOf(isReportSchedulingEnabled) : false;
    }

    public static Boolean isWPMTagSyncingEnabled() {
        if(!AccessControl.ifObjectFieldIsAccessible('General_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getOrgDefaults().WPM_Tag_Syncing__c;
    }

    public static String getConfigurationByName(String configName) {
        if(!AccessControl.ifObjectFieldIsAccessible('Configuration_List__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Map<String, Configuration_List__c> configNameToRecMap = Configuration_List__c.getAll();
        if(configNameToRecMap.containsKey(configName)) {
            return configNameToRecMap.get(configName).Value__c;
        }
    	return null;
    }

    public static Configuration_List__c upsertConfigurationListByName(String configName, String configValue){
        Map<String, Configuration_List__c> configNameToRecMap = Configuration_List__c.getAll();
        Configuration_List__c configRec ;
        if(configNameToRecMap.containsKey(configName)) {
            configRec = configNameToRecMap.get(configName);
        } else{
            configRec = new Configuration_List__c(Name = configName);
        }
        configRec.Value__c = configValue;
        DMLUtility.upsertSobjectList('Configuration_List__c', configRec);
    	return configRec;
    }

    public static Boolean isUsingDymoConnect() {
        return General_Configurations__c.getOrgDefaults().Is_Using_Dymo_Connect__c;
	}

    public static Boolean isPreferredPaymentIntegrationEnabled() {
        if(!AccessControl.ifObjectFieldIsAccessible('General_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return General_Configurations__c.getOrgDefaults().Enable_Preferred_Payment__c;
    }
    
    public static String getCompanyLogoHeightAndWidth() {
        if(!AccessControl.ifObjectFieldIsAccessible('Business_Profile__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Business_Profile__c> businessProfileList = [Select Logo_Height__c, Logo_Width__c from Business_Profile__c LIMIT 1];
    	if(businessProfileList.size() > 0) {
    		return System.JSON.serialize(new Map<String, Decimal> {'CompanyLogoHeight' => businessProfileList[0].Logo_Height__c, 'CompanyLogoWidth' => businessProfileList[0].Logo_Width__c});
    	}
    	return '';
    }
    
    public static String getFormIdToIncludeOnDealDocuments() {
        return Configurations__c.getOrgDefaults().Form_Id_To_Include_On_Deal_Documents__c;
    }
}