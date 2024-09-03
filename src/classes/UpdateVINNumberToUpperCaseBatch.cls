global without sharing class UpdateVINNumberToUpperCaseBatch extends PostInstallScriptBaseBatch {

    global UpdateVINNumberToUpperCaseBatch() {
        this.scriptName = 'executeUpdateVINNumberToUpperCaseBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select VIN_Number__c from Customer_Owned_Unit__c where VIN_Number__c != null';
        return Database.getQueryLocator(strQuery); 
    }

    global override void executeScript(Database.BatchableContext bc, List<SObject> couList) {
        for(Customer_Owned_Unit__c vinNumber: (List<Customer_Owned_Unit__c>)couList) {
            vinNumber.VIN_Number__c = (vinNumber.VIN_Number__c).toUpperCase();
        }
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', couList);
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {
        
    }
}