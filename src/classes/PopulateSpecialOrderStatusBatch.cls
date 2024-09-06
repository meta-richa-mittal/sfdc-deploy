global without sharing class PopulateSpecialOrderStatusBatch implements Database.Batchable<sobject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Id FROM CO_Header__c WHERE Order_status__c = \'Open\' ORDER BY CreatedDate ASC';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<CO_Header__c> coHeaderList) {
        Set<Id> coHeaderIdSet = new Set<Id>();
        for(CO_Header__c coHeader : coHeaderList) {
            coHeaderIdSet.add(coHeader.Id);
        }
        COSectionDetailService.setSectionStatus(coHeaderIdSet, null);
    }
    
    global void finish(Database.batchableContext bc) {
        
    }
}