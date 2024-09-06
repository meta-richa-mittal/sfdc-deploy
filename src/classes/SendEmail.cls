public without sharing class SendEmail {
    
    private static String FALLBACK_SENDER = 'BlackPurl';
    private static String businessName;
    public static String pageNameToEmail;
    
    public static void send(List<String> emailStrList, String subject, String htmlBody, String soHeaderId) {
        if(emailStrList.size() == 0) {
            return;
        }
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail = setDefaultFields(mail, null);
        
        List<String> sendTo = emailStrList;
        mail.setToAddresses(sendTo);
        List<Messaging.EmailFileAttachment> emailAttachmentList = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName('Service Order Preview.pdf');
        
        PageReference soInfoPreviewPDFPage = Page.SOInfoPrintPreviewPDF;
        soInfoPreviewPDFPage.getparameters().put('id', soHeaderId);
        Blob pageContent;
        if(!Test.isRunningTest()) {
            pageContent = soInfoPreviewPDFPage.getContentAsPdf();
        } else {
            pageContent = Blob.valueof('Test String');
        }
        emailAttachmentList.add(emailAttachment);
        emailAttachment.setBody(pageContent);
        mail.setFileAttachments(emailAttachmentList);
        
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        mails.add(mail);
        Messaging.sendEmail(mails);
    }
    
    public static String sendInvoice(List<String> emailStrList, List<String> ccEmailStrList, String subject, String htmlBody, String recId, string isFinalized, String brandingLocationId){
        if(emailStrList.size() == 0) {
            return 'email list empty';
        }
        try {
	        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail = setDefaultFields(mail, brandingLocationId);
	        mail.setToAddresses(emailStrList);
	        mail.setCcAddresses(ccEmailStrList);
	        
	        List<Messaging.EmailFileAttachment> emailAttachmentList = new List<Messaging.EmailFileAttachment>();
	        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
	        Blob pageContent;
	        
	        PageReference pageName;
	        String objectName = String.valueOf(Id.valueOf(recId).getSobjectType());
            if(objectName == Constants.Namespace + 'CustomerApproval__c') {
            	emailAttachment.setFileName('Customer Approval.pdf');
		        pageName = Page.ServiceWorkSheetPDF;
		        pageName.getparameters().put('customerApprovalId', recId);
            } else if(String.isNotBlank(pageNameToEmail)) {
            	emailAttachment.setFileName(pageNameToFileNameMap.get(pageNameToEmail) + '.pdf');
		        pageName = new PageReference('/apex/' + pageNameToEmail);
		        pageName.getparameters().put('id', recId);
		        if(String.isNotBlank(brandingLocationId)) {
		        	pageName.getparameters().put('brandingLocationId', brandingLocationId);
		        }
            } else {
		        emailAttachment.setFileName('Customer Order Invoice.pdf');
		        pageName = Page.Invoice;
		        pageName.getparameters().put('id', recId);
		        pageName.getparameters().put('isFinalized', isFinalized);
		        if(String.isNotBlank(brandingLocationId)) {
		        	pageName.getparameters().put('brandingLocationId', brandingLocationId);
		        }
            }
            pageName.setRedirect(true);
	        
	        if(!Test.isRunningTest()) {
	            pageContent = pageName.getContent();
	        } else {
	            pageContent = Blob.valueof('Test String');
	        }
	        emailAttachment.setBody(pageContent);
	        emailAttachmentList.add(emailAttachment);
	        mail.setFileAttachments(emailAttachmentList);
	        mail.setSubject(subject);
	        mail.setHtmlBody(htmlBody);
	        mails.add(mail);
	        Messaging.sendEmail(mails);
            return 'success';
        } catch(exception e){
            return e.getMessage();
        }
    }
    
    public static String sendSelectedDocument(List<DocumentWrapper> docWrapperList, List<String> toEmailStrList, List<String> ccEmailStrList) {
       try {
            return sendSelectedDocument(docWrapperList, toEmailStrList, ccEmailStrList, null);
        } catch(Exception e) {
            return e.getMessage();
        }
    }
    
    public static String sendSelectedDocument(List<DocumentWrapper> docWrapperList, List<String> toEmailStrList, List<String> ccEmailStrList, String subject) {
       try {
            List<Messaging.EmailFileAttachment> emailAttachmentList = createAttachmentList(docWrapperList);
       		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       		String brandingLocationId = docWrapperList.size() > 0 ? docWrapperList[0].BrandingLocationId : null;
            mail = setDefaultFields(mail, brandingLocationId);
	        mail.setToAddresses(toEmailStrList);
	        mail.setCcAddresses(ccEmailStrList);
            mail.setFileAttachments(emailAttachmentList);
            if(String.isBlank(subject)) {
            	List<CO_Invoice_Header__c> coInvoiceHeaderList = [Select Id, Invoice_Number__c, CO_Header__r.Name,  CO_Header__r.Customer_Name__c from CO_Invoice_Header__c where Id =: docWrapperList[0].COInvoiceId];    
                if (coInvoiceHeaderList.size() > 0 ) {
                    if (docWrapperList.size() == 1) {
                        if (docWrapperList[0].DocumentName == 'Pick Ticket') {
                            subject = 'Part picklist' + ' - ' + coInvoiceHeaderList[0].CO_Header__r.Name +' - ' +  coInvoiceHeaderList[0].CO_Header__r.Customer_Name__c;
                        } else {
                            subject = docWrapperList[0].DocumentName + ' - ' + coInvoiceHeaderList[0].CO_Header__r.Name +' - ' +  coInvoiceHeaderList[0].CO_Header__r.Customer_Name__c;
                        }
                    } else  {
                        subject = 'Multiple documents' + ' - ' + coInvoiceHeaderList[0].CO_Header__r.Name +' - ' +  coInvoiceHeaderList[0].CO_Header__r.Customer_Name__c;
                    }                    
                } else {
                    subject = 'Document from '+ businessName;
                }
            }
            mail.setSubject(subject);             
            mail.setHtmlBody('');
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            return 'success';
        } catch(Exception e) {
            return e.getMessage();
        }
    }
    
    private static List<Messaging.EmailFileAttachment> createAttachmentList(List<DocumentWrapper> docWrapperList) {
        List<Messaging.EmailFileAttachment> emailAttachmentList = new List<Messaging.EmailFileAttachment>();
        List<String> attachmentIdList = new List<String>();
        for(DocumentWrapper docWrapperObj : docWrapperList) {
            if(docWrapperObj.DocumentName == 'Pick Ticket') {
                emailAttachmentList.add(generateAttachment(docWrapperObj.DocumentName, Page.PrintPickTicket, docWrapperObj.COHeaderId, docWrapperObj.BrandingLocationId));
            
            } else if(docWrapperObj.DocumentName == 'Job worksheet' || docWrapperObj.DocumentName == 'Job review') {
                Map<String, String> paramMap = new Map<String, String>{'isPrintReview' => String.valueOf(docWrapperObj.DocumentName == 'Job review')};
                for(String selectedDocJsonRec : docWrapperObj.SelectedDocumentJSONList) {
                    paramMap.put('SelectedSOIds', selectedDocJsonRec);
                    emailAttachmentList.add(generateAttachment(docWrapperObj.DocumentName, Page.ServiceJobWorkSheet, docWrapperObj.COHeaderId, docWrapperObj.BrandingLocationId, paramMap));
                }
            } else if(docWrapperObj.DocumentName == 'Deposit Receipt' || docWrapperObj.DocumentName == 'Print deposit receipt') {
                emailAttachmentList.add(generateAttachment(docWrapperObj.DocumentName, Page.CODepositsPdf, docWrapperObj.COHeaderId, docWrapperObj.BrandingLocationId));
            
            } else if(docWrapperObj.DocumentName == 'Offer to purchase' || docWrapperObj.DocumentName == 'Bill of sale') {
                emailAttachmentList.add(generateAttachment(docWrapperObj.DocumentName, Page.DealDocumentPdf, docWrapperObj.DealId, docWrapperObj.BrandingLocationId));
            
            } else if(docWrapperObj.DocumentName == 'Invoice preview') {
                for(String selectedDocJsonRec : docWrapperObj.SelectedDocumentJSONList) {
                    emailAttachmentList.add(generateInvoicePreviewAttachment(docWrapperObj.DocumentName, Page.Invoice, docWrapperObj.COInvoiceId, docWrapperObj.BrandingLocationId, selectedDocJsonRec));
                }
            } else if(docWrapperObj.DocumentName == 'VendorOrderPDF') {
                emailAttachmentList.add(generateAttachment(docWrapperObj.DocumentName, Page.PrintVendorOrder, docWrapperObj.VendorOrderId, docWrapperObj.BrandingLocationId));
            } else if(docWrapperObj.DocumentName == 'AttachmentFile') {
            	attachmentIdList.add(docWrapperObj.AttachmentId);
            }
        }
        if(attachmentIdList.size() > 0) {
        	List<Messaging.EmailFileAttachment> emailAttachmentsFromAttachment = getEmailAttachmentFromAttachmentObject(attachmentIdList);
        	if(emailAttachmentsFromAttachment.size() > 0) {
        		emailAttachmentList.addAll(emailAttachmentsFromAttachment);
        	}
        }
        return emailAttachmentList;
    }
    
    private static List<Messaging.EmailFileAttachment> getEmailAttachmentFromAttachmentObject(List<String> attachmentIdList) {
    	List<Messaging.EmailFileAttachment> emailAttachmentList = new List<Messaging.EmailFileAttachment>();
    	if(AccessControl.ifObjectFieldIsAccessible('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Attachment> attachmentToEmailList = [SELECT Name,Body FROM Attachment WHERE Id IN :attachmentIdList];
		for(Integer i=0; i < attachmentToEmailList.size(); i++) {
			Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
			emailAttachment.setFileName(attachmentToEmailList[i].Name);
			emailAttachment.setBody(attachmentToEmailList[i].Body);
    		emailAttachmentList.add(emailAttachment);
		}
		return emailAttachmentList;
    }
    
    private static Messaging.EmailFileAttachment generateInvoicePreviewAttachment(String fileName, PageReference pageToEmail, String recordId, String brandingLocationId, String selectedDocJson) {
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        PageReference emailPage = pageToEmail;
        emailAttachment.setFileName(fileName + '.pdf');
        emailPage.getparameters().put('id', recordId);
        emailPage.getparameters().put('isFinalized', 'false');
        if(String.isNotBlank(brandingLocationId)) {
        	emailPage.getparameters().put('brandingLocationId', brandingLocationId);
        }
        emailPage.getparameters().put('SelectedSectionsIds', selectedDocJson);
        Blob pageContent;
        if(!Test.isRunningTest()) {
            pageContent = emailPage.getContent();
        } else {
            pageContent = Blob.valueof('Test String');
        }
        emailAttachment.setBody(pageContent);
        return emailAttachment;
    }

    private static Messaging.EmailFileAttachment generateAttachment(String fileName, PageReference pageToEmail, String recordId, String brandingLocationId) {
        return generateAttachment(fileName, pageToEmail, recordId, brandingLocationId, null);
    }

    private static Messaging.EmailFileAttachment generateAttachment(String fileName, PageReference pageToEmail, String recordId, String brandingLocationId, Map<String, String> parameKeyToValueMap) {
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName(fileName + '.pdf');
        pageToEmail.getparameters().put('id', recordId);
        if(fileName == 'Invoice preview') {
            pageToEmail.getparameters().put('isFinalized', 'false');
        }  else if(fileName == 'Offer to purchase' || fileName == 'Bill of sale') {
            pageToEmail.getparameters().put('documentType', fileName);
        }
        if(String.isNotBlank(brandingLocationId)) {
        	pageToEmail.getparameters().put('brandingLocationId', brandingLocationId);
        }
        if(parameKeyToValueMap != null) {
            for(String key : parameKeyToValueMap.keySet()) {
                pageToEmail.getparameters().put(key, parameKeyToValueMap.get(key));
            }
        }
        Blob pageContent;
        if(!Test.isRunningTest()) {
            pageContent = pageToEmail.getContent();
        } else {
            pageContent = Blob.valueof('Test String');
        }
        emailAttachment.setBody(pageContent);
        return emailAttachment;
    }
    
    public class DocumentWrapper {
        public String DocumentName;
        public String COHeaderId;
        public String COInvoiceId;
        public String DealId;
        public String VendorOrderId;
        public String AttachmentId;
        public String BrandingLocationId;
        public List<String> SelectedDocumentJSONList;
        public DocumentWrapper() {
            
        }
    }
    
    public static void sendSupportMail(List<String> emailStrList, String subject, String htmlBody) {
        if(emailStrList.size() == 0) {
            return;
        }  
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail = setDefaultFields(mail, null);
        List<String> sendTo = emailStrList;
        mail.setToAddresses(sendTo);
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        mails.add(mail);
        Messaging.sendEmail(mails);
    }
    
    private static Messaging.SingleEmailMessage setDefaultFields(Messaging.SingleEmailMessage mail, String brandingLocationId) {
    	List<Business_Profile__c> businessProfiles;
    	Branding_Location__c brandingLocationRec;
    	if(String.isBlank(brandingLocationId)) {
    		businessProfiles = SOQLUtil.getBusinessProfileData(new List<id>());
    	} else {
    		for(Branding_Location__c brandingLocRec: BrandingLocationSOQLUtil.getBrandingLocationDetailListByFilter(new Map<String, String>{'Id' => brandingLocationId})) {
	     		brandingLocationRec = brandingLocRec;
	     	}
    	}
        String sentFromEmailString;
        if(brandingLocationRec != null) {
        	businessName = brandingLocationRec.Business_Location_Name__c;
            sentFromEmailString = brandingLocationRec.Business_Email_Address__c;
        } else if(businessProfiles.size() > 0) {
            businessName = String.isNotBlank(businessProfiles[0].Business_Name__c) ? businessProfiles[0].Business_Name__c : FALLBACK_SENDER;
            sentFromEmailString = businessProfiles[0].Business_Email__c;
        } else {
            sentFromEmailString = Configurations__c.getInstance().Sent_From_Email_Id__c;
        }
        
        OrgWideEmailAddress[] owea;
        if(Email_Configuration__c.getOrgDefaults().Is_Org_Wide_Email_Verified__c) {
        	owea = [select Id from OrgWideEmailAddress Order By CreatedDate DESC LIMIT 1];
        }
        
		if(owea != null && owea.size() > 0) {
		    mail.setOrgWideEmailAddressId(owea.get(0).Id);
		} else {
			mail.setSenderDisplayName(businessName);
		}
        mail.setReplyTo(sentFromEmailString);
        return mail;
    }
    
     public static void sendFirstErrorEmail(String entityNameInUpperCase, String htmlBody,String subject) {
		String defaultEmail = GeneralConfiguration.getSupportEmailRecipient();
		List<String> emailStrList = new List<String>();
		if(String.isNotBlank(defaultEmail)) {
			emailStrList = defaultEmail.split(';');
		} else { 
			String supportMail = GeneralConfiguration.getSupportEmail();
			emailStrList = new List<String>{supportMail};
		}
		if(!Test.isRunningTest()){
			sendSupportMail(emailStrList, subject, htmlBody);
		}
	}
	
	public class EmailAddressWrapper {
        public String ToEmail;
        public String CcEmail;
        public String PageName;
    }
    
    public static Map<String, String> pageNameToFileNameMap = new Map<String, String>{'OrderFulfillmentInvoice' => 'Order Fulfillment'};
}