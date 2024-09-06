/**
 * Author: Richa Mittal
 * Since: May 10, 2022
 * Name: EscalatorService
 * Description: EscalatorService class.
**/
public without sharing class EscalatorService {

    private static String markupFieldLabelStartText = 'Markup_';
    private static String maxAmountFieldLableStartText = 'Max_Amount_';
    private static String markupWrapperKeyStartText = 'Markup';
    private static String maxAmountWrapperKeyStartText = 'MaxAmount';
    
    public static Escalator__c setMarkupData(Escalator escalatorObj, Escalator__c escalatorRec, String priceFileMappingId, String vendorId, String typeValue) {
		if(escalatorObj == null) return null;
        if(escalatorRec == null) escalatorRec = new Escalator__c(APF_Mapping__c = priceFileMappingId, Vendor__c = vendorId, Type__c = typeValue);
		Map<String, Object> escalatorObjMap = (Map<String, Object>)JSON.deserializeUntyped(system.JSON.serialize(escalatorObj));
        for(Integer i = 1; i <= EscalatorUtil.MAX_MARKUP_TIERS; i++) {
            escalatorRec.put(markupFieldLabelStartText + i + '__c', (Decimal)escalatorObjMap.get(markupWrapperKeyStartText + i));
            if(i != EscalatorUtil.MAX_MARKUP_TIERS) {
                escalatorRec.put(maxAmountFieldLableStartText + i + '__c', (Decimal)escalatorObjMap.get(maxAmountWrapperKeyStartText + i));
            }
        }
		return escalatorRec;
	}

    public static Decimal getMarkupValue(Decimal baseValue, Escalator__c escalatorRec) {
        if(escalatorRec == null) return 0;
        for(Integer i = 1; i <= EscalatorUtil.MAX_MARKUP_TIERS; i++) {
            if(i == EscalatorUtil.MAX_MARKUP_TIERS) {
                return (Decimal)escalatorRec.get(markupFieldLabelStartText + EscalatorUtil.MAX_MARKUP_TIERS + '__c');
            } else {
                Decimal fieldValue = (Decimal)escalatorRec.get(maxAmountFieldLableStartText + i + '__c');
                if(fieldValue == null || baseValue <= fieldValue) {
                    return (Decimal)escalatorRec.get(markupFieldLabelStartText + i + '__c');
                }
            }
        }
        return 0;
    }

    public static Map<String, Escalator__c> getVendorIdToEscalatorRecMap(List<Part__c> partList) {
        Set<String> vendorIdSet = new Set<String>();
        for(Part__c partRec: partList) {
            vendorIdSet.add(partRec.Vendor__c);
        }
        List<Escalator__c> escalatorList = EscalatorSOQLUtil.getEscalatorsForVendors(vendorIdSet);
        Map<String, Escalator__c> vendorIdToEscalatorRecMap = new Map<String, Escalator__c>();
        for(Escalator__c escRec: escalatorList) {
            vendorIdToEscalatorRecMap.put(escRec.Vendor__c, escRec);
        }
        return vendorIdToEscalatorRecMap;
    }

    public static Escalator getVendorPricingData(String vendorId) {
        List<Escalator__c> escalatorList = EscalatorSOQLUtil.getEscalatorsForVendors(new Set<String>{vendorId});
        if(escalatorList.size() > 0) return new Escalator(escalatorList[0]);
        return null;
    }
}