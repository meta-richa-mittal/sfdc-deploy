/**
 * Author: Nidhi Sharma
 * Since: Dec 16, 2018
 * Name: CashReconciliationService
 * Description: Used to handle all methods related to Cash Reconciliation
**/
public without sharing class CashReconciliationService {
    
    public static Cash_Reconciliation__c getCashReconciliationRec(DateTime dtValue) {
        List<Cash_Reconciliation__c> cashReconciliationList = 
                CashDrawerSOQLUtil.getReconciliationList(new Map<String, String>{'Reconciliation_Date__c' => dtValue.formatGMT('yyyy-MM-dd')});
        if(cashReconciliationList.size() == 0) {
            Cash_Reconciliation__c cashReconciliationRec = new Cash_Reconciliation__c(Status__c = 'Unreconciled');
            cashReconciliationRec.Reconciliation_Date__c = dtValue.dateGMT();
            return cashReconciliationRec;
        }
        return cashReconciliationList[0];
    }
    
    public static Cash_Drawer_Reconciliation__c getDummyCashDrawerReconciliationRec(Cash_Reconciliation__c cashReconciliationRec) {
        Cash_Drawer_Reconciliation__c cashDrawerReconcilationRec = new Cash_Drawer_Reconciliation__c(Status__c = 'Unreconciled');
        cashDrawerReconcilationRec.Cash_Reconciliation__r = cashReconciliationRec;
        return cashDrawerReconcilationRec;
    }
    
    public static Map<String, String> getCashDrawerReconciliationPaymentsByDrawerId(DateTime dtValue, String cashDrawerId) {
    	Cash_Reconciliation__c cashReconciliationRec = getCashReconciliationRec(dtValue);
    	Map<String, String> paymentMethodNameToIdMap = new Map<String, String>();
    	
    	if(String.isNotBlank(cashReconciliationRec.Id) && String.isNotBlank(cashDrawerId)) {
			Map<String, String> fieldNameToValueMap = new Map<String, String>{'Cash_Reconciliation__c' => cashReconciliationRec.Id, 'Cash_Drawer__c' => cashDrawerId};
			List<Cash_Drawer_Reconciliation__c> cashDrawerReconciliationList = CashDrawerSOQLUtil.getCashDrawerReconciliationByFieldValues(fieldNameToValueMap);
			if(cashDrawerReconciliationList.size() > 0) {
				for(Cash_Reconciliation_Payment__c reconciliationPaymentRec : cashDrawerReconciliationList[0].Cash_Reconciliation_Payments__r) {
					paymentMethodNameToIdMap.put(reconciliationPaymentRec.Payment_Method__c, reconciliationPaymentRec.Id);
				}
			}
		}
		return paymentMethodNameToIdMap;
    }
    
    public static ReconciliationWrapper getReconciliationDetails(DateTime dtValue, String cashDrawerId, Boolean isSingleDrawerOrPrintView) {
        if(AccessControl.ifObjectFieldIsAccessible('Reconciliation_Payment__mdt') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Reconciliation_Payment__mdt> paymentTypeMetadataList = [Select Payment_Method__c, Type__c, Active__c, Order_Number__c, Icon_Link__c, Label from 
                    Reconciliation_Payment__mdt where Active__c = true Order by Order_Number__c ASC];
                    
        List<Cash_Drawer__c> cashDrawerList = CashDrawerSOQLUtil.getCashDrawerDetailsByFieldValues(dtValue, cashDrawerId);
        Cash_Reconciliation__c cashReconciliationRec = getCashReconciliationRec(dtValue);
        Map<String, Cash_Drawer_Reconciliation__c> cashDrawerIdToDrawerReconciliationRecMap = new Map<String, Cash_Drawer_Reconciliation__c>();
        String activeInetgrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();

        if(String.isNotBlank(cashReconciliationRec.Id)) {
            Map<String, String> fieldNameToValueMap = new Map<String, String>{'Cash_Reconciliation__c' => cashReconciliationRec.Id};
            List<Cash_Drawer_Reconciliation__c> cashDrawerReconciliationList = CashDrawerSOQLUtil.getCashDrawerReconciliationByFieldValues(fieldNameToValueMap);
            for(Cash_Drawer_Reconciliation__c cashDrawerReconRec : cashDrawerReconciliationList) {
                cashDrawerIdToDrawerReconciliationRecMap.put(cashDrawerReconRec.Cash_Drawer__c, cashDrawerReconRec);
            }
        }
		return new ReconciliationWrapper(cashDrawerList, cashDrawerIdToDrawerReconciliationRecMap, paymentTypeMetadataList, 
                    cashReconciliationRec, isSingleDrawerOrPrintView, activeInetgrationName);
    }
    
    private static Cash_Reconciliation__c setCashReconciliationFields(ReconciliationWrapper.ReconciliationInfo reconWrapperObj) {
        Cash_Reconciliation__c cashReconciliationRec = new Cash_Reconciliation__c();
        cashReconciliationRec.Id = reconWrapperObj.Id;
        cashReconciliationRec.Reconciliation_Date__c = reconWrapperObj.ReconciliationDate != null ? 
                                                            DateTimeUtility.parseDate(reconWrapperObj.ReconciliationDate) : null;
        if(reconWrapperObj.Status == 'Reconciled') {
            cashReconciliationRec.Commit_Reconciliation_Date__c = system.today();
            if(reconWrapperObj.PostJEToAccouting != null && reconWrapperObj.PostJEToAccouting) {
                if(QBUtil.isQBEnabled()) {
                    cashReconciliationRec.Available_For_QB_Sync__c = true;
                } else if(XeroUtility.isXeroEnabled()) {
                    cashReconciliationRec.Available_For_Xero_Sync__c = true;
                }
            }
        }        
        cashReconciliationRec.Optional_Note__c = String.isNotBlank(reconWrapperObj.OptionalNote) ? reconWrapperObj.OptionalNote : '';                                           
        cashReconciliationRec.Status__c = reconWrapperObj.Status;
        return cashReconciliationRec;
    }
    
    
    private static Cash_Drawer_Reconciliation__c updateCashDrawerReconciliationDetails(String cashReconciliationId, CashDrawerReconcilationWrapper drawerReconciliationObj, 
                                                                                        String status) {
        Cash_Drawer_Reconciliation__c drawerReconciliationRec = new Cash_Drawer_Reconciliation__c();
        drawerReconciliationRec.Cash_Reconciliation__c = cashReconciliationId;
        drawerReconciliationRec.Id = drawerReconciliationObj.Id;
        drawerReconciliationRec.Cash_Drawer__c = drawerReconciliationObj.DrawerId;
        drawerReconciliationRec.Status__c = status;
        return drawerReconciliationRec;
    }
    
    public static void saveReconciliation(String jsonStr) {
    	ReconciliationWrapper reconciliationWrapperObj = (ReconciliationWrapper)System.JSON.deserialize(jsonStr, ReconciliationWrapper.class);
    	
    	Cash_Reconciliation__c cashReconciliationRec = setCashReconciliationFields(reconciliationWrapperObj.ReconciliationInfo);
    	if(reconciliationWrapperObj.ReconciliationInfo.Id == null) {
    		DateTime dtValue = DateTimeUtility.getGMTDateTimeFromFormattedDateStr(reconciliationWrapperObj.ReconciliationInfo.ReconciliationDate);
        	String reconciledDateStr = dtValue.formatGMT('yyyy-MM-dd');
        	
    		List<Cash_Reconciliation__c> cashReconcilationList = CashDrawerSOQLUtil.getReconciliationList(new Map<String, String>{'Reconciliation_Date__c' => reconciledDateStr});
    		if(cashReconcilationList.size() > 0) {
    			cashReconciliationRec.Id = cashReconcilationList[0].Id;
    		}
    	}
    	
    	Map<String, Cash_Drawer_Reconciliation__c> cashDrawerIdToDrawerReconciliationRecMap = new Map<String, Cash_Drawer_Reconciliation__c>();
    	if(String.isNotBlank(cashReconciliationRec.Id)) {
    		Map<String, String> fieldNameToValueMap = new Map<String, String>{'Cash_Reconciliation__c' => cashReconciliationRec.Id};
    		List<Cash_Drawer_Reconciliation__c> drawerReconciliationRecList = CashDrawerSOQLUtil.getCashDrawerReconciliationByFieldValues(fieldNameToValueMap);
    		for(Cash_Drawer_Reconciliation__c drawerReconciliationRec : drawerReconciliationRecList) {
    			cashDrawerIdToDrawerReconciliationRecMap.put(drawerReconciliationRec.Cash_Drawer__c, drawerReconciliationRec);
    		}
    	}
    	
    	if(reconciliationWrapperObj.CashDrawerReconcilationObjList.size() <= 1) {
    		if(AccessControl.ifObjectFieldIsUpdateable('Cash_Reconciliation__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
			if(AccessControl.ifObjectFieldIsCreateable('Cash_Reconciliation__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	    	upsert cashReconciliationRec;
    	}
    	
    	for(CashDrawerReconcilationWrapper drawerReconciliationObj : reconciliationWrapperObj.CashDrawerReconcilationObjList) {
    		if(reconciliationWrapperObj.CashDrawerReconcilationObjList.size() > 0 && cashReconciliationRec.Status__c == 'Reconciled' && 
    			(drawerReconciliationObj.Status != 'Reviewed' && drawerReconciliationObj.Status != 'Submitted')) {
    			throw new BlackPurlException(BlackPurlException.getErrorMessage('Can not reconcile full day', null));
    		}
    		
    		if(String.isBlank(drawerReconciliationObj.Id) && cashDrawerIdToDrawerReconciliationRecMap.containsKey(drawerReconciliationObj.DrawerId)) {
    			drawerReconciliationObj.Id = cashDrawerIdToDrawerReconciliationRecMap.get(drawerReconciliationObj.DrawerId).Id;
    		}
    		Cash_Drawer_Reconciliation__c draweReconciliationRec = updateCashDrawerReconciliationDetails(cashReconciliationRec.Id, drawerReconciliationObj, 
    													(cashReconciliationRec.Status__c == 'Reconciled' ? cashReconciliationRec.Status__c : drawerReconciliationObj.Status));
    		cashDrawerIdToDrawerReconciliationRecMap.put(drawerReconciliationObj.DrawerId, draweReconciliationRec);
    	}
    	
    	if(cashDrawerIdToDrawerReconciliationRecMap.values().size() > 0) {
	    	if(AccessControl.ifObjectFieldIsUpdateable('Cash_Drawer_Reconciliation__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
			if(AccessControl.ifObjectFieldIsCreateable('Cash_Drawer_Reconciliation__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	    	upsert cashDrawerIdToDrawerReconciliationRecMap.values();
    	}
    	
    	if(reconciliationWrapperObj.CashDrawerReconcilationObjList.size() > 0) {
    		if(AccessControl.ifObjectFieldIsUpdateable('Cash_Reconciliation__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
			if(AccessControl.ifObjectFieldIsCreateable('Cash_Reconciliation__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	    	upsert cashReconciliationRec;
    	}
    	
    	if(reconciliationWrapperObj.CashDrawerReconcilationObjList[0].CashReconciliationPaymentList != null) {
	    	List<Cash_Reconciliation_Payment__c> cashReconciliationPaymentList = new List<Cash_Reconciliation_Payment__c>();
	    	for(CashDrawerReconcilationWrapper drawerReconciliationObj : reconciliationWrapperObj.CashDrawerReconcilationObjList) {
	    		Map<String, Id> paymentMethodToReconPaymentListMap = new Map<String, Id>();
	    		if(cashDrawerIdToDrawerReconciliationRecMap.containsKey(drawerReconciliationObj.DrawerId)) {
	    			drawerReconciliationObj.Id = cashDrawerIdToDrawerReconciliationRecMap.get(drawerReconciliationObj.DrawerId).Id;
	    			
	    			for(Cash_Reconciliation_Payment__c reconPaymentRec : cashDrawerIdToDrawerReconciliationRecMap.get(drawerReconciliationObj.DrawerId).Cash_Reconciliation_Payments__r) {
			    		paymentMethodToReconPaymentListMap.put(reconPaymentRec.Payment_Method__c, reconPaymentRec.Id);
			    	}
	    		}
	    		cashReconciliationPaymentList.addAll(setCashReconciliationPaymentFields(cashReconciliationRec.Id, drawerReconciliationObj.Id, 
	    												drawerReconciliationObj.CashReconciliationPaymentList, paymentMethodToReconPaymentListMap));
	    		cashReconciliationPaymentList.addAll(setCashReconciliationPaymentFields(cashReconciliationRec.Id, drawerReconciliationObj.Id, 
	    											drawerReconciliationObj.OtherReconciliationPaymentList,  paymentMethodToReconPaymentListMap));
	    	}
	    	
	    	if(cashReconciliationPaymentList.size() > 0) {
	    		if(AccessControl.ifObjectFieldIsUpdateable('Cash_Reconciliation_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
	    		if(AccessControl.ifObjectFieldIsCreateable('Cash_Reconciliation_Payment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	    		upsert cashReconciliationPaymentList;
	    	}
    	}
    }
    
    private static List<Cash_Reconciliation_Payment__c> setCashReconciliationPaymentFields(Id cashReconciliationId, Id cashDrawerReconciliationId, 
                                                                        List<CashDrawerReconcilationWrapper.ReconciliationPayment> reconPaymentWrapperList,
                                                                        Map<String, Id> paymentMethodToReconPaymentListMap) {
        List<Cash_Reconciliation_Payment__c> cashReconciliationPaymentList = new List<Cash_Reconciliation_Payment__c>();
        Cash_Reconciliation_Payment__c cashReconciliationPaymentRec;
        for(CashDrawerReconcilationWrapper.ReconciliationPayment reconPaymentWrapperObj : reconPaymentWrapperList) {
            
            cashReconciliationPaymentRec = new Cash_Reconciliation_Payment__c(Cash_Reconciliation__c = cashReconciliationId);
            cashReconciliationPaymentRec.Cash_Drawer_Reconciliation__c = cashDrawerReconciliationId;
            cashReconciliationPaymentRec.Id = reconPaymentWrapperObj.Id;
            if(paymentMethodToReconPaymentListMap.containsKey(reconPaymentWrapperObj.PaymentMethod)) {
                cashReconciliationPaymentRec.Id = paymentMethodToReconPaymentListMap.get(reconPaymentWrapperObj.PaymentMethod);
            }
            cashReconciliationPaymentRec.Payment_Method__c = reconPaymentWrapperObj.ActualPaymentMethodName;
            cashReconciliationPaymentRec.Processed_Amount__c = reconPaymentWrapperObj.ProcessedAmount;
            cashReconciliationPaymentRec.Actual_Amount__c = reconPaymentWrapperObj.ActualAmount;
            cashReconciliationPaymentList.add(cashReconciliationPaymentRec);
        }
        return cashReconciliationPaymentList;
    }
    
    public static Map<String, List<Sobject>> createPaymentTypeToCOPaymentListMap(List<CO_Invoice_Payment__c> coPaymentList, List<CO_Deposit__c> coDepositList, List<Payment_on_Account__c> paymentOnAccountList) {
        Map<String, List<Sobject>> paymentTypeToCOPaymentListMap = new Map<String, List<Sobject>>();
        for(CO_Invoice_Payment__c coPaymentRec : coPaymentList) {
        	String paymentMethod = (coPaymentRec.Payment_Method__c == 'Use Deal Deposit') ? 'Use Deposit' : coPaymentRec.Payment_Method__c;
            if(paymentMethod != 'Store Credit' ||
                    (paymentMethod == 'Store Credit' && coPaymentRec.Amount__c > 0)) {
                
                if(!paymentTypeToCOPaymentListMap.containsKey(paymentMethod)) {
                    paymentTypeToCOPaymentListMap.put(paymentMethod, new List<Sobject>());
                }
                paymentTypeToCOPaymentListMap.get(paymentMethod).add(coPaymentRec);
            }
            
            if(paymentMethod == 'Store Credit' && coPaymentRec.Amount__c < 0) {
                if(!paymentTypeToCOPaymentListMap.containsKey('Store credit issued')) {
                    paymentTypeToCOPaymentListMap.put('Store credit issued', new List<Sobject>());
                }
                coPaymentRec.Amount__c = (coPaymentRec.Amount__c != null) ? (-1 * coPaymentRec.Amount__c) : 0;
                paymentTypeToCOPaymentListMap.get('Store credit issued').add(coPaymentRec);
            }
        }
        
        for(CO_Deposit__c coDepositRec : coDepositList) {
            if(!paymentTypeToCOPaymentListMap.containsKey(coDepositRec.Payment_Method__c)) { 
                paymentTypeToCOPaymentListMap.put(coDepositRec.Payment_Method__c, new List<Sobject>());
            }
            if(coDepositRec.Payment_Method__c != 'Financing' || !coDepositRec.Is_Reversal_of_Payment__c) {
                paymentTypeToCOPaymentListMap.get(coDepositRec.Payment_Method__c).add(coDepositRec);
            }
            if(coDepositRec.Payment_Method__c != 'Use Deposit') {
                if(!paymentTypeToCOPaymentListMap.containsKey('Deposits Taken')) {
                    paymentTypeToCOPaymentListMap.put('Deposits Taken', new List<Sobject>());
                }
                paymentTypeToCOPaymentListMap.get('Deposits Taken').add(coDepositRec);
            }
        }
        for(Payment_on_Account__c paymentOnAccountRec : paymentOnAccountList) {
            if(!paymentTypeToCOPaymentListMap.containsKey(paymentOnAccountRec.Payment_Method__c)) {
                paymentTypeToCOPaymentListMap.put(paymentOnAccountRec.Payment_Method__c, new List<Sobject>());
            }
            paymentTypeToCOPaymentListMap.get(paymentOnAccountRec.Payment_Method__c).add(paymentOnAccountRec);
        }
        return paymentTypeToCOPaymentListMap;
    }
    
    public static List<CashReconciliationTTWrapper> getTransactionTypeDetails(DateTime dtValue) {
        List<CashReconciliationTTWrapper> reconciliatioTTObjList = new List<CashReconciliationTTWrapper>();
        
        // create set of all active cash drawers
        List<Cash_Drawer__c> cashDrawerList = CashDrawerSOQLUtil.getAllCashDrawerList(false);
        Set<String> cashDrawerNameSet = new Set<String>();
        for(Cash_Drawer__c cashDrawerRec: cashDrawerList) {
            cashDrawerNameSet.add(cashDrawerRec.Name);
        }
        
        // create map of payment method to drawer name to actual amount for the given date
        Map<String, Map<String, Decimal>> paymentTypeToDrawerNameToActualAmountMap = createPaymentTypeToDrawerNameToRecPaymentListMap(dtValue, cashDrawerNameSet);
        
        // create map of payment method to drawer name to payment/deposit list for payments/deposits done on given date
        Map<String, Map<String, List<Sobject>>> paymentTypeToDrawerNameToCOPaymentListMap = createPaymentTypeToDrawerNameToCOPaymentListMap(dtValue);
        
        // query metadata for all payment records available
        if(AccessControl.ifObjectFieldIsAccessible('Reconciliation_Payment__mdt') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Reconciliation_Payment__mdt> paymentTypeList = 
                        [Select Payment_Method__c, Type__c, Active__c, Order_Number__c, Icon_Link__c, Label from 
                                Reconciliation_Payment__mdt where Active__c = true Order by Order_Number__c ASC];
        
        // get all defined payment methods
        Map<String, Payment_Method__c> paymentMethodsMap = Payment_Method__c.getAll();
        String activeInetgrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();

        // iterate to include all payment methods in result wrapper
        for(Reconciliation_Payment__mdt paymentTypeRec : paymentTypeList) {
            Map<String, List<sObject>> drawerNameToCOPaymentListMap = paymentTypeToDrawerNameToCOPaymentListMap.containsKey(paymentTypeRec.Payment_Method__c) ? paymentTypeToDrawerNameToCOPaymentListMap.get(paymentTypeRec.Payment_Method__c) : null; 
            Map<String, Decimal> drawerNameToActualAmountMap = paymentTypeToDrawerNameToActualAmountMap.containsKey(paymentTypeRec.Payment_Method__c) ? paymentTypeToDrawerNameToActualAmountMap.get(paymentTypeRec.Payment_Method__c) : null;
            CashReconciliationTTWrapper ttWrapperObj = new CashReconciliationTTWrapper(paymentTypeRec, drawerNameToCOPaymentListMap, cashDrawerNameSet, drawerNameToActualAmountMap);
            if((!paymentMethodsMap.containsKey(paymentTypeRec.Payment_Method__c) || paymentMethodsMap.get(paymentTypeRec.Payment_Method__c).Is_Active__c 
            	|| ttWrapperObj.TotalProcessedAmount != 0) && isIncludePayment(paymentTypeRec.Payment_Method__c, activeInetgrationName)) {
            	reconciliatioTTObjList.add(ttWrapperObj);
            }
        }
        return reconciliatioTTObjList;
    }

    public static Boolean isIncludePayment(String paymentMethod, String activeInetgrationName) {
        return ((paymentMethod != Constants.AR_Credit || (activeInetgrationName == QBUtil.QUICKBOOKS_ONLINE || activeInetgrationName == 'Xero')) && 
        !(paymentMethod == PreferredPaymentService.PREFERRED_PAYMENTS && !GeneralConfiguration.isPreferredPaymentIntegrationEnabled()));
    }
    
    private static Map<String, Map<String, List<Sobject>>> createPaymentTypeToDrawerNameToCOPaymentListMap(DateTime dtValue) {
        List<CO_Invoice_Payment__c> coPaymentList = CashDrawerSOQLUtil.getCOInvoicePaymentsByDate(dtValue);
        List<CO_Deposit__c> coDepositList = CashDrawerSOQLUtil.getCODepositByDate(dtValue);
        List<Payment_on_Account__c> paymentOnAccountList = CashDrawerSOQLUtil.getPaymentOnAccountByDate(dtValue);
        
        Map<String, Map<String, List<Sobject>>> paymentTypeToDrawerNameToCOPaymentListMap = new Map<String, Map<String, List<Sobject>>>();
        createPaymentsMapFromCOInvoicePayments(coPaymentList, paymentTypeToDrawerNameToCOPaymentListMap);
        createPaymentsMapFromCODeposits(coDepositList, paymentTypeToDrawerNameToCOPaymentListMap);
        createPaymentsMapFromPaymentsOnAccount(paymentOnAccountList, paymentTypeToDrawerNameToCOPaymentListMap);
        return paymentTypeToDrawerNameToCOPaymentListMap;
    }
    
    private static void createPaymentsMapFromCOInvoicePayments(List<CO_Invoice_Payment__c> coPaymentList, Map<String, Map<String, List<Sobject>>> paymentTypeToDrawerNameToCOPaymentListMap) {
        for(CO_Invoice_Payment__c coPaymentRec : coPaymentList) {
            String paymentMethod = (coPaymentRec.Payment_Method__c == 'Use Deal Deposit') ? 'Use Deposit' : coPaymentRec.Payment_Method__c;
            
            if(paymentMethod != 'Store Credit' ||
                    (paymentMethod == 'Store Credit' && coPaymentRec.Amount__c > 0)) {
                if(coPaymentRec.Cash_Drawer__c != null) {
                	
                    if(!paymentTypeToDrawerNameToCOPaymentListMap.containsKey(paymentMethod)) {
                        paymentTypeToDrawerNameToCOPaymentListMap.put(paymentMethod, new Map<String, List<Sobject>>{coPaymentRec.Cash_Drawer__r.Name => new List<Sobject>{coPaymentRec}});
                    } else {
                        if(!paymentTypeToDrawerNameToCOPaymentListMap.get(paymentMethod).containsKey(coPaymentRec.Cash_Drawer__r.Name)) {
                            paymentTypeToDrawerNameToCOPaymentListMap.get(paymentMethod).put(coPaymentRec.Cash_Drawer__r.Name, new List<Sobject>());
                        }
                        paymentTypeToDrawerNameToCOPaymentListMap.get(paymentMethod).get(coPaymentRec.Cash_Drawer__r.Name).add(coPaymentRec);
                    }
                }
            }
            
            if(paymentMethod == 'Store Credit' && coPaymentRec.Amount__c < 0) {
                if(coPaymentRec.Cash_Drawer__c != null) {
                    if(!paymentTypeToDrawerNameToCOPaymentListMap.containsKey('Store credit issued')) {
                        paymentTypeToDrawerNameToCOPaymentListMap.put('Store credit issued', new Map<String, List<Sobject>>());
                    } else {
                        if(!paymentTypeToDrawerNameToCOPaymentListMap.get('Store credit issued').containsKey(coPaymentRec.Cash_Drawer__r.Name)) {
                            paymentTypeToDrawerNameToCOPaymentListMap.get('Store credit issued').put(coPaymentRec.Cash_Drawer__r.Name, new List<Sobject>());
                        }
                        coPaymentRec.Amount__c = (coPaymentRec.Amount__c != null) ? (-1 * coPaymentRec.Amount__c) : 0;
                        paymentTypeToDrawerNameToCOPaymentListMap.get('Store credit issued').get(coPaymentRec.Cash_Drawer__r.Name).add(coPaymentRec);
                    }
                }
            }
        }
    }
    
    private static void createPaymentsMapFromCODeposits(List<CO_Deposit__c> coDepositList, Map<String, Map<String, List<Sobject>>> paymentTypeToDrawerNameToCOPaymentListMap) {
        for(CO_Deposit__c coDepositRec : coDepositList) {
            if(coDepositRec.Cash_Drawer__c != null) {
                if(!paymentTypeToDrawerNameToCOPaymentListMap.containsKey(coDepositRec.Payment_Method__c)) {
                    paymentTypeToDrawerNameToCOPaymentListMap.put(coDepositRec.Payment_Method__c, new Map<String, List<Sobject>>{coDepositRec.Cash_Drawer__r.Name => new List<Sobject>{coDepositRec}});
                } else {
                    if(!paymentTypeToDrawerNameToCOPaymentListMap.get(coDepositRec.Payment_Method__c).containsKey(coDepositRec.Cash_Drawer__r.Name)) {
                        paymentTypeToDrawerNameToCOPaymentListMap.get(coDepositRec.Payment_Method__c).put(coDepositRec.Cash_Drawer__r.Name, new List<Sobject>());
                    }
                    paymentTypeToDrawerNameToCOPaymentListMap.get(coDepositRec.Payment_Method__c).get(coDepositRec.Cash_Drawer__r.Name).add(coDepositRec);
                }
                if(coDepositRec.Payment_Method__c != 'Use Deposit') {
                    if(!paymentTypeToDrawerNameToCOPaymentListMap.containsKey('Deposits Taken')) {
                        paymentTypeToDrawerNameToCOPaymentListMap.put('Deposits Taken', new Map<String, List<Sobject>>{coDepositRec.Cash_Drawer__r.Name => new List<Sobject>{coDepositRec}});
                    } else {
                        if(!paymentTypeToDrawerNameToCOPaymentListMap.get('Deposits Taken').containsKey(coDepositRec.Cash_Drawer__r.Name)) {
                            paymentTypeToDrawerNameToCOPaymentListMap.get('Deposits Taken').put(coDepositRec.Cash_Drawer__r.Name, new List<Sobject>());
                        }
                        paymentTypeToDrawerNameToCOPaymentListMap.get('Deposits Taken').get(coDepositRec.Cash_Drawer__r.Name).add(coDepositRec);
                    }
                }
            }
        }
    }
    
    private static void createPaymentsMapFromPaymentsOnAccount(List<Payment_on_Account__c> paymentOnAccountList, Map<String, Map<String, List<Sobject>>> paymentTypeToDrawerNameToCOPaymentListMap) {
        for(Payment_on_Account__c paymentOnAccountRec : paymentOnAccountList) {
            if(paymentOnAccountRec.Cash_Drawer__c != null) {
                if(!paymentTypeToDrawerNameToCOPaymentListMap.containsKey(paymentOnAccountRec.Payment_Method__c)) {
                    paymentTypeToDrawerNameToCOPaymentListMap.put(paymentOnAccountRec.Payment_Method__c, new Map<String, List<Sobject>>{paymentOnAccountRec.Cash_Drawer__r.Name => new List<Sobject>{paymentOnAccountRec}});
                } else {
                    if(!paymentTypeToDrawerNameToCOPaymentListMap.get(paymentOnAccountRec.Payment_Method__c).containsKey(paymentOnAccountRec.Cash_Drawer__r.Name)) {
                        paymentTypeToDrawerNameToCOPaymentListMap.get(paymentOnAccountRec.Payment_Method__c).put(paymentOnAccountRec.Cash_Drawer__r.Name, new List<Sobject>());
                    }
                    paymentTypeToDrawerNameToCOPaymentListMap.get(paymentOnAccountRec.Payment_Method__c).get(paymentOnAccountRec.Cash_Drawer__r.Name).add(paymentOnAccountRec);
                }
            }
        }
    }
    
    private static Map<String, Map<String, Decimal>> createPaymentTypeToDrawerNameToRecPaymentListMap(DateTime dtValue, Set<String> cashDrawerNameSet) {
        List<Cash_Reconciliation_Payment__c> cashReconcilationPaymentList = CashDrawerSOQLUtil.getReconciliationPaymentsList(new Map<String, String>{'Cash_Reconciliation__r.Reconciliation_Date__c' => dtValue.formatGMT('yyyy-MM-dd')});
        
        Map<String, Map<String, Decimal>> paymentTypeToDrawerNameToActualAmountMap = new Map<String, Map<String, Decimal>>();
        for(Cash_Reconciliation_Payment__c paymentRec: cashReconcilationPaymentList) {
            cashDrawerNameSet.add(paymentRec.Cash_Drawer_Reconciliation__r.Cash_Drawer__r.Name);
            if(!paymentTypeToDrawerNameToActualAmountMap.containsKey(paymentRec.Payment_Method__c)) {
                paymentTypeToDrawerNameToActualAmountMap.put(paymentRec.Payment_Method__c, new Map<String, Decimal>{paymentRec.Cash_Drawer_Reconciliation__r.Cash_Drawer__r.Name => (paymentRec.Actual_Amount__c != null ? paymentRec.Actual_Amount__c : 0)});
            } else {
                if(!paymentTypeToDrawerNameToActualAmountMap.get(paymentRec.Payment_Method__c).containsKey(paymentRec.Cash_Drawer_Reconciliation__r.Cash_Drawer__r.Name)) {
                    paymentTypeToDrawerNameToActualAmountMap.get(paymentRec.Payment_Method__c).put(paymentRec.Cash_Drawer_Reconciliation__r.Cash_Drawer__r.Name, 0);
                }
                paymentTypeToDrawerNameToActualAmountMap.get(paymentRec.Payment_Method__c).put(paymentRec.Cash_Drawer_Reconciliation__r.Cash_Drawer__r.Name, (paymentRec.Actual_Amount__c != null ? paymentRec.Actual_Amount__c : 0));
            }
        }
        return paymentTypeToDrawerNameToActualAmountMap;
    }
    
    public static List<ReconciliationWrapper.ReconciliationInfo> getMiniCalenderData(String selectedJSONStr, String cashDrawerId) {
    	ReconciliationWrapper.MiniCalenderDate selectedDateRange = 
    			(ReconciliationWrapper.MiniCalenderDate)System.JSON.deserialize(selectedJSONStr, ReconciliationWrapper.MiniCalenderDate.class);
    	DateTime startDateValue = DateTimeUtility.getGMTDateTimeFromFormattedDateStr(selectedDateRange.StartDate);
    	DateTime endDateValue = DateTimeUtility.getGMTDateTimeFromFormattedDateStr(selectedDateRange.EndDate);
    	
    	if(AccessControl.ifObjectFieldIsAccessible('Cash_Reconciliation__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	String query = 'Select Reconciliation_Date__c, Status__c, Commit_Reconciliation_Date__c, Optional_Note__c ';
    	query += (String.isNotBlank(cashDrawerId) ? ', (Select Id, Status__c from Cash_Drawer_Reconciliations__r where Cash_Drawer__c =: cashDrawerId) ' : '');
    	query += ' from Cash_Reconciliation__c ';
    	query += ' WHERE Reconciliation_Date__c >= ' + startDateValue.formatGMT('yyyy-MM-dd') + 
    					' AND Reconciliation_Date__c < ' + endDateValue.addDays(1).formatGMT('yyyy-MM-dd');
    	List<Cash_Reconciliation__c> cashReconciliationList = Database.query(query);
    							
    	List<ReconciliationWrapper.ReconciliationInfo> reconciliationInfoList = new List<ReconciliationWrapper.ReconciliationInfo>();
    	for(Cash_Reconciliation__c cashReconciliationRec : cashReconciliationList) {
    		ReconciliationWrapper.ReconciliationInfo reconObj = new ReconciliationWrapper.ReconciliationInfo(cashReconciliationRec);
    		if(cashReconciliationRec.Status__c != 'Reconciled' && String.isNotBlank(cashDrawerId)) {
    			reconObj.Status = (cashReconciliationRec.Cash_Drawer_Reconciliations__r.size() > 0) ? cashReconciliationRec.Cash_Drawer_Reconciliations__r[0].Status__c
    							 : 'Unreconciled';
    		}
    		reconciliationInfoList.add(reconObj);
    	}
    	return reconciliationInfoList;
    }

    public static List<CashReconciliationTTWrapper.JournalEntryInfoWrapper> getCashReconciliationJE(String cashReconId) {
        List<Cash_Reconciliation__c> cashReconList = [Select Id, Name, Optional_Note__c, Reconciliation_Date__c, Accounting_Id__c, Sync_Token__c, Accounting_Response__c, (SELECT Payment_Method__c, Cash_Drawer_Reconciliation__c, Actual_Amount__c, Variance__c, Processed_Amount__c, Cash_Drawer_Reconciliation__r.Cash_Drawer__c, Cash_Drawer_Reconciliation__r.Cash_Drawer__r.Name FROM Cash_Reconciliation_Payments__r ORDER BY Payment_Method__c ASC LIMIT 1000) FROM Cash_Reconciliation__c WHERE Id =: cashReconId];
        if(cashReconList.isEmpty()) throw new BlackPurlException('Cash Reconciliation record not found');
        AccountingCashReconciliation cashReconRecord = new AccountingCashReconciliation(cashReconList[0]);

        String undepFundsAccId = AccountingUtil.getChartofAccount('Undeposited Funds');
        String cashRecClearingAccId = AccountingUtil.getChartofAccount('Cash Rec Clearing');
        String cashOverShortAccId = AccountingUtil.getChartofAccount('Cash over/short');

        String cashOverShortGLName, undepFundsGLName, cashRecClearingGLName;

        List<CashReconciliationTTWrapper.JournalEntryInfoWrapper> jeLines = new List<CashReconciliationTTWrapper.JournalEntryInfoWrapper>();

        String query = 'SELECT Account_Name__c, Accounting_Id__c, Account_Number__c FROM General_Account__c WHERE ';
        query += (QBUtil.isQBEnabled() ? 'Accounting_Id__c ': 'Account_Number__c ') + 'IN (\'' + undepFundsAccId + '\', \'' + cashRecClearingAccId + '\', \'' + cashOverShortAccId + '\')';
        
        List<General_Account__c> generalAccountList = Database.query(query);
        if(generalAccountList.isEmpty()) throw new BlackPurlException('GL Account records not found');

        for(General_Account__c generalAccountRec : generalAccountList) {
            if(QBUtil.isQBEnabled()) {
                if(generalAccountRec.Accounting_Id__c == undepFundsAccId) {
                    undepFundsGLName = generalAccountRec.Account_Name__c;
                } else if(generalAccountRec.Accounting_Id__c == cashRecClearingAccId) {
                    cashRecClearingGLName = generalAccountRec.Account_Name__c;
                } else if(generalAccountRec.Accounting_Id__c == cashOverShortAccId) {
                    cashOverShortGLName = generalAccountRec.Account_Name__c;
                }
            } else {
                if(generalAccountRec.Account_Number__c == undepFundsAccId) {
                    undepFundsGLName = generalAccountRec.Account_Name__c;
                } else if(generalAccountRec.Account_Number__c == cashRecClearingAccId) {
                    cashRecClearingGLName = generalAccountRec.Account_Name__c;
                } else if(generalAccountRec.Account_Number__c == cashOverShortAccId) {
                    cashOverShortGLName = generalAccountRec.Account_Name__c;
                }
            }
        }

        String lineItemDesc;
        for(AccountingCashReconciliation.CashReconciliationPaymentWrapper reconPaymentRec : cashReconRecord.ReconPaymentList) {
            if(reconPaymentRec.ActualAmount != null && reconPaymentRec.ActualAmount != 0) {
                lineItemDesc = String.ValueOf(cashReconRecord.ReconciliationDate) + ' - '+ reconPaymentRec.PaymentName + ' - ' + reconPaymentRec.CashDrawerName;
                if(reconPaymentRec.ActualAmount > 0) {
                    jeLines.add(new CashReconciliationTTWrapper.JournalEntryInfoWrapper(undepFundsGLName, lineItemDesc, null, reconPaymentRec.ActualAmount.setScale(2, RoundingMode.HALF_UP)));
                } else {
                    jeLines.add(new CashReconciliationTTWrapper.JournalEntryInfoWrapper(undepFundsGLName, lineItemDesc, reconPaymentRec.ActualAmount.setScale(2, RoundingMode.HALF_UP) * -1, null));
                }
            }
        }
        if(cashReconRecord.TotalProcessedAmount != 0) {
            if(cashReconRecord.TotalProcessedAmount > 0) {
                jeLines.add(new CashReconciliationTTWrapper.JournalEntryInfoWrapper(cashRecClearingGLName, String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation', cashReconRecord.TotalProcessedAmount.setScale(2, RoundingMode.HALF_UP), null));
            } else {
                jeLines.add(new CashReconciliationTTWrapper.JournalEntryInfoWrapper(cashRecClearingGLName, String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation', null, cashReconRecord.TotalProcessedAmount.setScale(2, RoundingMode.HALF_UP) * -1));
            }
        }

        if(cashReconRecord.TotalVariance != 0) {
            if(cashReconRecord.TotalVariance > 0) {
                jeLines.add(new CashReconciliationTTWrapper.JournalEntryInfoWrapper(cashOverShortGLName, String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation', cashReconRecord.TotalVariance.setScale(2, RoundingMode.HALF_UP), null));
            } else {
                jeLines.add(new CashReconciliationTTWrapper.JournalEntryInfoWrapper(cashOverShortGLName, String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation', null, cashReconRecord.TotalVariance.setScale(2, RoundingMode.HALF_UP) * -1));
            }
        }
        return jeLines;
    }

    public static Boolean isNewPaymentAccountingApplicable(String cashReconId) {
        List<Cash_Reconciliation__c> cashReconList = [Select Reconciliation_Date__c FROM Cash_Reconciliation__c WHERE Id =: cashReconId];
        if(cashReconList.isEmpty()) return false;
        return (Accountingutil.isNewPaymentAccountingApplicable(cashReconList[0].Reconciliation_Date__c)); 
    }

    public static Set<String> getCashCreditPaymentSet() {
        Set<String> paymentMethodTypeSet = new Set<String>();
        List<Reconciliation_Payment__mdt> paymentTypeList = [Select Payment_Method__c from Reconciliation_Payment__mdt where Active__c = true AND Type__c = 'Cash/Credit' ];
        for(Reconciliation_Payment__mdt paymentTypeRec : paymentTypeList) {
            paymentMethodTypeSet.add(paymentTypeRec.Payment_Method__c);
        }
        return paymentMethodTypeSet;
    }
}