public without sharing class DP360InventoryWrapper {
	public Integer dealer_id;
   	public String inv_id;
   	public String condition;
   	public String year;
    public String make;
    public String model;
    public Decimal price;
    
    public String vin;
    public String stocknumber;
    public String color;
    public String miles;
    public String description;
    public Boolean sold;
    public integer is_active; 
    
    public String engine_id;
    public String unit_status;
    public Decimal suggested_price;
    public String url;
    public Decimal sale_price;
    public Map<String, String> specifications;
    
    public DP360InventoryWrapper(Customer_Owned_Unit__c unitRec, Integer dealerId) {
        this.dealer_id = dealerId;
        this.inv_id = (unitRec.Unit_Id__c != null ? unitRec.Unit_Id__c : unitRec.Stock_Id__c);
        this.condition = (unitRec.New_Unit__c ? 'New' : 'Used');
        this.year = unitRec.Year__c != null ? String.valueOf(unitRec.Year__c) : null;
        this.make = (unitRec.Unit_Make__c != null) ? unitRec.Unit_Make__r.Name : null;
        this.model = (unitRec.Unit_Model__c != null) ? unitRec.Unit_Model__r.Name__c + ((unitRec.Sub_Model__c != null) ? ' ' + unitRec.Sub_Model__r.Sub_Model_Name__c : '') : null;
        this.price = unitRec.Total_Price__c != null ? unitRec.Total_Price__c : 0;
        if(unitRec.Consignment__c && unitRec.Suggested_Price__c != null){
            this.price = unitRec.Suggested_Price__c;
        }
        this.vin = String.isNotBlank(unitRec.VIN_Number__c) ? unitRec.VIN_Number__c: (unitRec.Unit_Id__c != null ? unitRec.Unit_Id__c : unitRec.Stock_Id__c);
        this.stocknumber = unitRec.Stock_Id__c;
        this.color = unitRec.Colour__c;
        this.miles = unitRec.Mileage_Value__c != null ? String.valueOf(unitRec.Mileage_Value__c) : null;
        this.description = unitRec.Notes__c;
        this.suggested_price = this.price;
        this.sold = (String.isNotBlank(unitRec.Status__c) && dp360UnitSoldStatusSet.contains(unitRec.Status__c));
        this.is_active = (this.sold ? 0 : 1);
        
        this.engine_id = unitRec.Engine_Serial_No__c;
        this.unit_status = unitRec.Status__c;
        this.url = AccountingUtil.getURL(unitRec.Id, 'ViewUnit');
        this.sale_price = unitRec.Suggested_Price__c != null ? unitRec.Suggested_Price__c : 0;
        this.specifications = getUnitSpecifications(unitRec);
    }

    private static Map<String,String> getUnitSpecifications(Customer_Owned_Unit__c unitRec) {
        Map<String,String> unitSpecificationsMap = new Map<String,String>();
        Set<String> dp360APIDefinedUnitSpecificationsSet = dp360APIDefinedUnitSpecificationsSet();
        Map<String, String> unitDataFieldNameToValueMap = getUnitDataFieldNameToValueMap(unitRec);
        List<GeneralConfiguration.UnitDataFieldConfigWrapper> unitDataFieldsConfigList = GeneralConfiguration.getUnitDataFieldsConfig();

        for(GeneralConfiguration.UnitDataFieldConfigWrapper configRec : unitDataFieldsConfigList) {
            if(dp360APIDefinedUnitSpecificationsSet.contains(configRec.DisplayLabel.toLowerCase())) {
                if(unitDataFieldNameToValueMap.containsKey(configRec.FieldName) && String.isNotBlank(unitDataFieldNameToValueMap.get(configRec.FieldName))) {
                    unitSpecificationsMap.put(configRec.DisplayLabel, unitDataFieldNameToValueMap.get(configRec.FieldName));
                }
            }
        }
        return unitSpecificationsMap;
    }

    private static Map<String, String> getUnitDataFieldNameToValueMap(Customer_Owned_Unit__c unitRec) {
        Map<String, String> unitDataFieldNameToValueMap = new Map<String, String>();
        if(unitRec != null) {
            unitDataFieldNameToValueMap.put('Unit Data 01', unitRec.Unit_Data_01__c);
        	unitDataFieldNameToValueMap.put('Unit Data 02', unitRec.Unit_Data_02__c);
        	unitDataFieldNameToValueMap.put('Unit Data 03', unitRec.Unit_Data_03__c);
        	unitDataFieldNameToValueMap.put('Unit Data 04', unitRec.Unit_Data_04__c);
        	unitDataFieldNameToValueMap.put('Unit Data 05', unitRec.Unit_Data_05__c);
        	unitDataFieldNameToValueMap.put('Unit Data 06', unitRec.Unit_Data_06__c);
        	unitDataFieldNameToValueMap.put('Unit Data 07', unitRec.Unit_Data_07__c);
        	unitDataFieldNameToValueMap.put('Unit Data 08', unitRec.Unit_Data_08__c);
        	unitDataFieldNameToValueMap.put('Unit Data 09', unitRec.Unit_Data_09__c);
        	unitDataFieldNameToValueMap.put('Unit Data 10', unitRec.Unit_Data_10__c);
        	unitDataFieldNameToValueMap.put('Unit Data 11', unitRec.Unit_Data_11__c);
        	unitDataFieldNameToValueMap.put('Unit Data 12', unitRec.Unit_Data_12__c);
        	unitDataFieldNameToValueMap.put('Unit Data 13', unitRec.Unit_Data_13__c);
        	unitDataFieldNameToValueMap.put('Unit Data 14', unitRec.Unit_Data_14__c);
        	unitDataFieldNameToValueMap.put('Unit Data 15', unitRec.Unit_Data_15__c);
        }
        return unitDataFieldNameToValueMap;
    }
    
    public static Set<String> dp360UnitSoldStatusSet = new Set<String>{'Reserved', 'Sold', 'Delivered', 'Received', 'Transferred', 'Inactive'};
    
    public static List<String> unitFieldsList() {
        return new List<String>{'New_Unit__c', 'Year__c', 'Unit_Make__c', 'Unit_Make__r.Name', 'Unit_Model__c', 'Unit_Model__r.Name__c', 
                                'Unit_Number__c', 'Unit_Id__c', 'Total_Price__c', 'VIN_Number__c', 'Stock_Id__c', 'Colour__c', 'Mileage_Value__c', 'Notes__c', 
                                'Status__c', 'Engine_Serial_No__c', 'Sub_Model__c', 'Sub_Model__r.Sub_Model_Name__c', 'Suggested_Price__c', 'Consignment__c',
                                'Unit_Data_01__c', 'Unit_Data_02__c', 'Unit_Data_03__c', 'Unit_Data_04__c', 'Unit_Data_05__c', 'Unit_Data_06__c', 'Unit_Data_07__c', 
                                'Unit_Data_08__c', 'Unit_Data_09__c', 'Unit_Data_10__c', 'Unit_Data_11__c', 'Unit_Data_12__c', 'Unit_Data_13__c', 'Unit_Data_14__c', 'Unit_Data_15__c'};
    }

    public static List<String> dp360UpdateUnitFieldsList() {
        return new List<String>{'New_Unit__c', 'Year__c', 'Unit_Make__c', 'Unit_Model__c', 'Unit_Number__c', 'Unit_Id__c', 'Total_Price__c', 'VIN_Number__c', 
                                'Stock_Id__c', 'Colour__c', 'Mileage_Value__c', 'Notes__c', 'Engine_Serial_No__c', 'Sub_Model__c', 'Suggested_Price__c', 
                                'Status__c', 'Consignment__c', 'Unit_Data_01__c', 'Unit_Data_02__c', 'Unit_Data_03__c', 'Unit_Data_04__c', 'Unit_Data_05__c', 
                                'Unit_Data_06__c', 'Unit_Data_07__c', 'Unit_Data_08__c', 'Unit_Data_09__c', 'Unit_Data_10__c', 'Unit_Data_11__c', 'Unit_Data_12__c',
                                'Unit_Data_13__c', 'Unit_Data_14__c', 'Unit_Data_15__c'};
    }
    
    public static Set<String> dp360APIDefinedUnitSpecificationsSet() {
        return new Set<String>{'engine displacement cc', 'engine displacement in', 'engine displacement l', 'engine type', 'fuel type', 'fuel system', 
                                'transmission', 'fuel capacity gal', 'fuel capacity l', 'ground clearance cm', 'ground clearance in', 'height cm', 'height ft', 
                                'height in', 'height m', 'length cm', 'length ft', 'length in', 'length m', 'width cm', 'width ft', 'width in', 'width m', 'gvwr kg', 
                                'gvwr lb', 'weight kg', 'weight lb', 'max load kg', 'max load lb', 'wheelbase cm', 'wheelbase in', 'seats', 'sleeps'};
    }
}