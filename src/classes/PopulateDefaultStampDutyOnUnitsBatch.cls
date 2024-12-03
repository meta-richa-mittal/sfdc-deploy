global without sharing class PopulateDefaultStampDutyOnUnitsBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Stamp_Duty_Calculators__c FROM Customer_Owned_Unit__c WHERE Unit_Type__c != \'COU\' ';
        return Database.getQueryLocator(strQuery); 
    }


    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> unitList) {
        List<Stamp_Duty_Calculators__c> stamDutyList = [SELECT Id, Default__c FROM Stamp_Duty_Calculators__c WHERE Default__c = true];
        if(!stamDutyList.isEmpty()) {
            for(Customer_Owned_Unit__c unitRec: unitList) {
                unitRec.Stamp_Duty_Calculators__c = stamDutyList[0].Id;
            }
    
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitList);
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
        }
        
    }
    global void finish(Database.batchableContext bc) {}
}