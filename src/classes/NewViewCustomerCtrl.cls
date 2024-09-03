/**
 * Author: Tarun Khandelwal
 * Since: June 05, 2015
 * Name: CustomerViewCtrl
 * Description: Controller Class of Customer Detail Page.
**/
global without sharing class NewViewCustomerCtrl {
    
    public Decimal Related_List_Page_Size { get{return GeneralConfiguration.getRelatedListPageSize();} private set;}
    public String MapAPIKey {get{return GeneralConfiguration.getMapAPIKey();} private set;}
    
    global NewViewCustomerCtrl (NewHomePageCtrl controller){}
    public NewViewCustomerCtrl() {}
    
    /* deprecated */
    /** deprecated by richa created getCustomerDetail()
     * Name: getCustomerInfo
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction 
    global static String getCustomerInfo(String customerId, String COUPageSortAttrsJSON, String ActiveOrdersPageSortAttrsJSON, String customersPageSortAttrsJSON, String contactsPageSortAttrsJSON) {
        /*customerId = BPUtility.getDecodedString(customerId);
        COUPageSortAttrsJSON = BPUtility.getDecodedString(COUPageSortAttrsJSON);
        ActiveOrdersPageSortAttrsJSON = BPUtility.getDecodedString(ActiveOrdersPageSortAttrsJSON);
        customersPageSortAttrsJSON = BPUtility.getDecodedString(customersPageSortAttrsJSON);
        contactsPageSortAttrsJSON = BPUtility.getDecodedString(contactsPageSortAttrsJSON);
        
        PaginationSorting COUPageSortAttrs = parsePageAttrs(COUPageSortAttrsJSON);
        PaginationSorting ActiveOrdersPageSortAttrs = parsePageAttrs(ActiveOrdersPageSortAttrsJSON);
        PaginationSorting customersPageSortAttrs = parsePageAttrs(customersPageSortAttrsJSON);
        PaginationSorting contactsPageSortAttrs = parsePageAttrs(contactsPageSortAttrsJSON);
        
        Integer TotalCustomerRecords;
        Integer TotalCOURecords;
        Integer TotalActiveSalesOrderRecords;
        Integer TotalContactRecords;
        Integer TotalTaxExemptionRecord;
        
        List<Account> customers = SOQLUtil.getCustomer(customerId, 'Customer');
        
        Map<String, String> accountIdToRelationMap = getRelatedCustomerRelationMap(customerId);
        List<Account> relatedCustomerRecList = SOQLUtil.getRelatedAccountRecs(accountIdToRelationMap.keyset());
        TotalCustomerRecords = relatedCustomerRecList.size();
        relatedCustomerRecList = TaxExemption.getPaginatedRecords(relatedCustomerRecList, customersPageSortAttrs.CurrentPage, customersPageSortAttrs.PageSize);
        
        List<Customer_Owned_Unit__c> COUList = SOQLUtil.getCOURecordByFieldName('Account__c', customerId);
        TotalCOURecords = COUList.size();
        COUList = TaxExemption.getPaginatedRecords(COUList, COUPageSortAttrs.CurrentPage, COUPageSortAttrs.PageSize);
        
        List<CO_Header__c> ActiveSalesOrdersList = SOQLUtil.getCOHeaderDetailsForCustomer(customerId, null);
        TotalActiveSalesOrderRecords = ActiveSalesOrdersList.size();
        ActiveSalesOrdersList = TaxExemption.getPaginatedRecords(ActiveSalesOrdersList, ActiveOrdersPageSortAttrs.CurrentPage, ActiveOrdersPageSortAttrs.PageSize);
        
        List<Contact> customerContactList = SOQLUtil.getCustomerContactByFieldName('AccountId', customerId);
        TotalContactRecords = customerContactList.size();
        customerContactList = TaxExemption.getPaginatedRecords(customerContactList, contactsPageSortAttrs.CurrentPage, contactsPageSortAttrs.PageSize);
        
        List<Tax_Exemption__c> taxExemptionList = SOQLUtil.getTaxExemptionList(customerId, new Map<String, String>());
        TotalTaxExemptionRecord = taxExemptionList.size();
        
        List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
        List<Sales_Tax__c> applicableTaxList = SOQLUtil.getSalesTax(new List<Id>());
         

        String JSONString = '{}'; 
        CustomerDetail customerDetailRec;
        if(customers.size() > 0) {
            customerDetailRec = new CustomerDetail(customers[0], relatedCustomerRecList, accountIdToRelationMap, COUList, ActiveSalesOrdersList, customerContactList, 
                                                        getLastVisitOrderByCustomerId(customerId), taxExemptionList, businessProfileList, applicableTaxList);
            customerDetailRec.TotalCustomerRecords = TotalCustomerRecords;
            customerDetailRec.TotalCOURecords = TotalCOURecords;
            customerDetailRec.TotalActiveSalesOrderRecords = TotalActiveSalesOrderRecords;
            customerDetailRec.TotalContactRecords = TotalContactRecords;
            customerDetailRec.TotalTaxExemptionRecords = TotalTaxExemptionRecord;
            
            JSONString = System.JSON.serialize(customerDetailRec);
        }*/
        return BPUtility.getEncodedString('');
    }
    
    
    /**
     * Name: getCustomerDetail
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction 
    global static String getCustomerDetail(String customerId, String COUPageSortAttrsJSON, String ActiveOrdersPageSortAttrsJSON, String customersPageSortAttrsJSON, String contactsPageSortAttrsJSON, String AllCustomerOrdersPageSortAttrsJSON) {
        
        return '';
    
    }
    
    /**
     * Name: getCustomerDetail
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction 
    global static String getCustomerDetails(String customerInfo) { // updated the getCustomerDetails parameter to handle multiple parameters updated by Hitesh
        customerInfo = BPUtility.getDecodedString(customerInfo);
        CustomerRequestBody requestBody = (CustomerRequestBody)System.JSON.deserialize(customerInfo, CustomerRequestBody.class);
        
        String customerId = requestBody.customerId;
        String COUPageSortAttrsJSON = requestBody.COUPageSortAttrsJSON;
        String ActiveOrdersPageSortAttrsJSON = requestBody.ActiveOrdersPageSortAttrsJSON;
        String activeQuotesPageSortAttrsJSON = requestBody.ActiveQuotesPageSortAttrsJSON;
        String archivedQuotesPageSortAttrsJSON = requestBody.ArchivedQuotesPageSortAttrsJSON;
        String customersPageSortAttrsJSON = requestBody.customersPageSortAttrsJSON;
        String contactsPageSortAttrsJSON = requestBody.contactsPageSortAttrsJSON;
        String AllCustomerOrdersPageSortAttrsJSON = requestBody.AllCustomerOrdersPageSortAttrsJSON;
        String StoreCreditPageSortAttrsJSON = requestBody.StoreCreditPageSortAttrsJSON;
        String SMSMessagePageSortAttrsJSON = requestBody.SMSMessagePageSortAttrsJSON; 
        
        PaginationSorting COUPageSortAttrs = parsePageAttrs(COUPageSortAttrsJSON);
        PaginationSorting ActiveOrdersPageSortAttrs = parsePageAttrs(ActiveOrdersPageSortAttrsJSON);
        PaginationSorting activeQuotesPageSortAttrs = parsePageAttrs(activeQuotesPageSortAttrsJSON);
        PaginationSorting archivedQuotesPageSortAttrs = parsePageAttrs(archivedQuotesPageSortAttrsJSON);
        PaginationSorting customersPageSortAttrs = parsePageAttrs(customersPageSortAttrsJSON);
        PaginationSorting contactsPageSortAttrs = parsePageAttrs(contactsPageSortAttrsJSON);
        PaginationSorting AllCustomerOrdersPageSortAttrs = parsePageAttrs(AllCustomerOrdersPageSortAttrsJSON);
        PaginationSorting StoreCreditPageSortAttrs = parsePageAttrs(StoreCreditPageSortAttrsJSON); 
        PaginationSorting SMSMessagePageSortAttrs = parsePageAttrs(SMSMessagePageSortAttrsJSON); 
        
        Integer TotalCustomerRecords, totalActiveQuoteCO, totalArchivedCO, totalActiveSalesCO;
        Integer TotalCOURecords;
        Integer TotalContactRecords;
        Integer TotalTaxExemptionRecord;
        Integer TotalCustomerOrderRecords;
        Integer TotalStoreCreditRecords;
        Integer TotalMSGRecords;
        
        List<Account> customers = SOQLUtil.getCustomer(customerId, 'Customer');
        
        Map<String, String> accountIdToRelationMap = getRelatedCustomerRelationMap(customerId);
        List<Account> relatedCustomerRecList = SOQLUtil.getRelatedAccountRecs(accountIdToRelationMap.keyset());
        TotalCustomerRecords = relatedCustomerRecList.size();
        relatedCustomerRecList = TaxExemption.getPaginatedRecords(relatedCustomerRecList, customersPageSortAttrs.CurrentPage, customersPageSortAttrs.PageSize);
        
        List<Customer_Owned_Unit__c> COUList = getActiveUnits(customerId);
        TotalCOURecords = COUList.size();
        COUList = TaxExemption.getPaginatedRecords(COUList, COUPageSortAttrs.CurrentPage, COUPageSortAttrs.PageSize);
        List<CO_Header__c> openOrdersList = SOQLUtil.getCOHeaderDetailsForCustomer(customerId, new Map<String, String>{'LastModifiedDate' => 'DESC'});
        List<CO_Header__c> activeSalesOrdersList = new List<CO_Header__c>();
        List<CO_Header__c> activeQuoteList = new List<CO_Header__c>();
        List<CO_Header__c> archivedQuoteList = new List<CO_Header__c>();
        for(CO_Header__c coh : openOrdersList) {
            if(String.isNotBlank(coh.Order_status__c) && coh.Order_status__c.equalsIgnoreCase('Quote')) {
                if(coh.Is_Archived__c) {
                    archivedQuoteList.add(coh);
                } else {
                    activeQuoteList.add(coh);
                }
            } else {
                activeSalesOrdersList.add(coh);
            }
        }
        totalActiveSalesCO = activeSalesOrdersList.size();
        totalActiveQuoteCO = activeQuoteList.size();
        totalArchivedCO = archivedQuoteList.size();
        activeSalesOrdersList = TaxExemption.getPaginatedRecords(activeSalesOrdersList, ActiveOrdersPageSortAttrs.CurrentPage, ActiveOrdersPageSortAttrs.PageSize);
        activeQuoteList = TaxExemption.getPaginatedRecords(activeQuoteList, activeQuotesPageSortAttrs.CurrentPage, activeQuotesPageSortAttrs.PageSize);
        archivedQuoteList = TaxExemption.getPaginatedRecords(archivedQuoteList, archivedQuotesPageSortAttrs.CurrentPage, archivedQuotesPageSortAttrs.PageSize);
        
        List<Contact> customerContactList = SOQLUtil.getCustomerContactByFieldName('AccountId', customerId);
        TotalContactRecords = customerContactList.size();
        customerContactList = TaxExemption.getPaginatedRecords(customerContactList, contactsPageSortAttrs.CurrentPage, contactsPageSortAttrs.PageSize);
        
        List<Tax_Exemption__c> taxExemptionList = SOQLUtil.getTaxExemptionList(customerId, new Map<String, String>());
        TotalTaxExemptionRecord = taxExemptionList.size();
        
        List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
        List<Sales_Tax__c> applicableTaxList = SOQLUtil.getSalesTax(new List<Id>());
        
        List<CO_Header__c> AllCustomerOrdersList = SOQLUtil.getAllCustomerOrdersForCustomer(customerId);
        TotalCustomerOrderRecords = AllCustomerOrdersList.size();
        AllCustomerOrdersList = TaxExemption.getPaginatedRecords(AllCustomerOrdersList, AllCustomerOrdersPageSortAttrs.CurrentPage, AllCustomerOrdersPageSortAttrs.PageSize);
         
        List<Store_Credit__c> customerStoreCreditList = SOQLUtil.getCustomerStoreCreditByFieldName('Customer__c', customerId);
        TotalStoreCreditRecords = customerStoreCreditList.size(); 
        customerStoreCreditList = TaxExemption.getPaginatedRecords(customerStoreCreditList, StoreCreditPageSortAttrs.CurrentPage, StoreCreditPageSortAttrs.PageSize);
        String taxExemptions;
        if(customers[0].Account_type__r.Id != null) {
        	AccountTypeWrapper accRec = AccountTypeService.getRecForAccountType(customers[0].Account_type__r.Id);
        	taxExemptions = accRec != null ? accRec.TaxExemptions : ''; 
        }
         
        List<Message_History__c> smsRecList = SOQLUtil.getMessageList(new Map<String, String>{'Sent_To__c' => customerId});
        TotalMSGRecords = smsRecList.size();
        smsRecList = TaxExemption.getPaginatedRecords(smsRecList, SMSMessagePageSortAttrs.CurrentPage, SMSMessagePageSortAttrs.PageSize);
        
        String JSONString = '{}'; 
        CustomerDetail customerDetailRec;
        if(customers.size() > 0) {
            customerDetailRec = new CustomerDetail(customers[0], relatedCustomerRecList, accountIdToRelationMap, COUList, activeSalesOrdersList, activeQuoteList, archivedQuoteList, customerContactList, 
                                                        getLastVisitOrderByCustomerId(customerId), taxExemptionList, businessProfileList, applicableTaxList, AllCustomerOrdersList,
                                                        customerStoreCreditList, smsRecList, taxExemptions);
            customerDetailRec.TotalCustomerRecords = TotalCustomerRecords;
            customerDetailRec.TotalCOURecords = TotalCOURecords; 
            customerDetailRec.TotalContactRecords = TotalContactRecords;
            customerDetailRec.TotalTaxExemptionRecords = TotalTaxExemptionRecord;
            customerDetailRec.TotalCustomerOrderRecords = TotalCustomerOrderRecords;
            customerDetailRec.TotalStoreCreditRecords = TotalStoreCreditRecords;
            customerDetailRec.TotalMessageRecords = TotalMSGRecords;
            customerDetailRec.TotalActiveSalesOrderRecords = totalActiveSalesCO;
            customerDetailRec.TotalActiveQuoteRecords = totalActiveQuoteCO;
            customerDetailRec.TotalArchivedQuoteRecords = totalArchivedCO;
            
            JSONString = System.JSON.serialize(customerDetailRec);
        }
        return BPUtility.getEncodedString(JSONString);
    }
    
    // Remove Transferred and Inactive Units - #4625
    private static List<Customer_Owned_Unit__c> getActiveUnits(String customerId) {
        List<Customer_Owned_Unit__c> COUList = new List<Customer_Owned_Unit__c>();
        for(Customer_Owned_Unit__c couRec : (List<Customer_Owned_Unit__c>)SOQLUtil.getCOURecordByFieldName('Account__c', customerId)) {
            if(couRec.Status__c == 'Active') {
                COUList.add(couRec);
            }
        }
        return COUList;
    }
    
    /**
     * Name: getOtherSimilarCustomer
     * Desc: 
     * @param:  
     * @return:  
    **/
   @RemoteAction
    global static String getSimilarCOUs(String VINNumber){
        VINNumber = BPUtility.getDecodedString(VINNumber);
        List<Customer_Owned_Unit__c> custOwnedUnits = SOQLUtil.getSimilarCOUs(VINNumber);
        List<CustomerOwnedUnit> custOwnedUnitList = new List<CustomerOwnedUnit>();
        for(Customer_Owned_Unit__c custOwnedUnitRec : custOwnedUnits) {
            if(custOwnedUnitRec.VIN_Number__c != null && custOwnedUnitRec.VIN_Number__c != '') {
                custOwnedUnitList.add(new CustomerOwnedUnit(custOwnedUnitRec));
            }
        }
        return BPUtility.getEncodedString(System.JSON.serialize(custOwnedUnitList));
    }

    @RemoteAction 
    global static String getInvoiceHistory(String customerId, String invoicePageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        invoicePageSortAttrsJSON = BPUtility.getDecodedString(invoicePageSortAttrsJSON);
        //system.assert(false, invoicePageSortAttrsJSON);
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(Customer_Service.getInvoiceHistory(customerId, invoicePageSortAttrsJSON), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: saveCOU
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String saveCOU(String customerId, String couJSONString, String COUPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        couJSONString = BPUtility.getDecodedString(couJSONString);
        COUPageSortAttrsJSON = BPUtility.getDecodedString(COUPageSortAttrsJSON);
        List<CustomerOwnedUnit> couObjList = CustomerOwnedUnit.parse(couJSONString);
        if(couObjList.size() == 0) {
            return BPUtility.getEncodedString('{}');
        }
        
        Customer_Owned_Unit__c unitRec = setUnitFields(couObjList[0]);
        unitRec.Account__c = customerId;
        if(unitRec.Id == null) { 
            if(AccessControl.ifObjectFieldIsCreateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        } else {
            if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        }
        upsert unitRec;
        
        return getCOUListByCustomerId(BPUtility.getEncodedString(customerId), BPUtility.getEncodedString(COUPageSortAttrsJSON));
    }
    
    public static Customer_Owned_Unit__c setUnitFields(CustomerOwnedUnit unitObj) {
        Customer_Owned_Unit__c unitRec = new Customer_Owned_Unit__c();
        
        unitRec.Id = unitObj.Id;
        if(unitObj.Consignment != null) {
        	unitRec.Consignment__c = unitObj.Consignment;
        }
        unitRec.Suggested_Price__c = unitObj.SuggestedPrice;
        unitRec.Agreed_Payout__c = unitObj.AgreedPayout;
        unitRec.Product_Type__c = unitObj.ProductTypeId;
        
        unitRec.VIN_Number__c = unitObj.VIN;
        unitRec.Unit_Type__c = (unitObj.UnitType != null) ? unitObj.UnitType : 'COU';
        unitRec = setUnitStatusField(unitRec);
        unitRec.Year__c = unitObj.Year;
        unitRec.Unit_Make__c = String.isNotBlank(unitObj.Make) ? unitObj.Make : null;
        unitRec.Unit_Model__c = String.isNotBlank(unitObj.Model) ? unitObj.Model : null;
        unitRec.Sub_Model__c = String.isNotBlank(unitObj.SubModel) ? unitObj.SubModel : null;
        
        if(unitObj.IsTaxable == null) {
            unitObj.IsTaxable = false;
        }
        unitRec.Taxable__c = unitObj.IsTaxable;
        if(unitRec.Taxable__c) {
            unitRec.Applicable_Tax__c = unitObj.ApplicableTax;
        } else {
            unitRec.Applicable_Tax__c = null;
        }
        
        if(unitObj.IsAutomatic == null) {
            unitObj.IsAutomatic = false;
        }
        unitRec.Automatic__c = unitObj.IsAutomatic;
        
        if(unitObj.IsNewUnit == null) {
            unitObj.IsNewUnit = false;
        } 
        
        unitRec.New_Unit__c = unitObj.IsNewUnit;    
        if(unitObj.UnitType == 'STOCK') {
            unitRec.Stock_Id__c = unitObj.StockId;
            unitRec.Publish_in_feeds__c = unitObj.IsPublishInFeeds == null ? true : unitObj.IsPublishInFeeds;
        } else if(unitObj.UnitType == 'ORDU') {
            unitRec.Unit_Id__c = unitObj.UnitId;
        }
        
        unitRec.Category__c = unitObj.Category;
        unitRec.Date_Stocked_In__c = (unitRec.Id == null) ? system.today() : ((String.isNotBlank(unitObj.DateIn)) ? DateTimeUtility.parseDate(unitObj.DateIn) : null);
        if(unitObj.Consignment != null && unitObj.Consignment && unitRec.Date_Stocked_In__c == null) {
        	unitRec.Date_Stocked_In__c = system.today();
        }
        unitRec.Date_Stocked_Out__c = (String.isNotBlank(unitObj.DateOut)) ? DateTimeUtility.parseDate(unitObj.DateOut) : null;
        unitRec.Location__c = unitObj.Location;
        unitRec.Account__c = unitObj.CustomerId;
        unitRec.Factory_Order_No__c = unitObj.FactoryOrderNo;
    	if(String.isBlank(unitRec.Category__c)){
        	List<Category__c> unitCategory = [select Id from Category__c where Default__c = true AND Type__c = 'Unit'];
        	if(unitCategory.size() > 0){
        		unitRec.Category__c = unitCategory[0].Id;
        	}										
        }
        if(unitObj.AssignedTags != null && unitObj.AssignedTags.size() > 0) {
        	List<String> tagStrListForFields = TagUtil.convertTagListIntoTagString(unitObj.AssignedTags);
        	if(tagStrListForFields.size() == 2) {
        		unitRec.Assigned_Tag_1__c = tagStrListForFields[0];
        		unitRec.Assigned_Tag_2__c = tagStrListForFields[1];
        	}
        } else {
        	unitRec.Assigned_Tag_1__c = unitRec.Assigned_Tag_2__c = '';
        }
        if(unitObj.UnitOptionalFields != null) {
            unitRec = setUnitOptionalFields(unitRec, unitObj.UnitOptionalFields);
        }
        
        return unitRec;
    }
    
    public static Customer_Owned_Unit__c setUnitStatusField(Customer_Owned_Unit__c unitRec) {
        if(unitRec.Unit_Type__c == 'COU' && (unitRec.Status__c == null || unitRec.Status__c == '')){
            unitRec.Status__c = 'Active';
        } else if(unitRec.Unit_Type__c == 'STOCK' && (unitRec.Status__c == null || unitRec.Status__c == '')){
                unitRec.Status__c = 'Available';
        } else if(unitRec.Unit_Type__c == 'ORDU' && (unitRec.Status__c == null || unitRec.Status__c == '')){
            unitRec.Status__c = 'On Order';
       }
       return unitRec;
    }

    public static Customer_Owned_Unit__c setUnitOptionalFields(Customer_Owned_Unit__c unitRec, UnitProductTypeWrapper unitOptionalFieldsObj) {
    	if(unitOptionalFieldsObj.CategoryList != null) {
            for(UnitProductTypeWrapper.CategoryDataWrapper categoryObj : unitOptionalFieldsObj.CategoryList) {
                for(UnitProductTypeWrapper.UnitProductTypeFieldWrapper fieldValueObj : categoryObj.FieldValuesList) {
                    if(fieldValueObj.FieldValue != null) {
                        if(fieldValueObj.FieldType == 'Date') {
                            unitRec.put(fieldValueObj.COUAPIName, (String.isNotBlank(fieldValueObj.FieldValue)) ? DateTimeUtility.parseDate(fieldValueObj.FieldValue) : null);
                        } else if(fieldValueObj.FieldType == 'Number') {
                            unitRec.put(fieldValueObj.COUAPIName, Decimal.valueOf(fieldValueObj.FieldValue));
                        } else {
                            unitRec.put(fieldValueObj.COUAPIName, fieldValueObj.FieldValue);
                        }
                    }
                }
            }
        }
        
        return unitRec;
    }
    
    /**
     * Name: getCOUListByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getCOUListByCustomerId(String customerId, String COUPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        COUPageSortAttrsJSON = BPUtility.getDecodedString(COUPageSortAttrsJSON);
        PaginationSorting COUPageSortAttrs = parsePageAttrs(COUPageSortAttrsJSON);

        List<Customer_Owned_Unit__c> COUList = getActiveUnits(customerId);
        Integer TotalCOURecords = COUList.size();
        COUList = TaxExemption.getPaginatedRecords(COUList, COUPageSortAttrs.CurrentPage, COUPageSortAttrs.PageSize);
        
        List<CustomerOwnedUnit> couObjList = new List<CustomerOwnedUnit>();
        for(Customer_Owned_Unit__c couRec : COUList) {
            couObjList.add(new CustomerOwnedUnit(couRec));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new CustomerOwnedUnitJSONWrapper(TotalCOURecords, couObjList)));
    }
    
    public class CustomerOwnedUnitJSONWrapper {
        public Integer TotalCOURecords;
        public List<CustomerOwnedUnit> CustomerOwnedUnitList;
        
        public CustomerOwnedUnitJSONWrapper(Integer TotalCOURecords, List<CustomerOwnedUnit> CustomerOwnedUnitList){
            this.TotalCOURecords = TotalCOURecords;
            this.CustomerOwnedUnitList = CustomerOwnedUnitList;
        }
    }
    
    /**
     * Name: getActiveOrdersListByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getActiveOrdersListByCustomerId(String customerId, String ActiveOrdersPageSortAttrsJSON) {
        return getSalesOrderListByCustomerId(customerId, true, false, ActiveOrdersPageSortAttrsJSON);
    }
    
    @RemoteAction
    global static String getActiveQuotesListByCustomerId(String customerId, String ActiveOrdersPageSortAttrsJSON) {
        return getSalesOrderListByCustomerId(customerId, false, true, ActiveOrdersPageSortAttrsJSON);
    }

    @RemoteAction
    global static String getArchivedQuotesListByCustomerId(String customerId, String ActiveOrdersPageSortAttrsJSON) {
        return getSalesOrderListByCustomerId(customerId, false, false, ActiveOrdersPageSortAttrsJSON);
    }

    private static String getSalesOrderListByCustomerId(String customerId, Boolean activeOrdersOnly, Boolean activeQuotesOnly, String ActiveOrdersPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        ActiveOrdersPageSortAttrsJSON = BPUtility.getDecodedString(ActiveOrdersPageSortAttrsJSON);
        
        PaginationSorting ActiveOrdersPageSortAttrs = parsePageAttrs(ActiveOrdersPageSortAttrsJSON);
        
        String query = 'Select ' + String.join(COHeader.fieldsList(), ',') + ' from CO_Header__c WHERE Customer__c =: customerId AND Order_Status__c != \'Closed\'';
        if(activeOrdersOnly) {
            query += ' AND Order_Status__c != \'Quote\'';
        } else if(activeQuotesOnly) {
            query += ' AND Order_Status__c = \'Quote\' AND Is_Archived__c = false';
        } else {
            query += ' AND Order_Status__c = \'Quote\' AND Is_Archived__c = true';
        }
        query += ' ORDER BY Name ASC';
        List<CO_Header__c> ActiveSalesOrdersList = Database.query(query);
        Integer TotalActiveSalesOrderRecords = ActiveSalesOrdersList.size();
        ActiveSalesOrdersList = TaxExemption.getPaginatedRecords(ActiveSalesOrdersList, ActiveOrdersPageSortAttrs.CurrentPage, ActiveOrdersPageSortAttrs.PageSize);
        
        List<ActiveSalesOrder> orderList = new List<ActiveSalesOrder>();
        for(CO_Header__c coh : ActiveSalesOrdersList) {
            orderList.add(new ActiveSalesOrder(coh));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new ActiveOrderJSONWrapper(orderList, TotalActiveSalesOrderRecords)));
    }
    
    public class ActiveOrderJSONWrapper {
        public Integer TotalRecords;
        public List<ActiveSalesOrder> OrderList;
        
        public ActiveOrderJSONWrapper(List<ActiveSalesOrder> orderList, Integer totalRecords){
            this.OrderList = orderList;
            this.TotalRecords = totalRecords;
        }
    }
    
    /**
     * Name: getCOURecordById
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getCOURecordById(String couId) {
        couId = BPUtility.getDecodedString(couId);
        
        List<Customer_Owned_Unit__c> COUList = SOQLUtil.getCOURecordByFieldName('Id', couId);
        List<CustomerOwnedUnit> couObjList = new List<CustomerOwnedUnit>();
        for(Customer_Owned_Unit__c couRec : COUList) {
            CustomerOwnedUnit couObj = new CustomerOwnedUnit(couRec);
            couObj.UnitOptionalFields = UnitProductTypeService.getUnitOptionalFieldsData(couRec.Product_Type__c, couRec.Id);
            couObjList.add(couObj);
        }
        return BPUtility.getEncodedString(System.JSON.serialize(couObjList));
    }
    
    /**
     * Name: getRelatedCustomerByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getRelatedCustomerByCustomerId(String customerId, String customersPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        customersPageSortAttrsJSON = BPUtility.getDecodedString(customersPageSortAttrsJSON);
        
        PaginationSorting customersPageSortAttrs = parsePageAttrs(customersPageSortAttrsJSON);
        
        Map<String, String> accountIdToRelationMap = getRelatedCustomerRelationMap(customerId);
        List<Account> relatedCustomerRecList = SOQLUtil.getRelatedAccountRecs(accountIdToRelationMap.keyset());
        Integer TotalCustomerRecords = relatedCustomerRecList.size();
        relatedCustomerRecList = TaxExemption.getPaginatedRecords(relatedCustomerRecList, customersPageSortAttrs.CurrentPage, customersPageSortAttrs.PageSize);
        
        List<RelatedCustomer> relatedCustomerObjList = new List<RelatedCustomer>();
        
        for(Account relatedCustomerRec : relatedCustomerRecList) {
            relatedCustomerObjList.add(new RelatedCustomer(relatedCustomerRec, accountIdToRelationMap));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new RelatedCustomerJSONWrapper(TotalCustomerRecords, relatedCustomerObjList)));
    }
    
    public class RelatedCustomerJSONWrapper {
        public Integer TotalCustomerRecords;
        public List<RelatedCustomer> RelatedCustomerList;
        
        public RelatedCustomerJSONWrapper(Integer TotalCustomerRecords, List<RelatedCustomer> RelatedCustomerList){
            this.TotalCustomerRecords = TotalCustomerRecords;
            this.RelatedCustomerList = RelatedCustomerList;
        }
    }
    
    /**
     * Name: getRelatedCustomerByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    private static Map<String, String> getRelatedCustomerRelationMap(String customerId) {
        List<People__c> parentRelatedCustomerList = SOQLUtil.getRelatedCustomer(customerId, true);
        Map<String, String> accountIdToRelationMap = new Map<String, String>();
        for(People__c peopleRec : parentRelatedCustomerList) {
            accountIdToRelationMap.put(peopleRec.Parent_Customer2__c, peopleRec.Relationship__c);
        }
        
        List<People__c> childRelatedCustomerList = SOQLUtil.getRelatedCustomer(customerId, false);
        for(People__c peopleRec : childRelatedCustomerList) {
            if(peopleRec.Relationship__c == 'Employee') {
                peopleRec.Relationship__c = 'Employer';
                
            } else if(peopleRec.Relationship__c == 'Employer') {
                peopleRec.Relationship__c = 'Employee';
            } 
            accountIdToRelationMap.put(peopleRec.Parent_Customer1__c, peopleRec.Relationship__c);
        }
        return accountIdToRelationMap;
    }
    
    /**
     * Name: addRelatedCustomer
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String updateRelatedCustomer(String relatedCustomerString, String customersPageSortAttrsJSON) {
        relatedCustomerString = BPUtility.getDecodedString(relatedCustomerString);
        customersPageSortAttrsJSON = BPUtility.getDecodedString(customersPageSortAttrsJSON);
        
        List<RelatedCustomer> relatedCustomerObjList = RelatedCustomer.parse(relatedCustomerString);
        List<Account> relatedCustomerListToUpsert = new List<Account>();
        List<People__c> peopleRecToInsert = new List<People__c>();
        for(RelatedCustomer relatedCustomerObj : relatedCustomerObjList) {
            Account relatedCustomerRec = new Account();
            relatedCustomerRec.Id = relatedCustomerObj.Id;
            if(AccessControl.ifObjectFieldIsAccessible('People__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<People__c> peopleList = [select Id from People__c Where (Parent_Customer1__c = :relatedCustomerObj.ParentCustomer AND Parent_Customer2__c = :relatedCustomerObj.Id) OR 
                                                                        (Parent_Customer2__c = :relatedCustomerObj.ParentCustomer AND Parent_Customer1__c = :relatedCustomerObj.Id)]; 
            if(relatedCustomerObj.Relation != null && relatedCustomerObj.Relation != '') {
                People__c peopleRec = new People__c();
                if(peopleList.size() > 0) {
                    peopleRec.Id = peopleList[0].Id;
                }
                peopleRec.Parent_Customer1__c = relatedCustomerObj.ParentCustomer;
                peopleRec.Parent_Customer2__c = relatedCustomerObj.Id;
                peopleRec.Relationship__c = relatedCustomerObj.Relation;
                peopleRecToInsert.add(peopleRec);
            } else {
                if(peopleList.size() > 0) {
                    if(AccessControl.ifObjectIsDeletable('People__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                    delete peopleList[0];
                }
            }
            relatedCustomerListToUpsert.add(relatedCustomerRec);
        }
        if(relatedCustomerListToUpsert.size() > 0) {
            if(AccessControl.ifObjectFieldIsCreateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            upsert relatedCustomerListToUpsert;
        }
        if(peopleRecToInsert.size() > 0) {
            if(AccessControl.ifObjectFieldIsCreateable('People__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('People__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            upsert peopleRecToInsert;
        }
        String customerId = '';
        if(relatedCustomerObjList.size() > 0) {
            customerId = relatedCustomerObjList[0].ParentCustomer ;
        }
        return getRelatedCustomerByCustomerId(BPUtility.getEncodedString(customerId), BPUtility.getEncodedString(customersPageSortAttrsJSON));
    }
    
    /**
     * Name: getCustomerContactByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getCustomerContactByCustomerId(String customerId, String contactsPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        contactsPageSortAttrsJSON = BPUtility.getDecodedString(contactsPageSortAttrsJSON);
        
        PaginationSorting contactsPageSortAttrs = parsePageAttrs(contactsPageSortAttrsJSON);
        
        List<Contact> customerContactList = SOQLUtil.getCustomerContactByFieldName('AccountId', customerId);
        Integer TotalContactRecords = customerContactList.size();
        customerContactList = TaxExemption.getPaginatedRecords(customerContactList, contactsPageSortAttrs.CurrentPage, contactsPageSortAttrs.PageSize);
        
        List<CustomerContact> customerContactObjList = new List<CustomerContact>();
        for(Contact customerContactRec : customerContactList) {
            customerContactObjList.add(new CustomerContact(customerContactRec));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new CustomerContactJSONWrapper(TotalContactRecords, customerContactObjList)));
    }
    
    public class CustomerContactJSONWrapper {
        public Integer TotalContactRecords;
        public List<CustomerContact> ContactList;
        
        public CustomerContactJSONWrapper(Integer TotalContactRecords, List<CustomerContact> ContactList){
            this.TotalContactRecords = TotalContactRecords;
            this.ContactList = ContactList;
        }
    }
    
    /**
     * Name: getCustomerContactById
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getCustomerContactById(String customerContactId) {
        //system.assert(false, 'In get');
        customerContactId = BPUtility.getDecodedString(customerContactId);
        
        List<Contact> customerContactList = SOQLUtil.getCustomerContactByFieldName('Id', customerContactId);
        List<CustomerContact> customerContactObjList = new List<CustomerContact>();
        for(Contact customerContactRec : customerContactList) {
            customerContactObjList.add(new CustomerContact(customerContactRec));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(customerContactObjList));
    }
    
    
    /**
     * Name: updateCustomerContact
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String updateCustomerContact(String jsonString, String contactsPageSortAttrsJSON) {
        //system.assert(false, jsonString);
        //system.assert(false, 'In Update');
        jsonString = BPUtility.getDecodedString(jsonString);
        contactsPageSortAttrsJSON = BPUtility.getDecodedString(contactsPageSortAttrsJSON);
        
        List<CustomerContact> customerContactObjList = CustomerContact.parse(jsonString);
        
        List<Contact> customerContactListToInsert = new List<Contact>();
        for(CustomerContact customerContactObj : customerContactObjList) {
            Contact customerContactRec = new Contact();
            
            customerContactRec.FirstName = customerContactObj.FirstName;
            customerContactRec.LastName = customerContactObj.LastName;
            customerContactRec.Work_Email__c = customerContactObj.Email;
            customerContactRec.Phone = customerContactObj.Phone;
            customerContactRec.Preferred_Email__c = (customerContactObj.PreferredEmail == null) ? false : customerContactObj.PreferredEmail;
            customerContactRec.Preferred_Phone__c = (customerContactObj.PreferredPhone == null) ? false : customerContactObj.PreferredPhone;
            customerContactRec.Preferred_SMS__c = (customerContactObj.PreferredSMS == null)? false : customerContactObj.PreferredSMS;
            customerContactRec.Is_SMS__c = (customerContactObj.IsSMS == null) ? false : customerContactObj.IsSMS;
            customerContactRec.Job_Title__c = customerContactObj.JobTitle;
            customerContactRec.Relationship__c = customerContactObj.Relation;
            customerContactRec.AccountId = customerContactObj.ParentCustomer;
            if(customerContactObj.Id != null) {
                customerContactRec.Id = customerContactObj.Id;
            }
            customerContactListToInsert.add(customerContactRec);
        }
        //system.assert(false, customerContactListToInsert);
        if(customerContactListToInsert.size() > 0) {
            if(AccessControl.ifObjectFieldIsCreateable('Contact') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Contact') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            upsert customerContactListToInsert;
        }
        String customerId = '';
        if(customerContactListToInsert.size() > 0) {
            customerId = customerContactListToInsert[0].AccountId ;
        }
        return getCustomerContactByCustomerId(BPUtility.getEncodedString(customerId), BPUtility.getEncodedString(contactsPageSortAttrsJSON));
    }
    
    /**
     * Name: updateCustomerContactRelation
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String updateCustomerContactRelation(String jsonString, String contactsPageSortAttrsJSON) {
        //system.assert(false, jsonString);
        jsonString = BPUtility.getDecodedString(jsonString);
        contactsPageSortAttrsJSON = BPUtility.getDecodedString(contactsPageSortAttrsJSON);
        
        List<CustomerContact> customerContactObjList = CustomerContact.parse(jsonString);
        List<Contact> customerContactListToInsert = new List<Contact>();
        for(CustomerContact customerContactObj : customerContactObjList) {
            Contact customerContactRec = new Contact();
            customerContactRec.Relationship__c = customerContactObj.Relation;
            customerContactRec.AccountId = customerContactObj.ParentCustomer;
            if(customerContactObj.Id != null) {
                customerContactRec.Id = customerContactObj.Id;
            }
            customerContactListToInsert.add(customerContactRec);
        }
        //system.assert(false, customerContactListToInsert);
        if(customerContactListToInsert.size() > 0) {
            if(AccessControl.ifObjectFieldIsCreateable('Contact') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Contact') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            upsert customerContactListToInsert;
        }
        String customerId = '';
        if(customerContactListToInsert.size() > 0) {
            customerId = customerContactListToInsert[0].AccountId ;
        }
        return getCustomerContactByCustomerId(BPUtility.getEncodedString(customerId), BPUtility.getEncodedString(contactsPageSortAttrsJSON));
    }
    
    /**
     * Name: getCustomerContactByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    public static String getLastVisitOrderByCustomerId(String customerId) {
        List<CO_Header__c> coHeaderList = SOQLUtil.getLastVisitOrderByCustomerId(customerId);
        String lastTime = '';
        if(coHeaderList.size() > 0) {
            Long createdDateValue = coHeaderList[0].CreatedDate.getTime();
            Long currentDateValue = system.now().getTime();
            lastTime = String.valueOf(Integer.valueOf(((currentDateValue - createdDateValue)/ (1000 * 60 * 60 * 24)) / 30 )) + 'm ';
            lastTime += String.valueOf(Integer.valueOf( Math.mod(((currentDateValue - createdDateValue)/ (1000 * 60 * 60 * 24)), 30))) + 'd ';
            lastTime += String.valueOf(Integer.valueOf( Math.mod(((currentDateValue - createdDateValue)/ (1000 * 60 * 60)), 24))) + 'h';
        }
        return lastTime;
    }
    
    /**
     * Name: removeCustomerContactRecord
     * Desc: Remove Record with given Id
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String removeCustomerContactRecord(String customerId, String recordId, String contactsPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        recordId = BPUtility.getDecodedString(recordId);
        contactsPageSortAttrsJSON = BPUtility.getDecodedString(contactsPageSortAttrsJSON);
        List<Sobject> sobjectListToDel = SOQLUtil.getReocrdByGivenId(recordId);
        if(sobjectListToDel.size() > 0) {
            if(AccessControl.ifObjectIsDeletable(sobjectListToDel[0]) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete sobjectListToDel[0];
        }
        return getCustomerContactByCustomerId(BPUtility.getEncodedString(customerId), BPUtility.getEncodedString(contactsPageSortAttrsJSON));
    }
    
    /**
     * Name: removeCOURecord
     * Desc: Remove Record with given Id
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String removeCOURecord(String customerId, String recordId, String COUPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        recordId = BPUtility.getDecodedString(recordId);
        COUPageSortAttrsJSON = BPUtility.getDecodedString(COUPageSortAttrsJSON);
        
        List<Customer_Owned_Unit__c> couListToUpdate = [Select Id, Status__c From Customer_Owned_Unit__c Where Id =: recordId];
        if(couListToUpdate.size() > 0) {
            couListToUpdate[0].Status__c = 'Inactive';
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', couListToUpdate[0]);
        }
        return getCOUListByCustomerId(BPUtility.getEncodedString(customerId), BPUtility.getEncodedString(COUPageSortAttrsJSON));
    }
    
    /**
     * Name: getAllActiveSalesTax
     * Desc: get all active sales tax list used for tax exemption edit box
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Sales Tax. 
    **/
    @RemoteAction
    global static String getAllActiveSalesTax(String customerId) {
        customerId = BPUtility.getDecodedString(customerId);
        
        List<Sales_Tax_Item__c> salesTaxItemList = SOQLUtil.getAllSalesTaxItemWithExemptions(customerId, new Map<String, String>());
        List<TaxExemptions> taxExemptionsList = new List<TaxExemptions>();  
        Map<Id, List<String>> salesTaxItemIdToAppliesToList = getAppliesToList(salesTaxItemList);
        
        for(Sales_Tax_Item__c salesTaxItemRec : salesTaxItemList) {
            taxExemptionsList.add(new TaxExemptions(salesTaxItemRec, salesTaxItemIdToAppliesToList.get(salesTaxItemRec.Id)));
        }
        return BPUtility.getEncodedString(system.JSON.serialize(taxExemptionsList));
    } 
    
    public static Map<Id, List<String>> getAppliesToList(List<Sales_Tax_Item__c> salesTaxItemList) {
        Set<Id> salesTaxItemIdSet = new Set<Id>();
        for(Sales_Tax_Item__c salesTaxItemRec : salesTaxItemList) {
            salesTaxItemIdSet.add(salesTaxItemRec.Id);
        }
        
        if(salesTaxItemIdSet.size() == 0) {
            return new Map<Id, List<String>>();
        }
        if(AccessControl.ifObjectFieldIsAccessible('Applicable_Taxes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Map<Id, List<String>> salesTaxItemIdToAppliesToList = new Map<Id, List<String>>(); 
        List<Applicable_Taxes__c> appTaxList = [select Sales_Tax_Item__c, Sales_Tax__c, Sales_Tax__r.Name__c from Applicable_Taxes__c
                                                    where Sales_Tax_Item__c IN: salesTaxItemIdSet];
        
        for(Applicable_Taxes__c appTaxRec : appTaxList) {
            if(appTaxRec.Sales_Tax__c != null) {
                List<String> appliesToList;
                if(!salesTaxItemIdToAppliesToList.containsKey(appTaxRec.Sales_Tax_Item__c)) {
                    salesTaxItemIdToAppliesToList.put(appTaxRec.Sales_Tax_Item__c, new List<String>());
                }
                salesTaxItemIdToAppliesToList.get(appTaxRec.Sales_Tax_Item__c).add(appTaxRec.Sales_Tax__r.Name__c);
            }
        }
        return salesTaxItemIdToAppliesToList;
    } 
    
    /**
     * Name: saveTaxExeptionList
     * Desc: save tax exemption records
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Sales Tax. 
    **/
    @RemoteAction
    global static String saveTaxExeptionList(String customerId, String taxExemptionJSONString, String taxExemptionPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        taxExemptionJSONString = BPUtility.getDecodedString(taxExemptionJSONString);
        taxExemptionPageSortAttrsJSON = BPUtility.getDecodedString(taxExemptionPageSortAttrsJSON);
        
        List<Tax_Exemption__c> taxExemptionListToInsert = new List<Tax_Exemption__c>();
        List<Tax_Exemption__c> taxExemptionListToDelete = new List<Tax_Exemption__c>();
        
        if(AccessControl.ifObjectFieldIsCreateable('Tax_Exemption__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        
        PaginationSorting taxExemptionPageSortAttrs = parsePageAttrs(taxExemptionPageSortAttrsJSON);
        
        List<TaxExemptions> taxExemptionObjList = (List<TaxExemptions>) System.JSON.deserialize(taxExemptionJSONString, List<TaxExemptions>.class);
        for(TaxExemptions taxExemptionObj : taxExemptionObjList) {
            Tax_Exemption__c taxExemptionRec = new Tax_Exemption__c();
            if(taxExemptionObj.IsSelected && taxExemptionObj.TaxExemptionId == null) {
                taxExemptionRec.Customer__c = customerId;
                taxExemptionRec.Sales_Tax_Item__c = taxExemptionObj.SalesTaxItemId;
                taxExemptionListToInsert.add(taxExemptionRec);
            } else if(!taxExemptionObj.IsSelected && taxExemptionObj.TaxExemptionId != null){
                taxExemptionRec.Id = taxExemptionObj.TaxExemptionId;
                taxExemptionListToDelete.add(taxExemptionRec);
            }
        }
        if(taxExemptionListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Tax_Exemption__c', taxExemptionListToInsert);
        }
        
        if(taxExemptionListToDelete.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('Tax_Exemption__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete taxExemptionListToDelete;
        }
        
        // Get all JSON List
        List<Tax_Exemption__c> taxExemptionList = SOQLUtil.getTaxExemptionList(customerId, new Map<String, String>());
        Integer TotalTaxExemptionRecords = taxExemptionList.size(); 
        taxExemptionList = TaxExemption.getPaginatedRecords(taxExemptionList, taxExemptionPageSortAttrs.CurrentPage, taxExemptionPageSortAttrs.PageSize);
        taxExemptionObjList = new List<TaxExemptions>();
        Map<Id, List<String>> salesTaxItemIdToAppliesToList = CustomerDetail.getAppliesToList(taxExemptionList);
        for(Tax_Exemption__c taxExemptionRec : taxExemptionList) {
            taxExemptionObjList.add(new TaxExemptions(taxExemptionRec, salesTaxItemIdToAppliesToList.get(taxExemptionRec.Sales_Tax_Item__c)));
        }
        return BPUtility.getEncodedString(system.JSON.serialize(new TaxExemptionJSONWrapper(TotalTaxExemptionRecords, taxExemptionObjList)));
    }
    
    
    public class TaxExemptionJSONWrapper {
        public Integer TotalTaxExemptionRecords;
        public List<TaxExemptions> TaxExemptionList;
        
        public TaxExemptionJSONWrapper(Integer TotalTaxExemptionRecords, List<TaxExemptions> TaxExemptionList){
            this.TotalTaxExemptionRecords = TotalTaxExemptionRecords;
            this.TaxExemptionList = TaxExemptionList;
        }
    }
    
    
    /**
     * Name: saveTaxExeptionList
     * Desc: save tax exemption records
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Sales Tax. 
    **/
    @RemoteAction
    global static String saveCustomerStoreCredit(String customerId, String storeCreditJSONString, String storeCreditPageSortAttrsJSON) {
        if(AccessControl.ifObjectFieldIsCreateable('Store_Credit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); } //FLS Create Nikhil 31/01/2017 
        customerId = BPUtility.getDecodedString(customerId);
        storeCreditJSONString = BPUtility.getDecodedString(storeCreditJSONString);
        storeCreditPageSortAttrsJSON = BPUtility.getDecodedString(storeCreditPageSortAttrsJSON);
        
        List<Store_Credit__c> storeCreditListToInsert = new List<Store_Credit__c>();
        Store_Credit__c storeCreditRec;
        List<StoreCredit> storeCreditObjList = (List<StoreCredit>) System.JSON.deserialize(storeCreditJSONString, List<StoreCredit>.class);
        for(StoreCredit storeCreditObj : storeCreditObjList) {
            storeCreditRec = new Store_Credit__c();
            storeCreditRec.Amount__c = storeCreditObj.Amount;
            storeCreditRec.Reference__c = storeCreditObj.Reference;
            storeCreditRec.Customer__c = customerId;
            storeCreditListToInsert.add(storeCreditRec);
        }
        if(storeCreditListToInsert.size() > 0){
            upsert storeCreditListToInsert; 
        }
        return getCustomerStoreCreditbyCustomerId(BPUtility.getEncodedString(customerId), BPUtility.getEncodedString(storeCreditPageSortAttrsJSON));
    }
    
     /**
     * Name: saveTaxExeptionList
     * Desc: save tax exemption records
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Sales Tax. 
    **/
    @RemoteAction
    global static String getCustomerStoreCreditbyCustomerId(String customerId, String storeCreditPageSortAttrsJSON) {
        if(AccessControl.ifObjectFieldIsCreateable('Store_Credit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); } //FLS Create Nikhil 31/01/2017 
        customerId = BPUtility.getDecodedString(customerId);
        storeCreditPageSortAttrsJSON = BPUtility.getDecodedString(storeCreditPageSortAttrsJSON);
        PaginationSorting StoreCreditPageSortAttrs = parsePageAttrs(StoreCreditPageSortAttrsJSON); 
        
        List<Account> customerRec = [select Total_Store_Credit__c 
                                    from Account 
                                    where Id = :customerId];
        
        Decimal totalStoreCredit = 0;
        if(customerRec.size() > 0){
            totalStoreCredit = customerRec[0].Total_Store_Credit__c;
        }
        List<Store_Credit__c> customerStoreCreditList = SOQLUtil.getCustomerStoreCreditByFieldName('Customer__c', customerId);
        Integer TotalStoreCreditRecords = customerStoreCreditList.size();
        customerStoreCreditList = TaxExemption.getPaginatedRecords(customerStoreCreditList, StoreCreditPageSortAttrs.CurrentPage, StoreCreditPageSortAttrs.PageSize);
        List<StoreCredit> storeCreditObjList = new List<StoreCredit>();
        for(Store_Credit__c sc : customerStoreCreditList){
            storeCreditObjList.add(new StoreCredit(sc));
        }
        return BPUtility.getEncodedString(system.JSON.serialize(new StoreCreditJSONWrapper(totalStoreCredit, TotalStoreCreditRecords, storeCreditObjList)));
    }
    
    
    public class StoreCreditJSONWrapper {
        public Decimal TotalStoreCreditValue;
        public Integer TotalStoreCreditRecords;
        public List<StoreCredit> customerStoreCreditList;
        
        public StoreCreditJSONWrapper(Decimal TotalStoreCreditValue, Integer TotalStoreCreditRecords, List<StoreCredit> customerStoreCreditList){
            this.TotalStoreCreditValue = TotalStoreCreditValue;
            this.TotalStoreCreditRecords = TotalStoreCreditRecords;
            this.customerStoreCreditList = customerStoreCreditList;
        }
    }
    
    
    
    /**
     * Name: parsePageAttrs
     * Desc: Method to Parse JSON String to class instance for Pagination and sort attributes
     * @param:  (1) JSONString - String - JSON String 
     * @return: PaginationSorting - Class Object
    **/
    public static PaginationSorting parsePageAttrs(String json) {
        return (PaginationSorting) System.JSON.deserialize(json, PaginationSorting.class);
    }

    @RemoteAction 
    global static String sendSMSMessage(String JSONString) {return '';} 
    
    @RemoteAction 
    global static String sendMessage(String JSONString, String msgHistoryPageSortAttrsJSON) {
    	JSONString = BPUtility.getDecodedString(JSONString);
    	CustomerDetail.MessageHistory msgObj = (CustomerDetail.MessageHistory) System.JSON.deserialize(JSONString, CustomerDetail.MessageHistory.class);
    	Message_History__c msgRec = setMessageFields(msgObj);
        //Call send Message
        List<Account> customerList = [Select Id, BillingCountry from Account where Id =: msgObj.SentToId];
        if(customerList.size() > 0) {
        	if(String.isNotBlank(customerList[0].BillingCountry) && (String.isNotBlank(SendMessage.getAreacodeFromCountry(customerList[0].BillingCountry)))) {
        		String phoneNumber = msgRec.Phone__c;
                String response;
                if(customerList[0].BillingCountry == 'Australia') {
                    if(msgRec.Phone__c.length() == 10) {
                        phoneNumber = (SendMessage.getAreacodeFromCountry(customerList[0].BillingCountry)) + (phoneNumber).subString(1, phoneNumber.length());
                    } else {
                        throw new BlackpurlException('Cannot send message to this number'); 
                    }
                } else {
                    phoneNumber = (SendMessage.getAreacodeFromCountry(customerList[0].BillingCountry)) + phoneNumber;
                }

                if(KenectService.isKenectEnable()) {
                    response = KenectService.sendMessage(phoneNumber, msgRec);
                    if(response == UniversalAPIUtility.errorMessage)  return response;
                } else {
                    response = SendMessage.sendUsingPlivo(phoneNumber, msgRec.SMS_Body__c);
                }
                if(response == 'Success') {
                    msgRec.Message_UUID__c = UniversalAPIUtility.messageUUID;
                    DMLUtility.insertSobjectList('Message_History__c', msgRec);
                    if(msgHistoryPageSortAttrsJSON == null) {
                        return '';
                    } else if(msgObj.COHeaderNumber != null) {
                        return CustomerOrderCtrl_V2.getTextHistory(BPUtility.getEncodedString(msgObj.SentToId), BPUtility.getEncodedString(msgObj.COHeaderNumber));
                    }
                    return getMessageListByCustomerId(BPUtility.getEncodedString(msgObj.SentToId), msgHistoryPageSortAttrsJSON); 
                }
	    		throw new BlackpurlException(response);
			} else {
				throw new BlackpurlException('Area Code is not registered for this country.');
			}
        } else {
        	throw new BlackpurlException('Invalid Customer');
        }
        
    } 
    
    @RemoteAction
    global static String getAllSMSTemplates() {
        return BPUtility.getEncodedString(System.JSON.serialize(TextMessageTemplateService.getAllSMSTemplates(false), true));
    }
    
    @RemoteAction 
    global static String parseSMSTemplateVariables(String templateId, String customerId, String coHeaderId) {
        templateId = BPUtility.getDecodedString(templateId);
        customerId = BPUtility.getDecodedString(customerId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        String messageBody = SMSTemplateVariableParser.parse(templateId, customerId, coHeaderId);
        return BPUtility.getEncodedString((system.JSON.serialize(messageBody)));
    }
    
    @RemoteAction
    global static String getMessageListByCustomerId(String customerId, String msgHistoryPageSortAttrsJSON) {
    	customerId = BPUtility.getDecodedString(customerId);
    	msgHistoryPageSortAttrsJSON = BPUtility.getDecodedString(msgHistoryPageSortAttrsJSON);
    	PaginationSorting MessageHistoryPageSortAttrs = parsePageAttrs(msgHistoryPageSortAttrsJSON); 
        
        List<Message_History__c> smsRecList = SOQLUtil.getMessageList(new Map<String, String>{'Sent_To__c' => customerId});
        Integer TotalMessageRecords = smsRecList.size();
        smsRecList = TaxExemption.getPaginatedRecords(smsRecList, MessageHistoryPageSortAttrs.CurrentPage, MessageHistoryPageSortAttrs.PageSize);
        List<CustomerDetail.MessageHistory> msgList = new List<CustomerDetail.MessageHistory>();
        for(Message_History__c smsRec : smsRecList) { 
            msgList.add(new CustomerDetail.MessageHistory(smsRec));
        }
    	return BPUtility.getEncodedString(system.JSON.serialize(new SMSMessageJSONWrapper(TotalMessageRecords, msgList)));
    }
	
    public class SMSMessageJSONWrapper {
        public Integer TotalMessageRecords;
        public List<CustomerDetail.MessageHistory> MessageHistoryList;
        
        public SMSMessageJSONWrapper(Integer TotalMSGRecords, List<CustomerDetail.MessageHistory> msgList){
            this.TotalMessageRecords = TotalMSGRecords;
            this.MessageHistoryList = msgList;
        }
    }
    
    private static Message_History__c setMessageFields(CustomerDetail.MessageHistory msgObj) {
        Message_History__c msgRec = new Message_History__c();
        msgRec.Id = msgObj.Id;
        msgRec.Sent_To__c = msgObj.SentToId;
        msgRec.Phone__c = msgObj.SentTo;
        msgRec.Sent_By__c = UserInfo.getUserId();
        msgRec.Activity__c = msgObj.Activity;
        msgRec.SMS_Body__c = msgObj.Text;
        if(msgObj.Activity == Constants.MESSAGE_HISTORY_ACTIVITY_TEXT_MESSAGE) {
        	msgRec.CO_Header__c = msgObj.COHeaderNumber;
	        msgRec.SMS_Direction__c = Constants.SMS_DIRECTION_SENT;
	        msgRec.SMS_Sent_From__c = msgObj.COHeaderNumber != null ? Constants.SMS_SENT_FROM_CO : Constants.SMS_SENT_FROM_CUSTOMER;
        }
        return msgRec;
    }
    
    @RemoteAction
    global static String getARPaymentsByCustomerAccId(String customerId) {
    	return Customer_Service.getARPaymentsByCustomerAccId(BPUtility.getDecodedString(customerId), true);
    }
    
    @RemoteAction
    global static String getPaidCOAInvoiceList(String customerId, String paidCOAInvoicePageSortAttrsJSON) {
    	return Customer_Service.getPaidCOAInvoiceList(BPUtility.getDecodedString(customerId), BPUtility.getDecodedString(paidCOAInvoicePageSortAttrsJSON));
    }

    @RemoteAction
    global static String getPOAHistoryList(String customerId, String poaHistoryPageSortAttrsJSON) {
    	return Customer_Service.getPOAHistoryList(BPUtility.getDecodedString(customerId), BPUtility.getDecodedString(poaHistoryPageSortAttrsJSON));
    }

    @RemoteAction
    global static Decimal getCustomerOpenARBalance(String customerId) {
    	return AccountingUtil.getCustomerOpenARBalance(BPUtility.getDecodedString(customerId));
    }
    
    @RemoteAction
    global static String getActiveCashDrawerList() {
        try {
            List<CashDrawerWrapper> cashDrawerObjList = CashDrawerService.getActiveCashDrawerList();
            return BPUtility.getEncodedString(system.JSON.serialize(cashDrawerObjList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String validatePaymentDate(String paymentDate) {
    	try {
	    	paymentDate = BPUtility.getDecodedString(paymentDate);
	    	return BPUtility.getEncodedString(system.JSON.serialize(COApexValidation.validatePaymentDate(paymentDate)));
    	} catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
	
    @RemoteAction
    global static String savePaymentsOnAccount(String paymentOnAccountJson) {
    	paymentOnAccountJson = BPUtility.getDecodedString(paymentOnAccountJson);
    	try {
    		List<POAWrapper> paymentOnAccountObjList = (List<POAWrapper>)System.JSON.deserialize(paymentOnAccountJson, List<POAWrapper>.class);
    		return BPUtility.getEncodedString(addPaymentOnAccount(paymentOnAccountObjList));
    	} catch (Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }

    private static String addPaymentOnAccount(List<POAWrapper> paymentOnAccountObjList) {
        ResponseWrapper responseObj = processPOA(paymentOnAccountObjList);
        if(responseObj != null && responseObj.responseStatus.equalsIgnoreCase('Error')) {
            return System.JSON.serialize(responseObj);
        }
        Map<String, Payment_on_Account__c> paymentMethodToPOARecMap = setPOAFields(paymentOnAccountObjList);
        DMLUtility.insertSobjectList('Payment_on_Account__c', paymentMethodToPOARecMap.values());

        if(GeneralConfiguration.getConfigurations().Enable_Automatic_Payment_Surcharges__c) updateSurchargeDetails(paymentMethodToPOARecMap);
        List<AR_Payment__c> arPaymentList = setARPaymentList(paymentMethodToPOARecMap, paymentOnAccountObjList);
        DMLUtility.insertSobjectList('AR_Payment__c', arPaymentList);

        return System.JSON.serialize(new ResponseWrapper('Success', 'Success'));
    }

    private static void updateSurchargeDetails(Map<String, Payment_on_Account__c> paymentMethodToPOARecMap) {
        String surchargePaymentId;
        Payment_on_Account__c poaHavingSurchargeApplied;
        for(String paymentMethod: paymentMethodToPOARecMap.keySet()) {
            if(paymentMethod == 'Payment Surcharge') {
                surchargePaymentId = paymentMethodToPOARecMap.get(paymentMethod).Id;
            } else {
                poaHavingSurchargeApplied = paymentMethodToPOARecMap.get(paymentMethod);
            }
        }
        
        if(poaHavingSurchargeApplied != null && surchargePaymentId != null) {
            poaHavingSurchargeApplied.Surcharge_POA__c = surchargePaymentId;
            DMLUtility.updateSobjectList('Payment_on_Account__c', poaHavingSurchargeApplied);
        }
    }
    
    private static Map<String, Payment_on_Account__c> setPOAFields(List<POAWrapper> paymentOnAccountObjList) {
        Map<String, Payment_on_Account__c> paymentMethodToPOARecMap = new Map<String, Payment_on_Account__c>();
        for(POAWrapper paymentOnAccountObj: paymentOnAccountObjList) {
            Payment_on_Account__c poaRec = new Payment_on_Account__c();
            poaRec.Customer__c = paymentOnAccountObj.CustomerId;
            poaRec.Cash_Drawer__c = paymentOnAccountObj.CashDrawerId;
            poaRec.Payment_Method__c = paymentOnAccountObj.PaymentMethod;
            if(paymentOnAccountObj.PaymentDate != null) {
                DateTime dtValue = HomeSearchFilterInterface.getDateFromString(paymentOnAccountObj.PaymentDate);
                poaRec.Payment_Date__c = Date.newInstance(dtValue.year(), dtValue.month(), dtValue.day());
            } else {
                poaRec.Payment_Date__c = date.today();
            }
            poaRec.Reference__c = paymentOnAccountObj.ReferenceNumber;
            poaRec.Amount_Paid__c = paymentOnAccountObj.ARActivityListTotal;
            paymentMethodToPOARecMap.put(poaRec.Payment_Method__c, poaRec);
        }
		return paymentMethodToPOARecMap;
    }
    
    private static List<AR_Payment__c> setARPaymentList(Map<String, Payment_on_Account__c> paymentMethodToPOARecMap, List<POAWrapper> paymentOnAccountObjList) {
    	List<AR_Payment__c> arPaymentList = new List<AR_Payment__c>();
    	Set<String> invoiceNumberSet = new Set<String>();
        for(POAWrapper paymentOnAccountObj: paymentOnAccountObjList) {
            for(ARPaymentWrapper ARPaymentObj: paymentOnAccountObj.ARPaymentList) {
                invoiceNumberSet.add(ARPaymentObj.InvoiceNumber);
            }
        }
    	Map<String, CO_Invoice_Header__c> invHeaderRecMap = new Map<String, CO_Invoice_Header__c>([Select Id, Invoice_Number__c from CO_Invoice_Header__c where Invoice_Status__c = 'Closed' AND 
    																								Invoice_Number__c IN: invoiceNumberSet]);
    	Map<String, String> invoiceNumberToInvIdMap = new Map<String, String>();
    	for(CO_Invoice_Header__c invRec : invHeaderRecMap.values()) {
    		invoiceNumberToInvIdMap.put(invRec.Invoice_Number__c, invRec.Id);
    	}
    	List<String> invoiceAccountingIdList = new List<String>();
        Map<String, AR_Payment__c> invoiceAccountingIdToARPaymentMap = new Map<String, AR_Payment__c>();
        for(POAWrapper paymentOnAccountObj: paymentOnAccountObjList) {
            for(ARPaymentWrapper ARPaymentObj: paymentOnAccountObj.ARPaymentList) {
                AR_Payment__c arPaymentRec = new AR_Payment__c(Payment_on_Account__c = paymentMethodToPOARecMap.get(paymentOnAccountObj.PaymentMethod).Id);
                arPaymentRec.Invoice_Accounting_Id__c = ARPaymentObj.InvoiceAccountingId;
                invoiceAccountingIdList.add(ARPaymentObj.InvoiceAccountingId);
                arPaymentRec.CO_Invoice_Header__c = invoiceNumberToInvIdMap.get(ARPaymentObj.InvoiceNumber);
                arPaymentRec.Invoice_Date__c = String.isNotBlank(ARPaymentObj.InvoiceDate) ? DateTimeUtility.getDateFromFormattedDateStr(ARPaymentObj.InvoiceDate, 'YYYY-MM-DD') : null;
                arPaymentRec.Due_Date__c = String.isNotBlank(ARPaymentObj.DueDate) ? DateTimeUtility.getDateFromFormattedDateStr(ARPaymentObj.DueDate, 'YYYY-MM-DD') : null;
                
                arPaymentRec.Original_Amount__c = ARPaymentObj.OriginalAmount;
                arPaymentRec.Balance_Due__c = ARPaymentObj.BalanceDue;
                arPaymentRec.Amount_Paid__c = ARPaymentObj.AmountPaid;
                if(QBUtil.isQBEnabled()) {
                    if(ARPaymentObj.UnappliedPaymentType == 'AR Payment') {
                        arPaymentRec.Txn_Type__c = 'Payment';
                    } else {
                        arPaymentRec.Txn_Type__c = arPaymentRec.Amount_Paid__c > 0 ? 'Invoice' : 'CreditMemo';
                    }
                } else {
                    if(ARPaymentObj.UnappliedPaymentType == 'AR Credit') {
                        arPaymentRec.Txn_Type__c = arPaymentRec.Amount_Paid__c > 0 ? 'Invoice' : 'CreditNote';
                    } else {
                        arPaymentRec.Txn_Type__c = ARPaymentObj.UnappliedPaymentType;
                    }
                }
                invoiceAccountingIdToARPaymentMap.put(arPaymentRec.Invoice_Accounting_Id__c, arPaymentRec);
                arPaymentList.add(arPaymentRec);
                // update AR Balance on invoice
                if(String.isNotBlank(invoiceNumberToInvIdMap.get(ARPaymentObj.InvoiceNumber))) {
                    invHeaderRecMap.get(invoiceNumberToInvIdMap.get(ARPaymentObj.InvoiceNumber)).AR_Balance__c = arPaymentRec.Balance_Due__c - arPaymentRec.Amount_Paid__c;
                }
            }
        }
        DMLUtility.updateSobjectList('CO_Invoice_Header__c', invHeaderRecMap.values());
        List<AR_Payment__c> existingARPaymentList = [Select Id, Invoice_Accounting_Id__c, Balance_Due__c, Amount_Paid__c from AR_Payment__c where Invoice_Accounting_Id__c In: invoiceAccountingIdList AND Amount_Paid__c != 0];
        if(!existingARPaymentList.isEmpty()) {
            for(AR_Payment__c arPaymentExsistingRec: existingARPaymentList) {
                AR_Payment__c newARPaymentRec = invoiceAccountingIdToARPaymentMap.get(arPaymentExsistingRec.Invoice_Accounting_Id__c);
                if(newARPaymentRec.Balance_Due__c == arPaymentExsistingRec.Balance_Due__c ) {
                    throw new BlackPurlException('Payment already processed for selected transactions. Please refresh the page');
                }
            }
        }
		return arPaymentList;
    }
    
    /**
     * Name: getActiveOrdersListByCustomerId
     * Desc: To get Customer Inforamtion used in View Customer Page
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String getAllCustomerOrdersListByCustomerId(String customerId, String AllCustomerOrdersPageSortAttrsJSON) {
        customerId = BPUtility.getDecodedString(customerId);
        AllCustomerOrdersPageSortAttrsJSON = BPUtility.getDecodedString(AllCustomerOrdersPageSortAttrsJSON);
        
        PaginationSorting AllCustomerOrdersPageSortAttrs = parsePageAttrs(AllCustomerOrdersPageSortAttrsJSON);
        
        List<CO_Header__c> AllCustomerOrdersList = SOQLUtil.getAllCustomerOrdersForCustomer(customerId);
        Integer TotalCustomerOrderRecords = AllCustomerOrdersList.size();
        AllCustomerOrdersList = TaxExemption.getPaginatedRecords(AllCustomerOrdersList, AllCustomerOrdersPageSortAttrs.CurrentPage, AllCustomerOrdersPageSortAttrs.PageSize);
        
        List<ActiveSalesOrder> customerOrdersList = new List<ActiveSalesOrder>();
        for(CO_Header__c coh : AllCustomerOrdersList) {
            customerOrdersList.add(new ActiveSalesOrder(coh));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(new CustomerOrderJSONWrapper(TotalCustomerOrderRecords, customerOrdersList)));
    }
    
    @RemoteAction
    global static void saveNotesForCustomer(String customerId, String customerNotes) {
        customerId = BPUtility.getDecodedString(customerId);
        customerNotes = BPUtility.getDecodedString(customerNotes);
        if(AccessControl.ifObjectFieldIsUpdateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        Account customerRec = new Account(Id = customerId); 
        customerRec.Notes__c = customerNotes;
        DMLUtility.updateSobjectList('Account', customerRec);
    }
    
    @RemoteAction
    global static String getActivePaymentMethodList() {
        return CustomerOrderCtrl_V2.getActivePaymentMethodList();
    }

    @RemoteAction
    global static String getAllActivePaymentTerminals() {
        return BPUtility.getEncodedString(System.JSON.serialize(PreferredPaymentService.getAllActivePaymentTerminals()));
    }

    @RemoteAction
    global static String getBrandingLocationList() {
        return BPUtility.getEncodedString(system.JSON.serialize(BrandingLocationService.getBrandingLocationList(), true));
    }

    @RemoteAction
    global static String getServiceWorksheetPrintDetail(String coHeaderId) {
        return ServiceJobService.getServiceWorksheetPrintDetail(coHeaderId);
    }

    global static String authorizeTransaction(String paymentIntegrationJson) {return'';}

    private static ResponseWrapper processPOA(List<POAWrapper> paymentOnAccountObjList) {
        Set<String> preferredPaymentIdSet = new Set<String>();
        Map<String, Boolean> ppIdToSignatureValueMap = new Map<String, Boolean>();
        Set<String> arAccIdSet = new Set<String>();
        for(POAWrapper paymentOnAccountObj: paymentOnAccountObjList) {
            if(String.isBlank(paymentOnAccountObj.PaymentProcessorToken) && String.isNotBlank(paymentOnAccountObj.PreferredPaymentTerminalId)) {
                preferredPaymentIdSet.add(paymentOnAccountObj.PreferredPaymentTerminalId);
            }
            for(ARPaymentWrapper arPaymentObj: paymentOnAccountObj.ARPaymentList) {
                if(String.isNotBlank(arPaymentObj.InvoiceAccountingId)) arAccIdSet.add(arPaymentObj.InvoiceAccountingId);
            }
        }
        Boolean logsToBeSaved = false;
        if(!arAccIdSet.isEmpty()) {
            if(isARAccIdsRemoved(arAccIdSet, paymentOnAccountObjList[0].CustomerId)) {
                Customer_Service.saveIFWConfig();
                return new ResponseWrapper('Error', 'AR credit has been modified, please refresh your page.');
            } else {
                logsToBeSaved = true;
            }
        }
        if(!preferredPaymentIdSet.isEmpty()) {
            ppIdToSignatureValueMap = PreferredPaymentService.getPPIdToSignatureValueMap(preferredPaymentIdSet);
        }

        ResponseWrapper responseObj = new ResponseWrapper('Success', 'Success');
        if(GeneralConfiguration.isPreferredPaymentIntegrationEnabled()) {
            for(POAWrapper paymentOnAccountObj: paymentOnAccountObjList) {
                if(paymentOnAccountObj.PaymentMethod.equalsIgnoreCase(PreferredPaymentService.PREFERRED_PAYMENTS) && paymentOnAccountObj.ARActivityListTotal > 0) {
                    PreferredPaymentService.PaymentDetail paymentDetailObj = new PreferredPaymentService.PaymentDetail();
                    paymentDetailObj.TerminalId = String.isBlank(paymentOnAccountObj.PaymentProcessorToken) ?  paymentOnAccountObj.PreferredPaymentTerminalId : null;
                    paymentDetailObj.Token = paymentOnAccountObj.PaymentProcessorToken;
                    paymentDetailObj.Amount = paymentOnAccountObj.ARActivityListTotal;
                    paymentDetailObj.IsSignatureRequired = String.isBlank(paymentOnAccountObj.PaymentProcessorToken) ? ppIdToSignatureValueMap.get(paymentOnAccountObj.PreferredPaymentTerminalId) : false;
                    responseObj = PreferredPaymentService.saleTransaction(paymentDetailObj);
                    if(responseObj.responseStatus == 'Success') {
                        paymentOnAccountObj.ReferenceNumber = responseObj.response;
                    }
                }
            }
        } else {
            if(logsToBeSaved && BaseIntegration.webServiceLogs != null) DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        }
        if(logsToBeSaved) {
            Customer_Service.saveIFWConfig();
        }
        return responseObj;
    }

    private static Boolean isARAccIdsRemoved(Set<String> arAccIdSet, String customerId) {
        //Check AR Accounting Id in QB/XERO
        List<ARPaymentWrapper> ARPaymentObjList = Customer_Service.getARPaymentsByCustAccId(customerId, true, false);
        Set<String> availableARCreditIdSet = new Set<String>();
        for(ARPaymentWrapper arPaymentObj : ARPaymentObjList) {
            availableARCreditIdSet.add(arPaymentObj.InvoiceAccountingId);
        }
        for(String arCreditAccId : arAccIdSet) {
            if(!availableARCreditIdSet.contains(arCreditAccId)) {
                return true;
            }
        }
        return false;
    }
    
    public class CustomerOrderJSONWrapper {
        public Integer TotalCustomerOrderRecords;
        public List<ActiveSalesOrder> AllCustomerOrderList;
        
        public CustomerOrderJSONWrapper(Integer TotalCustomerOrderRecords, List<ActiveSalesOrder> AllCustomerOrderList){
            this.TotalCustomerOrderRecords = TotalCustomerOrderRecords;
            this.AllCustomerOrderList = AllCustomerOrderList;
        }
    }
    
    // Wrapper class for pagination and sorting combination
    public class PaginationSorting {
        
        // Current page number
        public Integer CurrentPage;
        
        // Current page size
        public Integer PageSize;
        
        // Sorting list
        public List<SortAttrs> Sorting;
    }
    
    // SortAttrs for sorting attributes
    public class SortAttrs {
        // Field name 
        public String FieldName;
        
        // Sort direction
        public String SortDirection;
    }
    
    public class CustomerRequestBody{
        public String customerId;
        public String COUPageSortAttrsJSON; 
        public String ActiveOrdersPageSortAttrsJSON; 
        public String ActiveQuotesPageSortAttrsJSON;
        public String ArchivedQuotesPageSortAttrsJSON;
        public String customersPageSortAttrsJSON;
        public String contactsPageSortAttrsJSON;
        public String AllCustomerOrdersPageSortAttrsJSON;
        public String StoreCreditPageSortAttrsJSON;
        public String SMSMessagePageSortAttrsJSON;
    }
}