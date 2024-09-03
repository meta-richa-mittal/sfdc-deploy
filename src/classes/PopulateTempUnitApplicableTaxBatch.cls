/**
 * Author: Manoj Sharma
 * Since: Feb 02, 2024
 * Name: PopulateTempUnitApplicableTaxBatch
 * Description: Batch for Populating tax related fields on temp and required unit
**/
global without sharing class PopulateTempUnitApplicableTaxBatch extends PostInstallScriptBaseBatch {
    global PopulateTempUnitApplicableTaxBatch() {
        this.scriptName = 'executePopulateTempUnitApplicableTaxBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Taxable__c, Applicable_Tax__c FROM Customer_Owned_Unit__c WHERE Unit_Type__c = \'ORDU\' AND (Status__c = \'Temporary\' OR Status__c  = \'Required\') AND Applicable_Tax__c = null ';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> unitList) {
        for(Customer_Owned_Unit__c unitRec : (List<Customer_Owned_Unit__c>)unitList) {
            unitRec.Taxable__c = true;
            unitRec.Applicable_Tax__c = GeneralConfiguration.getConfigurations().Default_Tax_on_Unit__c;
        }
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSObjectList('Customer_Owned_Unit__c', (List<Customer_Owned_Unit__c>)unitList);
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}