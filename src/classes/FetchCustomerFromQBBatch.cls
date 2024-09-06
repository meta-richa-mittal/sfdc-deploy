global without sharing class FetchCustomerFromQBBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    
    public Integer APICounter = 0;
    public Boolean recordFound = false;
    public String defaultCustomerAccountTypeId;
    public String defaultPriceLevelId;
    
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
        return new List<Integer>{APICounter};
    }
    
    global void execute(Database.batchableContext bc, List<Integer> apiCountList) {
        QueryResponseWrapper customerInfo = new QueryResponseWrapper();
        List<CustomerWrapper> customerList = new List<CustomerWrapper>();
        String query = 'SELECT * FROM Customer WHERE Active = true AND Job = false';
        if(APICounter != 0) {
            query += ' STARTPOSITION '+ ((APICounter * 100) + 1);
        }
        query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
        
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('query?query='+query, null);
        HttpResponse res = responseObj.Response;
        system.debug('== res ==' + res);
        if(responseObj.RefreshToken !=  null) {
            QBUtil.saveRefreshToken(responseObj.RefreshToken, responseObj.RefreshTokenExpiresIn);
        }
        if(res.getStatusCode() == 200){
            system.debug('== res.getBody() ==' + res.getBody());
            customerInfo = (QueryResponseWrapper) System.JSON.deserialize(res.getBody(), QueryResponseWrapper.class);
            if(customerInfo.QueryResponse != null && customerInfo.QueryResponse.Customer != null && customerInfo.QueryResponse.Customer.size() > 0) {
                customerList.addAll(customerInfo.QueryResponse.Customer);
                updateCustomerInBlackPurl(customerList);
                recordFound = true;
            }
        } else {
            /*new LogService().createErrorLog('AccountingIntegrationSettingsCtrl', 'syncAccounts()', res.getBody(), res.getStatusCode(), null, 
                                          null, LogService.QUICKBOOKS);*/
        }
    }
    
    global void finish(Database.batchableContext bc) {
        APICounter++;
        if(recordFound) {
            Database.executeBatch(new FetchCustomerFromQBBatch(APICounter));
        }
    }
    
    public void updateCustomerInBlackPurl(List<CustomerWrapper> customerList) {
        Set<String> customerNameSet = getCustomerNameSet(customerList);
        List<Account> bpCustomerList = [SELECT Name FROM Account WHERE Name IN: customerNameSet];
        Map<String, List<Account>> nameToCustomerListMap = new Map<String, List<Account>>();
        for(Account acc : bpCustomerList) {
            if(!nameToCustomerListMap.containsKey(acc.Name)) {
                nameToCustomerListMap.put(acc.Name, new List<Account>());
            }
            nameToCustomerListMap.get(acc.Name).add(acc);
        }
        
        List<Account> customerListToUpsert = new List<Account>();
        for(CustomerWrapper customerObj : customerList) {
            Account customerRec = new Account();
            customerRec.AccountingId__c = customerObj.Id;
            customerRec.SyncToken__c = customerObj.SyncToken;
            if(nameToCustomerListMap.containsKey(customerObj.DisplayName)) {
                customerRec.Id = nameToCustomerListMap.get(customerObj.DisplayName)[0].Id;
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
                customerRec.BillingState = customerObj.BillAddr.CountrySubDivisionCode;
                customerRec.BillingPostalCode = customerObj.BillAddr.PostalCode;
            }
            if(customerObj.ShipAddr != null) {
                    customerRec.ShippingStreet = (customerObj.ShipAddr.Line1 != null ? customerObj.ShipAddr.Line1 + '\n' : '') +
												(customerObj.ShipAddr.Line2 != null ? customerObj.ShipAddr.Line2 : '');
                customerRec.ShippingCity = customerObj.ShipAddr.City;
                customerRec.ShippingCountry = customerObj.ShipAddr.Country;
                customerRec.ShippingState = customerObj.ShipAddr.CountrySubDivisionCode;
                customerRec.ShippingPostalCode = customerObj.ShipAddr.PostalCode;
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
            if(logList.size() > 0) {
                insert logList;
            }
        }
    }
    
    public Set<String> getCustomerNameSet(List<CustomerWrapper> customerList) {
        Set<String> customerNameSet = new Set<String>();
        for(CustomerWrapper customer : customerList) {
            customerNameSet.add(customer.DisplayName);
        }
        return customerNameSet;
    }
    
    
    public class QueryResponseWrapper{
        public AccountQueryResponseWrapper QueryResponse;
    }
    public class AccountQueryResponseWrapper {
        public List<CustomerWrapper> Customer;
    }
    public class CustomerWrapper {
        public String Id;
        public String SyncToken;
        public String GivenName;
        public String MiddleName;
        public String FamilyName;
        public String DisplayName;
        public String CompanyName;
        public Boolean Active;
        public Boolean sparse;
        public QuickBooksPhoneWrapper PrimaryPhone;
        public QuickBooksPhoneWrapper AlternatePhone;
        public QuickBooksPhoneWrapper Mobile;
        public QuickBooksPhoneWrapper Fax;
        public QuickBooksEmailWrapper PrimaryEmailAddr;
        public QuickBooksAddressWrapper BillAddr;
        public QuickBooksAddressWrapper ShipAddr;
    }
    
    public class QuickBooksPhoneWrapper{
        public String FreeFormNumber;
    }
     
    public class QuickBooksEmailWrapper{
        public String Address;
    }
     
    public class QuickBooksAddressWrapper {
        public String Line1;
        public String Line2;
        public String City;
        public String Country;
        public String CountrySubDivisionCode;
        public String PostalCode;
    }
}