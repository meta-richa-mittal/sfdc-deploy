public without sharing class JobClockingService {
    
    public static Map<String, Integer> serviceJobStatusToSortingOrderMap = new Map<String, Integer>();
    private static List<String> soHeaderStatusToExclude = new List<String>{ServiceJobUtil.ESTIMATE, ServiceJobUtil.READY_TO_INVOICE, ServiceJobUtil.INVOICED};
    private static List<String> soHeaderStatusWithFixedSortOrder = new List<String>{ServiceJobUtil.NEW_JOB, ServiceJobUtil.JOB_COMPLETE};

    public static List<JobClockingWrapper> getServiceJobs(String technicianId) {
        populateStatusSortOrderMap();

        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Header__c> serviceJobList = 
                            [select Id, SO_Status__c, SO_Status_Ref__c, CO_Header__c, CO_Header__r.Name, CO_Header__r.CreatedDate, Transaction_Type__r.Code_Label__c, 
                                Customer_Owned_Unit__r.Formatted_Name__c, Customer_Owned_Unit__r.VIN_Number__c, 
                                CO_Header__r.Customer_Name__c, Technician_Name__c, Hrs_Logged__c,Customer_Owned_Unit__r.Year__c,Name__c,SO_Concern__c,
                                (select Id, Technician__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, Technician__r.Active__c, Start_Date_Time__c, 
                                End_Date_Time__c, Time_Spent_d__c, Time_Spent_h__c, Time_Spent_m__c, Is_Removed__c, Paused_Date_Time__c from Hours_Logged__r order by CreatedDate desc)
                                from Service_Order_Header__c 
                                where SO_Status__c NOT IN : soHeaderStatusToExclude];
        
        List<JobClockingWrapper> jobClockingWrapperList = new List<JobClockingWrapper>();
        for(Service_Order_Header__c serviceJob: serviceJobList) {
            JobClockingWrapper jobClockingWrapperRecord = new JobClockingWrapper(serviceJob, technicianId);
            jobClockingWrapperList.add(jobClockingWrapperRecord);
        }
        
        if(technicianId == null) {
            jobClockingWrapperList = sortServiceJobsForDefaultView(jobClockingWrapperList);
        } else {
            jobClockingWrapperList = sortServiceJobsForTechnicianView(jobClockingWrapperList, technicianId);
        }
        return jobClockingWrapperList;
    }

    public static List<JobClockingWrapper> sortServiceJobsForDefaultView(List<JobClockingWrapper> serviceJobList) {
        List<JobClockingWrapper> serviceJobSortedList = new List<JobClockingWrapper>();
        
        List<JobClockingWrapper> currentlyClockedServiceJobList = new List<JobClockingWrapper>();
        List<JobClockingWrapper> techniciansAssignedServiceJobList = new List<JobClockingWrapper>();
        
        for(Integer i=0;i<serviceJobList.size();i++) {
            for(JobClockingWrapper.TechnicianInfo tech: serviceJobList[i].TechnicianList) {
                if(tech.IsClocked) {
                    currentlyClockedServiceJobList.add(serviceJobList[i]);
                    serviceJobList.remove(i);
                    i--;
                    break;
                }
            }
        }
        
        
        for(Integer i=0;i<serviceJobList.size();i++) {
            if(serviceJobList[i].TechnicianList.size() > 0) {
                techniciansAssignedServiceJobList.add(serviceJobList[i]);
                serviceJobList.remove(i);
                i--;
            }
        }
        
        currentlyClockedServiceJobList.sort();
        techniciansAssignedServiceJobList.sort();
        serviceJobList.sort();
        
        serviceJobSortedList.addAll(currentlyClockedServiceJobList);
        serviceJobSortedList.addAll(techniciansAssignedServiceJobList);
        serviceJobSortedList.addAll(serviceJobList);
        return serviceJobSortedList;
    }
    
    public static List<JobClockingWrapper> sortServiceJobsForTechnicianView(List<JobClockingWrapper> serviceJobList, String techId) {
        List<JobClockingWrapper> serviceJobSortedList = new List<JobClockingWrapper>();
        
        List<JobClockingWrapper> currentlyClockedServiceJobList = new List<JobClockingWrapper>();
        List<JobClockingWrapper> technicianAssignedServiceJobList = new List<JobClockingWrapper>();
        List<JobClockingWrapper> otherTechnicianAssignedServiceJobList = new List<JobClockingWrapper>();
        for(Integer i=0;i<serviceJobList.size();i++) {
            for(JobClockingWrapper.TechnicianInfo tech: serviceJobList[i].TechnicianList) {
                if(tech.IsClocked && tech.TechnicianId == techId) {
                    currentlyClockedServiceJobList.add(serviceJobList[i]);
                    serviceJobList.remove(i);
                    i--;
                    break;
                }
            }
            if(currentlyClockedServiceJobList.size() == 1) {
                break;
            }
        }
        for(Integer i=0;i<serviceJobList.size();i++) {
            for(JobClockingWrapper.TechnicianInfo tech: serviceJobList[i].TechnicianList) {
                if(tech.TechnicianId == techId) {
                    technicianAssignedServiceJobList.add(serviceJobList[i]);
                    serviceJobList.remove(i);
                    i--;
                    break;
                }
            }
        }
        for(Integer i=0;i<serviceJobList.size();i++) {
            if(!serviceJobList[i].TechnicianList.isEmpty()) {
                otherTechnicianAssignedServiceJobList.add(serviceJobList[i]);
                serviceJobList.remove(i);
                i--;
            }
        }
        
        technicianAssignedServiceJobList.sort();
        serviceJobList.sort();
        otherTechnicianAssignedServiceJobList.sort();
        
        serviceJobSortedList.addAll(currentlyClockedServiceJobList);
        serviceJobSortedList.addAll(technicianAssignedServiceJobList);
        serviceJobSortedList.addAll(serviceJobList);
        serviceJobSortedList.addAll(otherTechnicianAssignedServiceJobList);
        return serviceJobSortedList;
    }

    private static void populateStatusSortOrderMap() {
        String defaultClcokedOnStatus;
        Integer sortOrder = 0;
        if(!AccessControl.ifObjectFieldIsAccessible('SO_Status__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<SO_Status__c> soStatusList = [Select Name__c, Order_No__c, Default_Clock_ON_Status__c FROM SO_Status__c WHERE Is_Active__c = true AND Name__c NOT IN: soHeaderStatusToExclude AND 
                                Name__c NOT IN: soHeaderStatusWithFixedSortOrder ORDER BY Order_No__c ASC];
		for(SO_Status__c soStatusRec : soStatusList) {
            if(soStatusRec.Default_Clock_ON_Status__c) {
                defaultClcokedOnStatus = soStatusRec.Name__c;
                break;
            }
        }
        if(String.isNotBlank(defaultClcokedOnStatus)) {
            serviceJobStatusToSortingOrderMap.put(defaultClcokedOnStatus, ++sortOrder);
        }
        for(SO_Status__c soStatusRec : soStatusList) {
            if(!soStatusRec.Default_Clock_ON_Status__c) {
                serviceJobStatusToSortingOrderMap.put(soStatusRec.Name__c, ++sortOrder);
            }
        }
        for(String statusVal: soHeaderStatusWithFixedSortOrder) {
            serviceJobStatusToSortingOrderMap.put(statusVal, ++sortOrder);
        }
    }
}