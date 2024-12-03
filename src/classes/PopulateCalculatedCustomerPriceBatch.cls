global without sharing class PopulateCalculatedCustomerPriceBatch extends PostInstallScriptBaseBatch {
    private Boolean isTaxIncludePricing = GeneralConfiguration.getTaxIncludingPricing();

    global PopulateCalculatedCustomerPriceBatch() {
        this.scriptName = 'executePopulateCalculatedCustomerPriceBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id From CO_Header__c ';
        return Database.getQueryLocator(strQuery); 
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> coList) {
        Set<String> coIdSet = new Set<String>();
        for(CO_Header__c coRec : (List<CO_Header__c>)coList) {
            coIdSet.add(coRec.Id);
        }

        List<CO_Line_Item__c> coliList = [SELECT Calculated_Customer_Price__c, Price_When_Tax_Included__c, Price__c FROM CO_Line_Item__c WHERE Deal__c = null AND CO_Header__c In : coIdSet];
        List<Service_Order_Line_Item__c> soliList = [SELECT Calculated_Customer_Price__c, Price_When_Tax_Included__c, Kit_Price__c FROM Service_Order_Line_Item__c WHERE Deal__c = null AND Service_Order_Header__r.Transaction_Type__r.Type__c = 'Customer' AND Service_Order_Header__r.CO_Header__c In : coIdSet];

        for(CO_Line_Item__c coliRec : coliList) {
            coliRec.Calculated_Customer_Price__c = isTaxIncludePricing ? coliRec.Price_When_Tax_Included__c : coliRec.Price__c;
        }

        for(Service_Order_Line_Item__c soliRec : soliList) {
            soliRec.Calculated_Customer_Price__c = isTaxIncludePricing ? soliRec.Price_When_Tax_Included__c : soliRec.Kit_Price__c;
        }

        COLineItemTriggerHelper.isForceStopTrigger = true;
        ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
        DMLUtility.updateSobjectList('CO_Line_Item__c', coliList);
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliList);
        ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
        COLineItemTriggerHelper.isForceStopTrigger = false;
    }

    global override void finishScript(Database.BatchableContext bc) {}
}