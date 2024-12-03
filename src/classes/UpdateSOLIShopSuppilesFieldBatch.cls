/**
 * Author: Manoj Sharma
 * Since: Jan 31, 2023
 * Name: UpdateSOLIShopSuppilesFieldBatch
 * Description: Batch for Populating calculate shop suppiles field on service job line items.
**/
global without sharing class UpdateSOLIShopSuppilesFieldBatch extends PostInstallScriptBaseBatch{
    global UpdateSOLIShopSuppilesFieldBatch() {
        this.scriptName = 'executeUpdateSOLIShopSuppilesFieldBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Is_Calculate_Supplies__c, Labour_Code__c, Labour_Code__r.Calculate_Supplies__c FROM Service_Order_Line_Item__c WHERE Labour_Code__r.Calculate_Supplies__c = TRUE AND CO_Status__c = \'Open\'';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> soliList) {
        for(Service_Order_Line_Item__c soliRec : (List<Service_Order_Line_Item__c>)soliList) {
            soliRec.Is_Calculate_Supplies__c = soliRec.Labour_Code__r.Calculate_Supplies__c;
        }
        if(soliList.size() > 0) {
            ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
            DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliList);
            ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
        }
    }
    
    global override void finishScript(Database.BatchableContext bc) {
    }
}