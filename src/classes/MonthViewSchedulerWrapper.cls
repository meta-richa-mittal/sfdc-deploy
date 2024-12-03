public without sharing class MonthViewSchedulerWrapper {
    
    public Decimal TotalBookedHours;
    public Decimal TotalScheduledHours;
    public List<DayWrapper> DayInfo;
    public List<TechnicianMonthViewWrapper> TechnicianDetailList;
    
    public MonthViewSchedulerWrapper(Date viewStartDate, Date viewEndDate) {
    	this.DayInfo = new List<DayWrapper>();
    	for(Date thisDate = viewStartDate; thisDate <= viewEndDate;) {
      		DateTime thisDateTime = DateTime.newInstance(thisDate.year(), thisDate.month(), thisDate.day());
        	String weekDay = thisDateTime.format('EEEE');
        	
        	String formattedDayToDisplay = ((weekDay != null && weekDay.length() > 2) ? weekDay.subString(0, 2) : '') + ' ' + thisDateTime.format('d');
        	Boolean isWorkingDay = false;
        	if(MonthViewSchedulerService.weekDayToShopFromTimeMap.containsKey(weekDay.toLowerCase())) {
        		isWorkingDay = true;
        	}
        	this.DayInfo.add(new DayWrapper(formattedDayToDisplay, thisDateTime.format(MonthViewSchedulerService.Date_Format), isWorkingDay));
      		thisDate = thisDate.addDays(1);
      	}
      	
    	this.TechnicianDetailList = new List<TechnicianMonthViewWrapper>();
    }
    
    public class DayWrapper {
    	public String DayToDisplay;
    	public String FormattedDate;
    	public Boolean IsWorking;
    	
    	public DayWrapper(String formattedDay, String formattedDate, Boolean isWorking) {
    		this.DayToDisplay = formattedDay;
    		this.FormattedDate = formattedDate;
    		this.IsWorking = isWorking;
    	}
    }
    
    public class TechnicianMonthViewWrapper {
    	public TechnicianWrapper TechnicianInfo;
    	public Decimal HoursBooked;
    	public Decimal HoursScheduledToWork;
    	public Integer MaxNumberOfBlocks;
    	public List<TechnicianDayDetailWrapper> DayInfoList;
    	
    	public TechnicianMonthViewWrapper(DateTime fromDateTime, Technician__c techRec, Map<String, List<MonthViewSchedulerWrapper.BlockWrapper>> dayToLeaveBlockListMap, 
    					Map<String, Decimal> dayToLeaveHoursMap, Map<String, List<BlockWrapper>> dayToMultiDayAppListMap, 
    					Map<String, List<BlockWrapper>> dayToSingleDayAppListMap, Map<String, Decimal> dayToBookedHoursMap) {
    						
    		
    		this.TechnicianInfo = new TechnicianWrapper(techRec);
    		this.DayInfoList = new List<TechnicianDayDetailWrapper>();
    		
    		Map<String, Integer> dayToBlockCountMap = new Map<String, Integer>();
    		this.HoursBooked = 0;
    		this.HoursScheduledToWork = 0;
    		
    		for(Integer i = 0; i < MonthViewSchedulerService.NumberOfDaysToView; i++) {	//31 day View
	        	DateTime currentDateTime = fromDateTime.addHours(24*i);
				Datetime currentDateTimeByDate = ((DateTime)date.newInstance(fromDateTime.year(), fromDateTime.month(), fromDateTime.day())).addHours(24*i);
				String formatttedDate = currentDateTimeByDate.format(MonthViewSchedulerService.Date_Format);
	        	String weekDay = currentDateTimeByDate.formatGMT('EEEE');

	        	List<BlockWrapper> leaveBlockList = new List<BlockWrapper>();
	        	if(dayToLeaveBlockListMap.containsKey(formatttedDate)) {
	        		leaveBlockList = dayToLeaveBlockListMap.get(formatttedDate);
	        		getDayToExtendedBlockCountMap(currentDateTime, leaveBlockList, dayToBlockCountMap);
	        		dayToLeaveBlockListMap.remove(formatttedDate);
	        	}
	        	
	        	List<BlockWrapper> multiDayBlockList = new List<BlockWrapper>();
	        	if(dayToMultiDayAppListMap.containsKey(formatttedDate)) {
	        		multiDayBlockList = dayToMultiDayAppListMap.get(formatttedDate);
	        		getDayToExtendedBlockCountMap(currentDateTime, multiDayBlockList, dayToBlockCountMap);
	        		dayToMultiDayAppListMap.remove(formatttedDate);
	        	}
	        	
	        	List<BlockWrapper> singleDayBlockList = new List<BlockWrapper>();
	        	if(dayToSingleDayAppListMap.containsKey(formatttedDate)) {
	        		singleDayBlockList = dayToSingleDayAppListMap.get(formatttedDate);
	        		getDayToExtendedBlockCountMap(currentDateTime, singleDayBlockList, dayToBlockCountMap);
	        		dayToSingleDayAppListMap.remove(formatttedDate);
	        	}
	        	
	        	Integer maxBlockCountForThisDay = (leaveBlockList.size() + multiDayBlockList.size() + singleDayBlockList.size());
	        	if(dayToBlockCountMap.containsKey(formatttedDate)) {
	        		maxBlockCountForThisDay += dayToBlockCountMap.get(formatttedDate);
	        	}
	        	if(maxBlockCountForThisDay > 0) {
	        		dayToBlockCountMap.put(formatttedDate, maxBlockCountForThisDay);
	        	}
	        	
	        	Boolean isWorkingDayForTech = TechnicianService.isWorkingDayForTechnician(techRec, weekDay);
	        	Boolean isShopWorkingDay = MonthViewSchedulerService.weekDayToShopFromTimeMap.containsKey(weekDay.toLowerCase());
	        	Decimal totalBookedHrs = 0;
	        	Decimal totalScheduledHrs = 0;
	        	if(isWorkingDayForTech && isShopWorkingDay) {
	        		
	        		if(dayToBookedHoursMap.containsKey(formatttedDate)) {
		        		totalBookedHrs = dayToBookedHoursMap.get(formatttedDate);
		        	}
		        	
	        		Time shopFromTime = MonthViewSchedulerService.weekDayToShopFromTimeMap.get(weekDay.toLowerCase());
	        		Time shopToTime = MonthViewSchedulerService.weekDayToShopToTimeMap.get(weekDay.toLowerCase());
	        		
	        		Decimal hours = shopToTime.hour() - shopFromTime.hour();
	        		Decimal minutes = shopToTime.minute() - shopFromTime.minute();
		        	totalScheduledHrs = hours + minutes/60;
	        		
		        	if(dayToLeaveHoursMap.containsKey(formatttedDate)) {
		        		totalScheduledHrs -= dayToLeaveHoursMap.get(formatttedDate);
		        	}
	        	}
	        	
	        	this.HoursScheduledToWork += totalScheduledHrs;
	        	this.HoursBooked += totalBookedHrs;
	        	
	        	TechnicianDayDetailWrapper dayWrapperObj = new TechnicianDayDetailWrapper(isWorkingDayForTech, isShopWorkingDay, formatttedDate, 
	        		totalScheduledHrs, totalBookedHrs, leaveBlockList, 
	        						multiDayBlockList, singleDayBlockList);
	        	
	        	DayInfoList.add(dayWrapperObj);
	        }
        	
        	List<Integer> sortedBlockCountList = dayToBlockCountMap.values();
        	dayToBlockCountMap = null;
        	sortedBlockCountList.sort();
        	
    		if(sortedBlockCountList.size() > 0) {
    			this.MaxNumberOfBlocks = (sortedBlockCountList)[sortedBlockCountList.size() - 1];
    		}
    		this.MaxNumberOfBlocks = (this.MaxNumberOfBlocks == null || this.MaxNumberOfBlocks < 1) ? 1 : this.MaxNumberOfBlocks;
    	}
    }
    
    public class TechnicianDayDetailWrapper {
    	public String FormattedDate;
    	public Boolean IsWorkingDayForTechnician;
    	public Boolean IsWorkingDay;
    	public Decimal HoursBooked;
    	public Decimal HoursScheduledToWork;
    	public String AvailableHoursToShow;
    	public List<BlockWrapper> BlockList;
    	
    	public TechnicianDayDetailWrapper(Boolean isTechWorkingDay, Boolean isShopWorkingDay, String formattedDate, Decimal totalScheduledHrs, Decimal totalBookedHrs, 
    						List<BlockWrapper> leaveBlockList, 
    						List<BlockWrapper> multiDayAppList, List<BlockWrapper> singleDayAppList) {
    		this.IsWorkingDayForTechnician = isTechWorkingDay;
    		this.IsWorkingDay = isShopWorkingDay;
    		this.HoursScheduledToWork = totalScheduledHrs != null ? totalScheduledHrs : 0;
    		this.HoursBooked = totalBookedHrs != null ? totalBookedHrs : 0;
    		this.AvailableHoursToShow = '';
    		
			Integer totalMinutes = Integer.valueOf((this.HoursScheduledToWork - this.HoursBooked) * 60);
			if(totalMinutes < 0) {
				this.AvailableHoursToShow += '+';
				totalMinutes = totalMinutes * -1;	
			}
			
			Integer hrs = totalMinutes / 60;
			Integer mins = Math.Mod(totalMinutes, 60);

			if(hrs == 0 && mins == 0) {
				this.AvailableHoursToShow = '0';
			} else {
    			this.AvailableHoursToShow += (hrs > 0 ? hrs + 'h' : '')  + (mins > 0 ? mins + 'm' : '');
    		}
    		
    		this.FormattedDate = formattedDate;
    		
    		this.BlockList = new List<BlockWrapper>();
    		this.BlockList.addAll(leaveBlockList);
    		this.BlockList.addAll(multiDayAppList);
    		this.BlockList.addAll(singleDayAppList);
    		
    	}
    }
    
    public class TechnicianWrapper {
    	public String Id;
    	public String NameInitials;
		public String TechnicianFullName;

		public TechnicianWrapper(Technician__c techRec) {
			this.Id = techRec.Id;
			this.NameInitials = ((techRec.First_Name__c.length() > 0) ? techRec.First_Name__c.subString(0, 1) : '') +
                            ((techRec.Last_Name__c.length() > 0) ? techRec.Last_Name__c.subString(0, 1) : '');
			this.TechnicianFullName = techRec.Technician_Name__c != null ? techFullNameFormat(techRec.Technician_Name__c) : '';	
		}
    }
    
    public class BlockWrapper {
    	public Boolean IsLeave = false;
    	public Boolean IsMultiDayApp = false;
    	public Boolean IsSingleDayApp = false;
    	public Decimal EstimatedHours;
    	public Decimal BlockLastsForDays;
    	
    	//MultiDayApp flyout info
    	public String AppointmentId;
    	public String CustomerName;
	    public String COId;
	    public String CONumber;
	    public String UnitFormattedName;
	    public String TransactionType;
	    
	    public String AppointmentTitle;
	    public List<String> Concern;
    	public List<String> SOKitConcern;
	    public String ActualStartDate;
	    public String ActualEndDate;
	    public String ActualStartTime;
	    public String ActualEndTime;
		public Boolean IsConflicted;
		
		public String DueInTime;
		public String DueInDate;
		public String PromiseByTime;
		public String PromisedByDate;
		public Boolean IsUnitArrived;
		public String ServiceJobStatus;
		public String SOStatusTextColor;
		public String SOStatusBGColor;
		public String UnitLocation;
	    
	    public BlockWrapper(Leave__c leaveRec, Integer leaveLastFor) {
	    	this.IsLeave = true;
	    	this.BlockLastsForDays = leaveLastFor;
	    	this.UnitFormattedName = leaveRec.Name;
	    	this.CustomerName = leaveRec.Technician__r.Technician_Name__c;
	    	this.ActualStartDate = (leaveRec.From__c != null) ? BPUtility.getFormatedDateTime(leaveRec.From__c) : null;
	        this.ActualEndDate = (leaveRec.To__c != null) ? BPUtility.getFormatedDateTime(leaveRec.To__c) : null;
	        this.ActualStartTime = (leaveRec.From__c != null) ? leaveRec.From__c.format('h:mma') : null;
	        this.ActualEndTime = (leaveRec.To__c != null) ? leaveRec.To__c.format('h:mma') : null;
	    }
	    
	    public BlockWrapper(Event__c eventRec, Integer appLastsFor, Boolean isConflicted) {
	    	if(eventRec.Is_MultiDay__c) {
	    		this.IsMultiDayApp = true;
	    	} else {
	    		this.IsSingleDayApp = true;
	    	}
	    	this.IsConflicted = isConflicted;
	    	
	    	this.ActualStartDate = (eventRec.Start_DateTime__c != null) ? BPUtility.getFormatedDateTime(eventRec.Start_DateTime__c) : null;
	        this.ActualEndDate = (eventRec.End_DateTime__c != null) ? BPUtility.getFormatedDateTime(eventRec.End_DateTime__c) : null;
	        this.ActualStartTime = (eventRec.Start_DateTime__c != null) ? eventRec.Start_DateTime__c.format('h:mma') : null;
	        this.ActualEndTime = (eventRec.End_DateTime__c != null) ? eventRec.End_DateTime__c.format('h:mma') : null;
	        
	    	this.AppointmentId = eventRec.Id;
	    	this.TransactionType = eventRec.Transaction_Type__r.Type__c;
	    	this.BlockLastsForDays = appLastsFor;
	    	this.EstimatedHours = eventRec.Estimated_Hours__c;
	    	this.CustomerName = (eventRec.Customer__r.Name != null) ? eventRec.Customer__r.Name : null;
	    	this.COId = (eventRec.CO_Header__c != null) ? eventRec.CO_Header__c : null;
	        this.CONumber = (eventRec.CO_Header__r.Name != null) ? eventRec.CO_Header__r.Name : null;
	        this.UnitFormattedName = eventRec.Customer_Owned_Unit__r.Formatted_Name__c;
	        
	        this.AppointmentTitle = eventRec.Name__c;
	        this.Concern = (eventRec.Appointment_Concern__c != null) ? eventRec.Appointment_Concern__c.split('\n') : new List<String>();
        	this.SOKitConcern = new List<String>();
			
			this.DueInTime = (String.isNotBlank(eventRec.Due_In_Time__c) && eventRec.Due_In_DateTime__c != null) ? eventRec.Due_In_DateTime__c.format('h:mm a') : '';
			this.PromiseByTime = (String.isNotBlank(eventRec.Promised_By_Time__c) && eventRec.Promised_By_DateTime__c != null) ? eventRec.Promised_By_DateTime__c.format('h:mm a') : '';
			
			this.DueInDate = eventRec.Due_In_DateTime__c != null ?
				eventRec.Due_In_DateTime__c.format(Constants.localeToDateTimeFmtMap.get(UserInfo.getLocale())) : '';
			this.PromisedByDate = eventRec.Promised_By_DateTime__c != null ?
				eventRec.Promised_By_DateTime__c.format(Constants.localeToDateTimeFmtMap.get(UserInfo.getLocale())) : '';
			this.IsUnitArrived = eventRec.Unit_Arrived__c != null ? eventRec.Unit_Arrived__c : false;				
			if(eventRec.Service_Order_Header__c != null) {
				this.ServiceJobStatus = eventRec.Service_Order_Header__r.SO_Status__c;
				if(eventRec.Service_Order_Header__r.SO_Status_Ref__c != null) {
					this.SOStatusTextColor = eventRec.Service_Order_Header__r.SO_Status_Ref__r.Text_Color__c;
					this.SOStatusBGColor = eventRec.Service_Order_Header__r.SO_Status_Ref__r.Background_Color__c;
				}
			}
			this.UnitLocation = (eventRec.Unit_Location__c != null) ? eventRec.Unit_Location__c: '';
	    }
		
		public BlockWrapper(Event_Scheduling__c eventSchedulingRec, Integer appLastsFor, Boolean isConflicted) {
	    	if(eventSchedulingRec.Event__r.Is_MultiDay__c) {
	    		this.IsMultiDayApp = true;
	    	} else {
	    		this.IsSingleDayApp = true;
	    	}
	    	this.IsConflicted = isConflicted;
	    	
	    	this.ActualStartDate = (eventSchedulingRec.Start_Date_Time__c != null) ? BPUtility.getFormatedDateTime(eventSchedulingRec.Start_Date_Time__c) : null;
	        this.ActualEndDate = (eventSchedulingRec.End_Date_Time__c != null) ? BPUtility.getFormatedDateTime(eventSchedulingRec.End_Date_Time__c) : null;
	        this.ActualStartTime = (eventSchedulingRec.Start_Date_Time__c != null) ? eventSchedulingRec.Start_Date_Time__c.format('h:mma') : null;
	        this.ActualEndTime = (eventSchedulingRec.End_Date_Time__c != null) ? eventSchedulingRec.End_Date_Time__c.format('h:mma') : null;
	        
	    	this.AppointmentId = eventSchedulingRec.Event__r.Id;
	    	this.TransactionType = eventSchedulingRec.Event__r.Transaction_Type__r.Type__c;
	    	this.BlockLastsForDays = appLastsFor;
	    	this.EstimatedHours = eventSchedulingRec.Hours__c;
	    	this.CustomerName = (eventSchedulingRec.Event__r.Customer__r.Name != null) ? eventSchedulingRec.Event__r.Customer__r.Name : null;
	    	this.COId = (eventSchedulingRec.Event__r.CO_Header__c != null) ? eventSchedulingRec.Event__r.CO_Header__c : null;
	        this.CONumber = (eventSchedulingRec.Event__r.CO_Header__r.Name != null) ? eventSchedulingRec.Event__r.CO_Header__r.Name : null;
	        this.UnitFormattedName = eventSchedulingRec.Event__r.Customer_Owned_Unit__r.Formatted_Name__c;
	        
	        this.AppointmentTitle = eventSchedulingRec.Event__r.Name__c;
	        this.Concern = (eventSchedulingRec.Event__r.Appointment_Concern__c != null) ? eventSchedulingRec.Event__r.Appointment_Concern__c.split('\n') : new List<String>();
        	this.SOKitConcern = new List<String>();
			
			this.DueInTime = (String.isNotBlank(eventSchedulingRec.Event__r.Due_In_Time__c) && eventSchedulingRec.Event__r.Due_In_DateTime__c != null) ? eventSchedulingRec.Event__r.Due_In_DateTime__c.format('h:mm a') : '';
			this.PromiseByTime = (String.isNotBlank(eventSchedulingRec.Event__r.Promised_By_Time__c) && eventSchedulingRec.Event__r.Promised_By_DateTime__c != null) ? eventSchedulingRec.Event__r.Promised_By_DateTime__c.format('h:mm a') : '';
			
			this.DueInDate = eventSchedulingRec.Event__r.Due_In_DateTime__c != null ?
			eventSchedulingRec.Event__r.Due_In_DateTime__c.format(Constants.localeToDateTimeFmtMap.get(UserInfo.getLocale())) : '';
			this.PromisedByDate = eventSchedulingRec.Event__r.Promised_By_DateTime__c != null ?
			eventSchedulingRec.Event__r.Promised_By_DateTime__c.format(Constants.localeToDateTimeFmtMap.get(UserInfo.getLocale())) : '';
			this.IsUnitArrived = eventSchedulingRec.Event__r.Unit_Arrived__c != null ? eventSchedulingRec.Event__r.Unit_Arrived__c : false;
			if(eventSchedulingRec.Event__r.Service_Order_Header__c != null) {
				this.ServiceJobStatus = eventSchedulingRec.Event__r.Service_Order_Header__r.SO_Status__c;
				if(eventSchedulingRec.Event__r.Service_Order_Header__r.SO_Status_Ref__c != null) {
					this.SOStatusTextColor = eventSchedulingRec.Event__r.Service_Order_Header__r.SO_Status_Ref__r.Text_Color__c;
					this.SOStatusBGColor = eventSchedulingRec.Event__r.Service_Order_Header__r.SO_Status_Ref__r.Background_Color__c;
				}
			}			
			this.UnitLocation = (eventSchedulingRec.Event__r.Unit_Location__c != null) ? eventSchedulingRec.Event__r.Unit_Location__c: '';
	    }
    }
    
    private static void getDayToExtendedBlockCountMap(DateTime currentDateTime, List<BlockWrapper> blockList, Map<String, Integer> dayToExtendedBlockCountMap) {
    	for(BlockWrapper block : blockList) {
        	for(Integer i=1; i < block.BlockLastsForDays; i++) {
	    		String extendedDayFormatted = currentDateTime.addDays(i).format(MonthViewSchedulerService.Date_Format);
	    		if(!dayToExtendedBlockCountMap.containsKey(extendedDayFormatted)) {
	    			dayToExtendedBlockCountMap.put(extendedDayFormatted, 0);
	    		}
	    		dayToExtendedBlockCountMap.put(extendedDayFormatted, dayToExtendedBlockCountMap.get(extendedDayFormatted) + 1);
	    	}
    	}
    }
    
    private static String techFullNameFormat (String technicianName) {
		String nameInCamelCase = '';
		if (technicianName != null && technicianName != '') {
			for (String techNameStr : technicianName.split('[ ]+')) {
				if (techNameStr != null && techNameStr != '') {
					if (techNameStr.length() > 1) {  
						nameInCamelCase += techNameStr.substring(0,1).toUpperCase() + techNameStr.substring(1,techNameStr.length()) + ' ';
					} else {
						nameInCamelCase += techNameStr.substring(0,1).toUpperCase() + ' ';
					}
				}
			}
			nameInCamelCase = nameInCamelCase.substring(0, nameInCamelCase.length() - 1);
		}
		return nameInCamelCase;
	} 
}