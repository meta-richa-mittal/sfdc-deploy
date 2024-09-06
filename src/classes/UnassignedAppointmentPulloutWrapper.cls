/** 
* Author: Nidhi Sharma <nidhi.sharma@metacube.com>
* Since: Aug 08, 2020
* Name: UnassignedAppointmentPulloutWrapper
* Description: Apex class for unassigned appointment wrappers
**/
public without sharing class UnassignedAppointmentPulloutWrapper {
    public static final String Pullout_Date_Format = 'EEEE, dd MMM yyyy';
    public List<DatewiseUnassignedAppWrapper> DaywiseUnassignedAppointmentList;
    
    public UnassignedAppointmentPulloutWrapper(List<Event__c> appointmentList) {
    	this.DaywiseUnassignedAppointmentList = new List<DatewiseUnassignedAppWrapper>();
    	
    	Set<String> appDateStrSet = new Set<String>();
    	Map<String, List<AppointmentWrapper>> appDateToAMAppListMap = new Map<String, List<AppointmentWrapper>>();
		Map<String, List<AppointmentWrapper>> appDateToPMAppListMap = new Map<String, List<AppointmentWrapper>>();
		
        Map<String, List<String>> eventIdToSOKitConcernList = AppointmentService.getSOKitConcernsByAppointments(appointmentList);
        for(Event__c appRec : appointmentList) {
        	if(appRec.Start_DateTime__c != null) {
	    		AppointmentWrapper appointmentObj = new AppointmentWrapper(appRec, true);
	            if(eventIdToSOKitConcernList.containsKey(appRec.Id)) {
	                appointmentObj.SOKitConcern.addAll(eventIdToSOKitConcernList.get(appRec.Id));
	            }	            
	            List<AppointmentWrapper> appList = new List<AppointmentWrapper>();
	            if(appRec.Start_DateTime__c.format('h:mma').contains('AM')) {
		            if(!appDateToAMAppListMap.containsKey(appRec.Start_DateTime__c.format(Pullout_Date_Format))) {
		            	appDateToAMAppListMap.put(appRec.Start_DateTime__c.format(Pullout_Date_Format), new List<AppointmentWrapper>());
		            }
		            appList = appDateToAMAppListMap.get(appRec.Start_DateTime__c.format(Pullout_Date_Format));
	            } else {
	            	if(!appDateToPMAppListMap.containsKey(appRec.Start_DateTime__c.format(Pullout_Date_Format))) {
		            	appDateToPMAppListMap.put(appRec.Start_DateTime__c.format(Pullout_Date_Format), new List<AppointmentWrapper>());
		            }
		            appList = appDateToPMAppListMap.get(appRec.Start_DateTime__c.format(Pullout_Date_Format));
	            }
	            
	            appDateStrSet.add(appRec.Start_DateTime__c.format(Pullout_Date_Format));
	            appList.add(appointmentObj);
        	}
        }
        
        appointmentList = null;
        
        for(String appDateStr : appDateStrSet) {
        	List<AppointmentWrapper> amAppList = appDateToAMAppListMap.containsKey(appDateStr) ? appDateToAMAppListMap.get(appDateStr) : null;
        	List<AppointmentWrapper> pmAppList = appDateToPMAppListMap.containsKey(appDateStr) ? appDateToPMAppListMap.get(appDateStr) : null;
        	DaywiseUnassignedAppointmentList.add(new DatewiseUnassignedAppWrapper(appDateStr, amAppList, pmAppList));
        }
    }
    
    public class DatewiseUnassignedAppWrapper {
	    public String DateFormattted;
	    public List<AppointmentWrapper> AMAppointmentList;
	    public List<AppointmentWrapper> PMAppointmentList;
	    
	    public DatewiseUnassignedAppWrapper(String formattedDate, List<AppointmentWrapper> morningAppList, List<AppointmentWrapper> afternoonAppList) {
			this.DateFormattted = formattedDate != null ? formattedDate : '';
	    	this.AMAppointmentList = morningAppList != null ? morningAppList : new List<AppointmentWrapper>();
	    	this.PMAppointmentList = afternoonAppList != null ? afternoonAppList : new List<AppointmentWrapper>();
	    }
    }
}