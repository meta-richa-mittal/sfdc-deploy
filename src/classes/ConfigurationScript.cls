/**
 * Author: Tarun Khandelwal
 * Since: 
 * Name: ConfigurationScript
 * Description: Apex class to delete all default data in org
**/
global without sharing class ConfigurationScript {
    public static boolean isPostInstallRunning = false;
    global static void runAll() {
        isPostInstallRunning = true;
        deleteConfigurations();
        createAdminConfigurations();
        createConfigurations();
        createWidgets();
        createTransactionTypes();
        createUserDependentFeature();
        setDashboardRefreshMinutes();
        String sch = '0 0 01 * * ?';
        executeReportScheduler(sch);
        enableNewPaymentAccounting();
    }
     
    global static void deleteNativeRecords() {}  
    
    /**
     * Name: deleteConfigurations
     * Desc: Method to configure custom default settings
     * @param:  
     * @return: 
    **/
    public static Boolean isTechnicianScheduling = false;
    public static Decimal maxNumberOfUsers = 5;
    public static Boolean isQBEnabled = false;
    public static Boolean isARIPartSmartEnabled = false;
    public static Boolean isHDDealerEnabled = false;
    public static Boolean isDisplayTaxInvoice = false;
    public static Decimal schedularStartDay = 0;
    public static Boolean isUseQBAccountingTaxCodes = false;
    public static Boolean isBrandingLocationEnabled = false;
    public static Boolean isTechnicianHoursCostingEnabled = false;
    public static Boolean isXeroEnabled = false;
    public static String barCodeLabelSize = '';
    public static Decimal maxNumberOfTechnicians;
    public static Decimal dashboardRefreshMinutes;
    public static Boolean isTwoWayTextEnabled = false;
    public static Boolean IsCassonsAPIEnabled = false;
    
    global static void deleteConfigurations() {
        isPostInstallRunning = true;
        List<String> objNamesList = new List<String>{'Configurations__c', 'SearchConfigurations__c'};
        if(AccessControl.ifObjectFieldIsAccessible(objNamesList) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable(objNamesList) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        
        List<SearchConfigurations__c> searchConfig = [Select Id from SearchConfigurations__c where Name != null];
        if(searchConfig.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('SearchConfigurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete searchConfig ;
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Reporting__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable('Reporting__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        List<Reporting__c> emailReport = [Select Id from Reporting__c where Reporting_Objects__c != null];
        if(emailReport.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('Reporting__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete emailReport ;
        }
    }

    /**
     * Name: enableNewPaymentAccounting
     * Desc: Method to General configure custom default settings for new functionlity of Accounting payments & deposits (ticket number 20510)
     * @param:  
     * @return: 
    **/
    private static void enableNewPaymentAccounting() {
        General_Configurations__c genConfig = General_Configurations__c.getOrgDefaults();
        genConfig.Use_new_payment_accounting__c = true;
        genConfig.New_Payment_Accounting_Enable_Time__c = datetime.now();
        DMLUtility.upsertSobjectList('General_Configurations__c', genConfig);
    }
    
    /**
     * Name: createAdminConfigurations
     * Desc: Method to configure custom default settings
     * @param:  
     * @return: 
    **/
    global static void createAdminConfigurations(){
        if(AccessControl.ifObjectFieldIsAccessible('Configurations__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Configurations__c config = Configurations__c.getOrgDefaults();
        config.SearchMinCharLength__c = 2;
        config.Sent_From_Email_Id__c = 'support@blackpurl.com';
        config.NumberOfCustomersRecordPageSize__c = 20;
        config.Cash_Payment_Rounding_Factor__c = 1;
        config.Default_Odometer_Type__c = 'Km'; 
        config.Default_Technician_Cost_Rate__c = 0;
        DMLUtility.upsertSobjectList('Configurations__c', config);
    }
    
    /**
     * Name: createConfigurations
     * Desc: Method to configure custom default settings
     * @param:  
     * @return: 
    **/
    global static void createConfigurations() {
        isPostInstallRunning = true;
        List<String> objNamesList = new List<String>{'Configurations__c', 'SearchConfigurations__c', 'Shop_Settings__c', 
        						'Payment_Method__c', 'Reporting__c','BP_Configurations__c'};
        if(AccessControl.ifObjectFieldIsCreateable(objNamesList) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable(objNamesList) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        
        List<ApexClass> apexClass = [Select NamespacePrefix, Name, Id From ApexClass where Name = 'Constants'];
    	String nameSpace = '';
    	if(apexClass.size() > 0 && String.isNotBlank(apexClass[0].NamespacePrefix)) {
          	nameSpace = apexClass[0].NamespacePrefix + '__';
     	}
        
        List<SearchConfigurations__c> searchConfigList = new List<SearchConfigurations__c>();
        searchConfigList.add(insertSearchConfigurationRecords('Customer', 'Name', '', 'Customer', 1, 'Name'));
        searchConfigList.add(insertSearchConfigurationRecords('Vendor', 'Name', '', 'Vendor', 2, 'Name,Is_Calculate_Part_Retail_Price__c,Retail_Base_Value__c,Retail_Rate__c,Retail_Rounding__c,Retail_Round_To__c'));
        searchConfigList.add(insertSearchConfigurationRecords('User', 'Name', '', 'User', 3, 'Name'));
        searchConfigList.add(insertSearchConfigurationRecords('Part__c', 'Part_Number__c', '{Description__c}', nameSpace + 'Part__c', 4, 'Part_Number__c,Description__c,Part_Id__c,Part_Id_Text__c,Qty_In_Stock__c, Qty_Committed__c, Retail_Price__c, Name, Vendor__c, AvailableParts__c,Non_Inventory_Part__c')); // ,Non_Inventory_Part__c: Added By Pooja 8 Feb. 2017
        searchConfigList.add(insertSearchConfigurationRecords('Category__c', 'Name', '', nameSpace + 'Category__c', 5, 'Name'));
        searchConfigList.add(insertSearchConfigurationRecords('Sales_Tax_Item__c', 'Name__c', '', nameSpace + 'Sales_Tax_Item__c', 6, 'Name__c'));
        searchConfigList.add(insertSearchConfigurationRecords('Labour','Name__c', '', nameSpace + 'Labour_Code__c', 7, 'Name__c, Name, Description__c, Code__c'));
        searchConfigList.add(insertSearchConfigurationRecords('Kit Header', 'Kit_Unique_Name__c', '', nameSpace + 'Kit_Header__c', 8, 'Name, Description__c, Kit_Unique_Name__c, Code__c,Service_Kit__c'));
        searchConfigList.add(insertSearchConfigurationRecords('Fee', 'Fee_Unique_Name__c', '', nameSpace + 'Fee__c', 9, 'Name, Description__c, Fee_Unique_Name__c, Code__c'));
        searchConfigList.add(insertSearchConfigurationRecords('Customer_Owned_Unit__c', 'Unit_Number__c', '{Year__c}, {Make_Name__c}, {Model_Name__c}', nameSpace + 'Customer_Owned_Unit__c', 10, 'Name,Unit_Number__c,Year__c,Unit_Make__r.Name,Unit_Model__r.Name,Make_Name__c,Model_Name__c,VIN_Number_Formula__c,Stock_Id__c,Formatted_Name__c'));
        searchConfigList.add(insertSearchConfigurationRecords('UnitModel', 'Name__c', '', 'UnitModel', 13, 'Name__c'));
        searchConfigList.add(insertSearchConfigurationRecords('Unit_Make__c', 'Name', '', nameSpace + 'Unit_Make__c', 12, 'Name'));
        searchConfigList.add(insertSearchConfigurationRecords('Unit_Model__c', 'Name__c', 'Name__c', nameSpace + 'Unit_Model__c', 14, 'Name__c'));
        searchConfigList.add(insertSearchConfigurationRecords('Unit_SubModel__c', 'sub_model__c', '', nameSpace + 'Unit_Model__c', 13, 'sub_model__c'));
        searchConfigList.add(insertSearchConfigurationRecords('Product__c', 'Product_Unique_Name__c', '', nameSpace + 'Product__c', 11, 'Product_Unique_Name__c, Code__c, Description__c, Type__c'));
        searchConfigList.add(insertSearchConfigurationRecords('Location__c', 'Name__c', '', nameSpace + 'Location__c', 15, 'Name__c'));
        DMLUtility.upsertSobjectList('SearchConfigurations__c', searchConfigList);
        
        List<Shop_Settings__c> shopConfigList = [Select Id from Shop_Settings__c where Name != null];
        if(shopConfigList.size() == 0) {
	        List<Shop_Settings__c> shopSettingConfigList = new List<Shop_Settings__c>();
	        shopSettingConfigList.add(insertShopSettingConfigurationRecords('Monday', true, 1));
	        shopSettingConfigList.add(insertShopSettingConfigurationRecords('Tuesday', true, 2));
	        shopSettingConfigList.add(insertShopSettingConfigurationRecords('Wednesday', true, 3));
	        shopSettingConfigList.add(insertShopSettingConfigurationRecords('Thursday', true, 4));
	        shopSettingConfigList.add(insertShopSettingConfigurationRecords('Friday', true, 5));
	        shopSettingConfigList.add(insertShopSettingConfigurationRecords('Saturday', false, 6));
	        shopSettingConfigList.add(insertShopSettingConfigurationRecords('Sunday', false, 7));
            DMLUtility.upsertSobjectList('Shop_Settings__c', shopSettingConfigList);
        }
        
        createPaymentMethodConfig();
        
        if(AccessControl.ifObjectFieldIsAccessible('Cash_Drawer__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Cash_Drawer__c> cashDrawerList = [Select Id from Cash_Drawer__c LIMIT 1];
        if(cashDrawerList.size() == 0) {
        	Cash_Drawer__c cashDrawerObj = new Cash_Drawer__c();
        	cashDrawerObj.Name = 'Main cash drawer';
        	cashDrawerObj.Active__c = true;
            DMLUtility.insertSobjectList('Cash_Drawer__c', cashDrawerObj);
        }
        
        Reporting__c reportingObj = Reporting__c.getOrgDefaults();
        reportingObj.Is_Reporting__c =  true;
        reportingObj.Receipient_Email__c = 'activity@blackpurl.com;yash.sharma@metacube.com;durga.singh@metacube.com;nikhil.srivastava@metacube.com';
        reportingObj.Reporting_Objects__c = 'Customer;Vendor;CO_Header__c;Part__c;Vendor_Order_Header__c';
        DMLUtility.upsertSobjectList('Reporting__c', reportingObj);
        
        Configurations__c config = Configurations__c.getOrgDefaults();
        Boolean isUpdateConfig = false;
        if(config.Cash_Payment_Rounding_Factor__c == null || config.Default_Odometer_Type__c == null ) {
            if(config.Cash_Payment_Rounding_Factor__c == null ) {
                config.Cash_Payment_Rounding_Factor__c = 1;
            }
            if(config.Default_Odometer_Type__c == null ) {
                config.Default_Odometer_Type__c = 'Km';
            }
            isUpdateConfig = true; 
        }
        isUpdateConfig = setShopifyDefaultValues(config);
        if(isUpdateConfig) {
            DMLUtility.upsertSobjectList('Configurations__c', config);
        }
        
        General_Configurations__c genConfig = General_Configurations__c.getOrgDefaults();
        if(genConfig.VR_Related_List_Page_Size__c == null) {
            genConfig.VR_Related_List_Page_Size__c = 100;
            DMLUtility.upsertSobjectList('General_Configurations__c', genConfig);
        }
        
        BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        bpConfig.Community_Link__c = 'https://blackpurlhelp.freshdesk.com/';
        if(bpConfig.Bypass_FLS_Check__c == null || !bpConfig.Bypass_FLS_Check__c) {
            bpConfig.Bypass_FLS_Check__c = true;
        }
        if(bpConfig.Dealership_Country__c == null) {
        	List<Business_Profile__c> businessProfileList = [SELECT Business_Country__r.Name__c FROM Business_Profile__c limit 1];
        	if(businessProfileList.size() > 0) {
        		bpConfig.Dealership_Country__c = businessProfileList[0].Business_Country__r.Name__c;
        	}
        }
        DMLUtility.upsertSobjectList('BP_Configurations__c', bpConfig);
        
        LMA_Config__c lmaConfig = LMA_Config__c.getOrgDefaults();
        if(lmaConfig.End_Point__c != null) {
            if(lmaConfig.End_Point__c.equalsIgnoreCase('https://test.salesforce.com')) {
                lmaConfig.End_Point__c = 'https://cs40.salesforce.com';
            } else if(lmaConfig.End_Point__c.equalsIgnoreCase('https://login.salesforce.com')) {
                lmaConfig.End_Point__c = 'https://na75.salesforce.com';
            }
            DMLUtility.updateSobjectList('LMA_Config__c', lmaConfig);
        }
    } 
    
    public static Boolean setShopifyDefaultValues(Configurations__c config) {
    	Boolean isUpdateConfig = false;
    	if(config != null) {
    		if(String.isBlank(config.Shopify_TT_Id__c)) {
    			List<Transaction_Type__c> ttList = [SELECT Id FROM Transaction_Type__c WHERE Type__c =: Constants.PART_SALE AND Active__c = true AND Default__c = true LIMIT 1];
    			if(ttList.size() > 0) {
    				config.Shopify_TT_Id__c = ttList[0].Id;
    				isUpdateConfig = true;
    			}
    		}
    		if(String.isBlank(config.Shopify_Payment_Method_Id__c)) {
    			List<Payment_Method__c> paymentMethods = [Select Id from Payment_Method__c where Is_Active__c = true Order By Order_Number__c ASC LIMIT 1];
    			if(paymentMethods.size() > 0) {
    				config.Shopify_Payment_Method_Id__c = paymentMethods[0].Id;
    				isUpdateConfig = true;
    			}
    		}
    	}
    	return isUpdateConfig;
    }
    /**
     * Name: insertSearchConfigurationRecords
     * Desc: Method to insert search configuration record
     * @param:      (1) name - record name
     *              (2) displayFieldForAutoComplete - Display Field For Auto Complete
     *              (3) displayInfo -  Display Information String
     *              (4) objectName - Object Name
     *              (5) Order - Order Number
     *              (6) searchableFieldForAutoComplete - Search Field For Auto Complete
     * @return: SearchConfigurations__c record
    **/
    private static SearchConfigurations__c insertSearchConfigurationRecords(String name, String displayFieldForAutoComplete, String displayInfo, String objectName, Integer Order, String searchableFieldForAutoComplete ) {
        SearchConfigurations__c searchConfig = new SearchConfigurations__c();
        searchConfig.Name = name;
        searchConfig.Display_Field__c = displayFieldForAutoComplete;
        searchConfig.Display_Info__c = displayInfo;
        searchConfig.Object_Name__c = objectName;
        searchConfig.Order__c = Order;
        searchConfig.Searchable_Field__c = searchableFieldForAutoComplete;    
        return searchConfig;
    } 
    
    private static Shop_Settings__c insertShopSettingConfigurationRecords(String day, Boolean isWorking, Integer orderNumber) {
        Shop_Settings__c shopSettingObject = new Shop_Settings__c();
        shopSettingObject.Name = day;
        shopSettingObject.Day__c = day;
        shopSettingObject.Is_Working__c = isWorking;
        shopSettingObject.From_Time__c = '8:00AM';
        shopSettingObject.To_Time__c = '5:00PM';
        shopSettingObject.Order_Number__c = orderNumber;
		return shopSettingObject;
    }  
    
    /**
     * Name: createWidgets
     * Desc: Method to create widget records
     * @param:  
     * @return: 
    **/
    global static void createWidgets() {
        List<Widget__c> widgetList  = new List<Widget__c>();
        widgetList.add(insertWidget(1, 'Selling'));
        widgetList.add(insertWidget(2, 'Ordering'));
        widgetList.add(insertWidget(3, 'MyProfile'));
        widgetList.add(insertWidget(4, 'Tasks'));
        widgetList.add(insertWidget(5, 'Actions'));
        widgetList.add(insertWidget(6, 'Chatter'));
        widgetList.add(insertWidget(7, 'News'));
        widgetList.add(insertWidget(8, 'Alerts'));
        DMLUtility.insertSobjectList('Widget__c', widgetList);
    }
    
     /**
     * Name: insertWidget
     * Desc: Method to insert widget record
     * @param:      (1) orderNumber - Order Number
     *              (2) widgetName - Widget Name
     * @return: Widget__c record
    **/
    private static Widget__c insertWidget(Integer orderNumber, String widgetName) {
        Widget__c widgetRec = new Widget__c();
        widgetRec.Order_Number__c = orderNumber;
        widgetRec.Widget_Name__c = widgetName;
        return widgetRec;
        
    }
    
    /**
     * Name: createTransactionTypes
     * Desc: Method to create Transaction Type records
     * @param:  
     * @return: 
    **/
    global static void createTransactionTypes() {
        List<Transaction_Type__c> ttList  = new List<Transaction_Type__c>();
        ttList.add(new Transaction_Type__c(Code__c = 'Customer Pay', Type__c = 'Customer', Code_Label__c = 'Customer Pay', Default__c = true, Active__c = true));
        ttList.add(new Transaction_Type__c(Code__c = 'Warranty', Type__c = 'Third-Party', Code_Label__c = 'Third-Party', Default__c = true, Active__c = true));
        ttList.add(new Transaction_Type__c(Code__c = 'Internal', Type__c = 'Internal', Code_Label__c = 'Internal Expense', Default__c = true, Active__c = true));
        ttList.add(new Transaction_Type__c(Code__c = 'Deal', Type__c = 'Deal Service', Code_Label__c = 'Deal', Default__c = true, Active__c = true));
        ttList.add(new Transaction_Type__c(Code__c = 'Unit Inventory', Type__c = 'Stock Unit', Code_Label__c = 'Unit Inventory', Default__c = true, Active__c = true));
        ttList.add(new Transaction_Type__c(Code__c = 'Quote Customer', Type__c = 'Quote', Code_Label__c = 'Quote Customer', Default__c = true, Active__c = true));
        ttList.add(new Transaction_Type__c(Code__c = 'Quote Third-Party', Type__c = 'Quote', Code_Label__c = 'Quote Third-Party', Default__c = false, Active__c = true));
        DMLUtility.insertSobjectList('Transaction_Type__c', ttList);
    }
    
    global static void createGlAccount() {}
    global static void createAccountingDataMigration(){}
    
    global static void createUserDependentFeature() {
        if(AccessControl.ifObjectFieldIsAccessible('User') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<User> userRecList =  [SELECT Id From User where IsActive = true AND Profile.Name = 'System Administrator' Order By CreatedDate LIMIT 1];
        if(!userRecList.isEmpty()) UserService.createFilters(new List<Id>{userRecList[0].Id});
    }
    
    global static void executeReportScheduler(String sch) {
        ReportScheduler repScheduler = new ReportScheduler();
        system.schedule('Automated Report', sch, repScheduler); 
    }
    
    global static void executePopulateVersionNameScheduler() {}

    global static void scheduleJobsOnNewOrgs() {
        ScheduleJobService.scheduleJobsOnNewOrgs();
    }
    
    global static void createQBIFWIntegrationConfig() {}   

    global static void setDashboardRefreshMinutes() {
        isPostInstallRunning = true;
        General_Configurations__c genConfig = General_Configurations__c.getOrgDefaults();
        if(genConfig.Dashboard_Refresh_Minutes__c == null) {
            genConfig.Dashboard_Refresh_Minutes__c = 15;
            DMLUtility.upsertSobjectList('General_Configurations__c', genConfig);
        }
    }
    
    public static void createPaymentMethodConfig() {
        List<Payment_Method__c> paymentMethodConfigList = [Select Id, Name from Payment_Method__c where Name != null];
        List<Payment_Method__c> paymentMethodConfigListToCreate = new List<Payment_Method__c>();

    	Boolean isPaymentProcessorIntegrationEnabled = GeneralConfiguration.isPreferredPaymentIntegrationEnabled();
    	if(paymentMethodConfigList.size() == 0) {
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Cash', true, 1, 'cash', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Debit', true, 2, 'debitCard', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Visa', true, 3, 'visa', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Mastercard', true, 4, 'mastercard', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Amex', true, 5, 'amex', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Cheque', true, 6, 'cheque', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Gift card', true, 7, 'giftCard', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('EFTPOS', false, 8, 'eftpos', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('PayPal', false, 9, 'paypal', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Afterpay', false, 10, 'afterpay', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Discover', false, 11, 'eftpos', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('PIN Payment', false, 12, 'eftpos', false));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Direct deposit', false, 13, '', true));
            paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Financing', false, 14, '', true));
            if(isPaymentProcessorIntegrationEnabled) {
                paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec(PreferredPaymentService.PREFERRED_PAYMENTS, false, 16, '', true));
            }
        } else {
        	Map<String, Payment_Method__c> nameToPaymentMethodMap = new Map<String, Payment_Method__c>();
            for(Payment_Method__c payment : paymentMethodConfigList){
                nameToPaymentMethodMap.put(payment.Name, payment);
            }
            if(!nameToPaymentMethodMap.containsKey('Direct deposit')) {
                paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Direct deposit', false, 13, '', true));
            }
            if(!nameToPaymentMethodMap.containsKey('Financing')) {
                paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Financing', false, 14, '', true));
            }
            if(!nameToPaymentMethodMap.containsKey('Webstore')) {
                paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec('Webstore', false, 15, 'eftpos', false));
            }
            if(isPaymentProcessorIntegrationEnabled && !nameToPaymentMethodMap.containsKey(PreferredPaymentService.PREFERRED_PAYMENTS)) {
                paymentMethodConfigListToCreate.add(createPaymentMethodConfigRec(PreferredPaymentService.PREFERRED_PAYMENTS, false, 16, '', true));
            }
        }
		
		if(paymentMethodConfigListToCreate.size() > 0) {
            DMLUtility.upsertSobjectList('Payment_Method__c', paymentMethodConfigListToCreate);
		}		
    }
    
    private static Payment_Method__c createPaymentMethodConfigRec(String name, Boolean isActive, Integer orderNumber, String iconLink, Boolean IsOnlyUpdepositedPaymentMethod) {
    	Payment_Method__c paymentMethodRec = new Payment_Method__c();
		paymentMethodRec.Name = name;
		paymentMethodRec.Is_Active__c = isActive;
		paymentMethodRec.Order_Number__c = orderNumber;
		paymentMethodRec.Icon_Link__c = iconLink;
        paymentMethodRec.Is_Only_Updeposited_Payment_Method__c = IsOnlyUpdepositedPaymentMethod;
		return paymentMethodRec;
    }

    global static void createCOARestrictionConfig() {
        // return if number of COA restrictions are 0
        List<COA_Restriction_Config__c> coaRestrictionConfigList = 
        	[SELECT Id, Integration_Name__c, Field_Name__c, Field_Value__c FROM COA_Restriction_Config__c limit: SOQLUtil.getAvailableQueryRowsLimit()];
        if(coaRestrictionConfigList.size() == 0) {
            return;
        }

        // creating map with already present COA restrication records 
        Map<String, Map<String, Set<String>>> coaIntegrationNameToFieldNameMap = new Map<String, Map<String, Set<String>>>();

        for(COA_Restriction_Config__c coaRestrictionConfig : coaRestrictionConfigList) {
        	if(!coaIntegrationNameToFieldNameMap.containsKey(coaRestrictionConfig.Integration_Name__c)) {
        		coaIntegrationNameToFieldNameMap.put(coaRestrictionConfig.Integration_Name__c, new Map<String, Set<String>>());
        	}
        	
        	if(!coaIntegrationNameToFieldNameMap.get(coaRestrictionConfig.Integration_Name__c).containsKey(coaRestrictionConfig.Field_Name__c)) {
        		coaIntegrationNameToFieldNameMap.get(coaRestrictionConfig.Integration_Name__c).put(coaRestrictionConfig.Field_Name__c, new Set<String>());
        	}
        	coaIntegrationNameToFieldNameMap.get(coaRestrictionConfig.Integration_Name__c).get(coaRestrictionConfig.Field_Name__c).add(coaRestrictionConfig.Field_Value__c);
        }
        
        // COA restrication values which are need to be insert if not already present in records
	    Map<String, Map<String, Set<String>>> integrationNameToFieldNameToValueMap = new Map<String, Map<String, Set<String>>>{
	        QBUtil.QUICKBOOKS_ONLINE => new Map<String, Set<String>>{'Detail Type' => new Set<String>{'GlobalTaxPayable'}},
	        XeroUtility.XERO => new Map<String, Set<String>>{'Account Type'	=>	new Set<String>{}}	
	    };

        // check if new COA restriction values are already present or not in records
        coaRestrictionConfigList = new List<COA_Restriction_Config__c>();
        for(String integrationName : integrationNameToFieldNameToValueMap.keySet()) {
            for(String fieldName : integrationNameToFieldNameToValueMap.get(integrationName).keySet()) {
                for(String fieldValue : integrationNameToFieldNameToValueMap.get(integrationName).get(fieldName)) {
                    if(!coaIntegrationNameToFieldNameMap.containsKey(integrationName) || !coaIntegrationNameToFieldNameMap.get(integrationName).containsKey(fieldName) || 
                    	!coaIntegrationNameToFieldNameMap.get(integrationName).get(fieldName).contains(fieldValue)) {
                        coaRestrictionConfigList.add(BPScriptUtility.createCOARestrictionConfig(integrationName, fieldName, fieldValue));
                    }
                }
            }
        }

        // insert new COA restriction records if not already present
		if(coaRestrictionConfigList.size() > 0) {
            DMLUtility.insertSobjectList('COA_Restriction_Config__c', coaRestrictionConfigList);
		}
    }
}