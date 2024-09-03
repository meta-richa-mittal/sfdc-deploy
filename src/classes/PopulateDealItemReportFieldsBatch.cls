/**
 * Author: Nidhi Sharma
 * Since: Aug 31, 2023
 * Name: PopulateDealItemReportFieldsBatch
 * Description: Batch for Populating fields on deal item
**/
global without sharing class PopulateDealItemReportFieldsBatch extends PostInstallScriptBaseBatch {

    global PopulateDealItemReportFieldsBatch() {
        this.scriptName = 'executePopulateDealItemReportFieldsBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Type__c, Actual_Cash_Value__c, Customer_Owned_Unit__r.Total_Cost__c, ' +
        '(Select Id, Type__c, Qty__c, Price__c FROM Deal_Unit_Prices_Costs__r WHERE Price__c != null AND Price__c != 0 AND Type__c != null), ' +
        '(SELECT Id, Qty__c, Cost__c, Price__c, Deal_Kit_Header__c, CO_Line_Item__c, Service_Order_Line_Item__c, Status__c, ' +
        'Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c, Product__r.Type__c, Product__r.Cost__c, Product__r.Cost_Method__c, ' +
        'Part__r.Average_Cost__c, Part__r.Last_Cost__c, Fee__r.Cost_Rate__c, Fee__r.Cost_Method__c, Fee__r.Is_Include_In_Profit_Calculation__c ' +
        'FROM Options_Fees__r WHERE Price__c != null AND Price__c != 0) FROM Deal_Item__c WHERE Type__c != null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealItemRecList) {
        for(Deal_Item__c dealItemRec : (List<Deal_Item__c>) dealItemRecList) {
            if(dealItemRec.Type__c.equalsIgnoreCase('Unit')) {
                dealItemRec.Part_Total__c = dealItemRec.Fee_Total__c = dealItemRec.Labour_Total__c = dealItemRec.Warranty_Product_Total__c = 
                dealItemRec.Sublet_Total__c = dealItemRec.Other_Product_Total__c = dealItemRec.Base_Price__c = dealItemRec.Factory_Option_Total__c = 
                dealItemRec.Dealer_Option_Total__c = dealItemRec.Unit_Option_Cost__c = 0;

                dealItemRec.Unit_Cost__c = (dealItemRec.Customer_Owned_Unit__r.Total_Cost__c != null ? dealItemRec.Customer_Owned_Unit__r.Total_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0);
                
                for(Deal_Unit_Price_Cost__c dupcRec : dealItemRec.Deal_Unit_Prices_Costs__r) {	    			
	    			dupcRec.Qty__c = (dupcRec.Qty__c != null && dupcRec.Qty__c != 0) ? dupcRec.Qty__c : 1;
	    			
    				Decimal price = (dupcRec.Price__c * dupcRec.Qty__c).setScale(2, RoundingMode.HALF_UP);
                    if(dupcRec.Type__c == 'Base') {
	    				dealItemRec.Base_Price__c += price;
	    			} else if(dupcRec.Type__c == 'Factory') {
	    				dealItemRec.Factory_Option_Total__c += price;
	    			} else if(dupcRec.Type__c == 'Dealer') {
	    				dealItemRec.Dealer_Option_Total__c += price;
	    			}
                }
                for(Option_Fee__c ofRec : dealItemRec.Options_Fees__r) {
                    ofRec.Qty__c = (ofRec.Qty__c != null) ? ofRec.Qty__c : 0;
                    
                    dealItemRec.Unit_Option_Cost__c += OptionAndFeeTriggerHelper.getOptionAndFeeCost(ofRec);

                    Decimal price = (ofRec.Qty__c * ofRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                    if(ofRec.Part__c != null) {
                        dealItemRec.Part_Total__c += price;
                    } else if(ofRec.Labour_Code__c != null) {
                        dealItemRec.Labour_Total__c += price;
                    } else if(ofRec.Fee__c != null) {
                        dealItemRec.Fee_Total__c += price;
                    } else if(ofRec.Product__c != null) {
                        if(ofRec.Product__r.Type__c == Constants.WARRANTY_PLAN) {
                            dealItemRec.Warranty_Product_Total__c += price;
                        } else if(ofRec.Product__r.Type__c == Constants.SUBLET) {
                            dealItemRec.Sublet_Total__c += price;
                        } else {
                            dealItemRec.Other_Product_Total__c += price;
                        }
                    }
                }
            } else if(dealItemRec.Type__c.equalsIgnoreCase('Trade In')) {
                dealItemRec.Unit_Cost__c = -1 * (dealItemRec.Actual_Cash_Value__c != null ? dealItemRec.Actual_Cash_Value__c.setScale(2, RoundingMode.HALF_UP) : 0);
            }
        }
		DealItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal_Item__c', dealItemRecList);
        DealItemTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}