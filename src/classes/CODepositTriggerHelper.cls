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
    }

    public static void populatesAccountingSyncFields(){
    	if(QBUtil.isQBEnabled()) {
			CODepositNewList = QBSyncFlagService.manageCODepositJESyncFlag(CODepositNewList);
		} else {
        	integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
        	if(integrationRec != null) {
                IntegrationSyncFlagService.manageCODepositSyncFlag(new List<BaseIntegrationService>{integrationRec}, CODepositNewList);
        	}
        }
    }
    
    public static void setCODepositDataForAccountSync(){
    	Set<Id> setCODepositIds = new Set<Id>();
    	for(CO_Deposit__c CODeposit : CODepositNewList){ 
    		if(QBUtil.isQBEnabled()) {
    			if(CODeposit.availForQBJournalEntrySync__c) {
    				setCODepositIds.add(CODeposit.Id);
    			}
    		} else if(integrationRec != null) {
    	    	if(CODeposit.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.CO_DEPOSIT).Sync_Flag_API_Name__c) != null && 
	    			Boolean.valueOf(CODeposit.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.CO_DEPOSIT).Sync_Flag_API_Name__c))) {
    	        	setCODepositIds.add(CODeposit.Id);
    	    	}
        	}
    	}

    	if(setCODepositIds.size() > 0) {
    		if(QBUtil.isQBEnabled()) {
    			CODepositJournalEntryService.syncCODeposits(setCODepositIds);
    		} else {
    			IntegrationBatchService.initiateBatch(setCODepositIds, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.CO_DEPOSIT);
    		}
    	}
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
}