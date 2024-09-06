public without sharing class PlivoIncomingMessageService {

    public static void handleIncomingMessage(String messageString) {
        try {
            MessageWrapper messageObj = (MessageWrapper)System.JSON.deserialize(messageString, MessageWrapper.class);
            removeCountryCodes(messageObj);
            attachMessageToCustomer(messageObj); 
        } catch(Exception e) {
            new LogService().createErrorLog('ReceiveMessageResource', 'handleIncomingMessage()', e.getMessage(), null, e.getStackTraceString(), 
                                            messageString, 'Plivo', true, 'error');
        }
    }

    public static void attachMessageToCustomer(MessageWrapper messageObj){
        String customerId = getCustomerIdByPhoneNumber(messageObj.CustomerPhone);
        MessageHistoryService.addMessageHistoryRecord(customerId, messageObj);
    }

    public static String getCustomerIdByPhoneNumber(String customerPhoneNumber) {
    	String customerId;
    	if(String.isNotBlank(customerPhoneNumber)) {
    		customerId = checkExactMatch(customerPhoneNumber);
    		if(String.isBlank(customerId)) {
    			if(customerPhoneNumber.length() > 10) {
    				customerPhoneNumber = customerPhoneNumber.substring(customerPhoneNumber.length() - 10 , customerPhoneNumber.length());
    				customerId = checkExactMatch(customerPhoneNumber);
    			}
    			if(String.isBlank(customerId) && customerPhoneNumber.length() > 9) {
    				customerPhoneNumber = customerPhoneNumber.substring(customerPhoneNumber.length() - 9 , customerPhoneNumber.length());
    				customerId = checkExactMatch(customerPhoneNumber);
    			}
    		}
    	}
        return customerId;
    }
	
    private static void removeCountryCodes(MessageWrapper messageObj) {
        if(messageObj.CustomerPhone != null) {
            messageObj.CustomerPhone = removeCountryCodeFromPhoneNumber(messageObj.CustomerPhone);
        }
        if(messageObj.DealershipPhone != null) {
            messageObj.DealershipPhone = removeCountryCodeFromPhoneNumber(messageObj.DealershipPhone);
        }
    }
    
    public static String removeCountryCodeFromPhoneNumber(String phoneNumber) {
        List<Country_Area_Code__mdt> countryCodeList = [SELECT Area_Code__c, Country__c FROM Country_Area_Code__mdt limit: SOQLUtil.getAvailableQueryRowsLimit()];
        for(Country_Area_Code__mdt countryCode : countryCodeList) {
            if(phoneNumber.startsWith(countryCode.Area_Code__c)) {
                phoneNumber = phoneNumber.replaceFirst(countryCode.Area_Code__c, '');
                if(countryCode.Area_Code__c == '61') {
                    phoneNumber = '0' + phoneNumber;
                }
                break;
            }
        }
        return phoneNumber;
    }
	
	private static String checkExactMatch(String phoneNumber) {
		List<Account> customerList = [Select Id From Account Where Is_Customer__c = true AND (Home_Number__c =: phoneNumber OR Work_Number__c =: phoneNumber OR Mobile__c =: phoneNumber) Order By LastModifiedDate DESC LIMIT 1];
	    if(customerList.size() == 0) {
	    	phoneNumber = '%' + phoneNumber;
	    	customerList = [Select Id From Account Where Is_Customer__c = true AND (Home_Number__c Like: phoneNumber OR Work_Number__c Like: phoneNumber OR Mobile__c Like: phoneNumber) Order By LastModifiedDate DESC LIMIT 1];
	    }
	    if(customerList.size() > 0) {
	    	return customerList[0].Id;
	    }
	    return null;
	}
	
    public class MessageWrapper {
        public String CustomerPhone;
        public String DealershipPhone;
        public String MessageUUID;
        public String MessageText;
    }
}