/**
 * Author: Nidhi Sharma
 * Since: March 21, 2024
 * Name: PopulateIndividualTaxRateNameBatch
 * Description: 
**/
global without sharing class PopulateIndividualTaxRateNameBatch extends PostInstallScriptBaseBatch {

    global PopulateIndividualTaxRateNameBatch() {
        this.scriptName = 'executePopulateIndividualTaxRateNameBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Sales_Tax_Item__r.Name__c FROM Individual_Tax__c Where Sales_Tax_Item_Name__c = null AND Sales_Tax_Item__c != null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> individualTaxList) {
        for(Individual_Tax__c individualTaxRec : (List<Individual_Tax__c>)individualTaxList) {
            individualTaxRec.Sales_Tax_Item_Name__c = individualTaxRec.Sales_Tax_Item__r.Name__c;
        }
        DMLUtility.updateSobjectList('Individual_Tax__c', individualTaxList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}