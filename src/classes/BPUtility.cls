/**
 * Author: Tarun Khandelwal
 * Since: July 09, 2016
 * Name: BPUtility
 * Description: Utility class which is used for generic methods used in application
**/
public without sharing class BPUtility {
    public static String EXT_TO_BP_VALUE_MAPPING_TYPE_COUNTRY = 'Country';

    public static String getDecodedString(String str) {
    	if(String.isBlank(str)) {
			return str;
		}
    	return (EncodingUtil.base64Decode(str) != null) ? EncodingUtil.base64Decode(str).toString() : null;
    }
	
	public static String getEncodedString(String str) {
		if(String.isBlank(str)) {
			return str;
		}
    	return getEncodedStr(Blob.valueOf(str));
    }
	    
    public static String getEncodedStr(Blob blobStr) {
    	return EncodingUtil.base64Encode(blobStr);
    }
    
    public static String escapeSingleQuotes(String inputStr) {
    	if(String.isNotBlank(inputStr)) {
    		inputStr = String.escapeSingleQuotes(inputStr);
    	}
    	return inputStr;
    }
    
    public static List<String> escapeSingleQuotes(List<String> inputStrList) {
        List<String> escapedInputStrList = new List<String>();
        for(String inputStr : inputStrList) {
            escapedInputStrList.add(escapeSingleQuotes(inputStr));
        }
        return escapedInputStrList;
    }
    
    public static Map<String, String> objectAPINameToActiveFlagAPIName = 
    				new Map<String, String> {'Account' => 'Active__c',
    										 'Customer' => 'Active__c',
    										 'Vendor' => 'Active__c',
			    							 Constants.NAMESPACE + 'Part__c' => 'Active__c',
			    							 Constants.NAMESPACE + 'Labour_Code__c' => 'Active__c',
			    							 Constants.NAMESPACE + 'Fee__c' => 'Active__c',
			    							 Constants.NAMESPACE + 'Kit_Header__c' => 'Active__c',
			    							 Constants.NAMESPACE + 'Category__c' => 'Active__c',
			    							 Constants.NAMESPACE + 'Price_Level__c' => 'Active__c',
			    							 Constants.NAMESPACE + 'Sales_Tax__c' => 'Active__c',
			    							 Constants.NAMESPACE + 'Sales_Tax_Item__c' => 'Active__c'
			    		}; 
    
    public static String getFormatedDateTime(Date dateToConvert) {
        return BPUtility.getFormatedDateTime(datetime.newInstance(dateToConvert.year(), dateToConvert.month(), dateToConvert.day()) );
    }
                        
  	public static String getFormatedDateTime(DateTime dateRec){
    	String userLocale = UserInfo.getLocale();
    	if(!Constants.localeToDateTimeFmtMap.containsKey(userLocale)){
    		return dateRec.format(Constants.localeToDateTimeFmtMap.get('en_US'));
    	}
    	return dateRec.format(Constants.localeToDateTimeFmtMap.get(userLocale));
    }
    
    public static String getFormatedDateAndTime(datetime dateRec){
    	String userLocale = UserInfo.getLocale();
    	if(!Constants.localeToDateTimeFmtMap.containsKey(userLocale)){
    		return dateRec.format(Constants.localeToDateAndTimeFmtMap.get('en_US'));
    	}
    	return dateRec.format(Constants.localeToDateAndTimeFmtMap.get(userLocale));
    }
    
    public static String getFormatedDateAndTimeWithHypen(datetime dateRec){
    	String userLocale = UserInfo.getLocale();
    	if(!Constants.localeToDateTimeFmtMap.containsKey(userLocale)){
    		return dateRec.format(Constants.localeToDateAndTimeFmtWithHypenMap.get('en_US'));
    	}
    	return dateRec.format(Constants.localeToDateAndTimeFmtWithHypenMap.get(userLocale));
    }
    
    public static String getDateFormat(){
   		String userLocale = UserInfo.getLocale();
   		if(!Constants.localeToDateTimeFmtOnPageMap.containsKey(userLocale)){
    		return Constants.localeToDateTimeFmtOnPageMap.get('en_US');
    	}
   		return Constants.localeToDateTimeFmtOnPageMap.get(userLocale);
   	
   			
   }
   
   public static String getExtendedDateFormat(datetime dateRec){
   		String userLocale = UserInfo.getLocale();
   		if(!Constants.localeToDateTimeMonthFmt.containsKey(userLocale)){
    		return dateRec.format(Constants.localeToDateTimeMonthFmt.get('en_US'));
    	}
   		return  dateRec.format(Constants.localeToDateTimeMonthFmt.get(userLocale));
   			
   } 
   
   public static String getExtendedDateFormatWithoutTime(datetime dateRec){
   		String userLocale = UserInfo.getLocale();
   		if(!Constants.localeToDateTimeMonthFmt.containsKey(userLocale)){
   			
    		return dateRec.format(Constants.localeToDateTimeMonthFmt.get('en_US').substring(0,Constants.localeToDateTimeMonthFmt.get('en_US').length()-8));
    	}
   		return  dateRec.format(Constants.localeToDateTimeMonthFmt.get(userLocale).substring(0,Constants.localeToDateTimeMonthFmt.get('en_US').length()-8));
   			
   }
   
   public static String getExtendedMonthFormat(datetime dateRec){
   		String userLocale = UserInfo.getLocale();
   		if(!Constants.localeToDateMonthTimeFmtMap.containsKey(userLocale)){
   			
    		return dateRec.format(Constants.localeToDateMonthTimeFmtMap.get('en_US'));
    	}
   		return  dateRec.format(Constants.localeToDateMonthTimeFmtMap.get(userLocale));
   			
   } 
   public static String getExtendedTimeMonthFormat(datetime dateRec){
   		String userLocale = UserInfo.getLocale();
   		if(!Constants.localeToDateTimeExtendedMonthFmt.containsKey(userLocale)){
    		return dateRec.format(Constants.localeToDateTimeExtendedMonthFmt.get('en_US'));
    	}
   		return  dateRec.format(Constants.localeToDateTimeExtendedMonthFmt.get(userLocale));
   			
   } 
   
   public static String getExportFormatedDateTime(datetime dateRec){
    	String userLocale = UserInfo.getLocale();
    	//Constants.localeToDateTimeFmtMap.get(userLocale);
    	if(!Constants.localeToExportFmtMap.containsKey(userLocale)){
    		return dateRec.format(Constants.localeToExportFmtMap.get('en_US'));
    	}
    	return dateRec.format(Constants.localeToExportFmtMap.get(userLocale));
    }
   
    
    public static DateTime createDateTimeFromStr(DateTime dtValue, String timeStr) {
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
    
    public static String convertListIntoString(List<String> strList) {
        String returnStr = '';
        if(strList.size() == 0) { 
            returnStr = null;
        }
        for(String subStr : strList) {
            subStr = (subStr.contains('\n')) ? subStr.replaceAll('\n', '') : subStr;
            returnStr += (subStr != null) ? (subStr + '\n') : '';
        }
        return returnStr;
    }
    
     public static String getCurrentUserTZSIDKey() {
        List<User> userList = [Select TimeZoneSidKey FROM User where Id =: UserInfo.getUserId()];
        return userList[0].TimeZoneSidKey;
    }
    
   	public static String getSectionNameBySectionId(String sectionId) {
   		String objectName = (Id.valueOf(sectionId)).getSObjectType().getDescribe().getName();
        if(!objectNameToSectionNameMap.containsKey(objectName)) {
            return '';
        }
        return objectNameToSectionNameMap.get(objectName);
   	}
    
    public static Map<String, String> objectNameToSectionNameMap = new Map<String, String>{
        Constants.NAMESPACE + 'Service_Order_Header__c' => 'Service',
        Constants.NAMESPACE + 'Deal__c' => 'Deal',
        Constants.NAMESPACE + 'Deal_Finance__c' => 'Financing',
        Constants.NAMESPACE + 'Product__c' => 'Vendor product',
        Constants.NAMESPACE + 'CO_Header__c' => 'All'
    };
    
    public static Map<String, String> getLocaleStaticResourceData() {
        Map<String, String> localizedMap = new Map<String, String>();
        String userLocale = UserInfo.getLocale();
        List<StaticResource> staticResourceList = [SELECT SystemModStamp FROM StaticResource WHERE Name = 'Locale' limit 1];
        if(staticResourceList.size() > 0) {
            String urlFileRef = '/resource/' + String.valueOf(((DateTime)staticResourceList[0].get('SystemModStamp')).getTime())
                            + '/Locale/locale-' + userLocale + '.json';
	        PageReference pageRef = new PageReference(urlFileRef);
	        String resJsonBody;
	        try {
	        	if(!Test.isRunningTest()) {
	        		resJsonBody = pageRef.getContent().toString().replaceAll('\UFEFF', '');
	        	} else {
	        		resJsonBody = '{"Test" : "Test"}';
	        	}
	        } catch(Exception e) {
	            urlFileRef = '/resource/' + String.valueOf(((DateTime)staticResourceList[0].get('SystemModStamp')).getTime())
                            + '/Locale/locale-en_US.json';
                pageRef = new PageReference(urlFileRef);
                resJsonBody = pageRef.getContent().toString().replaceAll('\UFEFF', '');
	        }
	        localizedMap = (Map<String, String>) system.JSON.deserialize(resJsonBody, Map<String, String>.class);
        }
		return localizedMap;
    }
    
    /* This method is used to add idle time to salesforce execution similar to a thread sleep
    *  accepts a integer value of delay interval in milliseconds  
    */
    public static void sleepSystem(Integer delayInMilliseconds) {
        Long startingTime = System.now().getTime();
        delayInMilliseconds = delayInMilliseconds != null ? delayInMilliseconds : 0;  
        while (System.now().getTime() - startingTime < delayInMilliseconds)  {
                    // Do nothing until desired delay has passed
         }
    }
    
    /*
    * to format a date into a date string with separator passed as argument
    * like : dd(Separator)MM(Separator)YYYY
    */
    public static String getFormatedDateTimewithSeparator(Date dateObj, String separator) {
       String dateString =  BPUtility.getFormatedDateTime(datetime.newInstance(dateObj.year(), dateObj.month(), dateObj.day()) );
       return dateString.replace('/', separator);
    }

    public static void setTimeout(Integer timeInSeconds) {
        for(Long i = 0; i < (timeInSeconds * 1000 * 100 * 0.2); i++) {
            continue;
        }
    }
    
    public static void setTimeoutInMiliSecond(Integer timeInMiliSeconds) {
        for(Long i = 0; i < (timeInMiliSeconds * 100 * 0.2); i++) {
            continue;
        }
    }
    
    public static String formatToDecimal(Decimal decVal) {
    	if(decVal != null) {
			decVal = decVal.setScale(2, RoundingMode.HALF_UP);
			String formattedVal = (decVal.format().contains('.') ? decVal.format() : (decVal.format() +'.00'));
			String presicionVal = formattedVal.subString(formattedVal.indexOf('.') + 1, formattedVal.length());
			if(presicionVal.length() == 1 ) {
			    formattedVal += '0';
			}
			return formattedVal;
    	}
    	return '';	
    }

    public static String formatToDecimalForCSV(Decimal decVal) {
        String value = formatToDecimal(decVal);
    	return value.contains(',') ? '"'+value+'"' : value;
    }
    
    public static String getCronExpForGivenTime(Integer second) {
        DateTime dtVal = system.now().addSeconds(second);
        String strSchedule = String.valueOf(dtVal.second()) + ' ' + String.valueOf(dtVal.minute()) + ' ' + String.valueOf(dtVal.hour()) + 
                                ' ' + String.valueOf(dtVal.day()) + ' ' + String.valueOf(dtVal.month()) + ' ?' + ' ' + String.valueOf(dtVal.year());
        return strSchedule;
    }

    public static void abortAlreadyScheduleJobs(String jobName) {
        List<CronTrigger> alreadyScheduledJobs = [Select Id from CronTrigger where CronJobDetail.Name =: jobName];
        if(alreadyScheduledJobs.size() > 0) {
            system.abortJob(alreadyScheduledJobs[0].Id);    
        }
    }

    public static void updateRecordList(List<SObject> sObjectUpdateList, Integer reTryCount){
        DMLUtility.updateSobjectListWithRetry(sObjectUpdateList);
    }

    public static void updateList(List<SObject> sObjectUpdateList) {
    	if(sObjectUpdateList != null && sObjectUpdateList.size() > 0) { 
            String objApiName = String.valueOf(sObjectUpdateList[0].getSObjectType());
    	    if(AccessControl.ifObjectFieldIsUpdateable(objApiName) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
    		update sObjectUpdateList;
    	}
    }
    
    public static void abortScheduledJobByJobName(String scheduledJobName) {
    	for(CronTrigger cronJob : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduledJobName]) {
	    	System.AbortJob(cronJob.Id);
	   	}
	}
	
	public static void abortApexBatchJobByName(String batchApexClassName) {
    	List<String> statusToExclude = new List<String>{'Aborted', 'Completed', 'Failed'};
    	for(AsyncApexJob asyncJob : [Select Id from AsyncApexJob where Status Not IN: statusToExclude AND ApexClass.Name =: batchApexClassName]) {
	    	System.AbortJob(asyncJob.Id);
	   	}
	}
	
	public static sObject updateSparseFieldForRecord(sObject newRec, sObject oldRec, String updatedFieldAPIName, List<String> fieldAPINameList) {
	    String changedFieldString = '';
	    for(String fieldName : fieldAPINameList) {
            if(newRec.get(fieldName) != oldRec.get(fieldName)) {
                changedFieldString += fieldName + ',';
            }
	    }
	    if(String.isNotBlank((String)newRec.get(updatedFieldAPIName))) {
	        if(!(String.valueOf(newRec.get(updatedFieldAPIName)).contains(changedFieldString))) {
	            newRec.put(updatedFieldAPIName, newRec.get(updatedFieldAPIName) + changedFieldString);
	        }
        } else {
            newRec.put(updatedFieldAPIName, changedFieldString);
        }
	    return newRec;
	}

    public static Map<String, String> getExternalValueToBPValueMap(String valueType) {
		Map<String, External_To_BP_Value_Mapping__mdt> devNameToBPValueMap = External_To_BP_Value_Mapping__mdt.getAll();
		Map<String, String> extValueToBPValueMap = new Map<String, String>();
		
		for(String devName: devNameToBPValueMap.keySet()) {
			if(String.isBlank(valueType) || devNameToBPValueMap.get(devName).Type__c.equalsIgnoreCase(valueType)) {
				extValueToBPValueMap.put(devNameToBPValueMap.get(devName).External_Value__c, devNameToBPValueMap.get(devName).BP_Value__c);
			}
		}
		return extValueToBPValueMap;
	}

    public static Boolean isDecimal(String value){
        Boolean isDecimalString = true;
        try{
            Decimal.valueOf(value);
        } catch (Exception e) {
            isDecimalString = false;
        }
        return isDecimalString;
    }

    public static string getFormattedCurrencyValue(String value){
        String formattedValue = value;
        if(isDecimal(value)) {
            Decimal decimalvalue = Decimal.valueOf(value);
            formattedValue = decimalvalue < 0 ? '($' + formatToDecimal(decimalvalue * -1) + ')': '$' + formatToDecimal(decimalvalue);
        }
        return formattedValue;
    }

    public static string getLastModifiedBy(sObject sObjRec) {
        if(sObjRec != null) {
            return String.valueOf((sObjRec.get('Last_Modified_By__c') != null) ? sObjRec.getSObject('Last_Modified_By__r').get('Name') : sObjRec.getSObject('LastModifiedBy').get('Name'));
        }
        return null;
    }

    public static DateTime getLastModifiedDate(sObject sObjRec) {
        if(sObjRec != null) {
            return DateTime.valueOf((sObjRec.get('Last_Modified_Date__c') != null) ? sObjRec.get('Last_Modified_Date__c') : sObjRec.get('LastModifiedDate'));
        }
        return null;
    }

    public static String getLastModifiedDateStr(sObject sObjRec) {
        if(sObjRec != null) {
            return BPUtility.getFormatedDateTime(DateTime.valueOf((sObjRec.get('Last_Modified_Date__c') != null) ? 
                    sObjRec.get('Last_Modified_Date__c') : sObjRec.get('LastModifiedDate')));
        }
        return null;
    }

    public static String addNamespaceToQuery(String query, String namespace) {
        // Regular expression to match object and field names
        String regex = '(\\b\\w+(__c|__r)\\b)';
        // Matcher to find matches in the query
        Matcher m = Pattern.compile(regex).matcher(query);
        // Buffer to build the namespaced query
        String namespacedQuery = '';
        // Index to keep track of where we are in the original string
        Integer lastIndex = 0;
        // Loop through the matches
        while (m.find()) {
            // Add the part of the string before the match
            namespacedQuery += query.substring(lastIndex, m.start());
            // Add the namespace to the match
            namespacedQuery += namespace + m.group(0);
            // Update the index
            lastIndex = m.end();
        }
        // Append the rest of the query to the buffer
        namespacedQuery += query.substring(lastIndex);
        return namespacedQuery;
    }
    
    public static String getTrimedStringByGivenLimit(String inputStr, Integer maxSize) {
        if(String.isNotBlank(inputStr) && inputStr.length() > maxSize && maxSize > 0) {
            return inputStr.subString(0, maxSize);
        }
        return inputStr;
    }
}