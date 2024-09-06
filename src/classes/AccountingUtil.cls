public without sharing class AccountingUtil {
    public final static String USE_DEPOSIT = 'Use Deposit';
    public static final String INVOICE =  'Invoice';
    public static final String USE_DEAL_DEPOSIT = 'Use Deal Deposit';
    public final static String XERO_CO_INVOICE_NO_LI_MSG = 'No line item to post to Xero while syncing invoice.';
    public static final String THIRD_PARTY = 'Third-Party';
    public static final String CUSTOMER_NOT_SYNC_MSG = 'Customer is not synced with accounting.';
    public static final String PROVIDER_NOT_SYNC_MSG = 'Provider is not synced with accounting.';
    public static final String VENDOR_NOT_SYNC_MSG = 'Vendor is not synced with accounting.';
	public static String activeAccIntegrationName = getActiveAccountingIntegration();
	
    public static String getChartofAccount(string accountType) {
        Accounting_Default_Accounts__c defaultAccounts = Accounting_Default_Accounts__c.getOrgDefaults();
        String accountId = '';
        if(String.isNotBlank(accountType)){
            if(accountType.equalsIgnoreCase('A/P Inventory Accrual')) {
                accountId = defaultAccounts.A_P_Inventory_Accrual__c;
            }
            else if(accountType.equalsIgnoreCase('Cost of Goods Sold')) {
                accountId = defaultAccounts.Cost_of_Goods_Sold__c;
            }
            else if(accountType.equalsIgnoreCase('Customer Deposits')) {
                accountId = defaultAccounts.Customer_Deposits__c;
            }
            else if(accountType.equalsIgnoreCase('Inventory')) {
                accountId = defaultAccounts.Inventory__c;
            }
            else if(accountType.equalsIgnoreCase('Inventory Adjustments')) {
                accountId = defaultAccounts.Inventory_Adjustments__c;
            }
            else if(accountType.equalsIgnoreCase('Miscellaneous Income')) {
                accountId = defaultAccounts.Miscellaneous_Income__c;
            }
            else if(accountType.equalsIgnoreCase('Sales Income')) {
                accountId = defaultAccounts.Sales_Income__c;
            }
            else if(accountType.equalsIgnoreCase('Sales Tax')) {
                accountId = defaultAccounts.Sales_Tax__c;
            }
            else if(accountType.equalsIgnoreCase('Undeposited Funds')) {
                accountId = defaultAccounts.Undeposited_Funds__c;
            }
            else if(accountType.equalsIgnoreCase('Cash Rounding')) {
                accountId = defaultAccounts.Cash_Rounding__c;
            }
            else if(accountType.equalsIgnoreCase('Cash Sale Customer')) {
                accountId = defaultAccounts.Cash_Sale_Customer_Id__c;
            } 
            else if(accountType.equalsIgnoreCase('Internal Service Customer')) {
                accountId = defaultAccounts.Internal_Service_Customer_Id__c;
            } 
            else if(accountType.equalsIgnoreCase('Store Credit Accrual')) {
                accountId = defaultAccounts.Store_Credit_Accrual__c;
            }
            else if(accountType.equalsIgnoreCase('Store Credit Expense')) {
                accountId = defaultAccounts.Store_Credit_Expense__c;
            }
            else if(accountType.equalsIgnoreCase('Stamp Duty Accrual')) {
                accountId = defaultAccounts.Stamp_Duty_Accrual__c;
            }
    		else if(accountType.equalsIgnoreCase('Undeposited Direct Deposit')) {
    			accountId = defaultAccounts.Undeposited_Direct_Deposit__c;
        	}
    		else if(accountType.equalsIgnoreCase('Undeposited Financing')) {
    			accountId = defaultAccounts.Undeposited_Financing__c;
    		}
            else if(accountType.equalsIgnoreCase('Deal Option Clearing')) {
                accountId = defaultAccounts.Deal_Option_Clearing__c;
            }
            else if(accountType.equalsIgnoreCase('WIP Labor Inventory')) {
                accountId = defaultAccounts.WIP_Labor_Inventory__c;
            }
            else if(accountType.equalsIgnoreCase('WIP Labor Expense')) {
                accountId = defaultAccounts.WIP_Labor_Expense__c;
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
            unitIdToRecMap = new Map<String, Customer_Owned_Unit__c>([SELECT Id, (SELECT Type__c, Total_Cost__c, Total_Price__c, Qty__c from Unit_Prices_Costs__r WHERE CreatedDate <= :invoicedDate) 
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

    public static Map<String, List<CO_Invoice_Item__c>> getInvoiceIdToInvoiceItemListMap(Set<Id> invoiceItemIdSet){
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

    public static void updateRefreshTokensForOAuth2(String activeIntegrationName, List<IFW_IntegrationConfig__c> integrationConfigList) {
        if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
            if(QuickBookQueryService.refreshToken !=  null) {
                QBUtil.saveRefreshToken(QuickBookQueryService.refreshToken, QuickBookQueryService.refreshTokenExpiresIn);
            }
        } else if(activeIntegrationName == 'Xero') {
            if(integrationConfigList != null && XeroUtility.isXeroOAuth2Enabled()) {
                update integrationConfigList;
            }
        }
    }

    public static Boolean isVendorActiveInAccounting(List<Account> vendorRecList, IFW_IntegrationConfig__c integrationConfig) {
        Boolean isVendorActive = true;
        if(QBUtil.isQBEnabled()) {
            if(vendorRecList.size() > 0 && vendorRecList[0].Vendor_AccountingId__c != null) {
                isVendorActive = QBUtil.isVendorActiveInQB(vendorRecList[0]);
            }
        } else {
            if(vendorRecList.size() > 0 && vendorRecList[0].Xero_Vendor_Accounting_Id__c != null) {
                isVendorActive = XeroUtility.isVendorActiveInXero(vendorRecList[0], integrationConfig);
            }
        }
        return isVendorActive;
    }

    public static Boolean isInvNumberAlreadyExistInAccounting(String invoiceNumber, IFW_IntegrationConfig__c integrationConfig) {
        Boolean isInvNumberAlreadyExist = false;
        if(QBUtil.isQBEnabled()) {
            isInvNumberAlreadyExist = QBUtil.isInvNumberAlreadyExistInQB(invoiceNumber);
        } else {
            isInvNumberAlreadyExist = XeroUtility.isInvNumberAlreadyExistInXero(invoiceNumber, integrationConfig);
        }
        return isInvNumberAlreadyExist;
    }

    public static String validateVendorRefNumberInAccounting(AccountingEntity txnJson) {
        String responseStr = 'Success';
        if(String.isNotBlank(txnJson.EntitySFId)) {
            Account vendorRec = [SELECT Vendor_AccountingId__c, Xero_Vendor_Accounting_Id__c FROM Account WHERE Id = :txnJson.EntitySFId];
            if(QBUtil.isQBEnabled()) {
                txnJson.EntityAccId = vendorRec.Vendor_AccountingId__c;
                if(QuickBookQueryService.refreshToken !=  null) {
                    QBUtil.saveRefreshToken(QuickBookQueryService.refreshToken, QuickBookQueryService.refreshTokenExpiresIn);
                }
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

    /* Created for validating vendor/customer reference number */
    public class AccountingEntity { 
        public String EntitySFId;
        public String TxnNumber;
        public String TxnType;
        public String EntityAccId;
    }
}