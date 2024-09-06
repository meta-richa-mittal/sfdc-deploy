/**
 * Author: Richa Mittal
 * Since: March 16, 2022
 * Name: BPScriptManager
 * Description: Apex class for all scripts executed after package installation
**/
global without sharing class BPScriptManager implements Callable {
    
    global static void createCustomerDepositsSpecialCategory() {
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Category__c> defaultCategoryList = [SELECT Id, Type__c FROM Category__c WHERE Default__c = true AND Active__c = true AND Type__c = 'Customer Deposits'];
        
        if(defaultCategoryList.size() == 0) {
            DMLUtility.insertSobjectList('Category__c', new Category__c(Name = 'Customer Deposits Default', Description__c = 'Customer Deposits Default',
                                    Type__c = 'Customer Deposits', Default__c = true, Active__c = true, 
                                                                        Income_GL__c = Accounting_Default_Accounts__c.getOrgDefaults().Customer_Deposits__c));
        }
    }

    global static void executePopulatePartTypeFieldOnPartV2Batch() {
        Database.executeBatch(new PopulatePartTypeFieldOnPartV2Batch());
    }
    
    global static void executePopulateClaimJobsDetailsBatch() {
        Database.executeBatch(new PopulateClaimJobsDetailsBatch(), 20);
    }

    global static void executePopulateSOCommitControlsBatch() {
        Database.executeBatch(new PopulateSOCommitControlsBatch(), 50);
    }
    
    global static void executePopulateTempUnitApplicableTaxBatch() {
        Database.executeBatch(new PopulateTempUnitApplicableTaxBatch());
    }
    
    global static void executePopulateVOGPkgSettingBatch() {
        Database.executeBatch(new PopulateVOGPkgSettingBatch());
    }

    global static void executePopulateBulkDiscountDefaultValueBatch() {
        Database.executeBatch(new PopulateBulkDiscountDefaultValueBatch(), 50);
    }

    global static void executeDeleteESSyncErrorLogBatch() {
        Database.executeBatch(new DeleteESSyncErrorLogBatch());
    }
    
    global static void executePopulateTextMsgFieldOnMsgHistoryBatch() {
        Database.executeBatch(new PopulateTextMsgFieldOnMsgHistoryBatch());
    }

    global static void executeUpdateVINNumberToUpperCaseBatch() {
        Database.executeBatch(new UpdateVINNumberToUpperCaseBatch());
    }

    global static void executePopulateLastSoldFieldOnPartBatch() {
        Database.executeBatch(new PopulateLastSoldFieldOnPartBatch());
    }
    
    global static void executePopulateDealOptionClearingAndStockTradeBatch() {
        Database.executeBatch(new PopulateDealOptionClearingAndStockTrade(), 50);
    }
    
    global static void executePopulateUnitCostOnConsignmentBatch() {
        Database.executeBatch(new PopulateUnitCostOnConsignmentBatch());
    }

    global static void executeSetPartHasFifoBucketFlagBatch() {
        Database.executeBatch(new SetPartHasFifoBucketFlagBatch());
    }
    
    global static void executePopulateCalculatedCustomerPriceBatch() {
        Database.executeBatch(new PopulateCalculatedCustomerPriceBatch(), 50);
    }
    
    global static void executeDeleteCOFormAttachmentsBatch() {
        Database.executeBatch(new DeleteCOFormAttachmentsBatch());
    }

    global static void executeUpdateSOLIShopSuppilesFieldBatch() {
        Database.executeBatch(new UpdateSOLIShopSuppilesFieldBatch());
    }

    global static void executeConvertTempUnitsIntoORDUUnitsBatch() {
        Database.executeBatch(new ConvertTempUnitsIntoORDUUnitsBatch(), 1);
    }

    global static void executeDP360SyncSoldUnitBatch() {
        if(DP360Service.isDP360Enabled()) {
            Database.executeBatch(new DP360SyncSoldUnitBatch(), 10);
        }
    }

    global static void schedulePopulateInvoiceARBalanceScheduler() {
        if(QBUtil.isQBEnabled() || XeroUtility.isXeroEnabled()) {
            PopulateInvoiceARBalanceBatchScheduler.executeScheduler();
        }
    }

	global static void enableHomePageDashboardPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Homepage_Dashboards__c' => 'Primary'}, true);
    }

    global static void disableAccSettingExportPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Accounting_settings_export__c' => 'None'}, false);
    }

    global static void enableReportAndWorkshopDashboardPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Reports__c' => 'Primary', 'Workshop_Dashboard__c' => 'Primary'}, true);
    }

    global static void enableReallocateOnOrderPartsPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Reallocate_On_Order_Parts__c' => 'Primary'}, true);
    }
	
    global static void enableApplyBulkDiscountsPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Apply_Bulk_Discounts__c' => 'Primary'}, true);
    }
	
	global static void enableJobReadyToInvoiceStatusPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Job_ready_to_invoice_status__c' => 'Primary'}, true);
    }
    
    global static void enableSpecificPermissionsForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'CO_profitability__c' => 'Primary', 
                                                                    'Deal_commissions__c' => 'Primary',
                                                                    'Adjust_store_credits__c' => 'Primary',
                                                                    'Approve_deals__c' => 'Primary'}, true);
    }

    global static void enableBulkDeletingPermissionForAdminGroup() {
        setSpecifiedPermissionForUserGroups(new Map<String, String>{'Bulk_deleting__c' => 'Primary'}, true, true);
    }

    global static void enableQuickTransfersPermissionsForAdminGroup() {
        setSpecifiedPermissionForUserGroups(new Map<String, String>{'Quick_transfers__c' => 'Primary'}, true, true);
    }

    global static void enableQuickFulfillDealOptionsPermissionsForAdminGroup() {
        setSpecifiedPermissionForUserGroups(new Map<String, String>{'Quick_Fulfill_Deal_Unit_Options__c' => 'Primary'}, true, true);
    }

    global static void enableReportSchedulingPermissionForAdminGroup() {
        setSpecifiedPermissionForUserGroups(new Map<String, String>{'Report_scheduling__c' => 'Primary'}, true, true);
    }

    global static void setAccountAdministrationPermissions() {
        Set<String> accountAdministrationPermissionsKeys = new Set<String>{'Accounting_settings_export__c', 'User_management__c', 
                                                            'Tax_management__c', 'App_settings__c', 'Linked_fees_forms__c', 'Locations_tags__c', 
                                                            'Make_model__c', 'Text_templates__c', 'Unit_pricing_options__c'};
        
        List<User_Group__c> userGroupList = [SELECT Id, System_Settings__c FROM User_Group__c];
        if(userGroupList.size() > 0) {
            for(User_Group__c userGroupRec : userGroupList) {
                for(String permAPIName : accountAdministrationPermissionsKeys) {
                    userGroupRec.put(permAPIName, userGroupRec.System_Settings__c);
                }
            }
            DMLUtility.updateSObjectList('User_Group__c', userGroupList);
        }
    }

    // isNewPermission - this flag is used to enable newly added permissions and used to avoid the permission overwirting.  
    global static void setSpecifiedPermissionForAllGroup(Map<String, String> permissionNameToValueMap, Boolean isNewPermission) {
        setSpecifiedPermissionForUserGroups(permissionNameToValueMap, isNewPermission, false);
    }
    
    global static void setSpecifiedPermissionForUserGroups(Map<String, String> permissionNameToValueMap, Boolean isNewPermission, Boolean isAdminGroupOnlyPermission) {
    	String query = 'SELECT Id FROM User_Group__c ';
        Boolean isWhereClause = false;
        if(isAdminGroupOnlyPermission) {
            query += ' Where Is_System_Created__c = true ';
            isWhereClause = true;
        }
    	if(permissionNameToValueMap != null && isNewPermission) {
	    	for(String permissionName : permissionNameToValueMap.keySet()) {
                if(isWhereClause) {
                    query += ' AND ' + permissionName + ' = null ';
                } else {
                    query += ' Where ' + permissionName + ' = null ';
                    isWhereClause = true;
                }
	    	}
    	}
    	List<User_Group__c> userGroupList = Database.query(query);
        if(userGroupList.size() > 0) {
            for(User_Group__c userGroupRec : userGroupList) {
                for(String permissionName : permissionNameToValueMap.keySet()) {
                    userGroupRec.put(permissionName, permissionNameToValueMap.get(permissionName));
                }
            }
            update userGroupList;
        }
    }

    global static void createIFWConfigAndConfigItemsForUniversalAPI() {
        UniversalAPIService.createIFWConfigAndConfigItemsForUniversalAPI(false);
    }

    global static void enableWebComponentSTA() {
        Configuration_List__c configListRec;
        Map<String, Configuration_List__c> configNameToRecMap = Configuration_List__c.getAll();
        if(configNameToRecMap.containsKey(GeneralConfiguration.ENABLE_WEB_COMPONENT_STA)) {
            configListRec = configNameToRecMap.get(GeneralConfiguration.ENABLE_WEB_COMPONENT_STA);
        } else {
            configListRec = new Configuration_List__c(Name = GeneralConfiguration.ENABLE_WEB_COMPONENT_STA);
        }
        configListRec.Value__c = 'true';
        DMLUtility.upsertSobjectList('Configuration_List__c', configListRec);
    }

    global static void populateCashDrawerOnCashRoundingPayments() {
        List<CO_Invoice_Payment__c> paymentList = SOQLUtility.getQueryResults('CO_Invoice_Payment__c', 'Select Id, Cash_Rounding_Payment__r.Cash_Drawer__c FROM CO_Invoice_Payment__c WHERE Payment_Method__c = \'Cash Rounding\' AND Cash_Drawer__c = null AND Cash_Rounding_Payment__r.Cash_Drawer__c != null');
        for(CO_Invoice_Payment__c paymentRec : paymentList) {
            paymentRec.Cash_Drawer__c = paymentRec.Cash_Rounding_Payment__r.Cash_Drawer__c;
        }
        DMLUtility.updateSObjectList('CO_Invoice_Payment__c', paymentList);
	}

    global static void createIFWConfigItemsForXeroUnappliedPayment() {
        if(IntegrationServiceFactory.getActiveAccountingIntegrationName() != XeroUtility.XERO) return;
        List<IFW_IntegrationConfig__c> ifwConfigList = [SELECT Id, (SELECT Id FROM IFW_IntegrationConfigItems__r WHERE Entity_Name__c IN ('Prepayment', 'Overpayment')) FROM IFW_IntegrationConfig__c WHERE Integration_Name__c =: XeroUtility.XERO AND Enabled__c = true];
        if(ifwConfigList.size() == 0) return;

        if(ifwConfigList[0].IFW_IntegrationConfigItems__r.size() > 0) DMLUtility.deleteSobjectList('IFW_IntegrationConfigItem__c', ifwConfigList[0].IFW_IntegrationConfigItems__r);

        List<IFW_IntegrationConfigItem__c> ifwItemListToInsert = new List<IFW_IntegrationConfigItem__c>();
        ifwItemListToInsert.add(new IFW_IntegrationConfigItem__c(Entity_Name__c = 'Prepayment', 
                                                                    Endpoint_URL__c = 'https://api.xero.com/api.xro/2.0/Prepayments', 
                                                                    IFW_IntegrationConfig__c = ifwConfigList[0].Id, 
                                                                    HTTP_Method__c = 'GET'));
        ifwItemListToInsert.add(new IFW_IntegrationConfigItem__c(Entity_Name__c = 'Overpayment', 
                                                                    Endpoint_URL__c = 'https://api.xero.com/api.xro/2.0/Overpayments', 
                                                                    IFW_IntegrationConfig__c = ifwConfigList[0].Id, 
                                                                    HTTP_Method__c = 'GET'));
        DMLUtility.insertSObjectList('IFW_IntegrationConfigItem__c', ifwItemListToInsert);
    }
    
    global static void assignBlackpurlPermissionToActiveUsers() {
        List<PermissionSet> bpPermissionList = [SELECT Id FROM PermissionSet WHERE Name = :Constants.BP_PERMISSION_SET_NAME];
        if(bpPermissionList.size() == 0) throw new BlackPurlException('Blackpurl Permissions Permission Set does not exists');

        String permissionSetId = bpPermissionList[0].Id;
        List<SObject> permissionSetAssList = new List<SObject>();
        List<User> userList = [SELECT Id, (SELECT Id FROM PermissionSetAssignments WHERE PermissionSetId = :permissionSetId) 
                                FROM User WHERE IsActive = true AND Profile.Name IN :Constants.allowedUserProfileNames];
        for(User userRec : userList) {
            if(userRec.PermissionSetAssignments.size() == 0) {
                sObject permissionSetAssignmentRec = Schema.getGlobalDescribe().get('PermissionSetAssignment').newSObject();
                permissionSetAssignmentRec.put('PermissionSetId', permissionSetId);
                permissionSetAssignmentRec.put('AssigneeId', userRec.Id);
                permissionSetAssList.add(permissionSetAssignmentRec);
            }
        }
        DMLUtility.insertSObjectList('PermissionSetAssignment', permissionSetAssList);
    }
    
    global static void createIFWConfigItemsForXeroCurrencies() {
        if(IntegrationServiceFactory.getActiveAccountingIntegrationName() != XeroUtility.XERO) return;
        List<IFW_IntegrationConfig__c> ifwConfigList = [SELECT Id, (SELECT Id FROM IFW_IntegrationConfigItems__r WHERE Entity_Name__c = :IntegrationUtility.CURRENCIES) FROM IFW_IntegrationConfig__c WHERE Integration_Name__c =: XeroUtility.XERO AND Enabled__c = true];
        if(ifwConfigList.size() == 0) return;

        if(ifwConfigList[0].IFW_IntegrationConfigItems__r.size() > 0) DMLUtility.deleteSobjectList('IFW_IntegrationConfigItem__c', ifwConfigList[0].IFW_IntegrationConfigItems__r);

        List<IFW_IntegrationConfigItem__c> ifwItemListToInsert = new List<IFW_IntegrationConfigItem__c>();
        ifwItemListToInsert.add(new IFW_IntegrationConfigItem__c(Entity_Name__c = 'Currencies', 
                                                                    Endpoint_URL__c = 'https://api.xero.com/api.xro/2.0/Currencies', 
                                                                    IFW_IntegrationConfig__c = ifwConfigList[0].Id, 
                                                                    HTTP_Method__c = 'GET'));
        DMLUtility.insertSObjectList('IFW_IntegrationConfigItem__c', ifwItemListToInsert);
    }

    global static void scheduleAccountingReconciliations() {
        if(String.isBlank(GeneralConfiguration.getConfigurationByName(GeneralConfiguration.ACCOUNTING_RECONCILIATION_EMAIL))) {
            insert new Configuration_List__c(
                Name = GeneralConfiguration.ACCOUNTING_RECONCILIATION_EMAIL,
                Value__c = 'activity@blackpurl.com'
            );
        }

        String jobName = ScheduleJobService.ACCOUNTING_RECONCILITAION;
        List<CronTrigger> alreadyScheduledJobs = [Select Id from CronTrigger where CronJobDetail.Name =: jobName];
        if(alreadyScheduledJobs.size() == 0) {
            ScheduleJobService.scheduleJob(jobName);
            ScheduleJobService.scheduleJob(ScheduleJobService.ACCOUNTING_RECONCILITAION_NOTIFICATION);
        }
    }

    global static void createMarkupDataForAPFMappings() {
        List<Price_File_Mapping__c> apfMappingList = [SELECT MSRP_Markup_Tier_1__c, MSRP_Markup_Tier_2__c, MSRP_Markup_Tier_3__c, 
            MSRP_Max_Markup_Amount_Tier_1__c, MSRP_Max_Markup_Amount_Tier_2__c, Retail_Markup_Tier_1__c, Retail_Markup_Tier_2__c, 
            Retail_Markup_Tier_3__c, Retail_Max_Markup_Amount_Tier_1__c, Retail_Max_Markup_Amount_Tier_2__c, Cost_Markup_Tier_1__c, 
            Cost_Markup_Tier_2__c, Cost_Markup_Tier_3__c, Cost_Max_Markup_Amount_Tier_1__c, Cost_Max_Markup_Amount_Tier_2__c 
            FROM Price_File_Mapping__c LIMIT :SOQLUtil.getAvailableQueryRowsLimit()];
        
        List<Escalator__c> escalatorList = new List<Escalator__c>();
        for(Price_File_Mapping__c apfMappingRec: apfMappingList) {
            escalatorList.add(getMarkupRecordForAPFMapping(EscalatorUtil.TYPE_MSRP, apfMappingRec));
            escalatorList.add(getMarkupRecordForAPFMapping(EscalatorUtil.TYPE_RETAIL, apfMappingRec));
            escalatorList.add(getMarkupRecordForAPFMapping(EscalatorUtil.TYPE_COST, apfMappingRec));
        }
        if(escalatorList.size() > 0) DMLUtility.insertSobjectList('Escalator__c', escalatorList);
    }

    global static void createMarkupDataForVendorControlledPricing() {
        List<Account> vendorList = [SELECT Id, Retail_Rate__c FROM Account 
            WHERE Is_Vendor__c = true AND Is_Calculate_Part_Retail_Price__c = true LIMIT :SOQLUtil.getAvailableQueryRowsLimit()];
        
        List<Escalator__c> escalatorList = new List<Escalator__c>();
        for(Account vendorRec: vendorList) {
            escalatorList.add(new Escalator__c(Vendor__c = vendorRec.Id, Type__c = EscalatorUtil.TYPE_RETAIL, Markup_1__c = vendorRec.Retail_Rate__c));
        }
        if(escalatorList.size() > 0) DMLUtility.insertSobjectList('Escalator__c', escalatorList);
    }

    global static void updateCategoryUniqueName() {
        List<Category__c> categoryRecordList = [SELECT Id, Unique_Category__c, Type__c, Name, availForQBSync__c, AccountingId__c, Active__c FROM Category__c];
        if(!categoryRecordList.isEmpty()){
            for(Category__c categoryRecord : categoryRecordList) {
                if(categoryRecord.Type__c == 'Sublet') {
                    categoryRecord.Type__c = 'Vendor Product';
                }
                categoryRecord.Unique_Category__c = categoryRecord.Type__c + '-' +categoryRecord.Name;
                if(String.isNotBlank(categoryRecord.AccountingId__c) && categoryRecord.Active__c) categoryRecord.availForQBSync__c = true;
            }
			CategoryTriggerHelper.runDefaultCheckBoxUpdate = false;
            DMLUtility.updateSObjectList('Category__c', categoryRecordList); 
            CategoryTriggerHelper.runDefaultCheckBoxUpdate = true;          
        }
    }

    global static void deleteTemplateCreatedAccReconciliationRecords() {
        List<CronTrigger> alreadyScheduledJobs = [SELECT Id, CreatedDate, CronJobDetail.Name FROM CronTrigger where CronJobDetail.Name = 'Accounting Reconciliation'];
        if(!alreadyScheduledJobs.isEmpty()) {
            List<Accounting_Reconciliation__c> accReconList = [Select Id From Accounting_Reconciliation__c Where CreatedDate <: alreadyScheduledJobs[0].CreatedDate];
            if(!accReconList.isEmpty()){
                DMLUtility.deleteSobjectList('Accounting_Reconciliation__c', accReconList);
            }
        }
    }

    global static void updateUnitIconTitleValueInConfigList() {
        String unitIconTitle = 'unit';
        AccessControl.checkObjectIsAccessible('Configuration_List__c');
        List<Configuration_List__c> configList = [SELECT Value__c FROM Configuration_List__c WHERE Name = :GeneralConfiguration.UNIT_ICON_TITLE LIMIT 1];
        if(configList.size() > 0) {
            configList[0].Value__c = unitIconTitle;
        } else {
            configList.add(new Configuration_List__c(Name = GeneralConfiguration.UNIT_ICON_TITLE, Value__c = unitIconTitle));
        }
        DMLUtility.upsertSobjectList('Configuration_List__c', configList);
    }
    
    global static void populateShopifyGoLiveDate() {
        Shopify_Configuration__c shopifyConfig = Shopify_Configuration__c.getOrgDefaults();
        if(shopifyConfig != null) {
            List<CO_Header__c> shopifyCOList = [SELECT Id, CreatedDate FROM CO_Header__c WHERE Shopify_ID__c != null Order by CreatedDate ASC LIMIT 1];
            if(shopifyCOList.isEmpty()) return; 
            shopifyConfig.Go_Live_Date__c = shopifyCOList[0].CreatedDate.date();
            DMLUtility.updateSObjectList('Shopify_Configuration__c', shopifyConfig);
        }
    }
    
    global static void createGEFileConfigRecsForBPExportFormats() {
        Set<String> existingBlackpurlFormatSet = new Set<String>();
        Map<String, String> BPExportFormatNameToOrderMap = new Map<String, String>{
                                                                                    'Generic (.csv)'	=>	'1',
                                                                                    'Parts Canada (.csv)'	=>	'2',
                                                                                    'HDnet Australia'	=>	'3',
                                                                                    'BossWeb'	=>	'4',
                                                                                    'KTM'	=>	'5',
                                                                                    'Honda eBiz'	=>	'6',
                                                                                    'Monza/Fox Australia'	=>	'7',
                                                                                    'Yamaha Canada'	=>	'8',
                                                                                    'Yamaha Australia'	=>	'9',
                                                                                    'American Honda'	=>	'10',
                                                                                    'Turn 14 (TRDOS)'	=>	'11'
                                                                                };
        for(GE_File_Config__c geFileConfigRec : [SELECT File_Name__c FROM GE_File_Config__c WHERE Blackpurl_Format__c = true]) {
            existingBlackpurlFormatSet.add(geFileConfigRec.File_Name__c);
        }
        List<GE_File_Config__c> fileConfigToInsertList = new List<GE_File_Config__c>();
        for(String exportName: BPExportFormatNameToOrderMap.keySet()) {
            if(!existingBlackpurlFormatSet.contains(exportName)) {
            GE_File_Config__c fileConfigRec = new GE_File_Config__c(File_Name__c = exportName,
                                                File_Content_Type__c = GenericExportUtil.NOT_APPLICABLE,
                                                File_Separator__c = GenericExportUtil.NOT_APPLICABLE,
                                                Object_API_Name__c = GenericExportUtil.NOT_APPLICABLE,
                                                Blackpurl_Format__c = true,
                Blackpurl_Format_Order_Number__c = Integer.valueOf(BPExportFormatNameToOrderMap.get(exportName)));
            fileConfigToInsertList.add(fileConfigRec);
        }
        }
        DMLUtility.insertSObjectList('GE_File_Config__c', fileConfigToInsertList);
    }

    global static void executePopulateIndividualTaxRateNameBatch() {
        Database.executeBatch(new PopulateIndividualTaxRateNameBatch());
    }
    
    global static void executePopulateTaxExemptionTypeBatch() {
        Database.executeBatch(new PopulateTaxExemptionTypeBatch());
    }
    
    global static void executeReportFilterCleanupBatch() {
        Database.executeBatch(new ReportFilterCleanupBatch());
    }

    global static void executeCreateIndividualTaxesUnderUPCBatch() {
        Database.executeBatch(new CreateIndividualTaxesUnderUPCBatch());
    }

    private static Escalator__c getMarkupRecordForAPFMapping(String typeValue, Price_File_Mapping__c apfMappingRec) {
        Escalator__c escalatorRec = new Escalator__c();
        escalatorRec.APF_Mapping__c = apfMappingRec.Id;
        escalatorRec.Type__c = typeValue;
        for(String fieldName: apfFieldNameToEscalatorFieldNameMap.keySet()) {
            escalatorRec.put(apfFieldNameToEscalatorFieldNameMap.get(fieldName) + '__c', apfMappingRec.get(typeValue + '_' + fieldName + '__c'));
        }
        return escalatorRec;
    }
    
    global static void enableIncludePricesOnPartLabels() {
    	Configurations__c configuration = Configurations__c.getOrgDefaults();
    	configuration.Include_Prices_On_Part_Labels__c = true;
        DMLUtility.upsertSobjectList('Configurations__c', configuration);
    }

    global static void populateCurrencyDetail() {
        new PopulateCurrencyDetail();
    }

    // This method update exitsting IFW details for the Xe.com if FX is enable otherwise delete the Xe.com IFW record
    global static void createIFWConfigAndConfigItemsForXE() {
        List<IFW_IntegrationConfig__c> ifwConfigList  = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Name__c' => ForeignExchangeUtil.integrationName});
        if(!ifwConfigList.isEmpty()) {
            if(GeneralConfiguration.getGeneralConfigurations().Enable_Foreign_Exchange_Costing__c && ifwConfigList[0].Username__c != ForeignExchangeUtil.xeAPIId) {
                ifwConfigList[0].username__c = ForeignExchangeUtil.xeAPIId;
                ifwConfigList[0].Password__c = ForeignExchangeUtil.xeAPIkey;
                DMLUtility.updateSObjectList('IFW_IntegrationConfig__c', ifwConfigList);
            } else {
                DMLUtility.deleteSobjectList('IFW_IntegrationConfig__c', ifwConfigList);
            }
        } 
    } 

    global static void scheduleFXCurrencyConversionScheduler() {
        //Fetch latest conversion rate from XE
        FXCurrencyConversionScheduler.getConversionRateFromXE();
        //Schedule currency conversion rate scheduler 
        ScheduleJobService.scheduleJobs(new Set<String>{ScheduleJobService.XE_CURRENCY_CONVERSION_SCH});
    } 

    global static void updateDefaultPartCostVariance() {
        Configurations__c configRec = Configurations__c.getOrgDefaults();
        configRec.Acceptable_Part_Cost_Variance__c = 50;
        DMLUtility.upsertSObjectList('Configurations__c', configRec);
    }

    global static void updateCurrentCostFlagOnPOTypes() {
        List<PO_Type__c> poTypeList = [SELECT Id FROM PO_Type__c];
        
        for(PO_Type__c poTypeRec: poTypeList) {
            poTypeRec.Update_Current_Cost__c = true;
        }
        DMLUtility.updateSObjectList('PO_Type__c', poTypeList);
    }

    global static void executeDealUnitOptionTaxedSelectionBatch() {
        Database.executeBatch(new DealUnitOptionTaxedSelectionBatch());
    }

    global static void setDefaultOptionTaxControls() {
        Configurations__c config = Configurations__c.getOrgDefaults();
        if(String.isBlank(config.Deal_Unit_Options_Taxed_Like_Unit__c)) {
            config.Deal_Unit_Options_Taxed_Like_Unit__c = DealUtil.UNIT_TAX_APPLICABLE_DEFAULT;
            update config;
        }
    }
    
    global static void schedulePartAgingScheduler() {
      BPUtility.abortAlreadyScheduleJobs('PartSyncAgeBatch_Schedular One Time');
      String CRON_EXP = BPUtility.getCronExpForGivenTime(1800); //Schedule after 30 mins of pkg installation
      system.schedule('PartSyncAgeBatch_Schedular One Time', CRON_EXP, new PartSyncAgeBatch_Schedular());
    }

    global static void createServiceJobStatuses() {
        if(Service_Job_Status__c.getAll().values().isEmpty()) {
            List<Service_Job_Status__c> soStatusInsertList = new List<Service_Job_Status__c>();
            Integer orderNumber = 1;
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.NEW_JOB, Order_Number__c = orderNumber, Is_Active__c = true, Is_Required__c = true));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.TRIAGE_REQUIRED, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = false));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.TRIAGE_DONE, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = false));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.CUSTOMER_TO_OK, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = false));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.CUSTOMER_APPROVED, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = false));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.READY_TO_START, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = true));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.IN_PROGRESS, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = true));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.WAIT_FOR_PARTS, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = false));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.PART_MGR_REVIEW, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = false));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.SERV_MGR_REVIEW, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = false));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.JOB_COMPLETE, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = true));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.READY_TO_INVOICE, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = false));
            soStatusInsertList.add(new Service_Job_Status__c(Name = ServiceJobUtil.INVOICED, Order_Number__c = ++orderNumber, Is_Active__c = true, Is_Required__c = true));
                
            DMLUtility.insertSobjectList('Service_Job_Status__c', soStatusInsertList);
        }
    }

    global static void executeUpdateServiceJobStatusBatch() {
        Database.executeBatch(new UpdateServiceJobStatusBatch());
    }

 	global static void updateLMAConfig() {
        LMA_Config__c lmaConfig = LMA_Config__c.getOrgDefaults();
        lmaConfig.End_Point__c = 'https://d41000000ldcjeaw.my.salesforce.com';
        DMLUtility.updateSobjectList('LMA_Config__c', lmaConfig);
    }

    //Deprecated
    global static void executeDFINProductCostFields() {}

    global static void executeDFINProductCostFieldsUpdateBatch() {
        Database.executeBatch(new DFINProductCostFieldsUpdateBatch());
    }

    global static void executeMissingVIVarianceJESyncBatch() {
        Database.executeBatch(new MissingVIVarianceJESyncBatch(), 25);
    }

    //Deprecated
    global static void executeDealAndDFINStatusUpdate() {}

    global static void executeDealAndDealFINStatusUpdateBatch() {
        Database.executeBatch(new DealAndDealFINStatusUpdateBatch());
    }

    global static void deleteQBIFWConfigForXeroEnableOrg() {
        String providerName = Accounting_Settings__c.getOrgDefaults().Provider_Name__c; 
        if(XeroUtility.isXeroEnabled() || (String.isNotBlank(providerName) && !providerName.containsIgnoreCase(QBUtil.QUICKBOOKS_ONLINE))) {
            List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(new Map<String, Object>{'Integration_Name__c' => QBUtil.QUICKBOOKS_ONLINE});
            if(ifwList.size() > 0) {
                DMLUtility.deleteSobjectList('IFW_IntegrationConfig__c', ifwList);
            } 
        }
    }
    
    global static void createUnitTradeInCategories() {}
 	global static void executeElasticSyncLogDeleteBatch() {}

	global static void mapUsersWithTechnicians() {
        Map<String, User> userIdToRecMap = new Map<String, User>([SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'Blackpurl']);
        UserService.mapUsersWithTechnicians(userIdToRecMap.keySet());
    }
    
    global static void resetBRPPasswords() {
        String namespace = [Select NamespacePrefix, Name, Id From ApexClass where Name = 'Constants'].NamespacePrefix;
        Map<String, List<String>> brpIFWNameToUNamePWordMap = new Map<String, List<String>>();
        if(String.isNotBlank(namespace) && namespace.equalsIgnoreCase('BlackPurlCore')) {
            brpIFWNameToUNamePWordMap = new Map<String, List<String>>{
                'BRP' => new List<String>{'BLACKPURL', '0z4aDe2dmAbaHZzqp9ZaR33hGcDlfkxx'},
                //'BRP OAuth2.0'=> new List<String>{'3MVG9PG9sFc71i9nECwhTwPw88sr1kAcjoMKU1KNrRsvwwboaePeNl23DL9esLIkIKq1kviHxZ36WN3_Zi3K8', '655CEFB829C45BC8EE45D367ED7906EB5DF9282EEA8266CB8EBABAB2103AE9BB'}, 
                'BRP DMS OAuth2.0'=> new List<String>{'0z4aDe2dmAbaHZzqp9ZaR33hGcDlfkxx', 'AtfonuIh28Q1HLYV'}
            };
        } else {
            brpIFWNameToUNamePWordMap = new Map<String, List<String>>{
                'BRP' => new List<String>{'BLACKPURL', 'K60mYH8mcbsYxxzKomIJTKt11uhGNwUz'},
                'BRP OAuth2.0'=> new List<String>{'3MVG9PG9sFc71i9nECwhTwPw88sr1kAcjoMKU1KNrRsvwwboaePeNl23DL9esLIkIKq1kviHxZ36WN3_Zi3K8', '655CEFB829C45BC8EE45D367ED7906EB5DF9282EEA8266CB8EBABAB2103AE9BB'}, 
                'BRP DMS OAuth2.0'=> new List<String>{'K60mYH8mcbsYxxzKomIJTKt11uhGNwUz', 'EQVTDmAWVNC3aP2K'}
            };
        }
        List<IFW_IntegrationConfig__c> ifwConfigUpdateList = [Select Id, Integration_Name__c FROM IFW_IntegrationConfig__c WHERE Integration_Name__c IN: brpIFWNameToUNamePWordMap.keyset()];
        for(IFW_IntegrationConfig__c ifwConfigRec : ifwConfigUpdateList) {
            if(ifwConfigRec.Integration_Name__c.equalsIgnoreCase('BRP')) {
                ifwConfigRec.Username__c = brpIFWNameToUNamePWordMap.get(ifwConfigRec.Integration_Name__c)[0];
                ifwConfigRec.Password__c = brpIFWNameToUNamePWordMap.get(ifwConfigRec.Integration_Name__c)[1];
            } else {
                ifwConfigRec.Client_Id__c = brpIFWNameToUNamePWordMap.get(ifwConfigRec.Integration_Name__c)[0];
                ifwConfigRec.Client_Secret__c = brpIFWNameToUNamePWordMap.get(ifwConfigRec.Integration_Name__c)[1];
            }
        }
        DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigUpdateList);
    }

    global static void populateCostMethodOnVendorProductAndFIProduct() {
        List<F_I_Product__c> FIProductListToUpdate = new List<F_I_Product__c>();
        List<Product__c> vendorProductListToUpdate = new List<Product__c>();
        for(Product__c vendorProduct : [SELECT id, Cost_Method__c, (SELECT Cost_Method__c FROM F_I_Products__r WHERE Cost_Method__c = null) FROM Product__c WHERE Cost_Method__c = null]) {
            vendorProduct.Cost_Method__c = 'Fixed Cost';
            for(F_I_Product__c FIProduct : vendorProduct.F_I_Products__r) {
                FIProduct.Cost_Method__c = 'Fixed Cost';
                FIProductListToUpdate.add(FIProduct);
            }
            vendorProductListToUpdate.add(vendorProduct);
        }
        DMLUtility.updateSobjectList('Product__c', vendorProductListToUpdate);
        DMLUtility.updateSobjectList('F_I_Product__c', FIProductListToUpdate);
    }

    global static void updateCOIPAmountToTwoDecimal() {
        List<CO_Invoice_Payment__c> coipList = [SELECT Id, Amount__c FROM CO_Invoice_Payment__c WHERE Amount__c != null AND CO_Invoice_Header__r.Invoice_Status__c = 'Active'];
        List<CO_Invoice_Payment__c> coipListUpdate = new List<CO_Invoice_Payment__c>();
        for(CO_Invoice_Payment__c coipRec : coipList) {
            if(coipRec.Amount__c != coipRec.Amount__c.setScale(2, RoundingMode.HALF_UP)) {
                coipRec.Amount__c = coipRec.Amount__c.setScale(2, RoundingMode.HALF_UP);
                coipListUpdate.add(coipRec);
            }
        }
        if(!coipListUpdate.isEmpty()) {
            DMLUtility.updateSobjectList('CO_Invoice_Payment__c', coipListUpdate);
        }
    }

    global static void updateCODepositAmountToTwoDecimal() {
        List<CO_Deposit__c> coDepositList = [SELECT Id, Amount__c FROM CO_Deposit__c WHERE Amount__c != null AND CO_Header__r.Order_status__c != 'Closed'];
        List<CO_Deposit__c> coDepositListUpdate = new List<CO_Deposit__c>();
        for(CO_Deposit__c coDepositRec : coDepositList) {
            if(coDepositRec.Amount__c != coDepositRec.Amount__c.setScale(2, RoundingMode.HALF_UP)) {
                coDepositRec.Amount__c = coDepositRec.Amount__c.setScale(2, RoundingMode.HALF_UP);
                coDepositListUpdate.add(coDepositRec);
            }
        }
        if(!coDepositListUpdate.isEmpty()) {
            DMLUtility.updateSobjectList('CO_Deposit__c', coDepositListUpdate);
        }
    }
    
    global static void PopulateStateFromAbbreviationBatch(){
        Database.executeBatch(new PopulateStateFromAbbreviationBatch(),50);
    } 
    
    global static void resyncClaimDeductibleInvoice() {
        List<SO_Payment_Role__c> soPaymentRoleList = [Select Id, Service_Order_Header__r.Invoice_Number__c From SO_Payment_Role__c where Status__c = 'Invoiced' AND Service_Order_Header__r.Invoice_Number__r.Xero_Accounting_Id__c != null AND RecordType.DeveloperName = 'Deductible' AND Service_Order_Header__r.Invoice_Number__r.Closed_Invoice_Date__c > 2023-05-28T00:00:00.000+0000];
        List<CO_Invoice_Header__c> invoiceList = new List<CO_Invoice_Header__c>();
        for(SO_Payment_Role__c soPaymentRoleRec : soPaymentRoleList) {
            invoiceList.add(new CO_Invoice_Header__c(Id = soPaymentRoleRec.Service_Order_Header__r.Invoice_Number__c, Available_For_Xero_Sync__c = true));
        }
        if(!invoiceList.isEmpty()) {
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', invoiceList);
        }
    }    
    global static void executeFeeCostSetToZeroBatch() {
        Database.executeBatch(new FeeCostSetToZeroBatch());
    }

    global static void executePopulateDealSalespersonBatch(){
        Database.executeBatch(new PopulateDealSalespersonBatch(), 50);
    }

    global static void executeSetHistoricalVendorCreditDataBatch() {
        Database.executeBatch(new SetHistoricalVendorCreditDataBatch(), 10);
    }

    global static void executePopulateDealItemReportFieldsBatch() {
        Database.executeBatch(new PopulateDealItemReportFieldsBatch());
    }

    global static void executePopulateCOSalespersonBatch(){
        Database.executeBatch(new PopulateCOSalespersonBatch(), 50);
    }

    global static void executeUpdateCOSalespersonBatch() { // to update all salespersons on COs
        Database.executeBatch(new UpdateCOSalespersonBatch(), 200);
    }

    global static void executeServiceJobLaborCostCalculation() {
        if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
            Database.executeBatch(new ServiceJobLaborCostCalculation(), 5);
        }
    }


    global static void executeDFINApprovedAmountFinancedBatch() {
        Database.executeBatch(new DFINApprovedAmountFinancedBatch());
    }

    global static void updateXeroShopifyIntegrityScript() {
        List<IFW_IntegrationConfig__c> ifwConfigList = BaseIntegration.getIFWConfigByName(new List<String>{ShopifyUtil.integrationName, XeroUtility.XERO});
        for(IFW_IntegrationConfig__c ifwRec: ifwConfigList) {
            if(ifwRec.Integration_Name__c == ShopifyUtil.integrationName && ifwRec.Accounting_Enabled__c == true) {
                List<CronTrigger> cornTriggerList = [Select Id, CronJobDetail.Name from CronTrigger where CronJobDetail.Name =: ScheduleJobService.INTEGRITY_CHECK_FOR_SHOPIFY];
                if(cornTriggerList.isEmpty()){ ScheduleJobService.scheduleJob(ScheduleJobService.INTEGRITY_CHECK_FOR_SHOPIFY); }
            } else if(ifwRec.Integration_Name__c == XeroUtility.XERO && ifwRec.Accounting_Enabled__c == true) {
                ScheduleJobService.rescheduleJobs(new Set<String>{ScheduleJobService.ACCOUNTING_INTEGRITY_CHECK_SCHEDULER});
            }
        }
    }
    
    global static void updateTechHoursMethodInConfig() {
        Configurations__c configurationRec = Configurations__c.getOrgDefaults();
    	configurationRec.Technician_Hours_Method_On_Jobs__c = 'Time-in/Time-out';
        DMLUtility.upsertSobjectList('Configurations__c', configurationRec);
    }

    global static void populateDealCOBuyerFromDFIN() {
        List<Deal__c> dealUpdateList = new List<Deal__c>();
        for(Deal_Finance__c dfinRec : [Select Id, Deal__c FROM Deal_Finance__c WHERE Deal__c != null AND Co_Buyer__c != null AND Deal__r.Co_Buyer__c = null]) {
            dealUpdateList.add(new Deal__c(Id = dfinRec.Deal__c, Co_Buyer__c = dfinRec.Co_Buyer__c));
        }
        DealTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal__c', dealUpdateList);
        DealTriggerHelper.isForceStopTrigger = false;
    }

    global static void executeCreateIndividualTaxOnDealBatch() {
        if(!GeneralConfiguration.getTaxIncludingPricing()) {
            Database.executeBatch(new CreateIndividualTaxOnDealBatch());
        }
    }

    global static void executePopulateMileageOnDealItemsBatch() {
        Database.executeBatch(new PopulateMileageOnDealItemsBatch());
    }

    global static void populateDealshipCountryInBPConfig() {
    	BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        bpConfig.Dealership_Country__c = null;
        for(Business_Profile__c businessProfilRec : [Select Business_Country__r.Name__c From Business_Profile__c LIMIT 1]) {
            bpConfig.Dealership_Country__c = businessProfilRec.Business_Country__r.Name__c;
        }
        upsert bpConfig;
    }
    global static void correctCountryData() {
        // Get countries details
        String unitedStateCountry = 'United States';
        String USACountry = 'USA';
        Set<String> countryNameSet = new Set<String>{USACountry, unitedStateCountry};
        Map<String, Country__c> countryNameToCountryRecMap = new Map<String, Country__c>();
        List<Country__c> countryList = [SELECT 	Id,Name__c,Default__c,Visible__c,Currency_Code__c,Active__c,Currency_Name__c,Currency_Symbol__c,Flag_Encoded__c,Conversion_Rate__c,Backward_Conversion_Rate__c ,Conversion_Rate_With_Markup__c FROM Country__c WHERE Name__c IN :countryNameSet LIMIT 2];
        for(Country__c countryRec : countryList) {
            countryNameToCountryRecMap.put(countryRec.Name__c, countryRec);
        }
        Savepoint sp = Database.setSavepoint();
        try {
            if(!countryList.IsEmpty()) {
                if(countryList.size() == 1 && countryNameToCountryRecMap.get(unitedStateCountry) != null) { // Check if Only United States name country present 
                    // update united state to USA and update all vendor/customers 
                    countryNameToCountryRecMap.get(unitedStateCountry).Name__c = USACountry;
                    DMLUtility.updateSobjectList('Country__c', countryNameToCountryRecMap.get(unitedStateCountry));
                    updateCountryOnCustomerVendor(unitedStateCountry, countryNameToCountryRecMap.get(unitedStateCountry));
                } else if(countryList.size() == 2) {
                    // Update USA country with states and update all vendor/customers 
                    List<Country__c> countryListToUpdate = new List<Country__c>();
                    List<Country__c> countryListToDelete = new List<Country__c>();
                    Set<String> countryNameToUpdate = new Set<String>();
                    Set<String> countryNameToDelete = new Set<String>();
                    if(countryNameToCountryRecMap.get(USACountry) != null && countryNameToCountryRecMap.get(unitedStateCountry) != null && String.isNotBlank(countryNameToCountryRecMap.get(unitedStateCountry).Currency_Code__c)) {
                        countryNameToCountryRecMap.get(USACountry).Default__c = (countryNameToCountryRecMap.get(USACountry).Default__c == true ? true : countryNameToCountryRecMap.get(unitedStateCountry).Default__c);
                        countryNameToCountryRecMap.get(USACountry).Visible__c =  (countryNameToCountryRecMap.get(USACountry).Default__c == true ? true : countryNameToCountryRecMap.get(unitedStateCountry).Visible__c);
                        countryNameToCountryRecMap.get(USACountry).Currency_Code__c = countryNameToCountryRecMap.get(unitedStateCountry).Currency_Code__c;
                        countryNameToCountryRecMap.get(USACountry).Active__c = countryNameToCountryRecMap.get(unitedStateCountry).Active__c;
                        countryNameToCountryRecMap.get(USACountry).Currency_Name__c = countryNameToCountryRecMap.get(unitedStateCountry).Currency_Name__c;
                        countryNameToCountryRecMap.get(USACountry).Currency_Symbol__c = countryNameToCountryRecMap.get(unitedStateCountry).Currency_Symbol__c;
                        countryNameToCountryRecMap.get(USACountry).Flag_Encoded__c = countryNameToCountryRecMap.get(unitedStateCountry).Flag_Encoded__c;
                        countryNameToCountryRecMap.get(USACountry).Conversion_Rate__c = countryNameToCountryRecMap.get(unitedStateCountry).Conversion_Rate__c;                        
                        DMLUtility.updateSobjectList('Country__c', countryNameToCountryRecMap.get(USACountry));
                    }
                    updateCountryOnStates(countryNameToCountryRecMap.get(unitedStateCountry).Id, countryNameToCountryRecMap.get(USACountry).Id);
                    updateCountryOnCustomerVendor(unitedStateCountry, countryNameToCountryRecMap.get(USACountry));
                    // Delete United States Country 
                    if(countryNameToCountryRecMap.get(unitedStateCountry) != null)
                    DMLUtility.deleteSobjectList('Country__c', countryNameToCountryRecMap.get(unitedStateCountry));
                }
            }                        
        } catch (Exception e) {
            Database.rollback(sp);
        }
    }

    global static void updateBRPDealerAuthCredentials() {
        List<IFW_IntegrationConfig__c> ifwConfigList = BaseIntegration.getIFWConfigByName(new List<String>{BRPUtility.BRP_OAUTH2});
        AdminBRPConfigWrapper configObj = new AdminBRPConfigWrapper();
        for(IFW_IntegrationConfig__c ifwRec: ifwConfigList) {
            ifwRec.Client_Id__c = configObj.OAuth2ClientId;
            ifwRec.Client_Secret__c = configObj.OAuth2ClientSecret;
        }
        DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigList);
    }
    
    global static void enableSOSLSearch() {
        Configuration_List__c soslConfig;
        String soslConfigName = 'Perform SOSL';
        Map<String, Configuration_List__c> configNameToRecMap = Configuration_List__c.getAll();
        if(configNameToRecMap.containsKey(soslConfigName)) {
            soslConfig = configNameToRecMap.get(soslConfigName);
        } else {
            soslConfig = new Configuration_List__c(Name = soslConfigName);
        }
        soslConfig.Value__c = 'true';
        DMLUtility.upsertSobjectList('Configuration_List__c', soslConfig);
    }

    global static void enableDuplicateTabDetector() {
        Configuration_List__c configListRec;
        Map<String, Configuration_List__c> configNameToRecMap = Configuration_List__c.getAll();
        if(configNameToRecMap.containsKey(GeneralConfiguration.ENABLE_DUPLICATE_TAB_DETECTOR)) {
            configListRec = configNameToRecMap.get(GeneralConfiguration.ENABLE_DUPLICATE_TAB_DETECTOR);
        } else {
            configListRec = new Configuration_List__c(Name = GeneralConfiguration.ENABLE_DUPLICATE_TAB_DETECTOR);
        }
        configListRec.Value__c = 'true';
        DMLUtility.upsertSobjectList('Configuration_List__c', configListRec);
    }
    global static void enableReportScheduling() {
        upsertFeatureToggle(GeneralConfiguration.ENABLE_REPORT_SCHEDULING, 'true');
    }
    global static void enableNewGlobalSearch() {
        upsertFeatureToggle(GeneralConfiguration.ENABLE_NEW_GLOBAL_SEARCH, 'true');
    }

    global static void disableNewGlobalSearch() {
        upsertFeatureToggle(GeneralConfiguration.ENABLE_NEW_GLOBAL_SEARCH, 'false');
    }

    global static void setSOSLOnlyFeatureToggle() {
        Configuration_List__c config = setFeatureToggleConfig(GeneralConfiguration.SOSL_SEARCH_ONLY, 'false', true);
        DMLUtility.upsertSObjectList('Configuration_List__c', config);
    }

    global static void setSyncPublishFeedUnitToDP360Toggle() {
        Configuration_List__c config = setFeatureToggleConfig(GeneralConfiguration.SYNC_PUBLISH_IN_FEED_UNITS_TO_DP360, 'false', false);
        DMLUtility.upsertSObjectList('Configuration_List__c', config);
    }

    global static void enableSOSLOnlyFeatureToggle() {
        Configuration_List__c config = createNewFeatureToggleConfig(GeneralConfiguration.SOSL_SEARCH_ONLY, 'true', true);
        DMLUtility.upsertSObjectList('Configuration_List__c', config);
    }

    global static void rescheduleJobs(Set<String> jobNames) {
        ScheduleJobService.rescheduleJobs(jobNames);
    }

    global static void enableAllowCustomerServiceJobWithoutUnit() {
        Configurations__c configuration = Configurations__c.getOrgDefaults();
    	configuration.Allow_Customer_Service_Job_Without_Unit__c = true;
        DMLUtility.upsertSobjectList('Configurations__c', configuration);
    }

    global static void createGenericCOU() {
        List<Customer_Owned_Unit__c> existingGenericUnits = [Select Id FROM Customer_Owned_Unit__c WHERE Is_Generic_Unit__c = true AND Unit_Type__c = 'COU' LIMIT 1];
        if(existingGenericUnits.isEmpty()) {
            Customer_Owned_Unit__c cou = new Customer_Owned_Unit__c(Is_Generic_Unit__c = true);
            cou.Unit_Type__c = 'COU';
            cou.Status__c = 'Active';
            cou.VIN_Number__c = 'No unit';
            insert cou;
        }
    }


    global static void updatePaymentMethodSurchargeDetails() {
        Set<String> paymentMethodsWithSurchargeSet = new Set<String>{'Visa', 'Mastercard', 'Amex', 'Discover'};
        List<Payment_Method__c> paymentMethodConfigList = [SELECT Id FROM Payment_Method__c WHERE Name IN: paymentMethodsWithSurchargeSet];
        paymentMethodConfigList.add(new Payment_Method__c(Name = AccountSettingService.INTEGRATED_PAYMENT_PROCESSOR, Is_Surcharge_Applicable__c = true));
        for(Payment_Method__c paymentMethodRec: paymentMethodConfigList) {
            paymentMethodRec.Is_Surcharge_Applicable__c = true;
        }
        DMLUtility.upsertSobjectList('Payment_Method__c', paymentMethodConfigList);
    }

    global static void enablePaymentSurchargePermissionForAllGroups() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Modify_payment_method_surcharge__c' => 'Primary'}, true);
    }

    global static void enableCreateMakeModelAdhocPermForAllGroups() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Create_Make_Model_Adhoc__c' => 'Primary'}, true);
    }

    private static void upsertFeatureToggle(String toggleName, String toggleValue) {
        Configuration_List__c featureToggleConfig;
        Map<String, Configuration_List__c> configNameToRecMap = Configuration_List__c.getAll();
        if(configNameToRecMap.containsKey(toggleName)) {
            featureToggleConfig = configNameToRecMap.get(toggleName);
        } else {
            featureToggleConfig = new Configuration_List__c(Name = toggleName);
        }
        featureToggleConfig.Value__c = toggleValue;
        DMLUtility.upsertSobjectList('Configuration_List__c', featureToggleConfig);
    }
    
    private static void updateCountryOnCustomerVendor(String oldCountry, Country__c newCountry) {
        List<Account> accountList = [SELECT Country__c, BillingCountry, ShippingCountry FROM Account WHERE Country__c = :oldCountry OR BillingCountry = :oldCountry OR ShippingCountry = :oldCountry];
        for(Account accRec : accountList) {
            if(accRec.Country__c != null) accRec.Country__c = newCountry.Id;
            if(accRec.BillingCountry != null) accRec.BillingCountry = newCountry.Name__c;
            if(accRec.ShippingCountry != null) accRec.ShippingCountry = newCountry.Name__c;
        }
        BPScriptUtility.disbaleTrigger('CustomerTrigger');
        DMLUtility.updateSobjectList('Account', accountList);
        BPScriptUtility.enableTrigger('CustomerTrigger');
    }

    private static void updateCountryOnStates(String oldCountryId, String newCountryId) {
        List<State__c> stateList = [SELECT Country__c FROM State__c WHERE Country__c = :oldCountryId];
        for(State__c stateRec : stateList) {
            stateRec.Country__c = newCountryId;
        }
        DMLUtility.updateSobjectList('State__c', stateList);
    }

    global static void updateDefTaxOnClaimDeductibleInConfig() {
        Configurations__c configurationRec = Configurations__c.getOrgDefaults();
    	configurationRec.Default_Tax_on_Claim_Deductibles__c = configurationRec.Default_Tax_on_Labor__c;
        DMLUtility.upsertSobjectList('Configurations__c', configurationRec);
    }

    global static void populateSOWorkStatusToNonBlank() {
        List<Service_Order_Header__c> soList = [SELECT Invoice_Number__c FROM Service_Order_Header__c WHERE SO_Status_Ref__c = null];
    	for(Service_Order_Header__c soRec : soList) {
            String status = soRec.Invoice_Number__c != null ? ServiceJobUtil.INVOICED : ServiceJobUtil.NEW_JOB;
            soRec.SO_Status_Ref__c = ServiceJobUtil.getSOStatusConfigByName(status).Id;
        }
        SOTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soList);
        SOTriggerHelper.isForceStopTrigger = false;
    }
    
    global static void scheduleArchiveDeleteCOBatch() {
        ScheduleJobService.scheduleJob(ScheduleJobService.ARCHIVE_DELETE_QUOTE_CO_SCHEDULER);
    }

    global static void scheduleIncorrectCommittedPartsBatch() {
        ScheduleJobService.scheduleJob(ScheduleJobService.INCORRECT_COMMITTED_PARTS_ALERT);
    }

    global static void updateSOMConfig() {
        List<SOM_Configuration__c> somConfigList = [SELECT Id FROM SOM_Configuration__c];
        if(!somConfigList.isEmpty()) {
            somConfigList[0].Upload_Directory__c = '/bp_uploads';
            somConfigList[0].Username__c = null;
            somConfigList[0].Password__c = null;
            DMLUtility.updateSObjectList('SOM_Configuration__c', somConfigList);
        }
    }

    global static void setGeneralConfig(String fieldAPIName, String fieldValue) {
        SObject obj = GeneralConfiguration.getGeneralConfigurations();
        obj.put(fieldAPIName, fieldValue);
        upsert obj;
    }
    
    global static void setGeneralConfig(String fieldAPIName, Boolean fieldValue) {
        SObject obj = GeneralConfiguration.getGeneralConfigurations();
        obj.put(fieldAPIName, fieldValue);
        upsert obj;
    }
    
    global static void schedulePayrollAndJobClockingOffBatch() {
        ScheduleJobService.scheduleJob(ScheduleJobService.PAYROLL_JOB_CLOCKING_AUTO_CLOCK_OFF_SCHEDULER);
    }

    global static void executePopulateCreditsPendingOnRVOBatch() {
        Database.executeBatch(new PopulateCreditsPendingOnRVOBatch(), 20);
    }

    private static Map<String, String> apfFieldNameToEscalatorFieldNameMap = new Map<String, String>{
                                                                                                        'Markup_Tier_1' => 'Markup_1', 
                                                                                                        'Markup_Tier_2' => 'Markup_2', 
                                                                                                        'Markup_Tier_3' => 'Markup_3',
                                                                                                        'Max_Markup_Amount_Tier_1' => 'Max_Amount_1',
                                                                                                        'Max_Markup_Amount_Tier_2' => 'Max_Amount_2'
                                                                                                    };
    global static void updateFontNamesForPaymentMethodIcons() {
        Map<String, String> paymentMethodNameToFontNameMap = new Map<String, String>{
                                                                                        '/Icons/afterpay.svg' => 'afterpay',
                                                                                        '/Icons/amex.svg' => 'amex',
                                                                                        '/Icons/cash.svg' => 'cash',
                                                                                        '/Icons/cheque.svg' => 'cheque',
                                                                                        '/Icons/Debit-card.svg' => 'debitCard',
                                                                                        '/Icons/EFTPOS.svg' => 'eftpos',
                                                                                        '/Icons/EFTPOS.svg' => 'eftpos',
                                                                                        '/Icons/gift-card.svg' => 'giftCard',
                                                                                        '/Icons/master-card.svg' => 'mastercard',
                                                                                        '/Icons/paypal.svg' => 'paypal',
                                                                                        '/Icons/EFTPOS.svg' => 'eftpos',
                                                                                        '/Icons/visa.svg' => 'visa',
                                                                                        '/Icons/EFTPOS.svg' => 'eftpos'
                                                                                    };
        List<Payment_Method__c> paymentMethodConfigList = [SELECT Id, Icon_Link__c FROM Payment_Method__c WHERE Icon_Link__c != null];
        for(Payment_Method__c paymentMethodRec: paymentMethodConfigList) {
            if(paymentMethodNameToFontNameMap.containsKey(paymentMethodRec.Icon_Link__c)) {
                paymentMethodRec.Icon_Link__c = paymentMethodNameToFontNameMap.get(paymentMethodRec.Icon_Link__c);
            }
        }
        DMLUtility.upsertSobjectList('Payment_Method__c', paymentMethodConfigList);
    }

    global static void createQBIFWConfigAndLineItems(Boolean isCreateNewIFW, Boolean isEnableQB) {
        List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(new Map<String, Object>{'Integration_Name__c' => QBUtil.QUICKBOOKS_ONLINE});
        List<IFW_IntegrationConfig__c> ifwConfigUpsertList = new List<IFW_IntegrationConfig__c>();
        List<IFW_IntegrationConfigItem__c> ifwConfigItemUpsertList = new List<IFW_IntegrationConfigItem__c>();
        if(ifwList.size() > 0) {
            ifwConfigUpsertList = ifwList;
            DMLUtility.deleteSobjectList('IFW_IntegrationConfigItem__c', ifwList[0].IFW_IntegrationConfigItems__r);
        } else if(isCreateNewIFW){
            ifwConfigUpsertList.add(new IFW_IntegrationConfig__c());
        }
        if(ifwConfigUpsertList.size() > 0) {
            ifwConfigUpsertList[0].Integration_Name__c = QBUtil.QUICKBOOKS_ONLINE;
            ifwConfigUpsertList[0].Client_Id_Long__c = QBUtil.isQBOSanboxEnvironment() ? 'ABPTXol7NDilGVo1GVCY3RusF96JL2HJscpNyuXA14KC5sRDpP' : 
                                                        'ABdfWqeFxNNHB9sTTagIfDPpgx9dLbb4e8M8lofmNrUVXhMEfM';
            ifwConfigUpsertList[0].Client_Secret_Long__c = QBUtil.isQBOSanboxEnvironment() ? 'QFST1LEekgM70Mg0cTiWHxl1631PBFa43lIKKC1K' : 
                                                            'NszYmCR4VxhlmBgirs8ux07qLBZJtgDoD3YPbKr9';
            ifwConfigUpsertList[0].Enabled__c = isEnableQB;
            ifwConfigUpsertList[0].Auth_Scheme__c = 'OAuth2.0';
            ifwConfigUpsertList[0].Integration_Type__c = 'Accounting';
            ifwConfigUpsertList = DMLUtility.upsertSobjectList('IFW_IntegrationConfig__c', ifwConfigUpsertList);
            if(ifwConfigUpsertList.size() > 0) {
                string endpointURL = QBUtil.isQBOSanboxEnvironment() ? QBUtil.SANDBOX_END_POINT_URL : QBUtil.PRODUCTION_END_POINT_URL;
                endpointURL = endpointURL + '{{company_id}}';
                for(String entityName : QBUtil.entityNameToEntityMap.keySet()) {
                    IFW_IntegrationConfigItem__c ifwItemRec = new IFW_IntegrationConfigItem__c();
                    ifwItemRec.IFW_IntegrationConfig__c = ifwConfigUpsertList[0].Id;
                    if(QBUtil.entityNameToEntityActionMap.containsKey(QBUtil.entityNameToEntityMap.get(entityName))){
                        ifwItemRec.Entity_Action__c = QBUtil.entityNameToEntityActionMap.get(QBUtil.entityNameToEntityMap.get(entityName));
                        ifwItemRec.Endpoint_URL__c = endpointURL;
                        if(entityName == 'Company Info') {
                            ifwItemRec.HTTP_Method__c = 'GET';
                        } else {
                            ifwItemRec.Entity_Name__c = entityName;
                            ifwItemRec.HTTP_Method__c = 'POST';
                            ifwItemRec.Endpoint_URL__c += ('/' + QBUtil.entityNameToEntityMap.get(entityName));
                        }
                    }
                    ifwConfigItemUpsertList.add(ifwItemRec);
                }
            }
            DMLUtility.upsertSobjectList('IFW_IntegrationConfigItem__c', ifwConfigItemUpsertList);
        }
    }

    global static void executePopulatePreTaxInvoiceTotalBatch() {
        Database.executeBatch(new PopulatePreTaxInvoiceTotalBatch('2023-04-21T00:00:00.000+0000'),20);
    }
    
    global static void runPopulatePreTaxInvoiceTotalBatch_V2() {
        executePopulatePreTaxInvoiceTotalBatch();
    }

    global static void executeDealProfitabilityBatch() {
        Database.executeBatch(new DealProfitabilityBatch(), 1);
    }

    //Create but not override feature toggle record value if already exists
    private static Configuration_List__c setFeatureToggleConfig(String featureName, String value, Boolean isVisibleOnAdminScreen) {
        Map<String, Configuration_List__c> existingFeatureConfigMap = Configuration_List__c.getAll();
        Configuration_List__c config = new Configuration_List__c(Name = featureName);
        if(existingFeatureConfigMap.containsKey(featureName)) {
            config = existingFeatureConfigMap.get(featureName);
        } else {
            config.Value__c = value;
        }
        config.Visible_on_Admin_Screen__c = isVisibleOnAdminScreen;
        return config;
    }
    
    public static Configuration_List__c createNewFeatureToggleConfig(String featureName, String value, Boolean isVisibleOnAdminScreen) {
        Map<String, Configuration_List__c> existingFeatureConfigMap = Configuration_List__c.getAll();
        Configuration_List__c config = new Configuration_List__c(Name = featureName);
        if(existingFeatureConfigMap.containsKey(featureName)) {
            config = existingFeatureConfigMap.get(featureName);
        }
        config.Value__c = value;
        config.Visible_on_Admin_Screen__c = isVisibleOnAdminScreen;
        return config;
    }  

    global static void executeORDUAndUPCTaxableCostBatch() {
        Database.executeBatch(new ORDUAndUPCTaxableCostBatch());
    }

    global static void createFeatureToggleConfig() {
        Set<String> allFeatureNameSet = new Set<String>{
            GeneralConfiguration.ENABLE_DUPLICATE_TAB_DETECTOR,
            GeneralConfiguration.ENABLE_NEW_GLOBAL_SEARCH,
            GeneralConfiguration.ENABLE_REPORT_SCHEDULING,
            GeneralConfiguration.ENABLE_WEB_COMPONENT_STA,
            GeneralConfiguration.ENABLE_SOSL_SEARCH
        };
        Map<String, Configuration_List__c> existingFeatureConfigMap = Configuration_List__c.getAll();
        
        List<Configuration_List__c> configUpdateList = new List<Configuration_List__c>();
        for(String featureName : allFeatureNameSet) {
            Configuration_List__c config = new Configuration_List__c(Name = featureName, Value__c = 'false');
            if(existingFeatureConfigMap.containsKey(featureName)) {
                config = existingFeatureConfigMap.get(featureName);
            }
            config.Visible_on_Admin_Screen__c = true;
            configUpdateList.add(config);
        }
        upsert configUpdateList;
    }

    global static void createSOStatusRecordsAndPopulateOnSO() {}

    global static void executeServiceJobStatusUpdateBatch() {
        List<SO_Status__c> existingSOStatusList = [Select Id FROM SO_Status__c LIMIT 1];
        if(existingSOStatusList.isEmpty()) {
            List<SO_Status__c> soStatusRecInsertList = new List<SO_Status__c>();
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.Estimate, Short_Name__c = 'est', Order_No__c = 1, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-warm-grey-font', Background_Color__c = 'bp-white-ice'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.NEW_JOB, Short_Name__c = 'new', Order_No__c = 2, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-purpureus', Background_Color__c = 'bp-purple-light'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.TRIAGE_REQUIRED, Short_Name__c = 'triage', Order_No__c = 3, Is_Active__c = true, Text_Color__c = 'bp-red-font', Background_Color__c = 'bp-light-moss-green'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.TRIAGE_DONE, Short_Name__c = 'triage', Order_No__c = 4, Is_Active__c = true, Text_Color__c = 'bp-purpureus', Background_Color__c = 'bp-light-moss-green'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.CUSTOMER_TO_OK, Short_Name__c = 'cust', Order_No__c = 5, Is_Active__c = true, Text_Color__c = 'bp-red-font', Background_Color__c = 'bp-light-steel-blue'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.CUSTOMER_APPROVED, Short_Name__c = 'cust', Order_No__c = 6, Is_Active__c = true, Text_Color__c = 'bp-charcoal', Background_Color__c = 'bp-light-steel-blue'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.READY_TO_START, Short_Name__c = 'ready', Order_No__c = 7, Is_Active__c = true, Text_Color__c = 'bp-light-sea-green', Background_Color__c = 'bp-cyan-light'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.IN_PROGRESS, Short_Name__c = 'prog', Order_No__c = 8, Is_Active__c = true, Text_Color__c = 'bp-orange-dark-font', Background_Color__c = 'bp-orange-light'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.WAIT_FOR_PARTS, Short_Name__c = 'wait', Order_No__c = 9, Is_Active__c = true, Text_Color__c = 'bp-black ', Background_Color__c = 'bp-vivid-tangerine'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.PART_MGR_REVIEW, Short_Name__c = 'review', Order_No__c = 10, Is_Active__c = true, Text_Color__c = 'bp-black ', Background_Color__c = 'bp-crayola'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.SERV_MGR_REVIEW, Short_Name__c = 'review', Order_No__c = 11, Is_Active__c = true, Text_Color__c = 'bp-black ', Background_Color__c = 'bp-crayola'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = 'Other', Short_Name__c = 'other', Order_No__c = 12, Text_Color__c = 'bp-black ', Background_Color__c = 'bp-crayola'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.JOB_COMPLETE, Short_Name__c = 'comp', Order_No__c = 13, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-red-font', Background_Color__c = 'bp-middle-yellow'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.READY_TO_INVOICE, Short_Name__c = 'toinv', Order_No__c = 14, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-red-font', Background_Color__c = 'bp-middle-yellow'));
            soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.INVOICED, Short_Name__c = 'inv', Order_No__c = 15, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-green-dark-font', Background_Color__c = 'bp-green-light'));
            
            DMLUtility.insertSobjectList('SO_Status__c', soStatusRecInsertList);
        }
        Database.executeBatch(new ServiceJobStatusUpdateBatch());
    }
    
    global static void updateFusionReportingRecords(){
        Map<Integer, Integer> newOrderNumToOldOrderNum = New Map<Integer, Integer>{ 1 => 1 ,
                                                                                            2 => 2 ,
                                                                                            3 => 3 ,
                                                                                            4 => 4 ,
                                                                                            5 => 5 ,
                                                                                            6 => 7 ,
                                                                                            7 => 6 ,
                                                                                            8 => 8 ,
                                                                                            9 => 9 ,
                                                                                            10 => 10 ,
                                                                                            11 => 12 ,
                                                                                            12 => 11 ,
                                                                                            13 => 14 ,
                                                                                            14 => 16 ,
                                                                                            15 => 17 ,
                                                                                            16 => 19 ,
                                                                                            19 => 13 ,
                                                                                            20 => 22 ,
                                                                                            21 => 24 ,
                                                                                            22 => 25 ,
                                                                                            23 => 27 ,
                                                                                            26 => 21 ,
                                                                                            27 => 30 ,
                                                                                            28 => 32 ,
                                                                                            29 => 33 ,
                                                                                            30 => 35 ,
                                                                                            33 => 29 ,
                                                                                            34 => 37 ,
                                                                                            35 => 38 ,
                                                                                            36 => 39 ,
                                                                                            37 => 40 ,
                                                                                            38 => 41 ,
                                                                                            39 => 42 ,
                                                                                            41 => 43 ,
                                                                                            42 => 44 ,
                                                                                            43 => 51 ,
                                                                                            47 => 52 ,
                                                                                            48 => 53 ,
                                                                                            50 => 56 ,
                                                                                            54 => 57 ,
                                                                                            58 => 58 ,
                                                                                            59 => 59 ,
                                                                                            60 => 60 ,
                                                                                            61 => 62 ,
                                                                                            65 => 63 ,
                                                                                            66 => 64 ,
                                                                                            67 => 65 ,
                                                                                            68 => 66 ,
                                                                                            69 => 67 ,
                                                                                            70 => 68 ,
                                                                                            71 => 69 ,
                                                                                            72 => 70 ,
                                                                                            73 => 71 ,
                                                                                            74 => 72 ,
                                                                                            75 => 73 ,
                                                                                            76 => 74 ,
                                                                                            77 => 75 ,
                                                                                            78 => 76 ,
                                                                                            79 => 77 ,
                                                                                            80 => 78 ,
                                                                                            81 => 45 ,
                                                                                            82 => 46 ,
                                                                                            83 => 47 ,
                                                                                            84 => 48 ,
                                                                                            85 => 49 ,
                                                                                            86 => 50
                                                                                            };
        List<Fusion_Report_Line_Item__c> oldFusionReportLineItemList = [SELECT Id, Order_Number__c FROM Fusion_Report_Line_Item__c WHERE Id != null];
        if(oldFusionReportLineItemList != null && !oldFusionReportLineItemList.isEmpty() && oldFusionReportLineItemList.size() == 78) {
            List<Fusion_Report_Line_Item__c> newFusionReportLineItemList = new FusionBenchMarking().insertLineItems(false);
            Map<Integer, String> oldOrderNumToFRLTIdMap = new Map<Integer, String>();

            for(Fusion_Report_Line_Item__c fusionLineItemRec : oldFusionReportLineItemList) {
                oldOrderNumToFRLTIdMap.put(Integer.valueOf(fusionLineItemRec.Order_Number__c), fusionLineItemRec.Id);  
            }

            for(Fusion_Report_Line_Item__c fusionLineItemRec : newFusionReportLineItemList) {
                if(newOrderNumToOldOrderNum.containsKey(Integer.valueOf(fusionLineItemRec.Order_Number__c))) {
                    fusionLineItemRec.Id = oldOrderNumToFRLTIdMap.containsKey(newOrderNumToOldOrderNum.get(Integer.valueOf(fusionLineItemRec.Order_Number__c))) ? oldOrderNumToFRLTIdMap.get(newOrderNumToOldOrderNum.get(Integer.valueOf(fusionLineItemRec.Order_Number__c))) : null;
                }
            }
            
            List<Fusion_Report_Line_Item__c> deleteableFusionReportLineList = [SELECT Id FROM Fusion_Report_Line_Item__c WHERE Order_Number__c Not IN :newOrderNumToOldOrderNum.values()];
            if(deleteableFusionReportLineList != null && !deleteableFusionReportLineList.isEmpty()) {
                DMLUtility.deleteSobjectList('Fusion_Report_Line_Item__c', deleteableFusionReportLineList);
            }
            DMLUtility.upsertSObjectList('Fusion_Report_Line_Item__c', newFusionReportLineItemList);
        }
    }

    global static void executeConvertUnitAttachmentsToFilesBatch() {
        Database.executeBatch(new ConvertUnitAttachmentsToFilesBatch(), 1);
    }
    global static void executeUpdateDefaultProductTypeOnUnitsBatch() {
        Database.executeBatch(new UpdateDefaultProductTypeOnUnitsBatch());
    }

    global static String createDefaultUnitProductType() {
        List<Unit_Product_Type__c> unitProductTypeList = [SELECT Id FROM Unit_Product_Type__c WHERE Name__c = :UnitProductTypeService.GENERIC LIMIT 1];
        Unit_Product_Type__c unitProductTypeRec;
        if(unitProductTypeList.isEmpty()) {
            unitProductTypeRec = new Unit_Product_Type__c(Name__c = UnitProductTypeService.GENERIC, Default__c = true, Active__c = true);
            DMLUtility.insertSobjectList('Unit_Product_Type__c', unitProductTypeRec);
        } else {
            unitProductTypeRec = unitProductTypeList[0];
        }

        List<Unit_Product_Type_Field__c> uptfList = [SELECT Id FROM Unit_Product_Type_Field__c WHERE Unit_Product_Type__r.Name__c = 'Generic'];
        if(uptfList.isEmpty()) {
            setGeneralProductTypeFields(unitProductTypeRec.Id, uptfList);
            setWeigthDimensionProductTypeFields(unitProductTypeRec.Id, uptfList);
            setPowerWheelsProductTypeFields(unitProductTypeRec.Id, uptfList);
            setConstructionProductTypeFields(unitProductTypeRec.Id, uptfList);
            setOtherSpecsProductTypeFields(unitProductTypeRec.Id, uptfList);
            setMiscellaneousProductTypeFields(unitProductTypeRec.Id, uptfList);
            DMLUtility.insertSobjectList('Unit_Product_Type_Field__c', uptfList);
        }
        return unitProductTypeRec.Id;
    }

    // General & Identification - 21
    private static void setGeneralProductTypeFields(String unitProductTypeRecId, List<Unit_Product_Type_Field__c> uptfList) {
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Color exterior', true, true, true, true, 'General & Identification', 1, 'Colour__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Color interior', true, false, false, true, 'General & Identification', 2, 'Interior_Colour__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Compliance date', true, false, false, false, 'General & Identification', 3, 'Compliance_Date__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Description long', false, false, false, false, 'General & Identification', 4, 'Description_Long__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Description short', false, false, false, false, 'General & Identification', 5, 'Description_Short__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Feed category', false, false, false, false, 'General & Identification', 6, 'Feed_Category__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Feed subcategory', false, false, false, false, 'General & Identification', 7, 'Feed_SubCategory__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Hours', false, false, false, false, 'General & Identification', 8, 'Hours__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Manufactured date', true, false, false, false, 'General & Identification', 9, 'Manufactured_Date__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Mileage', true, true, true, false, 'General & Identification', 10, 'Mileage__c')); // Mileage__c/Mileage_Value__c
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Mileage type', true, true, true, false, 'General & Identification', 11, 'Mileage_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Chassis#', false, false, false, false, 'General & Identification', 12, 'Chassis__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Engine serial#', true, true, true, false, 'General & Identification', 13, 'Engine_Serial_No__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Engine type', false, false, false, false, 'General & Identification', 14, 'Engine_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Key#', true, true, false, false, 'General & Identification', 15, 'Key_No__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Other serial#', true, true, false, false, 'General & Identification', 16, 'Other_Serial_No__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Plate expiry', true, false, true, false, 'General & Identification', 17, 'Reg_Expiry_Date__c')); // Reg_Expiry_Date__c
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Plate#', true, true, true, false, 'General & Identification', 18, 'Plate__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Registration serial#', true, false, false, false, 'General & Identification', 19, 'Registration_Serial__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit#', false, false, false, false, 'General & Identification', 20, 'Unit__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Year of 1st rego', true, false, false, false, 'General & Identification', 21, 'Year_Of_1st_Rego__c'));
        
    }

    // Weights & Dimensions - 14
    private static void setWeigthDimensionProductTypeFields(String unitProductTypeRecId, List<Unit_Product_Type_Field__c> uptfList) {
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'GVWR', false, false, false, false, 'Weights & Dimensions', 1, 'GVWR__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'GAWR', false, false, false, false, 'Weights & Dimensions', 2, 'GAWR__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Payload capacity', false, false, false, false, 'Weights & Dimensions', 3, 'Payload_Capacity__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Curb weight', false, false, false, false, 'Weights & Dimensions', 4, 'Curb_Weight__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Towing capacity', false, false, false, false, 'Weights & Dimensions', 5, 'Towing_Capacity__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Length', false, false, false, false, 'Weights & Dimensions', 6, 'Length__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Length overall', false, false, false, false, 'Weights & Dimensions', 7, 'Length_Overall__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Length interior', false, false, false, false, 'Weights & Dimensions', 8, 'Length_Interior__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Width', false, false, false, false, 'Weights & Dimensions', 9, 'Width__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Width overall', false, false, false, false, 'Weights & Dimensions', 10, 'Width_Overall__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Width interior', false, false, false, false, 'Weights & Dimensions', 11, 'Width_Interior__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Height', false, false, false, false, 'Weights & Dimensions', 12, 'Height__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Height interior', false, false, false, false, 'Weights & Dimensions', 13, 'Height_Interior__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Height deck', false, false, false, false, 'Weights & Dimensions', 14, 'Height_Deck__c'));
        
    }

    // Power & Wheels - 18
    private static void setPowerWheelsProductTypeFields(String unitProductTypeRecId, List<Unit_Product_Type_Field__c> uptfList) {
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Cylinders', true, false, false, true, 'Power & Wheels', 1, 'Cylinders__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Displacement', true, false, false, true, 'Power & Wheels', 2, 'Displacement__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Drivetrain', false, false, false, false, 'Power & Wheels', 3, 'Drivetrain__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Fuel type', false, false, false, false, 'Power & Wheels', 4, 'Fuel_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Gears', true, false, false, false, 'Power & Wheels', 5, 'Gears__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Power type', false, false, false, false, 'Power & Wheels', 6, 'Power_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Tire size', false, false, false, false, 'Power & Wheels', 7, 'Tire_Size__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Tire load range', false, false, false, false, 'Power & Wheels', 8, 'Tire_Load_Range__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Tire type', false, false, false, false, 'Power & Wheels', 9, 'Tire_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Wheel type', false, false, false, false, 'Power & Wheels', 10, 'Wheel_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Wheel base', false, false, false, false, 'Power & Wheels', 11, 'Wheel_Base__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Wheel box width', false, false, false, false, 'Power & Wheels', 12, 'Wheel_Box_Width__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Wheel box height', false, false, false, false, 'Power & Wheels', 13, 'Wheel_Box_Height__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Axle quantity', false, false, false, false, 'Power & Wheels', 14, 'Axle_Quantity__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Axle type', false, false, false, false, 'Power & Wheels', 15, 'Axle_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Brakes', false, false, false, false, 'Power & Wheels', 16, 'Brakes__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Suspension', false, false, false, false, 'Power & Wheels', 17, 'Suspension__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Steering', false, false, false, false, 'Power & Wheels', 18, 'Steering__c'));

    }

    // Construction - 17
    private static void setConstructionProductTypeFields(String unitProductTypeRecId, List<Unit_Product_Type_Field__c> uptfList) {
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Body style', false, false, false, false, 'Construction', 1, 'Body_Style__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Frame', false, false, false, false, 'Construction', 2, 'Frame__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Sidewall liner', false, false, false, false, 'Construction', 3, 'Sidewall_Liner__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Floor decking', false, false, false, false, 'Construction', 4, 'Floor_Decking__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Tongue', false, false, false, false, 'Construction', 5, 'Tongue__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Roof type', false, false, false, false, 'Construction', 6, 'Roof_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Nose type', false, false, false, false, 'Construction', 7, 'Nose_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Pull type', false, false, false, false, 'Construction', 8, 'Pull_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Ramps', false, false, false, false, 'Construction', 9, 'Ramps__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Rear door type', false, false, false, false, 'Construction', 10, 'Rear_Door_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Rear door size', false, false, false, false, 'Construction', 11, 'Rear_Door_Size__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Front door type', false, false, false, false, 'Construction', 12, 'Front_Door_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Front door size', false, false, false, false, 'Construction', 13, 'Front_Door_Size__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Side door type', false, false, false, false, 'Construction', 14, 'Side_Door_Type__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Side door size', false, false, false, false, 'Construction', 15, 'Side_Door_Size__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Gate', false, false, false, false, 'Construction', 16, 'Gate__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Beavertail', false, false, false, false, 'Construction', 17, 'Beavertail__c'));

    }

    // Other specs - 14
    private static void setOtherSpecsProductTypeFields(String unitProductTypeRecId, List<Unit_Product_Type_Field__c> uptfList) {
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, '12v connection', false, false, false, false, 'Other specs', 1, 'X_12v_Connection__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Coupler size', false, false, false, false, 'Other specs', 2, 'Coupler_Size__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Coupler height', false, false, false, false, 'Other specs', 3, 'Coupler_Height__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Jack', false, false, false, false, 'Other specs', 4, 'Jack__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Fenders', false, false, false, false, 'Other specs', 5, 'Fenders__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Lights', false, false, false, false, 'Other specs', 6, 'Lights__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Hydraulics', false, false, false, false, 'Other specs', 7, 'Hydraulics__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Battery', false, false, false, false, 'Other specs', 8, 'Battery__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Tilt', false, false, false, false, 'Other specs', 9, 'Tilt__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Seating/capacity', false, false, false, false, 'Other specs', 10, 'Seating_Capacity__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Seat color', false, false, false, false, 'Other specs', 11, 'Seat_Color__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Windshield', false, false, false, false, 'Other specs', 12, 'Windshield__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Pull out', false, false, false, false, 'Other specs', 13, 'Pull_Out__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Track size', false, false, false, false, 'Other specs', 14, 'Track_Size__c'));

    }

    // Miscellaneous - 15
    private static void setMiscellaneousProductTypeFields(String unitProductTypeRecId, List<Unit_Product_Type_Field__c> uptfList) {
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 01', true, true, false, true, 'Miscellaneous', 1, 'Unit_Data_01__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 02', true, true, false, true, 'Miscellaneous', 2, 'Unit_Data_02__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 03', true, true, false, true, 'Miscellaneous', 3, 'Unit_Data_03__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 04', true, true, false, true, 'Miscellaneous', 4, 'Unit_Data_04__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 05', true, true, false, true, 'Miscellaneous', 5, 'Unit_Data_05__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 06', true, true, false, true, 'Miscellaneous', 6, 'Unit_Data_06__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 07', true, true, false, true, 'Miscellaneous', 7, 'Unit_Data_07__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 08', true, true, false, true, 'Miscellaneous', 8, 'Unit_Data_08__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 09', true, true, false, true, 'Miscellaneous', 9, 'Unit_Data_09__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 10', true, true, false, true, 'Miscellaneous', 10, 'Unit_Data_10__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 11', true, true, false, true, 'Miscellaneous', 11, 'Unit_Data_11__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 12', true, true, false, true, 'Miscellaneous', 12, 'Unit_Data_12__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 13', true, true, false, true, 'Miscellaneous', 13, 'Unit_Data_13__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 14', true, true, false, true, 'Miscellaneous', 14, 'Unit_Data_14__c'));
        uptfList.add(setUnitProductTypeFieldValues(unitProductTypeRecId, 'Unit Data 15', true, true, false, true, 'Miscellaneous', 15, 'Unit_Data_15__c'));

    }

    private static Unit_Product_Type_Field__c setUnitProductTypeFieldValues(String productTypeId, String name, Boolean isActive, 
                                                                                Boolean includeInSODoc, Boolean includeInDealDoc, 
                                                                                Boolean includeInUnitOrderDoc, String cateogry, 
                                                                                Integer orderNumber, String couAPIName) {
        return new Unit_Product_Type_Field__c(Unit_Product_Type__c = productTypeId, Name = name, Active__c = isActive, 
                                                Include_In_SO_Document__c = includeInSODoc, Include_In_Deal_Document__c = includeInDealDoc, 
                                                Include_In_Unit_Order_Document__c = includeInUnitOrderDoc, Category__c = cateogry, 
                                                Order__c = orderNumber, COU_API_Name__c = couAPIName);
    }

    global static void setTechnicianClockJobStatus() {
        List<SO_Status__c> soStatusList = [SELECT Id FROM SO_Status__c WHERE Name__c = 'In Progress' AND Is_Active__c = true LIMIT 1];
        for(SO_Status__c soStatus : soStatusList) {
            soStatus.Default_Clock_ON_Status__c = true;
        }
        DMLUtility.updateSObjectList('SO_Status__c', soStatusList);
    }

	global static void createKenectFeatureToggleConfig() {
        Configuration_List__c config = createNewFeatureToggleConfig(UniversalAPIUtility.featureToggleName, 'false', true);
        DMLUtility.upsertSObjectList('Configuration_List__c', config);
    }

    global static void createExcludeHeaderOnARIPartsmart10ToggleConfig() {
        Configuration_List__c config = createNewFeatureToggleConfig(GeneralConfiguration.EXCLUDE_HEADER_ON_ARI_PARTSMART10, 'false', true);
        DMLUtility.upsertSObjectList('Configuration_List__c', config);
    }

    
    global static void executePartQtyCommittedRecalculationBatch() {
        Database.executeBatch(new PartQtyCommittedRecalculationBatch(true));
    }
    
    global static void scheduleDeleteScheduler() {
        ScheduleJobService.scheduleJob(ScheduleJobService.DELETE_QUOTED_VOLI_SCHEDULER);
    }

    global static void executeCustomerVendorStateUpdateBatch() {
        DataLoadForCountryState.setStateCode();
        Database.executeBatch(new CustomerVendorStateUpdateBatch());
    }

    global static void updateLastModifiedFieldsOnHistoricalData() {
        BPTriggerHandler.getBlackpurlProfileId(); // This will update BP Profile Id in custom setting
        Database.executeBatch(new SetLastModifiedOnHistoricalDataBatch1(), 1);
    }
    
    global static void executeContactShippingDetailUpdateBatch() {
        Database.executeBatch(new ContactShippingDetailUpdateBatch());
    }

    global static void executeSKUDateStockedInBatch() {
        Database.executeBatch(new SKUDateStockedInBatch());
    }

    global static void executeUPCAdjustmentDateBatch() {
        Database.executeBatch(new UPCAdjustmentDateBatch());
    }
    
    global static void updateShopifyConfigForProSkuMappingField() {
        Shopify_Configuration__c config = Shopify_Configuration__c.getOrgDefaults();
        if(config != null && config.Id != null) {
            config.Product_Sku_Mapping_Field__c	= 'SKU_Number__c';
            DMLUtility.updateSobjectList('Shopify_Configuration__c', config);
        }
    }

    global static void updateCompanyLogoSizeInBusinessProfile() {
        String logoURL = GeneralConfiguration.getCompanyLogoUrl();
        List<Business_Profile__c> businessProfileList = [SELECT Id FROM Business_Profile__c WHERE Logo_Height__c = null OR Logo_Width__c = null];
        if(String.isBlank(logoURL) || businessProfileList.isEmpty()) return;
        PageReference page = new PageReference(logoURL);
        Blob imgdata = page.getContent();
        // Can't substring a blob, have to do the ugly and double the size as a hex string
        // When parsing the hex string, all offsets must be doubled, requiring *2 below
        string imgstring = EncodingUtil.convertToHex(imgdata);
        Integer imageWidth = 0;
        Integer imageHeight = 0;

        if(imgstring.substring(0,8) == '89504e47') {
            // PNG
            imageWidth = hexToInt(imgstring.substring(16*2,20*2));
            imageHeight = hexToInt(imgstring.substring(20*2,24*2));
        } else if(imgstring.substring(0,4) == 'ffd8') {
            // JPEG
            // Might need a lot of the imgstring, but don't want to pass it by value
            // due to limited heap space.  Instead, just parse it all here.
            imageWidth = 0;
            imageHeight = 0;
            integer offset = 2 *2; // Skip past the SOI marker that we already found
            while (offset < imgstring.length()) {
                if (imgstring.substring(offset, offset+3) == 'ffc') { // SOFn
                    imageHeight = hexToInt(imgstring.substring(offset+5*2, offset+7*2));
                    imageWidth = hexToInt(imgstring.substring(offset+7*2, offset+9*2));
                    break;
                } else if (imgstring.substring(offset, offset+2*2) == 'ffd8' // SOI (may appear after thumbnail)
                        || imgstring.substring(offset, offset+2*2) == 'ffd9' // EOF (maybe end of thumbnail, keep going)
                    ) {
                    offset += 2 *2;
                } else if (imgstring.substring(offset, offset+2) == 'ff') {
                    // Most blocks are variable length, find the length and skip it
                    integer blocklen = hexToInt(imgstring.substring(offset+4, offset+8));
                    offset += (blocklen+2) * 2;
                } else { // Not a header, either bad data or bad parsing, stop reading.
                    break;
                }
            }
        } else if (imgstring.substring(0, 8) == '47494638') {
            // GIF
            imageWidth = hexToInt(imgstring.substring(7*2,  8*2) + imgstring.substring(6*2, 7*2));
            imageHeight = hexToInt(imgstring.substring(9*2, 10*2) + imgstring.substring(8*2, 9*2));
        } else if (imgstring.substring(0, 8) == '52494646' && imgstring.substring(16,24) == '57454250') {
            // WebP
            integer offset = 12*2; // Skip past the RIFF header and WEBP identifier (already matched above)
            while (offset < imgstring.length()) {
                string chunk = imgstring.substring(offset, offset + 4*2);
                offset += 4*2;
                if (chunk == '56503820') {
                    // "VP8 " - lossy
                    // 16-bit unsigned, little endian, with 2 bits reserved.
                    imageWidth = hexToInt(imgstring.substring(offset+11*2, offset+12*2) + imgstring.substring(offset+10*2, offset+11*2)) & 16383;
                    imageHeight = hexToInt(imgstring.substring(offset+13*2, offset+14*2) + imgstring.substring(offset+12*2, offset+13*2)) & 16383;
                    break;
                } else if (chunk == '5650384c') {
                    // "VP8L" - lossless
                    // Horrible: https://developers.google.com/speed/webp/docs/webp_lossless_bitstream_specification
                    imageWidth = hexToInt(imgstring.substring(offset+5*2, offset+6*2)) + ((hexToInt(imgstring.substring(offset+6*2, offset+7*2)) & 63) << 8) + 1;
                    imageHeight = (hexToInt(imgstring.substring(offset+6*2, offset+7*2)) >> 6) + (hexToInt(imgstring.substring(offset+7*2, offset+8*2)) << 2) + ((hexToInt(imgstring.substring(offset+8*2, offset+9*2)) & 15) << 10) + 1;
                    break;
                } else if (chunk == '414e4d46') {
                    // "ANMF" - don't skip it, find the size of the 1st frame inside
                    offset += 20*2;
                } else {
                    // Skip all other chunks
                    integer chunklen = hexToInt(imgstring.substring(offset+3*2,offset+4*2) + imgstring.substring(offset+2*2,offset+3*2) + imgstring.substring(offset+1*2,offset+2*2) + imgstring.substring(offset,offset+1*2));
                    offset += (chunklen+4)*2;
                }
            }
        }

        Integer maxWidth = 350; // default value
        Integer maxHeight = 90; // default value
        Decimal logoWidth = maxWidth; // Decimal because after scaling it can be in decimal
        Decimal logoHeight = maxHeight; // Decimal because after scaling it can be in decimal
        Decimal scalingFactor = imageHeight == 0 ? 0 : ((Decimal)imagewidth/imageHeight).setScale(2);

        Integer diffWidth = imageWidth - maxWidth;
        Integer diffHeight = imageHeight - maxHeight;
        if(diffWidth > diffHeight) {
            logoWidth = maxWidth;     
            logoHeight = logoWidth/scalingFactor;
            if(logoHeight > maxHeight) {
                logoHeight = maxHeight;
                logoWidth = logoHeight*scalingFactor;
            }
        } else {
            logoHeight = maxHeight;     
            logoWidth = logoHeight*scalingFactor;
            if(logoWidth > maxWidth) {
                logoWidth = maxWidth;
                logoHeight = logoWidth/scalingFactor;
            }
        }

        businessProfileList[0].Logo_Width__c = logoWidth;
        businessProfileList[0].Logo_Height__c = logoHeight;
        DMLUtility.updateSObjectList('Business_Profile__c', businessProfileList);
    }

    private static final List<String> hex = '0123456789abcdef'.split('');
    private static Integer hexToInt(String str) {
        str = str.toLowerCase();
        String[] hexValue = str.split('');
        Integer retVal = 0;
        for(Integer i = 0; i < hexValue.size(); i++) {
            retVal = (retVal << 4) + hex.indexOf(hexValue[i]);
        }
        return retVal;
    }

    /**
     * Callable::call() implementation, calling static function
     * It is best to keep the naming consistent with the original method signature, no error checking is made for simplicity:
     * call() expects an object to be returned, null is returned for void function, other types can be used as needed:
     */
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'createCustomerDepositsSpecialCategory()' {
                createCustomerDepositsSpecialCategory();
                return null;
            }
            when 'executePopulatePartTypeFieldOnPartV2Batch()' {
                executePopulatePartTypeFieldOnPartV2Batch();
                return null;
            }
            when 'executeUpdateVINNumberToUpperCaseBatch()' {
                executeUpdateVINNumberToUpperCaseBatch();
                return null;
            }
            when 'disableAccSettingExportPermissionForAllGroup()' {
                disableAccSettingExportPermissionForAllGroup();
                return null;
            }
			when 'enableHomePageDashboardPermissionForAllGroup()' {
                enableHomePageDashboardPermissionForAllGroup();
                return null;
            }
            when 'enableReportAndWorkshopDashboardPermissionForAllGroup()' {
                enableReportAndWorkshopDashboardPermissionForAllGroup();
                return null;
            }
            when 'populateCashDrawerOnCashRoundingPayments()' {
                populateCashDrawerOnCashRoundingPayments();
                return null;
            }
            when 'scheduleAccountingReconciliations()' {
                scheduleAccountingReconciliations();
                return null;
            }
            when 'createMarkupDataForAPFMappings()' {
               createMarkupDataForAPFMappings();
               return null;
            }
            when 'createMarkupDataForVendorControlledPricing()' {
                createMarkupDataForVendorControlledPricing();
                return null;
            }
            when 'assignBlackpurlPermissionToActiveUsers()' {
                assignBlackpurlPermissionToActiveUsers();
                return null;
            }
			when 'executeConvertTempUnitsIntoORDUUnitsBatch()' {
                executeConvertTempUnitsIntoORDUUnitsBatch();
                return null;
            }
            when 'enableReallocateOnOrderPartsPermissionForAllGroup()' {
                enableReallocateOnOrderPartsPermissionForAllGroup();
                return null;
            } 
            when 'enableApplyBulkDiscountsPermissionForAllGroup()' {
                enableApplyBulkDiscountsPermissionForAllGroup();
                return null;
            }
            when 'createIFWConfigItemsForXeroUnappliedPayment()' {
                createIFWConfigItemsForXeroUnappliedPayment();
                return null;
            }
            when 'enableIncludePricesOnPartLabels()' {
                enableIncludePricesOnPartLabels();
                return null;
            }  
            when 'createGEFileConfigRecsForBPExportFormats()' {
                createGEFileConfigRecsForBPExportFormats();
                return null;
            }
            when 'updateDefaultPartCostVariance()' {
                updateDefaultPartCostVariance();
                return null;
            }
            when 'updateCurrentCostFlagOnPOTypes()' {
                updateCurrentCostFlagOnPOTypes();
                return null;
            }
            when 'populateCurrencyDetail()' {
                populateCurrencyDetail();
                return null;
            }
            when 'createIFWConfigAndConfigItemsForXE()' {
                createIFWConfigAndConfigItemsForXE();
                return null;
            }
            when 'createIFWConfigItemsForXeroCurrencies()' {
                createIFWConfigItemsForXeroCurrencies();
                return null;
            }
            when 'scheduleFXCurrencyConversionScheduler()' {
                scheduleFXCurrencyConversionScheduler();
                return null;
            }
            when 'executeDP360SyncSoldUnitBatch()' {
                executeDP360SyncSoldUnitBatch();
                return null;
            }
            when 'enableSpecificPermissionsForAllGroup()' {
                enableSpecificPermissionsForAllGroup();
                return null;
            }
            when 'setAccountAdministrationPermissions()' {
                setAccountAdministrationPermissions();
                return null;
            }
            when 'createQBIFWConfigAndLineItems()' {
                createQBIFWConfigAndLineItems(false, true);
                return null;
            }
            when 'createServiceJobStatuses()' {
                createServiceJobStatuses();
                return null;
            }
            when 'executeUpdateServiceJobStatusBatch()' {
                executeUpdateServiceJobStatusBatch();
                return null;
            }
            when 'enableJobReadyToInvoiceStatusPermissionForAllGroup()' {
                enableJobReadyToInvoiceStatusPermissionForAllGroup();
                return null;
            }
            when 'executeDFINProductCostFieldsUpdateBatch()' {
                executeDFINProductCostFieldsUpdateBatch();
                return null;
            }
            when 'executePopulateSOCommitControlsBatch()' {
                executePopulateSOCommitControlsBatch();
                return null;
            }
            when 'executePopulateClaimJobsDetailsBatch()' {
                executePopulateClaimJobsDetailsBatch();
                return null;
            }
            when 'executePopulateBulkDiscountDefaultValueBatch()' {
                executePopulateBulkDiscountDefaultValueBatch();
                return null;
            }
            when 'executePopulateTextMsgFieldOnMsgHistoryBatch()' {
                executePopulateTextMsgFieldOnMsgHistoryBatch();
                return null;
            }
            when 'executePopulateDealOptionClearingAndStockTradeBatch()' {
                executePopulateDealOptionClearingAndStockTradeBatch();
                return null;
            }
            when 'executeDealAndDealFINStatusUpdateBatch()' {
                executeDealAndDealFINStatusUpdateBatch();
                return null;
            }
            when 'updateLMAConfig()' {
                updateLMAConfig();
                return null;
            }
            when 'schedulePartAgingScheduler()' {
                schedulePartAgingScheduler();
                return null;
            }
            when 'deleteQBIFWConfigForXeroEnableOrg()' {
                deleteQBIFWConfigForXeroEnableOrg();
                return null;
            }
            when 'updateFontNamesForPaymentMethodIcons()' {
                updateFontNamesForPaymentMethodIcons();
                return null;
            }
            when 'resetBRPPasswords()' {
                resetBRPPasswords();
                return null;
            }  
             when 'executeUpdateSOLIShopSuppilesFieldBatch()' {
                executeUpdateSOLIShopSuppilesFieldBatch();
                return null;
            }    
            when 'executeFeeCostSetToZeroBatch()' {
                executeFeeCostSetToZeroBatch();
                return null;
            } 
            when 'updateUnitIconTitleValueInConfigList()' {
                updateUnitIconTitleValueInConfigList();
                return null;
            }
            when 'executeServiceJobLaborCostCalculation()' {
                executeServiceJobLaborCostCalculation();
                return null;
            }
            when 'executeDealUnitOptionTaxedSelectionBatch()' {
                executeDealUnitOptionTaxedSelectionBatch();
                return null;
            }
            when 'setDefaultOptionTaxControls()' {
                setDefaultOptionTaxControls();
                return null;
            }
            when 'enableQuickTransfersPermissionsForAdminGroup()' {
                enableQuickTransfersPermissionsForAdminGroup();
                return null;
            }
            when 'enableQuickFulfillDealOptionsPermissionsForAdminGroup()' {
                enableQuickFulfillDealOptionsPermissionsForAdminGroup();
                return null;
            }
            when 'enableReportSchedulingPermissionForAdminGroup()' {
                enableReportSchedulingPermissionForAdminGroup();
                return null;
            }
            when 'executeDFINApprovedAmountFinancedBatch()' {
                executeDFINApprovedAmountFinancedBatch();
                return null;
            }
            when 'updateTechHoursMethodInConfig()' {
                updateTechHoursMethodInConfig();
                return null;
            }
            when 'scheduleIncorrectCommittedPartsBatch()' {
                scheduleIncorrectCommittedPartsBatch();
                return null;
            }
            when 'updateSOMConfig()' {
                updateSOMConfig();
                return null;
            }
            when 'schedulePayrollAndJobClockingOffBatch()' {
                schedulePayrollAndJobClockingOffBatch();
                return null;
            }
            when 'executePopulateCreditsPendingOnRVOBatch()' {
                executePopulateCreditsPendingOnRVOBatch();
                return null;
            }
            when 'populateDealCOBuyerFromDFIN()' {
                populateDealCOBuyerFromDFIN();
                return null;
            }
            when 'executeCreateIndividualTaxOnDealBatch()' {
                executeCreateIndividualTaxOnDealBatch();
                return null;
            }
            when 'populateCostMethodOnVendorProductAndFIProduct()' {
                populateCostMethodOnVendorProductAndFIProduct();
                return null;
            }
            when 'executePopulateMileageOnDealItemsBatch()' {
                executePopulateMileageOnDealItemsBatch();
                return null;
            }
            when 'populateDealshipCountryInBPConfig()' {
                populateDealshipCountryInBPConfig();
                return null;
            }
            when 'updateDefTaxOnClaimDeductibleInConfig()' {
                updateDefTaxOnClaimDeductibleInConfig();
                return null;
            }
            when 'updateCOIPAmountToTwoDecimal()' {
                updateCOIPAmountToTwoDecimal();
                return null;
            }
            when 'updateCODepositAmountToTwoDecimal()' {
                updateCODepositAmountToTwoDecimal();
                return null;
            }
            when 'correctCountryData()' {
                correctCountryData();
                return null;
            }
            when 'executeElasticSyncLogDeleteBatch()' {
                executeElasticSyncLogDeleteBatch();
                return null;
            }
            when 'mapUsersWithTechnicians()' {
                mapUsersWithTechnicians();
                return null;
            }
            when 'scheduleArchiveDeleteCOBatch()' {
                scheduleArchiveDeleteCOBatch();
                return null;
            }
            when 'updateBRPDealerAuthCredentials()' {
                updateBRPDealerAuthCredentials();
                return null;
            }
            when 'enableSOSLSearch()' {
                enableSOSLSearch();
                return null;
            }
            when 'enableReportScheduling()' {
                enableReportScheduling();
                return null;
            }
            when 'enableNewGlobalSearch()' {
                enableNewGlobalSearch();
                return null;
            }
            when 'disableNewGlobalSearch()' {
                disableNewGlobalSearch();
                return null;
            }
            when 'updatePaymentMethodSurchargeDetails()' {
                updatePaymentMethodSurchargeDetails();
                return null;
            }
            when 'enablePaymentSurchargePermissionForAllGroups()' {
                enablePaymentSurchargePermissionForAllGroups();
                return null;
            }
            when 'runPopulatePreTaxInvoiceTotalBatch()' {
                executePopulatePreTaxInvoiceTotalBatch();
                return null;
            }
            when 'executeMissingVIVarianceJESyncBatch()' {
                executeMissingVIVarianceJESyncBatch();
                return null;
            }
            when 'PopulateStateFromAbbreviationBatch()' {
                PopulateStateFromAbbreviationBatch();
                return null;
            }
            when 'executePopulateDealSalespersonBatch()' {
                executePopulateDealSalespersonBatch();
                return null;
            }
            when 'resyncClaimDeductibleInvoice()' {
                resyncClaimDeductibleInvoice();
                return null;
            }
            when 'executeSetPartHasFifoBucketFlagBatch()' {
                executeSetPartHasFifoBucketFlagBatch();
                return null;
            }
            when 'executePopulateCalculatedCustomerPriceBatch()' {
                executePopulateCalculatedCustomerPriceBatch();
                return null;
            }
            when 'runPopulatePreTaxInvoiceTotalBatch_V2()' {
                runPopulatePreTaxInvoiceTotalBatch_V2();
                return null;
            }
            when 'enableDuplicateTabDetector()' {
                enableDuplicateTabDetector();
                return null;
            }
            when 'createExcludeHeaderOnARIPartsmart10ToggleConfig()' {
                createExcludeHeaderOnARIPartsmart10ToggleConfig();
                return null;
            }
            when 'executeDeleteCOFormAttachmentsBatch()' {
                executeDeleteCOFormAttachmentsBatch();
                return null;
            }
            when 'populateSOWorkStatusToNonBlank()' {
                populateSOWorkStatusToNonBlank();
                return null;
            }
            when 'schedulePopulateInvoiceARBalanceScheduler()' {
                schedulePopulateInvoiceARBalanceScheduler();
                return null;
            }
            when 'enableWebComponentSTA()' {
                enableWebComponentSTA();
                return null;
            }
            when 'executePopulateDealItemReportFieldsBatch()' {
                executePopulateDealItemReportFieldsBatch();
                return null;
            }
            when 'createIFWConfigAndConfigItemsForUniversalAPI()' {
                createIFWConfigAndConfigItemsForUniversalAPI();
                return null;
            }
            when 'executeDealProfitabilityBatch()' {
                executeDealProfitabilityBatch();
                return null;
            }
            when 'turnONVOShowAllNeeds()' {
                setGeneralConfig('VO_show_all_needs__c', true);
                return null;
            }
            when 'turnONCOAsyncAction()' {
                setGeneralConfig('Use_CO_Async_Action__c', true);
                return null;
            }
            when 'deleteTemplateCreatedAccReconciliationRecords()' {
                deleteTemplateCreatedAccReconciliationRecords();
                return null;
            }
            when 'executePopulateCOSalespersonBatch()' {
                executePopulateCOSalespersonBatch();
                return null;
            }
            when 'executeUpdateCOSalespersonBatch()' {
                executeUpdateCOSalespersonBatch();
                return null;
            }
            when 'executeORDUAndUPCTaxableCostBatch()' {
                executeORDUAndUPCTaxableCostBatch();
                return null;
            }
            when 'executePopulateTempUnitApplicableTaxBatch()' {
                executePopulateTempUnitApplicableTaxBatch();
                return null;
            }
            when 'executePopulateVOGPkgSettingBatch()' {
                executePopulateVOGPkgSettingBatch();
                return null;
            }
            when 'createFeatureToggleConfig()' {
                createFeatureToggleConfig();
                return null;
            }
            when 'executeServiceJobStatusUpdateBatch()' {
                executeServiceJobStatusUpdateBatch();
                return null;
            }
            when 'createKenectFeatureToggleConfig()' {
                createKenectFeatureToggleConfig();
                return null;
            }
            when 'executeSetHistoricalVendorCreditDataBatch()' {
                executeSetHistoricalVendorCreditDataBatch();
                return null;
            }
            when 'scheduleDeleteScheduler()' {
                scheduleDeleteScheduler();
                return null;
            }
            when 'executePopulateLastSoldFieldOnPartBatch()' {
                executePopulateLastSoldFieldOnPartBatch();
                return null;
            }
            when 'setTechnicianClockJobStatus()' {
                setTechnicianClockJobStatus();
                return null;
            }
            when 'executeCustomerVendorStateUpdateBatch()' {
                executeCustomerVendorStateUpdateBatch();
                return null;
            }
            when 'updateLastModifiedFieldsOnHistoricalData()' {
                updateLastModifiedFieldsOnHistoricalData();
                return null;
            }
            when 'executePopulateUnitCostOnConsignmentBatch()' {
                executePopulateUnitCostOnConsignmentBatch();
                return null;
            }
            when 'setSOSLOnlyFeatureToggle()' {
                setSOSLOnlyFeatureToggle();
                return null;
            }
            when 'executeContactShippingDetailUpdateBatch()' {
                executeContactShippingDetailUpdateBatch();
                return null;
            }
            when 'enableSOSLOnlyFeatureToggle()' {
                enableSOSLOnlyFeatureToggle();
                return null;
            }
            when 'enableAllowCustomerServiceJobWithoutUnit()' {
                enableAllowCustomerServiceJobWithoutUnit();
                return null;
            }
            when 'createGenericCOU()' {
                createGenericCOU();
                return null;
            }
            when 'executeDeleteESSyncErrorLogBatch()' {
                executeDeleteESSyncErrorLogBatch();
                return null;
            }
            when 'enableCreateMakeModelAdhocPermForAllGroups()' {
                enableCreateMakeModelAdhocPermForAllGroups();
                return null;
            }
            when 'updateCompanyLogoSizeInBusinessProfile()' {
                updateCompanyLogoSizeInBusinessProfile();
                return null;
            }
            when 'populateShopifyGoLiveDate()' {
                populateShopifyGoLiveDate();
                return null;
            }
            when 'updateCategoryUniqueName()' {
                updateCategoryUniqueName();
                return null;
            }
            when 'setSyncPublishFeedUnitToDP360Toggle()' {
                setSyncPublishFeedUnitToDP360Toggle();
                return null;
            }
            when 'enableBulkDeletingPermissionForAdminGroup()' {
                enableBulkDeletingPermissionForAdminGroup();
                return null;
            }
            when 'executePartQtyCommittedRecalculationBatch()' {
                executePartQtyCommittedRecalculationBatch();
                return null;
            }
            when 'executeSKUDateStockedInBatch()' {
                executeSKUDateStockedInBatch();
                return null;
            }
            when 'executeUPCAdjustmentDateBatch()' {
                executeUPCAdjustmentDateBatch();
                return null;
            }
            when 'executePopulateIndividualTaxRateNameBatch()' {
                executePopulateIndividualTaxRateNameBatch();
                return null;
            }
            when 'rescheduleAllJobs()' {
                Set<String> jobNames = new Set<String>(ScheduleJobService.jobNameToCronExpMap.keySet());
                jobNames.add(ScheduleJobService.INTEGRATION_INTEGRITY_CHECK_SCHEDULER);
                rescheduleJobs(jobNames);
                return null;
            }
            when 'updateFusionReportingRecords()' {
                updateFusionReportingRecords();
                return null;
            }
            when 'executeConvertUnitAttachmentsToFilesBatch()' {
                executeConvertUnitAttachmentsToFilesBatch();
                return null;
            }
            when 'executeUpdateDefaultProductTypeOnUnitsBatch()' {
                executeUpdateDefaultProductTypeOnUnitsBatch();
                return null;
            }
            when 'rescheduleAccountingIntegrityJobs()' {
                Set<String> jobNames = new Set<String>{ScheduleJobService.INTEGRITY_CHECK_FOR_QBO, ScheduleJobService.INTEGRITY_CHECK_FOR_XERO, 
                    ScheduleJobService.ACCOUNTING_INTEGRITY_CHECK_SCHEDULER, ScheduleJobService.INTEGRATION_INTEGRITY_CHECK_SCHEDULER};
                rescheduleJobs(jobNames);
                return null;
            }
            when 'updateShopifyConfigForProSkuMappingField()' {
                updateShopifyConfigForProSkuMappingField();
                return null;
            }
            when 'executePopulateTaxExemptionTypeBatch()' {
                executePopulateTaxExemptionTypeBatch();
                return null;
            }
            when 'updateXeroShopifyIntegrityScript()' {
                updateXeroShopifyIntegrityScript();
                return null;
            }
            when 'executeCreateIndividualTaxesUnderUPCBatch()' {
                executeCreateIndividualTaxesUnderUPCBatch();
                return null;
            }
            when 'scheduleAPFImport()' {
                APFImportScheduler.scheduleJob();
                return null;
            }
            when 'executeReportFilterCleanupBatch()' {
                executeReportFilterCleanupBatch();
                return null;
            }
            when else {
                throw new BlackPurlException('Method not implemented');
            }
        }
    }
}