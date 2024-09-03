/**
 * Author: Nidhi Sharma
 * Since: Jan 30, 2023
 * Name: FeeCostSetToZeroBatch
 * Description: Batch for updating cost on fees to 0
 * Test Coverage: Written in ViewFeeCtrlTest
**/
global without sharing class FeeCostSetToZeroBatch extends PostInstallScriptBaseBatch {

    global FeeCostSetToZeroBatch() {
        this.scriptName = 'executeFeeCostSetToZeroBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Cost_Rate__c, Cost_Method__c FROM Fee__c WHERE Cost_Rate__c != null OR Cost_Method__c != null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> feeList) {
        for(Fee__c feeRec: (List<Fee__c>)feeList) {
			feeRec.Cost_Rate__c = null;
            feeRec.Cost_Method__c = null;
		}
        DMLUtility.updateSobjectList('Fee__c', feeList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}