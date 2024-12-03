/**
 * Author: Richa Mittal
 * Since: Oct 16, 2017 
 * Name: JobClockingCtrl
 * Description: Used to handle all business logic related to Job Clocking
**/
global without sharing class JobClockingCtrl {
    
    global JobClockingCtrl (NewHomePageCtrl controller){}
    public JobClockingCtrl() {}

    @RemoteAction
    global static String getServiceJobs(String technicianId) {
        return BPUtility.getEncodedString(system.JSON.serialize(JobClockingService.getServiceJobs(BPUtility.getDecodedString(technicianId))));
    }
    
    @RemoteAction
    global static String getTechnicianList(String soHeaderId) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(TechnicianService.getUnassignedTechnicianList(soHeaderId)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        }
    }
    
    @RemoteAction
    global static String assignTechnician(String soHeaderId, String technicianId, String technicianViewId) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        technicianId = BPUtility.getDecodedString(technicianId);
        technicianViewId = BPUtility.getDecodedString(technicianViewId);
        TechnicianService.assignTechnician(soHeaderId, technicianId);
        
        if(technicianViewId == null) {
            return getServiceJob(soHeaderId, technicianViewId);
        } else {
            return getServiceJob(soHeaderId, technicianViewId);
        }
    }
    
    private static String getServiceJob(String soHeaderId, String technicianId) {
        List<String> soHeaderStatusToExclude = new List<String>{ServiceJobUtil.ESTIMATE, ServiceJobUtil.READY_TO_INVOICE, ServiceJobUtil.INVOICED};
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Service_Order_Header__c> serviceJobList = 
                            [select Id, SO_Status__c, SO_Status_Ref__c, CO_Header__c, CO_Header__r.Name, CO_Header__r.CreatedDate, Transaction_Type__r.Code_Label__c, 
                                Customer_Owned_Unit__r.Formatted_Name__c, Customer_Owned_Unit__r.VIN_Number__c, 
                                CO_Header__r.Customer_Name__c, Technician_Name__c, Hrs_Logged__c,Customer_Owned_Unit__r.Year__c,Name__c,SO_Concern__c,
                                (select Id, Technician__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, Technician__r.Active__c, Start_Date_Time__c, 
                                End_Date_Time__c, Time_Spent_d__c, Time_Spent_h__c, Time_Spent_m__c, Is_Removed__c, Paused_Date_Time__c from Hours_Logged__r order by CreatedDate desc)
                                from Service_Order_Header__c 
                                where SO_Status__c NOT IN : soHeaderStatusToExclude AND Id = :soHeaderId ORDER BY SO_Status_Ref__r.Order_No__c];
        
        return BPUtility.getEncodedString(system.JSON.serialize(new JobClockingWrapper(serviceJobList[0], technicianId)));
    }
    
    @RemoteAction
    global static String removeTechnician(String soHeaderId, String technicianId, String technicianViewId) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        technicianId = BPUtility.getDecodedString(technicianId);
        technicianViewId = BPUtility.getDecodedString(technicianViewId);
        if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Hours_Logged__c> hoursLoggedListForTechnician = [select Id, Start_Date_Time__c, End_Date_Time__c, Service_Order_Header__c, Technician__c 
                                                    from Hours_Logged__c
                                                    where Technician__c = :technicianId
                                                    AND Service_Order_Header__c = :soHeaderId];
        
        Boolean isCurrentlyClocked = false;
        Boolean isPreviouslyClocked = false;
        Boolean isAssigedButNotClocked = false;
        Hours_Logged__c hoursLoggedToDel = new Hours_Logged__c();
        for(Hours_Logged__c hrsLogged: hoursLoggedListForTechnician) {
            if(!isCurrentlyClocked && hrsLogged.Start_Date_Time__c != null && hrsLogged.End_Date_Time__c == null) {
                    isCurrentlyClocked = true;
                }
                if(!isPreviouslyClocked && hrsLogged.Start_Date_Time__c != null && hrsLogged.End_Date_Time__c != null) {
                    isPreviouslyClocked = true;
                }
                
                if(!isAssigedButNotClocked && hrsLogged.Start_Date_Time__c == null && hrsLogged.End_Date_Time__c == null) {
                    isAssigedButNotClocked = true;
                    hoursLoggedToDel = hrsLogged;
                }
        }
        if(isCurrentlyClocked) {
            throw new BlackPurlException('Technician is currently clocked on.');
        } else if(isPreviouslyClocked) {
            for(Hours_Logged__c hrsLogged: hoursLoggedListForTechnician) {
                hrsLogged.Is_Removed__c = true;
            }
            if(AccessControl.ifObjectFieldIsUpdateable('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update hoursLoggedListForTechnician;
            
        } else if(isAssigedButNotClocked) {
            if(AccessControl.ifObjectIsDeletable('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete hoursLoggedToDel;
        }
        
        /*if(technicianViewId == null) {
            return getServiceJobs(null);
        } else {
            return getServiceJobs(BPUtility.getEncodedString(technicianViewId));
        }*/
        TechnicianService.populateSOHeaderTechnicianName(new Set<String>{soHeaderId});
        if(technicianViewId == null) {
            return getServiceJob(soHeaderId, technicianViewId);
        } else {
            return getServiceJob(soHeaderId, technicianViewId);
        }
    }
    
    
    @RemoteAction
    global static String getHoursLoggedBySOHeaderId(String soHeaderId) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        String query;    
        query = 'SELECT ';  
        for(String fieldsName : SOHeaderWrapper.getHoursLoggedFieldsList()) {
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';  
        }
         
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Hours_Logged__c WHERE Start_Date_Time__c != null ';
        
        query += 'AND Service_Order_Header__c =: soHeaderId ';
        
        String query1 = query + 'AND End_Date_Time__c = null ';
        String query2 = query + 'AND End_Date_Time__c != null ';
        
        query1 += 'Order by Start_Date_Time__c asc';
        query2 += 'Order by Start_Date_Time__c asc';
        
        if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Hours_Logged__c> hoursClockedList = Database.query(query1);
        List<Hours_Logged__c> hoursLoggedList = Database.query(query2);
        
        List<JobClockingWrapper.HoursLoggedInfo> sortedHoursLoggedInfoList = new List<JobClockingWrapper.HoursLoggedInfo>();
        String CurrentLoggedInUser = UserInfo.getUserId();
        
        for(Integer i=0;i<hoursClockedList.size();i++) {
            if(hoursClockedList[i].Id == CurrentLoggedInUser && hoursClockedList[i].End_Date_Time__c == null) {
                sortedHoursLoggedInfoList.add(new JobClockingWrapper.HoursLoggedInfo(hoursClockedList[i]));
                hoursClockedList.remove(i);
                break;
            }
        }
        
        for(Hours_Logged__c hoursLoggedRec : hoursClockedList) {
            sortedHoursLoggedInfoList.add(new JobClockingWrapper.HoursLoggedInfo(hoursLoggedRec));
        }
        for(Hours_Logged__c hoursLoggedRec : hoursLoggedList) {
            sortedHoursLoggedInfoList.add(new JobClockingWrapper.HoursLoggedInfo(hoursLoggedRec));
        }
        
        //system.assert(false, hoursLoggedInfoList);
        return BPUtility.getEncodedString(System.JSON.serialize(sortedHoursLoggedInfoList));
    }     
    
    @RemoteAction
    global static String getPayrollEntryForTechnician(String technicianId) {
        technicianId = BPUtility.getDecodedString(technicianId);
        List<Technician__c> technicianList = SOQLUtil.getTechnicianListWithPayroll(new Map<String, String>{'Id' => technicianId});
        String returnStr = '{"IsPayrollOn" : false, "PayrollId" : null}';
        if(technicianList.size() > 0 && technicianList[0].Payroll_Times__r.size() > 0 && technicianList[0].Payroll_Times__r[0].End_Date__c == null) {
            returnStr = '{"IsPayrollOn" : true, "PayrollId" : "' + technicianList[0].Payroll_Times__r[0].Id + '"}';
        }
        return BPUtility.getEncodedString(returnStr);
    }
    
    @RemoteAction
    global static String setPayrollForTechnician(String jsonString, String technicianId) {
        PayrollCtrl.saveClockStatus(jsonString);
        return getPayrollEntryForTechnician(technicianId);
    }
    
    @RemoteAction
    global static String setPayrollEntryForTechnician(String technicianId) {
        technicianId = BPUtility.getDecodedString(technicianId);
        List<Technician__c> technicianList = SOQLUtil.getTechnicianListWithPayroll(new Map<String, String>{'Id' => technicianId});
        String returnStr = '{"IsPayrollOn" : false}';
        if(technicianList.size() > 0 && technicianList[0].Payroll_Times__r.size() > 0) {
            returnStr = '{"IsPayrollOn" : true}';
        }
        return BPUtility.getEncodedString(returnStr);
    }
    
    @RemoteAction
    global static String clockONTechnician(String recordId, String technicianId) {
        recordId = BPUtility.getDecodedString(recordId);
        technicianId = BPUtility.getDecodedString(technicianId);
        try {
        	String objectName = String.valueOf(Id.valueOf(recordId).getSobjectType());
            TechnicianService.clockONTechnician(objectName, recordId, technicianId);
            if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
                return getServiceJobs(BPUtility.getEncodedString(technicianId));
            } else if(objectName == Constants.NAMESPACE + 'Task__c') {
                return getTaskListWithTechnicianId(BPUtility.getEncodedString(technicianId));
            }
        } catch(Exception e){
            system.assert(false, e);
        }
        return getServiceJobs(BPUtility.getEncodedString(technicianId));
    }
    
    @RemoteAction
    global static String clockOFFTechnician(String recordId, String technicianId) {
        // Deprecated
        return null;
    }
    
    
    @RemoteAction
    global static String clockOFFTechnicianWithNotes(String recordId, String technicianId, String notes) {
        recordId = BPUtility.getDecodedString(recordId);
        technicianId = BPUtility.getDecodedString(technicianId);
        notes = BPUtility.getDecodedString(notes);
        try {
            String objectName = String.valueOf(Id.valueOf(recordId).getSobjectType());
            TechnicianService.clockOFFTechnicianWithNotes(objectName, recordId, technicianId, notes);
            if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
                //return getServiceJobs(BPUtility.getEncodedString(technicianId));
                return getServiceJob(recordId, technicianId);
            } else if(objectName == Constants.NAMESPACE + 'Task__c') {
                //return getTaskListWithTechnicianId(BPUtility.getEncodedString(technicianId));
                return getTask(recordId, technicianId);
            }
        } catch(Exception e){
            system.assert(false, e);
        }
        //return getServiceJobs(BPUtility.getEncodedString(technicianId));
        return getServiceJob(recordId, technicianId);
    }
    
    @RemoteAction
    global static String getTaskList() {
        // Deprecated
        return null;
    }
    
    @RemoteAction
    global static String getTaskListWithTechnicianId(String technicianId) {
        technicianId = BPUtility.getDecodedString(technicianId);
        List<Task__c> taskList;
        if(String.isBlank(technicianId)){
            taskList = [select Id, Name__c,
                                    (select Id, Technician__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, 
                                        Technician__r.Active__c, Start_Date_Time__c, End_Date_Time__c, Time_Spent_d__c, 
                                        Time_Spent_h__c, Time_Spent_m__c, Is_Removed__c, Paused_Date_Time__c 
                                        from Hours_Logged__r 
                                        Where ( Start_Date_Time__c = TODAY
                                                OR End_Date_Time__c = TODAY)
                                        order by CreatedDate desc)
                            from Task__c order by Name__c]; // CreatedDate
        }else{
            taskList = [select Id, Name__c,
                                    (select Id, Technician__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, 
                                        Technician__r.Active__c, Start_Date_Time__c, End_Date_Time__c, Time_Spent_d__c, 
                                        Time_Spent_h__c, Time_Spent_m__c, Is_Removed__c, Paused_Date_Time__c 
                                        from Hours_Logged__r 
                                        Where Technician__c = :technicianId
                                            AND( Start_Date_Time__c = TODAY
                                                OR End_Date_Time__c = TODAY)
                                        order by CreatedDate desc)
                                    from Task__c order by Name__c]; // CreatedDate
        }
        
        List<TaskWrapper> taskWrapperList = new List<TaskWrapper>();
        for(Task__c taskObj : taskList){
            taskWrapperList.add(new TaskWrapper(taskObj, technicianId));
        }
        taskWrapperList.sort();
        return BPUtility.getEncodedString(system.JSON.serialize(taskWrapperList));
    }
    
    private static String getTask(String taskId, String technicianId) {
        List<Task__c> taskList;
        if(String.isBlank(technicianId)){
            taskList = [select Id, Name__c,
                                    (select Id, Technician__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, 
                                        Technician__r.Active__c, Start_Date_Time__c, End_Date_Time__c, Time_Spent_d__c, 
                                        Time_Spent_h__c, Time_Spent_m__c, Is_Removed__c, Paused_Date_Time__c 
                                        from Hours_Logged__r 
                                        Where ( Start_Date_Time__c = TODAY
                                                OR End_Date_Time__c = TODAY)
                                        order by CreatedDate desc)
                            from Task__c where Id = :taskId];
        }else{
            taskList = [select Id, Name__c,
                                    (select Id, Technician__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, 
                                        Technician__r.Active__c, Start_Date_Time__c, End_Date_Time__c, Time_Spent_d__c, 
                                        Time_Spent_h__c, Time_Spent_m__c, Is_Removed__c, Paused_Date_Time__c 
                                        from Hours_Logged__r 
                                        Where Technician__c = :technicianId
                                            AND( Start_Date_Time__c = TODAY
                                                OR End_Date_Time__c = TODAY)
                                        order by CreatedDate desc)
                                    from Task__c where Id = :taskId];
        }
        return BPUtility.getEncodedString(system.JSON.serialize(new TaskWrapper(taskList[0], technicianId)));
    }
    
    @RemoteAction
    global static String addEditTask(String taskId, String taskName) {
        taskId = BPUtility.getDecodedString(taskId);
        taskName = BPUtility.getDecodedString(taskName);
        
        Task__c taskObj = new Task__c();
        if(String.isNotBlank(taskId)){
            taskObj.Id = taskId;
        }
        taskObj.Name__c = taskName;
        upsert taskObj;
        //return getTaskListWithTechnicianId(null);
        return getTask(taskObj.Id, null);
    }
    

    @RemoteAction
    global static String deleteTask(String taskId) {
        taskId = BPUtility.getDecodedString(taskId);
        
        Task__c taskObj = new Task__c();
        taskObj.Id = taskId;
        delete taskObj;
        return getTaskListWithTechnicianId(null);
    }    
    
    @RemoteAction
    global static String getOtherTasks(String filterJSON) {
        filterJSON = BPUtility.getDecodedString(filterJSON);
        HoursLoggedFilterWrapper filterObj = (HoursLoggedFilterWrapper) system.JSON.deserialize(filterJSON, HoursLoggedFilterWrapper.class);
        
        String whereClause = 'where Task__c != null';
        
        if(filterObj != null) {
            if(String.isNotBlank(filterObj.Id)) {
                whereClause += ' AND Id = \''+ filterObj.Id + '\'';
            }
            if(String.isNotBlank(filterObj.TechnicianId)) {
                whereClause += ' AND Technician__c = \''+ filterObj.TechnicianId + '\'';
            }
            if(String.isNotBlank(filterObj.TaskId)) {
                whereClause += ' AND Task__c = \''+ filterObj.TaskId + '\'';
            }
            if(filterObj.FromDate != null) {
                DateTime strtDate = HomeSearchFilterInterface.getDateFromString(filterObj.FromDate);
                whereClause += ' AND Start_Date_Time__c >= '+ strtDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            }
            if(filterObj.ToDate != null) {
                DateTime endDate = HomeSearchFilterInterface.getDateFromString((filterObj.ToDate)).addDays(1);
                whereClause += ' AND End_Date_Time__c <= '+ endDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            }
        }
        
        String query = 'select Task__r.Name__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, '+
                         'Start_Date_Time__c, End_Date_Time__c, Time_Spent_h__c, Time_Spent_m__c from Hours_Logged__c ';
        query += whereClause + ' Order By Task__r.Name__c, Technician__r.Technician_Name__c, Start_Date_Time__c, End_Date_Time__c';
        List<Hours_Logged__c> hoursLoggedList = Database.query(query);
        List<TaskWrapper.OtherTaskWrapper> otherTaskList = new List<TaskWrapper.OtherTaskWrapper>();
        for(Hours_Logged__c hoursLoggedRec : hoursLoggedList){
            otherTaskList.add(new TaskWrapper.OtherTaskWrapper(hoursLoggedRec));
        }
        return BPUtility.getEncodedString(system.JSON.serialize(otherTaskList));
    }
   
    @RemoteAction
    global static String addEditTaskHoursLogged(String taskWrapperJSON) {
        taskWrapperJSON = BPUtility.getDecodedString(taskWrapperJSON);
        
        TaskWrapper.OtherTaskWrapper taskHoursLoggedObj = (TaskWrapper.OtherTaskWrapper) system.JSON.deserialize(taskWrapperJSON, TaskWrapper.OtherTaskWrapper.class);
        Hours_Logged__c hoursLoggedRec = setHoursLoggedField(taskHoursLoggedObj);
        
        if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Hours_Logged__c> existingHoursLoggedList = [Select Id from Hours_Logged__c where Technician__c =: hoursLoggedRec.Technician__c
                                                            AND (Start_Date_Time__c =: hoursLoggedRec.Start_Date_Time__c
                                                                   OR End_Date_Time__c =: hoursLoggedRec.End_Date_Time__c) 
                                                            AND Id <>: hoursLoggedRec.Id];
        if(existingHoursLoggedList.size() > 0) {
            return BPUtility.getEncodedString('[{"HasError" : true, "ErrorMsg" : "' + Label.Payroll_Already_exists_error + '"}]');
        } else {
            List<Hours_Logged__c> hoursLoggedList = TechnicianService.getcalculatedHoursLoggedList(new List<Hours_Logged__c>{hoursLoggedRec});
            upsert hoursLoggedList;
            
            HoursLoggedFilterWrapper hrsLogObj = new HoursLoggedFilterWrapper();
            hrsLogObj.Id = hoursLoggedList[0].Id;
            return getOtherTasks(BPUtility.getEncodedString(system.JSON.serialize(hrsLogObj)));
        }
    }
    
    private static Hours_Logged__c setHoursLoggedField(TaskWrapper.OtherTaskWrapper hrsLoggedObj) {
        Hours_Logged__c hoursLoggedRec = new Hours_Logged__c();
        hoursLoggedRec.Id = hrsLoggedObj.Id;
        hoursLoggedRec.Technician__c = hrsLoggedObj.TechId;
        hoursLoggedRec.Task__c = hrsLoggedObj.TaskId;
        
        DateTime dtValue = HomeSearchFilterInterface.getDateFromString(hrsLoggedObj.StartDate);
        hoursLoggedRec.Start_Date_Time__c = createDateTimeFromStr(dtValue, hrsLoggedObj.StartTime);
        hoursLoggedRec.End_Date_Time__c = createDateTimeFromStr(dtValue, hrsLoggedObj.EndTime);
        return hoursLoggedRec;
    }
    
    @RemoteAction
    global static String deleteTaskHoursLogged(String hrsLogId, String hrsLoggedFilterJSON) {
        hrsLogId = BPUtility.getDecodedString(hrsLogId);
        
        if(String.isNotBlank(hrsLogId)) {
            delete new Hours_Logged__c(Id = hrsLogId);
        }
        
        HoursLoggedFilterWrapper hrsLogObj = new HoursLoggedFilterWrapper();
        return getOtherTasks(hrsLoggedFilterJSON);
    }

    @RemoteAction
    global static String verifyTechnicianPin(String technicianId, String technicianPin) {
        technicianId = BPUtility.getDecodedString(technicianId);
        technicianPin = BPUtility.getDecodedString(technicianPin);
        return TechnicianService.verifyTechnicianPin(technicianId, technicianPin);
    }
    
    @RemoteAction
    global static String getSOStatusConfiguration() {
        return BPUtility.getEncodedString(System.JSON.serialize(ServiceJobUtil.getActiveSOStatusRecList()));
    }

    @RemoteAction
    global static void pauseTechnician(String recordId, String technicianId) {
        TechnicianService.pauseTechnician(BPUtility.getDecodedString(recordId), BPUtility.getDecodedString(technicianId));
    }

    @RemoteAction
    global static void resumeTechnician(String recordId, String technicianId) {
        TechnicianService.resumeTechnician(BPUtility.getDecodedString(recordId), BPUtility.getDecodedString(technicianId));
    }
    
    private static DateTime createDateTimeFromStr(DateTime dtValue, String timeStr) {
        if(String.isNotBlank(timeStr)) {
            List<String> timeSubStrList = timeStr.split(' ');
            if(timeSubStrList.size() > 1) {
                Integer hoursValue = Integer.valueOf(timeSubStrList[0].split(':')[0]);
                hoursValue = (hoursValue == 12) ? (hoursValue - 12) : hoursValue; 
                dtValue = dtValue.addHours(hoursValue);
                dtValue = dtValue.addMinutes(Integer.valueOf(timeSubStrList[0].split(':')[1]));
                
                if(timeSubStrList[1] == 'PM') {
                    dtValue = dtValue.addHours(12);
                }
            }
        }
        return dtValue;
    }
    
    public class HoursLoggedFilterWrapper {
        public String Id;
        public String TechnicianId;
        public String TaskId;
        public String FromDate;
        public String ToDate;
    }
}