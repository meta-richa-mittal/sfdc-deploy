/** Author: Nidhi Sharma
 * Since: Dec 13, 2023
 * Name: CustomerVendorStateUpdateBatch
**/
global without sharing class CustomerVendorStateUpdateBatch extends PostInstallScriptBaseBatch {

    global CustomerVendorStateUpdateBatch() {
        this.scriptName = 'executeCustomerVendorStateUpdateBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        Set<String> countrySet = DataLoadForCountryState.countryToStateToCodeMap.keyset();
        String strQuery = 'SELECT Id, BillingCountry, BillingState, ShippingCountry, ShippingState FROM Account WHERE (Is_Customer__c = true OR Is_Vendor__c = true) AND (BillingCountry IN :countrySet OR ShippingCountry IN :countrySet)';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> accList) {
        Map<String, Map<String, String>> countryNameToStateNameToCodeMap = getCountryNameToStateNameToCodeMap();
        for(Account accRec : (List<Account>)accList) {
            if(String.isNotBlank(accRec.BillingCountry) && String.isNotBlank(accRec.BillingState) && countryNameToStateNameToCodeMap.get(accRec.BillingCountry.toUpperCase()) != null) {
                if(countryNameToStateNameToCodeMap.get(accRec.BillingCountry.toUpperCase()).get(accRec.BillingState.toUpperCase()) != null) {
                    accRec.BillingState = countryNameToStateNameToCodeMap.get(accRec.BillingCountry.toUpperCase()).get(accRec.BillingState.toUpperCase());
                }
            }
            if(String.isNotBlank(accRec.ShippingCountry) && String.isNotBlank(accRec.ShippingState) && countryNameToStateNameToCodeMap.get(accRec.ShippingCountry.toUpperCase()) != null) {
                if(countryNameToStateNameToCodeMap.get(accRec.ShippingCountry.toUpperCase()).get(accRec.ShippingState.toUpperCase()) != null) {
                    accRec.ShippingState = countryNameToStateNameToCodeMap.get(accRec.ShippingCountry.toUpperCase()).get(accRec.ShippingState.toUpperCase());
                }
            }
        }
        CustomerTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Account', accList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {}

    private static Map<String, Map<String, String>> getCountryNameToStateNameToCodeMap() {
        Map<String, Map<String, String>> countryNameToStateNameToCodeMap = new Map<String, Map<String, String>>(); 
		for(State__c state : [SELECT Id, Name__c, Display_Name__c, Country__r.Name__c FROM State__c WHERE Country__r.Name__c IN: DataLoadForCountryState.countryToStateToCodeMap.keySet()]) {
			if(!countryNameToStateNameToCodeMap.containsKey(state.Country__r.Name__c.toUpperCase())) countryNameToStateNameToCodeMap.put(state.Country__r.Name__c.toUpperCase(), new Map<String, String>());
            countryNameToStateNameToCodeMap.get(state.Country__r.Name__c.toUpperCase()).put(state.Name__c.toUpperCase(), state.Display_Name__c);
		}
        return countryNameToStateNameToCodeMap;
    }
}