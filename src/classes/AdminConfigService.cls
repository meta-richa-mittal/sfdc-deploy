/**
 * Author: Nidhi Sharma
 * Since: June 16, 2022
 * Name: AdminConfigService
**/
public class AdminConfigService {

    public static final Integer WEEK_DAYS_COUNT = 7;
    public static final String PARTIALLY_CONFIGURED = 'Partially configured';
    
    public static AdminPreferredPaymentConfigWrapper getPreferredPaymentConfig() {
        AdminPreferredPaymentConfigWrapper config = new AdminPreferredPaymentConfigWrapper();
        IFW_IntegrationConfig__c ifwConfig;
        for(IFW_IntegrationConfig__c ifwRec : BaseIntegration.getParentByName(PreferredPaymentIntegrationService.integrationName)) {
            ifwConfig = ifwRec;
        }
        config.IntegrationConfigured = ifwConfig != null ? 'Yes' : 'No';
        
        config.Enabled = GeneralConfiguration.isPreferredPaymentIntegrationEnabled();
        config.TerminalList = new List<PaymentTerminalWrapper>();

        String query = 'Select Id, Registration_Code__c, Status__c, Nickname__c, Preferred_Payment_Id__c, Is_Signature_Required__c FROM Payment_Terminal__c';
        for(Payment_Terminal__c terminalRec : (List<Payment_Terminal__c>)SOQLUtility.getQueryResults('Payment_Terminal__c', query)) {
            PaymentTerminalWrapper terminalObj = new PaymentTerminalWrapper(terminalRec);
            terminalObj.RegistrationCode = terminalRec.Registration_Code__c;
            terminalObj.Status = terminalRec.Status__c;
            config.TerminalList.add(terminalObj);
        }
        String orgBaseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
        config.ManageTerminalsURL = orgBaseURL + '/' + Schema.getGlobalDescribe().get(Constants.Namespace+'Payment_Terminal__c').getDescribe().getKeyPrefix();
        config.AddTerminalURL = config.ManageTerminalsURL + '/e';

        config.MaxCreditAmount = PreferredPaymentService.getRefundMaxCreditAmount();
        return config;
    }

    public static void configurePreferredPaymentIntegration(String preferredPaymentConfigJsonStr) {
        AdminPreferredPaymentConfigWrapper config = (AdminPreferredPaymentConfigWrapper) System.JSON.deserialize(preferredPaymentConfigJsonStr, AdminPreferredPaymentConfigWrapper.class);
        createPreferredPaymentIFWConfigAndItems(config);
        createPaymentMethodAndSetUndepositedFunds();
    }

    private static void createPaymentMethodAndSetUndepositedFunds() {
        String cashUndepositedFund;
        for(Payment_Method__c paymentMethod : [Select Id, Undeposited_Funds__c from Payment_Method__c where Name = 'Cash']) {
            cashUndepositedFund = paymentMethod.Undeposited_Funds__c;
        }
        List<Payment_Method__c > paymentMethodList = [Select Id, Name from Payment_Method__c where Name =: PreferredPaymentIntegrationService.integrationName];
       	if(paymentMethodList.size() == 0) {
            Payment_Method__c paymentMethodRec = new Payment_Method__c();
            paymentMethodRec.Name = PreferredPaymentIntegrationService.integrationName;
            paymentMethodRec.Is_Active__c = false;
            paymentMethodRec.Order_Number__c = 16;
            paymentMethodRec.Icon_Link__c = '';
            paymentMethodRec.Is_Only_Updeposited_Payment_Method__c = true;
            paymentMethodRec.Undeposited_Funds__c = cashUndepositedFund;
            DMLUtility.insertSobjectList('Payment_Method__c', paymentMethodRec);
        } else {
            paymentMethodList[0].Undeposited_Funds__c = cashUndepositedFund;
            DMLUtility.updateSobjectList('Payment_Method__c', paymentMethodList[0]);
        }
    }

    private static void createPreferredPaymentIFWConfigAndItems(AdminPreferredPaymentConfigWrapper config) {
        IFW_IntegrationConfig__c ifwConfig;
        for(IFW_IntegrationConfig__c ifwRec : BaseIntegration.getParentByName(PreferredPaymentIntegrationService.integrationName)) {
            ifwConfig = ifwRec;
        }
        if(ifwConfig != null) {
            ifwConfig.Bearer_Token__c = config.PrivateKey;
            ifwConfig.Public_Key__c = config.PublicKey;
            DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfig);
        } else {
            ifwConfig = IntegrationServiceFactory.createIFWConfig(false, PreferredPaymentIntegrationService.integrationName, 'Basic', config.PublicKey, config.PrivateKey, null);
            DMLUtility.insertSobjectList('IFW_IntegrationConfig__c', ifwConfig);

            List<IFW_IntegrationConfigItem__c> ifwConfigItemList = new List<IFW_IntegrationConfigItem__c>();
            ifwConfigItemList.add(
                IntegrationServiceFactory.createIFWConfigItem(
                    ifwConfig.Id, 
                    PreferredPaymentIntegrationService.PAYMENT_TERMINAL,
                    'https://api.preferredpayments.com/v1/terminals',
                    'GET'
                )
            );
            ifwConfigItemList.add(
                IntegrationServiceFactory.createIFWConfigItem(
                    ifwConfig.Id,
                    PreferredPaymentIntegrationService.PAYMENT_TERMINAL,
                    'https://api.preferredpayments.com/v1/terminals',
                    'POST'
                )
            );
            ifwConfigItemList.add(
                IntegrationServiceFactory.createIFWConfigItem(
                    ifwConfig.Id,
                    PreferredPaymentIntegrationService.PAYMENT_TERMINAL,
                    'https://api.preferredpayments.com/v1/terminals/{{terminal_id}}',
                    'DELETE'
                )
            );
            ifwConfigItemList.add(
                IntegrationServiceFactory.createIFWConfigItem(
                    ifwConfig.Id,
                    PreferredPaymentIntegrationService.VOID_TRANSACTION,
                    'https://api.preferredpayments.com/v1/transactions/void',
                    'POST'
                )
            );
            ifwConfigItemList.add(
                IntegrationServiceFactory.createIFWConfigItem(
                    ifwConfig.Id,
                    PreferredPaymentIntegrationService.REFUND_TRANSACTION,
                    'https://api.preferredpayments.com/v1/transactions/refund',
                    'POST'
                )
            );
            ifwConfigItemList.add(
                IntegrationServiceFactory.createIFWConfigItem(
                    ifwConfig.Id,
                    PreferredPaymentIntegrationService.CREDIT_TRANSACTION,
                    'https://api.preferredpayments.com/v1/transactions/credit',
                    'POST'
                )
            );
            ifwConfigItemList.add(
                IntegrationServiceFactory.createIFWConfigItem(
                    ifwConfig.Id,
                    PreferredPaymentIntegrationService.SALE_TRANSACTION,
                    'https://api.preferredpayments.com/v1/transactions/sale',
                    'POST'
                )
            );
            DMLUtility.insertSobjectList('IFW_IntegrationConfigItem__c', ifwConfigItemList);
        }
    }

    public static AdminGeneralInformationConfigWrapper getGeneralInfoConfig() {
        AdminGeneralInformationConfigWrapper config = new AdminGeneralInformationConfigWrapper();
        List<Organization> companyInfoList = [SELECT Name, DefaultLocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, Country FROM Organization limit 1];
        List<UserLicense> userLicenseList = [SELECT Name, TotalLicenses FROM UserLicense where Name = 'Salesforce Platform' AND Status = 'Active'];
        if(companyInfoList.size() > 0) {
            config.OrgName = companyInfoList[0].Name;
            config.Locale = companyInfoList[0].DefaultLocaleSidKey; 
            config.Language = companyInfoList[0].LanguageLocaleKey;
            config.TimeZone = (companyInfoList[0].TimeZoneSidKey);
            config.TimeZoneList = Schema.SObjectType.User.fields.TimeZoneSidKey.picklistValues;
        }
        config.DealershipCountry = BP_Configurations__c.getOrgDefaults().Dealership_Country__c;
        config.LogoURL = GeneralConfiguration.getCompanyLogoUrl();
        config.OrgCurrency = UserInfo.getDefaultCurrency(); 
        config.Licenses = 0;
        
        for(UserLicense licenseRec : userLicenseList) {
            config.Licenses += licenseRec.TotalLicenses != null ? (Integer) licenseRec.TotalLicenses : 0;
        }

        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        if(generalConfig != null) {
            config.ReportRecordsPerPage = generalConfig.Home_Search_Grid_Page_Size__c != null ? (Integer) generalConfig.Home_Search_Grid_Page_Size__c : 0;
            config.RelatedListSize = generalConfig.Related_List_Page_Size__c != null ? (Integer) generalConfig.Related_List_Page_Size__c : 0;
            config.MaxUsers = generalConfig.Max_Number_of_Users__c != null ? (Integer) generalConfig.Max_Number_of_Users__c : 0;
            config.MaxTechnicians = generalConfig.Max_Number_of_Technicians__c != null ? (Integer) generalConfig.Max_Number_of_Technicians__c : 0;
            config.LabelSize = generalConfig.Bar_Code_Label_Size__c != null ? generalConfig.Bar_Code_Label_Size__c : '';
            config.DashboardRefresh = generalConfig.Dashboard_Refresh_Minutes__c != null ? (Integer) generalConfig.Dashboard_Refresh_Minutes__c : 0;
            config.IsDisplayTaxInvoice = generalConfig.Display_Tax_Invoice__c;
            config.IsUseAccountingTaxCodes = generalConfig.Use_QB_accounting_tax_codes__c;
            config.IsTechnicianScheduling = generalConfig.Technician_Scheduling__c;
            config.IsTechnicianHoursCosting = generalConfig.Technician_Hours_Costing__c;
            config.IsUsingDYMOConnect = generalConfig.Is_Using_Dymo_Connect__c;
            config.VRRelatedListPageSize = generalConfig.VR_Related_List_Page_Size__c != null ? (Integer) generalConfig.VR_Related_List_Page_Size__c : 0;
            config.IsCOAsyncActionUsed = generalConfig.Use_CO_Async_Action__c;
            config.IsMESHEnabled = generalConfig.MESH_Enabled_Org__c;
            config.IsUseNewPaymentAccounting = generalConfig.Use_new_payment_accounting__c;
            config.NewPaymentAccountingAllowDate = (generalConfig.New_Payment_Accounting_Enable_Time__c != null) ? BPUtility.getFormatedDateTime(generalConfig.New_Payment_Accounting_Enable_Time__c) : '' ;
        }
        Configurations__c configuration = Configurations__c.getOrgDefaults();
        if(configuration != null) {
            config.IsPricesIncludeTax = configuration.Tax_Included_Pricing__c;
            config.CashPaymentRounding = configuration.Cash_Payment_Rounding_Factor__c != null ? (Integer) configuration.Cash_Payment_Rounding_Factor__c : 0;
            config.IsEnhancedTaxCalculations = configuration.Enhanced_Tax_Calculations__c;
        }

        return config;
    }
    
    public static Map<String, String> integrationNameToFeatureToggleFieldMap = new Map<String, String> {
		'PreferredPayments' => 'Enable_Preferred_Payment__c'
	};

    public static Map<String, String> integrationNameToIFWFeatureToggleFieldMap = new Map<String, String> {
		'BRP' => 'Enabled__c'
	};
	
	public static void toggleConfigurations(String configJSON) {
		Map<String, Object> configObj = (Map<String, Object>) JSON.deserializeUntyped(configJSON);
        if(configObj.containsKey('IsIFWToggle') && Boolean.valueOf(configObj.get('IsIFWToggle'))) {
            String integrationName = String.valueOf(configObj.get('IntegrationName'));
            if(integrationName != null) {
                List<String> integrationNameList = (integrationName == BRPUtility.BRP) ? new List<String>{BRPUtility.BRP, BRPUtility.BRP_DMS_OAUTH2} : new List<String>{integrationName};
                List<IFW_IntegrationConfig__c> configList = BaseIntegration.getIFWConfigByName(integrationNameList);
                for(IFW_IntegrationConfig__c ifwRec: configList) {
                    ifwRec.Enabled__c = (configObj.get('Enabled') != null ? Boolean.valueOf(configObj.get('Enabled')) : false);
                }
                DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', configList);
            }
        } else  {
            General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
		
            for(String integrationName : integrationNameToFeatureToggleFieldMap.keySet()) {
                if(configObj.containsKey(integrationName)) {
                    generalConfig.put(integrationNameToFeatureToggleFieldMap.get(integrationName), (configObj.get(integrationName) != null ? configObj.get(integrationName) : false));
                }
            }
            if(configObj.size() > 0) {
                update generalConfig;
            }
        }
	}
	
    public static void setCompanyGeneralInfo(String companyGeneralInfoJsonStr) {
        AdminGeneralInformationConfigWrapper config = (AdminGeneralInformationConfigWrapper) System.JSON.deserialize(companyGeneralInfoJsonStr, AdminGeneralInformationConfigWrapper.class);
        if(String.isNotBlank(config.TimeZone)) updateOrgTimezone(config.TimeZone);
        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        if(generalConfig != null) {
            generalConfig.Home_Search_Grid_Page_Size__c = config.ReportRecordsPerPage;
            generalConfig.Related_List_Page_Size__c = config.RelatedListSize;
            generalConfig.Max_Number_of_Users__c = config.MaxUsers;
            generalConfig.Max_Number_of_Technicians__c = config.MaxTechnicians;
            generalConfig.Bar_Code_Label_Size__c = config.LabelSize;
            generalConfig.Dashboard_Refresh_Minutes__c = config.DashboardRefresh;
            generalConfig.Display_Tax_Invoice__c = config.IsDisplayTaxInvoice;
            generalConfig.Use_QB_accounting_tax_codes__c = config.IsUseAccountingTaxCodes;
            generalConfig.Technician_Scheduling__c = config.IsTechnicianScheduling;
            generalConfig.Technician_Hours_Costing__c = config.IsTechnicianHoursCosting;
            generalConfig.Is_Using_Dymo_Connect__c = config.IsUsingDYMOConnect;
            generalConfig.VR_Related_List_Page_Size__c = config.VRRelatedListPageSize;
            generalConfig.Use_CO_Async_Action__c = config.IsCOAsyncActionUsed;
            generalConfig.MESH_Enabled_Org__c = config.IsMESHEnabled;
            DMLUtility.updateSobjectList('General_Configurations__c', generalConfig);
        }

        Configurations__c configuration = Configurations__c.getOrgDefaults();
        if(configuration != null) {
            configuration.Tax_Included_Pricing__c = config.IsPricesIncludeTax;
            configuration.Cash_Payment_Rounding_Factor__c = config.CashPaymentRounding;
            configuration.Enhanced_Tax_Calculations__c = config.IsEnhancedTaxCalculations;
            DMLUtility.updateSobjectList('Configurations__c', configuration);
        }
    }
    
    public static void updateOrgTimezone(String timeZone) {
        List<Organization> companyInfoList = [SELECT Id, TimeZoneSidKey FROM Organization limit 1];
        if(companyInfoList.size() > 0 && companyInfoList[0].TimeZoneSidKey != timeZone) {
            String sfdcURL = URL.getOrgDomainUrl().toExternalForm();
            String restAPIURL = sfdcURL + '/services/data/v54.0/sobjects/Organization/' + companyInfoList[0].Id + '?_HttpMethod=PATCH';
            HttpRequest httpRequest = new HttpRequest(); 
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Authorization', 'Bearer ' + System.UserInfo.getSessionId());
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setEndpoint(restAPIURL);
            httpRequest.setBody('{ "TimeZoneSidKey": "' + timeZone + '"}'); 
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);
            if(httpResponse != null && httpResponse.getStatusCode() != 200 && httpResponse.getStatusCode() != 201 && httpResponse.getStatusCode() != 204) {
                throw new BlackPurlException('Error while setting organization timezone ' + httpResponse.getStatusCode() + ' ' + httpResponse.getbody());
            }
        }
    }
	
    public static ResponseWrapper syncTerminalDetailsFromPP(String ppTerminalJson) {
		PreferredPaymentResponseWrapper.Terminal terminalObj = (PreferredPaymentResponseWrapper.Terminal) System.JSON.deserialize(ppTerminalJson, PreferredPaymentResponseWrapper.Terminal.class);
		ResponseWrapper responseObj; 
		
		if(String.isNotBlank(terminalObj.id)) {
			Boolean isTerminalAlreadySynced = false;
			
			// Check weather terminal is already present in BP?
			Payment_Terminal__c terminal = new Payment_Terminal__c();
			List<Payment_Terminal__c> bpTerminalList = [SELECT Registration_Code__c, Nickname__c FROM Payment_Terminal__c WHERE Preferred_Payment_Id__c =: terminalObj.id OR
															Nickname__c =: terminalObj.nickname ORDER BY CreatedDate DESC limit 1];
			if(bpTerminalList.size() > 0) {
				isTerminalAlreadySynced = true;
				terminal = bpTerminalList[0];
			}
			copyTerminalDetails(terminal, terminalObj);
			responseObj = new ResponseWrapper(200, (isTerminalAlreadySynced) ? 'Terminal already found in BP. Details are updated.' : 'New Terminal Created');
		} else {
			responseObj = new ResponseWrapper(400, 'Invalid Terminal');
		}
		return responseObj;
	}
	
	public static void copyTerminalDetails(Payment_Terminal__c terminal, PreferredPaymentResponseWrapper.Terminal terminalObj) {
		terminal.Preferred_Payment_Id__c = terminalObj.id;
        terminal.Serial_Number__c = terminalObj.serial_number;
        terminal.Status__c = terminalObj.status;
        terminal.Make__c = terminalObj.make;
        terminal.Model__c = terminalObj.model;
        terminal.Nickname__c = terminalObj.nickname;
        
        DMLUtility.upsertSobjectList('Payment_Terminal__c', terminal);
	}
    
    public static void savePPConfigChange(String preferredPaymentConfigJsonStr) {
        AdminPreferredPaymentConfigWrapper config = (AdminPreferredPaymentConfigWrapper) System.JSON.deserialize(preferredPaymentConfigJsonStr, AdminPreferredPaymentConfigWrapper.class);
        List<Configuration_List__c> configList = [Select Value__c from Configuration_List__c where Name = 'Max Credit Amount' LIMIT 1];
    	if(configList.size() > 0) {
    		configList[0].Value__c = String.valueOf(config.maxCreditAmount);
    	} else {
            configList.add(new Configuration_List__c (Name = 'Max Credit Amount', Value__c = String.valueOf(config.maxCreditAmount)));
        }
        DMLUtility.upsertSobjectList('Configuration_List__c', configList);
    }

    public static AdminBRPConfigWrapper getBRPConfig() {
        Map<String, SObject> identifierIdToRecMap = new Map<String, SObject>([SELECT Name FROM Account WHERE Id IN: BRP_Vendors_List__c.getAll().keySet()]);
        identifierIdToRecMap.putAll([SELECT Name FROM Unit_Make__c WHERE Id IN: BRP_Vendors_List__c.getAll().keySet()]);
        AdminBRPConfigWrapper brpConfig = new AdminBRPConfigWrapper(BRP_Settings__c.getOrgDefaults(), BP_Configurations__c.getOrgDefaults(), BRP_Vendors_List__c.getAll(), identifierIdToRecMap);
        Map<String, IFW_IntegrationConfig__c> nameToIFWRecMap = new Map<String, IFW_IntegrationConfig__c>();
        for(IFW_IntegrationConfig__c ifwRec: BaseIntegration.getIFWConfigByName(new List<String>{BRPUtility.BRP, BRPUtility.BRP_OAUTH2})) {
            nameToIFWRecMap.put(ifwRec.Integration_Name__c, ifwRec);
        }

        if(nameToIFWRecMap.size() > 0) {
            if(nameToIFWRecMap.containsKey(BRPUtility.BRP)) {
                brpConfig.IntegrationConfigured = nameToIFWRecMap.get(BRPUtility.BRP).IFW_IntegrationConfigItems__r.size() != 
                                                    BRPUtility.entityNameToFieldNameToValueMapForBasicIFW.size() ? PARTIALLY_CONFIGURED : 'Yes';
                brpConfig.Enabled = nameToIFWRecMap.get(BRPUtility.BRP).Accounting_Enabled__c;
            }
            if(nameToIFWRecMap.containsKey(BRPUtility.BRP_OAUTH2)) {
                brpConfig.BRPPOAuthorized = String.isNotBlank(nameToIFWRecMap.get(BRPUtility.BRP_OAUTH2).Access_Token__c);
            }
        }

        return brpConfig;
    }

    public static void configureBRPIntegration(String brpConfigJsonStr) {
        AdminBRPConfigWrapper config = (AdminBRPConfigWrapper) System.JSON.deserialize(brpConfigJsonStr, AdminBRPConfigWrapper.class);
        createBRPIFWConfigAndItems(config);
        if(config.IntegrationConfigured == PARTIALLY_CONFIGURED) return;

        saveBRPConfig(config);
        createPasswordNeverExpirePS();
        
        Database.executeBatch(new BRPGetDealersBatch());
        Database.executeBatch(new SetBRPPartIndexBatch(1, system.today()), 2000);
        
        DateTime dateToschedule = getNextDateForSpecifiedDay('Sun');

        String jobName = ScheduleJobService.BRP_PART_INVENTORY_SCHEDULER;
        AccountingUtil.abortScheduleJobs(jobName);
        system.schedule(jobName, '0 0 15 ' + dateToschedule.day() + ' ' + dateToschedule.format('MMM') + ' ? ' + dateToschedule.year(), new BRPPartInventoryScheduler(system.today())); // schedule on upcoming sunday 5pm

        jobName = ScheduleJobService.INTEGRITY_CHECK_FOR_BRP;
        AccountingUtil.abortScheduleJobs(jobName);
        new IntegrityCheckForBRPScheduler().executeEmailScheduler();

        BPScriptUtility.createVendorMasterRecordForBRP();

        jobName = ScheduleJobService.BRP_PARTS_MASTER_SCHEDULER;
        AccountingUtil.abortScheduleJobs(jobName);
	    system.schedule(jobName, ScheduleJobService.jobNameToCronExpMap.get(jobName), new BRPPartsMasterBatch());


        jobName = ScheduleJobService.SEND_DMS_INFO_TO_BRP;
	    system.schedule(jobName, ScheduleJobService.jobNameToCronExpMap.get(jobName), new BRPSendDMSInfoScheduler());
    }

    private static void createBRPIFWConfigAndItems(AdminBRPConfigWrapper config) {
        Map<String, IFW_IntegrationConfig__c> nameToIFWRecMap = new Map<String, IFW_IntegrationConfig__c>();
        for(IFW_IntegrationConfig__c ifwRec: BaseIntegration.getIFWConfigByName(new List<String>{BRPUtility.BRP, BRPUtility.BRP_OAUTH2, BRPUtility.BRP_DMS_OAUTH2})) {
            nameToIFWRecMap.put(ifwRec.Integration_Name__c, ifwRec);
        }

        if(!nameToIFWRecMap.containsKey(BRPUtility.BRP)) {
            // insert BRP basic ifw and config items
            IFW_IntegrationConfig__c configRec = new IFW_IntegrationConfig__c();
            configRec.Integration_Name__c = BRPUtility.BRP;
            configRec.Auth_Scheme__c = 'Basic';
            configRec.Username__c = config.BRPUserName;
            configRec.Password__c = config.BRPPassword;
            nameToIFWRecMap.put(BRPUtility.BRP, configRec);
        } else if(nameToIFWRecMap.get(BRPUtility.BRP).IFW_IntegrationConfigItems__r.size() > 0) {
            DMLUtility.deleteSobjectList('IFW_IntegrationConfigItem__c', nameToIFWRecMap.get(BRPUtility.BRP).IFW_IntegrationConfigItems__r);
        }

        if(!nameToIFWRecMap.containsKey(BRPUtility.BRP_OAUTH2)) {
            // insert BRP Parts ordering OAuth 2.0 ifw and config items
            IFW_IntegrationConfig__c configRec = new IFW_IntegrationConfig__c();
            configRec.Integration_Name__c = BRPUtility.BRP_OAUTH2;
            configRec.Auth_Scheme__c = 'OAuth2.0';
            configRec.Enabled__c = true;
            configRec.Client_Id__c = config.OAuth2ClientId;
            configRec.Client_Secret__c = config.OAuth2ClientSecret;
            nameToIFWRecMap.put(BRPUtility.BRP_OAUTH2, configRec);
        } else if(nameToIFWRecMap.get(BRPUtility.BRP_OAUTH2).IFW_IntegrationConfigItems__r.size() > 0) {
            DMLUtility.deleteSobjectList('IFW_IntegrationConfigItem__c', nameToIFWRecMap.get(BRPUtility.BRP_OAUTH2).IFW_IntegrationConfigItems__r);
        }

        if(!nameToIFWRecMap.containsKey(BRPUtility.BRP_2)) {
            // insert BRP DMS OAuth 2.0 ifw and config items
            IFW_IntegrationConfig__c configRec = new IFW_IntegrationConfig__c();
            configRec.Integration_Name__c = BRPUtility.BRP_2;
            configRec.Auth_Scheme__c = 'OAuth2.0';
            configRec.Client_Id__c = config.DMSOAuth2ClientId;
            configRec.Client_Secret__c = config.DMSOAuth2ClientSecret;
            configRec.Access_Token__c = config.DMSOAuth2AccessToken;
            nameToIFWRecMap.put(BRPUtility.BRP_2, configRec);
        } else if(nameToIFWRecMap.get(BRPUtility.BRP_2).IFW_IntegrationConfigItems__r.size() > 0) {
            DMLUtility.deleteSobjectList('IFW_IntegrationConfigItem__c', nameToIFWRecMap.get(BRPUtility.BRP_2).IFW_IntegrationConfigItems__r);
        }

        if(nameToIFWRecMap.size() > 0) DMLUtility.upsertSobjectList('IFW_IntegrationConfig__c', nameToIFWRecMap.values());

        List<IFW_IntegrationConfigItem__c> ifwItemListToInsert = new List<IFW_IntegrationConfigItem__c>();
        Map<String, Map<String, Map<String, String>>> authTypeToConfigItemsMap = new Map<String, Map<String, Map<String, String>>>();
        authTypeToConfigItemsMap.put(BRPUtility.BRP, BRPUtility.entityNameToFieldNameToValueMapForBasicIFW);
        authTypeToConfigItemsMap.put(BRPUtility.BRP_OAUTH2, BRPUtility.entityNameToFieldNameToValueMapForOAUth2POIFW);
        authTypeToConfigItemsMap.put(BRPUtility.BRP_2, BRPUtility.entityNameToFieldNameToValueMapForOAUth2IFW);

        for(String integrationName: authTypeToConfigItemsMap.keySet()) {
            Map<String, Map<String, String>> entityNameToIFWItemMap = authTypeToConfigItemsMap.get(integrationName);
            for(String entityName: entityNameToIFWItemMap.keySet()) {
                IFW_IntegrationConfigItem__c ifwConfigItem = new IFW_IntegrationConfigItem__c(IFW_IntegrationConfig__c = nameToIFWRecMap.get(integrationName).Id);
                Map<String, String> fieldNameToValueMap = entityNameToIFWItemMap.get(entityName);
                for(String fieldName: fieldNameToValueMap.keySet()) {
                    String fieldValue = fieldNameToValueMap.get(fieldName);
                    if(fieldName.contains('Endpoint_URL__c') && (Constants.NAMESPACE).equalsIgnoreCase('BlackPurlCore__')) {
                        if(entityName == 'GetArticle' || entityName == 'GetCampaigns') {
                            if(integrationName == BRPUtility.BRP_2) {
                                fieldValue = fieldValue.replace('ms-brp-proxy-5niqfavtya-uc', 'ms-brp-proxy-zu6w3drdfa-uc');
                            } else {
                                fieldValue = fieldValue.replace('qa', 'prod');
                            }
                        } else {
                            fieldValue = fieldValue.replace('qa-', '');
                        }
                    }
                    ifwConfigItem.put(fieldName, fieldValue);
                }
                ifwItemListToInsert.add(ifwConfigItem);
            }
        }

        if(ifwItemListToInsert.size() > 0) DMLUtility.insertSobjectList('IFW_IntegrationConfigItem__c', ifwItemListToInsert);
    }

    public static void saveBRPConfig(AdminBRPConfigWrapper config) {
        saveBRPSettings(config);
        saveBPConfig(config);
        saveBRPIdentifierList(config.BRPIdentifierList);
    }

    public static void disableBRPPartsOrder() {
        List<BRP_Vendors_List__c> brpIdentifierList = [SELECT Id, Is_Used_For_Parts_Ordering__c FROM BRP_Vendors_List__c WHERE Is_Used_For_Parts_Ordering__c = true];
        for(BRP_Vendors_List__c rec: brpIdentifierList) {
            rec.Is_Used_For_Parts_Ordering__c = false;
        }
        DMLUtility.updateSobjectList('BRP_Vendors_List__c', brpIdentifierList);
    }

    private static void saveBRPSettings(AdminBRPConfigWrapper config) {
        BRP_Settings__c brpSettingsConfig = BRP_Settings__c.getOrgDefaults();
        brpSettingsConfig.Dealer_Id__c = config.DealerId;
        brpSettingsConfig.Currency_Code__c = config.CurrencyCode;
        brpSettingsConfig.Radius_Measure__c = config.RadiusMeasure;
        brpSettingsConfig.Radius__c = config.Radius;
        DMLUtility.upsertSobjectList('BRP_Settings__c', brpSettingsConfig);
    }

    private static void saveBPConfig(AdminBRPConfigWrapper config) {
        BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        bpConfig.SF_Username__c = BPUtility.getEncodedString(config.DealershipUserName);
        bpConfig.SF_Password__c = BPUtility.getEncodedString(config.DealershipPassword);
        DMLUtility.upsertSobjectList('BP_Configurations__c', bpConfig);
    }

    private static void saveBRPIdentifierList(List<AdminBRPConfigWrapper.BRPIdentifier> brpIdentifierList) {
        List<BRP_Vendors_List__c> brpIdentifierListToUpsert = new List<BRP_Vendors_List__c>();
        for(AdminBRPConfigWrapper.BRPIdentifier identifierRec: brpIdentifierList) {
            BRP_Vendors_List__c brpRec = new BRP_Vendors_List__c();
            brpRec.Type__c = identifierRec.Type;
            brpRec.Is_Active_Vendor__c = identifierRec.Active;
            brpRec.Is_Used_For_Parts_Master__c = identifierRec.UsedForPartsMaster;
            brpRec.Is_Used_For_Parts_Ordering__c = identifierRec.UsedForPartsOrdering;
            brpRec.Name = identifierRec.IdentifierId;
            brpRec.Id = identifierRec.Id;
            brpIdentifierListToUpsert.add(brpRec);
        }
        DMLUtility.upsertSobjectList('BRP_Vendors_List__c', brpIdentifierListToUpsert);
    }

    public static DateTime getNextDateForSpecifiedDay(String dayName) {
        String todaysDay = system.now().format('E');
        Integer daysToAdd = 0;
        if(dayNameToDayValueMap.get(dayName) > dayNameToDayValueMap.get(todaysDay)) {
            daysToAdd = dayNameToDayValueMap.get(dayName) - dayNameToDayValueMap.get(todaysDay);
        } else {
            daysToAdd = WEEK_DAYS_COUNT - dayNameToDayValueMap.get(todaysDay) + dayNameToDayValueMap.get(dayName);
        }
        return system.now().addDays(daysToAdd);
    }

    @future
    public static void createPasswordNeverExpirePS() {
        List<PermissionSet> permSetList = [SELECT Id FROM PermissionSet WHERE Name = 'Password_Never_Expire'];
        PermissionSet permSet;
        List<SObject> permSetAssList;
        if(permSetList.size() == 0) {
            permSet = new PermissionSet(Label = 'Password Never Expire', Name = 'Password_Never_Expire');
        } else {
            permSet = permSetList[0];
            permSetAssList = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :permSet.Id AND AssigneeId = :UserInfo.getUserId()];
        }
        permSet.PermissionsPasswordNeverExpires = true;
        upsert permSet;

        //Assigning to the BP Admin User
        if(permSetAssList == null || permSetAssList.size() == 0) {
            sObject permissionSetAssignmentRec = Schema.getGlobalDescribe().get('PermissionSetAssignment').newSObject();
            permissionSetAssignmentRec.put('PermissionSetId', permSet.Id);
            permissionSetAssignmentRec.put('AssigneeId', UserInfo.getUserId());
            DMLUtility.insertSObjectList('PermissionSetAssignment', permissionSetAssignmentRec);
        }
    }

    private static Map<String, Integer> dayNameToDayValueMap = new Map<String, Integer>{
        'Mon' => 1,
        'Tue' => 2,
        'Wed' => 3,
        'Thu' => 4,
        'Fri' => 5,
        'Sat' => 6,
        'Sun' => 7
    };
    
    public static String resetAllUsersTimezone(String timeZone) {
    	if(String.isNotBlank(timeZone)) {
            updateOrgTimezone(timeZone);
            List<User> userList = [SELECT Id, Username, TimeZoneSidKey FROM User where IsActive = true AND (profile.name = 'Blackpurl' OR profile.name = 'System Administrator')];
            for(User userRec : userList) {
                userRec.TimeZoneSidKey = timeZone;
            }
            DMLUtility.updateSobjectList('User', userList);
        } else {
            throw new BlackPurlException('Timezone value cannot be blank');
        }
        return 'Success';
    }

    public static String getAccountingReconciliationTabURL() {
        return System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + Schema.getGlobalDescribe().get(GeneralConfiguration.getNamespace()+'Accounting_Reconciliation__c').getDescribe().getKeyPrefix();
    }

    public static List<AccountingReconciliationWrapper> getAccountingReconciliationByDate(String dateValueStr) {
        List<AccountingReconciliationWrapper> accReconcilicationObjList = new List<AccountingReconciliationWrapper>();
        Datetime selectedDate = DateTimeUtility.getDateTimeFromFormattedDateStr(dateValueStr);
        DateTime nextDate = selectedDate.addDays(1);
        List<Accounting_Reconciliation__c> accReconciliationList = Database.query('SELECT Id, Reconciliation_Date__c, Type__c, Number_of_BP_records__c, Blackpurl_Balance__c, GL_Balance__c, Variance__c, GL_Account_Name__c, CreatedDate, Variance_Change__c FROM Accounting_Reconciliation__c WHERE Reconciliation_Date__c >=' + selectedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' AND Reconciliation_Date__c < ' + nextDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' Order By Type__c, GL_Balance__c');
        for(Accounting_Reconciliation__c accReconciliationRec : accReconciliationList) {
            accReconcilicationObjList.add(new AccountingReconciliationWrapper(accReconciliationRec));
        }
        return accReconcilicationObjList;
    }

    public static List<AdminConfigWrapper.UnitDataFieldConfigWrapper> getUnitDataFieldConfig() {
        AccessControl.checkObjectIsAccessible('Unit_Data_Field_Config__c');
        List<Unit_Data_Field_Config__c> unitDataFieldConfigList = [SELECT Id, Name, Display_Label__c FROM Unit_Data_Field_Config__c WHERE Name != null ORDER BY Name];

        List<AdminConfigWrapper.UnitDataFieldConfigWrapper> unitDataFieldConfigObjList = new List<AdminConfigWrapper.UnitDataFieldConfigWrapper>();
        for(Unit_Data_Field_Config__c unitDataFieldConfig : unitDataFieldConfigList) {
            unitDataFieldConfigObjList.add(new AdminConfigWrapper.UnitDataFieldConfigWrapper(unitDataFieldConfig.Id, AdminConfigUtil.unitDataFieldNameMap.get(unitDataFieldConfig.Name), unitDataFieldConfig.Display_Label__c));
        }
        return unitDataFieldConfigObjList;
    }

    public static void saveUnitDataFieldConfig(String unitDataFieldConfigJsonStr) {
        AccessControl.checkObjectIsAccessible('Unit_Data_Field_Config__c');
        Map<Id, Unit_Data_Field_Config__c> unitDataFieldConfigIdToRecMap = new Map<Id, Unit_Data_Field_Config__c>([SELECT Id, Display_Label__c FROM Unit_Data_Field_Config__c WHERE Name != null]);

        List<AdminConfigWrapper.UnitDataFieldConfigWrapper> unitDataFieldConfigObjList = (List<AdminConfigWrapper.UnitDataFieldConfigWrapper>) System.JSON.deserialize(unitDataFieldConfigJsonStr, List<AdminConfigWrapper.UnitDataFieldConfigWrapper>.class);
        for(AdminConfigWrapper.UnitDataFieldConfigWrapper UnitDataFieldConfig : unitDataFieldConfigObjList) {
            unitDataFieldConfigIdToRecMap.get(UnitDataFieldConfig.Id).Display_Label__c = UnitDataFieldConfig.DisplayLabel;
        }
        DMLUtility.updateSobjectList('Unit_Data_Field_Config__c', unitDataFieldConfigIdToRecMap.values());
    }

    public static void removeIntegrationsConfig() {
        removeScheduledJobs();
        disconnectFromAccounting();
        deleteIFWConfigAndItems();
        updateCustomSettings();

    }

    private static void removeScheduledJobs() {
        try {
            String scheduledApexJobType = '7';
            for(CronTrigger scheduledJob: [SELECT Id FROM CronTrigger WHERE CronJobDetail.JobType = :scheduledApexJobType limit 99]) {
                system.abortJob(scheduledJob.Id);
            }
        } catch(Exception e) {
            // any error will be catched and no need to handle
        }
    }

    private static void disconnectFromAccounting() {
        try {
            String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
            if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
                AccountingIntegrationSettingsService.removeQBConnection();
            } else if(activeIntegrationName == XeroUtility.XERO) {
                QuickBooks_Configurations__c config = QuickBooks_Configurations__c.getOrgDefaults();
                AccountingIntegrationSettingsService.removeXeroConnection(config);
            }
        } catch(Exception e) {
            // any error will be catched and no need to handle
        }
    }

    public static void deleteIFWConfigAndItems() {
        try {
            DMLUtility.deleteSobjectList('IFW_IntegrationConfig__c', [SELECT Id FROM IFW_IntegrationConfig__c]);
        } catch(Exception e) {
            // any error will be catched and no need to handle
        }
    }

    private static void updateCustomSettings() {
        try {
            List<SObject> customSettingsToDeleteList1 = new List<SObject>();
            List<SObject> customSettingsToDeleteList2 = new List<SObject>();
            customSettingsToDeleteList1.addAll((List<SObject>)[SELECT Id FROM BRP_Vendors_List__c]);
            customSettingsToDeleteList1.addAll((List<SObject>)[SELECT Id FROM BRP_Settings__c]);
            customSettingsToDeleteList1.addAll((List<SObject>)[SELECT Id FROM DP360_Configuration__c]);
            customSettingsToDeleteList1.addAll((List<SObject>)[SELECT Id FROM SOM_Configuration__c]);
            customSettingsToDeleteList1.addAll((List<SObject>)[SELECT Id FROM Shopify_Configuration__c]);
            customSettingsToDeleteList1.addAll((List<SObject>)[SELECT Id FROM FTP_Config__c]);
            customSettingsToDeleteList2.addAll((List<SObject>)[SELECT Id FROM CASSONS_Configuration__c]);
            customSettingsToDeleteList2.addAll((List<SObject>)[SELECT Id FROM CASSONS_Vendor_List__c]);
            customSettingsToDeleteList2.addAll((List<SObject>)[SELECT Id FROM Yamaha_Australia_Config__c]);
            customSettingsToDeleteList2.addAll((List<SObject>)[SELECT Id FROM Honda_Configuration__c]);
            customSettingsToDeleteList2.addAll((List<SObject>)[SELECT Id FROM QuickBooks_Configurations__c]);
            delete customSettingsToDeleteList1;
            delete customSettingsToDeleteList2;
    
            General_Configurations__c genConfig = General_Configurations__c.getOrgDefaults();
            if(genConfig.Id != null) {
                genConfig.Enable_QB_Accounting__c = genConfig.Enable_Two_Way_Text__c = genConfig.Enable_Xero_Accounting__c = 
                genConfig.Enable_Shopify_Integration__c = genConfig.MESH_Enabled_Org__c = genConfig.Enable_Cassons__c = false;
    
                DMLUtility.updateSobjectList('General_Configurations__c', genConfig);
            }
        } catch(Exception e) {
            // any error will be catched and no need to handle
        }
    }

    public static List<AdminConfigWrapper.FeatueToggleWrapper> getFeatureToggleConfig() {
        List<AdminConfigWrapper.FeatueToggleWrapper> configObjList = new List<AdminConfigWrapper.FeatueToggleWrapper>();
        AccessControl.checkObjectIsAccessible('Configuration_List__c');
        for(Configuration_List__c config : [Select Name, Value__c FROM Configuration_List__c WHERE Visible_on_Admin_Screen__c = true Order By Name]) {
            configObjList.add(new AdminConfigWrapper.FeatueToggleWrapper(config));
        }
        return configObjList;
    }

    public static void saveFeatureToggleConfig(String featureToggleConfigJsonStr) {
        if(featureToggleConfigJsonStr != null) {
            List<Configuration_List__c> configUpdateList = new List<Configuration_List__c>();
            List<AdminConfigWrapper.FeatueToggleWrapper> featueToggleConfigObjList = (List<AdminConfigWrapper.FeatueToggleWrapper>) System.JSON.deserialize(featureToggleConfigJsonStr, List<AdminConfigWrapper.FeatueToggleWrapper>.class);
            for(AdminConfigWrapper.FeatueToggleWrapper config : featueToggleConfigObjList) {
                String value = config.IsEnabled != null ? String.valueOf(config.IsEnabled) : 'false';
                configUpdateList.add(new Configuration_List__c(Id = config.Id, Value__c = value));
            }
            update configUpdateList;
        }
    }

    public static AdminKenectWrapper getKenectConfig() {

        AdminKenectWrapper adminKenectWrapper = new AdminKenectWrapper();

        List<IFW_IntegrationConfig__c> ifwIntegConfigLst = [SELECT Integration_Name__c, Enabled__c FROM IFW_IntegrationConfig__c WHERE Integration_Name__c =: UniversalAPIUtility.UNIVERSAL_API ORDER BY CreatedDate DESC];
        String configListValue = GeneralConfiguration.getConfigurationByName(UniversalAPIUtility.featureToggleName);
        SMS_Configuration__c smsSettingsConfigRec = SMS_Configuration__c.getOrgDefaults();

        if(String.isNotBlank(smsSettingsConfigRec.Id)){
            if(!ifwIntegConfigLst.isEmpty() && configListValue != null && configListValue == 'true' && GeneralConfiguration.isTwoWayTextEnabled() && smsSettingsConfigRec.Kenect_Location_Id__c != null && String.isNotBlank(smsSettingsConfigRec.Source_Number__c)){
                adminKenectWrapper = new AdminKenectWrapper(smsSettingsConfigRec.Kenect_Location_Id__c, smsSettingsConfigRec.Source_Number__c, true);
            } else {
                adminKenectWrapper = new AdminKenectWrapper(smsSettingsConfigRec.Kenect_Location_Id__c, smsSettingsConfigRec.Source_Number__c, false);
            }
        }
        return adminKenectWrapper;
   }
   
   public static void saveKenectIntegration(String kenectJsonStr) {
        AdminKenectWrapper config = (AdminKenectWrapper) System.JSON.deserialize(BPUtility.getDecodedString(kenectJsonStr), AdminKenectWrapper.class);
       
        UniversalAPIService.createIFWConfigAndConfigItemsForUniversalAPI(true);

        SMS_Configuration__c smsSettingsConfigRec = SMS_Configuration__c.getOrgDefaults();
        smsSettingsConfigRec.Kenect_Location_Id__c = config.LocationId;
        smsSettingsConfigRec.Source_Number__c = config.SMSNumber;
        DMLUtility.upsertSobjectList('SMS_Configuration__c', smsSettingsConfigRec);

        GeneralConfiguration.upsertConfigurationListByName(UniversalAPIUtility.featureToggleName, 'true');

        General_Configurations__c generalSettingsConfigRec = GeneralConfiguration.getGeneralConfigurations();
        generalSettingsConfigRec.Enable_Two_Way_Text__c = true;
        DMLUtility.upsertSobjectList('General_Configurations__c', generalSettingsConfigRec);
   }

    public static List<AdminAccountingSyncFailureWrapper.SyncFailureWrapper> getAccountingSyncFailureDetails(Boolean fetchData) {
        AdminAccountingSyncFailureWrapper syncFailureObj = new AdminAccountingSyncFailureWrapper();
        Map<String, List<String>> entityNameToFailureCountMap = new Map<String, List<String>>();
        String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
        if(fetchData) {
            for(Integration_Entity__mdt mdtRec : [SELECT Entity_Name__c, Object_API_Name__c, Sync_Flag_API_Name__c FROM Integration_Entity__mdt where Label =: activeIntegrationName]) {
                String objectName = (mdtRec.Object_API_Name__c == 'Account' ? '' : Constants.Namespace) + mdtRec.Object_API_Name__c;
                String query = 'SELECT Name FROM ' + objectName + ' WHERE ' + mdtRec.Sync_Flag_API_Name__c +' = true';
                if(mdtRec.Entity_Name__c == 'Customer') {
                    query += ' AND Is_Customer__c = true'; // to remove providers from this list
                }
                entityNameToFailureCountMap.put(mdtRec.Entity_Name__c, new List<String>{String.valueOf(Database.query(query).size()), objectName});
            }

            // custom logic to add provider in the listing with customer sync flag
            String query1 = 'SELECT Name FROM Account WHERE availForQBSync__c = true AND Is_Vendor__c = true AND Claims_for_Service_Work__c = true';
            entityNameToFailureCountMap.put('Provider', new List<String>{String.valueOf(Database.query(query1).size()), 'Account'});
        }

        if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
            IntegrationUtility.syncEntityNameToFailureEntityNameMap.put('QB_AR_Payment', 'AR payment');
            IntegrationUtility.syncEntityNameToFailureEntityNameMap.put('Item_Category', 'Item category');
            IntegrationUtility.syncEntityNameToAsynListViewNameMap.put('QB_AR_Payment', 'Async QB AR Payment');
            IntegrationUtility.syncEntityNameToAsynListViewNameMap.put('Item_Category', 'Async QB Category');
        } else if(activeIntegrationName == XeroUtility.XERO) {
            IntegrationUtility.syncEntityNameToFailureEntityNameMap.put('AR_Payment', 'AR payment');
            IntegrationUtility.syncEntityNameToAsynListViewNameMap.put('AR_Payment', 'Async Xero AR Payment');
        }

        Map<String, ListView> listViewMap = getAccountingListViewsMap();
        for(String entityName: IntegrationUtility.syncEntityNameToFailureEntityNameMap.keySet()) {
            String countStr = !fetchData ? '?' : entityNameToFailureCountMap.containsKey(entityName) ? entityNameToFailureCountMap.get(entityName)[0] : '0';
            String objectName = entityNameToFailureCountMap.containsKey(entityName) ? entityNameToFailureCountMap.get(entityName)[1] : '';
            syncFailureObj.SyncFailureList.add(
                new AdminAccountingSyncFailureWrapper.SyncFailureWrapper(
                    IntegrationUtility.syncEntityNameToFailureEntityNameMap.get(entityName), 
                    countStr, 
                    getListViewURL(listViewMap.get(IntegrationUtility.syncEntityNameToAsynListViewNameMap.get(entityName)), objectName), 
                    null
            ));
        }
        return syncFailureObj.SyncFailureList;
    }

    public static AdminAccountingSyncFailureWrapper getAccountingLogsDetails() {
        AdminAccountingSyncFailureWrapper syncFailureObj = new AdminAccountingSyncFailureWrapper();
        syncFailureObj.ErrorLogsURL = getDefaultListViewURL(Constants.Namespace + 'Log__c');
        syncFailureObj.WebServiceLogsURL = getDefaultListViewURL(Constants.Namespace + 'WebService_Log__c');
        return syncFailureObj;
    }

    public static void executeAccountingScript(String entityName) {
        Integer maxNumberOfRecord = 25, maxNumberOfRecordForBulk = QBUtil.isQBEnabled() ? 1000 : (XeroUtility.isXeroEnabled() ? 5000 : 0);
        Integer timeIntervalForJobsInSec = 60;
        Integer batchChunkSizeForBulk = QBUtil.isQBEnabled() ? 30 : (XeroUtility.isXeroEnabled() ? 500 : 0);
        
        switch on entityName {
            when 'Account - Customer' {
                AccountingScriptUtil.syncBulkCustomers(maxNumberOfRecordForBulk, timeIntervalForJobsInSec, batchChunkSizeForBulk);
            }
            when 'Account - Provider' {
                AccountingScriptUtil.syncCustomers(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Account - Vendor' {
                AccountingScriptUtil.syncBulkVendors(maxNumberOfRecordForBulk, timeIntervalForJobsInSec, batchChunkSizeForBulk);
            }
            when 'CO Checkout payments (COIP)' {
                AccountingScriptUtil.syncCOInvoicePaymentJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'CO Deposits (CODN)' {
                AccountingScriptUtil.syncCODeposit(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'CO Invoice Header' {
                AccountingScriptUtil.syncCOInvoice(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'CO Invoice JE' {
                AccountingScriptUtil.syncCOInvoiceJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'CO Invoice Payment' {
                AccountingScriptUtil.syncCOInvoicePayment(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'CO Lien payout' {
                AccountingScriptUtil.syncLienPayouts(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'CO Stocked trade-in' {
                AccountingScriptUtil.syncStockedTradeInJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'COU - Consignments' {
                AccountingScriptUtil.syncConsignmentUnit(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'COU - Unit category' {
                AccountingScriptUtil.syncUnitCategory(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'COU - Unit Invoice' {
                AccountingScriptUtil.syncUnitInvoice(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'COU - Unit JE' {
                AccountingScriptUtil.syncUnitInvoiceJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'COU - Unit NITC JE' {
                AccountingScriptUtil.syncUnitNITCJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Count session JE' {
                AccountingScriptUtil.syncCountSessionJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Hours logged' {
                AccountingScriptUtil.syncHoursLogged(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Part - Category' {
                AccountingScriptUtil.syncPartCategory(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Part - FIFO bucket' {
                AccountingScriptUtil.syncFIFOBuckets(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Part - FIFO bucket activity' {
                AccountingScriptUtil.syncFIFOBucketLineItems(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Payment on account' {
                AccountingScriptUtil.syncPaymentsOnAccount(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Vendor credits' {
                AccountingScriptUtil.syncVendorCredit(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Vendor credit JE' {
                AccountingScriptUtil.syncVendorCreditVarianceJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Store credits' {
                AccountingScriptUtil.syncStoreCredits(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Unit Prices & cost' {
                AccountingScriptUtil.syncUnitAdjustments(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Vendor invoice' {
                AccountingScriptUtil.syncVendorInvoices(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Vendor invoice JE' {
                AccountingScriptUtil.syncVIVarianceJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Vendor receiving' {
                AccountingScriptUtil.syncVRJE(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'AR payment' {
                AccountingScriptUtil.syncARPayments(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Item category' {
                AccountingScriptUtil.syncCategory(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when 'Cash Reconciliation JE' {
                AccountingScriptUtil.syncCashReconciliation(maxNumberOfRecord, timeIntervalForJobsInSec);
            }
            when else {
                throw new BlackPurlException('Script can not be found.');
            }
        }
    }

    private static String getDefaultListViewURL(String objectName) {
        if(String.isBlank(objectName)) return System.URL.getSalesforceBaseUrl().toExternalForm();
        return (System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix());
    }

    private static String getListViewURL(ListView listViewRec, String objectName) {
        objectName = String.isBlank(objectName) && listViewRec != null ? listViewRec.SobjectType : objectName;
        String defListViewURL = getDefaultListViewURL(objectName);
        if(listViewRec == null) return defListViewURL;
        return defListViewURL + '?fcf=' + String.valueOf(listViewRec.Id).substring(0, 15);
    }

    private static Map<String, ListView> getAccountingListViewsMap() {
        Map<String, ListView> listViewMap = new Map<String, ListView>();
        for(ListView listViewRec : [SELECT Id, Name, SobjectType FROM ListView WHERE Name IN: IntegrationUtility.syncEntityNameToAsynListViewNameMap.values()]) {
            listViewMap.put(listViewRec.Name, listViewRec);
        }
        return listViewMap;
    }
}