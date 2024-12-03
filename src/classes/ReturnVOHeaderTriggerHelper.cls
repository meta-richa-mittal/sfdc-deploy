public without sharing class ReturnVOHeaderTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    public static List<Return_VO_Header__c> returnVONewList = new List<Return_VO_Header__c>();
    public static List<Return_VO_Header__c> returnVOOldList = new List<Return_VO_Header__c>();
    public static Map<Id, Return_VO_Header__c> returnVONewMap = new Map<Id, Return_VO_Header__c>();
    public static Map<Id, Return_VO_Header__c> returnVOOldMap = new Map<Id, Return_VO_Header__c>();

    public static void beforeUpdateCalculation() {
        Set<String> partiallyCreditedRVOIdSet = new Set<String>();
    	for(Return_VO_Header__c rvoHeaderRec: returnVONewList) {
            if(rvoHeaderRec.Status__c != returnVOOldMap.get(rvoHeaderRec.Id).Status__c) {
                if(rvoHeaderRec.Status__c == 'Approved') {
                    rvoHeaderRec.Credits_Pending__c = rvoHeaderRec.SubTotal__c;
                } else if(rvoHeaderRec.Status__c == 'Partially Credited') {
                    partiallyCreditedRVOIdSet.add(rvoHeaderRec.Id);
                    rvoHeaderRec.Credits_Pending__c = 0;
                } else {
                    rvoHeaderRec.Credits_Pending__c = 0;
                }
            }   
        }

        if(!partiallyCreditedRVOIdSet.isEmpty()) {
            List<Return_VO_Line_Item__c> rvoliList = [SELECT Item_Cost__c, Return_Qty__c, Return_VO_Header__c FROM Return_VO_Line_Item__c WHERE Return_VO_Header__c IN :partiallyCreditedRVOIdSet
                                                        AND Credit_Status__c = 'Pending'];
            for(Return_VO_Line_Item__c rvoliRec: rvoliList) {
                returnVONewMap.get(rvoliRec.Return_VO_Header__c).Credits_Pending__c += ((rvoliRec.Item_Cost__c != null ? rvoliRec.Item_Cost__c : 0) * (rvoliRec.Return_Qty__c != null ? rvoliRec.Return_Qty__c : 0));
            }
        }
    }
}