/** 
* Author: Richa Mittal
* Since: Dec 07, 2020 
* Name: SetIntextPartIndexBatch 
* Description: Apex class to set part index on parts with Public_In_feed flag to true for intext file.
**/
global without sharing class SetIntextPartIndexBatch implements Database.Batchable<sobject>, Database.Stateful {
  
    public Integer partIndex;
    private Boolean hasPartLineItemPresent = false;
    public Boolean isExecutePartInvBatch = false;
    public Date exportDate;
    
    global SetIntextPartIndexBatch(Integer partIndex) {
      this.partIndex = partIndex;
      this.exportDate = System.today();
    }
    
    global SetIntextPartIndexBatch(Integer partIndex, Date exportDate) {
        this.partIndex = partIndex;
        this.exportDate = exportDate;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Name, Intext_Part_Index__c FROM Part__c WHERE Intext_Part_Index__c = null AND Publish_In_Feeds__c = true ORDER BY Name ASC limit '
        					 + getNumberOfRecPerBatch();
        return Database.getQueryLocator(strQuery); 
    }
      
    public Integer getNumberOfRecPerBatch() {
        Integer totalParts = 0;
        List<AggregateResult> aggList = [Select Count(Id) totalParts from Part__c WHERE Publish_In_Feeds__c = true];
        if(aggList.size() > 0) {
            totalParts = (Integer) aggList[0].get('totalParts');
        }
        
        Integer numberOfRecPerBatch = (totalParts / 5);
        if(Math.mod(totalParts, 5) != null && math.mod(totalParts, 5) > 0) {
            numberOfRecPerBatch += 1;
        }
        return numberOfRecPerBatch;
    }
      
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        for(Part__c part : partList) {
            part.Intext_Part_Index__c = this.partIndex ;
        }
        GenericExportUtil.updatePartRecords(partList, 0);
        this.hasPartLineItemPresent = true;
      }
      
    global void finish(Database.batchableContext bc) {
        if(this.hasPartLineItemPresent) {
            Database.executeBatch(new SetIntextPartIndexBatch(this.partIndex + 1), 2000);
        }
    }
}