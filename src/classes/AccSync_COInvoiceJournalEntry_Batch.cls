global without sharing class AccSync_COInvoiceJournalEntry_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    
    public String strQuery;
    public Set<Id> setcustomerInvoiceIds;
    public static boolean preventOnAccountingSync = false;
    global List<CO_Invoice_Header__c> customerInvoiceListToUpdate; 
    global List<Log__c> errorLogToInsert;
    
    public static void runCustomerInvoicesForSync(Set<Id> setCustomerInvoiceIdVal, Integer batchSize){
        AccSync_COInvoiceJournalEntry_Batch clsAccSyncBatch = new AccSync_COInvoiceJournalEntry_Batch();
        clsAccSyncBatch.setcustomerInvoiceIds = setCustomerInvoiceIdVal;
        clsAccSyncBatch.strQuery = getBaseQuery();
        clsAccSyncBatch.strQuery += ' AND Id IN :setcustomerInvoiceIds';
        Id batchstart = Database.executeBatch(clsAccSyncBatch, batchSize);
    }
        
    public static String getBaseQuery(){
        String baseQuery = 'SELECT '; 
        //fields of CO Invoice header 
        for(String fieldName : AccountingCustomerInvoice.objectToFieldMap.get('COInvoiceHeader')){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
            
        // Child Query: fields of CO Invoice Item 
        baseQuery = baseQuery.substring(0, baseQuery.length()-2);
        baseQuery += ' FROM CO_Invoice_Header__c ';
        baseQuery += 'WHERE availForQBJournalEntrySync__c = true AND Invoice_Status__c = \'Closed\''; //AccountingId__c != null AND
        return baseQuery;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        customerInvoiceListToUpdate = new List<CO_Invoice_Header__c>();
        errorLogToInsert = new List<Log__c>();
        if(String.isBlank(strQuery)){
            strQuery = getBaseQuery();
        }
        if(setcustomerInvoiceIds != null && setcustomerInvoiceIds.size() > 0) {
            strQuery += ' AND Id IN :setcustomerInvoiceIds';
        }
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<CO_Invoice_Header__c> listCustomerInvoices) {
        Set<Id> coInvoiceIdSet = new Set<Id>();
        for(CO_Invoice_Header__c invoiceRec : listCustomerInvoices) {
        	coInvoiceIdSet.add(invoiceRec.Id);
        }
        Map<String, List<CO_Invoice_Item__c>> invoiceIdToInvoiceItemListMap = AccountingUtil.getInvoiceIdToInvoiceItemListMap(coInvoiceIdSet);
        List<AccountingCustomerInvoice> accountingCustomerInvoiceList = new List<AccountingCustomerInvoice>();
        for(CO_Invoice_Header__c customerInvoice : listCustomerInvoices) {
        	QBUtil.BatchResultWrapper batchResultObj = COInvoiceJournalEntryService.syncAccountingServer(new AccountingCustomerInvoice(customerInvoice, invoiceIdToInvoiceItemListMap.get(customerInvoice.Id)), customerInvoiceListToUpdate);
			errorLogToInsert.addAll(batchResultObj.ErrorLogToInsert);
			if(batchResultObj.RefreshToken !=  null) {
				QBUtil.saveRefreshToken(batchResultObj.RefreshToken, batchResultObj.RefreshTokenExpiresIn);
			}
        }
    }  
 
    global void finish(Database.batchableContext bc){
        updateCustomerInvoices(customerInvoiceListToUpdate);
         if(errorLogToInsert.size() > 0) {
          insert errorLogToInsert;
         }
    }
    
    public static void updateCustomerInvoices(List<CO_Invoice_Header__c> customerInvoiceListToUpdate){
        preventOnAccountingSync = true;
        DMLUtility.updateSobjectListWithRetry(customerInvoiceListToUpdate);
    }
}