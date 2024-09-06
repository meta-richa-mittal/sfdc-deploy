/** 
* Author: Tarun Khandelwal
* Since: Feb 03, 2021
* Name: ShopifySyncOrdersBatchScheduler 
* Description: Batch Apex class which sync orders to shopify store.
**/
global without sharing class ShopifySyncOrdersBatchScheduler implements Database.Batchable<Object>, Database.AllowsCallouts, Schedulable, Database.Stateful {
    
    public DateTime lastOrderFetchedAt;
    public Boolean isAPISuccessful = false;
    public DateTime nextOrderFetchAt;
    public List<String> coDepositIdList;
    public List<String> customerIdList;
    
    global ShopifySyncOrdersBatchScheduler() {
        coDepositIdList = new List<String>();
        customerIdList = new List<String>();
        lastOrderFetchedAt = Shopify_Configuration__c.getOrgDefaults().Last_Time_Orders_Fetched_At__c;
        if(lastOrderFetchedAt == null) {
            lastOrderFetchedAt = system.now().addDays(-7);
        }
    }
    
    global Iterable<Object> start(Database.BatchableContext bc) {
        String startDate = lastOrderFetchedAt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        nextOrderFetchAt = system.now();
        String endDate = nextOrderFetchAt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        List<Object> orderResponse = (List<Object>)ShopifyService.getOrdersByDate(startDate, endDate);
        if(orderResponse != null) {
            isAPISuccessful = true;
        } else {
            isAPISuccessful = false;
            orderResponse = new List<Object>();
        }
        return orderResponse;
    }
    
    global void execute(Database.batchableContext bc, List<Object> shopifyOrderObjectList) {
        List<ShopifyOrderWrapper> shopifyOrderList = (List<ShopifyOrderWrapper>) shopifyOrderObjectList;
        Set<String> shopifyIdSet = getShopifyOrderIds(shopifyOrderList);
        Set<String> existingCOWithShopifyIds = getExistingCOWithShopifyIds(shopifyIdSet);
        for(ShopifyOrderWrapper shopifyOrder : shopifyOrderList) {
        	try {
                if(existingCOWithShopifyIds.contains(shopifyOrder.shopifyId))
                    continue;
	            String customerId = ShopifyOrderService.createCustomer(shopifyOrder);
                if(customerId != null) {
                    customerIdList.add(customerId);
                }

	            String coHeaderId = ShopifyOrderService.createCO(customerId, shopifyOrder.shopifyId);
	            ShopifyOrderService.insertCOLIs(coHeaderId, shopifyOrder);
	            
                String coDepositId = ShopifyOrderService.addDeposit(coHeaderId, shopifyOrder);
                if(coDepositId != null) {
                    coDepositIdList.add(coDepositId);
                }

                ShopifyOrderService.addInternalComment(coHeaderId, shopifyOrder);
                
                existingCOWithShopifyIds.add(shopifyOrder.shopifyId);
        	} catch(Exception e) {
        		new LogService().createErrorLog('ShopifySyncOrdersBatchScheduler', 'execute()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                        String.valueOf(shopifyOrder), LogService.SHOPIFY, true, 'Error');
        	}
        }
    }

    private Set<String> getShopifyOrderIds(List<ShopifyOrderWrapper> shopifyOrderList) {
        Set<String> shopifyIdSet = new Set<String>();
        for(ShopifyOrderWrapper shopifyOrder : shopifyOrderList) {
            shopifyIdSet.add(shopifyOrder.shopifyId);
        }
        return shopifyIdSet;
    }

    private Set<String> getExistingCOWithShopifyIds(Set<String> shopifyIdSet) {
        Set<String> existingCOWithShopifyIds = new Set<String>();
        for(CO_Header__c coHeaderRecord : [SELECT Shopify_ID__c FROM CO_Header__c WHERE Shopify_ID__c IN :shopifyIdSet]) {
            existingCOWithShopifyIds.add(coHeaderRecord.Shopify_ID__c);
        }
        return existingCOWithShopifyIds;
    }
    
    global void finish(Database.batchableContext bc) {
        if(isAPISuccessful) {
            updateLastTimeOrderFetchedDate();
        }
        if(customerIdList.size() > 0) {
            syncCustomerToAccounting();
        }
        if(coDepositIdList.size() > 0) {
            syncDepositToAccounting(coDepositIdList);
        }
    }
    
    private void updateLastTimeOrderFetchedDate() {
        Shopify_Configuration__c shopifyRec = Shopify_Configuration__c.getOrgDefaults();
        shopifyRec.Last_Time_Orders_Fetched_At__c = nextOrderFetchAt;
        DMLUtility.upsertSobjectList('Shopify_Configuration__c', shopifyRec);
    }

    private void syncCustomerToAccounting() {
        if(QBUtil.isQBEnabled()) {
            // Sync customers to QB
            QBScriptUtil.syncCustomers(50, 60, 50);
        } else if(General_Configurations__c.getOrgDefaults().Enable_Xero_Accounting__c) {
            // Sync customers to Xero
            XeroScriptUtil.syncCustomers(50, 60, 50);
        }
    }
    
    private void syncDepositToAccounting(List<String> coDepositIdList) {
        List<CO_Deposit__c> coDepositList = [SELECT Id FROM CO_Deposit__c WHERE Id IN: coDepositIdList];
        if(QBUtil.isQBEnabled()) {
            for(CO_Deposit__c coDeposit : coDepositList) {
                coDeposit.availForQBJournalEntrySync__c = true;
            }
            update coDepositList;
            QBScriptUtil.syncDeposits(50, 60, 50);
        } else if(General_Configurations__c.getOrgDefaults().Enable_Xero_Accounting__c) {
            for(CO_Deposit__c coDeposit : coDepositList) {
                coDeposit.Available_For_Xero_Sync__c = true;
            }
            update coDepositList;
            XeroScriptUtil.syncCODeposit(50, 60);
        }
    }
    
    // Scheduler Execute method
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ShopifySyncOrdersBatchScheduler(), 1);
    }
}