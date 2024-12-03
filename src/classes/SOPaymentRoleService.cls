public without sharing class SOPaymentRoleService {
    
    public static void refreshIndividualTaxes(List<Id> soHeaderIdList) {
		refreshIndividualTaxes(soHeaderIdList, false);
	}

    public static void refreshIndividualTaxes(List<Id> soHeaderIdList, Boolean isRefreshTax) {
		List<SO_Payment_Role__c> soPaymentRoleList  = [SELECT Id, Applicable_Tax__c, Total_Amount__c, Service_Order_Header__r.CO_Header__c, Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c, Service_Order_Header__r.Provider__c FROM SO_Payment_Role__c WHERE recordType.Name = 'Deductible' AND Service_Order_Header__c IN: soHeaderIdList];
        DMLUtility.deleteSobjectList('Individual_Tax__c', [select Id from Individual_Tax__c where SO_Payment_Role__c IN: soPaymentRoleList]);
		insertIndividualTaxes(soPaymentRoleList, isRefreshTax);
	}

    public static void insertIndividualTaxes(List<SO_Payment_Role__c> soPaymentRoleList) {
        insertIndividualTaxes(soPaymentRoleList, false);
    }

	public static void insertIndividualTaxes(List<SO_Payment_Role__c> soPaymentRoleList, Boolean isRefreshTax) {
        TaxEngine.applySalesTaxOnSOPRList(soPaymentRoleList, isRefreshTax);
    }
}