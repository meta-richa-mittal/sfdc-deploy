/*
    Apex class to sync customer with accounting server
*/
global without sharing class AccSync_COInvoicePayment_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {

    public String strQuery;
    public Set<Id> setCOInvoicePaymentIds;
    global List<CO_Invoice_Payment__c> COInvoicePaymentListToUpdate;  
    public List<Account> accountListToUpdateToSyncCOInvoicePayment; 
    public Set<Id> alreadyRequestedAccountIdSet = new Set<Id>();
    global List<Log__c> errorLogToInsert;
    
    public static void runCOInvoicePaymentsForSync(Set<Id> setCOInvoicePaymentIdVal, Integer batchSize) {
        runCOInvoicePaymentsForSync(setCOInvoicePaymentIdVal, new Set<Id>(), batchSize);
    }
    
    public static void runCOInvoicePaymentsForSync(Set<Id> setCOInvoicePaymentIdVal, Set<Id> alreadyRequestedAccountIdSet, Integer batchSize ) {
        String strQuery;
        AccSync_COInvoicePayment_Batch clsAccSyncBatch = new AccSync_COInvoicePayment_Batch();
        clsAccSyncBatch.setCOInvoicePaymentIds = setCOInvoicePaymentIdVal;
        clsAccSyncBatch.alreadyRequestedAccountIdSet = alreadyRequestedAccountIdSet;
        clsAccSyncBatch.strQuery = getBaseQuery();
        clsAccSyncBatch.strQuery += ' AND Id IN :setCOInvoicePaymentIds';
        Id batchstart = Database.executeBatch(clsAccSyncBatch, batchSize);
    }
    
    public static String getBaseQuery(){
        String baseQuery = 'SELECT '; 
        for(String fieldName : AccountingCOInvoicePayment.fieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
        baseQuery = baseQuery.substring(0, baseQuery.length()-2);
        baseQuery += ' FROM CO_Invoice_Payment__c ';
        baseQuery += 'WHERE availForQBJournalEntrySync__c = true'; //  AND Payment_Method__c != \'Charge Account\' //WHERE CO_Invoice_Header__r.AccountingId__c != null AND availForQBSync__c = true AND Reverse_Link__c = null AND Amount__c >= 0
        return baseQuery;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
    	COInvoicePaymentListToUpdate = new List<CO_Invoice_Payment__c>();
        accountListToUpdateToSyncCOInvoicePayment = new List<Account>();
        errorLogToInsert = new List<Log__c>();
    	if(String.isBlank(strQuery)) {
	    	strQuery = getBaseQuery();
	    	if(setCOInvoicePaymentIds != null && setCOInvoicePaymentIds.size() > 0) {
                strQuery += ' AND Id IN :setCOInvoicePaymentIds';
            }
    	}
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<CO_Invoice_Payment__c> listCOInvoicePayments) {
        for(CO_Invoice_Payment__c COInvoicePayment : listCOInvoicePayments) {
            if(COInvoicePayment.Customer_Name__c != null && COInvoicePayment.Customer_Name__r.AccountingId__c == null 
        		&& !alreadyRequestedAccountIdSet.contains(COInvoicePayment.Customer_Name__c)) {
		    	List<Account> accountListToUpdate = AccSync_Customer_Batch.getAccountListToUpdateById(new Set<Id>{COInvoicePayment.Customer_Name__c});
		    	for(Account account: accountListToUpdate){
		    		accountListToUpdateToSyncCOInvoicePayment.add(account);
		    		alreadyRequestedAccountIdSet.add(account.Id);
		    	}
                if(!COInvoicePayment.Customer_Name__r.availForQBSync__c) {
                    COInvoicePayment.AccountingResponseForJournalEntry__c = AccountingUtil.CUSTOMER_NOT_SYNC_MSG;
                    COInvoicePaymentListToUpdate.add(COInvoicePayment);
                    errorLogToInsert.add(new LogService().createErrorLog('AccSync_COInvoicePayment_Batch', 'execute()', AccountingUtil.CUSTOMER_NOT_SYNC_MSG, LogService.NOT_APPLICABLE, null, 
                                                COInvoicePayment + LogService.METHOD_PARAM_SEPERATOR, LogService.QUICKBOOKS, false));
                }
            } else {
            	QBUtil.BatchResultWrapper batchResultObj = COInvoicePaymentJournalEntryService.syncAccountingServer(new AccountingCOInvoicePayment(COInvoicePayment), COInvoicePaymentListToUpdate);
				errorLogToInsert.addAll(batchResultObj.ErrorLogToInsert);
				QuickBookQueryService.refreshToken = batchResultObj.RefreshToken;
				QuickBookQueryService.refreshTokenExpiresIn = batchResultObj.RefreshTokenExpiresIn;
            }
        }
        if(QuickBookQueryService.refreshToken !=  null) {
			QBUtil.saveRefreshToken(QuickBookQueryService.refreshToken, QuickBookQueryService.refreshTokenExpiresIn);
		}
    } 
 
    global void finish(Database.batchableContext bc) {
    	try {
            BPUtility.updateRecordList(COInvoicePaymentListToUpdate, 0);
    	} catch(Exception e) {
    	        setErrorLogFields(e);
    	    }
    	
    	if(accountListToUpdateToSyncCOInvoicePayment.size() > 0) {
    		AccSync_Customer_Batch.updateCustomers(accountListToUpdateToSyncCOInvoicePayment);
    		accountListToUpdateToSyncCOInvoicePayment = new List<Account>();
    		runCOInvoicePaymentsForSync(setCOInvoicePaymentIds, alreadyRequestedAccountIdSet, 10);
    	}
        if(errorLogToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Log__c', errorLogToInsert);
    	}
    }
    
    public void setErrorLogFields(Exception e) {
        Set<Id> coInvoicePaymentIdSet = new Set<Id>();
        for(CO_Invoice_Payment__c COInvoicePaymentRec : COInvoicePaymentListToUpdate) {
            coInvoicePaymentIdSet.add(COInvoicePaymentRec.Id);
        }

        errorLogToInsert.add(new LogService().createErrorLog('AccSync_COInvoicePayment_Batch', 'finish()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                          coInvoicePaymentIdSet + LogService.METHOD_PARAM_SEPERATOR, LogService.QUICKBOOKS, false));
    }
}