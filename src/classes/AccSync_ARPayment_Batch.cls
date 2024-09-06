/*
    Apex class to sync Payment on Account with accounting server
*/
global without sharing class AccSync_ARPayment_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    public String strQuery;
    public Set<Id> poaIdSetForARPayment;
    public static boolean preventOnAccountingSync = false;
    global List<Payment_on_Account__c> paymentOnAccountListToUpdate; 
    global List<Log__c> errorLogToInsert;   
    
    public static void runARPaymentForSync(Set<Id> poaIdSetValForARPayment , Integer batchSize) {
        AccSync_ARPayment_Batch accSyncClsBatch = new AccSync_ARPayment_Batch();
        accSyncClsBatch.poaIdSetForARPayment = poaIdSetValForARPayment;
        accSyncClsBatch.strQuery = getBaseQuery();
        accSyncClsBatch.strQuery += ' AND Id IN :poaIdSetForARPayment';
        Id batchstart = Database.executeBatch(accSyncClsBatch, batchSize);
    }
        
    public static String getBaseQuery() {
        String baseQuery = 'SELECT '; 
        for(String fieldName : AccountingPaymentOnAccount.fieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
        
		// Child Query: fields of AR Payment
        baseQuery += '( SELECT ';
        for(String fieldName : AccountingARPayment.fieldsList()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
        baseQuery = baseQuery.substring(0, baseQuery.length()-2);
        baseQuery += ' FROM AR_Payments__r ) ';
        
        baseQuery += ' FROM Payment_on_Account__c ';
        baseQuery += 'WHERE Available_For_QB_AR_Payment_Sync__c = true';
        return baseQuery;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        paymentOnAccountListToUpdate = new List<Payment_on_Account__c>();
        errorLogToInsert = new List<Log__c>();
        if(String.isBlank(strQuery)){
            strQuery = getBaseQuery();
            if(poaIdSetForARPayment != null && poaIdSetForARPayment.size() > 0) {
                strQuery += ' AND Id IN :poaIdSetForARPayment';
            }
        }
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Payment_on_Account__c> paymentOnAccountList) {
        List<AccountingPaymentOnAccount> accountingPaymentOnAccountList = new List<AccountingPaymentOnAccount>();
        for(Payment_on_Account__c paymentOnAccountRec : paymentOnAccountList) {
        	QBUtil.BatchResultWrapper batchResultObj = QBARPaymentService.syncAccountingServer(new AccountingPaymentOnAccount(paymentOnAccountRec), paymentOnAccountListToUpdate);
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