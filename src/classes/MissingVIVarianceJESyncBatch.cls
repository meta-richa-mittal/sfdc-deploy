/**
 * Author: Nidhi Sharma
 * Since: June 12, 2023
 * Name: MissingVIVarianceJESyncBatch
 * Description: Batch for turn on sync flag on VI for variance JE when applied charges is not blank
**/
global without sharing class MissingVIVarianceJESyncBatch extends PostInstallScriptBaseBatch {

    private Boolean recordFound = false;
    global MissingVIVarianceJESyncBatch() {
        this.scriptName = 'executeMissingVIVarianceJESyncBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Id from Vendor_Invoicing_Header__c where Status__c = \'Invoiced\' AND Id IN (Select Vendor_Invoicing_Header__c from Vendor_Invoicing_Group__c where Applied_Charge__c != null AND Applied_Charge__c != 0)';
        if(String.isNotBlank(AccountingUtil.activeAccIntegrationName)) {
            if(QBUtil.isQBEnabled()) {
                strQuery += ' AND QB_Variance_JE_Accounting_Id__c = null';
            } else {
                strQuery += ' AND Xero_Variance_JE_Accounting_Id__c = null';
            }
        } else {
            strQuery += ' AND Id = null';
        }
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> viList) {
        recordFound = true;
        Set<Id> vendorIdSet = new Set<Id>();
        for(Vendor_Invoicing_Header__c viRec : (List<Vendor_Invoicing_Header__c>)viList) {
            if(QBUtil.isQBEnabled()) {
                viRec.Available_For_QB_Variance_JE_Sync__c = true;
            } else {
                viRec.Available_For_Xero_Variance_JE_Sync__c = true;
            }
        }
        DMLUtility.updateSobjectList('Vendor_Invoicing_Header__c', viList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {
        if(recordFound) {
            AccountingScriptUtil.syncVIVarianceJE(25,60);
        }
    }
}