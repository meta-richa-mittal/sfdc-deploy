/**
 * Author: Tarun Khandelwal
 * Since: Sept 06, 2017
 * Name: OtherChargesTriggerHelper
 * Description: Trigger Helper executes events of Other Charges object
**/
public without sharing class OtherChargesTriggerHelper {
	
	public static List<Other_Charges__c> otherChargesNewList = new List<Other_Charges__c>();
	public static List<Other_Charges__c> otherChargesOldList = new List<Other_Charges__c>();
    public static Map<Id, Other_Charges__c> otherChargesNewMap = new Map<Id, Other_Charges__c>();
    public static Map<Id, Other_Charges__c> otherChargesOldMap = new Map<Id, Other_Charges__c>();
    
    /**
     * Name: beforeInsertOperation
     * Desc: Method executed on before insert operation of Other Charges
     * @param: 
     * @return: 
    **/
    public static void beforeInsertOperation() {
    	populateTaxPercent();
    }
    
    public static void afterInsertOperation() {
    	populateFieldsOnVIHeader(otherChargesNewList);
    }
    
    public static void afterUpdateOperation() {
    	populateFieldsOnVIHeader(otherChargesNewList);
    }
    
    public static void afterDeleteOperation() {
    	populateFieldsOnVIHeader(otherChargesOldList);
    }
    
    /**
     * Name: populateTaxPercent
     * Desc: populate Tax Percent on Other Charges from Purchase Tax Rate if Fee is Taxable
     * @param: 
     * @return: 
    **/
    public static void populateTaxPercent() {
		Set<Id> venInvoiceIdSet = new set<Id>();
		Set<Id> feeIdSet = new set<Id>();
		for(Other_Charges__c otherChargeRec : otherChargesNewList) {
			venInvoiceIdSet.add(otherChargeRec.Vendor_Invoicing_Header__c);
			feeIdSet.add(otherChargeRec.Fee__c);
		}
		venInvoiceIdSet.remove(null);
		feeIdSet.remove(null);
		
		Map<Id, Decimal> viHeaderIdToPurchaseTaxRateMap = new Map<Id, Decimal>();
		Map<Id, Boolean> feeIdToIsTaxableMap = new Map<Id, Boolean>();
		
		if(AccessControl.ifObjectFieldIsAccessible('Vendor_Invoicing_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Vendor_Invoicing_Header__c> viHeaderList = [Select Vendor__r.Purchase_Tax__r.Rate__c From Vendor_Invoicing_Header__c where 
																Id IN: venInvoiceIdSet];
		for(Vendor_Invoicing_Header__c viHeaderRec : viHeaderList) {
			viHeaderIdToPurchaseTaxRateMap.put(viHeaderRec.Id, (viHeaderRec.Vendor__r.Purchase_Tax__r.Rate__c == null) ? 
																				viHeaderRec.Vendor__r.Purchase_Tax__r.Rate__c : 0);
		}
		
		if(AccessControl.ifObjectFieldIsAccessible('Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Fee__c> feeList = [Select Taxable__c From Fee__c where Id IN: feeIdSet];
		for(Fee__c feeRec : feeList){
			feeIdToIsTaxableMap.put(feeRec.Id, feeRec.Taxable__c);
		}
		
		for(Other_Charges__c otherChargeRec : otherChargesNewList) {
			if(feeIdToIsTaxableMap.get(otherChargeRec.Fee__c) && viHeaderIdToPurchaseTaxRateMap.containsKey(otherChargeRec.Vendor_Invoicing_Header__c)) {
				otherChargeRec.Tax_Percent__c = viHeaderIdToPurchaseTaxRateMap.get(otherChargeRec.Vendor_Invoicing_Header__c);
			} else {
				otherChargeRec.Tax_Percent__c = 0;
			}
		}
    }
    
    public static void populateFieldsOnVIHeader(List<Other_Charges__c> otherChargesList) {
    	Set<Id> venInvoiceIdSet = new set<Id>();
		Set<Id> rcrIdSet = new set<Id>();
    	for(Other_Charges__c otherChargeRec : otherChargesList) {
			if(otherChargeRec.Vendor_Invoicing_Header__c != null) {
				venInvoiceIdSet.add(otherChargeRec.Vendor_Invoicing_Header__c);
			} else if(otherChargeRec.Return_CR_Header__c != null) {
				rcrIdSet.add(otherChargeRec.Return_CR_Header__c);
			}
		}
		venInvoiceIdSet.remove(null);
		rcrIdSet.remove(null);
		
		if(!venInvoiceIdSet.isEmpty()) {
			updateTotalOnVIHeader(venInvoiceIdSet);
		} else if(!rcrIdSet.isEmpty()) {
			updateTotalOnRCRHeader(rcrIdSet);
		}
    }

	private static void updateTotalOnVIHeader(Set<Id> venInvoiceIdSet) {
		if(AccessControl.ifObjectFieldIsAccessible('Vendor_Invoicing_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Vendor_Invoicing_Header__c> viHeaderList = 
		          [Select Tax_Amount_For_Other_Charges__c, Vendor__r.Purchase_Tax__c, Vendor__r.Purchase_Tax__r.Rate__c, Total_Other_Charges__c,
						(SELECT Is_Taxable__c, Cost__c from Other_Charges__r) 
						FROM Vendor_Invoicing_Header__c where Id IN: venInvoiceIdSet];

		Map<Id, List<Decimal>> purchaseTaxIdToTaxLineRateMap = getPurchaseTaxIdToTaxLineRateMap(viHeaderList);
		Decimal totalCost, tax;
    	for(Vendor_Invoicing_Header__c viHeaderRec: viHeaderList) {
    		totalCost = tax = 0;
        	for(Other_Charges__c otherChargesRec: viHeaderRec.Other_Charges__r) {
        		if(otherChargesRec.Is_Taxable__c && purchaseTaxIdToTaxLineRateMap.containsKey(viHeaderRec.Vendor__r.Purchase_Tax__c)) {
					for(Decimal taxRate : purchaseTaxIdToTaxLineRateMap.get(viHeaderRec.Vendor__r.Purchase_Tax__c)) {
						tax += (((otherChargesRec.Cost__c * taxRate) / 100).setScale(2, RoundingMode.HALF_UP));
					}
				}
        		totalCost += (otherChargesRec.Cost__c != null) ? otherChargesRec.Cost__c : 0;
        	}
        	viHeaderRec.Total_Other_Charges__c = totalCost.setScale(2, RoundingMode.HALF_UP);
        	
        	viHeaderRec.Tax_Amount_For_Other_Charges__c = tax;
    	}
    	
		DMLUtility.updateSobjectList('Vendor_Invoicing_Header__c', viHeaderList);
	}
    
	private static void updateTotalOnRCRHeader(Set<Id> rcrIdSet) {
		if(AccessControl.ifObjectFieldIsAccessible('Return_CR_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Return_CR_Header__c> rcrHeaderList = 
						[SELECT Other_Charges_Tax_Amount__c, Vendor__r.Purchase_Tax__c, Vendor__r.Purchase_Tax__r.Rate__c, Other_Charges_Total__c,
						(SELECT Is_Taxable__c, Cost__c FROM Other_Charges__r) 
						FROM Return_CR_Header__c WHERE Id IN: rcrIdSet];

		Map<Id, List<Decimal>> purchaseTaxIdToTaxLineRateMap = getPurchaseTaxIdToTaxLineRateMap(rcrHeaderList);
		Decimal totalTaxableCost, totalCost, tax;
    	for(Return_CR_Header__c rcrHeaderRec: rcrHeaderList) {
    		totalTaxableCost = totalCost = tax = 0;
        	for(Other_Charges__c otherChargesRec: rcrHeaderRec.Other_Charges__r) {
        		if(otherChargesRec.Is_Taxable__c) {
					totalTaxableCost += (otherChargesRec.Cost__c != null) ? otherChargesRec.Cost__c : 0;
        		}
        		totalCost += (otherChargesRec.Cost__c != null) ? otherChargesRec.Cost__c : 0;
        	}
        	rcrHeaderRec.Other_Charges_Total__c = totalCost.setScale(2, RoundingMode.HALF_UP);
        	
        	if(purchaseTaxIdToTaxLineRateMap.containsKey(rcrHeaderRec.Vendor__r.Purchase_Tax__c)) {
                for(Decimal taxRate : purchaseTaxIdToTaxLineRateMap.get(rcrHeaderRec.Vendor__r.Purchase_Tax__c)) {
                    tax += (((totalTaxableCost * taxRate) / 100).setScale(2, RoundingMode.HALF_UP));
                }
            }
        	rcrHeaderRec.Other_Charges_Tax_Amount__c = tax;
    	}
    	
		DMLUtility.updateSobjectList('Return_CR_Header__c', rcrHeaderList);
	}

    private static Map<Id, List<Decimal>> getPurchaseTaxIdToTaxLineRateMap(List<sObject> listToProcess) {
        Set<Id> purchaseTaxIdSet = new Set<Id>();
        for(sObject sObjRec: listToProcess) {
			if(sObjRec.getSObject(Constants.NAMESPACE + 'Vendor__r').get('Purchase_Tax__c') != null) {
				purchaseTaxIdSet.add(String.valueOf(sObjRec.getSObject(Constants.NAMESPACE + 'Vendor__r').get('Purchase_Tax__c')));
			}
        }
        purchaseTaxIdSet.remove(null);
        
        Map<Id, List<Decimal>> purchaseTaxIdToTaxLineRateMap = new Map<Id, List<Decimal>>();
        if(!purchaseTaxIdSet.isEmpty()) {
            if(AccessControl.ifObjectFieldIsAccessible('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Applicable_Taxes__c> applicableTaxList = [Select Sales_Tax__c, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c from Applicable_Taxes__c
                                                          Where Sales_Tax__c IN: purchaseTaxIdSet];
            for(String purchaseTaxId : purchaseTaxIdSet) {
                for(Applicable_Taxes__c appTaxRec : applicableTaxList) {
	                if(appTaxRec.Sales_Tax__c == purchaseTaxId && appTaxRec.Sales_Tax_Item__r.Rate__c != null && appTaxRec.Sales_Tax_Item__r.Rate__c != 0) {
	                    if(!purchaseTaxIdToTaxLineRateMap.containsKey(purchaseTaxId)) {
	                        purchaseTaxIdToTaxLineRateMap.put(purchaseTaxId, new List<Decimal>());
	                    }
	                    purchaseTaxIdToTaxLineRateMap.get(purchaseTaxId).add(appTaxRec.Sales_Tax_Item__r.Rate__c);
	                }
	            }
            }
        }
        return purchaseTaxIdToTaxLineRateMap;
    }
}