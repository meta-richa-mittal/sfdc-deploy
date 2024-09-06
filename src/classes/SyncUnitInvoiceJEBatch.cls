/**
 * Author: Nidhi Sharma
 * Since: Sept 04, 2019
 * Name: SyncUnitInvoiceJEBatch
 * Description: Sync Batch for Unit Invoice JE. 
**/

global without sharing class SyncUnitInvoiceJEBatch  extends BaseSyncingBatch {
	
	global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Customer_Owned_Unit__c', AccountingUnit.fieldsList(), IntegrationUtility.UNIT_INVOICE_JE));
    }
    
    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> unitList) {
        for(Customer_Owned_Unit__c unitRec : unitList) {
            String accId = String.valueOf(unitRec.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.UNIT_INVOICE_JE).Integration_Id_API_Name__c));
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>{IntegrationUtility.JOURNAL_ENTRY => (String.isNotBlank(accId) ? IntegrationUtility.UPDATE_ACTION : IntegrationUtility.CREATE_ACTION)};
            this.webserviceLogs = integrationInstanceList[0].sync(new List<AccountingUnit>{new AccountingUnit(unitRec)}, (List<SObject>) sobjctListToUpdate, 
                                            IntegrationUtility.UNIT_INVOICE_JE, integrationEntityNameToActionMap);
            
        }
    }
  
    global override void finish(Database.batchableContext bc) {
        finishAction();
    }
    
}