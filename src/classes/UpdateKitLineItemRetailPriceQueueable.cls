/**
 * Author: Balveer Choudhary
 * Since: Aug 03, 2022
 * Name: UpdateKitLineItemRetailPriceQueueable
 * Description: Queueable apex for updating Kit Line Items pricing based on default price level
**/
global without sharing class UpdateKitLineItemRetailPriceQueueable implements Queueable {
    
    public Set<String> partIdSet = new Set<String>();

    global UpdateKitLineItemRetailPriceQueueable(){}

    global UpdateKitLineItemRetailPriceQueueable(Set<String> partIdSet1){
        this.partIdSet = partIdSet1;
    }

    private String getQueryString() {
        String strQuery = 'SELECT Fixed_Price__c, Is_Environmental_Fee__c, Kit_Header__c, Kit_Price__c, Labour_Code__c, Part__c, Retail__c, Fee__c, Retail_Price__c ' 
                        +' FROM Kit_Header_Line_Item__c WHERE (Part__c != null OR Labour_Code__c != null)';
        if(partIdSet.size() > 0) {
            strQuery += ' AND Part__c IN :partIdSet';
        }
        strQuery += ' ORDER BY Name ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return strQuery;
    }

    global void execute(QueueableContext context) {
        List<Kit_Header_Line_Item__c> kitLineItemList = (List<Kit_Header_Line_Item__c>) Database.query(getQueryString());
        KitLineItemtriggerHelper.setRetailPriceBasedOnDefaultPriceLevel(kitLineItemList);
        if(kitLineItemList.size() > 0){
            update kitLineItemList;
        }
    }
}