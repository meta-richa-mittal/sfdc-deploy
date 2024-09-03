/**
 * Author: Tarun Khandelwal
 * Since: Nov 03, 2017 
 * Name: PayrollCtrl
 * Description: Used to handle all business logic related to Payroll Clocking
**/
global without sharing class PayrollCtrl {
    
    global PayrollCtrl(NewHomePageCtrl controller){}
    public PayrollCtrl() {}
    
    @RemoteAction
    global static String getTechnicianList() {
        return getTechnicianList(new Map<String, String>());
    }
    
    public static String getTechnicianList(Map<String, String> fieldNameToFieldValueMap) {
        List<Technician__c> technicianList = SOQLUtil.getTechnicianListWithPayroll(fieldNameToFieldValueMap);
        List<PayrollWrapper> payrollWrapperList = new List<PayrollWrapper>();
        for(Technician__c technicianRec : technicianList) {
            payrollWrapperList.add(new PayrollWrapper(technicianRec)); 
        }
        payrollWrapperList.sort();
        return BPUtility.getEncodedString(System.JSON.serialize(payrollWrapperList));
    }
    
    @RemoteAction
    global static String saveClockStatus(String jsonString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        PayrollWrapper payrollObj = (PayrollWrapper) System.JSON.deserialize(jSONString, PayrollWrapper.class);
        //system.assert(false,payrollObj);
        
        if(payrollObj.IsClockedOn) {
            payrollOnForTechnician(payrollObj.TechnicianId);
        } else {
            Payroll_Time__c payrollTimeRec = new Payroll_Time__c();
            payrollTimeRec.Technician__c = payrollObj.TechnicianId;
            payrollTimeRec.Id = payrollObj.Id;
            payrollTimeRec.End_Date__c = system.now();
            DMLUtility.updateSobjectList('Payroll_Time__c', payrollTimeRec);
            
            // Clock Off all active job for the techinician
            List<Hours_Logged__c> hoursLoggedList = TechnicianService.clockOFFTechnicianforAllActiveJobs(payrollObj.TechnicianId);
            if(hoursLoggedList.size() > 0) {
                DMLUtility.updateSobjectList('Hours_Logged__c', hoursLoggedList);
                Set<Id> hoursLoggedIdSet = new Set<Id>();
                for(Hours_Logged__c hourlog : hoursLoggedList){
                	hoursLoggedIdSet.add(hourlog.Id);
                }
                ServiceJobService.calculateTechinicianHours(hoursLoggedIdSet, null);
            }
        }
        return getTechnicianList(new Map<String, String>{'Id' => payrollObj.TechnicianId});
    }
    
    public static void payrollOnForTechnician(String technicianId) {
        if(AccessControl.ifObjectFieldIsAccessible('Payroll_Time__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Payroll_Time__c> payrollList = [Select Id from Payroll_Time__c where Technician__c =: technicianId 
                                                    AND End_Date__c = null];
        
        if(payrollList.size() == 0) {
            Payroll_Time__c payrollTimeRec = new Payroll_Time__c();
            payrollTimeRec.Technician__c = technicianId; 
            payrollTimeRec.Start_Date__c = system.now();
            DMLUtility.insertSobjectList('Payroll_Time__c', payrollTimeRec);
        }
    }
    
    @RemoteAction
    global static String getPayrollList(String jsonString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        
        PayrollWrapper.PayrollFilterWrapper payrollFilterObj = 
                        (PayrollWrapper.PayrollFilterWrapper) System.JSON.deserialize(jSONString, PayrollWrapper.PayrollFilterWrapper.class);
        //system.assert(false,payrollFilterObj);
        DateTime startDtValue = HomeSearchFilterInterface.getDateFromString(payrollFilterObj.StartDate);
        String startDateStr = startDtValue.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        DateTime endDtValue = HomeSearchFilterInterface.getDateFromString(payrollFilterObj.EndDate);
        endDtValue = endDtValue.addDays(1);
        String endDateStr = endDtValue.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        List<Payroll_Time__c> payrollList = SOQLUtil.getPayrollList(new Map<String, String>{ 'Start_Date__c' => startDateStr, 
                                                                                            'End_Date__c' => endDateStr, 
                                                                                            'Technician__c' => payrollFilterObj.EmployeeId
                                                                                    });
   
        List<PayrollWrapper> payrollWrapperList = new List<PayrollWrapper>();
        for(Payroll_Time__c payrollRec : payrollList){
            payrollWrapperList.add(new PayrollWrapper(payrollRec)); 
        }
        payrollWrapperList.sort();
        //system.assert(false,payrollWrapperList);
        return BPUtility.getEncodedString(System.JSON.serialize(payrollWrapperList));
    }
    
    @RemoteAction
    global static String savePayrollRec(String jsonString, String filterWrapperString) {
        jsonString = BPUtility.getDecodedString(jsonString);
        PayrollWrapper payrollObj = (PayrollWrapper)System.JSON.deserialize(jSONString, PayrollWrapper.class);
        
        Payroll_Time__c payrollTimeRec = new Payroll_Time__c(Id = payrollObj.Id);
        payrollTimeRec.Technician__c = payrollObj.TechnicianId;
        DateTime dtValue = HomeSearchFilterInterface.getDateFromString(payrollObj.StartDate);
        payrollTimeRec.Start_Date__c = BPUtility.createDateTimeFromStr(dtValue, payrollObj.TimeIn);
        payrollTimeRec.End_Date__c = BPUtility.createDateTimeFromStr(dtValue, payrollObj.TimeOut);
        
        if(AccessControl.ifObjectFieldIsAccessible('Payroll_Time__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        DateTime currentDayStartTime = Datetime.newInstance(payrollTimeRec.End_Date__c.date(), Time.newInstance(0, 0, 0, 0));
        List<Payroll_Time__c> existingPayrollList = [Select Id from Payroll_Time__c where Technician__c =: payrollTimeRec.Technician__c
		        										AND Start_Date__c <: payrollTimeRec.End_Date__c AND (End_Date__c >: payrollTimeRec.Start_Date__c OR (End_Date__c = null AND Start_Date__c >=: currentDayStartTime))
		        										AND Id <>: payrollTimeRec.Id];
        
        if(existingPayrollList.size() > 0) {
        	return BPUtility.getEncodedString('[{"HasError" : true, "ErrorMsg" : "' + Label.Payroll_Already_exists_error + '"}]');
        } else {
            DMLUtility.upsertSobjectList('Payroll_Time__c', payrollTimeRec);
        	List<PayrollWrapper> payrollWrapperList = new List<PayrollWrapper>();
	        List<Payroll_Time__c> payrollList = SOQLUtil.getPayrollList(new Map<String, String>{'Id' => payrollTimeRec.Id});
	      	for(Payroll_Time__c payrollRec : payrollList){
	            payrollWrapperList.add(new PayrollWrapper(payrollRec)); 
	        }                                     
	        return BPUtility.getEncodedString(System.JSON.serialize(payrollWrapperList));
        }
    }
    
    @RemoteAction
    global static String deletePayrollRec(String payrollRecId, String filterWrapperString) {
        payrollRecId = BPUtility.getDecodedString(payrollRecId);
        Payroll_Time__c payrollTimeRec = new Payroll_Time__c(Id = payrollRecId);
        delete payrollTimeRec;
        
        return getPayrollList(filterWrapperString);
    }
    
    @RemoteAction
    global static String verifyTechnicianPin(String technicianId, String technicianPin) {
        technicianId = BPUtility.getDecodedString(technicianId);
        technicianPin = BPUtility.getDecodedString(technicianPin);
        return TechnicianService.verifyTechnicianPinForPayrollClocking(technicianId, technicianPin);
    }
}