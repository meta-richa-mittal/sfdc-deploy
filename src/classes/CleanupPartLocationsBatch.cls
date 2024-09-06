global without sharing class CleanupPartLocationsBatch implements Database.Batchable<sobject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT id, Assigned_Locations__c, Assigned_Location_1__c, Assigned_Location_2__c FROM Part__c WHERE Assigned_Locations__c != null '
        );
    }
    public void execute(Database.BatchableContext bc, List<Part__c> partList){
        if(partList.size() > 0) {
            for(Part__c part : partList) {
                if(part.Assigned_Location_1__c == ';' || part.Assigned_Location_1__c == ';;') {
                    part.Assigned_Location_1__c = null;
                } else if(part.Assigned_Location_1__c == ';"";') {
                    part.Assigned_Location_1__c = null;
                } else if(part.Assigned_Location_1__c != null && part.Assigned_Location_1__c.contains(';;')) {
                    part.Assigned_Location_1__c = part.Assigned_Location_1__c.replace(';;', ';');
                }
                if(part.Assigned_Location_2__c == ';' || part.Assigned_Location_2__c == ';;') {
                    part.Assigned_Location_2__c = null;
                } else if(part.Assigned_Location_2__c == ';"";') {
                    part.Assigned_Location_2__c = null;
                } else if(part.Assigned_Location_2__c != null && part.Assigned_Location_2__c.contains(';;')) {
                    part.Assigned_Location_2__c = part.Assigned_Location_2__c.replace(';;', ';');
                }
            }
            update partList;
        }    
    }

    public void finish(Database.batchableContext bc) {
    
    }
}