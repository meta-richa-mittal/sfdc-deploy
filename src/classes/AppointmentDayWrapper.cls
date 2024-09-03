/**
* @author Nidhi Sharma <nidhi.sharma@metacube.com>
* @Description Bean object for Appointment Day Data for one day
*/
public without sharing class AppointmentDayWrapper {
    
    public Integer DayIndex;
    public String Day;
    public String AppointmentDate;
    public Boolean IsWorking;
    public Boolean IsToday;
    public List<DaySegmentWrapper> DaySegments;
    
    public AppointmentDayWrapper(Integer dayIndex, String dayStr, DateTime appointmentDate, Boolean IsWorking) {
        this.DayIndex = dayIndex;
        this.Day = dayStr.substring(0, 3);
        this.IsWorking = IsWorking;
        if(appointmentDate != null) {
        	Date currentDate = system.today();
        	this.IsToday = currentDate.isSameDay(appointmentDate.date());
    		this.AppointmentDate = BPUtility.getFormatedDateTime(datetime.newInstance(appointmentDate.year(), appointmentDate.month(), appointmentDate.day()));
    	}
    }
    
    public static List<String> getAppointmentFieldsList() {
	   return new List<String>{'Start_DateTime__c', 'Estimated_Hours__c', 'Appointment_Day_Segment__c', 'End_DateTime__c', 'Is_MultiDay__c'};
   	}
   	
    // Inner class representing Day in week
    public class DaySegmentWrapper {
        
        public Decimal TotalWorkingHours;
        public Decimal BookedHours;
        public Decimal AvailableHours;
        public Integer TotalAppointments;
		public String StartTime;
		
        public DaySegmentWrapper(Decimal totalWorkingHours, Decimal bookedHours, Integer totalAppointments, String startTime) {
            this.TotalWorkingHours = totalWorkingHours;
            this.BookedHours = bookedHours;
            this.AvailableHours = this.TotalWorkingHours - this.BookedHours;
            this.TotalAppointments = TotalAppointments;
            this.StartTime = startTime;
        }
    }
}