/**
 * Author: Nidhi Sharma
 * Since: March 22, 2023
 * Name: DFINApprovedAmountFinancedBatch
 * Description: Batch for populating ApprovedAmountFinanced on deal finance
**/
global without sharing class DFINApprovedAmountFinancedBatch extends PostInstallScriptBaseBatch {
    
	global DFINApprovedAmountFinancedBatch() {
        this.scriptName = 'executeDFINApprovedAmountFinancedBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Deal__r.Amount_Financed__c FROM Deal_Finance__c WHERE Approved_Amount_Financed__c = null AND Status__c IN (\'Approved\', \'Funded\') AND Deal__r.Amount_Financed__c != null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealFinanceList) {
    	for(Deal_Finance__c dealFinanceRec : (List<Deal_Finance__c>) dealFinanceList) {
			dealFinanceRec.Approved_Amount_Financed__c = dealFinanceRec.Deal__r.Amount_Financed__c;
		}
        DMLUtility.updateSobjectList('Deal_Finance__c', dealFinanceList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}