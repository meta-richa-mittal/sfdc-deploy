public without sharing class UnitPriceAndCostService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncUnitPriceAndCosts(Set<Id> unitPriceAndCostIds){
        AccSync_UnitPriceAndCost_Batch.runUnitPriceAndCostForSync(unitPriceAndCostIds, 10);
    }
    
    public static QBUtil.BatchResultWrapper syncAccountingServer(AccountingUnitPriceAndCost unitPriceAndCostRecord, List<Unit_Price_Cost__c> unitPriceAndCostListToUpdate){
    	List<Log__c> errorLogToInsert = new List<Log__c>();
    	if(QBUtil.isQBEnabled()) {
	        errorLogToInsert = syncToQuickBooks(unitPriceAndCostRecord, unitPriceAndCostListToUpdate);
    	}
    	return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    public static List<Log__c> syncToQuickBooks(AccountingUnitPriceAndCost PriceAndCostRecord, List<Unit_Price_Cost__c> unitPriceAndCostListToUpdate){
        Unit_Price_Cost__c unitPriceAndCost = new Unit_Price_Cost__c();
        unitPriceAndCost.Id = PriceAndCostRecord.Id;
        String syncObjectName = 'journalentry';
        if(String.isNotBlank(PriceAndCostRecord.VendorId)) {
        	if(PriceAndCostRecord.TotalCost > 0) {
        		syncObjectName = 'bill';
        	} else {
        		syncObjectName = 'vendorcredit';
        	}
        }
        
        if(String.isNotBlank(PriceAndCostRecord.CustomerId)) {
        	if(PriceAndCostRecord.TotalCost > 0) {
        		syncObjectName = QBUtil.CREDIT_MEMO;
        	} else {
        		syncObjectName = QBUtil.INVOICE;
        	}
        }

        List<Log__c> errorLogList = new List<Log__c>();
        try{
            if(PriceAndCostRecord.JournalEntrySyncToken != null) {
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks(syncObjectName, PriceAndCostRecord.JournalEntryAccountingId);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB(syncObjectName, PriceAndCostRecord.JournalEntryAccountingId);
				HttpResponse getResponse = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200){ 
                    if(syncObjectName == 'journalentry') {
                		QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry JournalEntryGetResponce = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(getResponse.getBody(), QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    	PriceAndCostRecord.JournalEntrySyncToken = JournalEntryGetResponce.JournalEntry.SyncToken;
                	} else {
                		QBResponseWrapper result = (QBResponseWrapper)System.JSON.deserialize(getResponse.getBody(), QBResponseWrapper.class);
                		if(syncObjectName == 'bill') {
	                    	PriceAndCostRecord.JournalEntrySyncToken = result.Bill.SyncToken;
	                	} else if(syncObjectName == 'vendorcredit') {
	                		PriceAndCostRecord.JournalEntrySyncToken = result.VendorCredit.SyncToken;
	                	} else if(syncObjectName ==  QBUtil.CREDIT_MEMO) {
	                		PriceAndCostRecord.JournalEntrySyncToken = result.CreditMemo.SyncToken;
	                	} else if(syncObjectName ==  QBUtil.INVOICE) {
	                		PriceAndCostRecord.JournalEntrySyncToken = result.invoice.SyncToken;
	                	}
                	}
                } else {
                	errorLogList.add(new LogService().createErrorLog('UnitPriceAndCostService', 'syncToQuickBooks() - Get sync token Request From QuickBooks Online', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              PriceAndCostRecord + LogService.METHOD_PARAM_SEPERATOR + unitPriceAndCostListToUpdate, LogService.QUICKBOOKS, false));
                }
            }
            
            String unitPriceAndCostJSONBody;
            if(syncObjectName == 'journalentry') {
            QBJournalEntryServiceHelper.QuickBooksJournalEntry QBJournalEntry = new QBJournalEntryServiceHelper.QuickBooksJournalEntry(PriceAndCostRecord);
            	unitPriceAndCostJSONBody = System.JSON.serialize(QBJournalEntry);
            } else if(syncObjectName == 'vendorcredit') {
            	QBVendorPurchaseDTO billDTOObj = new QBVendorPurchaseDTO(PriceAndCostRecord);
            	unitPriceAndCostJSONBody = System.JSON.serialize(billDTOObj);
            } else if(syncObjectName == 'bill') {
                QBVendorBillDTO QB_VI = new QBVendorBillDTO(PriceAndCostRecord);
                QB_VI.DueDate = QBInvoiceDueDateService.getVendorInvoiceDueDate(PriceAndCostRecord.AdjustmentDate,PriceAndCostRecord.VendorAccountingId);
                unitPriceAndCostJSONBody = System.JSON.serialize(QB_VI);
            } else if(syncObjectName == QBUtil.CREDIT_MEMO) {
                QBCreditMemoDTO creditMemoDTOObj = new QBCreditMemoDTO(PriceAndCostRecord);
            	unitPriceAndCostJSONBody = System.JSON.serialize(creditMemoDTOObj);
            } else if(syncObjectName == QBUtil.INVOICE) {
                QBInvoiceDTO invoiceDTOObj = new QBInvoiceDTO(PriceAndCostRecord);
            	unitPriceAndCostJSONBody = System.JSON.serialize(invoiceDTOObj);
            }     
            
            System.debug('*************');
            System.debug(unitPriceAndCostJSONBody);
            String response= unitPriceAndCostJSONBody;
            //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks(syncObjectName, unitPriceAndCostJSONBody);
            QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB(syncObjectName, unitPriceAndCostJSONBody);
			HttpResponse res = responseObj.Response;
			refreshToken = responseObj.RefreshToken;
			refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
            System.debug(res);
            if(res.getStatusCode() == 200){ 
                String resParams = res.getBody();
                if(syncObjectName == 'journalentry') {
                QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry JournalEntryPostResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(resParams, QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                unitPriceAndCost.AccountingId__c = JournalEntryPostResponse.JournalEntry.Id;
                unitPriceAndCost.SyncToken__c = JournalEntryPostResponse.JournalEntry.SyncToken;
                } else {
                	QBResponseWrapper result = (QBResponseWrapper)System.JSON.deserialize(resParams, QBResponseWrapper.class);
            		if(syncObjectName == 'bill') {
            			unitPriceAndCost.AccountingId__c = result.Bill.Id;
                		unitPriceAndCost.SyncToken__c = result.Bill.SyncToken;
                	} else if(syncObjectName == 'vendorcredit') {
                		unitPriceAndCost.AccountingId__c = result.vendorcredit.Id;
                		unitPriceAndCost.SyncToken__c = result.vendorcredit.SyncToken;
                	} else if(syncObjectName == QBUtil.CREDIT_MEMO) {
                        unitPriceAndCost.AccountingId__c = result.CreditMemo.Id;
                		unitPriceAndCost.SyncToken__c = result.CreditMemo.SyncToken;
                    } else if(syncObjectName == QBUtil.INVOICE) {
                        unitPriceAndCost.AccountingId__c = result.invoice.Id;
                		unitPriceAndCost.SyncToken__c = result.invoice.SyncToken;
                    }                
                }
                response+= '\n\n'+resParams; 
                unitPriceAndCost.availForQBSync__c = false;
                unitPriceAndCost.accountingLastSyncTime__c = System.now(); 
            }else{
                response+= '\n\n'+res.getBody();
                response+= '\n\n'+res.getStatus();
                errorLogList.add(new LogService().createErrorLog('UnitPriceAndCostService', 'syncToQuickBooks() -  post request to save', res.getBody(), res.getStatusCode(), null, 
                                              PriceAndCostRecord + LogService.METHOD_PARAM_SEPERATOR + unitPriceAndCostListToUpdate, LogService.QUICKBOOKS, false));
            }
            unitPriceAndCost.AccountingResponse__c  = QBUtil.truncateString(response, 32768);
        }catch(Exception e){
            unitPriceAndCost.availForQBSync__c = true;
            unitPriceAndCost.AccountingResponse__c += e.getMessage();
            errorLogList.add(new LogService().createErrorLog('UnitPriceAndCostService', 'syncToQuickBooks() - exception', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
        	                                  PriceAndCostRecord + LogService.METHOD_PARAM_SEPERATOR + unitPriceAndCostListToUpdate, LogService.QUICKBOOKS, false));
        }
        if(unitPriceAndCostListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT){
            AccSync_UnitPriceAndCost_Batch.updateUnitPriceAndCosts(unitPriceAndCostListToUpdate);
            unitPriceAndCostListToUpdate = new List<Unit_Price_Cost__c>();
        }
        unitPriceAndCostListToUpdate.add(unitPriceAndCost);
     	return errorLogList;
    }
}