public class DateTimeUtility {
    
	private static String userLocale = UserInfo.getLocale();
	
    public static DateTime getConvertedDateTime(String strDate, String strTime) {
        String stringDateTime = '';
        stringDateTime += strDate;
        stringDateTime += ' ' + strTime.substring(0, strTime.length()-2);
        String strTimePeriod = ' ' + strTime.substring(strTime.length()-2, strTime.length());
        stringDateTime += strTimePeriod;
        return parseDateTime(stringDateTime);  
    }
    
    public static Time getTimeFromString(String timeString) {
    	List<String> ActualTimeHourAndMin = timeString.Split(':');
	   	Integer ActualTimeHour = Integer.valueOf(ActualTimeHourAndMin[0]);
	    Integer ActualTimeMin = Integer.valueOf(ActualTimeHourAndMin[1].substring(0, ActualTimeHourAndMin[1].length() - 2));
	    String ActualTimeHalf = ActualTimeHourAndMin[1].substring(ActualTimeHourAndMin[1].length() - 2, ActualTimeHourAndMin[1].length());
	    if(ActualTimeHalf == 'PM' && ActualTimeHour != 12) {
	    	ActualTimeHour = ActualTimeHour + 12;
	    }
	    return Time.newInstance(ActualTimeHour,ActualTimeMin,0,0);
    }
    
    //To convert 12:00AM to 00:00:0:0 - Use this in future
    public static Time getTimeFromString2(String timeString) {
    	List<String> ActualTimeHourAndMin = timeString.Split(':');
	   	Integer ActualTimeHour = Integer.valueOf(ActualTimeHourAndMin[0]);
	    Integer ActualTimeMin = Integer.valueOf(ActualTimeHourAndMin[1].substring(0, 2));
	    String ActualTimeHalf = ActualTimeHourAndMin[1].substring(ActualTimeHourAndMin[1].length() - 2, ActualTimeHourAndMin[1].length());
	    if(ActualTimeHalf == 'PM' && ActualTimeHour != 12) {
	    	ActualTimeHour = ActualTimeHour + 12;
	    } else if(ActualTimeHalf == 'AM' && ActualTimeHour == 12) {
	    	ActualTimeHour = 0;
	    }
	    return Time.newInstance(ActualTimeHour,ActualTimeMin,0,0);
    }
    
    public static Decimal getTimeDifference(DateTime fromDateTime, DateTime toDateTime) {
    	Long dt1Long = fromDateTime.getTime();
        Long dt2Long = toDateTime.getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        Long totalMinutes = (seconds / 60);
        Long hours = totalMinutes / 60;
        Long minutes = Math.mod(totalMinutes, 60);
        return Decimal.valueOf(hours + ';' + minutes);
    }
    
    public static Decimal getTimeBySegment(String segment, String fromTime, String toTime) {
    	Decimal availableHours = 0.00;
    	if(segment == 'AM') {
    		if(fromTime.contains('AM')) {
    			Time fromDateTime = getTimeFromString(fromTime);
    			Time toDateTime = Time.newInstance(12,0,0,0);
	        	if(toTime.contains('AM')) {
	        		toDateTime = getTimeFromString(toTime);
	        	}
        		Decimal hours = toDateTime.hour() - fromDateTime.hour();
        		Decimal minutes = toDateTime.minute() - fromDateTime.minute();
	        	availableHours = hours + minutes/60;
	        }
    	} else if(segment == 'PM') {
    		if(toTime.contains('PM')) {
    			Time fromDateTime = Time.newInstance(12,0,0,0);
    			Time toDateTime = getTimeFromString(toTime);
	        	if(fromTime.contains('PM')) {
	        		fromDateTime = getTimeFromString(fromTime);
	        	}
        		Decimal hours = toDateTime.hour() - fromDateTime.hour();
        		Decimal minutes = toDateTime.minute() - fromDateTime.minute();
	        	availableHours = hours + minutes/60;
	        }
    	}
    	if(availableHours < 0) {
    	    availableHours = 0;
    	}
    	return availableHours;
    }
    public static Map<String, List<DateTime>> getDaysDateMapForDateRange(DateTime startDateObject, DateTime endDateObject) {
    	Map<String, List<DateTime>> dayToDateMap = new Map<String, List<DateTime>>();
    	DateTime currentDateObject = startDateObject;
    	while(currentDateObject <= endDateObject) {
    		if(!dayToDateMap.containsKey(currentDateObject.format('EEEE'))) {
    			dayToDateMap.put(currentDateObject.format('EEEE'), new List<DateTime>());
    		} 
    		dayToDateMap.get(currentDateObject.format('EEEE')).add(currentDateObject);
    		currentDateObject =currentDateObject.addDays(1);
    	}
    	return dayToDateMap;
    } 
    public static Map<String, List<DateTime>> removeDateNotWithinRange(Map<String, List<DateTime>> dayToDateMap,DateTime startDate, DateTime fromDate) {
    	for(String dayName : dayToDateMap.keySet()) {
    		List<DateTime> dateList = dayToDateMap.get(dayName);
    		for(Integer j = 0; j < dateList.size(); j++ ) {
    			if(!(startDate <= dateList[j] &&  dateList[j] <= fromDate)) {
    				dateList.remove(j);
    				j--;
    			}
    		}
    		dayToDateMap.put(dayName, dateList );
    	}
    	return dayToDateMap;
    } 
    public static DateTime getDateTimeFromDate(Date dateValue) {
    	return datetime.newInstance(dateValue.year(),dateValue.month(),dateValue.day()); 
    }
    public static String getFormttedDateFromDateTime(DateTime dateTimeValue, String format) {
        return String.valueOf((dateTimeValue).format(format));
    }

	public static String getGMTFormttedDateFromDateTime(DateTime dateTimeValue, String format) {
        return String.valueOf((dateTimeValue).formatGmt(format));
    }
    
    public static Date getDateFromFormattedDateStr(String dateStr, String formatOfDatePassed) {
    	Date dateValue;
    	if(formatOfDatePassed == 'YYYY-MM-DD') {
    		List<String> dateStringList = dateStr.split('-');
    		dateValue = Date.newInstance(Integer.valueOf(dateStringList[0]), Integer.valueOf(dateStringList[1]), Integer.valueOf(dateStringList[2]));
    	} else if(formatOfDatePassed == 'DD-MM-YYYY') {
			List<String> dateStringList = dateStr.split('-');
    		dateValue = Date.newInstance(Integer.valueOf(dateStringList[2]), Integer.valueOf(dateStringList[1]), Integer.valueOf(dateStringList[0]));
    	} 
        return dateValue;
    }
	
    public static Date getDateFromFormattedDateStrBasedOnLocale(String dateStr) {
    	List<String> dateStringList = dateStr.split('/');
		String userLocale = UserInfo.getLocale();
		String formatOfDate;
    	if(!Constants.localeToDateTimeFmtMap.containsKey(userLocale)){
    		formatOfDate = Constants.localeToDateTimeFmtMap.get('en_US');
    	} else {
			formatOfDate = Constants.localeToDateTimeFmtMap.get(userLocale);
		}
		if(formatOfDate == 'MM/dd/yyyy') {
			return Date.newInstance(Integer.valueOf(dateStringList[2]), Integer.valueOf(dateStringList[0]), Integer.valueOf(dateStringList[1]));
		} else {
			return Date.newInstance(Integer.valueOf(dateStringList[2]), Integer.valueOf(dateStringList[1]), Integer.valueOf(dateStringList[0]));
		}
	}
	
	public static Date getDateFromFormattedDateStr(String dateStr) {
    	List<String> dateStringList = dateStr.split('/');
        return Date.newInstance(Integer.valueOf(dateStringList[2]), Integer.valueOf(dateStringList[1]), Integer.valueOf(dateStringList[0]));
	}
	
    // This date format is only used when you need to compare Dates in SOQL query but you need formatted DateTime in yyyy-mm-dd
    // In this case, GMT formatted DateTime gives same result.
    public static DateTime getGMTDateTimeFromFormattedDateStr(String dateStr) {
        DateTime dtValue;
        try {
	        List<Integer> dayMonthYearList = HomeSearchFilterInterface.getDayMonthYearList(dateStr);
	        dtValue = DateTime.newInstanceGMT(dayMonthYearList[2], dayMonthYearList[1], dayMonthYearList[0], 0, 0 , 0);
        } catch(Exception e) {
            system.debug('Exception occurs while parsing date into DateTime GMT value');
            dtValue = HomeSearchFilterInterface.getDateFromString(dateStr);
        }
        return dtValue;
    }
    
    public static DateTime getDateTimeFromMSAjaxDateStr(String dateStr) {
    	if(dateStr.contains('/Date(')) {
    		if(dateStr.contains('+')) {
    			return DateTime.newInstance(Long.valueOf(dateStr.substringBetween('/Date(', '+')));
    		} else if(dateStr.contains('-')) {
    			return DateTime.newInstance(Long.valueOf(dateStr.substringBetween('/Date(', '-')));
    		} else {
    			return DateTime.newInstance(Long.valueOf(dateStr.substringBetween('/Date(', ')')));
    		}
    	} else {
    		return DateTime.newInstance(Long.valueOf(dateStr));
    	}
    }

	public static DateTime getDateTimeFromFormattedDateStr(String dateStr) {
        DateTime dtValue;
        try {
	        List<Integer> dayMonthYearList = HomeSearchFilterInterface.getDayMonthYearList(dateStr);
	        dtValue = DateTime.newInstance(dayMonthYearList[2], dayMonthYearList[1], dayMonthYearList[0], 0, 0 , 0);
        } catch(Exception e) {
            system.debug('Exception occurs while parsing date into DateTime value');
            dtValue = HomeSearchFilterInterface.getDateFromString(dateStr);
        }
        return dtValue;
    }
	
	public static DateTime parseDateTime(String dateTimeStr) {
		if(String.isNotBlank(dateTimeStr)) {
			try {
				//Orgs where ICU is not enabled
        		return DateTime.parse(dateTimeStr);
			} catch(TypeException typeEx) {
				try {
					//Orgs where ICU is enabled
					if(!Constants.localeToDateTimeFmtMap.containsKey(userLocale)){
						userLocale = 'en_US';
					}
					String bpLocaleFormat = Constants.localeToDateTimeFmtMap.get(userLocale);
					List<Integer> dayMonthYearList = getDayMonthYearList(dateTimeStr.split(' ')[0], bpLocaleFormat.split(' ')[0].split('/'));
					if(dayMonthYearList.size() == 3) {
						Integer hr = Integer.valueOf(dateTimeStr.split(' ')[1].split(':')[0]);
						Integer min = Integer.valueOf(dateTimeStr.split(' ')[1].split(':')[1]);
							
						if(dateTimeStr.split(' ')[2].equalsIgnoreCase('PM') && hr > 0 && hr < 12) {
							hr += 12;
						}
						return DateTime.newInstance(dayMonthYearList[2], dayMonthYearList[1], dayMonthYearList[0], hr, min, 0);
					}
				} catch(Exception e) {
					throw new BlackPurlException('Invalid datetime format');
				}
			}
		}
		return null;
    }
	
	public static Date parseDate(String dateStr) {
		if(String.isNotBlank(dateStr)) {
			try {
        		return Date.parse(dateStr);
			} catch(TypeException typeEx) {
				try {
					//Orgs where ICU is enabled
					if(!Constants.localeToDateTimeFmtMap.containsKey(userLocale)){
						userLocale = 'en_US';
					}
					String bpLocaleFormat = Constants.localeToDateTimeFmtMap.get(userLocale);
					List<Integer> dayMonthYearList = getDayMonthYearList(dateStr, bpLocaleFormat.split('/'));
					if(dayMonthYearList.size() == 3) {
						return Date.newInstance(dayMonthYearList[2], dayMonthYearList[1], dayMonthYearList[0]);
					}
				} catch(Exception e) {
					throw new BlackPurlException('Invalid date format');
				}
			}
		}
		return null;
    }

	private static List<Integer> getDayMonthYearList(String dateStr, List<String> dateFmtSplitted) {
		List<Integer> dayMonthYearList;
		if(String.isNotBlank(dateStr) && dateFmtSplitted != null && dateFmtSplitted.size() == 3) {
			Integer day, month, year;
			for(Integer i = 0; i < dateFmtSplitted.size(); i++) {
				if(dateFmtSplitted[i].equalsIgnoreCase('dd')) {
					day = Integer.valueOf(dateStr.split('/')[i]);
				} else if(dateFmtSplitted[i].equalsIgnoreCase('mm')) {
					month = Integer.valueOf(dateStr.split('/')[i]);
				} else if(dateFmtSplitted[i].equalsIgnoreCase('yyyy')) {
					year = Integer.valueOf(dateStr.split('/')[i]);
				}
			}
			dayMonthYearList = new List<Integer>{day, month, year};
		}
		return dayMonthYearList;
	}
}