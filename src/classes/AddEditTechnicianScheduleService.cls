public class AddEditTechnicianScheduleService {

    public static TechnicianDetailWrapper getTechnicianById(String technicianRecId) {
    	if(AccessControl.ifObjectFieldIsAccessible('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Technician__c> technicianRecList = SOQLUtil.getTechnicianListByFieldName(new Map<String, String>{'Id' => technicianRecId});
        TechnicianDetailWrapper technicianDetailObj;
        if(technicianRecList.size() > 0) {
        	technicianDetailObj = new TechnicianDetailWrapper(technicianRecList[0]);
        }
        return technicianDetailObj;
    }
    
    public static void saveTechnicianDetail(String technicianDetailJSON) {
    	if(AccessControl.ifObjectFieldIsCreateable('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('Technician__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        TechnicianDetailWrapper technicianDetailObj = (TechnicianDetailWrapper)System.JSON.deserialize(technicianDetailJSON, TechnicianDetailWrapper.class);
        Technician__c technicianRec = setTechnicianFields(technicianDetailObj);
        DMLUtility.upsertSobjectList('Technician__c', technicianRec);
    }
    
    private static Technician__c setTechnicianFields(TechnicianDetailWrapper technicianDetailObj) {
    	Technician__c technicianRec = new Technician__c(Id = technicianDetailObj.Id);
    	technicianRec.Type__c = (technicianDetailObj.IsTechnician != null && technicianDetailObj.IsTechnician) ? Constants.TECHNICIAN : null;
    	
		if(!technicianDetailObj.IsLicensedUser) {
    		technicianRec.First_Name__c = technicianDetailObj.FirstName;
	        technicianRec.Last_Name__c = technicianDetailObj.LastName;
	        technicianRec.Technician_Name__c = technicianRec.First_Name__c + ' ' + technicianRec.Last_Name__c;
    	}
    	
        if(technicianDetailObj.LabourCostPerHour != null && technicianDetailObj.LabourCostPerHour < 0) {
        	throw new BlackpurlException('Labor cost should be greater than or equal to 0.');
        }
        if(String.isNotBlank(technicianDetailObj.PIN) && (technicianDetailObj.PIN).trim().length() > 10 ) {
        	throw new BlackpurlException('Technician PIN should not be greater than 10 characters');
        }
    	if(technicianDetailObj.IsTechnician != null && technicianDetailObj.IsTechnician) {
    		technicianRec.Type__c = Constants.TECHNICIAN;
    		technicianRec.Role__c = technicianDetailObj.Role;
    		technicianRec.Labour_Cost_Per_Hour__c = technicianDetailObj.LabourCostPerHour;
        	technicianRec.Working_Days__c = technicianDetailObj.WorkingDays;
    	} else {
    		technicianRec.Type__c = null;
    	}
        technicianRec.PIN__c = technicianDetailobj.PIN;
        return technicianRec;
    }
    
    public static List<LeaveWrapper> getTechnicianLeavesByTechnicianId(String technicianRecId) {
    	if(AccessControl.ifObjectFieldIsAccessible('Leave__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Leave__c> leaveList = SOQLUtil.getTechnicianLeavesByTechnicianId(new Set<String>{technicianRecId});
        List<LeaveWrapper> leaveObjList = new List<LeaveWrapper>();
    	for(Leave__c leaveRec : leaveList) {
    		leaveObjList.add(new LeaveWrapper(leaveRec));
    	}
        return leaveObjList;
    }
    
    public static LeaveWrapper saveLeaveDetail(String leaveJSON) {
        LeaveWrapper leaveDetailObj = (LeaveWrapper)System.JSON.deserialize(leaveJSON, LeaveWrapper.class);
    	Leave__c leaveRec = new Leave__c(Id = leaveDetailObj.Id);
    	leaveRec.Name = leaveDetailObj.Type;
    	leaveRec.Technician__c = leaveDetailObj.TechnicianId;
    	leaveRec.From__c = DateTimeUtility.getConvertedDateTime(leaveDetailObj.FromDate, leaveDetailObj.FromTime);
    	leaveRec.To__c = DateTimeUtility.getConvertedDateTime(leaveDetailObj.ToDate, leaveDetailObj.ToTime);
    
        DMLUtility.upsertSobjectList('Leave__c', leaveRec);
        return new LeaveWrapper(leaveRec);
    }
    
    public static void deleteLeave(String leaveId) {
    	if(AccessControl.ifObjectIsDeletable('Leave__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete new Leave__c(Id = leaveId);
    }
}