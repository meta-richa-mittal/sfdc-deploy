/**
 * Author: Tarun Khandelwal
 * Since: May 26, 2015
 * Name: COUFieldWrapper
 * Description: Apex class to handle JSON related oprations of COUField Wrapper.
**/
public without sharing class COUFieldWrapper {
	
	// Country List
	public List<Country> CountryList;
    
    // Country Wrapper / State
    public List<CountryWrapper> StateList;

    public List<State> StatesList;
    
    // Price Level
    public List<PriceLevel> PriceLevelList;
    
    // Sales Tax
    public List<SalesTax> SalesTaxList;
    
    // Unit Make
    public List<UnitMake> UnitMakeList; 
    
    // Unit Model
    public List<UnitMakeWrapper> UnitModelList;
    
    // Unit Sub Model
    public List<UnitMakeWrapper> UnitSubModelList;
    
    // Category List
    public List<Category> CategoryList;
    
    // Transaction type List
    public List<KitHeader.TransactionType> TransactionTypeList;
    
    // Default Ordering Tax Rate
    public String DefaultOrderingTaxId;
    
    // Constructor
    public COUFieldWrapper(List<Country__c> countryList, List<Country__c> countryWrapperList, List<Sales_Tax__c> salesTaxList, 
    							List<Price_Level__c> priceLevelList, List<Unit_Make__c> unitMakeList, List<Unit_Make__c> unitMakeWrapperList, 
    							List<Category__c> categoryList) {
        
        // Initilaize all list and objects
        this.CountryList = new List<Country>();
        this.StateList = new List<CountryWrapper>();
        this.PriceLevelList = new List<PriceLevel>();
        this.SalesTaxList = new List<SalesTax>();
        this.UnitMakeList = new List<UnitMake>();
        this.UnitModelList = new List<UnitMakeWrapper>();
        this.UnitSubModelList = new List<UnitMakeWrapper>();
        this.CategoryList = new List<Category>();
        
        for(Country__c countryRec : countryList) {
            this.CountryList.add(new Country(countryRec));
        }
	 	this.DefaultOrderingTaxId =  GeneralConfiguration.getOrderingTaxRate();
        this.StateList.add(new CountryWrapper(countryWrapperList));
        
        for(Price_Level__c priceLevelRec : priceLevelList) {
        	this.PriceLevelList.add(new PriceLevel(priceLevelRec));
        }
        
        for(Sales_Tax__c salesTaxRec : salesTaxList) {
            this.SalesTaxList.add(new SalesTax(salesTaxRec));
        }
        for(Unit_Make__c unitMakeRec  : unitMakeList) {
            this.UnitMakeList.add(new UnitMake(unitMakeRec));
        }
        this.UnitModelList.add(new UnitMakeWrapper(unitMakeWrapperList, getUnitMakeIdToUnitModelListMap(unitMakeWrapperList)));
        this.UnitSubModelList.addAll(this.UnitModelList);
        for(Category__c categoryRec : categoryList) {
        	this.CategoryList.add(new Category(categoryRec));
        }
    }
    
    
    public COUFieldWrapper(List<Unit_Make__c> unitMakeList, List<Unit_Make__c> unitMakeWrapperList, 
    							List<Category__c> categoryList, List<Transaction_Type__c> ttList ) {
        
        // Initilaize all list and objects
        this.UnitMakeList = new List<UnitMake>();
        this.UnitModelList = new List<UnitMakeWrapper>();
        this.UnitSubModelList = new List<UnitMakeWrapper>();
        this.CategoryList = new List<Category>();
        this.TransactionTypeList = new List<KitHeader.TransactionType>();
        
        for(Unit_Make__c unitMakeRec  : unitMakeList) {
            this.UnitMakeList.add(new UnitMake(unitMakeRec));
        }
        this.UnitModelList.add(new UnitMakeWrapper(unitMakeWrapperList, getUnitMakeIdToUnitModelListMap(unitMakeWrapperList)));
        this.UnitSubModelList.addAll(this.UnitModelList);
        for(Category__c categoryRec : categoryList) {
        	this.CategoryList.add(new Category(categoryRec));
        }
        
        for(Transaction_Type__c ttRec : ttList) {
        	this.TransactionTypeList.add(new KitHeader.TransactionType(ttRec));
        }
        
    }

    public COUFieldWrapper(List<Country__c> countryList, List<State__c> stateList, List<Price_Level__c> priceLevelList) {
        this.CountryList = new List<Country>();
        this.StatesList = new List<State>();
        this.PriceLevelList = new List<PriceLevel>();
        
        for(Country__c countryRec: countryList) {
            this.CountryList.add(new Country(countryRec));
        }
        for(State__c stateRec: stateList) {
            this.StatesList.add(new State(stateRec));
        }
        for(Price_Level__c priceLevelRec: priceLevelList) {
        	this.PriceLevelList.add(new PriceLevel(priceLevelRec));
        }
    }

    private static Map<String, List<UnitModel>> getUnitMakeIdToUnitModelListMap(List<Unit_Make__c> unitMakeWrapperList) {
        String query = 'SELECT ';
        for(String fieldsName : UnitModel.fieldsList()){
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Unit_Model__c where Active__c = true AND Unit_Make__c IN: unitMakeWrapperList';
        List<Unit_Model__c> unitModelList = Database.query(query);
        Map<String, List<UnitModel>> unitMakeIdToUnitModelListMap = new Map<String, List<UnitModel>>();
        for(Unit_Model__c unitModelRec : unitModelList) {
            if(!unitMakeIdToUnitModelListMap.containsKey(unitModelRec.Unit_Make__r.Id)) {
                unitMakeIdToUnitModelListMap.put(unitModelRec.Unit_Make__r.Id, new List<UnitModel>());
            }
            unitMakeIdToUnitModelListMap.get(unitModelRec.Unit_Make__r.Id).add(new UnitModel(unitModelRec));
        }
        return unitMakeIdToUnitModelListMap;
    }
    
}
