global without sharing class IntextDuplicatePartsEmailAlertBatch implements Database.Batchable<sObject>, Database.Stateful{
    public String fileData = '';
    public String exportType;
    public GE_File_Config__c fileConfigRec;
    private DateTime dateTimeValue;
    private String headerValue = 'Part Number,Vendor,Description,Part URL \n';
    global IntextDuplicatePartsEmailAlertBatch(String exportType, GE_File_Config__c fileConfigRec, DateTime dateTimeValue){
        this.exportType = exportType;
        this.fileConfigRec = fileConfigRec;
        this.dateTimeValue = dateTimeValue;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('Select Part_Number__c, Description__c, Vendor_Name_And_Code__c from Part__c where Publish_In_Feeds__c = true AND Is_Duplicate__c = true Order By Part_Number__c ASC');
	}

    global void execute(Database.BatchableContext BC, List<Part__c> partList){
		fileData += getDataForCSVFile(partList);
	}

	global void finish(Database.BatchableContext BC) {
		if(String.isNotBlank(fileData)) {
			createAttachment(fileData, exportType, fileConfigRec, dateTimeValue);
        	notifyTheSupportAdmin();
		}
    }
    

    private void notifyTheSupportAdmin() {
        String subject = 'Blackpurl Alert - Publish Part Feed Conflict';
        String htmlBody = getEmailTemplateBody() ;
        String defaultEmail = GeneralConfiguration.getIntextAlertEmailRecipient();
        List<String> emailStrList = new List<String>();
        if(String.isNotBlank(defaultEmail)) {
            emailStrList = defaultEmail.split(';');
        } else {
            emailStrList.add(GeneralConfiguration.getSupportEmail());
        }

        SendEmail.sendSupportMailWithAttachment(emailStrList, subject, htmlBody, getAttachment());
    }
    
    private Messaging.EmailFileAttachment getAttachment() {
        Blob pageContent = Blob.valueOf(headerValue + fileData);
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName('attachment.csv');
        emailAttachment.setBody(pageContent);
        return emailAttachment;
    }
    
    private String getDataForCSVFile(List<Part__c> partList) {
        String dataForCSVFile = '';
        for(Part__c partRec : partList) {
            dataForCSVFile += partRec.Part_Number__c + ',' + partRec.Vendor_Name_And_Code__c + ', ' + partRec.Description__c + ', ' + AccountingUtil.getURL(partRec.Id, 'ViewPart') + '\n' ;
        }
        return dataForCSVFile;
    }
 
    public String getEmailTemplateBody(){
        String htmlBody = '';
        htmlBody += '<span> Hi, </span>';
        htmlBody += '<p>The following parts in Blackpurl are currently being excluded from your data feed due to a duplicate part number conflict.  If more than one part with the same part number has the "Publish in Feed" flag turned on, none of the conflicting parts will be published until this has been resolved.</p>';
        htmlBody += '<p>Please refer to the list of parts below and make the necessary changes in Blackpurl to resolve this conflict. Once a conflict has been resolved, the part(s) should appear in the next scheduled data feed push.</p>';
        htmlBody += '<p style="margin-top: 20px;margin-bottom:5px;">From</p>';
        htmlBody += '<p style="margin:0px;">Blackpurl Support</p>';
        if(String.isNotBlank(fileConfigRec.Publish_In_Feed_URL__c)){
            htmlBody += '<a style="margin-top: 20px;margin-bottom:5px;" href ="' +  fileConfigRec.Publish_In_Feed_URL__c + '"> Article on Publish in Feeds</a>';
        }
        return htmlBody;
    }

    private String createAttachment(String fileContent, String fileType, GE_File_Config__c fileConfigRec, DateTime dateOfFileData) {
        Attachment attachment = new Attachment();
        attachment.ParentId = GenericExportService.getParentId(); 
        attachment.ContentType = GenericExportUtil.fileTypeToContentTypeMap.containsKey(fileConfigRec.File_Content_Type__c) ? 
        							GenericExportUtil.fileTypeToContentTypeMap.get(fileConfigRec.File_Content_Type__c) : 'text/csv';
        
        dateOfFileData = dateOfFileData != null ? dateOfFileData : system.now();
        attachment.Name = 'Duplicate_Parts_' + GenericExportUtil.getAttachmentName(fileType, dateOfFileData) + '.' + fileConfigRec.File_Content_Type__c;
        attachment.Body = Blob.valueOf(headerValue + fileContent);
        DMLUtility.insertSobjectList('Attachment', attachment);
        return attachment.Id;
    }
}