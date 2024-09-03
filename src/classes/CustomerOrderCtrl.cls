/** 
* Author: Tarun Khandelwal
* Since: March 13, 2015 
* Name: CustomerOrderCtrl 
* Description: Apex class which contains all remoted methods related to Customer Order Page.
**/
global without sharing class CustomerOrderCtrl {
    
    global CustomerOrderCtrl(NewHomePageCtrl controller) {}
    public CustomerOrderCtrl() {}
    
    // New STA searching function
    @RemoteAction // used on angucompleteServices
    global static String getSearchResult(String JSONString) {
        if(CustomerOrderCtrl_V2.isDummyServerCall(BPUtility.getDecodedString(JSONString))) return null;
        String searchJSONString = GenericSearchCtrl.getSearchResults(JSONString);
        return BPUtility.getEncodedString(searchJSONString);
    }

    @RemoteAction // used on AutoSuggestVendorOrderServices, SearchToAdd.component, CustomSearchToAddServices
    global static String getSearchResultsUpdated(String JSONString) {
        String searchJSONString = GenericSearchCtrl.getSearchSuggestionJSON(JSONString);
        return BPUtility.getEncodedString(searchJSONString);
    }
    
    @RemoteAction // used on angucompleteServices
    global static String getSearchResults(String JSONString) {
        // Parse the search JSON for object label and searc string
        JSONString = BPUtility.getDecodedString(JSONString);
        SearchSuggestionJSON.QueryJSON searchQueryJSON = SearchSuggestionJSON.parseQuery(JSONString);
        String searchJSONString = '';
        searchJSONString = SearchSuggestionUtil.getSearchSuggestionJSON(searchQueryJSON);
        return BPUtility.getEncodedString(searchJSONString);
    }
 
    global static String getRecordById(String recordId) { return ''; }

    global static String getPartDetails(String partId) { return ''; }

    global static String getCOHeaderDetails(String coHeaderId) { return ''; }
    
    // used in same class
    global static String getCOHeaderDetailsByGridName(String coHeaderId, String gridName) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        gridName = BPUtility.getDecodedString(gridName);
        try{            
            List<CO_Header__c> coHeaderRec = new List<CO_Header__c>();
            List<CO_Line_Item__c> coLineItems = new List<CO_Line_Item__c>();
            List<CO_Kit_Header__c> coKitHeaders = new List<CO_Kit_Header__c>();
            List<Vendor_Order_Line_Item__c> specialOrders = new List<Vendor_Order_Line_Item__c>();
            List<User> currentUser = new List<User>();
            List<CO_Deposit__c> coDeposits = new List<CO_Deposit__c>();
            List<CO_Invoice_Header__c> coInvoiceHeaders = new List<CO_Invoice_Header__c>();
            List<CO_Invoice_Payment__c> coInvoicePayments = new List<CO_Invoice_Payment__c>();
            List<CO_Invoice_Item__c> coInvoiceItems = new List<CO_Invoice_Item__c>();
            List<CO_Invoice_Header__c> closedCOInvoiceHeaders = new List<CO_Invoice_Header__c>();
            List<Customer_Owned_Unit__c> couRecords = new List<Customer_Owned_Unit__c>();
            List<Account> customerRecords = new List<Account>();
            List<Price_Level__c> priceLevelList = new List<Price_Level__c>();
            
            coHeaderRec = SOQLUtil.getCOHeaderDetails(coHeaderId) ;
            if(gridName == null || gridName.contains('coHeader')) {
                if(coHeaderRec.size() > 0 && coHeaderRec[0].CO_Type__c == 'Customer' && coHeaderRec[0].Customer__c != null){
                    customerRecords = SOQLUtil.getCardDetails(new Map<String, String>{'Id' => coHeaderRec[0].Customer__c});  
                }else if(coHeaderRec.size() > 0 && coHeaderRec[0].CO_Type__c == 'Cash Sale'){
                    priceLevelList = SOQLUtil.getCardDetailsForCO(null);  
                }else if(coHeaderRec.size() > 0 && coHeaderRec[0].CO_Type__c == 'Internal Service'){
                    String defaultPriceLevelId = GeneralConfiguration.getDefaultPriceLevelOnInternalService();
                    priceLevelList = SOQLUtil.getCardDetailsForCO(defaultPriceLevelId);  
                }
            }
            if(gridName == null || gridName.contains('coLineItem')) {
                coLineItems = SOQLUtil.getCOLineItemByCOHeaderId(coHeaderId);
                coKitHeaders = SOQLUtil.getCOKHByCOHeaderId(coHeaderId);
            }
            
            if(gridName == null || gridName.contains('specialOrder')) {
                specialOrders = SOQLUtil.getSpecialOrderByCOHeaderId(coHeaderId);
            }
            if(gridName == null ||  gridName.contains('user')) {
                currentUser = SOQLUtil.getCurrentUserInfo();
            }
            if(gridName == null ||  gridName.contains('coDeposit')) {
                coDeposits = SOQLUtil.getCODepositByCOHeaderId(coHeaderId);
            }
            if(gridName == null || gridName.contains('coInvoiceHeader')) {
                coInvoiceHeaders = SOQLUtil.getCOInvoiceHeaderByCOHeaderId(coHeaderId);
            }
            if(gridName == null || gridName.contains('closedCOInvoiceHeader')) {
                closedCOInvoiceHeaders = SOQLUtil.getInvoiceHistory(coHeaderId);
            }
            if(gridName == null || gridName.contains('cou')) {
                if(coHeaderRec.size() > 0 && coHeaderRec[0].Customer__c != null) {
                    couRecords = SOQLUtil.getCOUListByCustomerId(coHeaderRec[0].Customer__c);
                }
            }
            
            if(coInvoiceHeaders.size() > 0) {
                coInvoicePayments = SOQLUtil.getCOInvoicePaymentsByCOInvoiceHeaderId(coInvoiceHeaders[0].Id);
                coInvoiceItems = SOQLUtil.getCOInvoiceItemsByCOInvoiceHeaderId(coInvoiceHeaders[0].Id);
            }
            
            Map<Id, List<Vendor_Order_Header__c>> vendorIdToVOHeadesListMap = new Map<Id, List<Vendor_Order_Header__c>>();
            if(gridName == null || gridName.contains('coLineItem')) {
                List<Id> vendorIdList = new List<Id>();
                for(CO_Line_Item__c coLineItemRec : coLineItems) {
                    if(coLineItemRec.Part__r != null && coLineItemRec.Part__r.Vendor__c != null) {
                        vendorIdList.add(coLineItemRec.Part__r.Vendor__c);
                    }
                }
                List<Vendor_Order_Header__c> voHeaderList = SOQLUtil.getVOHeaderByFieldName(new Map<String, List<String>>{'Vendor__c'=> vendorIdList});
                List<Vendor_Order_Header__c> voHeadersList; 
                
                for(Vendor_Order_Header__c voHeaderRec : voHeaderList) {
                    if(!vendorIdToVOHeadesListMap.containsKey(voHeaderRec.Vendor__c)) {
                        voHeadersList = new List<Vendor_Order_Header__c>();
                    } else {
                        voHeadersList = vendorIdToVOHeadesListMap.get(voHeaderRec.Vendor__c);
                    }
                    voHeadersList.add(voHeaderRec);
                    vendorIdToVOHeadesListMap.put(voHeaderRec.Vendor__c, voHeadersList);
                }
            }
            
            COHeaderWrapper coHeaderWrapperObj;
            if(coHeaderRec.size() > 0) { 
                coHeaderWrapperObj = new COHeaderWrapper(coHeaderRec[0], coLineItems, coKitHeaders, currentUser[0].LocaleSidKey, coDeposits, coInvoiceHeaders, 
                                                            coInvoicePayments, coInvoiceItems, closedCOInvoiceHeaders, vendorIdToVOHeadesListMap, couRecords, specialOrders, customerRecords, priceLevelList);
            } else {
                coHeaderWrapperObj = new COHeaderWrapper(null, coLineItems, coKitHeaders, currentUser[0].LocaleSidKey, coDeposits, coInvoiceHeaders, 
                                                            coInvoicePayments, coInvoiceItems, closedCOInvoiceHeaders, vendorIdToVOHeadesListMap, couRecords, specialOrders, customerRecords, priceLevelList);
            }
            //system.assert(false, coHeaderWrapperObj);   
            return BPUtility.getEncodedString(System.JSON.serialize(coHeaderWrapperObj));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    global static String getSOHeaderDetails(String recordId, String gridName) { return ''; }
    
    global static String getVendorOrderByVendorId(string vendorId) { return ''; }
     
    global static String getSOMasterData(String coHeaderId) { return ''; }
    
    global static String saveSOHeaderInfo(String coHeaderId, String jSONString) { return ''; }
    
    global static String saveSOSignIn(String coHeaderId, String jSONString) { return ''; }
    
    global static String saveSOReviewInfo(String coHeaderId, String jSONString) { return ''; }
    
    global static String saveSOName(String coHeaderId, String soName, String soId) { return ''; }
    
    @RemoteAction // used on addEditCustomerService
    global static String addCustomer(String COHeaderId, String customerId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        COHeaderId = BPUtility.getDecodedString(COHeaderId);
        customerId = BPUtility.getDecodedString(customerId);
        try{
            if(String.isBlank(COHeaderId)) {
                COHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createCustomerOrder());  
            }
            COHeaderId = BPUtility.escapeSingleQuotes(COHeaderId);
            List<CO_Invoice_Header__c> coInvoiceHeaderList = [select Id, (select Id, Amount__c from CO_Invoice_Payments__r) // Amount__c Added by richa
                                                                    from CO_Invoice_Header__c 
                                                                    where Invoice_Status__c = 'Active' AND CO_Header__c =:COHeaderId];
            
            /* Start: Added by richa */
            Decimal totalPayment = 0;
            if(coInvoiceHeaderList.size() > 0) {
                for(CO_Invoice_Payment__c payment: coInvoiceHeaderList[0].CO_Invoice_Payments__r) {
                    totalPayment += (payment.Amount__c != null ? payment.Amount__c : 0);
                }
            }
            /* End: Added by richa */
            
            if(coInvoiceHeaderList.size() > 0 && totalPayment != 0) { // coInvoiceHeaderList[0].CO_Invoice_Payments__r.size() > 0  Removed and totalPayment != 0 Added by richa
                throw new BlackPurlException(BlackPurlException.getErrorMessage('Customer Can\'t be changed since payment is already added', null));
            }
            
            CO_Header__c coHeaderRec = new CO_Header__c(Id = COHeaderId, Customer__c = customerId);
            if(String.isBlank(customerId)) {
                coHeaderRec.CO_Type__c = 'Cash Sale';
                coHeaderRec.Selling_Group__c = 'Cash Sale';
            } else {
                List<CO_Header__c> coHeaderList =[Select Id, CO_Type__c, Customer__c, (Select Id from CO_Invoice_Headers__r where Invoice_Status__c = 'Closed'), (Select Id, SO_Status__c, Customer_Owned_Unit__c from Service_Order_Headers__r) from CO_Header__c where Id = :COHeaderId];
                
                if(coHeaderList.size() > 0  && coHeaderList[0].CO_Type__c == 'Internal Service'){
                    throw new BlackPurlException(BlackPurlException.getErrorMessage('Cannot add customer to Internal Service CO', null));
                } else if(coHeaderList.size() > 0 && coHeaderList[0].CO_Invoice_Headers__r.size() > 0) {
                    throw new BlackPurlException(BlackPurlException.getErrorMessage(Label.Changing_Customer_After_Invoicing_Error_Message, null));
                }
                
                if(coHeaderList.size() > 0  && coHeaderList[0].CO_Type__c == 'Cash Sale'){
                    coHeaderRec.Selling_Group__c = 'Part Sale';
                }
                if(coHeaderList.size() > 0  && ((String.isNotBlank(coHeaderList[0].Customer__c)) && 
                                (coHeaderList[0].Customer__c != customerId)) && coHeaderList[0].Service_Order_Headers__r.size() > 0) {
                    for(Service_Order_Header__c soHeaderRec : coHeaderList[0].Service_Order_Headers__r) {
                        if(String.isNotBlank(soHeaderRec.SO_Status__c) && ServiceJobUtil.isJobComplete(soHeaderRec.SO_Status__c)) {
                            throw new BlackPurlException(BlackPurlException.getErrorMessage(Label.Cannot_Change_Customer_With_Service_Job_Completed_Error_Message, null));
                        }
                        soHeaderRec.Customer_Owned_Unit__c = null;
                    }
                    update coHeaderList[0].Service_Order_Headers__r;
                }
                coHeaderRec.CO_Type__c = 'Customer';
            }
            updateCOPricingAndTax(new List<CO_Header__c> {coHeaderRec}, customerId, true);
            COService.updateCOPricingAndTaxOnKit(COHeaderId, customerId);
            return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderRec.Id), BPUtility.getEncodedString('coHeader,coLineItem,cou,user,specialOrder,coInvoiceHeader'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
            
    global static String refreshCOPricingAndTax(String coHeaderId, String customerId) { return ''; }
    
    global static String refreshCOPricingAndTaxOnKit(String coHeaderId, String customerId) { return ''; }

    public static void updateCOPricingAndTax(List<CO_Header__c> COHeaderRecList, String customerId, Boolean isCalculatePLandTax) { // used in same class
        if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        try{
            CO_Header__c COHeaderRec;
            if(COHeaderRecList.size() > 0){
                COHeaderRec = COHeaderRecList[0];
            }
            COTriggerHelper.isCalculatePLandTax = isCalculatePLandTax; 
            update COHeaderRec;
            
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    global static String getCOLineItemByCOHeaderId(String coHeaderId) { return ''; }

    global static String saveCOLineItem(String coHeaderId, String jSONString) { return ''; }
    
    global static String deleteCOLineItem(String coLineItemId, String coHeaderId) { return ''; }

    global static String getCODepositByCOHeaderId(String coHeaderId) { return ''; }

    global static String saveCODeposit(String jsonString) { return ''; }
    
    global static String getCOInvoicePaymentsByCOInvoiceHedaerId(String COInvoiceHeaderId) { return ''; }
    
    global static String saveCOInvoicePayment(String jsonString) { return ''; }
    
    global static String getCOInvoiceItemsByCOInvoiceHeaderId(String coInvoiceHeaderId) {
        return BPUtility.getEncodedString(System.JSON.serialize(COInvoiceItemService.getCOInvoiceItemList(BPUtility.getDecodedString(coInvoiceHeaderId)).InvoiceItemList));
    }
    
    global static String updateCOInvoiceItem(String jsonString, String coHeaderId) { return ''; }

    global static String getInvoiceHistoryWrapperList(String coInvoiceHeaderId) { return ''; }
    
    global static String closedOrderAction(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType) { return ''; }
    
    global static String closedInvoiceAction(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType) { return ''; }
            
    @RemoteAction // used on addEditCustomerService
    global static String getCustomer(String customerId) {
        customerId = BPUtility.getDecodedString(customerId);
        try{
            List<Account> customers = SOQLUtil.getCustomer(customerId, 'Customer');
            List<Customer> customerList = new List<Customer>();
            for(Account customerRec : customers) {
                customerList.add(new Customer(customerRec));
            }
            return BPUtility.getEncodedString(System.JSON.serialize(customerList));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction // used on addEditCustomerService
    global static String getOtherSimilarCustomer(String customerJSONString) {
        customerJSONString = BPUtility.getDecodedString(customerJSONString);
        try{
            Customer customerObj = (Customer) System.JSON.deserialize(customerJSONString, Customer.class);
            Account customerRecordFilterValue = (Account) setCustomerfields(customerObj, customerObj.Type);
            List<Account> customers = SOQLUtil.getOtherSimilarCustomer(customerRecordFilterValue);
    
            List<CustomerSuggestion> customerSuggestionList = new List<CustomerSuggestion>();
            for(Account customerRec : customers) {
                if(customerRec.Type__c == 'Individual') {
                    if(customerRec.LastName__c != null && customerRec.LastName__c != '' && customerRec.LastName__c == customerRecordFilterValue.LastName__c) {
                        if(customerRec.FirstName__c == customerRecordFilterValue.FirstName__c) {
                            customerSuggestionList.add(new CustomerSuggestion(customerRec, 4));
                            continue;
                        } else if(customerRec.FirstName__c != null && customerRec.FirstName__c.length() > 1 && customerRec.FirstName__c.subString(0,1) == customerRecordFilterValue.FirstName__c) {
                            customerSuggestionList.add(new CustomerSuggestion(customerRec, 5));
                            continue;
                        } else {
                            customerSuggestionList.add(new CustomerSuggestion(customerRec, 6));
                            continue;
                        }
                    } 
                } else if(customerRec.Type__c == 'Business') {
                    if(customerRec.Name ==  customerRecordFilterValue.Name) {
                        customerSuggestionList.add(new CustomerSuggestion(customerRec, 4));
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
                    
                    customerSuggestionList.add(new CustomerSuggestion(customerRec, 1));
                    continue;
                }
                
                if((customerRec.Home_Number__c != null && customerRec.Home_Number__c != '' && (customerRec.Home_Number__c == customerRecordFilterValue.Home_Number__c  ||
                                                                                               customerRec.Home_Number__c == customerRecordFilterValue.Mobile__c )) || 
                                                                                               
                        (customerRec.Work_Number__c != null && customerRec.Work_Number__c != '' && (customerRec.Work_Number__c == customerRecordFilterValue.Work_Number__c || 
                                                                                                    customerRec.Work_Number__c == customerRecordFilterValue.Mobile__c))  ||
                                                                                                     
                        (customerRec.Mobile__c != null && customerRec.Mobile__c != '' && (customerRec.Mobile__c == customerRecordFilterValue.Mobile__c ||
                                                                                          customerRec.Mobile__c == customerRecordFilterValue.Home_Number__c ||
                                                                                          customerRec.Mobile__c == customerRecordFilterValue.Work_Number__c ))) {
                            
                    customerSuggestionList.add(new CustomerSuggestion(customerRec, 2));
                    continue;
                }
                
                if((customerRec.Facebook__c != null && customerRec.Facebook__c != '' && customerRec.Facebook__c == customerRecordFilterValue.Facebook__c) || 
                        (customerRec.Twitter__c != null && customerRec.Twitter__c != '' && customerRec.Twitter__c == customerRecordFilterValue.Twitter__c) || 
                        (customerRec.LinkedIn__c != null && customerRec.LinkedIn__c != '' && customerRec.LinkedIn__c == customerRecordFilterValue.LinkedIn__c)) {
                    customerSuggestionList.add(new CustomerSuggestion(customerRec, 3));
                    continue;
                }
                
                String billingStreet = (customerRec.BillingStreet == null ) ? '' : customerRec.BillingStreet;
                List<String> bsList = billingStreet.split('\n');
                String billingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
                
                String filterBillingStreet = (customerRecordFilterValue.BillingStreet == null ) ? '' : customerRecordFilterValue.BillingStreet;
                List<String> filterBSList = filterBillingStreet.split('\n');
                String filterBillingStreet1 = (filterBSList.size() > 0) ? filterBSList[0] : '';
                if(filterBillingStreet1 != '' && filterBillingStreet1 != null && filterBillingStreet1 != 'null' && filterBillingStreet1 == billingStreet1) {
                    customerSuggestionList.add(new CustomerSuggestion(customerRec, 7));
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
    
    @RemoteAction // used on addEditCustomerService
    global static String getSimilarCOUs(String VINNumber){
        VINNumber = BPUtility.getDecodedString(VINNumber);
        try{
            Customer_Owned_Unit__c couRec = new Customer_Owned_Unit__c(VIN_Number__c = VINNumber);
            List<Customer_Owned_Unit__c> custOwnedUnits = SOQLUtil.getOtherSimilarActiveUnits(couRec);
            //List<Customer_Owned_Unit__c> custOwnedUnits = SOQLUtil.getSimilarCOUs(VINNumber);
            List<CustomerOwnedUnit> custOwnedUnitList = new List<CustomerOwnedUnit>();
            for(Customer_Owned_Unit__c custOwnedUnitRec : custOwnedUnits) {
                if(custOwnedUnitRec.VIN_Number__c != null && custOwnedUnitRec.VIN_Number__c != '' && custOwnedUnitRec.VIN_Number__c == VINNumber) {
                    custOwnedUnitList.add(new CustomerOwnedUnit(custOwnedUnitRec));
                }
            }
            return BPUtility.getEncodedString(System.JSON.serialize(custOwnedUnitList));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction // used on addEditCustomerService
    global static String getAllLookupFieldsJSON(){
        try{
            List<Country__c> countryList = SOQLUtil.getAllCountry();
            List<Country__c> countryWrapperList = SOQLUtil.getAllCountryWrapper();
            List<Sales_Tax__c> salesTaxList = SOQLUtil.getSalesTax(new List<Id>());
            List<Price_Level__c> priceLevelList = SOQLUtil.getPriceLevel(new List<Id>());
            List<Unit_Make__c> unitMakeList = new List<Unit_Make__c>();
            List<Unit_Make__c> unitMakeWrapperList = new List<Unit_Make__c>();
            
            COUFieldWrapper cOUFieldWrapperObj = new COUFieldWrapper(countryList, countryWrapperList, salesTaxList, priceLevelList, unitMakeList, unitMakeWrapperList, new List<Category__c>());
            cOUFieldWrapperObj.DefaultOrderingTaxId = GeneralConfiguration.getOrderingTaxRate();
            return BPUtility.getEncodedString(System.JSON.serialize(cOUFieldWrapperObj));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction // used on addEditCustomerService
    global static String saveCustomer(String customerJSONString, String couJSONString) {
        customerJSONString = BPUtility.getDecodedString(customerJSONString);
        couJSONString = BPUtility.getDecodedString(couJSONString);
        try {
            if(AccessControl.ifObjectFieldIsCreateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            if(AccessControl.ifObjectFieldIsCreateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            
            Customer customerObj = Customer.parse(customerJSONString);
            List<CustomerOwnedUnit> couObjList = CustomerOwnedUnit.parse(couJSONString);
            
            // check if customer can be deactivated or not
            ResponseWrapper openBalanceFromAccAppRes = AccountingUtil.getCustomerOpenBalanceInfoForAccApp(customerObj.Id, customerObj.Active, null, null);
            if(openBalanceFromAccAppRes.responseStatus == 'error') {
            	return BPUtility.getEncodedString(System.JSON.serialize(openBalanceFromAccAppRes));
            }
            
            Savepoint sp = Database.setSavepoint();
            Account customerToInsert = new Account();
            customerToInsert = (Account) setCustomerfields(customerObj, customerObj.Type);
            if(customerToInsert.Name != null ) {
                Boolean isInsert = String.isBlank(customerToInsert.Id);
                if(!isInsert) {
                    CustomerTriggerHelper.isBypassValidation = true;
                }
                upsert customerToInsert;
               
                // Create Activity History in case of Insert.
                if(isInsert && !Test.isRunningTest()) {
                    ActivityHistory.createActivityHistory('Add Customer', 'Customer', customerToInsert.Id, 'Customer', customerToInsert.Id, null);
                }
            }
            String customerId = customerToInsert.Id;
            Map<String, Unit_Make__c> makeNameToMakeRecMap = new Map<String, Unit_Make__c>();
            Map<String, Map<String, Unit_Model__c>> makeIdToModelNameToModelRecMap = new Map<String, Map<String, Unit_Model__c>>();
            Map<String, Map<String, Unit_Sub_Model__c>> modelIdToSubModelNameToSubModelRecMap = new Map<String, Map<String, Unit_Sub_Model__c>>();
            
            List<Customer_Owned_Unit__c> couListToInsert = new List<Customer_Owned_Unit__c>();
            List<CustomerOwnedUnit> couList = new List<CustomerOwnedUnit>();
            for(CustomerOwnedUnit couObj : couObjList) {
                if(String.isNotBlank(couObj.Make) && String.isNotBlank(couObj.Model)) {
                    if(String.isBlank(couObj.SubModel) && String.isNotBlank(couObj.SubModelName)) {
                        modelIdToSubModelNameToSubModelRecMap.put(couObj.Model, new Map<String, Unit_Sub_Model__c>{couObj.SubModelName => 
                                                                                                                new Unit_Sub_Model__c(Sub_Model_Name__c = couObj.SubModelName, Unit_Model__c = couObj.Model)});
                        couList.add(couObj);
                    } else {
                        Customer_Owned_Unit__c couRec = new Customer_Owned_Unit__c();
                        couRec.VIN_Number__c = couObj.VIN;
                        couRec.Account__c = customerId;
                        couRec.Colour__c = couObj.Color;
                        couRec.Mileage_Value__c = couObj.Mileage;
                        couRec.Plate__c = couObj.Plate;
                        
                        couRec.Unit_Make__c = couObj.Make;
                        couRec.Reg_Expiry_Date__c = (String.isNotBlank(couObj.RegExpiryDate)) ? DateTimeUtility.parseDate(couObj.RegExpiryDate) : null;/* added by kajal 1st may, 2017 #1975 */
                        couRec.Unit_Model__c = couObj.Model;
                        
                        couRec.Sub_Model__c = couObj.SubModel;
                        couRec.Year__c = couObj.Year;
                        couRec.Status__c = couObj.Status;
                        couRec.Unit_Type__c = couObj.UnitType;
                        couRec.Mileage_Type__c = couObj.MileageType;
                        couListToInsert.add(couRec);
                    }
                } else if(String.isNotBlank(couObj.MakeName) && String.isNotBlank(couObj.ModelName)) {
                    if(couObj.Make != null) {
                        if(makeIdToModelNameToModelRecMap.containsKey(couObj.Make)) {
                            Map<String, Unit_Model__c> modelNameToModelRecMap = makeIdToModelNameToModelRecMap.get(couObj.Make);
                            if(!modelNameToModelRecMap.containsKey(couObj.ModelName)) {
                                modelNameToModelRecMap.put(couObj.ModelName, new Unit_Model__c(Name__c = couObj.ModelName, Unit_Make__c = couObj.Make));
                            }
                            makeIdToModelNameToModelRecMap.put(couObj.Make, modelNameToModelRecMap);
                        } else {
                            makeIdToModelNameToModelRecMap.put(couObj.Make, new Map<String, Unit_Model__c>{couObj.ModelName => new Unit_Model__c(Name__c = couObj.ModelName, Unit_Make__c = couObj.Make)});
                        }
                    } else {
                        if(!makeNameToMakeRecMap.containsKey(couObj.MakeName)) {
                            makeNameToMakeRecMap.put(couObj.MakeName, new Unit_Make__c(Name = couObj.MakeName));
                        }
                    }
                    couList.add(couObj);
                }
             }
             if(makeNameToMakeRecMap.size() > 0) {
                DMLUtility.insertSobjectList('Unit_Make__c', makeNameToMakeRecMap.values());
                
                for(CustomerOwnedUnit couObj : couList) {
                    if(makeNameToMakeRecMap.containsKey(couObj.MakeName)) {
                        couObj.Make = makeNameToMakeRecMap.get(couObj.MakeName).Id;
                        if(makeIdToModelNameToModelRecMap.containsKey(couObj.Make)) {
                            Map<String, Unit_Model__c> modelNameToModelRecMap = makeIdToModelNameToModelRecMap.get(couObj.Make);
                            if(!modelNameToModelRecMap.containsKey(couObj.ModelName)) {
                                modelNameToModelRecMap.put(couObj.ModelName, new Unit_Model__c(Name__c = couObj.ModelName, Unit_Make__c = couObj.Make));
                            }
                            makeIdToModelNameToModelRecMap.put(couObj.Make, modelNameToModelRecMap);
                        
                        } else {
                            makeIdToModelNameToModelRecMap.put(couObj.Make, new Map<String, Unit_Model__c>{couObj.ModelName => new Unit_Model__c(Name__c = couObj.ModelName, Unit_Make__c = couObj.Make)});
                        }
                    }
                 }
             }
             
             if(makeIdToModelNameToModelRecMap.size() > 0) {
                List<Unit_Model__c> modelListToInsert = new List<Unit_Model__c>();
                for(Map<String, Unit_Model__c> modelNameToModelRecMap : makeIdToModelNameToModelRecMap.values()) {
                    modelListToInsert.addAll(modelNameToModelRecMap.values());
                }
                DMLUtility.insertSobjectList('Unit_Model__c', modelListToInsert);
                
                
                for(Unit_Model__c modelRec : modelListToInsert) {
                    if(makeIdToModelNameToModelRecMap.containsKey(modelRec.Unit_Make__c)) {
                        Map<String, Unit_Model__c> modelNameToModelRecMap = makeIdToModelNameToModelRecMap.get(modelRec.Unit_Make__c);
                        if(modelNameToModelRecMap.containsKey(modelRec.Name__c)) {
                            modelNameToModelRecMap.put(modelRec.Name__c, modelRec);
                        }
                    }
                }
             }
             //Database.rollback(sp);
             //system.assert(false, makeIdToModelNameToModelRecMap);
             
             for(CustomerOwnedUnit couObj : couList) {
                if(makeNameToMakeRecMap.containsKey(couObj.MakeName)) {
                    couObj.Make = makeNameToMakeRecMap.get(couObj.MakeName).Id;
                }
                
                if(makeIdToModelNameToModelRecMap.containsKey(couObj.Make)) {
                    Map<String, Unit_Model__c> modelNameToModelRecMap = makeIdToModelNameToModelRecMap.get(couObj.Make);
                    
                    if(modelNameToModelRecMap.containsKey(couObj.ModelName)) {
                        couObj.Model = modelNameToModelRecMap.get(couObj.ModelName).Id;
                    }
                }
                if(String.isNotBlank(couObj.SubModelName)) {
                    if(modelIdToSubModelNameToSubModelRecMap.containsKey(couObj.Model)) {
                        Map<String, Unit_Sub_Model__c> submodelNameToSubModelRecMap = modelIdToSubModelNameToSubModelRecMap.get(couObj.Model);
                        
                        if(!submodelNameToSubModelRecMap.containsKey(couObj.SubModelName)) {
                            submodelNameToSubModelRecMap.put(couObj.SubModelName, new Unit_Sub_Model__c(Sub_Model_Name__c = couObj.SubModelName, Unit_Model__c = couObj.Model));
                        }
                        modelIdToSubModelNameToSubModelRecMap.remove(couObj.Model);
                        modelIdToSubModelNameToSubModelRecMap.put(couObj.Model, submodelNameToSubModelRecMap);
                    
                    } else {
                        modelIdToSubModelNameToSubModelRecMap.put(couObj.Model, new Map<String, Unit_Sub_Model__c>{couObj.SubModelName => new Unit_Sub_Model__c(Sub_Model_Name__c = couObj.SubModelName, Unit_Model__c = couObj.Model)});
                    }
                }
             }
             
             if(modelIdToSubModelNameToSubModelRecMap.size() > 0) {
                List<Unit_Sub_Model__c> submodelListToInsert = new List<Unit_Sub_Model__c>();
                for(Map<String, Unit_Sub_Model__c> submodelNameToSubModelRecMap : modelIdToSubModelNameToSubModelRecMap.values()) {
                    submodelListToInsert.addAll(submodelNameToSubModelRecMap.values());
                }
                DMLUtility.insertSobjectList('Unit_Sub_Model__c', submodelListToInsert);
                for(Unit_Sub_Model__c submodelRec : submodelListToInsert) {
                    if(modelIdToSubModelNameToSubModelRecMap.containsKey(submodelRec.Unit_Model__c)) {
                        Map<String, Unit_Sub_Model__c> submodelNameToSubModelRecMap = modelIdToSubModelNameToSubModelRecMap.get(submodelRec.Unit_Model__c);
                        if(submodelNameToSubModelRecMap.containsKey(submodelRec.Sub_Model_Name__c)) {
                            submodelNameToSubModelRecMap.put(submodelRec.Sub_Model_Name__c, submodelRec);
                        }
                        modelIdToSubModelNameToSubModelRecMap.put(submodelRec.Unit_Model__c, submodelNameToSubModelRecMap);
                    }
                }
             }
             
             for(CustomerOwnedUnit couObj : couList) {
                Customer_Owned_Unit__c couRec = new Customer_Owned_Unit__c();
                if(modelIdToSubModelNameToSubModelRecMap.containsKey(couObj.Model) && String.isNotBlank(couObj.SubModelName)) {
                    Map<String, Unit_Sub_Model__c> submodelNameToSubModelRecMap = modelIdToSubModelNameToSubModelRecMap.get(couObj.Model);
                    if(submodelNameToSubModelRecMap.containsKey(couObj.SubModelName)) {
                        couRec.Sub_Model__c = submodelNameToSubModelRecMap.get(couObj.SubModelName).Id;
                    }
                }
                couRec.VIN_Number__c = couObj.VIN;
                couRec.Account__c = customerId;
                couRec.Colour__c = couObj.Color;
                couRec.Mileage_Value__c = couObj.Mileage;
                couRec.Plate__c = couObj.Plate;
                couRec.Reg_Expiry_Date__c = (String.isNotBlank(couObj.RegExpiryDate)) ? DateTimeUtility.parseDate(couObj.RegExpiryDate) : null;/* added by kajal 1st may, 2017 #1975 */
                couRec.Unit_Make__c = couObj.Make;
                couRec.Unit_Model__c = couObj.Model;
                //couRec.Sub_Model__c = couObj.SubModel;
                couRec.Year__c = couObj.Year;
                couRec.Status__c = couObj.Status;
                couRec.Unit_Type__c = couObj.UnitType;
                couRec.Mileage_Type__c = couObj.MileageType;
                couListToInsert.add(couRec);
             }
             if(couListToInsert.size() > 0) {
                insert couListToInsert ;
             }
             JSONGenerator gen = JSON.createGenerator(true);
             gen.writeStartObject();
             gen.writeStringField('Id', customerId);
             gen.writeStringField('CustomerName', customerToInsert.Name);
             gen.writeEndObject();
             return BPUtility.getEncodedString(gen.getAsString());


        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    // used in same class
    private static Sobject setCustomerfields(Customer custObj, String typeOfCustomer){
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
                customerToInsert.put('Nickname__c', custObj.Nickname);
            } else if(typeOfCustomer == 'Business'){
                customerToInsert.put('Name', custObj.BusinessName);
            }
            customerToInsert.put('Tax_Id__c', custObj.TaxId);
            customerToInsert.put('Ag_Other_ID__c', custObj.OtherId);
            
            customerToInsert.put('Home_Number__c', custObj.HomeNumber);
            customerToInsert.put('Mobile__c', custObj.OtherPhone);
            customerToInsert.put('Work_Number__c', custObj.WorkNumber);
            customerToInsert.put('Email__c', custObj.HomeEmail);
            
            if(custObj.BirthDay != null && custObj.BirthMonth != null && custObj.BirthYear != null) {
                Date birth_Date = Date.newInstance(custObj.BirthYear, custObj.BirthMonth, custObj.BirthDay);
                customerToInsert.put('Birth_Date__c', birth_Date);
            } else {
                customerToInsert.put('Birth_Date__c', null);
            }
                
            customerToInsert.put('Type__c', custObj.Type);
            customerToInsert.put('Active__c', custObj.Active);
            customerToInsert.put('Is_Customer__c', custObj.IsCustomer);
            customerToInsert.put('Is_Vendor__c', custObj.IsVendor);
            customerToInsert.put('Work_Email__c', custObj.WorkEmail);
            customerToInsert.put('Other_Email__c', custObj.OtherEmail);
            customerToInsert.put('Account_Type__c', custObj.AccountTypeId);
            
            customerToInsert.put('Home_Number_SMS__c', custObj.HomeNumberSMS);
            customerToInsert.put('Work_Number_SMS__c', custObj.WorkNumberSMS);
            customerToInsert.put('Mobile_Number_SMS__c', custObj.MobileNumberSMS);
            customerToInsert.put('Drivers_License__c', custObj.DriversLicense);
            customerToInsert.put('Drivers_License_Expiry_Date__c', DateTimeUtility.parseDate(custObj.LicenseExpiryFormattedDate));
            
            if(custObj.PreferredEmail == 'HomeEmail') {
                customerToInsert.put('Preferred_Email__c', custObj.HomeEmail);
            } else if(custObj.PreferredEmail == 'WorkEmail') {
                customerToInsert.put('Preferred_Email__c', custObj.WorkEmail);
            } else if(custObj.PreferredEmail == 'OtherEmail') {
                customerToInsert.put('Preferred_Email__c', custObj.OtherEmail);
            } else if(custObj.PreferredEmail == '') {
                customerToInsert.put('Preferred_Email__c', null);
            }
            
            if(custObj.PreferredPhone == 'HomeNumber') {
                customerToInsert.put('Preferred_Phone__c', custObj.HomeNumber);
            } else if(custObj.PreferredPhone == 'OtherPhone') {
                customerToInsert.put('Preferred_Phone__c', custObj.OtherPhone);
            } else if(custObj.PreferredPhone == 'WorkNumber') {
                customerToInsert.put('Preferred_Phone__c', custObj.WorkNumber);
            } else if(custObj.PreferredPhone == '') {
                customerToInsert.put('Preferred_Phone__c', null);
            } 
            
            if(custObj.PreferredSMS == 'HomeNumber') {
                customerToInsert.put('Preferred_SMS__c', custObj.HomeNumber);
            } else if(custObj.PreferredSMS == 'OtherPhone') {
                customerToInsert.put('Preferred_SMS__c', custObj.OtherPhone);
            } else if(custObj.PreferredSMS == 'WorkNumber') {
                customerToInsert.put('Preferred_SMS__c', custObj.WorkNumber);
            } else if(custObj.PreferredSMS == '') {
                customerToInsert.put('Preferred_SMS__c', null);
            } 
            
            customerToInsert.put('Facebook__c', custObj.FacebookLink);
            customerToInsert.put('Twitter__c', custObj.TwitterLink);
            customerToInsert.put('LinkedIn__c', custObj.LinkedInLink);
            
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
            customerToInsert.put('Sales_Tax__c', custObj.SalesTaxId);
            customerToInsert.put('Purchase_Tax__c', custObj.PurchaseTaxId);
             if(custObj.PriceLevelId == null && String.isBlank(custObj.Id)) {
                if(AccessControl.ifObjectFieldIsAccessible('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Price_Level__c> defaultPriceLevel = [select Id from Price_Level__c where Default__c = true];
                if(defaultPriceLevel.size() > 0) {
                    customerToInsert.put('Price_Level__c', defaultPriceLevel[0].Id);
                }
            }
            
            if(custObj.SalesTaxId == null && String.isBlank(custObj.Id)) {
                if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<Sales_Tax__c> defaultSalesTax = [select Id from Sales_Tax__c where Default__c = true];
                if(defaultSalesTax.size() > 0) {
                    customerToInsert.put('Sales_Tax__c', defaultSalesTax[0].Id);
                }
            }
            customerToInsert.put('Allow_Charge_On_Account__c', custObj.AllowChargeOnAccount != null ? custObj.AllowChargeOnAccount : false);
            if(custObj.Id != null && custObj.Id != '') {
                customerToInsert.put('Id', custObj.Id);
            }   
            return customerToInsert;
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    global static String addVOHeaderToCOLI(String partId, String coliId, String voHeaderId, String coHeaderId, String itemsPageSortAttrsJSON, String customersPageSortAttrsJSON, String stocksPageSortAttrsJSON) { return ''; }
    
    global static String addVOHeaderToCOLIServiceOrder(String partId,String coliId, String voHeaderId, String coHeaderId,String itemsPageSortAttrsJSON,String customersPageSortAttrsJSON,String stocksPageSortAttrsJSON) { return ''; }
    
    global static String createSOHeader(String coHeaderId) { return ''; }
    
    global static String saveCOU(String couJSONString, String customerId) { return ''; }
    
    global static String savePinItems(String pinItemsJSONStr) { return ''; }
    
    global static String addLineItems(String lineItemId, String soHeaderId, String coHeaderId, String customerId) {
    	ServiceJobService.addServiceJobLineItems(system.JSON.serialize(new CustomerOrderWrapper.LineItemWrapper(BPUtility.getDecodedString(lineItemId), null)), BPUtility.getDecodedString(soHeaderId), BPUtility.getDecodedString(coHeaderId), BPUtility.getDecodedString(customerId)); 
    	return '';
    }
    
    global static String changeSOHeaderStatusToComplete(String soHeaderId, String coHeaderId) { return ''; }
    
    global static String updateSOLineItems(String lineItemJSON, String coHeaderId) { return ''; }
    
    global static String updateSOKHLineItems(String soKHItemJSON, String coHeaderId) { return ''; }
    
    global static String removeLineItems(String lineItemId, String coHeaderId, String soHeaderId) { return ''; }
    
    global static String splitSOKHItem(String lineItemId, String coHeaderId) { return ''; }
    
    global static String saveHoursLogged(String hoursLoggedJSONString, String coHeaderId) { return ''; }
    
    global static String insertFeeInMerchGrid(String lineItemId, String coHeaderId) { return ''; }
    
    global static String insertKitHeaderInMerchGrid(String lineItemId, String coHeaderId) { return ''; }
    
    global static String updateCOKHLineItems(String coKHItemJSON, String coHeaderId) { return ''; }
    
    global static String updateCOKHLineItemsRecalculation(String coKHItemJSON, String coHeaderId,String CokHLineItemJson) { return ''; }
    
    global static String removeLineItemsInMerchGrid(String lineItemId, String coHeaderId) { return ''; }
    
    global static String splitCOKHItem(String lineItemId, String coHeaderId) { return ''; }
    
    global static String getGridTotal(String coHeaderId, String gridId, String gridName, Boolean isAustralianMarket) { return ''; }

    global static String moveLineItem(String idToMove, String destinationId, String sectionTo, String coHeaderId) { return ''; }
    
    global static String deleteServiceOrder(String coHeaderId, String soHeaderId) { return ''; }    
    
    global static String insertLogRecord(String jSONString, String statusType) { return ''; }
    
    global static String getStatusResults(String workStatus, String claimStatus) { return ''; }
    
    global static String getAppLogRecById(String appLogId) { return ''; }
    
    global static String getWizardInfo(String soHeaderId, String wizardName) { return ''; }
    
    global static String saveWizardDetails(String soHeaderId, String wizardKey, String wizardJsonToSave, String deleteRecordsJson) { return ''; }
    
    global static String sendOnSignInWizard(String custJsonStr, String notes, String soHeaderId, String customerName) { return ''; }
    
    global static void changeStatus(String soHeaderId, String newStatus, String statusType) {}
    
    global static string addDeductibleAmount(String deductibleJson) { return ''; }
    
    global static String getSoPaymentRoleById(String soHeaderId) { return ''; }
    
    global static String getAttachmentListByParentId(String parentId) { return ''; }
    
    global static String removeAttachment(String attachmentId, String soHeaderId) { return ''; }
    
    global static String uploadAttachment(String filename, String fileData, String recordId, String description) { return ''; }
    
    global static String getClaimRecById(String soHeaderId) { return ''; }
    
    global static String getCustomerApprovalInfo(String soHeaderId, String sectionKey, Decimal approvalCount) { return ''; }
    
    global static String saveCustomerApprovalInfo(String soHeaderId, String JSONString) { return ''; }
    
    global static String getProviderInfo(String vendorId) { return ''; }
    
    global static String getPrintingInfo(String soHeaderId) { return ''; }
    
    global static void createClaim(Service_Order_Header__c soHeaderRec) {}
    
    global static String submitClaimRecords(String soHeaderId) { return ''; }
    
    global static String saveClaimResponse(String soHeaderId, String ClaimWizardJson, String StepNumber) { return ''; }
    
    global static String createDeal(String coHeaderId) { return ''; }
    
    global static String getDealDetails(String objectId, String gridName) { return ''; }
    
    global static String getDealCoDeposits(String DealId) { return ''; }
    
    global static String saveCODealDeposit(String jsonString,String DealId) { return ''; }
    
    global static String saveDealInfoDetails(String coHeaderId, String dealId, String json) { return ''; }
    
    global static String updateDealStatus(String dealId, String dealStatus) { return ''; }

    global static String saveTemporaryUnit(String dealId, String jSONString) { return ''; }
    
    global static String addUnitToDeal(String dealItemId, String unitId) { return null; }
    
    global static String addUnitToDeal(String dealItemId, String unitId, String dealId) { return ''; }
    
    global static String updateDealUnitCostPrice(String DealUnitCostPriceItemjson, String dealId, String dealItemId) { return ''; }
    
    global static String removeUnitFromDeal(String dealId, String dealItemId) { return ''; }
    
    global static String getServiceWorksheetPrintDetail(String coHeaderId) { return ''; }
    
    global static void saveWorkseetSelectionJson(String coHeaderId, String jsonString) {}
    
    global static String insertFeeInQuickCashSale(String lineItemId, String coHeaderId) { return ''; } 
    
    global static String saveLineItemInQuickCashSale(String coHeaderId, String jSONString) { return ''; }
    
    global static String updateLineItemDescInQuickCashSale(String coHeaderId, String jSONString) { return ''; }
    
    public static void deleteTemporaryCoLineItems(String coHeaderId, String ColineItemId) { }
    
    global static String finalizeQuickSale(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType) { return ''; }
    
    global static String saveOptionFeesLineItem(String dealId, String dealItemId, String jSONString) { return ''; }
    
    global static String removeOptionFeesLineItem(String dealItemId, String lineItemId) { return ''; }
     
    global static String updateTradeIn(String dealId, String jsonString) { return ''; }
    
    global static String createDealMerchAndServiceSetion(String dealId, String coHeaderId) { return ''; }
    
    global static String moveDealMerchAndServiceLineItems(String optionFeeRecId, String coHeaderId) { return ''; }
    
    @RemoteAction // used on addEditCustomerService
    global static String getMakeList() {
        return ViewCustomerCtrl.getMakeList();
    }
    
    @RemoteAction // used on addEditCustomerService
    global static String getModelList(String MakeId) {
        return ViewCustomerCtrl.getModelList(MakeId);
    }
    
    @RemoteAction // used on addEditCustomerService
    global static String getSubModelList(String ModelName,String MakeId) {
        return ViewCustomerCtrl.getSubModelList(ModelName, MakeId);
    }
    
    global static String resolveFulfillment(String dealId, String unresolvedFulfillmentObjJSON, String chargeMethod, String selectedUnitId) { return ''; }
    
    global static String getDealFinanceMasterData() { return ''; }
    
    global static String updateDealFinanceDetails(String dealId, String dealFinanceJSON) { return ''; }
    
    global static String removeFAndIProductLineItem(String dealId, String fAndIProductId) { return ''; }
    
    global static String saveDealFAndIProduct(String dealId, String dealFAndIProductJSON) { return ''; }
        
    public static void createDUPCFromUPCForSKU_future(Map<String, String> skuIdToDealItemIdMap) {}
    
    global static String updateDealFinanceStatus(String coHeaderId, String dealId, String dealFinanceObjJson, String financeStatus) { return ''; }
    
    global static String recalculationOfDealKHLineItems(String dealKHJSON, String dealKHLineItemJSON) { return ''; }
    
    global static String insertKitHeaderInDealMerchGrid(String jsonStr, String dealId, String coHeaderId) { return ''; }
    
    global static String insertCOLineItems(String partId, String coHeaderId, String jSONString, Boolean isSuppress, Boolean isDuplicateCheck, String soHeaderId, String customerId) { return ''; }
    
    global static String insertOptionAndFeeLineItems(String partId, String coHeaderId, String dealId, String dealItemId, String jSONString, Boolean isSuppress, Boolean isDuplicateCheck) { return ''; }
    
    global static String showHistoryOnSuppressPopup(String partId, String coHeaderId) { return ''; }
    
    global static String getCOUListByCustomerId(String customerId) { return ''; }
    
    global static String getTechnicianList() { return ''; }
    
    global static void saveScheduleDate(String soHeaderId, String scheduledDate) {}
    
    global static void removeMerchandiseSection(String coHeaderId, Boolean flag) {}
    
    global static String getCheckoutSalesTax(String coInvoiceId) { return ''; }
    
    global static String removeDeal(String dealId) { return ''; }
    
    global static String deleteCustomerOrder(String coHeaderId) { return ''; }
    
    global static String setCOStatusAsQuote(String coHeaderId) { return ''; }
    
    global static String activateQuoteCO(String coHeaderId) { return ''; }
    
    global static String deleteQuoteCustomerOrder(String coHeaderId) { return ''; }
    
    global static String updateStampDuty(String dealItemId, String stampDutyTotal) { return ''; }
    
    global static String toggleRideawayPricingEnabled(String dealItemId, Decimal totalEnforceRideawayPrice, Boolean IsRideawayPricingEnabled) { return ''; }
    
    global static String updateRideawayPricing(String dealItemId, String unitJsonString) { return ''; }
    
    global static String getAlternatePartsList(String partId) { return ''; }
    
    global static String addServiceOrderLineItems(String partIdsString, String soHeaderId) { return ''; }
    
    @RemoteAction // used on addEditCustomerService
    public static String getAllAccountTypeForCustomer() {
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(AccountTypeService.getAllAccountTypeForCustomer()));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction // used on angucompleteServices
    global static String getCampaignsByVIN(String vin) {
        return BPUtility.getEncodedString(System.JSON.serialize(BRPAPIManager.getCampaignsByVIN(BPUtility.getDecodedString(vin))));
    }
}