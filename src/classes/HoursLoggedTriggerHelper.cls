/**
 * Author: Nidhi Sharma
 * Since: June 07, 2019
 * Name: HoursLoggedTriggerHelper
 * Description: Trigger Helper for Hours Logged object
**/
public without sharing class HoursLoggedTriggerHelper {
    
    public static Boolean isForceStopTrigger = false;    
    public static Boolean preventOnAccountingSync = false;
    private static BaseIntegrationService integrationRec;
    
    public static void beforeInsert(List<Hours_Logged__c> newList) {
        populateCostingRate(newList, null);
        if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
        	setAccountingSyncFlag(newList, null);
        }
    }
    
    public static void afterInsert(List<Hours_Logged__c> newList) {
		updateServiceJobLaborCosting(newList);
        if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
        	syncToAccounting(newList);
        }
    }
    
    public static void beforeUpdate(List<Hours_Logged__c> newList, Map<Id, Hours_Logged__c> oldMap) {
        populateCostingRate(newList, oldMap);
        populateOldHourAndCost(newList, oldMap);
        if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
        	setAccountingSyncFlag(newList, oldMap);
        }
    }
    
    public static void afterUpdate(List<Hours_Logged__c> newList, Map<Id, Hours_Logged__c> oldMap) {
		updateServiceJobLaborCosting(newList);
        if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
        	syncToAccounting(newList);
        }
    }
	
	public static void beforeDelete(List<Hours_Logged__c> oldList) {
        for(Hours_Logged__c hrsLoggedRec : oldList) {
        	if(hrsLoggedRec.End_Date_Time__c != null && hrsLoggedRec.Service_Order_Header__c != null) {
        		hrsLoggedRec.addError('Cannot delete hours logged record, please update "Is Removed" flag to true in order to avoid any entry.');
        	}
        }
    }
    
    public static void updateServiceJobLaborCosting(List<Hours_Logged__c> hrsLoggedList) {
    	if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
    	Set<String> soHeaderIdSet = new Set<String>();
    	Map<Id, Hours_Logged__c> hrsLoggedListOnCompletedJob = new Map<Id, Hours_Logged__c>([Select Id, Service_Order_Header__c from Hours_Logged__c where Id IN: hrsLoggedList AND 
    								Service_Order_Header__r.Work_Status__c =: Constants.SERVICE_ORDER_STATUS_TO_CHECKOUT]);
    	for(Hours_Logged__c hrsLoggedRec : hrsLoggedList) {
    		if(hrsLoggedListOnCompletedJob.containsKey(hrsLoggedRec.Id)) {
    			soHeaderIdSet.add(hrsLoggedRec.Service_Order_Header__c);
    		}
    	}
    	soHeaderIdSet.remove(null);
	        ServiceJobService.updateLabourCostingOnSOLIBasedOnTechHoursCosting(soHeaderIdSet);
    	}
    }
    
    public static void populateCostingRate(List<Hours_Logged__c> newList, Map<Id, Hours_Logged__c> oldMap) {
        Set<Id> technicianIdSet = new Set<Id>();
        for(Hours_Logged__c hoursLoggedRec : newList) {
            if(oldMap == null || (hoursLoggedRec.Technician__c != oldMap.get(hoursLoggedRec.Id).Technician__c)) {
                technicianIdSet.add(hoursLoggedRec.Technician__c);
            }
        }
        technicianIdSet.remove(null);
        
        if(technicianIdSet.size() > 0) {
            Map<Id, Technician__c> technicianIdToRecMap = new Map<Id, Technician__c>([SELECT Labour_Cost_Per_Hour__c FROM Technician__c WHERE Id IN: technicianIdSet]);
        
            for(Hours_Logged__c hoursLoggedRec : newList) {
                if((oldMap == null || hoursLoggedRec.Technician__c != oldMap.get(hoursLoggedRec.Id).Technician__c) 
                        && technicianIdToRecMap.containsKey(hoursLoggedRec.Technician__c)) {
                    hoursLoggedRec.Costing_Rate__c = technicianIdToRecMap.get(hoursLoggedRec.Technician__c).Labour_Cost_Per_Hour__c != null ? 
                                        technicianIdToRecMap.get(hoursLoggedRec.Technician__c).Labour_Cost_Per_Hour__c : 0;
                }
            }
        }
    }
    
    public static void populateOldHourAndCost(List<Hours_Logged__c> newList, Map<Id, Hours_Logged__c> oldMap) {
        for(Hours_Logged__c hoursLoggedRec : newList) {
            if(oldMap.get(hoursLoggedRec.Id).End_Date_Time__c != null && 
            	(hoursLoggedRec.Costing_Rate__c != oldMap.get(hoursLoggedRec.Id).Costing_Rate__c || 
                hoursLoggedRec.Total_Hours__c != oldMap.get(hoursLoggedRec.Id).Total_Hours__c)) {
                hoursLoggedRec.Old_Costing_Rate__c = oldMap.get(hoursLoggedRec.Id).Costing_Rate__c;
                hoursLoggedRec.Old_Total_Hours__c = oldMap.get(hoursLoggedRec.Id).Total_Hours__c;
            }
        }
    }
    
    public static void setAccountingSyncFlag(List<Hours_Logged__c> newList, Map<Id, Hours_Logged__c> oldMap) {
        if(QBUtil.isQBEnabled()) {
            QBSyncFlagService.manageHoursLoggedSyncFlag(newList, oldMap);
        } else {
            try {
               integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
               IntegrationSyncFlagService.manageHoursLoggedSyncFlag(new List<BaseIntegrationService>{integrationRec}, newList, oldMap);
            } catch(Exception e) {
            
            }
        }
    }
    
    public static void syncToAccounting(List<Hours_Logged__c> newList) {
        Set<Id> validHoursLoggedIdSet = new Set<Id>();
        for(Hours_Logged__c hoursLoggedRec : newList){
            if(QBUtil.isQBEnabled() && hoursLoggedRec.Available_For_QB_Sync__c) { 
                validHoursLoggedIdSet.add(hoursLoggedRec.Id);
            } else if(integrationRec != null) {
                if(hoursLoggedRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.HOURS_LOGGED).Sync_Flag_API_Name__c) != null && 
                    Boolean.valueOf(hoursLoggedRec.get(integrationRec.integrationEntityNameToRecMap.get(IntegrationUtility.HOURS_LOGGED).Sync_Flag_API_Name__c))) {
                    validHoursLoggedIdSet.add(hoursLoggedRec.Id);
                }
            }
        }
        if(validHoursLoggedIdSet.size() > 0) {
            if(QBUtil.isQBEnabled()) {
                QBHoursLoggedService.syncHoursLogged(validHoursLoggedIdSet);
            } else {
                IntegrationBatchService.initiateBatch(validHoursLoggedIdSet, new List<BaseIntegrationService>{integrationRec}, IntegrationUtility.HOURS_LOGGED);
            }
        }
    }
}