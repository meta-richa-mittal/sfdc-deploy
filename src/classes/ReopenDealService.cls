/** 
* Author: Nidhi Sharma
* Since: Sept 24, 2020
* Name: ReopenDealService 
* Description: Apex class which contains Reopening deal actions.
**/
public without sharing class ReopenDealService {
	
    //START : Validate Deal Reopen action
    private static Deal__c dealRecToReopen = new Deal__c();
    private static String integrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
    private static BaseIntegrationService integrationRec;
    private static Map<String, Map<String, String>> deletedEntitySFIdToAPINameToValueMap;
    private static Boolean isXeroInvoiceAccEntryDeleted = false;
    
    public class ReOpenDealValidationWrapper {
    	public Boolean AccEntriesCanBeRemoved = true;
    	public Boolean CanSoldUnitsBeReversed = false;
    	public Boolean CanTradedInUnitsBeReversed = false;
    	public String ErrroMsg = '';
    }
    
    public static ReOpenDealValidationWrapper validateDealReOpening(String dealId) {
    	if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	
    	ReOpenDealValidationWrapper reopenValidationWrapperObj = new ReOpenDealValidationWrapper();
    	if(!isValidDeal(dealId)) throw new BlackPurlException('Invalid Deal Id'); 
	    	
    	//validate Reopen deal action
    	reopenValidationWrapperObj = validateDealAccountingEntries(integrationName, reopenValidationWrapperObj);
		reopenValidationWrapperObj = validateSoldUnitsAndTradedInUnit(reopenValidationWrapperObj, dealRecToReopen.Deal_Items__r);
		
        return reopenValidationWrapperObj;
    }
    
    private static Boolean isValidDeal(String dealId) {
    	String query = 'SELECT Invoice_Number__r.Invoice_Date__c, CO_Header__r.Id, CO_Header__r.Customer__c, ' +
				'Invoice_Number__r.Total__c, Invoice_Number__r.Total_Payment__c, Invoice_Number__r.Is_Charge_Account_Payment_Exists__c, Invoice_Number__r.Total_Amount_Except_Charge_Account__c, ' + 
    			'(SELECT Id, Type__c, Customer_Owned_Unit__c, Customer_Owned_Unit__r.VIN_Number__c, Stocked_In_Unit__c, Is_Stocked_In__c, Customer_Owned_Unit__r.Stock_Id__c, ' +
    			'Customer_Owned_Unit__r.Consignment__c, ' + (integrationName == QBUtil.QUICKBOOKS_ONLINE ? 'Customer_Owned_Unit__r.Available_For_QB_Consignment_Sync__c, ' +
    			'Customer_Owned_Unit__r.QB_Consignment_Accounting_Id__c, ' : (integrationName == XeroUtility.XERO ? 
    			'Customer_Owned_Unit__r.Available_For_Xero_Consignment_Sync__c, Customer_Owned_Unit__r.Xero_Consignment_Accounting_Id__c, ' : '')) +
    			'Lien_Payout_Avail_For_QB_Sync__c, Lien_Payout_Accounting_Id__c, Lien_Payout_Avail_For_Xero_Sync__c, Lien_Payout_Xero_Accounting_Id__c FROM Deal_Items__r), ';
    			
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
    		query += 'Invoice_Number__r.AccountingId__c, Invoice_Number__r.availForQBSync__c, ' +
					'Invoice_Number__r.JournalEntryAccountingId__c, Invoice_Number__r.availForQBJournalEntrySync__c, ' +
					'Invoice_Number__r.AccountingIdForCOInvoicePayment__c, Invoice_Number__r.availForQBCOInvoicePayment__c, ';
					
    	} else if(integrationName == XeroUtility.XERO) {
    		query += 'Invoice_Number__r.Xero_Accounting_Id__c, Invoice_Number__r.Available_For_Xero_Sync__c, ' +
    				'Invoice_Number__r.Xero_CO_Invoice_JE_Accounting_Id__c, Invoice_Number__r.Available_For_Xero_CO_Invoice_JE_Sync__c, ' +
					'Invoice_Number__r.Xero_CO_Invoice_Payment_Accounting_Id__c, Invoice_Number__r.Available_For_Xero_Invoice_Payment_Sync__c, ';
    	}
    	query = query.substring(0, query.length()-2);
    	query += ' FROM Deal__c WHERE Id =: dealId AND Invoice_Number__c != null LIMIT 1';

    	List<Deal__c> dealList = Database.query(query);
    	
    	if(dealList.size() > 0) {
    		dealRecToReopen = dealList[0];
    		return true;
    	}
    	return false;
    }
    
    //START : Validate Accounting Entries
    private static ReOpenDealValidationWrapper validateDealAccountingEntries(String integrationName, ReOpenDealValidationWrapper reopenValidationWrapperObj) {
    	Boolean accEntriesCanBeRemoved = true;
		if(String.isNotBlank(integrationName)) {
    	if(transactionSyncedToAccApplication()) {
			Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
			if(integrationName == XeroUtility.XERO) {
				integrationEntityNameToActionMap.put(IntegrationUtility.ORGANISATION, null);
			}

			integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
			if(integrationRec == null) throw new BlackpurlException(integrationName + ' config is not active.');
    		List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(integrationName, integrationEntityNameToActionMap);
			if(integrationConfigList.size() == 0) throw new BlackpurlException(integrationName + ' config is not defined.');
			
    		accEntriesCanBeRemoved = (AccountingUtil.isTxnDateAfterAccPeriodCloseDateWithRefreshToken(integrationName, dealRecToReopen.Invoice_Number__r.Invoice_Date__c, integrationConfigList) && canInvoiceBeRemovedFromAcc(integrationConfigList));
			integrationRec.integrationConfigRec = integrationConfigList[0];
			updateRefreshToken();
		} else {
    		reopenValidationWrapperObj.ErrroMsg = 'Accounting entries could not be found.';
    		accEntriesCanBeRemoved = false;
    	}
		}
        reopenValidationWrapperObj.AccEntriesCanBeRemoved = accEntriesCanBeRemoved;
        return reopenValidationWrapperObj;
    }

	private static Boolean canInvoiceBeRemovedFromAcc(List<IFW_IntegrationConfig__c> integrationConfigList) {
		if(isPaidUsingARPayment()) {
			return false;
		} else {
			if(integrationName == QBUtil.QUICKBOOKS_ONLINE && dealRecToReopen.Invoice_Number__r.AccountingId__c != null && dealRecToReopen.Invoice_Number__r.Total_Amount_Except_Charge_Account__c != dealRecToReopen.Invoice_Number__r.Total_Payment__c) {
				return QBUtil.canInvoiceBeRemovedFromAcc(null, dealRecToReopen);
			} else if(integrationName == XeroUtility.XERO && dealRecToReopen.Invoice_Number__r.Xero_Accounting_Id__c != null) {
				return XeroUtility.canInvoiceBeRemovedFromAcc(null, dealRecToReopen, integrationConfigList);
			}
		}
		return true;
	}

	private static Boolean isPaidUsingARPayment() {
		List<AR_Payment__c> arPaymentList = [SELECT Id FROM AR_Payment__c WHERE CO_Invoice_Header__c = :dealRecToReopen.Invoice_Number__c LIMIT 1];
		return arPaymentList.size() > 0;
	}
    
    private static Boolean transactionSyncedToAccApplication() {
    	Boolean transactionSynced = true;
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
        	if((!dealRecToReopen.Invoice_Number__r.availForQBSync__c || dealRecToReopen.Invoice_Number__r.AccountingId__c != null) && 
        	(!dealRecToReopen.Invoice_Number__r.availForQBJournalEntrySync__c || dealRecToReopen.Invoice_Number__r.JournalEntryAccountingId__c != null) && 
        	(!dealRecToReopen.Invoice_Number__r.availForQBCOInvoicePayment__c || dealRecToReopen.Invoice_Number__r.AccountingIdForCOInvoicePayment__c != null)) {
        		for(Deal_Item__c dealItemRec : dealRecToReopen.Deal_Items__r) {
		            if((!dealItemRec.Lien_Payout_Avail_For_QB_Sync__c || dealItemRec.Lien_Payout_Accounting_Id__c != null) &&  
		            	!dealItemRec.Customer_Owned_Unit__r.Available_For_QB_Consignment_Sync__c || 
		            	dealItemRec.Customer_Owned_Unit__r.QB_Consignment_Accounting_Id__c != null) {
		                continue;
		            }
		            transactionSynced = false;
		            break;
		        }
        	} else {
        		transactionSynced = false;
        	}
        } else if(integrationName == XeroUtility.XERO) {
        	if((!dealRecToReopen.Invoice_Number__r.Available_For_Xero_Sync__c || dealRecToReopen.Invoice_Number__r.Xero_Accounting_Id__c != null) && 
        	(!dealRecToReopen.Invoice_Number__r.Available_For_Xero_CO_Invoice_JE_Sync__c || dealRecToReopen.Invoice_Number__r.Xero_CO_Invoice_JE_Accounting_Id__c != null) && 
        	(!dealRecToReopen.Invoice_Number__r.Available_For_Xero_Invoice_Payment_Sync__c || dealRecToReopen.Invoice_Number__r.Xero_CO_Invoice_Payment_Accounting_Id__c != null)) {
        		for(Deal_Item__c dealItemRec : dealRecToReopen.Deal_Items__r) {
		            if((!dealItemRec.Lien_Payout_Avail_For_Xero_Sync__c || dealItemRec.Lien_Payout_Xero_Accounting_Id__c != null) && 
		            	(!dealItemRec.Customer_Owned_Unit__r.Available_For_Xero_Consignment_Sync__c || 
		            	dealItemRec.Customer_Owned_Unit__r.Xero_Consignment_Accounting_Id__c != null)) {
		                continue;
		            }
		            transactionSynced = false;
		            break;
		        }
        	} else {
        		transactionSynced = false;
        	}
        }
        return transactionSynced;
    }
    //END : Validate Accounting Entries
    
    
    // START : Validate Sold Units and Traded In Unit
    private static ReOpenDealValidationWrapper validateSoldUnitsAndTradedInUnit(ReOpenDealValidationWrapper reopenValidationWrapperObj, List<Deal_Item__c> dealItemList) {
    	if(dealItemList.size() > 0) {
    		Set<String> soldUnitVINSet = new Set<String>();
    		Set<String> tradedInSKUIdSet = new Set<String>();
    		Boolean isVINError = false;
    		
    		for(Deal_Item__c dealItemRec : dealItemList) {
    			if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT) {
    				if(!isVINError && String.isBlank(dealItemRec.Customer_Owned_Unit__r.VIN_Number__c)) {
    					isVINError = true;
    					reopenValidationWrapperObj.ErrroMsg = 'VIN Number for '+ dealItemRec.Customer_Owned_Unit__r.Stock_Id__c + ' could not be found.';
    				} else {
    					soldUnitVINSet.add(dealItemRec.Customer_Owned_Unit__r.VIN_Number__c);
    				}
    			} else if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN && !dealItemRec.Is_Stocked_In__c) {
    				tradedInSKUIdSet.add(dealItemRec.Stocked_In_Unit__c);
    			}
    		}
    		
    		reopenValidationWrapperObj.CanSoldUnitsBeReversed = isVINError ? false : canSoldUnitsBeReversed(soldUnitVINSet);
    		reopenValidationWrapperObj.CanTradedInUnitsBeReversed = canTradedInUnitsBeReversed(tradedInSKUIdSet);
    	}
    	return reopenValidationWrapperObj;
    }
    
    private static Boolean canSoldUnitsBeReversed(Set<String> soldUnitVINSet) {
    	if(soldUnitVINSet.size() > 0) {
	        List<Customer_Owned_Unit__c> tradedInSKUList = [SELECT Id, Status__c, (SELECT Id FROM Service_Order_Headers__r LIMIT 1), 
	        					(SELECT Id FROM Deals_Units_Junction__r LIMIT 1) FROM Customer_Owned_Unit__c WHERE VIN_Number__c IN: soldUnitVINSet AND
	        					Account__c =: dealRecToReopen.CO_Header__r.Customer__c AND Unit_Type__c = 'COU'];
	    	for(Customer_Owned_Unit__c skuRec : tradedInSKUList) {
	    		if(skuRec.Status__c != 'Active' || skuRec.Service_Order_Headers__r.size() > 0 || skuRec.Deals_Units_Junction__r.size() > 0) {
	    			return false;
	    		}
	    	}
    	}
    	return true;
	}
    
    private static Boolean canTradedInUnitsBeReversed(Set<String> tradedInSKUIdSet) {
    	if(tradedInSKUIdSet.size() > 0) {
	        List<Customer_Owned_Unit__c> tradedInSKUList = [SELECT Id, Status__c, (SELECT Id FROM Service_Order_Headers__r LIMIT 1), 
	        					(SELECT Id FROM Deals_Units_Junction__r LIMIT 1), (SELECT Id FROM Unit_Prices_Costs__r where Ref_No__c LIKE 'UA-%' LIMIT 1) 
	        					FROM Customer_Owned_Unit__c WHERE Id IN: tradedInSKUIdSet AND Unit_Type__c = 'STOCK'];
	    	for(Customer_Owned_Unit__c skuRec : tradedInSKUList) {
	    		if(skuRec.Status__c != 'Available' || skuRec.Service_Order_Headers__r.size() > 0 || skuRec.Deals_Units_Junction__r.size() > 0 || 
	    						skuRec.Unit_Prices_Costs__r.size() > 0) {
	    			return false;
	    		}
	    	}
    	}
    	return true;
	}
	//END : Validate Sold Units and Traded In Unit
	//END : Validate Deal Reopen action
	
	//START : Reopen Deal action
    public static String reOpenDeal(String dealId) {
    	dealRecToReopen = getDealRecById(dealId);
		Savepoint sp;
		try {
			Boolean isAllEntriesDeleted = removeDealInvoiceAccountingEntries();
			if(isAllEntriesDeleted) {
				sp = Database.setSavepoint();
				updateDealRelatedInfo();
				updateCOHeaderInfo();
				updateRefreshToken();
				if(!System.isFuture()) DealService.calculateDealOptionClearingAndStockTrade(dealId);
				return 'success';
			} else {
				reSyncDeletedEntities();
			}
			
		} catch(Exception e) {
			if(sp != null) {
			Database.rollback(sp);
			}
			reassignNewInvoiceNumber();
			COInvoiceTriggerHelper.preventOnAccountingSync = false;
			reSyncDeletedEntities();
        	// create error log
			new LogService().createErrorLog('ReopenDealService', 'reOpenDeal()', e.getMessage(), null, e.getStackTraceString(), 
                                          		dealId, LogService.REOPEN_DEAL, true, 'Info');
        }
    	return 'error';
    }

    public static Deal__c getDealRecById(String dealId) {
    	String query = 'SELECT Id, Invoice_Number__r.Total__c, CO_Header__r.Id, CO_Header__r.Customer__c, Invoice_Number__r.Checkout_Type__c, ' +
				'Invoice_Number__r.CreatedDate, Reopen_Invoice_Created_Date__c, Invoice_Number__r.Closed_Invoice_Date__c, ' +
    			'Invoice_Number__r.Invoice_Status__c, Invoice_Number__r.AutoNumberHolder__c, Invoice_Number__r.Is_Deal_Invoiced__c, ' +
    			'(SELECT Type__c, Lien_Payout_Accounting_Id__c, Lien_Payout_Xero_Accounting_Id__c, Lien_Payout_Sync_Token__c, ' +
    			'Customer_Owned_Unit__r.Sync_Token_For_Consignment__c, Customer_Owned_Unit__r.QB_Consignment_Accounting_Id__c, ' +
    			'Customer_Owned_Unit__r.Xero_Consignment_Accounting_Id__c, ' +
    			'Customer_Owned_Unit__c, Customer_Owned_Unit__r.VIN_Number__c, Stocked_In_Unit__c, Is_Stocked_In__c FROM Deal_Items__r), ';
    			
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
    		query += 'Invoice_Number__r.AccountingId__c, Invoice_Number__r.SyncToken__c, ' +
					'Invoice_Number__r.JournalEntryAccountingId__c, Invoice_Number__r.SyncTokenForJournalEntry__c, ' +
					'Invoice_Number__r.AccountingIdForCOInvoicePayment__c, Invoice_Number__r.SyncTokenForCOInvoicePayment__c, ' +
					'Invoice_Number__r.Is_Charge_Account_Payment_Exists__c, Invoice_Number__r.Total_Amount_Except_Charge_Account__c, ';
					
    	} else if(integrationName == XeroUtility.XERO) {
    		query += 'Invoice_Number__r.Xero_Accounting_Id__c, Invoice_Number__r.Xero_CO_Invoice_JE_Accounting_Id__c, ' +
					'Invoice_Number__r.Xero_CO_Invoice_Payment_Accounting_Id__c, Invoice_Number__r.Is_Charge_Account_Payment_Exists__c, ';
    	}
    	query = query.substring(0, query.length()-2);
    	query += ' FROM Deal__c WHERE Id =: dealId AND Invoice_Number__c != null LIMIT 1';

    	List<Deal__c> dealList = Database.query(query);
    	if(dealList.size() == 0) throw new BlackpurlException('Invalid Deal Id');
    	return dealList[0];
    }
    
    private static void updateDealRelatedInfo() {
    	updateDealItems();
    	updateDeal();
		updateCOInvoiceHeader();
    }
    
    private static Boolean removeDealInvoiceAccountingEntries() {
		Boolean isAllEntriesDeleted = true;
		if(String.isNotBlank(integrationName)) {
    	deletedEntitySFIdToAPINameToValueMap = new Map<String, Map<String, String>>();
		integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
    	if(integrationRec == null) throw new BlackpurlException(integrationName + ' config is not active.');

        if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
			isAllEntriesDeleted = removeDealInvoiceAccEntriesFromQB();
        } else if(integrationName == XeroUtility.XERO) {
            isAllEntriesDeleted = removeDealInvoiceAccEntriesFromXero();
        }
		}
		return isAllEntriesDeleted;
    }
    
    private static Boolean removeDealInvoiceAccEntriesFromQB() {
		Boolean isDeleted =  true;
    	// delete deal invoice payment
        if(dealRecToReopen.Invoice_Number__r.AccountingIdForCOInvoicePayment__c != null) {
            isDeleted = deleteDealInvoicePaymentFromQB();
        }
        
        // delete deal invoice
        if(isDeleted && dealRecToReopen.Invoice_Number__r.AccountingId__c != null) {
        	isDeleted = deleteDealInvoiceFromQB();
        }
        
        // delete deal invoice JE
        if(isDeleted && dealRecToReopen.Invoice_Number__r.JournalEntryAccountingId__c != null) {
            isDeleted = deleteDealInvoiceJEFromQB();
        }
        
        // delete consignment credit memos
        if(isDeleted) {
        	isDeleted = deleteConsignmentCreditMemosFromQB();
        }
        
        // delete lien payouts
        if(isDeleted) {
        	isDeleted = deleteLienPayoutBillsFromQB();
        }
        
		return isDeleted;
    }

    private static Boolean deleteDealInvoicePaymentFromQB() {
		Boolean isDeleted =  true;
		try {
			QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(dealRecToReopen.Invoice_Number__r.AccountingIdForCOInvoicePayment__c, 
                            dealRecToReopen.Invoice_Number__r.SyncTokenForCOInvoicePayment__c), IntegrationUtility.INVOICE_PAYMENT);
		} catch(Exception e) {
			if(e.getMessage().equalsIgnoreCase('Read timed out')) {
				if(!QBUtil.reCheckAccountingEntriesInQB(IntegrationUtility.PAYMENT, dealRecToReopen.Invoice_Number__r.AccountingIdForCOInvoicePayment__c, integrationRec.integrationConfigRec)) {
					return false;
				}
			} else {
				return false;
			}
		}
		populateDeletedEntityMap(dealRecToReopen.Invoice_Number__c, 'CO Invoice Payment');
		return isDeleted;
    }
    
    private static Boolean deleteDealInvoiceFromQB() {
		Boolean isDeleted =  true;
    	String syncingObjectType = '';
        if(dealRecToReopen.Invoice_Number__r.Checkout_Type__c == 'Third-Party') {
            syncingObjectType = (dealRecToReopen.Invoice_Number__r.Total__c >= 0) ? IntegrationUtility.INVOICE : IntegrationUtility.CREDIT_MEMO;
        } else {
            syncingObjectType = QBUtil.getSyncingObjectName(dealRecToReopen.Invoice_Number__r.Total__c, 
											(dealRecToReopen.Invoice_Number__r.Is_Charge_Account_Payment_Exists__c > 0 && dealRecToReopen.Invoice_Number__r.Total_Amount_Except_Charge_Account__c != dealRecToReopen.Invoice_Number__r.Total__c)? true : false);

		
        }
		try{
			QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(dealRecToReopen.Invoice_Number__r.AccountingId__c, 
    																dealRecToReopen.Invoice_Number__r.SyncToken__c), syncingObjectType);
		} catch(Exception e) {
			if(e.getMessage().equalsIgnoreCase('Read timed out')) {
				if(!QBUtil.reCheckAccountingEntriesInQB(syncingObjectType, dealRecToReopen.Invoice_Number__r.AccountingId__c, integrationRec.integrationConfigRec)) {
					return false;
				}
			} else {
				return false;
			}
		}
        populateDeletedEntityMap(dealRecToReopen.Invoice_Number__c, 'CO Invoice');
		return isDeleted;
    }
    
    private static Boolean deleteDealInvoiceJEFromQB() {
		Boolean isDeleted =  true;
		try {
QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(dealRecToReopen.Invoice_Number__r.JournalEntryAccountingId__c, 
                            dealRecToReopen.Invoice_Number__r.SyncTokenForJournalEntry__c), IntegrationUtility.JOURNAL_ENTRY);
        
		} catch(Exception e) {
			if(e.getMessage().equalsIgnoreCase('Read timed out')) {
				if(!QBUtil.reCheckAccountingEntriesInQB(IntegrationUtility.JOURNAL_ENTRY,dealRecToReopen.Invoice_Number__r.JournalEntryAccountingId__c, integrationRec.integrationConfigRec)) {
					return false;
				}
			} else {
				return false;
			}
		}
		populateDeletedEntityMap(dealRecToReopen.Invoice_Number__c, 'CO Invoice JE');
		return isDeleted;
    }
    
    private static Boolean deleteConsignmentCreditMemosFromQB() {
		Boolean isDeleted =  true;
		String syncingObjectType = IntegrationUtility.CREDIT_MEMO;
		for(Deal_Item__c dealItemRec : dealRecToReopen.Deal_Items__r) {
			if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT && dealItemRec.Customer_Owned_Unit__r.QB_Consignment_Accounting_Id__c != null) {
				try {
					QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(dealItemRec.Customer_Owned_Unit__r.QB_Consignment_Accounting_Id__c, 
						dealItemRec.Customer_Owned_Unit__r.Sync_Token_For_Consignment__c), syncingObjectType);
				} catch(Exception e) {
					if(e.getMessage().equalsIgnoreCase('Read timed out')) {
						if(!QBUtil.reCheckAccountingEntriesInQB(syncingObjectType, dealItemRec.Customer_Owned_Unit__r.QB_Consignment_Accounting_Id__c, integrationRec.integrationConfigRec)) {
							return false;
						}
					} else {
						return false;
					}	
				}
				populateDeletedEntityMap(dealItemRec.Customer_Owned_Unit__c, IntegrationUtility.UNIT_CONSIGNMENT);
			}
		}	
		return isDeleted;
    }
    
    private static Boolean deleteLienPayoutBillsFromQB() {
		Boolean isDeleted =  true;
		for(Deal_Item__c dealItemRec : dealRecToReopen.Deal_Items__r) {
			if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN && dealItemRec.Lien_Payout_Accounting_Id__c != null) {
				try {
					QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(dealItemRec.Lien_Payout_Accounting_Id__c, dealItemRec.Lien_Payout_Sync_Token__c), IntegrationUtility.BILL);
				} catch(Exception e) {
					if(e.getMessage().equalsIgnoreCase('Read timed out')) {
						if(!QBUtil.reCheckAccountingEntriesInQB(IntegrationUtility.BILL, dealItemRec.Lien_Payout_Accounting_Id__c, integrationRec.integrationConfigRec)) {
							return false;
						}
					} else {
						return false;
					}	
				}
				populateDeletedEntityMap(dealItemRec.Id, 'Lien Payout');
			}
		}	
		return isDeleted;
    }
    
    private static Boolean removeDealInvoiceAccEntriesFromXero() {
		Boolean isDeleted =  true;
    	integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
    	if(integrationRec == null) throw new BlackpurlException('Xero config is not active.');
    	
    	//Invoice Payment
        if(dealRecToReopen.Invoice_Number__r.Xero_CO_Invoice_Payment_Accounting_Id__c != null) {
        	try {
        		XeroService.deleteEntity(integrationRec, dealRecToReopen.Invoice_Number__r.Xero_CO_Invoice_Payment_Accounting_Id__c, IntegrationUtility.INVOICE_PAYMENT);
				populateDeletedEntityMap(dealRecToReopen.Invoice_Number__c, 'CO Invoice Payment');
			}  catch(Exception e) {
				isDeleted = false;
			}
        }
        
        //Invoice JE
        if(isDeleted && dealRecToReopen.Invoice_Number__r.Xero_CO_Invoice_JE_Accounting_Id__c != null) {
        	try {
        		XeroService.deleteEntity(integrationRec, dealRecToReopen.Invoice_Number__r.Xero_CO_Invoice_JE_Accounting_Id__c, IntegrationUtility.JOURNAL_ENTRY);
				populateDeletedEntityMap(dealRecToReopen.Invoice_Number__c, 'CO Invoice JE');
			}  catch(Exception e) {
				isDeleted = false;
			}
        }
        
        //Consignment
        for(Deal_Item__c dealItemRec : dealRecToReopen.Deal_Items__r) {
        	if(isDeleted && dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_UNIT && dealItemRec.Customer_Owned_Unit__r.Xero_Consignment_Accounting_Id__c != null) {
            	try {
					XeroService.deleteEntity(integrationRec, dealItemRec.Customer_Owned_Unit__r.Xero_Consignment_Accounting_Id__c, IntegrationUtility.CREDIT_NOTE);
					populateDeletedEntityMap(dealItemRec.Customer_Owned_Unit__c, IntegrationUtility.UNIT_CONSIGNMENT);
				}  catch(Exception e) {
					isDeleted = false;
				}
        	}
        }
        
        //Lien Payout
        for(Deal_Item__c dealItemRec : dealRecToReopen.Deal_Items__r) {
        	if(isDeleted && dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN && dealItemRec.Lien_Payout_Xero_Accounting_Id__c != null) {
            	try {
					XeroService.deleteEntity(integrationRec, dealItemRec.Lien_Payout_Xero_Accounting_Id__c, IntegrationUtility.INVOICE);
					populateDeletedEntityMap(dealItemRec.Id, 'Lien Payout');
				}  catch(Exception e) {
					isDeleted = false;
				}
        	}
        }
        
        //Invoice - Delete Invoice in last as we cannot reuse voided Invoice 
        if(isDeleted && dealRecToReopen.Invoice_Number__r.Xero_Accounting_Id__c != null) {
        	String entityName = (dealRecToReopen.Invoice_Number__r.Total__c >= 0) ? IntegrationUtility.INVOICE : IntegrationUtility.CREDIT_NOTE;
        	try {
				XeroService.deleteEntity(integrationRec, dealRecToReopen.Invoice_Number__r.Xero_Accounting_Id__c, entityName);
				isXeroInvoiceAccEntryDeleted = true;
        		populateDeletedEntityMap(dealRecToReopen.Invoice_Number__c, 'CO Invoice');
			}  catch(Exception e) {
				isDeleted = false;
			}
        }
		return isDeleted;
    }
    
    private static void populateDeletedEntityMap(String mapKey, String entityName) {
    	if(!deletedEntitySFIdToAPINameToValueMap.containsKey(mapKey)) {
        	deletedEntitySFIdToAPINameToValueMap.put(mapKey, new Map<String, String>());
        }
        
        if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
        	deletedEntitySFIdToAPINameToValueMap.get(mapKey).putAll(QBUtil.syncEntityNameToFieldNameToValueMap.get(entityName));
        } else if(integrationName == XeroUtility.XERO) {
        	deletedEntitySFIdToAPINameToValueMap.get(mapKey).putAll(XeroUtility.syncEntityNameToFieldNameToValueMap.get(entityName));
        }
    }
    
    private static void reassignNewInvoiceNumber() {
    	if(isXeroInvoiceAccEntryDeleted && String.isNotBlank(dealRecToReopen.Invoice_Number__c)) {
    		AutoNumberHolder__c autoNumberRec = new AutoNumberHolder__c();
            DMLUtility.insertSobjectList('AutoNumberHolder__c', autoNumberRec);
    		CO_Invoice_Header__c coInvRec = new CO_Invoice_Header__c(Id = dealRecToReopen.Invoice_Number__c);
    		coInvRec.AutoNumberHolder__c = autoNumberRec.Id;
    		COInvoiceTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvRec);
    		COInvoiceTriggerHelper.isForceStopTrigger = false;
    	}
    }
    
    private static void reSyncDeletedEntities() {
		if(String.isNotBlank(integrationName)) {
			updateRefreshToken();

			List<sObject> sObjListToResync = new List<sObject>();
			for(String entitySFId: deletedEntitySFIdToAPINameToValueMap.keySet()) {
				
				String objName = (Id.valueOf(entitySFId)).getSObjectType().getDescribe().getName();
				Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objName);
				sObject sObjRec = sObjType.newSObject();
				sObjRec.put('Id', entitySFId);
				
				for(String fieldAPIName: deletedEntitySFIdToAPINameToValueMap.get(entitySFId).keySet()) {
					String dataType = String.valueOf(sObjType.getDescribe().fields.getMap().get(fieldAPIName).getDescribe().getType());
					String fieldValue = deletedEntitySFIdToAPINameToValueMap.get(entitySFId).get(fieldAPIName);
					if(dataType.equalsIgnoreCase('Boolean')) {
						sObjRec.put(fieldAPIName, Boolean.valueOf(fieldValue));
					} else {
						sObjRec.put(fieldAPIName, fieldValue);
					}
				}
				sObjListToResync.add(sObjRec);
			}
			if(sObjListToResync.size() > 0) {
				update sObjListToResync;
			}
		}
    }
    
    private static void updateRefreshToken() {
		if(String.isNotBlank(integrationName)) {
			DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', integrationRec.integrationConfigRec);
			}
    }
    
    private static void updateCOInvoiceHeader() {
        List<CO_Invoice_Header__c> coInvRecToUpdateList = new List<CO_Invoice_Header__c>{resetInvoiceAccFields(integrationName, dealRecToReopen.Invoice_Number__r)};
        if(coInvRecToUpdateList.size() == 0) return;

		DMLUtility.deleteSobjectList('CO_Salesperson__c', [Select Id FROM CO_Salesperson__c WHERE CO_Invoice_Header__c != null AND CO_Invoice_Header__c =: dealRecToReopen.Invoice_Number__c]);

        resetInvoiceToActive(coInvRecToUpdateList, dealRecToReopen.CO_Header__r.Id);
        if(coInvRecToUpdateList[0].Id != null) DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvRecToUpdateList);
    }
    
    private static CO_Invoice_Header__c resetInvoiceAccFields(String integrationName, CO_Invoice_Header__c coInvoiceHeaderRecToUpdate) {
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
    		
    		coInvoiceHeaderRecToUpdate.AccountingId__c = null;
	    	coInvoiceHeaderRecToUpdate.SyncToken__c = null;
	    	coInvoiceHeaderRecToUpdate.availForQBSync__c = false;
	    	coInvoiceHeaderRecToUpdate.AccountingResponse__c = null;
	    	coInvoiceHeaderRecToUpdate.accountingLastSyncTime__c = null;
			
			coInvoiceHeaderRecToUpdate.JournalEntryAccountingId__c = null;
	    	coInvoiceHeaderRecToUpdate.SyncTokenForJournalEntry__c = null;
	    	coInvoiceHeaderRecToUpdate.availForQBJournalEntrySync__c = false;
	    	coInvoiceHeaderRecToUpdate.AccountingResponseForJournalEntry__c = null;
	    	coInvoiceHeaderRecToUpdate.accountingLastSyncTimeForJE__c = null;
			
			coInvoiceHeaderRecToUpdate.AccountingIdForCOInvoicePayment__c = null;
	    	coInvoiceHeaderRecToUpdate.SyncTokenForCOInvoicePayment__c = null;
	    	coInvoiceHeaderRecToUpdate.availForQBCOInvoicePayment__c = false;
	    	coInvoiceHeaderRecToUpdate.AccountingResponseForCOInvoicePayment__c = null;
	    	coInvoiceHeaderRecToUpdate.accountingLastSyncTimeForCOInvPayment__c = null;
	    	
    	} else if(integrationName == XeroUtility.XERO) {
    		
    		coInvoiceHeaderRecToUpdate.Available_For_Xero_Sync__c = false;
	    	coInvoiceHeaderRecToUpdate.Xero_Accounting_Id__c = null;
	    	coInvoiceHeaderRecToUpdate.AccountingResponse__c = null;
	    	coInvoiceHeaderRecToUpdate.accountingLastSyncTime__c = null;
			
			coInvoiceHeaderRecToUpdate.Available_For_Xero_CO_Invoice_JE_Sync__c = false;
	    	coInvoiceHeaderRecToUpdate.Xero_CO_Invoice_JE_Accounting_Id__c = null;
	    	coInvoiceHeaderRecToUpdate.AccountingResponseForJournalEntry__c = null;
	    	coInvoiceHeaderRecToUpdate.accountingLastSyncTimeForJE__c = null;
			
			coInvoiceHeaderRecToUpdate.Available_For_Xero_Invoice_Payment_Sync__c = false;
	    	coInvoiceHeaderRecToUpdate.Xero_CO_Invoice_Payment_Accounting_Id__c = null;
	    	coInvoiceHeaderRecToUpdate.AccountingResponseForCOInvoicePayment__c = null;
	    	coInvoiceHeaderRecToUpdate.accountingLastSyncTimeForCOInvPayment__c = null;
    	
    	}
    	return coInvoiceHeaderRecToUpdate;
    }
    
    private static void updateDealItems() {
    	List<Deal_Item__c> tradeInListToUpdate = new List<Deal_Item__c>();
    	List<Customer_Owned_Unit__c> couListToUpdate = new List<Customer_Owned_Unit__c>();
    	List<sObject> sObjListToDelete = new List<sObject>();
    	
    	Set<String> soldUnitVINSet = new Set<String>();
    	Set<String> tradedInSKUIdSet = new Set<String>();
    	for(Deal_Item__c dealItemRec : dealRecToReopen.Deal_Items__r) {
    		Customer_Owned_Unit__c couRecToUpdate = new Customer_Owned_Unit__c(Id = dealItemRec.Customer_Owned_Unit__c);
    		if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
    			// update fields related to trade in
    			updateTradeInRelatedFields(dealItemRec, tradeInListToUpdate);
		    	
		    	// delete related sku created
		    	if(!dealItemRec.Is_Stocked_In__c) {
					couRecToUpdate.Status__c = 'Active';// updates on related cou
		    		tradedInSKUIdSet.add(dealItemRec.Stocked_In_Unit__c);
		    		sObjListToDelete.add(new Customer_Owned_Unit__c(Id = dealItemRec.Stocked_In_Unit__c));
		    	}
    		} else {
    			// updates on related sku
		    	couRecToUpdate.Status__c = 'Reserved';
		    	couRecToUpdate.Credit_Note_Number__c = null;
		    	couRecToUpdate.Date_Stocked_Out__c = null;
		    	
		    	//QB
				if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
					couRecToUpdate.QB_Consignment_Accounting_Id__c = couRecToUpdate.Sync_Token_For_Consignment__c = null;
			    	couRecToUpdate.Available_For_QB_Consignment_Sync__c = false;
			    	
			    //Xero
				} else if(integrationName == XeroUtility.XERO) {
		    		couRecToUpdate.Available_For_Xero_Consignment_Sync__c = false;
			    	couRecToUpdate.Xero_Consignment_Accounting_Id__c = null;
		    	}
		    	couRecToUpdate.Accounting_Response_Consignment__c = null;
		    	couRecToUpdate.Accounting_Last_Sync_Time_Consignment__c = null;
		    	
		    	if(String.isNotBlank(dealItemRec.Customer_Owned_Unit__r.VIN_Number__c)) {
		    		soldUnitVINSet.add(dealItemRec.Customer_Owned_Unit__r.VIN_Number__c);
		    	}
    		}
    		couListToUpdate.add(couRecToUpdate);
    	}
    	
    	// get related COU to delete
    	sObjListToDelete.addAll(convertObjListToSObjList(getRelatedCOUsToDelete(soldUnitVINSet)));
    	
    	// get related UPC for SKUs to delete
    	sObjListToDelete.addAll(convertObjListToSObjList(getRelatedUPCToDelete(tradedInSKUIdSet)));
    	
    	if(tradeInListToUpdate.size() > 0) {
    		DealItemTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Deal_Item__c', tradeInListToUpdate);
    		DealItemTriggerHelper.isForceStopTrigger = false;
    	}
    	
    	if(couListToUpdate.size() > 0) {
    		CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', couListToUpdate);
    		CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
    	}
    	
    	if(sObjListToDelete.size() > 0) {
            if(!AccessControl.ifObjectIsDeletable('Customer_Owned_Unit__c')){throw new BlackPurlException('Customer_Owned_Unit__c' + DMLUtility.NOT_DELETABLE);}
            if(!AccessControl.ifObjectIsDeletable('Unit_Price_Cost__c')){throw new BlackPurlException('Unit_Price_Cost__c' + DMLUtility.NOT_DELETABLE);}
    		delete sObjListToDelete;
    	}
    }
    
    private static void updateTradeInRelatedFields(Deal_Item__c dealItemRec, List<Deal_Item__c> tradeInListToUpdate) {
    	//QB
		if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
			dealItemRec.Lien_Payout_Accounting_Id__c = dealItemRec.Lien_Payout_Sync_Token__c = null;
	    	dealItemRec.Lien_Payout_Avail_For_QB_Sync__c = false;
	    	
	    //Xero
		} else if(integrationName == XeroUtility.XERO) {
    		dealItemRec.Lien_Payout_Avail_For_Xero_Sync__c = false;
	    	dealItemRec.Lien_Payout_Xero_Accounting_Id__c = null;
    	}
    	dealItemRec.Lien_Payout_Accounting_Response__c = null;
    	dealItemRec.Lien_Payout_Accounting_Last_Sync_Time__c = null;
    	tradeInListToUpdate.add(dealItemRec);
    }
    
    private static List<Customer_Owned_Unit__c> getRelatedCOUsToDelete(Set<String> soldUnitVINSet) {
    	List<Customer_Owned_Unit__c> couCreatedForSoldUnitsList = new List<Customer_Owned_Unit__c>();
    	if(soldUnitVINSet.size() > 0) {
	    	couCreatedForSoldUnitsList = [SELECT Id, Status__c FROM Customer_Owned_Unit__c WHERE VIN_Number__c IN: soldUnitVINSet AND
		        					Account__c =: dealRecToReopen.CO_Header__r.Customer__c AND Unit_Type__c = 'COU'];
    		for(Customer_Owned_Unit__c couRec: couCreatedForSoldUnitsList) {
		    	if(couRec.Status__c != 'Active') {
		    		throw new BlackPurlException('COU with Id ' + couRec.Id + ' is not having active status.');
		    	}
		    }
    	}
    	return couCreatedForSoldUnitsList;
    }
    
    private static List<Unit_Price_Cost__c> getRelatedUPCToDelete(Set<String> tradedInSKUIdSet) {
    	List<Unit_Price_Cost__c> upcList = new List<Unit_Price_Cost__c>();
    	if(tradedInSKUIdSet.size() > 0) {
    		upcList = [SELECT Id, Ref_No__c FROM Unit_Price_Cost__c WHERE Customer_Owned_Unit__c IN: tradedInSKUIdSet limit :SOQLUtil.getAvailableQueryRowsLimit()];
		    for(Unit_Price_Cost__c upcRec: upcList) {
		    	if(upcRec.Ref_No__c.startsWith('UA-')) {
		    		throw new BlackPurlException('SKU with Id ' + upcRec.Customer_Owned_Unit__c + ' is having unit adjustment ' + upcRec.Ref_No__c + '. So can not reopen deal.');
		    	}
		    }
    	}
    	return upcList;
    }
    
    private static void updateDeal() {
		dealRecToReopen.Status__c = 'Approved';
		if(dealRecToReopen.Reopen_Invoice_Created_Date__c == null) {
			dealRecToReopen.Reopen_Invoice_Created_Date__c = dealRecToReopen.Invoice_Number__r.Closed_Invoice_Date__c;
		}
    	dealRecToReopen.Invoice_Number__c = null;
        DMLUtility.updateSobjectList('Deal__c', dealRecToReopen);
    }

    private static List<CO_Invoice_Header__c> resetInvoiceToActive(List<CO_Invoice_Header__c> coInvoiceRecList, String coHeaderId) {
        setCOInvoiceItemsToActive(coInvoiceRecList[0].Id);
        deleteAllOtherActiveInvoiceOnCO(coInvoiceRecList[0], coHeaderId);
        coInvoiceRecList[0].Invoice_Status__c = 'Active';
		coInvoiceRecList[0].Is_Discount_Shown__c = false;
        coInvoiceRecList[0].AutoNumberHolder__c = null;
        coInvoiceRecList[0].Is_Deal_Invoiced__c = false;
        coInvoiceRecList[0].Closed_Invoice_Date__c = null;
        coInvoiceRecList[0].Salesperson__c = null;

        return coInvoiceRecList;
	}

	private static void setCOInvoiceItemsToActive(String coInvoiceId) {
		List<CO_Invoice_Item__c> invoiceItemList = [SELECT Is_Invoiceable__c, isActive__c FROM CO_Invoice_Item__c Where CO_Invoice_Header__c =: coInvoiceId];
		for(CO_Invoice_Item__c itemRec : invoiceItemList) {
			itemRec.Is_Invoiceable__c = true;
			itemRec.isActive__c = true;
		}

		if(invoiceItemList.size() > 0) {
            DMLUtility.updateSobjectList('CO_Invoice_Item__c', invoiceItemList);
		}
	}

	private static void deleteAllOtherActiveInvoiceOnCO(CO_Invoice_Header__c coInvoiceRec, String coHeaderId) {
		List<CO_Invoice_Header__c> activeCOInvoiceList = getListOfActiveCOInvoiceByCOHeaderId(coHeaderId);
		List<sObject> relatedObjectList = new List<sObject>();

		for(CO_Invoice_Header__c coInvRec : activeCOInvoiceList){
			for(BRP_Log__c brpLogRec : coInvRec.BRP_Logs__r){
				brpLogRec.CO_Invoice_Header__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.BRP_Logs__r));

			for(CO_Line_Item__c coliRec : coInvRec.CO_Line_Items__r){
				coliRec.Invoice_Number__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.CO_Line_Items__r));

			for(CO_Invoice_Item__c coInvItemRec : coInvRec.CO_Invoice_Items__r){
				coInvItemRec.CO_Invoice_Header__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.CO_Invoice_Items__r));

			for(CO_Invoice_Payment__c coipRec : coInvRec.CO_Invoice_Payments__r){
				coipRec.CO_Invoice_Header__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.CO_Invoice_Payments__r));

			for(CO_Deposit__c coDepositRec : coInvRec.CO_Deposits__r){
				coDepositRec.CO_Invoice_Header__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.CO_Deposits__r));

			for(Part_FIFO_Bucket_Activity_Line_Item__c partFIFOLIRec : coInvRec.Part_FIFO_Bucket_Activity_Line_Items__r){
				partFIFOLIRec.CO_Invoice_Header__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.Part_FIFO_Bucket_Activity_Line_Items__r));

			for(AR_Payment__c arPaymentRec : coInvRec.AR_Payments__r){
				arPaymentRec.CO_Invoice_Header__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.AR_Payments__r));

			for(Part_FIFO_Bucket__c partFIFORec : coInvRec.Part_FIFO_Buckets__r){
				partFIFORec.Customer_Return__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.Part_FIFO_Buckets__r));

			for(Service_Order_Header__c soRec : coInvRec.Service_Order_Headers__r){
				soRec.Invoice_Number__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.Service_Order_Headers__r));

			for(Store_Credit__c scRec : coInvRec.Store_Credits__r){
				scRec.CO_Invoice_Header__c = coInvoiceRec.Id;
			}
			relatedObjectList.addAll(convertObjListToSObjList(coInvRec.Store_Credits__r));
		}
		if(relatedObjectList.size() > 0) {
            if(!AccessControl.ifObjectFieldIsUpdateable('BRP_Log__c')) { throw new BlackPurlException('BRP_Log__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('CO_Line_Item__c')) { throw new BlackPurlException('CO_Line_Item__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Item__c')) { throw new BlackPurlException('CO_Invoice_Item__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Payment__c')) { throw new BlackPurlException('CO_Invoice_Payment__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('CO_Deposit__c')) { throw new BlackPurlException('CO_Deposit__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('Part_FIFO_Bucket_Activity_Line_Item__c')) { throw new BlackPurlException('Part_FIFO_Bucket_Activity_Line_Item__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('AR_Payment__c')) { throw new BlackPurlException('AR_Payment__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('Part_FIFO_Bucket__c')) { throw new BlackPurlException('Part_FIFO_Bucket__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('Service_Order_Header__c')) { throw new BlackPurlException('Service_Order_Header__c' + DMLUtility.NOT_UPDATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('Store_Credit__c')) { throw new BlackPurlException('Store_Credit__c' + DMLUtility.NOT_UPDATABLE); }
			update relatedObjectList;
		}
		if(activeCOInvoiceList.size() > 0) {
            DMLUtility.deleteSobjectList('CO_Invoice_Header__c', activeCOInvoiceList);
		}
	}

	private static List<sObject> convertObjListToSObjList(sObject[] objList) {
		return objList;
	}
	
	public static List<CO_Invoice_Header__c> getListOfActiveCOInvoiceByCOHeaderId(String coHeaderId) {
		String query;   
		query = 'SELECT Id, Name, (SELECT CO_Invoice_Header__c FROM BRP_Logs__r), '+
		'(SELECT Invoice_Number__c FROM CO_Line_Items__r), '+
		'(SELECT CO_Invoice_Header__c FROM CO_Invoice_Items__r), '+
		'(SELECT CO_Invoice_Header__c FROM CO_Invoice_Payments__r), '+
		'(SELECT CO_Invoice_Header__c FROM CO_Deposits__r), '+
		'(SELECT CO_Invoice_Header__c FROM Part_FIFO_Bucket_Activity_Line_Items__r), '+
		'(SELECT CO_Invoice_Header__c FROM AR_Payments__r), '+
		'(SELECT Customer_Return__c FROM Part_FIFO_Buckets__r), '+
		'(SELECT Invoice_Number__c FROM Service_Order_Headers__r), '+
		'(SELECT CO_Invoice_Header__c FROM Store_Credits__r), ';
        
        query = query.substring(0, query.length()-2);
        query += ' FROM CO_Invoice_Header__c WHERE CO_Header__c = :coHeaderId AND Invoice_Status__c = \'Active\'';
		return Database.query(query);
	}

	private static void updateCOHeaderInfo() {
		List<CO_Header__c> coHeaderList = [SELECT Order_status__c, Invoiced_Amount__c, Uninvoiced_Amount__c, Deal_Total__c FROM CO_Header__c Where Id =: dealRecToReopen.CO_Header__r.Id];
		if(coHeaderList.size() > 0) {
			if(coHeaderList[0].Order_status__c == 'Closed') {
				coHeaderList[0].Order_status__c = 'Open';
			}
			if(coHeaderList[0].Uninvoiced_Amount__c != null) {
				coHeaderList[0].Uninvoiced_Amount__c += coHeaderList[0].Deal_Total__c;
			} else {
				coHeaderList[0].Uninvoiced_Amount__c = coHeaderList[0].Deal_Total__c;
			}
			if(coHeaderList[0].Invoiced_Amount__c > coHeaderList[0].Deal_Total__c) {
				coHeaderList[0].Invoiced_Amount__c -= coHeaderList[0].Deal_Total__c;
			} else {
				coHeaderList[0].Invoiced_Amount__c = 0;
			}
		}

        DMLUtility.updateSobjectList('CO_Header__c', coHeaderList);
	}
	//END : Reopen Deal action
}