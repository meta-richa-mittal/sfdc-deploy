global without sharing class PopulateLastSoldFieldOnPartBatch extends PostInstallScriptBaseBatch{
    global PopulateLastSoldFieldOnPartBatch() {
        this.scriptName = 'executePopulateLastSoldFieldOnPartBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Last_Sold__c From Part__c';
        return Database.getQueryLocator(strQuery); 
    }

    global override void executeScript(Database.BatchableContext bc, List<SObject> partList) {
        Map<Id,Part__c> partIdToUpdatedPartRecMap = new Map<Id,Part__c>();
        
        for(Part__c partRec: [SELECT Id, Last_Sold__c, (Select Id, Invoice_Number__r.Closed_Invoice_Date__c FROM CO_Line_Items__r where Invoice_Number__c != null order by Invoice_Number__r.Closed_Invoice_Date__c desc limit 1) From Part__c where ID In :partList]) {
            for(CO_Line_Item__c coliRec: partRec.CO_Line_Items__r){
                if(partRec.Last_Sold__c == null || partRec.Last_Sold__c < coliRec.Invoice_Number__r.Closed_Invoice_Date__c){
                    partIdToUpdatedPartRecMap.put(partRec.Id, new Part__c(Id = partRec.Id, Last_Sold__c = coliRec.Invoice_Number__r.Closed_Invoice_Date__c));
                }
            }
        }

        PartTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Part__c', partIdToUpdatedPartRecMap.values());
        PartTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {
        
    }
}
