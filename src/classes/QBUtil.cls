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
    
    public static Boolean isQBEnabled() {
        return (General_Configurations__c.getOrgDefaults() != null) ? General_Configurations__c.getOrgDefaults().Enable_QB_Accounting__c : false ;
    }
    
    public static Boolean isQBOAuth2Enabled() {
        return (General_Configurations__c.getOrgDefaults() != null) ? General_Configurations__c.getOrgDefaults().Enable_QB_OAuth_2_0__c : false ;
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
        QuickBooks_Configurations__c qbConfig = QuickBooks_Configurations__c.getOrgDefaults();
        List<IFW_IntegrationConfig__c> ifwConfigList = AccountingIntegrationSettingsService.getIntegrationConfigWithItems(QUICKBOOKS_ONLINE, new Map<String, String>());
    	if(ifwConfigList[0].Refresh_Token__c != refreshToken) {
            //qbConfig.Refresh_Token__c = refreshToken;
            ifwConfigList[0].Refresh_Token__c = refreshToken;
    		qbConfig.Refresh_Token_Expires_In__c = refreshTokenExpiresIn;
    		qbConfig.Access_Token_Generation_Date__c = system.today();
            DMLUtility.updateSobjectList('QuickBooks_Configurations__c', qbConfig);
            DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', ifwConfigList);
    	}
    }
    
    public static void initiateBatch(Set<Id> idSet, String syncEntityName) {
        if (syncEntityName == 'Hours Logged') {
            AccSync_HoursLogged_Batch batchObj = (AccSync_HoursLogged_Batch)syncEntityNameToBatchName.get(syncEntityName).newInstance(); 
            batchObj.hoursLoggedIdSet = idSet;
            Database.executeBatch(batchObj, 10);
        } else if (syncEntityName == 'Unit NITC JE') {
            AccSync_UnitNITCJE_Batch batchObj = (AccSync_UnitNITCJE_Batch)syncEntityNameToBatchName.get(syncEntityName).newInstance(); 
            batchObj.setUnitIds = idSet;
            Database.executeBatch(batchObj, 10);
        } else if (syncEntityName == 'Unit Consignment') {
            AccSync_UnitConsignment_Batch batchObj = (AccSync_UnitConsignment_Batch)syncEntityNameToBatchName.get(syncEntityName).newInstance(); 
            batchObj.setConsUnitIds = idSet;
            Database.executeBatch(batchObj, 10);
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
    
    public static void deleteEntity(DeleteEntityWrapper deleteEntityObj, String objectType) {
    	String reqBody = system.JSON.serialize(deleteEntityObj);
    	QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.deleteRequest(objectType, reqBody);
    	HttpResponse res = responseObj.Response;
    	QuickBookQueryService.refreshToken = responseObj.RefreshToken;
		QuickBookQueryService.refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
    	
        if(res.getStatusCode() != 200) { 
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
	                                               }
    };
    
    public static Map<String, Type> syncEntityNameToBatchName = new Map<String, Type>{
        'Hours Logged'	=>	AccSync_HoursLogged_Batch.class,
        'Unit NITC JE'	=>	AccSync_UnitNITCJE_Batch.class
    };

    public static String getAccountingPeriodClosedDate() {
    	try {
			QBPreferencesDTO preferenceResponse = QBIntegrationService.getPreferencesFromQB();
            return handlePreferenceResponse(preferenceResponse);
		} catch(Exception e) {
			if(e.getMessage().contains('invalid_grant')) {
				throw new BlackPurlException('Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
			} else {
				throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
			}
		}
		return null;
    }

    public static String getAccountingClosedDateWithRefreshToken() {
        try {
			QBPreferencesDTO preferenceResponse = QBIntegrationService.getPreferencesWithRefreshToken();
            return handlePreferenceResponse(preferenceResponse);
		} catch(Exception e) {
			if(e.getMessage().contains('invalid_grant')) {
				throw new BlackPurlException('Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
			} else {
				throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
			}
		}
		return null;
    }

    private static String handlePreferenceResponse(QBPreferencesDTO preferenceResponse) {
        if(preferenceResponse == null) {
            throw new BlackPurlException('There is some error fetching details from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.');
        } else if(preferenceResponse.Preferences.AccountingInfoPrefs != null) {
            return preferenceResponse.Preferences.AccountingInfoPrefs.BookCloseDate;
        }
        return null;
    }

    public static Boolean isVendorActiveInQB(Account vendorRec) {
        Boolean isVendorActive = true;
        QuickBookQueryService.ResponseQuickBooks qbResponse = QuickBookQueryService.getRecordsByFieldName('Vendor', 'Id', '\''+ vendorRec.Vendor_AccountingId__c +'\'', '=', 0, null);
        if(qbResponse == null) {
            throw new BlackpurlException('Error communicating with the accounting package, try again later.');
        } else if(!(qbResponse.Vendor != null && qbResponse.Vendor.size() == 1 && qbResponse.Vendor[0].active)) { 
            isVendorActive = false;
        }
        return isVendorActive;
    }

    public static Boolean isInvNumberAlreadyExistInQB(String invoiceNumber) {
        Boolean isInvNumberAlreadyExist = false;
        String result = QuickBookQueryService.validateUniqueEntityValue('Bill', 'DocNumber', '\'' + invoiceNumber + '\'', '=');
        if(result == 'Duplicate') {
            isInvNumberAlreadyExist = true;
        } else if(result == 'Error QuickBooks Online') {
            throw new BlackpurlException('Error communicating with the accounting package, try again later.');
        }
        return isInvNumberAlreadyExist;
    }

    public static String validateVendorRefNumberInQB(AccountingUtil.AccountingEntity txnJson) {
        String txnNumberText = (txnJson.TxnType == 'vendorcredit') ? 'credit number' : 'vendor reference number';
        if(String.isNotBlank(txnJson.EntityAccId)) {
            List<String> filterConditions = new List<String>{'DocNumber =\'' + txnJson.TxnNumber + '\'', 'VendorRef =\'' + txnJson.EntityAccId + '\''};
            try {
                QuickBookQueryService.ResponseQuickBooks qbResponse = QuickBookQueryService.getRecordsByFilter(txnJson.TxnType, filterConditions);
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
            }
        } else {
            return 'Vendor is not synced to ' + QBUtil.QUICKBOOKS_ONLINE + ' for validating ' + txnNumberText;
        }
        return 'Success';
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
}