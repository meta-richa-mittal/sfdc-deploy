global without sharing class PopulateSOCommitControlsBatch extends PostInstallScriptBaseBatch  {
    global PopulateSOCommitControlsBatch() {
        this.scriptName = 'executePopulateSOCommitControlsBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, (SELECT Id, CO_Line_Item__c, CO_Line_Item__r.Merchandise_Commit_Order_controls__c FROM Service_Order_Line_Items__r) FROM Service_Order_Header__c Where Commit_Order_controls__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> soList) {
        List<Service_Order_Header__c> soListToUpdate = new List<Service_Order_Header__c>();
        List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
        List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();

        for(Service_Order_Header__c soRec : (List<Service_Order_Header__c>)soList) {
            soRec.Commit_Order_controls__c = CONSTANTS.COMMIT_AND_ORDER;
            soListToUpdate.add(soRec);

            for (Service_Order_Line_Item__c solineItem : soRec.Service_Order_Line_Items__r) {
                solineItem.Commit_Order_controls__c = CONSTANTS.COMMIT_AND_ORDER;
                soliListToUpdate.add(solineItem);
                if(solineItem.CO_Line_Item__c != null) {
                    solineItem.CO_Line_Item__r.Merchandise_Commit_Order_controls__c = CONSTANTS.COMMIT_AND_ORDER;
                    coliListToUpdate.add(solineItem.CO_Line_Item__r);
                }
            }
        }

        COLineItemTriggerHelper.isForceStopTrigger = true;
        SOTriggerHelper.isForceStopTrigger = true;
        ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soListToUpdate);
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);
        DMLUtility.updateSobjectList('CO_Line_Item__c', coliListToUpdate);
        ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
        SOTriggerHelper.isForceStopTrigger = false;
        COLineItemTriggerHelper.isForceStopTrigger = false;
       
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}