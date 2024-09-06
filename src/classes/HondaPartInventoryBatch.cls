/** 
* Author: Tarun Khandelwal
* Since: Dec 11, 2019
* Name: HondaPartInventoryBatch 
* Description: Batch class to send part invetory data file to honda server.
**/
global without sharing class HondaPartInventoryBatch implements Database.Batchable<sobject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	String hondaVendorCode = HondaUtility.getHondaVendorCode();
        String strQuery = 'SELECT Part_Number__c, CreatedDate, Qty_In_Stock__c FROM Part__c WHERE Qty_In_Stock__c > 0'; 
        
        strQuery += String.isNotBlank(hondaVendorCode) ? ' AND Vendor_Code__c = \'' + hondaVendorCode + '\'': ' AND Id = null';
        strQuery += ' Order By Part_Number__c ASC, Name ASC';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        if(HondaUtility.isHondaIntegrationEnabled()) {
            String body = System.JSON.serialize(new HondaPartInventoryWrapper(partList));
            HondaUtility.doCallout('Honda Part Inventory', body);
        }
    }
    
    global void execute(SchedulableContext sc) {
    	Database.executeBatch(new HondaPartInventoryBatch());
    }
    
    global void finish(Database.batchableContext bc) {}
    
    public class HondaPartInventoryWrapper {
        public String dealer_number;
        public String key;
        public List<PartWrapper> dealer_stock;
        
        public HondaPartInventoryWrapper(List<Part__c> partList) {
            this.dealer_number = HondaUtility.getDealerNumber();
            this.key = HondaUtility.getWebKeyNumber();
            this.dealer_stock = new List<PartWrapper>();
            for(Part__c partRec : partList) {
                dealer_stock.add(new PartWrapper(partRec));
            }
        }
    }  
    
    public class PartWrapper {
        public String product_number;
        public Integer quantity;
        
        public PartWrapper(Part__c partRec) {
            this.product_number = partRec.Part_Number__c;
            this.quantity = Integer.valueOf(partRec.Qty_In_Stock__c);
        }
    }
}