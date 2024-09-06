/**
 * Author: Richa Mittal
 * Since: August 27, 2020
 * Name: GenericExportUtil
 * Description: Util class for exporting any file
**/
public without sharing class GenericExportUtil {
    
    public static String newLineSeparator = '\r\n';
	
	public static Map<String, String> fileSeparatorToFileSeparatorSymbolMap = new Map<String, String>{
																					'comma'	=>	',',
																					'pipe'	=>	'|',
																					'semi-column'	=>	';'
																				};
	
	public static Map<String, String> fileTypeToContentTypeMap = new Map<String, String>{
																        'csv'	=>	'text/csv',
																        'txt'	=>	'text/plain',
																        'pdf'	=>	'application/pdf'
																    };
																    
	public static Map<String, String> fileNameToFilePrefixMap = new Map<String, String>{
																        'INTEXT.CSV'	=>	'INTEXT'
																    };
	public static Integer UPDATE_RECORD_MAX_RETRY = 2;

	public static FTP_Config__c getFTPConfigRec(String exportType) {
		if(!AccessControl.ifObjectFieldIsAccessible('FTP_Config__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<FTP_Config__c> ftpConfigList = [SELECT FTP_URL__c, FTP_Username__c, FTP_Password__c, Org_Name__c, Heroku_End_Point_URL__c, Port__c, 
												SFTP_Server__c, Directory_Path__c FROM FTP_Config__c WHERE Name =: exportType];
		if(ftpConfigList.size() > 0) {
			return ftpConfigList[0];
		}
		return null; 
	}
	
	public static GE_File_Config__c getGenericFileConfig(String exportType) {
		if(!AccessControl.ifObjectFieldIsAccessible('GE_File_Config__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		if(!AccessControl.ifObjectFieldIsAccessible('GE_File_Detail__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<GE_File_Config__c> fileConfigList = [SELECT Object_API_Name__c, File_Separator__c, Where_Clause__c, Order_By_Clause__c, Include_Images__c, Include_Timestamp__c, 
												File_Content_Type__c, Use_Public_Image__c, File_Name__c, Send_to_FTP__c, Include_Column_Header__c, Publish_In_Feed_URL__c,
												(Select Id, Data_Type__c, File_Column_Label__c, Field_API_Name__c, Other_Object_API_Name__c,  
                                                Active__c, Default_Value__c FROM GE_File_Details__r WHERE Active__c = true ORDER BY Order_Number__c ASC ) 
                                                FROM GE_File_Config__c where File_Name__c =: exportType];
		if(fileConfigList.size() > 0) {
			return fileConfigList[0];
		}
		return null; 
	}
	
	public static String createQueryToFetchImages(GE_File_Config__c fileConfigRec, List<sObject> recordList) {
		String query = '';
		
		if(fileConfigRec.Include_Images__c) {
	    	// query images
	    	query = 'SELECT Id, (SELECT ';
	    	if(fileConfigRec.Use_Public_Image__c) {
	    		// query documents
	    		query += 'Public_Image_URL__c FROM Documents__r Order by Is_Primary__c DESC, CreatedDate ASC)';
	    	} else {
	    		// query attachments
	    		query += 'Id FROM Attachments Order by CreatedDate ASC)';
	    	}
	    	query += ' FROM ' + fileConfigRec.Object_API_Name__c;
	    	query += ' WHERE Id IN :recordList';
	    }
		return query;
	}
	
	public static Map<String, sObject> getOtherObjectRecordMap(Map<String, List<String>> otherObjAPINameToFieldAPINameListMap) {
		Map<String, sObject> otherObjAPINameToRecMap = new Map<String, sObject>();
		if(otherObjAPINameToFieldAPINameListMap.size() > 0) {
        	// query other object data
        	for(String objectAPIName: otherObjAPINameToFieldAPINameListMap.keySet()) {
        		String query = 'SELECT ' + String.join(otherObjAPINameToFieldAPINameListMap.get(objectAPIName), ',') + ' FROM ' + objectAPIName + ' LIMIT 1'; // assuming single record will be of use
        		List<sObject> sObjectList = Database.query(query);
        		if(sObjectList.size() > 0) {
        			otherObjAPINameToRecMap.put(objectAPIName, sObjectList[0]);
        		}
        	}
        }
		return otherObjAPINameToRecMap;
	}
	
	public static Map<String, List<GE_File_Column_Override_Info__c>> getFileDetailToColOverrideInfoListMap(Set<String> fileDetailIdSet) {
		List<GE_File_Column_Override_Info__c> colOverrideInfoList = [SELECT Actual_Column_Value__c, Override_Column_Value__c, GE_File_Detail__c FROM GE_File_Column_Override_Info__c
        																WHERE GE_File_Detail__c IN :fileDetailIdSet];
        
        Map<String, List<GE_File_Column_Override_Info__c>> fileDetailToColOverrideInfoListMap = new Map<String, List<GE_File_Column_Override_Info__c>>();
        for(GE_File_Column_Override_Info__c overrideInfoRec: colOverrideInfoList) {
        	if(!fileDetailToColOverrideInfoListMap.containsKey(overrideInfoRec.GE_File_Detail__c)) {
        		fileDetailToColOverrideInfoListMap.put(overrideInfoRec.GE_File_Detail__c, new List<GE_File_Column_Override_Info__c>());
        	}
        	fileDetailToColOverrideInfoListMap.get(overrideInfoRec.GE_File_Detail__c).add(overrideInfoRec);
        }
        return fileDetailToColOverrideInfoListMap;
	}
	
	public static String getAttachmentName(String fileType, DateTime dateTimeValue) {
        return (String.isNotBlank(fileType) ? fileType + '_' : '') + (dateTimeValue != null ? dateTimeValue.format('yyyyMMdd') : Datetime.now().format('yyyyMMdd'));
	}

	public static String getAttachmentNameWithTime(String fileType, DateTime dateTimeValue) {
        return (String.isNotBlank(fileType) ? fileType + '_' : '') + (dateTimeValue != null ? dateTimeValue.format('yyyyMMdd_HHmmss') : Datetime.now().format('yyyyMMdd_HHmmss'));
    }

	public static void updatePartRecords(List<sObject> sObjectUpdateList, Integer reTryCount) {
        try {
            PartTriggerHelper.isForceStopTrigger = true;
			BPUtility.updateList(sObjectUpdateList); 
            PartTriggerHelper.isForceStopTrigger = false;
        } catch (Exception e) {
            if(e.getMessage().contains('UNABLE_TO_LOCK_ROW') && reTryCount < UPDATE_RECORD_MAX_RETRY) {
				BPUtility.setTimeout(2);
				updatePartRecords(sObjectUpdateList, reTryCount + 1);// Retry logic for unable to lock row issue 
            }
        }
    }
}