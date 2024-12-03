/**
 * Author: Tarun Khandelwal
 * Since: Nov. 13, 2014
 * Name: AccountTriggerHelper
 * Description: Helper class for triggers on Account object
**/
public without sharing class CustomerTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;
    
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

    public static Boolean isBypassValidation;
    
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
        IntegrationSyncFlagService.manageAccountSyncFlag(accountNewList, accountOldMap);
    }
    
    public static void setCustomerAndVendorDataForAccountSync() {
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(accountNewList, IntegrationUtility.CUSTOMER);
        IntegrationSyncFlagService.checkAndInitiateSyncBatch(accountNewList, IntegrationUtility.VENDOR);
    	
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
    		if(!System.isBatch() && !System.isFuture()) {
                CalculatePartRetailPrice_Batch batchObj = new CalculatePartRetailPrice_Batch(vendorIdSet, 50);
            } else {
                String jobName = 'CalculatePartRetailPrice_Batch';
                try {
                    for(CronTrigger alreadyScheduledJob : [SELECT Id FROM CronTrigger WHERE NextFireTime = null AND CronJobDetail.Name LIKE :(jobName+'%')]) {
                        system.abortJob(alreadyScheduledJob.Id);
                    }
                    System.schedule(jobName, BPUtility.getCronExpForGivenTime(5), new CalculatePartRetailPriceScheduler(vendorIdSet));
                } catch(AsyncException asyncEx) {
                    if(asyncEx.getMessage().contains('is already scheduled for execution.')) {    
                        jobName += '-' + GuidUtil.generateGuid();
                        System.schedule(jobName, BPUtility.getCronExpForGivenTime(5), new CalculatePartRetailPriceScheduler(vendorIdSet));
                    }
                }
            }
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
        for(String specialChar: Customer_Service.specialCharsNotAllowedInNameSet) {
            if(name.containsIgnoreCase(specialChar)) {
                isContains = true;
                break;
            }
        }
        return isContains;
    }
    
    public static void validateVendorDeletion() {
        Map<String, Account> vendorIdToRecMap = new Map<String, Account>([Select Id,
																		(SELECT Id FROM Parts__r LIMIT 1),
															            (SELECT Id FROM Products__r LIMIT 1),
																		(SELECT Id FROM Vendor_Order_Headers__r LIMIT 1),
															            (SELECT Id FROM Return_VO_Headers__r LIMIT 1),
															            (SELECT Id FROM Vendor_Receiving_Headers__r LIMIT 1),
															            (SELECT Id FROM Vendor_Invoicing_Headers__r LIMIT 1),
															            (SELECT Id FROM Customer_Owned_Units1__r LIMIT 1),
															            (SELECT Id FROM Unit_Prices_Costs__r LIMIT 1)
															             FROM Account WHERE Id IN: accountOldList AND Is_Vendor__c = true]);

        for(Account vendorToDelete : accountOldList) {
	        if(vendorIdToRecMap.containsKey(vendorToDelete.Id)) {
	            Account accRec = vendorIdToRecMap.get(vendorToDelete.Id);
	            if(accRec.Parts__r.size() > 0 || accRec.Products__r.size() > 0 || accRec.Vendor_Order_Headers__r.size() > 0 
	                    || accRec.Return_VO_Headers__r.size() > 0 || accRec.Vendor_Receiving_Headers__r.size() > 0 || accRec.Vendor_Invoicing_Headers__r.size() > 0
	                    || accRec.Customer_Owned_Units1__r.size() > 0 || accRec.Unit_Prices_Costs__r.size() > 0) {
	                vendorToDelete.addError('Cannot delete vendor as it has linked entities/purchase transactions.');
	            }
            }
        }	
    }

    public static void validateFXVendorOnUpdate() {
        for(Account vendorRec : accountNewList) {
	        if(vendorRec.Is_Foreign_Vendor__c != accountOldMap.get(vendorRec.Id).Is_Foreign_Vendor__c || vendorRec.Country__c != accountOldMap.get(vendorRec.Id).Country__c) {
                vendorRec.addError(Constants.restrictionErrorForFXCodeChanges);
            }   
        }
    }

    public static void validateCustomerVendorForMarkingInactive() {
        Set<Id> entityIdSet = new Set<Id>();
        String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
        if(String.isBlank(activeIntegrationName)) return;

        for(Account accRec: accountNewList) {
            String accountingId; 
            if(!accRec.Active__c && accountOldMap.get(accRec.Id).Active__c) {
                if(accRec.Is_Customer__c) {
                    if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
                        accountingId = accRec.AccountingId__c;
                    } else if(activeIntegrationName == XeroUtility.XERO) {
                        accountingId = accRec.Xero_Customer_Accounting_Id__c;
                    }
                    if(String.isNotBlank(accountingId)) {
                        entityIdSet.add(accRec.Id);
                    }
                } else if(accRec.Is_Vendor__c) {
                    if(activeIntegrationName == QBUtil.QUICKBOOKS_ONLINE) {
                        accountingId = accRec.Vendor_AccountingId__c;
                    } else if(activeIntegrationName == XeroUtility.XERO) {
                        accountingId = accRec.Xero_Vendor_Accounting_Id__c;
                    }
                    if(String.isNotBlank(accountingId)) {
                        entityIdSet.add(accRec.Id);
                    }
                }
            }
        }

        if(!isBypassValidation) {
            for(Id sfId: entityIdSet) {
                accountNewMap.get(sfId).addError('Use Blackpurl Customer/Vendor screen to mark customer/vendor as inactive.');
            }
        }
    }
}