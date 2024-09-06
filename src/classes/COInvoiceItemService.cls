public without sharing class COInvoiceItemService {
    
    public static final String INVOICE_ALREADY_CLOSED = 'The requested item is updated by some other process, please refresh the page.';
    public static CustomerOrderWrapper.CheckoutWrapper getCOCheckoutInfo(String coHeaderId) {
    	CustomerOrderWrapper.CheckoutWrapper checkoutObj;
        List<CO_Invoice_Header__c> coInvoiceHeaders = SOQLUtil.getCOInvoiceHeaderByCOHeaderId(coHeaderId);
        if(coInvoiceHeaders.size() > 0) {
        	List<CO_Invoice_Item__c> coInvoiceItems = SOQLUtil.getCOInvoiceItemsByCOInvoiceHeaderId(coInvoiceHeaders[0].Id);
        	List<CO_Invoice_Payment__c> coInvoicePayments = SOQLUtil.getCOInvoicePaymentsByCOInvoiceHeaderId(coInvoiceHeaders[0].Id);
        	List<PrintCustomerOrderInvoiceCtrl.TaxDetail> taxDetail = getCheckoutSalesTax(coInvoiceHeaders[0].Id);
        	CO_Invoice_Header__c coInvoiceHeaderRec = calculateInvoiceTotals(coInvoiceHeaders[0].Id);
        	List<CO_Deposit__c> coDeposits = SOQLUtil.getCODepositByCOHeaderId(coHeaderId);
        	
	        checkoutObj = new CustomerOrderWrapper.CheckoutWrapper(coInvoiceItems, coInvoicePayments, coInvoiceHeaders[0].Id, taxDetail, coInvoiceHeaderRec, coDeposits);
        }
        return checkoutObj;
    }
    
    private static CO_Invoice_Header__c calculateInvoiceTotals(String coInvoiceId) {
    	if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Individual_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        CO_Invoice_Header__c coInvoice = [SELECT Name, Total_Payment__c, CO_Header__r.Customer__r.Total_Store_Credit__c, Invoice_Status__c, CO_Header__r.Order_Status__c,
                                            (SELECT CO_Line_Item__c, isActive__c, Service_Order_Header__c, CO_Kit_Header__c, Deal__c, SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName 
											FROM CO_Invoice_Items__r WHERE isActive__c = true AND 
											((CO_Line_Item__c != null AND CO_Line_Item__r.Deal__c = null) OR
											(Service_Order_Header__c != null AND Service_Order_Header__r.Transaction_Type__r.Type__c = 'Customer' AND
													Service_Order_Header__r.Work_Status__c = 'Complete') OR
											(CO_Kit_Header__c != null AND CO_Kit_Header__r.Deal__c = null) OR
											(Deal__c != null)))
                                            FROM CO_Invoice_Header__c WHERE Id =: coInvoiceId];
                                            
        return COService.calculateInvoiceTotals(new List<CO_Invoice_Header__c>{coInvoice});    
    }
    
    public static List<PrintCustomerOrderInvoiceCtrl.TaxDetail> getCheckoutSalesTax(String coInvoiceId) {
       List<CO_Invoice_Header__c> coInvoices = [select Id,
                                                (SELECT isActive__c, CO_Line_Item__c, CO_Kit_Header__c, Service_Order_Header__c, Deal__c,
                                                Service_Order_Header__r.Transaction_Type__r.Type__c,
                                                Deal__r.Type__c FROM CO_Invoice_Items__r WHERE isActive__c = true AND 
        													((CO_Line_Item__c != null AND CO_Line_Item__r.Deal__c = null) OR
        													(Service_Order_Header__c != null AND Service_Order_Header__r.Transaction_Type__r.Type__c = 'Customer' AND
        															Service_Order_Header__r.Work_Status__c = 'Complete') OR
        													(CO_Kit_Header__c != null AND CO_Kit_Header__r.Deal__c = null) OR
        													(Deal__c != null)))
                                                FROM CO_Invoice_Header__c 
                                                WHERE Id = :coInvoiceId];
        List<PrintCustomerOrderInvoiceCtrl.TaxDetail> taxDetails = new  List<PrintCustomerOrderInvoiceCtrl.TaxDetail>();
        
        if(coInvoices.size() > 0) {
            Map<String, Decimal> salesTaxNameToTaxValue = new Map<String, Decimal>();  
            List<Id> coliIds = new List<Id>();
            Set<Id> sohIds = new Set<Id>();
            List<Id> cokhIds = new List<Id>();
            List<Id> dealIds = new List<Id>();
            String PermissionStr = NewHomePageCtrl.getUserPermissions(UserInfo.getUserId());// Added By Pooja for Checkout Payment section related changes: 14 Sep 2017
            UserGroupWrapper PermissionObj = (UserGroupWrapper) System.JSON.deserialize(PermissionStr, UserGroupWrapper.class); // Added By Pooja for Checkout Payment section related changes: 14 Sep 2017
            if(coInvoices[0].CO_Invoice_Items__r != null) {
                for(CO_Invoice_Item__c coInvoiceItem : coInvoices[0].CO_Invoice_Items__r){
                    if(coInvoiceItem.isActive__c){
                        // Start: Commented And Changed By Pooja for Checkout Payment section related changes: 14 Sep 2017
                        /**if(coInvoiceItem.CO_Line_Item__c != null) {
                            coliIds.add(coInvoiceItem.CO_Line_Item__c);
                        }
                        if(coInvoiceItem.Service_Order_Header__c != null) {
                            sohIds.add(coInvoiceItem.Service_Order_Header__c);
                        }
                        if(coInvoiceItem.CO_Kit_Header__c != null) {
                            cokhIds.add(coInvoiceItem.CO_Kit_Header__c);
                        }
                        if(coInvoiceItem.Deal__c != null) {
                            dealIds.add(coInvoiceItem.Deal__c);
                        }*/
                        
                        if(coInvoiceItem.CO_Line_Item__c != null) {
                            // Source Section: Merchandise, Checkout type: Customer && Merchandise>create/modify true
                            // Source Section: Deal Merchandise, Checkout type: Deal && Merchandise>create/modify true
                            if(PermissionObj.GroupOnlyPermissions.get('Merchandise').get('create/modify')) {
                                coliIds.add(coInvoiceItem.CO_Line_Item__c);
                            } 
                        }
                        if(coInvoiceItem.Service_Order_Header__c != null) {
                            // Source Section: Service job (type=internal), Checkout type: Internal && Internal Service>create/modify true
                            if((coInvoiceItem.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Internal' || coInvoiceItem.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Stock Unit')
                                && PermissionObj.GroupOnlyPermissions.get('Internal Service').get('create/modify')) {
                                sohIds.add(coInvoiceItem.Service_Order_Header__c);
                            }else {
                                // Source Section: Service job, Checkout type: Customer && Service job>create/modify true
                                // Source Section: Deal Service, Checkout type: Deal && Service job>create/modify true
                                if(PermissionObj.GroupOnlyPermissions.get('Service job').get('create/modify'))    {
                                    sohIds.add(coInvoiceItem.Service_Order_Header__c);
                                }
                            }
                        }
                        if(coInvoiceItem.CO_Kit_Header__c != null) {
                            // Source Section: Merchandise, Checkout type: Customer && Merchandise>create/modify true
                            // Source Section: Deal Merchandise, Checkout type: Deal && Merchandise>create/modify true
                            if(PermissionObj.GroupOnlyPermissions.get('Merchandise').get('create/modify')) {
                                cokhIds.add(coInvoiceItem.CO_Kit_Header__c);
                            }   
                        }
                        if(coInvoiceItem.Deal__c != null) {
                            // Source Section: Deal, Checkout type: Customer && Deal>create/modify true
                            if(PermissionObj.GroupOnlyPermissions.get('Deal').get('create/modify')) {
                                dealIds.add(coInvoiceItem.Deal__c);
                            } /**else if(coInvoiceItemRec.Deal__r.Type__c == Constants.FINANCED) {
                                this.CheckoutType = Constants.CHECKOUT_TYPE_THIRD_PARTY;
                            }*/
                        }
                    }
                }
            }
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            TaxCalculation.isInvoiced = false;
            List<Individual_Tax__c> individualItemsList = COService.getConditionalIndividualTaxList(isTaxIncludingPricing, TaxCalculation.isInvoiced, coliIds, cokhIds, 
                                                                    sohIds, dealIds);
                                                                    
            /*List<Individual_Tax__c> individualItemsList = [select CO_Line_Item__c, Tax_Rate__c, Form_Label__c, Tax_Amount_To_Invoice__c ,
                                                            Taxable_Amount__c, Tax_Amount__c, Taxable_Amount_To_Invoice__c,
                                                            Applicable_Tax__c, List_Tax_items_on_forms__c
                                                            from Individual_Tax__c where CO_Line_Item__c IN : coliIds
                                                                OR Service_Order_Line_Item__r.Service_Order_Header__c IN :sohIds
                                                                OR CO_Line_Item__r.CO_Kit_Header__c IN :cokhIds
                                                                OR Option_Fee__r.Deal__c IN: dealIds
                                                                OR Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c IN: dealIds
                                                                OR F_I_Product__r.Deal_Finance__r.Deal__c IN: dealIds
                                                                OR (Deal_Item__r.Deal__c IN: dealIds AND Deal_Item__r.Type__c = 'Trade In')];*/
            
            salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList);     
            TaxCalculation.isInvoiced = true;
            for(String taxName : salesTaxNameToTaxValue.keySet()){
                taxDetails.add(new PrintCustomerOrderInvoiceCtrl.TaxDetail(taxName, salesTaxNameToTaxValue.get(taxName)));
            }           
        }
        return taxDetails;
    } 
    
    private static String CHECKOUT_TYPE_VALUE = 'Third-Party';
    public static void finalizeCOInvoice(String recordIdsJson, String coHeaderId) {
        recordIdsJson = BPUtility.getDecodedString(recordIdsJson);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try {
            List<String> recIdList = (List<String>) System.JSON.deserialize(recordIdsJson, List<String>.class);
            List<COInvoiceItem> coInvoiceItemObjList = updateInvoiceItems(recIdList, coHeaderId, false, null);
            for(COInvoiceItem invItem : coInvoiceItemObjList) {
                if(invItem.IsActive) {
                    CHECKOUT_TYPE_VALUE = invItem.CheckoutType;
                    break;
                }
            }
            
            List<CO_Invoice_Item__c> coInvoiceItemList = [Select isActive__c, CO_Invoice_Header__r.CO_Header__r.Total_Deposit__c from CO_Invoice_Item__c where CO_Invoice_Header__c =: coInvoiceItemObjList[0].COInvoiceHeaderId 
                                                        AND isActive__c = false];
                                                        
            Decimal totalDepositOnCO = 0;
            Decimal totalPaymentOnActiveNonCustomerInvoice = 0;
            if(!coInvoiceItemList.isEmpty()) {
                totalDepositOnCO = coInvoiceItemList[0].CO_Invoice_Header__r.CO_Header__r.Total_Deposit__c;
            } else {
                List<CO_Header__c> coHeaderList = [Select Id, Total_Deposit__c, (Select Id, Total_Payment__c from CO_Invoice_Headers__r Where Invoice_Status__c = 'Active' limit 1) from CO_Header__c where Id =: coHeaderId];
                totalDepositOnCO = coHeaderList[0].Total_Deposit__c;
                if(coHeaderList[0].CO_Invoice_Headers__r.size() > 0 && CHECKOUT_TYPE_VALUE != 'Customer') {
                    totalPaymentOnActiveNonCustomerInvoice = coHeaderList[0].CO_Invoice_Headers__r[0].Total_Payment__c;
                }
            }
            
            List<Deal__c> dealList = [SELECT Status__c, (SELECT Id FROM CO_Invoice_Items__r) from Deal__c where CO_Header__c =: coHeaderId AND Status__c != 'Invoiced'];
            if(coInvoiceItemList.size() == 0 && totalDepositOnCO == 0 && 
            			(dealList.size() == 0 || (dealList.size() > 0 && dealList[0].CO_Invoice_Items__r.size() > 0)) && (CHECKOUT_TYPE_VALUE == 'Customer' || totalPaymentOnActiveNonCustomerInvoice == 0)) {
                COService.finalizeOrder(BPUtility.getEncodedString(System.JSON.serialize(coInvoiceItemObjList)), 
                            BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(CHECKOUT_TYPE_VALUE));
            } else {
                COService.finalizeInvoice(BPUtility.getEncodedString(System.JSON.serialize(coInvoiceItemObjList)), 
                            BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString(CHECKOUT_TYPE_VALUE));
            }
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));           
       }  
    }
             
    public static String finalizeInvoice(String recordIdsJson, String coHeaderId){
        try {
        	finalizeCOInvoice(recordIdsJson, coHeaderId);
            return COService.getCOHeaderDetailsByGridName(BPUtility.getDecodedString(coHeaderId), null);
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));           
        }  
        return '';
    }
    
    /**
    * Name: updateInvoiceItems
    * Desc: Method to update invoice items- (Is active = true for selected items only)
    * @param:   (1) recIdList - List<String> - Selected items id
    *           (2) coHeaderId - String - co header id
    *			(3) isCustomerCheckout - Boolean - (True - when checking out from modal window (with customer checkout type), false - when finalizing from pop up)
    * @return:List of CO Invoice Item Record
    **/
    public static List<COInvoiceItem> updateInvoiceItems_Old(List<String> recIdList, String coHeaderId, Boolean isCustomerCheckout, 
    				Boolean isShowDiscount) {
    	List<COInvoiceItem> coInvoiceItemObjList = new List<COInvoiceItem>(); 
	    
	    Map<String, String> objectNameRecordIdMap = new Map<String, String>();
    	objectNameRecordIdMap.put('CO_Invoice_Header__r.CO_Header__c', coHeaderId);
    	objectNameRecordIdMap.put('CO_Invoice_Header__r.Invoice_Status__c', 'Active'); 
        
        List<CO_Invoice_Item__c> coInvoiceItemList = SOQLUtil.getCoInvoiceItemByFieldName(objectNameRecordIdMap);
        for(CO_Invoice_Item__c invItemRec : coInvoiceItemList) {
        	
        	for(String recId : recIdList) {
	    		String objectName = (Id.valueOf(recId)).getSObjectType().getDescribe().getName();
	    		
	    		if(!isCustomerCheckout && objectName == 'Service_Order_Header__c' && invItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party') {
	    			CHECKOUT_TYPE_VALUE = 'Third-Party';
	    		}
	        	if(recId == ((sObject)invItemRec).get(objectName) && (invItemRec.Service_Order_Header__c == null || invItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c != 'Third-Party' || 
	        		(isCustomerCheckout && invItemRec.SO_Payment_Role__c != null && invItemRec.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible') ||
	        		(!isCustomerCheckout && invItemRec.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible' && invItemRec.SO_Payment_Role__r.RecordType.DeveloperName != 'Customer'))) {
				   	invItemRec.isActive__c = true;
				   	
				   	break;
				} else{
					invItemRec.isActive__c = false;
				}
	    	}
	    	COInvoiceItem invItemObj = new COInvoiceItem(invItemRec);
	    	if(isShowDiscount != null) {
	    		invItemObj.IsDisplayDiscountAmount = isShowDiscount;
	    	}
	    	coInvoiceItemObjList.add(invItemObj);
        }
	    update coInvoiceItemList;
	    return coInvoiceItemObjList;
    }
    
    public static List<COInvoiceItem> updateInvoiceItems(List<String> recIdList, String coHeaderId, Boolean isCustomerCheckout, 
    				Boolean isShowDiscount) {
        Set<String> recIdSet = new Set<String>(recIdList);
    	List<COInvoiceItem> coInvoiceItemObjList = new List<COInvoiceItem>(); 
	    
	    Map<String, String> objectNameRecordIdMap = new Map<String, String>();
    	objectNameRecordIdMap.put('CO_Invoice_Header__r.CO_Header__c', coHeaderId);
    	objectNameRecordIdMap.put('CO_Invoice_Header__r.Invoice_Status__c', 'Active'); 
        
        Boolean isAtLeastOneActiveItemPresent = false;
        List<CO_Invoice_Item__c> coInvoiceItemList = SOQLUtil.getCoInvoiceItemByFieldName(objectNameRecordIdMap);
        Boolean isInvItemContiansRec = false;
        for(CO_Invoice_Item__c invItemRec : coInvoiceItemList) {
            isInvItemContiansRec = false;
        	if(recIdSet.contains((ID)((sObject)invItemRec).get('CO_Line_Item__c')) || recIdSet.contains((ID)((sObject)invItemRec).get('CO_Kit_Header__c')) || recIdSet.contains((ID)((sObject)invItemRec).get('Deal__c'))) {
                isInvItemContiansRec = true;
            } else if(recIdSet.contains((ID)((sObject)invItemRec).get('Service_Order_Header__c'))) {
                if(!isCustomerCheckout && invItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party') {
	    			CHECKOUT_TYPE_VALUE = 'Third-Party';
                }
                isInvItemContiansRec = true;
            }
        	
            if(isInvItemContiansRec && (invItemRec.Service_Order_Header__c == null || invItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c != 'Third-Party' || 
                (isCustomerCheckout && invItemRec.SO_Payment_Role__c != null && invItemRec.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible') ||
                (!isCustomerCheckout && invItemRec.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible' && invItemRec.SO_Payment_Role__r.RecordType.DeveloperName != 'Customer'))) {
                invItemRec.isActive__c = true;
                isAtLeastOneActiveItemPresent = true;
            } else {
                invItemRec.isActive__c = false;
            }

	    	COInvoiceItem invItemObj = new COInvoiceItem(invItemRec);
            invItemObj.isActive = invItemRec.isActive__c;
	    	if(isShowDiscount != null) {
	    		invItemObj.IsDisplayDiscountAmount = isShowDiscount;
	    	}
	    	coInvoiceItemObjList.add(invItemObj);
        }
        if(!isAtLeastOneActiveItemPresent) {
            throw new BlackPurlException(INVOICE_ALREADY_CLOSED);
        }
	    update coInvoiceItemList;
	    return coInvoiceItemObjList;
    }
    
    public static String getActiveInvHeaderId(String coHeaderId) {
    	List<CO_Invoice_Header__c> coInvHeaderList = [Select Id from CO_Invoice_Header__c where CO_Header__c =: coHeaderId AND Invoice_Status__c = 'Active'];
    	return (coInvHeaderList.size() > 0 ? coInvHeaderList[0].Id : null);
    }
}