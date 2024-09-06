/**
* Author: Nidhi Sharma
* Since: April 16, 2021
* Name: SOMPartSalesTransactionBatchScheduler
* Description:
**/
global without sharing class SOMPartSalesTransactionBatchScheduler implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private String fileData = '';
    private Integer totalRecords = 0;
    private DateTime dateTimeValue;
    private Boolean includeAllSubmittedClaimItems = false;
	
    private static List<Log__c> logListToInsert = new List<Log__c>();
    public static String pathURLToImport = '/api/2.1/path/data';
    public static String fileSeparator = '|';
    public static String newLineSeparator = '\r\n'; 
    public static final String PART_INVENTORY_SNAPSHOT = 'Part inventory snapshot';
    public static final String PART_SALES_TRANSACTIONS = 'Part sales transactions';
    public static final String PARTS_ON_ORDER = 'Parts on order';
    public static String contentType = 'text/csv';
    public static String csvFileExtension = '.csv';
    public static Integer PSIRetryCount = 0;

	global SOMPartSalesTransactionBatchScheduler(Boolean includeAllSubmittedClaimItems) {
		this.includeAllSubmittedClaimItems = includeAllSubmittedClaimItems;
	}
	
    global SOMPartSalesTransactionBatchScheduler(Date dateValueToFilter, Boolean includeAllSubmittedClaimItems) {
    	if(dateValueToFilter != null) {
            this.dateTimeValue = DateTime.newInstance(dateValueToFilter.year(), dateValueToFilter.month(), dateValueToFilter.day());
        }
        this.includeAllSubmittedClaimItems = includeAllSubmittedClaimItems != null ? includeAllSubmittedClaimItems : false;
    }

    global Iterable<sObject> start(Database.BatchableContext bc) {
    	String nonThirdPartyCOLIQuery, thirdPartyCOLIQuery;
        thirdPartyCOLIQuery =  nonThirdPartyCOLIQuery = 'SELECT Id, CO_Header__r.Name, Invoice_Number__r.Invoice_Number__c, CO_Header__r.Customer__r.Customer_Number__c, ' +
        	'Part__r.Part_Number__c, Part__r.Vendor__r.Vendor_Code__c, Qty__c, Adjusted_Cost_Coli__c, Price__c, CO_Header__r.Customer__r.BillingCity, ' +
        	'CO_Header__r.Customer__r.BillingState, Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c, ' + 
        	'Service_Order_Line_Item__r.Service_Order_Header__r.Claim_Submitted_At__c, ' + 
            'CO_Header__r.Customer__r.BillingCountry, Invoice_Number__r.Invoice_Date__c, (Select Id from Vendor_Order_Line_Items__r LIMIT 1) FROM CO_Line_Item__c ' +
            'where Part__c != null ';
		
		nonThirdPartyCOLIQuery += ' AND Invoice_Number__c != null AND Invoice_Number__r.Checkout_Type__c != \'Third-Party\'';
		if(this.dateTimeValue != null) {
        	nonThirdPartyCOLIQuery += ' AND ' + getDateFilter('Invoice_Number__r.Closed_Invoice_Date__c');
		}
		nonThirdPartyCOLIQuery += ' Order By Part__r.Part_Number__c ASC';
        system.debug('nonThirdPartyCOLIQuery::' + nonThirdPartyCOLIQuery);
        List<CO_Line_Item__c> coliList = Database.query(nonThirdPartyCOLIQuery);
        
        includeAllSubmittedClaimItems = includeAllSubmittedClaimItems == null ? false : includeAllSubmittedClaimItems;
        if(includeAllSubmittedClaimItems || this.dateTimeValue != null) {
			thirdPartyCOLIQuery += ' AND Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c = \'Third-Party\'';
			if(includeAllSubmittedClaimItems) {
	    		thirdPartyCOLIQuery += ' AND Service_Order_Line_Item__r.Service_Order_Header__r.Claim_Status__c = \'Submitted\'';
	    	} else {
	    		thirdPartyCOLIQuery += ' AND Service_Order_Line_Item__r.Service_Order_Header__r.Claim_Status__c IN (\'Submitted\',\'Approved\')';
    			thirdPartyCOLIQuery += ' AND ' + getDateFilter('Service_Order_Line_Item__r.Service_Order_Header__r.Claim_Submitted_At__c');
	    	}
	    	thirdPartyCOLIQuery += ' Order By Part__r.Part_Number__c ASC';
        	system.debug('thirdPartyCOLIQuery::' + thirdPartyCOLIQuery);
        	coliList.addAll((List<CO_Line_Item__c>) Database.query(thirdPartyCOLIQuery));
		}
		
        return coliList;
    }

    public String getDateFilter(String fieldName) {
        DateTime fromDateTime = this.dateTimeValue;
        DateTime toDateTime = this.dateTimeValue.addDays(1);
        String dateWhereClause = fieldName + ' >= ' + fromDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        dateWhereClause += ' AND ' + fieldName + ' < ' + toDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        system.debug(fromDateTime +'   ' +toDateTime + '    ' +fromDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') );
        return dateWhereClause;
    }

    global void execute(Database.batchableContext bc, List<CO_Line_Item__c> coliList) {
        try {
            for(CO_Line_Item__c coliRec : coliList) {
            	
            	String invoiceId = '';
            	String soldOn = ''; 
            	
            	invoiceId = coliRec.Invoice_Number__c != null ? coliRec.Invoice_Number__r.Invoice_Number__c : coliRec.CO_Header__r.Name;
                if(coliRec.Service_Order_Line_Item__c != null && coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party') {
                	if(coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Claim_Submitted_At__c != null) {
                		soldOn = coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Claim_Submitted_At__c.format('yyyy-MM-dd');
                	}
                } else if(coliRec.Invoice_Number__c != null) {
                	soldOn = coliRec.Invoice_Number__r.Invoice_Date__c.format('yyyy-MM-dd');
                }
                
                fileData += getOrgCode() + fileSeparator;
                fileData += invoiceID + fileSeparator;
                fileData += (coliRec.CO_Header__r.Customer__r.Customer_Number__c != null ? coliRec.CO_Header__r.Customer__r.Customer_Number__c : ' ') + fileSeparator;
                fileData += coliRec.Part__r.Part_Number__c + fileSeparator;
                fileData += coliRec.Part__r.Vendor__r.Vendor_Code__c + fileSeparator;
                fileData += (coliRec.Qty__c != null ? String.valueOf(coliRec.Qty__c) : '0') + fileSeparator;
                fileData += (coliRec.Price__c != null ? String.valueOf(coliRec.Price__c.setScale(2, RoundingMode.HALF_UP)) : '0.00') + fileSeparator;

                coliRec.Qty__c = coliRec.Qty__c != null && coliRec.Qty__c != 0 ? coliRec.Qty__c : 1;

                Decimal itemCost = (coliRec.Adjusted_Cost_Coli__c / coliRec.Qty__c).setScale(2, RoundingMode.HALF_UP);
                fileData += itemCost +
                                fileSeparator;
                fileData += ' ' + fileSeparator;        //ExceptionalSale
                fileData += (coliRec.Vendor_Order_Line_Items__r.size() > 0 ? '1' : '0') + fileSeparator;

                fileData += (coliRec.CO_Header__r.Customer__r.BillingCity != null ? coliRec.CO_Header__r.Customer__r.BillingCity : ' ') + fileSeparator;
                fileData += (coliRec.CO_Header__r.Customer__r.BillingState != null ? coliRec.CO_Header__r.Customer__r.BillingState : ' ') + fileSeparator;
                fileData += (coliRec.CO_Header__r.Customer__r.BillingCountry != null ? coliRec.CO_Header__r.Customer__r.BillingCountry : ' ') + fileSeparator;
                fileData += ' ' + fileSeparator;        //SoldBy
                fileData +=  soldOn;        //SoldOn

                fileData += newLineSeparator;
            }
        } catch (Exception e) {
            //createLog('SOMPartSalesTransactionBatchScheduler', 'execute()', e, null, 'Error');
        }

        totalRecords += coliList.size();
    }
	
    public static void runNextJobAt10PM(Date dateToRun) {
    	String jobName = 'SOM PSI file generation';
    	List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: jobName];
    	if(existingSheduledJobs.size() > 0) {
    		system.abortJob(existingSheduledJobs[0].Id);
    	}
    	String CRON_EXP = '0 0 22 ? * * *';
		system.schedule(jobName, CRON_EXP, new SOMPartSalesTransactionBatchScheduler(dateToRun, false));
    }
    
    global void execute(SchedulableContext sc) {
    	Date todaysDate = Date.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day());
    	Database.executeBatch(new SOMPartSalesTransactionBatchScheduler(todaysDate, includeAllSubmittedClaimItems), 500);
    }

    global void finish(Database.batchableContext bc) {
        handleFinish(PART_SALES_TRANSACTIONS, fileData, totalRecords, null, dateTimeValue);
        
		if(!Test.isRunningTest() && dateTimeValue != null) {
			Date todaysDate = Date.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day());
			runNextJobAt10PM(todaysDate.addDays(1));
		}
    }
    
    public static String getOrgCode() {
        return SOM_Configuration__c.getOrgDefaults().Org_Code__c;
    }
    
    private static void handleFinish(String fileType, String fileContent, Integer totalRecords, Integer batchNumber, DateTime dateOfFileData) {
        try{
        Attachment attch = createAttachment(fileType, fileContent, totalRecords, batchNumber, dateOfFileData);
        HTTPResponse res = uploadToSFTPServer(attch.Body, attch.Name);

        if(attch.ParentId == null) {
        	SOM_Integration__c SOMIntegrationRec = new SOM_Integration__c();
        	insert SOMIntegrationRec;
        	attch.ParentId = SOMIntegrationRec.Id;
        }
        insertAttachment(new List<Attachment>{attch}, fileType);
        
        if(res != null) {
	        if(res.getStatusCode() != 200 && res.getStatusCode() != 201) {
				logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Error_Code__c = String.valueOf(res.getStatusCode()),
						Method_Params__c = 'File name ' + attch.Name,
						Apex_Class__c = 'SOMPartSalesTransactionBatchScheduler - Get response', Type__c = 'Error'));
						
			} else {
				logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Error_Code__c = String.valueOf(res.getStatusCode()),
						Method_Params__c = 'File name ' + attch.Name,
						Apex_Class__c = 'SOMPartSalesTransactionBatchScheduler - Get response', Type__c = 'Info'));
			}
        } else {
        	logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Log_Info__c = 'Blank response',
        				Method_Params__c = 'File name ' + attch.Name, 
						Apex_Class__c = 'SOMPartSalesTransactionBatchScheduler - Get response', Type__c = 'Error'));
        }
        sendFinishMail(res, attch.Name);
    	} catch(Exception e) {
    		logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Log_Info__c = e.getMessage(),
	        				Method_Params__c = 'fileType ' + fileType, Method__c = 'handleFinish()', 
							Apex_Class__c = 'SOMPartSalesTransactionBatchScheduler', Type__c = 'Error'));
    	}
        if(logListToInsert.size() > 0) {
        	insert logListToInsert;
        }
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
    
    private static HTTPResponse doGet(String endPoint, String authHeaderValue) {
    	HttpRequest req = new HttpRequest();
		req.setMethod('GET');
      	req.setEndpoint(endPoint);
      	req.setHeader('Authorization', authHeaderValue);
      	req.setTimeout(120000);
      	Http http = new Http();
		HTTPResponse res = http.send(req);
		return res;
    }
    
    private static Map<String, List<String>> fileTypeToFieldLabelListMap = new Map<String, List<String>> {
                    PART_INVENTORY_SNAPSHOT => new List<String>{'OrgCode','PartNumber','VendorCode','PartGroupID','QtyAvailable','Cost','AvgCost','Price','IsPackage',
                                                            'PackageUnit','ServiceQty','IsGM','Style','ObsoleteStatus','Inactive','NonStock','Superseded','SupersededTo',
                                                            'Seasonal','SeasonStartMonth','SeasonStartDay','SeasonEndMonth','SeasonEndDay','CreatedOn'},
                                                            
                    PART_SALES_TRANSACTIONS => new List<String>{'OrgCode','InvoiceID','CustomerID','PartNumber','VendorCode','Qty','Price','Cost','ExceptionalSale',
                                                            'IsSpecialOrder','CustomerCity','CustomerState','CustomerCountry','SoldBy','SoldOn'},
                                                            
                    PARTS_ON_ORDER => new List<String>{'OrgCode', 'PONumber', 'VendorCode', 'PartNumber', 'QtyOrderedNotReceived', 
                                                            'IsSpecialOrder', 'ExceptionalOrder', 'SubmittedOn'}
    };
    
    public static String getHeaderByFileType(String fileType) {
        String header = '';
        if(fileTypeToFieldLabelListMap.containsKey(fileType)) {
            header = String.join(fileTypeToFieldLabelListMap.get(fileType), fileSeparator);
        }
        return header;
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
    
    private static Map<String, String> fileTypeToFileNameInitialsMap = new Map<String, String> {PART_INVENTORY_SNAPSHOT => 'INV',
                                                                                                PART_SALES_TRANSACTIONS => 'PSI',
                                                                                                PARTS_ON_ORDER => 'POO'};
    
    public static String getFileNameByFileType(String fileType, DateTime dateTimeValue) {
        String fileName = '';
        if(fileTypeToFileNameInitialsMap.containsKey(fileType)) {
            fileName = fileTypeToFileNameInitialsMap.get(fileType) + '_';
        }
        fileName += getOrgCode() + '_';
        fileName += (dateTimeValue != null ? dateTimeValue.format('yyyyMMdd') : Datetime.now().format('yyyyMMdd'));
        
        return fileName;
    }
    
    public static String getSOMAttachmentParentId() {
        List<SOM_Integration__c> SOMIntegrationList = [SELECT Id FROM SOM_Integration__c LIMIT 1];
        
        SOM_Integration__c SOMIntegrationRec = new SOM_Integration__c();
        if(SOMIntegrationList.size() > 0) {
            SOMIntegrationRec = SOMIntegrationList[0];
        }
        return SOMIntegrationRec.Id;
    }
    
    private static void insertAttachment(List<Attachment> attachmentRecList, String fileType) {
        DMLUtility.insertSobjectList('Attachment', attachmentRecList);
    }
    
    private static HTTPResponse uploadToSFTPServer(Blob fileContentBlob, String fileName) {
    	SOM_Configuration__c somConfig = SOM_Configuration__c.getOrgDefaults();
    	
    	if(String.isNotBlank(somConfig.Username__c) && String.isNotBlank(somConfig.Password__c) && 
    			String.isNotBlank(somConfig.Upload_Directory__c) && String.isNotBlank(somConfig.SOM_sftp_URL__c)) {
    	
	    	String endPoint = somConfig.SOM_sftp_URL__c + pathURLToImport + somConfig.Upload_Directory__c;
	    	String userName = somConfig.Username__c;
			String password = somConfig.Password__c;
			
			String authHeaderValue = generateToken(userName, password);
			String boundary = '----------------------------741e90d31eff';
	        Blob bodyBlob = getRequestBody(fileContentBlob, fileName, boundary); 
	        
			HTTPResponse postRes = doPost(endPoint, bodyBlob, boundary, authHeaderValue);
			HTTPResponse getRes = doGet(endPoint + '/' + fileName, authHeaderValue);
			
			logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', 
						Error_Code__c = String.valueOf(postRes.getStatusCode()),
						Apex_Class__c = 'SOMPartSalesTransactionBatchScheduler - Post response', Type__c = 'Info', 
						Method_Params__c = 'File name ' + fileName, 
						Log_Info__c = postRes.getBody().length() > 2000 ? postRes.getBody().subString(0, 2000) : postRes.getBody()));
			
            // Retry if file failed to post
            if(getRes.getStatusCode() != 200 && getRes.getStatusCode() != 201 && PSIRetryCount < 4) {
                PSIRetryCount++;
                logListToInsert = new List<Log__c>(); 
                return uploadToSFTPServer(fileContentBlob, fileName);
            }
            return getRes;
		} else {
    		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.ToAddresses = new List<String>{'blackpurl@metacube.com'};
			message.Subject = UserInfo.getOrganizationName() + ' - SOM Part Sales status failed - Check configurations ';
			message.PlainTextBody = 'Hi,\n\n'+ 
									'Please check som configurations \n\n' +
									'Thank You\nTeam Blackpurl';
			
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
    	}
    	
    	return null;
    }
    
    private static void sendFinishMail(HTTPResponse res, String fileName) {
    	String status = res != null && (res.getStatusCode() == 200 || res.getStatusCode() == 201) ? 'Success' : 'Failed';
    	String statusCode = res != null ? String.valueOf(res.getStatusCode()) : '';
    	
    	Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.ToAddresses = new List<String>{'blackpurl@metacube.com'};
		message.Subject = UserInfo.getOrganizationName() + ' - SOM Part Sales posting ' + status + ' with status code ' + statusCode;
		message.PlainTextBody = 'Hi,\n\n'+ 
								'SOM Part Sales File - ' + fileName + ' posting ' + status + '\n\n' +
								'Thank You\nTeam Blackpurl';
		if(Test.isRunningTest()) {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
        }
    }
    
    private static String generateToken(String username, String password) {
    	Blob headerValue = Blob.valueOf(username + ':' + password);
      	return 'Basic ' + EncodingUtil.base64Encode(headerValue);
    }
    
    private static Blob getRequestBody(Blob fileBody, String fileName, String boundary) {
      	String header = '--'+boundary+'\nContent-Disposition: form-data; name="file"; filename="'+fileName+'";\nContent-Type: application/octet-stream';
      	String footer = '--'+boundary+'--';             
      	String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
      	while(headerEncoded.endsWith('=')) {
       		header+=' ';
       		headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
      	}
      	String bodyEncoded = EncodingUtil.base64Encode(fileBody);
 
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
		
		String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
		return EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);  
	}
}