public with sharing class FeeTriggerHelper {

    public static List<Fee__c> FeeNewList = new List<Fee__c>();
    public static List<Fee__c> FeeOldList = new List<Fee__c>();
    public static Map<Id, Fee__c> FeeOldMap = new Map<Id, Fee__c>();

    public static void beforeUpdate() {
        checkShopSuppliesConfigurationFeeUpdateAction();
    }
    
    public static void afterUpdate() {
        updateKitLineItems();
    }

    public static void beforeDelete() {
        checkShopSuppliesConfigurationFeeDeleteAction();
    }


    public static void checkShopSuppliesConfigurationFeeUpdateAction(){
        List<Shop_Supplies__c> shopSuppliesList = [Select Applicable_Fee__c From Shop_Supplies__c Limit 1];
        for(Fee__c feeRec: FeeNewList){
            if(feeRec.Id == shopSuppliesList[0].Applicable_Fee__c && feeRec.Active__c == false && FeeOldMap.get(feeRec.Id).Active__c == true){
                throw new BlackPurlException('Fee can not be made inactive as it is used in some configuration.'); 
            }
        }
    }

    public static void checkShopSuppliesConfigurationFeeDeleteAction(){
        List<Shop_Supplies__c> shopSuppliesList = [Select Applicable_Fee__c From Shop_Supplies__c Limit 1];
        for(Fee__c feeRec: FeeOldList){
            if(feeRec.Id == shopSuppliesList[0].Applicable_Fee__c){
                throw new BlackPurlException('Fee can not be deleted as it is used in some configuration.'); 
            }
        }
    }

    public static void updateKitLineItems() {
    	List<Id> feeIdList = new List<Id>();
    	for(Fee__c feeRec : FeeNewList) {
    		if(feeRec.Price__c != FeeOldMap.get(feeRec.Id).Price__c) {
    			feeIdList.add(feeRec.Id);
    		}
    	}
        if(!feeIdList.isEmpty()) {
            List<Kit_Header_Line_Item__c> kitLineItemList = [SELECT Fixed_Price__c, Is_Environmental_Fee__c, Kit_Header__c, Kit_Price__c, Labour_Code__c, Part__c, Retail__c, Fee__c, Retail_Price__c FROM Kit_Header_Line_Item__c WHERE Fee__c IN :feeIdList];
            if(!kitLineItemList.isEmpty()) {
                KitLineItemtriggerHelper.setRetailPriceBasedOnDefaultPriceLevel(kitLineItemList);
                DMLUtility.updateSobjectList('Kit_Header_Line_Item__c', kitLineItemList);
            }
        }
    }
}
