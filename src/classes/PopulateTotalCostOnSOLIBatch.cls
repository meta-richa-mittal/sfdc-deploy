/**
 * Author: Richa Mittal
 * Since: Nov 02, 2020
 * Name: PopulateTotalCostOnSOLIBatch
 * Description: Batch for Populating Total cost on invoiced SOLI
**/
global without sharing class PopulateTotalCostOnSOLIBatch implements Database.Batchable<sobject> {
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Labour_Code__c, Part__c, Fee__c, Sublet__c, Kit_Price__c, Qty_Needed__c, Total_Cost__c, ' + 
    					'Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c, Fee__r.Is_Include_In_Profit_Calculation__c, ' + 
    					'Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c, Sublet__r.Cost_Method__c, Cost__c, Sublet__r.Cost__c, Service_Order_Header__r.Is_Technician_Hours_Costing_Enabled__c, ' + 
    					'(select Adjusted_Cost_Coli__c from CO_Line_Items__r) FROM Service_Order_Line_Item__c ' + 
    					'WHERE Service_Order_Header__r.Invoice_Number__c != null AND Service_Order_Header__r.Work_Status__c = \'Invoiced\' ' + 
    					'LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit(); // AND Total_Cost__c != null  ??
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Service_Order_Line_Item__c> soliList) {
        for(Service_Order_Line_Item__c soliRec : soliList) {
        	soliRec.Qty_Needed__c = (soliRec.Qty_Needed__c != null) ? soliRec.Qty_Needed__c : 0;
        	soliRec.Kit_Price__c = (soliRec.Kit_Price__c != null) ? soliRec.Kit_Price__c : 0;
    		Decimal cost = 0;
    		if(soliRec.Fee__c != null && soliRec.Fee__r.Is_Include_In_Profit_Calculation__c) {
    			//FEE & SHOP SUPPLIES COST
    			if(soliRec.Fee__r.Cost_Method__c == 'Fixed Cost' && soliRec.Fee__r.Cost_Rate__c != null && soliRec.Qty_Needed__c != null) {
                    cost = (soliRec.Qty_Needed__c * soliRec.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
                } else if(soliRec.Fee__r.Cost_Method__c == 'Percent Retail'  && soliRec.Fee__r.Cost_Rate__c !=null &&  soliRec.Qty_Needed__c !=null ){
                    cost = (soliRec.Qty_Needed__c * ((soliRec.Kit_Price__c * soliRec.Fee__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
                }
    		} else if(soliRec.Labour_Code__c != null) {
    			//already populated when job was complete
    			// LABOUR COST
    			if(soliRec.Service_Order_Header__r.Is_Technician_Hours_Costing_Enabled__c) {
    				soliRec.Total_Cost__c = ((soliRec.Total_Cost__c != null) ? soliRec.Total_Cost__c : 0);
        			cost = (soliRec.Total_Cost__c).setScale(2, RoundingMode.HALF_UP);
    			} else {
        			if(soliRec.Labour_Code__r.Cost_Method__c == 'Fixed Cost' && soliRec.Labour_Code__r.Cost_Rate__c != null && soliRec.Qty_Needed__c !=null){
	                    cost = (soliRec.Qty_Needed__c * soliRec.Labour_Code__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
	                } else if(soliRec.Labour_Code__r.Cost_Method__c == 'Percent Retail' && soliRec.Labour_Code__r.Cost_Rate__c !=null && soliRec.Qty_Needed__c !=null ){
	                    cost = (soliRec.Qty_Needed__c * ((soliRec.Kit_Price__c *  soliRec.Labour_Code__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
	                }
    			}
    		} else if(soliRec.Sublet__c != null) {
    			// SUBLET COST
    			if(soliRec.Cost__c != null) {
    				cost = (soliRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
    			} else if(soliRec.Sublet__r.Cost_Method__c == 'Fixed Cost' && soliRec.Sublet__r.Cost__c != null && soliRec.Qty_Needed__c !=null){
                    cost = (soliRec.Qty_Needed__c * soliRec.Sublet__r.Cost__c).setScale(2, RoundingMode.HALF_UP);
                } else if(soliRec.Sublet__r.Cost_Method__c == 'Percent Retail' && soliRec.Sublet__r.Cost__c !=null && soliRec.Qty_Needed__c !=null ){
                    cost = (soliRec.Qty_Needed__c * ((soliRec.Kit_Price__c *  soliRec.Sublet__r.Cost__c)/100)).setScale(2, RoundingMode.HALF_UP);
                }
    		} else if(soliRec.Part__c != null) {
    			for(CO_Line_Item__c coli : soliRec.CO_Line_Items__r) {
					cost += ((coli.Adjusted_Cost_Coli__c != null) ? coli.Adjusted_Cost_Coli__c : 0);
                }
    			
    		}
    		soliRec.Total_Cost__c = cost;
        }
        if(soliList.size() > 0) {
        	ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
            update soliList;
            ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
        }
    }
    
    global void finish(Database.batchableContext bc) {}
}