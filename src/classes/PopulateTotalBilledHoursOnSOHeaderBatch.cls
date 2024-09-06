global without sharing class PopulateTotalBilledHoursOnSOHeaderBatch implements Database.Batchable<Sobject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        BPScriptUtility.disbaleTrigger('SOTrigger');
        return Database.getQueryLocator('SELECT Total_Hours_Billed__c FROM Service_Order_Header__c');
    }
    
    global void execute(Database.batchableContext bc, List<Service_Order_Header__c> soHeaderList) {
        soHeaderList = [SELECT Id, Total_Hours_Billed__c, 
                            (SELECT Qty_Needed__c FROM Service_Order_Line_Items__r WHERE Labour_Code__c != null AND Qty_Needed__c != null) 
                            FROM Service_Order_Header__c WHERE Id IN: soHeaderList];
        
        Decimal totalHoursBilled = 0;
        for(Service_Order_Header__c soHeader : soHeaderList) {
            totalHoursBilled = 0;
            for(Service_Order_Line_Item__c soliRec : soHeader.Service_Order_Line_Items__r) {
                totalHoursBilled += soliRec.Qty_Needed__c;
            }
            soHeader.Total_Hours_Billed__c = totalHoursBilled.setScale(2, RoundingMode.HALF_UP);
        }
        update soHeaderList;
    }
    
    global void finish(Database.batchableContext bc) {
        BPScriptUtility.enableTrigger('SOTrigger');
    }
}