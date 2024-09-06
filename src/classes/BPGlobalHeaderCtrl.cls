/**
 * Author: Hitesh Gupta
 * Since: Aug. 31, 2015
 * Name: BPGlobalHeaderCtrl
 * Description: Apex class which contains all remoted methods of global header.
**/ 
global without sharing class BPGlobalHeaderCtrl {
    
	public boolean Load_New_UI {get{return GeneralConfiguration.isLoadNewUI();} private set;}
	
	public Boolean IsTrialOrg { get{return GeneralConfiguration.isTrialOrg();} private set;}
	
	public boolean Load_Customer_Order_V2 {get{return GeneralConfiguration.isLoadNewCustomerOrder();} private set;}
 	public static Set<String> customerTypeSellingGroupSet = new Set<String> {'Part Sale', 'Service Order', 'Unit Deal'}; 
    public static Set<String> serviceSellingGroupSet = new Set<String> {'Service Order', 'Internal Service'};
    public static Set<String> dealSellingGroupSet = new Set<String> {'Unit Deal'};
    
    /**
     * Name: getCurrentUserImageURL
     * Desc: Method used to get user image url for current user
     * @param:  
     * @return: String - string url for user image
    **/  
    public String getCurrentUserImageURL(){
        return UsersUtility.getUserImageURL(UserInfo.getUserId());
    }
    
    /**
     * Name: createCustomerOrder
     * Desc: Method which creates a customer order header record
     * @param:  
     * @return: String - inserted customer order header record Id
    **/
    @RemoteAction
    global static String createCustomerOrder(){
    	if(AccessControl.ifObjectFieldIsCreateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        CO_Header__c coHeaderToInsert = new CO_Header__c();
        coHeaderToInsert.Order_status__c = 'Open';
        coHeaderToInsert.CO_Type__c = 'Cash Sale';
        coHeaderToInsert.Selling_Group__c = 'Cash Sale';
    	coHeaderToInsert.Owner__c = UserInfo.getUserId();
    	coHeaderToInsert.Transaction_Type__c = SOQLUtil.getDefaultPartSaleTransactionTypeId();

        DMLUtility.insertSobjectList('CO_Header__c', coHeaderToInsert);
        return BPUtility.getEncodedString(String.valueOf(coHeaderToInsert.Id));
    }
    
    global static String createNewCO(String customerId, String sellingGroup, Boolean isPreventMerchSectionCreation) {
    	customerId = BPUtility.getDecodedString(customerId);
		sellingGroup = BPUtility.getDecodedString(sellingGroup);
		
		CO_Header__c coHeaderToInsert  = createCORec(customerId, sellingGroup);
		String coHeaderId = createSection(new List<CO_Header__c> {coHeaderToInsert}, sellingGroup, isPreventMerchSectionCreation);
		return coHeaderId;
	}
	
	@RemoteAction
	global static String createNewCustomerOrder(String customerId, String sellingGroup) {
		customerId = BPUtility.getDecodedString(customerId);
		sellingGroup = BPUtility.getDecodedString(sellingGroup);
		
		CO_Header__c coHeaderToInsert  = createCORec(customerId, sellingGroup);
		String coHeaderId = createSection(new List<CO_Header__c> {coHeaderToInsert}, sellingGroup, false);
		return coHeaderId;
	}
	
	private static CO_Header__c createCORec(String customerId, String sellingGroup){
		CO_Header__c coHeaderToInsert = new CO_Header__c();
		coHeaderToInsert.Order_status__c = 'Open';
		coHeaderToInsert.Owner__c = UserInfo.getUserId();
		coHeaderToInsert.Selling_Group__c = sellingGroup;
		if(customerTypeSellingGroupSet.contains(sellingGroup)) {
			coHeaderToInsert.CO_Type__c = 'Customer';
		} else {
			coHeaderToInsert.CO_Type__c = sellingGroup;
		}
		coHeaderToInsert.Transaction_Type__c = SOQLUtil.getDefaultPartSaleTransactionTypeId();

        DMLUtility.insertSobjectList('CO_Header__c', coHeaderToInsert);
		
		if(String.isNotBlank(customerId)) {
			updateCustomerOrderInfo(coHeaderToInsert.Id, customerId);
		}
		
		return coHeaderToInsert;
	}
	
	private static String createSection(List<CO_Header__c> coHeaderToInsert, String sellingGroup, Boolean isPreventMerchSectionCreation){
		if(coHeaderToInsert == null || coHeaderToInsert.size() == 0) {
			return null;
		}
		if(sellingGroup == 'Part Sale' && !isPreventMerchSectionCreation) {
			List<SObject> sObjectListToInsert = CustomerOrderCtrl.addLinkedFee(coHeaderToInsert[0].Id, null, 'Merchandise');
			if(sObjectListToInsert != null) {
                if(!AccessControl.ifObjectFieldIsCreateable('CO_Line_Item__c')){throw new BlackPurlException('CO_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                if(!AccessControl.ifObjectFieldIsCreateable('Service_Order_Line_Item__c')){throw new BlackPurlException('Service_Order_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                if(!AccessControl.ifObjectFieldIsCreateable('Option_Fee__c')){throw new BlackPurlException('Option_Fee__c' + DMLUtility.NOT_CREATABLE);}
				insert sObjectListToInsert;
			}
		}
		if(serviceSellingGroupSet.contains(sellingGroup)) {
			CustomerOrderCtrl.createSOHeader(BPUtility.getEncodedString(coHeaderToInsert[0].Id));
		}
		if(dealSellingGroupSet.contains(sellingGroup)) {
			CustomerOrderCtrl.createDealHeader(coHeaderToInsert[0].Id);
		}
		return BPUtility.getEncodedString(String.valueOf(coHeaderToInsert[0].Id));
	}

    /**@RemoteAction
	global static String createNewCustomerOrder(String customerId, String sellingGroup) {
		customerId = BPUtility.getDecodedString(customerId);
		sellingGroup = BPUtility.getDecodedString(sellingGroup);
		
		CO_Header__c coHeaderToInsert = new CO_Header__c();
        coHeaderToInsert.Order_status__c = 'Open';
    	coHeaderToInsert.Owner__c = UserInfo.getUserId();
		coHeaderToInsert.Selling_Group__c = sellingGroup;
		if(customerTypeSellingGroupSet.contains(sellingGroup)) {
			coHeaderToInsert.CO_Type__c = 'Customer';
		} else {
			coHeaderToInsert.CO_Type__c = sellingGroup;
		}
		
		if(AccessControl.ifObjectFieldIsCreateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        insert coHeaderToInsert;
		
		if(String.isNotBlank(customerId)) {
    		//CustomerOrderCtrl.addCustomer(BPUtility.getEncodedString(coHeaderToInsert.Id), BPUtility.getEncodedString(customerId));
			updateCustomerOrderInfo(coHeaderToInsert.Id, customerId);
		}
		if(sellingGroup == 'Part Sale') {
			List<SObject> sObjectListToInsert = CustomerOrderCtrl.addLinkedFee(coHeaderToInsert.Id, null, 'Merchandise');
	        if(sObjectListToInsert != null) {
                if(!AccessControl.ifObjectFieldIsCreateable('CO_Line_Item__c')){throw new BlackPurlException('CO_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                if(!AccessControl.ifObjectFieldIsCreateable('Service_Order_Line_Item__c')){throw new BlackPurlException('Service_Order_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                if(!AccessControl.ifObjectFieldIsCreateable('Option_Fee__c')){throw new BlackPurlException('Option_Fee__c' + DMLUtility.NOT_CREATABLE);}
	        	insert sObjectListToInsert;
	        }
		}
		if(serviceSellingGroupSet.contains(sellingGroup)) {
			CustomerOrderCtrl.createSOHeader(BPUtility.getEncodedString(coHeaderToInsert.Id));
		}
		if(dealSellingGroupSet.contains(sellingGroup)) {
			createDeal(BPUtility.getEncodedString(coHeaderToInsert.Id));
		}
		return BPUtility.getEncodedString(String.valueOf(coHeaderToInsert.Id));
	}*/
    
    private static void updateCustomerOrderInfo(String coHeaderId, String customerId) {
        List<CO_Header__c> coHeaderListToUpdate = new List<CO_Header__c>{new CO_Header__c(Id = coHeaderId, Customer__c = customerId, CO_Type__c = 'Customer')};
    	DMLUtility.updateSobjectList('CO_Header__c', coHeaderListToUpdate);
    }

    /**
     * Name: createNewVendorOrder
     * Desc: Method which creates a Vendor order header record
     * @param:  
     * @return: String - inserted Vendor order header record Id
    **/
    @RemoteAction
	global static String createNewVendorOrder(String vendorId) {
		vendorId = BPUtility.getDecodedString(vendorId);
		
		Vendor_Order_Header__c voHeaderToInsert = new Vendor_Order_Header__c();
        voHeaderToInsert.Owner__c = UserInfo.getUserId();
        voHeaderToInsert.Vendor__c = vendorId;
        voHeaderToInsert.Status__c = 'Open';
        
        if(AccessControl.ifObjectFieldIsAccessible('PO_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<PO_Type__c> vendorStandardPOTypes = [Select Id from PO_Type__c where IsDefault__c = true AND Vendor__c =: vendorId];
		if(vendorStandardPOTypes.size() > 0){
            voHeaderToInsert.Purchase_Order_Type__c = vendorStandardPOTypes[0].Id;
        }
        
        DMLUtility.insertSobjectList('Vendor_Order_Header__c', voHeaderToInsert);
		
		return BPUtility.getEncodedString(String.valueOf(voHeaderToInsert.Id));
	}
	/**
     * Name: createNewVendorReceiving
     * Desc: Method which creates a Vendor Receiving header record
     * @param:  
     * @return: String - inserted Vendor Receiving header record Id
    **/
	@RemoteAction
	global static String createNewVendorReceiving(String vendorId){
		return VendorOrderReceivingCtrl.addVendor(vendorId, null);
	}
	//#1762 kajal 28th march 2017
	
	@RemoteAction
	global static String createNewVendorInvoicing(String vendorId){
        return VendorInvoicingCtrl.addVendor(vendorId, null, null, null);
	}
	
	
	@RemoteAction
	global static String createNewReturnVO(String vendorId){
        return ReturnVOCtrl.addVendor(vendorId, null);
	}
	
    /**
     * Name: createVendorOrder
     * Desc: Method which creates a Vendor order header record
     * @param:  
     * @return: String - inserted Vendor order header record Id
    **/
    @RemoteAction
    global static String createVendorOrder(){
        
        Vendor_Order_Header__c voHeaderToInsert = new Vendor_Order_Header__c();
        voHeaderToInsert.Owner__c = UserInfo.getUserId();
        voHeaderToInsert.Status__c = 'Open';
        
        DMLUtility.insertSobjectList('Vendor_Order_Header__c', voHeaderToInsert);
        return BPUtility.getEncodedString(String.valueOf(voHeaderToInsert.Id));
        // return null;
    }
    
    
    /**
     * Name: createVendorOrder
     * Desc: Method which creates a Vendor order header record
     * @param:  
     * @return: String - inserted Vendor order header record Id
    **/
    @RemoteAction
    global static String createVOReceiving(){
        
        Vendor_Receiving_Header__c voHeaderReceivingToInsert = new Vendor_Receiving_Header__c();
        voHeaderReceivingToInsert.Owner__c = UserInfo.getUserId();
        voHeaderReceivingToInsert.Status__c = 'In Progress';
        
        DMLUtility.insertSobjectList('Vendor_Receiving_Header__c', voHeaderReceivingToInsert);
        return BPUtility.getEncodedString(String.valueOf(voHeaderReceivingToInsert.Id));
        
        //return null;
    }
    
    /**
     * Name: createVOInvoicing
     * Desc: Method which creates a Vendor order header record
     * @param:  
     * @return: String - inserted Vendor order header record Id
    **/
    @RemoteAction
    global static String createVOInvoicing(){
        Vendor_Invoicing_Header__c viHeaderToInsert = new Vendor_Invoicing_Header__c();
        viHeaderToInsert.Owner__c = UserInfo.getUserId();
        viHeaderToInsert.Status__c = 'In Progress';
        
        DMLUtility.insertSobjectList('Vendor_Invoicing_Header__c', viHeaderToInsert);
        return BPUtility.getEncodedString(String.valueOf(viHeaderToInsert.Id));
    }
    
    //START: added by kv 01/20/2017
    /**
     * Name: getActiveCustomerOrdersById
     * Desc: Method which returns active orders of customer by its id
     * @param: String - customerId
     * @return: String - active orders of customer
    **/
    @RemoteAction
    global static String getActiveCustomerOrdersById(String filterJson) {
        filterJson = BPUtility.getDecodedString(filterJson);
        GlobalSearchResultsWrapper.COOpenOrderFilterJSON filterObj = (GlobalSearchResultsWrapper.COOpenOrderFilterJSON) System.JSON.deserialize(filterJson, 
                                                                        GlobalSearchResultsWrapper.COOpenOrderFilterJSON.class);
        
        String query = 'SELECT Name, Customer_Name__c, Deal_Header_Total__c, NumberOfDeals__c, Service_Order_Subtotal__c, ' + 
            			'TotalNumberOfSOHeader__c, Merchandise_Total__c, TotalNumberOfCOLI__c, Selling_Group__c, ' + 
            			'LastModifiedDate, Order_status__c FROM CO_Header__c WHERE Customer__c = \'' + BPUtility.escapeSingleQuotes(filterObj.CustomerId) + 
            			'\' AND Order_Status__c != \'Closed\' ORDER BY Name Desc ' + 
            			SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);
        List<CO_Header__c> coHeaderList = Database.query(query);
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return BPUtility.getEncodedString(System.JSON.serialize(new GlobalSearchResultsWrapper(coHeaderList.size(), coHeaderList)));
    }
    //END: added by kv 01/20/2017
    
    //START: Added By Pooja 3 Aug 2017
    /**
     * Name: addServiceJobForJobScheduling
     * Desc: Method which populates CoHeader to Event record
     * @param: String - eventJson
    **/
    @RemoteAction
    global static void addServiceJobForJobScheduling(String eventJson) {
    	JobSchedulingCtrl.addServiceJobForJobScheduling(eventJson);
    }
    
    @RemoteAction
    global static Boolean checkForHondaIntegrationEnabled(String vendorId) {
        Boolean hondaEnabledForGivenVendor = false;
        vendorId = BPUtility.getDecodedString(vendorId);
        try {
            if(HondaUtility.isHondaIntegrationEnabled() && String.isNotBlank(HondaUtility.getHondaVendorCode())) {
                List<Account> vendorList = [SELECT Vendor_Code__c FROM Account WHERE Id =: vendorId AND Vendor_Code__c =: HondaUtility.getHondaVendorCode()];
                hondaEnabledForGivenVendor = (vendorList.size() > 0);
            }
            return hondaEnabledForGivenVendor;
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return hondaEnabledForGivenVendor;
    }
    
    @RemoteAction
    global static String getHondaInvoiceList() {
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(HondaVendorInvoiceService.getInvoices(), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return null;
    }
    
    @RemoteAction
    global static String getHondaInvoiceData(String invoiceNumber) {
        invoiceNumber = BPUtility.getDecodedString(invoiceNumber);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(HondaVendorInvoiceService.getInvoiceData(invoiceNumber), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return null;
    }
    
    @RemoteAction
    public static Integer getUnreadTextMessageCount() {
        return IncomingMessageService.getUnreadMessageCount();
    }

    @RemoteAction
    global static String getRefreshMinutes() { 
        try {
            return BPUtility.getEncodedString(String.valueOf(General_Configurations__c.getOrgDefaults().Dashboard_Refresh_Minutes__c));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: getAccountingPeriodClosedDate 
     * Desc: Method which give Accounting Period closing Date in string format from Accounting Application.
     * @param: 
     * @return: String formatted date;
    **/
	@RemoteAction
    global static string getAccountingPeriodClosedDate(){
        return BPUtility.getEncodedString(System.JSON.serialize(AccountingUtil.getAccountingPeriodClosedDate()));
    }

    @RemoteAction
    global static String getActiveIntegrationList() {
        if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Integration_Name__c FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true];
        
        Set<String> activeIntegrationSet = new Set<String>();
        for(IFW_IntegrationConfig__c configRec : configList) {
            activeIntegrationSet.add(configRec.Integration_Name__c);
        }
        return BPUtility.getEncodedString(system.JSON.serialize(activeIntegrationSet));
    }
    
    @RemoteAction
    global static String getBRPVendorsList() {
        return BPUtility.getEncodedString(system.JSON.serialize(BRPUtility.getAllBRPVendorsIdSet()));
    }
}