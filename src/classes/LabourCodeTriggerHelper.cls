/**
 * Author: Tarun Khandelwal
 * Since: Dec. 10, 2015
 * Name: LabourCodeTriggerHelper
 * Description: Helper class for triggers on Labour_Code__c object
**/
public without sharing class LabourCodeTriggerHelper {
	
	// List to store trigger new list
    public static List<Labour_Code__c> LabourNewList = new List<Labour_Code__c>();
    
    // List to store trigger old list
    public static List<Labour_Code__c> LabourOldList = new List<Labour_Code__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Labour_Code__c> LabourNewMap = new Map<Id, Labour_Code__c>();

    // Map to store Old Trigger Map
    public static Map<Id, Labour_Code__c> LabourOldMap = new Map<Id, Labour_Code__c>();
    
    
    /**
     * Name: updateKitLineItems
     * Desc: Update Kit Line Item if Retail Price of Labour Code is changed.
     * @param: 
     * @return: 
    **/
    public static void updateKitLineItems() {
    	List<Id> labourIdList = new List<Id>();
    	for(Labour_Code__c labourRec : LabourNewList) {
    		if(LabourNewMap.get(labourRec.Id).Rate__c != LabourOldMap.get(labourRec.Id).Rate__c || LabourNewMap.get(labourRec.Id).Fixed_Rate__c != LabourOldMap.get(labourRec.Id).Fixed_Rate__c) {
    			labourIdList.add(labourRec.Id);
    		}
    	}
        if(!labourIdList.isEmpty()) {
            List<Kit_Header_Line_Item__c> kitLineItemList = [SELECT Fixed_Price__c, Is_Environmental_Fee__c, Kit_Header__c, Kit_Price__c, Labour_Code__c, Part__c, Retail__c, Fee__c, Retail_Price__c FROM Kit_Header_Line_Item__c WHERE Labour_Code__c IN :labourIdList];
            if(!kitLineItemList.isEmpty()) {
                KitLineItemtriggerHelper.setRetailPriceBasedOnDefaultPriceLevel(kitLineItemList);
                DMLUtility.updateSobjectList('Kit_Header_Line_Item__c', kitLineItemList);
            }
        }
    }
}