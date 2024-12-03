/** 
* Author: Manoj Sharma
* Since: June 20, 2020 
* Name: DisableFlagOnPartForBRP 
* Description: Apex class to disable part plag for brp.
**/
global without sharing class DisableFlagOnPartForBRP implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    
    global Date fileDate;
    
    global DisableFlagOnPartForBRP(Date dateValue) {
        this.fileDate = dateValue != null ? dateValue : system.today();
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Id, Is_Included_In_BRP_Inventory__c ' +
                        'FROM  Part__c where Is_Included_In_BRP_Inventory__c = true Order By Name ASC ';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List< Part__c> partList) {
      for( Part__c partRec : partList) {
          partRec.Is_Included_In_BRP_Inventory__c = false;
      }
      PartTriggerHelper.isForceStopTrigger = true;
      DMLUtility.updateSobjectList('Part__c', partList);
      PartTriggerHelper.isForceStopTrigger = false;
    }
    
    global void finish(Database.batchableContext bc) {
      BRPPartInventoryScript.run(this.fileDate);
    }
}