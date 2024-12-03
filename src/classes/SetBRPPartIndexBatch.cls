/** 
* Author: Manoj Sharma
* Since: June 20, 2020 
* Name: SetBRPPartIndexBatch 
* Description: Apex class to set part index on brp parts.
**/
global without sharing class SetBRPPartIndexBatch implements Database.Batchable<sobject>, Database.Stateful {
  
    public Integer partIndex;
    private Boolean hasPartLineItemPresent = false;
    public Boolean isExecutePartInvBatch = false;
    public Set<String> brpVendorsIdSet;
    public Date exportDate;
    
    global SetBRPPartIndexBatch(Integer partIndex) {
      this.partIndex = partIndex;
      this.exportDate = System.today();
    }
    
    global SetBRPPartIndexBatch(Integer partIndex, Date exportDate) {
        this.partIndex = partIndex;
        this.exportDate = exportDate;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
        String strQuery = 'SELECT Name, BRP_Part_Index__c FROM Part__c WHERE BRP_Part_Index__c != 1 AND Vendor__c IN :brpVendorsIdSet  ORDER BY Name ASC';
        return Database.getQueryLocator(strQuery); 
    }
      
    public Integer getNumberOfRecPerBatch() {
        Integer totalParts = 0;
        List<AggregateResult> aggList = [Select Count(Id) totalParts from Part__c WHERE Vendor__c IN :brpVendorsIdSet];
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
            part.BRP_Part_Index__c = this.partIndex ;
        }
        PartTriggerHelper.isForceStopTrigger = true;
        update partList;
        PartTriggerHelper.isForceStopTrigger = false;
        this.hasPartLineItemPresent = true;
      }
      
    global void finish(Database.batchableContext bc) {
        if(this.hasPartLineItemPresent) {
            Database.executeBatch(new SetBRPPartIndexBatch(this.partIndex), 2000);
        } else if(isExecutePartInvBatch) {
            Database.executeBatch(new DisableFlagOnPartForBRP(this.exportDate), 2000);
        }
    }
}