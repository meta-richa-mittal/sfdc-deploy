/**
 * Author: Richa Mittal
 * Since: August 25, 2020
 * Name: GenericExportService
 * Description: Service class for generating any file content
**/
public without sharing class GenericExportService {

    public static GenericExportBatch exportBatchObj;

	public static String getHeaders(GE_File_Config__c fileConfigRec) {
		if(!fileConfigRec.Include_Column_Header__c) {
			return '';
		}
		List<String> headerList = new List<String>();
        for(GE_File_Detail__c fileDetailRec: fileConfigRec.GE_File_Details__r) {
            String columnLabel = String.isNotBlank(fileDetailRec.File_Column_Label__c) ? fileDetailRec.File_Column_Label__c : fileDetailRec.File_Column_Name__c;
        	if(GenericExportUtil.isMultiImageColumn(fileConfigRec, fileDetailRec)) {
                for(Integer i=1; i<=GenericExportUtil.MAX_IMAGE_URL_COUNT; i++) {
                    headerList.add(columnLabel + '_' + i);
                }
            } else {
                headerList.add(columnLabel);
            }
        }

        String fileSeparator = GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.containsKey(fileConfigRec.File_Separator__c) ? 
        										GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.get(fileConfigRec.File_Separator__c) : 
                                                (fileConfigRec.File_Separator__c.equalsIgnoreCase('other') ? fileConfigRec.Delimiter__c : fileConfigRec.File_Separator__c);
        return String.join(headerList, fileSeparator);
	}
	
    public static String createFileData(GE_File_Config__c fileConfigRec, List<sObject> recordList, Map<Id, List<String>> recIdToImageUrlListMap, GenericExportBatch exportBatchObj) {
        exportBatchObj = exportBatchObj;
        String fileData = '';
        String fileSeparator = GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.containsKey(fileConfigRec.File_Separator__c) ? 
        										GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.get(fileConfigRec.File_Separator__c) : 
                                                (fileConfigRec.File_Separator__c.equalsIgnoreCase('Other') ? fileConfigRec.Delimiter__c : fileConfigRec.File_Separator__c);
        
        Map<String, List<String>> otherObjAPINameToFieldAPINameListMap = new Map<String, List<String>>();
        Set<String> fileDetailIdSet = new Set<String>();
        Map<String, List<GE_File_Column_Override_Info__c>> fileDetailToColOverrideInfoListMap = new Map<String, List<GE_File_Column_Override_Info__c>>();
        
        for(GE_File_Detail__c fileDetailRec: fileConfigRec.GE_File_Details__r) {
            if(String.isNotBlank(fileDetailRec.Other_Object_API_Name__c) && String.isNotBlank(fileDetailRec.Field_API_Name__c)) {
            	if(!otherObjAPINameToFieldAPINameListMap.containsKey(fileDetailRec.Other_Object_API_Name__c)) {
            		otherObjAPINameToFieldAPINameListMap.put(fileDetailRec.Other_Object_API_Name__c, new List<String>());
            	}
            	otherObjAPINameToFieldAPINameListMap.get(fileDetailRec.Other_Object_API_Name__c).add(fileDetailRec.Field_API_Name__c);
            }
            fileDetailIdSet.add(fileDetailRec.Id);
        }
        
        // get other objects data
        Map<String, sObject> otherObjectAPINameToRecordMap = GenericExportUtil.getOtherObjectRecordMap(otherObjAPINameToFieldAPINameListMap);
        
        // get column override info data
        if(fileDetailIdSet.size() > 0) {
        	fileDetailToColOverrideInfoListMap = GenericExportUtil.getFileDetailToColOverrideInfoListMap(fileDetailIdSet);
        }
        
        if(fileConfigRec.Group_By_Field_API_Name__c != null && exportBatchObj.groupByFileDetailRec == null) {
            exportBatchObj.groupByFileDetailRec = new GE_File_Detail__c(Field_API_Name__c = fileConfigRec.Group_By_Field_API_Name__c);
        }
        for(sObject record: recordList) {
            if(fileConfigRec.Group_By_Field_API_Name__c != null) {
                exportBatchObj.oldGroupByFieldValue = exportBatchObj.groupByFieldValue;
                exportBatchObj.groupByFieldValue = getFieldValueFromSObject(record, exportBatchObj.groupByFileDetailRec, null);
    
                if(exportBatchObj.oldGroupByFieldValue != exportBatchObj.groupByFieldValue) {
                    fileData += GenericExportUtil.newLineSeparator;
                    fileData += exportBatchObj.groupByFieldValue;
                    fileData += GenericExportUtil.newLineSeparator;
                }
            }
            
            List<GE_File_Detail__c> geFileDetailRecList = fileConfigRec.GE_File_Details__r != null ? fileConfigRec.GE_File_Details__r : new List<GE_File_Detail__c>();
            for(Integer i = 0; i < geFileDetailRecList.Size(); i++) {
            	GE_File_Detail__c fileDetailRec = geFileDetailRecList[i];
            	List<GE_File_Column_Override_Info__c> overrideInfoList = fileDetailToColOverrideInfoListMap.containsKey(fileDetailRec.Id) ? 
        																	fileDetailToColOverrideInfoListMap.get(fileDetailRec.Id) : null;
        		List<String> imageUrlList = (recIdToImageUrlListMap != null && recIdToImageUrlListMap.containsKey(String.valueOf(record.get('Id')))) ?
                                                recIdToImageUrlListMap.get(String.valueOf(record.get('Id'))) : null;
        		
        		sObject otherObjectRecord = otherObjectAPINameToRecordMap.containsKey(fileDetailRec.Other_Object_API_Name__c) ?
        										otherObjectAPINameToRecordMap.get(fileDetailRec.Other_Object_API_Name__c) : null;
        		
                String columnLabel = String.isNotBlank(fileDetailRec.File_Column_Label__c) ? fileDetailRec.File_Column_Label__c : fileDetailRec.File_Column_Name__c;
                if(GenericExportUtil.isMultiImageColumn(fileConfigRec, fileDetailRec)) {
                    for(Integer j=0; j<GenericExportUtil.MAX_IMAGE_URL_COUNT; j++) {
                        String columnValue = (imageUrlList != null && imageUrlList.size() > j && String.isNotBlank(imageUrlList[j]) ? imageUrlList[j] : '').escapeCsv();
                        fileData += columnValue;
                        fileData += (j == (GenericExportUtil.MAX_IMAGE_URL_COUNT - 1)) ? '' : fileSeparator;
                    }
                } else {
                    String imageURLSeparator = fileConfigRec.File_Name__c.containsIgnoreCase(GenericExportUtil.MOTORLOT_EXPORT) ? 
                                                GenericExportUtil.FILE_SEPARATOR_PIPE : GenericExportUtil.FILE_SEPARATOR_COMMA;
                    String columnValue = getFileColumnValue(record, fileDetailRec, overrideInfoList, imageUrlList, otherObjectRecord, imageURLSeparator).escapeCsv();
                    if(columnValue.contains(';') && !columnValue.contains('"')) {
                        columnValue = '"' + columnValue + '"';
                    }
                    fileData += columnValue;
                }
        		fileData += (i == (geFileDetailRecList.Size() - 1)) ? '' : fileSeparator;
            }
            fileData += GenericExportUtil.newLineSeparator;
            
            if(fileConfigRec.File_Name__c == 'INTEXT.CSV') {
            	record.put('Is_Included_In_Intext_Inventory__c', true);
            }
        }
        return fileData;
    }
    
    public static String createAttachment(String fileContent, GE_File_Config__c fileConfigRec) {
        Attachment attachment = new Attachment();
        attachment.ParentId = getParentId(); 
        if(fileConfigRec.Include_Timestamp__c) {
            fileConfigRec.File_Name__c = fileConfigRec.File_Name__c.containsIgnoreCase(fileConfigRec.File_Content_Type__c) ? 
                                            (fileConfigRec.File_Name__c).removeEnd('.' + fileConfigRec.File_Content_Type__c) : fileConfigRec.File_Name__c;
            attachment.Name = GenericExportUtil.getAttachmentNameWithTime(fileConfigRec.File_Name__c, Datetime.now()) + '.' + fileConfigRec.File_Content_Type__c;
        } else {
            attachment.Name = fileConfigRec.File_Name__c.containsIgnoreCase(fileConfigRec.File_Content_Type__c) ? 
                                fileConfigRec.File_Name__c : fileConfigRec.File_Name__c + '.' + fileConfigRec.File_Content_Type__c;
        }
        
        
        attachment.ContentType = GenericExportUtil.fileTypeToContentTypeMap.containsKey(fileConfigRec.File_Content_Type__c) ? 
        							GenericExportUtil.fileTypeToContentTypeMap.get(fileConfigRec.File_Content_Type__c) : 'text/csv';
        attachment.Body = Blob.valueOf(fileContent);
        DMLUtility.insertSobjectList('Attachment', attachment);
        return attachment.Id;
    }
    
    public static String createAttachment(String fileContent, String fileType, GE_File_Config__c fileConfigRec, Integer batchNumber, DateTime dateOfFileData) {
        Attachment attachment = new Attachment();
        attachment.ParentId = getParentId(); 
        attachment.ContentType = GenericExportUtil.fileTypeToContentTypeMap.containsKey(fileConfigRec.File_Content_Type__c) ? 
        							GenericExportUtil.fileTypeToContentTypeMap.get(fileConfigRec.File_Content_Type__c) : 'text/csv';
        
        dateOfFileData = dateOfFileData != null ? dateOfFileData : system.now();
        String batchNumberInTwoDigits = '';
        if(batchNumber != null) {
        	batchNumberInTwoDigits = '_' + ((batchNumber > 9) ? String.valueOf(batchNumber) : ('0' + batchNumber));
        }
        attachment.Name = GenericExportUtil.getAttachmentName(fileType, dateOfFileData) + batchNumberInTwoDigits + '.' + fileConfigRec.File_Content_Type__c;
        attachment.Body = Blob.valueOf(fileContent);
        DMLUtility.insertSobjectList('Attachment', attachment);
        return attachment.Id;
    }
    
    public static String getParentId() {
        if(!AccessControl.ifObjectFieldIsAccessible('File_Storage__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<File_Storage__c> fileStorageList = [SELECT Id FROM File_Storage__c WHERE Name__c = 'FTP' LIMIT 1];
        
        File_Storage__c fileStorageRec = new File_Storage__c();
        if(fileStorageList.size() > 0) {
            fileStorageRec = fileStorageList[0];
        } else {
            fileStorageRec.Name__c = 'FTP';
            DMLUtility.insertSobjectList('File_Storage__c', fileStorageRec);
        }
        return fileStorageRec.Id;
    }
    
    private static String getFileColumnValue(sObject record, GE_File_Detail__c fileDetailRec, List<GE_File_Column_Override_Info__c> overrideInfoList, 
    											List<String> imageUrlList, sObject otherObjectRecord, String imageURLSeparator) {
    	String columnValue = '';
    	if(String.isNotBlank(fileDetailRec.Default_Value__c)) {
			columnValue = fileDetailRec.Default_Value__c;
		} else if(String.isNotBlank(fileDetailRec.Other_Object_API_Name__c)) {
			if(otherObjectRecord != null) {
				columnValue = getFieldValueFromSObject(otherObjectRecord, fileDetailRec, overrideInfoList);
			}
		} else if(String.isBlank(fileDetailRec.Field_API_Name__c) && imageUrlList != null) {
			// Image
            columnValue = String.join(imageUrlList, imageURLSeparator);
		} else if(String.isNotBlank(fileDetailRec.Field_API_Name__c)) {
			sObject tempRecord = record; // Added to create new reference
			columnValue = getFieldValueFromSObject(tempRecord, fileDetailRec, overrideInfoList);
		}
		return columnValue;
    }
    
    private static String getFieldValueFromSObject(sObject tempRecord, GE_File_Detail__c fileDetailRec, List<GE_File_Column_Override_Info__c> overrideInfoList) {
    	String formattedValue = '';
    	sObject tempRecordCopy = tempRecord; // create copy of the record
    	for(String referencedFieldAPIName: fileDetailRec.Field_API_Name__c.split('\\/')) {
    		if(String.isNotBlank(referencedFieldAPIName)) {
    			referencedFieldAPIName = referencedFieldAPIName.trim();
    			List<String> fieldsList = referencedFieldAPIName.split('\\.');
				for(Integer i = 0; i < fieldsList.size(); i++) {
					if(i == fieldsList.size() - 1) {
						Object fieldValue = (tempRecord != null && tempRecord.get(fieldsList[i]) != null) ? tempRecord.get(fieldsList[i]) : '';
						
						if(String.isNotBlank(String.valueOf(fieldValue))) {
							formattedValue = getFormattedData(fileDetailRec, fieldValue, overrideInfoList);
						}
						if(String.isNotBlank(formattedValue)) {
							return formattedValue;
						}
						tempRecord = tempRecordCopy; // updating tempRecord to its initial value
					} else if(tempRecord != null) {
						tempRecord = tempRecord.getSObject(fieldsList[i]);
					}
				}
    		}
    	}
    	
		return formattedValue;
    }
    
    private static String getFormattedData(GE_File_Detail__c fileDetailRec, Object fieldValue, List<GE_File_Column_Override_Info__c> overrideInfoList) {
    	if(fieldValue == null) return '';
    	
    	if(overrideInfoList != null && overrideInfoList.size() > 0) {
    		Map<String, String> actualColValueToOverrideColValueMap = new Map<String, String>();
    		for(GE_File_Column_Override_Info__c colInfoRec: overrideInfoList) {
    			actualColValueToOverrideColValueMap.put((colInfoRec.Actual_Column_Value__c).toLowerCase(), colInfoRec.Override_Column_Value__c);
    		}
    		
    		if(actualColValueToOverrideColValueMap.containsKey(String.valueOf(fieldValue).toLowerCase())) {
    			return String.valueOf(actualColValueToOverrideColValueMap.get(String.valueOf(fieldValue).toLowerCase()));
    		}
    	} else {
    		if(fileDetailRec.Data_Type__c == 'Date') {
	    		return String.isNotBlank(String.valueOf(fieldValue)) ? Date.valueOf(fieldValue).format() : '';
	    	} else if(fileDetailRec.Data_Type__c == 'Date/Time') {
	    		return String.isNotBlank(String.valueOf(fieldValue)) ? DateTime.valueOf(fieldValue).format() : '';
	    	} else if(fileDetailRec.Data_Type__c == 'Integer') {
	    		return String.isNotBlank(String.valueOf(fieldValue)) ? String.valueOf(Integer.valueOf(fieldValue)) : '';
	    	}
    	}
    	return String.valueOf(fieldValue);
    }
    
    public static void sendFileToFTP(String exportType, String attachmentIdsString) {
        FTPWrapper ftpObj = new FTPWrapper(exportType, attachmentIdsString);
        if(exportType != 'INTEXT.CSV') {
            List<Attachment> attachList = [SELECT Name, Body FROM Attachment WHERE Id =: attachmentIdsString limit 1];
            if(!attachList.isEmpty()) {
                ftpObj.FileName = attachList[0].Name;
            } else {
                ftpObj.FileName = exportType;
            }
        }
        String ftpDetailJSON = BPUtility.getEncodedString(System.JSON.serialize(ftpObj));
        FTP_Config__c ftpConfigRec = GenericExportUtil.getFTPConfigRec(exportType);
        if(ftpConfigRec != null) {
            String endpoint = ftpConfigRec.Heroku_End_Point_URL__c + '/' + ftpDetailJSON;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'application/json');
            if(!Test.isRunningTest()) {
                HttpResponse res = h.send(req);
                if(res.getStatusCode() != 200 && res.getStatusCode() != 201) {
                    new LogService().createErrorLog('GenericExportService', 'sendFileToFTP()', res.getBody(), String.valueOf(res.getStatusCode()), null, 
                    									exportType + LogService.METHOD_PARAM_SEPERATOR + attachmentIdsString, LogService.GENERIC_EXPORT, true, 'Info');
                }
            }
        } else {
            new LogService().createErrorLog('GenericExportService', 'sendFileToFTP()', 'FTP config not defined', LogService.NOT_APPLICABLE, null, 
            									exportType + LogService.METHOD_PARAM_SEPERATOR + attachmentIdsString, LogService.GENERIC_EXPORT, true);
        }
        
    }

    public static GE_File_Config__c getExportRecById(String exportRecId) {
        List<GE_File_Config__c> fileConfigList = GenericExportUtil.getFileConfigUsingFilter(new Map<String, Object>{'Id' => exportRecId}, true);
        if(fileConfigList.size() == 0) return null;
        return fileConfigList[0];
	}

    public static String getBPExportFormatList() {
        List<GE_File_Config__c> fileConfigList = GenericExportUtil.getFileConfigUsingFilter(new Map<String, Object>{'Blackpurl_Format__c' => true}, false);
        List<GenericExportWrapper.BPExportFormatWrapper> bpExportFormatObjList = new List<GenericExportWrapper.BPExportFormatWrapper>();
        for(GE_File_Config__c fileConfigRec: fileConfigList) {
            if(fileConfigRec.File_Name__c == 'Yamaha Australia' && 
                String.isBlank(Yamaha_Australia_Config__c.getOrgDefaults().Dealer_Code__c)) {
                    continue;
            }
            bpExportFormatObjList.add(new GenericExportWrapper.BPExportFormatWrapper(fileConfigRec));
        }
        return System.JSON.serialize(bpExportFormatObjList, true);
    }

    public static String getBPColumnNameList(String exportType) {
        Set<String> columnNameSet = GenericExportUtil.exportTypeToAvailableBPColumnNameToAPINameMap.containsKey(exportType) ? 
                                        GenericExportUtil.exportTypeToAvailableBPColumnNameToAPINameMap.get(exportType).keySet() : new Set<String>();
        return System.JSON.serialize(columnNameSet, true);
    }

    public static GE_File_Config__c upsertGenericExportFormat(GenericExportWrapper genericExportObj){
        GE_File_Config__c fileConfigRec = new GE_File_Config__c();
        fileConfigRec.Id = genericExportObj.Id;
        fileConfigRec.File_Name__c = genericExportObj.FileName;
        fileConfigRec.File_Content_Type__c = genericExportObj.FileType;
        fileConfigRec.File_Separator__c = genericExportObj.DelimiterTextValue != null ? genericExportObj.DelimiterTextValue.toLowerCase() : 'comma';
        fileConfigRec.Delimiter__c = genericExportObj.Delimiter;
        fileConfigRec.Include_Column_Header__c = genericExportObj.IncludeColumnHeader;
        fileConfigRec.Vendor__c = genericExportObj.VendorId;
        fileConfigRec.Object_API_Name__c = genericExportObj.ObjectAPIName;
        fileConfigRec.Order_By_Clause__c = genericExportObj.OrderByClause;
        fileConfigRec.Filter__c = genericExportObj.FilterId;
        fileConfigRec.Group_By_Field_API_Name__c = genericExportObj.GroupByFieldAPIName;
        fileConfigRec.Where_Clause__c = genericExportObj.WhereClause;

        DMLUtility.upsertSobjectList('GE_File_Config__c', fileConfigRec);

        if(fileConfigRec.Id == null || genericExportObj.ColumnDetailList == null || genericExportObj.ColumnDetailList.size() == 0) return fileConfigRec;
        
        List<GE_File_Detail__c> columnDetailList = new List<GE_File_Detail__c>();
        List<GE_File_Detail__c> columnToDeleteList = new List<GE_File_Detail__c>(); 
        for(GenericExportWrapper.ColumnDetailWrapper columnDetailObj: genericExportObj.ColumnDetailList) {
            GE_File_Detail__c columnDetailRec = new GE_File_Detail__c(Id = columnDetailObj.Id);
            if(columnDetailObj.isDelete != null && columnDetailObj.isDelete && columnDetailObj.Id != null) {
                columnToDeleteList.add(columnDetailRec);
            } else if(columnDetailObj.isDelete == null || !columnDetailObj.isDelete) {
                if(columnDetailRec.Id == null) columnDetailRec.GE_File_Config__c = fileConfigRec.Id;
                columnDetailRec.File_Column_Name__c = columnDetailObj.ColumnName;
                columnDetailRec.File_Column_Label__c = columnDetailObj.ColumnLabel;
                columnDetailRec.Order_Number__c = columnDetailObj.OrderNumber;
                columnDetailRec.Default_Value__c = columnDetailObj.ColumnDefaultValue;
                if(genericExportObj.ExportType != null) {
                    columnDetailRec.Field_API_Name__c = 
                        GenericExportUtil.exportTypeToAvailableBPColumnNameToAPINameMap.get(genericExportObj.ExportType).get(columnDetailRec.File_Column_Name__c);
                } else {
                    columnDetailRec.Field_API_Name__c = columnDetailObj.FieldAPIName;
                }
                columnDetailList.add(columnDetailRec);
            }
        }
        DMLUtility.upsertSobjectList('GE_File_Detail__c', columnDetailList);
        DMLUtility.deleteSobjectList('GE_File_Detail__c', columnToDeleteList);
        return fileConfigRec;
	}

    public static void emailToCustomer(String filterId, String attId, String errorMsg) {
        Filter__c filterRec = [SELECT Email_Addresses__c, Filter_Label__c, Report_Format__c FROM Filter__c WHERE Id =: filterId];
        String subject = '';
        String body = '<span> Hi, </span>';

        if(String.isBlank(attId)) {
            if(String.isNotBlank(errorMsg)) {
                subject = 'Your scheduled ' + filterRec.Filter_Label__c + ' report failed';
                if(isDataError(errorMsg)) {
                    body += '<p>The report you have requested for <b>' + filterRec.Filter_Label__c + '</b> cannot be generated due to the presence of a substantial amount of data. ' + 
                            'Please consider refining your search filters to proceed.</p>';
                } else {
                    body += '<p>The generation of the requested report for <b>' + filterRec.Filter_Label__c + '</b> has encountered an issue and cannot be completed successfully. ' + 
                            'Kindly get in touch with our support team for assistance.</p>';
                }
                body += '<p style="margin-top:20px;margin-bottom:5px;">From</p>';
                body += '<p style="margin:0px;">Blackpurl Support</p>';
            } else {
                subject = 'Your scheduled ' + filterRec.Filter_Label__c + ' report did not have any results';
                body += '<p>The report <b>' + filterRec.Filter_Label__c + '</b> that you requested completed successfully but did not have any results to report. No attachment available.</p>';
            }
        } else {
            subject = 'Your scheduled ' + filterRec.Filter_Label__c + ' report result';
            body += '<p>The report <b>' + filterRec.Filter_Label__c + '</b> that you requested has been generated successfully. Please find it attached.</p>';
        }

        List<String> licensedUserEmailList = getLicensedUserEmailList();
        List<String> emailStrList;
        if(String.isNotBlank(filterRec.Email_Addresses__c)) {
            emailStrList = new List<String>();
            for(String emailStr: filterRec.Email_Addresses__c.split(',')) {
                if(licensedUserEmailList.contains(emailStr)) {
                    emailStrList.add(emailStr);
                }
            }
        }
        
        if(emailStrList != null && !emailStrList.isEmpty()) {
            SendEmail.send(emailStrList, subject, body, attId, filterRec.Filter_Label__c + '.' + filterRec.Report_Format__c);
        } else {
            throw new BlackPurlException('No email address defined for ' + + filterRec.Filter_Label__c + ' export.');
        }
    }

    public static List<String> getLicensedUserEmailList() {
        List<User> userList = [Select Email from User where isActive = true and ProfileId IN (Select Id from Profile where Name IN: UserSettingCtrl.PROFILE_NAME_LIST)];
        List<String> licensedUserEmailList = new List<String>();
        for(User userRec: userList) {
            licensedUserEmailList.add(userRec.Email);
        }
        return licensedUserEmailList;
    }

    public static Boolean isDataError(String errorMsg) {
        Boolean isDataErr = false;
        for(String dataErrorStr: GenericExportUtil.DATA_ERROR_SET) {
            isDataErr = errorMsg.contains(dataErrorStr);
            if(isDataErr) {
                break;
            }
        }
        return isDataErr;
    }
    
    public class FTPWrapper {
        public String FtpURL;
        public String Username;
        public String Password;
        public String SFUsername;
        public String SFPassword;
        public String OrgName;
        public String Namespace;
        public String AttachmentId;
        public Decimal PortNumber;
        public String DirectoryPath;
        public Boolean IsSFTPServer;
        public Boolean IsFTPSConnection;
        public String FileName;
        public String SalesforceBaseUrl;
        public String SessionId;
        
        public FTPWrapper(String exportType, String attachmentIdsString) {
        	FTP_Config__c ftpConfigRec = GenericExportUtil.getFTPConfigRec(exportType);
            if(ftpConfigRec != null) {
                this.FtpURL = ftpConfigRec.FTP_URL__c;
                this.Username = ftpConfigRec.FTP_Username__c;
                this.Password = ftpConfigRec.FTP_Password__c;
                this.OrgName = ftpConfigRec.Org_Name__c;
                this.PortNumber = ftpConfigRec.Port__c;
                this.DirectoryPath = ftpConfigRec.Directory_Path__c;
                this.IsSFTPServer = ftpConfigRec.SFTP_Server__c;
                this.IsFTPSConnection = ftpConfigRec.FTPS_Connection__c;
            }
            this.Namespace = (GeneralConfiguration.getPackageNamespace() == null) ? '' : GeneralConfiguration.getPackageNamespace();
            this.AttachmentId = attachmentIdsString;
            this.SessionId = UserInfo.getSessionId();
            this.SalesforceBaseUrl = URL.getSalesforceBaseUrl().toExternalForm();
            this.SFUsername = BPUtility.getDecodedString(BPConfigurationsService.getSFUsername());
            this.SFPassword = BPUtility.getDecodedString(BPConfigurationsService.getSFPassword());
        }
    }
}