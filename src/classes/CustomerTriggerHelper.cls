/**
 * Author: Tarun Khandelwal
 * Since: Nov. 13, 2014
 * Name: AccountTriggerHelper
 * Description: Helper class for triggers on Account object
**/
public without sharing class CustomerTriggerHelper {
    
    // List to store trigger new list
    public static List<Account> accountNewList = new List<Account>();
    
    // List to store trigger old list
    public static List<Account> accountOldList = new List<Account>();
    
    // Map to store new Trigger Map
    public static Map<Id, Account> accountNewMap = new Map<Id, Account>();

    // Map to store Old Trigger Map
    public static Map<Id, Account> accountOldMap = new Map<Id, Account>();
    
    // Trigger run boolean
    public static Boolean isTriggerRun = false;
    
    // Trigger run boolean 
    public static Boolean preventOnAccountingSync = false;
    
    private static BaseIntegrationService integrationRec;
    
    /**
     * Name: accountInsertOperation
     * Desc: When account record is inserted this method executes
     * @return: 
    **/
    public static void accountInsertOperation() {
        handleDefaultPOTypeRecord();
    }
    
    private static void handleDefaultPOTypeRecord() {
        Map<String, PO_Type__c> vendorIdToPOTypeRecMap = new Map<String, PO_Type__c>();
        Set<String> nonVendorCustomerIdSet = new Set<String>();        
        for(Account account : accountNewList) {
        	if(account.Is_Vendor__c && (trigger.isInsert || (trigger.isUpdate && !accountOldMap.get(account.Id).Is_Vendor__c))) {
                PO_Type__c poType = new PO_Type__c( Code__c = 'STANDARD',
                                                    Discount__c = 0,
                                                    IsDefault__c = true,
                                                    Landed_Cost_Adjustment__c = 0,
                                                    Lead_Time__c = 5,
                                                    Usage__c = 'Standard for vendor',
                                                    Vendor__c = account.Id);
                vendorIdToPOTypeRecMap.put(account.Id, poType);
            }
        }        
        if(vendorIdToPOTypeRecMap.size() > 0) {
        	if(trigger.isUpdate) {
        		List<PO_Type__c> existingPOTypeList = [Select Id, Vendor__c from PO_Type__c where Vendor__c IN: vendorIdToPOTypeRecMap.keySet() AND IsDefault__c = true];
        		for(PO_Type__c poTypeRec : existingPOTypeList) {
        			vendorIdToPOTypeRecMap.remove(poTypeRec.Vendor__c);
        		}
        	}	
        	if(vendorIdToPOTypeRecMap.size() > 0) {
        		if(AccessControl.ifObjectFieldIsCreateable('PO_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            	insert vendorIdToPOTypeRecMap.values();
        	}
        }
    }
    
    private static void populateVendorCode(List<Account> newList) {
        if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        Set<String> vendorNameInitialsSet = getVendorNameInitialsSet(newList);
        Map<String, Integer> vendorInitialToLastVendorCodeMap = new Map<String, Integer>();
        if(vendorNameInitialsSet.size() > 0) {
            List<Account> existingVendorList = [SELECT Name, Vendor_Code__c FROM Account WHERE Is_Vendor__c = true 
                                                    AND Vendor_Code__c LIKE: vendorNameInitialsSet Order by CreatedDate DESC, Vendor_Code__c DESC];
            for(Account vendorRec : existingVendorList) {
                String firstThreeLettersOfName = getFirst3Letters(vendorRec.Vendor_Code__c);
                if(!vendorInitialToLastVendorCodeMap.containsKey(firstThreeLettersOfName)) {
                    Integer vendorCountNumber = 0;
                    if(vendorRec.Vendor_Code__c.length() == 5) {
                        try {
                            vendorCountNumber = Integer.valueOf(vendorRec.Vendor_Code__c.subString(3, 5));
                        } catch(System.TypeException e) {
                            continue;
                        }
                    } else {
                        vendorCountNumber = (vendorRec.Vendor_Code__c.length() == 3) ? 0 : -1;
                    }
                    vendorInitialToLastVendorCodeMap.put(firstThreeLettersOfName, vendorCountNumber);
                }
            }
        }
        
        for(Account accRec : newList) {
            if(accRec.Is_Vendor__c && String.isBlank(accRec.Vendor_Code__c)) {
                String firstThreeLettersOfName = getFirst3Letters(accRec.Name);
                if(vendorInitialToLastVendorCodeMap.containsKey(firstThreeLettersOfName)) {
                    Integer lastVendorCount = vendorInitialToLastVendorCodeMap.get(firstThreeLettersOfName);
                    String vendorUniqueCount = (lastVendorCount == -1) ? '' : String.valueOf(++lastVendorCount);
                    vendorInitialToLastVendorCodeMap.put(firstThreeLettersOfName, lastVendorCount);
                    accRec.Vendor_Code__c = firstThreeLettersOfName + ((vendorUniqueCount.length() == 1) ? ('0' + vendorUniqueCount) : vendorUniqueCount);
                } else {
                    vendorInitialToLastVendorCodeMap.put(firstThreeLettersOfName, 0);
                    accRec.Vendor_Code__c = firstThreeLettersOfName;
                }
            }
        }
    }
    
    private static Set<String> getVendorNameInitialsSet(List<Account> newList) {
        Set<String> vendorNameInitialsSet = new Set<String>();
        for(Account accRec : newList) {
            if(accRec.Is_Vendor__c && String.isBlank(accRec.Vendor_Code__c)) {
                String firstThreeLettersOfName = getFirst3Letters(accRec.Name);
                vendorNameInitialsSet.add(firstThreeLettersOfName + '%');
            }
        }
        vendorNameInitialsSet.remove(null);
        return vendorNameInitialsSet;
    }
    
    
    private static String getFirst3Letters(String vendorName) {
        String vendorNameWithoutSpace = vendorName.replaceAll(' ', '');
        return (vendorNameWithoutSpace.length() > 3) ? vendorNameWithoutSpace.subString(0,3).toUpperCase() : vendorNameWithoutSpace.toUpperCase();
    }
    
    /**
     * Name: populatesFieldsBeforeInsert
     * Desc: create Recent Account record
     * @param: 
     * @return: 
    **/
    public static void populatesFieldsBeforeInsert() {
    	populateVendorCode(accountNewList);
        populatesVendorNumberBeforeInsert();
        setDefaultBillingCoutry();
        validateAccountName(accountNewList); // Ticket #12757 - To validate account name as per QB/Xero customer and vendor name validations
    }
    
    private static void setDefaultBillingCoutry() {
    	Boolean isBlankCountry = false; 
        for(Account customerRec : accountNewList) {
        	if(String.isBlank(customerRec.BillingCountry)) {
                isBlankCountry = true;
                break;
            }
        }
        if(isBlankCountry) {
        	if(AccessControl.ifObjectFieldIsAccessible('Country__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        	List<Country__c> countryList = [SELECT Name__c FROM Country__c WHERE Default__c = true AND Visible__c = true];
        	if(countryList.size() > 0) {
        		String defaultCountryName = countryList[0].Name__c;
		        for(Account customerRec : accountNewList) {
		        	if(String.isBlank(customerRec.BillingCountry)) {
		        		customerRec.BillingCountry = defaultCountryName;
		        	}
		        }
        	}
        }
    }
    
    /**
     * Name: populatesVendorNumberBeforeInsert
     * Desc: create Recent Account record
     * @param: 
     * @return: 
    **/
    public static void populatesVendorNumberBeforeInsert() {
    	if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Account> vendorList = [select Name, Vendor_Number_Count__c from Account where Is_Vendor__c = true AND Vendor_Number_Count__c != null order by Vendor_Number_Count__c desc limit 1];
        Integer lastVendorNumberCount; 
        if(vendorList.size() > 0) {
            if(vendorList[0].Vendor_Number_Count__c == null) {
                vendorList[0].Vendor_Number_Count__c = 0;
            }
            lastVendorNumberCount = Integer.valueOf(vendorList[0].Vendor_Number_Count__c);
        } else {
            lastVendorNumberCount = 0;
        }
        for(Account vendor : accountNewList) {
            if(vendor.Is_Vendor__c) {
            	if((trigger.isUpdate && vendor.Vendor_Number_Count__c == null) || trigger.isInsert) {
                	vendor.Vendor_Number_Count__c = ++lastVendorNumberCount;
                }
                String prefix = 'VDR-';
                String vendorNumberUniqueCount = String.valueOf(vendor.Vendor_Number_Count__c);
                vendorNumberUniqueCount = (vendorNumberUniqueCount.length() == 1) ? ('000' + vendorNumberUniqueCount) : (vendorNumberUniqueCount.length() == 2 ? ('00' + vendorNumberUniqueCount) : (vendorNumberUniqueCount.length() == 3 ? ('0' + vendorNumberUniqueCount) : vendorNumberUniqueCount));
                vendor.Vendor_Number__c = prefix + vendorNumberUniqueCount;
            }
        }
    }
    
    public static void populatesAccountingSyncFields() {
    	if(QBUtil.isQBEnabled()) {
            QBSyncFlagService.manageAccountSyncFlag(accountNewList, accountOldMap);
		} else {
            try {
               integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
               IntegrationSyncFlagService.manageAccountSyncFlag(new List<BaseIntegrationService>{integrationRec}, accountNewList, accountOldMap);
            } catch(Exception e) {
            }
        }
    }
    
    public static void setCustomerAndVendorDataForAccountSync() {
        Set<Id> customerIdSet = new Set<Id>();
	    Set<Id> vendorIdSet = new Set<Id>();
    	for(Account acc : accountNewList) {
    		if(QBUtil.isQBEnabled()) {
    			if(acc.availForQBSync__c) {
	                customerIdSet.add(acc.Id);
	    		}
	    		if(acc.Vendor_AvailForQBSync__c) {
	    			vendorIdSet.add(acc.Id);
	    		}
    		} else if(integrationRec != null) {
    	    	if(acc.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.CUSTOMER).Sync_Flag_API_Name__c) != null && 
    	    			Boolean.valueOf(acc.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.CUSTOMER).Sync_Flag_API_Name__c))) {
    	        	customerIdSet.add(acc.Id);
    	    	} 
    	    	if(acc.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.VENDOR).Sync_Flag_API_Name__c) != null && 
    	    			Boolean.valueOf(acc.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.VENDOR).Sync_Flag_API_Name__c))) {
    	    		vendorIdSet.add(acc.Id);
    	    	}
    	    }
    	}
    	  
    	if(QBUtil.isQBEnabled()) {
    		if(customerIdSet.size() > 0 && vendorIdSet.size() > 0) {
	    		CustomerService.syncCustomers(customerIdSet, vendorIdSet);
	    	} else if(customerIdSet.size() > 0) {
	    		CustomerService.syncCustomers(customerIdSet, new Set<Id>());
	    	} else if(vendorIdSet.size() > 0) {
	    		VendorService.syncVendors(vendorIdSet);
	    	}
    	} else {
    		if(customerIdSet.size() > 0 && vendorIdSet.size() > 0) {
	    		IntegrationBatchService.initiateBatch(customerIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.CUSTOMER);
                IntegrationBatchService.initiateBatch(vendorIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.VENDOR);
	    	} else if(customerIdSet.size() > 0) {
	    		IntegrationBatchService.initiateBatch(customerIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.CUSTOMER);
	    	} else if(vendorIdSet.size() > 0) {
	    		IntegrationBatchService.initiateBatch(vendorIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.VENDOR);
	    	}
    	}
    	
    }
    
    /**
     * Name: afterUpdateCalculations
     * Desc: calculation after vendor update
     * @param: 
     * @return: 
    **/
    public static void afterUpdateCalculations() {
    	handleDefaultPOTypeRecord();
    	calculatePartsRetailPrice();
    }
    
    /**
     * Name: calculatePartsRetailPrice
     * Desc: calculate retail price of all parts of a vendor 
     * @param:  
     * @return: 
    **/
    private static void calculatePartsRetailPrice() {
    	Set<Id> vendorIdSet = new Set<Id>();
    	for(Account accountRec: accountNewList)	{
    		if(accountRec.Is_Vendor__c)	{
    			if(accountRec.Is_Calculate_Part_Retail_Price__c || (accountOldMap.get(accountRec.Id).Is_Calculate_Part_Retail_Price__c && !accountNewMap.get(accountRec.Id).Is_Calculate_Part_Retail_Price__c)) {
    				vendorIdSet.add(accountRec.Id);
    			}
    		}
    	}
    	
    	if(vendorIdSet.size() > 0) {
    		CalculatePartRetailPrice_Batch batchObj = new CalculatePartRetailPrice_Batch(vendorIdSet, 50);
    	}
    }
    
    public static void updatePartIdTextField() {
        Set<Id> vendorIdSet = new Set<Id>();
        for(Account vendorRec : accountNewList) {
            if((vendorRec.Vendor_Code__c != accountOldMap.get(vendorRec.Id).Vendor_Code__c) && vendorRec.Is_Vendor__c) {
                vendorIdSet.add(vendorRec.Id);
            }
        }
        if(vendorIdSet.size() > 0) {
            Database.executeBatch(new UpdatePartIdTextBatch(vendorIdSet),500);
        }
    }

    private static void validateAccountName(List<Account> accountList) {
        for(Account acc : accountList) {
            if(trigger.isInsert) {
            if(String.isNotBlank(acc.FirstName__c) && validateName(acc.FirstName__c)) {
                throw new BlackPurlException('First name should have valid set of characters');
            } else if(String.isNotBlank(acc.LastName__c) &&  validateName(acc.LastName__c)){
                throw new BlackPurlException('Last name should have valid set of characters');
            } else if(String.isNotBlank(acc.Company_Name__c) && validateName(acc.Company_Name__c)){
                throw new BlackPurlException('Company name should have valid set of characters');
            } else if(String.isNotBlank(acc.Name) && validateName(acc.Name)){
                throw new BlackPurlException('Company name should have valid set of characters');
            }
        }
    }
    }

    private static Boolean validateName(String name) {
        Boolean isContains = false;
        if(name.containsIgnoreCase(':') || name.containsIgnoreCase('>') || name.containsIgnoreCase('<')) {
            isContains = true;
        }
        return isContains;
    }
}