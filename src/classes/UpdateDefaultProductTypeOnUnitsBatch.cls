/** Author: Richa Mittal
 * Since: July 23, 2024
 * Name: UpdateDefaultProductTypeOnUnitsBatch
 * Description: 
**/
global without sharing class UpdateDefaultProductTypeOnUnitsBatch extends PostInstallScriptBaseBatch {

    private String defaultProductTypeId;

    global UpdateDefaultProductTypeOnUnitsBatch() {
        this.scriptName = 'executeUpdateDefaultProductTypeOnUnitsBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        defaultProductTypeId = BPScriptManager.createDefaultUnitProductType();
        String strQuery = 'SELECT Id FROM Customer_Owned_Unit__c WHERE Product_type__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> couList) {
        for(Customer_Owned_Unit__c couRec: (List<Customer_Owned_Unit__c>)couList) {
            couRec.Product_type__c = defaultProductTypeId;
        }
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', couList);
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}