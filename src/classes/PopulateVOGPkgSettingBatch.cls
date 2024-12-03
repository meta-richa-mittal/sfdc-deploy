global without sharing class PopulateVOGPkgSettingBatch extends PostInstallScriptBaseBatch {
    global PopulateVOGPkgSettingBatch() {
        this.scriptName = 'executePopulateVOGPkgSettingBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id FROM Part__c';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> partList) {
        List<Vendor_Order_Line_Item_Group__c> vogList = [SELECT Id, Is_Packaged_Part__c, Is_Order_Lot__c, Package_Qty__c, Package_Unit__c, Order_Lots__c, Part__r.Packaged_Part__c, Part__r.Is_OrderLot__c, Part__r.Package_Qty__c, Part__r.Package_Unit__c, Part__r.Order_Lots__c  FROM Vendor_Order_Line_Item_Group__c WHERE Part__c IN :partList];
        List<Vendor_Receiving_Group__c> vrgList = [SELECT Id, Is_Packaged_Part__c, Is_Order_Lot__c, Package_Qty__c, Package_Unit__c, Order_Lots__c, Part__r.Packaged_Part__c, Part__r.Is_OrderLot__c, Part__r.Package_Qty__c, Part__r.Package_Unit__c, Part__r.Order_Lots__c  FROM Vendor_Receiving_Group__c WHERE Part__c IN :partList];

        for(Vendor_Order_Line_Item_Group__c vogRec : vogList) {
            vogRec.Is_Packaged_Part__c = vogRec.Part__r.Packaged_Part__c;
            vogRec.Is_Order_Lot__c = vogRec.Part__r.Is_OrderLot__c;
            vogRec.Package_Qty__c = vogRec.Part__r.Package_Qty__c;
            vogRec.Package_Unit__c = vogRec.Part__r.Package_Unit__c;
            vogRec.Order_Lots__c = vogRec.Part__r.Order_Lots__c;
        }
        
        for(Vendor_Receiving_Group__c vrgRec : vrgList) {
            vrgRec.Is_Packaged_Part__c = vrgRec.Part__r.Packaged_Part__c;
            vrgRec.Is_Order_Lot__c = vrgRec.Part__r.Is_OrderLot__c;
            vrgRec.Package_Qty__c = vrgRec.Part__r.Package_Qty__c;
            vrgRec.Package_Unit__c = vrgRec.Part__r.Package_Unit__c;
            vrgRec.Order_Lots__c = vrgRec.Part__r.Order_Lots__c;
        }


        VendorOrderLineItemGroupTriggerHelper.isForceStopTrigger = true;
        VendorReceivingGroupTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSObjectList('Vendor_Order_Line_Item_Group__c', vogList);
        DMLUtility.updateSObjectList('Vendor_Receiving_Group__c', vrgList);
        VendorReceivingGroupTriggerHelper.isForceStopTrigger = false;
        VendorOrderLineItemGroupTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}
}