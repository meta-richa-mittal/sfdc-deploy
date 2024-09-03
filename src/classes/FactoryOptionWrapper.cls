/**
 * Author: Nidhi Sharma
 * Since: January 04, 2021
 * Name: FactoryOptionWrapper
 * Description: Factory Option Wrapper
**/
public without sharing class FactoryOptionWrapper {
    public String Id;
    public String MakeId;
    public String Code;
    public String Description;
	public Decimal Cost;
	public Decimal Price;
	public String SubModelId;
	public String ModelId;
	public String FactoryOptionId;
    
    public FactoryOptionWrapper(Factory_Option__c factOptionRec) {
    	this.Id = this.FactoryOptionId = factOptionRec.Id;
    	this.MakeId = factOptionRec.Unit_Make__c;
    	this.Code = factOptionRec.Code__c;
    	this.Description = factOptionRec.Description__c;
    	this.Cost = factOptionRec.Cost__c != null ? factOptionRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
    	this.Price = factOptionRec.Price__c != null ? factOptionRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
	}
	
	public FactoryOptionWrapper(Submodel_Factory_Option_Junction__c subModelFactOptionRec) {
    	this.Id = subModelFactOptionRec.Id;
        this.SubModelId = subModelFactOptionRec.Unit_Sub_Model__c;
        this.ModelId = subModelFactOptionRec.Unit_Model__c;
        this.FactoryOptionId = subModelFactOptionRec.Factory_Option__c;
    	this.Code = String.isNotBlank(subModelFactOptionRec.Factory_Option__r.Code__c) ? subModelFactOptionRec.Factory_Option__r.Code__c : '';
    	this.Description = String.isNotBlank(subModelFactOptionRec.Factory_Option__r.Description__c) ? subModelFactOptionRec.Factory_Option__r.Description__c : '';
    	this.Cost = subModelFactOptionRec.Cost__c != null ? subModelFactOptionRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
    	this.Price = subModelFactOptionRec.Price__c != null ? subModelFactOptionRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
    }
    
    public static List<String> getSubmodelFactoryOptionFieldList() {
    	return new List<String>{'Id', 'Unit_Sub_Model__c', 'Unit_Model__c', 'Factory_Option__c', 'Factory_Option__r.Code__c', 'Factory_Option__r.Description__c', 'Cost__c', 'Price__c'};
    }
    
    public List<String> getFields() {
    	return new List<String>{'Id', 'Unit_Make__c', 'Code__c', 'Description__c', 'Cost__c', 'Price__c'};
    }
    
    public static Factory_Option__c getFactoryOptionRecFromObj(FactoryOptionWrapper obj) {
    	Factory_Option__c factOptionRec =  new Factory_Option__c(Id = obj.Id);
    	factOptionRec.Unit_Make__c = obj.MakeId;
    	factOptionRec.Code__c = obj.Code;
    	factOptionRec.Description__c = obj.Description;
    	factOptionRec.Cost__c = obj.Cost != null ? obj.Cost.setScale(2, RoundingMode.HALF_UP) : 0;
    	factOptionRec.Price__c = obj.Price != null ? obj.Price.setScale(2, RoundingMode.HALF_UP) : 0;
    	return factOptionRec;	
    }
}