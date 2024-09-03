/**
 * Author: Nidhi Sharma
 * Since: 13 May, 2024
 * Name: UPCAdjustmentDateBatch
 * Description: Batch for adjustment date on UPC
**/
global without sharing class UPCAdjustmentDateBatch extends PostInstallScriptBaseBatch {

    global UPCAdjustmentDateBatch() {
        this.scriptName = 'executeUPCAdjustmentDateBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Customer_Owned_Unit__r.Date_Stocked_In__c, Customer_Owned_Unit__r.CreatedDate from Unit_Price_Cost__c WHERE Adjustment_Date__c = null AND Unit_Type__c = \'STOCK\'';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> upcList) {
        for(Unit_Price_Cost__c upcRec : (List<Unit_Price_Cost__c>) upcList) {
            if(upcRec.Customer_Owned_Unit__r.Date_Stocked_In__c != null) {
                Date stockedInDateTime = upcRec.Customer_Owned_Unit__r.Date_Stocked_In__c;
                upcRec.Adjustment_Date__c = DateTime.newInstance(stockedInDateTime.year(), stockedInDateTime.month(), stockedInDateTime.day(), 0, 0, 0);
            } else {
                upcRec.Adjustment_Date__c = upcRec.Customer_Owned_Unit__r.CreatedDate;
            }
        }
        DMLUtility.updateSobjectList('Unit_Price_Cost__c', upcList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}