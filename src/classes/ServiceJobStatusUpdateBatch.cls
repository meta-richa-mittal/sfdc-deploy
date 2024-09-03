/** Author: Nidhi Sharma
 * Since: Oct 10, 2023
 * Name: ServiceJobStatusUpdateBatch
 * Description: 
**/
global without sharing class ServiceJobStatusUpdateBatch extends PostInstallScriptBaseBatch {

    global ServiceJobStatusUpdateBatch() {
        this.scriptName = 'executeServiceJobStatusUpdateBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Work_Status__c FROM Service_Order_Header__c WHERE Work_Status__c != null AND SO_Status_Ref__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> soList) {
        Map<String, Id> soStatusNameToIdMap = getSOStatusNameToIdMap(); 
        for(Service_Order_Header__c soRec : (List<Service_Order_Header__c>)soList) {
            if(UpdateServiceJobStatusBatch.oldSOStatusToNewStatusMap.containsKey(soRec.Work_Status__c)) {
                soRec.Work_Status__c = UpdateServiceJobStatusBatch.oldSOStatusToNewStatusMap.get(soRec.Work_Status__c);
            }
            soRec.SO_Status_Ref__c = soStatusNameToIdMap.get(soRec.Work_Status__c.toLowerCase());
        }
        SOTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soList);
        SOTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}

    private static Map<String, Id> getSOStatusNameToIdMap() {
        Map<String, Id> statusNameToIdMap = new Map<String, Id>();
        for(SO_Status__c soStatusRec : [Select Id, Name__c FROM SO_Status__c ORDER BY Order_No__c]) {
            statusNameToIdMap.put(soStatusRec.Name__c.toLowerCase(), soStatusRec.Id);
        }
        return statusNameToIdMap;
    }
}