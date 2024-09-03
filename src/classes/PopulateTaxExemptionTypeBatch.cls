/**
 * Author: Nidhi Sharma
 * Since: June 18, 2024
 * Name: PopulateTaxExemptionTypeBatch
 * Description: 
**/
global without sharing class PopulateTaxExemptionTypeBatch extends PostInstallScriptBaseBatch {

    global PopulateTaxExemptionTypeBatch() {
        this.scriptName = 'executePopulateTaxExemptionTypeBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Type__c FROM Tax_Exemption__c Where Type__c = null AND (CO_Header__c != null OR Service_Order_Header__c != null)';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> taxExemptList) {
        for(Tax_Exemption__c taxExemptRec : (List<Tax_Exemption__c>)taxExemptList) {
            taxExemptRec.Type__c = TaxUtility.EXEMPTION;
        }
        DMLUtility.updateSobjectList('Individual_Tax__c', taxExemptList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}