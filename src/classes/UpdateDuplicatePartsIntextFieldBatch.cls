global without sharing class UpdateDuplicatePartsIntextFieldBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('Select Part_Number__c from Part__c Where Publish_In_Feeds__c = true Order By Part_Number__c ASC');
    }
    
    global void execute(Database.BatchableContext BC, List<Part__c> partList){
        
        Set<String> partNumberSet = getPartNumberSet(partList);
       
        //Get the duplicate part records
        List<Part__c> duplicatePartList = [Select Part_Number__c, Is_Duplicate__c from Part__c where Part_Number__c IN: partNumberSet AND Id Not In: partList AND Publish_In_Feeds__c = true Order By Part_Number__c ASC];
        duplicatePartList.addAll(partList);
        
        //Map contains Part numbers as Key and Id as values
        Map<String, Set<String>> partNumberToPartIdSetMap = new Map<String, Set<String>> ();
        for(Part__c partRecords : duplicatePartList){
            if(!partNumberToPartIdSetMap.containsKey(partRecords.Part_Number__c)){
                partNumberToPartIdSetMap.put(partRecords.Part_Number__c,new set<String>());
            }
            partNumberToPartIdSetMap.get(partRecords.Part_Number__c).add(partRecords.id);
        }
        
        //List contains the duplicate part number records
        List<Part__c> duplicatePartListToUpdate = new List<Part__c>();
        for(String partNumber : partNumberToPartIdSetMap.keySet()){
            if(partNumberToPartIdSetMap.get(partNumber).size()>1){
                for(String partId : partNumberToPartIdSetMap.get(partNumber)){
                    Part__c partRec = new Part__c(Id = partId, Is_Duplicate__c = true);
                    duplicatePartListToUpdate.add(partRec);
                }
            } else{
                Part__c partRec = new Part__c(Id = (new list<string>(partNumberToPartIdSetMap.get(partNumber)))[0] , Is_Duplicate__c = false);
                duplicatePartListToUpdate.add(partRec);
            }
        }
        PartTriggerHelper.isForceStopTrigger = true;
        database.update(duplicatePartListToUpdate, false);
        PartTriggerHelper.isForceStopTrigger = false;
    }

    global void finish(Database.BatchableContext BC) {
        //Log Generate Code
    }
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateDuplicatePartsIntextFieldBatch(), 2000);
    }

    private Set<String> getPartNumberSet(List<Part__c> partList){
        Set<String> partNumberSet = new Set<String>();
       
        //Get all the unique part numbers
        for(Part__c partRec : partList){
            partNumberSet.add(partRec.Part_Number__c);
        }
        partNumberSet.remove(null);
        return partNumberSet;
    }
}