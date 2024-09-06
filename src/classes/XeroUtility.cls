public without sharing class XeroUtility {
	
	public final static String XERO = 'Xero';
	public final static String ACCESS_DENIED = 'Access Denied';
	public final static Integer MAX_RETRY_COUNT = 3;
	
	public static Map<String, String> entityNameToXeroURLParamMap = new Map<String, String>{ IntegrationUtility.JOURNAL_ENTRY => 'Narration=',
																							 IntegrationUtility.INVOICE_PAYMENT => 'Reference='
																						   };
																						   
	public static Map<String, List<String>> commonEntityNameToEntityNameMap = new Map<String, List<String>> { 
																							  IntegrationUtility.JOURNAL_ENTRY => new List<String> { IntegrationUtility.COUNT_SESSION_JE,
																																					 IntegrationUtility.UNIT_INVOICE_JE,
																																					 IntegrationUtility.CO_INVOICE_JE,
																																					 IntegrationUtility.CO_DEPOSIT,
																																					 IntegrationUtility.CO_INVOICE_PAYMENT,
																																					 IntegrationUtility.VENDOR_RECEIVING
																																				   }
																											};	
    
    public static String getWhereClauseForGETReq(Map<String, List<Object>> payload) {
    	String whereClause = '';
    	
    	for(String syncEntityType: payload.keySet()) {
    		if(syncingEntityTypeToXeroUniqueIdentifierMap.containsKey(syncEntityType) && payload.containsKey(syncEntityType) && 
    			payload.get(syncEntityType).size() > 0) {
    			String xeroUniqueIdentifier = syncingEntityTypeToXeroUniqueIdentifierMap.get(syncEntityType);
    			whereClause += xeroUniqueIdentifier + '=';
    			Map<String, Object> reqObj = (Map<String, Object>)JSON.deserializeUntyped(Json.serialize(payload.get(syncEntityType)[0]));
    			whereClause += '"' + reqObj.get(xeroUniqueIdentifier) +'"';
    			if(syncEntityType.equalsIgnoreCase('ManualJournals')) {
    				whereClause += '&&Status!="VOIDED"&&Status!="DELETED"';
    			}
	    		break;
    		}
    	}
    	return whereClause;
    }
    
    public static Date getDueDateForBills(Date invoiceDate, String paymentTerms, Integer days) {
        Date dueDate;
        if(paymentTerms == 'DAYSAFTERBILLDATE') {
            dueDate = invoiceDate.addDays(days);
        } else if(paymentTerms == 'DAYSAFTERBILLMONTH' || paymentTerms == 'OFFOLLOWINGMONTH') {
            dueDate = invoiceDate.toStartOfMonth().addMonths(1).addDays(days - 1);
        } else if(paymentTerms == 'OFCURRENTMONTH') {
            dueDate = invoiceDate.toStartOfMonth().addDays(days - 1);
            if(dueDate < invoiceDate) {
                dueDate = invoiceDate;
            }
        }
        return dueDate;
    }
    
    public static Boolean isXeroOAuth2Enabled() {
        return (General_Configurations__c.getOrgDefaults() != null) ? General_Configurations__c.getOrgDefaults().Enable_Xero_OAuth_2_0__c : false ;
    }
    
    public static Map<String, String> entityTypeToAccResponseAPINameMap = new Map<String, String>{
    							IntegrationUtility.ITEM_CATEGORY	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.PART_FIFO	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.PART_CATEGORY	=>	CONSTANTS.NAMESPACE + 'Accounting_Response_Category__c',
    							IntegrationUtility.CO_DEPOSIT	=>	CONSTANTS.NAMESPACE + 'AccountingResponseForJournalEntry__c',
    							IntegrationUtility.VENDOR	=>	CONSTANTS.NAMESPACE + 'Vendor_AccountingResponse__c',
    							IntegrationUtility.CO_INVOICE_PAYMENT	=>	CONSTANTS.NAMESPACE + 'AccountingResponseForJournalEntry__c',
    							IntegrationUtility.CUSTOMER	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.STORE_CREDIT	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.UNIT_PRICE_COST	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.STOCK_UNIT_CATEGORY	=>	CONSTANTS.NAMESPACE + 'Accounting_Response_Category__c',
    							IntegrationUtility.VENDOR_RECEIVING	=>	CONSTANTS.NAMESPACE + 'AccountingResponseForJournalEntry__c',
    							IntegrationUtility.INVOICE	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.STOCK_TRADE_IN	=>	CONSTANTS.NAMESPACE + 'Accounting_Response__c',
    							IntegrationUtility.VO_INVOICE	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.AR_PAYMENT	=>	CONSTANTS.NAMESPACE + 'Accounting_Response__c',
    							IntegrationUtility.PAYMENT_ON_ACCOUNT	=>	CONSTANTS.NAMESPACE + 'Accounting_Response__c',
    							IntegrationUtility.LIEN_PAYOUT	=>	CONSTANTS.NAMESPACE + 'Lien_Payout_Accounting_Response__c',
    							IntegrationUtility.CO_INVOICE_JE	=>	CONSTANTS.NAMESPACE + 'AccountingResponseForJournalEntry__c',
    							IntegrationUtility.VO_RETURN	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.UNIT_INVOICE	=>	CONSTANTS.NAMESPACE + 'AccountingResponse__c',
    							IntegrationUtility.UNIT_INVOICE_JE	=>	CONSTANTS.NAMESPACE + 'Accounting_Response_Unit_Invoice_JE__c',
    							IntegrationUtility.HOURS_LOGGED	=>	CONSTANTS.NAMESPACE + 'Accounting_Response__c',
    							IntegrationUtility.COUNT_SESSION_JE	=>	CONSTANTS.NAMESPACE + 'Accounting_Response__c',
    							IntegrationUtility.UNIT_CONSIGNMENT	=>	CONSTANTS.NAMESPACE + 'Accounting_Response_Consignment__c'
    };
    
    public static Map<String, List<String>> entityTypeToSyncTypeMap = new Map<String, List<String>>{
    							IntegrationUtility.ITEM_CATEGORY	=>	new List<String>{'Items'},
    							IntegrationUtility.PART_FIFO	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.PART_CATEGORY	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.CO_DEPOSIT	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.VENDOR	=>	new List<String>{'Contacts'},
    							IntegrationUtility.CO_INVOICE_PAYMENT	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.CUSTOMER	=>	new List<String>{'Contacts'},
    							IntegrationUtility.STORE_CREDIT	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.UNIT_PRICE_COST	=>	new List<String>{'ManualJournals', 'Invoices', 'CreditNotes'},
    							IntegrationUtility.STOCK_UNIT_CATEGORY	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.VENDOR_RECEIVING	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.INVOICE	=>	new List<String>{'Invoices', 'CreditNotes'},
    							IntegrationUtility.STOCK_TRADE_IN	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.VO_INVOICE	=>	new List<String>{'Invoices', 'CreditNotes'},
    							IntegrationUtility.AR_PAYMENT	=>	new List<String>{'Payments'},
    							IntegrationUtility.PAYMENT_ON_ACCOUNT	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.LIEN_PAYOUT	=>	new List<String>{'Invoices'},
    							IntegrationUtility.CO_INVOICE_JE	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.VO_RETURN	=>	new List<String>{'CreditNotes'},
    							IntegrationUtility.UNIT_INVOICE	=>	new List<String>{'Invoices'},
    							IntegrationUtility.UNIT_INVOICE_JE	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.HOURS_LOGGED	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.COUNT_SESSION_JE	=>	new List<String>{'ManualJournals'},
    							IntegrationUtility.UNIT_CONSIGNMENT	=>	new List<String>{'CreditNotes'}
    };
    
    public static Map<String, String> syncingEntityTypeToXeroUniqueIdentifierMap = new Map<String, String>{
    							'ManualJournals'	=>	'Narration',
    							'Contacts'	=>	'ContactNumber',
    							'Invoices'	=>	'InvoiceNumber',
    							'CreditNotes'	=>	'CreditNoteNumber',
    							'Payments'	=>	'Reference'
    };
    
    public static Map<String, String> syncingEntityTypeToXeroAccIdNameMap = new Map<String, String>{
    							'ManualJournals'	=>	'ManualJournalID',
    							'Contacts'	=>	'ContactID',
    							'Invoices'	=>	'InvoiceID',
    							'CreditNotes'	=>	'CreditNoteID',
    							'Payments'	=>	'PaymentID'
    };

    public static Boolean isTxnDateAfterAccPeriodCloseDate(DateTime txnDate) {
		String accPeriodCloseDate = getAccountingPeriodClosedDate();
		if(String.isBlank(accPeriodCloseDate) || (txnDate > DateTimeUtility.getDateTimeFromMSAjaxDateStr(accPeriodCloseDate))) {
			return true;
		}
		return false;
    }
    
    public static Map<String, Map<String, String>> syncEntityNameToFieldNameToValueMap = new Map<String, Map<String, String>>{
        'CO Invoice Payment'	=>	new Map<String, String>{Constants.NAMESPACE +'Available_For_Xero_Invoice_Payment_Sync__c' => 'true', 
															Constants.NAMESPACE +'Xero_CO_Invoice_Payment_Accounting_Id__c' => null
	                                                       },
	    'CO Invoice'	=>	new Map<String, String>{Constants.NAMESPACE +'Available_For_Xero_Sync__c' => 'true', 
													Constants.NAMESPACE +'Xero_Accounting_Id__c' => null
	                                               },
	    'CO Invoice JE'	=>	new Map<String, String>{Constants.NAMESPACE +'Available_For_Xero_CO_Invoice_JE_Sync__c' => 'true', 
													Constants.NAMESPACE +'Xero_CO_Invoice_JE_Accounting_Id__c' => null
	                                               },
	    'Lien Payout'	=>	new Map<String, String>{Constants.NAMESPACE +'Lien_Payout_Avail_For_Xero_Sync__c' => 'true',
													Constants.NAMESPACE +'Lien_Payout_Xero_Accounting_Id__c' => null
	                                               },
		IntegrationUtility.UNIT_CONSIGNMENT =>	new Map<String, String>{Constants.NAMESPACE + 'Available_For_Xero_Consignment_Sync__c' => 'true',
                                                    Constants.NAMESPACE + 'Xero_Consignment_Accounting_Id__c' => null
	                                               }
    };

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

	public static String getAccountingPeriodClosedDate() {
		List<IFW_IntegrationConfig__c> integrationConfigList = AccountingIntegrationSettingsService.getIntegrationConfigWithItems('Xero', new Map<String, String>{IntegrationUtility.ORGANISATION => null});
        
		String accClosedDate = getAccountingClosedDateWithRefreshToken(integrationConfigList);
    	if(XeroUtility.isXeroOAuth2Enabled()) {
    		update integrationConfigList;
    	}
		return accClosedDate;
    }

	public static String getAccountingClosedDateWithRefreshToken(List<IFW_IntegrationConfig__c> integrationConfigList) {
		if(integrationConfigList == null) {
			integrationConfigList = AccountingIntegrationSettingsService.getIntegrationConfigWithItems('Xero', new Map<String, String>{IntegrationUtility.ORGANISATION => null});
		}
        if(integrationConfigList.size() == 0) throw new BlackpurlException('Xero config is not defined');
        
        List<IFW_IntegrationConfigItem__c> configItemList = integrationConfigList[0].IFW_IntegrationConfigItems__r;
        if(configItemList.size() == 0) throw new BlackpurlException('Config item for Organization not defined');
    	
    	HttpResponse orgResponse = BaseIntegration.performCallout(integrationConfigList[0], configItemList[0], null, new List<customHttpHeaderWrapper>(), IntegrationUtility.ORGANISATION);
        if(orgResponse.getStatusCode() == 200) {
            XeroResponseWrapper xeroResponseWrapper = (XeroResponseWrapper)System.JSON.deserialize(orgResponse.getBody(), XeroResponseWrapper.class);
            if(xeroResponseWrapper.Organisations != null && !xeroResponseWrapper.Organisations.isEmpty()) {
				return xeroResponseWrapper.Organisations[0].EndOfYearLockDate;
        	}
        } else {
            throw new BlackpurlException('There is some error fetching organization details from xero.');
        }
		return null;
    }

	public static Boolean isVendorActiveInXero(Account vendorRec, IFW_IntegrationConfig__c integrationConfig) {
        Boolean isVendorActive = true;
		String whereClause = 'ContactID == Guid("' + vendorRec.Xero_Vendor_Accounting_Id__c + '")';
		XeroResponseWrapper xeroResponse = XeroService.getDataFromXero('Contacts', whereClause, integrationConfig);
		if(xeroResponse == null) {
			throw new BlackpurlException('Error communicating with the accounting package, try again later.');
		} else if(!(xeroResponse.Contacts != null && xeroResponse.Contacts.size() == 1 && xeroResponse.Contacts[0].ContactStatus == 'ACTIVE')) { 
			isVendorActive = false;
		}
		return isVendorActive;
	}

	public static Boolean isInvNumberAlreadyExistInXero(String invoiceNumber, IFW_IntegrationConfig__c integrationConfig) {
		Boolean isInvNumberAlreadyExist = false;
        String whereClause = 'InvoiceNumber == "' + invoiceNumber + '"';
        XeroResponseWrapper xeroResponse = XeroService.getDataFromXero('Invoice', whereClause, integrationConfig);
        if(xeroResponse == null) {
            throw new BlackpurlException('Error communicating with the accounting package, try again later.');
        } else if(xeroResponse.Invoices != null && xeroResponse.Invoices.size() > 0) {
			isInvNumberAlreadyExist = true;
		}
		return isInvNumberAlreadyExist;
	}

	public static String validateVendorRefNumberInXero(AccountingUtil.AccountingEntity txnJson, IFW_IntegrationConfig__c integrationConfig) {
		String txnNumberText = (txnJson.TxnType == 'Credit Note') ? 'credit number' : 'vendor reference number';
		if(String.isNotBlank(txnJson.EntityAccId)) {
			String whereClause = 'Contact.ContactID == Guid("' + txnJson.EntityAccId + '")';
			whereClause += '&&' + (txnJson.TxnType == 'Invoice' ? 'InvoiceNumber' : 'CreditNoteNumber') + ' == "' + txnJson.TxnNumber + '"';
			XeroResponseWrapper responseWrapper = XeroService.getDataFromXero(txnJson.TxnType, whereClause, integrationConfig);
			if(responseWrapper == null) return 'Error validating ' + txnNumberText + ' from Xero';
			if((responseWrapper.Invoices != null && responseWrapper.Invoices.size() > 0) || (responseWrapper.CreditNotes != null && responseWrapper.CreditNotes.size() > 0)) {
				return 'Duplicate';
			} else {
				return 'Success'; 
			}
		} else {
			return 'Vendor is not synced to Xero for validating ' + txnNumberText;
		}
		return 'Success';
	}
}