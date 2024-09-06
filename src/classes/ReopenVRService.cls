/** 
* Author: Nidhi Sharma
* Since: Dec 05, 2023
* Name: ReopenCOService 
* Description: Apex class which contains Reopening co invoices actions.
**/
public without sharing class ReopenVRService {
    
    private Vendor_Receiving_Header__c vrRec;
	private ReopenCOValidationWrapper validationWrapperObj;
	private Map<String, Boolean> validationTextToFlagValueMap;
    private Map<String, String> syncEntityFieldMap;
	private static String integrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
	private BaseIntegrationService integrationRec;

    public ReopenCOValidationWrapper validateReopening(String vrId) {
        if(!isValidVR(vrId)) throw new BlackPurlException('Invalid vendor receiving to reopen.'); 
		validationWrapperObj = new ReopenCOValidationWrapper();
		validationTextToFlagValueMap = new Map<String, Boolean>();
        
        validateAccountingEntries();
        validateVRToReopen();
        
        validationWrapperObj = new ReopenCOValidationWrapper(ReopenUtil.INVOICE_TYPE_VR, validationTextToFlagValueMap, validationWrapperObj.ErrorMsg);
        return validationWrapperObj;
    }

    private Boolean isValidVR(String vrId) {
    	String query = 'SELECT Id, In_Progress_VI__c, Finalized_Date__c, ' +
        '(Select Id, Qty_Out__c, Qty_In__c, Part__r.AvailableParts__c FROM Part_FIFO_Buckets__r WHERE Is_FIFO_Bucket__c = true), ';
    			
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
    		query += ' AccountingIdForJournalEntry__c, availForQBJournalEntrySync__c, ';
					
    	} else if(integrationName == XeroUtility.XERO) {
    		query += ' Xero_Accounting_Id__c, Available_For_Xero_Sync__c, ';
    	}
    	query = query.substring(0, query.length()-2);
    	query += ' FROM Vendor_Receiving_Header__c WHERE Id = \''+vrId + '\' AND Status__c = \'Stocked\'';

		List<Vendor_Receiving_Header__c> vrRecList =  Database.query(query);
    	if(!vrRecList.isEmpty()) {
    		vrRec = vrRecList[0];
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
				
				Boolean accEntriesCanBeRemoved = AccountingUtil.isTxnDateAfterAccPeriodCloseDateWithRefreshToken(integrationName, vrRec.Finalized_Date__c, integrationConfigList);
				validationTextToFlagValueMap.put(ReopenUtil.INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, accEntriesCanBeRemoved);
				integrationRec.integrationConfigRec = integrationConfigList[0];
				updateRefreshToken();
			} else {
				validationTextToFlagValueMap.put(ReopenUtil.INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, true);
			}
		} else {
			validationWrapperObj.ErrorMsg = 'Accounting entries could not be found';
    		validationTextToFlagValueMap.put(ReopenUtil.INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, false);
		}
	}

    private Boolean hasAllTxnsSyncedToAccountingApp() {
    	Boolean transactionSynced = true;
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
        	transactionSynced = !(vrRec.availForQBJournalEntrySync__c && vrRec.AccountingIdForJournalEntry__c == null);
        } else if(integrationName == XeroUtility.XERO) {
        	transactionSynced = !(vrRec.Available_For_Xero_Sync__c && vrRec.Xero_Accounting_Id__c == null);
        }
        return transactionSynced;
    }
	
	private Boolean isAnythingSyncedToAccounting() {
		Boolean transactionSynced = false;
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
            transactionSynced = vrRec.AccountingIdForJournalEntry__c != null;
        } else if(integrationName == XeroUtility.XERO) {
            transactionSynced = vrRec.Xero_Accounting_Id__c != null;
        }
        return transactionSynced;
	}

    private void validateVRToReopen() {
        validationTextToFlagValueMap.put(ReopenUtil.NO_ASSOCIATED_VI, String.isBlank(vrRec.In_Progress_VI__c));

        Boolean isFIFOSoldOrCommitted = false;
        Boolean isSpecialOrderActive = true;
		for(Vendor_Receiving_Group__c vrgRec : [Select Id, Part__c, (Select Id, Received__c, CO_Header__c, Related_SOLI__c, Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c, 
        CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c, CO_Line_Item__r.Invoice_Number__c, CO_Line_Item__r.Qty_Committed__c 
        FROM Vendor_Order_Line_Items__r), 
        (Select Id, Qty_Out__c, Qty_In__c, Part__r.AvailableParts__c FROM Part_FIFO_Buckets__r WHERE Is_FIFO_Bucket__c = true) 
        FROM Vendor_Receiving_Group__c WHERE Vendor_Receiving_Header__c =: vrRec.Id]) {
            Decimal specialOrderCommittedQty = 0;
            for(Vendor_Order_Line_Item__c voli : vrgRec.Vendor_Order_Line_Items__r) {
                if(voli.CO_Header__c != null) {
                    if(vrgRec.Part__c != null) {
                        if(voli.CO_Line_Item__r.Qty_Committed__c < voli.Received__c) {
                            isSpecialOrderActive = false;
                        }
                        specialOrderCommittedQty += (voli.CO_Line_Item__r.Qty_Committed__c <= voli.Received__c) ? 
                                                    voli.CO_Line_Item__r.Qty_Committed__c : voli.Received__c;
                    }
                    if(isSpecialOrderActive) {
                        if(String.isNotBlank(voli.Related_SOLI__c)) {
                            Service_Order_Line_Item__c relatedSOLI = voli.Service_Order_Line_Item__c != null ? voli.Service_Order_Line_Item__r : voli.CO_Line_Item__r.Service_Order_Line_Item__r;
                            if(relatedSOLI.Service_Order_Header__r.SO_Status__c == ServiceJobUtil.INVOICED || ServiceJobUtil.invoiceableStatusSet.contains(relatedSOLI.Service_Order_Header__r.SO_Status__c)) {
                                isSpecialOrderActive = false;
                            }
                        } else if(String.isNotBlank(voli.CO_Line_Item__c)) {
                            CO_Line_Item__c relatedCOLI = voli.CO_Line_Item__r;
                            if(relatedCOLI.Invoice_Number__c != null) {
                                isSpecialOrderActive = false;
                            }
                        }
                    }
                }
            }
            system.debug('specialOrderCommittedQty : ' + specialOrderCommittedQty);
            system.debug('vrgRec.Part_FIFO_Buckets__r : ' + vrgRec.Part_FIFO_Buckets__r);
            for(Part_FIFO_Bucket__c fifoRec : vrgRec.Part_FIFO_Buckets__r) {
                if(fifoRec.Qty_Out__c != 0 || (fifoRec.Qty_In__c - specialOrderCommittedQty) > fifoRec.Part__r.AvailableParts__c) {
                    isFIFOSoldOrCommitted = true;
                    break;
                }
            }
            if(isSpecialOrderActive && isFIFOSoldOrCommitted) {
                break;
            }
		}
        validationTextToFlagValueMap.put(ReopenUtil.PART_NOT_SOLD_COMMITTED, !isFIFOSoldOrCommitted);
        validationTextToFlagValueMap.put(ReopenUtil.SPECIAL_ORDER_STATUS_ACTIVE, isSpecialOrderActive);
    }

    public String reopenVR(String vrId) {
		setVRRec(vrId);
        if(vrRec != null) {
            Savepoint sp;
            try {
                Boolean isAllActngEntriesDeleted = removeAccountingEntries();
                if(isAllActngEntriesDeleted) {
                    sp = Database.setSavepoint();
                    deleteActivityHistory();
                    DMLUtility.deleteSobjectList('Part_FIFO_Bucket__c', vrRec.Part_FIFO_Buckets__r);

                    List<Vendor_Order_Line_Item__c> voliUpdateList = updateSpecialOrderRelatedLines();
                    updateVOLIGsAndVOs(voliUpdateList);
                    VendorOrderLineItemTriggerHelper.setSpecialOrderStatusOnCO(voliUpdateList);
                    updateParts();
                    updateVRRec();
                    updateRefreshToken();
                    return 'success';
                }
            } catch(Exception e) {
                if(sp != null) {
                    Database.rollback(sp);
                }
                reSyncDeletedEntities();
                new LogService().createErrorLog('ReopenVRService', 'reopenVR()', e.getMessage(), null, e.getStackTraceString(), 
                                                    vrId, LogService.REOPEN_INVOICE, true, 'Info');
            }
		}
		return 'error';
    }

    private void setVRRec(String vrId) {
    	String query = 'SELECT Id, In_Progress_VI__c, ' +
        '(Select Id, Qty_Out__c, Qty_In__c, Part__r.AvailableParts__c FROM Part_FIFO_Buckets__r WHERE Is_FIFO_Bucket__c = true), ';
    			
    	if(integrationName == QBUtil.QUICKBOOKS_ONLINE) {
    		query += ' AccountingIdForJournalEntry__c, SyncTokenForJournalEntry__c, ';
					
    	} else if(integrationName == XeroUtility.XERO) {
    		query += ' Xero_Accounting_Id__c, ';
    	}
    	query = query.substring(0, query.length()-2);
    	query += ' FROM Vendor_Receiving_Header__c WHERE Id = \''+vrId + '\' AND Status__c = \'Stocked\'';

		List<Vendor_Receiving_Header__c> vrRecList =  Database.query(query);
        if(vrRecList.size() == 0) throw new BlackpurlException('Invalid Id');
        vrRec = vrRecList[0];
    }

	private void reSyncDeletedEntities() {
		if(String.isNotBlank(integrationName)) {
            updateRefreshToken();
            List<sObject> sObjListToResync = new List<sObject>();
            String objName = (Id.valueOf(vrRec.Id)).getSObjectType().getDescribe().getName();
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objName);
            sObject sObjRec = sObjType.newSObject();
            sObjRec.put('Id', vrRec.Id);
            
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
            VendorReceivingHeaderTriggerHelper.preventOnAccountingSync = false;
            DMLUtility.updateSobjectList('Vendor_Receiving_Header__c', sObjListToResync);
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
		
            if(integrationName == QBUtil.QUICKBOOKS_ONLINE && vrRec.AccountingIdForJournalEntry__c != null) {
                try {
                    QBUtil.deleteEntity(new QBUtil.DeleteEntityWrapper(vrRec.AccountingIdForJournalEntry__c, vrRec.SyncTokenForJournalEntry__c), IntegrationUtility.JOURNAL_ENTRY);
                    syncEntityFieldMap = QBUtil.syncEntityNameToFieldNameToValueMap.get(IntegrationUtility.VENDOR_RECEIVING);
                } catch(Exception e) {
                    if(e.getMessage().equalsIgnoreCase('Read timed out')) {
                        if(!QBUtil.reCheckAccountingEntriesInQB(IntegrationUtility.JOURNAL_ENTRY, vrRec.AccountingIdForJournalEntry__c, integrationRec.integrationConfigRec)) {
                            isAllEntriesDeleted = false;
                        }
                    } else {
                        isAllEntriesDeleted = false;
                    }
                }
            } else if(integrationName == XeroUtility.XERO) {
                if(vrRec.Xero_Accounting_Id__c != null) {
                    try {
                        XeroService.deleteEntity(integrationRec, vrRec.Xero_Accounting_Id__c, IntegrationUtility.JOURNAL_ENTRY);
                        syncEntityFieldMap = XeroUtility.syncEntityNameToFieldNameToValueMap.get(IntegrationUtility.VENDOR_RECEIVING);
                    }  catch(Exception e) {
                        isAllEntriesDeleted = false;
                    }
                }
            }
        }
        return isAllEntriesDeleted;
    }

    private void deleteActivityHistory() {
        DMLUtility.deleteSobjectList('Activity_History__c', [Select Id FROM Activity_History__c WHERE Source_Entity_Id__c =: vrRec.Id AND Action__c = 'Commit Vendor Receiving']);
    }

    private List<Vendor_Order_Line_Item__c> updateSpecialOrderRelatedLines() {
        
        List<Vendor_Order_Line_Item__c> voliUpdateList = new List<Vendor_Order_Line_Item__c>();
        Map<Id,CO_Line_Item__c> coliUpdateMap = new Map<Id,CO_Line_Item__c>();
        Map<Id,Service_Order_Line_Item__c> soliUpdateMap = new Map<Id,Service_Order_Line_Item__c>();

        for(Vendor_Order_Line_Item__c voliRec : [Select Id, Sublet__c, Vendor_Order_Line_Item_Group__c, Vendor_Order_Header__c, Received__c, CO_Header__c, Related_SOLI__c, Service_Order_Line_Item__r.Qty_Committed__c, 
        CO_Line_Item__r.Service_Order_Line_Item__r.Qty_Committed__c, CO_Line_Item__c, CO_Line_Item__r.Invoice_Number__c, CO_Line_Item__r.Qty_Committed__c 
        FROM Vendor_Order_Line_Item__c WHERE Vendor_Receiving_Group__r.Vendor_Receiving_Header__c =: vrRec.Id]) {
            if(voliRec.CO_Header__c != null) {
                if(voliRec.Sublet__c != null) {
                    Service_Order_Line_Item__c relatedSOLI = voliRec.Service_Order_Line_Item__r;
                    relatedSOLI.Qty_Committed__c -= voliRec.Received__c;
                    relatedSOLI.Status__c = 'Ordered';
                    if(!soliUpdateMap.containsKey(relatedSOLI.Id)) {soliUpdateMap.put(relatedSOLI.Id, relatedSOLI);}
                } else if(voliRec.CO_Line_Item__c != null) {
                    CO_Line_Item__c relatedCOLI = voliRec.CO_Line_Item__r;
                    relatedCOLI.Qty_Committed__c -= voliRec.Received__c;
                    relatedCOLI.Status__c = 'Ordered';
                    relatedCOLI.VO_Status__c = 'On Order';
                    if(!coliUpdateMap.containsKey(voliRec.CO_Line_Item__c)) { coliUpdateMap.put(voliRec.CO_Line_Item__c, voliRec.CO_Line_Item__r); }

                    if(voliRec.CO_Line_Item__r.Service_Order_Line_Item__c != null) {
                        Service_Order_Line_Item__c relatedSOLI = voliRec.CO_Line_Item__r.Service_Order_Line_Item__r;
                        relatedSOLI.Qty_Committed__c -= voliRec.Received__c;
                        if(!soliUpdateMap.containsKey(relatedSOLI.Id)) { soliUpdateMap.put(relatedSOLI.Id, relatedSOLI); }
                    }
                }
            }
            voliRec.Status__c = null;
            voliRec.Is_Received__c = false;
            voliUpdateList.add(voliRec);
        }
        DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voliUpdateList);
        DMLUtility.updateSobjectList('CO_Line_Item__c', coliUpdateMap.values());
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliUpdateMap.values());
        return voliUpdateList;
    }

    private void updateVOLIGsAndVOs(List<Vendor_Order_Line_Item__c> volis) {
        Set<Id> voligIdSet = new Set<Id>();
        Set<Id> voIdSet = new Set<Id>();
        for(Vendor_Order_Line_Item__c voli : volis) {
            if(voli.Vendor_Order_Line_Item_Group__c != null) voligIdSet.add(voli.Vendor_Order_Line_Item_Group__c);
            if(voli.Vendor_Order_Header__c != null) voIdSet.add(voli.Vendor_Order_Header__c);
        }
        if(!voIdSet.isEmpty()) {
            List<Vendor_Order_Line_Item_Group__c> voligUpdateList = [Select Id, Need__c, Status__c, (Select Id, Received__c FROM Vendor_Order_Line_Items__r WHERE Is_Received__c = true AND Received__c != null) FROM Vendor_Order_Line_Item_Group__c WHERE Id IN: voligIdSet];
            for(Vendor_Order_Line_Item_Group__c volig : voligUpdateList) {
                volig.Received_Qty__c = 0;
                for(Vendor_Order_Line_Item__c voli : volig.Vendor_Order_Line_Items__r) {
                    volig.Received_Qty__c += voli.Received__c;
                }
            }
            VendorOrderLineItemGroupTriggerHelper.isByPassVOLIUpdate = true;
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item_Group__c', voligUpdateList);

            List<Vendor_Order_Header__c> voList = [Select Id, (Select Id, Need__c, Status__c, Received_Qty__c FROM Vendor_Order_Line_Item_Groups__r) FROM Vendor_Order_Header__c WHERE Id IN: voIdSet];
            for(Vendor_Order_Header__c voRec : voList) {
                Set<String> voliGroupStatusSet = new Set<String>();
                for(Vendor_Order_Line_Item_Group__c volig : voRec.Vendor_Order_Line_Item_Groups__r) {
                    if(volig.Received_Qty__c == volig.Need__c) {
                        voliGroupStatusSet.add('Received');
                    } else if(volig.Received_Qty__c > 0 && volig.Status__c != 'Cancelled') {
                        voliGroupStatusSet.add('Partially Received');
                    } else if(volig.Received_Qty__c == 0 && volig.Status__c != 'Cancelled') {
                        voliGroupStatusSet.add('On Order');
                    }
                }
                if(!voliGroupStatusSet.isEmpty()) {
                    voRec.Status__c = (voliGroupStatusSet.size() == 1) ? new List<String>(voliGroupStatusSet)[0] : 'Partially Received';
                }
            }
            DMLUtility.updateSobjectList('Vendor_Order_Header__c', voList);
        }
    }

    private void updateParts() {
        Set<Id> partIdSet = new Set<Id>();
        for(Vendor_Receiving_Group__c vrg : vrRec.Vendor_Receiving_Groups__r) {
            if(vrg.Part__c != null) partIdSet.add(vrg.Part__c);
        }
        if(!partIdSet.isEmpty()) {
            List<Part__c> partList = [Select Id, Oversold_Qty__c, Oversold_Cost__c, Total_Cost__c, Average_Cost__c,
            (Select Id, Qty_Needed__c FROM Vendor_Order_Line_Items__r WHERE Is_Received__c = false AND Vendor_Order_Header__c != null AND Needed_For__c = 'STOCK' AND Qty_Needed__c != null),
            (Select Id, CreatedDate, Vendor_Receiving_Group__c, Qty_In__c, Qty_Out__c, Total__c, Source_Name__c, Remaining_Qty__c from Part_FIFO_Buckets__r Where Is_FIFO_Bucket__c = true Order By CreatedDate ASC) from Part__c where Id In :partIdSet];
            
            for(Part__c partRec : partList) {
                Decimal oversoldQty = 0;
                Decimal oversoldCost = 0;
                Decimal totalCost = 0;
                Decimal qtyOnOrder = 0;
                Decimal qtyInStock = 0;
                for(Part_FIFO_Bucket__c partFIFOBucketRec : partRec.Part_FIFO_Buckets__r) {
                    if(!String.isBlank(partFIFOBucketRec.Source_Name__c) && (partFIFOBucketRec.Source_Name__c.equalsIgnoreCase('Oversold') || partFIFOBucketRec.Remaining_Qty__c < 0)){
                        oversoldQty += ((partFIFOBucketRec.Qty_In__c != null) ? partFIFOBucketRec.Qty_In__c : 0.00) - ((partFIFOBucketRec.Qty_Out__c != null) ? partFIFOBucketRec.Qty_Out__c : 0.00);
                        oversoldCost += (partFIFOBucketRec.Total__c != null) ? partFIFOBucketRec.Total__c : 0.00;
                    } else {
                        totalCost  += (partFIFOBucketRec.Total__c != null ) ? partFIFOBucketRec.Total__c : 0.00;
                        qtyInStock += (partFIFOBucketRec.Remaining_Qty__c != null ) ? partFIFOBucketRec.Remaining_Qty__c : 0;
                    }
                    if(partFIFOBucketRec.Vendor_Receiving_Group__c != null) partRec.Last_Stocked__c = partFIFOBucketRec.CreatedDate;
                }
                for(Vendor_Order_Line_Item__c voliRec : partRec.Vendor_Order_Line_Items__r) {
                    qtyOnOrder += voliRec.Qty_Needed__c;
                }
                partRec.Qty_On_Order__c = qtyOnOrder;
                partRec.Qty_In_Stock__c = qtyInStock;
                partRec.Last_Counted__c = system.Now();
                partRec.Total_Cost__c = totalCost;
                partRec.Oversold_Qty__c = oversoldQty < 0 ? -(oversoldQty) : oversoldQty;
                partRec.Oversold_Cost__c = oversoldCost < 0 ? -(oversoldCost) : oversoldCost;
                partRec.Average_Cost__c = (qtyInStock > 0) ? (TotalCost / qtyInStock) : 0.00;
            }
            DMLUtility.updateSobjectList('Part__c', partList);
        }
    }
    
    private void updateVRRec() {
        vrRec.Available_For_Xero_Sync__c = vrRec.availForQBJournalEntrySync__c = false;
        vrRec.Xero_Accounting_Id__c = vrRec.AccountingIdForJournalEntry__c = null;
        vrRec.SyncTokenForJournalEntry__c = null;
        vrRec.accountingLastSyncTime__c = null;
        vrRec.AccountingResponseForJournalEntry__c = null;
        vrRec.Status__c = 'In Progress';
        vrRec.Finalized_Date__c = null;
        vrRec.Finalized_VR_Conversion_Rate__c = null;
        DMLUtility.updateSobjectList('Vendor_Receiving_Header__c', vrRec);
    }
}