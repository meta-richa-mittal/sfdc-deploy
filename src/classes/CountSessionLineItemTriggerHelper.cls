/**
 * Author: Manoj Sharma
 * Since: Oct 27, 2020
 * Name: CountSessionLineItemTrigger
 * Description: 
**/
public without sharing class CountSessionLineItemTriggerHelper {
    public static Boolean isForceStopTrigger = false;

    public static void beforeInsertCalculation(List<Count_Session_Line_Item__c> countSessionLINewList) {
        setCountedFalseForIssueItem(countSessionLINewList);
    }

    public static void beforeUpdateCalculation(List<Count_Session_Line_Item__c> countSessionLINewList) {
        setCountedFlagForLineItem(countSessionLINewList);
    }

    private static void setCountedFalseForIssueItem(List<Count_Session_Line_Item__c> countSessionLINewList) {
        for(Count_Session_Line_Item__c csliRec : countSessionLINewList) {
            if(csliRec.Issue_Indicator__c != null) {
                csliRec.Is_Counted__c = false;
            }
        }
    }

    private static void setCountedFlagForLineItem(List<Count_Session_Line_Item__c> countSessionLINewList) {
        Set<String> partFIFOCSLIIdSet = new Set<String>();

		List<Part_FIFO_Bucket__c> partFIFOList = [SELECT Id, Count_Session_Line_Item__c FROM Part_FIFO_Bucket__c Where Count_Session_Line_Item__c IN: countSessionLINewList];
		List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOLIList = [SELECT Id, Count_Session_Line_Item__c FROM Part_FIFO_Bucket_Activity_Line_Item__c Where Count_Session_Line_Item__c IN: countSessionLINewList];
        
		for(Part_FIFO_Bucket__c partRec : partFIFOList) {
			partFIFOCSLIIdSet.add(partRec.Count_Session_Line_Item__c);
		}

		for(Part_FIFO_Bucket_Activity_Line_Item__c partLIRec : partFIFOLIList) {
			partFIFOCSLIIdSet.add(partLIRec.Count_Session_Line_Item__c);
        }
        
        for(Count_Session_Line_Item__c csliRec : countSessionLINewList) {
            if(csliRec.Issue_Indicator__c != null) {
                csliRec.Is_Counted__c = false;
            } else if(partFIFOCSLIIdSet.contains(csliRec.Id)){
                csliRec.Is_Counted__c = true;
            }
        }
    }
}