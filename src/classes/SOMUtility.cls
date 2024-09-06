/** 
* Author: Nidhi Sharma
* Since: Nov 1, 2019
* Name: SOMUtility 
* Description: Utility class for SOM Integration
**/
public without sharing class SOMUtility {
	
	public static String pathURLToImport = '/api/2/path/data';
	public static List<Log__c> errorLogList = new List<Log__c>();
	
	public static String contentType = 'text/csv';
	public static String zipFileExtension = '.zip';
	public static String csvFileExtension = '.csv';
	public static String fileSeparator = '|';
	public static String newLineSeparator = '\n'; 
	
	public static final String PART_INVENTORY_SNAPSHOT = 'Part inventory snapshot';
	public static final String PART_SALES_TRANSACTIONS = 'Part sales transactions';
	public static final String PARTS_ON_ORDER = 'Parts on order';
	
	private static Map<String, String> fileTypeToFileNameInitialsMap = new Map<String, String> {PART_INVENTORY_SNAPSHOT => 'INV',
																								PART_SALES_TRANSACTIONS => 'PSI',
																								PARTS_ON_ORDER => 'POO'};
	
	private static Map<String, String> fileTypeToBatchNameMap = new Map<String, String> {PART_INVENTORY_SNAPSHOT => 'SOMPartInventoryBatch',
																								PART_SALES_TRANSACTIONS => 'SOMPartSalesTransactionBatch',
																								PARTS_ON_ORDER => 'SOMPartsOnOrderBatch'};
	
	private static Map<Integer, String> somErrorCodeToDetailMessageMap = new Map<Integer, String> {200 => 'Success - Everything worked as expected.',
											201 => 'Created - Everything worked as expected.',
											400 => 'Bad Request - Often missing required field or validation failure. See response for more information.',
											401 => 'Unauthorized - Authorization has been refused for the provided credentials.',
											402 => 'Payment Required - Often site is over transfer or storage quota.',
											403 => 'Permission Denied - Authentication failure. See Authentication for more information.',
											404 => 'Not Found - The requested item does not exist.',
											409 => 'Conflict - Can only upload to an existing directory.',
											415 => 'Unsupported media - You may have mixed up file/folder. Check Path.'};
																																														
	private static Map<String, List<String>> fileTypeToFieldLabelListMap = new Map<String, List<String>> {
					PART_INVENTORY_SNAPSHOT => new List<String>{'OrgCode','PartNumber','VendorCode','PartGroupID','QtyAvailable','Cost','AvgCost','Price','IsPackage',
															'PackageUnit','ServiceQty','IsGM','Style','ObsoleteStatus','Inactive','NonStock','Superseded','SupersededTo',
															'Seasonal','SeasonStartMonth','SeasonStartDay','SeasonEndMonth','SeasonEndDay','CreatedOn'},
															
					PART_SALES_TRANSACTIONS => new List<String>{'OrgCode','InvoiceID','CustomerID','PartNumber','VendorCode','Qty','Price','Cost','ExceptionalSale',
															'IsSpecialOrder','CustomerCity','CustomerState','CustomerCountry','SoldBy','SoldOn'},
															
					PARTS_ON_ORDER => new List<String>{'OrgCode', 'PONumber', 'VendorCode', 'PartNumber', 'QtyOrderedNotReceived', 
                                                            'IsSpecialOrder', 'ExceptionalOrder', 'SubmittedOn'}
	};
																																															
	public static String getFileNameByFileType(String fileType, DateTime dateTimeValue) {
		String fileName = '';
		if(fileTypeToFileNameInitialsMap.containsKey(fileType)) {
			fileName = fileTypeToFileNameInitialsMap.get(fileType) + '_';
		}
		fileName += getOrgCode() + '_';
		fileName += (dateTimeValue != null ? dateTimeValue.format('YYYYMMdd') : Datetime.now().format('YYYYMMdd'));
		
		return fileName;
	}
	
	public static String getOrgCode() {
		return SOM_Configuration__c.getOrgDefaults().Org_Code__c;
	}
	
	public static Integer geMaxLinesInCSVFile() {
		Decimal maxLinesInCSVFile = SOM_Configuration__c.getOrgDefaults().Max_Lines_in_CSV_File__c;
		maxLinesInCSVFile = (maxLinesInCSVFile != null && maxLinesInCSVFile > 50000) ? 50000 : maxLinesInCSVFile; 
		return (maxLinesInCSVFile != null ? Integer.valueOf(maxLinesInCSVFile) : 50000);
	}
	
	public static String getSOMAttachmentParentId() {
	    if(!AccessControl.ifObjectFieldIsAccessible('SOM_Integration__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<SOM_Integration__c> SOMIntegrationList = [SELECT Id FROM SOM_Integration__c LIMIT 1];
		
		SOM_Integration__c SOMIntegrationRec = new SOM_Integration__c();
		if(SOMIntegrationList.size() > 0) {
			SOMIntegrationRec = SOMIntegrationList[0];
		} else {
			DMLUtility.insertSobjectList('SOM_Integration__c', SOMIntegrationRec);
		}
		return SOMIntegrationRec.Id;
	}
	
	public static String getHeaderByFileType(String fileType) {
		String header = '';
		if(fileTypeToFieldLabelListMap.containsKey(fileType)) {
			header = String.join(fileTypeToFieldLabelListMap.get(fileType), fileSeparator);
		}
		return header;
	}
	
	public static Attachment createAttachment(String fileType, String fileContent, Integer totalLines, DateTime dateOfFileData) {
	    return createAttachment(fileType, fileContent, totalLines, null, dateOfFileData);
	}
	
	public static Attachment createAttachment(String fileType, String fileContent, Integer totalLines, Integer batchNumber, DateTime dateOfFileData) {
	    Attachment attachment = new Attachment();
        
        fileContent = getHeaderByFileType(fileType) + newLineSeparator + fileContent;
        attachment.ParentId = getSOMAttachmentParentId(); 
        attachment.ContentType = contentType;
        attachment.Description = fileType;
        
        dateOfFileData = dateOfFileData != null ? dateOfFileData : system.now();
        attachment.Name = getFileNameByFileType(fileType, dateOfFileData) + (batchNumber != null ? ('_' + batchNumber) : '') + csvFileExtension;
        attachment.Body = Blob.valueOf(fileContent);
        return attachment;
	}
	
        
    public static HTTPResponse uploadToSFTPServer(Blob fileContentBlob, String fileName) {
    	SOM_Configuration__c somConfig = SOM_Configuration__c.getOrgDefaults();
    	
    	if(String.isBlank(somConfig.Upload_Directory__c)) {
    		throw new BlackPurlException('Upload directory not specified');
    	}
    	String endPoint = somConfig.SOM_sftp_URL__c + pathURLToImport + somConfig.Upload_Directory__c;
    	String userName = somConfig.Username__c;
		String password = somConfig.Password__c;
		
		String authHeaderValue = generateToken(userName, password);
		String boundary = '----------------------------741e90d31eff';
        Blob bodyBlob = getRequestBody(fileContentBlob, fileName, boundary); 
        
		HTTPResponse res = doPost(endPoint, bodyBlob, boundary, authHeaderValue);
		return res;
    }
    
    private static HTTPResponse doPost(String endPoint, Blob body, String boundary, String authHeaderValue) {
    	HttpRequest req = new HttpRequest();
		req.setMethod('POST');
      	req.setEndpoint(endPoint);
      	req.setBodyAsBlob(body);
      	req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
      	req.setHeader('Authorization', authHeaderValue);
      	req.setTimeout(120000);
      	Http http = new Http();
		HTTPResponse res = http.send(req);
		return res;
    }
    
    private static void handleResponse(HTTPResponse res, String fileType, String fileName) {
    	if(res.getStatusCode() == 200 || res.getStatusCode() == 201 || res.getStatusCode() == 500) {
    		createLog('SOMUtility', 'uploadToSFTPServer()', null, fileName, 'Info');
    	} else {
    		String errorMessage = (somErrorCodeToDetailMessageMap.containsKey(res.getStatusCode()) ? somErrorCodeToDetailMessageMap.get(res.getStatusCode()) : '');
    		
            errorLogList.add(new LogService().createErrorLog('SOMUtility', 'uploadToSFTPServer() ', errorMessage, 
            			String.valueOf(res.getStatusCode()), null, fileName, LogService.SOM, false, 'Error'));
            			
            sendFailureEmailNotification(fileType, String.valueOf(res.getStatusCode()) + ' : ' + errorMessage, 
            									fileTypeToBatchNameMap.get(fileType) + 'SOMUtility.uploadToSFTPServer()');
    	}
    }
    
    public static void createLog(String batchName, String methodName, Exception e, String attchName, String logType) {
    	String message = e != null ? e.getMessage() : 'Success';
    	String stackTrace = e != null ? e.getStackTraceString() : null;
    	errorLogList.add(new LogService().createErrorLog(batchName, methodName, message, LogService.NOT_APPLICABLE, stackTrace, 
                                          attchName, LogService.SOM, false, logType));
    }
    
    
    private static String generateToken(String username, String password) {
    	Blob headerValue = Blob.valueOf(username + ':' + password);
      	return 'Basic ' + BPUtility.getEncodedStr(headerValue);
    }
    
	private static Blob getRequestBody(Blob fileBody, String fileName, String boundary) {
      	String header = '--'+boundary+'\nContent-Disposition: form-data; name="file"; filename="'+fileName+'";\nContent-Type: application/octet-stream';
      	String footer = '--'+boundary+'--';             
      	String headerEncoded = BPUtility.getEncodedStr(Blob.valueOf(header+'\r\n\r\n'));
      	while(headerEncoded.endsWith('=')) {
       		header+=' ';
       		headerEncoded = BPUtility.getEncodedStr(Blob.valueOf(header+'\r\n\r\n'));
      	}
      	String bodyEncoded = BPUtility.getEncodedStr(fileBody);
 
      	Blob bodyBlob = null;
      	String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
 
		if(last4Bytes.endsWith('==')) {
			last4Bytes = last4Bytes.substring(0,2) + '0K';
        	bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
      	} else if(last4Bytes.endsWith('=')) {
        	last4Bytes = last4Bytes.substring(0,3) + 'N';
        	bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
        	footer = '\n' + footer;
      	} else {
        	footer = '\r\n' + footer;
		}
		
		String footerEncoded = BPUtility.getEncodedStr(Blob.valueOf(footer));
		return EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);  
	}
	
	private static void insertLogs() {
		if(errorLogList != null && errorLogList.size() > 0) {
			if(AccessControl.ifObjectFieldIsCreateable('Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
			DMLUtility.insertSobjectList('Log__c', errorLogList);
			errorLogList = new List<Log__c>();
		}
	}
    
    private static void sendFailureEmailNotification(String fileType, String message, String stackTraceString) {
        String subject = UserInfo.getOrganizationName() + ' - SOM ' + fileType + ' script failure';
        String htmlBody = '<span> Hi Support Team, </span> <br/> <br/>';
		htmlBody += '<div>Failed to upload file to super-som.smartfile.com. </div>';
		htmlBody += '<div> <b>Error message - </b>' + message + '</div>';
		htmlBody += stackTraceString != null ? '<div> <b>Stacktrace - </b>' + stackTraceString + '</div>' : '';
    	String defaultEmail = GeneralConfiguration.getSupportEmailRecipient();
		List<String> emailStrList = new List<String>();
		if(String.isNotBlank(defaultEmail)) {
			emailStrList = defaultEmail.split(';');
		} else {
			emailStrList.add(GeneralConfiguration.getSupportEmail());
		}
		if(!Test.isRunningTest()) {
        	SendEmail.sendSupportMail(emailStrList, subject, htmlBody);
		}
    }
    
    public static void handleFinish(String fileType, String fileContent, Integer totalRecords, DateTime dateOfFileData) {
    	handleFinish(fileType, fileContent, totalRecords, null, dateOfFileData);
    }
    
    public static void handleFinish(String fileType, String fileContent, Integer totalRecords, Integer batchNumber, DateTime dateOfFileData) {
        Attachment attch = createAttachment(fileType, fileContent, totalRecords, batchNumber, dateOfFileData);
        try {
            HTTPResponse res = uploadToSFTPServer(attch.Body, attch.Name);
            handleResponse(res, fileType, attch.Name);
        } catch (Exception e) {
            createLog(fileTypeToBatchNameMap.get(fileType), 'uploadToSFTPServer()', e, attch.Name, 'Error');
            sendFailureEmailNotification(fileType, e.getMessage(), e.getStackTraceString());
        }
        insertAttachment(new List<Attachment>{attch}, fileType);
        insertLogs();
    }
    
    private static void insertAttachment(List<Attachment> attachmentRecList, String fileType) {
		if(attachmentRecList.size() == 0) return;
    	try {
			DMLUtility.insertSobjectList('Attachment', attachmentRecList);
    		createLog(fileTypeToBatchNameMap.get(fileType), 'finish()', null, attachmentRecList[0].Name, 'Info');
    	} catch(Exception e) {
    		createLog(fileTypeToBatchNameMap.get(fileType), 'insertAttachment()', e, attachmentRecList[0].Name, 'Error');
    	}
    }

	public static void updatePartRecords(List<Part__c> partList) {
        try {
            PartTriggerHelper.isForceStopTrigger = true;
			DMLUtility.updateSobjectList('Part__c', partList);
            PartTriggerHelper.isForceStopTrigger = false;
        } catch (Exception e) {
            if(e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
				BPUtility.setTimeout(2);
                updatePartRecords(partList);
            }
        }
    } 
    
	public static void retryFilePostingToSOM() {		
		BPUtility.setTimeout(5); // Time delay
		System.enqueueJob(new MergeAndPostToSOMQueueable());
    }
}