public without sharing class DealTriggerHelper {
    
    private static BaseIntegrationService integrationRec;
    public static Boolean isForceStopTrigger = false;
    
    public static void onBeforeUpdate(List<Deal__c> newList, Map<Id, Deal__c> oldMap) {
        populateSyncFields(newList, oldMap);
        updateConfirmedSaleDate(newList, oldMap);
    }
    
    public static void onAfterUpdate(List<Deal__c> newList, Map<Id, Deal__c> oldMap) {
        syncDealToDP360(newList);
    }
    
    public static void onAfterInsert(List<Deal__c> newList) {
        populateDealCountOnCO(newList);
    }
    
    public static void onAfterDelete(List<Deal__c> oldList) {
        deleteRelatedCOForms(oldList);
        populateDealCountOnCO(oldList);
    }

    public static void populateDealCountOnCO(List<Deal__c> dealList) {
        Set<Id> coHeaderIdSet = new Set<Id>();
        for(Deal__c dealRec : dealList) {
            coHeaderIdSet.add(dealRec.CO_Header__c);
        }
        
        Map<Id, CO_Header__c> coHeaderMapToUpdate = new Map<Id, CO_Header__c>();
        if(coHeaderIdSet.size() > 0) {
            Map<Id, CO_Header__c> coHeaderMap = new Map<Id, CO_Header__c>([SELECT Id, (SELECT Id FROM Deals__r) FROM CO_Header__c 
                                                                                    WHERE Id IN: coHeaderIdSet FOR UPDATE]);
            for(Deal__c dealRec : dealList) {
                if(!coHeaderMapToUpdate.containsKey(dealRec.CO_Header__c) && coHeaderMap.get(dealRec.CO_Header__c).Deals__r.size() <= 1) {
                    CO_Header__c coHeaderRec = coHeaderMap.get(dealRec.CO_Header__c);
                    coHeaderRec.NumberOfDeals__c = coHeaderRec.Deals__r.size();
                    coHeaderMapToUpdate.put(coHeaderRec.Id, coHeaderRec);
                } else {
                    dealRec.addError('Deal already exists for this customer order');
                }
            }
            if(coHeaderMapToUpdate.size() > 0) {
                update coHeaderMapToUpdate.values();
            }
        }
    }
    
    public static void populateSyncFields(List<Deal__c> newList, Map<Id, Deal__c> oldMap) {
        if(QBUtil.isQBEnabled()) {
            QBSyncFlagService.manageLienPayoutSyncFlag(newList, oldMap);
        } else {
            try {
               integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
               IntegrationSyncFlagService.manageLienPayoutSyncFlag(new List<BaseIntegrationService>{integrationRec}, newList, oldMap);
            } catch(Exception e) {
            }
        }
        
        if(DP360Service.isDP360Enabled()) {
            DP360SyncFlagService.manageDealSyncFlag(newList, oldMap);
        }
    }
    
    public static void syncDealToDP360(List<Deal__c> newList) {
        Set<Id> validDealIdSet = new Set<Id>();
        for(Deal__c dealRec : newList) {
            if(dealRec.Available_For_DP360_Sync__c) {
                validDealIdSet.add(dealRec.Id);
            }
        }
        if(validDealIdSet.size() > 0 && DP360Service.isDP360Enabled()) {
            Database.executeBatch(new DP360LeadBatch(validDealIdSet), 10);
        }
    }
    
    private static void deleteRelatedCOForms(List<Deal__c> oldList) {
        Set<Id> dealIdSet = new Set<Id>();
        for(Deal__c dealRec : oldList) {
            dealIdSet.add(dealRec.Id);
        }
        dealIdSet.remove(null);
        COFormService.deleteCOFormUsingSectionId(dealIdSet);
    }

    private static void updateConfirmedSaleDate(List<Deal__c> newList, Map<Id, Deal__c> oldMap) {
        Boolean needToQueryDealDeposits = false;
        for(Deal__c dealRec: newList) {
            if((dealRec.Confirmed_Sale_Date__c != null && dealRec.Status__c == 'Quotation' && 
                ((oldMap.get(dealRec.Id).Status__c == 'In Progress' || oldMap.get(dealRec.Id).Status__c == 'Approved')))) {
                    needToQueryDealDeposits = true;
                    break;
            }
        }
        
        List<CO_Deposit__c> coDepositList = !needToQueryDealDeposits ? new List<CO_Deposit__c>() : 
                                            [SELECT Deal__c, Amount__c, Payment_Date__c FROM CO_Deposit__c WHERE Deal__c IN :newList];
        Map<String, Decimal> dealIdToDepositAmountMap = DealService.getDealIdToDepositAmountMap(coDepositList);
        DealService.updateConfirmedSaleDate(newList, oldMap, dealIdToDepositAmountMap, false);
    }
}