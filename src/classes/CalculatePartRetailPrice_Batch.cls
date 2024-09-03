/*
    Apex batch class to update part records 
*/
global without sharing class CalculatePartRetailPrice_Batch implements Database.Batchable<sobject>, Database.Stateful {

    public String baseQuery;
    public Set<Id> setVendorIds;
    private List<Kit_Header_Line_Item__c> kitLineItemsToUpdate;
    
    global CalculatePartRetailPrice_Batch(){
       
    }
    global CalculatePartRetailPrice_Batch(Set<Id> setVendorIdsVal, Integer batchSize){
        CalculatePartRetailPrice_Batch clsPartBatch = new CalculatePartRetailPrice_Batch();
        clsPartBatch.setVendorIds = setVendorIdsVal;
        Id batchstart = Database.executeBatch(clsPartBatch, batchSize);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        baseQuery = 'SELECT ' + String.join(PartDetail.fieldsList(), ',');
        baseQuery += ' FROM Part__c WHERE Vendor__c IN :setVendorIds';
        return Database.getQueryLocator(baseQuery); 
    } 

    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        baseQuery = 'SELECT ' + String.join(PartDetail.fieldsList(), ','); 
        baseQuery += ', (SELECT Retail_Price__c FROM Kit_Header_Line_Items__r)';
        baseQuery += ' FROM Part__c WHERE Id IN :partList And Is_Retail_Locked_In__c = False';
        List<Part__c> partListToUpdate = Database.query(baseQuery);

        kitLineItemsToUpdate = new List<Kit_Header_Line_Item__c>();
        Map<String, Escalator__c> vendorIdToEscalatorRecMap = EscalatorService.getVendorIdToEscalatorRecMap(partListToUpdate);
        for(Part__c partRec: partListToUpdate) {
          for(Kit_Header_Line_Item__c kitLineItemRec : partRec.Kit_Header_Line_Items__r) {
          kitLineItemsToUpdate.add(kitLineItemRec);
        }
            ViewPartCtrl.calculatePartRetailPrice(partRec, vendorIdToEscalatorRecMap.get(partRec.Vendor__c));
        }
        if(AccessControl.ifObjectFieldIsUpdateable('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        update partListToUpdate;
        if(AccessControl.ifObjectFieldIsUpdateable('Kit_Header_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        update kitLineItemsToUpdate;
    } 
 
    global void finish(Database.batchableContext bc){
    }
}