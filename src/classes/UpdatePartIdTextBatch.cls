global without sharing class UpdatePartIdTextBatch implements Database.Batchable<sObject> {

    Set<Id> vendorIdSet = new Set<Id>();
    global UpdatePartIdTextBatch(Set<Id> vendorIdSet) {
        this.vendorIdSet = vendorIdSet;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Part_Id_Text__c, Part_Number__c, Vendor__c, Vendor__r.Vendor_Code__c FROM Part__c WHERE Vendor__c IN: vendorIdSet'
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Part__c> partList) {
        for(Part__c partRec : partList) {
            if(partRec.Vendor__r.Vendor_Code__c != null) {
                partRec.Part_Id_Text__c = partRec.Part_Number__c + partRec.Vendor__r.Vendor_code__c;
            }
        }
        if(partList.size() > 0) {
            Database.update(partList, false);
        }
    }
    
    global void finish(Database.BatchableContext bc) {}
}