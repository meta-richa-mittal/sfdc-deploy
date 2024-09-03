/**
 * Author: Nidhi Sharma
 * Since: Dec 19, 2022
 * Name: DFINProductCostFieldsUpdateBatch
 * Description: Batch for Populating cost fields on financing products
**/
global without sharing class DFINProductCostFieldsUpdateBatch extends PostInstallScriptBaseBatch {
    
	global DFINProductCostFieldsUpdateBatch() {
        this.scriptName = 'executeDFINProductCostFieldsUpdateBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Price__c, Vendor_Product__r.Cost_Method__c, Vendor_Product__r.Cost__c FROM F_I_Product__c WHERE Cost_Method__c = null AND Vendor_Product__r.Type__c = \'' + Constants.FINANCING_PRODUCT + '\'';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> fiProductList) {
    	for(F_I_Product__c fiProductRec : (List<F_I_Product__c>)fiProductList) {
			fiProductRec.Cost_Method__c = fiProductRec.Vendor_Product__r.Cost_Method__c;
            fiProductRec.Cost__c = fiProductRec.Vendor_Product__r.Cost__c;
            if(String.isNotBlank(fiProductRec.Cost_Method__c) && fiProductRec.Cost_Method__c.equalsIgnoreCase('Percent Retail')) {
                fiProductRec.Cost_Rate__c = (fiProductRec.Vendor_Product__r.Cost__c != null ? fiProductRec.Vendor_Product__r.Cost__c : 0);
                Decimal price = (fiProductRec.Price__c != null ? fiProductRec.Price__c : 0);
                fiProductRec.Cost__c = ((price * fiProductRec.Cost_Rate__c)/100).setScale(2, RoundingMode.HALF_UP);
            }
		}
        FIProductTriggerHelper.isForceStopTrigger = true;
		update fiProductList;
        FIProductTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}