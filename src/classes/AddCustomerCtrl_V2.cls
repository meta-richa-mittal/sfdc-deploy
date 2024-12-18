global without sharing class AddCustomerCtrl_V2 {
    
    global AddCustomerCtrl_V2(NewHomePageCtrl controller){}
    public AddCustomerCtrl_V2() {}
    
    @RemoteAction
    global static String getMasterData() {
        List<Country__c> countryList = Customer_Service.getCountryList();
        List<State__c> stateList = Customer_Service.getStateList();
        List<Price_Level__c> priceLevelList = SOQLUtil.getPriceLevel(new List<Id>());
        return BPUtility.getEncodedString(System.JSON.serialize(new COUFieldWrapper(countryList, stateList, priceLevelList), true));
    }
    
    @RemoteAction
    global static String getOtherSimilarCustomer(String customerJSONString){
        customerJSONString = BPUtility.getDecodedString(customerJSONString);
        try{
            CustomerWrapper_V2 customerObj = (CustomerWrapper_V2) System.JSON.deserialize(customerJSONString, CustomerWrapper_V2.class);
            Account customerRecordFilterValue = (Account) setCustomerfields(customerObj, customerObj.Type);
            List<Account> customers = SOQLUtil.getOtherSimilarCustomer(customerRecordFilterValue);
            
    
            List<CustomerSuggestion> customerSuggestionList = new List<CustomerSuggestion>();
            for(Account customerRec : customers) {
                if(customerRec.Type__c == 'Individual') {
                    if(customerRec.LastName__c != null && customerRec.LastName__c != '' && customerRec.LastName__c == customerRecordFilterValue.LastName__c) {
                        if(customerRec.FirstName__c == customerRecordFilterValue.FirstName__c) {
                            customerSuggestionList.add(new CustomerSuggestion(customerRec, 4, customerRec.Customer_Owned_Units__r));
                            continue;
                        } else if(customerRec.FirstName__c != null && customerRec.FirstName__c.length() > 1 && customerRec.FirstName__c.subString(0,1) == customerRecordFilterValue.FirstName__c) {
                            customerSuggestionList.add(new CustomerSuggestion(customerRec, 5, customerRec.Customer_Owned_Units__r));
                            continue;
                        } else {
                            customerSuggestionList.add(new CustomerSuggestion(customerRec, 6, customerRec.Customer_Owned_Units__r));
                            continue;
                        }
                    } 
                } else if(customerRec.Type__c == 'Business') {
                    if(customerRec.Name ==  customerRecordFilterValue.Name) {
                        customerSuggestionList.add(new CustomerSuggestion(customerRec, 4, customerRec.Customer_Owned_Units__r));
                        continue;
                    }
                }
                if(( customerRec.Email__c !=null  && customerRec.Email__c !='' && (customerRec.Email__c == customerRecordFilterValue.Email__c || 
                                                                                    customerRec.Email__c == customerRecordFilterValue.Other_Email__c))  || 
                                                                                    
                        (customerRec.Work_Email__c != null && customerRec.Work_Email__c != '' && (customerRec.Work_Email__c == customerRecordFilterValue.Work_Email__c ||
                                                                                                  customerRec.Work_Email__c == customerRecordFilterValue.Other_Email__c)) ||
                            
                        (customerRec.Other_Email__c != null && customerRec.Other_Email__c != '' && (customerRec.Other_Email__c == customerRecordFilterValue.Other_Email__c ||
                                                                                                     customerRec.Other_Email__c == customerRecordFilterValue.Work_Email__c || 
                                                                                                     customerRec.Other_Email__c == customerRecordFilterValue.Email__c))) {
                    
                    customerSuggestionList.add(new CustomerSuggestion(customerRec, 1, customerRec.Customer_Owned_Units__r));
                    continue;
                }
                
                if((customerRec.Home_Number__c != null && customerRec.Home_Number__c != '' && (customerRec.Home_Number__c == customerRecordFilterValue.Home_Number__c  ||
                                                                                               customerRec.Home_Number__c == customerRecordFilterValue.Mobile__c )) || 
                                                                                               
                        (customerRec.Work_Number__c != null && customerRec.Work_Number__c != '' && (customerRec.Work_Number__c == customerRecordFilterValue.Work_Number__c || 
                                                                                                    customerRec.Work_Number__c == customerRecordFilterValue.Mobile__c))  ||
                                                                                                     
                        (customerRec.Mobile__c != null && customerRec.Mobile__c != '' && (customerRec.Mobile__c == customerRecordFilterValue.Mobile__c ||
                                                                                          customerRec.Mobile__c == customerRecordFilterValue.Home_Number__c ||
                                                                                          customerRec.Mobile__c == customerRecordFilterValue.Work_Number__c ))) {
                            
                    customerSuggestionList.add(new CustomerSuggestion(customerRec, 2, customerRec.Customer_Owned_Units__r));
                    continue;
                }
                
                if((customerRec.Facebook__c != null && customerRec.Facebook__c != '' && customerRec.Facebook__c == customerRecordFilterValue.Facebook__c) || 
                        (customerRec.Twitter__c != null && customerRec.Twitter__c != '' && customerRec.Twitter__c == customerRecordFilterValue.Twitter__c) || 
                        (customerRec.LinkedIn__c != null && customerRec.LinkedIn__c != '' && customerRec.LinkedIn__c == customerRecordFilterValue.LinkedIn__c)) {
                    customerSuggestionList.add(new CustomerSuggestion(customerRec, 3, customerRec.Customer_Owned_Units__r));
                    continue;
                }
                
                String billingStreet = (customerRec.BillingStreet == null ) ? '' : customerRec.BillingStreet;
                List<String> bsList = billingStreet.split('\n');
                String billingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
                
                String filterBillingStreet = (customerRecordFilterValue.BillingStreet == null ) ? '' : customerRecordFilterValue.BillingStreet;
                List<String> filterBSList = filterBillingStreet.split('\n');
                String filterBillingStreet1 = (filterBSList.size() > 0) ? filterBSList[0] : '';
                if(filterBillingStreet1 != '' && filterBillingStreet1 != null && filterBillingStreet1 != 'null' && filterBillingStreet1 == billingStreet1) {
                    customerSuggestionList.add(new CustomerSuggestion(customerRec, 7, customerRec.Customer_Owned_Units__r));
                }
            }
            //system.assert(false, customerSuggestionList);
            customerSuggestionList.sort();
            Integer listSizeLimit = 7;
            if(customerSuggestionList.size() > listSizeLimit) {
                List<CustomerSuggestion> customerSuggestionLimitedList = new List<CustomerSuggestion>();
                for(Integer i = 0 ; i < listSizeLimit ; i++) {
                    customerSuggestionLimitedList.add(customerSuggestionList[i]);
                }
                customerSuggestionList = new List<CustomerSuggestion>();
                customerSuggestionList.addAll(customerSuggestionLimitedList);
            }
            //system.assert(false, customerSuggestionList);
            return BPUtility.getEncodedString(System.JSON.serialize(customerSuggestionList));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
     
    @RemoteAction
    global static String saveCustomer(String customerJSONString) {
        customerJSONString = BPUtility.getDecodedString(customerJSONString);
        try {
            Savepoint sp = Database.setSavepoint(); 
            if(AccessControl.ifObjectFieldIsCreateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            
            CustomerWrapper_V2 customerObj = CustomerWrapper_V2.parse(customerJSONString);
            Account customerToInsert = new Account();
            customerToInsert = (Account) setCustomerfields(customerObj, customerObj.Type);
            if(customerToInsert.Name != null ) {
                Boolean isInsert = String.isBlank(customerToInsert.Id); 
                if(isInsert && customerToInsert.Price_Level__c == null) {
                    if(AccessControl.ifObjectFieldIsAccessible('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                    List<Price_Level__c> priceLevelList = [Select Id from Price_Level__c where Default__c = true];
                    if(priceLevelList.size() > 0) {
                        customerToInsert.Price_Level__c = priceLevelList[0].Id;
                    }
                }
                upsert customerToInsert;
                
                // Create Activity History in case of Insert.
                if(isInsert && !Test.isRunningTest()) {
                    ActivityHistory.createActivityHistory('Add Customer', 'Customer', customerToInsert.Id, 'Customer', customerToInsert.Id, null);
                }
            }
            return customerToInsert.Id;
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
     private static Sobject setCustomerfields(CustomerWrapper_V2 custObj, String typeOfCustomer) {
        try{
            SObject customerToInsert = new Account();
            
            if(typeOfCustomer == 'Individual') {
                customerToInsert.put('FirstName__c', custObj.FirstName);
                customerToInsert.put('Middle_Name__c', custObj.MiddleName);
                customerToInsert.put('LastName__c', custObj.LastName);
                if(custObj.FirstName != null && custObj.LastName != null) {
                    String name = custObj.FirstName;
                    name += (String.isNotBlank(custObj.MiddleName) ? ' ' + custObj.MiddleName : '');
                    name += ' ' + custObj.LastName;
                    customerToInsert.put('Name', name);
                }
                customerToInsert.put('Company_Name__c', custObj.Company);
                customerToInsert.put('Job_Title__c', custObj.JobTitle);
                
                if(custObj.BirthDay != null && custObj.BirthMonth != null && custObj.BirthYear != null) { 
                    Date birth_Date = Date.newInstance(custObj.BirthYear, custObj.BirthMonth, custObj.BirthDay);
                    customerToInsert.put('Birth_Date__c', birth_Date);
                } else {
                    customerToInsert.put('Birth_Date__c', null);
                }
            } else if(typeOfCustomer == 'Business'){
                customerToInsert.put('Name', custObj.BusinessName);
            }
            customerToInsert.put('Tax_Id__c', custObj.TaxId);
            customerToInsert.put('Ag_Other_ID__c', custObj.OtherId);
            
            customerToInsert.put('Home_Number__c', custObj.HomeNumber);
            customerToInsert.put('Mobile__c', custObj.OtherPhone);
            customerToInsert.put('Work_Number__c', custObj.WorkNumber);
            customerToInsert.put('Email__c', custObj.HomeEmail);
            
            customerToInsert.put('Type__c', custObj.Type);
            customerToInsert.put('Active__c', custObj.Active);
            customerToInsert.put('Is_Customer__c', custObj.IsCustomer);
            customerToInsert.put('Is_Vendor__c', custObj.IsVendor);
            customerToInsert.put('Work_Email__c', custObj.WorkEmail);
            customerToInsert.put('Other_Email__c', custObj.OtherEmail);
            customerToInsert.put('SA_same_as_BA__c', custObj.IsBothAddressSame);
            customerToInsert.put('Account_Type__c', custObj.AccountTypeId);
            customerToInsert.put('Drivers_License__c', custObj.DriversLicense);
            customerToInsert.put('Drivers_License_Expiry_Date__c', DateTimeUtility.parseDate(custObj.LicenseExpiryDate));
            
            if(custObj.BillingStreet1 == null && custObj.BillingStreet2 != null) {
                customerToInsert.put('BillingStreet', '\n' + custObj.BillingStreet2);
            } else if(custObj.BillingStreet2 == null && custObj.BillingStreet1 != null) {
                customerToInsert.put('BillingStreet', custObj.BillingStreet1 + '\n');
            } else if(custObj.BillingStreet1 != null && custObj.BillingStreet2 != null) {
                customerToInsert.put('BillingStreet', custObj.BillingStreet1 + '\n' + custObj.BillingStreet2);
            }
            customerToInsert.put('BillingCity', custObj.BillingCity);
            customerToInsert.put('Billing_County_Parish__c', custObj.BillingCountyParish);
            customerToInsert.put('BillingCountry', custObj.BillingCountry);
            customerToInsert.put('BillingState', custObj.BillingState);
            customerToInsert.put('BillingPostalCode', custObj.BillingPostalCode);
            customerToInsert.put('Price_Level__c', custObj.PriceLevelId);
            customerToInsert.put('Allow_Charge_On_Account__c', (custObj.AllowChargeOnAccount != null ? custObj.AllowChargeOnAccount : false));

            if(custObj.Id != null && custObj.Id != '') {
                customerToInsert.put('Id', custObj.Id);
            }   
            return customerToInsert;
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /** Method to get data of all account type present in appication
    * CtrlClass -AccountTypeCtrl
    * @Return - String(Json containing all account type data)
    */
    @RemoteAction
    public static String getAllAccountTypeData() {
        return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.getAllAccountTypeOnlyForCustomer()));
    }
}