/**
 * Author: Balveer Choudhary
 * Since: Jun 13, 2022
 * Name: ConvertTempUnitsIntoORDUUnitsBatch
 * Description: Batch for converting Temp units into Order units and add back to deal
**/
global without sharing class ConvertTempUnitsIntoORDUUnitsBatch extends PostInstallScriptBaseBatch{    
    global ConvertTempUnitsIntoORDUUnitsBatch() {
        this.scriptName = 'executeConvertTempUnitsIntoORDUUnitsBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id FROM Deal_Item__c WHERE Unit_Type__c = \'Temporary unit\' AND Unit_Status__c = \'Temporary\' AND Deal__c != null And Type__c = \'Unit\' And Unit_Make__c != null';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> dealItemList) {
        dealItemList = Database.query('SELECT Id, Colour__c, Unit_Make__c, Unit_Model__c, Sub_Model__c, Year__c, Deal__c, Taxable__c, Applicable_Tax__c, (SELECT Id, Item_Description__c, Type__c, Qty__c, Price__c, Total_Price__c, Cost__c, Total_Cost__c, Factory_Option__c FROM Deal_Unit_Prices_Costs__r) FROM Deal_Item__c WHERE Id IN :dealItemList');
        List<Customer_Owned_Unit__c> orderUnitListToInsert = new List<Customer_Owned_Unit__c>();
        Map<Id, Deal_Item__c> dealItemIdToRecMap = new Map<Id, Deal_Item__c>();
        Map<Id, Customer_Owned_Unit__c> dealItemIdToUnitRecMap = new Map<Id, Customer_Owned_Unit__c>();

        for(Deal_Item__c dealItem : (List<Deal_Item__c>)dealItemList) {
            Customer_Owned_Unit__c orderUnitRec = createORDUFromTempUnitWithUPC(dealItem);
            dealItemIdToRecMap.put(dealItem.Id, dealItem);
            dealItemIdToUnitRecMap.put(dealItem.Id, orderUnitRec);
        }

        for(Id dealItemId : dealItemIdToUnitRecMap.keySet()) {
            orderUnitListToInsert.add(dealItemIdToUnitRecMap.get(dealItemId));
        }

        // Insert Newly created Order units from temporary units
        CustomerOwnedUnitTriggerHelper.forcefullyRunPopulateUnitIdLogic = true;
        DMLUtility.insertSobjectList('Customer_Owned_Unit__c', orderUnitListToInsert);

        // Populate Unit Lookup on Deal Item and Create UPCs for Unit From Deal UPCs
        updateDealItemAndCreateUPCFromDUPC(dealItemIdToRecMap, dealItemIdToUnitRecMap);
    }

    public void updateDealItemAndCreateUPCFromDUPC(Map<Id, Deal_Item__c> dealItemIdToRecMap, Map<Id, Customer_Owned_Unit__c> dealItemIdToUnitRecMap) {
        Map<Id, Unit_Price_Cost__c> dealUPCIdToUPCMap = new Map<Id, Unit_Price_Cost__c>();
        Map<Id, Deal_Unit_Price_Cost__c> dealUPCIdToDealUPCRecMap = new Map<Id, Deal_Unit_Price_Cost__c>();
        List<Deal_Item__c> dealItemListToUpdate = new List<Deal_Item__c>();

        for(Id dealItemId : dealItemIdToRecMap.keySet()) {
            dealUPCIdToUPCMap.putAll(createUPCFromDealUPCForORDU(dealItemIdToRecMap.get(dealItemId).Deal_Unit_Prices_Costs__r, String.valueOf(dealItemIdToUnitRecMap.get(dealItemId).Id)));
            dealItemIdToRecMap.get(dealItemId).Customer_Owned_Unit__c = dealItemIdToUnitRecMap.get(dealItemId).Id;
            dealItemIdToRecMap.get(dealItemId).Colour__c = null;
            dealItemIdToRecMap.get(dealItemId).Unit_Make__c = null;
            dealItemIdToRecMap.get(dealItemId).Unit_Model__c = null;
            dealItemIdToRecMap.get(dealItemId).Year__c = null;
            dealItemIdToRecMap.get(dealItemId).Sub_Model__c = null; 
            dealItemListToUpdate.add(dealItemIdToRecMap.get(dealItemId));
            for(Deal_Unit_Price_Cost__c dealUPCRec : dealItemIdToRecMap.get(dealItemId).Deal_Unit_Prices_Costs__r) {
                dealUPCIdToDealUPCRecMap.put(dealUPCRec.Id, dealUPCRec);
            }
        }

        // insert UPCs and populate on Deal UPC
        updateDealUPCAndInsertUPC(dealUPCIdToUPCMap, dealUPCIdToDealUPCRecMap);
        DMLUtility.updateSobjectList('Deal_Item__c', dealItemListToUpdate);
    }

    public void updateDealUPCAndInsertUPC(Map<Id, Unit_Price_Cost__c> dealUPCIdToUPCMap, Map<Id, Deal_Unit_Price_Cost__c> dealUPCIdToDealUPCRecMap) {
        List<Unit_Price_Cost__c> UPCListToInsert = new List<Unit_Price_Cost__c>();
        List<Deal_Unit_Price_Cost__c> dealUPCListToUpdate = new List<Deal_Unit_Price_Cost__c>();
        Set<Id> unitIdSet = new Set<Id>();

        for(Id DealUPCId : DealUPCIdToUPCMap.keySet()) {
            UPCListToInsert.add(DealUPCIdToUPCMap.get(DealUPCId));
            if(DealUPCIdToUPCMap.get(DealUPCId).Customer_Owned_Unit__c != null) {
				unitIdSet.add(DealUPCIdToUPCMap.get(DealUPCId).Customer_Owned_Unit__c);	
			}
        }
        DMLUtility.insertSobjectList('Unit_Price_Cost__c', UPCListToInsert);
        UnitPriceAndCostTriggerHelper.updateUnitList(unitIdSet);
        
        for(Id DealUPCId : DealUPCIdToUPCMap.keySet()) {
            dealUPCIdToDealUPCRecMap.get(DealUPCId).Unit_Price_Cost__c = DealUPCIdToUPCMap.get(DealUPCId).Id;
            dealUPCListToUpdate.add(dealUPCIdToDealUPCRecMap.get(DealUPCId));
        }
        DMLUtility.updateSobjectList('Deal_Unit_Price_Cost__c', dealUPCListToUpdate);
    }

    public Customer_Owned_Unit__c createORDUFromTempUnitWithUPC(Deal_Item__c dealItem) {
        Customer_Owned_Unit__c orderUnitRec = new Customer_Owned_Unit__c();
        orderUnitRec.Colour__c = dealItem.Colour__c;
        orderUnitRec.Unit_Make__c = dealItem.Unit_Make__c;
        orderUnitRec.Unit_Model__c = dealItem.Unit_Model__c;
        orderUnitRec.Sub_Model__c = dealItem.Sub_Model__c;
        orderUnitRec.Year__c = dealItem.Year__c;
        orderUnitRec.Unit_Type__c = 'ORDU';
        orderUnitRec.Status__c  = 'Temporary'; 
        orderUnitRec.Taxable__c = dealItem.Taxable__c;
        orderUnitRec.Applicable_Tax__c = dealItem.Applicable_Tax__c;
        return orderUnitRec;
    }

    public Map<Id, Unit_Price_Cost__c> createUPCFromDealUPCForORDU(List<Deal_Unit_Price_Cost__c> dealUPCList, Id unitId) {
        Map<Id, Unit_Price_Cost__c> DealUPCIdToUPCMap = new Map<Id, Unit_Price_Cost__c>();
        for(Deal_Unit_Price_Cost__c dealUPC : dealUPCList) {
            Unit_Price_Cost__c unitPriceCostRec = new Unit_Price_Cost__c();
            unitPriceCostRec.Customer_Owned_Unit__c = unitId; 
            unitPriceCostRec.Item_Description__c = dealUPC.Item_Description__c;
            unitPriceCostRec.Type__c = dealUPC.Type__c;
            unitPriceCostRec.Qty__c = dealUPC.Qty__c;
            unitPriceCostRec.Price__c = dealUPC.Price__c;
            unitPriceCostRec.Total_Price__c = dealUPC.Total_Price__c;
            unitPriceCostRec.Cost__c = dealUPC.Cost__c;
            unitPriceCostRec.Total_Cost__c = dealUPC.Total_Cost__c;
            unitPriceCostRec.Factory_Option__c = dealUPC.Factory_Option__c;
            DealUPCIdToUPCMap.put(dealUPC.Id, unitPriceCostRec);
        }
        return DealUPCIdToUPCMap;
    }

    global override void finishScript(Database.BatchableContext bc) {}
}