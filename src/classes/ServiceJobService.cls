public without sharing class ServiceJobService {

	public static String SERVICE_DECLINE_SEPARATOR = '^';
    
    public static ServiceOrderWrapper.SOMasterData getServiceJobMasterData(String coHeaderId) {
    	
    	List<Account> providerList = SOQLUtil.getProviderList();
        List<Customer_Owned_Unit__c> couRecords = new List<Customer_Owned_Unit__c>();
        
    	List<CO_Header__c> coHeaderRec = SOQLUtil.getCOHeaderDetails(coHeaderId);
        if(coHeaderRec.size() > 0 && coHeaderRec[0].Customer__c != null) {
            String query;    
            query = 'SELECT '; 
            for(String field : CustomerOwnedUnit.fieldsList()){
                field = BPUtility.escapeSingleQuotes(field);
                query += field + ', ';
            }
            query = query.substring(0, query.length()-2);
            
            query += ' FROM Customer_Owned_Unit__c WHERE Account__c = \'' + coHeaderRec[0].Customer__c + '\' AND Status__c = \'Active\' ORDER BY LastModifiedDate DESC';
            if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            couRecords = Database.query(query);
        }
        List<Transaction_Type__c> ttList = SOQLUtil.getTransactionTypesWithProvider(new List<Id>());
        ttList = ServiceJobTypeService.sortJobTypes(ttList);
        ServiceOrderWrapper.SOMasterData masterDataObj = new ServiceOrderWrapper.SOMasterData(ttList, couRecords, providerList, 
																(coHeaderRec.size() > 0 ? coHeaderRec[0].CO_Type__c : ''));
        return masterDataObj;
    }
    
    public static void deleteDeductibleRecord(String deductibleId) {
    	List<SO_Payment_Role__c> soPaymentList = [Select Id,(Select Id From CO_Invoice_Items__r) From SO_Payment_Role__c where Id=:deductibleId];
    	if(soPaymentList.size() > 0) {
            if(!AccessControl.ifObjectIsDeletable('SO_Payment_Role__c')){throw new BlackPurlException('SO_Payment_Role__c' + DMLUtility.NOT_DELETABLE);}
    		delete new List<SObject>{soPaymentList[0]};
    	} 
    }
    
    public static String saveDeductibleAmount(SOHeaderWrapper.Deductible soPaymentWrapperObj) {
        
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsCreateable('SO_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('SO_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        Decimal taxRate = 0;
		if(soPaymentWrapperObj.DeductibleId != null && soPaymentWrapperObj.DeductibleAmount == 0) {
        	deleteDeductibleRecord(soPaymentWrapperObj.DeductibleId);
        } else {
	        List<RecordType> deductibleRecordTypeIdList =  SOQLUtil.getRecordTypeId(Constants.NAMESPACE + 'SO_Payment_Role__c', 'Deductible');
	        String RecordTypeDeductible = deductibleRecordTypeIdList[0].Id;
	        Integer nullStatusDeductibleRec = 0;
	        Integer OwingStatusDeductibleRec = 0;
	         
	        List<SO_Payment_Role__c> soPaymentRoleRecList = SOQLUtil.getSOPaymentWrapperById(soPaymentWrapperObj.SoHeaderId, null);
	        for(SO_Payment_Role__c soPaymentRec: soPaymentRoleRecList ){
	            if(soPaymentRec.RecordType.DeveloperName == 'Deductible') {
					taxRate = soPaymentRec.Tax__c != null ? soPaymentRec.Tax__c : 0;
				}
				if(soPaymentRec.Deductible_Status__c == null && soPaymentRec.RecordTypeId == RecordTypeDeductible){
	                nullStatusDeductibleRec += 1;
	                break;
	            } else if(soPaymentRec.Deductible_Status__c == 'Owing' && soPaymentRec.RecordTypeId == RecordTypeDeductible){
	                OwingStatusDeductibleRec += 1;
	                break;
	            }
	        }
	        
	        List<CO_Invoice_Item__c> closedDeductibleInvoiceItem = [Select Id  From CO_Invoice_Item__c where CO_Invoice_Header__r.Status__c = 'Closed' AND 
	        				SO_Payment_Role__r.Service_Order_Header__c =: soPaymentWrapperObj.SoHeaderId AND SO_Payment_Role__r.RecordTypeId =: RecordTypeDeductible];
	        if(closedDeductibleInvoiceItem.size() > 0) {
	        	throw new BlackpurlException('Deductible has already invoiced, you can no longer modify this amount.');
	        }
	        
	        SO_Payment_Role__c soPaymentRoleRec = new SO_Payment_Role__c();
	        soPaymentRoleRec.Total_Amount__c = soPaymentWrapperObj.DeductibleAmount;
	        soPaymentRoleRec.RecordTypeId =deductibleRecordTypeIdList[0].Id;
	        soPaymentRoleRec.Service_Order_Header__c = soPaymentWrapperObj.SoHeaderId;
			if(!TaxCalculation.IsEnhancedTaxCalculationApplicable) {
				if(GeneralConfiguration.getTaxIncludingPricing()) {
					soPaymentRoleRec.Tax_Amount__c = (soPaymentRoleRec.Total_Amount__c - (soPaymentRoleRec.Total_Amount__c / (1 + (taxRate / 100))).setScale(2, RoundingMode.HALF_UP));
				} else {
					soPaymentRoleRec.Tax_Amount__c = ((soPaymentRoleRec.Total_Amount__c * taxRate)/100).setScale(2, RoundingMode.HALF_UP);
				}
			}
	        String coInvoiceHeaderId = '';
	        if(nullStatusDeductibleRec > 0 && soPaymentWrapperObj.DeductibleStatus == null ){
	            soPaymentRoleRec.Id = soPaymentWrapperObj.DeductibleId;
                DMLUtility.updateSobjectList('SO_Payment_Role__c', soPaymentRoleRec);
				if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
					SOPaymentRoleService.refreshIndividualTaxes(new List<Id>{soPaymentWrapperObj.SoHeaderId});
				}
	        } else if((OwingStatusDeductibleRec > 0) && ((soPaymentWrapperObj.DeductibleStatus == 'Adjust') || (soPaymentWrapperObj.DeductibleStatus == 'Owing') )){
	            soPaymentRoleRec.Id = soPaymentWrapperObj.DeductibleId;  
	            if(soPaymentWrapperObj.DeductibleStatus == 'Adjust'){
	                soPaymentRoleRec.Deductible_Status__c = 'Owing';
	            }
                DMLUtility.updateSobjectList('SO_Payment_Role__c', soPaymentRoleRec);
	            if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
					SOPaymentRoleService.refreshIndividualTaxes(new List<Id>{soPaymentWrapperObj.SoHeaderId});
				}
	        } else {
	            if(soPaymentWrapperObj.DeductibleStatus == 'Adjust'){
	                soPaymentRoleRec.Deductible_Status__c = 'Owing';   
	            } else {
	                soPaymentRoleRec.Deductible_Status__c = soPaymentWrapperObj.DeductibleStatus;
	            }
				soPaymentRoleRec.Applicable_Tax__c = GeneralConfiguration.getDefaultTaxOnClaimDeductibles();
                DMLUtility.insertSobjectList('SO_Payment_Role__c', soPaymentRoleRec);
                SOPaymentRoleService.refreshIndividualTaxes(new List<Id>{soPaymentWrapperObj.SoHeaderId});
	        }
            if(String.isNotBlank(soPaymentWrapperObj.SoHeaderId)) {
                Service_Order_Header__c soRec = new Service_Order_Header__c(Id = soPaymentWrapperObj.SoHeaderId, Deductible_SO_Payment__c = soPaymentRoleRec.Id);
                SOTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('Service_Order_Header__c', soRec);
                SOTriggerHelper.isForceStopTrigger = false;
            }
	        return soPaymentRoleRec.Id;
	    }
        return null;
    }
    
    public static List<ServiceOrderWrapper.SOWrapper> getServiceJobDetails(String recordId, String gridName) {
    	try {
	    	List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
	        List<Service_Order_Kit_Header__c> soKitHeaderList = new List<Service_Order_Kit_Header__c>();
	        Map<Id, List<Service_Order_Line_Item__c>> soHeaderIdToSOLIListMap = new Map<Id, List<Service_Order_Line_Item__c>>();
			Map<Id, List<Hours_Logged__c>> soHeaderIdToHoursLoggedListMap = new Map<Id, List<Hours_Logged__c>>();
	        
	        String objectName = (Id.valueOf(recordId)).getSObjectType().getDescribe().getName();

	        if(gridName == null || gridName.contains('soHeader')) {
	            if(objectName == Constants.NAMESPACE + 'CO_Header__c') {
	                soHeaderList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'CO_Header__c' => recordId});
	            } else if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
	                soHeaderList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'Id' => recordId});
	            }
				// Assembla #17116 To avaoid Aggregate query has too many rows for direct assignment, use FOR loop exception
				String query = 'SELECT ' + String.join(SOHeaderWrapper.getHoursLoggedFieldsList(), ',') + ' FROM Hours_Logged__c WHERE Is_Removed__c = false AND Service_Order_Header__c IN : soHeaderList ORDER BY CreatedDate'; 
				for(Hours_Logged__c hoursLoggedRec :  (List<Hours_Logged__c>) Database.query(query)) {
					if(!soHeaderIdToHoursLoggedListMap.containsKey(hoursLoggedRec.Service_Order_Header__r.Id)) {
						soHeaderIdToHoursLoggedListMap.put(hoursLoggedRec.Service_Order_Header__r.Id, new List<Hours_Logged__c>());
	        		}
					soHeaderIdToHoursLoggedListMap.get(hoursLoggedRec.Service_Order_Header__r.Id).add(hoursLoggedRec);
				}
	        }
	        
	        Map<Id, List<Service_Order_Kit_Header__c>> soHeaderIdToSOKIListMap = new Map<Id, List<Service_Order_Kit_Header__c>>();
	        Map<Id, Service_Order_Line_Item__c> soliIdToRecMap = new Map<Id, Service_Order_Line_Item__c>();
	        if(gridName == null || gridName.contains('Grid Items')) {
	            if(objectName == Constants.NAMESPACE + 'CO_Header__c') {
	                soKitHeaderList = SOQLUtil.getSOKitHeaderByFieldName(new Map<String, String>{'Service_Order_Header__r.CO_Header__c' => recordId});
	                soliIdToRecMap = new Map<Id, Service_Order_Line_Item__c>([Select Id, 
                    	(Select Id, Variance__c from Claim_Line_Items__r where Is_Variance__c = false AND Variance__c != 0) 
                    	from Service_Order_Line_Item__c where Service_Order_Header__r.CO_Header__c =: recordId]);
	            } else if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
	                soKitHeaderList = SOQLUtil.getSOKitHeaderByFieldName(new Map<String, String>{'Service_Order_Header__c' => recordId});
	                soliIdToRecMap = new Map<Id, Service_Order_Line_Item__c>([Select Id, 
                    	(Select Id, Variance__c from Claim_Line_Items__r where Is_Variance__c = false AND Variance__c != 0) 
                    	from Service_Order_Line_Item__c where Service_Order_Header__c =: recordId]);
	            }
	            for(Service_Order_Kit_Header__c soKitHeaderRec : soKitHeaderList) {
	                List<Service_Order_Kit_Header__c> sokhList;
	                if(!soHeaderIdToSOKIListMap.containsKey(soKitHeaderRec.Service_Order_Header__c)) {
	                    sokhList = new List<Service_Order_Kit_Header__c>();
	                } else {
	                    sokhList = soHeaderIdToSOKIListMap.get(soKitHeaderRec.Service_Order_Header__c);
	                }
	                sokhList.add(soKitHeaderRec);
	                soHeaderIdToSOKIListMap.put(soKitHeaderRec.Service_Order_Header__c, sokhList);
	            }
	        }
	        
	        List<ServiceOrderWrapper.SOWrapper> soWrapperList = new List<ServiceOrderWrapper.SOWrapper>();
			List<Service_Order_Kit_Header__c> serviceOrderKitHeaderList;
			List<Hours_Logged__c> HoursLoggedList;
	        for(Service_Order_Header__c soRec : soHeaderList) {
				serviceOrderKitHeaderList = soHeaderIdToSOKIListMap.containsKey(soRec.Id) ? soHeaderIdToSOKIListMap.get(soRec.Id) : new List<Service_Order_Kit_Header__c>();
				HoursLoggedList = soHeaderIdToHoursLoggedListMap.containsKey(soRec.Id) ? soHeaderIdToHoursLoggedListMap.get(soRec.Id) : new List<Hours_Logged__c>();
				soWrapperList.add(new ServiceOrderWrapper.SOWrapper(soRec, serviceOrderKitHeaderList, HoursLoggedList));
	        }
	        
            for(ServiceOrderWrapper.SOWrapper soObj : soWrapperList) {
             	for(SOHeaderWrapper.SOKitHeader soGridObj : soObj.SOGridItems) {
             		for(SOHeaderWrapper.SOLineItem soliObj : soGridObj.SOLIList) {
             			if(soliIdToRecMap.containsKey(soliObj.Id) && soliIdToRecMap.get(soliObj.Id).Claim_Line_Items__r.size() > 0) {
			    			soliObj.IsVariance = true;
			    		}
             		}
             	}
             	
            }
	        return soWrapperList;
    	} catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public static Map<String, List<CustomerApproval>> getCustomerApprovalList(String recordId) {
    	String objectName = (Id.valueOf(recordId)).getSObjectType().getDescribe().getName();
        List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
        
        if(objectName == Constants.NAMESPACE + 'CO_Header__c') {
            soHeaderList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'CO_Header__c' => recordId});
        } else if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
            soHeaderList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'Id' => recordId});
        }
	        
    	Set<String> customerApprovalIdSet = new Set<String>();
        Map<String, Set<String>> soIdToCustomerApprovalIdSetMap = new Map<String, Set<String>>();
        for(Service_Order_Header__c soRec : soHeaderList) {
        	for(Service_Job_To_Customer_Approval__c junctionObjRec : soRec.Service_Jobs_To_Customer_Approvals__r) { 
        		if(!soIdToCustomerApprovalIdSetMap.containsKey(soRec.Id)) {
        			soIdToCustomerApprovalIdSetMap.put(soRec.Id, new Set<String>());
        		}
        		soIdToCustomerApprovalIdSetMap.get(soRec.Id).add(junctionObjRec.Customer_Approval__c);
        		customerApprovalIdSet.add(junctionObjRec.Customer_Approval__c);
        	}
        }
        
        Map<String, CustomerApproval__c> customerApprovalIdToRecMap = SOQLUtil.getCustomerApprovalsById(customerApprovalIdSet);
        Map<String, List<CustomerApproval>> soIdToCustomerApprovalRecListMap = new Map<String, List<CustomerApproval>>();
        for(String soId : soIdToCustomerApprovalIdSetMap.keySet()) {
        	for(String customerApprovalId : soIdToCustomerApprovalIdSetMap.get(soId)) {
        		if(!soIdToCustomerApprovalRecListMap.containsKey(soId)) {
        			soIdToCustomerApprovalRecListMap.put(soId, new List<CustomerApproval>());
        		}
        		soIdToCustomerApprovalRecListMap.get(soId).add(new CustomerApproval(customerApprovalIdToRecMap.get(customerApprovalId)));
        	}
        }
        
        return soIdToCustomerApprovalRecListMap;
    }
    
    public static String createServiceJobWithSpecificFields(String coHeaderId, String couId, List<String> concernList, Boolean isAddLinkedFee) {
		return createServiceJobWithSpecificFields(coHeaderId, couId, concernList, isAddLinkedFee, false);
	}

    public static String createServiceJobWithSpecificFields(String coHeaderId, String couId, List<String> concernList, Boolean isAddLinkedFee, Boolean isNewCO) {
		coHeaderId = BPUtility.escapeSingleQuotes(coHeaderId);
		isNewCO = isNewCO != null ? isNewCO : false;
		
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
		List<CO_Header__c> coHeaderList = [Select CO_Type__c, Customer__c, Order_Status__c, Selling_Group__c,
				(select Id from CO_Invoice_Headers__r where Invoice_Status__c = 'Active' LIMIT 1), 
				(select Name__c from Service_Order_Headers__r where Deal__c = null) from CO_Header__c where Id = :coHeaderId];
		
		if(coHeaderList.size() == 0) {
			return null;
		}	
		Service_Order_Header__c soHeaderToInsert = new Service_Order_Header__c();
		soHeaderToInsert.Name__c = calculateNewServiceJobName(coHeaderList[0].Service_Order_Headers__r, isNewCo);
		soHeaderToInsert.CO_Header__c = coHeaderId;
		soHeaderToInsert.Status__c = 'New';
		soHeaderToInsert.SO_Status_Ref__c = ServiceJobUtil.getSOStatusConfigByName(ServiceJobUtil.NEW_JOB).Id;
		soHeaderToInsert.SO_Type__c = coHeaderList[0].CO_Type__c;

		if(concernList != null && concernList.size() > 0) {
			soHeaderToInsert.SO_Concern__c = '';
			for(String concernStr : concernList) {
				concernStr = (concernStr.contains('\n')) ? concernStr.replaceAll('\n', '') : concernStr;
				soHeaderToInsert.SO_Concern__c += concernStr + '\n';
			}
		}
		
		String transactionType = 'Customer';
		if(coHeaderList[0].CO_Type__c == 'Internal Service') {
			transactionType = 'Stock Unit';
			if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            for(Category__c defaultCategory : [select Id, Name, Default__c from Category__c where Type__c = 'Internal Expense' AND Default__c = true AND Active__c = true LIMIT 1]) {
            	soHeaderToInsert.Category__c = defaultCategory.Id;
			}
		} else if(coHeaderList[0].CO_Type__c == 'Customer' && String.isNotBlank(coHeaderList[0].Order_Status__c) && (coHeaderList[0].Order_Status__c == 'Quote')) {
			transactionType = 'Quote';
			soHeaderToInsert.SO_Status_Ref__c = ServiceJobUtil.getSOStatusConfigByName(ServiceJobUtil.ESTIMATE).Id;
		} 
		
		if(String.isNotBlank(transactionType)) {
			if(AccessControl.ifObjectFieldIsAccessible('Transaction_Type__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
			for(Transaction_Type__c ttRec : [select Id from Transaction_Type__c where Type__c = :transactionType AND Default__c = true LIMIT 1]) {
				soHeaderToInsert.Transaction_Type__c = ttRec.Id;
			}
		}
		//Check for Single Unit
		if(String.isNotBlank(couId)) {
			soHeaderToInsert.Customer_Owned_Unit__c = couId;
		}
		DMLUtility.insertSobjectList('Service_Order_Header__c', soHeaderToInsert);
		
		if(isNewCO && String.isNotBlank(coHeaderList[0].Selling_Group__c) && coHeaderList[0].Selling_Group__c == 'Service Order') {
			COFormService.insertDefaultCOForms(coHeaderId, soHeaderToInsert.Id);
		}

		if(soHeaderToInsert.Id != null) {
			CO_Invoice_Header__c coInvoiceHeaderRec = coHeaderList[0].CO_Invoice_Headers__r.size() > 0 ? coHeaderList[0].CO_Invoice_Headers__r[0] : COLineItemTriggerHelper.insertCOInvoiceHeader(coHeaderId);
			
			CO_Invoice_Item__c coInvoiceItem = new CO_Invoice_Item__c();
			coInvoiceItem.Is_Invoiceable__c = false;
			coInvoiceItem.isActive__c = false;
			coInvoiceItem.Service_Order_Header__c = soHeaderToInsert.Id;
			coInvoiceItem.CO_Invoice_Header__c = coInvoiceHeaderRec.Id;
			DMLUtility.insertSobjectList('CO_Invoice_Item__c', coInvoiceItem);
		}		
		if(isAddLinkedFee) {
			List<SObject> sObjectListToInsert = COService.addLinkedFee(soHeaderToInsert.Id, null, 'Service Job');
			if(sObjectListToInsert != null) {
				DMLUtility.upsertSobjectList('Service_Order_Line_Item__c', sObjectListToInsert);
			}
		}
		
		return soHeaderToInsert.Id;
    }
    
    public static void createServiceJob(String coHeaderId) {
		createServiceJobWithSpecificFields(coHeaderId, null, null, true);
    }
    
    public static SO_KLI_Recalculation.Errorhandler error;
    public static String updateSOLIRec(String lineItemJSON, String soHeaderId) {
    	Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
    	
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

            SOHeaderWrapper.SOLineItem soHeaderObj = (SOHeaderWrapper.SOLineItem) System.JSON.deserialize(lineItemJSON, SOHeaderWrapper.SOLineItem.class);
            if(soHeaderObj.Id == null) {
            	return null;
                //return CustomerOrderCtrl_V2.getSOHeaderDetails(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString('soHeader,Grid Items'));
            } 
            
            error = SO_KLI_Recalculation.updateSOKitLineItem(soHeaderObj);
            
            if(error == null || error.ResponseCode == '200') {
                Service_Order_Line_Item__c soliToUpdate = new Service_Order_Line_Item__c();
                soliToUpdate.Id = soHeaderObj.Id;
                if(String.isNotBlank(soHeaderObj.Id) && soHeaderObj.IsSublet != null && soHeaderObj.IsSublet) {
                	List<Vendor_Order_Line_Item__c> subletVOLIList = [Select Id, Service_Order_Line_Item__r.Qty_Needed__c from Vendor_Order_Line_Item__c 
										where Service_Order_Line_Item__c =: soHeaderObj.Id AND Sublet__c != null 
										AND Vendor_Order_Line_Item_Group__c != null AND Vendor_Order_Header__r.Status__c != 'Open' AND 
										Vendor_Order_Header__r.Status__c != 'Locked'];
                	if(subletVOLIList.size() > 0 && subletVOLIList[0].Service_Order_Line_Item__r.Qty_Needed__c != soHeaderObj.QtyNeeded) {
                		throw new BlackpurlException('{"HasError" : true, "ErrorMsg" : "Can not update qty on ordered sublet"}');
                	}
                }
                soliToUpdate.Qty_Needed__c = soHeaderObj.QtyNeeded;
                if(soHeaderObj.IsFee || soHeaderObj.IsLabour || soHeaderObj.IsSublet || 
                    (soHeaderObj.IsPart && soHeaderObj.IsNonInventoryPart != null && soHeaderObj.IsNonInventoryPart)) {
                    soliToUpdate.Item_Description__c = soHeaderObj.ItemDescription;
                }
                if(soHeaderObj.StockCommited > soHeaderObj.QtyNeeded) {
                    soliToUpdate.Qty_Committed__c = soHeaderObj.QtyNeeded;
                } else {  
                    soliToUpdate.Qty_Committed__c = soHeaderObj.StockCommited;
                }
                if(isTaxIncludingPricing && String.isBlank(soHeaderObj.DealId)) {
                    if(soHeaderObj.Tax == -100) {
                        soHeaderObj.Tax = 0;
                    }                    
                    soliToUpdate.Price_When_Tax_Included__c = soHeaderObj.KitPrice;
                    soliToUpdate.kit_Price__c = (soHeaderObj.KitPrice / (1 + (soHeaderObj.Tax / 100 ))).setScale(2, RoundingMode.HALF_UP);
                } else {
                    soliToUpdate.kit_Price__c = soHeaderObj.KitPrice;
                }
                
                List<Service_Order_Line_Item__c> soliList = [SELECT Service_Order_Header__r.Deal__c, Qty_Needed__c, Service_Order_Header__c,
                                                            Labour_Code__c, Is_Calculate_Supplies__c, Service_Order_Header__r.CO_Header__c 
                                                            FROM Service_Order_Line_Item__c WHERE Id =: soliToUpdate.Id];
                DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliToUpdate);
                
                if(soliList.size() > 0 && soliList[0].Labour_Code__c != null && soliList[0].Is_Calculate_Supplies__c) {
                    ShopSuppliesService.shopSuppliesCalculation(soliList[0].Service_Order_Header__c);
                }

                if(soliList.size() > 0) {
                    Decimal previousQty = soliList[0].Qty_Needed__c;               
                    if(String.isNotBlank(soliList[0].Service_Order_Header__r.Deal__c)) {
                        if(previousQty != soHeaderObj.QtyNeeded) {
                            DealService.createDealUnresolvedFulfillment(new List<String>{soliToUpdate.Id}, soHeaderObj.DealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_UPDATED);
                        }
                    }
                }                
            }
        
        return null;
    }
    
    public static List<SOPaymentWrapper> getSoPaymentRoleById(String recId, String status) {
        List<SO_Payment_Role__c> soPaymentRoleRecList = SOQLUtil.getSOPaymentWrapperById(recId , status);
        List<SOPaymentWrapper> soPaymentRoleObjList = new List<SOPaymentWrapper>();
        for(SO_Payment_Role__c soPaymentRoleRec : soPaymentRoleRecList) {
            soPaymentRoleObjList.add(new SOPaymentWrapper(soPaymentRoleRec));
        }
        return soPaymentRoleObjList;
    }
    
    public static void splitSOKHItem(String lineItemId) {
    	try {
	    	if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        if(AccessControl.ifObjectIsDeletable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
	        if(AccessControl.ifObjectIsDeletable('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
	
	        lineItemId = BPUtility.escapeSingleQuotes(lineItemId);
	        List<Service_Order_Kit_Header__c> sokhList = [select Id,
	                                                         (select Actual_Kit_Price__c, Kit_Price__c, Price_When_Tax_Included__c, Is_Calculate_Supplies__c, Labour_Code__c, Fee__c, Part__c, Qty_Needed__c, Service_Order_Header__c from Service_Order_Line_Items__r)
	                                                         from Service_Order_Kit_Header__c where Id =: lineItemId];
	                                                             
	        List<Service_Order_Line_Item__c> soLineItemListToInsert = new List<Service_Order_Line_Item__c>();
	        List<Service_Order_Line_Item__c> soLineItemListToDelete = new List<Service_Order_Line_Item__c>();
	            
	        for(Service_Order_Kit_Header__c sokhRec : sokhList) {
	            for(Service_Order_Line_Item__c soliRec : sokhRec.Service_Order_Line_Items__r) {
	                Service_Order_Line_Item__c newSOLIRec = new Service_Order_Line_Item__c();
	                newSOLIRec.Service_Order_Header__c = soliRec.Service_Order_Header__c;
	                
	                newSOLIRec.Labour_Code__c = soliRec.Labour_Code__c;
	                newSOLIRec.Fee__c = soliRec.Fee__c;
	                newSOLIRec.Part__c = soliRec.Part__c;
	                newSOLIRec.Qty_Needed__c = soliRec.Qty_Needed__c;
	                if(newSOLIRec.Labour_Code__c != null) {
                        newSOLIRec.Is_Calculate_Supplies__c = soliRec.Is_Calculate_Supplies__c;
	                    newSOLIRec.Kit_Price__c = soliRec.Actual_Kit_Price__c;
	                    newSOLIRec.Price_When_Tax_Included__c = soliRec.Price_When_Tax_Included__c;
	                    newSOLIRec.Actual_Kit_Price__c = soliRec.Actual_Kit_Price__c;
	                }
	                //CO_Line_Item__c newCOLIRec = coliRec.clone(false, true, false, false);
	                soLineItemListToInsert.add(newSOLIRec);
	                soLineItemListToDelete.add(soliRec);
	            }
	        }
	            
	        if(soLineItemListToDelete.size() > 0) {
	            delete soLineItemListToDelete;
	        }
	                                                         
	        if(sokhList.size() > 0) {
	            delete sokhList;
	        }
	        
	        if(soLineItemListToInsert.size() > 0) {
                DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soLineItemListToInsert);
	        }
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	} 
    }
    
    public static List<SOHeaderWrapper.HoursLogged> getHoursLogged(String soHeaderId) {
        try{
        	List<Service_Order_Header__c> soHeaderRecList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'Id' => soHeaderId});

	        List<SOHeaderWrapper.HoursLogged> hoursLoggedList = new List<SOHeaderWrapper.HoursLogged>();
	        for(Hours_Logged__c hourLoggedRec : soHeaderRecList[0].Hours_Logged__r) {
	        	if(hourLoggedRec.Start_Date_Time__c != null && hourLoggedRec.End_Date_Time__c != null) {
	        		hoursLoggedList.add(new SOHeaderWrapper.HoursLogged(hourLoggedRec));
	        	}
	        }
	    
	        return hoursLoggedList; 
        }catch(Exception e) {
        	throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
    * Method to load Category list based on category type
    **/
    public static ServiceOrderWrapper.SOMasterData getServiceJobCategories(Map<String, String> searchFields) {
        return new ServiceOrderWrapper.SOMasterData(SOQLUtil.getCategories(searchFields));
    }
    
    public static void refreshSOPricingAndTax(String recalculationObjJson) {
		if(String.isNotBlank(recalculationObjJson)) {
			CORecalculationWrapper recalculationObj = (CORecalculationWrapper) System.JSON.deserialize(recalculationObjJson, CORecalculationWrapper.class);
			if(String.isNotBlank(recalculationObj.SOHeaderId)) {
				List<Service_Order_Header__c> soList = [Select Id, Provider__c, Job_Type__c, Is_Tax_Based_On_Customer_Address__c, 
                (Select Id, Type__c FROM Tax_Exemptions__r WHERE Type__c =: TaxUtility.AUTOMATED_CUSTOMER) from Service_Order_Header__c where Id =: recalculationObj.SOHeaderId AND Invoice_Number__c = null AND Deal__r.Invoice_Number__c = null];
				if(recalculationObj.IsResetPricing) {
					SOTriggerHelper.updatePLFields(soList);
				}
				if(recalculationObj.IsRecalculateTaxes) {
					SOTriggerHelper.refreshTaxExemptions = true;
                    refreshAutomatedTaxesOnSO(soList[0]);
				}
				DMLUtility.updateSobjectList('Service_Order_Header__c', soList);
				SOPaymentRoleService.refreshIndividualTaxes(new List<String>{recalculationObj.SOHeaderId}, true);
			}
		}
    }
    
    private static ResponseWrapper refreshAutomatedTaxesOnSO(Service_Order_Header__c soRec) {
        ResponseWrapper resObj = new ResponseWrapper('success', 'Customer taxes populated successfully');
        if(soRec != null && soRec.Is_Tax_Based_On_Customer_Address__c && soRec.Provider__c != null) {
            resObj = Customer_Service.populateCustomerTaxesOnCO(soRec.Id, soRec.Provider__c, true);
        }
        if(resObj != null && resObj.responseStatus.equalsIgnoreCase('success')) {
            DMLUtility.deleteSObjectList('Tax_Exemption__c', soRec.Tax_Exemptions__r);
        }
        return resObj;
    }
    
    public static void refreshSOLIPricingAndTax(String coHeaderId, String soHeaderId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<CO_Header__c> coHeaderList = [select Customer__c, Discount_Markup_From_Prive_Level__c, Part_Price_Base_From_Price_Level__c,
                                                (select Part__c, Fee__c, CO_Kit_Header__c, Kit_Header_Line_Item__c, Id, Deal__c, Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c, 
                                                Is_Environmental_Fee__c, Is_Linked_Fee__c, Type__c, Price_When_Tax_Included__c, Price__c, Bulk_Discount_Percent__c, Calculated_Customer_Price__c,
                                                Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c, Service_Order_Line_Item__r.Service_Order_Kit_Header__c,
                                                Service_Order_Line_Item__r.Service_Order_Header__r.Provider__r.Price_Level__r.Discount_Markup__c,
                                                Service_Order_Line_Item__r.Service_Order_Header__r.Provider__r.Price_Level__r.Part_Price_Base__c from CO_Line_Items__r where 
                                                Invoice_Number__c = null AND CO_Kit_Header__c = null AND Service_Order_Line_Item__r.Service_Order_Kit_Header__c = null 
                                                AND Service_Order_Line_Item__r.Service_Order_Header__c =: soHeaderId) 
                                                from CO_Header__c where Id =: coHeaderId];
                                               // AND (Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c != 'Internal' OR Service_Order_Line_Item__r.Service_Order_Header__r.CO_Header__r.CO_Type__c = 'Internal Service')
		COTriggerHelper.isRetainItemPrices = true;
		COTriggerHelper.setPLforCOLIs(coHeaderList);
        COTriggerHelper.salesTaxCalculation(soHeaderId, coHeaderId, null);
        COTriggerHelper.setPriceLevelAndSalesTaxForLabourInServiceOrder(soHeaderId);
		SOPaymentRoleService.refreshIndividualTaxes(new List<Id>{soHeaderId});
        CustomerOrderCtrl_V2.isRefreshCOKit = true;
        SO_KLI_Recalculation.changePriceWhenCustomerIsChanged(new Set<Id>{soHeaderId}, coHeaderId);
    }
    
    public static String saveCustomerApproval(String customerApprovalObj, String soHeaderIds)  {
    	//try {
	        if(AccessControl.ifObjectFieldIsUpdateable('CustomerApproval__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }

        	CustomerApproval custApprovalObj = (CustomerApproval)System.JSON.deserialize(customerApprovalObj, CustomerApproval.class);
        	
        	List<CustomerApproval__c> approvalListToUpsert = new List<CustomerApproval__c>();
			
			CustomerApproval__c custApprovalRec = new CustomerApproval__c();
			custApprovalRec.Status__c = 'Approved';
			
			custApprovalRec.ApprovalDate__c = date.today();
			
			custApprovalRec.ApprovalType__c = custApprovalObj.ApprovalType;
			custApprovalRec.ApprovalDetailJson__c = custApprovalObj.ApprovalDetailJson;
			approvalListToUpsert.add(custApprovalRec);
			 
            DMLUtility.insertSobjectList('CustomerApproval__c', approvalListToUpsert);
    		List<Service_Job_To_Customer_Approval__c> serviceJobToCustomerApprovalList = new List<Service_Job_To_Customer_Approval__c>();
    		List<String> soHeaderIdList = new List<String>();
			soHeaderIdList = soHeaderIds.split(',');
    		for(integer i=0; i < soHeaderIdList.size() ; i++){
    			Service_Job_To_Customer_Approval__c serviceJobToCustomerApproval = new Service_Job_To_Customer_Approval__c();
    			serviceJobToCustomerApproval.Service_Order_Header__c = soHeaderIdList[i];
    			serviceJobToCustomerApproval.Customer_Approval__c = approvalListToUpsert[0].Id;
    			serviceJobToCustomerApprovalList.add(serviceJobToCustomerApproval);
    		}
    		if(String.isNotBlank(custApprovalObj.signatureBlobValue)) {
    			List<String> base64 = new List<String>();
    			base64 = custApprovalObj.signatureBlobValue.split(',');
            	Blob actualdata = EncodingUtil.base64Decode(base64[1]);
    			List<Attachment> attachmentToBeInserted = new List<Attachment>();
				Attachment att = new Attachment(ParentId = approvalListToUpsert[0].Id, Body = actualdata);
	            att.Name = 'Customer Signature.png'; 
		        attachmentToBeInserted.add(att);
	    		if(attachmentToBeInserted.size() > 0) {
                DMLUtility.insertSobjectList('Attachment', attachmentToBeInserted);
    			}
    		}
            
    		if(serviceJobToCustomerApprovalList.size() > 0) {
                DMLUtility.insertSobjectList('Service_Job_To_Customer_Approval__c', serviceJobToCustomerApprovalList);
    		}
    		  
    		
    		return 'Success';
    	//} catch (Exception e) {
    	//	throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	//}
    }
    
    public static String addMultiplePartsInServiceJob(List<COService.SearchPartDetailWrapper> partToInsertList, String soHeaderId) {
    	Map<String, Decimal> partIdTQtyToInsertMap = new Map<String, Decimal>();
		for(COService.SearchPartDetailWrapper partInfoObj : partToInsertList) {
    		partIdTQtyToInsertMap.put(partInfoObj.PartId, partInfoObj.Qty);
		}
    	Map<Id, Part__c> partIdToPartRecMap = new Map<Id, Part__c>([select Part_Number__c, Enviro_Fee__c, 
                                                                    Enviro_Fee_Code__c, 
                                                                    Enviro_Fee_Code__r.Code__c, 
                                                                    Enviro_Fee_Code__r.Description__c 
                                                                    from Part__c 
                                                                    where Id =: partIdTQtyToInsertMap.keySet()]);
        if(partIdToPartRecMap.keySet().size() == 0) {
            return null;
        }
            
    	List<Service_Order_Header__c> serviceOrderHeaderList = [Select Deal__c, Deal_Item__c, CO_Header__c from Service_Order_Header__c where Id = :soHeaderId];
        List<Service_Order_Line_Item__c> soliListToInsert = new List<Service_Order_Line_Item__c>();
        Service_Order_Line_Item__c relatedEnvFeeRec;
        Service_Order_Line_Item__c soliRec;
        
        for(COService.SearchPartDetailWrapper partInfoObj : partToInsertList) {
            soliRec = new Service_Order_Line_Item__c();
            soliRec.Service_Order_Header__c = soHeaderId;
            soliRec.Part__c = partInfoObj.PartId;
            soliRec.Qty_Needed__c = (partInfoObj.Qty != null && partInfoObj.Qty != 0) ? partInfoObj.Qty : 1;
            if(serviceOrderHeaderList.size() > 0) {
                soliRec.Deal__c = serviceOrderHeaderList[0].Deal__c;
                soliRec.Deal_Item__c = serviceOrderHeaderList[0].Deal_Item__c;
            }
            soliRec.Actual_Kit_Price__c = (soliRec.Kit_Price__c == null) ? 0 : soliRec.Kit_Price__c;
            soliListToInsert.add(soliRec);
            if(partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee__c != null && partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee_Code__c != null) {
                relatedEnvFeeRec = new Service_Order_Line_Item__c();
                relatedEnvFeeRec = insertFeeInGrid(partIdToPartRecMap.get(partInfoObj.PartId).Enviro_Fee_Code__c, soHeaderId, true, partIdToPartRecMap.get(partInfoObj.PartId), 1, null);
                soliListToInsert.add(relatedEnvFeeRec);
            }  
        }
        DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliListToInsert);
        Set<String> soliIdSet = new Set<String>();
        for(Service_Order_Line_Item__c solineItemRec : soliListToInsert) {
            soliIdSet.add(solineItemRec.Id);
        }
        DealService.createDealUnresolvedFulfillment(new List<String>(soliIdSet), serviceOrderHeaderList[0].Deal__c, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
    
        return serviceOrderHeaderList[0].CO_Header__c;
    }
    
    public static Map<String, List<ProfitabilityWrapper.SectionProfitabilityWrapper>> getServiceJobProfitability(String coId) {
    	Map<String, List<ProfitabilityWrapper.SectionProfitabilityWrapper>> sectionTypeToProfitabilityWrapperMap = 
    		new Map<String, List<ProfitabilityWrapper.SectionProfitabilityWrapper>>();
    		
    	List<ProfitabilityWrapper.SectionProfitabilityWrapper> profitabilityWrapperList = new List<ProfitabilityWrapper.SectionProfitabilityWrapper>();
    	
    	List<Service_Order_Line_Item__c> soLineItemList = [SELECT Service_Order_Header__c, Service_Order_Header__r.SO_Status__c, Service_Order_Header__r.Invoice_Number__c, Service_Order_Header__r.Name__c, Service_Order_Header__r.Deal__c, Labour_Code__c, Part__c, Part__r.Part_Type__c, Fee__c, 
    		Service_Order_Header__r.Total_Labour_Cost__c, Service_Order_Header__r.Total_Fee_Cost__c, Service_Order_Header__r.Total_Shop_Supplies_Cost__c, Service_Order_Header__r.Total_Related_Sublet_Cost__c, 
    		Type__c, Sublet__c, Kit_Price__c, Price_When_Tax_Included__c, Tax_Percent__c, Qty_Needed__c, Fee__r.Cost_Method__c, Fee__r.Is_Include_In_Profit_Calculation__c, Fee__r.Cost_Rate__c, Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c, 
    		Sublet__r.Cost_Method__c, Cost__c, Total_Cost__c, Sublet__r.Cost__c, (select Adjusted_Cost_Coli__c, Qty__c, Part__r.Average_Cost__c, Part__r.Last_Cost__c from CO_Line_Items__r) FROM Service_Order_Line_Item__c WHERE Service_Order_Header__r.CO_Header__c =: coId Order By Service_Order_Header__r.Deal__c NULLS First, Service_Order_Header__r.CreatedDate ASC];
                                    
       
       	if(soLineItemList.size() > 0) {
       		Map<String, List<Service_Order_Line_Item__c>> soIdToSOLIListMap = new Map<String, List<Service_Order_Line_Item__c>>();
       		Map<String, Service_Order_Header__c> soIdToSORecMap = new Map<String, Service_Order_Header__c>();
       		for(Service_Order_Line_Item__c soliRec : soLineItemList) {
       			if(!soIdToSOLIListMap.containsKey(soliRec.Service_Order_Header__c)) {
       				soIdToSOLIListMap.put(soliRec.Service_Order_Header__c, new List<Service_Order_Line_Item__c>());
       			}
       			soIdToSOLIListMap.get(soliRec.Service_Order_Header__c).add(soliRec);
       			
       			if(!soIdToSORecMap.containsKey(soliRec.Service_Order_Header__c)) {
       				soIdToSORecMap.put(soliRec.Service_Order_Header__c, soliRec.Service_Order_Header__r);
       			}
       		}
       		Decimal defaultTechnicianCostingRate = GeneralConfiguration.getDefaultTechnicianCostingRate();
       		//Boolean IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        
	    	Decimal partSales, merchSales, labourSales, feeSales, shopSuppliesSales, subletSales;
			Decimal partCost, merchCost, labourCost, feeCost, shopSuppliesCost, subletCost;
			
			List<String> coHeaderIdList = new List<String>();
			
	    	for(String soId : soIdToSOLIListMap.keySet()) {
	    		partSales = merchSales = labourSales = feeSales = shopSuppliesSales = subletSales = null;
				partCost = merchCost = labourCost = feeCost = shopSuppliesCost =subletCost = 0;
				
				Boolean isDealService = false;
	    		for(Service_Order_Line_Item__c soli : soIdToSOLIListMap.get(soId)) {
	    			isDealService = String.isNotBlank(soli.Service_Order_Header__r.Deal__c) ? true : false;
	    			
		        	soli.Qty_Needed__c = (soli.Qty_Needed__c != null) ? soli.Qty_Needed__c : 0;
		        	soli.Kit_Price__c = (soli.Kit_Price__c != null) ? soli.Kit_Price__c : 0;
	        		if(soli.Fee__c != null && soli.Fee__r.Is_Include_In_Profit_Calculation__c) {
	        			Decimal cost = 0;
	        			if(soli.Fee__r.Cost_Method__c == 'Fixed Cost' && soli.Fee__r.Cost_Rate__c !=null && soli.Qty_Needed__c != null) {
		                    cost = (soli.Qty_Needed__c * soli.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
		                } else if(soli.Fee__r.Cost_Method__c == 'Percent Retail'  && soli.Fee__r.Cost_Rate__c !=null &&  soli.Qty_Needed__c !=null ){
		                    cost = (soli.Qty_Needed__c * ((soli.Kit_Price__c *  soli.Fee__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
		                }
	                	if(soli.Type__c == Constants.SHOP_SUPPLY) {
	                		soli.Tax_Percent__c = soli.Tax_Percent__c != null ? soli.Tax_Percent__c : 0;
	                		shopSuppliesSales = (shopSuppliesSales != null) ? shopSuppliesSales : 0;
	                		soli.Kit_Price__c = (GeneralConfiguration.getTaxIncludingPricing() && soli.Price_When_Tax_Included__c != null) ? 
	                			(soli.Price_When_Tax_Included__c / (1 + soli.Tax_Percent__c / 100)) : soli.Kit_Price__c;
	        		        shopSuppliesSales += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
	        		        shopSuppliesCost += cost;
	        		    } else {
	        		    	feeSales = (feeSales != null) ? feeSales : 0;
	                	    feeSales += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
	                	    feeCost += cost;
	        		    }
	        		    //cost = null;
	        		} else if(soli.Part__c != null) {
                						
	        			if(String.isNotBlank(soli.Part__r.Part_Type__c) && soli.Part__r.Part_Type__c == 'Merchandise') {
	        				merchSales = (merchSales != null) ? merchSales : 0;
	        				merchSales += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
	        				for(CO_Line_Item__c coli : soli.CO_Line_Items__r) {
	        					Decimal partAvgCost = coli.Part__r.Average_Cost__c != null && coli.Part__r.Average_Cost__c != 0 ? 
                						coli.Part__r.Average_Cost__c : (coli.Part__r.Last_Cost__c != null ? coli.Part__r.Last_Cost__c : 0);
                						
			                    merchCost += (soli.Service_Order_Header__r.Invoice_Number__c != null ? ((coli.Adjusted_Cost_Coli__c != null) ? coli.Adjusted_Cost_Coli__c : 0) :
			                    	((partAvgCost != null) ? (partAvgCost * coli.Qty__c) : 0));
			                }
	        			} else {
	        				partSales = (partSales != null) ? partSales : 0;
	        				partSales += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
	        				for(CO_Line_Item__c coli : soli.CO_Line_Items__r) {
	        					Decimal partAvgCost = coli.Part__r.Average_Cost__c != null && coli.Part__r.Average_Cost__c != 0 ? 
                						coli.Part__r.Average_Cost__c : (coli.Part__r.Last_Cost__c != null ? coli.Part__r.Last_Cost__c : 0);
                						
			                    partCost += (soli.Service_Order_Header__r.Invoice_Number__c != null ? ((coli.Adjusted_Cost_Coli__c != null) ? coli.Adjusted_Cost_Coli__c : 0) :
			                    	((partAvgCost != null) ? (partAvgCost * coli.Qty__c) : 0));
			                }
	        			}
	        		} else if(soli.Labour_Code__c != null) {
	        			labourSales = (labourSales != null) ? labourSales : 0;
	        			labourSales += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
	        			if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
	        				if(ServiceJobUtil.isJobComplete(soli.Service_Order_Header__r.SO_Status__c)) {
	        					soli.Total_Cost__c = (soli.Total_Cost__c != null ? soli.Total_Cost__c : 0);
	        					labourCost += (soli.Total_Cost__c).setScale(2, RoundingMode.HALF_UP);
	        				} else {
	        					labourCost += (soli.Qty_Needed__c * defaultTechnicianCostingRate).setScale(2, RoundingMode.HALF_UP);
	        				}
	        			} else {
	        				if(soli.Labour_Code__r.Cost_Method__c == 'Fixed Cost' && soli.Labour_Code__r.Cost_Rate__c != null && soli.Qty_Needed__c !=null){
			                    labourCost += (soli.Qty_Needed__c * soli.Labour_Code__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
			                } else if(soli.Labour_Code__r.Cost_Method__c == 'Percent Retail' && soli.Labour_Code__r.Cost_Rate__c !=null && soli.Qty_Needed__c !=null ){
			                    labourCost += (soli.Qty_Needed__c * ((soli.Kit_Price__c *  soli.Labour_Code__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
			                }
	        			}
	        		} else if(soli.Sublet__c != null) {
	        			subletSales = (subletSales != null) ? subletSales : 0;
	        			subletSales += (soli.Qty_Needed__c * soli.Kit_Price__c).setScale(2, RoundingMode.HALF_UP);
	        			if(soli.Cost__c != null) {
	        				subletCost += (soli.Qty_Needed__c * soli.Cost__c).setScale(2, RoundingMode.HALF_UP);
	        			} else if(soli.Sublet__r.Cost_Method__c == 'Fixed Cost' && soli.Sublet__r.Cost__c != null && soli.Qty_Needed__c !=null){
		                    subletCost += (soli.Qty_Needed__c * soli.Sublet__r.Cost__c).setScale(2, RoundingMode.HALF_UP);
		                } else if(soli.Sublet__r.Cost_Method__c == 'Percent Retail' && soli.Sublet__r.Cost__c !=null && soli.Qty_Needed__c !=null ){
		                    subletCost += (soli.Qty_Needed__c * ((soli.Kit_Price__c *  soli.Sublet__r.Cost__c)/100)).setScale(2, RoundingMode.HALF_UP);
		                }
	        		}
	    		}
	    		
	    		if(soIdToSORecMap.get(soId).Invoice_Number__c != null && soIdToSORecMap.get(soId).SO_Status__c == ServiceJobUtil.INVOICED) {
					labourCost = soIdToSORecMap.get(soId).Total_Labour_Cost__c;
					feeCost = soIdToSORecMap.get(soId).Total_Fee_Cost__c;
					shopSuppliesCost = soIdToSORecMap.get(soId).Total_Shop_Supplies_Cost__c;
					subletCost = soIdToSORecMap.get(soId).Total_Related_Sublet_Cost__c;
				}
                
	    		List<ProfitabilityWrapper.ProductProfitabilityWrapper> soProfitabilityObjList = new List<ProfitabilityWrapper.ProductProfitabilityWrapper>();
				
				if(partSales != null) {
					soProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Parts', partSales, partCost));
				}
				if(merchSales != null) {
					soProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Merchandise', merchSales, merchCost));
				}
				if(labourSales != null) {
					soProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Labor', labourSales, labourCost));
				}
				if(subletSales != null) {
					soProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Sublet', subletSales, subletCost));
				}
				if(shopSuppliesSales != null) { 
					soProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Shop Supplies', shopSuppliesSales, shopSuppliesCost));
				}
	       		if(feeSales != null) {
					soProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Fees', feeSales, feeCost));
				}
	       		
	       		if(soProfitabilityObjList.size() > 0) {
	       			if(soIdToSORecMap.containsKey(soId)) {
	       				//profitabilityWrapperList.add(new ProfitabilityWrapper.SectionProfitabilityWrapper(soIdToSORecMap.get(soId).Name__c, soProfitabilityObjList));
	       				if(String.isNotBlank(soIdToSORecMap.get(soId).Deal__c)) {
	       					if(!sectionTypeToProfitabilityWrapperMap.containsKey('Deal Service Job')) {
	       						sectionTypeToProfitabilityWrapperMap.put('Deal Service Job', new List<ProfitabilityWrapper.SectionProfitabilityWrapper>());
	       					}
	       					sectionTypeToProfitabilityWrapperMap.get('Deal Service Job').add(new ProfitabilityWrapper.SectionProfitabilityWrapper(soIdToSORecMap.get(soId).Name__c, soProfitabilityObjList));
	       				} else {
	       					if(!sectionTypeToProfitabilityWrapperMap.containsKey('Service Job')) {
	       						sectionTypeToProfitabilityWrapperMap.put('Service Job', new List<ProfitabilityWrapper.SectionProfitabilityWrapper>());
	       					}
	       					sectionTypeToProfitabilityWrapperMap.get('Service Job').add(new ProfitabilityWrapper.SectionProfitabilityWrapper(soIdToSORecMap.get(soId).Name__c, soProfitabilityObjList));
	       				}
	       			}
	       		}
	    	}
       	}
       	return sectionTypeToProfitabilityWrapperMap;
    }
    
    /**
    * Method to get all customer units which are having status 'Active'
    **/
    public static List<ServiceOrderWrapper.Unit> getActiveCOUList(String customerId) { 
        List<Customer_Owned_Unit__c> couRecords = SOQLUtil.geCOUList(customerId, new Map<String, String>{'Status__c' => 'Active'});
        List<ServiceOrderWrapper.Unit> couList = new List<ServiceOrderWrapper.Unit>();
        for(Customer_Owned_Unit__c couRec : couRecords) {
        	couList.add(new ServiceOrderWrapper.Unit(couRec));
        }
        return couList;
    }
        
    public static void populateSOIndividualsCostTotalsAfterFinalize(String coInvoiceId) {
    	List<Service_Order_Line_Item__c> soLineItemList = [SELECT Service_Order_Header__c, Service_Order_Header__r.Deal__c, Labour_Code__c, Part__c, Fee__c, 
    		Type__c, Sublet__c, Kit_Price__c, Price_When_Tax_Included__c, Tax_Percent__c, Qty_Needed__c, Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c, Fee__r.Is_Include_In_Profit_Calculation__c,
    		Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c, Sublet__r.Cost_Method__c, Cost__c, Total_Cost__c, Sublet__r.Cost__c, 
    		(select Adjusted_Cost_Coli__c from CO_Line_Items__r) FROM Service_Order_Line_Item__c 
    		WHERE Service_Order_Header__r.Invoice_Number__c =: coInvoiceId AND Service_Order_Header__r.SO_Status__c = :ServiceJobUtil.INVOICED Order By Service_Order_Header__r.Deal__c NULLS First, Service_Order_Header__r.CreatedDate ASC];
                                    
       
       	if(soLineItemList.size() > 0) {
       		List<Service_Order_Header__c> soListToUpdate = new List<Service_Order_Header__c>();
       		Decimal partCost, merchCost, labourCost, feeCost, shopSuppliesCost, subletCost;
       		
       		Map<String, List<Service_Order_Line_Item__c>> soIdToSOLIListMap = new Map<String, List<Service_Order_Line_Item__c>>();
       		Map<String, Service_Order_Header__c> soIdToSORecMap = new Map<String, Service_Order_Header__c>();
       		for(Service_Order_Line_Item__c soliRec : soLineItemList) {
       			if(!soIdToSOLIListMap.containsKey(soliRec.Service_Order_Header__c)) {
       				soIdToSOLIListMap.put(soliRec.Service_Order_Header__c, new List<Service_Order_Line_Item__c>());
       			}
       			soIdToSOLIListMap.get(soliRec.Service_Order_Header__c).add(soliRec);
       			
       			if(!soIdToSORecMap.containsKey(soliRec.Service_Order_Header__c)) {
       				soIdToSORecMap.put(soliRec.Service_Order_Header__c, soliRec.Service_Order_Header__r);
       			}
       		}
			
			List<String> coHeaderIdList = new List<String>();
			
	    	for(String soId : soIdToSOLIListMap.keySet()) {
	    		Service_Order_Header__c soRec = new Service_Order_Header__c(Id = soId); 
				partCost = merchCost = labourCost = feeCost = shopSuppliesCost = subletCost = 0;
				
				for(Service_Order_Line_Item__c soli : soIdToSOLIListMap.get(soId)) {
	    			soli.Qty_Needed__c = (soli.Qty_Needed__c != null) ? soli.Qty_Needed__c : 0;
		        	soli.Kit_Price__c = (soli.Kit_Price__c != null) ? soli.Kit_Price__c : 0;
	        		Decimal cost = 0;
	        		if(soli.Fee__c != null && soli.Fee__r.Is_Include_In_Profit_Calculation__c) {
	        			//FEE & SHOP SUPPLIES COST
	        			if(soli.Fee__r.Cost_Method__c == 'Fixed Cost' && soli.Fee__r.Cost_Rate__c != null && soli.Qty_Needed__c != null) {
		                    cost = (soli.Qty_Needed__c * soli.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
		                } else if(soli.Fee__r.Cost_Method__c == 'Percent Retail'  && soli.Fee__r.Cost_Rate__c !=null &&  soli.Qty_Needed__c !=null ){
		                    cost = (soli.Qty_Needed__c * ((soli.Kit_Price__c * soli.Fee__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
		                }
	                	if(soli.Type__c == Constants.SHOP_SUPPLY) {
	        		        shopSuppliesCost += cost;
	        		    } else {
	                	    feeCost += cost;
	        		    }
	        		    //cost = null;
	        		} else if(soli.Labour_Code__c != null) {
	        			//already populated when job was complete
	        			// LABOUR COST
	        			if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
	        				soli.Total_Cost__c = ((soli.Total_Cost__c != null) ? soli.Total_Cost__c : 0);
                			cost = (soli.Total_Cost__c).setScale(2, RoundingMode.HALF_UP);
	        			} else {
		        			if(soli.Labour_Code__r.Cost_Method__c == 'Fixed Cost' && soli.Labour_Code__r.Cost_Rate__c != null && soli.Qty_Needed__c !=null){
			                    cost = (soli.Qty_Needed__c * soli.Labour_Code__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
			                } else if(soli.Labour_Code__r.Cost_Method__c == 'Percent Retail' && soli.Labour_Code__r.Cost_Rate__c !=null && soli.Qty_Needed__c !=null ){
			                    cost = (soli.Qty_Needed__c * ((soli.Kit_Price__c *  soli.Labour_Code__r.Cost_Rate__c)/100)).setScale(2, RoundingMode.HALF_UP);
			                }
	        			}
	        			labourCost += cost;
	        		} else if(soli.Sublet__c != null) {
	        			// SUBLET COST
	        			if(soli.Cost__c != null) {
	        				cost = (soli.Qty_Needed__c * soli.Cost__c).setScale(2, RoundingMode.HALF_UP);
	        			} else if(soli.Sublet__r.Cost_Method__c == 'Fixed Cost' && soli.Sublet__r.Cost__c != null && soli.Qty_Needed__c !=null){
		                    cost = (soli.Qty_Needed__c * soli.Sublet__r.Cost__c).setScale(2, RoundingMode.HALF_UP);
		                } else if(soli.Sublet__r.Cost_Method__c == 'Percent Retail' && soli.Sublet__r.Cost__c !=null && soli.Qty_Needed__c !=null ){
		                    cost = (soli.Qty_Needed__c * ((soli.Kit_Price__c *  soli.Sublet__r.Cost__c)/100)).setScale(2, RoundingMode.HALF_UP);
		                }
		                subletCost += cost;
	        		} else if(soli.Part__c != null) {
	        			for(CO_Line_Item__c coli : soli.CO_Line_Items__r) {
        					cost += ((coli.Adjusted_Cost_Coli__c != null) ? coli.Adjusted_Cost_Coli__c : 0);
		                }
	        		}
	        		soli.Total_Cost__c = cost;
	    		}
	       		
	       		soRec.Total_Labour_Cost__c = labourCost.setScale(2, RoundingMode.HALF_UP);
	       		soRec.Total_Fee_Cost__c = feeCost.setScale(2, RoundingMode.HALF_UP);
	       		soRec.Total_Shop_Supplies_Cost__c = shopSuppliesCost.setScale(2, RoundingMode.HALF_UP);
	       		soRec.Total_Related_Sublet_Cost__c = subletCost.setScale(2, RoundingMode.HALF_UP);
                soListToUpdate.add(soRec);
	    	}
            DMLUtility.updateSobjectList('Service_Order_Header__c', soListToUpdate);
            ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
            DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soLineItemList);
            ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
       	}
    }
    
	public static String handleBillToCustomerVariance(Map<Id, Claim_Line_Item__c> IdToClaimLineItemMap, Map<Id, Claim_Line_Item__c> claimLineOldmap, String coHeaderId, String couId) {
        String customerPaySOId = createServiceJobWithSpecificFields(coHeaderId, couId, new List<String>{'Claim variances billed to the customer'}, false);
        
        List<Service_Order_Line_Item__c>  soliListToInsert = new List<Service_Order_Line_Item__c>();
		Boolean isShopSupplyAvailable = false;
        List<SObject> sObjectListToInsert = COService.addLinkedFee(customerPaySOId, null, 'Service Job');
        if(sObjectListToInsert != null) {
            soliListToInsert.addAll((List<Service_Order_Line_Item__c>) sObjectListToInsert);
        }
		Map<Id, Service_Order_Line_Item__c> oldSOLIIdToNewRecMap = new Map<Id, Service_Order_Line_Item__c>();
        for(String claimLIId : IdToClaimLineItemMap.KeySet()) {
        	Claim_Line_Item__c claimLineItemRec = claimLineOldmap.get(claimLIId);
        	Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c(Service_Order_Header__c = customerPaySOId);
    		soliRec.Qty_Needed__c = (IdToClaimLineItemMap.get(claimLIId).Variance_Qty__c != null && IdToClaimLineItemMap.get(claimLIId).Variance_Qty__c != 0) ? 
    							IdToClaimLineItemMap.get(claimLIId).Variance_Qty__c : 1;
    		soliRec.Price_When_Tax_Included__c = claimLineItemRec.Service_Order_Line_Item__r.Price_When_Tax_Included__c;
			soliRec.Kit_Price__c = claimLineItemRec.Service_Order_Line_Item__r.Kit_Price__c;
			soliRec.Actual_Kit_Price__c = claimLineItemRec.Service_Order_Line_Item__r.Actual_Kit_Price__c;
			soliRec.Is_Calculate_Supplies__c = claimLineItemRec.Service_Order_Line_Item__r.Is_Calculate_Supplies__c;
			soliRec.Is_Hidden__c = claimLineItemRec.Service_Order_Line_Item__r.Is_Hidden__c;
			soliRec.Type__c = claimLineItemRec.Service_Order_Line_Item__r.Type__c;
			if(soliRec.Is_Calculate_Supplies__c) {
				isShopSupplyAvailable = true;
			}
        	if(claimLineItemRec.Service_Order_Line_Item__r.Part__c != null) {
        		soliRec.Part__c = claimLineItemRec.Service_Order_Line_Item__r.Part__c;        		
        	} else if(claimLineItemRec.Service_Order_Line_Item__r.Fee__c != null) {
        		soliRec.Fee__c = claimLineItemRec.Service_Order_Line_Item__r.Fee__c;
				soliRec.Item_Description__c = claimLineItemRec.Service_Order_Line_Item__r.Item_Description__c;
				soliRec.Item_Code__c = claimLineItemRec.Service_Order_Line_Item__r.Item_Code__c;
        	} else if(claimLineItemRec.Service_Order_Line_Item__r.Labour_Code__c != null) {
        		soliRec.Labour_Code__c = claimLineItemRec.Service_Order_Line_Item__r.Labour_Code__c;
        	} else if(claimLineItemRec.Service_Order_Line_Item__r.Sublet__c != null) {
        		soliRec.Sublet__c = claimLineItemRec.Service_Order_Line_Item__r.Sublet__c;
        	}
			soliRec.Status__c = claimLineItemRec.Service_Order_Line_Item__r.Status__c;
			soliRec.Vendor_Order_Header__c = claimLineItemRec.Service_Order_Line_Item__r.Vendor_Order_Header__c;
			soliRec.VO_Number__c = claimLineItemRec.Service_Order_Line_Item__r.VO_Number__c;
			soliRec.VO_Status__c = claimLineItemRec.Service_Order_Line_Item__r.VO_Status__c;
			soliRec.Qty_Committed__c = claimLineItemRec.Service_Order_Line_Item__r.Qty_Committed__c;
			soliRec.Cost__c = claimLineItemRec.Service_Order_Line_Item__r.Cost__c;
			soliRec.Expected_Delivery_Date__c = claimLineItemRec.Service_Order_Line_Item__r.Expected_Delivery_Date__c;
			oldSOLIIdToNewRecMap.put(claimLineItemRec.Service_Order_Line_Item__c, soliRec);
        }
		soliListToInsert.addAll(oldSOLIIdToNewRecMap.values());

		Map<Id, Service_Order_Line_Item__c> soliMap = new Map<Id, Service_Order_Line_Item__c>(
			[Select Id, Sublet__c, Part__c, Fee__c, CO_Line_Item__c, CO_Line_Item__r.Status__c, CO_Line_Item__r.Vendor_Order_Header__c, 
			CO_Line_Item__r.VO_Number__c, CO_Line_Item__r.Qty_Committed__c, CO_Line_Item__r.VO_Status__c, CO_Line_Item__r.Oversold_Qty__c, 
			CO_Line_Item__r.Expected_Delivery_Date__c, (Select Id FROM Vendor_Order_Line_Items__r) FROM Service_Order_Line_Item__c 
			WHERE Id IN: oldSOLIIdToNewRecMap.keySet()]);

		Map<Id, List<Vendor_Order_Line_Item__c>> coliIdToVOLIListMap = new Map<Id, List<Vendor_Order_Line_Item__c>>();
		for(Vendor_Order_Line_Item__c voliRec : [Select Id, CO_Line_Item__c, CO_Line_Item__r.Service_Order_Line_Item__c, 
		CO_Line_Item__r.Status__c, CO_Line_Item__r.Vendor_Order_Header__c, CO_Line_Item__r.VO_Number__c, 
		CO_Line_Item__r.VO_Status__c, CO_Line_Item__r.Expected_Delivery_Date__c FROM Vendor_Order_Line_Item__c WHERE
		CO_Line_Item__c != null AND CO_Line_Item__r.Service_Order_Line_Item__c IN: oldSOLIIdToNewRecMap.keySet()]) {
			if(!coliIdToVOLIListMap.containsKey(voliRec.CO_Line_Item__c)) {
				coliIdToVOLIListMap.put(voliRec.CO_Line_Item__c, new List<Vendor_Order_Line_Item__c>());
			}
			coliIdToVOLIListMap.get(voliRec.CO_Line_Item__c).add(voliRec);
		}

		COLineItemTriggerHelper.isMoveLineItem = ServiceOrderLineItemTriggerHelper.isMoveLineItem = true;
        delete IdToClaimLineItemMap.values();
        updateVarianceClaimLineItems(oldSOLIIdToNewRecMap.keySet());
        DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliListToInsert);
		COLineItemTriggerHelper.isMoveLineItem = ServiceOrderLineItemTriggerHelper.isMoveLineItem = false;

        soliMap.putAll(new Map<Id, Service_Order_Line_Item__c>(
			[Select Id, Sublet__c, Part__c, Fee__c, CO_Line_Item__c, CO_Line_Item__r.Status__c, CO_Line_Item__r.Vendor_Order_Header__c, 
			CO_Line_Item__r.VO_Number__c, CO_Line_Item__r.Qty_Committed__c, CO_Line_Item__r.VO_Status__c, CO_Line_Item__r.Oversold_Qty__c, 
			CO_Line_Item__r.Expected_Delivery_Date__c, (Select Id FROM Vendor_Order_Line_Items__r) FROM Service_Order_Line_Item__c 
			WHERE Id IN: soliListToInsert]));
		
		List<CO_Line_Item__c> coliUpdateList = new List<CO_Line_Item__c>();
		List<Service_Order_Line_Item__c> soliUpdateList = new List<Service_Order_Line_Item__c>();
		List<Vendor_Order_Line_Item__c> voliUpdateList = new List<Vendor_Order_Line_Item__c>();
		//TO Update Fee Price in Third party when claim is denied
		List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
		List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();
		for(Id soliId : oldSOLIIdToNewRecMap.keySet()) {
			if(soliMap.get(soliId).Sublet__c != null && !soliMap.get(soliId).Vendor_Order_Line_Items__r.isEmpty()) {
				for(Vendor_Order_Line_Item__c voliRec : soliMap.get(soliId).Vendor_Order_Line_Items__r) {
					voliRec.Service_Order_Line_Item__c = oldSOLIIdToNewRecMap.get(soliId).Id;
					voliUpdateList.add(voliRec);
				}
			} else if(soliMap.get(soliId).Part__c != null && coliIdToVOLIListMap.containsKey(soliMap.get(soliId).CO_Line_Item__c) && 
			!coliIdToVOLIListMap.get(soliMap.get(soliId).CO_Line_Item__c).isEmpty()) {
				Service_Order_Line_Item__c newSOLI = oldSOLIIdToNewRecMap.get(soliId);
				CO_Line_Item__c newCOLI = new CO_Line_Item__c(Id = soliMap.get(newSOLI.Id).CO_Line_Item__c);
				newCOLI.Qty_Committed__c = soliMap.get(soliId).CO_Line_Item__r.Qty_Committed__c;
				newCOLI.Status__c = soliMap.get(soliId).CO_Line_Item__r.Status__c;
				newCOLI.Vendor_Order_Header__c = soliMap.get(soliId).CO_Line_Item__r.Vendor_Order_Header__c;
				newCOLI.VO_Number__c = soliMap.get(soliId).CO_Line_Item__r.VO_Number__c;
				newCOLI.VO_Status__c =  soliMap.get(soliId).CO_Line_Item__r.VO_Status__c;
				newCOLI.Expected_Delivery_Date__c = soliMap.get(soliId).CO_Line_Item__r.Expected_Delivery_Date__c;
                newCOLI.Oversold_Qty__c = soliMap.get(soliId).CO_Line_Item__r.Oversold_Qty__c;
				coliUpdateList.add(newCOLI);

				newSOLI.Qty_Committed__c = newCOLI.Qty_Committed__c;
				soliUpdateList.add(newSOLI);

				for(Vendor_Order_Line_Item__c voliRec : coliIdToVOLIListMap.get(soliMap.get(soliId).CO_Line_Item__c)) {
					voliRec.CO_Line_Item__c = newCOLI.Id;
					voliUpdateList.add(voliRec);
				}
			}
			else{
				//To Update Fee Price in Third party when claim is denied
				if(soliMap.get(soliId).Fee__c != null){
					Service_Order_Line_Item__c newSOLI = oldSOLIIdToNewRecMap.get(soliId);
					CO_Line_Item__c newCOLI = new CO_Line_Item__c(Id = soliMap.get(newSOLI.Id).CO_Line_Item__c);
					newSOLI.Price_When_Tax_Included__c = newCOLI.Price_When_Tax_Included__c = oldSOLIIdToNewRecMap.get(soliId).Price_When_Tax_Included__c;
					newSOLI.Actual_Kit_Price__c = newSOLI.Kit_Price__c = newCOLI.Price__c = (oldSOLIIdToNewRecMap.get(soliId).Kit_Price__c != null) ? oldSOLIIdToNewRecMap.get(soliId).Kit_Price__c : 0;
					
					coliListToUpdate.add(newCOLI);
					soliListToUpdate.add(newSOLI);
				}
			}
		}
		
		DMLUtility.updateSobjectList('CO_Line_Item__c', coliListToUpdate);
		DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);

		COLineItemTriggerHelper.isForceStopTrigger = true;
		DMLUtility.updateSobjectList('CO_Line_Item__c', coliUpdateList);
		COLineItemTriggerHelper.isForceStopTrigger = false;

		ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
		DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliUpdateList);
		ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
		
		VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
		DMLUtility.updateSobjectList('Vendor_Order_Line_Item__c', voliUpdateList);
		VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = false;

		if(isShopSupplyAvailable) {
			ShopSuppliesService.shopSuppliesCalculation(customerPaySOId);
		}

		return customerPaySOId;
    }
    
    public static void updateVarianceClaimLineItems(Set<Id> soliIdSet) {
		if(AccessControl.ifObjectFieldIsAccessible('Claim_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Claim_Line_Item__c> claimLIList = [Select Id, Service_Order_Line_Item__c, Tax__c, Approved_Price__c, Approved_Qty__c, Claimed_Price__c, Claimed_Qty__c from 
			Claim_Line_Item__c where Service_Order_Line_Item__c IN: soliIdSet AND Is_Variance__c = false];
		
		List<Claim_Line_Item__c> claimLIListToUpdate = new List<Claim_Line_Item__c>();
		List<Service_Order_Line_Item__c> soliListToDelete = new List<Service_Order_Line_Item__c>();
		for(Claim_Line_Item__c claimLIRec : claimLIList) {
			if(claimLIRec.Approved_Qty__c == 0) {
				soliListToDelete.add(new Service_Order_Line_Item__c(Id = claimLIRec.Service_Order_Line_Item__c));
				continue;
			}
            claimLIRec.Claimed_Qty__c = claimLIRec.Approved_Qty__c;
            claimLIRec.Claimed_Price__c = claimLIRec.Approved_Price__c;
            claimLIListToUpdate.add(claimLIRec);
        }

		if(soliListToDelete.size() > 0) {
	        if(AccessControl.ifObjectIsDeletable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
	        Boolean isTriggerExecute = ServiceOrderLineItemTriggerHelper.isTriggerExecuted;
    		ServiceOrderLineItemTriggerHelper.isTriggerExecuted = false;
	        delete soliListToDelete;
	        ServiceOrderLineItemTriggerHelper.isTriggerExecuted = isTriggerExecute;
		}
		if(claimLIListToUpdate.size() > 0) {
            DMLUtility.updateSobjectList('Claim_Line_Item__c', claimLIListToUpdate);
		}
	}
	
	public static void updateLabourCostingOnSOLIBasedOnTechHoursCosting(Set<String> soHeaderIdSet) {
		updateLaborCostingOnSOLI(soHeaderIdSet);
	}
	
	@future
	public static void updateLabourCostingOnSOLIBasedOnTechHoursCosting_Future(Set<String> soHeaderIdSet) {
		updateLaborCostingOnSOLI(soHeaderIdSet);
	}

	private static void updateLaborCostingOnSOLI(Set<String> soHeaderIdSet) {
		if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
			List<Service_Order_Line_Item__c> soliListToUpdate = populateLabourCostingOnSOLIBasedOnTechHoursCosting(soHeaderIdSet);
			if(soliListToUpdate != null && soliListToUpdate.size() > 0) {
				ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
                DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);
				ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
			}
		}
	}
	
	public static List<Service_Order_Line_Item__c> populateLabourCostingOnSOLIBasedOnTechHoursCosting(Set<String> soHeaderIdSet) {
		if(!GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
			return null;
		}
		List<Service_Order_Header__c> soHeaderRecList = [select Id, 
                                                            (select Qty_Needed__c, Total_Cost__c, Cost__c, Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c 
                                                            from Service_Order_Line_Items__r
                                                            where Labour_Code__c != NULL),
                                                            (select Total_Cost__c from Hours_Logged__r where Is_Removed__c = false)  
                                                            from Service_Order_Header__c
                                                            where Id IN : soHeaderIdSet AND SO_Status__c IN: ServiceJobUtil.invoiceableStatusSet];
        
        return populateCostOnLaborSOLI(soHeaderRecList);
	}
	
        public static List<Service_Order_Line_Item__c> populateCostOnLaborSOLI(List<Service_Order_Header__c> soHeaderRecList) {
        Map<String, Decimal> soHeaderIdToTotalLaborCostMap = new Map<String, Decimal>();
        Map<String, Decimal> soHeaderIdToTotalBilledHoursMap = new Map<String, Decimal>();
        for(Service_Order_Header__c soHeaderRec : soHeaderRecList) {
			if(!soHeaderIdToTotalBilledHoursMap.containsKey(soHeaderRec.Id)) {
                soHeaderIdToTotalBilledHoursMap.put(soHeaderRec.Id, 0);
            }
			for(Service_Order_Line_Item__c soliRec : soHeaderRec.Service_Order_Line_Items__r) {
                soliRec.Qty_Needed__c = ((soliRec.Qty_Needed__c != null) ? soliRec.Qty_Needed__c : 0);
                soHeaderIdToTotalBilledHoursMap.put(soHeaderRec.Id, (soHeaderIdToTotalBilledHoursMap.get(soHeaderRec.Id) + soliRec.Qty_Needed__c));
            }
            
            if(!soHeaderIdToTotalLaborCostMap.containsKey(soHeaderRec.Id)) {
                soHeaderIdToTotalLaborCostMap.put(soHeaderRec.Id, 0);
            }
            for(Hours_Logged__c hrsLoggedRec : soHeaderRec.Hours_Logged__r) {
                soHeaderIdToTotalLaborCostMap.put(soHeaderRec.Id, (soHeaderIdToTotalLaborCostMap.get(soHeaderRec.Id) + hrsLoggedRec.Total_Cost__c));
            }
		}
		
		List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
		for(Service_Order_Header__c soHeaderRec : soHeaderRecList) {
			
			for(Service_Order_Line_Item__c soliRec : soHeaderRec.Service_Order_Line_Items__r) {
				if(soHeaderIdToTotalBilledHoursMap.get(soHeaderRec.Id) != null && soHeaderIdToTotalBilledHoursMap.get(soHeaderRec.Id) != 0) {
	                soliRec.Total_Cost__c = ((soliRec.Qty_Needed__c / soHeaderIdToTotalBilledHoursMap.get(soHeaderRec.Id)) * soHeaderIdToTotalLaborCostMap.get(soHeaderRec.Id));
                } else {
					soliRec.Total_Cost__c = 0;
				}
				soliRec.Cost__c = (soliRec.Qty_Needed__c != null && soliRec.Qty_Needed__c != 0) ? (soliRec.Total_Cost__c / soliRec.Qty_Needed__c) : 0;
            	soliListToUpdate.add(soliRec);
            }
		}
		return soliListToUpdate;
	}
	
	public static List<DeduplicationWrapper> getActiveSKUServiceJobByUnitId(String unitId) {
        String query;   
        List<String> internalTTTypeList = new List<String>{'Third-Party', 'Internal', 'Deal Service', 'Stock Unit'};
        query = 'SELECT '; 
        
        for(String fieldName : DeduplicationWrapper.getServiceJobFieldsList()){
        	fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Service_Order_Header__c ';
        if(unitId != null) {
            query += 'WHERE Customer_Owned_Unit__c =: unitId AND SO_Status__c != \'' +  ServiceJobUtil.INVOICED + '\' AND Transaction_Type__r.Type__c IN: internalTTTypeList ';
        }
        // Order by clause
        query += ' ORDER BY LastModifiedDate Desc';
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Header__c> activeSOList = Database.query(query);
        List<DeduplicationWrapper> serviceJobs = new List<DeduplicationWrapper>();
        for(Service_Order_Header__c soRec : activeSOList) {
			serviceJobs.add(new DeduplicationWrapper(soRec));
		}
		
    	return serviceJobs;
	}

	public static List<ServiceOrderWrapper.ServiceNotes> getServiceNotesList(List<String> notesList) {
        List<ServiceOrderWrapper.ServiceNotes> serviceNotesList = new List<ServiceOrderWrapper.ServiceNotes>();
        for(String note : notesList) {
            serviceNotesList.add(new ServiceOrderWrapper.ServiceNotes(note));
        }
        return serviceNotesList; 
	} 
	
	public static Boolean isDeclineServiceNote(String noteString) {
		return ((noteString != null) && (noteString.length() > 0) && (noteString.substring(0,1) == SERVICE_DECLINE_SEPARATOR)) ? true : false;
	}

	public static List<String> getDeclineAddedNotesList(List<String> notesList) {
		List<String> notesListWithDeclineWord = new List<String>();
		for(String note : notesList) {
			if(isDeclineServiceNote(note)) {
				note = note.subString(1, note.length()) + ' (Declined)';
			}
			notesListWithDeclineWord.add(note);
		}
		return notesListWithDeclineWord;
	}
	
    public static SObject validateDueInAndPromisedDateTime(Event__c eventRec, Service_Order_Header__c soRec, String dueInDateStr, String dueInTimeStr, 
    									String promisedDateStr, String promisedTimeStr) {
    	
    	if((String.isNotBlank(dueInTimeStr) && String.isBlank(dueInDateStr)) || (String.isNotBlank(promisedTimeStr) && String.isBlank(promisedDateStr))) {
    		throw new BlackpurlException('Date must be selected while selecting time');
    	}
		List<Service_Order_Header__c> serviceJobList = new List<Service_Order_Header__c>();
		if(soRec != null) {
			serviceJobList = [SELECT Due_In_DateTime__c, Promised_By_DateTime__c FROM Service_Order_Header__c WHERE Id =: soRec.Id];
		}
    	Date dueInDate, promisedDate;
    	Time dueInTime, promisedTime;
    	DateTime dueInDateTime, promisedByDateTime;
    	
    	Date eventStartDate = eventRec != null ? Date.newInstance(eventRec.Start_DateTime__c.year(), eventRec.Start_DateTime__c.month(), eventRec.Start_DateTime__c.day()) : null;
    	
    	if(String.isNotBlank(dueInDateStr)) {
    		dueInDateTime = HomeSearchFilterInterface.getDateFromString(dueInDateStr);
    		dueInDate = Date.newInstance(dueInDateTime.year(), dueInDateTime.month(), dueInDateTime.day());
    		
    		if(eventStartDate == null && dueInDate < system.today() && (serviceJobList.isEmpty() || serviceJobList[0].Due_In_DateTime__c != dueInDateTime)) {
    			throw new BlackpurlException('Due In Date can not be prior to today\'s date');
    		}
    		
    		if(String.isNotBlank(dueInTimeStr)) {
    			dueInTime = DateTimeUtility.getTimeFromString2(dueInTimeStr);
    			dueInDateTime = DateTime.newInstance(dueInDate, dueInTime);
    		}
    	} else if(String.isNotBlank(dueInTimeStr)) {
    		throw new BlackpurlException('Due In Date must be selected while selecting Due In Time');
    	}
    	
    	if(String.isNotBlank(promisedDateStr)) {
    		promisedByDateTime = HomeSearchFilterInterface.getDateFromString(promisedDateStr);
    		promisedDate = Date.newInstance(promisedByDateTime.year(), promisedByDateTime.month(), promisedByDateTime.day());
    		
    		if(eventStartDate != null && promisedDate < eventStartDate) {
    			throw new BlackpurlException('Promised Date cannot be prior to appointment start date');
    		} else if(eventStartDate == null && promisedDate < system.today() && (serviceJobList.isEmpty() || serviceJobList[0].Promised_By_DateTime__c != promisedByDateTime)) {
    			throw new BlackpurlException('Promised date can not be prior to today\'s date');
    		}
    		
    		if(String.isNotBlank(promisedTimeStr)) {
    			promisedTime = DateTimeUtility.getTimeFromString2(promisedTimeStr);
    			promisedByDateTime = DateTime.newInstance(promisedDate, promisedTime);
    		}
    	} else if(String.isNotBlank(promisedTimeStr)) {
    		throw new BlackpurlException('Promised Date must be selected while selecting Promised Time');
    	}
    	if(dueInDate != null && promisedDate != null) {
    		if(dueInDate > promisedDate) {
    			throw new BlackpurlException('Promised date must be greater than Date due In');
    		} else if(dueInTime != null && promisedTime != null && dueInDate == promisedDate && dueInTime > promisedTime) {
    			throw new BlackpurlException('Promised Time must be greater than Due Time');
    		}
    	}
    	if(eventRec != null) {
    		eventRec.Due_In_DateTime__c = dueInDateTime;
        	eventRec.Promised_By_DateTime__c = promisedByDateTime;
        	eventRec.Due_In_Time__c = String.isNotBlank(dueInTimeStr) ? dueInTimeStr : null;
        	eventRec.Promised_By_Time__c = String.isNotBlank(promisedTimeStr) ? promisedTimeStr : null;
        	return eventRec;
    	} else {
    		soRec.Due_In_DateTime__c = dueInDateTime;
        	soRec.Promised_By_DateTime__c = promisedByDateTime;
        	soRec.Due_In_Time__c = String.isNotBlank(dueInTimeStr) ? dueInTimeStr : null;
        	soRec.Promised_By_Time__c = String.isNotBlank(promisedTimeStr) ? promisedTimeStr : null;
        	return soRec;
    	}
    }

	public static String calculateNewServiceJobName(List<Service_Order_Header__c> soHeaderNameList, Boolean isNewCo) {
		if(isNewCo != null && isNewCo) {
			return 'Service Job 1';
		} else if(soHeaderNameList != null) {
			Integer totalSO = soHeaderNameList.size();
			Boolean isSoHeaderNameAlreadyExist = false;
			String soHeaderName = 'Service Job ' + (totalSO + 1);
			for(Service_Order_Header__c soHeaderRec : soHeaderNameList) {
				if(soHeaderRec.Name__c == soHeaderName) {
					isSoHeaderNameAlreadyExist = true;
					break;
				}
			}
			if(isSoHeaderNameAlreadyExist) {  
				return 'Service Job ' + (totalSO + 2);
			} else {
				return 'Service Job ' + (totalSO + 1);
			}
		}
		return null;        
	}

	public static ResponseWrapper saveServiceJobTaxInfo(COService.COSectionTaxDetailWrapper sectionTaxDetailObj) {
        ResponseWrapper resObj = new ResponseWrapper('success', 'Taxes calculated successfully');
		if(sectionTaxDetailObj != null) {
			Service_Order_Header__c soHeaderRec = new Service_Order_Header__c(Id = sectionTaxDetailObj.SOHeaderId);
            if(sectionTaxDetailObj.IsOverrideTax != null) {
                soHeaderRec.Is_Override_Tax__c = sectionTaxDetailObj.IsOverrideTax;
                if(soHeaderRec.Is_Override_Tax__c) {
                    soHeaderRec.Applicable_Tax__c = sectionTaxDetailObj.ApplicableTaxId;
                    soHeaderRec.Override_Tax_Applicable_On__c = String.isNotBlank(sectionTaxDetailObj.OverrideTaxApplicableOn) ? sectionTaxDetailObj.OverrideTaxApplicableOn : null;
                } else {
                    soHeaderRec.Applicable_Tax__c = null;
                    soHeaderRec.Override_Tax_Applicable_On__c = null;
                }
            }
            
			Set<String> entitiesToRecalculatePriceSet = new Set<String>();
			List<Service_Order_Header__c> oldSORecList = [Select Id, Is_Tax_Based_On_Customer_Address__c, Is_Override_Tax__c, Applicable_Tax__c, Override_Tax_Applicable_On__c, Provider__c, CO_Header__r.Customer__c, 
            (Select Id FROM Tax_Exemptions__r WHERE Type__c =: TaxUtility.AUTOMATED_CUSTOMER LIMIT 1)
            FROM Service_Order_Header__c Where Id =: soHeaderRec.Id AND Invoice_Number__c = null];
			if(!oldSORecList.isEmpty()) {
				for(Service_Order_Header__c oldSORec : oldSORecList) {
					if(GeneralConfiguration.getConfigurations().Automatic_Tax_Rates__c && sectionTaxDetailObj.IsTaxBasedOnCustomerAddress != null && oldSORec.Is_Tax_Based_On_Customer_Address__c != sectionTaxDetailObj.IsTaxBasedOnCustomerAddress) {
                        soHeaderRec.Is_Tax_Based_On_Customer_Address__c = sectionTaxDetailObj.IsTaxBasedOnCustomerAddress;
                        if(sectionTaxDetailObj.IsTaxBasedOnCustomerAddress) {
                            if(oldSORecList[0].Provider__c != null) {
                                if(oldSORecList[0].Tax_Exemptions__r.isEmpty()) resObj = Customer_Service.populateCustomerTaxesOnCO(oldSORecList[0].Id, oldSORecList[0].Provider__c, true);
                            } else {
                                List<Tax_Exemption__c> customerTaxes = [Select Id FROM Tax_Exemption__c WHERE Type__c =: TaxUtility.AUTOMATED_CUSTOMER AND CO_Header__c =: oldSORecList[0].CO_Header__c LIMIT 1];
                                if(customerTaxes.isEmpty()) resObj = Customer_Service.populateCustomerTaxesOnCO(oldSORecList[0].CO_Header__c, oldSORecList[0].CO_Header__r.Customer__c, true);
                            }
                            if(resObj != null && resObj.responseStatus.equalsIgnoreCase('error')) {
                                return resObj;
                            }
                        }
                        entitiesToRecalculatePriceSet.add(DealUtil.UNIT_TAX_APPLICABLE_ON_PARTS);
						entitiesToRecalculatePriceSet.add(DealUtil.UNIT_TAX_APPLICABLE_ON_LABOR);
						entitiesToRecalculatePriceSet.add(DealUtil.UNIT_TAX_APPLICABLE_ON_SUBLET);
						entitiesToRecalculatePriceSet.add(DealUtil.UNIT_TAX_APPLICABLE_ON_FEES);
                    } else if((soHeaderRec.Is_Override_Tax__c && oldSORec.Applicable_Tax__c != soHeaderRec.Applicable_Tax__c) || 
					    oldSORec.Is_Override_Tax__c != soHeaderRec.Is_Override_Tax__c) {
						if(String.isNotBlank(oldSORec.Override_Tax_Applicable_On__c)) {
							entitiesToRecalculatePriceSet.addAll(oldSORec.Override_Tax_Applicable_On__c.split(DealUtil.delimitor));
						}
						if(String.isNotBlank(soHeaderRec.Override_Tax_Applicable_On__c)) {
							entitiesToRecalculatePriceSet.addAll(soHeaderRec.Override_Tax_Applicable_On__c.split(DealUtil.delimitor));
						}
					} else if(oldSORec.Override_Tax_Applicable_On__c != soHeaderRec.Override_Tax_Applicable_On__c) {
						if(String.isNotBlank(oldSORec.Override_Tax_Applicable_On__c)) {
							entitiesToRecalculatePriceSet.addAll(oldSORec.Override_Tax_Applicable_On__c.split(DealUtil.delimitor));
						}
						if(String.isNotBlank(soHeaderRec.Override_Tax_Applicable_On__c)) {
							for(String entityName : soHeaderRec.Override_Tax_Applicable_On__c.split(DealUtil.delimitor)) {
								if(String.isNotBlank(oldSORec.Override_Tax_Applicable_On__c) && oldSORec.Override_Tax_Applicable_On__c.contains(entityName)) {
									entitiesToRecalculatePriceSet.remove(entityName);
								} else {
									entitiesToRecalculatePriceSet.add(entityName);
								}
							}
						}
					}
				}
				system.debug('entitiesToRecalculatePriceSet:: ' +entitiesToRecalculatePriceSet);
				SOTriggerHelper.isForceStopTrigger = true;
				DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);
				SOTriggerHelper.isForceStopTrigger = false;
				
				if(!entitiesToRecalculatePriceSet.isEmpty()) {
					
					List<Service_Order_Line_Item__c> soliList = getSOLIToRecalculatePrices(soHeaderRec.Id, entitiesToRecalculatePriceSet);
					if(!soliList.isEmpty()) {
						Boolean jobContainsKit = false;
						List<Service_Order_Line_Item__c> laborAndSubletSOLIList = new List<Service_Order_Line_Item__c>();
						List<CO_Line_Item__c> partAndFeeCOLIList = new List<CO_Line_Item__c>();
						List<Individual_Tax__c> laborAndSubletSOLIIndividualTaxList = new List<Individual_Tax__c>();
						for(Service_Order_Line_Item__c soliRec : soliList) {
							if(soliRec.Service_Order_Kit_Header__c != null) {
								jobContainsKit = true;
							} else if(soliRec.Labour_Code__c != null || soliRec.Sublet__c != null) {
								laborAndSubletSOLIList.add(soliRec);
								laborAndSubletSOLIIndividualTaxList.addAll(soliRec.Individual_Taxes__r);
							} else if(!soliRec.CO_Line_Items__r.isEmpty()) {
								partAndFeeCOLIList.add(soliRec.CO_Line_Items__r[0]);
							}
						}

						system.debug('partAndFeeCOLIList:: ' +partAndFeeCOLIList.size());
						if(!partAndFeeCOLIList.isEmpty()) {
							COLineItemTriggerHelper.isTotalCalculated = false;
							COTriggerHelper.calculateSalesTax(partAndFeeCOLIList);
						}
						system.debug('laborAndSubletSOLIList:: ' +laborAndSubletSOLIList.size());
						if(!laborAndSubletSOLIList.isEmpty()) {
							//in case of enhanced tax calculation individual taxes are already deleted in soli trigger
                            if(!TaxCalculation.IsEnhancedTaxCalculationApplicable) DMLUtility.deleteSobjectList('Individual_Tax__c', laborAndSubletSOLIIndividualTaxList);
							
							ServiceOrderLineItemTriggerHelper.isTriggerExecuted = true;
							ServiceOrderLineItemTriggerHelper.isCalculateSalesTax = false;
							TaxEngine.applySalesTaxonSOLIList(laborAndSubletSOLIList);
						}
						system.debug('jobContainsKit:: ' +jobContainsKit);
						if(jobContainsKit) {
							List<Service_Order_Kit_Header__c> sokhList = SO_KLI_Recalculation.getSOKitRecList(null, new Set<Id>{sectionTaxDetailObj.SOHeaderId}, null);
							sokhList = SO_KLI_Recalculation.applySalesTax(sokhList, new Set<Id>{sectionTaxDetailObj.SOHeaderId}, sectionTaxDetailObj.COHeaderId);

							List<Sobject> sobjListWithTaxToUpdate = new List<Sobject>(); 
							if(!sokhList.isEmpty()) {
								sobjListWithTaxToUpdate.addAll((List<Sobject>)sokhList);
								for(Service_Order_Kit_Header__c soKHRec : sokhList) {
									if(soKHRec.Service_Order_Line_Items__r != null) {
										sobjListWithTaxToUpdate.addAll((List<Sobject>)soKHRec.Service_Order_Line_Items__r);
									}
								}
							}
							if(!sobjListWithTaxToUpdate.isEmpty()) {
								if(!AccessControl.ifObjectFieldIsUpdateable('Service_Order_Kit_Header__c')) { throw new BlackPurlException('Service_Order_Kit_Header__c' + DMLUtility.NOT_UPDATABLE); }
								if(!AccessControl.ifObjectFieldIsUpdateable('Service_Order_Line_Item__c')) { throw new BlackPurlException('Service_Order_Line_Item__c' + DMLUtility.NOT_UPDATABLE); }
								update sobjListWithTaxToUpdate;
							}
						}
					}
				}
			}
		}
        return resObj;
	}

	private static List<Service_Order_Line_Item__c> getSOLIToRecalculatePrices(Id soId, Set<String> entitiesToRecalculatePriceSet) {
		List<Service_Order_Line_Item__c> soliList = new List<Service_Order_Line_Item__c>();
		if(String.isNotBlank(soId) && entitiesToRecalculatePriceSet != null && !entitiesToRecalculatePriceSet.isEmpty()) {
			String query = 'SELECT Id, Deal__c, Part__c, Fee__c, Sublet__r.Taxable__c, Sublet__r.Applicable_Tax__c, ' +
			'Labour_Code__r.Taxable__c, Labour_Code__r.Applicable_Tax__c, Service_Order_Header__r.Deal__c, ' +
			'Service_Order_Header__r.CO_Header__r.Customer__c, Service_Order_Header__r.CO_Header__r.CO_Type__c, ' +
			'Service_Order_Header__r.Provider__c, Service_Order_Header__r.Job_Type__c, Service_Order_Header__r.Is_Override_Tax__c, ' +
			'Service_Order_Header__r.Override_Tax_Applicable_On__c, Service_Order_Header__r.Applicable_Tax__c, ' +
			'Service_Order_Header__r.Transaction_Type__r.Type__c, Service_Order_Kit_Header__c, Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c, ' +
			'Kit_Price__c, Qty_Needed__c, Applicable_Tax__c, (Select Id from Individual_Taxes__r), '+

			'(SELECT Id, Qty__c, Price__c, Applicable_Tax__c, Deal__c, Service_Order_Line_Item__r.Labour_Code__r.Taxable__c, ' +
			'Service_Order_Line_Item__r.Sublet__r.Taxable__c, Service_Order_Line_Item__r.Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c, '+
			'Part__r.Taxable__c, Part__r.Applicable_Tax__c, Fee__r.Taxable__c, Fee__r.Applicable_Tax__c, '+
			'Service_Order_Line_Item__r.Part__r.Taxable__c, Service_Order_Line_Item__r.Part__r.Applicable_Tax__c, ' +
			'Service_Order_Line_Item__r.Fee__r.Taxable__c, Service_Order_Line_Item__r.Fee__r.Applicable_Tax__c, ' +
			'Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c, ' +
			'Service_Order_Line_Item__r.Service_Order_Header__r.Is_Override_Tax__c, CO_Header__r.Is_Tax_Based_On_Customer_Address__c, ' +
			'Service_Order_Line_Item__r.Service_Order_Header__r.Override_Tax_Applicable_On__c, ' + 
			'Service_Order_Line_Item__r.Service_Order_Header__r.Applicable_Tax__c, Service_Order_Line_Item__r.Service_Order_Header__r.Deal__c, ' +
			'Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c, Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c, '+ 
			'CO_Header__c, CO_Header__r.CO_Type__c, CO_Header__r.Customer__c from CO_Line_Items__r) ' +

			'from Service_Order_Line_Item__c WHERE Service_Order_Header__c =: soId AND (';
			if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_PARTS)) query += ' Part__c != null OR';
			if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_LABOR)) query += ' Labour_Code__c != null OR';
			if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_SUBLET)) query += ' Sublet__c != null OR';
			if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_FEES)) query += ' Fee__c != null OR';
		
			query = (query.substringBeforeLast(' OR') + ')');
			soliList = Database.query(query);
		}
		return soliList;
	}
    
	public static String moveHoursLog(String destinationSOId, String hoursLogId) {
		List<Service_Order_Header__c> destinationServiceJobList = [SELECT Name__c, CO_Header__c, CO_Header__r.Name FROM Service_Order_Header__c WHERE Id =: destinationSOId AND SO_Status__c NOT IN (:ServiceJobUtil.READY_TO_INVOICE, :ServiceJobUtil.INVOICED)]; 
		if(destinationServiceJobList.isEmpty()) {
			throw new BlackpurlException('Service job status is not valid to move hours log.');
		}
		List<Hours_Logged__c> hoursLogList = [SELECT Name, Service_Order_Header__c, Service_Order_Header__r.Name__c, Service_Order_Header__r.CO_Header__c, Service_Order_Header__r.CO_Header__r.Name FROM Hours_Logged__c WHERE Id =: hoursLogId AND Service_Order_Header__r.SO_Status__c NOT IN (:ServiceJobUtil.READY_TO_INVOICE, :ServiceJobUtil.INVOICED)]; 
		if(hoursLogList.isEmpty()) {
			throw new BlackpurlException('Time log entry cannot be moved since service job is already closed.');
		}
		Hours_Logged__c hoursLogToUpdate = new Hours_Logged__c(Id = hoursLogList[0].Id, Service_Order_Header__c = destinationServiceJobList[0].Id);
		DMLUtility.updateSobjectList('Hours_Logged__c', hoursLogToUpdate);
		updateLabourCostingOnSOLIBasedOnTechHoursCosting(new Set<String>{hoursLogList[0].Service_Order_Header__c});
		calculateTechinicianHours(null, new Set<Id>{hoursLogList[0].Service_Order_Header__c, destinationServiceJobList[0].Id});
		createInternalCommentsForHoursLogUpdate(hoursLogList[0], destinationServiceJobList[0]);
		return 'Success';
	}

	public static void updateSOWorkStatus(String soHeaderId, String soStatusId , String soStatusName) {
        if(String.isNotBlank(soStatusId)) {
            if(String.isNotBlank(soStatusName) && ServiceJobUtil.invoiceableStatusSet.contains(soStatusName) ){
                List<Service_Order_Header__c> soHeaderList = [SELECT Id, Special_Order_Status__c FROM Service_Order_Header__c WHERE Id =: soHeaderId AND (Special_Order_Status__c = 'Need to order' OR Special_Order_Status__c = 'Order submitted')];
                if(!soHeaderList.isEmpty()){
                    throw new BlackpurlException('Service Job status cannot be changed as special order is not received.');
                }
            }
            Service_Order_Header__c soHeaderRec = new Service_Order_Header__c(Id = soHeaderId, SO_Status_Ref__c = soStatusId);
            DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);
        }
	}

	private static void createInternalCommentsForHoursLogUpdate(Hours_Logged__c hoursLog, Service_Order_Header__c serviceJobDestination) {
		List<InternalCommentWrapper> internalCommentWrapperList = new List<InternalCommentWrapper>();
		InternalCommentWrapper internalComment1 = new InternalCommentWrapper();
		internalComment1.CoHeaderId = hoursLog.Service_Order_Header__r.CO_Header__c;
		internalComment1.Comment = 'Time entry '+ hoursLog.Name +' moved from ' + hoursLog.Service_Order_Header__r.Name__c +' to ';
		internalComment1.IsNonEditable = true;
		internalComment1.IsNonDeletable = true;
		if(hoursLog.Service_Order_Header__r.CO_Header__c != serviceJobDestination.CO_Header__c) {
			InternalCommentWrapper internalComment2 = new InternalCommentWrapper();
			internalComment2.CoHeaderId = serviceJobDestination.CO_Header__c;
			internalComment2.Comment = 'Time entry '+ hoursLog.Name +' moved from ' + '<a href="#/CustomerOrder_V2?Id=' + hoursLog.Service_Order_Header__r.CO_Header__c + '" target="_blank">' + hoursLog.Service_Order_Header__r.CO_Header__r.Name + '</a> ' +hoursLog.Service_Order_Header__r.Name__c +' to ' + serviceJobDestination.Name__c;
			internalComment2.IsNonEditable = true;
			internalComment2.IsNonDeletable = true;
			internalCommentWrapperList.add(internalComment2);
			internalComment1.Comment +=  '<a href="#/CustomerOrder_V2?Id=' + serviceJobDestination.CO_Header__c + '" target="_blank">' + serviceJobDestination.CO_Header__r.Name + '</a> ';
		}
		internalComment1.Comment +=  serviceJobDestination.Name__c;
		internalCommentWrapperList.add(internalComment1);
		InternalCommentService.saveInternalCommentOnCOInBulk(System.JSON.serialize(internalCommentWrapperList));
	}

    /* Methods moved from CustomerOrderCtrl */
    public static void addServiceJobLineItems(String jsonStr, String soHeaderId, String coHeaderId, String customerId) {
        CustomerOrderWrapper.LineItemWrapper jsonObj = (CustomerOrderWrapper.LineItemWrapper) System.JSON.deserialize(jsonStr, CustomerOrderWrapper.LineItemWrapper.class);            
        String objectName = (Id.valueOf(jsonObj.EntityId)).getSObjectType().getDescribe().getName();
        if(objectName == Constants.NAMESPACE + 'Kit_Header__c') {
            COLineItemTriggerHelper.isTotalCalculated = true;
            ServiceOrderLineItemTriggerHelper.isTotalCalculated = true;
            Id soKHId = insertKitHeaderInGrid(jsonObj.EntityId, soHeaderId, jsonObj.UUID);
            COLineItemTriggerHelper.isTotalCalculated = false;
            ServiceOrderLineItemTriggerHelper.isTotalCalculated = false;
            SO_KLI_Recalculation.soKitPriceCalculation(new Set<Id>{soKHId}, new Set<Id>{soHeaderId}, coHeaderId);
            if(hasLabor) {
                ShopSuppliesService.shopSuppliesCalculation(soHeaderId);
            }
        } else if(objectName == Constants.NAMESPACE + 'Part__c') {
            insertPartInGrid(jsonObj.EntityId, soHeaderId, 1, jsonObj.UUID);
        } else if(objectName == Constants.NAMESPACE + 'Labour_Code__c') {
            Labour_Code__c laborRecToCalculateShopSupplies = insertLabourInGrid(jsonObj.EntityId, soHeaderId, null, jsonObj.UUID);
            if(laborRecToCalculateShopSupplies != null) {
                ShopSuppliesService.calculateShopSupplies(laborRecToCalculateShopSupplies, soHeaderId);
            }
        } else if(objectName == Constants.NAMESPACE + 'Fee__c') {
            insertFeeInGrid(jsonObj.EntityId, soHeaderId, false, new Part__c(), 1, jsonObj.UUID);  
        } else if(objectName == Constants.NAMESPACE + 'Product__c') {
            insertProductInGrid(jsonObj.EntityId, soHeaderId, 1, jsonObj.UUID);
            COFormService.insertDefaultCOForms(coHeaderId, soHeaderId, jsonObj.EntityId);
        }
        
        soHeaderId = BPUtility.escapeSingleQuotes(soHeaderId);
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Header__c> soHeaderList = [select Status__c, Deal__c, (select Id,Kit_Price__c,Actual_Kit_Price__c,Qty_Needed__c from Service_Order_Line_Items__r) from Service_Order_Header__c where Id =: soHeaderId];
        if(soHeaderList.size() > 0 && soHeaderList[0].Service_Order_Line_Items__r != null && soHeaderList[0].Service_Order_Line_Items__r.size() > 0) {
            if(Constants.SOStatusToPriorityMap.get(soHeaderList[0].Status__c) < 3) {
                soHeaderList[0].Status__c = 'In Progress';
            }
            if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update soHeaderList[0];
        }    
    }

    /**
    * Name: removeSOLineItem
    * Desc: Method to remove service order line item
    * @param:  (1)lineItemId - String - id of line item
    * @return: void
    **/
    public static void removeSOLineItem(String lineItemId) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        lineItemId = BPUtility.escapeSingleQuotes(lineItemId);

        List<Service_Order_Line_Item__c> soliList = [SELECT Service_Order_Header__r.SO_Status__c, Deal__c, Labour_Code__c, Sublet__c, 
                                                            Is_Calculate_Supplies__c, Part__c, Service_Order_Header__r.CO_Header__c,
                                                            (Select Id from Vendor_Order_Line_Items__r 
																where Sublet__c != null AND Vendor_Order_Line_Item_Group__c != null 
																AND Vendor_Order_Header__r.Status__c != 'Open' AND 
																Vendor_Order_Header__r.Status__c != 'Locked') 
                                                            FROM Service_Order_Line_Item__c WHERE Id =: lineItemId];
        
        if(soliList.size() > 0 && soliList[0].Service_Order_Header__r.SO_Status__c != ServiceJobUtil.INVOICED) {
        	if(soliList[0].Sublet__c != null && soliList[0].Vendor_Order_Line_Items__r.size() > 0) {
        		throw new BlackpurlException('{"HasError" : true, "ErrorMsg" : "Can not remove sublet that is already ordered."}');
        	}
            String dealId = soliList[0].Deal__c;
            if(String.isNotBlank(dealId)) {
                DealService.createDealUnresolvedFulfillment(new List<String>{soliList[0].Id}, dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_REMOVED);
            }
            
            String serviceJobId;
            Boolean isRecalculateShopSupply = false;
            if(soliList[0].Labour_Code__c != null && soliList[0].Is_Calculate_Supplies__c) {
                isRecalculateShopSupply = true;
                serviceJobId = soliList[0].Service_Order_Header__c;
            }
            
            if(AccessControl.ifObjectIsDeletable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete soliList;
            
            if(isRecalculateShopSupply) {
                ShopSuppliesService.shopSuppliesCalculation(serviceJobId);
            }
            if(soliList[0].Part__c != null) {
                COSectionDetailService.setSectionStatus(new Set<Id>{soliList[0].Service_Order_Header__r.CO_Header__c}, COSectionDetailService.SERVICE);
            }
        }
    }

    /**
    * Name: removeSOKHItems
    * Desc: Method to add Line Items in Items Grid.
    * @param:  (1)lineItemId - String - id of line item
    * @return: String - Wrapper JSON String of all Lookup fields of Customer
    **/
    public static void removeSOKHItems(String lineItemId) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        
        lineItemId = BPUtility.escapeSingleQuotes(lineItemId);

        List<Service_Order_Kit_Header__c> sokhList = [select Service_Order_Header__r.SO_Status__c, Deal__c, Service_Order_Header__r.CO_Header__c,
                                    (Select Id from Service_Order_Line_Items__r) from Service_Order_Kit_Header__c where Id =: lineItemId];
        
        List<SObject> sObjectListToDelete = new List<SObject>();
        if(sokhList.size() > 0 && sokhList[0].Service_Order_Header__r.SO_Status__c != ServiceJobUtil.INVOICED) {
        for(Service_Order_Kit_Header__c sokhRec : sokhList) {
            if(sokhRec.Service_Order_Line_Items__r != null && sokhRec.Service_Order_Line_Items__r.size() > 0) {
                sObjectListToDelete.addAll((List<SObject>) sokhRec.Service_Order_Line_Items__r);
            }
        }
        sObjectListToDelete.addAll((List<SObject>) sokhList);
        }
        if(sObjectListToDelete.size() > 0) {
            if(sokhList.size() > 0) {
                if(String.isNotBlank(sokhList[0].Deal__c)) {
                    DealService.createDealUnresolvedFulfillment(new List<String>{sokhList[0].Id}, sokhList[0].Deal__c, Constants.UNRESOLVED_FULFILLMENT_TYPE_REMOVED);
                }
            }
            if(AccessControl.ifObjectIsDeletable('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete sObjectListToDelete;
            COSectionDetailService.setSectionStatus(new Set<Id>{sokhList[0].Service_Order_Header__r.CO_Header__c}, COSectionDetailService.SERVICE);
        }
    }

    public static void saveUnitArrivalInfo(String soHeaderjSONString) {
        
        ServiceOrderWrapper.SOInfo soHeaderObj = (ServiceOrderWrapper.SOInfo) System.JSON.deserialize(soHeaderjSONString, ServiceOrderWrapper.SOInfo.class);
        Service_Order_Header__c soHeaderRec = new Service_Order_Header__c(Id = soHeaderObj.Id);
        soHeaderRec.Unit_Arrived__c = (soHeaderObj.IsUnitArrived == null ? false : soHeaderObj.IsUnitArrived);  
        
		if(soHeaderRec.Unit_Arrived__c && String.isNotBlank(soHeaderObj.UnitLocation)) {
            if(soHeaderObj.UnitLocation.length() > 25) {
                throw new BlackpurlException('Unit Location cannot be greater than 25 characters.');
            }
            soHeaderRec.Unit_Location__c = soHeaderObj.UnitLocation;
        } else {
            soHeaderRec.Unit_Location__c = null;
		}
        soHeaderRec = (Service_Order_Header__c)(ServiceJobService.validateDueInAndPromisedDateTime(null, soHeaderRec, soHeaderObj.DueInDate, 
        		soHeaderObj.DueInTime, soHeaderObj.PromisedByDate, soHeaderObj.PromiseByTime));
        if(soHeaderRec.Id != null) {
            updatedRelatedSOHeaderAndEventRecord(soHeaderObj.Id, soHeaderRec.Unit_Arrived__c, soHeaderRec.Due_In_DateTime__c, soHeaderRec.Promised_By_DateTime__c, 
            			soHeaderObj.DueInTime, soHeaderObj.PromiseByTime, soHeaderObj.UnitLocation);
        }
    }

    public static String saveHoursLoggedRec(String hoursLoggedJSONString, String coHeaderId) {      
        SOHeaderWrapper.HoursLogged hoursLoggedObj = (SOHeaderWrapper.HoursLogged) System.JSON.deserialize(hoursLoggedJSONString, SOHeaderWrapper.HoursLogged.class);
        List<Hours_Logged__c> hrsLoggedList = [Select Service_Order_Header__r.SO_Status__c, Available_For_QB_Sync__c, Available_For_Xero_Sync__c from Hours_Logged__c where Id =: hoursLoggedObj.Id];
        if(hrsLoggedList.size() > 0 && hrsLoggedList[0].Service_Order_Header__r.SO_Status__c == ServiceJobUtil.INVOICED) {
        	throw new BlackPurlException('Service job is already invoiced. You cannot modify this entry.');
        } else if(hrsLoggedList.size() > 0 && (hrsLoggedList[0].Available_For_QB_Sync__c || hrsLoggedList[0].Available_For_Xero_Sync__c)) {
            throw new BlackPurlException(Constants.HOURS_LOGGED_NOT_EDITABLE);
        }    
        Hours_Logged__c hours = new Hours_Logged__c();
        hours.Id = hoursLoggedObj.Id;
        hours.Technician__c = hoursLoggedObj.EmployeeId;
        hours.Notes__c = hoursLoggedObj.Notes;
        hours.Is_Hours_Only__c = (Configurations__c.getOrgDefaults().Technician_Hours_Method_On_Jobs__c == 'Hours only') ? true : false;
        /*hours.Remaining_Estimate_d__c = hoursLoggedObj.RemainingEstimate_D;
        hours.Remaining_Estimate_h__c = hoursLoggedObj.RemainingEstimate_H;
        hours.Remaining_Estimate_m__c = hoursLoggedObj.RemainingEstimate_M;
        hours.Original_Estimate__c = hoursLoggedObj.OriginalEstimate;
        hours.Previously_Logged__c = hoursLoggedObj.PreviouslyLogged;*/
        
        hours.Service_Order_Header__c = hoursLoggedObj.SOHeaderId;
        Integer hoursValue = 0;
        Integer minutesValue = 0;
        if(hoursLoggedObj.TimeSpent_H != null) {
            hoursValue = hoursLoggedObj.TimeSpent_H.intValue();
            minutesValue = ((hoursLoggedObj.TimeSpent_H - hoursLoggedObj.TimeSpent_H.intValue())*60).intValue();
        }
        hours.Time_Spent_d__c = hoursLoggedObj.TimeSpent_D;
        hours.Time_Spent_h__c = (Decimal)hoursValue;
        hours.Time_Spent_m__c = (Decimal)minutesValue;
        
        if(hoursLoggedObj.StartDate != null) {
            DateTime dtValue = HomeSearchFilterInterface.getDateFromString(hoursLoggedObj.StartDate);
            hours.Work_Performed_Date__c = DateTimeUtility.parseDate(hoursLoggedObj.StartDate);
            hours.Start_Date_Time__c = BPUtility.createDateTimeFromStr(dtValue, hoursLoggedObj.TimeIn);
            hours.End_Date_Time__c = BPUtility.createDateTimeFromStr(dtValue, hoursLoggedObj.TimeOut);
        } else {
            hours.Work_Performed_Date__c = null;
            hours.Start_Date_Time__c = hours.End_Date_Time__c = null;
        }
        hours.Notes_Required__c = hoursLoggedObj.NotesRequired;    
             
        List<Hours_Logged__c> existingHoursLoggedList;
        if(!hours.Is_Hours_Only__c) {
            DateTime currentDayStartTime = Datetime.newInstance(hours.End_Date_Time__c.date(), Time.newInstance(0, 0, 0, 0));
            existingHoursLoggedList = [Select Id, End_Date_Time__c from Hours_Logged__c where Technician__c =: hours.Technician__c 
                   AND Id !=: hours.Id AND Is_Removed__c = false AND 
                   Start_Date_Time__c <: hours.End_Date_Time__c AND (End_Date_Time__c >: hours.Start_Date_Time__c OR (End_Date_Time__c = null AND Start_Date_Time__c >=: currentDayStartTime))];
                   
            
        }
        if(existingHoursLoggedList != null && existingHoursLoggedList.size() > 0) {
            if(existingHoursLoggedList[0].End_Date_Time__c == null) {
                return '[{"HasError" : true, "ErrorMsg" : "This clocking entry conflicts with another active clocking entry."}]';
            } else {
                return '[{"HasError" : true, "ErrorMsg" : "' + Label.Payroll_Already_exists_error + '"}]';
            }
        } else {
            Long dt1Long = hours.Start_Date_Time__c.getTime();
            Long dt2Long = hours.End_Date_Time__c.getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            Long minutes = (seconds / 60);
            Long hoursVal = minutes / 60;
            Long days = hoursVal / 24;
            hours.Time_Spent_d__c = days;
            hours.Time_Spent_h__c = math.mod(hoursVal, 24);
            hours.Time_Spent_m__c = math.mod(minutes, 60);
            
            DMLUtility.upsertSobjectList('Hours_Logged__c', hours);
            calculateTechinicianHours(new Set<Id>{hours.Id}, null);
            setJobStatusWhenTechClocksOn(hoursLoggedObj.SOHeaderId);
        }
        return hoursLoggedObj.SOHeaderId;  
    }

    public static void setJobStatusWhenTechClocksOn(Id soHeaderId) {
        if(String.isNotBlank(soHeaderId)) {
            List<Service_Order_Header__c> soHeaderList = [select SO_Status_Ref__c from Service_Order_Header__c where Id = :soHeaderId];
            if(!soHeaderList.isEmpty()) {
                List<SO_Status__c> soStatusConfigList = [Select Id FROM SO_Status__c WHERE Default_Clock_ON_Status__c = true AND Is_Active__c = true LIMIT 1];
                if(!soStatusConfigList.isEmpty() && soHeaderList[0].SO_Status_Ref__c != soStatusConfigList[0].Id) {
                    soHeaderList[0].SO_Status_Ref__c = soStatusConfigList[0].Id;
                    DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderList[0]);
                }
            }
        }
    }

    public static String submitClaimRecords(String soHeaderId) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        if(AccessControl.ifObjectFieldIsAccessible('Claim__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsCreateable('SO_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('SO_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        
        soHeaderId = BPUtility.escapeSingleQuotes(soHeaderId);
        List<Service_Order_Line_Item__c> soLineItemList = SOQlUtil.getServiceOrderLineItemBySoHeader(soHeaderId);
        List<Claim__c> claimRecords = [select Id from Claim__c where Service_Order_Header__c =: soHeaderId];
        if(claimRecords.size() > 0 || soLineItemList.size() == 0) {
            return BPUtility.getEncodedString('{}');
        }  
        
        Claim__c claimRec = new Claim__c();
        claimRec.Service_Order_Header__c = soHeaderId;
        claimRec.Claim_Disposition__c = 'Accepted';
        DMLUtility.insertSobjectList('Claim__c', claimRec);
        
        List<RecordType> ThirdPartRecordTypeList =  SOQLUtil.getRecordTypeId(Constants.NAMESPACE + 'SO_Payment_Role__c', 'Third_Party');
        SO_Payment_Role__c sopaymetntRoleRec = new SO_Payment_Role__c(Service_Order_Header__c = soHeaderId, Claim__c = claimRec.Id,
                                                                        RecordTypeId = ThirdPartRecordTypeList[0].Id);
        DMLUtility.insertSobjectList('SO_Payment_Role__c', sopaymetntRoleRec);                                                              
        
        List<Claim_Line_Item__c> claimLineItemList = new List<Claim_Line_Item__c>();
        Decimal TotalAmount = 0;
        Decimal TotalTaxamount = 0;
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        for(Service_Order_Line_Item__c soLineItemRec : soLineItemList) {
            Claim_Line_Item__c  claimLineItemRec= new Claim_Line_Item__c();
            Decimal Amount = 0;
            claimLineItemRec.Approved_Price__c = isTaxIncludingPricing ? soLineItemRec.Price_When_Tax_Included__c : soLineItemRec.Kit_Price__c;
            claimLineItemRec.Approved_Qty__c = soLineItemRec.Qty_Needed__c;
            claimLineItemRec.Claimed_Price__c = isTaxIncludingPricing ? soLineItemRec.Price_When_Tax_Included__c : soLineItemRec.Kit_Price__c; 
            claimLineItemRec.Claimed_Qty__c = soLineItemRec.Qty_Needed__c;
            
            /* START: Added By Tarun - #170 - 09/23/2016 */
            claimLineItemRec.Item_Code__c = soLineItemRec.Item_Code__c ;
            claimLineItemRec.Item_Description__c = soLineItemRec.Item_Description__c ;
            
            claimLineItemRec.Item_Desc__c = soLineItemRec.Item_Desc__c ;
            claimLineItemRec.Service_Order_Line_Item__c = soLineItemRec.Id;
            claimLineItemRec.SO_Payment_Role__c = sopaymetntRoleRec.Id;
            
            //claimLineItemRec.Tax__c = soLineItemRec.Tax__c;
            Decimal soLineItemRecTaxRate = 0;
            for(Individual_Tax__c individualTaxItem: soLineItemRec.Individual_Taxes__r) {
                soLineItemRecTaxRate += individualTaxItem.Tax_Rate__c != null ? individualTaxItem.Tax_Rate__c : 0;
            }
            claimLineItemRec.Tax__c = soLineItemRecTaxRate;
            
            claimLineItemRec.Claim__c = claimRec.Id;
            Amount = (soLineItemRec.Kit_Price__c !=null) ? soLineItemRec.Kit_Price__c : 0;
            TotalAmount += (Amount *claimLineItemRec.Approved_Qty__c);
            TotalTaxamount += Amount * ((soLineItemRec.Tax__c != null) ? soLineItemRec.Tax__c : 0) / 100;
            claimLineItemList.add(claimLineItemRec);
        }
                
        if(claimLineItemList.size() > 0){
            DMLUtility.insertSobjectList('Claim_Line_Item__c', claimLineItemList);
        }
        
        if(claimLineItemList.size() > 0 && sopaymetntRoleRec.Id !=null){
            sopaymetntRoleRec.Total_Amount__c = TotalAmount;
            sopaymetntRoleRec.Tax_Amount__c = TotalTaxamount;
            update sopaymetntRoleRec;
        }
        
        Service_Order_Header__c soHeader = new Service_Order_Header__c(
        	Id = soHeaderId, 
        	Claim_Status__c = 'Submitted', 
            Claim__c = claimRec.Id, 
        	Claim_Submitted_At__c = system.now());
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeader);
        
        return BPUtility.getEncodedString('{}');
    }

    public static String getWizardInfo(String soHeaderId, String wizardName) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        wizardName = BPUtility.getDecodedString(wizardName);
        if(wizardName == 'Claim_Response'|| wizardName == 'View_Claim_Response' ){
                return getClaimRecById(BPUtility.getEncodedString(soHeaderId));
        
        }else{
            List<Service_Order_Header__c> soHeaderList = SOQLUtil.getSOHeaderById(soHeaderId, wizardName);
            if(soHeaderList.size() == 0) {
                return BPUtility.getEncodedString('{}');


            }
            Service_Order_Header__c soHeaderRec = soHeaderList[0];
            return BPUtility.getEncodedString(System.JSON.serialize(new SOWizard(soHeaderRec, wizardName)));
        }   
    }

    public static String getClaimRecById(String soHeaderId){
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        List<Claim__c> claimRecList = SOQLUtil.getClaimDetailsBySOHeaderId(soHeaderId); 
        if(claimRecList.size() == 0) {
            return BPUtility.getEncodedString('{}');


        }
        List<SO_Payment_Role__c> soPaymentRoles = SOQLUtil.getSOPaymentWrapperById(soHeaderId, null);
        List<Category__c> internalCategoryList = SOQLUtil.getCategoryById('Internal Expense');
        List<SO_Payment_Role__c> deductibleList = new List<SO_Payment_Role__c>();
        
        for(SO_Payment_Role__c soPaymentRec : soPaymentRoles) {
            if(soPaymentRec.RecordType.DeveloperName == 'Deductible') {
                deductibleList.add(soPaymentRec);
            }
        }
        ClaimWizard claimObj = new ClaimWizard(claimRecList[0], deductibleList,internalCategoryList);
        return BPUtility.getEncodedString(System.JSON.serialize(claimObj));
    }

    /**
    * Name: createSOHeader
    * Desc: Method to add VO Header Rec to Special Order CO Line Item Rec.
    * @param:   (1) coHeaderId - String - id of coHeader
    * @return: String - Wrapper JSON String of all Lookup fields of Customer
    **/
    public static String createSOHeader(String coHeaderId){
        ServiceJobService.createServiceJobWithSpecificFields(BPUtility.getDecodedString(coHeaderId), null, null, true, false);
        return getSOHeaderDetails(coHeaderId, BPUtility.getEncodedString('soHeader,pinItems,checkOut'));
    }

    public static void calculateTechinicianHours(Set<Id> hoursLoggedIdList, Set<Id> soHeaderIds){
        if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Technician_Hour__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                
        Set<Id> soHeaderIdSet = new Set<Id>();
        if(hoursLoggedIdList != null){
            List<Hours_Logged__c> hoursLoggedList = [select Id, Service_Order_Header__c 
                                                            from Hours_Logged__c
                                                            where Id IN : hoursLoggedIdList AND Is_Removed__c = false];
                                                            
            for(Hours_Logged__c hourlog : hoursLoggedList){
                if(hourlog.Service_Order_Header__c != null){
                    soHeaderIdSet.add(hourlog.Service_Order_Header__c);
                }
            }
        }else if(soHeaderIds != null){
            soHeaderIdSet = soHeaderIds;
        }else{
            return;
        }
        
        List<Service_Order_Header__c> serviceOrderList = [select Id, 
                                                            (select Id, Total_Hours__c, Time_Spent_d__c, Time_Spent_h__c, Time_Spent_m__c, Technician__c, Service_Order_Header__c, Job_Hours__c 
                                                            from Hours_Logged__r WHERE Is_Removed__c = false),
                                                            (select Qty_Needed__c 
                                                            from Service_Order_Line_Items__r
                                                            where Labour_Code__c != NULL),
                                                            (select Id, Technician__c, Service_Order_Header__c, Total_Hours__c 
                                                            from Technician_Hours__r)
                                                            from Service_Order_Header__c
                                                            where Id IN : soHeaderIdSet For Update];
                                            
        Map<String,Decimal> soHeaderIdtoBilledHoursMap = new Map<String, Decimal>();    
        Map<String,Map<String, Decimal>> soHeaderIdtoEmployeeIdtoHoursLogMap = new Map<String, Map<String, Decimal>>();
        Map<String,Map<String, String>> soHeaderIdtoEmployeeIdtoTechnicianHourIdMap = new Map<String, Map<String, String>>();
        Map<String,Decimal> soHeaderIdHoursLoggedMap = new Map<String, Decimal>();  
        Set<Id> employeeIdSet = new Set<Id>();  
        for(Service_Order_Header__c soHeader : serviceOrderList){
            for(Service_Order_Line_Item__c soli : soHeader.Service_Order_Line_Items__r){
                if(!soHeaderIdtoBilledHoursMap.containsKey(soHeader.Id)){
                    soHeaderIdtoBilledHoursMap.put(soHeader.Id, 0);
                }
                if(soli.Qty_Needed__c != null){
                    soHeaderIdtoBilledHoursMap.put(soHeader.Id, (soHeaderIdtoBilledHoursMap.get(soHeader.Id)+soli.Qty_Needed__c));
                }
            }
            if(!soHeaderIdtoEmployeeIdtoHoursLogMap.containsKey(soHeader.Id)){
                soHeaderIdtoEmployeeIdtoHoursLogMap.put(soHeader.Id, new Map<String, Decimal>());
            }
            if(!soHeaderIdHoursLoggedMap.containsKey(soHeader.Id)){
                soHeaderIdHoursLoggedMap.put(soHeader.Id, 0);
            }
            for(Hours_Logged__c HL : soHeader.Hours_Logged__r){
                if(HL.Technician__c != null && !soHeaderIdtoEmployeeIdtoHoursLogMap.get(HL.Service_Order_Header__c).containsKey(HL.Technician__c)){
                    soHeaderIdtoEmployeeIdtoHoursLogMap.get(HL.Service_Order_Header__c).put(HL.Technician__c, 0);
                    employeeIdSet.add(HL.Technician__c);
                }
                if(HL.Technician__c != null && HL.Job_Hours__c != null) {
                    soHeaderIdtoEmployeeIdtoHoursLogMap.get(HL.Service_Order_Header__c).put(HL.Technician__c, soHeaderIdtoEmployeeIdtoHoursLogMap.get(HL.Service_Order_Header__c).get(HL.Technician__c)+HL.Job_Hours__c);
                }
                
                if(HL.Job_Hours__c != null){
                    soHeaderIdHoursLoggedMap.put(HL.Service_Order_Header__c, soHeaderIdHoursLoggedMap.get(HL.Service_Order_Header__c)+HL.Job_Hours__c);
                }
            }
            for(Technician_Hour__c TH : soHeader.Technician_Hours__r){
                if(!soHeaderIdtoEmployeeIdtoTechnicianHourIdMap.containsKey(TH.Service_Order_Header__c)){
                    soHeaderIdtoEmployeeIdtoTechnicianHourIdMap.put(TH.Service_Order_Header__c, new Map<String, String>());
                }
                if(!soHeaderIdtoEmployeeIdtoTechnicianHourIdMap.get(TH.Service_Order_Header__c).containsKey(TH.Technician__c)){
                    soHeaderIdtoEmployeeIdtoTechnicianHourIdMap.get(TH.Service_Order_Header__c).put(TH.Technician__c, null);
                }
                soHeaderIdtoEmployeeIdtoTechnicianHourIdMap.get(TH.Service_Order_Header__c).put(TH.Technician__c, TH.Id);
            }       
        }                               
        if(AccessControl.ifObjectFieldIsAccessible('user') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        Map<Id, Technician__c> employeeIdtoNameMap = new Map<Id, Technician__c>([select Id, Labour_Cost_Per_Hour__c, Technician_Name__c
                                                                    from Technician__c
                                                                    where Id IN :employeeIdSet]);
                                                                    
        List<Service_Order_Header__c> soHeaderListToUpdate = new List<Service_Order_Header__c>();                                                           
        Service_Order_Header__c soHeaderRec;
        List<Technician_Hour__c> technicianHoursList = new List<Technician_Hour__c>();
        Technician_Hour__c technicianHoursObj;
        for(String soHeaderId : soHeaderIdtoEmployeeIdtoHoursLogMap.keySet()){ 
            Decimal TotalHoursLogged = 0;
            soHeaderRec = new Service_Order_Header__c();
            soHeaderRec.Id = soHeaderId;
            String techniciansNames = '';
            for(String employeeId : soHeaderIdtoEmployeeIdtoHoursLogMap.get(soHeaderId).keySet()){
                TotalHoursLogged += soHeaderIdtoEmployeeIdtoHoursLogMap.get(soHeaderId).get(employeeId);
            }
            if(soHeaderIdHoursLoggedMap.containsKey(soHeaderId)){
                soHeaderRec.Hrs_Logged__c = soHeaderIdHoursLoggedMap.get(soHeaderId);
            }

            for(String employeeId : soHeaderIdtoEmployeeIdtoHoursLogMap.get(soHeaderId).keySet()){
                if(String.isBlank(employeeId)) {
                    continue;
                }
                techniciansNames += employeeIdtoNameMap.get(employeeId).Technician_Name__c+';';
                technicianHoursObj = new Technician_Hour__c();
                if(soHeaderIdtoEmployeeIdtoTechnicianHourIdMap.containsKey(soHeaderId) 
                    && soHeaderIdtoEmployeeIdtoTechnicianHourIdMap.get(soHeaderId).containsKey(employeeId)){
                    technicianHoursObj.Id = soHeaderIdtoEmployeeIdtoTechnicianHourIdMap.get(soHeaderId).get(employeeId);
                }else{
                    technicianHoursObj.Service_Order_Header__c = soHeaderId;
                }
                technicianHoursObj.Technician__c = employeeId;
                technicianHoursObj.Costing_Rate__c = (employeeIdtoNameMap.containsKey(employeeId) && employeeIdtoNameMap.get(employeeId).Labour_Cost_Per_Hour__c != null ? 
                		employeeIdtoNameMap.get(employeeId).Labour_Cost_Per_Hour__c : 0.00);
                //System.assert(false, soHeaderIdtoBilledHoursMap);
                if(TotalHoursLogged == 0 || !soHeaderIdtoBilledHoursMap.containsKey(soHeaderId)){
                    technicianHoursObj.Total_Hours__c = 0;
                }else{
                    technicianHoursObj.Total_Hours__c = (soHeaderIdtoEmployeeIdtoHoursLogMap.get(soHeaderId).get(employeeId)/TotalHoursLogged)*soHeaderIdtoBilledHoursMap.get(soHeaderId);
                }
                technicianHoursList.add(technicianHoursObj);
            }
            if(techniciansNames.length() >= 1){
                techniciansNames = techniciansNames.substring(0, techniciansNames.length() > 255 ? 255 :techniciansNames.length()-1);
                soHeaderRec.Technician_Name__c = techniciansNames; 
            }
            soHeaderListToUpdate.add(soHeaderRec);
        }
        //System.assert(false, technicianHoursList);        
        DMLUtility.upsertSobjectList('Service_Order_Header__c', soHeaderListToUpdate);
        DMLUtility.upsertSobjectList('Technician_Hour__c', technicianHoursList);
         
    }

    public static String getProviderInfo(String vendorId) {
        return ViewVendorCtrl.getVendorInfo(vendorId);    
    }

    public static String getServiceWorksheetPrintDetail(String coHeaderId) { 
        coHeaderId = BPUtility.getDecodedString(coHeaderId); 
        
        if(String.isNotBlank(coHeaderId)) {
            List<CO_Header__c> coHeaderList = SOQLUtil.getSOHeaderListByCOHeaderId(new Set<Id>{coHeaderId});
            if(coHeaderList.size() > 0) {
                Map<Id, Customer_Owned_Unit__c> unitIdToUnitMap = new Map<Id, Customer_Owned_Unit__c>();
                Map<Id, List<Service_Order_Header__c>> unitIdToSOHeaderMap = new Map<Id, List<Service_Order_Header__c>>();
                
                for(Service_Order_Header__c soHeaderRec : coHeaderList[0].Service_Order_Headers__r) {
                    if(soHeaderRec.Customer_Owned_Unit__c != null) {
                        String formattedName = ((soHeaderRec.Customer_Owned_Unit__r.Unit_Make__c != null) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Make__r.Name + ' ' : '') + 
                                       ((soHeaderRec.Customer_Owned_Unit__r.Unit_Model__c != null) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c + ' ' : '') + 
                                       ((soHeaderRec.Customer_Owned_Unit__r.Sub_Model__c != null && soHeaderRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c != null) 
                                                       ? soHeaderRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c + ' ' : '') +
                                       ((soHeaderRec.Customer_Owned_Unit__r.Year__c != null) ? STring.valueOf(soHeaderRec.Customer_Owned_Unit__r.Year__c) : '');
                        Customer_Owned_Unit__c unitRec = new Customer_Owned_Unit__c(Id = soHeaderRec.Customer_Owned_Unit__c, 
                                                                                    VIN_Number__c = soHeaderRec.Customer_Owned_Unit__r.VIN_Number__c,
                                                                                    Search_Tag__c = formattedName);                                                                                    
                        unitIdToUnitMap.put(unitRec.Id, unitRec);
                        if(unitIdToSOHeaderMap.containsKey(soHeaderRec.Customer_Owned_Unit__c)) {
                            unitIdToSOHeaderMap.get(soHeaderRec.Customer_Owned_Unit__c).add(soHeaderRec);
                        } else {
                            unitIdToSOHeaderMap.put(soHeaderRec.Customer_Owned_Unit__c, new List<Service_Order_Header__c>{soHeaderRec});
                        }
                    }
                } 
                List<SOWorkSheetWrapper.ServiceWorkSheetPrintDetail> soWorksheetWrapperList = new List<SOWorkSheetWrapper.ServiceWorkSheetPrintDetail>();
                for(Id unitId : unitIdToUnitMap.keySet()) {
                    SOWorkSheetWrapper.ServiceWorkSheetPrintDetail soWorksheetPrintDetailObj = new SOWorkSheetWrapper.ServiceWorkSheetPrintDetail(unitIdToUnitMap.get(unitId), unitIdToSOHeaderMap.get(unitId));
                    soWorksheetWrapperList.add(soWorksheetPrintDetailObj); 
                }
                return BPUtility.getEncodedString(JSON.serialize(soWorksheetWrapperList));
            }
        }
        return '{}';   
    }

    public static void saveWorkseetSelectionJson(String coHeaderId, String jsonString) { 
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        jsonString = BPUtility.getDecodedString(jsonString);
        
        if(coHeaderId != null) {
            if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            CO_Header__c coHeaderRec = new CO_Header__c(Id = coHeaderId, SO_Worksheet_User_selection__c = jsonString);
            update coHeaderRec;
        }
    }

    public static String saveClaimResponse(String soHeaderId, String ClaimWizardJson, String StepNumber) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        ClaimWizardJson = BPUtility.getDecodedString(ClaimWizardJson);
        if(StepNumber == '1'){
            ClaimWizard claimWizardObj = (ClaimWizard)System.JSON.deserialize(ClaimWizardJson, ClaimWizard.class);
             
            Claim__c claimRec =  new  Claim__c();
            if(claimWizardObj.ClaimId != null ){
                claimRec.Id = claimWizardObj.ClaimId;
            }
            claimRec.Provider_Claim_Number__c = claimWizardObj.ProviderClaimNumber;
            claimRec.Notes__c =claimWizardObj.Notes;
            if(claimWizardObj.ResponseDate != null) {
                claimRec.Response_Date__c = (String.isNotBlank(claimWizardObj.ResponseDate)) ? DateTimeUtility.parseDate(claimWizardObj.ResponseDate) : null;
                //claimRec.Response_Date__c = DateTime.valueOf(claimWizardObj.ResponseDate).format('MM/dd/yyyy');
            }
            claimRec.Claim_Disposition__c =claimWizardObj.ClaimDisposition;
            claimRec.Service_Order_Header__c = soHeaderId;
            DMLUtility.updateSobjectList('Claim__c', claimRec);
        }
        if(StepNumber == '2'){
            CreateNewVariance( soHeaderId, ClaimWizardJson);
        } else if(StepNumber == '3'){
             updateVariance(soHeaderId, ClaimWizardJson, false);
             //changeStatus(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString('Approved'), BPUtility.getEncodedString('claim'));
        }
        return getWizardInfo(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString('Claim_Response'));
    }
    
    // Update Bill to information for Variable
     public Static String updateVariance(String soHeaderId, String ClaimWizardJson, Boolean isFinalize) {
        if(AccessControl.ifObjectFieldIsAccessible('Claim_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('SO_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('RecordType') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Claim_Line_item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsCreateable('So_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('So_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectIsDeletable('SO_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        
        soHeaderId = BPUtility.escapeSingleQuotes(soHeaderId);
        ServiceOrderLineItemTriggerHelper.isTotalCalculated = true; // To avoid order total calculation here, it should be done at end

        ClaimWizard claimWizardObj = (ClaimWizard)System.JSON.deserialize(ClaimWizardJson, ClaimWizard.class);
        List<ClaimWizard.ClaimLineItem>  claimLineItemClassList = claimWizardObj.VarianceLineItemList;
        
        //If Finalize
        Map<Id, ClaimWizard.ClaimLineItem> soliIdToNonVarianceClaimLIRecordMap = new Map<Id, ClaimWizard.ClaimLineItem>();
        List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
    	if(isFinalize) {
    		if(claimWizardObj.NonVarianceLineItemList != null && claimWizardObj.NonVarianceLineItemList.size() > 0) {
    			for(ClaimWizard.ClaimLineItem nonVarianceClaimLI : claimWizardObj.NonVarianceLineItemList) {
    				soliIdToNonVarianceClaimLIRecordMap.put(nonVarianceClaimLI.ServiceOrderLineItem, nonVarianceClaimLI);
    			}
    		}
    	}
    	
        map<Id,SO_Payment_Role__c> CategoryToSoPaymentRoleMap = new   map<Id,SO_Payment_Role__c>();
        String newCustomerPaySOId;
        if( claimWizardObj.ClaimId == null) {
            return 'ID Doesnt Exits';
        } else {
            map<Id,Claim_Line_Item__c> claimLineOldmap = new map<Id,Claim_Line_Item__c> ([select Id,SO_Payment_Role__r.Status__c, Approved_Price__c,Is_Variance__c,
            Service_Order_Line_Item__r.Actual_Kit_Price__c, Service_Order_Line_Item__r.Kit_Price__c, Service_Order_Line_Item__r.Price_When_Tax_Included__c,
            			Approved_Qty__c, Variance_Qty__c, Variance_Amount__c, Service_Order_Line_Item__r.Service_Order_Header__r.CO_Header__c, Service_Order_Line_Item__c, 
            			Service_Order_Line_Item__r.Service_Order_Header__r.Customer_Owned_Unit__c, SO_Payment_Role__c, SO_Payment_Role__r.RecordType.DeveloperName,
            			Service_Order_Line_Item__r.Part__c, Service_Order_Line_Item__r.Fee__c, Service_Order_Line_Item__r.Labour_Code__c, Service_Order_Line_Item__r.Sublet__c,
                        Service_Order_Line_Item__r.Item_Description__c, Service_Order_Line_Item__r.Item_Code__c, Service_Order_Line_Item__r.Qty_Committed__c, Service_Order_Line_Item__r.Is_Hidden__c,
                        Service_Order_Line_Item__r.Cost__c, Service_Order_Line_Item__r.Status__c, Service_Order_Line_Item__r.Vendor_Order_Header__c, Service_Order_Line_Item__r.Type__c,
                        Service_Order_Line_Item__r.VO_Number__c, Service_Order_Line_Item__r.VO_Status__c, Service_Order_Line_Item__r.Is_Calculate_Supplies__c,
                        Service_Order_Line_Item__r.Expected_Delivery_Date__c From Claim_Line_Item__c where Claim__c =: claimWizardObj.ClaimId and Is_Variance__c = true]);
            List<SO_Payment_Role__c> SoPaymentList = [select Id,Status__c,RecordType.DeveloperName,Category__c from SO_Payment_Role__c where Service_Order_Header__c =: soHeaderId and
                                                     RecordType.DeveloperName ='Internal' and Status__c !='Invoiced' order by LastModifiedDate];
            List<RecordType> RecordTypeList =([select Id,DeveloperName from RecordType where RecordType.DeveloperName ='Internal' or  RecordType.DeveloperName ='customer']);
            String CustomerRecordType;
            String InternalRecordType;
            
            for(RecordType recordItem :  RecordTypeList) {
                if(recordItem.DeveloperName =='Internal') {
                    InternalRecordType = recordItem.Id;
                } else if(recordItem.DeveloperName =='Customer') {
                    CustomerRecordType = recordItem.Id;
                }
            }
            
            for(SO_Payment_Role__c SoPaymentRecord : SoPaymentList) {
	            if(SoPaymentRecord.Category__c != null) {
	                CategoryToSoPaymentRoleMap.put(SoPaymentRecord.Category__c, SoPaymentRecord);
	            }
            }
            String coHeaderId;
            String couId;
            List<Claim_Line_Item__c> InternalSoPaymentClaimLineItemList = new List<Claim_Line_Item__c>();
            map<Id,SO_Payment_Role__c> ClaimLineItemIdToSopayment = new map<Id,SO_Payment_Role__c>();
            map<Id,Claim_Line_Item__c> IdToClaimLineItemMap = new map<Id,Claim_Line_Item__c>();
            List<Claim_Line_Item__C> CategoryIdToClaimLineList = new List<Claim_Line_Item__C> ();
            List<Service_Order_Header__c> soHeaderListToInsert = new List<Service_Order_Header__c>();
            
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            for(ClaimWizard.ClaimLineItem ClaimLineItemVarianceRec :  claimLineItemClassList) {
                if(claimLineOldmap.ContainsKey(ClaimLineItemVarianceRec.Id)) {
                	if(coHeaderId == null) {
                		coHeaderId = claimLineOldmap.get(ClaimLineItemVarianceRec.Id).Service_Order_Line_Item__r.Service_Order_Header__r.CO_Header__c;
                		couId = claimLineOldmap.get(ClaimLineItemVarianceRec.Id).Service_Order_Line_Item__r.Service_Order_Header__r.Customer_Owned_Unit__c;
                	}
                    Claim_Line_Item__c claimRec =  claimLineOldmap.get(ClaimLineItemVarianceRec.Id);
                    if(claimRec.SO_Payment_Role__r.RecordType.DeveloperName !=  ClaimLineItemVarianceRec.BillTo){
                    	Claim_Line_Item__c ClaimRecordsTosave =  new Claim_Line_Item__c();
                        ClaimRecordsTosave.Id= ClaimLineItemVarianceRec.Id;
                        ClaimRecordsTosave.Variance_Amount__c= ClaimLineItemVarianceRec.VarianceAmount; 
                        ClaimRecordsTosave.Variance_Qty__c= ClaimLineItemVarianceRec.VarianceQuantity;
                        ClaimRecordsTosave.Claim__c = ClaimLineItemVarianceRec.Claim;
                        ClaimRecordsTosave.Category__c = ClaimLineItemVarianceRec.Category;  
                        ClaimRecordsTosave.Total_Variance_Amount__c = ClaimLineItemVarianceRec.TotalVariance;  
                        ClaimRecordsTosave.Tax__c =  ClaimLineItemVarianceRec.Tax;
                        ClaimRecordsTosave.Bill_To__c = ClaimLineItemVarianceRec.BillTo;
                        if(ClaimLineItemVarianceRec.BillTo =='Customer') {
                            IdToClaimLineItemMap.put(ClaimRecordsTosave.Id, ClaimRecordsTosave);
                        } else if(ClaimLineItemVarianceRec.BillTo =='Internal') {
                            if(CategoryToSoPaymentRoleMap.containsKey(ClaimRecordsTosave.Category__c)) {
                                CategoryIdToClaimLineList.add(ClaimRecordsTosave);
                            } else{
                                SO_Payment_Role__c soPaymentRec = new SO_Payment_Role__c(Service_Order_Header__c = claimWizardObj.soHeaderId,
                                RecordTypeId = InternalRecordType,Status__c='Pending',Category__c = ClaimRecordsTosave.Category__c,
                                Claim__c =ClaimRecordsTosave.Claim__c); 
                                CategoryToSoPaymentRoleMap.put(ClaimRecordsTosave.Category__c,soPaymentRec);
                                CategoryIdToClaimLineList.add(ClaimRecordsTosave);
                            }
                            
                        	if(isFinalize && soliIdToNonVarianceClaimLIRecordMap.containsKey(ClaimLineItemVarianceRec.ServiceOrderLineItem)) {
                        		ClaimWizard.ClaimLineItem nonVarianceClaimLI = soliIdToNonVarianceClaimLIRecordMap.get(ClaimLineItemVarianceRec.ServiceOrderLineItem);
		                        Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c(Id = ClaimLineItemVarianceRec.ServiceOrderLineItem);
		                        if(isTaxIncludingPricing) {
		                        	soliRec.Price_when_Tax_Included__c = nonVarianceClaimLI.ApprovedPrice;
		                        	soliRec.kit_Price__c = (nonVarianceClaimLI.ApprovedPrice / (1 + nonVarianceClaimLI.Tax / 100));
		                        } else {
		                        	soliRec.Kit_Price__c = nonVarianceClaimLI.ApprovedPrice;
		                        }
		                        soliListToUpdate.add(soliRec);
                        	}
                        }
                    }
                }
            }

            List<Claim_Line_Item__c> ClaimLineItemListToUpdate = new List<Claim_Line_Item__c>();
            List<So_Payment_Role__c>  SoPaymentRoleInternal =new  List<So_Payment_Role__c>();
           
			if(CategoryToSoPaymentRoleMap.Size() > 0 ){
			    upsert CategoryToSoPaymentRoleMap.Values();  
			    for(Claim_Line_Item__c claimLineItemRec :  CategoryIdToClaimLineList){
		            So_Payment_Role__C SopaymentRec = CategoryToSoPaymentRoleMap.get(claimLineItemRec.Category__c);
		            claimLineItemRec.SO_Payment_Role__c = SopaymentRec.Id;
		            ClaimLineItemListToUpdate.add(claimLineItemRec);
			     }
			     
			     if(isFinalize) {
                    DMLUtility.updateSobjectList('Claim_Line_Item__c', ClaimLineItemListToUpdate);
				     ServiceOrderLineItemTriggerHelper.isUpdateClaimLI = false;
                     DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);
				     ServiceOrderLineItemTriggerHelper.isUpdateClaimLI = true;
			     }
			}

			if(IdToClaimLineItemMap.Size() > 0) {
				if(isFinalize) {
					newCustomerPaySOId = ServiceJobService.handleBillToCustomerVariance(IdToClaimLineItemMap, claimLineOldmap, coHeaderId, couId);
				} else {
					update IdToClaimLineItemMap.values();
				}
            }
            
            List<SO_Payment_Role__c> SoPaymentAllList =[select Id,Total_Amount__c,Tax_Amount__c ,RecordType.DeveloperName,(select Id,Approved_Qty__c,Approved_Price__c,
            			Tax__c, Variance_Qty__c,Variance_Amount__c, Service_Order_Line_Item__r.Kit_Price__c, Total_Variance_Amount__c from Claim_Line_items__r ) 
            			from SO_Payment_Role__c where Service_Order_Header__c =: soHeaderId  and RecordType.DeveloperName !='Deductible'];

            List<SO_Payment_Role__c> SoPaymentListToDelete = new  List<SO_Payment_Role__c>();
            List<SO_Payment_Role__c> SoPaymentListToUpdate = new  List<SO_Payment_Role__c>();

            for(SO_Payment_Role__c  SolPayemtRec : SoPaymentAllList){
                if(SolPayemtRec.Claim_Line_Items__r.size() == 0) {
                    if(SolPayemtRec.RecordType.DeveloperName != 'Third_Party') {
                		SoPaymentListToDelete.add(SolPayemtRec);
                	}
                } else {
                    SoPaymentListToUpdate.add(SolPayemtRec);
                }
            }
            UpdateSoPaymentTotal(SoPaymentListToUpdate);
            if(SoPaymentListToDelete.size() > 0 ){
                delete SoPaymentListToDelete;
            }
        }
        if(isFinalize) {
            Set<Id> soIdSetToUpdateTotals = new Set<Id>{soHeaderId};
            if(String.isNotBlank(newCustomerPaySOId)) {
                soIdSetToUpdateTotals.add(newCustomerPaySOId);
            }
            ServiceOrderLineItemTriggerHelper.calculateTotals_bulk(soIdSetToUpdateTotals);
		    ServiceOrderLineItemTriggerHelper.isTotalCalculated = false; // To calculate order total calculation here after this

            changeStatus(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString((claimWizardObj != null && claimWizardObj.ClaimDisposition == 'Denied') ? 'Denied' : 'Approved'), BPUtility.getEncodedString('claim'));
        }
        return '{}';
	}
         
     // create new Variance For SOLI's
     public Static String CreateNewVariance(String soHeaderId, String ClaimWizardJson){
        if(AccessControl.ifObjectFieldIsAccessible('Claim_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('SO_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable('Claim_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        

        ClaimWizard claimWizardObj = (ClaimWizard)System.JSON.deserialize(ClaimWizardJson, ClaimWizard.class);
        Claim__c claimRec =  new  Claim__c();
        claimRec.Id = claimWizardObj.ClaimId;
        claimRec.Claim_Number__c =  claimWizardObj.ClaimNumber;
        claimRec.Provider_Claim_Number__c = claimWizardObj.ProviderClaimNumber;
        claimRec.Notes__c =claimWizardObj.Notes;
        //claimRec.Response_Date__c = DateTime.valueOf(claimWizardObj.ResponseDate).format('MM/dd/yyyy');
        claimRec.Claim_Disposition__c =claimWizardObj.ClaimDisposition;
        claimRec.Service_Order_Header__c = soHeaderId;
        DMLUtility.updateSobjectList('Claim__c', claimRec);
        
        List<ClaimWizard.ClaimLineItem>  claimLineItemClassList = claimWizardObj.NonVarianceLineItemList ;
        
        List<Claim_Line_Item__c> claimLineOldList=new List<Claim_Line_Item__c> ([select Id,SO_Payment_Role__r.Status__c, Approved_Price__c, Is_Variance__c,
                                                                                SO_Payment_Role__r.RecordType.DeveloperName,Approved_Qty__c, 
                                                                                Claimed_Qty__c, Claimed_Price__c, Variance_Qty__c,
                                                                                Variance_Amount__c, Service_Order_Line_Item__c
                                                                                From Claim_Line_Item__c where  Claim__c =: claimRec.Id]);
        Map<Id,Claim_Line_Item__c> SoliToClaimLineItemMap =  new Map<Id,Claim_Line_Item__c>();  
        Map<Id,Claim_Line_Item__c> SoliToCaimVarinceLineItemMap =  new Map<Id,Claim_Line_Item__c>();  
        set<Id> SoPaymentRoleToUpdateSet = new set<Id>();
        for(Claim_Line_Item__c claimLineItemRec : claimLineOldList){
            if(claimLineItemRec.Is_Variance__c) {
                SoliToCaimVarinceLineItemMap.put(claimLineItemRec.Service_Order_Line_Item__c,claimLineItemRec );
            } else {
                if(claimLineItemRec.SO_Payment_Role__c !=null) {
                    SoPaymentRoleToUpdateSet.add(claimLineItemRec.SO_Payment_Role__c);
                }
                SoliToClaimLineItemMap.put(claimLineItemRec.Service_Order_Line_Item__c,claimLineItemRec );
            }
        } 
        List<Claim_Line_Item__c> claimLineItemList = new List<Claim_Line_Item__c>();
        List<Claim_Line_Item__c> claimLineItemVarianceList = new List<Claim_Line_Item__c>();
        List<Claim_Line_Item__c> claimLineItemVarianceListToDelete = new List<Claim_Line_Item__c>();
        
        for(ClaimWizard.ClaimLineItem  claimLineItemobj :claimLineItemClassList  ){
            Claim_Line_Item__c claimLineItemRec = new Claim_Line_Item__c();
            Claim_Line_Item__c claimLineItemVarRec = new Claim_Line_Item__c();
            Claim_Line_Item__c claimLineItemVarRecToDelete = new Claim_Line_Item__c();
            
            if(SoliToClaimLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).Approved_Price__c != claimLineItemobj.ApprovedPrice ||  
                SoliToClaimLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).Approved_Qty__c != claimLineItemobj.ApprovedQty || 
                SoliToClaimLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).Claimed_Qty__c != claimLineItemobj.ClaimedQty || 
                SoliToClaimLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).Claimed_Price__c != claimLineItemobj.ClaimedPrice) {
                    
                if(SoliToClaimLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).SO_Payment_Role__r.Status__c =='Invoiced'){
                    return'{}';
                } else if( SoliToCaimVarinceLineItemMap.containsKey(claimLineItemobj.ServiceOrderLineItem) && SoliToCaimVarinceLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).SO_Payment_Role__c  !=null && SoliToCaimVarinceLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).SO_Payment_Role__r.Status__c  =='Invoiced'  ){
                    return'{}';
                } else{   
                    claimLineItemRec.Id = claimLineItemobj.Id; 
                    claimLineItemRec.Claimed_Price__c =  claimLineItemobj.ClaimedPrice;
                    claimLineItemRec.Claimed_Qty__c   =  claimLineItemobj.ClaimedQty;
                    claimLineItemRec.Approved_Price__c =  claimLineItemobj.ApprovedPrice;
                    claimLineItemRec.Approved_Qty__c   =  claimLineItemobj.ApprovedQty;  
                    if(claimLineItemobj.ClaimedQty > claimLineItemobj.ApprovedQty ||  claimLineItemobj.ClaimedPrice >  claimLineItemobj.ApprovedPrice){
                        if( SoliToCaimVarinceLineItemMap.ContainsKey(claimLineItemobj.ServiceOrderLineItem)){
                            claimLineItemVarRec.Id = SoliToCaimVarinceLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).Id;
                        }
                        /* START: Added By Tarun - #170 - 09/24/2016 */
                        claimLineItemVarRec.Item_Code__c =  claimLineItemobj.ItemCode;
                        claimLineItemVarRec.Item_Description__c =  claimLineItemobj.ItemDescription;
                         
                        claimLineItemVarRec.Item_Desc__c =  claimLineItemobj.Itemdesc;
                        claimLineItemVarRec.Claim__c = claimWizardObj.ClaimId;
                        claimLineItemVarRec.Approved_Qty__c   =  claimLineItemobj.ApprovedQty;  
                        claimLineItemVarRec.Approved_Price__c =  claimLineItemobj.ApprovedPrice;
                        claimLineItemVarRec.Variance_Amount__c = claimLineItemobj.ClaimedPrice -claimLineItemobj.ApprovedPrice;
                        claimLineItemVarRec.Variance_Qty__c = claimLineItemobj.ClaimedQty - claimLineItemobj.ApprovedQty;
                        claimLineItemVarRec.Is_Variance__c= true;
                        claimLineItemVarRec.Bill_To__c = (claimLineItemobj.ClaimedQty > claimLineItemobj.ApprovedQty) ? 'Customer' : 'Internal';
                        claimLineItemVarRec.Service_Order_Line_Item__c = claimLineItemobj.ServiceOrderLineItem;
                        claimLineItemVarRec.Total_Variance_Amount__c   =
                        ((claimLineItemobj.ClaimedPrice * claimLineItemobj.ClaimedQty) - (claimLineItemobj.ApprovedPrice *  ((claimLineItemobj.ApprovedQty == 0) ? 1 : claimLineItemobj.ApprovedQty)));
                        claimLineItemVarRec.Tax__c   = claimLineItemobj.Tax;
                        claimLineItemVarianceList.add(claimLineItemVarRec);
                    } else {
		            	if(SoliToCaimVarinceLineItemMap.containsKey(claimLineItemobj.ServiceOrderLineItem)){
		                   claimLineItemVarRecToDelete.Id = SoliToCaimVarinceLineItemMap.get(claimLineItemobj.ServiceOrderLineItem).Id;
		                   claimLineItemVarianceListToDelete.add(claimLineItemVarRecToDelete);
		                }
                    }
                	claimLineItemList.add(claimLineItemRec);
                }
            }
        }
            
        if(claimLineItemList.size() > 0){
            DMLUtility.upsertSobjectList('Claim_Line_Item__c', claimLineItemList);
        }
        
      
        if(claimLineItemVarianceList.size() > 0){
            DMLUtility.upsertSobjectList('Claim_Line_Item__c', claimLineItemVarianceList);
        } 
        
        if(claimLineItemVarianceListToDelete.size() > 0){
            delete claimLineItemVarianceListToDelete;
        }
        
        List<SO_Payment_Role__c>  SoPaymentListToUpdate = ([select Id,Total_Amount__c,Tax_Amount__c ,RecordType.DeveloperName,(select Id,Approved_Qty__c,Approved_Price__c,
        													Tax__c, Variance_Qty__c,Variance_Amount__c, Total_Variance_Amount__c, Service_Order_Line_Item__r.Kit_Price__c
                                                            from Claim_Line_items__r)  From  SO_Payment_Role__c where Id IN:SoPaymentRoleToUpdateSet]);
        UpdateSoPaymentTotal(SoPaymentListToUpdate);
        //
        return'{}';
    }

    public Static List<So_Payment_Role__c> UpdateSoPaymentTotal(List<So_Payment_Role__c> SoPaymentListToUpdate) {
        if(AccessControl.ifObjectFieldIsUpdateable('SO_Payment_Role__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        for(SO_Payment_Role__c SoRolePaymentRec :  SoPaymentListToUpdate){
            decimal Amount = 0.00;
            decimal Tax = 0.00; 
            if(SoRolePaymentRec.RecordType.DeveloperName == 'Third_Party' ){    
                for(Claim_Line_item__c ClaimLineItemRec :  SoRolePaymentRec.Claim_Line_items__r){
                    Amount += ClaimLineItemRec.Approved_Qty__c * ClaimLineItemRec.Service_Order_Line_Item__r.Kit_Price__c;
                    Tax += (ClaimLineItemRec.Approved_Qty__c * ClaimLineItemRec.Service_Order_Line_Item__r.Kit_Price__c) * (ClaimLineItemRec.Tax__c / 100);
                }
            } else if( SoRolePaymentRec.RecordType.DeveloperName == 'Customer' || SoRolePaymentRec.RecordType.DeveloperName == 'Internal') {
                for(Claim_Line_item__c ClaimLineItemRec :  SoRolePaymentRec.Claim_Line_items__r){
                    Amount += ClaimLineItemRec.Total_Variance_Amount__c;
                    Tax += ClaimLineItemRec.Total_Variance_Amount__c *(ClaimLineItemRec.Tax__c/100);
                }
            }
            SoRolePaymentRec.Total_Amount__c = Amount;
            SoRolePaymentRec.Tax_Amount__c = Tax;
        }
        
        if(SoPaymentListToUpdate.Size() > 0){
            update SoPaymentListToUpdate;
        }
        
        return SoPaymentListToUpdate;
    }

    public static void updateSOHeaderList(Set<Id> soHeaderIdSet, String closedInvoiceId) {
        if(soHeaderIdSet.size() > 0) {
            List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
            Id soStatusRefId = ServiceJobUtil.getSOStatusConfigByName(ServiceJobUtil.INVOICED).Id;
            for(Id soId : soHeaderIdSet) {
                soHeaderList.add(new Service_Order_Header__c(Id = soId, SO_Status_Ref__c = soStatusRefId , Invoice_Number__c = closedInvoiceId, 
                	Is_Technician_Hours_Costing_Enabled__c = GeneralConfiguration.isTechnicianHoursCostingEnabled()));
            }
            if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update soHeaderList;
            COService.updateMileageOnUnitsWithSoOdometerOut(soHeaderIdSet);
        }
    }

    private static void updatedRelatedSOHeaderAndEventRecord(String soHeaderId, Boolean isUnitArrived, DateTime dueInDateTime, DateTime promisedByDateTime, 
    			String dueInTimeStr, String promisedTimeStr, String unitLocation) {
        if(!AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }        
        
        if (String.isNotBlank(soHeaderId)) {
            List<Service_Order_Header__c> soHeaderList = [SELECT Id, Customer_Owned_Unit__c, CO_Header__c, (SELECT Id FROM Events__r) FROM Service_Order_Header__c WHERE Id =: soHeaderId];
            if (soHeaderList.size() > 0 ) {
                if (String.isNotBlank(soHeaderList[0].Customer_Owned_Unit__c ) && String.isNotBlank(soHeaderList[0].CO_Header__c )) {
                    soHeaderList = [SELECT Id, (SELECT Id FROM Events__r) FROM Service_Order_Header__c WHERE Customer_Owned_Unit__c = : soHeaderList[0].Customer_Owned_Unit__c  AND CO_Header__c =: soHeaderList[0].CO_Header__c ];
                }
                List<Event__c> eventListToUpdate = new List<Event__c>();
                List<Service_Order_Header__c> soHeaderListToUpdate = new List<Service_Order_Header__c>();
                if (soHeaderList.size() > 0) {
                    for (Service_Order_Header__c sOHeaderRec: soHeaderList) {
                        sOHeaderRec.Unit_Arrived__c = isUnitArrived;
                        sOHeaderRec.Due_In_DateTime__c = dueInDateTime;
                        sOHeaderRec.Promised_By_DateTime__c = promisedByDateTime;
                        sOHeaderRec.Due_In_Time__c = String.isNotBlank(dueInTimeStr) ? dueInTimeStr : null;
    					sOHeaderRec.Promised_By_Time__c = String.isNotBlank(promisedTimeStr) ? promisedTimeStr : null;
                        sOHeaderRec.Unit_Location__c = String.isNotBlank(unitLocation) ? unitLocation : null;
        					
                        soHeaderListToUpdate.add(sOHeaderRec);
                        for (Event__c eventRec : sOHeaderRec.Events__r){
                            eventRec.Unit_Arrived__c = isUnitArrived;
                            eventRec.Due_In_DateTime__c =  dueInDateTime;
                            eventRec.Promised_By_DateTime__c = promisedByDateTime;
                            eventRec.Due_In_Time__c = sOHeaderRec.Due_In_Time__c;
        					eventRec.Promised_By_Time__c = sOHeaderRec.Promised_By_Time__c;
                            eventRec.Unit_Location__c = sOHeaderRec.Unit_Location__c;
        					
                            eventListToUpdate.add(eventRec);
                        }
                    }
                }  
                if(soHeaderListToUpdate.size() > 0) {
                    SOTriggerHelper.isForceStopTrigger = true;
                    DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderListToUpdate);
                    SOTriggerHelper.isForceStopTrigger = false;
                }
                if(eventListToUpdate.size() > 0) {
                    DMLUtility.updateSobjectList('Event__c', eventListToUpdate);
                }
            }
        }  
    }

    private static void changeStatus(String soHeaderId, String newStatus, String statusType) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        newStatus = BPUtility.getDecodedString(newStatus);
        statusType = BPUtility.getDecodedString(statusType);
        if(String.isNotBlank(soHeaderId)) {
            Service_Order_Header__c soHeader = new Service_Order_Header__c(Id = soHeaderId);
            if(statusType.equalsIgnoreCase('work')) {
                if(String.isNotBlank(newStatus)) {
                    soHeader.Work_Status__c = newStatus;
                }
            } else {
                soHeader.Claim_Status__c = newStatus;
            }
            DMLUtility.updateSobjectList('Service_Order_Header__c', soHeader);
        } 
    }

    public static String getSOHeaderDetails(String recordId, String gridName){
        recordId = BPUtility.getDecodedString(recordId);
        gridName = BPUtility.getDecodedString(gridName);
        try{
            List<Service_Order_Header__c> soHeaderRecList = new List<Service_Order_Header__c>();
            List<Service_Order_Kit_Header__c> soKitHeaderList = new List<Service_Order_Kit_Header__c>();
            List<CO_Invoice_Header__c> coInvoiceHeaders = new List<CO_Invoice_Header__c>();
            List<CO_Invoice_Item__c> coInvoiceItems = new List<CO_Invoice_Item__c>();
            List<Vendor_Order_Line_Item__c> specialOrders = new List<Vendor_Order_Line_Item__c>();
            List<CO_Line_Item__c> coLineItems = new List<CO_Line_Item__c>();
            
            Map<Id, List<Service_Order_Line_Item__c>> soHeaderIdToSOLIListMap = new Map<Id, List<Service_Order_Line_Item__c>>();
            Map<Id, List<Service_Order_Kit_Header__c>> soHeaderIdToSOKHListMap = new Map<Id, List<Service_Order_Kit_Header__c>>();
            
            List<String> pinItems = new List<String>();
            String objectName = (Id.valueOf(recordId)).getSObjectType().getDescribe().getName();
            
            Map<Id, Service_Order_Line_Item__c> soliIdToRecMap = new Map<Id, Service_Order_Line_Item__c>();
            if(gridName == null || gridName.contains('soHeader')) {
                if(objectName == Constants.NAMESPACE + 'CO_Header__c') {
                    soHeaderRecList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'CO_Header__c' => recordId});
                    soliIdToRecMap = new Map<Id, Service_Order_Line_Item__c>([Select Id, 
                    	(Select Id, Variance__c from Claim_Line_Items__r where Is_Variance__c = false AND Variance__c != 0) 
                    	from Service_Order_Line_Item__c where Service_Order_Header__r.CO_Header__c =: recordId]);
                } else if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
                    soHeaderRecList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'Id' => recordId});
                    soliIdToRecMap = new Map<Id, Service_Order_Line_Item__c>([Select Id, 
                    	(Select Id, Variance__c from Claim_Line_Items__r where Is_Variance__c = false AND Variance__c != 0) 
                    	from Service_Order_Line_Item__c where Service_Order_Header__c =: recordId]);
                }
            }
            //system.assert(false, soHeaderRecList);
            
            if(gridName == null || gridName.contains('pinItems')) {
                List<User> currentUserInfo = SOQLUtil.getCurrentUserInfo();
                if(currentUserInfo.size() > 0 && currentUserInfo[0].SO_Pinned_Info__c != null) {
                    pinItems = currentUserInfo[0].SO_Pinned_Info__c.split(',');
                }
            }
            
            Map<Id, List<Service_Order_Kit_Header__c>> soHeaderIdToSOKIListMap = new Map<Id, List<Service_Order_Kit_Header__c>>();
            
            if(gridName == null || gridName.contains('soItemGrid')) {
                if(objectName == Constants.NAMESPACE + 'CO_Header__c') {
                    soKitHeaderList = SOQLUtil.getSOKitHeaderByFieldName(new Map<String, String>{'Service_Order_Header__r.CO_Header__c' => recordId});
                } else if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
                    soKitHeaderList = SOQLUtil.getSOKitHeaderByFieldName(new Map<String, String>{'Service_Order_Header__c' => recordId});
                }
                
                for(Service_Order_Kit_Header__c soKitHeaderRec : soKitHeaderList) {
                    List<Service_Order_Kit_Header__c> sokhList;
                    if(!soHeaderIdToSOKIListMap.containsKey(soKitHeaderRec.Service_Order_Header__c)) {
                        sokhList = new List<Service_Order_Kit_Header__c>();
                    } else {
                        sokhList = soHeaderIdToSOKIListMap.get(soKitHeaderRec.Service_Order_Header__c);
                    }
                    sokhList.add(soKitHeaderRec);
                    soHeaderIdToSOKIListMap.put(soKitHeaderRec.Service_Order_Header__c, sokhList);
                }
            }
            
            if(gridName == null || gridName.contains('checkOut')) {
                coInvoiceHeaders = SOQLUtil.getCOInvoiceHeaderByCOHeaderId(recordId);
                if(coInvoiceHeaders.size() > 0) {
                    coInvoiceItems = SOQLUtil.getCOInvoiceItemsByCOInvoiceHeaderId(coInvoiceHeaders[0].Id);
                }
            }
            
            if(gridName == null || gridName.contains('specialOrder')) {
                specialOrders = SOQLUtil.getSpecialOrderByCOHeaderId(recordId);
            }
            
            SOHeaderWrapper soHeaderObj = new SOHeaderWrapper(soHeaderRecList, pinItems, soHeaderIdToSOKIListMap, coInvoiceHeaders, coInvoiceItems, specialOrders);
            
            for(SOHeaderWrapper.SOWrapper soObj : soHeaderObj.SOList) {
             	for(SOHeaderWrapper.SOGrid soGridObj : soObj.SOGridItems) {
             		for(SOHeaderWrapper.SOLineItem soliObj : soGridObj.SOKH.SOLIList) {
             			if(soliIdToRecMap.containsKey(soliObj.Id) && soliIdToRecMap.get(soliObj.Id).Claim_Line_Items__r.size() > 0) {
			    			//soliObj.IsVariance = true;
			    		}
             		}
             	}
            }
            //system.assert(false, soHeaderObj);
            system.debug('###############\n\n' + soHeaderObj.SOList);
            return BPUtility.getEncodedString(System.JSON.serialize(soHeaderObj));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    /**
    * Name: insertKitHeaderInGrid
    * Desc: Method to insert kit header in Grid
    * @param:   (1)lineItemId - String - id of line item
    *           (2)soHeaderId - String - id of Service Order Header
    * @return: String - Wrapper JSON String of all Lookup fields of Customer
    **/
    public static Id insertKitHeaderInGrid(String lineItemId, String soHeaderId, String UUID) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        String dealId;
        String dealItemId;
        String soCommitControls;
        String coHeaderId;
        List<Service_Order_Header__c> serviceOrderHeaderList = [Select Deal__c, Deal_Item__c, Commit_Order_Controls__c, CO_Header__c from Service_Order_Header__c where Id = :soHeaderId];
        if(serviceOrderHeaderList.size() > 0) {
            dealId = serviceOrderHeaderList[0].Deal__c;
            dealItemId = serviceOrderHeaderList[0].Deal_Item__c;
            soCommitControls = serviceOrderHeaderList[0].Commit_Order_Controls__c;
            coHeaderId =  serviceOrderHeaderList[0].CO_Header__c;
        }
        List<Kit_Header__c> kitHeaderList = SOQLUtil.getKitHeaderRec(new Map<String, String>{ 'Id' => lineItemId });
        if(kitHeaderList.size() == 0) {
            return null;
        }
        Service_Order_Kit_Header__c sokhRec = new Service_Order_Kit_Header__c();
        sokhRec.Service_Order_Header__c = soHeaderId;
        sokhRec.Kit_Header__c = kitHeaderList[0].Id;
        sokhRec.Can_Split__c = kitHeaderList[0].Can_Split__c;
        sokhRec.Code__c = kitHeaderList[0].Code__c;
        sokhRec.Description__c = kitHeaderList[0].Description__c;
        sokhRec.Fixed_Price__c = kitHeaderList[0].Fixed_Price__c;
        sokhRec.Fixed_Price_Flag__c = kitHeaderList[0].Fixed_Price_Flag__c;
        sokhRec.Is_Fixed_Kit_Header_SO__c = false; // kitHeaderList[0].Fixed_Price_Flag__c Changed by richa 23/11/2016
        sokhRec.Service_Kit__c = kitHeaderList[0].Service_Kit__c;
        sokhRec.Actual_Kit_Price__c = kitHeaderList[0].Fixed_Price__c;
        sokhRec.Deal_Item__c = dealItemId;
        sokhRec.Deal__c = dealId;
        sokhRec.UUID__c = UUID;
        DMLUtility.insertSobjectList('Service_Order_Kit_Header__c', sokhRec);
        insertAllKitLineItems(lineItemId, soHeaderId, sokhRec.Id, dealItemId, dealId, soCommitControls, coHeaderId);
        
        
        if(String.isNotBlank(dealId)) {
            DealService.createDealUnresolvedFulfillment(new List<String>{sokhRec.Id}, dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
        }
        // system.assert(false,soliListToInsert);
        return sokhRec.Id;
    }

    public static Boolean hasLabor = false;
    /**
    * Name: insertAllKitLineItems
    * Desc: Method to add Kit Line Items in Items Grid.
    * @param:   (1)lineItemId - String - id of line item
    *           (2)soHeaderId - String - id of Service Order Header
    *           (3)sokhRecId - String - id of service order kit header
                (4)dealItemId - String - id of deal Item
    * @return: void
    **/
    private static void insertAllKitLineItems(String lineItemId, String soHeaderId, String sokhRecId, String dealItemId, String dealId, String soCommitControls, String coHeaderId) {
        List<Kit_Header_Line_Item__c> khLineItemList = SOQLUtil.getKHLineItemRec(new Map<String, String>{ 'Kit_Header__c' => lineItemId });
        if(khLineItemList.size() == 0) {
            return;
        }
        //system.assert(false,khLineItemList);  
        Boolean isNonInventoryPartAvailable = false;
        List<Service_Order_Line_Item__c> soliListToInsert = new List<Service_Order_Line_Item__c>();
        for(Kit_Header_Line_Item__c khliRec : khLineItemList) {
            Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c(Kit_Header_Line_Item__c = khliRec.Id);
            
            soliRec.Service_Order_Header__c = soHeaderId;
            soliRec.Service_Order_Kit_Header__c = sokhRecId;
            soliRec.Fixed_Price__c = khliRec.Fixed_Price__c;
            soliRec.Is_Fixed_Kit_LineItem_SO__c = false; // khliRec.Fixed_Price__c Changed by richa 23/11/2016
            soliRec.Part__c = khliRec.Part__c;
            soliRec.Labour_Code__c = khliRec.Labour_Code__c;
            soliRec.Commit_Order_Controls__c = soCommitControls;
            if(khliRec.Part__c!= null && khliRec.Part__r.Non_Inventory_Part__c) {
                isNonInventoryPartAvailable = true;
            }
            if(soliRec.Labour_Code__c != null) {
                soliRec.Is_Calculate_Supplies__c = khliRec.Labour_Code__r.Calculate_Supplies__c;
                hasLabor = true;
            }
            soliRec.Deal_Item__c = dealItemId;
            if(khliRec.Labour_Code__c != null) {
                //soliRec.Fixed_Price__c = khliRec.Labour_Code__r.Fixed_Rate__c;
            }            
            if(khliRec.Fee__c != null) { // Richa Added 16/11/2016
                soliRec.Fee__c = khliRec.Fee__c;
            }
            soliRec.Kit_Price__c = (khliRec.Kit_Price__c != null) ? khliRec.Kit_Price__c : 0;
            soliRec.Price_When_Tax_Included__c = soliRec.Kit_Price__c;
            soliRec.Actual_Kit_Price__c = (soliRec.Kit_Price__c != null) ? soliRec.Kit_Price__c : 0;
            soliRec.Actual_Retail_Price__c = (khliRec.Part__r.Retail_Price__c != null) ? khliRec.Part__r.Retail_Price__c : 0;
            soliRec.Qty_Needed__c = khliRec.Qty_Needed__c;
            soliRec.Item_Code__c = khliRec.Item_Code__c;
            soliRec.Item_Description__c = khliRec.Item_Description__c;
            soliRec.Deal__c = dealId;
            soliListToInsert.add(soliRec);
        }
        if(soliListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliListToInsert);
            if(isNonInventoryPartAvailable) {
                COSectionDetailService.setSectionStatus_future(new Set<Id>{coHeaderId}, COSectionDetailService.SERVICE);
            }
        }

    }

    /**
    * Name: insertPartInGrid
    * Desc: Method to insert part in Grid.
    * @param:   (1)lineItemId - String - id of line item
    *           (2)soHeaderId - String - id of Service Order Header
    * @return: void
    **/
    public static List<Service_Order_Line_Item__c> insertPartInGrid(String lineItemId, String soHeaderId, Decimal qty, String UUID) {
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Part__c> partList = [select Part_Number__c, Enviro_Fee__c, Enviro_Fee_Code__c, Enviro_Fee_Code__r.Code__c, 
                                            Enviro_Fee_Code__r.Description__c, Non_Inventory_Part__c from Part__c where Id =: lineItemId];
        if(partList.size() == 0) {
            return null;
        }
        
        List<Service_Order_Header__c> serviceOrderHeaderList = [Select Deal__c, Deal_Item__c, Commit_Order_Controls__c, CO_Header__c from Service_Order_Header__c where Id = :soHeaderId];
        Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c();
        soliRec.Service_Order_Header__c = soHeaderId;
        soliRec.Part__c = partList[0].Id;
        soliRec.Qty_Needed__c = qty;
        if(serviceOrderHeaderList.size() > 0) {
            soliRec.Deal__c = serviceOrderHeaderList[0].Deal__c;
            soliRec.Deal_Item__c = serviceOrderHeaderList[0].Deal_Item__c;
            soliRec.Commit_Order_Controls__c = serviceOrderHeaderList[0].Commit_Order_Controls__c;
        }
        //soliRec.Kit_Price__c = (partList[0].Retail_Price__c != null) ? partList[0].Retail_Price__c : 0;
        soliRec.Actual_Kit_Price__c = (soliRec.Kit_Price__c == null) ? 0 : soliRec.Kit_Price__c;
        soliRec.UUID__c = UUID;
        //insert soliRec;
        
        List<Service_Order_Line_Item__c> soliListToInsert = new List<Service_Order_Line_Item__c>();
        soliListToInsert.add(soliRec);
        Service_Order_Line_Item__c relatedEnvFeeRec = new Service_Order_Line_Item__c();
        if(partList[0].Enviro_Fee__c != null && partList[0].Enviro_Fee_Code__c != null) {
            relatedEnvFeeRec = insertFeeInGrid(partList[0].Enviro_Fee_Code__c, soHeaderId, true, partList[0], 1, UUID);
            soliListToInsert.add(relatedEnvFeeRec);
        }
        
        DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliListToInsert);
        DealService.createDealUnresolvedFulfillment(new List<String>{soliRec.Id}, soliRec.Deal__c, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
        
        // Create Deal Unresoled Fulfillment for Env Fee Line item.
        if(partList[0].Enviro_Fee__c != null && soliListToInsert.size() > 1) {
            DealService.createDealUnresolvedFulfillment(new List<String>{relatedEnvFeeRec.Id}, relatedEnvFeeRec.Deal__c, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
        }
        if(partList[0].Non_Inventory_Part__c && !serviceOrderHeaderList.isEmpty()) {
            COSectionDetailService.setSectionStatus_future(new Set<Id>{serviceOrderHeaderList[0].CO_Header__c}, COSectionDetailService.SERVICE);
        }
        return soliListToInsert;
    }
    
    
    /**
    * Name: insertLabourInGrid
    * Desc: Method to insert labour in Grid
    * @param:   (1)lineItemId - String - id of line item
    *           (2)soHeaderId - String - id of Service Order Header
    * @return: void
    **/
    public static Labour_Code__c insertLabourInGrid(String lineItemId, String soHeaderId, Decimal qty, String UUID) {
        return insertLabourInGrid(lineItemId, soHeaderId, qty, UUID, null);
    }

    public static Labour_Code__c insertLabourInGrid(String lineItemId, String soHeaderId, Decimal qty, String UUID, String laborDesc) { 
        List<Labour_Code__c> labourList = SOQLUtil.getLabourRecords(new Set<Id>{lineItemId}, null);
        if(labourList.isEmpty()) return null;
        insertLabourInGrid(lineItemId, soHeaderId, qty, UUID, laborDesc, labourList);
        return labourList[0];
    }

    public static Service_Order_Line_Item__c insertLabourInGrid(String lineItemId, String soHeaderId, Decimal qty, String UUID, String laborDesc, List<Labour_Code__c> labourList) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        

        if(labourList == null) {
            labourList = SOQLUtil.getLabourRecords(new Set<Id>{lineItemId}, null);
        }
        
        List<Service_Order_Header__c> serviceOrderHeaderList = [Select Deal__c, Deal_Item__c from Service_Order_Header__c where Id = :soHeaderId];
        
        Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c();
        soliRec.Service_Order_Header__c = soHeaderId;
        soliRec.Labour_Code__c = labourList[0].Id;
        soliRec.Qty_Needed__c = (qty != null) ? qty : labourList[0].Hours__c; // Ticket#1841: 1-> labourList[0].Hours__c: Changed By Pooja 10 Apr. 2017;
        soliRec.Qty_Committed__c = 1;
        soliRec.Kit_Price__c = (labourList[0].Rate__c != null) ? labourList[0].Rate__c : 0;
        soliRec.Actual_Kit_Price__c = (soliRec.Kit_Price__c != null) ? soliRec.Kit_Price__c : 0;
        soliRec.UUID__c = UUID;
        soliRec.Is_Calculate_Supplies__c = labourList[0].Calculate_Supplies__c;
        if(serviceOrderHeaderList.size() > 0) {
            soliRec.Deal__c = serviceOrderHeaderList[0].Deal__c;
            soliRec.Deal_Item__c = serviceOrderHeaderList[0].Deal_Item__c;
        }
        if(String.isNotBlank(laborDesc)) {
            soliRec.Item_Description__c = laborDesc;
        }
        DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliRec);
        DealService.createDealUnresolvedFulfillment(new List<String>{soliRec.Id}, soliRec.Deal__c, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
        
        //Prices on soli have changes in trigger which are not reflected in soliRec. 
        return (new Service_Order_Line_Item__c(Id = soliRec.Id, Is_Calculate_Supplies__c = soliRec.Is_Calculate_Supplies__c));
    }
    
    /**
    * Name: insertFeeInGrid
    * Desc: Method to insert fee in Grid
    * @param:   (1)lineItemId - String - id of line item
    *           (2)soHeaderId - String - id of Service Order Header
    * @return: void
    **/
    public static Service_Order_Line_Item__c insertFeeInGrid(String lineItemId, String soHeaderId, Boolean isEnvFee, Part__c partRecHavingEnvFee, Decimal qty, String UUID) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Fee__c> feeList = SOQLUtil.getFeeByFieldName(new Map<String, String>{'Id' => lineItemId});
        if(feeList.size() == 0) {
            return new Service_Order_Line_Item__c();
        }
        
        List<Service_Order_Header__c> serviceOrderHeaderList = [Select Deal__c, Deal_Item__c from Service_Order_Header__c where Id = :soHeaderId];
        
        Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c();
        soliRec.Service_Order_Header__c = soHeaderId;
        soliRec.Fee__c = feeList[0].Id;
        soliRec.Qty_Needed__c = qty;
        soliRec.Qty_Committed__c = 1;
        soliRec.Kit_Price__c = (feeList[0].Price__c != null) ? feeList[0].Price__c : 0;
        soliRec.Actual_Kit_Price__c = (soliRec.Kit_Price__c != null) ? soliRec.Kit_Price__c : 0;
        soliRec.UUID__c = UUID;
        if(isEnvFee && partRecHavingEnvFee.Id != null) {
            soliRec.Is_Environmental_Fee__c = isEnvFee;
            soliRec.Kit_Price__c = (partRecHavingEnvFee.Enviro_Fee__c != null) ? partRecHavingEnvFee.Enviro_Fee__c : 0;
            soliRec.Actual_Kit_Price__c = soliRec.Kit_Price__c;
            soliRec.Price_When_Tax_Included__c = soliRec.Kit_Price__c;
            soliRec.Item_Code__c = partRecHavingEnvFee.Enviro_Fee_Code__r.Code__c;
            soliRec.Item_Description__c = partRecHavingEnvFee.Part_Number__c + ' ' + partRecHavingEnvFee.Enviro_Fee_Code__r.Description__c;
        } 
        
        if(serviceOrderHeaderList.size() > 0) {
            soliRec.Deal__c = serviceOrderHeaderList[0].Deal__c;
            soliRec.Deal_Item__c = serviceOrderHeaderList[0].Deal_Item__c;
        }
        if(!isEnvFee) {
            DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliRec);
            DealService.createDealUnresolvedFulfillment(new List<String>{soliRec.Id}, soliRec.Deal__c, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
        }
        return soliRec;
    }
    
    /**
    * Name: insertProductInGrid
    * Desc: Method to insert product in Grid
    * @param:   (1)lineItemId - String - id of line item
    *           (2)soHeaderId - String - id of Service Order Header
    * @return: void
    **/
    public static Service_Order_Line_Item__c insertProductInGrid(String lineItemId, String soHeaderId, Decimal qty, String UUID) {
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        

        List<Product__c> productList = SOQLUtil.getProductRecordsById(new List<Id>{lineItemId});
        if(productList.size() == 0) {
            return null;
        }
        
        List<Service_Order_Header__c> serviceOrderHeaderList = [Select Deal__c, Deal_Item__c, Commit_Order_Controls__c from Service_Order_Header__c where Id = :soHeaderId];
        
        Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c();
        soliRec.Service_Order_Header__c = soHeaderId;
        soliRec.Sublet__c = productList[0].Id;
        soliRec.Status__c = soliRec.Id != null ? soliRec.Status__c : 'Required';
        soliRec.Qty_Committed__c = 0;
        soliRec.Qty_Needed__c = (qty != null && qty != 0) ? qty : 1;
        soliRec.Kit_Price__c = (productList[0].Price__c != null) ? productList[0].Price__c : 0;
        soliRec.Actual_Kit_Price__c = (soliRec.Kit_Price__c != null) ? soliRec.Kit_Price__c : 0;
        soliRec.UUID__c = UUID;
        if(serviceOrderHeaderList.size() > 0) {
            soliRec.Deal__c = serviceOrderHeaderList[0].Deal__c;
            soliRec.Deal_Item__c = serviceOrderHeaderList[0].Deal_Item__c;
            soliRec.Commit_Order_Controls__c = serviceOrderHeaderList[0].Commit_Order_Controls__c;
        }
        DMLUtility.insertSobjectList('Service_Order_Line_Item__c', soliRec);
        
        DealService.createDealUnresolvedFulfillment(new List<String>{soliRec.Id}, soliRec.Deal__c, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
        return soliRec;
    }
    
    public static void updateBulkSOStatus(String soIdsJson, String soStatusId) {
        List<String> soIdList = (List<String>) System.JSON.deserialize(soIdsJson, List<String>.class);   
        List<Service_Order_Header__c> soUpdateList = new List<Service_Order_Header__c>();
        for(String soId : soIdList) {
            soUpdateList.add(new Service_Order_Header__c(Id = soId, SO_Status_Ref__c = soStatusId));
        }
        DMLUtility.updateSobjectList('Service_Order_Header__c', soUpdateList);
    }

    /* Methods moved from CustomerOrderCtrl */

    public Static String getServiceJobSalesTaxAmount(String soId) {
        Decimal taxAmount = 0;
        List<Individual_Tax__c> individualTaxList = new List<Individual_Tax__c>();
        if(!GeneralConfiguration.getTaxIncludingPricing()) {
            individualTaxList = [SELECT Deal__c, Taxable_Amount_for_Section_Header__c, CO_Line_Item__c, Tax_Rate__c, 
                                                            Form_Label__c, Sales_Tax_Item__r.Name__c, Tax_Amount__c, Tax_Amount_To_Invoice__c, 
                                                            Enhanced_Tax_Amount__c, Taxable_Amount__c, Taxable_Amount_To_Invoice__c, 
                                                            Applicable_Tax__c, List_Tax_items_on_forms__c, SO_Payment_Role__c 
                                                            FROM Individual_Tax__c WHERE Service_Order_Line_Item__c != null AND 
                                                            Service_Order_Line_Item__r.Service_Order_Header__c =: soId];
        }
        return System.JSON.serialize(new Map<String, Decimal>{'ServiceJobSalesTaxTotal' => TaxCalculation.getTaxAmount(individualTaxList)});
    }

    public static void saveServiceBulkDiscountPercent(String soId, String discountType, Decimal discountPct) {
        if(String.isBlank(soId)) throw new BlackPurlException('Invalid Service job Id.');
        List<Service_Order_Header__c> soHeaderList = [Select Name__c, CO_Header__c, Parts_Bulk_Discount_Percent__c, Fees_Bulk_Discount_Percent__c, Labor_Bulk_Discount_Percent__c, Sublet_Bulk_Discount_Percent__c From Service_Order_Header__c Where Id =: soId];
        if(!soHeaderList.isEmpty()) {
            if(discountType == 'Part') {
                InternalCommentService.addInternalCommentForBulkDiscount(soHeaderList[0].CO_Header__c, soHeaderList[0].Parts_Bulk_Discount_Percent__c, discountPct, soHeaderList[0].Name__c, 'Parts');
                soHeaderList[0].Parts_Bulk_Discount_Percent__c = discountPct;
            } else if (discountType == 'Fee') {
                InternalCommentService.addInternalCommentForBulkDiscount(soHeaderList[0].CO_Header__c, soHeaderList[0].Fees_Bulk_Discount_Percent__c, discountPct, soHeaderList[0].Name__c, 'Fees');
                soHeaderList[0].Fees_Bulk_Discount_Percent__c = discountPct;
            } else if (discountType == 'Labor') {
                InternalCommentService.addInternalCommentForBulkDiscount(soHeaderList[0].CO_Header__c, soHeaderList[0].Labor_Bulk_Discount_Percent__c, discountPct, soHeaderList[0].Name__c, 'Labor');
                soHeaderList[0].Labor_Bulk_Discount_Percent__c = discountPct;
            } else if (discountType == 'Sublet') {
                InternalCommentService.addInternalCommentForBulkDiscount(soHeaderList[0].CO_Header__c, soHeaderList[0].Sublet_Bulk_Discount_Percent__c, discountPct, soHeaderList[0].Name__c, 'Sublet');
                soHeaderList[0].Sublet_Bulk_Discount_Percent__c = discountPct;
            }
            SOTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderList);
            SOTriggerHelper.isForceStopTrigger = false;
            applyBulkDiscount(soId, discountType);
        }
    }

    private static void applyBulkDiscount(String soHeaderId, String discountType) {
        String query = 'SELECT Calculated_Customer_Price__c, Kit_Price__c , Price_When_Tax_Included__c, Tax_Percent__c, Bulk_Discount_Percent__c, Service_Order_Kit_Header__c, Fixed_Price__c, Service_Order_Kit_Header__r.Fixed_Price_Flag__c from Service_Order_Line_Item__c where '+
        'Service_Order_Header__r.Invoice_Number__c = null AND Service_Order_Header__c =: soHeaderId ';
        if(discountType == 'Part') {
            query += ' AND Part__c != null ';
        } else if (discountType == 'Fee') {
            query += ' AND Fee__c != null';
        } else if (discountType == 'Labor') {
            query += ' AND Labour_Code__c != null';
        } else if (discountType == 'Sublet') {
            query += ' AND Sublet__c != null';
        }
        boolean hasKit = false;
        List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
        for(Service_Order_Line_Item__c soliRec : (List<Service_Order_Line_Item__c>) Database.query(query)) {
            if(soliRec.Service_Order_Kit_Header__c != null) {
                if(!soliRec.Service_Order_Kit_Header__r.Fixed_Price_Flag__c && !soliRec.Fixed_Price__c) hasKit = true;
                continue;
            }            
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                soliRec.Price_When_Tax_Included__c = (soliRec.Calculated_Customer_Price__c * (1 - (soliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                if( soliRec.Tax_Percent__c != 0) {
                    soliRec.Kit_Price__c = (soliRec.Price_When_Tax_Included__c / (1 + (soliRec.Tax_Percent__c / 100))).setScale(2, RoundingMode.HALF_UP);
                } else {
                    soliRec.Kit_Price__c = soliRec.Price_When_Tax_Included__c;
                }
            } else {
                soliRec.Kit_Price__c = (soliRec.Calculated_Customer_Price__c * (1 - (soliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
            }
            soliListToUpdate.add(soliRec);
        }
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);

        if(hasKit) {
            MerchandiseService.isApplyBulkDiscount = true;
            CustomerOrderCtrl_V2.isRefreshCOKit = true;
            COTriggerHelper.isResetPricing = false;
            SO_KLI_Recalculation.soKitPriceCalculation(null, new Set<Id>{soHeaderId}, null);
            MerchandiseService.isApplyBulkDiscount = false;
            CustomerOrderCtrl_V2.isRefreshCOKit = false;
            COTriggerHelper.isResetPricing = true; 
        }
    }
}