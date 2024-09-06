global without sharing class CreateCOSectionDetailBatch implements Database.Batchable<sobject>{
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Id, (SELECT Section_Type__c FROM CO_Section_Details__r),' +  
                               '(SELECT Id FROM CO_Line_Items__r WHERE Service_Order_Line_Item__c = null AND Deal__c = null limit 1)' + 
                               ' FROM CO_Header__c WHERE Order_status__c = \'Open\' ORDER BY CreatedDate ASC';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<CO_Header__c> coHeaderList) {
        List<CO_Section_Detail__c> coSectionListToInsert = new List<CO_Section_Detail__c>();
        
        Map<Id, CO_Header__c> coHeaderMap = 
            new Map<Id, CO_Header__c>([SELECT Id, (SELECT Id FROM CO_Line_Items__r WHERE Service_Order_Line_Item__c = null AND Deal__c != null limit 1) 
                    FROM CO_Header__c WHERE Id IN: coHeaderList]);
        
        for(CO_Header__c coHeader : coHeaderList) {
            if(coHeader.CO_Line_Items__r.size() > 0) {
                if(!checkForExistingSection(coHeader, 'Merchandise')) {
                    coSectionListToInsert.add(COSectionDetailService.setCOSectionValue(coHeader.Id, 'Merchandise'));
                }
            }
            if(coHeaderMap.containsKey(coHeader.Id)) {
                if(coHeaderMap.get(coHeader.Id).CO_Line_Items__r.size() > 0) {
	                if(!checkForExistingSection(coHeader, 'Deal Merchandise')) {
	                    coSectionListToInsert.add(COSectionDetailService.setCOSectionValue(coHeader.Id, 'Deal Merchandise'));
	                }
	            }
            }
        }
        
        if(coSectionListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('CO_Section_Detail__c', coSectionListToInsert);
        }
    }
    
    private static Boolean checkForExistingSection(CO_Header__c coHeader, String sectionType) {
        Boolean isAlreadySectionExists = false;
        for(CO_Section_Detail__c coSection : coHeader.CO_Section_Details__r) {
            if(coSection.Section_Type__c == sectionType) {
                isAlreadySectionExists = true;
                break;
            }
        }
        return isAlreadySectionExists;
    }
    
    global void finish(Database.batchableContext bc) {
        
    }
}