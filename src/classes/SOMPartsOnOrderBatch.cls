/**
* Author : Tarun Khandelwal
* Since : Nov 01, 2019
* Name : SOMPartsOnOrderBatch
* Description : Batch class to export data for Vendor Order line itesm for SOM Integration
**/
global without sharing class SOMPartsOnOrderBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful, Schedulable {
    
    public String fileData;
    public Integer totalRecords = 0;
    private DateTime dateTimeValue;
    
    private static List<Log__c> logListToInsert = new List<Log__c>();
    public static String pathURLToImport = '/api/2.1/path/data';
    public static String fileSeparator = '|';
    public static String newLineSeparator = '\r\n'; 
    public static final String PART_INVENTORY_SNAPSHOT = 'Part inventory snapshot';
    public static final String PART_SALES_TRANSACTIONS = 'Part sales transactions';
    public static final String PARTS_ON_ORDER = 'Parts on order';
    public static String contentType = 'text/csv';
    public static String csvFileExtension = '.csv';
    public static Integer POORetryCount = 0;
    
    global SOMPartsOnOrderBatch(Date dateValueToFilter) {
        this.dateTimeValue = DateTime.newInstance(dateValueToFilter.year(), dateValueToFilter.month(), dateValueToFilter.day());
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        fileData = '';
        String query = 'SELECT Vendor_Order_Header__r.Name, Part__r.Vendor_Code__c, Part__r.Part_Number__c, Qty_Needed__c, '+
                        'CO_Header__c, Vendor_Order_Header__r.Ordered_Date__c, Vendor_Order_Header__r.Expected_Date__c, Vendor_Order_Header__r.Expected_Date_Formula__c FROM Vendor_Order_Line_Item__c ' + 
                'WHERE Part__c != null AND Is_Received__c = false AND Vendor_Order_Header__r.Status__c IN (\'On Order\', \'Partially Received\')';
        query += this.dateTimeValue != null ? ' AND CreatedDate < ' + (this.dateTimeValue.addDays(1)).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : '';
        query += ' Order By Part__r.Part_Number__c ASC';
        return Database.getQueryLocator(query);
    }
    
    public static String getOrgCode() {
        return SOM_Configuration__c.getOrgDefaults().Org_Code__c;
    }

    global void execute(Database.batchableContext bc, List<Vendor_Order_Line_Item__c> voliList) {
        try{
            for(Vendor_Order_Line_Item__c voliRec : voliList) {
                fileData += (getOrgCode() + fileSeparator);
                fileData += (voliRec.Vendor_Order_Header__r.Name + fileSeparator);
                fileData += (voliRec.Part__r.Vendor_Code__c + fileSeparator);
                fileData += (voliRec.Part__r.Part_Number__c + fileSeparator);
                fileData += ((voliRec.Qty_Needed__c != null ? voliRec.Qty_Needed__c : 0) + fileSeparator);
                fileData += ((voliRec.CO_Header__c != null ? '1' : '0') + fileSeparator);
                
                if(voliRec.Vendor_Order_Header__r.Expected_Date_Formula__c != null && 
                    System.today().daysBetween(voliRec.Vendor_Order_Header__r.Expected_Date_Formula__c) > 30) {
                        fileData += '1' + fileSeparator;
                } else {
                    fileData += '0' + fileSeparator;
                }

                if(voliRec.Vendor_Order_Header__r.Ordered_Date__c != null) {
                    Date orderedDate = voliRec.Vendor_Order_Header__r.Ordered_Date__c;
                    String orderedString = DateTime.newInstance(orderedDate.year(), orderedDate.month(), orderedDate.day()).format('yyyy-MM-dd');
                    fileData += (orderedString + fileSeparator);
                }
                if(voliRec.Vendor_Order_Header__r.Expected_Date__c != null) {
                    Date expectedDate = voliRec.Vendor_Order_Header__r.Expected_Date__c;
                    String expectedString = DateTime.newInstance(expectedDate.year(), expectedDate.month(), expectedDate.day()).format('yyyy-MM-dd');
                    fileData += expectedString;
                }
                fileData += newLineSeparator;
                totalRecords++;
            }
        } catch (Exception e) {
            //createLog('SOMPartsOnOrderBatch', 'execute()', e, null, 'Error');
        }
    }
    
    global void finish(Database.batchableContext bc) {
        handleFinish(PARTS_ON_ORDER, fileData, totalRecords, null, dateTimeValue);
        
        Date todaysDate = Date.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day());
        runNextJobAt10PM(todaysDate.addDays(1));
    }
    
    public static void runNextJobAt10PM(Date dateToRun) {
        String jobName = 'SOM POO file generation';
        List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: jobName];
        if(existingSheduledJobs.size() > 0) {
            system.abortJob(existingSheduledJobs[0].Id);
        }
        String CRON_EXP = '0 0 22 ? * * *';
        if(!Test.isRunningTest()) {
            system.schedule(jobName, CRON_EXP, new SOMPartsOnOrderBatch(dateToRun));
        }
    }
    
    global void execute(SchedulableContext sc) {
        Date todaysDate = Date.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day());
        Database.executeBatch(new SOMPartsOnOrderBatch(todaysDate), 500);
    }
    
    public static void handleFinish(String fileType, String fileContent, Integer totalRecords, Integer batchNumber, DateTime dateOfFileData) {
        try {
        	Attachment attch = createAttachment(fileType, fileContent, totalRecords, batchNumber, dateOfFileData);
	        
	        uploadToSFTPServer(attch.Body, attch.Name);

	        if(attch.ParentId == null) {
	            SOM_Integration__c SOMIntegrationRec = new SOM_Integration__c();
	            insert SOMIntegrationRec;
	            attch.ParentId = SOMIntegrationRec.Id;
	        }
	        insertAttachment(new List<Attachment>{attch}, fileType);
	        
        } catch(Exception e) {
    		logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Log_Info__c = e.getMessage(),
	        				Method_Params__c = 'fileType ' + fileType, Method__c = 'handleFinish()', 
							Apex_Class__c = 'SOMPartsOnOrderBatch', Type__c = 'Error'));
    	}
        if(logListToInsert.size() > 0) {
        	insert logListToInsert;
        }
    }
    
    private static void uploadToSFTPServer(Blob fileContentBlob, String fileName) {
        SOM_Configuration__c somConfig = SOM_Configuration__c.getOrgDefaults();
        
        if(String.isNotBlank(somConfig.Username__c) && String.isNotBlank(somConfig.Password__c) && 
                String.isNotBlank(somConfig.Upload_Directory__c) && String.isNotBlank(somConfig.SOM_sftp_URL__c)) {
            String endPoint = somConfig.SOM_sftp_URL__c + pathURLToImport + somConfig.Upload_Directory__c;
            String userName = somConfig.Username__c;
            String password = somConfig.Password__c;
            
            String authHeaderValue = generateToken(userName, password);
            String boundary = '----------------------------741e90d31eff';
            Blob bodyBlob = getRequestBody(fileContentBlob, fileName, boundary); 
            
            System.enqueueJob(new FilePostToSOMQueueable(endPoint, authHeaderValue, bodyBlob, fileName, 0));
        } else {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.ToAddresses = new List<String>{'blackpurl@metacube.com'};
            message.Subject = UserInfo.getOrganizationName() + ' - SOM Parts on order status failed - Check configurations ';
            message.PlainTextBody = 'Hi,\n\n'+ 
                                    'Please check som configurations \n\n' +
                                    'Thank You\nTeam Blackpurl';
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
            logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Log_Info__c = 'Blank response', 
	                        Method_Params__c = 'File name ' + fileName, 
	                        Apex_Class__c = 'SOMPartsOnOrderBatch - Get response', Type__c = 'Error'));
            sendFinishMail(null, fileName);
        }
    }
    
    public static void sendFinishMail(HTTPResponse res, String fileName) {
        String status = res != null && (res.getStatusCode() == 200 || res.getStatusCode() == 201) ? 'Success' : 'Failed';
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.ToAddresses = new List<String>{'blackpurl@metacube.com'};
        message.Subject = UserInfo.getOrganizationName() + ' - SOM Part On Order posting ' + status + ' with status code ' + res.getStatusCode();
        message.PlainTextBody = 'Hi,\n\n'+ 
                                'SOM Part on order File - ' + fileName + ' posting ' + status + '\n\n' +
                                'Thank You\nTeam Blackpurl';
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
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
    
    private static Map<String, List<String>> fileTypeToFieldLabelListMap = new Map<String, List<String>> {
                    PART_INVENTORY_SNAPSHOT => new List<String>{'OrgCode','PartNumber','VendorCode','PartGroupID','QtyAvailable','Cost','AvgCost','Price','IsPackage',
                                                            'PackageUnit','ServiceQty','IsGM','Style','ObsoleteStatus','Inactive','NonStock','Superseded','SupersededTo',
                                                            'Seasonal','SeasonStartMonth','SeasonStartDay','SeasonEndMonth','SeasonEndDay','CreatedOn'},
                                                            
                    PART_SALES_TRANSACTIONS => new List<String>{'OrgCode','InvoiceID','CustomerID','PartNumber','VendorCode','Qty','Price','Cost','ExceptionalSale',
                                                            'IsSpecialOrder','CustomerCity','CustomerState','CustomerCountry','SoldBy','SoldOn'},
                                                            
                    PARTS_ON_ORDER => new List<String>{'OrgCode', 'PONumber', 'VendorCode', 'PartNumber', 'QtyOrderedNotReceived', 
                                                            'IsSpecialOrder', 'ExceptionalOrder', 'SubmittedOn', 'ExpectedOn'}
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
}