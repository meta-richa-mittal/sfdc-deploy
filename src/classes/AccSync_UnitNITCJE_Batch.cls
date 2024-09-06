global without sharing class AccSync_UnitNITCJE_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    
    public String strQuery;
    public Set<Id> setUnitIds;
    public static boolean preventOnAccountingSync = false;
    global List<Customer_Owned_Unit__c> unitListToUpdate; 
    global List<Log__c> errorLogToInsert;
    
    public static void runUnitNITCJEForSync(Set<Id> setUnitInvoiceIdVal, Integer batchSize){
        
        AccSync_UnitNITCJE_Batch clsAccSyncBatch = new AccSync_UnitNITCJE_Batch();
        clsAccSyncBatch.setUnitIds = setUnitInvoiceIdVal;
        clsAccSyncBatch.strQuery = getBaseQuery();
        clsAccSyncBatch.strQuery += ' AND Id IN :setUnitIds';
        Id batchstart = Database.executeBatch(clsAccSyncBatch, batchSize);
    
    }
        
    public static String getBaseQuery(){
        String baseQuery = 'SELECT '; 
        for(String fieldName : AccountingUnit.fieldsList()){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            baseQuery += fieldName + ', ';
        }
        baseQuery = baseQuery.substring(0, baseQuery.length()-2);
        baseQuery += ' FROM Customer_Owned_Unit__c ';
        baseQuery += 'WHERE Available_For_QB_NITC_JE_Sync__c = true';
        return baseQuery;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc){
        unitListToUpdate = new List<Customer_Owned_Unit__c>();
        errorLogToInsert = new List<Log__c>();
        if(String.isBlank(strQuery)){
            strQuery = getBaseQuery();
            if(setUnitIds != null && setUnitIds.size() > 0) {
                strQuery += ' AND Id IN :setUnitIds';
            }
        }
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> listCOUs) {
        for(Customer_Owned_Unit__c skuRec : listCOUs) {
        	QBUtil.BatchResultWrapper batchResultObj = QBUnitNITCJEService.syncAccountingServer(new AccountingUnit(skuRec), unitListToUpdate);
			errorLogToInsert.addAll(batchResultObj.ErrorLogToInsert);
			if(batchResultObj.RefreshToken !=  null) {
				QBUtil.saveRefreshToken(batchResultObj.RefreshToken, batchResultObj.RefreshTokenExpiresIn);
			}
        }
    }  
 
    global void finish(Database.batchableContext bc){
        updateUnitInvoices(unitListToUpdate);
         if(errorLogToInsert.size() > 0) {
          insert errorLogToInsert;
         }
    }
    
    public static void updateUnitInvoices(List<Customer_Owned_Unit__c> unitListToUpdate){
        if(unitListToUpdate != null && unitListToUpdate.size() > 0){ 
            preventOnAccountingSync = true;
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitListToUpdate);
        }
    }
}