public without sharing class DP360InventoryService {
    
    public static void createUnitsInDP360(Set<Id> unitIdSet) {
        List<Customer_Owned_Unit__c> unitList = getUnits(unitIdSet);
        List<DP360InventoryWrapper> DP360InvObjList = getUnitsToSync(unitList);
        Map<String, Id> vinNumberToUnitSFIdMap = getVinNumberToUnitSFIdMap(unitList);
        Map<String, String> vinNumberToUnitIdMap = getVinNumberToUnitIdMap(unitList);
        
        String response = DP360Service.createUnit(System.JSON.serialize(DP360InvObjList));
        if(String.isNotBlank(response)) {
            handleCreateUnitResponse(response, vinNumberToUnitSFIdMap, vinNumberToUnitIdMap);
        }
    }
    
    public static void handleCreateUnitResponse(String response, Map<String, Id> vinNumberToUnitSFIdMap, Map<String, String> vinNumberToUnitIdMap) {
        List<Customer_Owned_Unit__c> unitListToUpdate = new List<Customer_Owned_Unit__c>();
        InventoryResultWapper resultObj = (InventoryResultWapper) System.JSON.deserialize(response, InventoryResultWapper.class);
        if(resultObj.data != null && (resultObj.data.AddedVins != null || resultObj.data.existingVins != null)) {
            List<String> vinNumberList = new List<String>();
            vinNumberList.addAll(resultObj.data.AddedVins);
            vinNumberList.addAll(resultObj.data.existingVins);
            
            for(String vinNumber : vinNumberList) {
                if(vinNumberToUnitSFIdMap.containsKey(vinNumber)) {
                    unitListToUpdate.add(new Customer_Owned_Unit__c(Id = vinNumberToUnitSFIdMap.get(vinNumber), 
                                           DP360_Inventory_Id__c = vinNumberToUnitIdMap.get(vinNumber), Available_For_DP360_Sync__c = false));
                }
            }
        } else {
            //system.assert(false, 'does not contain'+responseDataMap);
        }
        if(unitListToUpdate.size() > 0) {
            update unitListToUpdate;
        }
    }
    
    public static List<DP360InventoryWrapper> getUnitsToSync(List<Customer_Owned_Unit__c> unitList) {
        List<DP360InventoryWrapper> DP360InvObjList = new List<DP360InventoryWrapper>();
        for(Customer_Owned_Unit__c unit : unitList) {
            DP360InvObjList.add(new DP360InventoryWrapper(unit, DP360Service.getDealerId()));
        }
        return DP360InvObjList;
    }
    
    public static Map<String, Id> getVinNumberToUnitSFIdMap(List<Customer_Owned_Unit__c> unitList) {
        Map<String, Id> vinNumberToUnitSFIdMap = new Map<String, Id>();
        for(Customer_Owned_Unit__c unit : unitList) {
            vinNumberToUnitSFIdMap.put(unit.VIN_Number__c, unit.Id);
        }
        return vinNumberToUnitSFIdMap;
    }
    
    public static Map<String, String> getVinNumberToUnitIdMap(List<Customer_Owned_Unit__c> unitList) {
        Map<String, String> vinNumberToUnitIdMap = new Map<String, String>();
        for(Customer_Owned_Unit__c unit : unitList) {
            vinNumberToUnitIdMap.put(unit.VIN_Number__c, unit.Unit_Number__c);
        }
        return vinNumberToUnitIdMap;
    }
    
    public static List<Customer_Owned_Unit__c> getUnits(Set<Id> unitIdSet) {
        String query = 'SELECT ' + String.join(DP360InventoryWrapper.unitFieldsList(), ', ') + ' FROM Customer_Owned_Unit__c ' + 
                        'WHERE Id IN: unitIdSet AND Unit_Type__c IN (\'STOCK\', \'ORDU\')';
        List<Customer_Owned_Unit__c> unitList = Database.query(query);
        return unitList;
    }
    
    public class InventoryResultWapper {
        public String message;
        public InventoryVinsInfoWrapper data;
    }
    
    public class InventoryVinsInfoWrapper {
        public List<String> AddedVins;
        public List<String> NotAddedVins;
        public List<String> existingVins;
        public List<String> duplicateVins;
    }
}