/**
 * Author: Tarun Khandelwal
 * Since: May 25, 2015
 * Name: PriceLevel
 * Description: Apex class to handle JSON related oprations of PriceLevel object.
**/
public without sharing class PriceLevel {

	public Boolean IsActive;
	public Boolean IsDefault;
	public String PriceLevelName;
	public String PartPriceBase;
	public Decimal Discount;
	public Decimal LabourRate;
	public String Description;
	public String Id;
	
    public PriceLevel(Price_Level__c priceLevelRec) {
    	this.PriceLevelName = priceLevelRec.Name__c ;
    	this.Id = priceLevelRec.Id;
    	this.IsDefault = priceLevelRec.Default__c;
    	
    	this.Description = priceLevelRec.Description__c ;
    	this.PartPriceBase = priceLevelRec.Part_Price_Base__c;
    	this.Discount = priceLevelRec.Discount_Markup__c;
    	this.LabourRate = priceLevelRec.Labour_Rate__c;
    	this.IsActive = priceLevelRec.Active__c;
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> priceLevelFields = new List<String>{ 'Id',
	                                                    'Name__c', 
	                                                    'Default__c',
	                                                    'Active__c',
	                                                    'Description__c',
	                                                    'Discount_Markup__c',
	                                                    'Labour_Rate__c',
	                                                    'Part_Price_Base__c'
                                               		 };
        return priceLevelFields;
    }
}