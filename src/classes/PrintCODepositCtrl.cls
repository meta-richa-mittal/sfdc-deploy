/**
* Author: Richa Mittal
* Since: January 12, 2017
* Name: PrintCODepositCtrl
* Description: methods to handle operations related to print CO deposit.
**/
global without sharing class PrintCODepositCtrl {
    
    public String companyLogoURL { get{return GeneralConfiguration.getCompanyLogoUrl();} private set;}
    public PrintCODepositWrapper printCODepositRecord{get; private set;}
    public static String Application{get;set;}
    public static String Assests{get;set;}
    public static String Application_Images{get;set;}
    public String CoHeaderId {get; private set;}
    public String brandingLocationId {get; private set;}
    public Boolean isHidePartNumbersOnDocuments{get{return GeneralConfiguration.isHidePartNumbersOnDocuments();} private set;}
    public Boolean isHideKitDetailsOnDocuments{get{return GeneralConfiguration.isHideKitDetailsOnDocuments();} private set;}
    
    public PrintCODepositCtrl() {
    	Application = GlobalController.GetResourceURL('Application');
    	Application_Images = GlobalController.GetResourceURL('Application_Images');
    	Assests = GlobalController.GetResourceURL('Assests');
        CoHeaderId = ApexPages.currentPage().getParameters().get('id');
        brandingLocationId = ApexPages.currentPage().getParameters().get('brandingLocationId');
    	if(CoHeaderId  == '' || CoHeaderId == 'undefined' || CoHeaderId == null){
            return;
        }else{
        CoHeaderId = BPUtility.getEncodedString(CoHeaderId);
	        String coDepositDetailJson;
	        if(String.isNotBlank(brandingLocationId)) {
	        	brandingLocationId= BPUtility.getEncodedString(brandingLocationId);
	        	coDepositDetailJson = getPrintCODepositDataWithBrandingLocation(CoHeaderId, brandingLocationId);
	        } else {
	        	coDepositDetailJson = getPrintCODepositData(CoHeaderId);
	        }
        coDepositDetailJson = BPUtility.getDecodedString(coDepositDetailJson);
        printCODepositRecord = (PrintCODepositWrapper)JSON.deserialize(coDepositDetailJson, PrintCODepositWrapper.class);
        //system.assert(false,printCODepositRecord);
        
    }
    	
    }
    
    @RemoteAction
    global static String getPrintCODepositData(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        return BPUtility.getEncodedString(getPrintCODepositDetails(coHeaderId, null));
    }
    
    @RemoteAction
    global static String getPrintCODepositDataWithBrandingLocation(String coHeaderId, String brandingLocationId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        brandingLocationId = BPUtility.getDecodedString(brandingLocationId);
        return BPUtility.getEncodedString(getPrintCODepositDetails(coHeaderId, brandingLocationId));
    }
    
    private static String getPrintCODepositDetails(String coHeaderId, String brandingLocationId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Header__c> coHeaderList = [select Name, Customer__c, CreatedDate, Owner__r.Name, Deal_Total__c, Customer_PO_Number__c, (select Id from CO_Invoice_Headers__r) from CO_Header__c where Id=: coHeaderId];
        if(coHeaderList.size() == 0) {
            return '{}';
        }
        
        List<CO_Invoice_Header__c> coInvoiceHeaderIdSet = new   List<CO_Invoice_Header__c>();
        for(CO_Header__c coHeaderRec: coHeaderList) {
        	for(CO_Invoice_Header__c coInvoiceHeaderRec: coHeaderRec.CO_Invoice_Headers__r) {
        		coInvoiceHeaderIdSet.add(coInvoiceHeaderRec);
        	}
        }
        
        List<CO_Invoice_Payment__c> coInvoicePaymentsList = [select Id, Payment_Method__c, Amount__c, Deposit_Payment_Method__c, Reverse_Link__c from CO_Invoice_Payment__c where CO_Invoice_Header__c IN:coInvoiceHeaderIdSet];
        //system.assert(false, coInvoicePaymentsList);
        
        List<CO_Invoice_Payment__c> activeCOInvoicePaymentsList = [select Id, Amount__c, CO_Invoice_Header__r.Invoice_Number__c, Payment_Method__c, CreatedDate, Payment_Date__c, Deposit_Payment_Method__c, Reverse_Link__c, Reference__c from CO_Invoice_Payment__c where CO_Invoice_Header__c IN:coInvoiceHeaderIdSet and CO_Invoice_Header__r.Status__c = 'Active' ORDER BY Payment_Date__c DESC];
        //system.assert(false, activeCOInvoicePaymentsList);
        
        List<Account> customerList = new List<Account>();
        List<Service_Order_Header__c> soHeaderList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'CO_Header__c' => coHeaderId,
        																										'Deal__c' => null});
        List<CO_Line_Item__c> coLineItemsListFOrMerch = getCustomerOrderLineItems(coHeaderId);
        List<CO_Line_Item__c> coLineItemsListFOrMerchExcludingDealMerch = new List<CO_Line_Item__c>();
        for(CO_Line_Item__c coliRec: coLineItemsListFOrMerch) {
        	if(String.isBlank(coliRec.Deal__c)) {
        		coLineItemsListFOrMerchExcludingDealMerch.add(coliRec);
        	}
        }
        
        BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
        
        if(coHeaderList[0].Customer__c != null) { // Issue: Customer Info is not displaying on printCODeposit page: soHeaderList.size() > 0 && : Removed By Pooja 1 May 2017
            customerList = SOQLUtil.getCustomerDetailsByFieldName(new Map<String, String>{'Id' => coHeaderList[0].Customer__c});
        } 
        
        List<CO_Deposit__c> coDepositList = SOQLUtil.getCODepositByCOHeaderId(coHeaderId);
        
        List<Deal__c> dealList = [SELECT Id FROM Deal__c WHERE CO_Header__c =: coHeaderId];
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        List<Deal_Finance__c> dealFinanceList = new List<Deal_Finance__c>();
        if(dealList.size() > 0) {
        	dealItemList = PrintCustomerOrderInvoiceCtrl.getDealHeaders(new List<Id>{coHeaderId}, new List<Id>{dealList[0].Id});
        	dealFinanceList = SOQLUtil.getDealFinanceRecord(new Map<String, String>{'Deal__c' => dealList[0].Id});
        }
        //system.assert(false, dealFinanceList);
        List<CO_Kit_Header__c> coKitHeadersList = getCOKitHeadersByCOHeaderId(coHeaderId); //SOQLUtil.getCOKHByCOHeaderId(coHeaderId);
        List<CO_Kit_Header__c> coKitHeadersListExcludingDealMerch = new List<CO_Kit_Header__c>();
        for(CO_Kit_Header__c cokhRec: coKitHeadersList) {
        	if(String.isBlank(cokhRec.Deal__c)) {
        		coKitHeadersListExcludingDealMerch.add(cokhRec);
        	}
        }
        //System.assert(false, coKitHeadersList);
        List<COHeaderWrapper.COKitHeader> COKHList = COHeaderWrapper.getCOLineItemsList(coLineItemsListFOrMerchExcludingDealMerch, coKitHeadersListExcludingDealMerch);
        //system.assert(false, COKHList);
        
        List<Individual_Tax__c> individualItemsList = TaxCalculation.getConditionalIndividualTaxList(coLineItemsListFOrMerchExcludingDealMerch, 
        coKitHeadersListExcludingDealMerch, soHeaderList, dealList);
	    
	    Map<String, Decimal> salesTaxNameToTaxValue = new Map<String, Decimal>();  
	    salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList);	
        
        PrintCODepositWrapper printCODepositWrapper = new PrintCODepositWrapper(coHeaderId, coLineItemsListFOrMerchExcludingDealMerch, soHeaderList, 
        																coDepositList, brandingLocationObj, customerList, coHeaderList[0], 
        																coInvoicePaymentsList, activeCOInvoicePaymentsList, COKHList, dealItemList, dealFinanceList,
        																salesTaxNameToTaxValue); 
        
        		
	    //system.assert(false, printCODepositWrapper.dealInfo);
        return JSON.serialize(printCODepositWrapper);
    }
    
    private static List<CO_Line_Item__c> getCustomerOrderLineItems(Id coHeaderId) {
        String query;   
        query = 'SELECT '; 
        for(String fieldsName : COLineItem.fieldsList()){
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        
        // Child Query
        query += '(SELECT Tax_Rate__c, Sales_Tax_Item__r.Name__c FROM Individual_Taxes__r)';
        
        query += ' FROM ' + Constants.NAMESPACE + 'CO_Line_Item__c ';
        if(coHeaderId != null) {
            query += 'WHERE CO_Header__c = :coHeaderId AND Service_Order_Line_Item__c = null ORDER BY CreatedDate';
        }
        if(AccessControl.ifObjectFieldIsAccessible('Individual_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Line_Item__c> coLineItems = Database.query(query);
        return coLineItems;
    }
    
    /**
     * Name: getCOKHByCOHeaderId
     * Desc: To get Customer Order Kit Header by Header Id
     * @param: (1) coHeaderId - Id - Customer Order Header Id 
     * @return: List<Sobject> - Customer Order Kit Header records
    **/ 
    public static List<Sobject> getCOKitHeadersByCOHeaderId(Id coHeaderId) { 
        String query;    
        query = 'SELECT ';  
        for(String fieldsName : COHeaderWrapper.getCOKHFieldsList()) {
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';  
        }
         
        // Child Query
        query += '(SELECT ';
        for(String fieldsName : COLineItem.fieldsList()){
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'CO_Line_Items__r )';
        
        query += ' FROM ' + Constants.NAMESPACE + 'CO_Kit_Header__c ';
        if(coHeaderId != null) {
            query += 'WHERE CO_Header__c = :coHeaderId ORDER BY CreatedDate';
        }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Kit_Header__c> coKitHeaders = Database.query(query);
        return coKitHeaders;
    }
}