/*
    Apex class to sync customer with accounting server
*/
global without sharing class AccSync_FIFOBucketActivityLineItem_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
	
	public String strQuery;
    public Set<Id> setPartFIFOBucketActivityLineItemIds;
    public static boolean preventOnAccountingSync = false;
    global List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOBucketActivityLineItemListToUpdate; 
	public List<Account> accountListToUpdateToSyncFIFOBucketActivityLIs; 
	public Set<Id> alreadyRequestedAccountIdSet;
    global List<Log__c> errorLogToInsert;
    
	
    public static void runPartFIFOBucketActivityLineItemForSync(Set<Id> setPartFIFOBucketActivityLineItemIdVal, Integer batchSize) {
        runPartFIFOBucketActivityLineItemForSync(setPartFIFOBucketActivityLineItemIdVal, new Set<Id>(), batchSize);
	}
    
    public static void runPartFIFOBucketActivityLineItemForSync(Set<Id> setPartFIFOBucketActivityLineItemIdVal, Set<Id> alreadyRequestedAccountIdSet, Integer batchSize) {
        AccSync_FIFOBucketActivityLineItem_Batch clsAccSyncBatch = new AccSync_FIFOBucketActivityLineItem_Batch();
        clsAccSyncBatch.setPartFIFOBucketActivityLineItemIds = setPartFIFOBucketActivityLineItemIdVal;
        clsAccSyncBatch.alreadyRequestedAccountIdSet = alreadyRequestedAccountIdSet;
        clsAccSyncBatch.strQuery = getBaseQuery();
        clsAccSyncBatch.strQuery += ' AND Id IN :setPartFIFOBucketActivityLineItemIds';
        Id batchstart = Database.executeBatch(clsAccSyncBatch, batchSize);
	}
    	
	public static String getBaseQuery() {
        String baseQuery = 'SELECT '; 
        for(String fieldName : AccountingFIFOBucketActivityLineItem.fieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
        baseQuery = baseQuery.substring(0, baseQuery.length()-2);
        baseQuery += ' FROM Part_FIFO_Bucket_Activity_Line_Item__c ';
        baseQuery += 'WHERE availForQBSync__c = true';
        return baseQuery;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc){
    	partFIFOBucketActivityLineItemListToUpdate = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
        errorLogToInsert = new List<Log__c>();
        if(String.isBlank(strQuery)){
	    	strQuery = getBaseQuery();
	    	if(setPartFIFOBucketActivityLineItemIds != null && setPartFIFOBucketActivityLineItemIds.size() > 0) {
                strQuery += ' AND Id IN :setPartFIFOBucketActivityLineItemIds';
            }
    	}
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<Part_FIFO_Bucket_Activity_Line_Item__c> listPartFIFOBucketActivityLineItems) {
        List<AccountingFIFOBucketActivityLineItem> accountingPartFIFOBucketActivityLineItemList = new List<AccountingFIFOBucketActivityLineItem>();
        accountListToUpdateToSyncFIFOBucketActivityLIs = new List<Account>();
        for(Part_FIFO_Bucket_Activity_Line_Item__c partFIFOBucketActivityLineItem : listPartFIFOBucketActivityLineItems) {
           if(!Test.isRunningTest() && partFIFOBucketActivityLineItem.Part_FIFO_Bucket__r.Part__r.Vendor__c != null
           	&& partFIFOBucketActivityLineItem.Part_FIFO_Bucket__r.Part__r.Vendor__r.Vendor_AccountingId__c == null
           	&& !alreadyRequestedAccountIdSet.contains(partFIFOBucketActivityLineItem.Part_FIFO_Bucket__r.Part__r.Vendor__c)) {
           		Id vendorId = partFIFOBucketActivityLineItem.Part_FIFO_Bucket__r.Part__r.Vendor__c;
    			List<Account> accountListToUpdate = AccSync_Vendor_Batch.getAccountListToUpdateById(new Set<Id>{vendorId});
		    	for(Account account: accountListToUpdate) {
		    		accountListToUpdateToSyncFIFOBucketActivityLIs.add(account);
		    		alreadyRequestedAccountIdSet.add(account.Id);
		    	}	
    		} else {
    			QBUtil.BatchResultWrapper batchResultObj = FIFOBucketActivityLineItemService.syncAccountingServer(new AccountingFIFOBucketActivityLineItem(partFIFOBucketActivityLineItem), partFIFOBucketActivityLineItemListToUpdate);
				errorLogToInsert.addAll(batchResultObj.ErrorLogToInsert);
				if(batchResultObj.RefreshToken !=  null) {
					QBUtil.saveRefreshToken(batchResultObj.RefreshToken, batchResultObj.RefreshTokenExpiresIn);
				}
            }
        }
    }  
 
    global void finish(Database.batchableContext bc) {
        try{
            BPUtility.updateRecordList(partFIFOBucketActivityLineItemListToUpdate, 0);
            preventOnAccountingSync = true;
        } catch(Exception e) {
            setErrorLogFields(e);
        }
        if(accountListToUpdateToSyncFIFOBucketActivityLIs != null && accountListToUpdateToSyncFIFOBucketActivityLIs.size() > 0) {
    		AccSync_Vendor_Batch.updateVendors(accountListToUpdateToSyncFIFOBucketActivityLIs);
    		accountListToUpdateToSyncFIFOBucketActivityLIs = null;
    		runPartFIFOBucketActivityLineItemForSync(setPartFIFOBucketActivityLineItemIds, alreadyRequestedAccountIdSet, 10);
    	}
        if(errorLogToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Log__c', errorLogToInsert);
        }
    }
    
    public void setErrorLogFields(Exception e) {
        Set<Id> partFIFOBucketActivityLineItemIdSet = new Set<Id>();
        for(Part_FIFO_Bucket_Activity_Line_Item__c partFIFOBucketActivityLineItemRec : partFIFOBucketActivityLineItemListToUpdate) {
            partFIFOBucketActivityLineItemIdSet.add(partFIFOBucketActivityLineItemRec.Id);
    	}

        errorLogToInsert.add(new LogService().createErrorLog('AccSync_COInvoicePayment_Batch', 'finish()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
        partFIFOBucketActivityLineItemIdSet + LogService.METHOD_PARAM_SEPERATOR, LogService.QUICKBOOKS, false));
    }
}