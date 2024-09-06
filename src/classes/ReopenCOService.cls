/** 
* Author: Nidhi Sharma
* Since: July 28, 2021
* Name: ReopenCOService 
* Description: Apex class which contains Reopening co invoices actions.
**/
public without sharing class ReopenCOService {
	
	private CO_Invoice_Header__c coInvRec;
	public static String integrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
	private BaseIntegrationService integrationRec;
	private ReopenCOValidationWrapper validationWrapperObj;
	private Boolean isXeroInvoiceAccEntryDeleted = false;
	private Map<String, Map<String, String>> deletedEntitySFIdToAPINameToValueMap;
	private Map<String, Boolean> validationTextToFlagValueMap;
	 
	public ReopenCOValidationWrapper validateInvoiceReopening(String invoiceHeaderId) {
		if(!isValidInvoice(invoiceHeaderId)) throw new BlackPurlException('Invalid Invoice Id'); 
		validationWrapperObj = new ReopenCOValidationWrapper();
		validationTextToFlagValueMap = new Map<String, Boolean>();
		
		String invoiceType = getInvoiceType();
		if(String.isNotBlank(invoiceType)) {
			if(coInvRec.Deals__r.size() > 0) {
				return new ReopenCOValidationWrapper(ReopenDealService.validateDealReOpening(coInvRec.Deals__r[0].Id));
			} else {
				validateAccountingEntries();
				if(isValidPartToReopen()) {
					validationTextToFlagValueMap.put(ReopenUtil.RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY, true);
				}
				if(coInvRec.Service_Order_Headers__r.size() == 0) {
					if(coInvRec.CO_Header__r.Customer__c == null) {	
						validationTextToFlagValueMap.put(ReopenUtil.UNIT_IS_STILL_IN_INVENTORY, true);
					} else {
						validationTextToFlagValueMap.put(ReopenUtil.UNIT_IS_STILL_OWNED_BY_THE_SAME_CUSTOMER, true);
					}
				}

				if(coInvRec.CO_Invoice_Items__r.size() == 0) {
					validationTextToFlagValueMap.put(ReopenUtil.DEDUCTIBLE_NOT_ALREADY_CLAIMED, true);
				}
			}
			validationWrapperObj = new ReopenCOValidationWrapper(invoiceType, validationTextToFlagValueMap, validationWrapperObj.ErrorMsg);
		} else {
			validationWrapperObj.ErrorMsg = 'Unable to identify invoice type, please contact support';
		}
		return validationWrapperObj;
	}
	
	private String getInvoiceType() {
		String invoiceType;
		if(coInvRec.Deals__r.size() > 0) {
			invoiceType = Reopenutil.INVOICE_TYPE_DEAL;
		} else if(coInvRec.CO_Header__r.Customer__c != null) {
			if(coInvRec.Checkout_Type__c.equalsIgnoreCase(Constants.CHECKOUT_TYPE_DEAL)) {
				if(coInvRec.Service_Order_Headers__r.size() > 0) {
					invoiceType = Reopenutil.INVOICE_TYPE_DEAL_SERVICE;
				} else {
					invoiceType = Reopenutil.INVOICE_TYPE_DEAL_MERCH;
				}
			} else if(coInvRec.Checkout_Type__c.equalsIgnoreCase(Constants.CHECKOUT_TYPE_CUSTOMER)) {
				invoiceType = Reopenutil.INVOICE_TYPE_CUSTOMER;
			} else {
				invoiceType = Reopenutil.INVOICE_TYPE_OTHER;
			}
		} else if(String.isNotBlank(coInvRec.CO_Header__r.CO_Type__c)) {
			if(coInvRec.CO_Header__r.CO_Type__c.equalsIgnoreCase(Constants.CASH_SALE)) {
				invoiceType = Reopenutil.INVOICE_TYPE_CASH_SALE;
			} else if(coInvRec.CO_Header__r.CO_Type__c.equalsIgnoreCase(Constants.INTERNAL_SERVICE)) {
				invoiceType = Reopenutil.INVOICE_TYPE_UNIT_INVENTORY;
			}
		}
		return invoiceType;
	}
	
	private Boolean isValidInvoice(String invoiceHeaderId) {
		Set<String> invalidUnitStatus = new Set<String>{'inactive', 'transferred', 'sold'};
    	String query = 'SELECT Invoice_Date__c, Checkout_Type__c, CO_Header__c, CO_Header__r.Customer__c, CO_Header__r.CO_Type__c, ' +
    			'(Select Id from Deals__r LIMIT 1), ' +
    			'(Select Id from CO_Invoice_Items__r where SO_Payment_Role__r.RecordType.DeveloperName = \'Deductible\' AND ' +
				'SO_Payment_Role__r.Service_Order_Header__r.Invoice_Number__c != null LIMIT 1), ' +
    			'(Select Id, Qty_Out__c, Qty_In__c, Part__r.AvailableParts__c from Part_FIFO_Buckets__r where Is_FIFO_Bucket__c = true), ' +
    			'(Select Id, Deal__c from Service_Order_Headers__r where ' +
    			'Deal__c != null OR Customer_Owned_Unit__r.Status__c IN: invalidUnitStatus LIMIT 1), ';
    			
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
    		query += 'AccountingId__c, availForQBSync__c, ' +
					'JournalEntryAccountingId__c, availForQBJournalEntrySync__c, ' +
					'AccountingIdForCOInvoicePayment__c, availForQBCOInvoicePayment__c, ';
					
    	} else if(integrationName == XeroUtility.XERO) {
    		query += 'Xero_Accounting_Id__c, Available_For_Xero_Sync__c, ' +
    				'Xero_CO_Invoice_JE_Accounting_Id__c, Available_For_Xero_CO_Invoice_JE_Sync__c, ' +
					'Xero_CO_Invoice_Payment_Accounting_Id__c, Available_For_Xero_Invoice_Payment_Sync__c, ';
    	}
    	query = query.substring(0, query.length()-2);
    	query += ' FROM CO_Invoice_Header__c WHERE Id = \''+invoiceHeaderId + '\' AND Status__c = \'Closed\'';

		List<CO_Invoice_Header__c> coInvHeaderList =  Database.query(query);
    	if(coInvHeaderList.size() > 0) {
    		coInvRec = coInvHeaderList[0];
    		return true;
    	}
    	return false;
    }

    private Boolean isValidPartToReopen() {
    	if(coInvRec.Part_FIFO_Buckets__r.size() == 0) {
    		return true;
    	}
		for(Part_FIFO_Bucket__c fifoRec : coInvRec.Part_FIFO_Buckets__r) {
			if(fifoRec.Qty_Out__c != 0) {
				return false;
			}
			if(fifoRec.Qty_In__c <= fifoRec.Part__r.AvailableParts__c) {
				return true;
			}
		}
    	return false;
    }
	
	private void validateAccountingEntries() {
		if(hasAllTxnsSyncedToAccountingApp()) {
			if(isAnythingSyncedToAccounting()) {
				validationTextToFlagValueMap.put(ReopenUtil.INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, 
								AccountingUtil.isTxnDateAfterAccPeriodCloseDate(integrationName, coInvRec.Invoice_Date__c));
			} else {
				validationTextToFlagValueMap.put(ReopenUtil.INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, true);
			}
		} else {
			validationWrapperObj.ErrorMsg = 'Accounting entries could not be found';
    		validationTextToFlagValueMap.put(ReopenUtil.INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, false);
		}
	}
	
	private Boolean isAnythingSyncedToAccounting() {
		Boolean transactionSynced = false;
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
        	if(coInvRec.AccountingId__c != null || coInvRec.JournalEntryAccountingId__c != null || coInvRec.AccountingIdForCOInvoicePayment__c != null) {
        		transactionSynced = true;
        	}
        } else if(integrationName == XeroUtility.XERO) {
        	if(coInvRec.Xero_Accounting_Id__c != null || coInvRec.Xero_CO_Invoice_JE_Accounting_Id__c != null || coInvRec.Xero_CO_Invoice_Payment_Accounting_Id__c != null) {
        		transactionSynced = true;
        	}
        }
        return transactionSynced;
	}
	
	private Boolean hasAllTxnsSyncedToAccountingApp() {
    	Boolean transactionSynced = true;
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
        	if((coInvRec.availForQBSync__c && coInvRec.AccountingId__c == null) || (coInvRec.availForQBJournalEntrySync__c && coInvRec.JournalEntryAccountingId__c == null) 
        		|| (coInvRec.availForQBCOInvoicePayment__c && coInvRec.AccountingIdForCOInvoicePayment__c == null)) {
        		transactionSynced = false;
        	}
        } else if(integrationName == XeroUtility.XERO) {
        	if((coInvRec.Available_For_Xero_Sync__c && coInvRec.Xero_Accounting_Id__c == null) || 
        	(coInvRec.Available_For_Xero_CO_Invoice_JE_Sync__c && coInvRec.Xero_CO_Invoice_JE_Accounting_Id__c == null) || 
        	(coInvRec.Available_For_Xero_Invoice_Payment_Sync__c && coInvRec.Xero_CO_Invoice_Payment_Accounting_Id__c == null)) {
        		transactionSynced = false;
        	}
        }
        return transactionSynced;
    }

	// reopen non-deal customer invoice
	public String reOpenInvoice(String invoiceHeaderId) {
		coInvRec = getCOInvoiceRecById(invoiceHeaderId);
		if(coInvRec != null) {
			if(coInvRec.Deals__r.size() > 0) {
				return ReopenDealService.reopenDeal(coInvRec.Deals__r[0].Id);
			} else {
				Savepoint sp;
				try {
					Boolean isAllActngEntriesDeleted = removeCustomerInvoiceAccountingEntries();
					if(isAllActngEntriesDeleted) {
						if(coInvRec.Part_FIFO_Bucket_Activity_Line_Items__r.size() > 0) {
							delete coInvRec.Part_FIFO_Bucket_Activity_Line_Items__r;
						}
						if(coInvRec.Part_FIFO_Buckets__r.size() > 0) {
							delete coInvRec.Part_FIFO_Buckets__r;
						}
						if(coInvRec.CO_Line_Items__r.size() > 0) {
							updateRelatedCOLIs();
						}
						if(coInvRec.Service_Order_Headers__r.size() > 0) {
							updateRelatedServiceJobs();
							//Internal service jobs
							deleteRelatedUPCs(coInvRec.Service_Order_Headers__r);
						}
						
						//Deductible
						updateDeductibleRecords(invoiceHeaderId);
						///deal option and fees
						updateDealRelatedFields();
						
						//common objects
						updateCOInvoiceHeader();
						updateCOHeaderInfo();
						updatePartsInfo();
						return 'success';
					} else {
						reSyncDeletedEntities();
					}
				} catch(Exception e) {
					if(sp != null) {
						Database.rollback(sp);
					}
					reassignNewInvoiceNumber();
					reSyncDeletedEntities();
					// create error log
					new LogService().createErrorLog('ReopenCOService', 'reOpenInvoice()', e.getMessage(), null, e.getStackTraceString(), 
		                                          		invoiceHeaderId, LogService.REOPEN_INVOICE, true, 'Info');
				}
			}
		}
		return 'error';
	}

	public void updatePartsInfo() {
		set<id> partIdSet = new set<id>();
		
		for(CO_Line_Item__c coli : coInvRec.CO_Line_Items__r) {
			partIdSet.add(coli.Part__c);
		}

		if(partIdSet != null && partIdSet.size() > 0) {
			
			List<Part__c> partList = [SELECT Id, Qty_In_Stock__c, Qty_Committed__c, Oversold_Qty__c, Last_Counted__c, Oversold_Cost__c, Total_Cost__c, Average_Cost__c,
					(SELECT id, Qty_In__c, Qty_Out__c, Total__c, Source_Name__c, Remaining_Qty__c FROM Part_FIFO_Buckets__r Where Is_FIFO_Bucket__c = true ),
					(SELECT Qty_Committed__c, Deal__c, Oversold_Qty__c FROM CO_Line_Items__r WHERE Closed_CO_Invoice_link__c = null AND Invoice_Number__c = null AND 
						CO_Header__r.Order_Status__c != 'Quote'),
					(SELECT Return_Qty__c FROM Return_VO_Line_Items__r WHERE Return_VO_Header__r.Status__c NOT IN('Approved','Credited'))
					FROM Part__c WHERE Id In :partIdSet];

			for(Part__c partRec : partList) {
				Decimal oversoldQty = 0;
				Decimal oversoldCost = 0;
				Decimal TotalCost = 0;
				Decimal QtyInStock = 0;
				
				for(Part_FIFO_Bucket__c partFIFOBucketRec : partRec.Part_FIFO_Buckets__r) {
					if(!String.isBlank(partFIFOBucketRec.Source_Name__c) && (partFIFOBucketRec.Source_Name__c.equalsIgnoreCase('Oversold') || partFIFOBucketRec.Remaining_Qty__c < 0)) {
						oversoldQty += ((partFIFOBucketRec.Qty_In__c != null) ? partFIFOBucketRec.Qty_In__c : 0.00) - ((partFIFOBucketRec.Qty_Out__c != null) ? partFIFOBucketRec.Qty_Out__c : 0.00);
						oversoldCost += (partFIFOBucketRec.Total__c != null) ? partFIFOBucketRec.Total__c : 0.00;
					} else {
						TotalCost  += (partFIFOBucketRec.Total__c != null ) ? partFIFOBucketRec.Total__c : 0.00;
						QtyInStock += (partFIFOBucketRec.Remaining_Qty__c != null ) ? partFIFOBucketRec.Remaining_Qty__c : 0;
					}
				}

				PartRec.Qty_In_Stock__c = QtyInStock;
				PartRec.Last_Counted__c = system.Now();
				partRec.Oversold_Qty__c = oversoldQty < 0 ? -(oversoldQty) : oversoldQty;
				partRec.Oversold_Cost__c = oversoldCost < 0 ? -(oversoldCost) : oversoldCost;
				partRec.Total_Cost__c = TotalCost;	
				partRec.Average_Cost__c = (QtyInStock > 0) ? (TotalCost / QtyInStock) : 0.00;
				partRec.Qty_Committed__c = 0;

				for(CO_Line_Item__c coli: partRec.CO_Line_Items__r) {
					partRec.Qty_Committed__c += ((coli.Qty_Committed__c != null ? coli.Qty_Committed__c : 0) - (coli.Oversold_Qty__c != null ? coli.Oversold_Qty__c : 0));
				}

				for(Return_VO_Line_Item__c rvoli: partRec.Return_VO_Line_Items__r) {
					if(rvoli.Return_Qty__c != null) {
						partRec.Qty_Committed__c += rvoli.Return_Qty__c;
					}
				}
			}
			
			if(partList.size() > 0) {
                DMLUtility.updateSobjectList('Part__c', partList);
			}
		}
	}

	private void updateCOInvoiceHeader() {
        List<CO_Invoice_Header__c> coInvRecToUpdateList = new List<CO_Invoice_Header__c>{resetInvoiceAccFields(integrationName, coInvRec)};
        if(coInvRecToUpdateList.size() == 0) return;
        resetInvoiceToActive(coInvRecToUpdateList, coInvRec.CO_Header__c);
        if(coInvRecToUpdateList[0].Id != null) DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvRecToUpdateList);
    }

    private List<CO_Invoice_Header__c> resetInvoiceToActive(List<CO_Invoice_Header__c> coInvoiceRecList, String coHeaderId) {
        setCOInvoiceItemsToActive(coInvoiceRecList[0].Id);
        deleteAllOtherActiveInvoiceOnCO(coInvoiceRecList[0], coHeaderId);
        coInvoiceRecList[0].Invoice_Status__c = 'Active';
		coInvoiceRecList[0].Is_Discount_Shown__c = false;
        coInvoiceRecList[0].AutoNumberHolder__c = null;
        coInvoiceRecList[0].Closed_Invoice_Date__c = null;
        coInvoiceRecList[0].Checkout_Type__c = null;

        return coInvoiceRecList;
	}

	public void setCOInvoiceItemsToActive(String coInvoiceId) {
		List<CO_Invoice_Item__c> invoiceItemList = [SELECT Is_Invoiceable__c, isActive__c FROM CO_Invoice_Item__c Where CO_Invoice_Header__c =: coInvoiceId];
		for(CO_Invoice_Item__c itemRec : invoiceItemList) {
			itemRec.Is_Invoiceable__c = true;
			itemRec.isActive__c = true;
		}
		if(invoiceItemList.size() > 0) {
            DMLUtility.updateSobjectList('CO_Invoice_Item__c', invoiceItemList);
		}
	}

	public void deleteAllOtherActiveInvoiceOnCO(CO_Invoice_Header__c coInvoiceRec, String coHeaderId) {
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

	public CO_Invoice_Header__c resetInvoiceAccFields(String integrationName, CO_Invoice_Header__c coInvoiceHeaderRecToUpdate) {
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

	public CO_Invoice_Header__c getCOInvoiceRecById(String invoiceHeaderId) {
    	String query = 'SELECT Invoice_Date__c, Checkout_Type__c, CO_Header__c, CO_Header__r.Customer__c, Total__c, ' +
        		'Invoice_Status__c, AutoNumberHolder__c, ' +
    			'Closed_Invoice_Date__c, (Select Id from Deals__r), (Select Id from Part_FIFO_Buckets__r), ' +
				'(Select Id from Part_FIFO_Bucket_Activity_Line_Items__r), ' +
				'(Select Closed_CO_Invoice_link__c, Actual_Invoice_Date_Time__c, Option_Fee__c, Deal__r.Is_Deal_Fulfilled__c, Invoice_Number__c, Part__c from CO_Line_Items__r), ' +
				'(Select Transaction_Type__r.Type__c, Invoice_Number__c, Actual_Invoice_Date_Time__c, Work_Status__c from Service_Order_Headers__r), ';

    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
    		query += 'AccountingId__c, JournalEntryAccountingId__c, AccountingIdForCOInvoicePayment__c, ' +
					'SyncToken__c, SyncTokenForCOInvoicePayment__c, SyncTokenForJournalEntry__c, ' +
					'availForQBSync__c, availForQBJournalEntrySync__c, availForQBCOInvoicePayment__c, ' +
					'accountingLastSyncTime__c, accountingLastSyncTimeForJE__c, accountingLastSyncTimeForCOInvPayment__c, Is_Charge_Account_Payment_Exists__c, Total_Amount_Except_Charge_Account__c, ';
					
    	} else if(integrationName == XeroUtility.XERO) {
    		query += 'Xero_Accounting_Id__c, Xero_CO_Invoice_JE_Accounting_Id__c, Xero_CO_Invoice_Payment_Accounting_Id__c, ' +
					'Available_For_Xero_Sync__c, Available_For_Xero_CO_Invoice_JE_Sync__c, Available_For_Xero_Invoice_Payment_Sync__c, ' +
					'accountingLastSyncTime__c, accountingLastSyncTimeForJE__c, accountingLastSyncTimeForCOInvPayment__c, ';
    	}
		query = query.substring(0, query.length()-2);
        query += ' FROM CO_Invoice_Header__c WHERE Id = \''+ BPUtility.escapeSingleQuotes(invoiceHeaderId) + '\' AND Status__c = \'Closed\'';
		
		List<CO_Invoice_Header__c> invoiceHeaderList = Database.query(query);
    	if(invoiceHeaderList.size() == 0) throw new BlackpurlException('Invalid Id');
    	return invoiceHeaderList[0];
    }

	private void updateRelatedServiceJobs() {
		List<Service_Order_Header__c> sohListToUpdate = new List<Service_Order_Header__c>();
		for(Service_Order_Header__c sohRec : coInvRec.Service_Order_Headers__r) {
			sohRec.Invoice_Number__c = null;
			sohRec.Work_Status__c = 'Complete';
			if(sohRec.Transaction_Type__c != null && String.isNotBlank(sohRec.Transaction_Type__r.Type__c) && 
				sohRec.Transaction_Type__r.Type__c.equalsIgnoreCase('Third-Party')) {
				sohRec.Claim_Status__c = 'Submitted';
			}
			if(sohRec.Actual_Invoice_Date_Time__c == null) {
				sohRec.Actual_Invoice_Date_Time__c = coInvRec.Closed_Invoice_Date__c;
			}
			sohListToUpdate.add(sohRec);
		}
        DMLUtility.updateSobjectList('Service_Order_Header__c', sohListToUpdate);
	}
	
	private void updateDealRelatedFields() {
		List<Option_Fee__c> optionFeeUpdateList = new List<Option_Fee__c>();
		String dealId;
		for(CO_Line_Item__c coliRec : coInvRec.CO_Line_Items__r) {
			if(String.isNotBlank(coliRec.Deal__c) && String.isNotBlank(coliRec.Option_Fee__c)) {
				dealId = coliRec.Deal__r.Is_Deal_Fulfilled__c != null && coliRec.Deal__r.Is_Deal_Fulfilled__c ? coliRec.Deal__c : dealId;
				optionFeeUpdateList.add(new Option_Fee__c(Id = coliRec.Option_Fee__c, Status__c = Constants.COMMITTED));
			}
		}
		if(coInvRec.Service_Order_Headers__r.size() > 0) {
			for(Service_Order_Line_Item__c soliRec : [Select Id, Option_Fee__c, Service_Order_Header__r.Deal__c, Service_Order_Header__r.Deal__r.Is_Deal_Fulfilled__c,
			Service_Order_Header__c from Service_Order_Line_Item__c 
			where Service_Order_Header__c IN: coInvRec.Service_Order_Headers__r AND Service_Order_Header__r.Deal__c != null AND Option_Fee__c != null]) {
				dealId = soliRec.Service_Order_Header__r.Deal__r.Is_Deal_Fulfilled__c != null && soliRec.Service_Order_Header__r.Deal__r.Is_Deal_Fulfilled__c ? 
					soliRec.Service_Order_Header__r.Deal__c : dealId;
				optionFeeUpdateList.add(new Option_Fee__c(Id = soliRec.Option_Fee__c, Status__c = Constants.COMMITTED));		
			}
		}
		
		DMLUtility.updateSobjectList('Option_Fee__c', optionFeeUpdateList);
		if(String.isNotBlank(dealId)) {
			DealTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Deal__c', new Deal__c(Id = dealId, Is_Deal_Fulfilled__c = false));
			DealTriggerHelper.isForceStopTrigger = false;
		}
		List<Customer_Owned_Unit__c> unitListToUpdate = CustomerOrderCtrl.calculateDealOptionsWIPCost(coInvRec.Id);
		DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitListToUpdate);
	}
	
	private void updateDeductibleRecords(String invoiceHeaderId) {
		List<SO_Payment_Role__c> SOPaymentRoleList =  new List<SO_Payment_Role__c>();
		List<CO_Invoice_Item__c> coInvoiceItemList = [SELECT SO_Payment_Role__c FROM CO_Invoice_Item__c WHERE SO_Payment_Role__r.RecordType.DeveloperName = 'Deductible' AND CO_Invoice_Header__c = :invoiceHeaderId];
		for(CO_Invoice_Item__c coInvItem : coInvoiceItemList) {
			SO_Payment_Role__c SoPaymentRec = new SO_Payment_Role__c(Id = coInvItem.SO_Payment_Role__c);
			SoPaymentRec.Deductible_Status__c = null;
			SoPaymentRec.Status__c = null;
			SOPaymentRoleList.add(SoPaymentRec);
		}
		if(SOPaymentRoleList.size() > 0) {
            DMLUtility.updateSobjectList('SO_Payment_Role__c', SOPaymentRoleList);
		}

	}
	
	private void deleteRelatedUPCs(List<Service_Order_Header__c> soHeaderList) {
		List<Deal_Unit_Price_Cost__c> dealUPCDeleteList = new List<Deal_Unit_Price_Cost__c>();
		List<Unit_Price_Cost__c> upcDeleteList = new List<Unit_Price_Cost__c>();
		List<SObject> sobjectDeleteList =  new List<SObject>();
		for(Unit_Price_Cost__c upcRec : [SELECT Id, (Select Id From Deal_Unit_Prices_Costs__r where Deal_Item__r.Deal__r.Status__c != 'Invoiced') FROM Unit_Price_Cost__c 
				WHERE Service_Order_Line_Item__r.Service_Order_Header__c IN: soHeaderList]) {
			dealUPCDeleteList.addAll((List<Deal_Unit_Price_Cost__c>) upcRec.Deal_Unit_Prices_Costs__r);
			upcDeleteList.add(upcRec);
		}
		DMLUtility.deleteSobjectList('Deal_Unit_Price_Cost__c', dealUPCDeleteList);
		DMLUtility.deleteSobjectList('Unit_Price_Cost__c', upcDeleteList);
	}

	private void updateRelatedCOLIs() {
		List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();
		for(CO_Line_Item__c coliRec : coInvRec.CO_Line_Items__r) {
			coliRec.Closed_CO_Invoice_link__c = null;
			coliRec.Invoice_Number__c = null;
			if(coliRec.Actual_Invoice_Date_Time__c == null) {
				coliRec.Actual_Invoice_Date_Time__c = coInvRec.Closed_Invoice_Date__c;
			}
			coliListToUpdate.add(coliRec);
		}
		COLineItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('CO_Line_Item__c', coliListToUpdate);
		COLineItemTriggerHelper.isForceStopTrigger = false;
	}

	private Boolean removeCustomerInvoiceAccountingEntries() {
		Boolean isAllEntriesDeleted = true;
		deletedEntitySFIdToAPINameToValueMap = new Map<String, Map<String, String>>();
        if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
			isAllEntriesDeleted = removeInvoiceAccEntriesFromQB();
        } else if(integrationName == XeroUtility.XERO) {
			removeInvoiceAccEntriesFromXero();
        }
		return isAllEntriesDeleted;
    }

	private Boolean removeInvoiceAccEntriesFromQB() {
		Boolean isDeleted =  true;
    	
		// delete invoice payment
        if(coInvRec.AccountingIdForCOInvoicePayment__c != null) {
            isDeleted = deleteInvoicePaymentFromQB();
        }

        // delete invoice
        if(isDeleted && coInvRec.AccountingId__c != null) {
        	isDeleted = deleteInvoiceFromQB();
        }
        
        // delete invoice JE
        if(isDeleted && coInvRec.JournalEntryAccountingId__c != null) {
            isDeleted = deleteInvoiceJEFromQB();
        }

		return isDeleted;
    }

	private Boolean deleteInvoicePaymentFromQB() {
		Boolean isDeleted =  true;
		try {
			QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(coInvRec.AccountingIdForCOInvoicePayment__c, 
								coInvRec.SyncTokenForCOInvoicePayment__c), 'payment');
		} catch(Exception e) {
			if(e.getMessage().equalsIgnoreCase('Read timed out')) {
				if(!reCheckAccountingEntriesInQB('payment', coInvRec.AccountingIdForCOInvoicePayment__c)) {
					return false;
				}
			} else {
				return false;
			}
		}
		populateDeletedEntityMap(coInvRec.ID, 'CO Invoice Payment');
		return isDeleted;
    }
    
    private Boolean deleteInvoiceFromQB() {
		Boolean isDeleted =  true;
    	String syncingObjectType = '';
		if(coInvRec.Checkout_Type__c.equalsIgnoreCase(Constants.CHECKOUT_TYPE_THIRD_PARTY)) {
            syncingObjectType = (coInvRec.Total__c >= 0) ? QBUtil.INVOICE : QBUtil.CREDIT_MEMO;
        } else {
          	syncingObjectType = CustomerInvoiceService.getSyncingObjectName(coInvRec.Total__c, 
											(coInvRec.Is_Charge_Account_Payment_Exists__c > 0 && coInvRec.Total_Amount_Except_Charge_Account__c != coInvRec.Total__c)? true : false);
        }
		try{
			QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(coInvRec.AccountingId__c, 
    																 coInvRec.SyncToken__c), syncingObjectType);
		} catch(Exception e) {
			if(e.getMessage().equalsIgnoreCase('Read timed out')) {
				if(!reCheckAccountingEntriesInQB(syncingObjectType, coInvRec.AccountingId__c)) {
					return false;
				}
			} else {
				return false;
			}
		}
		populateDeletedEntityMap(coInvRec.ID, 'CO Invoice');
		return isDeleted;
    }
    
    private Boolean deleteInvoiceJEFromQB() {
		Boolean isDeleted =  true;
		try {
			QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(coInvRec.JournalEntryAccountingId__c, 
												coInvRec.SyncTokenForJournalEntry__c), 'journalentry');
        
		} catch(Exception e) {
			if(e.getMessage().equalsIgnoreCase('Read timed out')) {
				if(!reCheckAccountingEntriesInQB('journalentry', coInvRec.JournalEntryAccountingId__c)) {
					return false;
				}
			} else {
				return false;
			}
		}
		populateDeletedEntityMap(coInvRec.ID, 'CO Invoice JE');
		return isDeleted;
    }

	public Boolean reCheckAccountingEntriesInQB(String objectType, String quickbookId) {
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequest(objectType, quickbookId);
		HttpResponse res = responseObj.Response;
		QuickBookQueryService.refreshToken = responseObj.RefreshToken;
		QuickBookQueryService.refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
		if(res.getStatusCode() != 400 && !res.getBody().containsIgnoreCase('Object Not Found')) {
			return false;
		} else {
			return true;
		}
	}

	private void updateCOHeaderInfo() {
		CO_Header__c coRec = TaxCalculation.populateOrderTotal(coInvRec.CO_Header__c, false);
		coRec.Order_status__c = 'Open';
        DMLUtility.updateSobjectList('CO_Header__c', coRec);
	}

	public List<CO_Invoice_Header__c> getListOfActiveCOInvoiceByCOHeaderId(String coHeaderId) {
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

	private List<sObject> convertObjListToSObjList(sObject[] objList) {
		return objList;
	}

	public void updateRefreshToken() {
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
        	if(QuickBookQueryService.refreshToken !=  null) {
				QBUtil.saveRefreshToken(QuickBookQueryService.refreshToken, QuickBookQueryService.refreshTokenExpiresIn);
			}
        } else if(integrationName == XeroUtility.XERO && XeroUtility.isXeroOAuth2Enabled() && integrationRec != null && integrationRec.integrationConfigRec != null) {
            DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', integrationRec.integrationConfigRec);
        }
    }

	private void removeInvoiceAccEntriesFromXero() {
    	integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
    	if(integrationRec == null) throw new BlackpurlException('Xero config is not active.');
    	
    	//Invoice Payment
        if(coInvRec.Xero_CO_Invoice_Payment_Accounting_Id__c != null) {
        	XeroService.deleteEntity(integrationRec, coInvRec.Xero_CO_Invoice_Payment_Accounting_Id__c, IntegrationUtility.INVOICE_PAYMENT);
        	populateDeletedEntityMap(coInvRec.ID, 'CO Invoice Payment');
        }
        
        //Invoice JE
        if(coInvRec.Xero_CO_Invoice_JE_Accounting_Id__c != null) {
        	XeroService.deleteEntity(integrationRec, coInvRec.Xero_CO_Invoice_JE_Accounting_Id__c, IntegrationUtility.JOURNAL_ENTRY);
        	populateDeletedEntityMap(coInvRec.ID, 'CO Invoice JE');
        }
        
        //Invoice - Delete Invoice in last as we cannot reuse voided Invoice 
        if(coInvRec.Xero_Accounting_Id__c != null) {
        	String entityName = (coInvRec.Total__c >= 0) ? IntegrationUtility.INVOICE : IntegrationUtility.CREDIT_NOTE;
        	XeroService.deleteEntity(integrationRec, coInvRec.Xero_Accounting_Id__c, entityName);
        	isXeroInvoiceAccEntryDeleted = true;
        	populateDeletedEntityMap(coInvRec.ID, 'CO Invoice');
        }
    }

	private void reassignNewInvoiceNumber() {
    	if(isXeroInvoiceAccEntryDeleted && String.isNotBlank(coInvRec.Invoice_Number__c)) {
    		AutoNumberHolder__c autoNumberRec = new AutoNumberHolder__c();
            DMLUtility.insertSobjectList('AutoNumberHolder__c', autoNumberRec);
    		coInvRec.AutoNumberHolder__c = autoNumberRec.Id;
    		COInvoiceTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvRec);
    		COInvoiceTriggerHelper.isForceStopTrigger = false;
    	}
    }

	private void reSyncDeletedEntities() {
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
        	COInvoiceTriggerHelper.preventOnAccountingSync = false;
            update sObjListToResync;
        }
    }

	private void populateDeletedEntityMap(String mapKey, String entityName) {
    	if(!deletedEntitySFIdToAPINameToValueMap.containsKey(mapKey)) {
        	deletedEntitySFIdToAPINameToValueMap.put(mapKey, new Map<String, String>());
        }
        if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
        	deletedEntitySFIdToAPINameToValueMap.get(mapKey).putAll(QBUtil.syncEntityNameToFieldNameToValueMap.get(entityName));
        } else if(integrationName == XeroUtility.XERO) {
        	deletedEntitySFIdToAPINameToValueMap.get(mapKey).putAll(XeroUtility.syncEntityNameToFieldNameToValueMap.get(entityName));
        }
    }

}