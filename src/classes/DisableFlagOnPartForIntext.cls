/** 
* Author: Richa Mittal
* Since: Dec 07, 2020 
* Name: DisableFlagOnPartForIntext 
* Description: Apex class to disable part flag for intext.
**/
global without sharing class DisableFlagOnPartForIntext implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    
    global Date fileDate;
    
    global DisableFlagOnPartForIntext(Date dateValue) {
        this.fileDate = dateValue != null ? dateValue : system.today();
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Id, Is_Included_In_Intext_Inventory__c ' +
                        'FROM  Part__c where Is_Included_In_Intext_Inventory__c = true Order By Name ASC ';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.batchableContext bc, List< Part__c> partList) {
      for( Part__c partRec : partList) {
          partRec.Is_Included_In_Intext_Inventory__c = false;
      }
      GenericExportUtil.updatePartRecords(partList, 0);
    }
    
    global void finish(Database.batchableContext bc) {
      IntextPartInventoryScript.run(this.fileDate);
    }
}