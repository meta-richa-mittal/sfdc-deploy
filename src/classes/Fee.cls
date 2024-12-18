/**
 * Author: Tarun Khandelwal
 * Since: Nov 19, 2015
 * Name: KitHeader
 * Description: Apex class to handle JSON related oprations of Kit Header Object
**/
public without sharing class Fee {
	public String Type;
	public String Code;
	public String Description;
	public Decimal Price;
	public String CategoryName;
	public String CategoryId;
	public Boolean IsTaxable;
	public Boolean IsActive;
	public String Id;
	public String ApplicableTaxId;
	public String ApplicableTaxName;
	public Decimal CostRate; 			//Added by Nikhil 10/07/17
	public String  CostMethod; 			//Added by Nikhil 10/07/17
	public Decimal FinalCostRate;		//Added by Nikhil 12/07/17
	public Boolean IsIncludeInProfitCalculation;
	public List<String> AssignedTags;
	
	public Fee() {
		this.Price = 0.00;
		this.IsActive = true;
		this.IsIncludeInProfitCalculation = false;
	}
	
	public Fee(Fee__c feeRec) {
		this.Type = feeRec.Type__c;
		this.Code = feeRec.Code__c;
		this.Description = feeRec.Description__c;
		this.Price = (feeRec.Price__c == null) ? 0 : feeRec.Price__c;
		this.CategoryName = feeRec.Category__r.Name;
		this.CategoryId = feeRec.Category__c;
		this.IsTaxable = feeRec.Taxable__c;
		this.IsActive = feeRec.Active__c;
		this.IsIncludeInProfitCalculation = feeRec.Is_Include_In_Profit_Calculation__c;
		this.Id = feeRec.Id;
		this.ApplicableTaxId = feeRec.Applicable_Tax__c;
		this.ApplicableTaxName = feeRec.Applicable_Tax__r.Name__c;
		//Added by Nikhil 10/07/17
		this.CostRate = (feeRec.Cost_Rate__c == null) ? 0 : feeRec.Cost_Rate__c; 
		this.CostMethod = feeRec.Cost_Method__c;
		this.FinalCostRate = (feeRec.Cost_Method__c == 'Fixed Cost') ? feeRec.Cost_Rate__c : (feeRec.Cost_Method__c == 'Percent Retail' ? (this.CostRate * this.Price)/100 : 0 );
		this.AssignedTags = TagUtil.getTagsList(feeRec);
	}
	
	/**
     * Name: getFeeFields
     * Desc: Method to get all fields related to Fee Object.
     * @param:  
     * @return: List<String> - Fee fields list
    **/
	public static List<String> getFeeFields() {
		List<String> feeFields = new List<String>{	'Type__c',
													'Code__c',
													'Description__c',
													'Price__c',
													'Category__c',
													'Category__r.Name',
													'Taxable__c',
													'Active__c',
													'(Select Id, CO_Header__c, CO_Header__r.Name, CO_Header__r.Customer__c, CO_Header__r.Customer_Name__c, CO_Header__r.Customer__r.Name, CO_Header__r.Owner__c, CO_Header__r.Owner__r.Name, CO_Header__r.Order_status__c From CO_Line_Items__r WHERE Special_Order__c = false AND CO_Header__r.Order_status__c = \'Open\' )',
													'Applicable_Tax__r.Name__c',
													'Applicable_Tax__c',
													'Cost_Rate__c',
													'Cost_Method__c',
													'Is_Include_In_Profit_Calculation__c',
													'Assigned_Tag_1__c',
													'Assigned_Tag_2__c'
											};
		return feeFields;
	}
	
	/**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: Fee - Class Object
    **/
    public static Fee parse(String json) {
        return (Fee) System.JSON.deserialize(json, Fee.class);
    }
	
}