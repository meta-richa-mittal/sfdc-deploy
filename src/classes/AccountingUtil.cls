public without sharing class AccountingUtil {
    public final static String USE_DEPOSIT = 'Use Deposit';
    public static final String INVOICE =  'Invoice';
    public static final String USE_DEAL_DEPOSIT = 'Use Deal Deposit';
    public final static String XERO_CO_INVOICE_NO_LI_MSG = 'No line item to post to Xero while syncing invoice.';
    public static final String THIRD_PARTY = 'Third-Party';
    public static final String CUSTOMER_NOT_SYNC_MSG = 'Customer is not synced with accounting.';
    public static final String PROVIDER_NOT_SYNC_MSG = 'Provider is not synced with accounting.';
    public static final String VENDOR_NOT_SYNC_MSG = 'Vendor is not synced with accounting.';
    public static final String UNAPPLIED_PAYMENT = 'Unapplied Payment';
	public static Integer scheduleAfterSeconds = 10;
	public static String activeAccIntegrationName = getActiveAccountingIntegration();
    public static final String STATUS_CODE_TEXT = 'Status Code: ';
	
    public static String getChartofAccount(string accountType) {
        Accounting_Default_Accounts__c defaultAccounts = Accounting_Default_Accounts__c.getOrgDefaults();
        String accountId = '';
        if(String.isNotBlank(accountType)){
            if(accountType.equalsIgnoreCase('A/P Inventory Accrual')) {
                accountId = defaultAccounts.A_P_Inventory_Accrual__c;
            } else if(accountType.equalsIgnoreCase('Cost of Goods Sold')) {
                accountId = defaultAccounts.Cost_of_Goods_Sold__c;
            } else if(accountType.equalsIgnoreCase('Customer Deposits')) {
                accountId = defaultAccounts.Customer_Deposits__c;
            } else if(accountType.equalsIgnoreCase('Inventory')) {
                accountId = defaultAccounts.Inventory__c;
            } else if(accountType.equalsIgnoreCase('Inventory Adjustments')) {
                accountId = defaultAccounts.Inventory_Adjustments__c;
            } else if(accountType.equalsIgnoreCase('Miscellaneous Income')) {
                accountId = defaultAccounts.Miscellaneous_Income__c;
            } else if(accountType.equalsIgnoreCase('Sales Income')) {
                accountId = defaultAccounts.Sales_Income__c;
            } else if(accountType.equalsIgnoreCase('Sales Tax')) {
                accountId = defaultAccounts.Sales_Tax__c;
            } else if(accountType.equalsIgnoreCase('Undeposited Funds')) {
                accountId = defaultAccounts.Undeposited_Funds__c;
            } else if(accountType.equalsIgnoreCase('Cash Rounding')) {
                accountId = defaultAccounts.Cash_Rounding__c;
            } else if(accountType.equalsIgnoreCase('Cash Sale Customer')) {
                accountId = defaultAccounts.Cash_Sale_Customer_Id__c;
            } else if(accountType.equalsIgnoreCase('Internal Service Customer')) {
                accountId = defaultAccounts.Internal_Service_Customer_Id__c;
            } else if(accountType.equalsIgnoreCase('Store Credit Accrual')) {
                accountId = defaultAccounts.Store_Credit_Accrual__c;
            } else if(accountType.equalsIgnoreCase('Store Credit Expense')) {
                accountId = defaultAccounts.Store_Credit_Expense__c;
            } else if(accountType.equalsIgnoreCase('Stamp Duty Accrual')) {
                accountId = defaultAccounts.Stamp_Duty_Accrual__c;
            } else if(accountType.equalsIgnoreCase('Undeposited Direct Deposit')) {
    			accountId = defaultAccounts.Undeposited_Direct_Deposit__c;
        	} else if(accountType.equalsIgnoreCase('Undeposited Financing')) {
    			accountId = defaultAccounts.Undeposited_Financing__c;
    		} else if(accountType.equalsIgnoreCase('Deal Option Clearing')) {
                accountId = defaultAccounts.Deal_Option_Clearing__c;
            } else if(accountType.equalsIgnoreCase('WIP Labor Inventory')) {
                accountId = defaultAccounts.WIP_Labor_Inventory__c;
            } else if(accountType.equalsIgnoreCase('WIP Labor Expense')) {
                accountId = defaultAccounts.WIP_Labor_Expense__c;
            } else if(accountType.equalsIgnoreCase('Financing Commision Income')) {
                accountId = defaultAccounts.Finance_Commission_Income__c;
            } else if(accountType.equalsIgnoreCase('Financing Commision Clearing')) {
                accountId = defaultAccounts.Finance_Commission_Clearing__c;
            } else if(accountType.equalsIgnoreCase('Payment Method Surcharges')) {
                accountId = defaultAccounts.Payment_Method_Surcharges__c;
            } else if(accountType.equalsIgnoreCase('Cash over/short')) {
                accountId = defaultAccounts.Cash_over_short__c;
            } else if(accountType.equalsIgnoreCase('Checkout clearing')) {
                accountId = defaultAccounts.Checkout_clearing__c;
            } else if(accountType.equalsIgnoreCase('Cash Rec clearing')) {
                accountId = defaultAccounts.Cash_Rec_clearing__c;
            } else if(accountType.equalsIgnoreCase('Gift Card liability')) {
                accountId = defaultAccounts.Gift_Card_liability__c;
            }
    	}
        return accountId;
    }
    
    
    public static List<Category__c> getStampDutyCategory(){
        List<Category__c> stampDutyCategory = [select Name, AccountingId__c, Income_GL__c from Category__c
                                                    where Type__c = 'Stamp Duty' AND Active__c = true AND Default__c = true];
        return stampDutyCategory;
    }
    
    
    public static List<Category__c> getTradeInCategory(){
        List<Category__c> tradeInCategory = [select Name, AccountingId__c, Income_GL__c from Category__c
                                                    where Type__c = 'Trade-in' AND Active__c = true AND Default__c = true];
        return tradeInCategory;
    }
    
    public static List<Category__c> getSystemDefaultCategory(String categoryType){
    	List<Category__c> systemDefaultCategory = [SELECT Name, AccountingId__c, Income_GL__c, Inventory_GL__c FROM Category__c 
    											WHERE Type__c =: categoryType AND Default__c = true AND Active__c = true];
		return systemDefaultCategory;
    }
    
    public static Map<String, Category__c> getTypeToDefaultCategoryMap(List<String> categoryTypeList) {
    	List<Category__c> defaultCategoryList = [select Name, Inventory_GL__c, COGS_GL__c, Income_GL__c, Type__c, AccountingId__c from Category__c
                									where (Type__c IN :categoryTypeList) AND Active__c = true AND Default__c = true];
                									
    	Map<String, Category__c> categoryTypeToDefaultRecMap = new Map<String, Category__c>();
        for(Category__c categoryRec: defaultCategoryList) {
        	if(!categoryTypeToDefaultRecMap.containsKey(categoryRec.Type__c)) {
        		categoryTypeToDefaultRecMap.put(categoryRec.Type__c, categoryRec);
        	}
        }  
        return categoryTypeToDefaultRecMap;
    }
    
    public static Map<String, List<Unit_Price_Cost__c>> setDealItemIdToPriceCostListMap(List<Deal_Item__c> dealItemList) {
        Map<String, String> dealItemIdToUnitIdMap = new Map<String, String>();
        DateTime invoicedDate;
        for(Deal_Item__c dealItemRec : dealItemList) {
            invoicedDate = dealItemRec.Deal__r.Invoice_Number__r.Closed_Invoice_Date__c != null ? dealItemRec.Deal__r.Invoice_Number__r.Closed_Invoice_Date__c : dealItemRec.Deal__r.Invoice_Number__r.Invoice_Date__c;
            dealItemIdToUnitIdMap.put(dealItemRec.Id, dealItemRec.Customer_Owned_Unit__c);
        }
        
        Map<String, List<Unit_Price_Cost__c>> unitIdToPriceCostListMap = new Map<String, List<Unit_Price_Cost__c>>();
        Map<String, Customer_Owned_Unit__c> unitIdToRecMap;
        if(dealItemIdToUnitIdMap.size() > 0) {
            unitIdToRecMap = new Map<String, Customer_Owned_Unit__c>([SELECT Id, (SELECT Type__c, Cost__c, Price__c, Total_Cost__c, Total_Price__c, Qty__c from Unit_Prices_Costs__r WHERE CreatedDate <= :invoicedDate)
                                                            FROM Customer_Owned_Unit__c WHERE Id IN: dealItemIdToUnitIdMap.values()]);
        }
        
        Map<String, List<Unit_Price_Cost__c>> dealItemIdToPriceCostListMap = new Map<String, List<Unit_Price_Cost__c>>();
        for(String dealItemId : dealItemIdToUnitIdMap.keyset()) {
            String unitId = dealItemIdToUnitIdMap.get(dealItemId);
            if(unitIdToRecMap.containsKey(unitId)) {
                dealItemIdToPriceCostListMap.put(dealItemId, unitIdToRecMap.get(unitId).Unit_Prices_Costs__r);
            }
        }
        return dealItemIdToPriceCostListMap;
    }
    
    public static Map<String, Category__c> getTradeInTaxCategoryMap() {
    	Set<Id> tradeInTaxCategoryIdSet = new Set<Id>{GeneralConfiguration.getTradeTaxPendingSaleCategory(), 
    														GeneralConfiguration.getTradeTaxLiabilityCategory(), 
    														GeneralConfiguration.getTradeTaxExpenseCategory(),
    														GeneralConfiguration.getPurchaseTaxLiabilityCategory()};
    	return new Map<String, Category__c>([SELECT Id, Income_GL__c, Default__c, Active__c 
    																				FROM Category__c where (Default__c = true AND Active__c = true) 
    																				OR Id IN: tradeInTaxCategoryIdSet]);
    }
    
    public static String getURL(String entityId, String pageName) {
        String url = BP_Configurations__c.getInstance().Org_Base_Url__c;
        if(String.isBlank(url)) {
            url =  System.Url.getSalesforceBaseUrl().toExternalForm();
        }
        url +=  '/apex/Blackpurl#/' + pageName + '?Id=' + entityId;
        return url;
    }
    
    public static String getHoursLoggedJENarration(AccountingHoursLogged hoursLoggedObj) {
        String narration = '';
        if(hoursLoggedObj.Name != null) {
            narration += hoursLoggedObj.Name + ';';
        }
        if(hoursLoggedObj.IsRemoved) {
            narration += 'Removed;';
        } else {
            narration += (hoursLoggedObj.OldTotalCost == null) ? 'Added;' : 'Modified;';
        }
        if(hoursLoggedObj.TechnicianName != null) {
            narration += hoursLoggedObj.TechnicianName + ';';
        }
        if(hoursLoggedObj.CONumber != null) {
            narration += hoursLoggedObj.CONumber + ';';
        }
        if(hoursLoggedObj.ServiceJobName != null) {
            narration += hoursLoggedObj.ServiceJobName;
        }
        return narration;
    }
    
    public static String getHoursLoggedJELineItemDesc(AccountingHoursLogged hoursLoggedObj, Boolean isAdded) {
        String description = '';
        if(hoursLoggedObj.Name != null) {
            description += hoursLoggedObj.Name + ';';
        }
        if(hoursLoggedObj.TechnicianName != null) {
            description += hoursLoggedObj.TechnicianName + ';';
        }
        if(!hoursLoggedObj.IsRemoved && hoursLoggedObj.TotalHours != null){
            description += (isAdded) ? (hoursLoggedObj.TotalHours + ' hours added;') : (hoursLoggedObj.OldTotalHours + ' hours removed;');
        } else if(hoursLoggedObj.TotalHours != null) {
            description += hoursLoggedObj.TotalHours + ' hours removed;';
        }
        if(hoursLoggedObj.CONumber != null) {
            description += hoursLoggedObj.CONumber + ';';
        }
        if(hoursLoggedObj.ServiceJobName != null) {
            description += hoursLoggedObj.ServiceJobName;
        }
        return description;
    }
    
    public static Map<Id, List<Count_Session_Line_Item__c>> getCountSessionIdToCountSessionLineItemsMap(List<Count_Session__c> countSessionRecList) {
    	String query;
        query = 'SELECT ';
        for(String fieldName : AccountingCountSession.getCountSessionLineItemfieldsList()) {
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Count_Session_Line_Item__c where Count_Session__c IN: countSessionRecList AND Variance__c != 0';
        if(AccessControl.ifObjectFieldIsAccessible('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Count_Session_Line_Item__c> countSessionLineItemRecList = Database.query(query);
        
        Map<Id, List<Count_Session_Line_Item__c>> countSessionIdToLineItemListMap = new Map<Id, List<Count_Session_Line_Item__c>>();
        for(Count_Session_Line_Item__c countSessionLineItemRec : countSessionLineItemRecList) {
        	if(!countSessionIdToLineItemListMap.containsKey(countSessionLineItemRec.Count_Session__c)) {
        		countSessionIdToLineItemListMap.put(countSessionLineItemRec.Count_Session__c, new List<Count_Session_Line_Item__c>());
        	}
        	countSessionIdToLineItemListMap.get(countSessionLineItemRec.Count_Session__c).add(countSessionLineItemRec);
        }
        return countSessionIdToLineItemListMap;
    }
    
    public static List<Vendor_Invoicing_Group__c> getVIGroupsListByVIHeaderId(Set<Id> vendorInvoiceIdSet){
        String viGroupQueryStr = 'SELECT ';
        for(String fieldName : AccountingVendorInvoice.objectToFieldMap.get('VIGroup')){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            viGroupQueryStr += fieldName + ', ';
        }
        viGroupQueryStr = viGroupQueryStr.substring(0, viGroupQueryStr.length()-2);
        viGroupQueryStr += ' FROM Vendor_Invoicing_Group__c WHERE Vendor_Invoicing_Header__c IN: vendorInvoiceIdSet';
    	if(AccessControl.ifObjectFieldIsAccessible('Vendor_Invoicing_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	return Database.query(viGroupQueryStr);
    }
    
    public static List<Other_Charges__c> getOtherChargesListByVIHeaderId(Set<Id> vendorInvoiceIdSet){
        String otherChargeQueryStr = 'SELECT ';
        for(String fieldName : AccountingVendorInvoice.objectToFieldMap.get('OtherCharges')){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            otherChargeQueryStr += fieldName + ', ';
        }
        otherChargeQueryStr = otherChargeQueryStr.substring(0, otherChargeQueryStr.length()-2);
        otherChargeQueryStr += ' FROM Other_Charges__c WHERE Vendor_Invoicing_Header__c IN: vendorInvoiceIdSet';
    	
    	if(AccessControl.ifObjectFieldIsAccessible('Other_Charges__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	return Database.query(otherChargeQueryStr);
    }
    
    public static List<Part_FIFO_Bucket__c> getPartFifoBucketListByVIHeaderId(Set<Id> vendorInvoiceIdSet){
        String partFifoBucketQueryStr = 'SELECT ';
        for(String fieldName : AccountingFIFOBucket.fieldsList()){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            partFifoBucketQueryStr += fieldName + ', ';
        }
        partFifoBucketQueryStr = partFifoBucketQueryStr.substring(0, partFifoBucketQueryStr.length()-2);
        partFifoBucketQueryStr += ' FROM Part_FIFO_Bucket__c WHERE Vendor_Invoicing_Header__c IN: vendorInvoiceIdSet';
        
        if(AccessControl.ifObjectFieldIsAccessible('Part_FIFO_Bucket__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(partFifoBucketQueryStr);
    }

    public static String getPaymentUndepositedFundAccId(String paymentType) {
        paymentType = paymentType.trim();
        String accountId = '';
        List<Payment_Method__c> paymentMethodList = [SELECT Undeposited_Funds__c FROM Payment_Method__c Where Name =: paymentType];
        if(paymentMethodList.size() > 0) {
            accountId = paymentMethodList[0].Undeposited_Funds__c;
        }
        return accountId;
    }

    public static Map<String, List<CO_Invoice_Item__c>> getInvoiceIdToInvoiceItemListMap(Set<Id> invoiceItemIdSet) {
        List<CO_Invoice_Item__c> coInvoiceItemList = getInvoiceItemListByInvoiceId(invoiceItemIdSet);
        Map<String, List<CO_Invoice_Item__c>> invoiceIdToInvoiceItemListMap = new Map<String, List<CO_Invoice_Item__c>>();
        for(CO_Invoice_Item__c invoiceItemRec : coInvoiceItemList) {
    		if(!invoiceIdToInvoiceItemListMap.containsKey(invoiceItemRec.CO_Invoice_Header__c)) {
    			invoiceIdToInvoiceItemListMap.put(invoiceItemRec.CO_Invoice_Header__c, new List<CO_Invoice_Item__c>());
    		}
    		invoiceIdToInvoiceItemListMap.get(invoiceItemRec.CO_Invoice_Header__c).add(invoiceItemRec);
        }

        return invoiceIdToInvoiceItemListMap;
    }

    public static Map<String, List<Return_VO_Line_Item__c>> getRCRIdToRVOLIListMap(Set<Id> rcrIdSet) {
        List<Return_VO_Line_Item__c> rvoLIList = [SELECT Return_CR_Line_Item__r.Return_CR_Header__c, Variance__c FROM Return_VO_Line_Item__c WHERE Return_CR_Line_Item__r.Return_CR_Header__c IN :rcrIdSet];
        Map<String, List<Return_VO_Line_Item__c>> rcrIdToRVOLIListMap = new Map<String, List<Return_VO_Line_Item__c>>();
        for(Return_VO_Line_Item__c rvoLIRec: rvoLIList) {
    		if(!rcrIdToRVOLIListMap.containsKey(rvoLIRec.Return_CR_Line_Item__r.Return_CR_Header__c)) {
    			rcrIdToRVOLIListMap.put(rvoLIRec.Return_CR_Line_Item__r.Return_CR_Header__c, new List<Return_VO_Line_Item__c>());
    		}
    		rcrIdToRVOLIListMap.get(rvoLIRec.Return_CR_Line_Item__r.Return_CR_Header__c).add(rvoLIRec);
        }

        return rcrIdToRVOLIListMap;
    }

    private static List<CO_Invoice_Item__c> getInvoiceItemListByInvoiceId(Set<Id> invoiceItemIdSet){
        String invItemQueryStr = 'SELECT ';
        for(String fieldName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceItem')){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            invItemQueryStr += fieldName + ', ';
        }
        invItemQueryStr = invItemQueryStr.substring(0, invItemQueryStr.length()-2);
        invItemQueryStr += ' FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c IN: invoiceItemIdSet';
    	if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	return Database.query(invItemQueryStr);
    }
    
    public static Boolean isSyncVRToAccounting(Vendor_Receiving_Header__c newRec, Vendor_Receiving_Header__c oldRec) {
    	return (newRec.Status__c == IntegrationUtility.STOCKED && oldRec.Status__c != IntegrationUtility.STOCKED);
    }
    
    public static String getIntegrationVersion() {
        String integrationVersion;
        if(QBUtil.isQBEnabled()) {
            integrationVersion = QuickBooks_Configurations__c.getOrgDefaults().Integration_Version__c;
            if(String.isBlank(integrationVersion)) {
                AccountingIntegrationSettingsCtrl.getQBCompanyInfo();
                integrationVersion = QuickBooks_Configurations__c.getOrgDefaults().Integration_Version__c;
            }
        }
        return integrationVersion;
    }

    public static Map<String, Integration_Error_Handling_Config__mdt> getRetryConfigsByIntegration(String integrationType) {
        List<Integration_Error_Handling_Config__mdt> retryConfigList = [SELECT Error__c, Required_GET_call__c, Retry_After_sec__c, Error_Code__c 
                                    FROM Integration_Error_Handling_Config__mdt WHERE Integration_Name__c =: integrationType];
        Map<String, Integration_Error_Handling_Config__mdt> errorTypeToRetryConfigListMap = new Map<String, Integration_Error_Handling_Config__mdt>();
        for(Integration_Error_Handling_Config__mdt retryConfigRec : retryConfigList) {
            errorTypeToRetryConfigListMap.put(retryConfigRec.Error__c, retryConfigRec);
        }
        return errorTypeToRetryConfigListMap;
    }

    public static Boolean isSyncVIToAccounting(Vendor_Invoicing_Header__c newRec, Vendor_Invoicing_Header__c oldRec) {
    	return (newRec.Status__c == IntegrationUtility.INVOICED && oldRec.Status__c != IntegrationUtility.INVOICED);
    }

    public static Boolean isSyncReturnVOToAccounting(Return_VO_Header__c newRec, Return_VO_Header__c oldRec) {
    	return (newRec.Status__c == IntegrationUtility.CREDITED && oldRec.Status__c != IntegrationUtility.CREDITED);
    }
    
    public static String getActiveAccountingIntegration() {
    	Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults();
    	if(accConfig != null) {
    		return accConfig.Provider_Name__c;
    	}
    	return null;
    }
    
    private static Map<String, String> restrictionConfigFieldNameToGenAccFieldAPIName = new Map<String, String>{
			'Account Type' => 'Account_Type__c',
			'Detail Type' => 'Account_Detail_Type__c',
			'Account Name' => 'Account_Name__c'
	};
    
    public static void validateChartOnAccounts() {
    	try {
	    	if(String.isNotBlank(activeAccIntegrationName)) {
		    	List<COA_Restriction_Config__c> restrictionConfigList = [Select Id, Field_Name__c, Field_Value__c from COA_Restriction_Config__c 
		    			where Integration_Name__c =: activeAccIntegrationName];
		    	
	    		List<General_Account__c> generalAccountUpdateList = new List<General_Account__c>();
		    	for(General_Account__c genAcc : [SELECT Id, Restricted__c, Account_Name__c, Account_Type__c, Account_Detail_Type__c FROM General_Account__c 
                                                ORDER By LastModifiedDate ASC LIMIT : SOQLUtil.getAvailableQueryRowsLimit()]) {
		    		Boolean isRestricted = false;
					for(COA_Restriction_Config__c config : restrictionConfigList) {
		    			if(String.isNotBlank(config.Field_Name__c) && String.isNotBlank(config.Field_Value__c) && 
	    											restrictionConfigFieldNameToGenAccFieldAPIName.containsKey(config.Field_Name__c)) {
	    					String fieldAPIName = restrictionConfigFieldNameToGenAccFieldAPIName.get(config.Field_Name__c);							
							if(genAcc.get(fieldAPIName) != null) {
								String genAccFieldValue = String.valueOf(genAcc.get(fieldAPIName));
		    					if(String.isNotBlank(genAccFieldValue) && config.Field_Value__c.equalsIgnoreCase(genAccFieldValue)) {
			    					isRestricted = true;
			    					break;	
								}
							}
						}
		    		}
		    		genAcc.Restricted__c = genAcc.Restricted__c != null ? genAcc.Restricted__c : false;
		    		if(genAcc.Restricted__c != isRestricted) {
		    			genAcc.Restricted__c = isRestricted;
		    			generalAccountUpdateList.add(genAcc);
		    		}
		    	}
		    	if(generalAccountUpdateList.size() > 0) {
                    DMLUtility.updateSobjectList('General_Account__c', generalAccountUpdateList);
		    	}
	    	}
    	} catch(Exception e) {
    		system.debug('Exception while validating restriction on general accounts ' + e.getMessage());
    	}
    }
    
    public static String getAccountingPeriodClosedDate() {
        String accPeriodClosedDate;
        if(QBUtil.isQBEnabled()) {
            accPeriodClosedDate = QBUtil.getAccountingPeriodClosedDate();
            if(accPeriodClosedDate != null) {
                accPeriodClosedDate = BPUtility.getFormatedDateTime(DateTimeUtility.getDateFromFormattedDateStr(accPeriodClosedDate, 'YYYY-MM-DD'));
            }
        } else if (IntegrationServiceFactory.getActiveAccountingIntegrationName() == 'Xero') {
            accPeriodClosedDate = XeroUtility.getAccountingPeriodClosedDate();
            if(accPeriodClosedDate != null) {
                accPeriodClosedDate = BPUtility.getFormatedDateTime(Date.valueOf(DateTimeUtility.getDateTimeFromMSAjaxDateStr(accPeriodClosedDate)));
            }
        }
        return accPeriodClosedDate;
    }

    public static Boolean isTxnDateAfterAccPeriodCloseDate(String integrationName, DateTime transactionDate) {
    	Boolean isTxnDateAfterAccPeriodCloseDate = true;
		if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
            isTxnDateAfterAccPeriodCloseDate = QBUtil.isTxnDateAfterAccPeriodCloseDate(transactionDate);
        } else if(integrationName == XeroUtility.XERO) {
            isTxnDateAfterAccPeriodCloseDate = XeroUtility.isTxnDateAfterAccPeriodCloseDate(transactionDate);
        }
        return isTxnDateAfterAccPeriodCloseDate;
    }

    // This is used where transaction date is of Date type like in VO flow.
    public static Boolean isTxnDateAfterAccPeriodCloseDateWithRefreshToken(String integrationName, Date transactionDate, List<IFW_IntegrationConfig__c> configList) {
    	Boolean isTxnDateAfterAccPeriodCloseDate = true;
		if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
            isTxnDateAfterAccPeriodCloseDate = QBUtil.isTxnDateAfterAccPeriodCloseDateWithRefreshToken(transactionDate, configList);
        } else if(integrationName == XeroUtility.XERO) {
            isTxnDateAfterAccPeriodCloseDate = XeroUtility.isTxnDateAfterAccPeriodCloseDateWithRefreshToken(transactionDate, configList);
        }
        return isTxnDateAfterAccPeriodCloseDate;
    }

    // This is used where transaction date is of DateTime type like in CO flow.
    public static Boolean isTxnDateAfterAccPeriodCloseDateWithRefreshToken(String integrationName, DateTime transactionDate, List<IFW_IntegrationConfig__c> configList) {
    	Boolean isTxnDateAfterAccPeriodCloseDate = true;
		if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
            isTxnDateAfterAccPeriodCloseDate = QBUtil.isTxnDateAfterAccPeriodCloseDateWithRefreshToken(transactionDate, configList);
        } else if(integrationName == XeroUtility.XERO) {
            isTxnDateAfterAccPeriodCloseDate = XeroUtility.isTxnDateAfterAccPeriodCloseDateWithRefreshToken(transactionDate, configList);
        }
        return isTxnDateAfterAccPeriodCloseDate;
    }

    public static void updateRefreshTokensForOAuth2(String activeIntegrationName, List<IFW_IntegrationConfig__c> integrationConfigList) {
        if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
            if(!integrationConfigList.isEmpty()) QBCalloutManager.updateRecords(integrationConfigList[0]);
        } else if(activeIntegrationName == 'Xero') {
            if(integrationConfigList != null && XeroUtility.isXeroEnabled()) {
                update integrationConfigList;
            }
        }
    }

    public static Boolean isVendorActiveInAccounting(List<Account> vendorRecList, IFW_IntegrationConfig__c integrationConfig) {
        Boolean isVendorActive = true;
        if(!vendorRecList.isEmpty()) {
            if(integrationConfig.Integration_Name__c == QBUtil.QUICKBOOKS_ONLINE) {
                if(vendorRecList[0].Vendor_AccountingId__c != null) {
                    isVendorActive = QBUtil.isVendorActiveInQB(vendorRecList[0], integrationConfig);
                }
            } else if(integrationConfig.Integration_Name__c == XeroUtility.XERO) {
                if(vendorRecList[0].Xero_Vendor_Accounting_Id__c != null) {
                    isVendorActive = XeroUtility.isVendorActiveInXero(vendorRecList[0], integrationConfig);
                }
            }
        }
        return isVendorActive;
    }

    public static Boolean isInvNumberAlreadyExistInAccounting(String invoiceNumber, IFW_IntegrationConfig__c integrationConfig) {
        Boolean isInvNumberAlreadyExist = false;
        if(String.isNotBlank(invoiceNumber)) {
            if(integrationConfig.Integration_Name__c == QBUtil.QUICKBOOKS_ONLINE) {
                isInvNumberAlreadyExist = QBUtil.isInvNumberAlreadyExistInQB(invoiceNumber, integrationConfig);
            } else if(integrationConfig.Integration_Name__c == XeroUtility.XERO) {
                isInvNumberAlreadyExist = XeroUtility.isInvNumberAlreadyExistInXero(invoiceNumber, integrationConfig);
            }
        }
        return isInvNumberAlreadyExist;
    }

    public static String validateVendorRefNumberInAccounting(AccountingEntity txnJson) {
        String responseStr = 'Success';
        if(String.isNotBlank(txnJson.EntitySFId)) {
            Account vendorRec = [SELECT Vendor_AccountingId__c, Xero_Vendor_Accounting_Id__c FROM Account WHERE Id = :txnJson.EntitySFId];
            if(QBUtil.isQBEnabled()) {
                txnJson.EntityAccId = vendorRec.Vendor_AccountingId__c;
                responseStr = QBUtil.validateVendorRefNumberInQB(txnJson);
            } else {
                List<IFW_IntegrationConfig__c> integrationConfigList = BaseIntegration.getParentByName('Xero');
				if(integrationConfigList.size() > 0) {
                    txnJson.EntityAccId = vendorRec.Xero_Vendor_Accounting_Id__c;
                    responseStr = XeroUtility.validateVendorRefNumberInXero(txnJson, integrationConfigList[0]);
                    update integrationConfigList;
                }
            }
        }
        return responseStr;
    }

    public static Boolean isMultiCurrencyEnabled() {
        if(!AccessControl.ifObjectFieldIsAccessible('QuickBooks_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return (QuickBooks_Configurations__c.getOrgDefaults().Multi_Currency_Enabled__c);
    }

    public static String getHomeCurrency() {
        if(!AccessControl.ifObjectFieldIsAccessible('QuickBooks_Configurations__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return (QuickBooks_Configurations__c.getOrgDefaults().Home_Currency__c);
    }

    public static void abortScheduleJobs(String jobName) {
        String jobNameLike = jobName + '%';
        List<CronTrigger> alreadyScheduledJobs = [Select Id from CronTrigger where CronJobDetail.Name LIKE :jobNameLike];
        for(CronTrigger scheduledJobRec: alreadyScheduledJobs) {
            system.abortJob(scheduledJobRec.Id);
        }
    }
    
    public static ResponseWrapper getCustomerOpenBalanceInfoForAccApp(String customerId, Boolean isActive, IFW_IntegrationConfig__c ifwConfigRec, String activeIntegrationName) {
    	if(activeIntegrationName == null) activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
        if(String.isNotBlank(customerId)) {
        	Account customerToUpdate = [SELECT Active__c, AccountingId__c, Xero_Customer_Accounting_Id__c FROM Account WHERE Id = :customerId];
    		if(!isActive && customerToUpdate.Active__c != isActive) {
    			if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
    				if(String.isNotBlank(customerToUpdate.AccountingId__c)) {
    					try {
                            QBResponseWrapper customerGetResponse = QBCalloutManager.getDataByQBIdAndUpdateRecords('customer', customerToUpdate.AccountingId__c, ifwConfigRec);
		                    if(customerGetResponse == null) {
		                    	return new ResponseWrapper('error', 'There is some error fetching Customer details from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.');
		                    } else if(customerGetResponse.Customer != null && customerGetResponse.Customer.Balance != 0) {
		                    	return new ResponseWrapper('error', 'Customer has a non-zero balance in ' + QBUtil.QUICKBOOKS_ONLINE + ' so cannot deactivate it.');
		                    }
    					} catch(Exception e) {
    						if(e.getMessage().contains('invalid_grant')) {
    							return new ResponseWrapper('error', 'Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
    						}
                            return new ResponseWrapper('error', 'There is some error fetching Customer details from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.');
    					}
    				}
    			} else if(activeIntegrationName == XeroUtility.XERO) {
                    if(ifwConfigRec == null) {
                        BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
                        if(integrationRec != null && integrationRec.integrationConfigRec != null) ifwConfigRec = integrationRec.integrationConfigRec;
                    }
                    
                    if(ifwConfigRec != null && String.isNotBlank(customerToUpdate.Xero_Customer_Accounting_Id__c)) {
                        String whereClause = 'ContactID == Guid("' + customerToUpdate.Xero_Customer_Accounting_Id__c + '")';
                        XeroResponseWrapper xeroResponse = XeroService.getDataFromXero('Contacts', whereClause, ifwConfigRec);
                        DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigRec);
                        if(BaseIntegration.webServiceLogs != null) DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
                        
                        if(xeroResponse == null) {
                            return new ResponseWrapper('error', 'Error communicating with the accounting package, try again later.');
                        } else if(xeroResponse.Contacts != null && !xeroResponse.Contacts.isEmpty() && xeroResponse.Contacts[0].Balances != null && 
                                    xeroResponse.Contacts[0].Balances.AccountsReceivable != null && xeroResponse.Contacts[0].Balances.AccountsReceivable.Outstanding != 0) { 
                            return new ResponseWrapper('error', 'Customer has a non-zero balance in ' + XeroUtility.XERO + ' so cannot deactivate it.');
                        }
    				}
                }
        	}
        }
        return new ResponseWrapper('success', 'success');
    }

    public static ResponseWrapper getVendorOpenBalanceInfoForAccApp(String vendorId, Boolean isActive, IFW_IntegrationConfig__c ifwConfigRec, String activeIntegrationName) {
    	if(String.isNotBlank(vendorId)) {
        	Account vendorToUpdate = [SELECT Active__c, Vendor_AccountingId__c, Xero_Vendor_Accounting_Id__c FROM Account WHERE Id = :vendorId];
    		if(!isActive && vendorToUpdate.Active__c != isActive) {
    			if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
    				if(String.isNotBlank(vendorToUpdate.Vendor_AccountingId__c)) {
    					try {
    						QBResponseWrapper vendorGetResponse = QBCalloutManager.getDataByQBId('vendor', vendorToUpdate.Vendor_AccountingId__c, ifwConfigRec);
		                    if(vendorGetResponse == null) {
		                    	return new ResponseWrapper('error', 'There is some error fetching Vendor details from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.');
		                    } else if(vendorGetResponse.Vendor != null && vendorGetResponse.Vendor.Balance != 0) {
		                    	return new ResponseWrapper('error', 'Vendor has a non-zero balance in ' + QBUtil.QUICKBOOKS_ONLINE + ' so cannot deactivate it.');
		                    }
    					} catch(Exception e) {
    						if(e.getMessage().contains('invalid_grant')) {
    							return new ResponseWrapper('error', 'Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
    						}
                            return new ResponseWrapper('error', 'There is some error fetching Vendor details from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.');
    					}
    				}
    			} else if(activeIntegrationName == XeroUtility.XERO) {
                    String whereClause = 'ContactID == Guid("' + vendorToUpdate.Xero_Vendor_Accounting_Id__c + '")';
                    XeroResponseWrapper xeroResponse = XeroService.getDataFromXero('Contacts', whereClause, ifwConfigRec);
                    
                    if(xeroResponse == null) {
                        return new ResponseWrapper('error', 'Error communicating with the accounting package, try again later.');
                    } else if(xeroResponse.Contacts != null && !xeroResponse.Contacts.isEmpty() && xeroResponse.Contacts[0].Balances != null && 
                                xeroResponse.Contacts[0].Balances.AccountsPayable != null && xeroResponse.Contacts[0].Balances.AccountsPayable.Outstanding != 0) { 
                        return new ResponseWrapper('error', 'Vendor has a non-zero balance in ' + XeroUtility.XERO + ' so cannot deactivate it.');
                    }
                }
        	}
        }
        return new ResponseWrapper('success', 'success');
    }

    public static List<ForeignExchangeUtil.CurrencyWrapper> getActiveCurrenciesFromQB(ForeignExchangeUtil.CurrencyWrapper homeCurrency) {
        Integer apiCount = 0;
        String query;
        List<ForeignExchangeUtil.CurrencyWrapper> foreignCurrencyList = new List<ForeignExchangeUtil.CurrencyWrapper>();
        List<QBQueryResponseWrapper.CompanyCurrencyWrapper> qbPaymentResponseList = new List<QBQueryResponseWrapper.CompanyCurrencyWrapper>();
        QBQueryResponseWrapper.QBResponseWrapper resObj;
        
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, new Map<String, String>());
        if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
        try {
			do {
                resObj = QBCalloutManager.getData('companycurrency', new List<String>(), integrationConfigList[0], apiCount, AccountingIntegrationSettingsService.RECORDS_PER_PAGE);        
                if(resObj != null && resObj.CompanyCurrency != null && resObj.CompanyCurrency.size() > 0) {
                    qbPaymentResponseList.addAll(resObj.CompanyCurrency);
                }
                apiCount++;
			} while(resObj != null && resObj.CompanyCurrency != null && resObj.CompanyCurrency.size() == AccountingIntegrationSettingsService.RECORDS_PER_PAGE);
		} catch(Exception e) {
			// added to create the log records inserted in QBCalloutManager
		}
        DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', integrationConfigList);

        if(!qbPaymentResponseList.isEmpty()) {
            Set<String> currencyCodeSet = new Set<String>();
            for(QBQueryResponseWrapper.CompanyCurrencyWrapper qbCurrency : qbPaymentResponseList) {
                if(!qbCurrency.Code.equalsIgnoreCase(homeCurrency.CurrencyCode) && qbCurrency.Active) {
                    currencyCodeSet.add(qbCurrency.Code);
                }
            }
            foreignCurrencyList = activateForeignCurrenciesInBP(currencyCodeSet);
        }
        return foreignCurrencyList;
    }
    
    public static List<ForeignExchangeUtil.CurrencyWrapper> getActiveCurrenciesFromXERO(ForeignExchangeUtil.CurrencyWrapper homeCurrency) {
        List<ForeignExchangeUtil.CurrencyWrapper> foreignCurrencyList = new List<ForeignExchangeUtil.CurrencyWrapper>();
        
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems('Xero', new Map<String, String>{IntegrationUtility.CURRENCIES => null});
        if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
        List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
        if(configItemList.size() == 0) throw new BlackpurlException('Config item for Organization not defined');

        HttpResponse response = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], '', new List<customHttpHeaderWrapper>());
        update integrationConfigList;

        if(response.getStatusCode() == 200) {
            XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
            if(xeroResponseWrapper != null && xeroResponseWrapper.Currencies != null) {
                Set<String> currencyCodeSet = new Set<String>();
                for(XeroCurrencyDTO xeroCurrency : xeroResponseWrapper.Currencies) {
                    if(!xeroCurrency.Code.equalsIgnoreCase(homeCurrency.CurrencyCode)) {
                        currencyCodeSet.add(xeroCurrency.Code);
                    }
                }
                foreignCurrencyList = activateForeignCurrenciesInBP(currencyCodeSet);
            }
        }
        return foreignCurrencyList;
    }

    public static String getDepositMemo(AccountingCODeposit coDepositRec) {
        String memo = '';
        if(String.isNotBlank(coDepositRec.DepositName)) {
            memo += coDepositRec.DepositName + ';';
        }
        if(String.isNotBlank(coDepositRec.customer.Name)){
            memo += coDepositRec.customer.Name + ';';
        } else if(coDepositRec.COType == Constants.CASH_SALE) {
            memo += Constants.CASH_SALE + ';';
        } else if(coDepositRec.COType == Constants.INTERNAL_SERVICE) {
            memo += Constants.INTERNAL_SERVICE + ';';
        }
        memo += coDepositRec.CustomerOrderNumber + ';';
        if(String.isNotBlank(coDepositRec.ReverseLink)) {
            memo += coDepositRec.PaymentMethod + ';Deposit Reversal';
        } else if(coDepositRec.Amount < 0 && coDepositRec.PaymentMethod == 'Invoice') {
            memo += 'Use Deposit' + ';Invoice Payment';
        } else if(coDepositRec.Amount < 0) {
            memo += coDepositRec.PaymentMethod + ';Deposit Refund';
        } else if(coDepositRec.PaymentMethod == 'Invoice') {
            memo += 'Use Deposit' + ';Invoice Payment Reversal';
        } else {
            memo += coDepositRec.PaymentMethod + ';Deposit';
        }
        return memo;
    }

    public static String getDepositLineItemDesc(AccountingCODeposit coDepositRec) {
        String lineItemDesc = coDepositRec.PaymentMethod == 'Invoice' ? 'Use Deposit' : coDepositRec.PaymentMethod;
        if(String.isNotBlank(coDepositRec.ReverseLink)) {
            lineItemDesc += ';Deposit Reversal;';
        } else if(coDepositRec.Amount < 0 && coDepositRec.PaymentMethod == 'Invoice') {
            lineItemDesc += ';Invoice Payment;';
        } else if(coDepositRec.Amount < 0) {
            lineItemDesc += ';Deposit Refund;';
        } else if(coDepositRec.PaymentMethod == 'Invoice') {
            lineItemDesc += ';Invoice Payment Reversal;';
        } else {
            lineItemDesc += ';Deposit;';
        }

        if(String.isNotBlank(coDepositRec.DepositName)) {
            lineItemDesc += coDepositRec.DepositName + ';';
        }
        if(String.isNotBlank(coDepositRec.customer.Name)){
            lineItemDesc += coDepositRec.customer.Name + ';';
        } else if(coDepositRec.COType == Constants.CASH_SALE) {
            lineItemDesc += Constants.CASH_SALE + ';';
        } else if(coDepositRec.COType == Constants.INTERNAL_SERVICE) {
            lineItemDesc += Constants.INTERNAL_SERVICE + ';';
        }
        lineItemDesc += coDepositRec.CustomerOrderNumber;
        return lineItemDesc;
    }

    public static String getQueryByEntityName(String entityType, Map<String, Integration_Entity__mdt> integrationEntityNameToRecMap) { 
		String queryStr = '';
		if(integrationEntityNameToRecMap.keyset().size() > 0) {
			queryStr += 'SELECT Id';
			queryStr += integrationEntityNameToRecMap.get(entityType).Accounting_Response_API_Name__c != null ? (', ' + integrationEntityNameToRecMap.get(entityType).Accounting_Response_API_Name__c) : '';
			queryStr += ' FROM ';
			queryStr += integrationEntityNameToRecMap.get(entityType).Object_API_Name__c;
			queryStr += ' WHERE ' + integrationEntityNameToRecMap.get(entityType).Sync_Flag_API_Name__c + ' = true ';
			if(entityType == IntegrationUtility.PART_FIFO) {
				queryStr += ' AND Is_FIFO_Bucket__c = true AND Vendor_Receiving_Header__c = null AND Customer_Return__c = null AND Source_Name__c != \'Oversold\' ';
			} else if(entityType == IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM) {
				queryStr += ' AND Part_FIFO_Bucket__r.Is_FIFO_Bucket__c = true AND CO_Invoice_Header__c = null ';
			} else if(entityType == IntegrationUtility.VENDOR_RECEIVING) {
				queryStr += ' AND (Status__c = \'Stocked\' OR Status__c = \'Invoiced\') ';
			} else if(entityType == IntegrationUtility.VO_RETURN) {
				queryStr += ' AND Status__c = \'Credited\' ';
			} else if(entityType == IntegrationUtility.VO_INVOICE) {
				queryStr += ' AND Status__c = \'Invoiced\' ';
			}
			queryStr += ' Order by CreatedDate ASC ';
		}
		return queryStr;
	}

    public static String getCronExpForGivenTime(Integer second) {
        DateTime dtVal = system.now().addSeconds(second);
        String strSchedule = String.valueOf(dtVal.second()) + ' ' + String.valueOf(dtVal.minute()) + ' ' + String.valueOf(dtVal.hour()) + 
                                ' ' + String.valueOf(dtVal.day()) + ' ' + String.valueOf(dtVal.month()) + ' ?' + ' ' + String.valueOf(dtVal.year());
        return strSchedule;
    }

    public static void abortAlreadyScheduleJobs(String jobName) {
        List<CronTrigger> alreadyScheduledJobs = [Select Id from CronTrigger where CronJobDetail.Name =: jobName];
        if(alreadyScheduledJobs.size() > 0) {
            system.abortJob(alreadyScheduledJobs[0].Id);    
        }
    }

    private static List<ForeignExchangeUtil.CurrencyWrapper> activateForeignCurrenciesInBP(Set<String> currencyCodeSet) {
        List<ForeignExchangeUtil.CurrencyWrapper> foreignCurrencyList = new List<ForeignExchangeUtil.CurrencyWrapper>();
        List<Country__c> countryList = [SELECT Id,Currency_Code__c,Currency_Name__c,Name__c,Flag_Encoded__c,Currency_Symbol__c,Active__c,Conversion_Rate__c FROM Country__c WHERE Currency_Code__c IN :currencyCodeSet ORDER BY Currency_Code__c ASC];
        Boolean isAlreadyActive = checkIfAnyCurrencyAlreadyActive(countryList);
        for(Country__c countryRec : countryList) {
            if(!isAlreadyActive) countryRec.Active__c = true;
            foreignCurrencyList.add(new ForeignExchangeUtil.CurrencyWrapper(countryRec));
        }
        DMLUtility.updateSobjectList('Country__c', countryList);    
        return foreignCurrencyList;  
    }

    private static Boolean checkIfAnyCurrencyAlreadyActive(List<Country__c> countryList) {
        for(Country__c countryRec : countryList) {
            if(countryRec.Active__c) return true;
        }
        return false;
    }

    public static Decimal getCustomerOpenARBalance(String customerId) {
    	String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
        Decimal customerOpenBalance = 0;
        BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');

        if(String.isNotBlank(customerId) && String.isNotBlank(activeIntegrationName) && integrationRec != null && integrationRec.integrationConfigRec != null) {
        	Account customerToUpdate = [SELECT Active__c, AccountingId__c, Xero_Customer_Accounting_Id__c FROM Account WHERE Id = :customerId];
            if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
                if(String.isNotBlank(customerToUpdate.AccountingId__c)) {
                    try {
                        QBResponseWrapper customerGetResponse = QBCalloutManager.getDataByQBIdAndUpdateRecords('customer', customerToUpdate.AccountingId__c, integrationRec.integrationConfigRec);
                        if(customerGetResponse == null) {
                            throw new BlackPurlException('There is some error fetching Customer details from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.');
                        } else if(customerGetResponse.Customer != null) {
                            customerOpenBalance = customerGetResponse.Customer.Balance;
                        }
                    } catch(Exception e) {
                        if(e.getMessage().contains('invalid_grant')) {
                            throw new BlackPurlException('Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
                        }
                        throw new BlackPurlException('There is some error fetching Customer details from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.');
                    }
                }
            } else if(activeIntegrationName == XeroUtility.XERO) {
                if(String.isNotBlank(customerToUpdate.Xero_Customer_Accounting_Id__c)) {
                    String whereClause = 'ContactID == Guid("' + customerToUpdate.Xero_Customer_Accounting_Id__c + '")';
                    XeroResponseWrapper xeroResponse = XeroService.getDataFromXero('Contacts', whereClause, integrationRec.integrationConfigRec);
                    DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', integrationRec.integrationConfigRec);
                    if(BaseIntegration.webServiceLogs != null) DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
                    
                    if(xeroResponse == null) {
                        throw new BlackPurlException('Error communicating with the accounting package, try again later.');
                    } else if(xeroResponse.Contacts != null && !xeroResponse.Contacts.isEmpty() && xeroResponse.Contacts[0].Balances != null && 
                                xeroResponse.Contacts[0].Balances.AccountsReceivable != null) { 
                        customerOpenBalance = xeroResponse.Contacts[0].Balances.AccountsReceivable.Outstanding;
                    }
                }
            }
        }
        return customerOpenBalance;
    }

    public static Map<String, Decimal> getCOInvoicesIdToARBalanceMap(List<CO_Invoice_Header__c> coInvoiceList, BaseIntegrationService integrationRec) {
        Map<String, Decimal> invoiceIdToARBalanceMap = new Map<String, Decimal>();
        String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();

        if(String.isNotBlank(activeIntegrationName) && integrationRec != null && integrationRec.integrationConfigRec != null) {
            Map<String, CO_Invoice_Header__c> accountingIdToCOInvoiceMap = new Map<String, CO_Invoice_Header__c>();
            Map<String, CO_Invoice_Header__c> accountingIdToCreditNoteCOInvoiceMap = new Map<String, CO_Invoice_Header__c>();
        	for(CO_Invoice_Header__c coInvoiceRec : coInvoiceList) {
                if(coInvoiceRec.AccountingId__c != null) {
                    accountingIdToCOInvoiceMap.put(coInvoiceRec.AccountingId__c, coInvoiceRec);
                } else if(coInvoiceRec.Xero_Accounting_Id__c != null) {
                    accountingIdToCOInvoiceMap.put(coInvoiceRec.Xero_Accounting_Id__c, coInvoiceRec);
                    if(coInvoiceRec.Total__c < 0) {
                        accountingIdToCreditNoteCOInvoiceMap.put(coInvoiceRec.Xero_Accounting_Id__c, coInvoiceRec);
                    }
                }
            }
            if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
                List<QBInvoiceDTO> qbInvoiceList = QBService.getUnpaidInvoicesFromQB(null, integrationRec.integrationConfigRec, accountingIdToCOInvoiceMap.keySet());
                List<QBInvoiceDTO> unappliedCreditList = QBService.getUnappliedCreditsFromQB(null, integrationRec.integrationConfigRec, accountingIdToCOInvoiceMap.keySet());
                for(QBInvoiceDTO invoiceDtoObj : qbInvoiceList) {
                    if(accountingIdToCOInvoiceMap.containsKey(invoiceDtoObj.Id)) {
                        invoiceIdToARBalanceMap.put(accountingIdToCOInvoiceMap.get(invoiceDtoObj.Id).Id, invoiceDtoObj.Balance);
                    }
                }
                for(QBInvoiceDTO invoiceDtoObj : unappliedCreditList) {
                    if(accountingIdToCOInvoiceMap.containsKey(invoiceDtoObj.Id)) {
                        invoiceIdToARBalanceMap.put(accountingIdToCOInvoiceMap.get(invoiceDtoObj.Id).Id, (Decimal.valueOf(invoiceDtoObj.RemainingCredit) * -1));
                    }
                }
            } else if(activeIntegrationName == XeroUtility.XERO) {
                List<XeroInvoiceDTO> xeroInvoiceList = XeroService.getUnpaidInvoicesFromXero(integrationRec.integrationConfigRec, accountingIdToCOInvoiceMap.keySet());
                if(!accountingIdToCreditNoteCOInvoiceMap.isEmpty()) {
                    List<XeroCreditNoteDTO> xeroCreditNotesList = XeroService.getUnappliedCreditsFromXero(integrationRec.integrationConfigRec, accountingIdToCreditNoteCOInvoiceMap.keySet());
                    for(XeroCreditNoteDTO invoiceDtoObj : xeroCreditNotesList) {
                        if(accountingIdToCOInvoiceMap.containsKey(invoiceDtoObj.CreditNoteID)) {
                            invoiceIdToARBalanceMap.put(accountingIdToCOInvoiceMap.get(invoiceDtoObj.CreditNoteID).Id, (invoiceDtoObj.RemainingCredit * -1));
                        }
                    }
                }
                for(XeroInvoiceDTO invoiceDtoObj : xeroInvoiceList) {
                    if(accountingIdToCOInvoiceMap.containsKey(invoiceDtoObj.InvoiceID)) {
                        invoiceIdToARBalanceMap.put(accountingIdToCOInvoiceMap.get(invoiceDtoObj.InvoiceID).Id, invoiceDtoObj.AmountDue);
                    }
                }
            }
        }
        return invoiceIdToARBalanceMap;
    }

    public static Boolean isNewPaymentAccountingApplicable(Date transactionDate) {
        General_Configurations__c genConfiguration = General_Configurations__c.getOrgDefaults();
        if(genConfiguration.Use_new_payment_accounting__c) {
            Datetime enableDateTime = genConfiguration.New_Payment_Accounting_Enable_Time__c;
            Integer offset = UserInfo.getTimezone().getOffset(enableDateTime);
            if(transactionDate != null && transactionDate >= (enableDateTime.addSeconds(offset/1000)).date()) {
                return true;
            }
        }
        return false;
    }   

    /* Created for validating vendor/customer reference number */
    public class AccountingEntity { 
        public String EntitySFId;
        public String TxnNumber;
        public String TxnType;
        public String EntityAccId;
    }
}