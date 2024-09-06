/*
    Apex class to sync Payment on Account with accounting server
*/
global without sharing class AccSync_PaymentOnAccount_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    public String strQuery;
    public Set<Id> paymentOnAccountIdSet;
    public static boolean preventOnAccountingSync = false;
    global List<Payment_on_Account__c> paymentOnAccountListToUpdate; 
    global List<Log__c> errorLogToInsert;   
    
    public static void runPaymentOnAccountForSync(Set<Id> paymentOnAccountIdSetVal , Integer batchSize) {
        AccSync_PaymentOnAccount_Batch accSyncClsBatch = new AccSync_PaymentOnAccount_Batch();
        accSyncClsBatch.paymentOnAccountIdSet = paymentOnAccountIdSetVal;
        accSyncClsBatch.strQuery = getBaseQuery();
        accSyncClsBatch.strQuery += ' AND Id IN :paymentOnAccountIdSet';
        Id batchstart = Database.executeBatch(accSyncClsBatch, batchSize);
    }
        
    public static String getBaseQuery() {
        String baseQuery = 'SELECT '; 
        for(String fieldName : AccountingPaymentOnAccount.fieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
        baseQuery = baseQuery.substring(0, baseQuery.length()-2);
        baseQuery += ' FROM Payment_on_Account__c ';
        baseQuery += 'WHERE Available_For_QB_Sync__c = true';
        return baseQuery;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        paymentOnAccountListToUpdate = new List<Payment_on_Account__c>();
        errorLogToInsert = new List<Log__c>();
        if(String.isBlank(strQuery)){
            strQuery = getBaseQuery();
            if(paymentOnAccountIdSet != null && paymentOnAccountIdSet.size() > 0) {
                strQuery += ' AND Id IN :paymentOnAccountIdSet';
            }
        }
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Payment_on_Account__c> paymentOnAccountList) {
        List<AccountingPaymentOnAccount> accountingPaymentOnAccountList = new List<AccountingPaymentOnAccount>();
        for(Payment_on_Account__c paymentOnAccountRec : paymentOnAccountList) {
        	QBUtil.BatchResultWrapper batchResultObj = QBPaymentOnAccountService.syncAccountingServer(new AccountingPaymentOnAccount(paymentOnAccountRec), paymentOnAccountListToUpdate);
			errorLogToInsert.addAll(batchResultObj.ErrorLogToInsert);
			if(batchResultObj.RefreshToken !=  null) {
				QBUtil.saveRefreshToken(batchResultObj.RefreshToken, batchResultObj.RefreshTokenExpiresIn);
			}
        }
    }  
 
    global void finish(Database.batchableContext bc) {
        updatePaymentOnAccount(paymentOnAccountListToUpdate);
        if(errorLogToInsert.size() > 0) {
          insert errorLogToInsert;
        }
    }
    
    public static void updatePaymentOnAccount(List<Payment_on_Account__c> paymentOnAccountListToUpdate) {
        if(paymentOnAccountListToUpdate != null && paymentOnAccountListToUpdate.size() > 0) { 
            preventOnAccountingSync = true;
            PaymentOnAccountTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Payment_on_Account__c', paymentOnAccountListToUpdate);
            PaymentOnAccountTriggerHelper.isForceStopTrigger = true;
        }
    }
}