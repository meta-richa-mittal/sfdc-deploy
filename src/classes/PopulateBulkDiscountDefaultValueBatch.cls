global without sharing class PopulateBulkDiscountDefaultValueBatch extends PostInstallScriptBaseBatch {
    global PopulateBulkDiscountDefaultValueBatch() {
        this.scriptName = 'executePopulateBulkDiscountDefaultValueBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c FROM CO_Header__c ';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> sobjectList) {
        List<CO_Header__c> coList = (List<CO_Header__c>) sobjectList;

        List<Service_Order_Header__c> soList = [SELECT Id, Fees_Bulk_Discount_Percent__c, Labor_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, 
                                               Sublet_Bulk_Discount_Percent__c FROM Service_Order_Header__c WHERE (Fees_Bulk_Discount_Percent__c = null 
                                                OR Labor_Bulk_Discount_Percent__c = null OR Parts_Bulk_Discount_Percent__c = null OR Sublet_Bulk_Discount_Percent__c = null) AND CO_Header__c IN : coList];

        for (CO_Header__c coRec : coList) {
            if (coRec.Fees_Bulk_Discount_Percent__c == null) {
                coRec.Fees_Bulk_Discount_Percent__c = 0;
            }
            if (coRec.Parts_Bulk_Discount_Percent__c == null) {
                coRec.Parts_Bulk_Discount_Percent__c = 0;
            }
        }

        for (Service_Order_Header__c soRec : soList) {
            if (soRec.Fees_Bulk_Discount_Percent__c == null) {
                soRec.Fees_Bulk_Discount_Percent__c = 0;
            }
            if (soRec.Labor_Bulk_Discount_Percent__c == null) {
                soRec.Labor_Bulk_Discount_Percent__c = 0;
            }
            if (soRec.Parts_Bulk_Discount_Percent__c == null) {
                soRec.Parts_Bulk_Discount_Percent__c = 0;
            }
            if (soRec.Sublet_Bulk_Discount_Percent__c == null) {
                soRec.Sublet_Bulk_Discount_Percent__c = 0;
            }
        }


        COTriggerHelper.isForceStopTrigger = true;
        SOTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('CO_Header__c', coList);
        DMLUtility.updateSobjectList('Service_Order_Header__c', soList);
        COTriggerHelper.isForceStopTrigger = false;
        SOTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}