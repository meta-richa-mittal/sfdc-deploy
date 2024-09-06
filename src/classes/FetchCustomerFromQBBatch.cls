global without sharing class FetchCustomerFromQBBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    
    public Integer APICounter = 0;
    public Boolean recordFound = false;
    public String defaultCustomerAccountTypeId;
    public String defaultPriceLevelId;
    List<IFW_IntegrationConfig__c> integrationConfigList;

    
    global FetchCustomerFromQBBatch() {
    }
    
    global FetchCustomerFromQBBatch(Integer APICounter) {
        this.APICounter = APICounter;
    }
    
    global Iterable<Integer> start(Database.BatchableContext bc) {
        List<Account_Type__c> accTypeList = [Select Id From Account_Type__c Where Applies_To__c = 'Customers' AND Active__c = true AND Default__c = true Limit 1];
        if(accTypeList.size() > 0) {
            defaultCustomerAccountTypeId = accTypeList[0].Id;
        }
        List<Price_Level__c> priceLevelList = [Select Id From Price_Level__c Where Active__c = true AND Default__c = true Limit 1];
        if(priceLevelList.size() > 0) {
            defaultPriceLevelId = priceLevelList[0].Id;
        }
        if(integrationConfigList == null) {
            integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
            if(integrationConfigList.isEmpty()) throw new BlackPurlException('IFW record for ' + QBUtil.QUICKBOOKS_ONLINE + ' doesn\'t exists');
        }
        return new List<Integer>{APICounter};
    }
    
    global void execute(Database.batchableContext bc, List<Integer> apiCountList) {
        List<QBCustomerDTO> customerList = new List<QBCustomerDTO>();
        String query = 'SELECT * FROM Customer WHERE Active = true AND Job = false';
        if(APICounter != 0) {
            query += ' STARTPOSITION '+ ((APICounter * 100) + 1);
        }
        query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
        try {
            QBQueryResponseWrapper.QBResponseWrapper responseObj = QBCalloutManager.getDataAndUpdateRecords('Customer', query, integrationConfigList[0]);
            if(responseObj != null && responseObj.Customer != null && responseObj.Customer.size() > 0) {
                customerList.addAll(responseObj.Customer);
                updateCustomerInBlackPurl(customerList);
                recordFound = true;
            }
        } catch(Exception e) {}
    }
    
    global void finish(Database.batchableContext bc) {
        APICounter++;
        if(recordFound) {
            Database.executeBatch(new FetchCustomerFromQBBatch(APICounter));
        }
    }
    
    public void updateCustomerInBlackPurl(List<QBCustomerDTO> customerList) {
        Set<String> customerNameSet = getCustomerNameSet(customerList);
        List<Account> bpCustomerList = [SELECT Name, 
                                                (SELECT LastName, FirstName,  Is_Shipping_Address__c, MailingCountry, MailingPostalCode,
                                                MailingState, MailingStreet, MailingCity FROM Contacts WHERE Is_Shipping_Address__c = true)  
                                                FROM Account WHERE Name IN: customerNameSet];
        Map<String, List<Account>> nameToCustomerListMap = new Map<String, List<Account>>();
        for(Account acc : bpCustomerList) {
            if(!nameToCustomerListMap.containsKey((acc.Name).toLowerCase())) {
                nameToCustomerListMap.put((acc.Name).toLowerCase(), new List<Account>());
            }
            nameToCustomerListMap.get((acc.Name).toLowerCase()).add(acc);
        }
        Map<String, List<Contact>> nameToContactsRecMap = new Map<String, List<Contact>>();
        Map<String, Account> nameToAccountRecMap = new Map<String, Account>();
        List<Account> customerListToUpsert = new List<Account>();
        for(QBCustomerDTO customerObj : customerList) {
            Account customerRec = new Account();
            customerRec.AccountingId__c = customerObj.Id;
            customerRec.SyncToken__c = customerObj.SyncToken;
            if(nameToCustomerListMap.containsKey((customerObj.DisplayName).toLowerCase())) {
                customerRec.Id = nameToCustomerListMap.get((customerObj.DisplayName).toLowerCase())[0].Id;
            } else {
            customerRec.Name = customerObj.DisplayName;
                customerRec.Type__c = 'Individual';
                if(String.isNotBlank(customerObj.CompanyName)) {
                    customerRec.Type__c = 'Business';
                    customerRec.Company_Name__c = customerObj.CompanyName;
                } else if(String.isNotBlank(customerObj.DisplayName)) {
            	Integer spaceIndex = customerObj.DisplayName.indexOf(' ');
            	if(String.isBlank(customerObj.GivenName)) {
            		String firstName = customerObj.DisplayName;
            		if(spaceIndex != -1) {
	            		firstName = customerObj.DisplayName.substring(0, spaceIndex);
	            	}
            		customerRec.FirstName__c = firstName;
            	} else {
            		customerRec.FirstName__c = customerObj.GivenName;
            	}
            	
            	if(String.isBlank(customerObj.FamilyName) && spaceIndex != -1) {
					String lastName = customerObj.DisplayName.substring(spaceIndex + 1);
					customerRec.LastName__c = lastName;
            	} else {
            		customerRec.LastName__c = customerObj.FamilyName;
            	}
				
            }
            customerRec.Active__c = true;
            customerRec.Is_Customer__c = true;
                customerRec.Price_Level__c = defaultPriceLevelId;
                customerRec.Account_Type__c = defaultCustomerAccountTypeId;
            
            customerRec.Email__c = (customerObj.PrimaryEmailAddr != null && customerObj.PrimaryEmailAddr.Address != null) ? 
                                        customerObj.PrimaryEmailAddr.Address : null;
            customerRec.Home_Number__c = (customerObj.PrimaryPhone != null && customerObj.PrimaryPhone.FreeFormNumber != null) ? 
                                        customerObj.PrimaryPhone.FreeFormNumber : null;
            
            if(customerObj.BillAddr != null) {
                    customerRec.BillingStreet = customerRec.BillingStreet = (customerObj.BillAddr.Line1 != null ? customerObj.BillAddr.Line1 + '\n' : '') +
												(customerObj.BillAddr.Line2 != null ? customerObj.BillAddr.Line2 : '');
                customerRec.BillingCity = customerObj.BillAddr.City;
                customerRec.BillingCountry = customerObj.BillAddr.Country;
                customerRec.BillingState = (customerObj.BillAddr.CountrySubDivisionCode != null && (customerObj.BillAddr.CountrySubDivisionCode).length() != 2) ? AbbreviationsUtil.getStateAbbreviationsByName(customerRec.BillingCountry , customerObj.BillAddr.CountrySubDivisionCode) : customerObj.BillAddr.CountrySubDivisionCode;
                customerRec.BillingPostalCode = customerObj.BillAddr.PostalCode;
            }
            if(customerObj.ShipAddr != null && String.isNotBlank(customerObj.ShipAddr.Country)) {
                String shippingStreet = (customerObj.ShipAddr.Line1 != null ? customerObj.ShipAddr.Line1 + '\n' : '') +
												(customerObj.ShipAddr.Line2 != null ? customerObj.ShipAddr.Line2 : '');
                String shippingCity = customerObj.ShipAddr.City;
                String shippingCountry = customerObj.ShipAddr.Country;
                String shippingState = (customerObj.ShipAddr.CountrySubDivisionCode != null && (customerObj.ShipAddr.CountrySubDivisionCode).length() != 2) ? AbbreviationsUtil.getStateAbbreviationsByName(shippingCountry , customerObj.ShipAddr.CountrySubDivisionCode) : customerObj.ShipAddr.CountrySubDivisionCode;
                String shippingPostalCode = customerObj.ShipAddr.PostalCode;
                Boolean isShippingAddrExist = false;
                if(nameToCustomerListMap.containsKey((customerObj.DisplayName).toLowerCase())) {
                    for(Contact contactRec : nameToCustomerListMap.get((customerObj.DisplayName).toLowerCase())[0].Contacts) {
                        if(contactRec.MailingStreet.toLowerCase() == ShippingStreet.toLowerCase() && 
                        contactRec.MailingCity.toLowerCase() == shippingCity.toLowerCase() &&
                        contactRec.MailingState.toLowerCase() == shippingState.toLowerCase() &&
                        contactRec.MailingPostalCode.toLowerCase() == shippingPostalCode.toLowerCase() && 
                        contactRec.MailingCountry.toLowerCase() == shippingCountry.toLowerCase()) {
                            isShippingAddrExist = true;
                            break;
                        }
                    }
                }
                if(!isShippingAddrExist) {
                    Contact conRec = new Contact();
                    String key ;
                    if(nameToCustomerListMap.containsKey((customerObj.DisplayName).toLowerCase())) { 
                        conRec.AccountId = nameToCustomerListMap.get((customerObj.DisplayName).toLowerCase())[0].Id;
                        key = conRec.AccountId;
                    } else {
                        key = customerObj.DisplayName;
                        nameToAccountRecMap.put(key, customerRec);
                    }
                    conRec.LastName = 'Shipping';
                    conRec.MailingStreet = ShippingStreet;
                    conRec.MailingCity = shippingCity;
                    conRec.MailingState = shippingState;
                    conRec.MailingPostalCode = shippingPostalCode;
                    conRec.MailingCountry = shippingCountry;
                    conRec.Is_Shipping_Address__c = true;
                    if(!nameToContactsRecMap.containsKey(key)) {
                        nameToContactsRecMap.put(key, new List<Contact>());
                    }
                    nameToContactsRecMap.get(key).add(conRec);
                }
            }
        }
            customerListToUpsert.add(customerRec);
        }
        system.debug(' == customerListToUpsert == ' + customerListToUpsert.size());
        system.debug(' == customerListToUpsert == ' + customerListToUpsert);
        if(customerListToUpsert.size() > 0) {
            if(!AccessControl.ifObjectFieldIsCreateable('Account')) { throw new BlackPurlException('Account' + DMLUtility.NOT_CREATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('Account')) { throw new BlackPurlException('Account' + DMLUtility.NOT_UPDATABLE); }
			List<Database.UpsertResult> upsertResultList = Database.upsert(customerListToUpsert, false);
            if(!nameToAccountRecMap.isEmpty()) {
                for(String key : nameToAccountRecMap.keySet()) {
                    if(nameToContactsRecMap.containsKey(key)) {
                        for(Contact conRec : nameToContactsRecMap.get(key)) {
                            conRec.AccountId = nameToAccountRecMap.get(key).Id;
                        }
                    }
                }
            }
    
            if(!nameToContactsRecMap.isEmpty()) {
                List<contact> contactsToInsert = new List<Contact>();
                for(String key : nameToContactsRecMap.keySet()) {
                    for(Contact conRec : nameToContactsRecMap.get(key)) {
                        if(conRec.AccountId != null) contactsToInsert.add(conRec);
                    }
                }
                DMLUtility.insertSobjectList('Contact', contactsToInsert);
            }
            List<Log__c> logList = new List<Log__c>();
            
            for(Integer i = 0; i < upsertResultList.size(); i++) {
                if(!upsertResultList[i].isSuccess()) {
                    Log__c logRec = new Log__c();
                    logRec.Type__c = 'Info';
                    logRec.Apex_Class__c = 'FetchCustomerFromQB';
                    //logRec.Method_Params__c = customerListToUpsert[i].AccountingId__c;
					logRec.Method_Params__c = 'Accounting Id: ' + customerListToUpsert[i].AccountingId__c + ', Customer Name: ' + customerListToUpsert[i].Name;
                    logRec.Log_Info__c = upsertResultList[i].getErrors()[0].getFields() + '  \n' + upsertResultList[i].getErrors()[0].getMessage();
                    logList.add(logRec);
                }
            }
            DMLUtility.insertSobjectList('Log__c', logList);
        }
    }
    
    public Set<String> getCustomerNameSet(List<QBCustomerDTO> customerList) {
        Set<String> customerNameSet = new Set<String>();
        for(QBCustomerDTO customer : customerList) {
            customerNameSet.add(customer.DisplayName);
        }
        return customerNameSet;
    }
}