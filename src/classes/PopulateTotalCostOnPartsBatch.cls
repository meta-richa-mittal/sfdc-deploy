/**
 * Author: Richa Mittal
 * Since: Sept 04, 2020
 * Name: PopulateTotalCostOnPartsBatch
 * Description: Batch for Populating Total cost on part
**/
global without sharing class PopulateTotalCostOnPartsBatch implements Database.Batchable<sobject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Oversold_Qty__c, Oversold_Cost__c, Total_Cost__c, Average_Cost__c, '
        					+ '(Select id, Qty_In__c, Qty_Out__c, Total__c, Source_Name__c, Remaining_Qty__c from Part_FIFO_Buckets__r WHERE Is_FIFO_Bucket__c = true) '
        					+ 'FROM Part__c WHERE Qty_In_Stock__c > 0';
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        for(Part__c partRec : partList) {
			Decimal oversoldQty = 0;
			Decimal oversoldCost = 0;
			Decimal TotalCost = 0;
			Decimal QtyInStock = 0;
			for(Part_FIFO_Bucket__c partFIFOBucketRec : partRec.Part_FIFO_Buckets__r) {
				if(!String.isBlank(partFIFOBucketRec.Source_Name__c) && (partFIFOBucketRec.Source_Name__c.equalsIgnoreCase('Oversold') || partFIFOBucketRec.Remaining_Qty__c < 0)){
					oversoldQty += ((partFIFOBucketRec.Qty_In__c != null) ? partFIFOBucketRec.Qty_In__c : 0.00) - ((partFIFOBucketRec.Qty_Out__c != null) ? partFIFOBucketRec.Qty_Out__c : 0.00);
					oversoldCost += (partFIFOBucketRec.Total__c != null) ? partFIFOBucketRec.Total__c : 0.00;
				} else {
	    			TotalCost  += (partFIFOBucketRec.Total__c != null ) ? partFIFOBucketRec.Total__c : 0.00;
	    			QtyInStock += (partFIFOBucketRec.Remaining_Qty__c != null ) ? partFIFOBucketRec.Remaining_Qty__c : 0;
    			}
			}
			
			partRec.Oversold_Qty__c = oversoldQty < 0 ? -(oversoldQty) : oversoldQty;
			partRec.Oversold_Cost__c = oversoldCost < 0 ? -(oversoldCost) : oversoldCost;
			partRec.Total_Cost__c = TotalCost;
			
	        partRec.Average_Cost__c = (QtyInStock > 0) ? (TotalCost / QtyInStock) : 0.00;
		}
		PartTriggerHelper.isForceStopTrigger = true;
		update partList;
		PartTriggerHelper.isForceStopTrigger = false;
    }
    
    global void finish(Database.batchableContext bc) {
        
    }
}