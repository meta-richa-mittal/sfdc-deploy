/**
 * Author: Pooja Khandelwal
 * Since: Jun 18, 2018
 * Name: COSalesReceiptCtrl
 * Description: Ctrl Class to Fetch CO Sales Receipt details on PDF Page
**/
global without sharing class COSalesReceiptCtrl {
    public static String Application{get;set;}
    public static String Assests{get;set;}
    public static String Application_Images{get;set;}
    
    public COSalesReceiptCtrl() { 
        Application = GlobalController.GetResourceURL('Application');
        Application_Images = GlobalController.GetResourceURL('Application_Images');
        Assests = GlobalController.GetResourceURL('Assests');
    }
    
    /**
     * Name: getCOInvoiceDetailsWithFinalize
     * Desc: to get CO Sales Receipt details
     * @param:  (1) coInvoiceIdStr (2) isFinalized
     * @return: String - JSON String
    **/
    @RemoteAction
    global static String getCOInvoiceDetailsWithFinalize(String coInvoiceIdStr, Boolean isFinalized) {
    	coInvoiceIdStr = BPUtility.getDecodedString(coInvoiceIdStr);
    	return BPUtility.getEncodedString(getCOInvoiceDetails(coInvoiceIdStr, isFinalized, null));
    }
    
    @RemoteAction
    global static String getCOInvoiceDetailsWithBrandingLocation(String coInvoiceIdStr, Boolean isFinalized, String brandingLocationId) {
    	coInvoiceIdStr = BPUtility.getDecodedString(coInvoiceIdStr);
    	brandingLocationId = BPUtility.getDecodedString(brandingLocationId);
    	return BPUtility.getEncodedString(getCOInvoiceDetails(coInvoiceIdStr, isFinalized, brandingLocationId));
    }
    
    private static String getCOInvoiceDetails(String coInvoiceIdStr, Boolean isFinalized, String brandingLocationId) {
    	String coInvoiceDetails;
    	Id coInvoiceId = coInvoiceIdStr;
    	List<CO_Invoice_Header__c> coInvoices = PrintCustomerOrderInvoiceCtrl.getCustomerOrderInvoiceHeaders(new List<Id>{coInvoiceId});
    	if(coInvoices.size() > 0) {
    		CO_Invoice_Header__c coInvRec = coInvoices[0];
            
            BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
    		
    		List<Id> coliIds = new List<Id>();
    		List<Id> cokhIds = new List<Id>();
    		List<Id> sohTaxableItemIds = new List<Id>();
    		List<Id> sohIds = new List<Id>();
    		List<Id> dealIds = new List<Id>();
            for(CO_Invoice_Item__c coInvoiceItem : coInvoices[0].CO_Invoice_Items__r) {
            	if(coInvoiceItem.CO_Line_Item__c != null) {
	                coliIds.add(coInvoiceItem.CO_Line_Item__c);
	            }
	            if(coInvoiceItem.CO_Kit_Header__c != null) {
	                cokhIds.add(coInvoiceItem.CO_Kit_Header__c);
	            }
	            if(coInvoiceItem.Service_Order_Header__c != null) {
	                if(coInvoiceItem.SO_Payment_Role__c == null || coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible') {
	                    sohTaxableItemIds.add(coInvoiceItem.Service_Order_Header__c);
	                }
	                sohIds.add(coInvoiceItem.Service_Order_Header__c);
	            }
	            if(coInvoiceItem.Deal__c != null) {
	                dealIds.add(coInvoiceItem.Deal__c);
	            }
            }
            
    		Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            List<Individual_Tax__c> individualItemsList = COService.getConditionalIndividualTaxList(isTaxIncludingPricing, true, coliIds, cokhIds, 
                                                            new Set<Id>(sohTaxableItemIds), dealIds);
             
			Map<String, Decimal> salesTaxNameToTaxValue = new Map<String, Decimal>();                                                          
			salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList);    
             
             Id coId = coInvoices[0].CO_Header__c;
             List<CO_Header__c> coHeadersList = PrintCustomerOrderInvoiceCtrl.getCustomerOrderHeaders(new List<Id>{coId}, coliIds);
             List<CO_Kit_Header__c> coKitHeadersList = PrintCustomerOrderInvoiceCtrl.getKitHeaders(new List<Id>{coId}, cokhIds);
             List<COHeaderWrapper.COKitHeader> COKHList = COHeaderWrapper.getCOLineItemsList(coHeadersList[0].CO_Line_Items__r, coKitHeadersList);
             List<Deal_Item__c> dealItemList = PrintCustomerOrderInvoiceCtrl.getDealHeaders(new List<Id>{coId}, dealIds);
             
             Set<Id> dealItemIds = new Set<Id>();
             for(Deal_Item__c dealItemRec : dealItemList) { 
                dealItemIds.add(dealItemRec.Id);
             }
            
             Map<Id, List<Deal_Kit_Header__c>> dealItemIdToDKHListMap = new Map<Id, List<Deal_Kit_Header__c>>();
             List<Deal_Kit_Header__c> dealKitHeaderList = SOQLUtil.getDealKitHeaderDetailsByDealItemId(new Set<Id>(dealItemIds));
             for(Deal_Kit_Header__c dealKitHeaderRec : dealKitHeaderList) {
             	if(dealItemIdToDKHListMap.containsKey(dealKitHeaderRec.Deal_Item__c)) {
                	List<Deal_Kit_Header__c> dealKitHeaders = dealItemIdToDKHListMap.get(dealKitHeaderRec.Deal_Item__c);
                    dealKitHeaders.add(dealKitHeaderRec);
                    dealItemIdToDKHListMap.put(dealKitHeaderRec.Deal_Item__c, dealKitHeaders);
                } else {
                    dealItemIdToDKHListMap.put(dealKitHeaderRec.Deal_Item__c, new List<Deal_Kit_Header__c>{dealKitHeaderRec});
                }
         	}
            
			List<Service_Order_Header__c> soHeadersList = PrintCustomerOrderInvoiceCtrl.getServiceOrderHeaders(new List<Id>{coId}, sohIds);
            Map<String, String> dealObjFieldNameToFieldValueMap = new Map<String, String>();
            List<F_I_Product__c> dealFAndIProductList = new List<F_I_Product__c>();
            if(dealIds.size() > 0) {
            	dealFAndIProductList = SOQLUtil.getDealFAndIProductRecord(new Map<String, String>{'Deal__c' => dealIds[0]});
            }
    		COSalesReceiptDetail coSalesReceiptDetailObj = new COSalesReceiptDetail(brandingLocationObj, coInvRec, salesTaxNameToTaxValue, COKHList, coHeadersList[0].CO_Line_Items__r, coKitHeadersList, dealItemList, dealItemIdToDKHListMap, soHeadersList, dealFAndIProductList);
    		coInvoiceDetails = System.JSON.serialize(coSalesReceiptDetailObj);
    	}
                
    	return coInvoiceDetails;
    }
}
