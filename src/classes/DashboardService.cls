/** 
* Author: Manoj Sharma
* Since: May 13, 2020 
* Name: DashboardService 
* Description: Apex class which contains all methods related to dashboard.
**/
public without sharing class DashboardService {
	
	/**
    * Name: getServiceJobList
    * Desc: To get Dashboard ServiceJob Wrapper based on filter Json String
    * @param:  String filter Json String
    * @return: DashboardServiceJobWrapper records list
    **/
    public static List<DashboardServiceJobWrapper> getServiceJobList(String filterJsonStr) {
		DashboardServiceJobWrapper.FilterWrapper filterWrapperObj = (DashboardServiceJobWrapper.FilterWrapper)system.JSON.deserialize(filterJsonStr, DashboardServiceJobWrapper.FilterWrapper.class);
        
		List<Event__c> eventList = DashboardSOQLUtil.getAppointmentList(getFilterClause(filterWrapperObj));
		List<Hours_Logged__c> hoursLogList = DashboardSOQLUtil.getHoursLogList(getFilterClause(filterWrapperObj));
		Set<Id> soHeaderIdSet = new Set<Id>();
		soHeaderIdSet = getSOHeaderIdSet(eventList, soHeaderIdSet);
		soHeaderIdSet = getSOHeaderIdSet(hoursLogList, soHeaderIdSet);
		Map<Id, List<Event__c>> soHeaderIdToEventListMap = getSOHeaderIdToSObjectListMap(eventList);
		Map<Id, List<Hours_Logged__c>> soHeaderIdToHoursLogListMap = getSOHeaderIdToSObjectListMap(hoursLogList);

		List<DashboardServiceJobWrapper> dashboardServiceJobsList = new List<DashboardServiceJobWrapper>();
		List<DashboardServiceJobWrapper> clockedOnServiceJobsList = new List<DashboardServiceJobWrapper>();
		List<Service_Order_Header__c> soHeaderList = DashboardSOQLUtil.getSOHeaderByIdSet(soHeaderIdSet);
		DashboardServiceJobWrapper serviceJobWrapperObj;
		for(Service_Order_Header__c soHeaderRec : soHeaderList) {
			serviceJobWrapperObj = new DashboardServiceJobWrapper(soHeaderRec, soHeaderIdToEventListMap, soHeaderIdToHoursLogListMap);
			if(serviceJobWrapperObj.IsTechnicianClocked) {
				clockedOnServiceJobsList.add(serviceJobWrapperObj);
			} else {
				dashboardServiceJobsList.add(serviceJobWrapperObj);
			}
		}
		clockedOnServiceJobsList.addAll(dashboardServiceJobsList);
    	return clockedOnServiceJobsList;
	}

	private static String getFilterClause(DashboardServiceJobWrapper.FilterWrapper filterWrapperObj) {
		String filterClause = '';
		if(String.isNotBlank(filterWrapperObj.StatusFilter)) {
			if(ServiceJobUtil.jobStatusGroupToExcludedValueMap.containsKey(filterWrapperObj.StatusFilter)) {
				filterClause += ' WHERE Service_Order_Header__r.SO_Status__c NOT IN (\'';
				filterClause += String.join(ServiceJobUtil.jobStatusGroupToExcludedValueMap.get(filterWrapperObj.StatusFilter), '\',\'') + '\')';
			} else {
				filterClause += ' WHERE Service_Order_Header__r.SO_Status__c = \'' + filterWrapperObj.StatusFilter + '\'';
			}
		}
		if(filterWrapperObj.JobTypeFilterList.size() > 0 && filterWrapperObj.JobTypeFilterList[0] != 'All job types') {
			filterClause += (String.isNotBlank(filterClause) ? ' AND' : ' WHERE');
			filterClause += ' Service_Order_Header__r.Transaction_Type__r.Code_Label__c IN (\'' + String.join(filterWrapperObj.JobTypeFilterList, '\',\'') + '\')';
		}
		return filterClause;
	}

	private static Set<Id> getSOHeaderIdSet(List<SObject> sObjectList, Set<Id> soHeaderIdSet) {
		for(SObject sObjectRec : sObjectList) {
			soHeaderIdSet.add((ID)sObjectRec.get('Service_Order_Header__c'));
		}
		return soHeaderIdSet;
	}

	private static Map<Id, List<SObject>> getSOHeaderIdToSObjectListMap(List<SObject> sObjectList) {
		Map<Id, List<SObject>> soHeaderIdToSObjectListMap = new Map<Id, List<SObject>>();
		for(SObject sObjectRec : sObjectList) {
			if(soHeaderIdToSObjectListMap.containsKey((ID)sObjectRec.get('Service_Order_Header__c'))) {
				soHeaderIdToSObjectListMap.get((ID)sObjectRec.get('Service_Order_Header__c')).add(sObjectRec);
			} else {
				soHeaderIdToSObjectListMap.put((ID)sObjectRec.get('Service_Order_Header__c'), new List<SObject>{sObjectRec});
			}
		}
		return soHeaderIdToSObjectListMap;
	}

	/**
    * Name: getFormattedTodaysDate
    * Desc: To get todays day and date
    * @param: 
    * @return: day and date string
    **/
	public static String getFormattedTodaysDate() {
		return (System.now().format('EEEE') + ', ' + System.now().format(Constants.localeToDateMonthFmt.get('en_AU')));
	}
 
	public static List<DashboardServiceJobWrapper.JobTypeWrapper> getJobTypeList() {
		List<DashboardServiceJobWrapper.JobTypeWrapper> jobTypeList = new List<DashboardServiceJobWrapper.JobTypeWrapper>();
		List<Transaction_Type__c> ttList = SOQLUtil.getTransactionTypesWithProvider(new List<Id>());
		ttList = ServiceJobTypeService.sortJobTypes(ttList);
		for(Integer index = 0; index < ttList.size(); index++) {
			if(ttList[index].Type__c != 'Quote') {
				jobTypeList.add(new DashboardServiceJobWrapper.JobTypeWrapper(index, ttList[index].Code_Label__c, true));
			}
		}
		return jobTypeList;
	}
}