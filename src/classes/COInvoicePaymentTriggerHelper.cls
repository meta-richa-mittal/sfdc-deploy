/**
 * Author: Pooja Khandelwal
 * Since: Jan. 13, 2017
 * Name: COInvoicePaymentTriggerHelper
 * Description: Helper class for triggers on CO Invoice Payment object
**/
public without sharing class COInvoicePaymentTriggerHelper {
    // List to store trigger new list
    public static List<CO_Invoice_Payment__c> COInvoicePaymentNewList = new List<CO_Invoice_Payment__c>();
    
    // List to store trigger old list
    public static List<CO_Invoice_Payment__c> COInvoicePaymentOldList = new List<CO_Invoice_Payment__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, CO_Invoice_Payment__c> COInvoicePaymentNewMap = new Map<Id, CO_Invoice_Payment__c>();

    // Map to store Old Trigger Map
    public static Map<Id, CO_Invoice_Payment__c> COInvoicePaymentOldMap = new Map<Id, CO_Invoice_Payment__c>();
     
    // Trigger run boolean
    public static Boolean isTriggerRun;
    
    // Trigger run boolean
    public static Boolean preventOnAccountingSync = false;
    
    private static BaseIntegrationService integrationRec;
    
	public static void beforeInsert() {
		validateDepositPayment();
    }

    public static void afterInsert() {
		updateDealFinance();
    }

	private static void validateDepositPayment() {
		Map<Id, List<Decimal>> coHeaderIdToDepositAmountsToUseMap = getCOHeaderIdToDepositAmountsToUseMap(COInvoicePaymentNewList);
		
		if(coHeaderIdToDepositAmountsToUseMap != null && !coHeaderIdToDepositAmountsToUseMap.isEmpty()) {
			Map<Id, List<Decimal>> coHeaderIdToAvailableDepositAmountsMap = getCOHeaderIdToAvailableDepositAmountsMap(coHeaderIdToDepositAmountsToUseMap.keySet());
			for(Id coId : coHeaderIdToDepositAmountsToUseMap.keySet()) {
				if(coHeaderIdToAvailableDepositAmountsMap.get(coId) != null) {
					if(coHeaderIdToDepositAmountsToUseMap.get(coId)[0] > coHeaderIdToAvailableDepositAmountsMap.get(coId)[0] || 
						coHeaderIdToDepositAmountsToUseMap.get(coId)[1] > coHeaderIdToAvailableDepositAmountsMap.get(coId)[1] || 
						coHeaderIdToDepositAmountsToUseMap.get(coId)[2] > coHeaderIdToAvailableDepositAmountsMap.get(coId)[2]) {
						for(CO_Invoice_Payment__c coInvPaymentRec : COInvoicePaymentNewList) {
							coInvPaymentRec.addError('There is not enough unused deposit left.');
						}
						return;
					}
				}
			}
			system.debug(coHeaderIdToDepositAmountsToUseMap  + '          ' + coHeaderIdToAvailableDepositAmountsMap);
		}
	}

	private static Map<Id, List<Decimal>> getCOHeaderIdToAvailableDepositAmountsMap(Set<Id> coIdSet) {
		Map<Id, List<Decimal>> coHeaderIdToAvailableDepositAmountsMap = new Map<Id, List<Decimal>>();
		for(CO_Header__c coRec : [Select Id, (Select Id, Amount__c, Payment_Method__c, Deal__c FROM CO_Deposits__r WHERE Is_Reversal_of_Payment__c = false AND Payment_Method__c != 'Invoice') From CO_Header__c WHERE Id IN: coIdSet]) {
			Decimal availableFinanceDeposit, availableDealDeposit, availableCustomerDeposit;
			availableFinanceDeposit = availableDealDeposit = availableCustomerDeposit = 0;
			for(CO_Deposit__c depositRec : coRec.CO_Deposits__r) {
				if(depositRec.Payment_Method__c == 'Financing') {
					availableFinanceDeposit += depositRec.Amount__c;
				} else if(depositRec.Deal__c != null) {
					availableDealDeposit += depositRec.Amount__c;
				} else {
					availableCustomerDeposit += depositRec.Amount__c;
				}
			}
			coHeaderIdToAvailableDepositAmountsMap.put(coRec.Id, new List<Decimal>{availableFinanceDeposit, availableDealDeposit, availableCustomerDeposit});
		}
		Map<Id, List<CO_Invoice_Payment__c>> coIdToInvPaymentRecListMap = new Map<Id, List<CO_Invoice_Payment__c>>();
		for(CO_Invoice_Payment__c paymentRec : [Select Id, CO_Invoice_Header__r.CO_Header__c, Deposit_Payment_Method__c, Amount__c, Payment_Method__c FROM CO_Invoice_Payment__c WHERE CO_Invoice_Header__r.CO_Header__c IN: coIdSet AND CO_Invoice_Header__r.Status__c != 'Closed' AND (Payment_Method__c = 'Use Deposit' OR Payment_Method__c = 'Use Deal Deposit')]) {
			if(!coIdToInvPaymentRecListMap.containsKey(paymentRec.CO_Invoice_Header__r.CO_Header__c)) {
				coIdToInvPaymentRecListMap.put(paymentRec.CO_Invoice_Header__r.CO_Header__c, new List<CO_Invoice_Payment__c>{paymentRec});
			} else {
				coIdToInvPaymentRecListMap.get(paymentRec.CO_Invoice_Header__r.CO_Header__c).add(paymentRec);
			}
		}

		for(Id coId : coIdToInvPaymentRecListMap.keySet()) {
			Decimal availableFinanceDeposit, availableDealDeposit, availableCustomerDeposit;
			availableFinanceDeposit = availableDealDeposit = availableCustomerDeposit = 0;
			for(CO_Invoice_Payment__c paymentRec : coIdToInvPaymentRecListMap.get(coId)) {
				if(String.isNotBlank(paymentRec.Deposit_Payment_Method__c) && paymentRec.Deposit_Payment_Method__c == 'Financing') {
					availableFinanceDeposit -= paymentRec.Amount__c;
				} else if(paymentRec.Payment_Method__c == 'Use Deal Deposit') {
					availableDealDeposit -= paymentRec.Amount__c;
				} else if(paymentRec.Payment_Method__c == 'Use Deposit') {
					availableCustomerDeposit -= paymentRec.Amount__c;
				}
			}
			if(!coHeaderIdToAvailableDepositAmountsMap.containsKey(coId)) {
				coHeaderIdToAvailableDepositAmountsMap.put(coId, new List<Decimal>{availableFinanceDeposit, availableDealDeposit, availableCustomerDeposit});
			} else {
				coHeaderIdToAvailableDepositAmountsMap.put(coId, new List<Decimal>{
					coHeaderIdToAvailableDepositAmountsMap.get(coId)[0] + availableFinanceDeposit,
					coHeaderIdToAvailableDepositAmountsMap.get(coId)[1] + availableDealDeposit,
					coHeaderIdToAvailableDepositAmountsMap.get(coId)[2] + availableCustomerDeposit
				});
			}
		}
		return coHeaderIdToAvailableDepositAmountsMap;
	}

	private static Map<Id, List<Decimal>> getCOHeaderIdToDepositAmountsToUseMap(List<CO_Invoice_Payment__c> coInvPaymentList) {
		Map<Id, List<Decimal>> coHeaderIdToDepositAmountsToUseMap = new Map<Id, List<Decimal>>();
		for(CO_Invoice_Payment__c coInvPaymentRec : coInvPaymentList) {
			if(String.isNotBlank(coInvPaymentRec.Payment_Method__c) && (coInvPaymentRec.Payment_Method__c == Constants.USE_DEPOSIT || coInvPaymentRec.Payment_Method__c == 'Use Deal Deposit')) {
				if(coInvPaymentRec.Is_Reverse__c == null || !coInvPaymentRec.Is_Reverse__c) {
					Decimal financeDepositToUse, dealDepositToUse, customerDepositToUse;
					financeDepositToUse = dealDepositToUse = customerDepositToUse = 0;
					if(String.isNotBlank(coInvPaymentRec.Deposit_Payment_Method__c) && coInvPaymentRec.Deposit_Payment_Method__c.equalsIgnoreCase('Financing')) {
						financeDepositToUse += coInvPaymentRec.Amount__c;
					} else if(coInvPaymentRec.Payment_Method__c == 'Use Deal Deposit') {
						dealDepositToUse += coInvPaymentRec.Amount__c;
					} else if(coInvPaymentRec.Payment_Method__c == 'Use Deposit') {
						customerDepositToUse += coInvPaymentRec.Amount__c;
					}
					if(financeDepositToUse != 0 || dealDepositToUse != 0 || customerDepositToUse != 0) {
						Id coId = coInvPaymentRec.CO_Header__c;
						if(!coHeaderIdToDepositAmountsToUseMap.containsKey(coId)) {
							coHeaderIdToDepositAmountsToUseMap.put(coId, new List<Decimal>{financeDepositToUse, dealDepositToUse, customerDepositToUse});
						} else {
							coHeaderIdToDepositAmountsToUseMap.put(coId, new List<Decimal>{
								coHeaderIdToDepositAmountsToUseMap.get(coId)[0] + financeDepositToUse, 
								coHeaderIdToDepositAmountsToUseMap.get(coId)[1] + dealDepositToUse,
								coHeaderIdToDepositAmountsToUseMap.get(coId)[2] + customerDepositToUse
							});
						}
					}
				}
			}
        }
		return coHeaderIdToDepositAmountsToUseMap;
	}

	private static void updateDealFinance() {
		Set<Id> coInvHeaderIdSet = new Set<Id>();
		for(CO_Invoice_Payment__c coInvPaymentRec : COInvoicePaymentNewList) {
            if(String.isNotBlank(coInvPaymentRec.Payment_Method__c) && coInvPaymentRec.Payment_Method__c.equalsIgnoreCase('Financing')) {
				
				coInvHeaderIdSet.add(coInvPaymentRec.CO_Invoice_Header__c);
			}
        }
		if(!coInvHeaderIdSet.isEmpty()) {
			Map<Id, Decimal> coIdToFinanceAmountPaidMap = new Map<Id, Decimal>();
			for(CO_Invoice_Header__c coInvHeaderRec : [Select CO_Header__c FROM CO_Invoice_Header__c WHERE Id IN: coInvHeaderIdSet]) {
				coIdToFinanceAmountPaidMap.put(coInvHeaderRec.CO_Header__c, 0);
			}
			CODepositTriggerHelper.updateDealFinanceStatus(coIdToFinanceAmountPaidMap);
		}
	}
	
    public static void populatesAccountingSyncFields() {
		IntegrationSyncFlagService.manageCOInvoicePaymentSyncFlag(COInvoicePaymentNewList);
    }
    
    public static void setCOInvoicePaymentDataForAccountSync(){
		IntegrationSyncFlagService.checkAndInitiateSyncBatch(COInvoicePaymentNewList, IntegrationUtility.CO_INVOICE_PAYMENT);
    }
    
    
    
    public static void createStoreCredit(){
    	List<CO_Invoice_Payment__c> newPaymentsList = [select Id, CO_Invoice_Header__r.CO_Header__r.Customer__c,
    													Payment_Method__c, CO_Invoice_Header__c, Amount__c
    													from CO_Invoice_Payment__c
    													where Id IN : COInvoicePaymentNewList];
    	List<Store_Credit__c> storeCreditListToInsert = new List<Store_Credit__c>(); 
    	Store_Credit__c storeCreditObj;
		for(CO_Invoice_Payment__c payment : newPaymentsList){ 
			if(payment.Payment_Method__c == 'Store Credit'){
				if(payment.CO_Invoice_Header__r.CO_Header__r.Customer__c == null){
					payment.addError('Store Credit can be used for Customer Only');
				}else{
					storeCreditObj = new Store_Credit__c();
					storeCreditObj.Customer__c = payment.CO_Invoice_Header__r.CO_Header__r.Customer__c;
					storeCreditObj.CO_Invoice_Header__c = payment.CO_Invoice_Header__c;
					storeCreditObj.Amount__c = -1 * payment.Amount__c;
					if(payment.Amount__c >= 0){
						storeCreditObj.Reference__c = 'Invoice Payment';
					}else{
						storeCreditObj.Reference__c = 'Return Invoice';
					}
					storeCreditListToInsert.add(storeCreditObj);
				}
			}
		}
		DMLUtility.insertSobjectList('Store_Credit__c', storeCreditListToInsert);	
    }

	public static void convertAmountToDecimal() {
		for(CO_Invoice_Payment__c coInvPaymentRec : COInvoicePaymentNewList) {
			coInvPaymentRec.Amount__c = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c.setScale(2, RoundingMode.HALF_UP) : 0;
        }
	}
}