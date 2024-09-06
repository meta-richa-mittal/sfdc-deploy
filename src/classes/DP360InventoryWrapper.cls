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
    
    public String engine_id;
    public String unit_status;
    public Decimal suggested_price;
    public String url;
    public Decimal sale_price;
    
    public DP360InventoryWrapper(Customer_Owned_Unit__c unitRec, Integer dealerId) {
        this.dealer_id = dealerId;
        this.inv_id = unitRec.Unit_Number__c;
        this.condition = (unitRec.New_Unit__c ? 'New' : 'Used');
        this.year = unitRec.Year__c != null ? String.valueOf(unitRec.Year__c) : null;
        this.make = (unitRec.Unit_Make__c != null) ? unitRec.Unit_Make__r.Name : null;
        this.model = (unitRec.Unit_Model__c != null) ? unitRec.Unit_Model__r.Name__c + ((unitRec.Sub_Model__c != null) ? ' ' + unitRec.Sub_Model__r.Sub_Model_Name__c : '') : null;
        this.price = unitRec.Total_Price__c != null ? unitRec.Total_Price__c : 0;
        
        this.vin = String.isNotBlank(unitRec.VIN_Number__c) ? unitRec.VIN_Number__c: unitRec.Unit_Number__c;
        this.stocknumber = unitRec.Stock_Id__c;
        this.color = unitRec.Colour__c;
        this.miles = unitRec.Mileage_Value__c != null ? String.valueOf(unitRec.Mileage_Value__c) : null;
        this.description = unitRec.Notes__c;
        this.suggested_price = this.price;
        this.sold = (String.isNotBlank(unitRec.Status__c) && dp360UnitSoldStatusSet.contains(unitRec.Status__c));
        
        this.engine_id = unitRec.Engine_Serial_No__c;
        this.unit_status = unitRec.Status__c;
        this.url = AccountingUtil.getURL(unitRec.Id, 'ViewUnit');
        this.sale_price = unitRec.Suggested_Price__c != null ? unitRec.Suggested_Price__c : 0;
    }
    
    public static Set<String> dp360UnitSoldStatusSet = new Set<String>{'Reserved', 'Sold', 'Delivered', 'Received', 'Transferred', 'Inactive'};
    
    public static List<String> unitFieldsList() {
        return new List<String>{'New_Unit__c', 'Year__c', 'Unit_Make__c', 'Unit_Make__r.Name', 'Unit_Model__c', 'Unit_Model__r.Name__c', 
                                'Unit_Number__c', 'Total_Price__c', 'VIN_Number__c', 'Stock_Id__c', 'Colour__c', 'Mileage_Value__c', 'Notes__c', 
                                'Status__c', 'Engine_Serial_No__c', 'Sub_Model__c', 'Sub_Model__r.Sub_Model_Name__c', 'Suggested_Price__c'};
    }

    public static List<String> dp360UpdateUnitFieldsList() {
        return new List<String>{'New_Unit__c', 'Year__c', 'Unit_Make__c', 'Unit_Model__c', 'Unit_Number__c', 'Total_Price__c', 'VIN_Number__c', 
                                'Stock_Id__c', 'Colour__c', 'Mileage_Value__c', 'Notes__c', 'Engine_Serial_No__c', 'Sub_Model__c', 'Suggested_Price__c', 'Status__c'};
    }
    
}