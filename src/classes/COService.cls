global without sharing class COService {

    public static SO_KLI_Recalculation.Errorhandler error;
	
	public static String getCOHeaderDetailsByGridName(String coHeaderId, String gridName) {
        try{ 
            List<CO_Header__c> coHeaderRec = new List<CO_Header__c>();
            coHeaderRec = SOQLUtility.getCOHeaderDetails(coHeaderId, 2); 
            List<CO_Invoice_Header__c> closedCOInvoiceHeaders = new List<CO_Invoice_Header__c>();
            List<CO_Line_Item__c> coLineItems = new List<CO_Line_Item__c>();
            List<CO_Kit_Header__c> coKitHeaders = new List<CO_Kit_Header__c>();
            List<Price_Level__c> priceLevelList = new List<Price_Level__c>();
            List<CO_Deposit__c> coDeposits = new List<CO_Deposit__c>();
            List<CO_Invoice_Payment__c> coInvoicePayments = new List<CO_Invoice_Payment__c>();
            
            List<Account> customerRecords = new List<Account>(); 
            if(String.isNotBlank(coHeaderRec[0].Customer__c)) {
                customerRecords = SOQLUtil.getCardDetails(new Map<String, String>{'Id' => coHeaderRec[0].Customer__c}); 
            } else if(coHeaderRec[0].CO_Type__c == 'Cash Sale'){
                priceLevelList = SOQLUtil.getCardDetailsForCO(null);     
            } else if(coHeaderRec[0].CO_Type__c == 'Internal Service') {
                String defaultPriceLevelId = GeneralConfiguration.getDefaultPriceLevelOnInternalService();
                priceLevelList = SOQLUtil.getCardDetailsForCO(defaultPriceLevelId);    
            }
            if(gridName == null ||  gridName.contains('coDeposit')) {
                List<CO_Invoice_Header__c> coInvoiceHeaders = SOQLUtil.getCOInvoiceHeaderByCOHeaderId(coHeaderId);   
                coDeposits = SOQLUtil.getCODepositByCOHeaderId(coHeaderId);
                if(coInvoiceHeaders.size() > 0) {
                    coInvoicePayments = SOQLUtil.getCOInvoicePaymentsByCOInvoiceHeaderId(coInvoiceHeaders[0].Id);
                }
            }
            if(gridName == null || gridName.contains('closedCOInvoiceHeader')) {
                closedCOInvoiceHeaders = SOQLUtil.getInvoiceHistory(coHeaderId);
            }
            
            if(gridName == null || gridName.contains('coLineItem')) {
                coLineItems = SOQLUtil.getCOLineItemByCOHeaderId(coHeaderId);
                coKitHeaders = SOQLUtil.getCOKHByCOHeaderId(coHeaderId);
            }
            
            CustomerOrderWrapper.COHeaderWrapper coHeaderWrapperObj;
            if(coHeaderRec.size() > 0) {  
                coHeaderWrapperObj = new CustomerOrderWrapper.COHeaderWrapper(coHeaderRec[0], customerRecords, coLineItems, coKitHeaders, closedCOInvoiceHeaders, priceLevelList, 
                                                    coDeposits, coInvoicePayments);
            } else {
                coHeaderWrapperObj = new CustomerOrderWrapper.COHeaderWrapper(null, customerRecords, coLineItems, coKitHeaders, closedCOInvoiceHeaders, priceLevelList, 
                                                    coDeposits, coInvoicePayments);
            } 
            return BPUtility.getEncodedString(System.JSON.serialize(coHeaderWrapperObj, true));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public static String addPayment(List<COInvoicePayment> coInvoicePaymentsObjList, String coId) {
        try {
            // Added one common method for validation
        	validationsBeforeAddingPayment(coInvoicePaymentsObjList);
            
            ResponseWrapper response = processPayments(coInvoicePaymentsObjList);
            if(response != null && response.responseStatus.equalsIgnoreCase('Error')) {
                return System.JSON.serialize(response);
            }
            List<CO_Invoice_Payment__c> coInvoicePaymentListToUpdate = new List<CO_Invoice_Payment__c>();
            List<Id> reversePaymentIds = new List<Id>();
            
            List<CO_Invoice_Header__c> coInvHeaderList = new List<CO_Invoice_Header__c>();
            List<CO_Deposit__c> coDepositsListToInsert = new List<CO_Deposit__c>();
            for(COInvoicePayment coInvoicePaymentObj : coInvoicePaymentsObjList) {
                if(coInvoicePaymentObj.PaymentMethod != null && (coInvoicePaymentObj.PaymentMethod == Constants.USE_DEPOSIT || coInvoicePaymentObj.PaymentMethod =='Use Deal Deposit')) {
                    CO_Deposit__c coDepositRec = new CO_Deposit__c();
                    if(coInvoicePaymentObj.IsReverse != null && coInvoicePaymentObj.IsReverse && String.isNotBlank(coInvoicePaymentObj.DepositPaymentMethod)) {
                        coDepositRec.Payment_Method__c = coInvoicePaymentObj.DepositPaymentMethod;
                        coDepositRec.Is_Reversal_Of_Payment__c = true;
                    } else {
                        coDepositRec.Payment_Method__c = 'Invoice';
                        coDepositRec.CO_Invoice_Header__c = coInvoicePaymentObj.COInvoiceHeaderId;
                    }
                    coDepositRec.CO_Header__c = coId;
                    coDepositRec.Cash_Drawer__c  = coInvoicePaymentObj.CashDrawerId;
                    coDepositRec.Amount__c = -1 * coInvoicePaymentObj.Amount;
                    DateTime dtValue = HomeSearchFilterInterface.getDateFromString(coInvoicePaymentObj.PaymentDate);
                	coDepositRec.Payment_Date__c = (coInvoicePaymentObj.PaymentDate != null) ? Date.newInstance(dtValue.year(), dtValue.month(), dtValue.day()) : date.today();
                    
                    if(String.isNotBlank(coInvoicePaymentObj.DealId)) {
                        coDepositRec.Deal__c =coInvoicePaymentObj.DealId; 
                    }
                    coDepositRec.Customer_Name__c = coInvoicePaymentObj.CustomerId;
                    coDepositsListToInsert.add(coDepositRec);
                }
            }
            if(coDepositsListToInsert.size() > 0) {
                DMLUtility.insertSobjectList('CO_Deposit__c', coDepositsListToInsert);
            }
             
            Boolean isRelatedTxn = false;
            String customerId;
            for(COInvoicePayment coInvoicePaymentObj : coInvoicePaymentsObjList) {
                if(coInvoicePaymentObj.PaymentMethod != 'Cash Rounding' || coInvoicePaymentObj.Amount != 0) {
                    CO_Invoice_Payment__c coInvoicePaymentRec = COPaymentService.createCOPaymentRecord(coInvoicePaymentObj);
                    if(coInvoicePaymentObj.ReverseLink != null) {
                        reversePaymentIds.add(coInvoicePaymentObj.ReverseLink);
                    }
                    coInvoicePaymentListToUpdate.add(coInvoicePaymentRec);
                }
                if(coInvoicePaymentObj.PaymentMethod == 'Cash Rounding' || coInvoicePaymentObj.PaymentMethod == 'Payment Surcharge') {
                	isRelatedTxn = true;
                    customerId = coInvoicePaymentObj.CustomerId;
                }
            }
            
            Boolean isAlreadyInserted = false;
            if(reversePaymentIds.size() > 0) {
                List<CO_Invoice_Payment__c> roundingPaymentList = [select Id, Amount__c, Cash_Rounding_Payment__c,
                                                                     CO_Invoice_Header__c, Is_Reverse__c, Cash_Drawer__c, 
                                                                     Payment_Method__c, Reverse_Link__c, 
                                                                     Reverse_Payment_From__c,Payment_Date__c, Customer_Name__c from CO_Invoice_Payment__c 
                                                                     where Cash_Rounding_Payment__c IN :reversePaymentIds];
                if(roundingPaymentList.size() > 0){
                    CO_Invoice_Payment__c clonedRoundingPayment = roundingPaymentList[0].clone(false, true);
                    clonedRoundingPayment.Is_Reverse__c = true;
                    clonedRoundingPayment.Reverse_Link__c = roundingPaymentList[0].Id;  
                    clonedRoundingPayment.Reverse_Payment_From__c = roundingPaymentList[0].Id;
                    if(roundingPaymentList[0].Amount__c != null){
                        clonedRoundingPayment.Amount__c = -1 * roundingPaymentList[0].Amount__c;    
                    }
                    
                    coInvoicePaymentListToUpdate.add(clonedRoundingPayment);
                    isAlreadyInserted = true;
                    DMLUtility.upsertSobjectList('CO_Invoice_Payment__c', coInvoicePaymentListToUpdate);
                    roundingPaymentList[0].Reverse_Link__c = clonedRoundingPayment.Id;
                    roundingPaymentList[0].Reverse_Payment_From__c = clonedRoundingPayment.Id;
                    DMLUtility.updateSobjectList('CO_Invoice_Payment__c', roundingPaymentList);
                }   
                
            } 
        	if(!isAlreadyInserted && coInvoicePaymentListToUpdate.size() > 0) {
                DMLUtility.upsertSobjectList('CO_Invoice_Payment__c', coInvoicePaymentListToUpdate);
            }
			
			String relatedTxnRecId;            
            if(isRelatedTxn) {
            	for(CO_Invoice_Payment__c coInvoicePaymentRec : coInvoicePaymentListToUpdate) {
	                if(coInvoicePaymentRec.Payment_Method__c != 'Cash Rounding' && coInvoicePaymentRec.Payment_Method__c != 'Payment Surcharge') {
	                    relatedTxnRecId = coInvoicePaymentRec.Id;
	                    break;
	                }
	            }
	            
	            List<CO_Invoice_Payment__c> coInvoicePaymentListForRounding = new List<CO_Invoice_Payment__c>();
	            for(CO_Invoice_Payment__c coInvoicePaymentRec : coInvoicePaymentListToUpdate) {
	                if(coInvoicePaymentRec.Payment_Method__c == 'Cash Rounding' || coInvoicePaymentRec.Payment_Method__c == 'Payment Surcharge') {
	                    coInvoicePaymentRec.Cash_Rounding_Payment__c = relatedTxnRecId;
                        coInvoicePaymentRec.Customer_Name__c = customerId;
                    	coInvoicePaymentListForRounding.add(coInvoicePaymentRec);
	                    break;
	                }
	            }
	            
	            if(coInvoicePaymentListForRounding.size() > 0){
                    DMLUtility.updateSobjectList('CO_Invoice_Payment__c', coInvoicePaymentListForRounding);
	            }
            }
            
            if(reversePaymentIds.size() > 0) {
            	if(String.isBlank(relatedTxnRecId)) {
            		relatedTxnRecId = coInvoicePaymentListToUpdate[0].Id;
            	}
                if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<CO_Invoice_Payment__c> COInvoicePaymentsToBeReversed = [select Id, Reverse_Link__c from CO_Invoice_Payment__c where Id IN :reversePaymentIds];
                for(CO_Invoice_Payment__c coInvoicePaymentRec : COInvoicePaymentsToBeReversed) {
                    coInvoicePaymentRec.Reverse_Link__c = relatedTxnRecId;
                    coInvoicePaymentRec.Reverse_Payment_From__c = relatedTxnRecId;
                }
                if(COInvoicePaymentsToBeReversed.size() > 0) {
                    if(AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                    update COInvoicePaymentsToBeReversed;
                    validateAndCloseCO(coId);
                }
            }
            
            if(coInvoicePaymentListToUpdate.size() > 0 && coInvoicePaymentListToUpdate[0].Payment_Method__c == Constants.AR_CREDIT) {
                return coInvoicePaymentListToUpdate[0].Id;
            }
            return '';
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    private static void validationsBeforeAddingPayment(List<COInvoicePayment> coInvoicePaymentsObjList) {
    	Set<String> arCreditAccIdSet = new Set<String>();
        String customerId;
        for(COInvoicePayment coInvoicePaymentObj : coInvoicePaymentsObjList) {
            if(coInvoicePaymentObj.PaymentMethod == Constants.AR_CREDIT && coInvoicePaymentObj.ARCreditAccId != null) {
                customerId = coInvoicePaymentObj.CustomerId;
                arCreditAccIdSet.add(coInvoicePaymentObj.ARCreditAccId);
            }
        }
        if(!arCreditAccIdSet.isEmpty()) {
            if(isARCreditsAlreadyAdded(arCreditAccIdSet)) {
            	throw new BlackPurlException('AR credit is already added on some customer order.');
            } else if(isARCreditsRemoved(arCreditAccIdSet, customerId)) {
                throw new BlackPurlException('AR credit has been modified, please refresh your page.');
            }
        }
        
        // Check for Invoice. If Invoice already closed, then don't add payment.
        String invoiceId = (coInvoicePaymentsObjList.size() > 0 ? coInvoicePaymentsObjList[0].COInvoiceHeaderId : null);
        if(String.isNotBlank(invoiceId)) {
        	List<CO_Invoice_Header__c> invoiceList = [SELECT Invoice_Status__c FROM CO_Invoice_Header__c WHERE Id =: invoiceId limit 1];
        	if(invoiceList.size() == 1 && invoiceList[0].Invoice_Status__c == 'Closed') {
        		throw new BlackPurlException('Invoice is already closed. Please refresh page to continue.');
        	}
        }
    }
    
    public static CO_Line_Item__c createEnvFeeLineItem(Part__c partRec, String coHeaderId) {
        CO_Line_Item__c envFeeLineItemRec = new CO_Line_Item__c();
        if(partRec != null && partRec.Enviro_Fee__c != null && partRec.Enviro_Fee_Code__c != null) {
            envFeeLineItemRec.Fee__c = partRec.Enviro_Fee_Code__c;
            envFeeLineItemRec.Item_Code__c = partRec.Enviro_Fee_Code__r.Code__c;
            envFeeLineItemRec.Item_Description__c = partRec.Part_Number__c + ' ' + partRec.Enviro_Fee_Code__r.Description__c;
            envFeeLineItemRec.CO_Header__c = coHeaderId;
            envFeeLineItemRec.Price__c = partRec.Enviro_Fee__c;
            envFeeLineItemRec.Qty__c = envFeeLineItemRec.Qty_Committed__c = 1;
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                envFeeLineItemRec.Price_When_Tax_Included__c = partRec.Enviro_Fee__c;
            }
            envFeeLineItemRec.Is_Environmental_Fee__c = true;
        }
        return envFeeLineItemRec;
    }
    
    public static Map<String, Part__c> getPartIdToPartRecMap(Set<String> partIdSet) {
        Map<String, Part__c> partIdToPartRecMap = new Map<String, Part__c>();
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Part__c> partList = [SELECT Part_Number__c, Enviro_Fee__c, Enviro_Fee_Code__c, Enviro_Fee_Code__r.Code__c, 
                                    Enviro_Fee_Code__r.Description__c FROM Part__c WHERE Id IN :partIdSet];
        for(Part__c partRec: partList) {
            partIdToPartRecMap.put(partRec.Id, partRec);
        }
        return partIdToPartRecMap;
    }
    
    public static List<Sobject> addLinkedFee(String recordId, String dealId, String objectType) {
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        if(String.isNotBlank(objectType)){
            List<Linked_Fee__c> linkedFeeList = SOQLUtil.getLinkedFeeList(new Map<String, String>{'Related_To__c' => objectType});
            if(linkedFeeList.size() == 0) {
                return null;
            }
            if(objectType == 'Merchandise') {
                List<CO_Line_Item__c> coliList = new List<CO_Line_Item__c>();
                CO_Line_Item__c coLineItemRec;
                for(Linked_Fee__c linkFee : linkedFeeList){
                    coLineItemRec = new CO_Line_Item__c();
                    coLineItemRec.Qty__c = 1 ;
                    coLineItemRec.Qty_Committed__c = 1;
                    if(isTaxIncludingPricing){
                        coLineItemRec.Price_When_Tax_Included__c = linkfee.Price__c == null ? linkfee.Fee__r.Price__c : linkfee.Price__c;
                    } else {
                        coLineItemRec.Price__c = linkfee.Price__c == null ? linkfee.Fee__r.Price__c : linkfee.Price__c;
                    }
                    coLineItemRec.CO_Header__c = recordId;
                    coLineItemRec.Fee__c = linkFee.Fee__c;
                    coLineItemRec.Item_Description__c = linkfee.Description__c == null ? linkfee.Fee__r.Description__c : linkfee.Description__c;
                    coLineItemRec.Is_Linked_Fee__c = true;
                    coliList.add(coLineItemRec);
                }
                if(coliList.size() > 0){
                    return coliList;
                }
            } else if(objectType == 'Service Job') {
                List<Service_Order_Line_Item__c> soliList = new List<Service_Order_Line_Item__c>();
                Service_Order_Line_Item__c soliRec;
                for(Linked_Fee__c linkFee : linkedFeeList){
                    soliRec = new Service_Order_Line_Item__c();
                    soliRec.Service_Order_Header__c = recordId;
                    soliRec.Fee__c = linkFee.Fee__c;
                    soliRec.Item_Code__c = linkFee.Fee__r.Code__c;
                    soliRec.Item_Description__c = linkfee.Description__c == null ? linkfee.Fee__r.Description__c : linkfee.Description__c;
                    soliRec.Qty_Needed__c = 1;
                    soliRec.Qty_Committed__c = 1;
                    if(isTaxIncludingPricing){
                        soliRec.Price_When_Tax_Included__c = linkfee.Price__c == null ? linkfee.Fee__r.Price__c : linkfee.Price__c;
                    } else {
                        soliRec.Kit_Price__c = linkfee.Price__c == null ? linkfee.Fee__r.Price__c : linkfee.Price__c;
                    }
                    soliRec.Actual_Kit_Price__c = (soliRec.Kit_Price__c != null) ? soliRec.Kit_Price__c : 0;
                    soliRec.Is_Linked_Fee__c = true;
                    soliList.add(soliRec);
                }
                if(soliList.size() > 0){
                    return soliList;
                }
            } else if(objectType == 'Deal') {
                List<Option_Fee__c> optionAndFeeRecList = new List<Option_Fee__c>();
                Option_Fee__c optionAndFeeRec;
                for(Linked_Fee__c linkFee : linkedFeeList){
                    optionAndFeeRec = new Option_Fee__c();
                    optionAndFeeRec.Deal__c = dealId;
                    optionAndFeeRec.Deal_Item__c = recordId;
                    optionAndFeeRec.Fee__c = linkFee.Fee__c;
                    optionAndFeeRec.Item_Code__c = linkFee.Fee__r.Code__c;
                    optionAndFeeRec.Item_Description__c = linkfee.Description__c == null ? linkfee.Fee__r.Description__c : linkfee.Description__c;
                    optionAndFeeRec.Qty__c = 1;
                    if(isTaxIncludingPricing){
                        optionAndFeeRec.Price_When_Tax_Included__c = linkfee.Price__c == null ? linkfee.Fee__r.Price__c : linkfee.Price__c;
                    } else {
                        optionAndFeeRec.Price__c = linkfee.Price__c == null ? linkfee.Fee__r.Price__c : linkfee.Price__c;
                    }
                    optionAndFeeRecList.add(optionAndFeeRec);
                    optionAndFeeRec.Is_Linked_Fee__c = true;
                } 
                if(optionAndFeeRecList.size() > 0){
                    return optionAndFeeRecList;
                }
            }
        }
            
        return null;
    }
    
    /**
    * Name: saveCustomerApproval
    * Desc: Save CustomerApproval Information to CustomerApproval__c
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    * @param:  (2) List<CustomerApproval> - custApprovalObjList to save
    * @return: Updated JSON data of Customer Approvals
    **/
    public static String saveCustomerApproval(String soHeaderId, List<CustomerApproval> custApprovalObjList) {

        List<CustomerApproval__c> custApprovalList = new List<CustomerApproval__c>();
        Decimal approvalCount;
        for(CustomerApproval custApprovalObj : custApprovalObjList) {
            if(custApprovalObj.ApprovalCount != null) {
                approvalCount = custApprovalObj.ApprovalCount;
            }   
        }
        List<CustomerApproval__c> existingApprovalList;
        if(approvalCount == null) {
            existingApprovalList = [SELECT Id, Approval_Count__c FROM CustomerApproval__c 
                                    WHERE Service_Order_Header__c =: soHeaderId AND Section_key__c = 'Get_Approval' 
                                    Order By Approval_Count__c DESC nulls last];
            approvalCount = (existingApprovalList.size() == 0) ? 1 : (existingApprovalList[0].Approval_Count__c + 1);                                                      
        }
        
        existingApprovalList = [SELECT Id, Section_key__c, ApprovalType__c, Approval_Count__c FROM CustomerApproval__c 
                                WHERE Service_Order_Header__c =: soHeaderId AND Approval_Count__c =: approvalCount]; 
        
        Map<String, CustomerApproval__c> approvalTypeToApprovalRecordMap = new Map<String, CustomerApproval__c>();
        for(CustomerApproval__c custApprovalRec : existingApprovalList) {
            approvalTypeToApprovalRecordMap.put(custApprovalRec.ApprovalType__c, custApprovalRec);
        }                                                   
        
        List<CustomerApproval__c> approvalListToUpsert = new List<CustomerApproval__c>();
        for(CustomerApproval custApprovalObj : custApprovalObjList) {
            CustomerApproval__c custApprovalRec = new CustomerApproval__c();
            custApprovalRec.Service_Order_Header__c = soHeaderId;
            custApprovalRec.Section_key__c = 'Get_Approval';
            custApprovalRec.Section_Name__c = 'Get-Approval';
            
            if(custApprovalObj.IsApprovalObtained != null && custApprovalObj.IsApprovalObtained) {
                custApprovalRec.Status__c = 'Approved';
            } else {
                custApprovalRec.Status__c = 'Pending';
            }
            custApprovalRec.Notes__c = custApprovalObj.Notes;
            custApprovalRec.ApprovalType__c = custApprovalObj.ApprovalType;
            custApprovalRec.Approval_Count__c = approvalCount;
            if(approvalTypeToApprovalRecordMap.containsKey(custApprovalObj.ApprovalType)) {
                custApprovalRec.Id = approvalTypeToApprovalRecordMap.get(custApprovalObj.ApprovalType).Id;
                approvalTypeToApprovalRecordMap.remove(custApprovalObj.ApprovalType);
            } 
            approvalListToUpsert.add(custApprovalRec);
        }
        
        if(approvalListToUpsert.size() > 0) {
            DMLUtility.upsertSobjectList('CustomerApproval__c', approvalListToUpsert);
        }
        if(approvalTypeToApprovalRecordMap.values().size() > 0) {
            delete approvalTypeToApprovalRecordMap.values();
        }
        
        return getCustomerApprovals(soHeaderId, 'Get_Approval', approvalCount);
    }

    /**
    * Name: getCustomerApprovals
    * Desc: Get all CustomerApprovals for a Service Order
    * @param: (1) soHeaderId - String - Id of SO Header Record
    * @param: (2) sectionKey
    * @param: (3) approvalCount
    * @return: JSON data for customer approvals
    **/
    public static String getCustomerApprovals(String soHeaderId, String sectionKey, Decimal approvalCount) {
        List<CustomerApproval> custApprovalList = new List<CustomerApproval>();
        List<CustomerApproval__c> customerApprovalList = new List<CustomerApproval__c>();
        
        if(sectionKey == 'Get_Approval' && approvalCount != null) {
            customerApprovalList = [select Approval_Count__c, ApprovalDetailJson__c, ApprovalType__c, Notes__c, Section_key__c, Name, LastModifiedDate,
                                                Section_Name__c, Service_Order_Header__c, Status__c from CustomerApproval__c
                                                where Service_Order_Header__c =: soHeaderId AND Approval_Count__c = :approvalCount];
        
        } else if(sectionKey != 'Get_Approval') {
            customerApprovalList = [select Approval_Count__c, ApprovalDetailJson__c, ApprovalType__c, Notes__c, Section_key__c, Name, LastModifiedDate,
                                                Section_Name__c, Service_Order_Header__c, Status__c from CustomerApproval__c 
                                                where Service_Order_Header__c =: soHeaderId AND Section_key__c =: sectionKey];
        } 
        
        for(CustomerApproval__c custApproval : customerApprovalList) {
            custApprovalList.add(new CustomerApproval(custApproval));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(custApprovalList));
    }
    
    public static void createMerchSectionIfNotExist(String coHeaderId) {
        try{
            List<CO_Header__c> coHeaderList = [Select id, Hide_Merchandise_Section__c, Customer__c,
                                                    (Select id from CO_Line_Items__r where Is_In_Merch_Section__c = true) from CO_Header__c where Id =: coHeaderId];
                                                    
            if(coHeaderList.size() > 0 && coHeaderList[0].Hide_Merchandise_Section__c) { // && coHeaderList[0].Customer__c != null
                if(coHeaderList[0].CO_Line_Items__r.size() == 0) {
                    List<SObject> sObjectListToInsert = addLinkedFee(coHeaderId, null, 'Merchandise');
                    if(sObjectListToInsert != null) {
                        if(!AccessControl.ifObjectFieldIsCreateable('CO_Line_Item__c')){throw new BlackPurlException('CO_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                        if(!AccessControl.ifObjectFieldIsCreateable('Service_Order_Line_Item__c')){throw new BlackPurlException('Service_Order_Line_Item__c' + DMLUtility.NOT_CREATABLE);}
                        if(!AccessControl.ifObjectFieldIsCreateable('Option_Fee__c')){throw new BlackPurlException('Option_Fee__c' + DMLUtility.NOT_CREATABLE);}
                        insert sObjectListToInsert;
                    }
                    addDefaultSalespersonToCOSection(coHeaderId);
                    // Add CO Section Detail record for Merchandise section when first record is added in Merchandise section.
                    COSectionDetailService.createCOSection(coHeaderId, COSectionDetailService.MERCHANDISE);
                }
                MerchandiseService.updateMerchSectionToDisplay(coHeaderId, false);
            }
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public static String finalizeInvoice(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType){
        String currentFormattedDate = BPutility.getFormatedDateTime(datetime.newinstance(System.now().date(), System.now().time()));
        return finalizeInvoice(coInvoiceItemsJsonString, coHeaderId, currentCheckoutType,currentFormattedDate);
    }
    
    //create private method to setContactAndShippingFields
    private static void setContactAndShippingFields(CO_Invoice_Header__c coInvHeaderRec, CO_Header__c coHeaderRec) {
        if(coInvHeaderRec != null && coHeaderRec != null) {
            if(coHeaderRec.Customer_Shipping_Address__c != null && coHeaderRec.Customer_Shipping_Address__r.Is_Shipping_Address__c) {
                coInvHeaderRec.Shipping_Contact_Name__c = coHeaderRec.Customer_Shipping_Address__r.LastName;
                coInvHeaderRec.Shipping_Street__c = coHeaderRec.Customer_Shipping_Address__r.MailingStreet;
                coInvHeaderRec.Shipping_City__c = coHeaderRec.Customer_Shipping_Address__r.MailingCity;
                coInvHeaderRec.Shipping_County_Parish__c = coHeaderRec.Customer_Shipping_Address__r.Mailing_County_Parish__c;
                coInvHeaderRec.Shipping_State__c = coHeaderRec.Customer_Shipping_Address__r.MailingState;
                coInvHeaderRec.Shipping_Postal_Code__c = coHeaderRec.Customer_Shipping_Address__r.MailingPostalCode;
                coInvHeaderRec.Shipping_Country__c = coHeaderRec.Customer_Shipping_Address__r.MailingCountry;
            } else {
                coInvHeaderRec.Shipping_Contact_Name__c = coInvHeaderRec.Shipping_Street__c = coInvHeaderRec.Shipping_City__c = 
                coInvHeaderRec.Shipping_County_Parish__c = coInvHeaderRec.Shipping_State__c = coInvHeaderRec.Shipping_Postal_Code__c = 
                coInvHeaderRec.Shipping_Country__c = null;
            }
            if(coHeaderRec.Customer_Contact__c != null && coHeaderRec.Customer_Contact__r.Is_Contact__c) {
                coInvHeaderRec.Contact_Name__c = coHeaderRec.Customer_Contact__r.LastName;
                coInvHeaderRec.Contact_Formatted_Phone__c = coHeaderRec.Customer_Contact__r.Formatted_Phone_number__c;
                coInvHeaderRec.Contact_Email__c = coHeaderRec.Customer_Contact__r.Email;
            } else {
                coInvHeaderRec.Contact_Name__c = coInvHeaderRec.Contact_Formatted_Phone__c = coInvHeaderRec.Contact_Email__c = null;
            }
        }
    }

    private static void transferReceivedVOLineItem(Map<Integer, List<Vendor_Order_Line_Item__c>> counterToReceivedVOLineItemListMap, 
                                                    List<CO_Line_Item__c> coLineItemRecToInserted) {
        List<Vendor_Order_Line_Item__c> voLineItemListToUpdate = new List<Vendor_Order_Line_Item__c>();
        for(Integer i = 0; i < coLineItemRecToInserted.size(); i++) {
            if(counterToReceivedVOLineItemListMap.containsKey(i)) {
                for(Vendor_Order_Line_Item__c voliRec : counterToReceivedVOLineItemListMap.get(i)) {
                    voliRec.CO_Line_Item__c = coLineItemRecToInserted[i].Id;
                    voLineItemListToUpdate.add(voliRec);
                }
            }
        }
        if(voLineItemListToUpdate.size() > 0) {
            VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
            DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voLineItemListToUpdate);
            VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
        }
    }
    
    public static void finalizeOrder(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType) {
        String currentFormattedDate = BPutility.getFormatedDateTime(datetime.newinstance(System.now().date(), System.now().time()));
        finalizeOrder(coInvoiceItemsJsonString, coHeaderId, currentCheckoutType, currentFormattedDate);
    }
    
    private static void validatePayment(String currentCheckoutType, CO_Invoice_Header__c invoiceRec, List<CO_Invoice_Item__c> dealCOInvItemList) {
	    if(!Test.isRunningTest() && currentCheckoutType.equalsIgnoreCase('Customer')) {
	    	if(!BPConfigurationsService.isBypassValidation() && (dealCOInvItemList == null || dealCOInvItemList.isEmpty() || !dealCOInvItemList[0].Deal__r.Type__c.equalsIgnoreCase('Financed')) && invoiceRec.Total__c != invoiceRec.Total_Payment__c) {
	        	throw new BlackpurlException('Cannot finalize. Payment amount does not match with invoice total.');
	        } else if(invoiceRec.Total__c == 0 && invoiceRec.Total_Amount_Except_Charge_Account__c != 0) {
	        	throw new BlackpurlException('Cannot finalize. For invoice total of zero, there should be no charge on account.');
	        }
        }
    }

    private static void validateDeposit(List<CODeposit> coDepositObjList) {
    	List<CO_Header__c> coHeaderList = [Select Id, Total_Deposit__c FROM CO_Header__c Where Id =: coDepositObjList[0].COHeaderId];
        if(coHeaderList.size() > 0) {
            Decimal totalDepositAmt = 0;
            for(CODeposit coDepositObj : coDepositObjList) { 
                totalDepositAmt += coDepositObj.Amount;
            }
            if(coHeaderList[0].Total_Deposit__c < (-totalDepositAmt)) {
                throw new BlackpurlException('The deposit payment amount cannot be greater than the current deposit total');
            }
        }   
    }

    public static String saveCODeposit(List<CODeposit> coDepositObjList) {
        try{
            String coHeaderId;
            if(coDepositObjList.size() > 0) {
                coHeaderId = coDepositObjList[0].COHeaderId;
            } else {
                coHeaderId = null;
            }

            if(coDepositObjList.size() > 0) {
                validateDeposit(coDepositObjList);
                ResponseWrapper response = processDeposits(coDepositObjList);
                if(response != null && response.responseStatus.equalsIgnoreCase('Error')) {
                    return System.JSON.serialize(response);
                }
            }

            String customerId;
            Set<String> arCreditAccIdSet = new Set<String>();
            for(CODeposit coDepositObj : coDepositObjList) {
                if(coDepositObj.PaymentMethod == Constants.AR_CREDIT && coDepositObj.ARCreditAccId != null) {
                    customerId = coDepositObj.CustomerId;
                    arCreditAccIdSet.add(coDepositObj.ARCreditAccId);
                }
            }
            if(!arCreditAccIdSet.isEmpty()) {
                if(isARCreditsAlreadyAdded(arCreditAccIdSet)) {
                    throw new BlackPurlException('AR credit is already added on some customer order.');
                } else if(isARCreditsRemoved(arCreditAccIdSet, customerId)) {
                    throw new BlackPurlException('AR credit has been modified, please refresh your page.');
            	}
            }

            Boolean isRelatedTxn = false;
            List<CO_Deposit__c> coDepositListToUpdate = new List<CO_Deposit__c>();
            for(CODeposit coDepositObj : coDepositObjList) {
                CO_Deposit__c coDepositRec = new CO_Deposit__c();
                coDepositRec.Amount__c = coDepositObj.Amount ;
                coDepositRec.Payment_Method__c = coDepositObj.PaymentMethod;
                coDepositRec.CO_Header__c = coDepositObj.coHeaderId;
                coDepositRec.Deal__c = coDepositObj.Deal;
                coDepositRec.Reverse_Link__c = coDepositObj.ReverseLink; 
                coDepositRec.Cash_Drawer__c = coDepositObj.CashDrawerId;
                DateTime dtValue = HomeSearchFilterInterface.getDateFromString(coDepositObj.PaymentDate);
            	coDepositRec.Payment_Date__c = (coDepositObj.PaymentDate !=null) ? Date.newInstance(dtValue.year(), dtValue.month(), dtValue.day()) : date.today();
                if( coDepositRec.Deal__c != null){
                    coDepositRec.Recorded_From__c = 'Customer';
                }
                if(coDepositObj.CODepositId != null) {
                    coDepositRec.Id = coDepositObj.CODepositId ;
                }
                if(coDepositRec.Payment_Method__c == Constants.AR_CREDIT) {
                    coDepositRec.AR_Credit_Accounting_Id__c = coDepositObj.ARCreditAccId;
                    coDepositRec.AR_Credit_Number__c = coDepositObj.ARCreditNumber;
                    coDepositRec.Unapplied_Payment_Type__c = coDepositObj.UnappliedPaymentType;
                }
                coDepositRec.Customer_Name__c = coDepositObj.CustomerId;
                coDepositRec.Reference__c = coDepositObj.ReferenceNumber;
                coDepositRec.Payment_Terminal__c = String.isNotBlank(coDepositObj.PaymentTerminalId) ? coDepositObj.PaymentTerminalId : null;
                coDepositListToUpdate.add(coDepositRec);

                if(coDepositRec.Payment_Method__c == 'Payment Surcharge') {
                	isRelatedTxn = true;
                }
            }

            if(coDepositListToUpdate.size() > 0) {
                DMLUtility.upsertSobjectList('CO_Deposit__c', coDepositListToUpdate);

                String relatedTxnRecId;            
                if(isRelatedTxn) {
                    for(CO_Deposit__c coDepositRec : coDepositListToUpdate) {
                        if(coDepositRec.Payment_Method__c != 'Payment Surcharge') {
                            relatedTxnRecId = coDepositRec.Id;
                            break;
                        }
                    }
                }
                
                List<Id> coDepositIdList = new List<Id>();
                for(CO_Deposit__c deposit: coDepositListToUpdate) {
                    coDepositIdList.add(deposit.Id);
                    
                } 
                createStoreCredit(coDepositIdList);
                List<CO_Deposit__c> coDepositListToUpdatedRelatedTxn = new List<CO_Deposit__c>();
                for(CO_Deposit__c coDepositRec: coDepositListToUpdate) {
                    if(String.isNotBlank(coDepositRec.Reverse_Link__c)) {
                        CO_Deposit__c coDepositUpdRec = new CO_Deposit__c(Id = coDepositRec.Reverse_Link__c);
                        coDepositUpdRec.Reverse_Link__c = coDepositRec.Id;
                        coDepositListToUpdatedRelatedTxn.add(coDepositUpdRec);
                    }
                    if(relatedTxnRecId != null && coDepositRec.Payment_Method__c == 'Payment Surcharge') {
                        coDepositRec.Related_Deposit__c = relatedTxnRecId;
                        coDepositListToUpdatedRelatedTxn.add(coDepositRec);
                    }
                }
                DMLUtility.updateSobjectList('CO_Deposit__c', coDepositListToUpdatedRelatedTxn);
            }
            if(coDepositListToUpdate.size() > 0 && coDepositListToUpdate[0].Payment_Method__c == Constants.AR_CREDIT) {
                return coDepositListToUpdate[0].Id;
            }
            return coHeaderId;
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    /*
    *   Method to calculate Part, Labour, fee sublet and Tax total on closed Invoice.
    */
    public static CO_Invoice_Header__c calculateIndividualsTotalsForInvoice(String coInvoiceId) {
        return calculateIndividualsTotalsForInvoice(coInvoiceId, true);
    }
    
    public static CO_Invoice_Header__c getInvoiceRec(String coInvoiceId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Individual_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        return [SELECT Name, Total_Payment__c, CO_Header__r.Customer__r.Total_Store_Credit__c, Invoice_Status__c, CO_Header__r.Order_Status__c,
                                            Total_Amount_Except_Charge_Account__c, 
                                            (SELECT CO_Line_Item__c, CO_Line_Item__r.Deal__c, Service_Order_Header__c, Service_Order_Header__r.Deal__c, 
                                            CO_Kit_Header__c, CO_Kit_Header__r.Deal__c, Deal__c, Service_Order_Header__r.Transaction_Type__r.Type__c, 
                                            SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName, isActive__c 
                                            FROM CO_Invoice_Items__r)
                                            FROM CO_Invoice_Header__c WHERE Id =: coInvoiceId ];
    }
    
    @future
    global static void populateIndividualsCostTotalsAfterFinalize(String coInvoiceId) {
    	DealService.populateDealIndividualsCostTotalsAfterFinalize(coInvoiceId); // Deal Totals
        ServiceJobService.populateSOIndividualsCostTotalsAfterFinalize(coInvoiceId); // Service Job/Deal Service Totals 
        MerchandiseService.populateMerchIndividualsCostTotalsAfterFinalize(coInvoiceId); // Merchandise /Deal Merchandise Totals
    }
	
    // This method can be used if want to TO do calling for - TaxCalculation.getTaxAmountWithFormLabel()
    public static List<Individual_Tax__c> getConditionalIndividualTaxList(Boolean isTaxIncludingPricing, Boolean isInvoiced, 
                                                    List<Id> coliIds, List<Id> cokhIds,
                                                    Set<Id> soIdsToIncludeTax, List<Id> dealIds) {
        return getConditionalIndividualTaxList(isTaxIncludingPricing, isInvoiced, coliIds, cokhIds, soIdsToIncludeTax, dealIds, null);
    }
    public static List<Individual_Tax__c> getConditionalIndividualTaxList(Boolean isTaxIncludingPricing, Boolean isInvoiced, 
                                                    List<Id> coliIds, List<Id> cokhIds,
                                                    Set<Id> soIdsToIncludeTax, List<Id> dealIds, List<Id> soPaymentRolesId) {
        
        String query = 'SELECT Deal__c, Taxable_Amount_for_Section_Header__c, CO_Line_Item__c, Tax_Rate__c, Form_Label__c, Sales_Tax_Item__r.Is_Automated__c, Sales_Tax_Item__r.Name__c, SO_Payment_Role__c, SO_Payment_Role__r.Applicable_Tax_Name__c, ';
        if(isTaxIncludingPricing) {
            query += (isInvoiced) ? 'Tax_Amount__c, ' : 'Tax_Amount_To_Invoice__c, ';
        } else {
            query += 'Enhanced_Tax_Amount__c, ' + ((isInvoiced) ? 'Taxable_Amount__c, ' : 'Taxable_Amount_To_Invoice__c, ');
        }
        query += 'Applicable_Tax__c, List_Tax_items_on_forms__c from Individual_Tax__c' + 
                 ' WHERE CO_Line_Item__c IN : coliIds OR CO_Line_Item__r.CO_Kit_Header__c IN :cokhIds OR ' +
                        'Service_Order_Line_Item__r.Service_Order_Header__c IN :soIdsToIncludeTax ';
        if(isTaxIncludingPricing) {
            query += 'OR Option_Fee__r.Deal__c IN: dealIds OR ' +
                    'Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c IN: dealIds OR F_I_Product__r.Deal_Finance__r.Deal__c IN: dealIds '+
                    'OR (Deal_Item__r.Deal__c IN: dealIds AND Deal_Item__r.Type__c = \'Trade In\') ' +
                    'OR Deal__c IN: dealIds';
        } else {
            query += 'OR Deal__c IN: dealIds';
        } 
        if(soPaymentRolesId != null) {
            query += ' OR SO_payment_Role__c IN : soPaymentRolesId';
        }                    
        return Database.query(query);
    }
    
    public static CO_Invoice_Header__c populateFieldsOnInvoice(Id coInvoiceId) {
        CO_Invoice_Header__c coInvoice = [SELECT Name, Total_Payment__c, CO_Header__r.Customer__r.Total_Store_Credit__c, Invoice_Status__c, 
                                            (SELECT CO_Line_Item__c, Service_Order_Header__c, CO_Kit_Header__c, Deal__c,
                                            SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName 
                                            FROM CO_Invoice_Items__r)
                                            FROM CO_Invoice_Header__c WHERE Id =: coInvoiceId ];
        return populateFieldsOnInvoice(coInvoice);
    }

    private static Map<Id, Set<Id>> getAppliedTaxCodeIdToRateIdSetMap(List<Option_Fee__c> optionFeeList, List<Deal_Item__c> dealItemList, 
    List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList, List<F_I_Product__c> fAndIProductList) {
        Map<Id, Set<Id>> taxCodeIdToRateIdSetMap = new Map<Id, Set<Id>>();
        if(optionFeeList != null) {
            for(Option_Fee__c optionFeeRec : optionFeeList) {
                taxCodeIdToRateIdSetMap.put(optionFeeRec.Applicable_Tax__c, new Set<Id>());
            }
        }
        if(dealItemList != null){
            for(Deal_Item__c dealItemRec : dealItemList) {
        	    if(dealItemRec.Type__c == 'Trade In') {
                    taxCodeIdToRateIdSetMap.put(dealItemRec.Applicable_Tax__c, new Set<Id>());
                }
            }
        }
        if(dealUnitPriceAndCostList != null){
            for(Deal_Unit_Price_Cost__c dupcRec : dealUnitPriceAndCostList) {
                taxCodeIdToRateIdSetMap.put(dupcRec.Applicable_Tax__c, new Set<Id>());
            }
        }
        if(fAndIProductList != null){
            for(F_I_Product__c fAndIProductRec : fAndIProductList) {
                taxCodeIdToRateIdSetMap.put(fAndIProductRec.Applicable_Tax__c, new Set<Id>());
            }
        }
        if(!taxCodeIdToRateIdSetMap.isEmpty()) {
            for(Sales_Tax__c taxCode : [Select Id, (Select Id, Sales_Tax_Item__c FROM Applicable_Taxes__r WHERE Sales_Tax_Item__c != null) FROM Sales_Tax__c WHERE Id IN: taxCodeIdToRateIdSetMap.keyset()]) {
                for(Applicable_Taxes__c applicableTax : taxCode.Applicable_Taxes__r) {
                    taxCodeIdToRateIdSetMap.get(taxCode.Id).add(applicableTax.Sales_Tax_Item__c);
                }
            }
        }
        return taxCodeIdToRateIdSetMap;
    }
    
    @future
    public static void populateFieldsOnInvoice_future(Id coInvoiceId) {
        CO_Invoice_Header__c coInvHeaderRec = populateFieldsOnInvoice(coInvoiceId);
        DMLUtility.updateSobjectListWithRetry(new List<SObject>{coInvHeaderRec});
    }
    
    public static void updateCOPricingAndTaxOnKit(String coHeaderId, String customerId) {
        if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        try{
            COLineItemTriggerHelper.isTotalCalculated = false;
            COKH_Recalcualtion.changePriceWhenCustomerIsChanged(coHeaderId);
            //COKH_Recalcualtion.AddCustomerCoForKititemUpdate(customerId, coHeaderId);
            //SO_KLI_Recalculation.SOPriceCalcultaionByPriceLevel(customerId, coHeaderId);
            SO_KLI_Recalculation.changePriceWhenCustomerIsChanged( new Set<Id>(), coHeaderId);
            DealKH_Recalculation.changePriceWhenCustomerIsChanged(customerId, coHeaderId);
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    public static String addRelatedPartInSO(String partIdsString, String soHeaderId) {
    	try{
    		if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        if(AccessControl.ifObjectFieldIsCreateable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        
	        List<String> partIds = (List<String>) System.JSON.deserialize(partIdsString, List<String>.class);
	        List<COService.SearchPartDetailWrapper> partToInsertList = new List<COService.SearchPartDetailWrapper>();
            for(String partId : partIds) {
            	COService.SearchPartDetailWrapper partObj = new COService.SearchPartDetailWrapper();
            	partObj.PartId = partId;
            	partObj.Qty = 1;
            	partToInsertList.add(partObj);
            }
            return ServiceJobService.addMultiplePartsInServiceJob(partToInsertList, soHeaderId);
            
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public static List<Id> getUnitIdList(Id recordId) {
        try {
            List<Id> unitIdList = new List<Id>();
            if(recordId.getSObjectType().getDescribe().getName() == Constants.Namespace + 'CO_Header__c') {
                List<Service_Order_Header__c> soHeadersList = [select Id, Customer_Owned_Unit__c from Service_Order_Header__c where CO_Header__c =: recordId];
                List<Deal__c> dealList = [select Id, (select Id, Customer_Owned_Unit__c from Deal_Items__r) from Deal__c where CO_Header__c =: recordId];
                
                for(Service_Order_Header__c soHeaderRec : soHeadersList) {
                    if(soHeaderRec.Customer_Owned_Unit__c != null) {
                        unitIdList.add(soHeaderRec.Customer_Owned_Unit__c);
                    }
                }
                if(dealList.size() > 0) {
                    for(Deal_Item__c dealItemRec : dealList[0].Deal_Items__r) {
                        if(dealItemRec.Customer_Owned_Unit__c != null) {
                            unitIdList.add(dealItemRec.Customer_Owned_Unit__c);
                        }
                    }
                }
            } else if(recordId.getSObjectType().getDescribe().getName() == Constants.Namespace + 'Customer_Owned_Unit__c') {
                unitIdList.add(recordId);
            }
            return unitIdList;
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
       
    public static Map<String, List<SearchPartDetailWrapper>> addPartsSmartItems(String partsInfoJson, String sectionName, String sectionHeaderId, String partImportFormat) {
    	List<SearchPartDetailWrapper> searchPartsDetailObjList = (List<SearchPartDetailWrapper>) System.JSON.deserialize(partsInfoJson, List<SearchPartDetailWrapper>.class);
    	//Get DealerVu to BP Vendor code mapping records
    	List<Partsmart_To_BP_Vendor_Code_Mapping__c> vendorCodeMappingList = [SELECT Id, Name, BP_Vendor_Code__c FROM Partsmart_To_BP_Vendor_Code_Mapping__c limit :SOQLUtil.getAvailableQueryRowsLimit()];
    	Map<String, String> partsmartToBPVendorCodeMap = new Map<String, String>();
    	for(Partsmart_To_BP_Vendor_Code_Mapping__c vendorCodeObj : vendorCodeMappingList) {
    		partsmartToBPVendorCodeMap.put(vendorCodeObj.Name, vendorCodeObj.BP_Vendor_Code__c);
    	}
    	
    	Set<String> partNumberSet = new Set<String>();
        Set<String> partNumberSetFromFile = new Set<String>();
    	for(SearchPartDetailWrapper partInfoObj : searchPartsDetailObjList) {
    		if(partImportFormat == Constants.ARI_Partsmart10) {
    			for(String partSmartVendorCode : partsmartToBPVendorCodeMap.keySet()) {
    				partNumberSet.add(partInfoObj.PartNumber + partsmartToBPVendorCodeMap.get(partSmartVendorCode));
    			}
    		} else if(partImportFormat == Constants.ARI_Partsmart8) {
                if(partsmartToBPVendorCodeMap.containsKey(partInfoObj.Manufacturer)) {
                    partNumberSet.add(partInfoObj.PartNumber + partsmartToBPVendorCodeMap.get(partInfoObj.Manufacturer));
                }
            } else if(partImportFormat == Constants.Generic_CSV || partImportFormat == Constants.Snap_On_EPC || partImportFormat == Constants.HLSM_CSV || 
                        partImportFormat == Constants.BRP_PICK_LIST) {
                partNumberSet.add(partInfoObj.PartNumber);
            }
            partNumberSetFromFile.add(partInfoObj.PartNumber);
    	}
    	Map<Id, Part__c> partIdToRecMap = new Map<Id, Part__c>();
    	//Query Part
    	if(partNumberSet.size() > 0) {
            String query = 'Select Id, AvailableParts__c, Vendor__r.Name, Retail_Price__c, Part_Id__c, Item_Description__c, Non_Inventory_Part__c, Part_Number__c FROM Part__c WHERE';
            if(partImportFormat == Constants.Generic_CSV || partImportFormat == Constants.BRP_PICK_LIST) {
                query += ' Part_ID__c IN: partNumberSet OR Part_Number__c IN: partNumberSet ';
            } else if(partImportFormat == Constants.Snap_On_EPC || partImportFormat == Constants.HLSM_CSV) {
                query += ' Part_Number__c IN: partNumberSet ';
            } else {
                query += ' Part_Id__c IN: partNumberSet ';
            }
            query += 'Limit ' + SOQLUtil.getAvailableQueryRowsLimit();
	    	partIdToRecMap = new Map<Id, Part__c>((List<Part__c>)Database.query(query));
    	}

        Map<String, List<Part__c>> partNumberToRecListMap = new Map<String, List<Part__c>>();
        Map<String, Part__c> partUniqueIdToRecMap = new Map<String, Part__c>();
        for(Part__c partRecord: partIdToRecMap.values()) {
            if(partNumberSetFromFile.contains(partRecord.Part_Number__c)) {
                if(!partNumberToRecListMap.containsKey(partRecord.Part_Number__c)) {
                    partNumberToRecListMap.put(partRecord.Part_Number__c, new List<Part__c>());
                }
                partNumberToRecListMap.get(partRecord.Part_Number__c).add(partRecord);
            } else if(partNumberSetFromFile.contains(partRecord.Part_Id__c)) {
                partUniqueIdToRecMap.put(partRecord.Part_Id__c, partRecord);
            }
        }

    	List<SearchPartDetailWrapper> partNotInSystemList = new List<SearchPartDetailWrapper>();
    	List<SearchPartDetailWrapper> partToInsertList = new List<SearchPartDetailWrapper>();
    	List<SearchPartDetailWrapper> outOfStockPartList = (sectionName == Constants.CASH_SALE) ? new List<SearchPartDetailWrapper>() : null;
    	for(SearchPartDetailWrapper partInfoObj : searchPartsDetailObjList) {
            Part__c partRecordToUse;
            
            if(partImportFormat == Constants.ARI_Partsmart10) {
                if(partNumberToRecListMap.containsKey(partInfoObj.PartNumber)) {
                    partRecordToUse = partNumberToRecListMap.get(partInfoObj.PartNumber).size() > 0 ? partNumberToRecListMap.get(partInfoObj.PartNumber)[0] : null;
                }
            } else if(partImportFormat == Constants.ARI_Partsmart8) {
                if(partNumberToRecListMap.containsKey(partInfoObj.PartNumber)) {
                    for(Part__c partRec : partNumberToRecListMap.get(partInfoObj.PartNumber)) {
                        if(partRec.Part_Id__c == (partInfoObj.PartNumber + partsmartToBPVendorCodeMap.get(partInfoObj.Manufacturer))) {
                            partRecordToUse = partRec;
                            break;
                        }
                    }
                }
            } else if(partImportFormat == Constants.Generic_CSV || partImportFormat == Constants.BRP_PICK_LIST) {
                if(partNumberToRecListMap.containsKey(partInfoObj.PartNumber)) {
                    if(partNumberToRecListMap.get(partInfoObj.PartNumber).size() == 1) {
                        partRecordToUse = partNumberToRecListMap.get(partInfoObj.PartNumber)[0];
                    }
                } else if(partUniqueIdToRecMap.containsKey(partInfoObj.PartNumber)) {
                    partRecordToUse = partUniqueIdToRecMap.get(partInfoObj.PartNumber);
                }
            } else if(partImportFormat == Constants.Snap_On_EPC || partImportFormat == Constants.HLSM_CSV) {
                if(partNumberToRecListMap.containsKey(partInfoObj.PartNumber) && partNumberToRecListMap.get(partInfoObj.PartNumber).size() > 0) {
                    if(partNumberToRecListMap.get(partInfoObj.PartNumber).size() > 1) {
                        for(Part__c partRec : partNumberToRecListMap.get(partInfoObj.PartNumber)) {
                            if(string.isNotBlank(partRec.Vendor__r.Name) && string.isNotBlank(partInfoObj.Vendor) && partRec.Vendor__r.Name.containsIgnoreCase(partInfoObj.Vendor)) {
                                partRecordToUse = partRec;
                                break;
                            }
                        }
                    } else {
                        partRecordToUse = partNumberToRecListMap.get(partInfoObj.PartNumber)[0];
                    }
                }
            }
            if(partRecordToUse != null) {
                partInfoObj.PartId = partRecordToUse.Id;
                partInfoObj.Price = partRecordToUse.Retail_Price__c;
                if(!partRecordToUse.Non_Inventory_Part__c && sectionName == Constants.CASH_SALE && partRecordToUse.AvailableParts__c < partInfoObj.Qty) {
                    partInfoObj.AvailableParts = partRecordToUse.AvailableParts__c;
                    partInfoObj.Item = partRecordToUse.Item_Description__c;
                    outOfStockPartList.add(partInfoObj);
                } else {
                    partToInsertList.add(partInfoObj);
                }
            } else {
                partNotInSystemList.add(partInfoObj);
            }
    	}
    	if(partToInsertList.size() > 0) {
    		addPartsInRespectiveSections(partToInsertList, sectionName, sectionHeaderId);
    	}
    	return new Map<String, List<SearchPartDetailWrapper>>{'Out of stock parts' => outOfStockPartList, 
    														'In stock parts' => partToInsertList, 
    														'Parts not found' => partNotInSystemList};
    }
    
    /*
    *   
    */
    public static CustomerDetail.Company getBussinessProfileData() {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
		List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
		CustomerDetail.Company CompanyInfo;
		if(businessProfileList.size() > 0) {
			CompanyInfo = new CustomerDetail.Company(businessProfileList[0]);
		} else {
			CompanyInfo = new CustomerDetail.Company(new Business_Profile__c());
		}
		return CompanyInfo;
    }
    
    public static void addPartsInRespectiveSections(List<SearchPartDetailWrapper> partToInsertList, String sectionName, String sectionHeaderId) {
    	if(sectionName == 'Merchandise' || sectionName == 'Deal Merchandise') {
    		List<COLIWrapper> coliListToInsert = new List<COLIWrapper>();
    		for(SearchPartDetailWrapper partInfoObj : partToInsertList) {
	    		COLIWrapper coliObj = new COLIWrapper(new CO_Line_Item__c(Part__c = partInfoObj.PartId));
	    		coliObj.Qty = partInfoObj.Qty;
	    		coliObj.Price = partInfoObj.Price;
	    		coliObj.DealId = partInfoObj.DealId;
	    		coliListToInsert.add(coliObj);
    		}
    		CustomerOrderCtrl_V2.saveCOLineItem(BPUtility.getEncodedString(sectionHeaderId), BPUtility.getEncodedString(System.JSON.serialize(coliListToInsert)), null);
    		
    	} else {
    		if(sectionName == 'Service Job' || sectionName == 'Deal Service Job') {
	    		ServiceJobService.addMultiplePartsInServiceJob(partToInsertList, sectionHeaderId); 
	    	} else if(sectionName == 'Deal') {
	    		DealService.addMultiplePartsInDeal(partToInsertList, sectionHeaderId);
	    	}
    	}
    }
    
    public class SearchPartDetailWrapper {
    	public String PartNumber;
    	public String Manufacturer;
    	public Decimal Qty;
    	public String PartId;
    	public Decimal Price;
    	public String DealId;
    	public Decimal AvailableParts;
    	public String Item;
        public String Model;
        public Decimal Dealer;
        public Decimal Retail;
        public String Comment;
        public String Description;
        public String Vendor;
    }
    
    public static ProfitabilityWrapper getCOProfitability(String coId) {
    	
    	List<ProfitabilityWrapper.SectionProfitabilityWrapper> profitabilityWrapperList = new List<ProfitabilityWrapper.SectionProfitabilityWrapper>();
    	profitabilityWrapperList.addAll(DealService.getDealProfitability(coId));
    	
    	Map<String, List<ProfitabilityWrapper.SectionProfitabilityWrapper>> sectionTypeToProfitabilityWrapperMap = new Map<String, List<ProfitabilityWrapper.SectionProfitabilityWrapper>>();
    	sectionTypeToProfitabilityWrapperMap.putAll(ServiceJobService.getServiceJobProfitability(coId));
    	Map<String, ProfitabilityWrapper.SectionProfitabilityWrapper> merchTypeToProfitabilityWrapperMap = MerchandiseService.getMerchAndDealMerchProfitability(coId);
    	
    	if(sectionTypeToProfitabilityWrapperMap.containsKey('Service Job')) {
    		profitabilityWrapperList.addAll(sectionTypeToProfitabilityWrapperMap.get('Service Job'));
    	}
    	if(merchTypeToProfitabilityWrapperMap != null && merchTypeToProfitabilityWrapperMap.containsKey('Parts & Accessories')) {
    		profitabilityWrapperList.add(merchTypeToProfitabilityWrapperMap.get('Parts & Accessories'));
    	}
    	if(sectionTypeToProfitabilityWrapperMap.containsKey('Deal Service Job')) {
    		profitabilityWrapperList.addAll(sectionTypeToProfitabilityWrapperMap.get('Deal Service Job'));
    	}
    	if(merchTypeToProfitabilityWrapperMap != null && merchTypeToProfitabilityWrapperMap.containsKey('Deal Merchandise')) {
    		profitabilityWrapperList.add(merchTypeToProfitabilityWrapperMap.get('Deal Merchandise'));
    	}    	
    	ProfitabilityWrapper coProfitabilityObj = new ProfitabilityWrapper(profitabilityWrapperList);
       	return coProfitabilityObj;
    }
    
    /**
     * Name: updateMileageOnUnitsWithSoOdometerOut
     * Desc: Method to update Mileage value on unit records with the Odometer OUT value from the service job; when service jobs are invoiced.
     * @param: soHeaderIdSet - String - Id set of SO headers
     * @return:
    **/
    public static void updateMileageOnUnitsWithSoOdometerOut(Set<Id> soHeaderIdSet) { 	
	 	if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	 	List<Service_Order_Header__c> soHeaderList = [SELECT Id, Odometer_on_Departure__c, Customer_Owned_Unit__r.Is_Generic_Unit__c, Customer_Owned_Unit__r.Mileage_Value__c FROM Service_Order_Header__c 
	 														WHERE Id IN: soHeaderIdSet AND Customer_Owned_Unit__c != null];
	 	
	 	if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	 	Map<String, Customer_Owned_Unit__c> couIdToCOURecMap = new Map<String, Customer_Owned_Unit__c>(); 												
	 	for(Service_Order_Header__c soHeaderRec : soHeaderList) {
            if(!soHeaderRec.Customer_Owned_Unit__r.Is_Generic_Unit__c) {
                Decimal existingUnitMileage = soHeaderRec.Customer_Owned_Unit__r.Mileage_Value__c != null ? soHeaderRec.Customer_Owned_Unit__r.Mileage_Value__c : 0;
                if(soHeaderRec.Odometer_on_Departure__c != null && (soHeaderRec.Odometer_on_Departure__c > existingUnitMileage)) {
                    if(!couIdToCOURecMap.containsKey(soHeaderRec.Customer_Owned_Unit__c)) {
                        couIdToCOURecMap.put(soHeaderRec.Customer_Owned_Unit__c, 
                                            new Customer_Owned_Unit__c(Id = soHeaderRec.Customer_Owned_Unit__c, Mileage_Value__c = soHeaderRec.Odometer_on_Departure__c));
                    } else if(soHeaderRec.Odometer_on_Departure__c > couIdToCOURecMap.get(soHeaderRec.Customer_Owned_Unit__c).Mileage_Value__c) {
                        couIdToCOURecMap.get(soHeaderRec.Customer_Owned_Unit__c).Mileage_Value__c = soHeaderRec.Odometer_on_Departure__c;
                    }
                }
            }
	 	}
	 	
	 	if(couIdToCOURecMap.size() > 0)	{
	 		if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
	 		update couIdToCOURecMap.values();
	 	}									
	 }
	 
	 /**
     * Name: closeCO when last CO item is deleted
     * Desc: Method to closeCO when last CO item is deleted.
     * @param: CoHeaderId - String - Id of Co Header
     * @return:
    **/
    public static String validateAndCloseCO(String coHeaderId) {   
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Invoice_Header__c> coInvoiceHeaderList = [SELECT CO_Header__r.Order_status__c,CO_Header__r.Hide_Merchandise_Section__c, CO_Header__r.Total_Deposit__c, Invoice_Status__c, (Select Id from CO_Invoice_Items__r), Total_Payment__c FROM CO_Invoice_Header__c 
                                                            WHERE CO_Header__c =: coHeaderId Order by CreatedDate Desc limit 2];
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Map<String, CO_Header__c> coHeaderIdToRecMap = new Map<String, CO_Header__c>();
        if(coInvoiceHeaderList.size() == 0 || (coInvoiceHeaderList.size() == 1 && coInvoiceHeaderList[0].Invoice_Status__c != 'Active')) {
    		return coInvoiceHeaderList.size() > 0 ? coInvoiceHeaderList[0].CO_Header__r.Order_status__c : 'Open';
        } else if(coInvoiceHeaderList.size() > 1 && coInvoiceHeaderList[0].CO_Header__r.Total_Deposit__c == 0) {
        	for(CO_Invoice_Header__c coInvRec : coInvoiceHeaderList) {
        		if(coInvRec.Invoice_Status__c == 'Active' && coInvRec.CO_Invoice_Items__r.size() == 0 && coInvRec.Total_Payment__c == 0) {
        			if(coInvRec.CO_Header__r.Hide_Merchandise_Section__c){
        			    coHeaderIdToRecMap.put(coHeaderId, new CO_Header__c(Id= coHeaderId, Order_status__c = 'Closed'));
                    } else {
                        coHeaderIdToRecMap.put(coHeaderId, new CO_Header__c(Id= coHeaderId, Order_status__c = 'Closed', Merchandise_Status__c = 'Invoiced'));
                    }
        		}
        	}
        }
        List<CO_Header__c> coHeaderList = [SELECT (Select Status__c from Deals__r) FROM CO_Header__c WHERE Id =: coHeaderId ];
        if(coHeaderList.size() > 0 ) {
        	for(CO_Header__c coHeaderRec : coHeaderList) {
        		if(coHeaderRec.Deals__r.size() > 0 && coHeaderRec.Deals__r[0].Status__c != 'Invoiced' && coHeaderIdToRecMap.size() > 0 && coHeaderIdToRecMap.containsKey(coHeaderRec.Id)) {
        			coHeaderIdToRecMap.get(coHeaderRec.Id).Order_status__c = 'Open';
                }
        	}
        }
        if(coHeaderIdToRecMap.size() > 0) {
            DMLUtility.updateSobjectList('CO_Header__c', coHeaderIdToRecMap.values());
        	return coHeaderIdToRecMap.get(coHeaderId).Order_status__c;
        }
        return coInvoiceHeaderList.size() > 0 ? coInvoiceHeaderList[0].CO_Header__r.Order_status__c : 'Open';
     }
     
     public static BrandingLocationWrapper getBrandingLocationDataForPrint(String brandingLocationId) {
     	BrandingLocationWrapper brandingLocationObj = new BrandingLocationWrapper();
     	if(String.isBlank(brandingLocationId)) {
        	List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
        	brandingLocationObj.setDefaultBrandingLocation((businessProfileList.size() > 0 ? businessProfileList[0] : new Business_Profile__c()));
        } else {
	     	for(Branding_Location__c brandingLocRec: BrandingLocationSOQLUtil.getBrandingLocationDetailListByFilter(new Map<String, String>{'Id' => brandingLocationId})) {
	     		brandingLocationObj.setAllBrandingLocationFields(brandingLocRec);
	     	}
        }
    	
    	return brandingLocationObj;
     }
     
    private static void transferPaymentsAndDepositToActiveInvHeader(String currentCheckoutType, String closedInvHeaderId, String activeInvHeaderId, Boolean isDealInvoiced) {
        List<CO_Invoice_Header__c> coInvoiceList= new List<CO_Invoice_Header__c>();
        List<CO_Invoice_Payment__c> coInvoicePayments = new List<CO_Invoice_Payment__c>();
        List<CO_Deposit__c> coDepositList = new List<CO_Deposit__c>();
        if(!currentCheckoutType.equalsIgnoreCase('Customer')) {
            coInvoiceList = [Select Id, (Select Id, CO_Invoice_Header__c From CO_Invoice_Payments__r) , (Select Id, CO_Invoice_Header__c from CO_Deposits__r) 
                                 From CO_Invoice_Header__c where Id =: closedInvHeaderId];
            
        } else if(!isDealInvoiced){
            coInvoiceList = [Select Id, (Select Id, CO_Invoice_Header__c from CO_Invoice_Payments__r where Deposit_Payment_Method__c = 'Financing'),
                             (Select Id, CO_Invoice_Header__c from CO_Deposits__r where Payment_Method__c = 'Financing') From CO_Invoice_Header__c where Id = :closedInvHeaderId];
        }
            
        for(CO_Invoice_Header__c coInvoiceRec : coInvoiceList){
            for(CO_Invoice_Payment__c invPaymentRec: coInvoiceRec.CO_Invoice_Payments__r){
                invPaymentRec.CO_Invoice_Header__c = activeInvHeaderId;
                coInvoicePayments.add(invPaymentRec);
            }
            for(CO_Deposit__c coDepositRec : coInvoiceRec.CO_Deposits__r) {
                coDepositRec.CO_Invoice_Header__c = activeInvHeaderId;
                coDepositList.add(coDepositRec);
            }
        }

        if(coInvoicePayments.size() > 0) {
            if(AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            COInvoiceTriggerHelper.isForceStopTrigger = true;
            update coInvoicePayments;
            COInvoiceTriggerHelper.isForceStopTrigger = false;
        }

        if(coDepositList.size() > 0) {
            DMLUtility.updateSobjectList('CO_Deposit__c', coDepositList);
        }
    }

    public static void savePartPickListCOLI(String recordJSON) {
        PartPickListCOLIWrapper partPickWrapperRec = (PartPickListCOLIWrapper) System.JSON.deserialize(recordJSON, PartPickListCOLIWrapper.class);
        if(partPickWrapperRec.IsSublet) {
            VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
            update new Vendor_Order_Line_Item__c(Id = partPickWrapperRec.CoLineItemId, Pulled__c = partPickWrapperRec.Pulled);
            VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
        } else {
            COLineItemTriggerHelper.isForceStopTrigger = true;
            update new CO_Line_Item__c(Id = partPickWrapperRec.CoLineItemId, Pulled__c = partPickWrapperRec.Pulled);
            COLineItemTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    public static Set<String> getCustomerOrderPartIds(Set<String> coIdSet) {
        Set<String> partIdSet = new Set<String>();
        List<CO_Line_Item__c> coLineItems = [SELECT ID, Part__c FROM CO_Line_Item__c WHERE Part__c != null AND CO_Header__c IN : coIdSet];
        for(CO_Line_Item__c coLineItem : coLineItems) {
            partIdSet.add(coLineItem.Part__c);
        }

        List<Option_fee__c> optionFeeParts = [SELECT ID, Part__c FROM Option_fee__c WHERE Part__c != null AND Deal_Item__r.Deal__r.CO_Header__c IN :coIdSet];
        for(Option_fee__c optionFeePart : optionFeeParts) {
            partIdSet.add(optionFeePart.Part__c);
        }
        return partIdSet;
    }
    
    public static String getActiveCOCountByCustomerId(String customerId) {
    	String query = 'SELECT Count(Id) COCount FROM CO_Header__c WHERE Customer__c = \''+ BPUtility.escapeSingleQuotes(customerId) + '\' AND Order_Status__c != \'Closed\'';
    	List<AggregateResult> aggList = SOQLUtility.getQueryResults('CO_Header__c', query);
    	return String.valueOf((aggList.size() > 0) ? (Integer) aggList[0].get('COCount') : 0);
    }

    public static Boolean isARCreditsAlreadyAdded(Set<String> arCreditAccIdSet) {
        List<CO_Invoice_Payment__c> coInvPaymentList = [SELECT Id FROM CO_Invoice_Payment__c WHERE AccountingIdForJournalEntry__c = null 
            AND Xero_Accounting_Id__c = null AND Payment_Method__c =: Constants.AR_CREDIT AND AR_Credit_Accounting_Id__c IN: arCreditAccIdSet];
        
        if(coInvPaymentList.size() > 0) {
            return true;
        }
        
        List<CO_Deposit__c> coDepositList = [SELECT Id FROM CO_Deposit__c WHERE AccountingIdForJournalEntry__c = null 
            AND Xero_Accounting_Id__c = null AND Payment_Method__c =: Constants.AR_CREDIT AND AR_Credit_Accounting_Id__c IN: arCreditAccIdSet];
        
        if(coDepositList.size() > 0) {
            return true;
        }
        return false;
    }

    public static String convertListIntoString(List<String> strList) {
        String returnStr = '';
        if(strList.size() == 0) returnStr = null;
        for(String str : strList) {
            str = (str.contains('\n')) ? str.replaceAll('\n', '') : str;
            returnStr += (str != null ? (str + '\n') : '');
        }
        return returnStr;
    }

    public static void addInternalCommentToCO(String coHeaderId, String comment) {
        InternalCommentWrapper commentObj = new InternalCommentWrapper();
        commentObj.CoHeaderId = coHeaderId;
        commentObj.Comment = comment;
        InternalCommentService.saveInternalCommentOnCO(system.JSON.serialize(commentObj));
    }

    public static String createCO(String customerId, String sellingGroup, Boolean isPreventMerchSectionCreation) {  
		if(String.isNotBlank(sellingGroup)) {
            CO_Header__c coHeaderToInsert = new CO_Header__c();
            coHeaderToInsert.Order_status__c = 'Open';
            coHeaderToInsert.Hide_Merchandise_Section__c = true;
            coHeaderToInsert.Owner__c = UserInfo.getUserId();
            coHeaderToInsert.Selling_Group__c = sellingGroup;
            coHeaderToInsert.CO_Type__c = BPGlobalHeaderCtrl.customerTypeSellingGroupSet.contains(sellingGroup) ? 'Customer' : sellingGroup;
            coHeaderToInsert.Transaction_Type__c = SOQLUtil.getDefaultPartSaleTransactionTypeId();
            if(AccessControl.ifObjectFieldIsCreateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            coHeaderToInsert.Customer__c = customerId;
            DMLUtility.insertSobjectList('CO_Header__c', coHeaderToInsert);
            
            if(sellingGroup.equalsIgnoreCase('Service Order')) {
                ServiceJobService.createServiceJobWithSpecificFields(coHeaderToInsert.Id, null, null, true, true);
            }
            return coHeaderToInsert.Id;
        }
        return null;
	}

    public static Map<String, Object> getCOBasicInfo(String coHeaderId, String sellingGroup) {
        Map<String, Object> infoMap = new Map<String, Object>();
        if(String.isNotBlank(coHeaderId) && String.isNotBlank(sellingGroup)) {
            infoMap.put('COHeaderId', coHeaderId);
            if(sellingGroup.equalsIgnoreCase('Service Order')) {
                for(Service_Order_Header__c soRec : [Select Id, Name__c, Customer_Owned_Unit__c, Transaction_Type__r.Code_Label__c, SO_Status__c, SO_Status_Ref__c, 
                    CO_Header__r.Customer__r.Name, CO_Header__r.CO_Type__c, CO_Header__r.Customer__c FROM Service_Order_Header__c where CO_Header__c = :coHeaderId LIMIT 1]) {
                    if(soRec.CO_Header__r.Customer__c != null) {
                        infoMap.put('COType', soRec.CO_Header__r.CO_Type__c);
                        infoMap.put('CustomerId', soRec.CO_Header__r.Customer__c);
                        infoMap.put('CustomerName', soRec.CO_Header__r.Customer__r.Name);
                    }
                    infoMap.put('ServiceJobDetails', new ServiceOrderWrapper.SOWrapper(soRec, true));
                }
            } else if(sellingGroup.equalsIgnoreCase('Unit Deal')) {
                for(Deal__c dealRec : [Select Id, Type__c, CO_Header__c, Status__c, (Select Id from Deal_Items__r), 
                    CO_Header__r.Customer__r.Name, CO_Header__r.CO_Type__c, CO_Header__r.Customer__c FROM Deal__c where CO_Header__c = :coHeaderId LIMIT 1]) {
                    if(dealRec.CO_Header__r.Customer__c != null) {
                        infoMap.put('COType', dealRec.CO_Header__r.CO_Type__c);
                        infoMap.put('CustomerId', dealRec.CO_Header__r.Customer__c);
                        infoMap.put('CustomerName', dealRec.CO_Header__r.Customer__r.Name);
                    }
                    infoMap.put('DealDetails', new DealWrapper(dealRec, true));
                }
            }
        }
        return infoMap;
    }

    public static void updateStockOrStockExcessOrders(List<Vendor_Order_Line_Item_Group__c> voligList, Decimal requiredQty, List<Vendor_Order_Line_Item__c> voLineItemListToUpdate) {
        /* Approach: 
            - If required qty on CO is grater than unreceived Stock item then delete it 
            - or else update items by subtracting required qty
        */
        List<Vendor_Order_Line_Item__c> voLineItemListToDelete = new List<Vendor_Order_Line_Item__c>();
        Map<Id, Decimal> voLineItemIdToQtyMap = new Map<Id, Decimal>();

        for(Vendor_Order_Line_Item_Group__c voligRec : voligList) {
            for(Vendor_Order_Line_Item__c voliRec : voligRec.Vendor_Order_Line_Items__r) {
                /* Check if required qty is grater than or equals to vo stock or stock excess items
                    - If yes than delete vo line item
                    - else update vo line item by subtracting required qty
                */
                if(requiredQty <= 0) break;
                
                if(requiredQty < voliRec.Qty_Needed__c) {
                    // Create a map of vo stock or stock excess item to qty for update
                    voLineItemIdToQtyMap.put(voliRec.Id, voliRec.Qty_Needed__c - requiredQty);
                } else {
                    // add vo stock or stock excess item to delete
                    voLineItemListToDelete.add(voliRec);
                }
                requiredQty -= voliRec.Qty_Needed__c;
            }
            if(requiredQty <= 0) break;
        }

        // delete vo stock or stock excess items 
        DMLUtility.deleteSobjectList('Vendor_Order_Line_Item__c', voLineItemListToDelete);

        // update vo stock or stock excess items
        for(Id voLineItemId: voLineItemIdToQtyMap.keySet()) {
            voLineItemListToUpdate.add(new Vendor_Order_Line_Item__c(id = voLineItemId, Qty_Needed__c = voLineItemIdToQtyMap.get(voLineItemId), Received__c = 0));
        }
    }

    public static void addRequiredVOLineItemsToVO(String coliId, String voHeaderId, String voNumber, String voliGroup, List<Vendor_Order_Line_Item__c> voLineItemListToUpdate) {
        // get required vo line item for coli and add to vo header
        for(Vendor_Order_Line_Item__c voliRec : [SELECT Id FROM Vendor_Order_Line_Item__c WHERE CO_Line_Item__c =: coliId AND CO_Line_Item__r.Status__c = 'Required' ORDER BY createdDate DESC LIMIT 1]) {
            voliRec.Vendor_Order_Header__c = voHeaderId;
            voliRec.Vendor_Order_Line_Item_Group__c = voliGroup;
            voliRec.Received__c = 0;
            voLineItemListToUpdate.add(voliRec);
        }
        DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voLineItemListToUpdate);
		update new CO_Line_Item__c(Id = coliId, Status__c = 'Ordered', VO_Status__c = 'On Order', Vendor_Order_Header__c = voHeaderId, VO_Number__c = voNumber);
    }

    public static String updateUnitDetails(String jsonString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        UnitWrapper.UnitInfoWrapper unitObj = (UnitWrapper.UnitInfoWrapper) System.JSON.deserialize(jsonString, UnitWrapper.UnitInfoWrapper.class);
        Customer_Owned_Unit__c couRec = new Customer_Owned_Unit__c(Id = unitObj.Id, Plate__c = unitObj.Plate, 
                                            Reg_Expiry_Date__c = null));
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', couRec);
        return 'Success';
    }

    public static void updateMerchServiceSOStatus(String coHeaderId) {
        if(String.isNotBlank(coHeaderId)) {
            COSectionDetailService.setSectionStatus_future(new Set<Id>{coHeaderId});
        }
    }
    
    public static Map<String, Object> getCOSpecificSettings() {
        Map<String, Object> coSettingNameToValueMap = new Map<String, Object>();
        coSettingNameToValueMap.put('TechnicianHoursMethodOnJobs', Configurations__c.getOrgDefaults().Technician_Hours_Method_On_Jobs__c);
        return coSettingNameToValueMap;
    }

    public static CustomerOrderWrapper.COHeader getCOHeaderTotals(String coHeaderId) {
        CustomerOrderWrapper.COHeader coHeaderObj = new CustomerOrderWrapper.COHeader();
        if(String.isNotBlank(coHeaderId)) {
            for(CO_Header__c coRec : [Select Id, Order_Total__c, Invoiced_Amount__c, Uninvoiced_Amount__c, Total_Payment__c 
            FROM CO_Header__c WHERE Id =: coHeaderId]) {
                
            }
        }
        return coHeaderObj;
    }

    public class COSectionTaxDetailWrapper {
        public String SOHeaderId;
        public String COHeaderId;
        public String DealId;
        public Boolean IsOverrideTax;
        public String ApplicableTaxId;
        public String OverrideTaxApplicableOn;
        public Boolean IsTaxBasedOnCustomerAddress;
    }

    public static void reactivateCustomerOrder(String coId) {
        if(String.isNotBlank(coId)) {
            COTriggerHelper.isForceStopTrigger = true;
            update new CO_Header__c(Id = coId, Is_Archived__c = false, Archived_Date_Time__c = null);
            COTriggerHelper.isForceStopTrigger = false;
        }
    }

    /* Methods moved from CustomerOrderCtrl */
    public static void AddPartToPartMap( Map<Id,Part__c> updateStockedMap, Map<Id,Part__c> updateStockBucketMap ,decimal QuantityNeed,decimal quantityComitted ,Part__c PartRecordObj , List<Part__c> PartForPartReturnBuckets  ,decimal PartReturnPrice,decimal qtyOverSold){
        if(AccessControl.ifObjectFieldIsCreateable('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        
        Part__c PartRecord = PartRecordObj.clone(false, false, false, false);
        PartRecord.Id = PartRecordObj.Id;  
        if(!(updateStockedMap.containsKey(PartRecordObj.Id))){ 
            updateStockedMap.put(PartRecordObj.Id,PartRecordObj);
        }
        
        if(QuantityNeed > 0 ) {
            if(qtyOverSold > 0){
                quantityComitted = quantityComitted - qtyOverSold;
            }
            updateStockedMap.get(PartRecordObj.Id).Qty_Committed__c = updateStockedMap.get(PartRecordObj.Id).Qty_Committed__c - quantityComitted;
            if(updateStockBucketMap.containsKey(PartRecordObj.Id)) {
                updateStockBucketMap.get(PartRecord.Id).Qty_In_Stock__c = updateStockBucketMap.get(PartRecord.Id).Qty_In_Stock__c + quantityComitted;
                updateStockBucketMap.get(PartRecord.Id).Qty_Committed__c = updateStockBucketMap.get(PartRecord.Id).Qty_Committed__c + quantityComitted;
                updateStockBucketMap.get(PartRecord.Id).Oversold_Qty__c = updateStockBucketMap.get(PartRecord.Id).Oversold_Qty__c + qtyOverSold;
                
            } else {
                updateStockBucketMap.put(PartRecord.Id,PartRecord);
                updateStockBucketMap.get(PartRecord.Id).Qty_In_Stock__c = quantityComitted;
                updateStockBucketMap.get(PartRecord.Id).Qty_Committed__c = quantityComitted;
                updateStockBucketMap.get(PartRecord.Id).Oversold_Qty__c = qtyOverSold;
            }
        } else {
            updateStockedMap.get(PartRecordObj.Id).Qty_In_Stock__c = updateStockedMap.get(PartRecordObj.Id).Qty_In_Stock__c - QuantityNeed;
            part__c partRecForBucket  = new part__c( Id = PartRecord.Id,Qty_In_Stock__c =  - (QuantityNeed!=null ? QuantityNeed : 0), Last_Cost__c =  PartReturnPrice, Description__c ='Part Return');
            PartForPartReturnBuckets.add(partRecForBucket);  
        }
    }

    public static void createStoreCredit(List<Id> coDepositIdList){
        List<CO_Deposit__c> coDepositList = [select Id, CO_Header__r.Customer__c,
                                                        Payment_Method__c, Amount__c
                                                        from CO_Deposit__c
                                                        where Id IN : coDepositIdList]; 
        List<Store_Credit__c> storeCreditListToInsert = new List<Store_Credit__c>();
        Store_Credit__c storeCreditObj;
        for(CO_Deposit__c deposit : coDepositList){ 
            if(deposit.Payment_Method__c == 'Store Credit'){
                if(deposit.CO_Header__r.Customer__c == null){
                    deposit.addError('Store Credit can be used for Customer Only'); 
                }else{
                    storeCreditObj = new Store_Credit__c();
                    storeCreditObj.Customer__c = deposit.CO_Header__r.Customer__c;
                    storeCreditObj.Amount__c = -1 * deposit.Amount__c;
                    storeCreditObj.Reference__c = 'Order Deposit';
                    storeCreditObj.CO_Header__c = deposit.CO_Header__c;
                    storeCreditListToInsert.add(storeCreditObj);
                }
            }
        }
        DMLUtility.insertSobjectList('Store_Credit__c', storeCreditListToInsert);
    }

    /**
    * Name: InsertSuppressLineItem
    * Desc: Method Which saves CO Line Items in Database 
    * @return: void 
    **/
    public static void insertSuppressLineItem(String coHeaderId, String partId){
        if(coHeaderId != null &&  partId != null){
            Suppress_CO_Item__c SuppressCoItemRec = new Suppress_CO_Item__c(CO_Header__c = coHeaderId, Part__c = partId, User__c = UserInfo.getUserId());
            if(AccessControl.ifObjectFieldIsCreateable('Suppress_CO_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert SuppressCoItemRec;
        }
    }

    public static Boolean isDuplicatePartOnCO(String coHeaderId, String partId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        
        //Analysis : Limit in each query for size chk
        List<CO_Header__c> coHeaderList = [Select Id, (Select Id from CO_Line_Items__r where Part__c =: partId LIMIT 1), (Select Id from Deals__r) from CO_Header__c where Id =: coHeaderId];
        if(coHeaderList.size() > 0) {
            if(coHeaderList[0].CO_Line_Items__r.size() > 0) {
                return true;
            }
            if(coHeaderList[0].Deals__r.size() > 0) {
                List<Deal_Item__c> dealItemList = [Select Id, (Select Id from Options_Fees__r where Part__c =: partId LIMIT 1) from Deal_Item__c where Deal__c =: coHeaderList[0].Deals__r[0].Id];
                for(Deal_Item__c dealItemRec : dealItemList) {
                    if(dealItemRec.Options_Fees__r.size() > 0) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
    * Name: isSuppressLineItemOnCO
    * Desc: Method Which saves CO Line Items in Database 
    * @param:   (1) coHeaderId - String - CO Header record Id
    *           (2) partId - String - JSON String of CO Line Items
    * @return: String - JSON String of CO Header Detail Record
    **/
    public static boolean isSuppressLineItemOnCO(String coHeaderId, String partId){
        if(AccessControl.ifObjectFieldIsAccessible('Suppress_CO_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Suppress_CO_Item__c> suppressCOItemList = [SELECT Id FROM Suppress_CO_Item__c where CO_Header__c =: coHeaderId 
                                                                    AND Part__c =: partId AND User__c =: UserInfo.getUserId()];   
        return (suppressCOItemList.size() > 0);
    }

    public static String showHistoryOnSuppressPopup(String partId, String coHeaderId) {
        partId = BPUtility.getDecodedString(partId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        if(AccessControl.ifObjectFieldIsAccessible('Option_Fee__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        
        List<DuplicatePartWrapper> duplicatePartList = new List<DuplicatePartWrapper>(); 
        List<CO_Line_Item__c> coliList = [Select Id, Qty__c, Service_Order_Line_Item__c, Deal__c,
                                                Service_Order_Line_Item__r.Service_Order_Header__r.Name__c, Service_Order_Line_Item__r.Qty_Needed__c
                                                 from CO_Line_Item__c where Part__c =: partId
                                                AND CO_Header__c =: coHeaderId ];
        for(CO_Line_Item__c coliRec : coliList) {
            duplicatePartList.add(new DuplicatePartWrapper(coliRec));
        }
        
        List<Option_Fee__c> optionFeeList = [Select Qty__c, Deal_Item__c, Deal_Item__r.Name__c
                                                 from Option_Fee__c where Part__c =: partId
                                                AND Deal_Item__r.Deal__r.CO_Header__c =: coHeaderId
                                                AND Deal_Item__r.Deal__r.Status__c = 'Quotation'];
        for(Option_Fee__c optionFeeRec : optionFeeList) {
            duplicatePartList.add(new DuplicatePartWrapper(optionFeeRec));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(duplicatePartList));
        
    }

    public static String deleteCustomerOrder(String coHeaderId){
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
    	if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
    	if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        
        List<CO_Header__c> coHeaderList = [SELECT Status__c,
        										(select Id from Tax_Exemptions__r),
                                            	(select Id from CO_Line_Items__r limit 1),
                                            	(select Id from Service_Order_Headers__r limit 1),
                                            	(select Id from Deals__r limit 1),
                                            	(select Amount__c from CO_Deposits__r WHERE Amount__c != null),
                                            	(select Id from CO_Invoice_Headers__r where Invoice_Status__c = 'Closed' limit 1)
                                            FROM CO_Header__c
                                            WHERE Id =: coHeaderId];
                                            
        List<CO_Invoice_Payment__c> paymentList = [SELECT Amount__c from CO_Invoice_Payment__c 
        													WHERE CO_Invoice_Header__r.CO_Header__c =: coHeaderId AND Amount__c != null];                         
        
        String response = 'Error';
        if(coHeaderList.size() > 0) {
            Decimal totalCoDeposits = 0;
            for(CO_Deposit__c coDeposit : coHeaderList[0].CO_Deposits__r) {
                totalCoDeposits += coDeposit.Amount__c;
            }
            
            Decimal totalCoPayments = 0;
            for(CO_Invoice_Payment__c coPaymentRec : paymentList) {
                totalCoPayments += coPaymentRec.Amount__c;
            }
            
	        if(paymentList.size() > 0 && totalCoPayments > 0) {
	            response = 'Error';
	        } else if(coHeaderList[0].Status__c == 'Open' 
                && coHeaderList[0].CO_Line_Items__r.size() == 0
                && coHeaderList[0].Service_Order_Headers__r.size() == 0
                && coHeaderList[0].Deals__r.size() == 0) {
                if(!coHeaderList[0].CO_Deposits__r.isEmpty() || !paymentList.isEmpty()) {
                    DMLUtility.updateSobjectList('CO_Header__c', new CO_Header__c(Id = coHeaderId, Order_status__c = 'Closed'));
                    response = 'Closed';
                } else if((coHeaderList[0].CO_Deposits__r.size() == 0 || totalCoDeposits == 0)
                && coHeaderList[0].CO_Invoice_Headers__r.size() == 0
                && (paymentList.size() == 0 || totalCoPayments == 0)) {
                    InternalCommentService.deleteInternalCommentsFromCO(coHeaderId);
                    if(coHeaderList[0].Tax_Exemptions__r.size() > 0) {
                        if(AccessControl.ifObjectIsDeletable('Tax_Exemption__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                        delete coHeaderList[0].Tax_Exemptions__r;
                    }
                    
                    CO_Header__c coHeaderRec = new CO_Header__c(Id = coHeaderId);
                    if(AccessControl.ifObjectIsDeletable('CO_Header__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE);}
                    delete coHeaderRec;
                    response = 'Success';
                }
            }   
        }
        return BPUtility.getEncodedString(response);
    }

    private static void getSuperSesionPartIds(Part__c activePart, Part__c partRec, Map<String, Integer> partIdToSupersessionLevelMap) {
    	Integer maxParentQueryLevel = 5;
    	for(Integer i = 0; i < maxParentQueryLevel; i++) {
    		if(partRec != null && partRec.Is_Superseded__c && partRec.Superseded_To__c != null && partRec.Superseded_To__c != activePart.Id 
    					&& !partIdToSupersessionLevelMap.containsKey(partRec.Superseded_To__c)) {
    			partIdToSupersessionLevelMap.put(partRec.Superseded_To__c, partIdToSupersessionLevelMap.size() + 1);
    			
    			if(i == (maxParentQueryLevel - 1)) {
    				partRec = new Part__c(Id = partRec.Superseded_To__c);
    			} else {
    				partRec = partRec.Superseded_To__r;
    			}
    		} else {
    			partRec = null;
    			break;
    		}
    	}
    	
    	if(partRec != null) {
    		partRec = [Select Id, Is_Superseded__c, Superseded_To__c, 
    				Superseded_To__r.Is_Superseded__c, Superseded_To__r.Superseded_To__c, 
    				Superseded_To__r.Superseded_To__r.Is_Superseded__c, Superseded_To__r.Superseded_To__r.Superseded_To__c, 
    				Superseded_To__r.Superseded_To__r.Superseded_To__r.Is_Superseded__c, Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__c, 
    				Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Is_Superseded__c, Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__c 
    				from Part__c where Id =: partRec.Id LIMIT 1];
    		getSuperSesionPartIds(activePart, partRec, partIdToSupersessionLevelMap);
    	}
    	
    }
    
    private static List<PartAlternateWrapper> getSupersededPartAlternateList(Map<String, Integer> partIdToSupersessionLevelMap) {
    	List<PartAlternateWrapper> partAlternateList = new List<PartAlternateWrapper>();
    	
    	if(partIdToSupersessionLevelMap.size() > 0) {
    		partIdToSupersessionLevelMap.remove(null);
    		List<Part__c> partList = [Select Id, Item_Description__c, Vendor__r.Vendor_Code__c, AvailableParts__c, Retail_Price__c 
    				from Part__c where Id IN :partIdToSupersessionLevelMap.keySet()];
    		
    		for(Part__c partRec : partList) {
    			Integer priorityIndex = partIdToSupersessionLevelMap.get(partRec.Id);
    			String relation = 'Superseded To' + (priorityIndex > 1 ? ' #' + priorityIndex : '');
    			Boolean isSelected = (priorityIndex == partIdToSupersessionLevelMap.size()) ? true : false;
    			partAlternateList.add(new PartAlternateWrapper(partRec, priorityIndex, relation, isSelected));
    		}
    	}
    	partAlternateList.sort();
    	return partAlternateList;
    }

    public static String closeOrder(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType, String invoiceDate){
        try {
            COService.finalizeOrder(coInvoiceItemsJsonString, coHeaderId, currentCheckoutType, invoiceDate);
            return '';
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    public static String closeInvoice(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType, String invoiceDateString){
        return COService.finalizeInvoice(coInvoiceItemsJsonString, coHeaderId, currentCheckoutType, invoiceDateString);
    }

    /**
    * Name: saveCODeposit
    * Desc: Method to save CO Deposits in database
    * @param:  (1) jsonString - String - jsonString of CO Deposits which is to be saved.
    * @return: String - JSON String of all CO Deposits 
    **/
    public static String saveCODeposit(String jsonString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        List<CODeposit> coDepositObjList = CODeposit.parse(jsonString);
        String response = saveCODeposit(coDepositObjList);
        if(coDepositObjList[0].PaymentMethod.equalsIgnoreCase(PreferredPaymentService.PREFERRED_PAYMENTS) && response != null) {
            try {
                ResponseWrapper responseObj = (ResponseWrapper) System.JSON.deserialize(response, ResponseWrapper.class);
                if(responseObj.responseStatus.equalsIgnoreCase('Error')) {
                    return BPUtility.getEncodedString(response);
                }
            } catch(Exception exp) {}
        } else if(String.isNotBlank(response) && coDepositObjList.size() > 0 && coDepositObjList[0].PaymentMethod == Constants.AR_CREDIT) {
            return response;
        }
        return getCODepositByCOHeaderId(BPUtility.getEncodedString(response));
    }

    /**
     * Name: getCODepositByCOHeaderId
     * Desc: Method to get CO Deposits from CO Header Record Id
     * @param:  (1) coHeaderId - String - CO Header record Id
     * @return: String - JSON String of all CO Deposits 
     **/
    public static String getCODepositByCOHeaderId(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try{
            List<CO_Deposit__c> coDeposits = SOQLUtil.getCODepositByCOHeaderId(coHeaderId);
            List<CODeposit> coDepositObjList = new List<CODeposit>();
            for(CO_Deposit__c coDepositRec : coDeposits) {
                coDepositObjList.add(new CODeposit(coDepositRec));
            }
            return BPUtility.getEncodedString(System.JSON.serialize(coDepositObjList));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    public static String getAlternatePartsList(String partId) {
        partId = BPUtility.getDecodedString(partId);
        List<Part_Alternates__c> alternatePartsList = [SELECT Part_ID__r.Is_Superseded__c, Part_ID__r.Superseded_To__c, 
					Part_ID__r.Superseded_To__r.Is_Superseded__c, Part_ID__r.Superseded_To__r.Superseded_To__c, 
					Part_ID__r.Superseded_To__r.Superseded_To__r.Is_Superseded__c, Part_ID__r.Superseded_To__r.Superseded_To__r.Superseded_To__c, 
					Part_ID__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Is_Superseded__c, Part_ID__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__c, 
					Part_ID__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Is_Superseded__c, Part_ID__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__r.Superseded_To__c, 
					Alternate_Part_ID__c, Relation__c FROM Part_Alternates__c
                        WHERE Part_ID__c = :partId
                            AND (Relation__c = 'Replaces' OR Relation__c = 'Alternate' OR Relation__c = 'Replaced By')];
                            
        Map<String, String> partIdToRelationMap = new Map<String, String>();
        partIdToRelationMap.put(partId, 'Actual');
        
        Part__c activePart;
        for(Part_Alternates__c alterPart : alternatePartsList){
        	if(alterPart.Relation__c == 'Replaced By') { 
        		activePart = alterPart.Part_ID__r;
        	} else {
            	partIdToRelationMap.put(alterPart.Alternate_Part_ID__c, alterPart.Relation__c);
        	}
        }
        
        Part__c partRec = [SELECT SKU_Number__c, Mfg_Part__c, Part_Number__c from Part__c WHERE Id =: partId];
        List<Part__c> matchedParts = [SELECT Part_Number__c, Item_Description__c, Vendor__r.Vendor_Code__c, AvailableParts__c, 
                                        Retail_Price__c, Mfg_Part__c, SKU_Number__c FROM Part__c
                                        WHERE Id IN :partIdToRelationMap.keySet()
                                            OR (Part_Number__c = :partRec.SKU_Number__c AND Part_Number__c != null) 
                                            OR (Part_Number__c = :partRec.Mfg_Part__c AND Part_Number__c != null) 
                                            OR (SKU_Number__c = :partRec.SKU_Number__c AND SKU_Number__c != null) 
                                            OR (Mfg_Part__c = :partRec.Mfg_Part__c AND Mfg_Part__c != null)
                                            OR (Part_Number__c =: partRec.Part_Number__c AND Part_Number__c != null)];  
                                                                                            
        List<PartAlternateWrapper> partAlternateList = new List<PartAlternateWrapper>();
        
        //Get supersession parts
    	Map<String, Integer> partIdToSupersessionLevelMap = new Map<String, Integer>();
	    if(activePart != null) {
	    	getSuperSesionPartIds(activePart, activePart, partIdToSupersessionLevelMap); 
	        List<PartAlternateWrapper> supersededPartList = getSupersededPartAlternateList(partIdToSupersessionLevelMap);
	        if(supersededPartList != null && supersededPartList.size() > 0) {
	        	partAlternateList.addAll(supersededPartList);
	        }
        }
        
        Integer priorityIndex = 0;
        String relation = '';
        Boolean isSelected;
        for(Part__c part : matchedParts){
            isSelected = false;
            if(part.Id == partId){
                priorityIndex = 0;
                relation = 'Active Part';
                isSelected = partIdToSupersessionLevelMap.size() == 0 ? true : false;
            }else if(partIdToRelationMap.containsKey(part.Id) && partIdToRelationMap.get(part.Id) == 'Replaces'){
                priorityIndex = partIdToSupersessionLevelMap.size() + 1;
                relation = 'Replaces';
            }else if(partIdToRelationMap.containsKey(part.Id) && partIdToRelationMap.get(part.Id) == 'Alternate'){
                priorityIndex = partIdToSupersessionLevelMap.size() + 2;
                relation = 'Alternate';
            }else if(part.Part_Number__c == partRec.Part_Number__c){
                priorityIndex = partIdToSupersessionLevelMap.size() + 3;
                relation = 'Other Vendor';
            }else if(part.Part_Number__c == partRec.Mfg_Part__c){
                priorityIndex = partIdToSupersessionLevelMap.size() +  4;
                relation = 'Actual MFG Part#';
            }else if(part.Part_Number__c == partRec.SKU_Number__c){
                priorityIndex = partIdToSupersessionLevelMap.size() +  5;
                relation = 'Actual SKU #';
            }else if(part.Mfg_Part__c == partRec.Mfg_Part__c){
                priorityIndex = partIdToSupersessionLevelMap.size() +  6;
                relation = 'Same MFG Part#';
            }else if(part.SKU_Number__c == partRec.SKU_Number__c){
                priorityIndex = partIdToSupersessionLevelMap.size() +  7;
                relation = 'Same SKU #';
            }else{
                priorityIndex = partIdToSupersessionLevelMap.size() + 8;
                relation = 'Other relation'; 
            }
            partAlternateList.add(new PartAlternateWrapper(part, priorityIndex, relation, isSelected));
        }
        partAlternateList.sort();
        return BPUtility.getEncodedString(System.JSON.serialize(partAlternateList));
    }

    /* Methods moved from CustomerOrderCtrl */
    
    public static void addDefaultSalespersonToCOSection(String sectionId) {
        addDefaultSalespersonToCOSection(sectionId, null, null);
    }

    public static void saveCOContactAndShippingAddressInfo(String coJson) {
        if(String.isNotBlank(coJson)) {
            COContactWrapper coContactObj = (COContactWrapper) System.JSON.deserialize(coJson, COContactWrapper.class);
            if(String.isNotBlank(coContactObj.COHeaderId)) {
                CO_Header__c coHeaderRec = new CO_Header__c(Id = coContactObj.COHeaderId);
                if(String.isNotBlank(coContactObj.SelectedCustomerContactId)) {
                    coHeaderRec.Customer_Contact__c = coContactObj.SelectedCustomerContactId;
                }
                if(String.isNotBlank(coContactObj.SelectedShippingAddressId)) {
                    coHeaderRec.Customer_Shipping_Address__c = coContactObj.SelectedShippingAddressId;
                }
                DMLUtility.updateSobjectList('CO_Header__c', new List<CO_Header__c>{coHeaderRec});
            }
        }
    }

    public class COContactWrapper {
        public String COHeaderId;
        public String SelectedCustomerContactId;
        public String SelectedShippingAddressId;
    }

    public static List<ServiceOrderWrapper.Unit> getGenericCOU() {
        String query = 'SELECT ' + String.join(CustomerOwnedUnit.fieldsList(), ',') + ' FROM Customer_Owned_Unit__c WHERE Is_Generic_Unit__c = true AND Unit_Type__c = \'COU\' LIMIT 1';
        List<Customer_Owned_Unit__c> genericUnitRecs = (List<Customer_Owned_Unit__c>) SOQLUtility.getQueryResults('Customer_Owned_Unit__c', query);
        List<ServiceOrderWrapper.Unit> genericUnitObjs = new List<ServiceOrderWrapper.Unit>();
        for(Customer_Owned_Unit__c unitRec : genericUnitRecs) {
            genericUnitObjs.add(new ServiceOrderWrapper.Unit(unitRec));
        }
        return genericUnitObjs;
    }
}