/**
 * Author: Nidhi Sharma
 * Since: April 15, 2023
 * Name: MerchandiseUtil
 * Description: 
**/
public without sharing class MerchandiseUtil {

	public static Id getApplicableTaxOnCOLI(CO_Line_Item__c coliRec) {
		Id applicableTaxId;
		if(coliRec != null) {
			if(coliRec.Service_Order_Line_Item__c != null) {
				applicableTaxId = ServiceJobUtil.getApplicableTaxOnSOLI(coliRec.Service_Order_Line_Item__r);
			} else {
				if(isEntityTaxable(coliRec)) {
					String entityName = getEntityName(coliRec);
					if(!GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c && coliRec.Deal__c == null && 
					coliRec.CO_Header__c != null && coliRec.CO_Header__r.Is_Override_Merch_Tax__c && entityName != null && 
					coliRec.CO_Header__r.Override_Merch_Tax_Applicable_On__c != null && 
					coliRec.CO_Header__r.Override_Merch_Tax_Applicable_On__c.contains(entityName)) {
						applicableTaxId = coliRec.CO_Header__r.Merch_Applicable_Tax__c;
					} else {
						applicableTaxId = getApplicableTaxOnEntity(coliRec);
					}
				}
			}
		}
		return applicableTaxId;
	}

	public static Id getApplicableTaxOnEntity(CO_Line_Item__c coliRec) {
		Id applicableTaxId;
		if(coliRec.Part__c != null && coliRec.Part__r.Taxable__c) {
			applicableTaxId = coliRec.Part__r.Applicable_Tax__c;
		} else if(coliRec.Fee__c != null && coliRec.Fee__r.Taxable__c) {
			applicableTaxId = coliRec.Fee__r.Applicable_Tax__c;
		}
		return applicableTaxId;
	}

	private static Boolean isEntityTaxable(CO_Line_Item__c coliRec) {
        return (coliRec != null && (coliRec.Part__c != null && coliRec.Part__r.Taxable__c) || 
            (coliRec.Fee__c != null && coliRec.Fee__r.Taxable__c));
    }

	public static String getEntityName(CO_Line_Item__c coliRec) {
		if(coliRec != null) {
			if(coliRec.Part__c != null) return DealUtil.UNIT_TAX_APPLICABLE_ON_PARTS;
			if(coliRec.Fee__c != null) return DealUtil.UNIT_TAX_APPLICABLE_ON_FEES;
		}
		return null;
	}
}