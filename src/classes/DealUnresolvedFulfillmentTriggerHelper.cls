/**
 * Author: Nidhi Sharma
 * Since: March 04, 2020
 * Name: DealUnresolvedFulfillmentTriggerHelper
 * Description: Trigger executes on trigger event of deal unresolved fulfillment object
**/
public without sharing class DealUnresolvedFulfillmentTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    public static List<Deal_Unresolved_Fulfillment__c> dealURFOldList = new List<Deal_Unresolved_Fulfillment__c>();
    
    public static void afterDelete() {
    	reactivateCommitOption(dealURFOldList);
    }
    
    private static void reactivateCommitOption(List<Deal_Unresolved_Fulfillment__c> dealURFList) {
    	Set<String> dealIdSet = new Set<String>();
    	Set<String> coliIdSet = new Set<String>();
    	Set<String> soliIdSet = new Set<String>();
    	Set<String> cokhIdSet = new Set<String>();
    	Set<String> sokhIdSet = new Set<String>();
    	for(Deal_Unresolved_Fulfillment__c durfRec : dealURFList) {
    		if(String.isNotBlank(durfRec.CO_Line_Item__c)) {
    			coliIdSet.add(durfRec.CO_Line_Item__c);
    		}
    		if(String.isNotBlank(durfRec.Service_Order_Line_Item__c)) {
    			soliIdSet.add(durfRec.Service_Order_Line_Item__c);
    		}
    		if(String.isNotBlank(durfRec.CO_Kit_Header__c)) {
    			cokhIdSet.add(durfRec.CO_Kit_Header__c);
    		}
    		if(String.isNotBlank(durfRec.Service_Order_Kit_Header__c)) {
    			sokhIdSet.add(durfRec.Service_Order_Kit_Header__c);
    		}
			dealIdSet.add(durfRec.Deal__c);
    	}
    	if(dealIdSet.size() > 0) {
		    List<Deal__c> dealList = [Select Id, Is_Deal_Fulfilled__c, (Select Deal__c from Deal_Unresolved_Fulfillments__r where Is_Resolved__c = false), 
    				(Select Id, Option_And_Fee_Status__c from Deal_Items__r where Option_And_Fee_Status__c !=: Constants.UNCOMIITTED), 
    				(Select Id from CO_Line_Items__r where Id NOT IN: coliIdSet Limit 1), (Select Id from Service_Order_Line_Items__r where Id NOT IN: soliIdSet Limit 1), 
    				(Select Id from CO_Kit_Headers__r where Id NOT IN: cokhIdSet Limit 1), (Select Id from Service_Order_Kit_Headers__r where Id NOT IN: sokhIdSet Limit 1) 
    				from Deal__c where Id IN: dealIdSet];
		    if(dealList.size() > 0) {
		    	List<Deal__c> dealListToUpdate = new List<Deal__c>();
		    	List<Deal_Item__c> dealItemListToUpdate = new List<Deal_Item__c>();
		    	for(Deal__c dealRec : dealList) {
		    		if(dealRec.CO_Line_Items__r.size() == 0 && dealRec.Service_Order_Line_Items__r.size() == 0 && dealRec.Deal_Unresolved_Fulfillments__r.size() == 0) {
		    			if(dealRec.Is_Deal_Fulfilled__c) {
		    				dealListToUpdate.add(new Deal__c(Id = dealRec.Id, Is_Deal_Fulfilled__c = false));
		    			}
		    			for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
		    				dealItemListToUpdate.add(new Deal_Item__c(Id = dealItemRec.Id, Option_And_Fee_Status__c = Constants.UNCOMIITTED));
		    			}
		    		}
		    	}
		    	if(dealListToUpdate.size() > 0) {
		    		if(AccessControl.ifObjectFieldIsUpdateable('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		    		update dealListToUpdate;
		    	}
		    	if(dealItemListToUpdate.size() > 0) {
		    		if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		    		update dealItemListToUpdate;
		    	}
		    }
    	}
    }
}