global without sharing class SetSOMPartIndexBatch implements Database.Batchable<sobject>, Database.Stateful {
    
    public Integer partIndex;
    private Boolean hasPartLineItemPresent = false;
    
    global SetSOMPartIndexBatch(Integer partIndex) {
        this.partIndex = partIndex;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Name, Part_Index__c FROM Part__c WHERE Part_Index__c = null ORDER BY Name ASC limit ' + getNumberOfRecPerBatch();
        return Database.getQueryLocator(strQuery); 
    }
    
    public static Integer getNumberOfRecPerBatch() {
        Integer totalParts = 0;
        List<AggregateResult> aggList = [Select Count(Id) totalParts from Part__c WHERE Name != null];
        if(aggList.size() > 0) {
            totalParts = (Integer) aggList[0].get('totalParts');
        }
        
        Integer numberOfRecPerBatch = (totalParts / 5);
        if(Math.mod(totalParts, 5) != null && math.mod(totalParts, 5) > 0) {
            numberOfRecPerBatch += 1;
        }
        return numberOfRecPerBatch;
    }
    
    public static Integer getNumberOfRecPerBatchForFirstFourIndexes() {
        Integer totalParts = 0;
        List<AggregateResult> aggList = [Select Count(Id) totalParts from Part__c WHERE Part_Index__c < 5];
        if(aggList.size() > 0) {
            totalParts = (Integer) aggList[0].get('totalParts');
        }
        
        Integer numberOfRecPerBatch = (totalParts / 4);
        if(Math.mod(totalParts, 4) != null && math.mod(totalParts, 4) > 0) {
            numberOfRecPerBatch += 1;
        }
        return numberOfRecPerBatch;
    }
    
    public void execute(Database.batchableContext bc, List<Part__c> partList) {
        for(Part__c part : partList) {
            part.Part_Index__c = this.partIndex ;
        }
        SOMUtility.updatePartRecords(partList);
        this.hasPartLineItemPresent = true;
    }
    
    public void finish(Database.batchableContext bc) {
        if(this.hasPartLineItemPresent) {
            Database.executeBatch(new SetSOMPartIndexBatch(this.partIndex + 1), 2000);
        }
    }
}