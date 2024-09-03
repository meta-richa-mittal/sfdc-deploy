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

    public static String finalizeInvoice(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType, String invoiceDateStr) {
        Savepoint sp;
        if(!Test.isRunningTest()) {
        	sp = Database.setSavepoint();
        }
        try {    
            coInvoiceItemsJsonString = BPUtility.getDecodedString(coInvoiceItemsJsonString);
            coHeaderId = BPUtility.getDecodedString(coHeaderId);
            currentCheckoutType = BPUtility.getDecodedString(currentCheckoutType);
            if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            
            List<COInvoiceItem> coInvoiceItemObjList = (List<COInvoiceItem>) System.JSON.deserialize(coInvoiceItemsJsonString, List<COInvoiceItem>.class);
            Set<Id> coLineItemIdSet = new Set<Id>();
            Set<Id> returnCOLineItemIdSet = new Set<Id>(); 
            Boolean isDisplayDiscountAmountOnPrint = false;
            String trackingNumber = coInvoiceItemObjList.size() > 0 ? coInvoiceItemObjList[0].TrackingNumber : null;
            for(COInvoiceItem coInvoiceItemObj : coInvoiceItemObjList) {
                if(coInvoiceItemObj.COLineItemId != null && coInvoiceItemObj.IsActive && coInvoiceItemObj.QtyRequired > coInvoiceItemObj.Qty && coInvoiceItemObj.Qty != 0 )  {
                    coLineItemIdSet.add(coInvoiceItemObj.COLineItemId);
                } else if(coInvoiceItemObj.COLineItemId != null && coInvoiceItemObj.QtyRequired < 0){
                    
                }
                if(coInvoiceItemObj.IsActive && coInvoiceItemObj.IsDisplayDiscountAmount != null && !isDisplayDiscountAmountOnPrint) {
                    isDisplayDiscountAmountOnPrint = coInvoiceItemObj.IsDisplayDiscountAmount;
                }
            }
            List<CO_Line_Item__c> coLineItemRecList = 
                [SELECT Qty__c, Qty_Committed__c, Part__c, CO_Header__c, Price__c, Tax__c, Price_When_Tax_Included__c, Pulled__c, 
                Item_Code__c, Item_Description__c, Actual_Retail_Price__c, Applicable_Tax__c, Actual_Kit_Price__c, 
                (Select Id, Tax_Rate__c, Sales_Tax_Item__r.Name__c from Individual_Taxes__r), 
                        (SELECT Id FROM Vendor_Order_Line_Items__r WHERE Status__c = 'Received') 
                   FROM CO_Line_Item__c WHERE Id IN : coLineItemIdSet ];
            List<CO_Line_Item__c> coLineItemRecToUpdated = new List<CO_Line_Item__c>();
            List<CO_Line_Item__c> coLineItemRecToInserted = new List<CO_Line_Item__c>();
            
            Map<Integer, List<Vendor_Order_Line_Item__c>> counterToReceivedVOLineItemListMap = new Map<Integer, List<Vendor_Order_Line_Item__c>>();
            Integer counter = 0;
            for(CO_Line_Item__c coLineItemRec : coLineItemRecList) {
                if(coLineItemRec.Qty__c > coLineItemRec.Qty_Committed__c) {
                    CO_Line_Item__c coLineItemDuplicate = new CO_Line_Item__c();
                    coLineItemDuplicate = coLineItemRec.clone(false, true, false, false);
                    coLineItemDuplicate.Qty__c = coLineItemDuplicate.Qty_Committed__c = coLineItemRec.Qty_Committed__c;
                    coLineItemRec.Qty__c = coLineItemRec.Qty__c - coLineItemRec.Qty_Committed__c;
                    coLineItemRec.Qty_Committed__c = 0;
                    coLineItemRec.Pulled__c = '0';
                    
                    counterToReceivedVOLineItemListMap.put(counter, coLineItemRec.Vendor_Order_Line_Items__r);
                    counter++;
                    coLineItemRecToUpdated.add(coLineItemRec);
                    coLineItemRecToInserted.add(coLineItemDuplicate);  
                }
            }
            if(coLineItemRecToUpdated.size() > 0) {
                COLineItemTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemRecToUpdated);
                COLineItemTriggerHelper.isForceStopTrigger = false;
            }
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            Set<Id> newInsertedCOLineItemIdSet = new Set<Id>();
            if(coLineItemRecToInserted.size() > 0) {
                COLineItemTriggerHelper.isForceStopTrigger = true;
                DMLUtility.insertSobjectList('CO_Line_Item__c', coLineItemRecToInserted);
                COLineItemTriggerHelper.isForceStopTrigger = false;
                
                transferReceivedVOLineItem(counterToReceivedVOLineItemListMap, coLineItemRecToInserted); 
                
                List<Individual_Tax__c> individualTaxInsertList = new List<Individual_Tax__c>();
                List<CO_Invoice_Item__c> coInvItemInsertList = new List<CO_Invoice_Item__c>();
                for(Integer i=0 ; i < coLineItemRecToInserted.size() ; i++ ) {
                    /**coLineItemRecToInserted[i].Price__c = coLineItemRecToUpdated[i].Price__c;
                    if(isTaxIncludingPricing) {
                        coLineItemRecToInserted[i].Price_When_Tax_Included__c = coLineItemRecToUpdated[i].Price_When_Tax_Included__c;
                    }**/
                    for(Individual_Tax__c indvTaxRec : coLineItemRecToUpdated[i].Individual_Taxes__r) {
                		Individual_Tax__c indvTaxInsertRec = indvTaxRec.clone(false, true, false, false);
                		indvTaxInsertRec.CO_Line_Item__c = coLineItemRecToInserted[i].Id;
	                	individualTaxInsertList.add(indvTaxInsertRec);
	                }
                    coInvItemInsertList.add(new CO_Invoice_Item__c(
                        CO_Line_Item__c = coLineItemRecToInserted[i].Id, 
                        isActive__c = true,
                        CO_Invoice_Header__c = coInvoiceItemObjList[0].COInvoiceHeaderId));
                
                }
                DMLUtility.insertSobjectList('Individual_Tax__c', individualTaxInsertList);
                DMLUtility.insertSobjectList('CO_Invoice_Item__c', coInvItemInsertList);
                
                for(CO_Line_Item__c coLineItemRec : coLineItemRecToInserted) {
                    newInsertedCOLineItemIdSet.add(coLineItemRec.Id); 
                }
            }
            
            // Close Invoice Header
            String activeCOInvoiceHeaderId = '';
            String closedCOInvoiceHeaderId = '';
            if(coInvoiceItemObjList.size() == 0) {
                return null;
            }
            DateTime invoiceDate = (invoiceDateStr != null) ? HomeSearchFilterInterface.getDateFromString(invoiceDateStr) : date.today();
            activeCOInvoiceHeaderId = coInvoiceItemObjList[0].COInvoiceHeaderId;
            activeCOInvoiceHeaderId = BPUtility.escapeSingleQuotes(activeCOInvoiceHeaderId);
            CO_Invoice_Header__c coInvoiceHeaderRec = [select CO_Header__r.Customer__c, Invoice_Status__c,
            CO_Header__r.Customer_Contact__r.Is_Contact__c, CO_Header__r.Customer_Shipping_Address__r.Is_Shipping_Address__c, 
            CO_Header__r.Customer_Contact__r.LastName, CO_Header__r.Customer_Contact__r.Formatted_Phone_number__c, CO_Header__r.Customer_Contact__r.Email, 
            CO_Header__r.Customer_Shipping_Address__r.LastName, CO_Header__r.Customer_Shipping_Address__r.MailingStreet, CO_Header__r.Customer_Shipping_Address__r.MailingCity, 
            CO_Header__r.Customer_Shipping_Address__r.Mailing_County_Parish__c, CO_Header__r.Customer_Shipping_Address__r.MailingPostalCode, 
            CO_Header__r.Customer_Shipping_Address__r.MailingState, CO_Header__r.Customer_Shipping_Address__r.MailingCountry 
            from CO_Invoice_Header__c where Id = :activeCOInvoiceHeaderId];
            coInvoiceHeaderRec.Invoice_Status__c = 'Closed';
            coInvoiceHeaderRec.Closed_Invoice_Date__c = system.now();
            coInvoiceHeaderRec.Checkout_Type__c = currentCheckoutType;
            coInvoiceHeaderRec.Invoice_Date__c = invoiceDate; 
            coInvoiceHeaderRec.Tracking_Number__c = trackingNumber;
            setContactAndShippingFields(coInvoiceHeaderRec, coInvoiceHeaderRec.CO_Header__r);
            closedCOInvoiceHeaderId = activeCOInvoiceHeaderId;
            String customerId = coInvoiceHeaderRec.CO_Header__r.Customer__c;
            
            CO_Invoice_Header__c coInvoiceHeaderRecToInsert = new CO_Invoice_Header__c();
            coInvoiceHeaderRecToInsert.Invoice_Status__c = 'Active';
            coInvoiceHeaderRecToInsert.CO_Header__c = coHeaderId; 
            DMLUtility.insertSobjectList('CO_Invoice_Header__c', coInvoiceHeaderRecToInsert);
            
            if(coInvoiceHeaderRec != null) {
                AutoNumberHolder__c objnewAutonumber = new AutoNumberHolder__c();
                DMLUtility.insertSobjectList('AutoNumberHolder__c', objnewAutonumber);
                coInvoiceHeaderRec.AutoNumberHolder__c = objnewAutonumber.Id;
            }
            
            String activeInvoiceHeaderId = coInvoiceHeaderRecToInsert.Id;
            
            closedCOInvoiceHeaderId = BPUtility.escapeSingleQuotes(closedCOInvoiceHeaderId);
            
            List<CO_Invoice_Item__c> coInvoiceItems = [select isActive__c, CO_Invoice_Header__c, CO_Kit_Header__c,Service_Order_Header__c,CO_Line_Item__c,CO_Line_Item__r.Closed_CO_Invoice_link__c, CO_Invoice_Header__r.Name,
                                                            Deal_Finance__c,Deal__c from CO_Invoice_Item__c 
                                                            where (CO_Invoice_Header__c = :closedCOInvoiceHeaderId AND isActive__c = false) 
                                                                        OR CO_Line_Item__c IN : coLineItemIdSet];
            for(CO_Invoice_Item__c coInvoiceItemRec : coInvoiceItems) {
                if(coInvoiceItemRec.CO_Line_Item__c == null) {
                     coInvoiceItemRec.CO_Invoice_Header__c = activeInvoiceHeaderId;
                     coInvoiceItemRec.isActive__c = (coInvoiceItemRec.Deal__c != null ? true : coInvoiceItemRec.isActive__c);
                     continue;
                }
                if(newInsertedCOLineItemIdSet.contains(coInvoiceItemRec.CO_Line_Item__c)) {  
                    coInvoiceItemRec.isActive__c = true;
                } else {
                    coInvoiceItemRec.isActive__c = false;  
                    coInvoiceItemRec.CO_Invoice_Header__c = activeInvoiceHeaderId;
                }
            }
            if(coInvoiceItems.size() > 0) { 
                DMLUtility.updateSobjectList('CO_Invoice_Item__c', coInvoiceItems);
            }
            
            Map<String,List<CO_Invoice_Item__c>> coInvoiceTypeToLineItemMap =  new Map<String,List<CO_Invoice_Item__c>>();
            closedCOInvoiceHeaderId = BPUtility.escapeSingleQuotes(closedCOInvoiceHeaderId);
            List<CO_Invoice_Item__c> closedCOInvoicItemList = [select   CO_Invoice_Header__c,SO_Payment_Role__c, CO_Kit_Header__c,Service_Order_Header__c,
            		Service_Order_Header__r.Transaction_Type__r.Type__c, CO_Invoice_Header__r.Invoice_Number__c,
                    CO_Line_Item__c,CO_Line_Item__r.Closed_CO_Invoice_link__c, CO_Invoice_Header__r.Name, Deal__c, Deal__r.Type__c, Deal_Finance__c from CO_Invoice_Item__c 
                    where CO_Invoice_Header__c = :closedCOInvoiceHeaderId];
            List<CO_Line_Item__c> coLineItemsToUpdated = new List<CO_Line_Item__c>();
            List<Service_Order_Line_Item__c> soLineItemInternalservice = new List<Service_Order_Line_Item__c>();
            List<Service_Order_Line_Item__c> soLineItemDealservice = new List<Service_Order_Line_Item__c>();
            List<CO_Line_Item__c> coLineItemDealservice = new List<CO_Line_Item__c>();
            
            Map<Id,CO_Invoice_Item__c> invoicedServiceOrderHeaderMap =new  Map<Id,CO_Invoice_Item__c>();
            Map<Id, CO_Invoice_Item__c > invoicedCoLineItemMap = new Map<Id, CO_Invoice_Item__c >();
            Map<Id, CO_Invoice_Item__c > invoicedCOKHMap = new Map<Id, CO_Invoice_Item__c >();
            Map<Id, CO_Invoice_Item__c > invoicedSoPaymentMap = new Map<Id, CO_Invoice_Item__c >();
            Map<Id, CO_Invoice_Item__c > invoicedDealFinanceMap = new Map<Id, CO_Invoice_Item__c >();
            Map<Id, CO_Invoice_Item__c > invoicedDealMap = new Map<Id, CO_Invoice_Item__c >();
            //system.assert(false, closedCOInvoicItemList);
            List<Part__c> PartForPartReturnBuckets = new  List<Part__c>();
            Boolean isDealInvoiced = false;
            for(CO_Invoice_Item__c coInoiceItemRec : closedCOInvoicItemList) {
                if(coInoiceItemRec.Deal__c != null){
                    isDealInvoiced = true;
                }
                if(coInoiceItemRec.CO_Line_Item__c != null) {
                    if(!coInvoiceTypeToLineItemMap.ContainsKey('ColiInvoice')) {
                        coInvoiceTypeToLineItemMap.Put('ColiInvoice',new List<CO_Invoice_Item__c>{ coInoiceItemRec});
                    }
                    coInvoiceTypeToLineItemMap.get('ColiInvoice').add(coInoiceItemRec);
                    invoicedCoLineItemMap.Put(coInoiceItemRec.CO_Line_Item__c,coInoiceItemRec );
                } else if( coInoiceItemRec.CO_Kit_Header__c !=null){
                    if(!coInvoiceTypeToLineItemMap.ContainsKey('CoKitInvoice')) {
                        coInvoiceTypeToLineItemMap.Put('CoKitInvoice',new List<CO_Invoice_Item__c>{ coInoiceItemRec});
                    }
                    coInvoiceTypeToLineItemMap.get('CoKitInvoice').add(coInoiceItemRec);
                    invoicedCOKHMap.Put(coInoiceItemRec.CO_Kit_Header__c,coInoiceItemRec );
                
                } else if( coInoiceItemRec.Service_Order_Header__c !=null && coInoiceItemRec.SO_Payment_Role__c ==null && 
                	 		coInoiceItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c != 'Third-Party') {
                    if(!coInvoiceTypeToLineItemMap.ContainsKey('SoKitInvoice')) {
                        coInvoiceTypeToLineItemMap.Put('SoKitInvoice',new List<CO_Invoice_Item__c>{ coInoiceItemRec});
                    }
                    coInvoiceTypeToLineItemMap.get('SoKitInvoice').add(coInoiceItemRec);
                    invoicedServiceOrderHeaderMap.Put(coInoiceItemRec.Service_Order_Header__c,coInoiceItemRec );
                } else if( coInoiceItemRec.SO_Payment_Role__c !=null){
                    if(!coInvoiceTypeToLineItemMap.ContainsKey('SoPayment')) {
                        coInvoiceTypeToLineItemMap.Put('SoPayment',new List<CO_Invoice_Item__c>{ coInoiceItemRec});
                    }
                    coInvoiceTypeToLineItemMap.get('SoPayment').add(coInoiceItemRec);
                    invoicedSoPaymentMap.Put(coInoiceItemRec.SO_Payment_Role__c , coInoiceItemRec );
                } else if( coInoiceItemRec.Deal__c !=null){
                     if( coInoiceItemRec.Deal_Finance__c != null) {
                        invoicedDealFinanceMap.Put(coInoiceItemRec.Deal_Finance__c , coInoiceItemRec );
                     } else {
                        invoicedDealMap.Put(coInoiceItemRec.Deal__c , coInoiceItemRec );
                     }
                }
            }
            
            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            
            transferPaymentsAndDepositToActiveInvHeader(currentCheckoutType, closedCOInvoiceHeaderId, activeInvoiceHeaderId, isDealInvoiced);
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvoiceHeaderRec);
            
            List<Option_Fee__c> optionAndFeeRecListWithDoNotInvOption = new List<Option_Fee__c>();
            // for Service order records 
            Set<String> dealKHIdSet = new Set<String>();
			if(coInvoiceTypeToLineItemMap.containsKey('SoKitInvoice')) {
				if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	            if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	           	if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

               	List<Service_Order_Line_Item__c> serviceOrderLineItemFromInvoiceList  = new List<Service_Order_Line_Item__c>([Select Service_Order_Header__c,
																	Service_Order_Kit_Header__c, Service_Order_Kit_Header__r.Deal_Kit_Header__c,
																	
																	(Select Qty__c, Qty_Committed__c, Status__c, Price__c, part__c,part__r.Qty_In_Stock__c,
                                                                    part__r.Qty_Committed__c,part__r.Last_Cost__c, Closed_CO_Invoice_link__c,Oversold_Qty__c 
                                                                    From CO_Line_Items__r),
                                                                    
                                                                    (Select Id, CO_Line_Item__r.Price__c, Service_Order_Line_Item__r.Kit_Price__c from Options_Fees__r
                                                                    where Do_Not_Invoice__c = true), 
                                                                    
                                                                    Option_Fee__c, Labour_Code__r.Description__c,Fee__r.Description__c, 
                                                                    Part__r.Description__c, Qty_Needed__c,Retail_Price__c,Kit_Price__c,CO_Line_Item__c,
                                                                    Service_Order_Header__r.Customer_Owned_Unit__c,Service_Order_Header__r.SO_Type__c, Service_Order_Header__r.Deal__c,
                                                                    Item_Code__c, Item_Description__c, Service_Order_Header__r.Transaction_Type__r.Type__c
                                                                    From Service_Order_Line_Item__c where Service_Order_Header__c  =: invoicedServiceOrderHeaderMap.KeySet()]);
                                                                                                                                  
                for(Service_Order_Line_Item__c serviceOrderLineItemFromInvoiceRec : serviceOrderLineItemFromInvoiceList) {
                    if(invoicedServiceOrderHeaderMap.containsKey(serviceOrderLineItemFromInvoiceRec.Service_Order_Header__c)) {
                        CO_Invoice_Item__c   closedCOInvoiceItem =  invoicedServiceOrderHeaderMap.get(serviceOrderLineItemFromInvoiceRec.Service_Order_Header__c);
                        if(serviceOrderLineItemFromInvoiceRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Stock Unit'){
                            soLineItemInternalservice.add(serviceOrderLineItemFromInvoiceRec);
                        } else if(serviceOrderLineItemFromInvoiceRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Deal Service' ) {
                            soLineItemDealservice.add(serviceOrderLineItemFromInvoiceRec);
                            if(String.isNotBlank(serviceOrderLineItemFromInvoiceRec.Service_Order_Kit_Header__c) &&
                                    String.isNotBlank(serviceOrderLineItemFromInvoiceRec.Service_Order_Kit_Header__r.Deal_Kit_Header__c)) {
                                dealKHIdSet.add(serviceOrderLineItemFromInvoiceRec.Service_Order_Kit_Header__r.Deal_Kit_Header__c);
                            } else {
                        		optionAndFeeRecListWithDoNotInvOption.addAll(serviceOrderLineItemFromInvoiceRec.Options_Fees__r);
                        	}
                        }
                            
                        List<CO_Line_Item__c> coliUpdateFromServiceOrderInvoiceList = new   List<CO_Line_Item__c>(serviceOrderLineItemFromInvoiceRec.CO_Line_Items__r);
                        for(CO_Line_Item__c colirec : coliUpdateFromServiceOrderInvoiceList ){
                            colirec.Closed_CO_Invoice_link__c = closedCOInvoiceItem.CO_Invoice_Header__r.Name;
                            colirec.Invoice_Number__c = closedCOInvoiceItem.CO_Invoice_Header__c;
                            coLineItemsToUpdated.add(colirec);
                        }
                    }
                }
            }
                
            if(coInvoiceTypeToLineItemMap.containsKey('ColiInvoice')) {
                if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                
                List<CO_Line_Item__c> ColiFromInvoiceList = new   List<CO_Line_Item__c>([Select Qty__c, Qty_Committed__c, Price__c, Status__c,part__c,part__r.Qty_In_Stock__c,Related_Option_And_Fees__c,
						(Select Id, CO_Line_Item__r.Price__c, Service_Order_Line_Item__r.Kit_Price__c from Options_Fees__r where Do_Not_Invoice__c = true), 
                        part__r.Qty_Committed__c,part__r.Last_Cost__c,closed_CO_Invoice_link__c,Oversold_Qty__c,Deal__c From CO_Line_Item__c where Id =: invoicedCoLineItemMap.KeySet()]);
                for(CO_Line_Item__c colirec : ColiFromInvoiceList) {
                    CO_Invoice_Item__c   closedCOInvoiceItem = invoicedCoLineItemMap.get(colirec.Id);
                    colirec.Closed_CO_Invoice_link__c = closedCOInvoiceItem.CO_Invoice_Header__r.Name;
                    colirec.Invoice_Number__c = closedCOInvoiceItem.CO_Invoice_Header__c;
                    coLineItemsToUpdated.add(colirec);
                    if(String.isNotBlank(colirec.Related_Option_And_Fees__c)){
                        coLineItemDealservice.add(colirec);
                    }
                    optionAndFeeRecListWithDoNotInvOption.addAll(colirec.Options_Fees__r);
                }
             }   
             if(coInvoiceTypeToLineItemMap.containsKey('CoKitInvoice')) {
                if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

                List<CO_Kit_Header__c> ColiFromInvoiceList = new   List<CO_Kit_Header__c>([Select Id, Deal_Kit_Header__c, (Select Qty__c, Qty_Committed__c, Price__c, Status__c,part__c,part__r.Qty_In_Stock__c,Related_Option_And_Fees__c,
                                                                                        part__r.Qty_Committed__c,part__r.Last_Cost__c, Closed_CO_Invoice_link__c,Oversold_Qty__c, Deal__c From CO_Line_Items__r)
                                                                                        From CO_Kit_Header__c where  Id =: invoicedCOKHMap.KeySet()]);
                                                                                        
                for(CO_Kit_Header__c coKitHeaderFromInvoiceRec : ColiFromInvoiceList) {
                    if(String.isNotBlank(coKitHeaderFromInvoiceRec.Deal_Kit_Header__c)) {
                        dealKHIdSet.add(coKitHeaderFromInvoiceRec.Deal_Kit_Header__c);
                    }
                }

                for(CO_Kit_Header__c coKitHeaderFromInvoiceRec : ColiFromInvoiceList) {
                    if(invoicedCOKHMap.containsKey(coKitHeaderFromInvoiceRec.Id)){
                        CO_Invoice_Item__c   closedCOInvoiceItem =  invoicedCOKHMap.get(coKitHeaderFromInvoiceRec.Id);
                        List<CO_Line_Item__c> coliUpdateFromServiceOrderInvoiceList = new   List<CO_Line_Item__c>(coKitHeaderFromInvoiceRec.CO_Line_Items__r);
                        for(CO_Line_Item__c colirec : coliUpdateFromServiceOrderInvoiceList ){
                            colirec.Closed_CO_Invoice_link__c = closedCOInvoiceItem.CO_Invoice_Header__r.Name;
                            colirec.Invoice_Number__c = closedCOInvoiceItem.CO_Invoice_Header__c;
                            coLineItemsToUpdated.add(colirec);
                            if(String.isNotBlank(colirec.Related_Option_And_Fees__c)) {                                         
                                coLineItemDealservice.add(colirec);
                            }
                        }
                    }
                }
            }
            
            Map<Id,Part__c> updateStockedMap = new Map<Id,Part__c>();
            Map<Id,Part__c> updateStockBucketMap = new Map<Id,Part__c>();
            Set<Id> invoiceableSOIdSet = new Set<Id>();
            List<So_Payment_Role__c> SoPaymentRoleList  = new List<So_Payment_Role__c>();
            Map<String, CO_Line_Item__c> coliIdTocoliRecRelatedToThirdPartyMap = new Map<String, CO_Line_Item__c>();
            Map<Id, Part__c> partIdToPartRecMap = new Map<Id, Part__c>(); 
            if(coInvoiceTypeToLineItemMap.containsKey('SoPayment')){  
                if(AccessControl.ifObjectFieldIsAccessible('So_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('Claim_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

                SoPaymentRoleList  = new List<So_Payment_Role__c>([Select Id,RecordType.DeveloperName, Invoice_Number__c, Service_Order_Header__c, (select Id,Is_Variance__c,Approved_Qty__c, 
                                                                        Variance_Qty__c,Service_Order_Line_Item__c,Approved_Price__c, Service_Order_Line_Item__r.part__c, 
                                                                        Service_Order_Line_Item__r.part__r.Qty_In_Stock__c,
                                                                        Service_Order_Line_Item__r.part__r.last_cost__c,Service_Order_Line_Item__r.part__r.Qty_Committed__c ,
                                                                        Service_Order_Line_Item__r.CO_Line_Item__c, 
                                                                        Service_Order_Line_Item__r.CO_Line_Item__r.Qty_Committed__c, 
                                                                        Service_Order_Line_Item__r.Fee__c,
                                                                        Service_Order_Line_Item__r.Qty_Needed__c,
                                                                        Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c  From Claim_Line_Items__r)
                                                                        From So_Payment_Role__c  where  Id  IN : invoicedSoPaymentMap.KeySet()]);
                     
                for(So_Payment_Role__c SoPaymentRec : SoPaymentRoleList){
                    CO_Invoice_Item__c closedCOInvoiceItem = invoicedSoPaymentMap.get(SoPaymentRec.Id);
                    SoPaymentRec.Invoice_Number__c = closedCOInvoiceHeaderId;
                    if(SoPaymentRec.RecordType.DeveloperName == 'Third_Party' || SoPaymentRec.RecordType.DeveloperName == 'Customer' || 
                    	 											SoPaymentRec.RecordType.DeveloperName == 'Internal') {
                    	SoPaymentRec.Status__c = 'Invoiced'; 											
                        if(SoPaymentRec.RecordType.DeveloperName == 'Third_Party' ) {
                        	for(Claim_Line_Item__c ClaimLineItemrec : SoPaymentRec.Claim_Line_Items__r ){
	                            if(ClaimLineItemrec.Service_Order_Line_Item__r.part__c!=null){
	                                Part__c partRec = new part__c();
	                                partRec.Id =  ClaimLineItemrec.Service_Order_Line_Item__r.part__c;
	                                partRec.Qty_In_Stock__c =  ClaimLineItemrec.Service_Order_Line_Item__r.part__r.Qty_In_Stock__c;
	                                partRec.Qty_Committed__c =  ClaimLineItemrec.Service_Order_Line_Item__r.part__r.Qty_Committed__c;
	                                Decimal qtyNeed = SoPaymentRec.RecordType.DeveloperName == 'Third_Party' ? ClaimLineItemrec.Approved_Qty__c : 
	                                												ClaimLineItemrec.Variance_Qty__c;
	                                Decimal quantityComitted = qtyNeed;
	                                Decimal qtyOverSold = ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c != null ? 
	                                		ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c : 0;
	                                
	                                Decimal ReturnCost = ClaimLineItemrec.Service_Order_Line_Item__r.part__r.last_cost__c !=null ? 
	                                						ClaimLineItemrec.Service_Order_Line_Item__r.part__r.last_cost__c : 0 ; 
	                                ReturnCost = (SoPaymentRec.RecordType.DeveloperName == 'Internal') ? ClaimLineItemrec.Approved_Price__c : ReturnCost;
	                                AddPartToPartMap(updateStockedMap, updateStockBucketMap, quantityComitted, quantityComitted, partRec, 
	                                				PartForPartReturnBuckets, ReturnCost, qtyOverSold);
                                    if(!partIdToPartRecMap.containsKey(partRec.Id)){
                                        partIdToPartRecMap.put(partRec.Id, new Part__c(Id = partRec.Id, Last_Sold__c = system.Now()));
                                    }
	                            }
	                            
	                            if(String.isNotBlank(ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__c)) {
	                                CO_Line_Item__c colirec = new CO_Line_Item__c(Id = ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__c);
	                                colirec.Closed_CO_Invoice_link__c = closedCOInvoiceItem.CO_Invoice_Header__r.Name;
	                                colirec.Invoice_Number__c = closedCOInvoiceItem.CO_Invoice_Header__c;
	                                colirec.Part__c = ClaimLineItemrec.Service_Order_Line_Item__r.Part__c;
	                                colirec.Fee__c = ClaimLineItemrec.Service_Order_Line_Item__r.Fee__c;
	                                colirec.Oversold_Qty__c = ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c;
	                                colirec.Qty_Committed__c = ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__r.Qty_Committed__c;
	                                colirec.Qty__c = ClaimLineItemrec.Service_Order_Line_Item__r.Qty_Needed__c;
	                                coliIdTocoliRecRelatedToThirdPartyMap.put(colirec.Id, colirec);
	                            }
	                        }
                        	invoiceableSOIdSet.add(SoPaymentRec.Service_Order_Header__c);
                        }
 					} else if(SoPaymentRec.RecordType.DeveloperName == 'deductible'){
	                    SoPaymentRec.Deductible_Status__c = 'Paid';
	                    SoPaymentRec.Status__c = 'Invoiced'; 
                    }
                }                    
            }
            
            for(CO_Line_Item__c coLineItemsToUpdatedRec : coLineItemsToUpdated){
                if(coLineItemsToUpdatedRec.Part__c != null){
                    Decimal quantityComitted = coLineItemsToUpdatedRec.Qty_Committed__c  ==null ? 0 :coLineItemsToUpdatedRec.Qty_Committed__c;
                    Decimal qtyNeed = coLineItemsToUpdatedRec.Qty__c  ==null ? 0 :coLineItemsToUpdatedRec.Qty__c;
                    Decimal qtyOverSold = coLineItemsToUpdatedRec.Oversold_Qty__c;
                    Decimal ReturnCost = coLineItemsToUpdatedRec.part__r.last_cost__c !=null ?  coLineItemsToUpdatedRec.part__r.last_cost__c : 0 ;
                    AddPartToPartMap(updateStockedMap,  updateStockBucketMap,qtyNeed,quantityComitted,coLineItemsToUpdatedRec.part__r,
                             PartForPartReturnBuckets,ReturnCost,qtyOverSold);
                    if(!partIdToPartRecMap.containsKey(coLineItemsToUpdatedRec.Part__c)){
                        partIdToPartRecMap.put(coLineItemsToUpdatedRec.Part__c, new Part__c(Id = coLineItemsToUpdatedRec.Part__c, Last_Sold__c = system.Now()));
                    }
                }
            }
            
            if(partIdToPartRecMap.size() > 0) {
                if(AccessControl.ifObjectFieldIsUpdateable('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                update partIdToPartRecMap.values();
            }
              
            if(PartForPartReturnBuckets.size() > 0){
                FIFOTransaction.createFIFOBucketForCustomerReturn(PartForPartReturnBuckets, activeCOInvoiceHeaderId,coLineItemsToUpdated);
            } 
              
            List<Part_FIFO_Bucket__c>  PartFifoList=  SOQLUtil.getPartFIFOBucketByPartList(updateStockedMap.keySet());
            Map<Id,List<Part_FIFO_Bucket__c>> PartToFIFOBucketMap   = new Map<Id,List<Part_FIFO_Bucket__c>>();
            for(Part_FIFO_Bucket__c partFifoRec : PartFifoList){
                if(PartToFIFOBucketMap.containsKey(partFifoRec.part__c)){
                    PartToFIFOBucketMap.get(partFifoRec.part__c).add(partFifoRec);
                }else{ 
                    List<Part_FIFO_Bucket__c> listpartFifo  = new List<Part_FIFO_Bucket__c>();
                    listpartFifo.add(partFifoRec);
                    PartToFIFOBucketMap.put(partFifoRec.part__c, listpartFifo);
                } 
            } 
            
            for(CO_Line_Item__c coliRec : coLineItemsToUpdated) {
                if(coliIdTocoliRecRelatedToThirdPartyMap.containskey(coliRec.Id)) {
                    coliIdTocoliRecRelatedToThirdPartyMap.remove(coliRec.Id);
                }
            }
            coLineItemsToUpdated.addAll(coliIdTocoliRecRelatedToThirdPartyMap.values());
            List<Part__c> partFifoBucketValueToUpdate = new List<Part__c>(); 
            if(updateStockBucketMap.size()> 0){
                String Result = FIFOTransaction.CreateFiFoBucketActivityForInvoice(PartToFIFOBucketMap, closedCOInvoiceHeaderId,updateStockBucketMap.values(),updateStockedMap, coLineItemsToUpdated);
            }
            
            if(coLineItemsToUpdated.size() > 0) {
                COLineItemTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemsToUpdated);
                COLineItemTriggerHelper.isForceStopTrigger = false;
            }  
            if(SoPaymentRoleList.Size()>0){
                if(AccessControl.ifObjectFieldIsUpdateable('So_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                update SoPaymentRoleList;
            }
             
            if(invoicedDealFinanceMap.size() > 0 ){
                String dealFinanceId = '';
                for(String  Str : invoicedDealFinanceMap.Keyset()){
                    dealFinanceId = Str;
                    break;
                }
                if(String.isNotBlank(dealFinanceId)) {
                    if(AccessControl.ifObjectFieldIsUpdateable('Deal_Finance__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                    update new Deal_Finance__c(Id = dealFinanceId, Status__c = 'Paid');
                }
                DealService.UpdateOptionFeeStatus(coHeaderId);
            }
            if(invoicedDealMap.size() > 0 ){
                String dealId = '';
                String invoiceNumber = '';
                for(String  Str : invoicedDealMap.Keyset()){
                    dealId = Str;
                    invoiceNumber = invoicedDealMap.get(dealId).CO_Invoice_Header__r.Invoice_Number__c;
                    break;
                }                       
                DealService.finalizeDeal(dealId, activeCOInvoiceHeaderId, invoiceNumber, invoiceDate);
            }
            if(soLineItemInternalservice.size()>0){
                string UnitID = soLineItemInternalservice[0].Service_Order_Header__r.Customer_Owned_Unit__c;
                list<Unit_Price_Cost__c> listUnitPriceCostToInsert = DealService.createPriceAndCostLineItem(UnitID, soLineItemInternalservice,closedCOInvoiceHeaderId);
                if(listUnitPriceCostToInsert.size() > 0){
                    DMLUtility.insertSobjectList('Unit_Price_Cost__c', listUnitPriceCostToInsert);
                }                       
            }
               
            //Invoicing Deal Item Adding cost to option fee
            if(coLineItemDealservice.size() > 0 || soLineItemDealservice.size() > 0 || optionAndFeeRecListWithDoNotInvOption.size() > 0){
                List<Option_Fee__c> optionFeeListToUpdate = DealService.UpdateOptionFeeInvoice(coLineItemDealservice,soLineItemDealservice, optionAndFeeRecListWithDoNotInvOption);
                if(optionFeeListToUpdate.size() > 0 ){
                    OptionAndFeeTriggerHelper.isForceStopTrigger = true;
                    DMLUtility.updateSobjectList('Option_Fee__c', optionFeeListToUpdate);
                    OptionAndFeeTriggerHelper.isForceStopTrigger = false;
                    DealService.UpdateOptionFeeStatus(coHeaderId); 
                }
            }
             // Reverse Entry of Payment in Deposit if Payment is done from deposits.
            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

            List<CO_Invoice_Payment__c> coInvoicePayments = new List<CO_Invoice_Payment__c>();
            closedCOInvoiceHeaderId = BPUtility.escapeSingleQuotes(closedCOInvoiceHeaderId);
            
            CO_Invoice_Header__c invoiceRec = calculateIndividualsTotalsForInvoice(closedCOInvoiceHeaderId);
            validatePayment(currentCheckoutType, invoiceRec, invoicedDealMap.values());
            
            invoiceRec.Is_Discount_Shown__c = isDisplayDiscountAmountOnPrint;
            Set<Id> soheaderInvoiceIdSet = new Set<Id>(invoicedServiceOrderHeaderMap.keyset());
            soheaderInvoiceIdSet.addAll(invoiceableSOIdSet);
            
            ServiceJobService.updateSOHeaderList(soheaderInvoiceIdSet, closedCOInvoiceHeaderId);
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', invoiceRec);
            // Populate Totals.
            TaxCalculation.populateOrderTotal(coHeaderId);
            
            // Create Activity History.
            if(!Test.isRunningTest()) {
                ActivityHistory.createActivityHistory('Finalize Customer Invoice', 'Customer Invoice', closedCOInvoiceHeaderId, 'Customer', customerId, coHeaderId);
            }
            if(!system.isFuture() && !Test.isRunningTest()) {
                populateFieldsOnInvoice_future(closedCOInvoiceHeaderId);
                populateIndividualsCostTotalsAfterFinalize(closedCOInvoiceHeaderId);
            } else {
                CO_Invoice_Header__c coInvHeaderRec = populateFieldsOnInvoice(closedCOInvoiceHeaderId);
                DMLUtility.updateSobjectListWithRetry(new List<SObject>{coInvHeaderRec});
            }
            updateMerchServiceSOStatus(coHeaderId);
            return 'Success';
        } catch(Exception e) {
        	if(!Test.isRunningTest()) {
            	Database.rollback(sp);
        	}
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));           
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
    public static void finalizeOrder(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType, String invoiceDateStr) {
        Savepoint sp;
        if(!Test.isRunningTest()) {
        	sp = Database.setSavepoint();
        }
        try {
            DateTime invoiceDate = (invoiceDateStr != null) ? HomeSearchFilterInterface.getDateFromString(invoiceDateStr) : date.today();
            if(AccessControl.ifObjectFieldIsUpdateable('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            
            coInvoiceItemsJsonString = BPUtility.getDecodedString(coInvoiceItemsJsonString);
            coHeaderId = BPUtility.getDecodedString(coHeaderId);
            currentCheckoutType = BPUtility.getDecodedString(currentCheckoutType);
        
            List<COInvoiceItem> coInvoiceItemObjList = (List<COInvoiceItem>) System.JSON.deserialize(coInvoiceItemsJsonString, List<COInvoiceItem>.class);
            Set<Id> coLineItemIdSet = new Set<Id>();
            Boolean isDisplayDiscountAmountOnPrint = false;
            String trackingNumber = coInvoiceItemObjList.size() > 0 ? coInvoiceItemObjList[0].TrackingNumber : null;
            for(COInvoiceItem coInvoiceItemObj : coInvoiceItemObjList) {
               coLineItemIdSet.add(coInvoiceItemObj.COLineItemId);
                if(coInvoiceItemObj.IsActive && coInvoiceItemObj.IsDisplayDiscountAmount != null && !isDisplayDiscountAmountOnPrint) {
                    isDisplayDiscountAmountOnPrint = coInvoiceItemObj.IsDisplayDiscountAmount;
                }
            }

            String activeCOInvoiceHeaderId = coInvoiceItemObjList[0].COInvoiceHeaderId;
            activeCOInvoiceHeaderId = BPUtility.escapeSingleQuotes(activeCOInvoiceHeaderId);
            if(activeCOInvoiceHeaderId == null ||  activeCOInvoiceHeaderId == ''){
                return; 
            }

            AutoNumberHolder__c AutonumberRec = new AutoNumberHolder__c();
            DMLUtility.insertSobjectList('AutoNumberHolder__c', AutonumberRec);
            if(AutonumberRec.Id !=null){
                CO_Invoice_Header__c coInvoiceHeaderUpdateRec = new CO_Invoice_Header__c(Id = activeCOInvoiceHeaderId, AutoNumberHolder__c = AutonumberRec.Id);
                COInvoiceTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvoiceHeaderUpdateRec);
                COInvoiceTriggerHelper.isForceStopTrigger = false;
            }

            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            Map<String,List<CO_Invoice_Item__c>> coInvoiceTypeToLineItemMap =  new Map<String,List<CO_Invoice_Item__c>>();
            List<CO_Invoice_Item__c> closedCOInvoicItemList = [select   CO_Invoice_Header__c,SO_Payment_Role__c,Deal__c, Deal__r.Type__c, CO_Kit_Header__c,Service_Order_Header__c,CO_Line_Item__c,CO_Line_Item__r.Closed_CO_Invoice_link__c, CO_Invoice_Header__r.Name, CO_Invoice_Header__r.Invoice_Number__c from CO_Invoice_Item__c where CO_Invoice_Header__c = :activeCOInvoiceHeaderId];
            List<CO_Line_Item__c> coLineItemsToUpdated = new List<CO_Line_Item__c>();
            List<Service_Order_Line_Item__c> soLineItemInternalservice = new List<Service_Order_Line_Item__c>();
            Map<Id,CO_Invoice_Item__c> invoicedServiceOrderHeaderMap =new  Map<Id,CO_Invoice_Item__c>();
            Map<Id, CO_Invoice_Item__c > invoicedCoLineItemMap = new Map<Id, CO_Invoice_Item__c >();
            Map<Id, CO_Invoice_Item__c > invoicedCOKHMap = new Map<Id, CO_Invoice_Item__c >();
            Map<Id, CO_Invoice_Item__c > invoicedSoPaymentMap = new Map<Id, CO_Invoice_Item__c >();
            Map<Id, CO_Invoice_Item__c > invoicedDealMap = new Map<Id, CO_Invoice_Item__c >();
             
            List<Part__c> PartForPartReturnBuckets = new  List<Part__c>();
            for(CO_Invoice_Item__c coInoiceItemRec : closedCOInvoicItemList) {
                if(coInoiceItemRec.CO_Line_Item__c != null) {
                    if(!coInvoiceTypeToLineItemMap.ContainsKey('ColiInvoice')) {
                        coInvoiceTypeToLineItemMap.Put('ColiInvoice',new List<CO_Invoice_Item__c>{ coInoiceItemRec});
                    }
                    coInvoiceTypeToLineItemMap.get('ColiInvoice').add(coInoiceItemRec);
                    invoicedCoLineItemMap.Put(coInoiceItemRec.CO_Line_Item__c,coInoiceItemRec );
                } else if(coInoiceItemRec.CO_Kit_Header__c !=null){
                    if(!coInvoiceTypeToLineItemMap.ContainsKey('CoKitInvoice')) {
                        coInvoiceTypeToLineItemMap.Put('CoKitInvoice',new List<CO_Invoice_Item__c>{ coInoiceItemRec});
                    }
                    coInvoiceTypeToLineItemMap.get('CoKitInvoice').add(coInoiceItemRec);
                    invoicedCOKHMap.Put(coInoiceItemRec.CO_Kit_Header__c,coInoiceItemRec );
                } else if(coInoiceItemRec.Service_Order_Header__c !=null && coInoiceItemRec.SO_Payment_Role__c ==null){
                    if(!coInvoiceTypeToLineItemMap.ContainsKey('SoKitInvoice')) {
                        coInvoiceTypeToLineItemMap.Put('SoKitInvoice',new List<CO_Invoice_Item__c>{ coInoiceItemRec});
                    }
                    coInvoiceTypeToLineItemMap.get('SoKitInvoice').add(coInoiceItemRec);
                    invoicedServiceOrderHeaderMap.Put(coInoiceItemRec.Service_Order_Header__c,coInoiceItemRec );
               } else if( coInoiceItemRec.SO_Payment_Role__c !=null) {
                    if(!coInvoiceTypeToLineItemMap.ContainsKey('SoPayment')) {
                        coInvoiceTypeToLineItemMap.Put('SoPayment',new List<CO_Invoice_Item__c>{ coInoiceItemRec});
                    }
                    coInvoiceTypeToLineItemMap.get('SoPayment').add(coInoiceItemRec);
                    invoicedSoPaymentMap.Put(coInoiceItemRec.SO_Payment_Role__c , coInoiceItemRec);
                } else if(coInoiceItemRec.Deal__c !=null){
                    invoicedDealMap.Put(coInoiceItemRec.Deal__c , coInoiceItemRec );
                }
            }                        
            
            List<CO_Line_Item__c> coLineItemDealservice = new List<CO_Line_Item__c>();
            List<Service_Order_Line_Item__c> soLineItemDealservice = new List<Service_Order_Line_Item__c>();
            List<Option_Fee__c> optionAndFeeRecListWithDoNotInvOption = new List<Option_Fee__c>();
            
            if(coInvoiceTypeToLineItemMap.containsKey('SoKitInvoice') ){
                if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }                
                List<Service_Order_Line_Item__c> serviceOrderLineItemFromInvoiceList  = new List<Service_Order_Line_Item__c>([Select Service_Order_Header__c,(Select Qty__c, Qty_Committed__c, Status__c, Price__c, part__c,part__r.Qty_In_Stock__c,
                                                                                                                        part__r.Qty_Committed__c,part__r.Last_Cost__c, Closed_CO_Invoice_link__c,Oversold_Qty__c From CO_Line_Items__r),
                                                                                                                        
                                                                                                                        (Select Id, CO_Line_Item__r.Price__c, Service_Order_Line_Item__r.Kit_Price__c from Options_Fees__r
                                                                                                                            where Do_Not_Invoice__c = true), 
                                                                    
                                                                                                                        Labour_Code__r.Description__c,Fee__r.Description__c, Part__r.Description__c, Qty_Needed__c,Retail_Price__c,Kit_Price__c,CO_Line_Item__c,Service_Order_Header__r.Customer_Owned_Unit__c,Service_Order_Header__r.SO_Type__c,
                                                                                                                        Item_Code__c, Item_Description__c, Service_Order_Header__r.Transaction_Type__r.Type__c, Service_Order_Header__r.Deal__c,
                                                                                                                        Service_Order_Kit_Header__c, Service_Order_Kit_Header__r.Deal_Kit_Header__c, Option_Fee__c
                                                                                                                        
                                                                                                                        From Service_Order_Line_Item__c  where  Service_Order_Header__c  =: invoicedServiceOrderHeaderMap.KeySet()]);
                for( Service_Order_Line_Item__c serviceOrderLineItemFromInvoiceRec : serviceOrderLineItemFromInvoiceList  ){
                    if(invoicedServiceOrderHeaderMap.containsKey(serviceOrderLineItemFromInvoiceRec.Service_Order_Header__c)){
                        CO_Invoice_Item__c   closedCOInvoiceItem =  invoicedServiceOrderHeaderMap.get(serviceOrderLineItemFromInvoiceRec.Service_Order_Header__c);
                        if(serviceOrderLineItemFromInvoiceRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Stock Unit'){
                            soLineItemInternalservice.add(serviceOrderLineItemFromInvoiceRec);
                        } else if(serviceOrderLineItemFromInvoiceRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Deal Service' ) {
                            soLineItemDealservice.add(serviceOrderLineItemFromInvoiceRec);
                            if(String.isNotBlank(serviceOrderLineItemFromInvoiceRec.Service_Order_Kit_Header__c) &&
                                    String.isNotBlank(serviceOrderLineItemFromInvoiceRec.Service_Order_Kit_Header__r.Deal_Kit_Header__c)) {
                                //dealKHIdSet.add(serviceOrderLineItemFromInvoiceRec.Service_Order_Kit_Header__r.Deal_Kit_Header__c);
                            } else {
                                optionAndFeeRecListWithDoNotInvOption.addAll(serviceOrderLineItemFromInvoiceRec.Options_Fees__r);
                            }
                        }
                        
                        List<CO_Line_Item__c> coliUpdateFromServiceOrderInvoiceList = new   List<CO_Line_Item__c>(serviceOrderLineItemFromInvoiceRec.CO_Line_Items__r);
                        for(CO_Line_Item__c colirec : coliUpdateFromServiceOrderInvoiceList ){
                            colirec.Closed_CO_Invoice_link__c = closedCOInvoiceItem.CO_Invoice_Header__r.Name;
                            colirec.Invoice_Number__c = closedCOInvoiceItem.CO_Invoice_Header__c;
                            coLineItemsToUpdated.add(colirec);
                        }
                    }
                }
            }
                    
            if(coInvoiceTypeToLineItemMap.containsKey('ColiInvoice')) {
                if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }                    
                List<CO_Line_Item__c> ColiFromInvoiceList = [SELECT Qty__c, Qty_Committed__c, Price__c, Status__c,part__c,part__r.Qty_In_Stock__c, Related_Option_And_Fees__c,
                                                    (Select Id, CO_Line_Item__r.Price__c, Service_Order_Line_Item__r.Kit_Price__c from Options_Fees__r where Do_Not_Invoice__c = true),
                                                        Part__r.Qty_Committed__c,part__r.Last_Cost__c,closed_CO_Invoice_link__c,Oversold_Qty__c,Deal__c 
                                                        From CO_Line_Item__c where  Id =: invoicedCoLineItemMap.keySet()];
                for(CO_Line_Item__c colirec : ColiFromInvoiceList ){
                    CO_Invoice_Item__c closedCOInvoiceItem = invoicedCoLineItemMap.get(colirec.Id);
                    colirec.Closed_CO_Invoice_link__c = closedCOInvoiceItem.CO_Invoice_Header__r.Name;
                    colirec.Invoice_Number__c = closedCOInvoiceItem.CO_Invoice_Header__c;
                    coLineItemsToUpdated.add(colirec);
                    if(String.isNotBlank(colirec.Related_Option_And_Fees__c)){
                        coLineItemDealservice.add(colirec);
                    }
                    optionAndFeeRecListWithDoNotInvOption.addAll(colirec.Options_Fees__r);
                 }
             }    

                 if(coInvoiceTypeToLineItemMap.containsKey('CoKitInvoice')){
                    if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                    if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                    if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                    

                    List<CO_Kit_Header__c> ColiFromInvoiceList = [Select Id,(Select Qty__c, Qty_Committed__c, Price__c, Status__c,part__c,part__r.Qty_In_Stock__c, Related_Option_And_Fees__c,
                                                                    part__r.Qty_Committed__c,part__r.Last_Cost__c, Closed_CO_Invoice_link__c,Oversold_Qty__c, Deal__c From CO_Line_Items__r)
                                                                    From CO_Kit_Header__c where  Id =: invoicedCOKHMap.KeySet()];
                                                                                            
                    for( CO_Kit_Header__c coKitHeaderFromInvoiceRec : ColiFromInvoiceList ){
                        if(invoicedCOKHMap.containsKey(coKitHeaderFromInvoiceRec.Id)){
                            CO_Invoice_Item__c   closedCOInvoiceItem =  invoicedCOKHMap.get(coKitHeaderFromInvoiceRec.Id);
                            List<CO_Line_Item__c> coliUpdateFromServiceOrderInvoiceList = new   List<CO_Line_Item__c>(coKitHeaderFromInvoiceRec.CO_Line_Items__r);
                            for(CO_Line_Item__c colirec : coliUpdateFromServiceOrderInvoiceList ){
                                colirec.Closed_CO_Invoice_link__c = closedCOInvoiceItem.CO_Invoice_Header__r.Name;
                                colirec.Invoice_Number__c = closedCOInvoiceItem.CO_Invoice_Header__c;
                                coLineItemsToUpdated.add(colirec);
                                if(String.isNotBlank(colirec.Related_Option_And_Fees__c)) {                                         
                                    coLineItemDealservice.add(colirec);
                                }
                            }
                        }
                    }
                }   

            Map<Id,Part__c> updateStockedMap = new Map<Id,Part__c>();
            Map<Id,Part__c> updateStockBucketMap = new Map<Id,Part__c>();
            Set<Id> invoiceableSOIdSet = new Set<Id>();
            List<So_Payment_Role__c> SoPaymentRoleList  = new List<So_Payment_Role__c>();
            Map<String, CO_Line_Item__c> coliIdTocoliRecRelatedToThirdPartyMap = new Map<String, CO_Line_Item__c>();
            Map<Id, Part__c> partIdToPartRecMap = new Map<Id, Part__c>(); 
            if(coInvoiceTypeToLineItemMap.containsKey('SoPayment')) {  
                if(AccessControl.ifObjectFieldIsAccessible('So_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                if(AccessControl.ifObjectFieldIsAccessible('Claim_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

                SoPaymentRoleList  = new List<So_Payment_Role__c>([Select Id,RecordType.DeveloperName, Invoice_Number__c, Service_Order_Header__c, (select Id,Is_Variance__c,Approved_Qty__c,
                                                            Variance_Qty__c,Service_Order_Line_Item__c,Approved_Price__c, Service_Order_Line_Item__r.part__c,
                                                            Service_Order_Line_Item__r.part__r.Qty_In_Stock__c, Service_Order_Line_Item__r.part__r.Qty_Committed__c,
                                                            Service_Order_Line_Item__r.CO_Line_Item__c, 
                                                            Service_Order_Line_Item__r.CO_Line_Item__r.Qty_Committed__c, 
                                                            Service_Order_Line_Item__r.Fee__c,
                                                            Service_Order_Line_Item__r.Qty_Needed__c,
                                                            Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c,Service_Order_Line_Item__r.part__r.Last_Cost__c 
                                                            From Claim_Line_Items__r) From So_Payment_Role__c  where  Id  IN : invoicedSoPaymentMap.KeySet()]);
                         
                for(So_Payment_Role__c SoPaymentRec: SoPaymentRoleList){
                    CO_Invoice_Item__c closedCOInvoiceItem = invoicedSoPaymentMap.get(SoPaymentRec.Id);
                    SoPaymentRec.Invoice_Number__c = activeCOInvoiceHeaderId;
                    if(SoPaymentRec.RecordType.DeveloperName == 'Third_Party' || SoPaymentRec.RecordType.DeveloperName == 'Customer' || 
                    	 											SoPaymentRec.RecordType.DeveloperName == 'Internal') {
                    	SoPaymentRec.Status__c = 'Invoiced'; 											
                        if(SoPaymentRec.RecordType.DeveloperName == 'Third_Party' ) {
                        	for(Claim_Line_Item__c ClaimLineItemrec : SoPaymentRec.Claim_Line_Items__r ){
	                            if(ClaimLineItemrec.Service_Order_Line_Item__r.part__c!=null){
	                                Part__c partRec = new part__c();
	                                partRec.Id =  ClaimLineItemrec.Service_Order_Line_Item__r.part__c;
	                                partRec.Qty_In_Stock__c =  ClaimLineItemrec.Service_Order_Line_Item__r.part__r.Qty_In_Stock__c;
	                                partRec.Qty_Committed__c =  ClaimLineItemrec.Service_Order_Line_Item__r.part__r.Qty_Committed__c;
	                                Decimal qtyNeed = SoPaymentRec.RecordType.DeveloperName == 'Third_Party' ? ClaimLineItemrec.Approved_Qty__c : 
	                                												ClaimLineItemrec.Variance_Qty__c;
	                                Decimal quantityComitted = qtyNeed;
	                                Decimal qtyOverSold = ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c != null ? 
	                                		ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c : 0;
	                                
	                                Decimal ReturnCost = ClaimLineItemrec.Service_Order_Line_Item__r.part__r.last_cost__c !=null ? 
	                                						ClaimLineItemrec.Service_Order_Line_Item__r.part__r.last_cost__c : 0 ; 
	                                ReturnCost = (SoPaymentRec.RecordType.DeveloperName == 'Internal') ? ClaimLineItemrec.Approved_Price__c : ReturnCost;
	                                AddPartToPartMap(updateStockedMap, updateStockBucketMap, quantityComitted, quantityComitted, partRec, 
	                                				PartForPartReturnBuckets, ReturnCost, qtyOverSold);
                                    if(!partIdToPartRecMap.containsKey(partRec.Id)){
                                        partIdToPartRecMap.put(partRec.Id, new Part__c(Id = partRec.Id, Last_Sold__c = system.Now()));
                                    }
	                            }
	                            
	                            if(String.isNotBlank(ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__c)) {
	                                CO_Line_Item__c colirec = new CO_Line_Item__c(Id = ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__c);
	                                colirec.Closed_CO_Invoice_link__c = closedCOInvoiceItem.CO_Invoice_Header__r.Name;
	                                colirec.Invoice_Number__c = closedCOInvoiceItem.CO_Invoice_Header__c;
	                                colirec.Part__c = ClaimLineItemrec.Service_Order_Line_Item__r.Part__c;
	                                colirec.Fee__c = ClaimLineItemrec.Service_Order_Line_Item__r.Fee__c;
	                                colirec.Oversold_Qty__c = ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__r.Oversold_Qty__c;
	                                colirec.Qty_Committed__c = ClaimLineItemrec.Service_Order_Line_Item__r.CO_Line_Item__r.Qty_Committed__c;
	                                colirec.Qty__c = ClaimLineItemrec.Service_Order_Line_Item__r.Qty_Needed__c;
	                                coliIdTocoliRecRelatedToThirdPartyMap.put(colirec.Id, colirec);
	                            }
	                        }
                        	invoiceableSOIdSet.add(SoPaymentRec.Service_Order_Header__c);
                        }
 					} else if(SoPaymentRec.RecordType.DeveloperName == 'deductible'){
	                    SoPaymentRec.Deductible_Status__c = 'Paid';
	                    SoPaymentRec.Status__c = 'Invoiced'; 
                    }
                }                                                                                                    
            }
                
            
            for(CO_Line_Item__c coLineItemsToUpdatedRec : coLineItemsToUpdated){
                if(coLineItemsToUpdatedRec.part__c !=null){
                    Decimal quantityComitted = coLineItemsToUpdatedRec.Qty_Committed__c  ==null ? 0 :coLineItemsToUpdatedRec.Qty_Committed__c;
                    Decimal qtyNeed = coLineItemsToUpdatedRec.Qty__c  ==null ? 0 :coLineItemsToUpdatedRec.Qty__c;
                    Decimal qtyOverSold = coLineItemsToUpdatedRec.Oversold_Qty__c;
                    Part__c  ObjPart = coLineItemsToUpdatedRec.part__r;
                    Decimal ReturnCost = coLineItemsToUpdatedRec.part__r.last_cost__c !=null ?  coLineItemsToUpdatedRec.part__r.last_cost__c : 0 ;
                    AddPartToPartMap(updateStockedMap,  updateStockBucketMap,qtyNeed,quantityComitted,ObjPart,
                             PartForPartReturnBuckets,ReturnCost,qtyOverSold);
                    if(!partIdToPartRecMap.containsKey(coLineItemsToUpdatedRec.Part__c)){
                        partIdToPartRecMap.put(coLineItemsToUpdatedRec.Part__c, new Part__c(Id = coLineItemsToUpdatedRec.Part__c, Last_Sold__c = system.Now()));
                    }
                }
            }
            if(partIdToPartRecMap.size() > 0) { 
                if(AccessControl.ifObjectFieldIsUpdateable('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                update partIdToPartRecMap.values();
            }

            for(CO_Line_Item__c coliRec : coLineItemsToUpdated) {
                if(coliIdTocoliRecRelatedToThirdPartyMap.containskey(coliRec.Id)) {
                    coliIdTocoliRecRelatedToThirdPartyMap.remove(coliRec.Id);
                }
            }
            coLineItemsToUpdated.addAll(coliIdTocoliRecRelatedToThirdPartyMap.values());  
                
            if(PartForPartReturnBuckets.size() > 0){
                FIFOTransaction.createFIFOBucketForCustomerReturn(PartForPartReturnBuckets, activeCOInvoiceHeaderId,coLineItemsToUpdated);
            } 
            List<Part_FIFO_Bucket__c>  PartFifoList=  SOQLUtil.getPartFIFOBucketByPartList(updateStockedMap.keySet());
            Map<Id,List<Part_FIFO_Bucket__c>> PartToFIFOBucketMap   = new Map<Id,List<Part_FIFO_Bucket__c>>();
            for(Part_FIFO_Bucket__c partFifoRec : PartFifoList){
                if(PartToFIFOBucketMap.containsKey(partFifoRec.part__c)){
                        PartToFIFOBucketMap.get(partFifoRec.part__c).add(partFifoRec);
                }else{ 
                    List<Part_FIFO_Bucket__c> listpartFifo  = new List<Part_FIFO_Bucket__c>();
                    listpartFifo.add(partFifoRec);
                    PartToFIFOBucketMap.put(partFifoRec.part__c, listpartFifo);
                } 
            }
                  
            List<Part__c> partFifoBucketValueToUpdate = new List<Part__c>(); 
            if(updateStockBucketMap.size()> 0){
                String Result =  FIFOTransaction.CreateFiFoBucketActivityForInvoice(PartToFIFOBucketMap, activeCOInvoiceHeaderId,updateStockBucketMap.values(),updateStockedMap, coLineItemsToUpdated);
            }
            
            if(coLineItemsToUpdated.size() > 0) {
                COLineItemTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemsToUpdated);
                COLineItemTriggerHelper.isForceStopTrigger = false;
            } 
            
            if(invoicedDealMap.size() > 0 ){
                String dealId = '';
                String invoiceNumber = '';
                for(String  Str : invoicedDealMap.Keyset()){
                    dealId = Str;
                        invoiceNumber = invoicedDealMap.get(dealId).CO_Invoice_Header__r.Invoice_Number__c;
                    break;
                }                       
                DealService.finalizeDeal(dealId, activeCOInvoiceHeaderId, invoiceNumber, invoiceDate);
            } 
            if(SoPaymentRoleList.Size()>0){
                if(AccessControl.ifObjectFieldIsUpdateable('So_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                update SoPaymentRoleList;
            }
            if(soLineItemInternalservice.size()>0){
                string UnitID = soLineItemInternalservice[0].Service_Order_Header__r.Customer_Owned_Unit__c;
                list<Unit_Price_Cost__c> listUnitPriceCostToInsert = DealService.createPriceAndCostLineItem(UnitID, soLineItemInternalservice,activeCOInvoiceHeaderId);
                if(listUnitPriceCostToInsert.size() > 0){
                    DMLUtility.insertSobjectList('Unit_Price_Cost__c', listUnitPriceCostToInsert);
                }           
            }

            
            //Invoicing Deal Item Adding cost to option fee
            if(coLineItemDealservice.size() > 0 || soLineItemDealservice.size() > 0 || optionAndFeeRecListWithDoNotInvOption.size() > 0){
                List<Option_Fee__c> optionFeeListToUpdate = DealService.UpdateOptionFeeInvoice(coLineItemDealservice,soLineItemDealservice, optionAndFeeRecListWithDoNotInvOption);
                if(optionFeeListToUpdate.size() > 0 ){
                    OptionAndFeeTriggerHelper.isForceStopTrigger = true;
                    DMLUtility.updateSobjectList('Option_Fee__c', optionFeeListToUpdate);
                    OptionAndFeeTriggerHelper.isForceStopTrigger = false;
                    DealService.updateOptionFeeStatusAndDealStatus(coHeaderId); 
                }
            }
            
            
            List<CO_Invoice_Payment__c> coInvoicePayments = new List<CO_Invoice_Payment__c>();
            activeCOInvoiceHeaderId = BPUtility.escapeSingleQuotes(activeCOInvoiceHeaderId);
            
            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            coHeaderId = BPUtility.escapeSingleQuotes(coHeaderId);
            activeCOInvoiceHeaderId = BPUtility.escapeSingleQuotes(activeCOInvoiceHeaderId);
            if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            CO_Header__c coHeaderRec =[select CO_Type__c, Customer__c, Order_status__c, 
                        (select Invoice_Status__c from CO_Invoice_Headers__r where Id = :activeCOInvoiceHeaderId),
                        Customer_Contact__r.Is_Contact__c, Customer_Shipping_Address__r.Is_Shipping_Address__c, 
                        Customer_Contact__r.LastName, Customer_Contact__r.Formatted_Phone_number__c, Customer_Contact__r.Email, 
                        Customer_Shipping_Address__r.LastName, Customer_Shipping_Address__r.MailingStreet, Customer_Shipping_Address__r.MailingCity, 
                        Customer_Shipping_Address__r.Mailing_County_Parish__c, Customer_Shipping_Address__r.MailingPostalCode, 
                        Customer_Shipping_Address__r.MailingState, Customer_Shipping_Address__r.MailingCountry 
            										 from CO_Header__c  where Id = :coHeaderId ];
            CO_Invoice_Header__c coInvoiceHeaderRec = coHeaderRec.CO_Invoice_Headers__r[0];

            if(coInvoiceHeaderRec !=null &&  coHeaderRec != null ){
                if(AccessControl.ifObjectFieldIsCreateable('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                if(AccessControl.ifObjectFieldIsCreateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                

                coInvoiceHeaderRec.Invoice_Status__c = 'Closed';
                coInvoiceHeaderRec.Closed_Invoice_Date__c = system.now();
                coInvoiceHeaderRec.Checkout_Type__c = currentCheckoutType;
                coInvoiceHeaderRec.Invoice_Date__c = invoiceDate;
                coInvoiceHeaderRec.Tracking_Number__c = trackingNumber;
                coHeaderRec.Order_status__c='Closed';
                setContactAndShippingFields(coInvoiceHeaderRec, coHeaderRec);
                if(AutonumberRec.Id !=null){
                    coInvoiceHeaderRec.AutoNumberHolder__c = AutonumberRec.Id;
                    DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvoiceHeaderRec);
                    DMLUtility.updateSobjectList('CO_Header__c', coHeaderRec);

                }else{
                      throw new BlackPurlException('Unable to generate Invoice');
                }
            }           
            List<CO_Invoice_Header__c> invoiceRec = new List<CO_Invoice_Header__c>();
            invoiceRec.add(calculateIndividualsTotalsForInvoice(coInvoiceHeaderRec.Id));
            validatePayment(currentCheckoutType, invoiceRec[0], invoicedDealMap.values());
            
            if(invoiceRec.size()>0) {
                invoiceRec[0].Is_Discount_Shown__c = isDisplayDiscountAmountOnPrint;
            }
            Set<Id> soheaderInvoiceIdSet = new Set<Id>(invoicedServiceOrderHeaderMap.keyset());
            soheaderInvoiceIdSet.addAll(invoiceableSOIdSet);
            ServiceJobService.updateSOHeaderList(soheaderInvoiceIdSet, coInvoiceHeaderRec.Id);
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', invoiceRec);
            
            // Populate Totals.
            TaxCalculation.populateOrderTotal(coHeaderId);
            
            String customerId = coHeaderRec.Customer__c;
            // Create Activity History.
            if(!Test.isRunningTest()) {
                ActivityHistory.createActivityHistory('Finalize Customer Invoice', 'Customer Invoice', coInvoiceHeaderRec.Id, 'Customer', customerId, coHeaderId);
            }
            if(!system.isFuture() && !Test.isRunningTest()){
                populateFieldsOnInvoice_future(coInvoiceHeaderRec.Id);
                populateIndividualsCostTotalsAfterFinalize(coInvoiceHeaderRec.Id);
            } else {
                CO_Invoice_Header__c coInvHeaderRec = populateFieldsOnInvoice(coInvoiceHeaderRec.Id);
                DMLUtility.updateSobjectListWithRetry(new List<SObject>{coInvHeaderRec});
            }
            updateMerchServiceSOStatus(coHeaderId);
        } catch(Exception e) {
        	if(!Test.isRunningTest()) {
	        	Database.rollback(sp);
	        }
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));           
        }
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

    private static ResponseWrapper processDeposits(List<CODeposit> coDepositObjList) {
        ResponseWrapper responseObj = new ResponseWrapper('Success', 'Success');
        Map<String, Boolean> ppIdToSignatureValueMap = new Map<String, Boolean>();
        Set<String> preferredPaymentIdSet = new Set<String>();
        for(CODeposit coDepositObjRec : coDepositObjList) {
            if(String.isBlank(coDepositObjRec.PaymentProcessorToken)) {
                preferredPaymentIdSet.add(coDepositObjRec.PreferredPaymentTerminalId);
            }
        }
        if(preferredPaymentIdSet.size() > 0) {
            ppIdToSignatureValueMap = PreferredPaymentService.getPPIdToSignatureValueMap(preferredPaymentIdSet);
        }
        if(GeneralConfiguration.isPreferredPaymentIntegrationEnabled()) {
            for(CODeposit coDepositObj : coDepositObjList) { 
                if(coDepositObj.PaymentMethod.equalsIgnoreCase(PreferredPaymentService.PREFERRED_PAYMENTS) && coDepositObj.Amount != 0) {
                    PreferredPaymentService.PaymentDetail paymentDetailObj = new PreferredPaymentService.PaymentDetail();
                    paymentDetailObj.TerminalId = String.isBlank(coDepositObj.PaymentProcessorToken) ? coDepositObj.PreferredPaymentTerminalId : null;
                    paymentDetailObj.Token = coDepositObj.PaymentProcessorToken;
                    paymentDetailObj.IsSignatureRequired = String.isBlank(coDepositObj.PaymentProcessorToken) ? ppIdToSignatureValueMap.get(coDepositObj.PreferredPaymentTerminalId) : false;
                    if(String.isNotBlank(coDepositObj.ReverseLink)) {
                        responseObj = PreferredPaymentService.refundTransaction(coDepositObj.ReferenceNumber, coDepositObj.Amount);
                    } else if(coDepositObj.Amount < 0) {
                        paymentDetailObj.Amount = coDepositObj.Amount*-1;
                        responseObj = PreferredPaymentService.creditTransaction(paymentDetailObj);
                        coDepositObj.ReferenceNumber = responseObj != null ? responseObj.response : null;
                    }  else if(coDepositObj.Amount > 0) {
                        paymentDetailObj.Amount = coDepositObj.Amount;
                        responseObj = PreferredPaymentService.saleTransaction(paymentDetailObj);
                        if(responseObj.responseStatus == 'Success') {
                            coDepositObj.ReferenceNumber = responseObj.response;
                        }
                    }
                }
            }
        }
        return responseObj;
    }

    private static ResponseWrapper processPayments(List<COInvoicePayment> coInvoicePaymentsObjList) {
        ResponseWrapper responseObj = new ResponseWrapper('Success', 'Success');
        Set<String> preferredPaymentIdSet = new Set<String>();
        Map<String, Boolean> ppIdToSignatureValueMap = new Map<String, Boolean>();
        for(COInvoicePayment coInvoicePaymentObjRec : coInvoicePaymentsObjList) {
            if(String.isBlank(coInvoicePaymentObjRec.PaymentProcessorToken)) {
                preferredPaymentIdSet.add(coInvoicePaymentObjRec.PreferredPaymentTerminalId);
            }
        }
        if(preferredPaymentIdSet.size() > 0) {
            ppIdToSignatureValueMap = PreferredPaymentService.getPPIdToSignatureValueMap(preferredPaymentIdSet);
        }
        if(GeneralConfiguration.isPreferredPaymentIntegrationEnabled()) {
            for(COInvoicePayment coInvoicePaymentObj : coInvoicePaymentsObjList) {
                if(coInvoicePaymentObj.PaymentMethod.equalsIgnoreCase(PreferredPaymentService.PREFERRED_PAYMENTS) && coInvoicePaymentObj.Amount != 0) {
                    PreferredPaymentService.PaymentDetail paymentDetailObj = new PreferredPaymentService.PaymentDetail();
                    paymentDetailObj.TerminalId = String.isBlank(coInvoicePaymentObj.PaymentProcessorToken) ? coInvoicePaymentObj.PreferredPaymentTerminalId : null;
                    paymentDetailObj.Token = coInvoicePaymentObj.PaymentProcessorToken;
                    paymentDetailObj.IsSignatureRequired = String.isBlank(coInvoicePaymentObj.PaymentProcessorToken) ? ppIdToSignatureValueMap.get(coInvoicePaymentObj.PreferredPaymentTerminalId) : false;
                    if(String.isNotBlank(coInvoicePaymentObj.ReverseLink)) {
                        responseObj = PreferredPaymentService.refundTransaction(coInvoicePaymentObj.ReferenceNumber, coInvoicePaymentObj.Amount);
                    } else if(coInvoicePaymentObj.Amount < 0) {
                        paymentDetailObj.Amount = coInvoicePaymentObj.Amount*-1;
                        responseObj = PreferredPaymentService.creditTransaction(paymentDetailObj);
                        coInvoicePaymentObj.ReferenceNumber = responseObj != null ? responseObj.response : null;
                    } else if(coInvoicePaymentObj.Amount > 0) {
                        paymentDetailObj.Amount = coInvoicePaymentObj.Amount;
                        responseObj = PreferredPaymentService.saleTransaction(paymentDetailObj);
                        if(responseObj.responseStatus == 'Success') {
                            coInvoicePaymentObj.ReferenceNumber = responseObj.response;
                        }
                    }
                }
            }
        }
        return responseObj;
    }

    /*
    *   Method to calculate Part, Labour, fee sublet and Tax total on closed Invoice.
    */
    public static CO_Invoice_Header__c calculateIndividualsTotalsForInvoice(String coInvoiceId) {
        return calculateIndividualsTotalsForInvoice(coInvoiceId, true);
    }
    
    public static CO_Invoice_Header__c calculateIndividualsTotalsForInvoice(String coInvoiceId, Boolean isInvoiceFinalized) {
        CO_Invoice_Header__c coInvoice = getInvoiceRec(coInvoiceId);
        return calculateInvoiceTotals(new List<CO_Invoice_Header__c>{coInvoice}, isInvoiceFinalized);                                        
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
    
    public static CO_Invoice_Header__c calculateInvoiceTotals(List<CO_Invoice_Header__c> coInvoiceList) {
        return calculateInvoiceTotals(coInvoiceList, true);
    }
    
    public static CO_Invoice_Header__c calculateInvoiceTotals(List<CO_Invoice_Header__c> coInvoiceList, Boolean isInvoiceFinalized) {
        if(coInvoiceList.size() == 0) {
            return new CO_Invoice_Header__c();
        }
        CO_Invoice_Header__c coInvoice = coInvoiceList[0]; 
        
        List<Id> coliIds = new List<Id>();  
        List<Id> sohIds = new List<Id>();
        List<Id> soPaymentRoleIds = new List<Id>();
        List<Id> cokhIds = new List<Id>();
        List<Id> dealIds = new List<Id>();
        String invoiceType = '';
                                                  
        for(CO_Invoice_Item__c coInvoiceItem : coInvoice.CO_Invoice_Items__r) {
            if(coInvoice.CO_Header__r.Order_Status__c == 'Quote' || !isInvoiceFinalized || (coInvoice.CO_Header__r.Order_Status__c != 'Quote' && coInvoiceItem.isActive__c)) {
                if(coInvoiceItem.CO_Line_Item__c != null) { 
                	if(isInvoiceFinalized || coInvoiceItem.CO_Line_Item__r.Deal__c == null) {
                    	coliIds.add(coInvoiceItem.CO_Line_Item__c);
                	}
                } else if(coInvoiceItem.Service_Order_Header__c != null) {
                	if(isInvoiceFinalized || coInvoiceItem.Service_Order_Header__r.Deal__c == null) {
	                    if(coInvoiceItem.SO_Payment_Role__c != null && coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible') {
	                        soPaymentRoleIds.add(coInvoiceItem.SO_Payment_Role__c);
	                    } else {
	                        sohIds.add(coInvoiceItem.Service_Order_Header__c);
	                    }
                	}
                } else if(coInvoiceItem.Deal__c != null) {
                    dealIds.add(coInvoiceItem.Deal__c);
                } else if(coInvoiceItem.CO_Kit_Header__c != null) {
                	if(isInvoiceFinalized || coInvoiceItem.Service_Order_Header__r.Deal__c == null) {
                    	cokhIds.add(coInvoiceItem.CO_Kit_Header__c);
                	}
                }
            }
         }
        
        List<CO_Line_Item__c> coliList = new List<CO_Line_Item__c>();
        List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
        List<SO_Payment_Role__c> soPaymentRoleList = new List<SO_Payment_Role__c>();
        List<CO_Kit_Header__c> coKitHeaderList = new List<CO_Kit_Header__c>();
        List<Deal__c> dealList = new List<Deal__c>();
        
        if(coliIds.size() > 0) {
            coliList = [SELECT Item_ID__c, Part__c, Fee__c, Qty__c, Qty_Committed__c, Price__c, Deal__c, Price_When_Tax_Included__c, Actual_Retail_Price__c, 
                             CO_Header__r.Order_status__c, Part__r.Non_Inventory_Part__c FROM CO_Line_Item__c WHERE Service_Order_Line_Item__c = null AND Id IN: coliIds];
        }
                                             
        if(sohIds.size() > 0) {                                   
            soHeaderList =  [select Total_Parts__c, Total_Fees__c, Total_Labor__c, Total_Sublet__c, Total_Shop_Supplies__c, Total_Discount__c,Transaction_Type__r.Type__c, (SELECT Id, Kit_Price__c, Labour_Code__c, 
                                      Part__c, Sublet__c, Qty_Needed__c, Total__c, Fee__c, Tax_Percent__c, Tax_Amount__c FROM Service_Order_Line_Items__r), (SELECT Id, RecordType.DeveloperName, Total_Amount__c FROM SO_Payment_Roles__r where RecordType.DeveloperName = 'Deductible') 
                                FROM Service_Order_Header__c WHERE Id IN: sohIds];
        }
        
        if(soPaymentRoleIds.size() > 0) {
            soPaymentRoleList =  [SELECT Id, Service_Order_Header__c, RecordType.DeveloperName, Total_Amount__c FROM SO_Payment_Role__c WHERE Id IN: soPaymentRoleIds];
        }
                                                                          
        if(cokhIds.size() > 0) {                                   
            coKitHeaderList =  [select Id, Total_Discount__c, Deal__c, Price__c, Tax_Amount__c, (SELECT Id, Part__c, Fee__c, Qty__c, Price__c, 
                                        Deal__c, Sub_Total_Without_Tax__c, Price_When_Tax_Included__c, Tax__c, Sub_Total_With_Tax__c
                                        FROM CO_Line_Items__r)  FROM CO_Kit_Header__c WHERE Id IN: cokhIds];
        }
        
        if(dealIds.size() > 0) {                                   
            dealList =  [select Id, Part_Total__c, Labour_Total__c, Fee_Total__c, Lien_Payout_Total__c, Warranty_Product_Total__c, Sublet_Total__c, 
                            Other_Product_Total__c, Trade_In_Total__c, Trade_In_Tax_Total__c, Unit_Price_And_Cost_Total__c, Type__c, F_I_Total__c, F_I_Tax_Total__c, 
                            Product_Total__c, Stamp_Duty_Total__c, Deal_Commission__c, Total_Finance_Commission__c,
                            Salesperson_Name__c FROM Deal__c 
                            WHERE Id IN: dealIds];
        }
                                                                        
        boolean IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal partTotal = 0;
        Decimal labourTotal = 0;
        Decimal feeTotal = 0;
        Decimal lienPayoutTotal = 0;
        Decimal subletTotal = 0;
        Decimal unitTotal = 0;
        Decimal tradeInsTotal = 0;
        Decimal tradeInsTaxTotal = 0;
        Decimal warrantyProductTotal = 0;
        Decimal stampDutyTotal = 0;
        Decimal otherProductTotal = 0;
        Decimal productTotal = 0;
        Decimal shopSupplyTotal = 0;
        Decimal salesTaxTotal = 0;
        Decimal totalDiscount = 0;
        Decimal deductibleTotal = 0;
        Decimal fandIProductTotal = 0;
        Decimal dealCommission = 0;
        
        for(CO_Line_Item__c coli : coliList) {
            coli.Price__c = (coli.Price__c != null) ? coli.Price__c : 0;
            coli.Qty__c = (coli.Qty__c != null) ? coli.Qty__c : 0;
            coli.Actual_Retail_Price__c = (coli.Actual_Retail_Price__c != null) ? coli.Actual_Retail_Price__c : 0;
            Decimal discount = 0;
            if(coli.Part__c != null) {
                coli.Qty_Committed__c = (coli.Qty_Committed__c != null) ? coli.Qty_Committed__c : 0;
                Decimal qty = (!coli.Part__r.Non_Inventory_Part__c && coli.Qty__c > 0 && coli.CO_Header__r.Order_status__c != 'Quote') ? coli.Qty_Committed__c : coli.Qty__c;
                
                if(!isTaxIncludingPricing || String.isNotBlank(coli.Deal__c)) {
                    partTotal += (qty * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                    if(qty > 0) {
                        discount = (coli.Actual_Retail_Price__c - coli.Price__c) * qty;
                    }
                } else {
                    if(coli.Price_When_Tax_Included__c == null) {
                        coli.Price_When_Tax_Included__c = 0;
                    }
                    partTotal += (qty * coli.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
                    if(qty > 0) {
                        discount = (coli.Actual_Retail_Price__c - coli.Price_When_Tax_Included__c) * qty;
                    }
                }
                totalDiscount += (discount > 0) ? discount : 0;
            
            } else if(coli.Fee__c != null) {
                if(!isTaxIncludingPricing) {
                    feeTotal += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                } else {
                    feeTotal += (coli.Qty__c * coli.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
                }
            }
        }
        
        Set<Id> soIdsToIncludeTax = new Set<Id>();
        
        for(SO_Payment_Role__c soPaymentRoleRec : soPaymentRoleList) {
            deductibleTotal += (soPaymentRoleRec.Total_Amount__c != null) ? soPaymentRoleRec.Total_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0;
            if(soPaymentRoleRec.RecordType.DeveloperName != 'Deductible' ) {
                soIdsToIncludeTax.add(soPaymentRoleRec.Service_Order_Header__c);
            }
        }
        
        for(Service_Order_Header__c soHeaderRec : soHeaderList) {
            soIdsToIncludeTax.add(soHeaderRec.Id);
            partTotal += (soHeaderRec.Total_Parts__c != null) ? soHeaderRec.Total_Parts__c.setScale(2, RoundingMode.HALF_UP) : 0;
            feeTotal += (soHeaderRec.Total_Fees__c != null) ? soHeaderRec.Total_Fees__c.setScale(2, RoundingMode.HALF_UP) : 0;
            labourTotal += (soHeaderRec.Total_Labor__c != null) ? soHeaderRec.Total_Labor__c.setScale(2, RoundingMode.HALF_UP) : 0;
            subletTotal += (soHeaderRec.Total_Sublet__c != null) ? soHeaderRec.Total_Sublet__c.setScale(2, RoundingMode.HALF_UP) : 0;
            productTotal += (soHeaderRec.Total_Sublet__c != null) ? soHeaderRec.Total_Sublet__c.setScale(2, RoundingMode.HALF_UP) : 0;
            shopSupplyTotal += (soHeaderRec.Total_Shop_Supplies__c != null) ? soHeaderRec.Total_Shop_Supplies__c.setScale(2, RoundingMode.HALF_UP) : 0;
            totalDiscount += ((soHeaderRec.Total_Discount__c != null) && (soHeaderRec.Total_Discount__c > 0)) ? soHeaderRec.Total_Discount__c : 0;
            if(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party' && soHeaderRec.SO_Payment_Roles__r.size() > 0) {
                deductibleTotal += (soHeaderRec.SO_Payment_Roles__r[0].Total_Amount__c != null) ? -1 * (soHeaderRec.SO_Payment_Roles__r[0].Total_Amount__c.setScale(2, RoundingMode.HALF_UP)) : 0;
                invoiceType = 'Third-Party';
                soPaymentRoleIds.add(soHeaderRec.SO_Payment_Roles__r[0].Id);
            }
        }
                
        for(CO_Kit_Header__c coKitHeader : coKitHeaderList) {
            for(CO_Line_Item__c coli : coKitHeader.CO_Line_Items__r){
                if(coli.Part__c != null && coli.Qty__c != null && coli.Price__c != null){
                    if(!isTaxIncludingPricing || (isTaxIncludingPricing && coKitHeader.Deal__c != null)) {
                        partTotal += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                    }else if(coli.Sub_Total_With_Tax__c != null) {
                        partTotal += (coli.Qty__c * coli.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
                    }
                } else if(coli.Fee__c != null && coli.Qty__c != null && coli.Price__c != null){
                    if(!isTaxIncludingPricing || (isTaxIncludingPricing && coKitHeader.Deal__c != null)) {
                        feeTotal += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
                    }else if(coli.Sub_Total_With_Tax__c != null){
                        feeTotal += (coli.Qty__c * coli.Price_When_Tax_Included__c).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
            totalDiscount += ((coKitHeader.Total_Discount__c != null) && (coKitHeader.Total_Discount__c > 0)) ? coKitHeader.Total_Discount__c : 0;
        }
        
        for(Deal__c dealRec : dealList) {
            unitTotal += (dealRec.Unit_Price_And_Cost_Total__c != null) ? dealRec.Unit_Price_And_Cost_Total__c : 0;
            partTotal += (dealRec.Part_Total__c != null) ? dealRec.Part_Total__c : 0;
            feeTotal += (dealRec.Fee_Total__c != null) ? dealRec.Fee_Total__c : 0;
            lienPayoutTotal += (dealRec.Lien_Payout_Total__c != null) ? dealRec.Lien_Payout_Total__c : 0;
            labourTotal += (dealRec.Labour_Total__c != null) ? dealRec.Labour_Total__c : 0;
            tradeInsTotal += (dealRec.Trade_In_Total__c != null) ? dealRec.Trade_In_Total__c : 0;
            tradeInsTaxTotal += dealRec.Trade_In_Tax_Total__c != null ? dealRec.Trade_In_Tax_Total__c : 0;
            warrantyProductTotal += (dealRec.Warranty_Product_Total__c != null) ? dealRec.Warranty_Product_Total__c : 0;
            subletTotal += (dealRec.Sublet_Total__c != null) ? dealRec.Sublet_Total__c : 0;
            otherProductTotal += (dealRec.Other_Product_Total__c != null) ? dealRec.Other_Product_Total__c : 0;
            productTotal += (dealRec.Product_Total__c != null) ? dealRec.Product_Total__c : 0;
            stampDutyTotal += (dealRec.Stamp_Duty_Total__c != null) ? dealRec.Stamp_Duty_Total__c : 0;
            dealCommission = (dealRec.Deal_Commission__c != null) ? dealRec.Deal_Commission__c : 0;
            coInvoice.Total_Finance_Commission__c = (dealRec.Total_Finance_Commission__c != null) ? dealRec.Total_Finance_Commission__c : 0;
            
            if(dealRec.Type__c == Constants.FINANCED) {
                fandIProductTotal += (dealRec.F_I_Total__c != null) ? dealRec.F_I_Total__c : 0;
                if(isTaxIncludingPricing) {
                    fandIProductTotal += (dealRec.F_I_Tax_Total__c != null) ? dealRec.F_I_Tax_Total__c : 0;
                }
            }
        }
        
        TaxCalculation.isInvoiced = (coInvoice.Invoice_Status__c == 'Active') ? false : true;
        List<Individual_Tax__c> individualItemsList = getConditionalIndividualTaxList(isTaxIncludingPricing, TaxCalculation.isInvoiced, coliIds, cokhIds, 
                                                                    soIdsToIncludeTax, dealIds, soPaymentRoleIds);
        
        Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList, invoiceType);
        TaxCalculation.isInvoiced = true;
        for(String taxName : salesTaxNameToTaxValue.keySet()) {
            salesTaxTotal += salesTaxNameToTaxValue.get(taxName); 
        }
                                           
        coInvoice.Part_Total__c = partTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Labour_Total__c = labourTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Fee_Total__c = feeTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Lien_Payout_Total__c = lienPayoutTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Sublet_Total__c = subletTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Stamp_Duty_Total__c = stampDutyTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Unit_Total__c = unitTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Shop_Supplies_Total__c = shopSupplyTotal.setScale(2, RoundingMode.HALF_UP);
        
        coInvoice.Trade_In_Total__c = tradeInsTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Trade_In_Tax_Total__c = tradeInsTaxTotal.setScale(2, RoundingMode.HALF_UP); //Only to exclude in profitability
        
        coInvoice.Warranty_Product_Total__c = warrantyProductTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Other_Product_Total__c = otherProductTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Product_Total__c = productTotal.setScale(2, RoundingMode.HALF_UP);
        
        coInvoice.SalesTax_Total__c = salesTaxTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Discount_Amount__c = totalDiscount.setScale(2, RoundingMode.HALF_UP);
        coInvoice.F_I_Total__c = fandIProductTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Deductible_Total__c = deductibleTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoice.Deal_Commission__c = dealCommission.setScale(2, RoundingMode.HALF_UP);
        // Added by TK : Update Total Variable on Invoice Header when Finalise Invoice/Order.
        coInvoice.Total__c = coInvoice.Part_Total__c + coInvoice.Labour_Total__c + coInvoice.Fee_Total__c + coInvoice.Lien_Payout_Total__c 
        								+ unitTotal + coInvoice.Trade_In_Total__c + coInvoice.Product_Total__c + coInvoice.Stamp_Duty_Total__c 
                                        + coInvoice.Shop_Supplies_Total__c + coInvoice.Deductible_Total__c + coInvoice.F_I_Total__c;
        if(!isTaxIncludingPricing){
            coInvoice.Total__c += coInvoice.SalesTax_Total__c;
        }
        return coInvoice;
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
    
    public static CO_Invoice_Header__c populateFieldsOnInvoice(CO_Invoice_Header__c coInvoiceRec) {
        boolean IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        
        List<Id> coliIds = new List<Id>();
        List<Id> sohIds = new List<Id>();
        List<Id> cokhIds = new List<Id>();
        List<Id> dealIds = new List<Id>();       

        for(CO_Invoice_Item__c coInvoiceItem : coInvoiceRec.CO_Invoice_Items__r) {
            if(coInvoiceItem.CO_Line_Item__c != null) { 
                coliIds.add(coInvoiceItem.CO_Line_Item__c);
            } else if(coInvoiceItem.CO_Kit_Header__c != null) {
                cokhIds.add(coInvoiceItem.CO_Kit_Header__c);
            } else if(coInvoiceItem.Service_Order_Header__c != null) {
            	if(coInvoiceItem.SO_Payment_Role__c == null || coInvoiceItem.SO_Payment_Role__r.RecordType.DeveloperName != 'Deductible') {
                    sohIds.add(coInvoiceItem.Service_Order_Header__c);
                }
            } else if(coInvoiceItem.Deal__c != null) {
                coInvoiceRec.Is_Deal_Invoiced__c = true;
                dealIds.add(coInvoiceItem.Deal__c);
            }
        }
        
        List<CO_Line_Item__c> coliList = new List<CO_Line_Item__c>();
        List<Service_Order_Line_Item__c> soliList = new List<Service_Order_Line_Item__c>();
        List<Option_Fee__c> optionFeeList = new List<Option_Fee__c>();
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList = new List<Deal_Unit_Price_Cost__c>();
        List<F_I_Product__c> fAndIProductList = new List<F_I_Product__c>();
        List<Individual_Tax__c> individualTaxForDealList = new List<Individual_Tax__c>();
        if(coliIds.size() > 0 || cokhIds.size() > 0) {
            coliList = [SELECT Qty__c, Qty_Committed__c, Part__r.Non_Inventory_Part__c, Price__c, Deal__c, Price_When_Tax_Included__c, Actual_Retail_Price__c, Part__c, Fee__c, 
                        Item_ID__c, Adjusted_Cost_Coli__c, Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c, Fee__r.Is_Include_In_Profit_Calculation__c, 
                            (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0)
                           FROM CO_Line_Item__c WHERE Service_Order_Line_Item__c = null AND (Id IN: coliIds OR CO_Kit_Header__c IN: cokhIds)];
                           
        }
                                             
        if(sohIds.size() > 0) {
            soliList = [SELECT Kit_Price__c, Qty_Needed__c, Part__c, Fee__c, Labour_Code__c, Sublet__c, Service_Order_Header__c, Actual_Retail_Price__c, 
            Cost__c, Total_Cost__c, Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c, Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c,
            Sublet__r.Cost_Method__c, Sublet__r.Cost__c, Fee__r.Is_Include_In_Profit_Calculation__c, Price_When_Tax_Included__c, Type__c,
            (select Adjusted_Cost_Coli__c from CO_Line_Items__r),  
            (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0)
                                FROM Service_Order_Line_Item__c where Service_Order_Header__c IN: sohIds];
        }
        
        if(dealIds.size() > 0) {
            if(!GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c) {
                individualTaxForDealList = [Select Id, Sales_Tax_Item__c, Tax_Rate__c, Enhanced_Tax_Amount__c FROM Individual_Tax__c WHERE Deal__c IN: dealIds];
            }

            optionFeeList = [SELECT Price__c, Qty__c, Part__c, Fee__c, Labour_Code__c, Product__c, Product__r.Type__c, Applicable_Tax__c,
                            Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c, Product__r.Cost__c, Product__r.Cost_Method__c, Deal_Item__r.Taxable__c, Deal_Item__r.Unit_Tax_Applicable_On__c,
                            Deal_Kit_Header__c, Fee__r.Is_Include_In_Profit_Calculation__c, Cost__c, Price_When_Tax_Included__c, 
                            Part__r.Taxable__c, Fee__r.Taxable__c , Labour_Code__r.Taxable__c , Product__r.Taxable__c ,
                            (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0) 
                                from Option_Fee__c where Deal__c IN: dealIds];

            dealItemList = [SELECT Agreed_Value__c, Actual_Cash_Value__c, Default_Unit_Sales_Tax_Percentage__c, Type__c, Lien_Payout__c, Stamp_Duty_Total__c, 
                                Deal__r.Total_Commission_Cost__c, Deal__r.Deal_Commission__c, Taxable__c , Unit_Tax_Applicable_On__c, Applicable_Tax__c,
                                (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0)
                                from Deal_Item__c WHERE (Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN OR Lien_Payout__c > 0 OR Stamp_Duty_Total__c != null) AND Deal__c IN: dealIds];
            
            dealUnitPriceAndCostList = [Select Qty__c, Price__c, Type__c, Total_Cost__c, Unit_Price_Cost__r.Total_Cost__c, Deal_Item__r.Deal__r.Total_Commission_Cost__c, Deal_Item__r.Deal__r.Deal_Commission__c, 
                                        Deal_Item__r.Taxable__c, Applicable_Tax__c,
                                        (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0) 
                                        from Deal_Unit_Price_Cost__c where Deal_Item__r.Deal__c IN: dealIds];
                            
            fAndIProductList = [Select Price__c, Sales_Tax__c, Cost__c,Vendor_Product__r.Taxable__c, Applicable_Tax__c, (Select Id from Individual_Taxes__r WHERE Tax_Rate__c > 0 OR Enhanced_Tax_Amount__c != 0) 
                            from F_I_Product__c where Deal__c IN: dealIds OR Deal_Finance__r.Deal__c IN: dealIds];
        }

        populatePreTaxTotals(coInvoiceRec, coliList, soliList, optionFeeList, dealItemList, dealUnitPriceAndCostList, fAndIProductList, individualTaxForDealList);
        populateCostTotals(coInvoiceRec, coliList, soliList, optionFeeList, dealItemList, dealUnitPriceAndCostList, fAndIProductList);
        return coInvoiceRec;
    }

    private static CO_Invoice_Header__c populateCostTotals(CO_Invoice_Header__c coInvoiceRec, 
        List<CO_Line_Item__c> coliList, 
        List<Service_Order_Line_Item__c> soliList, 
        List<Option_Fee__c> optionFeeList,
        List<Deal_Item__c> dealItemList,
        List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList,
        List<F_I_Product__c> fAndIProductList) {
        Decimal totalInvoiceCost = 0;     
        Decimal feeTotalExcludedInProfitability = 0;
        
        for(CO_Line_Item__c coliRec : coliList) {
            if(coliRec.Part__c != null) {
                totalInvoiceCost += (coliRec.Adjusted_Cost_Coli__c != null) ? coliRec.Adjusted_Cost_Coli__c : 0 ;
            } else if(coliRec.Fee__c != null) {
                if(coliRec.Fee__r.Is_Include_In_Profit_Calculation__c) {
                    if(coliRec.Fee__r.Cost_Method__c == 'Fixed Cost' && coliRec.Fee__r.Cost_Rate__c != null && coliRec.Qty__c != null) {
                        totalInvoiceCost += (coliRec.Qty__c * coliRec.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
                    } else if(coliRec.Fee__r.Cost_Method__c == 'Percent Retail' && coliRec.Fee__r.Cost_Rate__c != null && coliRec.Qty__c != null) {
                        totalInvoiceCost += (coliRec.Qty__c * ((coliRec.Price__c * coliRec.Fee__r.Cost_Rate__c) /100)).setScale(2, RoundingMode.HALF_UP);
                    }
                } else {
                    feeTotalExcludedInProfitability += (coliRec.Qty__c * coliRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                }
            }
        }
        
        for(Service_Order_Line_Item__c soliRec : soliList) {
            if(soliRec.Part__c != null){
                for(CO_Line_Item__c coliRec : soliRec.CO_Line_Items__r) {
                    totalInvoiceCost += (coliRec.Adjusted_Cost_Coli__c != null) ? coliRec.Adjusted_Cost_Coli__c : 0;
                }
                
            } else if(soliRec.Fee__c != null) {
                if(soliRec.Fee__r.Is_Include_In_Profit_Calculation__c) {
                    if(soliRec.Fee__r.Cost_Method__c == 'Fixed Cost' && soliRec.Fee__r.Cost_Rate__c !=null && soliRec.Qty_Needed__c != null) {
                        totalInvoiceCost += (soliRec.Qty_Needed__c * soliRec.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
                    } else if(soliRec.Fee__r.Cost_Method__c == 'Percent Retail'  && soliRec.Fee__r.Cost_Rate__c !=null &&  soliRec.Qty_Needed__c !=null ){
                        totalInvoiceCost += (soliRec.Qty_Needed__c * ((soliRec.Kit_Price__c *  soliRec.Fee__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
                    }
                } else {
                    feeTotalExcludedInProfitability += (soliRec.Qty_Needed__c * soliRec.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
                }
            } else if(soliRec.Labour_Code__c != null) {
            	if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
					soliRec.Total_Cost__c = (soliRec.Total_Cost__c != null ? soliRec.Total_Cost__c : 0);
					totalInvoiceCost += (soliRec.Total_Cost__c).setScale(2, RoundingMode.HALF_UP);
    			} else {
    				if(soliRec.Labour_Code__r.Cost_Method__c == 'Fixed Cost' && soliRec.Labour_Code__r.Cost_Rate__c != null && soliRec.Qty_Needed__c !=null){
	                    totalInvoiceCost += (soliRec.Qty_Needed__c * soliRec.Labour_Code__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
	                } else if(soliRec.Labour_Code__r.Cost_Method__c == 'Percent Retail' && soliRec.Labour_Code__r.Cost_Rate__c !=null && soliRec.Qty_Needed__c !=null ){
	                    totalInvoiceCost += (soliRec.Qty_Needed__c * ((soliRec.Kit_Price__c *  soliRec.Labour_Code__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
	                }
    			}
	        			
            } else if(soliRec.Sublet__c != null ) {
                if(soliRec.Cost__c != null && soliRec.Qty_Needed__c != null) {
                    totalInvoiceCost += soliRec.Cost__c * soliRec.Qty_Needed__c;
                } else if(soliRec.Sublet__r.Cost_Method__c == 'Fixed Cost' && soliRec.Sublet__r.Cost__c != null && soliRec.Qty_Needed__c !=null){
                    totalInvoiceCost += (soliRec.Qty_Needed__c * soliRec.Sublet__r.Cost__c).setScale(2, RoundingMode.HALF_UP);
                } else if(soliRec.Sublet__r.Cost_Method__c == 'Percent Retail' && soliRec.Sublet__r.Cost__c !=null && soliRec.Qty_Needed__c !=null ){
                    totalInvoiceCost += (soliRec.Qty_Needed__c * ((soliRec.Kit_Price__c *  soliRec.Sublet__r.Cost__c)/100)).setScale(2, RoundingMode.HALF_UP);
                }
            }
        }
        
        Decimal totalDealInvoiceCost = 0;
        for(Option_Fee__c optionFeeRec : optionFeeList) {
            if(optionFeeRec.Fee__c != null) {
                if(optionFeeRec.Fee__r.Is_Include_In_Profit_Calculation__c) {
                    if(optionFeeRec.Deal_Kit_Header__c != null) {
                        totalDealInvoiceCost += ((optionFeeRec.Cost__c != null) ? (optionFeeRec.Qty__c * optionFeeRec.Cost__c) : 0).setScale(2, RoundingMode.HALF_UP);
                    } else {
                        if(optionFeeRec.Fee__r.Cost_Method__c == 'Fixed Cost' && optionFeeRec.Fee__r.Cost_Rate__c != null && optionFeeRec.Qty__c != null) {
                            totalDealInvoiceCost += (optionFeeRec.Qty__c * optionFeeRec.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
                        } else if(optionFeeRec.Fee__r.Cost_Method__c == 'Percent Retail'  && optionFeeRec.Fee__r.Cost_Rate__c != null && optionFeeRec.Qty__c != null) {
                            totalDealInvoiceCost += (optionFeeRec.Qty__c * ((optionFeeRec.Price__c * optionFeeRec.Fee__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
                        }
                    }
                } else {
                    feeTotalExcludedInProfitability += (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                }
            } else if(optionFeeRec.Product__c != null ) {
                if(optionFeeRec.Product__r.Type__c == Constants.SUBLET) {
                    totalDealInvoiceCost += ((optionFeeRec.Cost__c != null) ? optionFeeRec.Cost__c : 0).setScale(2, RoundingMode.HALF_UP);
                } else {
                    if(optionFeeRec.Product__r.Cost_Method__c == 'Fixed Cost' && optionFeeRec.Product__r.Cost__c != null && optionFeeRec.Qty__c != null) {
                        totalDealInvoiceCost += (optionFeeRec.Qty__c * optionFeeRec.Product__r.Cost__c).setScale(2, RoundingMode.HALF_UP);
                    } else if(optionFeeRec.Product__r.Cost_Method__c == 'Percent Retail'  && optionFeeRec.Product__r.Cost__c != null && optionFeeRec.Qty__c != null) {
                        totalDealInvoiceCost += (optionFeeRec.Qty__c * ((optionFeeRec.Price__c * optionFeeRec.Product__r.Cost__c)/100)).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            } else if((optionFeeRec.Part__c != null || optionFeeRec.Labour_Code__c != null) && optionFeeRec.Cost__c != null) {
                totalDealInvoiceCost += (optionFeeRec.Qty__c * optionFeeRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
            }
        }
        
        for(Deal_Unit_Price_Cost__c dealUnitPriceCostRec : dealUnitPriceAndCostList) {
            if(dealUnitPriceCostRec.Type__c == 'Base' && dealUnitPriceCostRec.Total_Cost__c != null) {
				totalDealInvoiceCost += dealUnitPriceCostRec.Total_Cost__c.setScale(2, RoundingMode.HALF_UP);
			} else if(dealUnitPriceCostRec.Unit_Price_Cost__r.Total_Cost__c != null) {
				totalDealInvoiceCost += dealUnitPriceCostRec.Unit_Price_Cost__r.Total_Cost__c.setScale(2, RoundingMode.HALF_UP);
			}
        }
        
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
				dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c : 0;
				dealItemRec.Actual_Cash_Value__c = (dealItemRec.Actual_Cash_Value__c != null) ? dealItemRec.Actual_Cash_Value__c : 0;
				if(GeneralConfiguration.getTaxIncludingPricing()) {
					dealItemRec.Default_Unit_Sales_Tax_Percentage__c = (dealItemRec.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItemRec.Default_Unit_Sales_Tax_Percentage__c : 0;
					dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100));
				}
				totalDealInvoiceCost += (dealItemRec.Agreed_Value__c - dealItemRec.Actual_Cash_Value__c).setScale(2, RoundingMode.HALF_UP);
			}
        }

        for(F_I_Product__c fiProductRec: fAndIProductList) {
            totalDealInvoiceCost += (fiProductRec.Cost__c != null ? fiProductRec.Cost__c : 0).setScale(2, RoundingMode.HALF_UP);
        }
        
        totalInvoiceCost += totalDealInvoiceCost;
        coInvoiceRec.Deal_Cost__c = totalDealInvoiceCost;
        coInvoiceRec.Invoice_Cost__c = totalInvoiceCost;
        coInvoiceRec.Fee_Total_Excluded_In_Profitability__c = feeTotalExcludedInProfitability;
        
        List<Customer_Owned_Unit__c> unitListToUpdate = DealService.calculateDealOptionsWIPCost(coInvoiceRec.Id);
        if(unitListToUpdate.size() > 0) {
            update unitListToUpdate;
        }
        return coInvoiceRec;
    }
    
    public static CO_Invoice_Header__c populatePreTaxTotals(CO_Invoice_Header__c coInvoiceRec, 
        List<CO_Line_Item__c> coliList, 
        List<Service_Order_Line_Item__c> soliList, 
        List<Option_Fee__c> optionFeeList,
        List<Deal_Item__c> dealItemList,
        List<Deal_Unit_Price_Cost__c> dealUnitPriceAndCostList,
        List<F_I_Product__c> fAndIProductList,
        List<Individual_Tax__c> individualTaxForDealList) {
        Decimal taxableAmount = 0, nonTaxableAmount = 0;
        //Pre Tax Totals
        Decimal preTaxPartTotal = 0, preTaxLabourTotal = 0, preTaxFeeTotal = 0, preTaxSubletTotal = 0, preTaxUnitTotal = 0, preTaxTradeInsTotal = 0;
        Decimal preTaxWarrantyProductTotal = 0, preTaxOtherProductTotal = 0, preTaxShopSupplyTotal = 0;

        for(CO_Line_Item__c coliRec : coliList) {
            coliRec.Price__c = (coliRec.Price__c != null) ? coliRec.Price__c : 0;
            coliRec.Qty__c = (coliRec.Qty__c != null) ? coliRec.Qty__c : 0;
            if(coliRec.Individual_Taxes__r.size() > 0) {
                taxableAmount += (coliRec.Price__c * coliRec.Qty__c);
            } else {
                nonTaxableAmount += (coliRec.Price__c * coliRec.Qty__c);
            }
            
            if(coliRec.Part__c != null) {
                coliRec.Qty_Committed__c = (coliRec.Qty_Committed__c != null) ? coliRec.Qty_Committed__c : 0;
                Decimal qty = (!coliRec.Part__r.Non_Inventory_Part__c && coliRec.Qty__c > 0 ? coliRec.Qty_Committed__c : coliRec.Qty__c);
                preTaxPartTotal += (qty * coliRec.Price__c).setScale(2, RoundingMode.HALF_UP);
            } else if(coliRec.Fee__c != null) {
                preTaxFeeTotal += (coliRec.Qty__c * coliRec.Price__c).setScale(2, RoundingMode.HALF_UP);
            }
        }
        
        for(Service_Order_Line_Item__c soliRec : soliList) {
            soliRec.Kit_Price__c = (soliRec.Kit_Price__c != null) ? soliRec.Kit_Price__c.setScale(2, RoundingMode.HALF_UP) : 0;
            soliRec.Qty_Needed__c = (soliRec.Qty_Needed__c != null) ? soliRec.Qty_Needed__c : 0;
            if(soliRec.Individual_Taxes__r.size() > 0) {
                taxableAmount += (soliRec.Kit_Price__c * soliRec.Qty_Needed__c);
            } else {
                nonTaxableAmount += (soliRec.Kit_Price__c * soliRec.Qty_Needed__c);
            }
            
            Decimal total = (soliRec.Qty_Needed__c * soliRec.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
            if(soliRec.Fee__c != null) {
                if(soliRec.Type__c == Constants.SHOP_SUPPLY) {
                    preTaxShopSupplyTotal += total;
                } else {
                    preTaxfeeTotal += total;
                }
            } else if(soliRec.Part__c != null) {
                preTaxPartTotal += total;
            } else if(soliRec.Labour_Code__c != null) {
                preTaxLabourTotal += total;
            } else if(soliRec.Sublet__c != null) {
                preTaxSubletTotal += total;
            }
        }
        Map<Id, Set<Id>> taxCodeIdToRateIdSetMap = getAppliedTaxCodeIdToRateIdSetMap(optionFeeList, dealItemList, dealUnitPriceAndCostList, fAndIProductList);
        Set<Id> appliedTaxRateIdOnDealSet = new Set<Id>();
        if(individualTaxForDealList != null) {
            for(Individual_Tax__c individualTaxRec : individualTaxForDealList) {
                if(individualTaxRec.Sales_Tax_Item__c != null && 
                (individualTaxRec.Enhanced_Tax_Amount__c != null || (individualTaxRec.Tax_Rate__c != null && individualTaxRec.Tax_Rate__c != 0))) {
                    appliedTaxRateIdOnDealSet.add(individualTaxRec.Sales_Tax_Item__c);
                }
            }
        }
        if(optionFeeList != null) {
            for(Option_Fee__c optionFeeRec : optionFeeList) {
                optionFeeRec.Price__c = (optionFeeRec.Price__c != null) ? optionFeeRec.Price__c : 0;
                optionFeeRec.Qty__c = (optionFeeRec.Qty__c != null) ? optionFeeRec.Qty__c : 0;
                Boolean isEntityTaxable ;
                String entity;
                Decimal total = (optionFeeRec.Qty__c * optionFeeRec.Price__c).setScale(2, RoundingMode.HALF_UP);
                if(optionFeeRec.Part__c != null) {
                    entity = 'Parts';
                    isEntityTaxable = optionFeeRec.Part__r.Taxable__c;
                    preTaxPartTotal += total;
                } else if(optionFeeRec.Labour_Code__c != null) {
                    entity = 'Labor';
                    isEntityTaxable = optionFeeRec.Labour_Code__r.Taxable__c;
                    preTaxLabourTotal += total;
                } else if(optionFeeRec.Fee__c != null) {
                    entity = 'Fees';
                    isEntityTaxable = optionFeeRec.Fee__r.Taxable__c;
                    preTaxFeeTotal += total;
                } else if(optionFeeRec.Product__c != null) {
                    isEntityTaxable = optionFeeRec.Product__r.Taxable__c;
                    if(optionFeeRec.Product__r.Type__c == Constants.WARRANTY_PLAN) {
                        entity = 'Warranty products';
                        preTaxWarrantyProductTotal += total;
                    } else if(optionFeeRec.Product__r.Type__c == Constants.SUBLET) {
                        entity = 'Sublet';
                        preTaxSubletTotal += total;
                    } else {
                        entity = 'Other products';
                        preTaxOtherProductTotal += total;
                    }
                }
                Decimal totalPreTaxPrice = (optionFeeRec.Price__c * optionFeeRec.Qty__c);
                if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c) {
                    if(optionFeeRec.Individual_Taxes__r.size() > 0) {
                        taxableAmount += totalPreTaxPrice;
                    } else {
                        nonTaxableAmount += totalPreTaxPrice;
                    }
                } else {
                    isEntityTaxable = isEntityTaxable && (optionFeeRec.Deal_Item__r.Unit_Tax_Applicable_On__c == null || !optionFeeRec.Deal_Item__r.Unit_Tax_Applicable_On__c.contains(entity) || optionFeeRec.Deal_Item__r.Taxable__c);
                    Boolean isTaxApplied = false;
                    if(isEntityTaxable && taxCodeIdToRateIdSetMap.containsKey(optionFeeRec.Applicable_Tax__c)) {
                        for(Id appliedTaxRateIdOnOF : taxCodeIdToRateIdSetMap.get(optionFeeRec.Applicable_Tax__c)) {
                            if(appliedTaxRateIdOnDealSet.contains(appliedTaxRateIdOnOF)) {
                                isTaxApplied = true;
                                break;
                            }
                        }
                    }
                    if(isTaxApplied) {
                        taxableAmount += totalPreTaxPrice;
                    } else {
                        nonTaxableAmount += totalPreTaxPrice;
                    }
                }
            }
        }

        if(dealItemList != null){
            for(Deal_Item__c dealItemRec : dealItemList) {
        	    if(dealItemRec.Type__c == 'Trade In') {
        		    dealItemRec.Agreed_Value__c = (dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c : 0;
                    if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c) {
                        if(dealItemRec.Individual_Taxes__r.size() > 0) {
                            taxableAmount -= dealItemRec.Agreed_Value__c;
                        } else {
                            nonTaxableAmount -= dealItemRec.Agreed_Value__c;
                        }
                    } else {
                        Boolean isTaxApplied = false;
                        if(dealItemRec.Taxable__c && taxCodeIdToRateIdSetMap.containsKey(dealItemRec.Applicable_Tax__c)) {
                            for(Id appliedTaxRateIdOnTradeIn : taxCodeIdToRateIdSetMap.get(dealItemRec.Applicable_Tax__c)) {
                                if(appliedTaxRateIdOnDealSet.contains(appliedTaxRateIdOnTradeIn)) {
                                    isTaxApplied = true;
                                    break;
                                }
                            }
                        }
                        if(isTaxApplied) {
                            taxableAmount -= dealItemRec.Agreed_Value__c;
                        } else {
                            nonTaxableAmount -= dealItemRec.Agreed_Value__c;
                        }
                    }
	            
	                dealItemRec.Agreed_Value__c = dealItemRec.Agreed_Value__c.setScale(2, RoundingMode.HALF_UP);
	                dealItemRec.Default_Unit_Sales_Tax_Percentage__c = (dealItemRec.Default_Unit_Sales_Tax_Percentage__c != null) ? dealItemRec.Default_Unit_Sales_Tax_Percentage__c : 0;
	                if(GeneralConfiguration.getTaxIncludingPricing()) {
	            	    preTaxTradeInsTotal -= (dealItemRec.Agreed_Value__c / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100)).setScale(2, RoundingMode.HALF_UP);
	        	    } else {
	                    preTaxTradeInsTotal -= dealItemRec.Agreed_Value__c;
	                }
	            
	                if(dealItemRec.Lien_Payout__c != null && dealItemRec.Lien_Payout__c > 0) {
	                    nonTaxableAmount += dealItemRec.Lien_Payout__c.setScale(2, RoundingMode.HALF_UP);
	                }
        	    } else if(dealItemRec.Stamp_Duty_Total__c != null) {
        		    nonTaxableAmount += dealItemRec.Stamp_Duty_Total__c.setScale(2, RoundingMode.HALF_UP);
        	    }
            }
        }

        if(dealUnitPriceAndCostList != null){
            for(Deal_Unit_Price_Cost__c dupcRec : dealUnitPriceAndCostList) {
                dupcRec.Qty__c = (dupcRec.Qty__c != null) ? dupcRec.Qty__c : 0;
                dupcRec.Price__c = (dupcRec.Price__c != null) ? dupcRec.Price__c : 0;
                Decimal preTaxPrice = (dupcRec.Price__c * dupcRec.Qty__c);
                if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c) {
                    if(!dupcRec.Individual_Taxes__r.isEmpty()) {
                        taxableAmount += preTaxPrice;
                    } else {
                        nonTaxableAmount += preTaxPrice;
                    }
                } else {
                    Boolean isTaxApplied = false;
                    if(dupcRec.Deal_Item__r.Taxable__c && taxCodeIdToRateIdSetMap.containsKey(dupcRec.Applicable_Tax__c)) {
                        for(Id appliedTaxRateIdOnDUPC : taxCodeIdToRateIdSetMap.get(dupcRec.Applicable_Tax__c)) {
                            if(appliedTaxRateIdOnDealSet.contains(appliedTaxRateIdOnDUPC)) {
                                isTaxApplied = true;
                                break;
                            }
                        }
                    }
                    if(isTaxApplied) {
                        taxableAmount += preTaxPrice;
                    } else {
                        nonTaxableAmount += preTaxPrice;
                    }
                }
                preTaxUnitTotal += preTaxPrice.setScale(2, RoundingMode.HALF_UP);
            }
        }
         
        if(fAndIProductList != null){
            for(F_I_Product__c fAndIProductRec : fAndIProductList) {
                fAndIProductRec.Price__c = (fAndIProductRec.Price__c != null) ? fAndIProductRec.Price__c : 0;
                if(GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c) {
                    if(!fAndIProductRec.Individual_Taxes__r.isEmpty()) {
                        taxableAmount += fAndIProductRec.Price__c;
                    } else {
                        nonTaxableAmount += fAndIProductRec.Price__c;
                    }
                } else {
                    Boolean isTaxApplied = false;
                    if(fAndIProductRec.Vendor_Product__r.Taxable__c && taxCodeIdToRateIdSetMap.containsKey(fAndIProductRec.Applicable_Tax__c)) {
                        for(Id appliedTaxRateIdOnFIProd : taxCodeIdToRateIdSetMap.get(fAndIProductRec.Applicable_Tax__c)) {
                            if(appliedTaxRateIdOnDealSet.contains(appliedTaxRateIdOnFIProd)) {
                                isTaxApplied = true;
                                break;
                            }
                        }
                    }
                    if(isTaxApplied) {
                        taxableAmount += fAndIProductRec.Price__c;
                    } else {
                        nonTaxableAmount += fAndIProductRec.Price__c;
                    }
                }
            }
        }
        
        coInvoiceRec.Taxable_Total__c = taxableAmount;
        coInvoiceRec.Non_Taxable_Total__c = nonTaxableAmount;
        
        //Pre Tax totals
        coInvoiceRec.Pre_Tax_Part_Total__c = preTaxPartTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoiceRec.Pre_Tax_Labour_Total__c = preTaxLabourTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoiceRec.Pre_Tax_Fee_Total__c = preTaxFeeTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoiceRec.Pre_Tax_Sublet_Total__c = preTaxSubletTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoiceRec.Pre_Tax_Unit_Total__c = preTaxUnitTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoiceRec.Pre_Tax_Shop_Supplies_Total__c = preTaxShopSupplyTotal.setScale(2, RoundingMode.HALF_UP);
        
        coInvoiceRec.Pre_Tax_Trade_In_Total__c = preTaxTradeInsTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoiceRec.Pre_Tax_Warranty_Product_Total__c = preTaxWarrantyProductTotal.setScale(2, RoundingMode.HALF_UP);
        coInvoiceRec.Pre_Tax_Other_Product_Total__c = preTaxOtherProductTotal.setScale(2, RoundingMode.HALF_UP);
        return coInvoiceRec;
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
    
    public static List<UnitWrapper.Documents> getUnitImages(String unitId, Boolean isPrimary) {
        if(AccessControl.ifObjectFieldIsAccessible('ContentDocument') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('ContentDocumentLink') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('ContentDistribution') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Set<String> contentDocIdSet = new Set<String>();
        for(ContentDocumentLink contentDocLinkRec: [Select ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :unitId]) {
            contentDocIdSet.add(contentDocLinkRec.ContentDocumentId);
        }

        
        Map<String, ContentVersion> contetDocIdToContentVerRecMap = new Map<String, ContentVersion>();
        List<ContentVersion> contentVersionList = [SELECT Is_Primary__c, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :contentDocIdSet ORDER BY Image_Uploaded_At__c ASC NULLS LAST, CreatedDate ASC];
        for(ContentVersion contentVerRec: contentVersionList) {
            contetDocIdToContentVerRecMap.put(contentVerRec.ContentDocumentId, contentVerRec);
        }

        Map<String, ContentDistribution> contetDocIdToContentDistrRecMap = new Map<String, ContentDistribution>();
        List<ContentDistribution> contentDistrList = [SELECT ContentDocumentId, Name, DistributionPublicUrl FROM ContentDistribution WHERE ContentDocumentId IN :contentDocIdSet];
        for(ContentDistribution contentDistrRec: contentDistrList) {
            contetDocIdToContentDistrRecMap.put(contentDistrRec.ContentDocumentId, contentDistrRec);
        }
        
        if(contetDocIdToContentVerRecMap.isEmpty() || contetDocIdToContentDistrRecMap.isEmpty()) {
            return new List<UnitWrapper.Documents>();
        }
        
        List<UnitWrapper.Documents> imageList = new List<UnitWrapper.Documents>();
        for(String contentDocId: contetDocIdToContentVerRecMap.keySet()) {
            if(isPrimary) {
                if(contetDocIdToContentVerRecMap.get(contentDocId).Is_Primary__c) {
                    imageList.add(new UnitWrapper.Documents(contentDocId, contetDocIdToContentVerRecMap.get(contentDocId), contetDocIdToContentDistrRecMap.get(contentDocId)));
                    break;
                }
            } else {
                imageList.add(new UnitWrapper.Documents(contentDocId, contetDocIdToContentVerRecMap.get(contentDocId), contetDocIdToContentDistrRecMap.get(contentDocId)));
            }
        }
        return imageList;
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

    public static Boolean isARCreditsRemoved(Set<String> arCreditAccIdSet, String customerId) {
        //Check AR credit Accounting Id in QB/XERO
        List<ARPaymentWrapper> ARPaymentObjList = Customer_Service.getARPaymentsByCustAccId(customerId, false);
        Set<String> availableARCreditIdSet = new Set<String>();
        for(ARPaymentWrapper arPaymentObj : ARPaymentObjList) {
            availableARCreditIdSet.add(arPaymentObj.InvoiceAccountingId);
        }
        for(String arCreditAccId : arCreditAccIdSet) {
            if(!availableARCreditIdSet.contains(arCreditAccId)) {
                return true;
            }
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

    public static void addIntCommentForCOEmailedDocs(List<SendEmail.DocumentWrapper> docWrapperList, SendEmail.EmailAddressWrapper emailAddressObj) {
        InternalCommentWrapper commentObj;
        List<InternalCommentWrapper> commentObjList = new List<InternalCommentWrapper>();
        for(SendEmail.DocumentWrapper docWrapperObj : docWrapperList) {
            if(String.isNotBlank(docWrapperObj.coHeaderId)) {
                commentObj = new InternalCommentWrapper();
                commentObj.CoHeaderId = docWrapperObj.coHeaderId;
                commentObj.IsNonDeletable = commentObj.IsNonEditable = true;
                commentObj.Comment = docWrapperObj.DocumentName + ' emailed to ' + emailAddressObj.ToEmail;
                commentObjList.add(commentObj);
            }
        }
        InternalCommentService.saveInternalCommentOnCOInBulk(system.JSON.serialize(commentObjList));
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
            
            Customer_Service.populateStoreTaxesOnCO(coHeaderToInsert.Id);
            if(sellingGroup.equalsIgnoreCase('Service Order')) {
                ServiceJobService.createServiceJobWithSpecificFields(coHeaderToInsert.Id, null, null, true, true);
            } else if(sellingGroup.equalsIgnoreCase('Unit Deal')) {
                DealService.createDealHeader(coHeaderToInsert.Id);
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

    public static List<ReallocateCOPartsWrapper.UnreceivedPartVOInfoWrapper> getUnreceivedStockPartVODetails(String partId) {
        List<ReallocateCOPartsWrapper.UnreceivedPartVOInfoWrapper> unreceivedPartVOInfoWrapperList = new List<ReallocateCOPartsWrapper.UnreceivedPartVOInfoWrapper>();
        if(String.isBlank(partId)) { return unreceivedPartVOInfoWrapperList; }

        if(!AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item_Group__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Vendor_Order_Line_Item_Group__c> voligList = [SELECT Vendor_Order_Header__c, Vendor_Order_Header__r.Name, Vendor_Order_Header__r.Ordered_Date__c, Vendor_Order_Header__r.Expected_Date__c, 
        Vendor_Order_Header__r.Purchase_Order_Type__r.Code__c, 
        (SELECT Qty_Needed__c FROM Vendor_Order_Line_Items__r WHERE Part__c = :partId AND Qty_Needed__c > 0 AND Is_received__c = false 
        AND Is_required_For_Customer__c = false AND Is_Service__c = false AND Vendor_Receiving_Group__c = null)   
        FROM Vendor_Order_Line_Item_Group__c WHERE Part__c = :partId AND Vendor_Order_Header__r.Status__c IN ('On Order', 'Partially Received')
        ORDER BY Vendor_Order_Header__r.Ordered_Date__c, Vendor_Order_Header__r.Name ASC];

        for(Vendor_Order_Line_Item_Group__c voligRec : voligList) {
            ReallocateCOPartsWrapper.UnreceivedPartVOInfoWrapper unreceivedPartVOInfoObj = new ReallocateCOPartsWrapper.UnreceivedPartVOInfoWrapper(voligRec);
            if(unreceivedPartVOInfoObj.UnreceivedOnOrderQty > 0) unreceivedPartVOInfoWrapperList.add(unreceivedPartVOInfoObj);
        }
        return unreceivedPartVOInfoWrapperList;
    }

    public static String reallocateOnOrderPartToCO(String reallocatePartJSON) {
        ReallocateCOPartsWrapper.ReallocatePartWrapper reallocatePartObj = (ReallocateCOPartsWrapper.ReallocatePartWrapper) System.JSON.deserialize(reallocatePartJSON, ReallocateCOPartsWrapper.ReallocatePartWrapper.class);
        String partId = reallocatePartObj.PartId;
        String vendorId = reallocatePartObj.VendorId;
        String voHeaderId = reallocatePartObj.VoHeaderId;
        String coliId = reallocatePartObj.ColiId;
        Decimal requiredQty = reallocatePartObj.RequiredQty;

        List<Vendor_Order_Line_Item__c> voliList = [SELECT Id FROM Vendor_Order_Line_Item__c WHERE Vendor_Order_Line_Item_Group__c != null AND CO_Line_Item__c = :coliId];
        if(!voliList.isEmpty()) {
            throw new BlackPurlException('On order quantity is already allocated to this Part. Please refresh the page.');
        }

        // Get unreceived stock orders
        if(!AccessControl.ifObjectIsAccessible('Vendor_Order_Line_Item_Group__c')){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Vendor_Order_Line_Item_Group__c> voligList = [SELECT Id, Vendor_Order_Header__c, Vendor_Order_Header__r.Name, Vendor_Order_Header__r.Ordered_Date__c, Vendor_Order_Header__r.Expected_Date__c, 
        Vendor_Order_Header__r.Purchase_Order_Type__r.Code__c, 
        (SELECT Qty_Needed__c, Vendor_Order_Line_Item_Group__c FROM Vendor_Order_Line_Items__r WHERE Part__c = :partId AND Qty_Needed__c > 0 AND Is_received__c = false 
        AND Is_required_For_Customer__c = false AND Is_Service__c = false AND Vendor_Receiving_Group__c = null)   
        FROM Vendor_Order_Line_Item_Group__c WHERE Part__c = :partId AND Vendor_Order_Header__c = :voHeaderId AND Vendor_Order_Header__r.Status__c IN ('On Order', 'Partially Received')
        ORDER BY Vendor_Order_Header__r.Ordered_Date__c, Vendor_Order_Header__r.Name ASC];

        Decimal unreceivedOnOrderQty = 0;
        for(Vendor_Order_Line_Item_Group__c voligRec : voligList) {
            for(Vendor_Order_Line_Item__c voliRec : voligRec.Vendor_Order_Line_Items__r) {
                unreceivedOnOrderQty += voliRec.Qty_Needed__c;
            }
        }

        /* Validation:
            - required qty can't be grater than unreceived stock order qty
            - required qty is must be grater than 0
        */
        if(requiredQty > unreceivedOnOrderQty || requiredQty <= 0) {
            throw new BlackpurlException('Required qty can\'t be zero/negative or grater than on order qty.');
        }

        String voNumber = voligList[0].Vendor_Order_Header__r.Name;
        String voliGroup = voligList[0].Id;
        // Create special order for required co line item and update VO stock and stock excess
        if(String.isNotBlank(coliId) && String.isNotBlank(voHeaderId) && String.isNotBlank(voliGroup)) {
            List<Vendor_Order_Line_Item__c> voLineItemListToUpdate = new List<Vendor_Order_Line_Item__c>();
            updateStockOrStockExcessOrders(voligList, requiredQty, voLineItemListToUpdate);
            addRequiredVOLineItemsToVO(coliId, voHeaderId, voNumber, voliGroup, voLineItemListToUpdate);
        }

        // update parts On Order quantity
        PartService.updatePartOnOrderQty(new Set<Id>{partId});

        return 'Success';
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
                                            Reg_Expiry_Date__c = (String.isNotBlank(unitObj.RegExpiryDate) ? DateTimeUtility.parseDate(unitObj.RegExpiryDate) : null));
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

    public static ResponseWrapper saveCOSectionTaxInfo(String coSectionTaxInfoJSON) {
        COSectionTaxDetailWrapper coSectionTaxDetailObj = (COSectionTaxDetailWrapper) system.JSON.deserialize(coSectionTaxInfoJSON, COSectionTaxDetailWrapper.class);
        ResponseWrapper resObj;
        if(String.isNotBlank(coSectionTaxDetailObj.DealId)) {
            resObj = DealService.saveDealTaxInfo(coSectionTaxDetailObj);
        } else if(String.isNotBlank(coSectionTaxDetailObj.SOHeaderId)) {
            resObj = ServiceJobService.saveServiceJobTaxInfo(coSectionTaxDetailObj);
        } else if(String.isNotBlank(coSectionTaxDetailObj.COHeaderId)) {
            resObj = MerchandiseService.saveMerchTaxInfo(coSectionTaxDetailObj);
        }
        return resObj;
    }

    public static CustomerOrderWrapper.COHeader getCOHeaderTotals(String coHeaderId) {
        CustomerOrderWrapper.COHeader coHeaderObj = new CustomerOrderWrapper.COHeader();
        if(String.isNotBlank(coHeaderId)) {
            for(CO_Header__c coRec : [Select Id, Order_Total__c, Invoiced_Amount__c, Uninvoiced_Amount__c, Total_Payment__c 
            FROM CO_Header__c WHERE Id =: coHeaderId]) {
                coHeaderObj.setCOTotals(coRec);
            }
        }
        return coHeaderObj;
    }

    public static void refreshCOPricingAndTax(String recalculationObjJson) {
        if(String.isNotBlank(recalculationObjJson)) {
			CORecalculationWrapper recalculationObj = (CORecalculationWrapper) System.JSON.deserialize(recalculationObjJson, CORecalculationWrapper.class);
			if(String.isNotBlank(recalculationObj.COHeaderId)) {
                COTriggerHelper.isCalculatePLandTax = COTriggerHelper.isRecalculateCOPLAndTax = true;
                COTriggerHelper.isResetPricing = recalculationObj.IsResetPricing;
                COTriggerHelper.isRecalculateTaxes = recalculationObj.IsRecalculateTaxes;
                CO_Header__c coHeaderRec = new CO_Header__c(Id = recalculationObj.COHeaderId, Customer__c = recalculationObj.CustomerId);
                if(COTriggerHelper.isRecalculateTaxes) {
                    refreshAutomatedTaxesOnCO(recalculationObj.COHeaderId, recalculationObj.CustomerId);
                }
                DMLUtility.updateSobjectList('CO_Header__c', new List<CO_Header__c>{coHeaderRec});
            }
        }
    }

    private static void refreshAutomatedTaxesOnCO(Id coId, Id custId) {
        if(GeneralConfiguration.getConfigurations().Automatic_Tax_Rates__c && String.isNotBlank(coId) && String.isNotBlank(custId)) {
            List<CO_Header__c> coHeaderList = [SELECT Is_Tax_Based_On_Customer_Address__c, 
                (Select Id FROM Service_Order_Headers__r WHERE Provider__c = null AND Is_Tax_Based_On_Customer_Address__c = true LIMIT 1), 
                (Select Id FROM Deals__r WHERE Is_Tax_Based_On_Customer_Address__c = true LIMIT 1), 
                (Select Id, Type__c FROM Tax_Exemptions__r WHERE Type__c !=: TaxUtility.EXEMPTION) 
                FROM CO_Header__c where Id = :coId];
            if(coHeaderList.size() == 0) throw new BlackPurlException(BlackPurlException.getErrorMessage('Invalid CO Header Id', null));
            Boolean isTaxBasedOnCustAddressOnCO = (coHeaderList[0].Is_Tax_Based_On_Customer_Address__c || !coHeaderList[0].Service_Order_Headers__r.isEmpty() || !coHeaderList[0].Deals__r.isEmpty());
            Boolean hasCustomerTaxesPopulate = false;
            List<Tax_Exemption__c> taxByAddressDeleteList = coHeaderList[0].Tax_Exemptions__r;
            if(isTaxBasedOnCustAddressOnCO) {
                ResponseWrapper responseObj = Customer_Service.populateCustomerTaxesOnCO(coId, custId, true);
                if(responseObj != null && responseObj.responseStatus.equalsIgnoreCase('error')) {
                    taxByAddressDeleteList = new List<Tax_Exemption__c>();
                    for(Tax_Exemption__c taxExmpt : coHeaderList[0].Tax_Exemptions__r) {
                        if(taxExmpt.Type__c.equalsIgnoreCase(TaxUtility.AUTOMATED_STORE)) taxByAddressDeleteList.add(taxExmpt);
                    }
                }
            }
            DMLUtility.deleteSObjectList('Tax_Exemption__c', taxByAddressDeleteList);
            Customer_Service.populateStoreTaxesOnCO(coId);
        }
    }

    public static void refreshCOPricingAndTaxOnKit(String recalculationObjJson) {
        if(String.isNotBlank(recalculationObjJson)) {
			CORecalculationWrapper recalculationObj = (CORecalculationWrapper) System.JSON.deserialize(recalculationObjJson, CORecalculationWrapper.class);
			if(String.isNotBlank(recalculationObj.COHeaderId)) {
                CustomerOrderCtrl_V2.isRefreshCOKit = true;
                COTriggerHelper.isResetPricing = recalculationObj.IsResetPricing;
                COTriggerHelper.isRecalculateTaxes = recalculationObj.IsRecalculateTaxes;

                updateCOPricingAndTaxOnKit(recalculationObj.COHeaderId, recalculationObj.CustomerId);
            }
        }
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


    public static Map<String, Decimal> getCOInvoicesARBalance(String coId) {
        Map<String, Decimal> invoiceIdToARBalanceMap = new Map<String, Decimal>();
        List<CO_Invoice_Header__c> coInvoiceList = [SELECT Id, AccountingId__c, Xero_Accounting_Id__c, Invoice_Number__c, Total__c FROM CO_Invoice_Header__c WHERE (AccountingId__c != null OR Xero_Accounting_Id__c != null) AND Total_Charge_On_Account__c != 0 AND CO_Header__c =: coId];
        if(!coInvoiceList.isEmpty()) {
            BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
            invoiceIdToARBalanceMap = AccountingUtil.getCOInvoicesIdToARBalanceMap(coInvoiceList, integrationRec);
            QBCalloutManager.updateRecords(integrationRec.integrationConfigRec); // This will update the latest tokens and web service log for QB/Xero.
        }
        return invoiceIdToARBalanceMap;
    }

    public static Decimal getCOInvoiceARBalance(Id coInvId) {
        Map<String, Decimal> invoiceIdToARBalanceMap = new Map<String, Decimal>();
        List<CO_Invoice_Header__c> coInvoiceList = [SELECT Id, AccountingId__c, Xero_Accounting_Id__c, Invoice_Number__c, Total__c FROM CO_Invoice_Header__c WHERE (AccountingId__c != null OR Xero_Accounting_Id__c != null) AND Total_Charge_On_Account__c != 0 AND Id =: coInvId];
        if(!coInvoiceList.isEmpty()) {
            BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
            invoiceIdToARBalanceMap = AccountingUtil.getCOInvoicesIdToARBalanceMap(coInvoiceList, integrationRec);
            QBCalloutManager.updateRecords(integrationRec.integrationConfigRec); 
        }
        return invoiceIdToARBalanceMap.get(coInvId);
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

    public static String activateQuoteCO(String coHeaderId){
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        
        List<CO_Header__c> coHeaderList = [Select Order_Status__c, 
                                                (Select Id from CO_Line_Items__r where Is_In_Merch_Section__c = true), 
                                                (Select Transaction_Type__c, Transaction_Type__r.Code_Label__c, SO_Status__c from Service_Order_Headers__r), 
                                                (Select Status__c from Deals__r) from CO_Header__c where Id =: coHeaderId];
        if(coHeaderList.size() > 0) {
            List<SObject> sObjectListToUpdate = new List<SObject>();
            List<CO_Line_Item__c> coLineItemToUpdate = new List<CO_Line_Item__c>();
            Set<Id> soHeaderIdSet = new Set<Id>();
            
            coHeaderList[0].Order_Status__c = 'Open';
            sObjectListToUpdate.add(coHeaderList[0]);
            
            coLineItemToUpdate.addAll(coHeaderList[0].CO_Line_Items__r);
            
            if(coHeaderList[0].Service_Order_Headers__r.size() > 0) {
                String customerPayTTRecId, thirdPartyTTRecId;
                List<Transaction_Type__c> ttRecList = [Select Id, Type__c from Transaction_Type__c where Type__c IN ('Customer', 'Third-Party') AND Default__c = true];
                if(ttRecList.size() > 0) {
                	for(Transaction_Type__c ttRec : ttRecList) {
                		if(ttRec.Type__c == 'Customer') {
                			customerPayTTRecId = ttRec.Id;
                		} else if(ttRec.Type__c == 'Third-Party') {
                			thirdPartyTTRecId = ttRec.Id;
                		}
                	}
                }
                
                Id soStatusConfigId = ServiceJobUtil.getSOStatusConfigByName(ServiceJobUtil.NEW_JOB).Id;
                for(Service_Order_Header__c soHeaderRec : coHeaderList[0].Service_Order_Headers__r) {
                    if(String.isNotBlank(soHeaderRec.Transaction_Type__r.Code_Label__c) && soHeaderRec.Transaction_Type__r.Code_Label__c == 'Quote Third-Party') {
                		soHeaderRec.Claim_Status__c = 'Unsubmitted';
                        soHeaderRec.Transaction_Type__c = thirdPartyTTRecId;
                	} else {
                    	soHeaderRec.Transaction_Type__c = customerPayTTRecId;
                	}
                    soHeaderRec.SO_Status_Ref__c = soStatusConfigId;
                    soHeaderIdSet.add(soHeaderRec.Id);
                }
                sObjectListToUpdate.addAll((List<SObject>) coHeaderList[0].Service_Order_Headers__r);
            }
            update sObjectListToUpdate;
            
            List<Service_Order_Line_Item__c> soliList = [select Id from Service_Order_Line_Item__c where Service_Order_Header__c IN: soHeaderIdSet
                                                                    AND (Part__c != null OR Sublet__c != null)];
            
            if(coLineItemToUpdate.size() > 0) {
                COLineItemTriggerHelper.isActivateQuoteCO = true;
                ServiceOrderLineItemTriggerHelper.isActivateQuoteCO = true;
                DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemToUpdate);
            }
            
            if(soliList.size() > 0) {
                COLineItemTriggerHelper.isActivateQuoteCO = true;
                ServiceOrderLineItemTriggerHelper.isActivateQuoteCO = true;
                DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliList);
            }
            
			COSectionDetailService.setSectionStatus_future(new Set<Id>{coHeaderId});
            return BPUtility.getEncodedString('Success');
        }
        return '';
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

    public static String setCOStatusAsQuote(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        List<Vendor_Order_Line_Item__c> voliList = [Select Id, Vendor_Order_Line_Item_Group__c from Vendor_Order_Line_Item__c where CO_Header__c =: coHeaderId];
        for(Vendor_Order_Line_Item__c voliRec : voliList) {
            if(voliRec.Vendor_Order_Line_Item_Group__c != null) {
                throw new BlackPurlException('Cannot Quote this customer order. Some special order line items already added to the vendor order. Please refresh the browser page.');
            }
        }
        
        // #5353 - update the line items, so that they have qty committed value reset and then delete VOLI
        PartTriggerHelper.isCoToQuoteAction = true;
        List<CO_Line_Item__c> coliList = [Select Id from CO_Line_Item__c where Is_In_Merch_Section__c = true AND CO_Header__c =: coHeaderId];
        DMLUtility.updateSobjectList('CO_Line_Item__c', coliList);
        List<Service_Order_Line_Item__c> soliList = [Select Id from Service_Order_Line_Item__c where Service_Order_Header__r.CO_Header__c =: coHeaderId];
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliList);
        PartTriggerHelper.isCoToQuoteAction = false;
        
        List<CO_Header__c> coHeaderList = [Select Order_Status__c, (Select Transaction_Type__c, SO_Status__c from Service_Order_Headers__r), 
                (Select Status__c from Deals__r), (Select Id from Vendor_Order_Line_Items__r) from CO_Header__c where Id =: coHeaderId];
        if(coHeaderList.size() > 0) {
            //delete VOLIs
            DMLUtility.deleteSobjectList('Vendor_Order_Line_Item__c', coHeaderList[0].Vendor_Order_Line_Items__r);

            List<SObject> sObjectListToUpdate = new List<SObject>();
            coHeaderList[0].Order_Status__c = 'Quote';
            sObjectListToUpdate.add(coHeaderList[0]);
            
            if(coHeaderList[0].Service_Order_Headers__r.size() > 0) {
                List<Transaction_Type__c> ttRecList = [Select Id from Transaction_Type__c where Type__c = 'Quote' AND Default__c = true];
                String quoteTTRecId = (ttRecList.size() > 0) ? ttRecList[0].Id : null;
                
                Id soStatusConfigId = ServiceJobUtil.getSOStatusConfigByName(ServiceJobUtil.ESTIMATE).Id;
                for(Service_Order_Header__c soHeaderRec : coHeaderList[0].Service_Order_Headers__r) {
                    soHeaderRec.Transaction_Type__c = quoteTTRecId;
                    soHeaderRec.SO_Status_Ref__c = soStatusConfigId;
                }
                sObjectListToUpdate.addAll((List<SObject>) coHeaderList[0].Service_Order_Headers__r);
            }
            
            for(Deal__c dealRec : coHeaderList[0].Deals__r) {
                dealRec.Status__c = 'Quotation';
            }
            sObjectListToUpdate.addAll((List<SObject>) coHeaderList[0].Deals__r);
            update sObjectListToUpdate;
            return BPUtility.getEncodedString('Status updated successfully');
        }
        return BPUtility.getEncodedString('Error updating status');
    }

    /* Methods moved from CustomerOrderCtrl */
    
    public static void addDefaultSalespersonToCOSection(String sectionId) {
        addDefaultSalespersonToCOSection(sectionId, null, null);
    }

    public static void addDefaultSalespersonToCOSection(String sectionId, String sectionName, Id dealId) {
        try {
            if(String.isNotBlank(sectionId)) {
                for(Technician__c techRec : [Select Id FROM Technician__c WHERE User__c =: UserInfo.getUserId() LIMIT 1]) {
                    COSalesperson coSPObj = new COSalesperson(null);
                    coSPObj.SectionId = sectionId;
                    coSPObj.TechnicianId = techRec.Id;
                    coSPObj.SectionName = sectionName;
                    coSPObj.DealId = dealId;
                    addRemoveSalespersonOnCOSection(coSPObj);
                }
            }
        } catch(Exception e) {
            system.debug('Exception while adding co salesperson: ' + e.getMessage());
        }
    }
    
    public static void addRemoveSalespersonOnCOSection(String coSalespersonJsonStr) {
        if(String.isNotBlank(coSalespersonJsonStr)) {
			COSalesperson coSPObj = (COSalesperson) System.JSON.deserialize(coSalespersonJsonStr, COSalesperson.class);
            addRemoveSalespersonOnCOSection(coSPObj);
        }
    }

    public static void addRemoveSalespersonOnCOSection(COSalesperson coSPObj) {
        if(String.isNotBlank(coSPObj.SectionId) && String.isNotBlank(coSPObj.TechnicianId)) {
            Map<String, String> sectionNameToObjAPINameMap = new Map<String, String>{
                'Merchandise' => 'CO_Header__c',
                'ServiceJob' => 'Service_Order_Header__c',
                'Deal' => 'Deal__c',
                DealUtil.DEAL_MERCH => 'CO_Header__c'
            };
            Boolean isDealMerch = String.isNotBlank(coSPObj.SectionName) && coSPObj.SectionName.equalsIgnoreCase(DealUtil.DEAL_MERCH);
            if(!isDealMerch || String.isNotBlank(coSPObj.DealId)) {
                String objName = sectionNameToObjAPINameMap.get(coSPObj.SectionName);
                if(String.isBlank(objName)) {
                    objName = ((Id.valueOf(coSPObj.SectionId)).getSObjectType().getDescribe().getName()).substringAfter(Constants.NAMESPACE);
                }
                String query = 'Select Id FROM CO_Salesperson__c WHERE ' + objName + ' = \'' + coSPObj.SectionId + '\' AND Technician__c = \'' + coSPObj.TechnicianId + '\'';
                if(isDealMerch) {
                    query += ' AND Deal__c != null AND CO_Header__c != null';
                } else {
                    if(objName.equalsIgnoreCase('CO_Header__c')) {  //Merch Section
                        query += ' AND Deal__c = null';
                    } else if(objName.equalsIgnoreCase('Deal__c')) {  //Deal Section
                        query += ' AND CO_Header__c = null';
                    }
                }
                List<SObject> coSalespersonList = SOQLUtility.getQueryResults('CO_Salesperson__c', query);
                if(!coSalespersonList.isEmpty()) {
                    DMLUtility.deleteSobjectList('CO_Salesperson__c', coSalespersonList);
                } else {
                    CO_Salesperson__c spRec = new CO_Salesperson__c(Technician__c = coSPObj.TechnicianId);
                    spRec.put(objName, coSPObj.SectionId);
                    if(isDealMerch) spRec.put('Deal__c', coSPObj.DealId);
                    DMLUtility.insertSobjectList('CO_Salesperson__c', new List<CO_Salesperson__c>{spRec});
                }
            }
        }
    }

    public static void removeAllCOSalespersonBySectionId(String sectionId) {
        if(String.isNotBlank(sectionId)) {
            String objName = ((Id.valueOf(sectionId)).getSObjectType().getDescribe().getName()).substringAfter(Constants.NAMESPACE);
            COSalespersonTriggerHelper.isForceStopTrigger = true;
            String query = 'Select Id FROM CO_Salesperson__c WHERE ' + objName + ' = \'' + sectionId + '\'';
            if(objName.equalsIgnoreCase('CO_Header__c')) {  //Merch Section
                query += ' AND Deal__c = null';
            } else if(objName.equalsIgnoreCase('Deal__c')) {  //Deal Section
                query += ' AND CO_Header__c = null';
            }
            DMLUtility.deleteSobjectList('CO_Salesperson__c', (List<SObject>) SOQLUtility.getQueryResults('CO_Salesperson__c', query));
            COSalespersonTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    public static List<COSalesperson> getSalespersonsBySectionId(String sectionJson) {
        List<COSalesperson> coSalespersonObjList = new List<COSalesperson>();
        if(String.isNotBlank(sectionJson)) {
			COSalesperson sectionObj = (COSalesperson) System.JSON.deserialize(sectionJson, COSalesperson.class);
            Map<String, String> sectionNameToObjAPINameMap = new Map<String, String>{
                'Merchandise' => 'CO_Header__c',
                'Service Job' => 'Service_Order_Header__c',
                'Deal' => 'Deal__c',
                DealUtil.DEAL_MERCH => 'CO_Header__c'
            };
            if(String.isNotBlank(sectionObj.SectionId)) {
                Boolean isDealMerch = String.isNotBlank(sectionObj.SectionName) && sectionObj.SectionName.equalsIgnoreCase(DealUtil.DEAL_MERCH);
                String objName = sectionNameToObjAPINameMap.get(sectionObj.SectionName);
                if(String.isBlank(objName)) {
                    objName = ((Id.valueOf(sectionObj.SectionId)).getSObjectType().getDescribe().getName()).substringAfter(Constants.NAMESPACE);
                }
                String query = 'Select Id, Technician__r.Technician_Name__c, Technician__r.First_Name__c, Technician__r.Last_Name__c FROM CO_Salesperson__c WHERE ' + objName + ' = \'' + sectionObj.SectionId + '\'';
                if(isDealMerch) {
                    query += ' AND Deal__c != null AND CO_Header__c != null';
                } else {
                    if(objName.equalsIgnoreCase('CO_Header__c')) {  //Merch Section
                        query += ' AND Deal__c = null';
                    } else if(objName.equalsIgnoreCase('Deal__c')) {  //Deal Section
                        query += ' AND CO_Header__c = null';
                    }
                }
                for(CO_Salesperson__c coSalespersonRec : (List<CO_Salesperson__c>) SOQLUtility.getQueryResults('CO_Salesperson__c', query)) {
                    coSalespersonObjList.add(new COSalesperson(coSalespersonRec));
                }
            }
        }
        return coSalespersonObjList;
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