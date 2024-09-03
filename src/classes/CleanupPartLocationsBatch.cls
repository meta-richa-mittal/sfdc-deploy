global without sharing class CleanupPartLocationsBatch implements Database.Batchable<sobject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT id, Assigned_Locations__c, Assigned_Location_1__c, Assigned_Location_2__c FROM Part__c WHERE (Assigned_Location_1__c != null OR Assigned_Location_2__c  != null) '
        );
    }
    public void execute(Database.BatchableContext bc, List<Part__c> partList){
        List<Part__c> partListToUpdate = new List<Part__c>();
        Boolean isPartUpdatable;
        for(Part__c part : partList) {
            isPartUpdatable = false;
            if(part.Assigned_Location_1__c == ';' || part.Assigned_Location_1__c == ';;' || part.Assigned_Location_1__c == ';"";') {
                part.Assigned_Location_1__c = null;
                isPartUpdatable = true;
            } else if(part.Assigned_Location_1__c != null && part.Assigned_Location_1__c.contains(';;')) {
                part.Assigned_Location_1__c = part.Assigned_Location_1__c.replace(';;', ';');
                isPartUpdatable = true;
            }
            if(part.Assigned_Location_2__c == ';' || part.Assigned_Location_2__c == ';;' || part.Assigned_Location_2__c == ';"";') {
                part.Assigned_Location_2__c = null;
                isPartUpdatable = true;
            } else if(part.Assigned_Location_2__c != null && part.Assigned_Location_2__c.contains(';;')) {
                part.Assigned_Location_2__c = part.Assigned_Location_2__c.replace(';;', ';');
                isPartUpdatable = true;
            }
            if(isPartUpdatable == true) { partListToUpdate.add(part); }
        }
        PartTriggerHelper.isForceStopTrigger = true;
        if(partListToUpdate.size() > 0) { update partListToUpdate; }
        PartTriggerHelper.isForceStopTrigger = false;
    }

    public void finish(Database.batchableContext bc) {
    
    }
}
