global without sharing class SyncUnitConsignmentBatch extends BaseSyncingBatch {
    
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Customer_Owned_Unit__c', AccountingUnit.fieldsList(), IntegrationUtility.UNIT_CONSIGNMENT));
    }
    
    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> listConsignmentUnit) {
    	for(Customer_Owned_Unit__c consignmentUnitRec : listConsignmentUnit) {
        	String accId = String.valueOf(consignmentUnitRec.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.UNIT_CONSIGNMENT).Integration_Id_API_Name__c));
    		Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.CREDIT_NOTE => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
        	this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingUnit>{new AccountingUnit(consignmentUnitRec)}, (List<SObject>) sobjctListToUpdate, 
                                            IntegrationUtility.UNIT_CONSIGNMENT, integrationEntityNameToActionMap));
        }
    }
    
    global override void finish(Database.batchableContext bc){
        finishAction();
    }
}