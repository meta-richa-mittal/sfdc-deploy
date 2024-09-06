/**
 * Author: Manoj Sharma
 * Since: May 11, 2021
 * Name: UpdateKitLineItemRetailPriceBatch
 * Description: Batch for updating Kit Line Items pricing based on default price level
 * THIS BATCH IS NOT IN USE, NOW USE UpdateKitLineItemRetailPriceQueueable
**/
global without sharing class UpdateKitLineItemRetailPriceBatch implements Database.Batchable<sobject> {
    public Set<String> partIdSet = new Set<String>();

    global UpdateKitLineItemRetailPriceBatch(){}

    global UpdateKitLineItemRetailPriceBatch(Set<String> partIdSet){
        this.partIdSet = partIdSet;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Fixed_Price__c, Is_Environmental_Fee__c, Kit_Header__c, Kit_Price__c, Labour_Code__c, Part__c, Retail__c, Fee__c, Retail_Price__c FROM Kit_Header_Line_Item__c WHERE (Part__c != null OR Labour_Code__c != null)';
        if(partIdSet.size() > 0) {
            strQuery += ' AND Part__c IN :partIdSet ';
        }
        strQuery += ' ORDER BY Name ASC';
        return Database.getQueryLocator(strQuery); 
    }
    global void execute(Database.batchableContext bc, List<Kit_Header_Line_Item__c> kitLineItemList) {
        KitLineItemtriggerHelper.setRetailPriceBasedOnDefaultPriceLevel(kitLineItemList);
        if(kitLineItemList.size() > 0){
            update kitLineItemList;
        }
    }
      
    global void finish(Database.batchableContext bc) {}
}
