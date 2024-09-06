public without sharing class PrintUnitOrderCtrl {

    public String companyLogoURL { get{return GeneralConfiguration.getCompanyLogoUrl();} private set;}
    public Boolean IsForeignExchangeCostingEnabled {get{return GeneralConfiguration.getGeneralConfigurations().Enable_Foreign_Exchange_Costing__c;} private set;}
    public UnitOrderDetail unitWrapper {get; private set;}
    
    public PrintUnitOrderCtrl() {
        String vendorId = ApexPages.currentPage().getParameters().get('id');
        String unitIds = BPUtility.getDecodedString(ApexPages.currentPage().getParameters().get('unitIds'));
        
        Map<String, String> unitIdToProductTypeIdMap = new Map<String, String>();
        for(Customer_Owned_Unit__c couRec: [SELECT Product_type__c FROM Customer_Owned_Unit__c WHERE Id IN: unitIds.split(',')]) {
            if(String.isNotBlank(couRec.Product_type__c))unitIdToProductTypeIdMap.put(couRec.Id, couRec.Product_type__c);
        }
        BrandingLocationWrapper brandingLocationObj = getBrandingLocation();
        List<Account> vendorList = SOQLUtil.getVendorDetailRecord('Id', vendorId);

        Map<Id, Customer_Owned_Unit__c> unitIdToRecMap;
        if(!unitIdToProductTypeIdMap.isEmpty()) {
            List<FilterJSON> filerObjList = new List<FilterJSON>{
                new FilterJSON('Unit_Product_Type__c', 'IN', String.join(unitIdToProductTypeIdMap.values(), ',')),
                new FilterJSON('Active__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE),
                new FilterJSON('Include_In_Unit_Order_Document__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE)
            };
            UnitProductTypeService.OptionalFieldAPINameToRecMap = UnitProductTypeService.getUnitOptionalFieldAPINameToRecMap(filerObjList);
            UnitProductTypeService.UnitDataFieldsAPINameToLabelMap = GeneralConfiguration.getUnitDataFieldsAPINameToLabelMap();
            Unit_Service.UnitPrimaryFields.addAll(new List<String>{
                                                    'Name', 'ORDU_Stock_Id__c', 'Sub_Model__r.Description__c', 'Factory_Order_No__c', 'Total_Price__c', 'Total_Cost__c', 'Status__c', 
                                                    '(SELECT Item_Description__c, Total_Cost__c FROM Unit_Prices_Costs__r ORDER BY Type__c ASC, CreatedDate ASC)'
                                                });
            unitIdToRecMap = Unit_Service.getUnitIdToRecMap(unitIdToProductTypeIdMap.keySet(), Unit_Service.UnitPrimaryFields, new List<String>(UnitProductTypeService.OptionalFieldAPINameToRecMap.keySet()));
        }
        
        unitWrapper = new UnitOrderDetail(brandingLocationObj, vendorList[0], unitIdToRecMap.values());
    }
    
    private List<Customer_Owned_Unit__c> getUnits(String unitIds) {
        List<String> unitIdList = unitIds.split(',');
        Set<Id> unitIdSet = new Set<Id>();
        for(String unitId : unitIdList) {
            unitIdSet.add(Id.valueOf(unitId));
        } 
        return SOQLUtil.getUnitDetails(unitIdSet);
    }
    
    private BrandingLocationWrapper getBrandingLocation() {
        List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
        BrandingLocationWrapper brandingLocationObj = new BrandingLocationWrapper();
        brandingLocationObj.setDefaultBrandingLocation((businessProfileList.size() > 0 ? businessProfileList[0] : new Business_Profile__c()));
        return brandingLocationObj;
    }

    public class UnitOrderDetail {
        public CustomerDetail.Company CompanyInfo {get; set;}
        public Vendor vendor {get; set;}
        public List<UnitWrapper> unitList {get; set;}

        public UnitOrderDetail(BrandingLocationWrapper brandingLocationObj, Account vendorRec, List<Customer_Owned_Unit__c> units) {
            this.CompanyInfo = new CustomerDetail.Company(brandingLocationObj);
            this.vendor = new Vendor(vendorRec);
            
            this.unitList = new List<UnitWrapper>();
            for(Customer_Owned_Unit__c unitRec : units) {
                unitList.add(new UnitWrapper(unitRec));
            }
        }
    }
    
    public class Vendor {
        public String Name {get; private set;}
        public String AccountNumber {get; private set;}
        public String Address1 {get; private set;}
        public String Address2 {get; private set;}
        public String CityProv {get; private set;}
        public String Postal {get; private set;}
        public String State {get; private set;}
        public String Email {get; private set;}
        public String Phone {get; private set;}
        public Date CurrentDate {get; private set;} 
        public Boolean IsForeignVendor {get; private set;} 
        public String CurrencyCode {get; private set;} 
        
        public Vendor(Account vendorRec) {
            this.CurrentDate = system.today();
            this.Name = vendorRec.Name;
            
            String billingStreet = (vendorRec.BillingStreet == null ) ? '' : vendorRec.BillingStreet;
            List<String> bsList = billingStreet.split('\n');
            this.Address1 = (bsList.size() > 0) ? bsList[0].replace(',', ' ') : '';
            this.Address2 = (bsList.size() > 1) ? bsList[1].replace(',', ' ') : '';
            this.CityProv = vendorRec.BillingCity;
            this.Postal = vendorRec.BillingPostalCode;
            this.State = vendorRec.BillingState;
            
            if(vendorRec.Preferred_Email__c == null) {
                if(vendorRec.Email__c != null) {
                    this.Email = vendorRec.Email__c;
                } else if(vendorRec.Work_Email__c != null) {
                    this.Email = vendorRec.Work_Email__c;
                } else if(vendorRec.Other_Email__c != null) {
                    this.Email = vendorRec.Other_Email__c;
                }
            } else {
                this.Email = vendorRec.Preferred_Email__c;
            }

            if(vendorRec.Preferred_Phone__c == null) {
                if(vendorRec.Home_Number__c != null) {
                    this.Phone = vendorRec.Formatted_Home_number__c;
                } else if(vendorRec.Mobile__c != null) {
                    this.Phone = vendorRec.Formatted_Mobile_Number__c;
                } else if(vendorRec.Work_Number__c != null) {
                    this.Phone = vendorRec.Formatted_Work_Number__c;
                }
            } else {
                this.Phone = vendorRec.Formatted_Preferred_Phone__c;
            }
            this.AccountNumber = vendorRec.AccountNumber;
            this.IsForeignVendor = vendorRec.Is_Foreign_Vendor__c;
            if(this.IsForeignVendor) {
                this.CurrencyCode = vendorRec.Country__c != null ? vendorRec.Country__r.Currency_Code__c : '';
            }
        }
    }
    
    public class UnitWrapper {  
        public String Id {get; private set;}
        public String Name {get; private set;}
        public String UnitType {get; private set;}
        public String UnitId {get; private set;}
        public String StockNumber {get; private set;}
        public Decimal Year {get; private set;}
        public String MakeModelDescription {get; private set;}
        public String Make {get; private set;}
        public String MakeName {get; private set;}
        public String Model {get; private set;}
        public String ModelName {get; private set;}
        public String SubModel {get; private set;}
        public String SubModelName {get; private set;}
        public String ExteriorColour {get; private set;}
        public Decimal TotalPrice {get; private set;}
        public Decimal TotalCost {get; private set;}
        public String Unit {get; private set;}
        public String VINNumber {get;set;}
        public String FONumber {get;set;}
        public List<UnitExtraFields> unitExtraFieldList {get; set;}
        public List<UnitCostingWrapper> unitCostingList {get; private set;}
		
        public UnitWrapper(Customer_Owned_Unit__c unitRec) {
            this.Id = unitRec.Id;
            this.Name = unitRec.Name != null ? unitRec.Name : '';
            this.UnitType = (unitRec.Unit_Type__c != null) ? unitRec.Unit_Type__c : '';
            if(unitRec.Unit_Type__c == 'Stock'){
                this.UnitId = unitRec.Stock_Id__c;
            }else if(unitRec.Unit_Type__c == 'COU' || unitRec.Unit_Type__c == 'ORDU'){
                this.UnitId = unitRec.Unit_Id__c;
            }
            if(unitRec.Status__c == 'Received') {
                this.StockNumber = unitRec.ORDU_Stock_Id__c;
            } else {
                this.StockNumber = unitRec.Stock_Id__c;
            }
    		
            this.Year = unitRec.Year__c;
            this.Make = unitRec.Unit_Make__c;
            this.MakeName = (unitRec.Unit_Make__c != null) ? unitRec.Unit_Make__r.Name : '';
            this.Model = unitRec.Unit_Model__c;
            this.ModelName = (unitRec.Unit_Model__c != null) ? unitRec.Unit_Model__r.Name__c : '';        
            this.SubModel = unitRec.Sub_Model__c;
            this.SubModelName = (unitRec.Sub_Model__c != null) ? unitRec.Sub_Model__r.Sub_Model_Name__c : '';
            this.MakeModelDescription = (unitRec.Sub_Model__c != null) ? unitRec.Sub_Model__r.Description__c : '';
            this.VINNumber = (unitRec.VIN_Number__c != null) ? unitRec.VIN_Number__c : '';
            this.FONumber = (unitRec.Factory_Order_No__c != null) ? unitRec.Factory_Order_No__c : '';
            this.ExteriorColour = UnitProductTypeService.OptionalFieldAPINameToRecMap.containsKey('Colour__c') && String.isNotBlank(unitRec.Colour__c) ? unitRec.Colour__c : null;

            unit = '';
            Unit += String.isNotBlank(this.MakeName) ? this.MakeName: '';
            Unit += String.isNotBlank(this.ModelName) ? ', '+ this.ModelName: '';
            Unit += String.isNotBlank(this.SubModelName) ? ', '+ this.SubModelName : '';
            Unit += this.Year != null ? ', '+ this.Year : '';
            Unit += String.isNotBlank(this.ExteriorColour) ? ', '+ this.ExteriorColour : '';
            
            this.TotalPrice = (unitRec.Total_Price__c != null) ? unitRec.Total_Price__c : 0;
            this.TotalCost = (unitRec.Total_Cost__c != null) ? unitRec.Total_Cost__c : 0;
            
            this.unitExtraFieldList = new List<UnitExtraFields>();
            if(UnitProductTypeService.OptionalFieldAPINameToRecMap != null && UnitProductTypeService.UnitDataFieldsAPINameToLabelMap != null) {
                for(String apiName: UnitProductTypeService.OptionalFieldAPINameToRecMap.keySet()) {
                    String fieldName = UnitProductTypeService.OptionalFieldAPINameToRecMap.get(apiName).Name;
                    if(String.isBlank(apiName)) continue;
                    object fieldValue = unitRec.get(apiName);
                    String fieldCat = UnitProductTypeService.OptionalFieldAPINameToRecMap.get(apiName).Category__c;
                    if(fieldValue != null && String.isNotBlank(String.valueOf(fieldValue))) {
                        if(fieldCat != 'Miscellaneous') {
                            this.unitExtraFieldList.add(new UnitExtraFields(fieldName, String.valueOf(fieldValue)));
                        } else if(UnitProductTypeService.UnitDataFieldsAPINameToLabelMap.keySet().contains(apiName)) {
                            this.unitExtraFieldList.add(new UnitExtraFields(UnitProductTypeService.UnitDataFieldsAPINameToLabelMap.get(apiName), String.valueOf(fieldValue)));
                        }
                    }
                }
            }
            
            this.unitCostingList = new List<UnitCostingWrapper>();
            for(Unit_Price_Cost__c unitPriceCost : unitRec.Unit_Prices_Costs__r) {
                this.unitCostingList.add(new UnitCostingWrapper(unitPriceCost));
            }
        }
        
        public String getUnitGenericFieldValue(Customer_Owned_Unit__c unitRec, String genericFieldLabel) {
	        String fieldAPIName = genericFieldLabel.replace(' ', '_') + '__c';
	        try {
	            return (unitRec.get(fieldAPIName) != null ? String.valueOf(unitRec.get(fieldAPIName)) : '');
	        } catch(Exception e) {
	        }
	        return '';
	    }
    }
    
    public class UnitCostingWrapper {
        public String Description {get; private set;}
        public Decimal Cost {get; private set;}
        
        public UnitCostingWrapper(Unit_Price_Cost__c unitPriceCostRec) {
            this.description = unitPriceCostRec.Item_Description__c;
            this.cost = unitPriceCostRec.Total_Cost__c;
        }
    }
    
    public class UnitExtraFields {
        public String Label {get; private set;}
        public String Value {get; private set;}
        
        public UnitExtraFields(String label, String value) {
            this.Label = label;
            this.Value = value;
        }
    }
}