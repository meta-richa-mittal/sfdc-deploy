public without sharing class AccountingIntegrationSettingsService {
    
	private static final String UNDEPOSITED_STRING = 'Undeposited ';
	public static final String ID_STRING = 'ID';
	public static final Integer RECORDS_PER_PAGE = 100;

    public static ResponseWrapper OAuthConnectionStep1(String consumerKey, String consumerSecret, String integrationName) {
        if(integrationName == XeroUtility.XERO) {
			saveAccountSettingsData(integrationName);
			saveClientIdAndSecret(consumerKey, consumerSecret, integrationName);
			return new ResponseWrapper('success', createXeroAuthorizeURL(consumerKey, consumerSecret));
        } else if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
			return oAuthConnectionStep1ForQB(consumerKey, consumerSecret, integrationName);
		}
		return new ResponseWrapper('', '');
    }

    public static String getConnectedCompanyInfo(String integrationName) {
		Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
		if(integrationName != QBUtil.QUICKBOOKS_ONLINE) {
			integrationEntityNameToActionMap.put(IntegrationUtility.ORGANISATION, null);
		}
        
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(integrationName, integrationEntityNameToActionMap, false);
        if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
        
		ResponseWrapper resObj;
		QuickBooks_Configurations__c integrationConfig = QuickBooks_Configurations__c.getOrgDefaults();
        if(integrationName == XeroUtility.XERO) {
			resObj = getXeroCompanyInfo(integrationConfigList, integrationConfig);
        } else if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
			resObj = getQBCompanyInfo(integrationConfigList[0], integrationConfig);
		}
        return System.JSON.serialize(resObj);
    }
    
    public static String getChartOfAccounts(String integrationName) {
		Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
		if(integrationName != QBUtil.QUICKBOOKS_ONLINE) {
			integrationEntityNameToActionMap.put(IntegrationUtility.Account, null);
		}

		List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(integrationName, integrationEntityNameToActionMap, false);
		if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');

		if(integrationName == XeroUtility.XERO) {
			return getChartOfAccountsFromXero(integrationConfigList);
		} else if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
			return getChartOfAccountsFromQB(integrationConfigList[0]);
		}
		return null;
    }

	public static String syncTaxCodes(String integrationName) {
		Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
		if(integrationName != QBUtil.QUICKBOOKS_ONLINE) {
			integrationEntityNameToActionMap.put(IntegrationUtility.TAX_RATE, null);
		}

		List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(integrationName, integrationEntityNameToActionMap, false);
		if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');

		if(integrationName == XeroUtility.XERO) {
			return syncTaxCodesFromXero(integrationConfigList);
		} else if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
			return syncTaxCodesFromQB(integrationConfigList[0]);
		}
		return null;
    }

	public static String syncTaxRates(String integrationName) {
		List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(integrationName, new Map<String, String>(), false);
		if(integrationConfigList.size() == 0) throw new BlackpurlException('No active integration');
		return syncTaxRatesFromQB(integrationConfigList[0]);
    }

	// START - QB methods
	private static ResponseWrapper oAuthConnectionStep1ForQB(String clientId, String clientSecret, String integrationName) {
		Map<String, Object> fieldsMap = new Map<String, Object>{'Integration_Name__c' => QBUtil.QUICKBOOKS_ONLINE, 'Enabled__c' => true};
        List<IFW_IntegrationConfig__c> ifwConfigList = IFW_SOQLUtil.getIntegrationConfig(fieldsMap);
		if(ifwConfigList.size() == 0 || String.isBlank(ifwConfigList[0].Client_Id_Long__c) || String.isBlank(ifwConfigList[0].Client_Secret_Long__c)) {
			throw new BlackPurlException('Some configurations are missing.');
		}
		clientId = ifwConfigList[0].Client_Id_Long__c;
		clientSecret = ifwConfigList[0].Client_Secret_Long__c;
		try {
			saveAccountSettingsData(integrationName);
			
			QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
			if(String.isBlank(qbConfig.End_Point_URL__c)) {
				if(QBUtil.isQBOSanboxEnvironment()) {
					qbConfig.End_Point_URL__c = QBUtil.SANDBOX_END_POINT_URL;
				} else {
					qbConfig.End_Point_URL__c = QBUtil.PRODUCTION_END_POINT_URL;
				}
			}
			upsert qbConfig;
			return new ResponseWrapper('success', createQBAuthorizeURL(clientId, clientSecret));
		} catch(Exception e) {
			new LogService().createErrorLog('AccountingIntegrationSettingsService', 'OAuthConnectionStep1', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
											clientId + LogService.METHOD_PARAM_SEPERATOR + clientSecret, LogService.QUICKBOOKS, true);
			return new ResponseWrapper(e.getMessage(), '');
		}
	}

	private static String createQBAuthorizeURL(String clientId, String clientSecret) {
    	String redirectUrl = 'https://appcenter.intuit.com/connect/oauth2' +
	    				'?client_id='+ clientId + '&response_type=code&scope=com.intuit.quickbooks.accounting' + 
						'&state=blackpurl&redirect_uri=' + createRedirectURI('QBO');
	   	return redirectUrl;
    }

	private static String createRedirectURI(String integrationType) {
		String redirectURI = 'https://login.salesforce.com/apex/' ;
		if(integrationType == 'QBO'){
			redirectURI += Constants.NAMESPACE + 'Quickbooks_oauth_callback';
		} else if(integrationType == 'Xero'){
			redirectURI += Constants.NAMESPACE + 'Oauth_callback';
		}
		return redirectURI;
	}

	private static ResponseWrapper getQBCompanyInfo(IFW_IntegrationConfig__c ifwConfigRec, QuickBooks_Configurations__c qbConfig) {
		String responseStatus = '', responseString = '';
		try {
			QBResponseWrapper resObj = QBCalloutManager.getDataByQBId('companyinfo', qbConfig.Company_Id__c, ifwConfigRec);

			if(resObj != null) {
				qbConfig.Company_Name__c = resObj.CompanyInfo.CompanyName;
				qbConfig.Enable_QuickBooks__c = true;
				qbConfig.Company_Country__c = resObj.CompanyInfo.Country;
				for(QBInnerEntityWrapper nameValueRec : resObj.CompanyInfo.nameValue) {
					if(nameValueRec.Name == 'OfferingSku') {
						qbConfig.Integration_Version__c = nameValueRec.Value;
					}
				}
				responseStatus = 'success';

				// get multi currency information
				QBUtil.setCurrencyRef(qbConfig, ifwConfigRec);
				DMLUtility.updateSobjectList('QuickBooks_Configurations__c', qbConfig);
			}
		} catch(Exception e) {
			responseStatus = e.getMessage();
		}
		QBCalloutManager.updateRecords(ifwConfigRec);
		responseString = BPUtility.getDecodedString(AccountingIntegrationSettingsCtrl.getAccountingSettingDetails());
		return new ResponseWrapper(responseStatus, responseString);
	}

	private static String getChartOfAccountsFromQB(IFW_IntegrationConfig__c ifwConfigRec) {
		Integer pageNumber = 0;
		String responseStatus; 
        List<QBQueryResponseWrapper.AccountWrapper> charOfAccounts;
		List<QBQueryResponseWrapper.AccountWrapper> charOfAccountList = new List<QBQueryResponseWrapper.AccountWrapper>();

		try {
			do {
				charOfAccounts = getPaginatedChartOfAccountsFromQB(pageNumber, ifwConfigRec);
				charOfAccountList.addAll(charOfAccounts);
				pageNumber++;
			} while(charOfAccounts.size() >= RECORDS_PER_PAGE);
		} catch(Exception e) {
			responseStatus = e.getMessage();
		}
		
		QBCalloutManager.updateRecords(ifwConfigRec);

		if(charOfAccountList.size() > 0) {
			Map<String, General_Account__c> generalAccountIdToRecMap = new Map<String, General_Account__c>([SELECT Id, Accounting_Id__c from General_Account__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()]);
			Map<String, String> existingGeneralAccountIdToSFIdMap = new Map<String, String>();
			for(General_Account__c GLAcc : generalAccountIdToRecMap.values()) {
				existingGeneralAccountIdToSFIdMap.put(GLAcc.Accounting_Id__c, GLAcc.Id);
			}
			List<General_Account__c> GLAccountList = new List<General_Account__c>();
			General_Account__c GLAccount;
			Boolean isActiveGLAccount = false;
			for(QBQueryResponseWrapper.AccountWrapper acc : charOfAccountList) {
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
			DMLUtility.deleteSobjectList('General_Account__c', generalAccountIdToRecMap.values());
			if(GLAccountList.size() > 0){
				DMLUtility.upsertSobjectList('General_Account__c', GLAccountList);
				AccountingUtil.validateChartOnAccounts();
				responseStatus = 'success';
			}
		} else {
			responseStatus = 'error';
		}
		return responseStatus;
	}

	private static List<QBQueryResponseWrapper.AccountWrapper> getPaginatedChartOfAccountsFromQB(Integer pageNumber, IFW_IntegrationConfig__c ifwConfigRec) {
		List<String> filterConditions = new List<String>{'Active IN (true, false)'};
        QBQueryResponseWrapper.QBResponseWrapper resObj = QBCalloutManager.getData(IntegrationUtility.ACCOUNT, filterConditions, ifwConfigRec, pageNumber, RECORDS_PER_PAGE);        
		if(resObj != null && resObj.Account != null && resObj.Account.size() > 0) {
			return resObj.Account;
		} else {
			return new List<QBQueryResponseWrapper.AccountWrapper>();
		}
	}

	private static String syncTaxCodesFromQB(IFW_IntegrationConfig__c ifwConfigRec) {
		Integer pageNumber = 0;
        Set<String> taxRatesAccountingIdSet = new Set<String>(); 
        List<QBTaxCodeWrapper> taxCodesOnQuickbooks = new List<QBTaxCodeWrapper>();
        List<QB_TaxCode__c> qbTaxCodeRecordsToInsert = new List<QB_TaxCode__c>();
        List<QBTaxCodeWrapper>  taxCodeResponseList;
		String responseStatus = 'Success';
		try {
			do{
				taxCodeResponseList = getPaginatedTaxCodesFromQB(pageNumber, ifwConfigRec);
				taxCodesOnQuickbooks.addAll(taxCodeResponseList);
				pageNumber++;
			} while(taxCodeResponseList.size() >= RECORDS_PER_PAGE);
		} catch(Exception e) {
			responseStatus = e.getMessage();
		}
		QBCalloutManager.updateRecords(ifwConfigRec);      

		if(taxCodesOnQuickbooks.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('QB_TaxCode__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            Delete [Select Id from QB_TaxCode__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
            
            for(QBTaxCodeWrapper qbTaxCode : taxCodesOnQuickbooks){
                String childSalesTaxRateString = '';
                String childPurchaseTaxRateString = '';
                if(qbTaxCode.SalesTaxRateList != null && qbTaxCode.SalesTaxRateList.TaxRateDetail != null && qbTaxCode.SalesTaxRateList.TaxRateDetail.size() > 0) {
                    
                    for(QBTaxCodeWrapper.TaxRateDetailWrapper childSalesTaxRate : qbTaxCode.SalesTaxRateList.TaxRateDetail) {
                        String taxRateAccId = childSalesTaxRate.TaxRateRef.value;
                        taxRatesAccountingIdSet.add(taxRateAccId);
                        childSalesTaxRateString += String.isNotBlank(taxRateAccId)?  (taxRateAccId+';') : '';
                    }
                    
                }
                if(qbTaxCode.PurchaseTaxRateList != null && qbTaxCode.PurchaseTaxRateList.TaxRateDetail != null && qbTaxCode.PurchaseTaxRateList.TaxRateDetail.size() > 0) {
                    
                    for(QBTaxCodeWrapper.TaxRateDetailWrapper childPurchaseTaxRate : qbTaxCode.PurchaseTaxRateList.TaxRateDetail) {
                        String taxRateAccId = childPurchaseTaxRate.TaxRateRef.value;
                        taxRatesAccountingIdSet.add(taxRateAccId);
                        childPurchaseTaxRateString += String.isNotBlank(taxRateAccId)?  (taxRateAccId+';') : '';
                    }
                    
                }
                String originalTaxCodeName = qbTaxCode.Name;
                if(String.isNotBlank(childSalesTaxRateString)) {
                    childSalesTaxRateString = childSalesTaxRateString.removeEnd(';');
                    qbTaxCode.TaxApplicableOn = QBUtil.SALES;
                    if(String.isNotBlank(childPurchaseTaxRateString)) {
                        qbTaxCode.Name = originalTaxCodeName.length() > 68 ? originalTaxCodeName.subString(0, 68) : originalTaxCodeName;
                        qbTaxCode.Name += ' ('+qbTaxCode.TaxApplicableOn+')';
                    }
                    if(qbTaxCode.Active) {
                        qbTaxCodeRecordsToInsert.add(getTaxCodeWrapperToSObject(qbTaxCode, childSalesTaxRateString));
                    }
                }
                if(String.isNotBlank(childPurchaseTaxRateString)) {
                    qbTaxCode.TaxApplicableOn = QBUtil.PURCHASE;
                    childPurchaseTaxRateString = childPurchaseTaxRateString.removeEnd(';');
                    if(String.isNotBlank(childSalesTaxRateString)) {
                        qbTaxCode.Name = originalTaxCodeName.length() > 68 ? originalTaxCodeName.subString(0, 68) : originalTaxCodeName;
                        qbTaxCode.Name += ' ('+qbTaxCode.TaxApplicableOn+')';
                    }
                    if(qbTaxCode.Active) {
                        qbTaxCodeRecordsToInsert.add(getTaxCodeWrapperToSObject(qbTaxCode, childPurchaseTaxRateString));
                    }
                }
                if(String.isBlank(childPurchaseTaxRateString) && String.isBlank(childSalesTaxRateString) && qbTaxCode.Active) {
                    qbTaxCodeRecordsToInsert.add(getTaxCodeWrapperToSObject(qbTaxCode, null));
                }
            }
            Map<String, QB_Tax_Rate__c> taxRateMap = getAccountingIdToQBTaxRateMap(taxRatesAccountingIdSet);
            for(Integer index=0; index < qbTaxCodeRecordsToInsert.size(); index++){ 
                if(String.isNotBlank(qbTaxCodeRecordsToInsert[index].Applicable_QB_Tax_Rates__c)){
                    for(String acctId : qbTaxCodeRecordsToInsert[index].Applicable_QB_Tax_Rates__c.split(';')) {
                        if(String.isNotBlank(acctId) && taxRateMap.containsKey(acctId)) {
                            qbTaxCodeRecordsToInsert[index].Rate_Value__c += taxRateMap.get(acctId).Rate_Value__c != null ? taxRateMap.get(acctId).Rate_Value__c : 0 ;
                        }
                    }
                }
            }
            DMLUtility.upsertSobjectList('QB_TaxCode__c', qbTaxCodeRecordsToInsert);
        }
		return responseStatus;
	}

	private static List<QBTaxCodeWrapper> getPaginatedTaxCodesFromQB(Integer pageNumber, IFW_IntegrationConfig__c ifwConfigRec) {
        List<String> filterConditions = new List<String>{'Active = true'};
		QBQueryResponseWrapper.QBResponseWrapper resObj = QBCalloutManager.getData('TaxCode', filterConditions, ifwConfigRec, pageNumber, RECORDS_PER_PAGE);        
		if(resObj != null && resObj.TaxCode != null && resObj.TaxCode.size() > 0) {
			return resObj.TaxCode;
		} else {
			return new List<QBTaxCodeWrapper>();
		}
    }

	private static String syncTaxRatesFromQB(IFW_IntegrationConfig__c ifwConfigRec) {
		Integer pageNumber = 0;
		String responseStatus = 'Success';
        List<QBTaxRateWrapper> taxRatesOnQuickbooks = new List<QBTaxRateWrapper>();
        List<QBTaxRateWrapper>  taxRateResponseList;
        
		try {
			do{
				taxRateResponseList = getPaginatedTaxRatesFromQB(pageNumber, ifwConfigRec);
				taxRatesOnQuickbooks.addAll(taxRateResponseList);
				pageNumber++;
			} while(taxRateResponseList.size() >= RECORDS_PER_PAGE);
		} catch(Exception e) {
			responseStatus = e.getMessage();
		}

		QBCalloutManager.updateRecords(ifwConfigRec);       
		
		List<QB_Tax_Rate__c> qbTaxRateRecordsToInsert = new List<QB_Tax_Rate__c>();
        if(taxRatesOnQuickbooks.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('QB_Tax_Rate__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            Delete [Select Id from QB_Tax_Rate__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
            
            for(QBTaxRateWrapper qbTaxRate : taxRatesOnQuickbooks){
                QB_Tax_Rate__c taxRateRec = new QB_Tax_Rate__c();
                taxRateRec.Name = qbTaxRate.Name;
                taxRateRec.Rate_Value__c = qbTaxRate.RateValue;
                taxRateRec.Accounting_Id__c = qbTaxRate.Id;
                taxRateRec.Tax_Agency__c = qbTaxRate.AgencyRef.value;
                taxRateRec.Is_Active__c = qbTaxRate.Active;
                if(qbTaxRate.Active) {
                    qbTaxRateRecordsToInsert.add(taxRateRec);
                }
            }
           DMLUtility.upsertSobjectList('QB_Tax_Rate__c', qbTaxRateRecordsToInsert);
        }
		return responseStatus;
	}

	private static List<QBTaxRateWrapper> getPaginatedTaxRatesFromQB(Integer pageNumber, IFW_IntegrationConfig__c ifwConfigRec) {
		List<String> filterConditions = new List<String>{'Active = true'};
        QBQueryResponseWrapper.QBResponseWrapper resObj = QBCalloutManager.getData('TaxRate', filterConditions, ifwConfigRec, pageNumber, RECORDS_PER_PAGE);        
		if(resObj != null && resObj.TaxRate != null && resObj.TaxRate.size() > 0) {
			return resObj.TaxRate;
		} else {
			return new List<QBTaxRateWrapper>();
		}
    }
	// END - QB methods

	// START - XERO methods
	private static String createXeroAuthorizeURL(String consumerKey, String consumerSecret) {
    	String redirectUrl = 'https://login.xero.com/identity/connect/authorize?response_type=code' +
	    				'&client_id='+ consumerKey + '&redirect_uri=' + createRedirectURI('Xero') +
	    				'&scope=offline_access accounting.settings accounting.transactions accounting.contacts accounting.reports.read&state=blackpurl';
	   	return redirectUrl;
    }

	private static ResponseWrapper getXeroCompanyInfo(List<IFW_IntegrationConfig__c> integrationConfigList, QuickBooks_Configurations__c integrationConfig) {
		List<Log__c> errorLogList = new List<Log__c>();
		String responseStatus = '', responseString = '';
		List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
        if(configItemList.size() == 0) throw new BlackpurlException('Config item for Organization not defined');
		
		HttpResponse response = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], '', new List<customHttpHeaderWrapper>());
		
		// get multi currency information
		configItemList[0].Endpoint_URL__c = configItemList[0].Endpoint_URL__c + 's/Actions';
		String responseStr = XeroUtility.setCurrencyRef(integrationConfig, integrationConfigList[0], configItemList[0]);
		if(responseStr != 'Success') errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsService', 'getConnectedCompanyInfo() -  - get multi currency info', responseStr, LogService.NOT_APPLICABLE, null, 
														XeroUtility.XERO, LogService.XERO, false));
		update integrationConfigList;

		if(response.getStatusCode() == 200) {
			try {
				XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
				responseStatus = 'success';
				List<IntegrationCompanyWrapper> companyJsonList = new List<IntegrationCompanyWrapper>();
				for(XeroOrganisationDTO organisationObj: xeroResponseWrapper.Organisations) {
					companyJsonList.add(new IntegrationCompanyWrapper(organisationObj));
				}
				
				if(companyJsonList.size() == 0) throw new BlackpurlException('Unable to get connected company info');
				saveCompanyInfo(companyJsonList[0], integrationConfig);
				responseString = System.JSON.serialize(new AccountingSettingWrapper.ConfigurationWrapper(Accounting_Settings__c.getOrgDefaults(), QuickBooks_Configurations__c.getOrgDefaults()));
			} catch(Exception e) {
				responseStatus = 'error';
				errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsService', 'getConnectedCompanyInfo()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
									XeroUtility.XERO, LogService.XERO, false));
			}
		} else {
			responseString = System.JSON.serialize((HttpErrorDTO)System.JSON.deserialize(response.getBody(), HttpErrorDTO.class));
			responseStatus = 'error';
			errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsService', 'getConnectedCompanyInfo()', response.getBody(), response.getStatusCode(), null, 
								XeroUtility.XERO, LogService.XERO, false));
		}
		DMLUtility.insertSobjectList('Log__c', errorLogList);

		return new ResponseWrapper(responseStatus, responseString);
	}

	private static String getChartOfAccountsFromXero(List<IFW_IntegrationConfig__c> integrationConfigList) {
		List<Log__c> errorLogList = new List<Log__c>();
        
        List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
        if(configItemList.size() == 0) throw new BlackpurlException('Config item for Account is not defined');

		String responseStatus;
		HttpResponse response = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], '', new List<customHttpHeaderWrapper>());
		update integrationConfigList;
		if(response.getStatusCode() == 200) {
			try {
				XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper) System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
				responseStatus = 'success';

				List<General_Account__c> existingGeneralAccountList = [SELECT Id, Account_Number__c from General_Account__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
				Map<String, String> existingGeneralAccountNumberToSFIdMap = new Map<String, String>(); // because Account Number is unique in Xero
				for(General_Account__c GLAcc : existingGeneralAccountList){
					existingGeneralAccountNumberToSFIdMap.put(GLAcc.Account_Number__c, GLAcc.Id);
				}
				List<General_Account__c> glAccountListToUpsert = new List<General_Account__c>();
				Map<Id,General_Account__c> glAccountIdToRecMapToDelete = new Map<Id,General_Account__c>();
				List<String> glAccountAvailableOnXero = new List<String>();
				for(XeroAccountDTO accObj: xeroResponseWrapper.Accounts){
					General_Account__c glAccount = new General_Account__c(); 
					if(existingGeneralAccountNumberToSFIdMap.containsKey(accObj.Code)){
						glAccount.Id = existingGeneralAccountNumberToSFIdMap.get(accObj.Code);
						glAccountAvailableOnXero.add(existingGeneralAccountNumberToSFIdMap.get(accObj.Code));
					}
					glAccount.Accounting_Id__c = accObj.AccountID;
					glAccount.Account_Number__c = accObj.Code;
					glAccount.Account_Name__c = accObj.Name;
					glAccount.Account_Type__c = accObj.Type;
					glAccount.Is_Active__c = (accObj.Status).equalsIgnoreCase('Active') ? true : false;
					glAccount.Account_Tax_Rate__c = accObj.TaxType;
					glAccount.Payments_Enabled__c = accObj.EnablePaymentsToAccount;
					if(glAccount.Is_Active__c && String.isNotBlank(glAccount.Account_Number__c)) {
						glAccountListToUpsert.add(glAccount);
					} else if(glAccount.Id != null && !glAccountIdToRecMapToDelete.containsKey(glAccount.Id)) {
						glAccountIdToRecMapToDelete.put(glAccount.Id, glAccount);
					}
				}
				for(General_Account__c glAcc : existingGeneralAccountList) {
					if(!glAccountAvailableOnXero.contains(String.valueOf(glAcc.Id)) && !glAccountIdToRecMapToDelete.containsKey(glAcc.Id)) {
						glAccountIdToRecMapToDelete.put(glAcc.Id, new General_Account__c(Id = glAcc.Id));
					}
				}
				if(glAccountListToUpsert.size() > 0) {
					DMLUtility.upsertSobjectList('General_Account__c', glAccountListToUpsert);
					AccountingUtil.validateChartOnAccounts();
				}
				DMLUtility.deleteSobjectList('General_Account__c', glAccountIdToRecMapToDelete.values());
				return system.JSON.serialize(getChartOfAccountsList());
			} catch(Exception e) {
				responseStatus = 'error';
				errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsService', 'getChartOfAccounts()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
											XeroUtility.XERO, LogService.XERO, false));
			}
		} else {
			responseStatus = 'error';
			errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsService', 'getChartOfAccounts()', response.getBody(), response.getStatusCode(), null, 
											XeroUtility.XERO, LogService.XERO, false));
		}
		if(errorLogList.size() > 0) {
            insert errorLogList;
        }
		return responseStatus;
	}

	private static String syncTaxCodesFromXero(List<IFW_IntegrationConfig__c> integrationConfigList) {
    	List<Log__c> errorLogList = new List<Log__c>();
        HttpResponse response;
        String responseStatus = '';
        
        List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
        if(configItemList.size() == 0) throw new BlackpurlException('Config item for Tax rates is not defined');
    	
    	List<QB_TaxCode__c> taxCodeToUpsertList = new List<QB_TaxCode__c>();
		response = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], '', new List<customHttpHeaderWrapper>());
		update integrationConfigList;
		if(response.getStatusCode() == 200) {
			try {
				XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
				responseStatus = 'success';
				List<QBTaxCodeWrapper> taxCodeJsonList = new List<QBTaxCodeWrapper>();
				for(XeroTaxRateDTO taxRateObj: xeroResponseWrapper.TaxRates) {
					taxCodeToUpsertList.add(saveTaxCode(taxRateObj.Name, taxRateObj.Status == 'ACTIVE', true, taxRateObj.TaxType, '', '', taxRateObj.EffectiveRate));
				}
				
				if(taxCodeToUpsertList.size() == 0) throw new BlackpurlException('No tax rates defined');
				
				if(AccessControl.ifObjectIsDeletable('QB_TaxCode__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
				delete [Select Id from QB_TaxCode__c LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
				DMLUtility.upsertSobjectList('QB_TaxCode__c', taxCodeToUpsertList);
			} catch(Exception e) {
				responseStatus = 'error';
				errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsService', 'getTaxCodes()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
												XeroUtility.XERO, LogService.XERO, false));
			}
		} else {
			responseStatus = 'error';
			errorLogList.add(new LogService().createErrorLog('AccountingIntegrationSettingsService', 'getTaxCodes()', response.getBody(), response.getStatusCode(), null, 
												XeroUtility.XERO, LogService.XERO, false));
		}
    	return responseStatus;
    }
	// END - XERO methods

	// can be removed - used in QuickbookConnector class and AccountingIntegrationSettingsCtrl - method not in use
    public static List<IFW_IntegrationConfig__c> getQuickBooksIFWConfig() {
    	List<IFW_IntegrationConfig__c> ifwConfigList = [SELECT Id, Client_Id_Long__c, Client_Secret_Long__c, Refresh_Token__c, Token_Expiry__c FROM IFW_IntegrationConfig__c 
        		WHERE Integration_Name__c =: QBUtil.QUICKBOOKS_ONLINE AND Enabled__c = true];
        return ifwConfigList;
    }
    
    private static List<GeneralAccountWrapper> getChartOfAccountsList() {
    	List<General_Account__c> generalAccountList = [SELECT Restricted__c, Payments_Enabled__c, Accounting_Id__c, Account_Name__c, Account_Number__c,
                                                                Account_Type__c, LastModifiedDate
                                                                 from General_Account__c 
                                                                 WHERE Is_Active__c = true 
                                                                 LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
		    
	    List<GeneralAccountWrapper> accountingList = new List<GeneralAccountWrapper>();
	    for(General_Account__c generalAcc : GeneralAccountList) {
	        accountingList.add(new GeneralAccountWrapper(generalAcc, USerInfo.getTimeZone().getDisplayName()));
	    }
	    return accountingList;
    }
    
    private static void saveAccountSettingsData(String providerName) {
    	Accounting_Settings__c accConfig = Accounting_Settings__c.getOrgDefaults();
    	accConfig.Provider_Name__c = providerName;
    	upsert accConfig;
    }
    
    private static void saveCompanyInfo(IntegrationCompanyWrapper companyJson, QuickBooks_Configurations__c integrationConfig) {
    	integrationConfig.Company_Name__c = companyJson.CompanyName;
    	integrationConfig.Company_Id__c = companyJson.CompanyId;
    	integrationConfig.Enable_QuickBooks__c = true;
		integrationConfig.Home_Currency__c = companyJson.HomeCurrency;
    	upsert integrationConfig;
    }
    
    private static QB_TaxCode__c saveTaxCode(String taxCodeName, Boolean isActive, Boolean isTaxable, String accId, String applicableTaxRateStr, String taxApplicableOn, String rateValue) {
		QB_TaxCode__c taxCodeRec = new QB_TaxCode__c();
		taxCodeRec.Name = taxCodeName;
		taxCodeRec.Is_Active__c = isActive;
		taxCodeRec.Is_Taxable__c = isTaxable;
		taxCodeRec.Accounting_Id__c = accId;
        taxCodeRec.Applicable_QB_Tax_Rates__c = applicableTaxRateStr;
        taxCodeRec.Tax_Applicable_On__c = taxApplicableOn;
        taxCodeRec.Rate_Value__c = Decimal.valueOf(rateValue);
		return taxCodeRec;
    }

    private static void saveClientIdAndSecret(String clientId, String clientSecret, String integrationName) {
    	IFW_IntegrationConfig__c configRec = getIFWConfiguration(integrationName);
        if(clientId != null) configRec.Client_Id__c = clientId;
        if(clientSecret != null) configRec.Client_Secret__c = clientSecret;
        configRec.Enabled__c = true;
        configRec.Auth_Scheme__c = 'OAuth2.0';
        update configRec;
    }

    public static IFW_IntegrationConfig__c getIFWConfiguration(String integrationName) {
        List<IFW_IntegrationConfig__c> integrationConfigList = [SELECT Integration_Name__c, Auth_Scheme__c, Refresh_Token__c, Client_Id__c, Client_Secret__c, Access_Token__c, Access_Token_Secret__c From IFW_IntegrationConfig__c 
                                                                        WHERE Integration_Name__c =: integrationName ORDER BY Name ASC LIMIT 1];
        if(integrationConfigList.size() > 0) {
        	return integrationConfigList[0];
        } else {
        	throw new BlackpurlException('IFW config is not created for ' + integrationName + '.');
        }
    }
    
    public static HttpResponse removeXeroConnection(QuickBooks_Configurations__c qbConfig) {
        return XeroPublicUtility.removeXeroConnection(qbConfig);
    }
    
    public static HttpResponse removeQBConnection() {
    	return QBCalloutManager.disconnect();
    }

	public static List<PaymentMethodWrapper> getUndepositedFundPaymentMethod() {
    	List<PaymentMethodWrapper> paymentMethodObjList = new List<PaymentMethodWrapper>();
        if(!AccessControl.ifObjectFieldIsCreateable('Payment_Method__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Payment_Method__c> paymentMethodRecList = [SELECT Name, Undeposited_Funds__c FROM Payment_Method__c WHERE Is_Active__c = true OR Is_Only_Updeposited_Payment_Method__c = true 
    													ORDER BY Name];
		for(Payment_Method__c paymentMethodRec : paymentMethodRecList) {
			paymentMethodObjList.add(new PaymentMethodWrapper(paymentMethodRec));
		}
    	return paymentMethodObjList;
    }

	private static Boolean checkUndepositedGLInCustomerDeposit(List<PaymentMethodWrapper> paymentMethodList) {
		Boolean isSameCustomerDepositGLExist = false;
		String customerDepositGL = Accounting_Default_Accounts__c.getOrgDefaults().Customer_Deposits__c;
		if(customerDepositGL != null) {
			for(PaymentMethodWrapper paymentMethodObjRec : paymentMethodList ) {
				if(paymentMethodObjRec.UndepositedFunds == customerDepositGL) {
					isSameCustomerDepositGLExist = true;
					break;
				}
			}
		}
		return isSameCustomerDepositGLExist;
	}

	public static void saveUndepositedFundPaymentMethod(String updepositedPaymentJSONString) {
		if(!AccessControl.ifObjectFieldIsUpdateable('Payment_Method__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<PaymentMethodWrapper> paymentMethodObjList = (List<PaymentMethodWrapper>) System.JSON.deserialize(updepositedPaymentJSONString, List<PaymentMethodWrapper>.class);
		if(checkUndepositedGLInCustomerDeposit(paymentMethodObjList)) {
			throw new BlackpurlException('This GL is already being used as the Customer Deposits GL, please select a different GL account');
		}
		Map<String, Payment_Method__c> paymentNameToPaymentMethodMap = new Map<String, Payment_Method__c>();
		for(Payment_Method__c paymentMethodRec : [SELECT Name, Undeposited_Funds__c FROM Payment_Method__c WHERE Is_Active__c = true OR Is_Only_Updeposited_Payment_Method__c = true] ) {
			paymentNameToPaymentMethodMap.put(paymentMethodRec.Name, paymentMethodRec);
		}
		for(PaymentMethodWrapper paymentMethodObjRec : paymentMethodObjList ) {
			if(paymentNameToPaymentMethodMap.containsKey(paymentMethodObjRec.Name.replace(UNDEPOSITED_STRING,'').trim())) {
				Payment_Method__c paymentMethodRec  = paymentNameToPaymentMethodMap.get(paymentMethodObjRec.Name.replace(UNDEPOSITED_STRING,'').trim());
				paymentMethodRec.Undeposited_Funds__c = paymentMethodObjRec.UndepositedFunds;
			}
		}
		if(!paymentNameToPaymentMethodMap.isEmpty()) {
			update paymentNameToPaymentMethodMap.values();
		}
	}

	public static Map<String, String> getAccountingIdToAccountNumMap() {
		List<General_Account__c> generalAccList = [Select Accounting_Id__c, Account_Number__c From General_Account__c Where Accounting_Id__c != null];

		Map<String, String> accountingIdToAccountNumMap = new Map<String, String>();
		for(General_Account__c genAccRec : generalAccList) {
			if(!accountingIdToAccountNumMap.containsKey(genAccRec.Accounting_Id__c)) {
				accountingIdToAccountNumMap.put(genAccRec.Accounting_Id__c, genAccRec.Account_Number__c);
			}
		}
		return accountingIdToAccountNumMap;
	}

	public static List<QBTaxCodeWrapper> getTaxCodes(Set<String> taxCodeAccIdSet) {
		String query;   
		query = 'SELECT '; 
		for(String fieldsName : QBTaxCodeWrapper.getFieldList()) {
			fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
			query += fieldsName + ', ';
		}
		query = query.substring(0, query.length()-2);
		query += ' FROM ' + Constants.NAMESPACE + 'QB_TaxCode__c';
		query += (taxCodeAccIdSet != null && taxCodeAccIdSet.size() > 0) ? ' WHERE Accounting_Id__c IN :taxCodeAccIdSet' : '';
		query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
		
		if(AccessControl.ifObjectFieldIsAccessible('QB_TaxCode__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<QB_TaxCode__c> taxCodeList  = Database.query(query);
		
		List<QBTaxCodeWrapper> taxCodeRecList = new List<QBTaxCodeWrapper>();
		for(QB_TaxCode__c taxCode: taxCodeList) {
			taxCodeRecList.add(new QBTaxCodeWrapper(taxCode));
		}
		return taxCodeRecList;
	}
	
	public static List<QBTaxCodeWrapper> getNonTaxableTaxCodes() {
		String query;   
		query = 'SELECT '; 
		for(String fieldsName : QBTaxCodeWrapper.getFieldList()) {
			fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
			query += fieldsName + ', ';
		}
		query = query.substring(0, query.length()-2);
		query += ' FROM ' + Constants.NAMESPACE + 'QB_TaxCode__c WHERE Rate_Value__c = 0';
		query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
		
		if(AccessControl.ifObjectFieldIsAccessible('QB_TaxCode__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<QB_TaxCode__c> nonTaxableTaxCodeList  = Database.query(query);
		
		List<QBTaxCodeWrapper> nonTaxableTaxCodeRecList = new List<QBTaxCodeWrapper>();
		for(QB_TaxCode__c taxCode: nonTaxableTaxCodeList) {
			nonTaxableTaxCodeRecList.add(new QBTaxCodeWrapper(taxCode));
		}
		return nonTaxableTaxCodeRecList;
	}
	
	
	public static List<QBTaxRateWrapper> getTaxRates() {
		String query;   
		query = 'SELECT '; 
		for(String fieldsName : QBTaxRateWrapper.getFieldList()) {
			fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
			query += fieldsName + ', ';
		}
		query = query.substring(0, query.length()-2);
		query += ' FROM ' + Constants.NAMESPACE + 'QB_Tax_Rate__c';
		query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
		
		if(AccessControl.ifObjectFieldIsAccessible('QB_Tax_Rate__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<QB_Tax_Rate__c> taxRateList  = Database.query(query);
		
		List<QBTaxRateWrapper> taxRateRecList = new List<QBTaxRateWrapper>();
		for(QB_Tax_Rate__c taxRate: taxRateList) {
			taxRateRecList.add(new QBTaxRateWrapper(taxRate));
		}
		return taxRateRecList;
	}
	
	public static void saveSalesTaxMapping(String salesTaxListJson) {
		List<SalesTax> salesTaxList = (List<SalesTax>) System.JSON.deserialize(salesTaxListJson, List<SalesTax>.class);
		List<Sales_Tax__c> saleTaxListToUpdate = new List<Sales_Tax__c>();
		
		Set<String> mappedTaxCodeAccIdSet = new Set<String>();
		for(SalesTax salesTaxObj : salesTaxList) {
			if(String.isBlank(salesTaxObj.AccountingId)) throw new BlackPurlException(BlackPurlException.getErrorMessage('Error: Mappings cannot be blank', ''));
			saleTaxListToUpdate.add(new Sales_Tax__c(Id = salesTaxObj.Id, Accounting_Id__c = salesTaxObj.AccountingId));
			mappedTaxCodeAccIdSet.add(salesTaxObj.AccountingId);
		}
		
		if(saleTaxListToUpdate.size() > 0) {
			if(AccessControl.ifObjectFieldIsUpdateable('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
			update saleTaxListToUpdate;
		}
	}
	
	public static void saveNonTaxableTaxCodeMapping(String salesAccountingId, String purchaseAccountingId, String nitcWithHeldAccId, String nitcClaimedAccId) {
		QuickBooks_Configurations__c QBConfig = QuickBooks_Configurations__c.getOrgDefaults();
		QBConfig.Non_Taxable_Tax_Code__c = salesAccountingId;
		QBConfig.Non_Taxable_Purchase_Tax_Code__c = purchaseAccountingId;
		QBConfig.NITC_WithHeld_Tax_Code__c = nitcWithHeldAccId;
		QBConfig.NITC_Claimed_Tax_Code__c = nitcClaimedAccId;
		DMLUtility.upsertSobjectList('QuickBooks_Configurations__c', QBConfig);
	}
	
	public static void saveSalesTaxItemMapping(String salesTaxItemListJson) {
		List<SalesTaxItem> salesTaxItemList = (List<SalesTaxItem>) System.JSON.deserialize(salesTaxItemListJson, List<SalesTaxItem>.class);
		List<Sales_Tax_Item__c>  salesTaxItemListToUpdate = new List<Sales_Tax_Item__c>();
		
		Set<String> mappedAccountingIdSet = new Set<String>();
		for(SalesTaxItem salesTaxItemRec : salesTaxItemList) {
			if(String.isBlank(salesTaxItemRec.AccountingId)) throw new BlackPurlException(BlackPurlException.getErrorMessage('Error: Mappings cannot be blank', ''));
			mappedAccountingIdSet.add(salesTaxItemRec.AccountingId);
			salesTaxItemListToUpdate.add(new Sales_Tax_Item__c(Id = salesTaxItemRec.Id, AccountingId__c = salesTaxItemRec.AccountingId));
		}
									
		validateTaxRateMappings(salesTaxItemList, mappedAccountingIdSet);
		
		if(salesTaxItemListToUpdate.size() > 0) {	       
			if(AccessControl.ifObjectFieldIsUpdateable('Sales_Tax_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
			update salesTaxItemListToUpdate;
		}
	}
			
	private static void validateTaxRateMappings(List<SalesTaxItem> salesTaxItemList, Set<String> mappedAccountingIdSet) {
		List<QB_Tax_Rate__c> taxRateList = [Select Id, Accounting_Id__c, Rate_Value__c from QB_Tax_Rate__c where Accounting_Id__c IN: mappedAccountingIdSet];
		Map<String, Decimal> accountingIdToRateMap = new Map<String, Decimal>();
		for(QB_Tax_Rate__c taxRateRec : taxRateList) {
			accountingIdToRateMap.put(taxRateRec.Accounting_Id__c, (taxRateRec.Rate_Value__c != null ? taxRateRec.Rate_Value__c : 0));
		}
		
		for(SalesTaxItem salesTaxItemObj : salesTaxItemList) {
			salesTaxItemObj.TaxRate = (salesTaxItemObj.TaxRate != null ? salesTaxItemObj.TaxRate : 0);
			if(String.isBlank(salesTaxItemObj.AccountingId) || !accountingIdToRateMap.containsKey(salesTaxItemObj.AccountingId) || 
				(accountingIdToRateMap.get(salesTaxItemObj.AccountingId) != salesTaxItemObj.TaxRate)) {
				throw new BlackPurlException(BlackPurlException.getErrorMessage('Error: Incorrect tax rate mappings', ''));
			}
		}
	}
	
	private static QB_TaxCode__c getTaxCodeWrapperToSObject(QBTaxCodeWrapper qbTaxCode, String childRateString) {
		QB_TaxCode__c taxCodeRec = new QB_TaxCode__c();
		taxCodeRec.Name = (qbTaxCode.Name != null && qbTaxCode.Name.length() > 79) ? qbTaxCode.Name.subString(0, 79) : qbTaxCode.Name;
		taxCodeRec.Is_Active__c = qbTaxCode.Active;
		taxCodeRec.Is_Taxable__c = qbTaxCode.Taxable;
		taxCodeRec.Accounting_Id__c = qbTaxCode.Id;
		taxCodeRec.Applicable_QB_Tax_Rates__c = childRateString;
		taxCodeRec.Tax_Applicable_On__c = qbTaxCode.TaxApplicableOn;
		taxCodeRec.Rate_Value__c = 0;
		return taxCodeRec;
	}
	
	private static Map<String, QB_Tax_Rate__c> getAccountingIdToQBTaxRateMap(Set<String> taxRatesAccountingIdSet) {
		Map<String, QB_Tax_Rate__c> accountingIdToQBTaxRateMap = new Map<String, QB_Tax_Rate__c>();
		List<QB_Tax_Rate__c> taxRatesRecs = [SELECT Rate_Value__c, Accounting_Id__c From QB_Tax_Rate__c WHERE Accounting_Id__c IN :taxRatesAccountingIdSet];
		for(QB_Tax_Rate__c taxRateRec : taxRatesRecs) {
			accountingIdToQBTaxRateMap.put(taxRateRec.Accounting_Id__c, taxRateRec);
		}
		return accountingIdToQBTaxRateMap;
	}

	public static String saveDepositsAndPaymentMethod(String defaultAccountJSON) {
        Accounting_Default_Accounts__c accDefaultConfig = Accounting_Default_Accounts__c.getOrgDefaults();
        AccountingSettingWrapper.DefaultAccountWrapper accountingWrapperObj = (AccountingSettingWrapper.DefaultAccountWrapper) System.JSON.deserialize(defaultAccountJSON, AccountingSettingWrapper.DefaultAccountWrapper.class);
        
        if(checkCustomerDepositInUndepositedGL(accountingWrapperObj.CustomerDeposits)) {
            throw new BlackpurlException('This GL is already being used as an Undeposited Funds GL, please select a different GL account');
        }

        accDefaultConfig.Payment_Method_Surcharges__c = accountingWrapperObj.PaymentMethodSurcharges;
        accDefaultConfig.Undeposited_Funds__c = accountingWrapperObj.UndepositedFunds;
        accDefaultConfig.Customer_Deposits__c = accountingWrapperObj.CustomerDeposits;
        accDefaultConfig.Cash_Rounding__c = accountingWrapperObj.CashRounding;
        accDefaultConfig.Checkout_clearing__c = accountingWrapperObj.CheckoutClearing;
        accDefaultConfig.Cash_Rec_clearing__c = accountingWrapperObj.CashRecClearing;
        accDefaultConfig.Cash_over_short__c = accountingWrapperObj.CashOverShort;
        accDefaultConfig.Gift_Card_liability__c = accountingWrapperObj.GiftCardLiability;
        upsert accDefaultConfig;
		AccountingIntegrationSettingsCtrl.updateSpecialCategories(accountingWrapperObj);
        
        return AccountingIntegrationSettingsCtrl.getAccountingSettingDetails();
    }

	public static Boolean checkCustomerDepositInUndepositedGL(String customerDepositGL) {
        Set<String> unDepositedPaymentSet = new set<String>();
		for(Payment_Method__c paymentMethodRec : [SELECT Undeposited_Funds__c FROM Payment_Method__c WHERE Undeposited_Funds__c != null AND (Is_Active__c = true OR Is_Only_Updeposited_Payment_Method__c = true)] ) {
            unDepositedPaymentSet.add(paymentMethodRec.Undeposited_Funds__c);
		}
        return unDepositedPaymentSet.contains(customerDepositGL);
    }

	public class PaymentMethodWrapper {
		public String Name;
		public String UndepositedFunds;
    
		public PaymentMethodWrapper(Payment_Method__c paymentMethodRec) {
			this.Name = UNDEPOSITED_STRING + paymentMethodRec.Name;
			this.UndepositedFunds = paymentMethodRec.Undeposited_Funds__c;
		}
	}
}