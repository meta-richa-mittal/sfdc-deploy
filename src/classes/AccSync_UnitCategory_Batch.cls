/*
    Apex class to sync unit category with accounting server on change of inventory GL of categoy
*/
global without sharing class AccSync_UnitCategory_Batch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    global List<Customer_Owned_Unit__c> unitListToUpdate;
        
    public static void runUnitForSync(Set<Id> setunitIdVal, Integer batchSize) {
    }
        
    public static String getBaseQuery() {
        return null;
    }
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
    
    global void execute(Database.batchableContext bc, List<Customer_Owned_Unit__c> listUnits) {
    }
 
    global void finish(Database.batchableContext bc) {
    }
}