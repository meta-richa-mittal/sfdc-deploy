/** 
* Author: Tarun Khandelwal
* Since: Nov 25, 2020
* Name: SMSTemplateVariableParser 
* Description: Apex class which contains Text template variables parsing logic
**/
public without sharing class SMSTemplateVariableParser {
    
    public static Business_Profile__c businessProfile;
    public static final String STORE_NAME_VAR = '[store_name]';
    public static final String STORE_PHONE_VAR = '[store_phone]';
    public static final String CUSTOMER_VAR = '[customer]';
    public static final String PARTS_READY_THIS_CO_VAR = '[parts_ready_qty_this_CO]';
    public static final String PARTS_READY_ALL_CO_VAR = '[parts_ready_qty_all_CO]';
    public static final String SERVICE_JOB_UNIT_VAR = '[service_job_unit]';
    public static final String SERVICE_JOB_TOTAL_VAR = '[service_job_total]';
    
    public static String parse(String templateId, String customerId, String coHeaderId) {
        String templateBody = getTemplateBody(templateId);
        List<String> variableNameList = TextMessageTemplateService.getSMSTemplateVarLabels();
        

        for(String variableName : variableNameList) {
            if(templateBody != null && templateBody.contains(variableName)) {
                templateBody = replaceVariable(templateBody, variableName, customerId, coHeaderId);
            }
        }
        return templateBody;
    }
    
    public static String replaceVariable(String templateBody, String variableName, String customerId, String coHeaderId) {
        if(variableName == STORE_NAME_VAR) {
            templateBody = templateBody.replace(STORE_NAME_VAR, getStoreShortName());
            
        } else if(variableName == STORE_PHONE_VAR) {
            templateBody = templateBody.replace(STORE_PHONE_VAR, getStorePhoneNumber());
            
        } else if(variableName == CUSTOMER_VAR) {
            templateBody = templateBody.replace(CUSTOMER_VAR, getCustomerName(customerId));
            
        } else if(variableName == PARTS_READY_THIS_CO_VAR) {
            templateBody = templateBody.replace(PARTS_READY_THIS_CO_VAR, getPartsReadyQtyThisCO(coHeaderId));
            
        } else if(variableName == PARTS_READY_ALL_CO_VAR) {
            templateBody = templateBody.replace(PARTS_READY_ALL_CO_VAR, getPartsReadyQtyAllCO(customerId));
            
        } else if(variableName == SERVICE_JOB_UNIT_VAR) {
            templateBody = templateBody.replace(SERVICE_JOB_UNIT_VAR, getServiceJobUnit(coHeaderId));
            
        } else if(variableName == SERVICE_JOB_TOTAL_VAR) {
            templateBody = templateBody.replace(SERVICE_JOB_TOTAL_VAR, getServiceJobTotal(coHeaderId));
            
        }
        return templateBody;
    }
    
    
    /*public static Set<String> getVariableNameSet() {
        return new Set<String>{'[store_name]', '[store_phone]', '[customer]', '[parts_ready_qty_this_CO]', '[parts_ready_qty_all_CO]', 
                                '[service_job_unit]', '[service_job_total]'};
    }*/
    
    public static String getTemplateBody(String templateId) {
        List<Text_Message_Template__c> templateList = SMSTemplateSOQLUtil.getSMSTemplates(new Map<String, String>{'Id' => templateId});
        if(templateList.size() > 0) {
            return templateList[0].Template_Body__c;
        } else {
            throw new BlackPurlException('Template not found.');
        }
    }
    
    public static String getStoreShortName() {
        if(businessProfile == null) {
            businessProfile = getBusinessProfile();
        }
        return (businessProfile.Abbreviated_Business_Name__c != null ? businessProfile.Abbreviated_Business_Name__c : '');
    }
    
    public static String getStorePhoneNumber() {
        if(businessProfile == null) {
            businessProfile = getBusinessProfile();
        }
        return (businessProfile.Formatted_Business_Number__c != null ? businessProfile.Formatted_Business_Number__c : '');
    }
    
    public static String getCustomerName(String customerId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Account')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Account> customerList = [SELECT FirstName__c, Name, Type__c FROM Account WHERE Id =: customerId AND Is_Customer__c = true];
        if(customerList.size() > 0) {
            return (customerList[0].Type__c == 'Individual') ? customerList[0].FirstName__c : customerList[0].Name;
        } else {
            return '';
        }
    }
    
    public static String getPartsReadyQtyThisCO(String coHeaderId) {
        if(String.isBlank(coHeaderId)) {
            return 'NO'; 
        }
        if(!AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Line_Item__c> coliList = [SELECT Invoice_Number__c, Qty_To_Order__c FROM CO_Line_Item__c WHERE CO_Header__c =: coHeaderId 
                                            AND Part__c != null AND Service_Order_Line_Item__c = null AND Deal__c = null];
        
        return getPartsReadyQtyFromCOLineItemList(coliList);
    }
    
    public static String getPartsReadyQtyAllCO(String customerId) {
        if(String.isBlank(customerId)) {
            return 'NO'; 
        }
        if(!AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Line_Item__c> coliList = [SELECT Invoice_Number__c, Qty_To_Order__c FROM CO_Line_Item__c WHERE CO_Header__r.Order_status__c = 'Open' 
                                            AND CO_Header__r.Customer__c =: customerId AND Part__c != null AND
                                                Service_Order_Line_Item__c = null AND Deal__c = null ];
        
        return getPartsReadyQtyFromCOLineItemList(coliList);
    }
    
    public static String getPartsReadyQtyFromCOLineItemList(List<CO_Line_Item__c> coliList) {
        String qty = 'NO';
        if(coliList.size() > 0) {
            Integer invoicedPart = 0;
            Integer readyToInvoicePart = 0;
            Integer notReadyToInvoicePart = 0;
            for(CO_Line_Item__c coliRec : coliList) {
                if(coliRec.Invoice_Number__c != null) {
                    invoicedPart++;
                } else if(coliRec.Qty_To_Order__c > 0) {
                    notReadyToInvoicePart++;
                } else {
                    readyToInvoicePart++;
                }
            }
            if(invoicedPart == coliList.size()) {
                qty = 'NO';
            } else {
                qty = readyToInvoicePart + ' of ' + (readyToInvoicePart + notReadyToInvoicePart);
            }
        }
        return qty;
    }
    
    public static String getServiceJobUnit(String coHeaderId) {
        String unit = 'NO';
        if(String.isBlank(coHeaderId)) {
            return unit;
        }
        if(!AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Header__c> soHeaderList = [SELECT Customer_Owned_Unit__c, Customer_Owned_Unit__r.Year__c, Customer_Owned_Unit__r.Make_Name__c 
                                                        FROM Service_Order_Header__c WHERE CO_Header__c =: coHeaderId 
                                                        Order by CreatedDate ASC limit 1];
        
        if(soHeaderList.size() > 0 && soHeaderList[0].Customer_Owned_Unit__c != null) {
            unit = (soHeaderList[0].Customer_Owned_Unit__r.Year__c != null ? String.valueOf(soHeaderList[0].Customer_Owned_Unit__r.Year__c) : '') + ' ' + 
                    (soHeaderList[0].Customer_Owned_Unit__r.Make_Name__c != null ? soHeaderList[0].Customer_Owned_Unit__r.Make_Name__c : '');
        }
        return unit;
    }
    
    public static String getServiceJobTotal(String coHeaderId) {
        String total = 'NO';
        if(String.isBlank(coHeaderId)) {
            return total;
        }
        if(!AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Header__c> soHeaderList = [SELECT Id, Total__c FROM Service_Order_Header__c WHERE CO_Header__c =: coHeaderId 
                                                        AND Transaction_Type__r.Type__c = 'Customer'];
        
        Decimal serviceJobTotal = 0;
        if(soHeaderList.size() > 0) {
            Set<Id> sohIds = new Set<Id>();
	        for(Service_Order_Header__c soHeaderRec : soHeaderList) {
	            serviceJobTotal += soHeaderRec.Total__c;
	            sohIds.add(soHeaderRec.Id);
	        }
	        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
	        if(!isTaxIncludingPricing) {
	            TaxCalculation.isInvoiced = false;
	            List<Individual_Tax__c> individualItemsList = COService.getConditionalIndividualTaxList(isTaxIncludingPricing, TaxCalculation.isInvoiced, 
                                                                new List<Id>(), new List<Id>(), sohIds, new List<Id>());
	            Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList);
	            TaxCalculation.isInvoiced = true;
	            Decimal totalTax = 0;
	            for(String salesTaxName : salesTaxNameToTaxValue.keyset()) {
	                totalTax += salesTaxNameToTaxValue.get(salesTaxName);
	            }
	            serviceJobTotal = serviceJobTotal + totalTax;
	        }
        }
        
        if(serviceJobTotal > 0) {
            total = '$' + BPUtility.formatToDecimal(serviceJobTotal);
        }
        return total;
    }
    
    public static Business_Profile__c getBusinessProfile() {
        if(!AccessControl.ifObjectFieldIsAccessible('Business_Profile__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Business_Profile__c> businessProfileList = [SELECT Formatted_Business_Number__c, Abbreviated_Business_Name__c FROM Business_Profile__c limit 1];
        if(businessProfileList.size() > 0) {
            return businessProfileList[0];
        } else {
            throw new BlackPurlException('Business Profile not found.');
        }
    }
}