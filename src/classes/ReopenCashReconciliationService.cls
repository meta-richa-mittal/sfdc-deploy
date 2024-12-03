public without sharing class ReopenCashReconciliationService {
    private Cash_Reconciliation__c cashReconRec;
	private ReopenCOValidationWrapper validationWrapperObj;
	private Map<String, Boolean> validationTextToFlagValueMap;
    private Map<String, String> syncEntityFieldMap;
	private static String integrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
	private BaseIntegrationService integrationRec;

    public ReopenCOValidationWrapper validateReopening(String cashReconId) {
        if(!isValidCashReconciliation(cashReconId)) throw new BlackPurlException('Invalid Cash Reconciliation to reopen.'); 
		validationWrapperObj = new ReopenCOValidationWrapper();
		validationTextToFlagValueMap = new Map<String, Boolean>();
        
        validateAccountingEntries();
        
        validationWrapperObj = new ReopenCOValidationWrapper(ReopenUtil.INVOICE_TYPE_CASH_RECON, validationTextToFlagValueMap, validationWrapperObj.ErrorMsg);
        return validationWrapperObj;
    }

    private Boolean isValidCashReconciliation(String cashReconId) {
    	String query = 'SELECT Id, Accounting_Id__c, Accounting_Last_Sync_Time__c, Accounting_Response__c, Sync_Token__c, Status__c, Commit_Reconciliation_Date__c, Reconciliation_Date__c, (SELECT Id, Status__c FROM Cash_Drawer_Reconciliations__r limit 1000) ';    			
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
    		query += ' Accounting_Id__c, Available_For_QB_Sync__c, ';
					
    	} else if(integrationName == XeroUtility.XERO) {
    		query += ' Accounting_Id__c, Available_For_Xero_Sync__c, ';
    	}
    	query = query.substring(0, query.length()-2);
    	query += ' FROM Cash_Reconciliation__c WHERE Id = \''+cashReconId + '\' AND Status__c = \'Reconciled\'';

		List<Cash_Reconciliation__c> cashReconRecList =  Database.query(query);
    	if(!cashReconRecList.isEmpty()) {
    		cashReconRec = cashReconRecList[0];
    		return true;
    	}
    	return false;
    }

    private void validateAccountingEntries() {
		if(hasAllTxnsSyncedToAccountingApp()) {
			if(isAnythingSyncedToAccounting() && String.isNotBlank(integrationName)) {
				Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
				if(integrationName == XeroUtility.XERO) {
					integrationEntityNameToActionMap.put(IntegrationUtility.ORGANISATION, null);
				}

				integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
				if(integrationRec == null) throw new BlackpurlException(integrationName + ' config is not active.');
				List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(integrationName, integrationEntityNameToActionMap);
				if(integrationConfigList.size() == 0) throw new BlackpurlException(integrationName + ' config is not defined.');
				
				Boolean accEntriesCanBeRemoved = AccountingUtil.isTxnDateAfterAccPeriodCloseDateWithRefreshToken(integrationName, cashReconRec.Reconciliation_Date__c, integrationConfigList);
                validationTextToFlagValueMap.put(ReopenUtil.CASH_RECONCILIATION_CAN_BE_REMOVED_FROM_ACCOUNTING, accEntriesCanBeRemoved);
				integrationRec.integrationConfigRec = integrationConfigList[0];
				updateRefreshToken();
			} else {
				validationTextToFlagValueMap.put(ReopenUtil.CASH_RECONCILIATION_CAN_BE_REMOVED_FROM_ACCOUNTING, true);
			}
		} else {
			validationWrapperObj.ErrorMsg = 'Accounting entries could not be found';
    		validationTextToFlagValueMap.put(ReopenUtil.CASH_RECONCILIATION_CAN_BE_REMOVED_FROM_ACCOUNTING, false);
		}
	}

    private Boolean hasAllTxnsSyncedToAccountingApp() {
    	Boolean transactionSynced = true;
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
        	transactionSynced = !(cashReconRec.Available_For_QB_Sync__c && cashReconRec.Accounting_Id__c == null);
        } else if(integrationName == XeroUtility.XERO) {
        	transactionSynced = !(cashReconRec.Available_For_Xero_Sync__c && cashReconRec.Accounting_Id__c == null);
        }
        return transactionSynced;
    }
	
	private Boolean isAnythingSyncedToAccounting() {
        return (cashReconRec.Accounting_Id__c != null);
	}

    public String reopenCashReconciliation(String cashReconId) {
		isValidCashReconciliation(cashReconId);
        if(cashReconRec != null) {
            Boolean isNewPaymentAccountingApplicable = AccountingUtil.isNewPaymentAccountingApplicable(cashReconRec.Reconciliation_Date__c);
            Savepoint sp;
            try {
                Boolean isAllActngEntriesDeleted = isNewPaymentAccountingApplicable ? removeAccountingEntries() : true;
                if(isAllActngEntriesDeleted) {
                    sp = Database.setSavepoint();
                    updatecashReconRec();
                    if(isNewPaymentAccountingApplicable) updateRefreshToken();
                    return 'success';
                }
            } catch(Exception e) {
                if(sp != null) {
                    Database.rollback(sp);
                }
                if(isNewPaymentAccountingApplicable) reSyncDeletedEntities();
                new LogService().createErrorLog('ReopenCashReconciliationService', 'reopenCashReconciliation()', e.getMessage(), null, e.getStackTraceString(), 
                                                cashReconId, LogService.REOPEN_INVOICE, true, 'Info');
            }
		}
		return 'error';
    }

	private void reSyncDeletedEntities() {
		if(String.isNotBlank(integrationName)) {
            updateRefreshToken();
            List<sObject> sObjListToResync = new List<sObject>();
            String objName = (Id.valueOf(cashReconRec.Id)).getSObjectType().getDescribe().getName();
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objName);
            sObject sObjRec = sObjType.newSObject();
            sObjRec.put('Id', cashReconRec.Id);
            
            for(String fieldAPIName: syncEntityFieldMap.keyset()) {
                String dataType = String.valueOf(sObjType.getDescribe().fields.getMap().get(fieldAPIName).getDescribe().getType());
                String fieldValue = syncEntityFieldMap.get(fieldAPIName);
                if(dataType.equalsIgnoreCase('Boolean')) {
                    sObjRec.put(fieldAPIName, Boolean.valueOf(fieldValue));
                } else {
                    sObjRec.put(fieldAPIName, fieldValue);
                }
            }
            sObjListToResync.add(sObjRec);
            CashReconciliationTriggerHelper.preventOnAccountingSync = false;
            DMLUtility.updateSobjectList('Cash_Reconciliation__c', sObjListToResync);
        }
    }

	public void updateRefreshToken() {
		if(String.isNotBlank(integrationName)) {
			DMLUtility.updateSobjectList('IFW_IntegrationConfig__c', integrationRec.integrationConfigRec);
		}
    }

    private Boolean removeAccountingEntries() {
		Boolean isAllEntriesDeleted = true;
		if(String.isNotBlank(integrationName)) {
            syncEntityFieldMap = new Map<String, String>();
		    integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
    	    if(integrationRec == null) throw new BlackpurlException(integrationName + ' config is not active.');
		
            if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
                try {
                    QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(cashReconRec.Accounting_Id__c, cashReconRec.Sync_Token__c), IntegrationUtility.JOURNAL_ENTRY);
                    syncEntityFieldMap = QBUtil.syncEntityNameToFieldNameToValueMap.get(IntegrationUtility.CASH_RECONCILIATION);
                } catch(Exception e) {
                    if(e.getMessage().equalsIgnoreCase('Read timed out')) {
                        if(!QBUtil.reCheckAccountingEntriesInQB(IntegrationUtility.JOURNAL_ENTRY, cashReconRec.Accounting_Id__c, integrationRec.integrationConfigRec)) {
                            isAllEntriesDeleted = false;
                        }
                    } else {
                        isAllEntriesDeleted = false;
                    }
                }
            } else if(integrationName == XeroUtility.XERO) {
                if(cashReconRec.Accounting_Id__c != null) {
                    try {
                        XeroService.deleteEntity(integrationRec, cashReconRec.Accounting_Id__c, IntegrationUtility.JOURNAL_ENTRY);
                        syncEntityFieldMap = XeroUtility.syncEntityNameToFieldNameToValueMap.get(IntegrationUtility.CASH_RECONCILIATION);
                    }  catch(Exception e) {
                        isAllEntriesDeleted = false;
                    }
                }
            }
        }
        return isAllEntriesDeleted;
    }
    
    private void updatecashReconRec() {
        cashReconRec.Available_For_Xero_Sync__c = cashReconRec.Available_For_QB_Sync__c = false;
        cashReconRec.Accounting_Id__c = null;
        cashReconRec.Sync_Token__c = null;
        cashReconRec.Accounting_Last_Sync_Time__c = null;
        cashReconRec.Accounting_Response__c = null;
        cashReconRec.Status__c = 'Unreconciled';
        cashReconRec.Commit_Reconciliation_Date__c = null;
        List<Cash_Drawer_Reconciliation__c> cashDrawerRecList = new List<Cash_Drawer_Reconciliation__c>();
        for(Cash_Drawer_Reconciliation__c cashDrawerRec: cashReconRec.Cash_Drawer_Reconciliations__r) {
            cashDrawerRec.Id = cashDrawerRec.Id;
            cashDrawerRec.Status__c = 'Reviewed';
            cashDrawerRecList.add(cashDrawerRec);
        }
        DMLUtility.updateSobjectList('Cash_Drawer_Reconciliation__c', cashDrawerRecList);
        DMLUtility.updateSobjectList('Cash_Reconciliation__c', cashReconRec);
    }
}