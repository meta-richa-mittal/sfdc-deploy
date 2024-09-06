global without sharing class DisableSOMFlagOnPartBatch implements Database.Batchable<sobject>, Database.Stateful {
    
    public Date fileDate;
    
    global DisableSOMFlagOnPartBatch(Date dateValue) {
        this.fileDate = dateValue != null ? dateValue : system.today();
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery = 'SELECT Is_Included_In_SOM__c FROM Part__c WHERE Is_Included_In_SOM__c = TRUE Order By Name ASC ';
        return Database.getQueryLocator(strQuery); 
    }
    
    public void execute(Database.batchableContext bc, List<Part__c> partList) {
        for(Part__c partRec : partList) {
            partRec.Is_Included_In_SOM__c = false;
        }
        SOMUtility.updatePartRecords(partList);
    }
    
    public void finish(Database.batchableContext bc) {
        SOMPartInventoryBatchManager.run(this.fileDate);
    }    
}