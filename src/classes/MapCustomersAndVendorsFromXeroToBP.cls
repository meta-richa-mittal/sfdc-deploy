/** 
* Author: Balveer Choudhary
* Since: March 15, 2023
* Name: MapCustomersAndVendorsFromXeroToBP 
* Description: Batch class for fetching contacts from xero and map to BP customer/vendor.
**/
global without sharing class MapCustomersAndVendorsFromXeroToBP implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    
    public Integer APICounter = 1;
    public Boolean recordFound = false;
    public List<IFW_IntegrationConfig__c> integrationConfigList;
	public String defaultCustomerAccountTypeId;
	public String defaultVendorAccountTypeId;
    public String defaultPriceLevelId;
	public String defaultPurchaseTaxId;
    
    global MapCustomersAndVendorsFromXeroToBP() {}
    
    global MapCustomersAndVendorsFromXeroToBP(Integer APICounter) {
        this.APICounter = APICounter;
    }
    
    global Iterable<Integer> start(Database.BatchableContext bc) {
		//Default account type for customers and vendors
		List<Account_Type__c> accTypeList = [Select Id, Applies_To__c From Account_Type__c Where (Applies_To__c = 'Customers' OR Applies_To__c = 'Vendors') AND Active__c = true AND Default__c = true Limit 2];
        for(Account_Type__c accType : accTypeList) {
			if(accType.Applies_To__c == 'Customers') {
				defaultCustomerAccountTypeId = accType.Id;
			} else if(accType.Applies_To__c == 'Vendors') {
				defaultVendorAccountTypeId = accType.Id;
			}
		}
		// Default price level for customers
        List<Price_Level__c> priceLevelList = [Select Id From Price_Level__c Where Active__c = true AND Default__c = true Limit 1];
        if(priceLevelList.size() > 0) {
            defaultPriceLevelId = priceLevelList[0].Id;
        }
		// Default Purchase Tax for vendors
        defaultPurchaseTaxId = GeneralConfiguration.getOrderingTaxRate();
        if(String.isBlank(defaultPurchaseTaxId)) {
            List<Sales_Tax__c> salesTaxList = [Select Id From Sales_Tax__c Where Tax_Type__c = 'Purchase' AND Active__c = true AND Default__c = true Limit 1];
            if(salesTaxList.size() > 0) {
                defaultPurchaseTaxId = salesTaxList[0].Id;
            }
        }
        return new List<Integer>{APICounter};
    }
    
    global void execute(Database.batchableContext bc, List<Integer> apiCountList) {
		
    	if(integrationConfigList == null) {
			integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(XeroUtility.XERO, new Map<String, String>{IntegrationUtility.CONTACTS => IntegrationUtility.RETRIEVE_ACTION});
			if(integrationConfigList.isEmpty()) throw new BlackPurlException('IFW record for ' + XeroUtility.XERO + ' doesn\'t exists');
    	}
        
        XeroResponseWrapper responseWrapper = getContactsFromXero(APICounter);
        if(responseWrapper != null && responseWrapper.Contacts != null && responseWrapper.Contacts.size() > 0) {
        	recordFound = true;
        	updateCustomerVendorInBlackPurl(responseWrapper);
        }
    }
    
    global void finish(Database.batchableContext bc) {
        APICounter++;
        if(!Test.isRunningTest() && recordFound) {
            Database.executeBatch(new MapCustomersAndVendorsFromXeroToBP(APICounter));
        }
    }
    
    private XeroResponseWrapper getContactsFromXero(Integer APICounter) {
    	XeroResponseWrapper responseWrapper;
        Map<String, String> urlParamMap = new Map<String, String>{'page' => String.valueOf(APICounter)};
        HttpResponse response = BaseIntegration.performCallout(integrationConfigList[0], integrationConfigList[0].IFW_IntegrationConfigItems__r[0], null, new List<CustomHttpHeaderWrapper>(), urlParamMap);
        update integrationConfigList;
        
        if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            responseWrapper = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
        }
        return responseWrapper;
    }

    private void updateCustomerVendorInBlackPurl(XeroResponseWrapper responseWrapper) {
    	Map<String, XeroContactDTO> contactNameToXeroContactRecMap = new Map<String, XeroContactDTO>();
		Set<String> ctmNumberSet = new Set<String>(); 
		Set<String> vdrNumberSet = new Set<String>(); 
        for(XeroContactDTO xeroContactRec : responseWrapper.Contacts) {
			if(xeroContactRec.Name.containsIgnoreCase(' CTM-')) {
				ctmNumberSet.add('CTM-' + xeroContactRec.Name.substringAfter(' CTM-'));
			} else if(xeroContactRec.Name.containsIgnoreCase(' VDR-')){
				vdrNumberSet.add('VDR-' + xeroContactRec.Name.substringAfter(' VDR-'));
			}
            contactNameToXeroContactRecMap.put((xeroContactRec.Name).toLowerCase(), xeroContactRec);
        }
        
        if(contactNameToXeroContactRecMap.size() > 0) {
        	List<Account> accList = [SELECT Id, Name, Email__c, Other_Email__c, Work_Email__c, Is_Customer__c, Is_Vendor__c, Is_Foreign_Vendor__c, Country__r.Currency_Code__c, Customer_Number__c, Vendor_Number__c FROM Account 
        								WHERE (Is_Customer__c = true OR Is_Vendor__c = true) AND (Customer_Number__c IN :ctmNumberSet OR Vendor_Number__c IN :vdrNumberSet OR Customer_Number__c = null OR Vendor_Number__c = null OR Name IN :contactNameToXeroContactRecMap.keySet())];
        	
			String accName;
			String customerOrVendorNumber;
			String accNameAndNumber;
        	Map<String, List<Account>> fullNameToListOfCustomers = new Map<String, List<Account>>();
        	Map<String, List<Account>> fullNameToListOfVendors = new Map<String, List<Account>>();

        	for(Account accRec: accList) {
        		accName = (accRec.Name).toLowerCase();
				customerOrVendorNumber = (accRec.Is_Customer__c == true) ? (accRec.Customer_Number__c != null ? accRec.Customer_Number__c : '') : (accRec.Vendor_Number__c != null ? accRec.Vendor_Number__c : '');
				accNameAndNumber = (String.isNotBlank(customerOrVendorNumber) ? (accName + ' ' + customerOrVendorNumber.toLowerCase()) : accName );

        		if(accRec.Is_Customer__c) {
        			if(!fullNameToListOfCustomers.containsKey(accName)) {
        				fullNameToListOfCustomers.put(accName, new List<Account>());
        			}
					if(!fullNameToListOfCustomers.containsKey(accNameAndNumber)) {
						fullNameToListOfCustomers.put(accNameAndNumber, new List<Account>());
					}
        			fullNameToListOfCustomers.get(accName).add(accRec);
					fullNameToListOfCustomers.get(accNameAndNumber).add(accRec);
        		} else if(accRec.Is_Vendor__c) {
        			if(!fullNameToListOfVendors.containsKey(accName)) {
        				fullNameToListOfVendors.put(accName, new List<Account>());
        			}
					if(!fullNameToListOfVendors.containsKey(accNameAndNumber)) {
        				fullNameToListOfVendors.put(accNameAndNumber, new List<Account>());
        			}
        			fullNameToListOfVendors.get(accName).add(accRec);
					fullNameToListOfVendors.get(accNameAndNumber).add(accRec);
        		}
        	}
        	
        	List<Account> accountListToUpsert = new List<Account>();
    		accountListToUpsert.addAll(mapContactFromXero('Customer', fullNameToListOfCustomers, contactNameToXeroContactRecMap));
    		accountListToUpsert.addAll(mapContactFromXero('Vendor', fullNameToListOfVendors, contactNameToXeroContactRecMap));
    		if(accountListToUpsert.size() > 0) {
				AccessControl.checkObjectIsCreatable('Account');
				AccessControl.checkObjectIsUpdatable('Account');
				CustomerTriggerHelper.isForceStopTrigger = true;
				List<Database.UpsertResult> upsertResultList = Database.upsert(accountListToUpsert, false);
				CustomerTriggerHelper.isForceStopTrigger = false;
				
				List<Log__c> logList = new List<Log__c>();
				for(Integer i = 0; i < upsertResultList.size(); i++) {
					if(!upsertResultList[i].isSuccess()) {
						Log__c logRec = new Log__c();
						logRec.Type__c = 'Info';
						logRec.Apex_Class__c = 'FetchVendorFromQBBatch';
						logRec.Method_Params__c = accountListToUpsert[i].AccountingId__c;
						logRec.Log_Info__c = upsertResultList[i].getErrors()[0].getFields() + '  \n' + upsertResultList[i].getErrors()[0].getMessage();
						logList.add(logRec);
					}
				}
				if(logList.size() > 0) {
					insert logList;
				}
	    	}
        }
    }
    
    private List<Account> mapContactFromXero(String accType, Map<String, List<Account>> nameToListOfAccRecs, Map<String, XeroContactDTO> contactNameToXeroContactRecMap) {
		List<Account> accountListToUpsert = new List<Account>();
		String homeCurr = AccountingUtil.getHomeCurrency();

		Map<String, Country__c> currCodeToCountryRecMap = new Map<String, Country__c>();
		for(Country__c countryRec: [SELECT Id, Currency_Code__c FROM Country__c WHERE Currency_Code__c != NULL]) {
			if(!currCodeToCountryRecMap.containsKey(countryRec.Currency_Code__c)) {
				currCodeToCountryRecMap.put(countryRec.Currency_Code__c, countryRec);
			}
		}

		for(String name: contactNameToXeroContactRecMap.keySet()) {
			XeroContactDTO xeroContactRec = contactNameToXeroContactRecMap.get(name);
			if(nameToListOfAccRecs.containsKey(name)) {
				if((accType == 'Customer' && xeroContactRec.IsCustomer) || (accType == 'Vendor' && xeroContactRec.IsSupplier)) {
    				if(nameToListOfAccRecs.get(name).size() == 1) {
    					if(accType == 'Customer') {
    						accountListToUpsert.add(new Account(Id = nameToListOfAccRecs.get(name)[0].Id, Xero_Customer_Accounting_Id__c = xeroContactRec.ContactID));
    					} else if(accType == 'Vendor') {
							setMatchedVendorAccIdInBP(nameToListOfAccRecs.get(name)[0], xeroContactRec, accountListToUpsert);
    					}
	    			} else {
	    				List<Account> matchedAccList = new List<Account>();
	    				for(Account accRec: nameToListOfAccRecs.get(name)) {
	    					Set<String> emailStrSet = new Set<String>();
        					if(accType == 'Customer' && String.isNotBlank(nameToListOfAccRecs.get(name)[0].Email__c)) {
        						emailStrSet.add(nameToListOfAccRecs.get(name)[0].Email__c);	
        					}
        					if(String.isNotBlank(nameToListOfAccRecs.get(name)[0].Other_Email__c)) {
        						emailStrSet.add(nameToListOfAccRecs.get(name)[0].Other_Email__c);	
        					}
        					if(String.isNotBlank(nameToListOfAccRecs.get(name)[0].Work_Email__c)) {
        						emailStrSet.add(nameToListOfAccRecs.get(name)[0].Work_Email__c);	
        					}
        					
        					if(String.isBlank(xeroContactRec.EmailAddress) && emailStrSet.size() == 0) {
        						matchedAccList.add(accRec);
        					} else if(String.isNotBlank(xeroContactRec.EmailAddress) && emailStrSet.contains(xeroContactRec.EmailAddress)) {
        						matchedAccList.add(accRec);
        					}
	    				}
	    				if(matchedAccList.size() == 1) {
	    					if(accType == 'Customer') {
	    						accountListToUpsert.add(new Account(Id = matchedAccList[0].Id, Xero_Customer_Accounting_Id__c = xeroContactRec.ContactID));
	    					} else if(accType == 'Vendor') {
								setMatchedVendorAccIdInBP(matchedAccList[0], xeroContactRec, accountListToUpsert);
	    					}
	    				}
    				}
    			}
			} else if((accType == 'Customer' && xeroContactRec.IsCustomer) || (accType == 'Vendor' && xeroContactRec.IsSupplier)) {

				Account accRec = new Account();
				if(accType == 'Customer') {
					accRec.Xero_Customer_Accounting_Id__c = xeroContactRec.ContactID;
					accRec.Price_Level__c = defaultPriceLevelId;
					accRec.Account_Type__c = defaultCustomerAccountTypeId;
					accRec.Type__c = 'Individual';
					accRec.Email__c = xeroContactRec.EmailAddress;
				} else if(accType == 'Vendor') {
					accRec.Xero_Vendor_Accounting_Id__c = xeroContactRec.ContactID;
					accRec.Purchase_Tax__c = defaultPurchaseTaxId;
					accRec.Vendor_Account_Type__c = defaultVendorAccountTypeId;
					accRec.Type__c = 'Business';
					accRec.Company_Name__c = xeroContactRec.Name;
					accRec.Work_Email__c = xeroContactRec.EmailAddress;
					if(String.isNotBlank(xeroContactRec.DefaultCurrency) && currCodeToCountryRecMap.get(xeroContactRec.DefaultCurrency) != null) {
						accRec.Is_Foreign_Vendor__c = true;
						accRec.Country__c =  currCodeToCountryRecMap.get(xeroContactRec.DefaultCurrency).Id;
					} 
				}

				accRec.Name = xeroContactRec.Name;
				accRec.FirstName__c = xeroContactRec.FirstName;
				accRec.LastName__c = xeroContactRec.LastName;
				accRec.Active__c = true;
				accRec.Is_Customer__c = xeroContactRec.IsCustomer;
				accRec.Is_Vendor__c = xeroContactRec.IsSupplier;

				if(xeroContactRec.IsCustomer == true && (String.isBlank(xeroContactRec.FirstName) || String.isBlank(xeroContactRec.LastName))) {
					accRec.Type__c = 'Business';
					accRec.Email__c = '';	
					accRec.Work_Email__c = xeroContactRec.EmailAddress;
					accRec.Company_Name__c = xeroContactRec.Name;
				} 
				for(XeroContactDTO.AddressWrapper address : xeroContactRec.Addresses) {
					if(Address.AddressType == 'POBOX') {
						accRec.BillingStreet = address.AddressLine1 + '\n' + address.AddressLine2;
						accRec.BillingCity = address.City;
						accRec.BillingCountry = address.Country;
						accRec.BillingState = address.Region;
						accRec.BillingPostalCode = address.PostalCode;
					} else if(Address.AddressType == 'STREET') {
						accRec.ShippingStreet = address.AddressLine1 + '\n' + address.AddressLine2;
						accRec.ShippingCity = address.City;
						accRec.ShippingCountry = address.Country;
						accRec.ShippingState = address.Region;
						accRec.ShippingPostalCode = address.PostalCode;
					}
				}
				for(XeroContactDTO.PhoneWrapper phone : xeroContactRec.Phones) {
					if(phone.PhoneType == 'DEFAULT' && accRec.Type__c == 'Individual') {
						accRec.Home_Number__c = phone.PhoneNumber;
					} else if (phone.PhoneType == 'DEFAULT' && accRec.Type__c == 'Business') {
						accRec.Work_Number__c = phone.PhoneNumber;
					}
					if(phone.PhoneType == 'MOBILE') {
						accRec.Mobile__c = phone.PhoneNumber;
					}
					if(phone.PhoneType == 'FAX') {
						accRec.Fax = phone.PhoneNumber;
					}
				}
				accountListToUpsert.add(accRec);
			}
		}
		return accountListToUpsert;
	}

	private void setMatchedVendorAccIdInBP(Account matchedAcc, XeroContactDTO xeroContactRec, List<Account> accountListToUpsert) {
		String homeCurr = AccountingUtil.getHomeCurrency();
		Account accRecToUpdate;
		if(String.isBlank(homeCurr)) {
			accRecToUpdate = new Account(Id = matchedAcc.Id, Xero_Vendor_Accounting_Id__c = xeroContactRec.ContactID);
		} else {
			if((String.isBlank(xeroContactRec.DefaultCurrency) || (homeCurr == xeroContactRec.DefaultCurrency)) && 
				!matchedAcc.Is_Foreign_Vendor__c) {
				accRecToUpdate = new Account(Id = matchedAcc.Id, Xero_Vendor_Accounting_Id__c = xeroContactRec.ContactID);
			} else if(String.isNotBlank(xeroContactRec.DefaultCurrency) && matchedAcc.Is_Foreign_Vendor__c && 
						matchedAcc.Country__r.Currency_Code__c == xeroContactRec.DefaultCurrency) {
				accRecToUpdate = new Account(Id = matchedAcc.Id, Xero_Vendor_Accounting_Id__c = xeroContactRec.ContactID);
			}
		}
		if(accRecToUpdate != null) accountListToUpsert.add(accRecToUpdate);
	}

}