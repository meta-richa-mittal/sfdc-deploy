public without sharing class ReturnCRLITriggerHelper {
    // List to store trigger new list
    public static List<Return_CR_Line_Item__c> returnCRLINewList = new List<Return_CR_Line_Item__c>();
    
    // List to store trigger old list
    public static List<Return_CR_Line_Item__c> returnCRLIOldList = new List<Return_CR_Line_Item__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Return_CR_Line_Item__c> returnCRLINewMap = new Map<Id, Return_CR_Line_Item__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Return_CR_Line_Item__c> returnCRLIOldMap = new Map<Id, Return_CR_Line_Item__c>();

    public static void afterInsertOperation(){
    	calculateVOLITotal(returnCRLINewList);
    }

    public static void afterUpdateOperation(){
    	calculateVOLITotal(returnCRLINewList);
    }

    public static void afterDeleteOperation(){
    	calculateVOLITotal(returnCRLIOldList);
    }

    public static void calculateVOLITotal(List<Return_CR_Line_Item__c> returnCRLIList){
    	Set<String> returnCRIdSet = new  Set<String>();
    	for(Return_CR_Line_Item__c returnCRLIRec: returnCRLIList) {
    		returnCRIdSet.add(returnCRLIRec.Return_CR_Header__c);
    	}
    	List<Return_CR_Header__c> returnCRRecList =  [SELECT Id, Item_Total__c, Vendor__r.Purchase_Tax__r.Rate__c,
    													 (SELECT Id, Credit_Cost__c, Return_Qty__c FROM Return_CR_Line_Items__r)
    													 FROM Return_CR_Header__c WHERE Id IN : returnCRIdSet];
    	for(Return_CR_Header__c returnCRHRec: returnCRRecList) {
    		returnCRHRec.Item_Total__c = 0;
    		for(Return_CR_Line_Item__c returnCRLIRec: returnCRHRec.Return_CR_Line_Items__r) {
				if(returnCRLIRec.Credit_Cost__c == null) {
					returnCRLIRec.Credit_Cost__c = 0;
				}
				if(returnCRLIRec.Return_Qty__c == null) {
					returnCRLIRec.Return_Qty__c = 0 ;
				}
    			returnCRHRec.Item_Total__c +=  (returnCRLIRec.Credit_Cost__c * returnCRLIRec.Return_Qty__c);
    		}
    		returnCRHRec.Item_Tax_Amount__c = 0;
    		if(returnCRHRec.Vendor__r.Purchase_Tax__r.Rate__c != null){
    			returnCRHRec.Item_Tax_Amount__c = (returnCRHRec.Item_Total__c * returnCRHRec.Vendor__r.Purchase_Tax__r.Rate__c)/100;
    		}
    	}
        DMLUtility.updateSobjectList('Return_CR_Header__c', returnCRRecList);
    }
}