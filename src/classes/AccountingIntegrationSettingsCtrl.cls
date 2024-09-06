global without sharing class AccountingIntegrationSettingsCtrl {
    
    global AccountingIntegrationSettingsCtrl (NewHomePageCtrl controller){}
    public AccountingIntegrationSettingsCtrl() {}
    
    
    public static String Consumer_Key;
    public static String Request_Token_URL = 'https://oauth.intuit.com/oauth/v1/get_request_token';
    public static String Consumer_Secret;
    public static String Temporary_Token_Secret;
    public static String OAuth_Token;
    public static String Access_Token_URL;
    public static String OAuth_Token_Secret;
    public static String End_Point_URL;
    public static String CASH_SALE = 'CASH SALE';
    public static String INTERNAL_SERVICE = 'INTERNAL SERVICE';
    public static final String CONSIGNMENT_CLEARING = 'Consignment Clearing';
    
    public static Set<String> SPECIAL_CATEGORIES_TYPE_SET = new Set<String>{'Deductible', 'Trade-in', 'Stocked Trade', 'Stamp Duty', 
                                                                'Lien Payout', CONSIGNMENT_CLEARING, 'Customer Deposits'};
    
    @remoteAction 
    global static String getCategoryDetails() {
        List<Category__c> categoryList = SOQLUtil.getAllCategoryDetails();
        if(categoryList.size() == 0) {
            return BPUtility.getEncodedString('{}');
        }

        Map<String, String> accountingIdToAccountNumMap = new Map<String, String>();
        if(QBUtil.isQBEnabled()) {
            accountingIdToAccountNumMap = AccountingIntegrationSettingsService.getAccountingIdToAccountNumMap();
        }
        List<CategoryWrapper> categoryObjList = new List<CategoryWrapper>();
        for(Category__c categoryRec : categoryList) {
            if(!SPECIAL_CATEGORIES_TYPE_SET.contains(categoryRec.Type__c)) {
                CategoryWrapper CategoryWrapperObj = new CategoryWrapper(categoryRec);
                if(QBUtil.isQBEnabled()) { 
                    CategoryWrapperObj.IncomeGLAccNumber = accountingIdToAccountNumMap.get(CategoryWrapperObj.IncomeGL) != null ? accountingIdToAccountNumMap.get(CategoryWrapperObj.IncomeGL): (CategoryWrapperObj.IncomeGL != null? AccountingIntegrationSettingsService.ID_STRING + CategoryWrapperObj.IncomeGL : '');
                    CategoryWrapperObj.InventoryGLAccNumber = accountingIdToAccountNumMap.get(CategoryWrapperObj.InventoryGL) != null ? accountingIdToAccountNumMap.get(CategoryWrapperObj.InventoryGL): (CategoryWrapperObj.InventoryGL != null ? AccountingIntegrationSettingsService.ID_STRING + CategoryWrapperObj.InventoryGL : '');
                    CategoryWrapperObj.COGSGLAccNumber = accountingIdToAccountNumMap.get(CategoryWrapperObj.COGSGL) != null ? accountingIdToAccountNumMap.get(CategoryWrapperObj.COGSGL): (CategoryWrapperObj.COGSGL != null ? AccountingIntegrationSettingsService.ID_STRING + CategoryWrapperObj.COGSGL : '');
                } else {
                    CategoryWrapperObj.IncomeGLAccNumber = CategoryWrapperObj.IncomeGL;
                    CategoryWrapperObj.InventoryGLAccNumber = CategoryWrapperObj.InventoryGL;
                    CategoryWrapperObj.COGSGLAccNumber = CategoryWrapperObj.COGSGL;
                }
                categoryObjList.add(CategoryWrapperObj);
            }
        }
        return BPUtility.getEncodedString(system.JSON.serialize(categoryObjList));
    }
      
    
    @remoteAction 
    global static String removeCategory(String categoryId) {
        categoryId = BPUtility.getDecodedString(categoryId);
        List<Category__c> categoryList = [select Id from Category__c where Id = :categoryId];
        if(categoryList.size() > 0){
            delete categoryList;
        }
        return getCategoryDetails(); 
    }
    
    
    //This method is not in use
    @remoteAction 
    global static String getQuickBooksAuthorizationCodes() {
        List<IFW_IntegrationConfig__c> ifwConfigList = AccountingIntegrationSettingsService.getQuickBooksIFWConfig();
        if(ifwConfigList.size() > 0){
            return BPUtility.getEncodedString(System.JSON.serialize(new QuickBooksAuthorizationCodeWrapper(ifwConfigList[0]))); 
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new QuickBooksAuthorizationCodeWrapper())); 
    }

    @remoteAction 
    global static String saveAccountingProviderName(String accountingProviderName) {
        accountingProviderName = BPUtility.getDecodedString(accountingProviderName);
        Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults(); 
        accConfig.Provider_Name__c = accountingProviderName;
        upsert accConfig;
        createAccoutingCustomer(accountingProviderName);
        return getAccountingSettingDetails(); 
    }
    
    private static void createAccoutingCustomer(String accountingProviderName) {
        if(accountingProviderName == 'MYOB Account Right') {
            List<Account> existingAccountList = [select Name from Account where Is_Used_For_Accouting__c = true];
            List<Account> accountingCustomerList = new List<Account>();
            if(existingAccountList.size() == 0) {
                accountingCustomerList.add(new Account(Name = INTERNAL_SERVICE, Is_Used_For_Accouting__c = true, Type__c = 'Business'));
                accountingCustomerList.add(new Account(Name = CASH_SALE, Is_Used_For_Accouting__c = true, Type__c = 'Business'));
            } else if(existingAccountList.size() == 1) {
                if(existingAccountList[0].Name == INTERNAL_SERVICE) {
                    accountingCustomerList.add(new Account(Name = CASH_SALE, Is_Used_For_Accouting__c = true, Type__c = 'Business'));
                } else if(existingAccountList[0].Name == CASH_SALE) {
                    accountingCustomerList.add(new Account(Name = INTERNAL_SERVICE, Is_Used_For_Accouting__c = true, Type__c = 'Business'));
                }
            }
            if(accountingCustomerList.size() > 0) {
                insert accountingCustomerList;
            }
            populateAccountingId();
        }
    }
    
    private static void populateAccountingId() {
        List<Account> existingAccountList = [select Name, Customer_Number__c from Account where Is_Used_For_Accouting__c = true];
        Accounting_Default_Accounts__c accDefaultConfig = Accounting_Default_Accounts__c.getOrgDefaults();
        for(Account accRec : existingAccountList) {
            if(accRec.Name == CASH_SALE) {
                accDefaultConfig.Cash_Sale_Customer_Id__c = accRec.Customer_Number__c;
            } else if(accRec.Name == INTERNAL_SERVICE) {
                accDefaultConfig.Internal_Service_Customer_Id__c = accRec.Customer_Number__c;
            }
        }
        upsert accDefaultConfig;
    }
    
    @remoteAction 
    global static String saveAccountingAlignmentMethod(String alignmentMethod) {
        alignmentMethod = BPUtility.getDecodedString(alignmentMethod);
        Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults(); 
        accConfig.Alignment_Method__c = alignmentMethod;
        upsert accConfig;
        return getAccountingSettingDetails(); 
    }
    
    @remoteAction 
    global static String getAccountingSettingDetails() {  
        Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults(); 
        Accounting_Default_Accounts__c accDefaultAccount = Accounting_Default_Accounts__c.getOrgDefaults();
        List<General_Account__c> existingGeneralAccountList = [SELECT Accounting_Id__c, Account_Name__c, Account_Number__c, Restricted__c, Payments_Enabled__c, 
                                                                Account_Type__c, LastModifiedDate
                                                                 from General_Account__c 
                                                                 WHERE Is_Active__c = true 
                                                                 LIMIT : SOQLUtil.getAvailableQueryRowsLimit()]; // order by Account_Name__c ASC
        
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Category__c> categoryRecList = [SELECT Name, Income_GL__c, Type__c FROM Category__c WHERE Type__c IN: SPECIAL_CATEGORIES_TYPE_SET AND Default__c = true];
        
        QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
        AccountingSettingWrapper accWrap = new AccountingSettingWrapper(accConfig, qbConfig,  existingGeneralAccountList, accDefaultAccount, categoryRecList);
        
        return BPUtility.getEncodedString(System.JSON.serialize(accWrap));
    }
    
    @remoteAction 
    global static String getQBConfigurations() {
        QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
        return BPUtility.getEncodedString(System.JSON.serialize(qbConfig));
    }
    
    @RemoteAction
    global static String OAuthConnection(String ConsumerKey, String ConsumerSecret) {
        
        List<IFW_IntegrationConfig__c> ifwConfigList = AccountingIntegrationSettingsService.getQuickBooksIFWConfig();
        		
        if(ifwConfigList.size() == 0 || String.isBlank(ifwConfigList[0].Client_Id_Long__c) || String.isBlank(ifwConfigList[0].Client_Secret_Long__c)) {
        	throw new BlackPurlException('Some configurations are missing.');
        }
        
        Consumer_Key = ifwConfigList[0].Client_Id_Long__c;
        Consumer_Secret = ifwConfigList[0].Client_Secret_Long__c;
        
        consumerKey = BPUtility.getEncodedString(Consumer_Key);
        ConsumerSecret = BPUtility.getEncodedString(Consumer_Secret);
        
        List<Log__c> errorLogList = new List<Log__c>();
        String responseStatus = '';
        String redirectUrl = '';

        if(!QBUtil.isQBOAuth2Enabled()) {
        	HttpResponse res = QuickbookConnector.OAuthConnection(ConsumerKey, ConsumerSecret);
	        //return res.getBody(); 
	        if(res.getStatusCode() == 200) {
	            String resParams = res.getBody();
	            Map<String,String> responseItems = new Map<String,String>();
	            for(String s : resParams.split('&')) {
	                List<String> kv = s.split('=');
	                responseItems.put(kv[0],kv[1]);
	            }
	            try {
	                OAuth_Token_Secret = responseItems.get('oauth_token_secret');
	                OAuth_Token = responseItems.get('oauth_token');
	                Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults(); 
	                QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
	                qbConfig.Consumer_Key__c = Consumer_Key;
	                if(!String.isNotBlank(qbConfig.End_Point_URL__c)) {
	                    qbConfig.End_Point_URL__c = QBUtil.SANDBOX_END_POINT_URL;
	                }
	                accConfig.Provider_Name__c = 'QuickBooks Online';
	                qbConfig.Consumer_Secret__c = Consumer_Secret;
	                qbConfig.OAuth_Token__c = OAuth_Token;
	                qbConfig.OAuth_Token_Secret__c = OAuth_Token_Secret;
	                qbConfig.Access_Token_Generation_Date__c = system.today();
	                upsert qbConfig;
	                upsert accConfig;
	                responseStatus = 'success';
	            } catch(Exception e) {
	                responseStatus = e.getMessage();
	                errorLogList.add(new LogService().createErrorLog('COInvoicePaymentService', 'syncToQuickBooks()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
	                                              ConsumerKey + LogService.METHOD_PARAM_SEPERATOR + ConsumerSecret, LogService.QUICKBOOKS, false));
	            }
	             
	            redirectUrl = 'https://appcenter.intuit.com/Connect/Begin?oauth_token=' + OAuth_Token;
	        } else {
	            responseStatus = res.getBody();
	            errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsCtrl', 'OAuthConnection()', res.getBody(), res.getStatusCode(), null, 
	                                              ConsumerKey + LogService.METHOD_PARAM_SEPERATOR + ConsumerSecret, LogService.QUICKBOOKS, false));
	        }
        } else {
        	try {
        		Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults();
        		accConfig.Provider_Name__c = 'QuickBooks Online';
        		upsert accConfig;
        		
                QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
				if(String.isBlank(qbConfig.End_Point_URL__c)) {
					if(QBUtil.isQBOSanboxEnvironment()) {
						qbConfig.End_Point_URL__c = QBUtil.SANDBOX_END_POINT_URL;
					} else {
						qbConfig.End_Point_URL__c = QBUtil.PRODUCTION_END_POINT_URL;
					}
                }
		        upsert qbConfig;
        		redirectUrl = QuickbookConnector.authorizeQuickBooks(ConsumerKey, ConsumerSecret);
        		responseStatus = 'success';
	        } catch(Exception e) {
	        	responseStatus = e.getMessage();
	            errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsCtrl', 'OAuthConnectionOAuth2()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
	                                          ConsumerKey + LogService.METHOD_PARAM_SEPERATOR + ConsumerSecret, LogService.QUICKBOOKS, false));
	        }
        }
        
        if(errorLogList.size() > 0) {
            insert errorLogList;
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper(responseStatus, redirectUrl)));
    }
    
    @RemoteAction
    global static String OAuthConnectionStep1(String consumerKey, String consumerSecret, String integrationName) {
        Consumer_Key = BPUtility.getDecodedString(consumerKey);
        Consumer_Secret = BPUtility.getDecodedString(consumerSecret);
        integrationName = BPUtility.getDecodedString(integrationName);
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(AccountingIntegrationSettingsService.OAuthConnectionStep1(Consumer_Key,
                                                            Consumer_Secret, integrationName)));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getQBCompanyInfo() {
        QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
        List<IFW_IntegrationConfig__c> ifwConfigList = AccountingIntegrationSettingsService.getQuickBooksIFWConfig();
        if(ifwConfigList.size() == 0) {
        	throw new BlackpurlException('No active integration');
        }
        String CompanyId = qbConfig.Company_Id__c;
        //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks('companyinfo/' + CompanyId, null);
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('companyinfo/' + CompanyId, null);
		HttpResponse getResponse = responseObj.Response;
		if(responseObj.RefreshToken !=  null && responseObj.RefreshToken != ifwConfigList[0].Refresh_Token__c) {
            //qbConfig.Refresh_Token__c = responseObj.RefreshToken;
            ifwConfigList[0].Refresh_Token__c = responseObj.RefreshToken;
    		qbConfig.Refresh_Token_Expires_In__c = responseObj.RefreshTokenExpiresIn;
    		qbConfig.Access_Token_Generation_Date__c = system.today();
		}
        String responseStatus = '';
        if(getResponse.getStatusCode() == 200) {
            CompanyInfoWrapper company = (CompanyInfoWrapper) System.JSON.deserialize(getResponse.getBody(), CompanyInfoWrapper.class);
            qbConfig.Company_Name__c = company.CompanyInfo.CompanyName;
            qbConfig.Enable_QuickBooks__c = true;
            qbConfig.Company_Country__c = company.CompanyInfo.Country;
            responseStatus = 'success';
        } else {
            Dom.Document doc = getResponse.getBodyDocument();
            Dom.XMLNode address = doc.getRootElement();
            responseStatus = '';
            for(DOM.XMLNode xmlnodeobj : address.getChildElements()){       
                for(DOM.XMLNode xmlnodeobj1 : xmlnodeobj.getChildElements()){     
                    for(DOM.XMLNode xmlnodeobj2 : xmlnodeobj1.getChildElements()){   
                        if(xmlnodeobj2.getName() == 'Message'){
                            responseStatus = xmlnodeobj2.getText();
                            List<String> messageList = responseStatus.split(';');
                            if(messageList.size() > 1){
                                responseStatus = messageList[1];
                                if(messageList[1].contains('errorCode=')){
                                    responseStatus = messageList[1].replace('errorCode=', '');
                                }
                            }
                        }   
                    }   
                }  
            }
            new LogService().createErrorLog('AccountingIntegrationSettingsCtrl', 'getQBCompanyInfo()', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              null, LogService.QUICKBOOKS);     
        }
        update qbConfig;
        update ifwConfigList;
        String response = BPUtility.getDecodedString(getAccountingSettingDetails());
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper(responseStatus, response)));
    }
    
    @RemoteAction
    global static String getConnectedCompanyInfo(String integrationName) {
    	integrationName = BPUtility.getDecodedString(integrationName);
    	try {
            return BPUtility.getEncodedString(AccountingIntegrationSettingsService.getConnectedCompanyInfo(integrationName));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String syncAccounts() {
        Integer APICount = 0;
        List<AccountWrapper> accountList = new List<AccountWrapper>();
        QueryResponseWrapper accountInfo;
        do{
            accountInfo = new QueryResponseWrapper();
            String query = 'SELECT Id, Name, AcctNum, AccountType, Active, AccountSubType, TaxCodeRef FROM Account WHERE Active IN (true, false) ';
            if(APICount != 0){
                query += 'STARTPOSITION '+ ((APICount * 100) + 1);
            }
            query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
            query += '&minorversion=3';
            
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('query?query='+query, null);
			HttpResponse res = responseObj.Response;
			if(responseObj.RefreshToken !=  null) {
				QBUtil.saveRefreshToken(responseObj.RefreshToken, responseObj.RefreshTokenExpiresIn);
			}
            if(res.getStatusCode() == 200){
                accountInfo = (QueryResponseWrapper) System.JSON.deserialize(res.getBody(), QueryResponseWrapper.class);
                if(accountInfo.QueryResponse != null && accountInfo.QueryResponse.Account != null && accountInfo.QueryResponse.Account.size() > 0) {
                    accountList.addAll(accountInfo.QueryResponse.Account);
                }
            } else {
                new LogService().createErrorLog('AccountingIntegrationSettingsCtrl', 'syncAccounts()', res.getBody(), res.getStatusCode(), null, 
                                              null, LogService.QUICKBOOKS);
            }
            APICount++;
        }while(accountInfo != null && accountInfo.QueryResponse != null && accountInfo.QueryResponse.Account != null && accountInfo.QueryResponse.Account.size() == 100);
        
        String responseStatus = ''; 
        if(accountList.size()>0) {
            Map<String, General_Account__c> generalAccountIdToRecMap = new Map<String, General_Account__c>([SELECT Id, Accounting_Id__c from General_Account__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()]);
            List<General_Account__c> existingGeneralAccountList = generalAccountIdToRecMap.values();
            Map<String, String> existingGeneralAccountIdToSFIdMap = new Map<String, String>();
            for(General_Account__c GLAcc : existingGeneralAccountList){
                existingGeneralAccountIdToSFIdMap.put(GLAcc.Accounting_Id__c, GLAcc.Id);
            }
            List<General_Account__c> GLAccountList = new List<General_Account__c>();
            General_Account__c GLAccount;
            Boolean isActiveGLAccount = false;
            for(AccountWrapper acc : accountList){
                GLAccount = new General_Account__c(); 
                isActiveGLAccount = (acc.Active != null) ? acc.Active : false;
                if(existingGeneralAccountIdToSFIdMap.containsKey(acc.Id)){
                    GLAccount.Id = existingGeneralAccountIdToSFIdMap.get(acc.Id);
                    if(isActiveGLAccount) {
                        generalAccountIdToRecMap.remove(existingGeneralAccountIdToSFIdMap.get(acc.Id));
                    }
                }
                GLAccount.Accounting_Id__c = acc.Id;
                GLAccount.Account_Number__c = acc.AcctNum;
                GLAccount.Account_Name__c = acc.Name;
                GLAccount.Account_Type__c = acc.AccountType;
                GLAccount.Is_Active__c = isActiveGLAccount;
                GLAccount.Account_Detail_Type__c = acc.AccountSubType;
                GLAccount.Account_Tax_Rate__c = acc.TaxCodeRef != null ? acc.TaxCodeRef.value : null;
                if(isActiveGLAccount) {
                    GLAccountList.add(GLAccount);
                }
            }
            if(generalAccountIdToRecMap.values().size() > 0) {
                delete generalAccountIdToRecMap.values();
            }
            if(GLAccountList.size() > 0){
                DMLUtility.upsertSobjectList('General_Account__c', GLAccountList);
                AccountingUtil.validateChartOnAccounts();
                responseStatus = 'success';
            }
        } else {
            responseStatus = 'Please check your QuickBooks Online connection';
        }
        String response = BPUtility.getDecodedString(getAccountingSettingDetails());
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper(responseStatus, response)));
    }
    
    @RemoteAction
    global static String getChartOfAccounts(String integrationName) {
    	integrationName = BPUtility.getDecodedString(integrationName);
    	try {
            return BPUtility.getEncodedString(AccountingIntegrationSettingsService.getChartOfAccounts(integrationName));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String syncTaxCodes(String integrationName) {
    	integrationName = BPUtility.getDecodedString(integrationName);
    	try {
            return BPUtility.getEncodedString(AccountingIntegrationSettingsService.syncTaxCodes(integrationName));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getMasterDataForServiceJobType() {
        return BPUtility.getEncodedString(System.JSON.serialize(ServiceJobTypeService.getMasterDataForServiceJobType(), true));
    }
    
    @RemoteAction
    global static String getAllServiceJobTypes() {
        return BPUtility.getEncodedString(System.JSON.serialize(ServiceJobTypeService.getAllServiceJobTypes(), true));
    }
    
    @RemoteAction
    global static String saveJobType(String ttListJSON) {
        ttListJSON = BPUtility.getDecodedString(ttListJSON);
        return BPUtility.getEncodedString(ServiceJobTypeService.saveJobType(ttListJSON));
    }
    
   @RemoteAction
   global static String saveControlAccounts(String DefaultAccountJSON) {
        DefaultAccountJSON = BPUtility.getDecodedString(DefaultAccountJSON);
        Accounting_Default_Accounts__c accDefaultConfig = Accounting_Default_Accounts__c.getOrgDefaults();
        AccountingSettingWrapper.DefaultAccountWrapper accountingWrapperObj = (AccountingSettingWrapper.DefaultAccountWrapper) System.JSON.deserialize(DefaultAccountJSON, AccountingSettingWrapper.DefaultAccountWrapper.class);
        
        if(checkCustomerDepositInUndepositedGL(accountingWrapperObj.CustomerDeposits)) {
            throw new BlackpurlException('This GL is already being used as an Undeposited Funds GL, please select a different GL account');
        }

        accDefaultConfig.Undeposited_Funds__c = accountingWrapperObj.UndepositedFunds;
        accDefaultConfig.Customer_Deposits__c = accountingWrapperObj.CustomerDeposits;
        accDefaultConfig.A_P_Inventory_Accrual__c = accountingWrapperObj.APInventoryAccrual;
        accDefaultConfig.Inventory_Adjustments__c = accountingWrapperObj.InventoryAdjustments;
        accDefaultConfig.Cash_Rounding__c = accountingWrapperObj.CashRounding;
        accDefaultConfig.Store_Credit_Accrual__c = accountingWrapperObj.StoreCreditAccural;
        accDefaultConfig.Store_Credit_Expense__c = accountingWrapperObj.StoreCreditExpense;
        accDefaultConfig.Stamp_Duty_Accrual__c = accountingWrapperObj.StampDutyAccrual;
        accDefaultConfig.Cash_Sale_Customer_Id__c = accountingWrapperObj.CashSaleCustomer;
        accDefaultConfig.Internal_Service_Customer_Id__c = accountingWrapperObj.InternalServiceCustomer;
        accDefaultConfig.Undeposited_Direct_Deposit__c = accountingWrapperObj.UndepositedDirectDeposit;
        accDefaultConfig.Undeposited_Financing__c = accountingWrapperObj.UndepositedFinancing;
        accDefaultConfig.Deal_Option_Clearing__c = accountingWrapperObj.DealOptionClearing;
        accDefaultConfig.WIP_Labor_Inventory__c = accountingWrapperObj.WIPLaborInventory;
        accDefaultConfig.WIP_Labor_Expense__c = accountingWrapperObj.WIPLaborExpense;
        upsert accDefaultConfig;
        
		updateSpecialCategories(accountingWrapperObj);
        return getAccountingSettingDetails();
    }

    private static Boolean checkCustomerDepositInUndepositedGL(String customerDepositGL) {
        Set<String> unDepositedPaymentSet = new set<String>();
		for(Payment_Method__c paymentMethodRec : [SELECT Undeposited_Funds__c FROM Payment_Method__c WHERE Undeposited_Funds__c != null AND (Is_Active__c = true OR Is_Only_Updeposited_Payment_Method__c = true)] ) {
            unDepositedPaymentSet.add(paymentMethodRec.Undeposited_Funds__c);
		}
        return unDepositedPaymentSet.contains(customerDepositGL);
    }
    
    private static void updateSpecialCategories(AccountingSettingWrapper.DefaultAccountWrapper accountingWrapperObj) {
		if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		Map<String, List<String>> categoryTypeToCategoryValueListMap = new Map<String, List<String>>{'Stamp Duty' => new List<String>{accountingWrapperObj.StampDutyClearing, 'Stamp Duty Default'},
        																			 'Deductible' => new List<String>{accountingWrapperObj.ClaimDeductibleClearing, 'Deductible Default'}, 
        																			 'Stocked Trade' => new List<String>{accountingWrapperObj.StockedTradeClearing, 'Stocked Trade Default'},
        																			 'Lien Payout' => new List<String>{accountingWrapperObj.LienPayoutClearing, 'Lien Payout'},
        																			 CONSIGNMENT_CLEARING => new List<String>{accountingWrapperObj.ConsignmentClearing, CONSIGNMENT_CLEARING},
                                                                                     'Customer Deposits' => new List<String>{accountingWrapperObj.CustomerDeposits, 'Customer Deposits Default'} 
        																			 };
		
		List<Category__c> categoryRecList = [SELECT Name, Income_GL__c, Type__c FROM Category__c WHERE Type__c IN: categoryTypeToCategoryValueListMap.keySet() AND Default__c = true];
		List<Category__c> categoryRecUpdateList = new List<Category__c>();
		for(Category__c categoryRec : categoryRecList) {
			categoryRecUpdateList.add(setIncomeGLOfCategory(categoryTypeToCategoryValueListMap.get(categoryRec.Type__c)[0], categoryRec, null, null));
			categoryTypeToCategoryValueListMap.remove(categoryRec.Type__c);
		}
		for(String categoryType : categoryTypeToCategoryValueListMap.keySet()) {
			categoryRecUpdateList.add(setIncomeGLOfCategory(categoryTypeToCategoryValueListMap.get(categoryType)[0], null, categoryTypeToCategoryValueListMap.get(categoryType)[1], categoryType));
		}
		if(AccessControl.ifObjectIsCreateable('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		if(AccessControl.ifObjectIsUpdateable('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		if(categoryRecUpdateList.size() > 0) {
			upsert categoryRecUpdateList;
		}
    }
    
    private static Category__c setIncomeGLOfCategory(String incomeGL, Category__c categoryRec, String categoryName, String categoryType) {
    	if(categoryRec == null) {
    		categoryRec = new Category__c(Name = categoryName, Description__c = categoryName, Type__c = categoryType, Default__c = true);
    	}
		categoryRec.Income_GL__c = incomeGL;
		return categoryRec;
    }
    
    @RemoteAction
    global static String saveDefaultAccounts(String DefaultAccountJSON){
        DefaultAccountJSON = BPUtility.getDecodedString(DefaultAccountJSON);
        Accounting_Default_Accounts__c accDefaultConfig = Accounting_Default_Accounts__c.getOrgDefaults();
        AccountingSettingWrapper.DefaultAccountWrapper accountingWrapperObj = (AccountingSettingWrapper.DefaultAccountWrapper) System.JSON.deserialize(DefaultAccountJSON, AccountingSettingWrapper.DefaultAccountWrapper.class);
        accDefaultConfig.Sales_Income__c = accountingWrapperObj.SalesIncome;
        accDefaultConfig.Cost_of_Goods_Sold__c = accountingWrapperObj.CostofGoodsSold;
        accDefaultConfig.Inventory__c = accountingWrapperObj.Inventory;
        accDefaultConfig.Miscellaneous_Income__c = accountingWrapperObj.MiscellaneousIncome;
        accDefaultConfig.Sales_Tax__c = accountingWrapperObj.SalesTax;
        upsert accDefaultConfig;
        return getAccountingSettingDetails();
    }
    
    @remoteAction 
    global static String checkCategory(String categoryId){
        categoryId = BPUtility.getDecodedString(categoryId);
        List<String> categoryChildRelationshipNames = new List<String>{'Customer_Owned_Units__r',
        																'Labour_Codes__r',
                                                                        'Fees__r',
                                                                        'Parts__r',
                                                                        'Products__r',
                                                                        'Sales_Tax_Items__r',
                                                                        'Unit_Models__r'};
        String query = '';
        String ErrorMessage = '';
        query = 'SELECT Id'; 
        for (String childRelationshipName :  categoryChildRelationshipNames) 
        {
            query += ', (SELECT Id From '+Constants.NAMESPACE + '' +childRelationshipName+' LIMIT 1)';
        }
        query += ' FROM ' + Constants.NAMESPACE + 'Category__c ';
        if(categoryId != null) {
            query += 'WHERE Id = : categoryId'; 
        }
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Category__c> categoryList = Database.query(query);
    
        String presentedEntites = '';
        if(categoryList.size() > 0){
            for (String childRelationshipName :  categoryChildRelationshipNames){
                if(categoryList[0].getSObjects(Constants.NAMESPACE + '' +childRelationshipName) != null &&
                    categoryList[0].getSObjects(Constants.NAMESPACE + '' +childRelationshipName).size() > 0){
                    presentedEntites += ((childRelationshipName.replace('s__r', '')).replace('_', ' ')) + ',';
                }
            }   
        }
        
        if(presentedEntites.length() > 0){
            presentedEntites = presentedEntites.substring(0, presentedEntites.length() - 1);
            Integer endIndex = presentedEntites.lastIndexOf(',');
            if (endIndex != -1) {
                presentedEntites = presentedEntites.substring(0, endIndex) + ' and ' +presentedEntites.substring(endIndex+1,  presentedEntites.length());
            }
            presentedEntites = presentedEntites.replace('Customer Owned Unit', 'Unit');
            ErrorMessage = 'This category cannot be removed as it is currently in use on a '+presentedEntites+' in your application';
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('Error', ErrorMessage)));
        }
        
        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('Success', 'Successfully deleted')));
    }
    
    
    @remoteAction 
    global static String removeGeneralAccounts() {
        List<Accounting_Default_Accounts__c> accDefaultAccountList = [Select Id from Accounting_Default_Accounts__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
        Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults();
        List<General_Account__c> existingGeneralAccountList = [select Id, Accounting_Id__c, Account_Name__c,
                                                                Account_Type__c, LastModifiedDate
                                                                 from General_Account__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
                                                                 
        List<Category__c> categoryList = SOQLUtil.getAllCategoryDetails();
        for(Category__c c : categoryList){
            c.COGS_GL__c = '';
            c.Income_GL__c = '';
            c.Inventory_GL__c = '';
        }
        accConfig.Alignment_Method__c = '';
        try {
            if(!General_Configurations__c.getOrgDefaults().Is_Preserve_QB_Config__c) {
                delete accDefaultAccountList;
                delete existingGeneralAccountList;
                update accConfig;
                update categoryList;
            }
        }catch(Exception e){
            //system.assert(false, e);
        }
        return getAccountingSettingDetails();       
    }
    
    @remoteAction 
    global static String getQBTaxCodes() {
    	try {
	        return BPUtility.getEncodedString(system.JSON.serialize(QBIntegrationService.getTaxCodes(), true));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction 
    global static String getQBNonTaxableTaxCodes() {
    	try {
	        return BPUtility.getEncodedString(system.JSON.serialize(QBIntegrationService.getNonTaxableTaxCodes(), true));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction 
    global static String getTaxRates() {
    	try {
	        return BPUtility.getEncodedString(system.JSON.serialize(QBIntegrationService.getTaxRates(), true));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction 
    global static String getSalesTaxList() {
    	try {	        
	        List<Sales_Tax__c> salesTaxList = getSalesTaxWithApplicableTaxList();
	        List<SalesTax> salesTaxRecList = new List<SalesTax>();
	        for(Sales_Tax__c salesTax: salesTaxList) {
	        	salesTaxRecList.add(new SalesTax(salesTax, salesTax.Applicable_Taxes__r));
	        }
	        return BPUtility.getEncodedString(system.JSON.serialize(salesTaxRecList, true));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    private static List<Sales_Tax__c> getSalesTaxWithApplicableTaxList() {
    	String query;
        query = 'SELECT '; 
        for(String fieldsName : TaxCodeWrapper.salesTaxFieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        
        // Child Query: fields of Applicable_Taxes
        query += '(SELECT  Sales_Tax_Item__c, Sales_Tax_Item__r.AccountingId__c, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c FROM Applicable_Taxes__r WHERE Sales_Tax_Item__r.Active__c = true), '; 
        query = query.substring(0, query.length()-2);
        
        query += ' FROM ' + Constants.NAMESPACE + 'Sales_Tax__c WHERE Active__c = true';
        query += ' order by Default__c DESC, Active__c Desc, Name__c';
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Sales_Tax__c> salesTaxList = Database.query(query);
        return salesTaxList;
    }
    
    @remoteAction 
    global static String getSalesTaxItemList() {
    	try {
	        List<Sales_Tax_Item__c> salesTaxItemList = SOQLUtil.getActiveSalesTaxItemList(new List<Id>());
        
	        List<SalesTaxItem> salesTaxItemRecList = new List<SalesTaxItem>();
	        for(Sales_Tax_Item__c salesTaxItem: salesTaxItemList) {
	        	salesTaxItemRecList.add(new SalesTaxItem(salesTaxItem));
	        }
	        return BPUtility.getEncodedString(system.JSON.serialize(salesTaxItemRecList, true));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String saveSalesTaxMappingForQB(String salesTaxListJson) {
    	salesTaxListJson = BPUtility.getDecodedString(salesTaxListJson);
    	try {
    		QBIntegrationService.saveSalesTaxMapping(salesTaxListJson);
	        return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String saveSalesTaxItemMappingForQB(String salesTaxItemListJson) {
    	salesTaxItemListJson = BPUtility.getDecodedString(salesTaxItemListJson);
    	try {
    		QBIntegrationService.saveSalesTaxItemMapping(salesTaxItemListJson);
	        return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction 
    global static String saveNonTaxableTaxCodeMappingForQB(String accountingConfigurationJson) {
    	accountingConfigurationJson = BPUtility.getDecodedString(accountingConfigurationJson);
    	AccountingSettingWrapper.ConfigurationWrapper configObj = (AccountingSettingWrapper.ConfigurationWrapper)System.JSON.deserialize(accountingConfigurationJson, AccountingSettingWrapper.ConfigurationWrapper.class);
    	try {
    		QBIntegrationService.saveNonTaxableTaxCodeMapping(configObj.NonTaxableTaxCode, configObj.NonTaxablePurchaseTaxCode, configObj.NITCWithHeldTaxCode, 
    												configObj.NITCClaimedTaxCode);
	        return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    } 
    
    @remoteAction 
    global static String syncTaxCodesWithQuickbooks() {
        QBIntegrationService.syncTaxCodesWithQuickbooks();  
        return 'Success';    
    }
    
    @remoteAction 
    global static String syncTaxRatesWithQuickbooks() {
        QBIntegrationService.syncTaxRatesWithQuickbooks();  
        return 'Success';    
    }
    
    @remoteAction 
    global static String removeAccountingData() {
        try {
        	QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
        	qbConfig.Enable_QuickBooks__c = false;
	        qbConfig.Consumer_Key__c = null;
	        qbConfig.Consumer_Secret__c = null;
	        qbConfig.OAuth_Token__c = null;
	        qbConfig.OAuth_Token_Secret__c = null;
	        qbConfig.End_Point_URL__c = null;
	        qbConfig.Tax_Code_Sync_Response__c = null;
	        
	        if(XeroUtility.isXeroOAuth2Enabled()) {
	        	try {
	        	    HttpResponse res = AccountingIntegrationSettingsService.removeXeroConnection(qbConfig);
	        	} catch(Exception e) {
	        	    //system.assert(false, res.getStatusCode() + '  ' + res.getBody());
	        	}
	        	qbConfig.Company_Id__c = null;
	        	qbConfig.Connection_Id__c = null;
	        } else if(QBUtil.isQBEnabled()) {
	        	try {
	        		HttpResponse res = AccountingIntegrationSettingsService.removeQBConnection();
	        		if(res.getStatusCode() != 200) {
	        			// create info log
	        			new LogService().createErrorLog('AccountingIntegrationSettingsCtrl', 'removeAccountingData()', res.getBody(), String.valueOf(res.getStatusCode()), LogService.NOT_APPLICABLE, 
                                              '', LogService.QuickBooks, true, 'Info');
	        		}
	        	} catch(Exception e) {
	        		// create info log
	        		new LogService().createErrorLog('AccountingIntegrationSettingsCtrl', 'removeAccountingData()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                              '', LogService.QuickBooks, true, 'Info');
	        	}
	        	qbConfig.Company_Id__c = null;
	        	qbConfig.Company_Name__c = null;
	        	qbConfig.Company_Country__c = null;
	        }
	        upsert qbConfig;
	        
	        List<IFW_IntegrationConfig__c> activeIntegrationConfigList = new List<IFW_IntegrationConfig__c>();
	        
	        if(QBUtil.isQBEnabled()) {
	        	activeIntegrationConfigList = AccountingIntegrationSettingsService.getQuickBooksIFWConfig();
	        } else {
	        	activeIntegrationConfigList = 
	        	      [SELECT Id FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true AND Integration_Name__c = 'Xero'];
	        }
    		if(activeIntegrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
    		
    		activeIntegrationConfigList[0].Access_Token__c = null;
    		activeIntegrationConfigList[0].Access_Token_Secret__c = null;
			activeIntegrationConfigList[0].Token_Expiry__c = null;
			activeIntegrationConfigList[0].Refresh_Token__c = null;
			activeIntegrationConfigList[0].Token_Type__c = null;
    		update activeIntegrationConfigList[0];
    		
            if(!General_Configurations__c.getOrgDefaults().Is_Preserve_QB_Config__c) {
                removeRelatedConfigWhileRemovingConnection();
            }
        } catch(Exception e) {
            //system.assert(false, e.getMessage());
        }
        return getAccountingSettingDetails();       
    }
    
    public static void removeRelatedConfigWhileRemovingConnection() {
        delete [SELECT Id FROM Accounting_Settings__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
        delete [SELECT Id FROM Accounting_Default_Accounts__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
        delete [SELECT Id FROM General_Account__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
                                                         
        List<Category__c> categoryList = SOQLUtil.getAllCategoryDetails();
        for(Category__c categoryRec : categoryList){
            categoryRec.COGS_GL__c = '';
            categoryRec.Income_GL__c = '';
            categoryRec.Inventory_GL__c = '';
        }
        update categoryList;
    }
    
    @RemoteAction
    global static String getUndepositedFundPaymentMethod() {
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(AccountingIntegrationSettingsService.getUndepositedFundPaymentMethod()));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static void saveUndepositedFundPaymentMethod(String jsonString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        try {
            AccountingIntegrationSettingsService.saveUndepositedFundPaymentMethod(jsonString);  
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    public class ResponseWrapper{
        public String responseStatus;
        public String response;
        
        public ResponseWrapper(String responseStatus, String response){
            this.responseStatus = responseStatus;
            this.response = response;
        }
    }
    
    public class CompanyInfoWrapper {
        public CompanyInfo companyInfo;
    }
    public class CompanyInfo {
        public String CompanyName;
        public String Country;
    }
    public class QueryResponseWrapper{
        public AccountQueryResponseWrapper QueryResponse;
    }
    public class AccountQueryResponseWrapper{
        public List<AccountWrapper> Account;
    }
    public class AccountWrapper{
        public String Name;
        public String AccountType;
        public String AcctNum;
        public Boolean Active;
        public String AccountSubType;
        public TaxCodeInfo TaxCodeRef;
        public String Id;
    }
    public class TaxCodeInfo {
        public String value;
    }
}