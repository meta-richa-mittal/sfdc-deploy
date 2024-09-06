/**
 * Author: Richa Mittal
 * Since: August 25, 2020
 * Name: GenericExportService
 * Description: Service class for generating any file content
**/
public without sharing class GenericExportService {
	
	public static String getHeaders(GE_File_Config__c fileConfigRec) {
		if(!fileConfigRec.Include_Column_Header__c) {
			return '';
		}
		List<String> headerList = new List<String>();
        for(GE_File_Detail__c fileDetailRec: fileConfigRec.GE_File_Details__r) {
        	headerList.add(fileDetailRec.File_Column_Label__c);
        }
        return String.join(headerList, GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.containsKey(fileConfigRec.File_Separator__c) ? 
        								GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.get(fileConfigRec.File_Separator__c) : fileConfigRec.File_Separator__c);
	}
	
    public static String createFileData(GE_File_Config__c fileConfigRec, List<sObject> recordList, Map<Id, sObject> recIdToImageRecordsMap) {
        String fileData = '';
        String fileSeparator = GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.containsKey(fileConfigRec.File_Separator__c) ? 
        										GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.get(fileConfigRec.File_Separator__c) : fileConfigRec.File_Separator__c;
        
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
        
        for(sObject record: recordList) {
            List<GE_File_Detail__c> geFileDetailRecList = fileConfigRec.GE_File_Details__r != null ? fileConfigRec.GE_File_Details__r : new List<GE_File_Detail__c>();
            for(Integer i = 0; i < geFileDetailRecList.Size(); i++) {
            	GE_File_Detail__c fileDetailRec = geFileDetailRecList[i];
            	List<GE_File_Column_Override_Info__c> overrideInfoList = fileDetailToColOverrideInfoListMap.containsKey(fileDetailRec.Id) ? 
        																	fileDetailToColOverrideInfoListMap.get(fileDetailRec.Id) : null;
        		sObject recordWithImagesList = recIdToImageRecordsMap.containsKey(String.valueOf(record.get('Id'))) ?
        											recIdToImageRecordsMap.get(String.valueOf(record.get('Id'))) : null;
        		
        		sObject otherObjectRecord = otherObjectAPINameToRecordMap.containsKey(fileDetailRec.Other_Object_API_Name__c) ?
        										otherObjectAPINameToRecordMap.get(fileDetailRec.Other_Object_API_Name__c) : null;
        		
        		String columnValue = getFileColumnValue(record, fileDetailRec, overrideInfoList, recordWithImagesList, otherObjectRecord, 
        										fileConfigRec.Use_Public_Image__c, fileSeparator).escapeCsv();
        		if(columnValue.contains(';') && !columnValue.contains('"')) {
        			columnValue = '"' + columnValue + '"';
        		}
        		
        		fileData += columnValue;
        										
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
    											sObject recordWithImagesList, sObject otherObjectRecord, Boolean usePublicImages, String fileSeparator) {
    	String columnValue = '';
    	if(String.isNotBlank(fileDetailRec.Default_Value__c)) {
			columnValue = fileDetailRec.Default_Value__c;
		} else if(String.isNotBlank(fileDetailRec.Other_Object_API_Name__c)) {
			if(otherObjectRecord != null) {
				columnValue = getFieldValueFromSObject(otherObjectRecord, fileDetailRec, overrideInfoList);
			}
		} else if(String.isBlank(fileDetailRec.Field_API_Name__c) && recordWithImagesList != null) {
			// Image
			columnValue = getImageColumnValue(usePublicImages, record, recordWithImagesList, fileSeparator);
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
					} else {
						tempRecord = tempRecord.getSObject(fieldsList[i]);
					}
				}
    		}
    	}
    	
		return formattedValue;
    }
    
    private static String getImageColumnValue(Boolean usePublicImage, sObject record, sObject recordWithImagesList, String fileSeparator) {
		if(recordWithImagesList != null) {
			List<String> imageUrls = new List<String>();
			if(usePublicImage) {
				for(sObject document : recordWithImagesList.getSObjects('Documents__r')) {
					if(document.get('Public_Image_URL__c') != null) {
						imageUrls.add(String.valueOf(document.get('Public_Image_URL__c')));
					}
				}
			} else {
				for(sObject attachmentRec : recordWithImagesList.getSObjects('Attachments')) {
					String imageURL = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + String.valueOf(attachmentRec.get('Id'));
					imageUrls.add(imageURL);
				}
			}
			return (String.join(imageUrls, fileSeparator));
		}
		return '';
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
	    	}
    	}
    	return String.valueOf(fieldValue);
    }
    
    public static void sendFileToFTP(String exportType, String attachmentIdsString) {
        String ftpDetailJSON = BPUtility.getEncodedString(System.JSON.serialize(new FTPWrapper(exportType, attachmentIdsString)));
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
            }
            this.Namespace = [SELECT NameSpacePrefix FROM ApexClass limit 1].NameSpacePrefix;
            this.Namespace = this.Namespace != null ? this.Namespace : '';
            this.AttachmentId = attachmentIdsString;
            this.SFUsername = BPUtility.getDecodedString(BPConfigurationsService.getSFUsername());
            this.SFPassword = BPUtility.getDecodedString(BPConfigurationsService.getSFPassword());
        }
    }
}