/**
 * Author: Richa Mittal
 * Since: Jan. 16, 2017
 * Name: CODepositTriggerHelper
 * Description: Helper class for triggers on CO Deposit object
**/
public without sharing class CODepositTriggerHelper {
    // List to store trigger new list
    public static List<CO_Deposit__c> CODepositNewList = new List<CO_Deposit__c>();
    
    // List to store trigger old list
    public static List<CO_Deposit__c> CODepositOldList = new List<CO_Deposit__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, CO_Deposit__c> CODepositNewMap = new Map<Id, CO_Deposit__c>();

    // Map to store Old Trigger Map
    public static Map<Id, CO_Deposit__c> CODepositOldMap = new Map<Id, CO_Deposit__c>();
     
    // Trigger run boolean
    public static Boolean isTriggerRun;
    
    // Trigger run boolean
    public static Boolean preventOnAccountingSync = false;
    
    private static BaseIntegrationService integrationRec;
    
	public static void afterInsert() {
        preventOnAccountingSync = true;
        setCODepositDataForAccountSync();
		updateConfirmedSaleDate();
		updateDealFinance();
    }

    public static void populatesAccountingSyncFields(){
    	IntegrationSyncFlagService.manageCODepositSyncFlag(CODepositNewList);
    }
    
    public static void setCODepositDataForAccountSync(){
    	IntegrationSyncFlagService.checkAndInitiateSyncBatch(CODepositNewList, IntegrationUtility.CO_DEPOSIT);
    }

	private static void updateConfirmedSaleDate() {
		List<String> dealIdSet = new List<String>();
		for(CO_Deposit__c coDepositRec : coDepositNewList) {
            dealIdSet.add(coDepositRec.Deal__c); 
        }
		if(dealIdSet.size() == 0) return;
		List<Deal__c> dealList = [SELECT Confirmed_Sale_Date__c, Status__c, (SELECT Deal__c, Amount__c, Payment_Date__c FROM CO_Deposits__r 
									ORDER BY CreatedDate DESC) FROM Deal__c WHERE Id IN :dealIdSet];
		
		List<CO_Deposit__c> coDepositList = new List<CO_Deposit__c>();
        for(Deal__c dealRec: dealList) {
			coDepositList.addAll(dealRec.CO_Deposits__r);
        }
		
		Map<String, Decimal> dealIdToDepositAmountMap = DealService.getDealIdToDepositAmountMap(coDepositList);
		DealService.updateConfirmedSaleDate(dealList, null, dealIdToDepositAmountMap, true);
	}

	private static void updateDealFinance() {
		Map<Id, Decimal> coIdToFinanceAmountPaidMap = new Map<Id, Decimal>();
		for(CO_Deposit__c coDepositRec : coDepositNewList) {
            if(String.isNotBlank(coDepositRec.Payment_Method__c) && coDepositRec.Payment_Method__c.equalsIgnoreCase('Financing')) {
				coIdToFinanceAmountPaidMap.put(coDepositRec.CO_Header__c, 0);
			}
        }
		updateDealFinanceStatus(coIdToFinanceAmountPaidMap);
	}

	public static void updateDealFinanceStatus(Map<Id, Decimal> coIdToFinanceAmountPaidMap) {
        if(coIdToFinanceAmountPaidMap != null && !coIdToFinanceAmountPaidMap.isEmpty()) {
            for(AggregateResult aggCOIP : [Select CO_Invoice_Header__r.CO_Header__c COId, SUM(Amount__c) TotalFinancePayment FROM CO_Invoice_Payment__c WHERE CO_Invoice_Header__r.CO_Header__c IN: coIdToFinanceAmountPaidMap.keySet() AND (Payment_Method__c = 'Financing' OR (Deposit_Payment_Method__c = 'Financing' AND Amount__c < 0)) AND Amount__c != null Group By CO_Invoice_Header__r.CO_Header__c]) {
                String coId = String.valueOf(aggCOIP.get('COId'));
                coIdToFinanceAmountPaidMap.put(coId, coIdToFinanceAmountPaidMap.get(coId) + Decimal.valueOf(String.valueOf(aggCOIP.get('TotalFinancePayment'))));
            }
            List<CO_Invoice_Item__c> coInvItemList = new List<CO_Invoice_Item__c>();
            List<Deal_Finance__c> dealFinanceUpdateList = new List<Deal_Finance__c>();
            for(Deal__c dealRec : [Select Id, CO_Header__c, (Select Deal__c, Is_Invoiceable__c, IsActive__c from Co_Invoice_Items__r), (Select Id, Status__c FROM Deal_Finances__r), (Select Amount__c FROM CO_Deposits__r WHERE Payment_Method__c = 'Financing' AND Amount__c != null) 
            FROM Deal__c WHERE CO_Header__c IN: coIdToFinanceAmountPaidMap.keySet()]) {
                if(!dealRec.Deal_Finances__r.isEmpty()) {
                    Decimal totalFinanceAmountPaid = coIdToFinanceAmountPaidMap.get(dealRec.CO_Header__c);
                    for(CO_Deposit__c depositRec : dealRec.CO_Deposits__r) {
                        totalFinanceAmountPaid += depositRec.Amount__c;
                    }
                    if((totalFinanceAmountPaid != 0 && dealRec.Deal_Finances__r[0].Status__c != 'Funded') 
                    || (totalFinanceAmountPaid == 0 && dealRec.Deal_Finances__r[0].Status__c == 'Funded')) {
                        dealRec.Deal_Finances__r[0].Status__c = (totalFinanceAmountPaid != 0) ? 'Funded' : 'Approved';
                        dealFinanceUpdateList.add(dealRec.Deal_Finances__r[0]);
                    }
                    if(coInvItemList.isEmpty() && !dealRec.Co_Invoice_Items__r.isEmpty()) {
                        coInvItemList.add(dealRec.Co_Invoice_Items__r[0]);
                    }
                }
            }
            DMLUtility.updateSobjectList('Deal_Finance__c', dealFinanceUpdateList);
            if(!coInvItemList.isEmpty()) {
                Map<String, Boolean> optionNameToOptionValueMap = DealService.isDealInvoiceable(coInvItemList[0].Deal__c);
                if(optionNameToOptionValueMap.get('Invoiceable') != coInvItemList[0].Is_Invoiceable__c) {
                    coInvItemList[0].Is_Invoiceable__c = optionNameToOptionValueMap.get('Invoiceable');
                    coInvItemList[0].IsActive__c = optionNameToOptionValueMap.get('Active');
                    DMLUtility.updateSobjectList('Co_Invoice_Item__c', coInvItemList);
                }
            }
        }
    }

    public static void convertAmountToDecimal() {
		for(CO_Deposit__c depositRec : CODepositNewList) {
			depositRec.Amount__c = depositRec.Amount__c != null ? depositRec.Amount__c.setScale(2, RoundingMode.HALF_UP) : 0;
        }
	}
}