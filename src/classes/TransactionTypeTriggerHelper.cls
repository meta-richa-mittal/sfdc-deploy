public without sharing class TransactionTypeTriggerHelper {
    
    public static List<Transaction_Type__c> transTypeNewList = new List<Transaction_Type__c>();
    public static List<Transaction_Type__c> transTypeOldList = new List<Transaction_Type__c>();
    
    public static void validateBeforeUpsert(){
        Set<String> codeLabelSet = new Set<String>();
        Map<Id, String> ttIdToNameMap = new Map<Id, String>();
        for(Transaction_Type__c ttRec: transTypeNewList){
            if(String.isBlank(ttRec.Id) && ttRec.Code_Label__c != null){
                codeLabelSet.add(ttRec.Code_Label__c);
            }
            if(ttRec.Id != null){
                ttIdToNameMap.put(ttRec.Id, ttRec.Code_Label__c);
            }
        }
        if(!codeLabelSet.isEmpty()) {
            List<Transaction_Type__c> existingTTList = [Select Id From Transaction_Type__c where Code_Label__c In: codeLabelSet];
            if(!existingTTList.isEmpty()) { throw new BlackPurlException('Duplicate code name'); }
        }
        if(!ttIdToNameMap.isEmpty()) {
            List<Transaction_Type__c> existingTTwithSameNameList = [Select Id, Code_Label__c From Transaction_Type__c where Code_Label__c In: ttIdToNameMap.values()];
            for(Transaction_Type__c ttRec: existingTTwithSameNameList){
                if(!ttIdToNameMap.containsKey(ttRec.Id)) { throw new BlackPurlException('Duplicate code name'); }
            }
        }
    }
}