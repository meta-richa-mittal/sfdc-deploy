global without sharing class DP360ScriptUtil {
    
    global static void syncAvailableStockUnitsToDP360() {
        setFlagForAllStockUnits();
        setFlagForAllOrderedUnits();
        Database.executeBatch(new DP360InventoryBatch(), 10);
    }
    
    global static void setFlagForAllStockUnits() {
        List<Customer_Owned_Unit__c> stockUnitList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' AND Status__c = 'Available'
                                                        AND DP360_Inventory_Id__c = null AND Available_For_DP360_Sync__c = false];
        for(Customer_Owned_Unit__c skuUnit : stockUnitList) {
            skuUnit.Available_For_DP360_Sync__c = true;
        }
        if(stockUnitList.size() > 0) {
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
            update stockUnitList;
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    global static void setFlagForAllOrderedUnits() {
        List<Customer_Owned_Unit__c> orderedUnitList = [SELECT Id FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'ORDU' AND Status__c = 'On Order'
                                                        AND DP360_Inventory_Id__c = null AND Available_For_DP360_Sync__c = false];
        for(Customer_Owned_Unit__c orderedUnit : orderedUnitList) {
            orderedUnit.Available_For_DP360_Sync__c = true;
        }
        if(orderedUnitList.size() > 0) {
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
            update orderedUnitList;
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
        }
    }
}