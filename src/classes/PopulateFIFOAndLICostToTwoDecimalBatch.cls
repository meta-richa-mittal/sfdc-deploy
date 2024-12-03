/** 
* Author: Manoj Sharma
* Since: Nov 11, 2024
* Name: PopulateFIFOAndLICostToTwoDecimalBatch 
* Description: Apex class to set cost of FIFO and FIFO LI's
**/
global without sharing class PopulateFIFOAndLICostToTwoDecimalBatch extends PostInstallScriptBaseBatch {

    global PopulateFIFOAndLICostToTwoDecimalBatch() {
        this.scriptName = 'executePopulateFIFOAndLICostToTwoDecimalBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Cost__c, VRCost__c FROM Part_FIFO_Bucket__c';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> bucketList) {
        List<Part_FIFO_Bucket_Activity_Line_Item__c> bucketLiList = [SELECT Cost__c FROM Part_FIFO_Bucket_Activity_Line_Item__c WHERE Part_FIFO_Bucket__c IN: bucketList];
        List<Part_FIFO_Bucket_Activity_Line_Item__c> bucketLiListToUpdate = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
        List<Part_FIFO_Bucket__c> bucketListToUpdate = new List<Part_FIFO_Bucket__c>();

        for(Part_FIFO_Bucket__c fifoRec : (List<Part_FIFO_Bucket__c>) bucketList) {
            if(fifoRec.Cost__c != null && fifoRec.Cost__c != (fifoRec.Cost__c).setScale(2, RoundingMode.HALF_UP)) {
                fifoRec.Cost__c = (fifoRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                fifoRec.VRCost__c = (fifoRec.VRCost__c).setScale(2, RoundingMode.HALF_UP);
                bucketListToUpdate.add(fifoRec);
            }
        }

        for(Part_FIFO_Bucket_Activity_Line_Item__c fifoLiRec : bucketLiList) {
            if(fifoLiRec.Cost__c != null && fifoLiRec.Cost__c != (fifoLiRec.Cost__c).setScale(2, RoundingMode.HALF_UP)) {
                fifoLiRec.Cost__c = (fifoLiRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                bucketLiListToUpdate.add(fifoLiRec);
            }
        }

        DMLUtility.updateSobjectList('Part_FIFO_Bucket__c', bucketListToUpdate);
        DMLUtility.updateSobjectList('Part_FIFO_Bucket_Activity_Line_Item__c', bucketLiListToUpdate);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}