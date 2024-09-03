public without sharing class QBUtil {
    public final static String US_VERSION = 'US';
    public final static String INTERNATIONAL_VERSION = 'International';
    public final static String AUS_VERSION = 'AUS';
    public final static String SALES_RECEIPT = 'salesreceipt';
    public final static String INVOICE = 'invoice';
    public final static String REFUND_RECEIPT = 'refundreceipt';
    public final static String CREDIT_MEMO = 'creditmemo';
    public final static String VENDOR_CREDIT = 'vendorcredit';
    public final static String BILL = 'bill';
    public final static String CO_INVOICE_NO_JE_MSG = 'All Line items either have zero cost or are fees. So, no line item to post to QB.';
    public final static String CO_INVOICE_NO_LI_MSG = 'No line item to post to QuickBooks Online while syncing invoice.';
    public final static String INTERNAL = 'Internal';
    public final static String DEAL = 'Deal';
    public final static String CLOSED = 'Closed';
    public final static String CHARGE_ACCOUNT = 'Charge Account';
    public final static String PART_CREATED = 'Part Created';
    public final static String OVERSOLD = 'Oversold';
    public final static String STOCKED = 'Stocked';
    public final static String DEAL_ITEM_TYPE_TRADE_IN = 'Trade In';
    public final static String TAX_NOT_APPLICABLE = 'NotApplicable';
    public final static String TAX_EXCLUDED = 'TaxExcluded';
    public final static String TAX_INCLUSIVE = 'TaxInclusive';
    public final static String SALES = 'Sales';
    public final static String PURCHASE = 'Purchase';
    public final static String PRODUCTION_END_POINT_URL = 'https://quickbooks.api.intuit.com/v3/company/';
    public final static String SANDBOX_END_POINT_URL = 'https://sandbox-quickbooks.api.intuit.com/v3/company/';
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static Boolean isQBTaxCodesEnabled = (General_Configurations__c.getOrgDefaults() != null) ? General_Configurations__c.getOrgDefaults().Use_QB_accounting_tax_codes__c : false;
    public static String nonTaxableCodeAccId = (QuickBooks_Configurations__c.getOrgDefaults() != null) ? QuickBooks_Configurations__c.getOrgDefaults().Non_Taxable_Tax_Code__c : null;
    public static String nonTaxablePurchaseCodeAccId = (QuickBooks_Configurations__c.getOrgDefaults() != null) ? QuickBooks_Configurations__c.getOrgDefaults().Non_Taxable_Purchase_Tax_Code__c : null;
    public final static String QUICKBOOKS_ONLINE = 'QuickBooks Online';
    public final static String JOURNALENTRY = 'JournalEntry';
    public final static String PREFERENCES = 'preferences';
    public final static String ASSIGNED_CUSTOMER_DELETED = 'Customer assigned to this transaction has been deleted';
    public final static String ASSIGNED_VENDOR_DELETED = 'Supplier assigned to this transaction has been deleted';
    public final static String AR_CREDIT_TOO_LONG_ERR_MSG = 'Can\'t process AR credit as credit number is too long';
    public final static String OBJECT_NOT_FOUND = 'Object Not Found';
    public final static String DUPLICATE_DOC_NUMBER = 'Duplicate Document Number Error';
    
    public static Set<String> journalEntryEntities = new Set<String>{IntegrationUtility.VENDOR_RECEIVING,
                                                              IntegrationUtility.HOURS_LOGGED,
                                                              IntegrationUtility.STORE_CREDIT,
                                                              IntegrationUtility.PART_FIFO,
                                                              IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM,
                                                              IntegrationUtility.CO_INVOICE_JE,
                                                              IntegrationUtility.PAYMENT_ON_ACCOUNT,
                                                              IntegrationUtility.COUNT_SESSION_JE,
                                                              IntegrationUtility.UNIT_INVOICE_JE,
                                                              IntegrationUtility.CO_DEPOSIT,
                                                              IntegrationUtility.PART_CATEGORY,
                                                              IntegrationUtility.STOCK_UNIT_CATEGORY,
                                                              IntegrationUtility.STOCK_TRADE_IN,
                                                              IntegrationUtility.UNIT_NITC_JE,
                                                              IntegrationUtility.VO_INVOICE_VARIANCE_JE,
                                                              IntegrationUtility.ITEM_CATEGORY,
                                                              IntegrationUtility.CO_INVOICE_PAYMENT
                                                            };
    
    public static Boolean isQBEnabled() {
        return (General_Configurations__c.getOrgDefaults() != null) ? General_Configurations__c.getOrgDefaults().Enable_QB_Accounting__c : false ;
    }
    
    public static Boolean isQBOSanboxEnvironment() {
        return (BP_Configurations__c.getOrgDefaults() != null) ? BP_Configurations__c.getOrgDefaults().Is_QBO_Sandbox__c : false ;
    }
     
    public static Boolean isUSVersionQB() {
        return (getQBVersion() == US_VERSION);
    }
    
    public static String getQBVersion() {
        QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
        return qbConfig.Company_Country__c;
    }
    
    public static String getDealUnitName(Deal_Item__c dealItem) {
        String Item = '';
        if(dealItem.Customer_Owned_Unit__c != null) {
            Boolean showDash = false;
            if(dealItem.Customer_Owned_Unit__r.Year__c != null){
                Item += dealItem.Customer_Owned_Unit__r.Year__c;
                showDash = true;
            }
            if(String.isNotBlank(dealItem.Customer_Owned_Unit__r.Unit_Make__r.Name)) {
                Item += ' ' + dealItem.Customer_Owned_Unit__r.Unit_Make__r.Name;
                showDash = true;
            }
            if(String.isNotBlank(dealItem.Customer_Owned_Unit__r.Unit_Model__r.Name__c)) {
                Item += ' ' + dealItem.Customer_Owned_Unit__r.Unit_Model__r.Name__c;
                showDash = true;
            }
            if(String.isNotBlank(dealItem.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c)) {
                Item += ' ' + dealItem.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c;
                showDash = true;
            }
            if(String.isNotBlank(dealItem.Customer_Owned_Unit__r.VIN_Number__c)) {
                if(showDash) {
                    Item += ' - ';
                }
                Item += dealItem.Customer_Owned_Unit__r.VIN_Number__c ;
            }
        }
        return Item;
    }
    
    public static String truncateString(String stringToTruncate, Integer noOfCharacters) {
    	return String.isNotBlank(stringToTruncate) && (stringToTruncate.length() > noOfCharacters) ? stringToTruncate.substring(0, noOfCharacters) : stringToTruncate ;
    }
    
    public static Map<String, List<String>> getNonTaxableTaxCodeWithRates(String taxType) {
    	Map<String, List<String>> nonTaxableTaxCodeToTaxRatesMap = new Map<String, List<String>>();
    	if(String.isNotBlank(nonTaxableCodeAccId)) {
    	    if(AccessControl.ifObjectFieldIsAccessible('QB_TaxCode__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    		List<QB_TaxCode__c> taxCodeList = [SELECT Applicable_QB_Tax_Rates__c FROM QB_TaxCode__c WHERE Accounting_Id__c = :nonTaxableCodeAccId AND Tax_Applicable_On__c =: taxType];
    		if(taxCodeList.size() > 0 && String.isNotBlank(taxCodeList[0].Applicable_QB_Tax_Rates__c)) {
    			 List<String> taxRates = taxCodeList[0].Applicable_QB_Tax_Rates__c.split(';');
    			 nonTaxableTaxCodeToTaxRatesMap.put(nonTaxableCodeAccId, taxRates);
    		}
    	}
    	return nonTaxableTaxCodeToTaxRatesMap;
    }
    
    public static void saveRefreshToken(String refreshToken, Decimal refreshTokenExpiresIn) {
        List<IFW_IntegrationConfig__c> ifwConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QUICKBOOKS_ONLINE, new Map<String, String>());
    	if(ifwConfigList[0].Refresh_Token__c != refreshToken) {
            ifwConfigList[0].Refresh_Token__c = refreshToken;
            ifwConfigList[0].Token_Expiry__c = refreshTokenExpiresIn;
            DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigList);
    	}
    }
    
    public static Boolean isTxnDateAfterAccPeriodCloseDate(DateTime txnDateTime) {
    	Date txnDate = Date.newInstance(txnDateTime.year(), txnDateTime.month(), txnDateTime.day());
        String accPeriodCloseDate = getAccountingPeriodClosedDate();
        if(String.isBlank(accPeriodCloseDate) || (txnDate > DateTimeUtility.getDateFromFormattedDateStr(accPeriodCloseDate, 'YYYY-MM-DD'))) {
            return true;
        }
		return false;
    }

    // This is used where transaction date is of Date type like in VO flow.
    public static Boolean isTxnDateAfterAccPeriodCloseDateWithRefreshToken(Date txnDate, List<IFW_IntegrationConfig__c> configList) {
    	if(configList.size() == 0) throw new BlackpurlException(QUICKBOOKS_ONLINE + ' config is not defined.');
        String accPeriodCloseDate = getAccountingClosedDateWithRefreshToken(configList[0]);
        if(String.isBlank(accPeriodCloseDate) || (txnDate > DateTimeUtility.getDateFromFormattedDateStr(accPeriodCloseDate, 'YYYY-MM-DD'))) {
            return true;
        }
		return false;
    }

    // This is used where transaction date is of DateTime type like in CO flow.
    public static Boolean isTxnDateAfterAccPeriodCloseDateWithRefreshToken(DateTime txnDateTime, List<IFW_IntegrationConfig__c> configList) {
    	if(configList.size() == 0) throw new BlackpurlException(QUICKBOOKS_ONLINE + ' config is not defined.');
        Date txnDate = Date.newInstance(txnDateTime.year(), txnDateTime.month(), txnDateTime.day());
        String accPeriodCloseDate = getAccountingClosedDateWithRefreshToken(configList[0]);
        if(String.isBlank(accPeriodCloseDate) || (txnDate > DateTimeUtility.getDateFromFormattedDateStr(accPeriodCloseDate, 'YYYY-MM-DD'))) {
            return true;
        }
		return false;
    }
    
    public static void deleteEntity(DeleteEntityWrapper deleteEntityObj, String objectType) {
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, new Map<String, String>{objectType => IntegrationUtility.DELETE_ACTION});
        List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
        if(integrationConfigList.isEmpty()) throw new BlackpurlException(QBUtil.QUICKBOOKS_ONLINE + ' config is not defined');
        string endpoint;
        configItemList[0].HTTP_Method__c = 'POST';
        if(String.isNotBlank(configItemList[0].Endpoint_URL__c)) {
            endpoint = configItemList[0].Endpoint_URL__c;
            configItemList[0].Endpoint_URL__c = (configItemList[0].Endpoint_URL__c + '?operation=delete'); // Endpoint manipuation for GET call in QB
        }
    	String reqBody = system.JSON.serialize(deleteEntityObj);
        HttpResponse res = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], reqBody, new List<customHttpHeaderWrapper>(), new Map<String, String>());
        //configItemList[0].Endpoint_URL__c = endpoint; //Resetting endpoint to actual endpoint.

        if(res.getStatusCode() != 200 && !res.getBody().containsIgnoreCase(OBJECT_NOT_FOUND)) { 
            throw new BlackPurlException(res.getBody() + '\n' + objectType + '\n' + reqBody);
        } 
    }
    
    public static Map<String, Map<String, String>> syncEntityNameToFieldNameToValueMap = new Map<String, Map<String, String>>{
        'CO Invoice Payment'	=>	new Map<String, String>{Constants.NAMESPACE + 'availForQBCOInvoicePayment__c' => 'true', 
                                                            Constants.NAMESPACE + 'AccountingIdForCOInvoicePayment__c' => null,
	                                                        Constants.NAMESPACE + 'SyncTokenForCOInvoicePayment__c' => null
	                                                       },
	    'CO Invoice'	=>	new Map<String, String>{Constants.NAMESPACE + 'availForQBSync__c' => 'true', 
                                                    Constants.NAMESPACE + 'AccountingId__c' => null,
                                                    Constants.NAMESPACE + 'SyncToken__c' => null
	                                               },
	    'CO Invoice JE'	=>	new Map<String, String>{Constants.NAMESPACE + 'availForQBJournalEntrySync__c' => 'true', 
                                                    Constants.NAMESPACE + 'JournalEntryAccountingId__c' => null,
                                                    Constants.NAMESPACE + 'SyncTokenForJournalEntry__c' => null
	                                               },
	    'Lien Payout'	=>	new Map<String, String>{Constants.NAMESPACE + 'Lien_Payout_Avail_For_QB_Sync__c' => 'true',
                                                    Constants.NAMESPACE + 'Lien_Payout_Accounting_Id__c' => null,
                                                    Constants.NAMESPACE + 'Lien_Payout_Sync_Token__c' => null
	                                               },
		IntegrationUtility.UNIT_CONSIGNMENT =>	new Map<String, String>{Constants.NAMESPACE + 'Available_For_QB_Consignment_Sync__c' => 'true',
                                                    Constants.NAMESPACE + 'QB_Consignment_Accounting_Id__c' => null,
                                                    Constants.NAMESPACE + 'Sync_Token_For_Consignment__c' => null
	                                               },
        IntegrationUtility.VENDOR_RECEIVING =>	new Map<String, String>{Constants.NAMESPACE + 'availForQBJournalEntrySync__c' => 'true',
                                                    Constants.NAMESPACE + 'AccountingIdForJournalEntry__c' => null,
                                                    Constants.NAMESPACE + 'SyncTokenForJournalEntry__c' => null
                                                    }
    };
    
    public static String getAccountingPeriodClosedDate() {
    	try {
			QBResponseWrapper resObj = QBCalloutManager.getDataByQBIdAndUpdateRecords('preferences?minorversion=21', null, null);
            if(resObj != null && resObj.Preferences != null && resObj.Preferences.AccountingInfoPrefs != null) {
                return resObj.Preferences.AccountingInfoPrefs.BookCloseDate;
            }
            return null;
		} catch(Exception e) {
			if(e.getMessage().contains('invalid_grant')) {
				throw new BlackPurlException('Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
			}
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
		}
    }

    public static String getAccountingClosedDateWithRefreshToken(IFW_IntegrationConfig__c ifwConfigRec) {
        try {
			QBResponseWrapper resObj = QBCalloutManager.getDataByQBId('preferences?minorversion=21', null, ifwConfigRec);
            if(resObj != null && resObj.Preferences != null && resObj.Preferences.AccountingInfoPrefs != null) {
                return resObj.Preferences.AccountingInfoPrefs.BookCloseDate;
            }
            return null;
		} catch(Exception e) {
			if(e.getMessage().contains('invalid_grant')) {
				throw new BlackPurlException('Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
			}
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
		}
    }

    public static Boolean isVendorActiveInQB(Account vendorRec, IFW_IntegrationConfig__c integrationConfig) {
        Boolean isVendorActive = true;
        List<String> filterConditionList = new List<String>{'Id =\'' + vendorRec.Vendor_AccountingId__c + '\''};
        
        QBQueryResponseWrapper.QBResponseWrapper resObj = QBCalloutManager.getData('Vendor', filterConditionList, integrationConfig);
        if(!(resObj != null && resObj.Vendor != null && resObj.Vendor.size() == 1 && resObj.Vendor[0].active)) { 
            isVendorActive = false;
        }
        return isVendorActive;
	}

    public static Boolean isInvNumberAlreadyExistInQB(String invoiceNumber, IFW_IntegrationConfig__c integrationConfig) {
        Boolean isInvNumberAlreadyExist = false;
        if(String.isNotBlank(invoiceNumber)) {
            List<String> filterConditions = new List<String>{'DocNumber = \'' + BPUtility.escapeSingleQuotes(invoiceNumber) + '\''};
            QBQueryResponseWrapper.QBResponseWrapper qbResponse = QBCalloutManager.getData(IntegrationUtility.BILL, filterConditions, integrationConfig);        
            if(isInvoiceNumberDuplicate('Bill', '=', qbResponse) == 'Duplicate') isInvNumberAlreadyExist = true;
        }
        return isInvNumberAlreadyExist;
    }

    public static String isInvoiceNumberDuplicate(String entityType, String operator, QBQueryResponseWrapper.QBResponseWrapper qbResponse) {
        Set<String> invoiceNumberSet = new Set<String>();
        if(qbResponse != null && ((qbResponse.TotalCount != null && qbResponse.TotalCount > 0) || (qbResponse.maxResults != null && qbResponse.maxResults > 0))) {
            if(operator == '=') {
                if(entityType.equalsIgnoreCase('salesreceipt') || entityType.equalsIgnoreCase('refundreceipt') || entityType.equalsIgnoreCase('creditmemo') || entityType.equalsIgnoreCase('invoice')) {
                    return system.JSON.serialize(qbResponse);
                }
                return 'Duplicate';
            } else {
                if(entityType == 'Bill') {
                    for(QBVendorBillDTO entity : qbResponse.Bill ) {
                        invoiceNumberSet.add(entity.DocNumber);
                    }
                }
            }
        } else {
            return 'Success';
        }
        return system.JSON.serialize(invoiceNumberSet);
    }

    public static String validateVendorRefNumberInQB(AccountingUtil.AccountingEntity txnJson) {
        String txnNumberText = (txnJson.TxnType == 'vendorcredit') ? 'credit number' : 'vendor reference number';
        if(String.isNotBlank(txnJson.EntityAccId)) {
            List<String> filterConditions = new List<String>{'DocNumber =\'' + txnJson.TxnNumber + '\'', 'VendorRef =\'' + txnJson.EntityAccId + '\''};
            try {
                List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
                QBQueryResponseWrapper.QBResponseWrapper qbResponse = QBCalloutManager.getDataAndUpdateRecords(txnJson.TxnType, filterConditions, integrationConfigList[0]);        
                if(qbResponse == null) {
                    return 'There is some error validating ' + txnNumberText + ' from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.';
                } else {
                    if((qbResponse.Bill != null && qbResponse.Bill.size() > 0) || (qbResponse.VendorCredit != null && qbResponse.VendorCredit.size() > 0)) {
                        return 'Duplicate';
                    }
                    return 'Success';
                }
            } catch(Exception e) {
                if(e.getMessage().contains('invalid_grant')) {
                    return 'Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.';
                }
                return 'There is some error validating ' + txnNumberText + ' from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.';
            }
        } else {
            return 'Vendor is not synced to ' + QBUtil.QUICKBOOKS_ONLINE + ' for validating ' + txnNumberText;
        }
    }

    private static QBPreferencesDTO.CurrencyPrefsWrapper getCurrencyPreferences(IFW_IntegrationConfig__c ifwConfigRec) {
        QBResponseWrapper resObj = QBCalloutManager.getDataByQBId('preferences?minorversion=21', null, ifwConfigRec);
        if(resObj != null) {
            return resObj.Preferences.CurrencyPrefs;
        }
        return null;
    }

    public static QBInnerEntityWrapper getCurrencyRef() {
        if(AccountingUtil.isMultiCurrencyEnabled()) {
            return new QBInnerEntityWrapper(AccountingUtil.getHomeCurrency(), null);
        }
        return null;
    }

    public static void setCurrencyRef(QuickBooks_Configurations__c configRec, IFW_IntegrationConfig__c ifwConfigRec) {
        QBPreferencesDTO.CurrencyPrefsWrapper currPrefsObj = getCurrencyPreferences(ifwConfigRec);
        if(currPrefsObj != null) {
            configRec.Multi_Currency_Enabled__c = currPrefsObj.MultiCurrencyEnabled;
            if(currPrefsObj.HomeCurrency != null) configRec.Home_Currency__c = currPrefsObj.HomeCurrency.value;
        }
    }

    public static Boolean canInvoiceBeRemovedFromAcc(CO_Invoice_Header__c coInvRec, Deal__c dealRec) {
        try {
        String syncingObjectType, accId;
        Decimal amountPaidUsingCOA = 0;
        if(coInvRec != null) {
                syncingObjectType = (coInvRec.Total__c >= 0) ? IntegrationUtility.INVOICE : IntegrationUtility.CREDIT_MEMO;
            accId = coInvRec.AccountingId__c;
                amountPaidUsingCOA = (syncingObjectType == IntegrationUtility.INVOICE) ? (coInvRec.Total_Payment__c - coInvRec.Total_Amount_Except_Charge_Account__c) : 
                                    coInvRec.Total_Payment__c*-1;
        } else if(dealRec != null) {
                syncingObjectType = (dealRec.Invoice_Number__r.Total__c >= 0) ? IntegrationUtility.INVOICE : IntegrationUtility.CREDIT_MEMO;
            accId = dealRec.Invoice_Number__r.AccountingId__c;
                amountPaidUsingCOA = (syncingObjectType == IntegrationUtility.INVOICE) ? (dealRec.Invoice_Number__r.Total_Payment__c - dealRec.Invoice_Number__r.Total_Amount_Except_Charge_Account__c) : 
                                    dealRec.Invoice_Number__r.Total_Payment__c*-1;
        }

            List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, new Map<String, String>{syncingObjectType => IntegrationUtility.RETRIEVE_ACTION});
            List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
            if(integrationConfigList.isEmpty()) throw new BlackpurlException(QBUtil.QUICKBOOKS_ONLINE + ' config is not defined');
            
            configItemList[0].HTTP_Method__c = 'GET';
            if(String.isNotBlank(configItemList[0].Endpoint_URL__c)) {
                configItemList[0].Endpoint_URL__c = (configItemList[0].Endpoint_URL__c + '/' + accId); // Endpoint manipuation for without query GET call in QB
            }
            HttpResponse res = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], null, new List<customHttpHeaderWrapper>(), new Map<String, String>());
            system.debug('invoiceResonseObj ==== ' + res.getBody());

            QBResponseWrapper response = (QBResponseWrapper)System.JSON.deserialize(res.getBody(), QBResponseWrapper.class);
            if(response.Invoice != null) {
                return (amountPaidUsingCOA == response.Invoice.Balance);
            } else if(response.CreditMemo != null) {
                return (amountPaidUsingCOA == response.CreditMemo.Balance);
            }
        } catch (Exception e) {
            return false;
        }
        return false;
    }

    public static Boolean reCheckAccountingEntriesInQB(String objectType, String quickbookId, IFW_IntegrationConfig__c ifwConfigRec) {
		try {
            QBResponseWrapper resObj = QBCalloutManager.getDataByQBId(objectType, quickbookId, ifwConfigRec);
            if(resObj != null) {
                return false;
            }
            return false;
		} catch(Exception e) {
            if(e.getMessage().containsIgnoreCase(OBJECT_NOT_FOUND)) return true;
			return false;
		}
	}
    
	public static String getSyncingObjectName(Decimal invoiceTotal, Boolean isChargeAccount) {
        String objectType = '';
        if(invoiceTotal >= 0 && !isChargeAccount) {
            objectType = IntegrationUtility.SALES_RECEIPT;
        } else if(invoiceTotal < 0 && !isChargeAccount) {
            objectType = IntegrationUtility.REFUND_RECEIPT;
        } else if(invoiceTotal >= 0 && isChargeAccount) {
            objectType = IntegrationUtility.INVOICE;
        } else if(invoiceTotal < 0 && isChargeAccount) { 
            objectType = IntegrationUtility.CREDIT_MEMO;
        }
        return objectType;
    }

    public class BatchResultWrapper {
    	public List<Log__c> ErrorLogToInsert;
    	public String RefreshToken;
    	public Decimal RefreshTokenExpiresIn;
    	
    	public BatchResultWrapper(List<Log__c> errorLogToInsert, String refreshToken, Decimal refreshTokenExpiresIn) {
    		this.ErrorLogToInsert = errorLogToInsert;
    		this.RefreshToken = refreshToken;
    		this.RefreshTokenExpiresIn = refreshTokenExpiresIn;
    	}
    }
    
    public class DeleteEntityWrapper {
    	public String Id;
    	public String SyncToken;
    	
    	public DeleteEntityWrapper(String accId, String syncToken) {
    		this.Id = accId;
    		this.SyncToken = String.isNotBlank(syncToken) ? syncToken : '0';
    	}
    }

    public static Map<String, String> syncingEntityTypeToXeroAccIdNameMap = new Map<String, String>{
        IntegrationUtility.JOURNAL_ENTRY	=>	'JournalEntry.Id'
    };

    public static Map<String,String> entityNameToEntityMap = new Map<String,String> { 'Journal Entry' => 'journalentry',
																					  'Company Info' => 'companyinfo',
																					  'Invoice_Payment' => 'payment',
																					  'Refund Receipt' => 'refundreceipt',
                                                                                      'Sales Receipt' => 'salesreceipt',
                                                                                      'Invoice' => 'invoice',
                                                                                      'Credit Memo' => 'creditmemo',
                                                                                      'Customer' => 'customer',
                                                                                      'Item' => 'item',
                                                                                      'Bill' => 'bill',
                                                                                      'Vendor' => 'vendor',
                                                                                      'Vendor Credit' => 'vendorcredit', 
                                                                                      'Batch'  => 'batch'
																					}; 
    
    public static Map<String,String> entityNameToEntityActionMap = new Map<String,String> { 'journalentry' => 'Create; Update; Delete; Retrieve',
                                                                                            'companyinfo' => 'Create; Update',
                                                                                            'payment' => 'Create; Update; Delete; Retrieve',
                                                                                            'refundreceipt' => 'Create; Update; Delete; Retrieve',
                                                                                            'salesreceipt' => '	Create; Update; Delete; Retrieve',
                                                                                            'invoice' => 'Create; Update; Delete; Retrieve',
                                                                                            'creditmemo' => 'Create; Update; Delete; Retrieve',
                                                                                            'customer' => 'Create; Update; Delete; Retrieve',
                                                                                            'item' => 'Create; Update',
                                                                                            'bill' => 'Create; Update; Delete; Retrieve',
                                                                                            'vendor' => 'Create; Update; Delete; Retrieve',
                                                                                            'vendorcredit' => 'Create; Update; Delete; Retrieve',
                                                                                            'batch' => 'Create; Update; Delete; Retrieve'
                                                                                        }; 
}