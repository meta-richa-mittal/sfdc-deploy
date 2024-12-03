global without sharing class PopulateCreditsPendingOnRVOBatch extends PostInstallScriptBaseBatch {

    global PopulateCreditsPendingOnRVOBatch() {
        this.scriptName = 'executePopulateCreditsPendingOnRVOBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Id from Return_VO_Header__c where Credits_Pending__c = null';
        return Database.getQueryLocator(strQuery); 
    }

    global override void executeScript(Database.BatchableContext bc, List<SObject> rvoList) {
        List<Return_VO_Header__c> rvoWithLIList = [SELECT SubTotal__c, Status__c, (SELECT Item_Cost__c, Return_Qty__c FROM Return_VO_Line_Items__r WHERE Credit_Status__c = 'Pending') FROM Return_VO_Header__c WHERE Id IN :rvoList];
        for(Return_VO_Header__c rvoHeaderRec: rvoWithLIList) {
            if(rvoHeaderRec.Status__c == 'Approved') {
                rvoHeaderRec.Credits_Pending__c = rvoHeaderRec.SubTotal__c;
            } else if(rvoHeaderRec.Status__c == 'Partially Credited') {
                rvoHeaderRec.Credits_Pending__c = 0;
                for(Return_VO_Line_Item__c rvoliRec: rvoHeaderRec.Return_VO_Line_Items__r) {
                    rvoHeaderRec.Credits_Pending__c += ((rvoliRec.Item_Cost__c != null ? rvoliRec.Item_Cost__c : 0) * (rvoliRec.Return_Qty__c != null ? rvoliRec.Return_Qty__c : 0));
                }
            } else {
                rvoHeaderRec.Credits_Pending__c = 0;
            }
        }
        ReturnVOHeaderTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Return_VO_Header__c', rvoWithLIList);
        ReturnVOHeaderTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}