global without sharing class SyncCustomerBatch extends BaseSyncingBatch {
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Account', AccountingCustomer.fieldsList(), IntegrationUtility.CUSTOMER));
    }
    
    global void execute(Database.batchableContext bc, List<Account> listCustomers) {
        List<AccountingCustomer> accountingCustomerList = new List<AccountingCustomer>();
        for(Account customer : listCustomers) {
        	String accId = String.valueOf(customer.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.CUSTOMER).Integration_Id_API_Name__c));
        	accountingCustomerList.add(new AccountingCustomer(customer));
        }
       if(accountingCustomerList.size() > 0) {
            Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
            if(QBUtil.isQBEnabled()) {
                integrationEntityNameToActionMap.put(IntegrationUtility.CUSTOMER, IntegrationUtility.UPDATE_ACTION);
                for(AccountingCustomer customerObj : accountingCustomerList) {
                    this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingCustomer>{customerObj}, (List<SObject>) sobjctListToUpdate, 
                    IntegrationUtility.CUSTOMER, integrationEntityNameToActionMap));
                }
            } else {
                integrationEntityNameToActionMap.put(IntegrationUtility.CONTACTS, IntegrationUtility.UPDATE_ACTION);
                this.webserviceLogs = (integrationInstanceList[0].sync(accountingCustomerList, (List<SObject>) sobjctListToUpdate, 
	                                            IntegrationUtility.CUSTOMER, integrationEntityNameToActionMap));
            }
       } 
   	}
        
    global override void finish(Database.batchableContext bc){
    	finishAction();
    	
    }
}