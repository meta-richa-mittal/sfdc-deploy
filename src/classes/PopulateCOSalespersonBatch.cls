/**
 * Author: Nidhi Sharma
 * Since: Sept 22, 2023
 * Name: PopulateCOSalespersonBatch
**/
global without sharing class PopulateCOSalespersonBatch extends PostInstallScriptBaseBatch {

    global PopulateCOSalespersonBatch() {
        this.scriptName = 'executePopulateCOSalespersonBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'Select Id, CreatedById, (Select Id, CreatedById FROM Service_Order_Headers__r WHERE Salesperson_Names__c = null), (Select Id From CO_Invoice_Headers__r WHERE Status__c = \'Closed\') from CO_Header__c WHERE Salesperson_Names__c = null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> coList) {
        Set<Id> invoiceIdSet = new Set<Id>();
        Map<Id, Id> userIdToTechIdMap = new Map<Id, Id>();
        Map<Id, CO_Line_Item__c> coIdToDealMerchRecMap = new Map<Id, CO_Line_Item__c>();
        for(CO_Header__c coRec : [Select Id, (Select Deal__c, CreatedById FROM CO_Line_Items__r Where Deal__c != null AND Service_Order_Line_Item__c = null Order By CreatedDate ASC LIMIT 1) FROM CO_Header__c 
        WHERE Id IN: coList]) {
            if(!coRec.CO_Line_Items__r.isEmpty()) {
                coIdToDealMerchRecMap.put(coRec.Id, coRec.CO_Line_Items__r[0]);
            }
        }
        for(CO_Header__c coRec : (List<CO_Header__c>)coList) {
            userIdToTechIdMap.put(coRec.CreatedById, null);
            if(coIdToDealMerchRecMap.get(coRec.Id) != null) {
                userIdToTechIdMap.put(coIdToDealMerchRecMap.get(coRec.Id).CreatedById, null);
            }
            for(Service_Order_Header__c soRec : coRec.Service_Order_Headers__r) {
                userIdToTechIdMap.put(soRec.CreatedById, null);
            }
            for(CO_Invoice_Header__c invRec : coRec.CO_Invoice_Headers__r) {
                invoiceIdSet.add(invRec.Id);
            }
        }
        if(!userIdToTechIdMap.isEmpty()) {
            for(Technician__c techRec : [Select Id, User__c FROM Technician__c WHERE User__c IN: userIdToTechIdMap.keySet()]) {
                userIdToTechIdMap.put(techRec.User__c, techRec.Id);
            }
            List<CO_Salesperson__c> spInsertList = new List<CO_Salesperson__c>();
            for(CO_Header__c coRec : (List<CO_Header__c>)coList) {
                if(userIdToTechIdMap.get(coRec.CreatedById) != null) {
                    spInsertList.add(new CO_Salesperson__c(CO_Header__c = coRec.Id, Technician__c = userIdToTechIdMap.get(coRec.CreatedById)));
                }
                if(coIdToDealMerchRecMap.get(coRec.Id) != null) {
                    CO_Line_Item__c dealMerchRec = coIdToDealMerchRecMap.get(coRec.Id);
                    if(userIdToTechIdMap.get(dealMerchRec.CreatedById) != null) {
                        spInsertList.add(new CO_Salesperson__c(CO_Header__c = coRec.Id, Deal__c = dealMerchRec.Deal__c, Technician__c = userIdToTechIdMap.get(dealMerchRec.CreatedById)));
                    }
                }
                for(Service_Order_Header__c soRec : coRec.Service_Order_Headers__r) {
                    if(userIdToTechIdMap.get(soRec.CreatedById) != null) {
                        spInsertList.add(new CO_Salesperson__c(Service_Order_Header__c = soRec.Id, Technician__c = userIdToTechIdMap.get(soRec.CreatedById)));
                    }
                }
            }
            DMLUtility.insertSobjectList('CO_Salesperson__c', spInsertList);
        }
        COInvoiceTriggerHelper.addCOSalespersonsOnCOInvoice(invoiceIdSet);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}