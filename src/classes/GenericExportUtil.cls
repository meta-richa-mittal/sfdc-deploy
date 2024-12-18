/**
 * Author: Richa Mittal
 * Since: August 27, 2020
 * Name: GenericExportUtil
 * Description: Util class for exporting any file
**/
public without sharing class GenericExportUtil {
    
    public static String newLineSeparator = '\r\n';
	public static String NOT_APPLICABLE = 'N/A';
	public static Decimal MAX_ASYNC_HEAP_SIZE = 11500000;
	public static Decimal MAX_CPU_TIME = Limits.getLimitCpuTime() - (10*1000);
	public static String APEX_HEAP_SIZE_ERROR = 'Apex heap size too large';
	public static String APEX_CPU_TIME_LIMIT_ERROR = 'Apex CPU time limit exceeded';
	public static String STRING_LENGTH_EXCEEDS_MAX_ERROR = 'String length exceeds maximum';
	public static Set<String> DATA_ERROR_SET = new Set<String>{APEX_HEAP_SIZE_ERROR, APEX_CPU_TIME_LIMIT_ERROR, STRING_LENGTH_EXCEEDS_MAX_ERROR};
	public static Integer MAX_IMAGE_URL_COUNT = 20;
	public static String FILE_SEPARATOR_COMMA = ',';
    public static String FILE_SEPARATOR_PIPE = '|';
	public static String MOTORLOT_EXPORT = 'Motorlot';
	
	public static Map<String, String> fileSeparatorToFileSeparatorSymbolMap = new Map<String, String>{
																					'comma'	=>	',',
																					'pipe'	=>	'|',
																					'semi-column'	=>	';',
																					'space'	=>	'&nbsp',
																					'tab'	=>	'\t'
																				};
	
	public static Map<String, String> fileTypeToContentTypeMap = new Map<String, String>{
																        'csv'	=>	'text/csv',
																        'txt'	=>	'text/plain',
																        'pdf'	=>	'application/pdf',
																		'xlsx' => 'application/vnd.ms-excel'
																    };
																    
	public static Map<String, String> fileNameToFilePrefixMap = new Map<String, String>{
																        'INTEXT.CSV'	=>	'INTEXT'
																    };
	
	public static Integer UPDATE_RECORD_MAX_RETRY = 2;

	private static Map<String, String> objAPINameToHSReportObjNameMap = new Map<String, String>{
																			'Service_Order_Header__c' => 'Service Jobs',
																			'Customer_Owned_Unit__c' => 'Inventory Unit'
																		};

	public static Map<String, Map<String, String>> exportTypeToAvailableBPColumnNameToAPINameMap = new Map<String, Map<String, String>>{
										'VO' => new Map<String, String>{
																			'Part number' => 'Part__r.Part_Number__c',
																			'Description' => 'Part__r.Description__c',
																			'Vendor code' => 'Vendor_Order_Header__r.Vendor__r.Vendor_Code__c',
																			'Needed qty' => 'Need__c',
																			'Cost' => 'Cost__c',
																			'VO number' => 'Vendor_Order_Header__r.Name',
																			'Ordered date' => 'Vendor_Order_Header__r.Ordered_Date__c',
																			'Expected date' => 'Vendor_Order_Header__r.Expected_Date_Formula__c',
																			'MFG Part#' => 'Part__r.Mfg_Part__c'
																		}
	};

	public static FTP_Config__c getFTPConfigRec(String exportType) {
		if(!AccessControl.ifObjectFieldIsAccessible('FTP_Config__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<FTP_Config__c> ftpConfigList = [SELECT FTP_URL__c, FTP_Username__c, FTP_Password__c, Org_Name__c, Heroku_End_Point_URL__c, Port__c, 
												SFTP_Server__c, FTPS_Connection__c, Directory_Path__c FROM FTP_Config__c WHERE Name =: exportType];
		if(ftpConfigList.size() > 0) {
			return ftpConfigList[0];
		}
		return null; 
	}
	
	public static GE_File_Config__c getGenericFileConfig(String exportType) {
		if(!AccessControl.ifObjectFieldIsAccessible('GE_File_Config__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		if(!AccessControl.ifObjectFieldIsAccessible('GE_File_Detail__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<GE_File_Config__c> fileConfigList = [SELECT Object_API_Name__c, File_Separator__c, Where_Clause__c, Order_By_Clause__c, 
												Include_Images__c, Include_Timestamp__c, File_Content_Type__c, Use_Public_Image__c, 
												File_Name__c, Send_to_FTP__c, Include_Column_Header__c, Publish_In_Feed_URL__c, 
												Delimiter__c, Group_By_Field_API_Name__c, Filter__c, Filter__r.Field_Filter_Json__c, 
												Filter__r.Field_Filter_Json_2__c, Include_Image_URLs_In_One_Column__c, Image_Delimiter__c, 
												(Select Id, Data_Type__c, File_Column_Label__c, Field_API_Name__c, Other_Object_API_Name__c,  
                                                Active__c, Default_Value__c, File_Column_Name__c, Order_Number__c, Image_Column__c FROM GE_File_Details__r 
												WHERE Active__c = true ORDER BY Order_Number__c ASC ) 
                                                FROM GE_File_Config__c where File_Name__c =: exportType];
		if(fileConfigList.size() > 0) {
			return fileConfigList[0];
		}
		return null; 
	}

	public static List<GE_File_Config__c> getFileConfigUsingFilter(Map<String, Object> fieldsMap, Boolean performChildQuery) {
		if(!AccessControl.ifObjectFieldIsAccessible('GE_File_Config__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		if(!AccessControl.ifObjectFieldIsAccessible('GE_File_Detail__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		
		String query = 'SELECT ' + String.join(GenericExportWrapper.fileConfigFields, ', ');
		if(performChildQuery) query += ', ' + '(SELECT ' + String.join(GenericExportWrapper.fileDetailFields, ', ') + ' FROM GE_File_Details__r Order By Order_Number__c)';
		query += ' FROM GE_File_Config__c ' + SOQLUtil.getWhereClause(fieldsMap);
    	return SOQLUtility.getQueryResults('GE_File_Config__c', query);
	}

	public static String createQueryForDataToExport(GE_File_Config__c fileConfigRec, STring exportType, Integer partIndex) {
		String query = 'SELECT ';
	        
		Set<String> fieldsToQuerySet = new Set<String>();
		for(GE_File_Detail__c fileDetailRec: fileConfigRec.GE_File_Details__r) {
			if(String.isBlank(fileDetailRec.Other_Object_API_Name__c) && String.isNotBlank(fileDetailRec.Field_API_Name__c) && !fileDetailRec.Field_API_Name__c.contains('__child.')) {
				for(String referencedFieldAPIName: fileDetailRec.Field_API_Name__c.split('\\/')) {
					if(String.isNotBlank(referencedFieldAPIName)) {
						fieldsToQuerySet.add(referencedFieldAPIName);
					}
				}
			}
		}

		if(String.isNotBlank(fileConfigRec.Group_By_Field_API_Name__c)) {
			fieldsToQuerySet.add(fileConfigRec.Group_By_Field_API_Name__c);
		}
		
		query += String.join(new List<String>(fieldsToQuerySet), ',');
		query += ' FROM ' + fileConfigRec.Object_API_Name__c;
		
		if(String.isNotBlank(fileConfigRec.Where_Clause__c)) {
			query += ' WHERE ' + fileConfigRec.Where_Clause__c;
		}
		query = getPublishInFeedWhereClause(fileConfigRec.Object_API_Name__c, query);
		if(exportType == 'INTEXT.CSV') {
			query = getIntextFileWhereClause(query, partIndex);
		}
		
		if(String.isNotBlank(fileConfigRec.Group_By_Field_API_Name__c)) {
			if(String.isNotBlank(fileConfigRec.Order_By_Clause__c)) {
				List<String> orderClauseList = fileConfigRec.Order_By_Clause__c.split(' ');
				if(!orderClauseList.isEmpty() && !orderClauseList[0].equalsIgnoreCase(fileConfigRec.Group_By_Field_API_Name__c)) {
					query += ' ORDER BY ' + fileConfigRec.Group_By_Field_API_Name__c;
				}
			} else {
				query += ' ORDER BY ' + fileConfigRec.Group_By_Field_API_Name__c;
			}
		}
		if(String.isNotBlank(fileConfigRec.Order_By_Clause__c)) {
			if(query.containsIgnoreCase('ORDER BY')) {
				query += ', ' + fileConfigRec.Order_By_Clause__c;
			} else {
				query += ' ORDER BY ' + fileConfigRec.Order_By_Clause__c;
			}
		} else if(HomeSearchUtil.searchableObjectToUniqueValueFieldMap.containsKey(fileConfigRec.Object_API_Name__c)) {
			if(query.containsIgnoreCase('ORDER BY')) {
				query += ', ' + HomeSearchUtil.searchableObjectToUniqueValueFieldMap.get(fileConfigRec.Object_API_Name__c) + ' ASC';
			} else {
				query += ' ORDER BY ' + HomeSearchUtil.searchableObjectToUniqueValueFieldMap.get(fileConfigRec.Object_API_Name__c) + ' ASC';
			}
		}
		
		if(exportType == 'INTEXT.CSV') {
			query += ' LIMIT ' + IntextPartInventoryScript.Max_LIMIT;
		}
		system.debug('query****: ' + query);
		return query;
	}

	private static String getIntextFileWhereClause(String query, Integer partIndex) {
    	if(query.containsIgnoreCase('where')) {
    		query += ' AND';
    	} else {
    		query += ' WHERE';
    	}
    	query += ' Is_Included_In_Intext_Inventory__c = false AND Intext_Part_Index__c  = '+ partIndex;
    	return query;
    }

	private static String getPublishInFeedWhereClause(String objAPIName, String query) {
        if(GeneralConfiguration.alwaysObeyPublishInFeeds() && String.isNotBlank(objAPIName) && (objAPIName.equalsIgnoreCase('Customer_Owned_Unit__c') || objAPIName.equalsIgnoreCase('Part__c'))) {
            query += query.containsIgnoreCase('where') ? ' AND' : ' WHERE';
            query += ' Publish_in_feeds__c = true';
        }
        return query;
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

	public static Map<Id, List<String>> getRecIdToImageUrlListMap(GE_File_Config__c fileConfigRec, List<String> recIdList) {
		Map<Id, List<String>> recIdToImageUrlListMap = new Map<Id, List<String>>();
		if(!recIdList.isEmpty()) {
			String configValue = GeneralConfiguration.getConfigurationByName(GeneralConfiguration.INCLUDE_PRIMARY_IMAGE_IN_FTP_FEED);
			Boolean includeOnlyPrimaryImage = String.isNotBlank(configValue) ? Boolean.valueOf(configValue) : false;
			Map<Id, List<UnitWrapper.Documents>> unitIdToImageListMap = COService.getUnitImages(recIdList, includeOnlyPrimaryImage);
			for(Id recId: unitIdToImageListMap.keySet()) {
				List<String> imageUrlList = new List<String>();
				for(UnitWrapper.Documents doc: unitIdToImageListMap.get(recId)) {
					imageUrlList.add(doc.PublicUrl);
				}
				recIdToImageUrlListMap.put(recId, imageUrlList);
			}
		}
		return recIdToImageUrlListMap;
	}

	public static List<String> getRecordsIdList(GE_File_Config__c fileConfigRec, List<sObject> recordList) {
		Boolean isCreateRecIdList = fileConfigRec.Include_Images__c;
		if(!isCreateRecIdList && fileConfigRec.Filter__c != null && fileConfigRec.GE_File_Details__r != null) {
			for(GE_File_Detail__c fileDetailRec: fileConfigRec.GE_File_Details__r) {
				if(String.isNotBlank(fileDetailRec.Field_API_Name__c) && fileDetailRec.Field_API_Name__c.contains('__child.') && objAPINameToHSReportObjNameMap.containsKey(fileConfigRec.Object_API_Name__c)) {
					String objName = objAPINameToHSReportObjNameMap.get(fileConfigRec.Object_API_Name__c);
					if(!HomeSearchReportUtil.objNameToChildObjHSColumnListMap.containsKey(objName)) {
						HomeSearchReportUtil.objNameToChildObjHSColumnListMap.put(objName, new List<HomeSearch_Grid_Column__mdt>());
					}
					HomeSearchReportUtil.objNameToChildObjHSColumnListMap.get(objName).add(new HomeSearch_Grid_Column__mdt(Label = fileDetailRec.File_Column_Label__c, Field_API_Name__c = fileDetailRec.Field_API_Name__c));
				}
			}
		}
		List<String> recIdList = new List<String>();
		if(isCreateRecIdList || !HomeSearchReportUtil.objNameToChildObjHSColumnListMap.isEmpty()) {
			for(sObject rec: recordList) {
				recIdList.add(rec.Id);
			}
		}
		return recIdList;
	}

	public static Map<Id, Map<String, Decimal>> getRecIdToChildObjAggrResultMap(GE_File_Config__c fileConfigRec, List<String> recIdList) {
		Map<Id, Map<String, Decimal>> recIdToChildObjAggrLabelToValueMap = new Map<Id, Map<String, Decimal>>();
		if(!recIdList.isEmpty() && fileConfigRec.Filter__c != null) {
			String fieldFilterJson = ((fileConfigRec.Filter__r.Field_Filter_Json__c != null ? fileConfigRec.Filter__r.Field_Filter_Json__c : '' ) + (fileConfigRec.Filter__r.Field_Filter_Json_2__c  != null ? fileConfigRec.Filter__r.Field_Filter_Json_2__c : ''));
			HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(fieldFilterJson, HomeSearchFilterWrapper.class);
			Map<String, Map<String, String>> childObjAPINameToFieldAPINameToLabelMap = new Map<String, Map<String, String>>();
			String objName = objAPINameToHSReportObjNameMap.get(fileConfigRec.Object_API_Name__c);
			List<HomeSearch_Grid_Column__mdt> hsColumnList = HomeSearchReportUtil.objNameToChildObjHSColumnListMap.get(objName);
			for(HomeSearch_Grid_Column__mdt hsColumn : hsColumnList) {
			
				List<String> objAndFieldAPINameList = hsColumn.Field_API_Name__c.split('__child.');
				if(!childObjAPINameToFieldAPINameToLabelMap.containsKey(objAndFieldAPINameList[0])) {
					childObjAPINameToFieldAPINameToLabelMap.put(objAndFieldAPINameList[0], new Map<String, String>());
				}
				
				Map<String, String> fieldAPINameToLabelMap = childObjAPINameToFieldAPINameToLabelMap.get(objAndFieldAPINameList[0]);
				fieldAPINameToLabelMap.put(objAndFieldAPINameList[1], hsColumn.Label.replaceAll(' ', '_'));
			}

			if(childObjAPINameToFieldAPINameToLabelMap.size() > 0) {
				Map<String, List<HomeSearchFilterInterface.FieldFilter>> objNameToFieldFilterListMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
				
				for(String childObjName : childObjAPINameToFieldAPINameToLabelMap.keySet()) {
					String parentObjAPIName = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName);
					String whereClause = HomeSearchReportUtil.getWhereClauseForChildObjAggregate(objName, parentObjAPIName.replace('__c', '__r'), childObjName, objNameToFieldFilterListMap.get(objName), filterWrapperObj);
					String query = '';
					query += 'SELECT ' + parentObjAPIName + ' Parent_Object, ';
					Map<String, String> childObjFieldAPINameToLabelMap = childObjAPINameToFieldAPINameToLabelMap.get(childObjName);
					for(String fieldName: childObjFieldAPINameToLabelMap.keySet()) {
						query += 'SUM(' + fieldName + ') ' + childObjFieldAPINameToLabelMap.get(fieldName) + ', ';
					}
					query = query.substring(0, query.length() - 2);
					query += ' FROM ' + childObjName;

					if(String.isNotBlank(whereClause)) {
						whereClause += ' AND ' + parentObjAPIName + ' IN: recIdList';
					} else {
						whereClause = parentObjAPIName + ' IN: recIdList';
					}

					query += ' ' + whereClause;
					query += ' GROUP BY ' + parentObjAPIName;
					system.debug('Aggregate Query: ' + Database.query(query));
					for(AggregateResult aggregate : Database.query(query)) {
						Id recId = (Id)aggregate.get('Parent_Object');
						if(recId != null) {
							if(!recIdToChildObjAggrLabelToValueMap.containsKey(recId)) {
								recIdToChildObjAggrLabelToValueMap.put(recId, new Map<String, Decimal>());
							}
							for(String fieldName: childObjFieldAPINameToLabelMap.keySet()) {
								String fieldLabel = childObjFieldAPINameToLabelMap.get(fieldName);
								if(!recIdToChildObjAggrLabelToValueMap.get(recId).containsKey(fieldLabel)) {
									recIdToChildObjAggrLabelToValueMap.get(recId).put(fieldLabel, 0);
								}
								if(aggregate.get(fieldLabel) != null) {
									Decimal aggTotal = recIdToChildObjAggrLabelToValueMap.get(recId).get(fieldLabel);
									recIdToChildObjAggrLabelToValueMap.get(recId).put(fieldLabel, (aggTotal + (Decimal)aggregate.get(fieldLabel)));
								}
							}
						}
					}
				}
			}
		}
		return recIdToChildObjAggrLabelToValueMap;
	}
	
	public static String getImagePublicURL(String imageDistPublicURL, String versionId) {
		system.debug('****' + imageDistPublicURL);
		String orgId15Chars = UserInfo.getOrganizationId().substring(0, 15);
		String orgIdLast12Chars = orgId15Chars.substring(3, 15);
		Integer index = imageDistPublicURL.indexOf(orgIdLast12Chars);
		if(index == -1) return null;

		String urlHash = imageDistPublicURL.substring((index + orgIdLast12Chars.length()), imageDistPublicURL.length());
		return URL.getOrgDomainURL().toExternalForm() + '/sfc/dist/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId=' + versionId + '&d=' + urlHash + '&oid=' + orgId15Chars;
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

	public static Boolean isMultiImageColumn(GE_File_Config__c fileConfigRec, GE_File_Detail__c fileDetailRec) {
		String columnLabel = String.isNotBlank(fileDetailRec.File_Column_Label__c) ? fileDetailRec.File_Column_Label__c : fileDetailRec.File_Column_Name__c;
		String configValue = GeneralConfiguration.getConfigurationByName(GeneralConfiguration.INCLUDE_PRIMARY_IMAGE_IN_FTP_FEED);
		Boolean includeOnlyPrimaryImage = String.isNotBlank(configValue) ? Boolean.valueOf(configValue) : false;
		return (!fileConfigRec.Include_Image_URLs_In_One_Column__c && fileDetailRec.Image_Column__c && !includeOnlyPrimaryImage);
	}
}