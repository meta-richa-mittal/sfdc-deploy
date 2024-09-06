/** 
* Author: Tarun Khandelwal
* Since: Aug 29, 2019 
* Name: AccountTypeCtrl 
* Description: Apex btach class to create location based on Part Location__c field
**/
global without sharing class CreateLocationsBasedOnPartLocationBatch implements Database.Batchable<sobject>, Database.Stateful {
    
    public Set<String> locationsToCreateSet = new Set<String>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(!AccessControl.ifObjectFieldIsAccessible('Part__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        String baseQuery = 'SELECT Assigned_Location_1__c, Assigned_Location_2__c, Location__c FROM Part__c WHERE Location__c != null';
        return Database.getQueryLocator(baseQuery);
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        for(Part__c partRec : partList) {
            List<String> existingLocationList = new List<String>();
            for(String location : partRec.Location__c.split(';')) {
                existingLocationList.addAll(location.split(','));
            }
            locationsToCreateSet.addAll(existingLocationList);
            
            List<String> locationStrListForFields = TagUtil.convertTagListIntoTagString(existingLocationList);
            if(locationStrListForFields.size() == 2) {
                partRec.Assigned_Location_1__c = locationStrListForFields[0];
                partRec.Assigned_Location_2__c = locationStrListForFields[1];
            }
        }
        if(partList.size() > 0) {
            BPScriptUtility.disbaleTrigger('PartTrigger');
            update partList;
            BPScriptUtility.enableTrigger('PartTrigger');
        }
    }
    
    global void finish(Database.batchableContext bc) {
        locationsToCreateSet.remove(null);
        if(locationsToCreateSet.size() > 0) {
            List<Location__c> locationList = new List<Location__c>();
            for(String locationName : locationsToCreateSet) {
                locationList.add(new Location__c(Name__c = locationName, Active__c = true));
            }
            Database.insert(locationList, false);
        }
    }
}