global without sharing class AccSync_UnitConsignment_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    
    public String strQuery;
    public Set<Id> setConsUnitIds;
    global List<Customer_Owned_Unit__c> consUnitListToUpdate;
    public List<Account> accountListToUpdateToSyncConsUnit;
    public Set<Id> alreadyRequestedAccountIdSet;
    global List<Log__c> errorLogToInsert;
    
    public static void runConsignmentsForSync(Set<Id> setConsUnitIdVal, Set<Id> alreadyRequestedAccountIdSet, Integer batchSize) {
        AccSync_UnitConsignment_Batch clsAccSyncBatch = new AccSync_UnitConsignment_Batch();
        clsAccSyncBatch.setConsUnitIds = setConsUnitIdVal;
        clsAccSyncBatch.alreadyRequestedAccountIdSet = alreadyRequestedAccountIdSet;
        clsAccSyncBatch.strQuery = getBaseQuery();
        clsAccSyncBatch.strQuery += ' AND Id IN :setConsUnitIds';
        Id batchstart = Database.executeBatch(clsAccSyncBatch, batchSize);
    }
        
    public static String getBaseQuery() {
        String baseQuery = 'SELECT ' + String.join(AccountingUnit.fieldsList(), ','); 
        baseQuery += ' FROM Customer_Owned_Unit__c WHERE Available_For_QB_Consignment_Sync__c = true';
        return baseQuery;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        consUnitListToUpdate = new List<Customer_Owned_Unit__c>();
        errorLogToInsert = new List<Log__c>();
        if(String.isBlank(strQuery)) {
            strQuery = getBaseQuery();
            if(setConsUnitIds != null && setConsUnitIds.size() > 0) {
                strQuery += ' AND Id IN :setConsUnitIds';
            }
        } 
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> listConsUnits) {
        accountListToUpdateToSyncConsUnit = new List<Account>();
        for(Customer_Owned_Unit__c consUnit : listConsUnits) {
            if(consUnit.Account__c != null && consUnit.Account__r.AccountingId__c == null 
	            && alreadyRequestedAccountIdSet != null && !alreadyRequestedAccountIdSet.contains(consUnit.Account__c)) {
	            List<Account> accountListToUpdate = AccSync_Customer_Batch.getAccountListToUpdateById(new Set<Id>{consUnit.Account__c});
	            for(Account account: accountListToUpdate){
		            accountListToUpdateToSyncConsUnit.add(account);
		            alreadyRequestedAccountIdSet.add(account.Id);
	            }
            } else {
	            QBUtil.BatchResultWrapper batchResultObj = QBUnitConsignmentService.syncAccountingServer(new List<AccountingUnit>{ new AccountingUnit(consUnit)}, consUnitListToUpdate);
		        errorLogToInsert.addAll(batchResultObj.ErrorLogToInsert);
		        if(batchResultObj.RefreshToken !=  null) {
		            QBUtil.saveRefreshToken(batchResultObj.RefreshToken, batchResultObj.RefreshTokenExpiresIn);
		    	}
            }
        }
    }
 
    global void finish(Database.batchableContext bc) {
        updateConsUnits(consUnitListToUpdate);
        if(errorLogToInsert.size() > 0) {
            insert errorLogToInsert;
        }
        if(accountListToUpdateToSyncConsUnit != null && accountListToUpdateToSyncConsUnit.size() > 0) {
            AccSync_Customer_Batch.updateCustomers(accountListToUpdateToSyncConsUnit);
            accountListToUpdateToSyncConsUnit = null;
            runConsignmentsForSync(setConsUnitIds, alreadyRequestedAccountIdSet, 10);
        }
    }
    
    public static void updateConsUnits(List<Customer_Owned_Unit__c> consUnitListToUpdate) {
        if(consUnitListToUpdate != null && consUnitListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', consUnitListToUpdate);
        }
    }
}