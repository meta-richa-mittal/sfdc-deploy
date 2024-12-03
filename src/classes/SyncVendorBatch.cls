global without sharing class SyncVendorBatch extends BaseSyncingBatch {
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(getBaseQuery('Account', AccountingVendor.fieldsList(), IntegrationUtility.VENDOR));
    }

    global void execute(Database.batchableContext bc, List<Account> listVendors) {
        List<AccountingVendor> accountingVendorList = new List<AccountingVendor>();
        for(Account vendor : listVendors) {
        	String accId = String.valueOf(vendor.get(integrationInstanceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.VENDOR).Integration_Id_API_Name__c));
        		accountingVendorList.add(new AccountingVendor(vendor));
        	}	
        	if(accountingVendorList.size() > 0) {
        		//Note: We are only performing Update Action for Xero, Since POST works for Create and Update both. 
        		Map<String, String> integrationEntityNameToActionMap = new Map<String, String>();
                if(QBUtil.isQBEnabled()) {
                    integrationEntityNameToActionMap.put(IntegrationUtility.VENDOR, IntegrationUtility.UPDATE_ACTION);
                    for(AccountingVendor vendorObj : accountingVendorList) {
                        this.webserviceLogs = (integrationInstanceList[0].sync(new List<AccountingVendor>{vendorObj}, (List<SObject>) sobjctListToUpdate, 
                        IntegrationUtility.VENDOR, integrationEntityNameToActionMap));
                    }
                } else {
                    integrationEntityNameToActionMap.put(IntegrationUtility.CONTACTS, IntegrationUtility.UPDATE_ACTION);
                    this.webserviceLogs = (integrationInstanceList[0].sync(accountingVendorList, (List<SObject>) sobjctListToUpdate, 
                                            IntegrationUtility.VENDOR, integrationEntityNameToActionMap));
                }
        	}
    	}
 
    global override void finish(Database.batchableContext bc) {
        finishAction();   
    }
}