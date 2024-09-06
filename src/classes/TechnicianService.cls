public without sharing class TechnicianService {
    public static List<SOHeaderWrapper.TechnicianWrapper> getUnassignedTechnicianList(String soHeaderId) {
    	if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Hours_Logged__c> assignedTechnicianList = [select Technician__c from Hours_Logged__c 
                                                            where Service_Order_Header__c =: soHeaderId
                                                                AND Task__c = NULL];
        Set<Id> technicianIdSet = new Set<Id>();
        for(Hours_Logged__c hourLoggedRec: assignedTechnicianList) {
            technicianIdSet.add(hourLoggedRec.Technician__c);
        }
        String query;    
        query = 'SELECT ';  
        for(String fieldsName : SOHeaderWrapper.getTechnicianFieldsList()) {
            fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';  
        }
         
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Technician__c WHERE Active__c= true ';
        query += 'AND Type__c = \'Technician\' ';
        if(soHeaderId != null) {
            query += 'AND Id NOT IN : technicianIdSet ';
        }
        
        query += 'Order by Technician_Name__c ASC';
        if(AccessControl.ifObjectFieldIsAccessible('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Technician__c> technicians = Database.query(query);
        List<SOHeaderWrapper.TechnicianWrapper> technicianObjList = new List<SOHeaderWrapper.TechnicianWrapper>();
        for(Technician__c technicianRec : technicians) {
            technicianObjList.add(new SOHeaderWrapper.TechnicianWrapper(technicianRec));
        }
        return technicianObjList;
    }
    
    public static void assignTechnician(String soHeaderId, String technicianId) {
        DMLUtility.insertSobjectList('Hours_Logged__c', new Hours_Logged__c(Technician__c = technicianId, Service_Order_Header__c = soHeaderId));
        populateSOHeaderTechnicianName(new Set<String>{soHeaderId});
    }
    
    public static String assignOrUnassignTechnician(String soHeaderId, String technicianId) {
    	if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Hours_Logged__c> hoursLoggedList = [select Start_Date_Time__c, End_Date_Time__c from Hours_Logged__c 
                                                            where Service_Order_Header__c =: soHeaderId
                                                                AND Task__c = null AND Technician__c =: technicianId
                                                                AND Is_Removed__c = false];
        
        if(hoursLoggedList.size() == 0) {
        	TechnicianService.assignTechnician(soHeaderId, technicianId);
            populateSOHeaderTechnicianName(new Set<String>{soHeaderId});
        	return 'Technician assigned successfully';
        } else {
        	for(Hours_Logged__c hoursLoggedRec: hoursLoggedList) {
        		if(hoursLoggedRec.Start_Date_Time__c != null) {
        			return 'Technician is already assigned and has hours logged on service job.';
        		}
        	}
        	
        	// delete hours logged to unassign technician
            DMLUtility.deleteSobjectList('Hours_Logged__c', hoursLoggedList);
            populateSOHeaderTechnicianName(new Set<String>{soHeaderId});
        	return 'Technician unassigned successfully';
        }
        return '';
    }
    
    public static void populateSOHeaderTechnicianName(Set<String> soHeaderIdSet) {
        if(!AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }

        List<Service_Order_Header__c> serviceOrderList = [select Id, Technician_Name__c, (select Technician__r.Technician_Name__c from Hours_Logged__r WHERE Is_Removed__c = false) from Service_Order_Header__c
                                                            where Id IN : soHeaderIdSet];
        String techniciansNames = '';
        Set<String> techNameSet;
        for(Service_Order_Header__c soHeaderRec : serviceOrderList) {
            techniciansNames = '';
            techNameSet = new Set<String>();
            for(Hours_Logged__c hlRec : soHeaderRec.Hours_Logged__r) {
                if(hlRec.Technician__r.Technician_Name__c != null) {
                    techNameSet.add(hlRec.Technician__r.Technician_Name__c);
                }    
            }

            for(String techName : techNameSet) {
                techniciansNames += techName + ';';
            }

            if(techniciansNames.length() >= 1){
                techniciansNames = techniciansNames.substring(0, techniciansNames.length() > 255 ? 255 :techniciansNames.length()-1);
            }
            soHeaderRec.Technician_Name__c = techniciansNames; 
        }
        if(serviceOrderList.size() > 0) {
            SOTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Service_Order_Header__c', serviceOrderList);
            SOTriggerHelper.isForceStopTrigger = false;
        }
    }
    
    public static List<SOHeaderWrapper.TechnicianWrapper> getAssignedTechnicianList(String soHeaderId, List<Hours_Logged__c> hoursLoggedList) {
    	if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(hoursLoggedList == null) {
        	hoursLoggedList = [select Technician__c, Technician__r.First_Name__c, Technician__r.Last_Name__c, Technician__r.Technician_Name__c, 
        													Time_Spent_d__c, Time_Spent_h__c, Time_Spent_m__c, Start_Date_Time__c, End_Date_Time__c
        													from Hours_Logged__c 
                                                            where Service_Order_Header__c =: soHeaderId
                                                                AND Task__c = null AND Is_Removed__c = false];
        }
        
        Map<String, List<Hours_Logged__c>> techIdToHoursLoggedListMap = new Map<String, List<Hours_Logged__c>>();
        List<SOHeaderWrapper.TechnicianWrapper> assignedTechnicianObjList = new List<SOHeaderWrapper.TechnicianWrapper>();
        for(Hours_Logged__c hourLoggedRec: hoursLoggedList) {
        	if(!techIdToHoursLoggedListMap.containsKey(hourLoggedRec.Technician__c)) {
        		techIdToHoursLoggedListMap.put(hourLoggedRec.Technician__c, new List<Hours_Logged__c>());
        	}
        	techIdToHoursLoggedListMap.get(hourLoggedRec.Technician__c).add(hourLoggedRec);
        }
        
        for(String techId: techIdToHoursLoggedListMap.keySet()) {
        	assignedTechnicianObjList.add(new SOHeaderWrapper.TechnicianWrapper(techIdToHoursLoggedListMap.get(techId)));
        }
        return assignedTechnicianObjList;
    }
    
    public static void clockONTechnician(String objectName, String recordId, String technicianId) {
    	List<Hours_Logged__c> hoursLoggedListToUpdate = clockOFFTechnicianforAllActiveJobs(technicianId);
        // Turn Payroll ON for that technician
        PayrollCtrl.payrollOnForTechnician(technicianId);
        
        List<Hours_Logged__c> hoursLoggedList;
            
        if(AccessControl.ifObjectFieldIsAccessible('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
            hoursLoggedList = [select Id, Service_Order_Header__c, Technician__c 
                                from Hours_Logged__c
                                where Technician__c = :technicianId
                                AND Service_Order_Header__c = :recordId
                                AND Start_Date_Time__c = null];
        } else if(objectName == Constants.NAMESPACE + 'Task__c') {
            hoursLoggedList = [select Id, Service_Order_Header__c, Technician__c 
                                from Hours_Logged__c
                                where Technician__c = :technicianId
                                AND Task__c = :recordId
                                AND Start_Date_Time__c = null];
        }
        
        Hours_Logged__c hoursLoggedRec = new Hours_Logged__c();
        if(hoursLoggedList.size() > 0) {
            hoursLoggedRec.Id = hoursLoggedList[0].Id;
        } else{
            hoursLoggedRec.Technician__c = technicianId;
            if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
                hoursLoggedRec.Service_Order_Header__c = recordId;
            } else if(objectName == Constants.NAMESPACE + 'Task__c') {
                hoursLoggedRec.Task__c = recordId;
            }
        }
        hoursLoggedRec.Start_Date_Time__c = System.now();
        hoursLoggedListToUpdate.add(hoursLoggedRec);
        DMLUtility.upsertSobjectList('Hours_Logged__c', hoursLoggedListToUpdate);
        Set<Id> hoursLoggedIdSet = new Set<Id>();
        for(Hours_Logged__c hoursLogged  : hoursLoggedListToUpdate){
            hoursLoggedIdSet.add(hoursLogged.Id);
        }
        if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
            CustomerOrderCtrl.calculateTechinicianHours(hoursLoggedIdSet, null);
            List<Service_Order_Header__c> soHeaderList = [select Work_Status__c
                                                            from Service_Order_Header__c
                                                            where Id = :recordId];
            if(soHeaderList.size() > 0 && soHeaderList[0].Work_Status__c != 'In Progress'){
                soHeaderList[0].Work_Status__c = 'In Progress';
                DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderList);
            }
        }
    }
    
    public static String clockOFFTechnicianWithNotes(String objectName, String recordId, String technicianId, String notes) {
    	List<Hours_Logged__c> hoursLoggedList;
        
        if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
            hoursLoggedList = [select Id, Start_Date_Time__c, Service_Order_Header__c, Technician__c, Technician__r.Technician_Name__c, Notes__c,
                                Original_Estimate__c, Previously_Logged__c, Remaining_Estimate_d__c, Remaining_Estimate_h__c, Remaining_Estimate_m__c,
                                Time_Spent__c, Time_Spent_d__c, Time_Spent_h__c, Time_Spent_m__c, Work_Performed_Date__c, Total_Hours__c, CreatedDate, Name,
                                Service_Order_Header__r.Status__c, Notes_Required__c, End_Date_Time__c, Calculated_Hours__c 
                                from Hours_Logged__c
                                where Technician__c = :technicianId
                                AND Service_Order_Header__c = :recordId
                                AND Start_Date_Time__c != null
                                AND End_Date_Time__c = null];
        } else if(objectName == Constants.NAMESPACE + 'Task__c') { 
            hoursLoggedList = [select Id, Start_Date_Time__c, Service_Order_Header__c, Technician__c 
                                from Hours_Logged__c
                                where Technician__c = :technicianId
                                AND Task__c = :recordId
                                AND Start_Date_Time__c != null
                                AND End_Date_Time__c = null];
        }
        
        if(hoursLoggedList.size() > 0){
            hoursLoggedList[0].End_Date_Time__c = System.now();
            Long dt1Long = hoursLoggedList[0].Start_Date_Time__c.getTime();
            Long dt2Long = hoursLoggedList[0].End_Date_Time__c.getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            Long minutes = (seconds / 60);
            Long hours = minutes / 60;
            Long days = hours / 24;
            hoursLoggedList[0].Time_Spent_d__c = days;
            hoursLoggedList[0].Time_Spent_h__c = math.mod(hours, 24);
            hoursLoggedList[0].Time_Spent_m__c = math.mod(minutes, 60);
            if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
                hoursLoggedList[0].Notes__c = notes;
            }
            DMLUtility.updateSobjectList('Hours_Logged__c', hoursLoggedList);
        }
        if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c' && hoursLoggedList.size() > 0) {
            CustomerOrderCtrl.calculateTechinicianHours(new Set<Id>{hoursLoggedList[0].Id}, null);
            return System.JSON.serialize(new SOHeaderWrapper.HoursLogged(hoursLoggedList[0]), true);
        }
        return 'Success';
    }
    
    public static List<Hours_Logged__c> clockOFFTechnicianforAllActiveJobs(String technicianId){
        List<Hours_Logged__c> hoursLoggedList = [select Id, Start_Date_Time__c, End_Date_Time__c, Service_Order_Header__c, Technician__c 
                                                    from Hours_Logged__c
                                                    where Technician__c = :technicianId
                                                    AND Start_Date_Time__c != null
                                                    AND End_Date_Time__c = null];
                                                    
        return getcalculatedHoursLoggedList(hoursLoggedList);
    }
    
    
    public static List<Hours_Logged__c> clockOFFTaskforAllTechnician(String taskId){
        List<Hours_Logged__c> hoursLoggedList = [select Id, Start_Date_Time__c, End_Date_Time__c, Service_Order_Header__c, Technician__c 
                                                    from Hours_Logged__c
                                                    where Task__c = :taskId
                                                    AND Start_Date_Time__c != null
                                                    AND End_Date_Time__c = null];
                                                    
        return getcalculatedHoursLoggedList(hoursLoggedList);
    }
    
    public static List<Hours_Logged__c> getcalculatedHoursLoggedList(List<Hours_Logged__c> hoursLoggedList){
        for(Hours_Logged__c hoursLoggedRec : hoursLoggedList){
            if(hoursLoggedRec.End_Date_Time__c == null){
                hoursLoggedRec.End_Date_Time__c = System.now();
            }
            Long dt1Long = hoursLoggedRec.Start_Date_Time__c.getTime();
            Long dt2Long = hoursLoggedRec.End_Date_Time__c.getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            Long hours = minutes / 60;
            Long days = hours / 24;
            hoursLoggedRec.Time_Spent_d__c = days;
            hoursLoggedRec.Time_Spent_h__c = math.mod(hours, 24);
            hoursLoggedRec.Time_Spent_m__c = math.mod(minutes, 60);
        }
        return hoursLoggedList;
    }
    
    public static Boolean isWorkingDayForTechnician(Technician__c techRec, String day) {
	    Boolean isWorking = false;
	    if(String.isNotBlank(techRec.Working_Days__c) && techRec.Working_Days__c.contains(day)) {
	        isWorking = true;
	    }
	    return isWorking;
    }

    public static String verifyTechnicianPin(String technicianId, String technicianPin) {
        if(AccessControl.ifObjectFieldIsAccessible('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Technician__c> technicianList = [SELECT PIN__c FROM Technician__c WHERE Id =: technicianId AND PIN__c =: technicianPin LIMIT 1];
        if(technicianList.size() == 0 ) {
            throw new BlackPurlException('Incorrect PIN for this technician.');
        }
        return 'Success';
    }
    
    public static String verifyTechnicianPinForPayrollClocking(String technicianId, String technicianPin) {
        if(AccessControl.ifObjectFieldIsAccessible('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Technician__c> technicianList = [SELECT PIN__c FROM Technician__c WHERE Id =: technicianId AND PIN__c =: technicianPin LIMIT 1];
        if(technicianList.size() == 0 ) {
            throw new BlackPurlException('Incorrect PIN for this time clocking staff.');
        }
        return 'Success';
    }
}