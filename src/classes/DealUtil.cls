/**
 * Author: Nidhi Sharma
 * Since: March 18, 2023
 * Name: DealUtil
 * Description: 
**/
public without sharing class DealUtil {

    public static final String DEAL_MERCH = 'Deal Merchandise';
    public static final String delimitor = ';';
    public static final String UNIT_TAX_APPLICABLE_ON_PARTS = 'Parts';
    public static final String UNIT_TAX_APPLICABLE_ON_LABOR = 'Labor';
    public static final String UNIT_TAX_APPLICABLE_ON_SUBLET = 'Sublet';
    public static final String UNIT_TAX_APPLICABLE_ON_FEES = 'Fees';
    public static final String UNIT_TAX_APPLICABLE_ON_WARRANTY_PRODUCTS = 'Warranty products';
	public static final String UNIT_TAX_APPLICABLE_ON_OTHER_PRODUCTS = 'Other products';
	public static final Set<String> dealLockedStatusSet = new Set<String>{'Approved', 'Fulfilled', 'Invoiced'};

    public static final String UNIT_TAX_APPLICABLE_DEFAULT = String.join(new List<String>{UNIT_TAX_APPLICABLE_ON_PARTS, 
        UNIT_TAX_APPLICABLE_ON_LABOR, UNIT_TAX_APPLICABLE_ON_SUBLET}, delimitor);
        
    public static final String UNIT_TAX_APPLICABLE_ALL = String.join(new List<String>{UNIT_TAX_APPLICABLE_ON_PARTS, 
        UNIT_TAX_APPLICABLE_ON_LABOR, UNIT_TAX_APPLICABLE_ON_SUBLET, UNIT_TAX_APPLICABLE_ON_FEES, UNIT_TAX_APPLICABLE_ON_WARRANTY_PRODUCTS, 
        UNIT_TAX_APPLICABLE_ON_OTHER_PRODUCTS}, delimitor);

	public static Id getApplicableTaxOnOptionAndFee(Option_Fee__c optionAndFeeRec) {
		if(isOptionAndFeeTaxedSameAsUnit(optionAndFeeRec)) {
			return (isOptionAndFeeTaxable(optionAndFeeRec) ? optionAndFeeRec.Deal_Item__r.Applicable_Tax__c : null);
		}
		return getApplicableTaxOnEntity(optionAndFeeRec);
	}

	public static Boolean isOptionAndFeeTaxedSameAsUnit(Option_Fee__c optionAndFeeRec) {
        String entityName = getEntityName(optionAndFeeRec);
		return (entityName != null && optionAndFeeRec.Deal_Item__c != null && optionAndFeeRec.Deal_Item__r.Unit_Tax_Applicable_On__c != null && 
		optionAndFeeRec.Deal_Item__r.Unit_Tax_Applicable_On__c.contains(entityName));
	}

	public static Id getApplicableTaxOnEntity(Option_Fee__c optionAndFeeRec) {
		if(optionAndFeeRec != null) {
			if(optionAndFeeRec.Part__c != null && optionAndFeeRec.Part__r.Taxable__c) {
				return optionAndFeeRec.Part__r.Applicable_Tax__c;
			} else if(optionAndFeeRec.Labour_Code__c != null && optionAndFeeRec.Labour_Code__r.Taxable__c) {
				return optionAndFeeRec.Labour_Code__r.Applicable_Tax__c;
			} else if(optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Taxable__c) {
				return optionAndFeeRec.Product__r.Applicable_Tax__c;
			} else if(optionAndFeeRec.Fee__c != null && optionAndFeeRec.Fee__r.Taxable__c) {
				return optionAndFeeRec.Fee__r.Applicable_Tax__c;
			}
		}
		return null;
	}

    private static Boolean isOptionAndFeeTaxable(Option_Fee__c optionAndFeeRec) {
        return (optionAndFeeRec.Deal_Item__r.Taxable__c && (
            (optionAndFeeRec.Part__c != null && optionAndFeeRec.Part__r.Taxable__c) || 
            (optionAndFeeRec.Labour_Code__c != null && optionAndFeeRec.Labour_Code__r.Taxable__c) || 
            (optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Taxable__c) || 
            (optionAndFeeRec.Fee__c != null && optionAndFeeRec.Fee__r.Taxable__c)));
    }

	private static String getEntityName(Option_Fee__c optionAndFeeRec) {
		if(optionAndFeeRec != null) {
			if(optionAndFeeRec.Part__c != null) return UNIT_TAX_APPLICABLE_ON_PARTS;
			if(optionAndFeeRec.Labour_Code__c != null) return UNIT_TAX_APPLICABLE_ON_LABOR;
			if(optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Type__c == Constants.SUBLET) return UNIT_TAX_APPLICABLE_ON_SUBLET;
			if(optionAndFeeRec.Fee__c != null) return UNIT_TAX_APPLICABLE_ON_FEES;
			if(optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Type__c == Constants.WARRANTY_PLAN) return UNIT_TAX_APPLICABLE_ON_WARRANTY_PRODUCTS;
			if(optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Type__c != Constants.SUBLET && optionAndFeeRec.Product__r.Type__c != Constants.WARRANTY_PLAN) return UNIT_TAX_APPLICABLE_ON_OTHER_PRODUCTS;
		}
		return null;
	}
	
	public static List<Individual_Tax__c> getDealRelatedIndividualTaxes(Id dealId) {
		List<Individual_Tax__c> individualItemsList = new List<Individual_Tax__c>();
		if(String.isNotBlank(dealId)) {
			String query = 'SELECT Deal__c, Taxable_Amount_for_Section_Header__c, CO_Line_Item__c, Tax_Rate__c, Form_Label__c, SO_Payment_Role__c, ' +
			'Taxable_Amount__c, Tax_Amount__c, Enhanced_Tax_Amount__c, Sales_Tax_Item_Name__c, Sales_Tax_Item__r.Name__c, Applicable_Tax__c, List_Tax_items_on_forms__c, SO_Payment_Role__r.Applicable_Tax_Name__c '+
			'FROM Individual_Tax__c WHERE ';
			if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c) {
				query += 'Option_Fee__r.Deal__c =: dealId ' +
						'OR Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c =: dealId ' +
						'OR F_I_Product__r.Deal_Finance__r.Deal__c =: dealId ' +
						'OR (Deal_Item__r.Deal__c =: dealId AND Deal_Item__r.Type__c = \'Trade In\')';
			} else {
				query += 'Deal__c =: dealId ';
			}
			individualItemsList = Database.query(query);
		}
		return individualItemsList;
	}
}