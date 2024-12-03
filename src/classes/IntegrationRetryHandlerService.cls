/**
 * Author: Nikhil Kumar Srivastava
 * Since: May 10, 2019
 * Name: IntegrationRetryHandlerService
**/
public without sharing class IntegrationRetryHandlerService {
	
	public Set<Id> recordsToProcessIdSet = new Set<Id>();
	public List<Object> failedEntititesList;
    public String syncEntity;
    public Integer retrialAttemptNumber;
    public BaseIntegrationService integrationRec;
    
    public IntegrationRetryHandlerService(List<Object> failedEntititesList, String syncEntity, BaseIntegrationService integrationRec) {
        this.failedEntititesList = failedEntititesList;
        this.syncEntity = syncEntity;
        this.integrationRec = integrationRec;
    }
    
    public void executeRetry(Integer retrialAttemptNumber) {
        this.retrialAttemptNumber = retrialAttemptNumber;
        if(retrialAttemptNumber != null && retrialAttemptNumber <= IntegrationUtility.XERO_MAX_RETRY_COUNT) {
        	if(integrationRec != null) {
        		if(this.syncEntity == IntegrationUtility.CUSTOMER) {
		        	executeCustomerRetry();
		        } else if(this.syncEntity == IntegrationUtility.VENDOR) {
		            executeVendorRetry();
		        }
        	}
        }
    }
    
    private void executeCustomerRetry() {
    	Set<Id> customerIdSet = new Set<Id>();
    	Map<Id, String> sfIdToAccountingIdMap = new Map<Id, String>();
    	for(Object cusObj : failedEntititesList) {
        	AccountingCustomer acc = (AccountingCustomer)cusObj;
        	String whereQueryStr = 'ContactNumber=="' + acc.CustomerNumber + '"';
        	String customerAccId = XeroService.getContactsXeroId(whereQueryStr, integrationRec.integrationConfigRec);
            if(customerAccId != null || String.isNotBlank(customerAccId)){
            	sfIdToAccountingIdMap.put(acc.Id, customerAccId);
            } else {
            	customerIdSet.add(acc.Id);
            }
        }
        if(sfIdToAccountingIdMap.size() > 0){
        	populateAccountingId(sfIdToAccountingIdMap, IntegrationUtility.CUSTOMER);
        }
        addDelayToBatch(); 
        if(customerIdSet.size() > 0) {
        	IntegrationBatchService.initiateBatch(customerIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.CUSTOMER, retrialAttemptNumber+1);
        }
    }
    
    
    private void executeVendorRetry() {
    	Set<Id> vendorIdSet = new Set<Id>();
    	Map<Id,String> sfIdToAccountingIdMap = new Map<Id,String>();
    	for(Object cusObj : failedEntititesList) {
        	AccountingVendor acc = (AccountingVendor)cusObj;
        	String whereQueryStr = 'ContactNumber== "' + acc.VendorNumber + '"';
        	String vendorAccId = XeroService.getContactsXeroId(whereQueryStr, integrationRec.integrationConfigRec);
            if(vendorAccId != null || String.isNotBlank(vendorAccId)){
            	sfIdToAccountingIdMap.put(acc.Id, vendorAccId);
            } else {
            	vendorIdSet.add(acc.Id);
            }
        }
        if(sfIdToAccountingIdMap.size() > 0){
        	populateAccountingId(sfIdToAccountingIdMap, IntegrationUtility.VENDOR);
        }
        addDelayToBatch(); 
        if(vendorIdSet.size() > 0) {
        	IntegrationBatchService.initiateBatch(vendorIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.VENDOR, retrialAttemptNumber+1);
        }
    }
    
    public static void addDelayToBatch() {
        Integer delayInMilliseconds = 6000;
        BPUtility.sleepSystem(delayInMilliseconds);
    }
    
    public static void populateAccountingId(Map<Id, String> sfIdToAccountingIdMap, String entityName) {
    	if(entityName == IntegrationUtility.CUSTOMER) {
    		for(Id accId : sfIdToAccountingIdMap.keyset()) {
    			Account accUpdate = new Account(Id = accId);
    			accUpdate.Xero_Customer_Accounting_Id__c = sfIdToAccountingIdMap.get(accId); 
    			accUpdate.Available_For_Xero_Customer_Sync__c = false; 
				DMLUtility.updateSobjectList('Account', accUpdate);
    			//accUpdate.(baseIntegrationServiceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.CUSTOMER).Sync_Flag_API_Name__c); 
    		}
    	} else if(entityName == IntegrationUtility.CUSTOMER) {
    		for(Id accId : sfIdToAccountingIdMap.keyset()) {
    			Account accUpdate = new Account(Id = accId);
    			accUpdate.Xero_Vendor_Accounting_Id__c = sfIdToAccountingIdMap.get(accId); 
    			accUpdate.Available_For_Xero_Vendor_Sync__c = false; 
				DMLUtility.updateSobjectList('Account', accUpdate);
    		}
    	}
    } 
}