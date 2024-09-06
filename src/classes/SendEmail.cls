public without sharing class SendEmail {
    
    private static String FALLBACK_SENDER = 'BlackPurl';
    private static String businessName;
    public static String pageNameToEmail;
    
    public static void send(List<String> emailStrList, String subject, String htmlBody, String soHeaderId) {
        send(emailStrList, subject, htmlBody, soHeaderId, null);
    }

    public static void send(List<String> emailStrList, String subject, String htmlBody, String attId, String attName) {
        if(emailStrList.isEmpty()) {
            return;
        }
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail = setDefaultFields(mail, null, null);
        
        List<String> sendTo = emailStrList;
        mail.setToAddresses(sendTo);
        
        if(attId != null) {
            List<Messaging.EmailFileAttachment> emailAttachmentList = new List<Messaging.EmailFileAttachment>();
            String objectName = (Id.valueOf(attId)).getSObjectType().getDescribe().getName();
            if(objectName == 'Attachment') {
                List<Messaging.EmailFileAttachment> emailAttachmentsFromAttachment = getEmailAttachmentFromAttachmentObject(new List<String>{attId}, 
                                                                                        new Map<String, String>{attId => attName});
                if(!emailAttachmentsFromAttachment.isEmpty()) {
                    emailAttachmentList.addAll(emailAttachmentsFromAttachment);
                }
            } else {
                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                emailAttachment.setFileName('Service Order Preview.pdf');
                PageReference soInfoPreviewPDFPage = Page.SOInfoPrintPreviewPDF;
                soInfoPreviewPDFPage.getparameters().put('id', attId);
                Blob pageContent;
                if(!Test.isRunningTest()) {
                    pageContent = soInfoPreviewPDFPage.getContentAsPdf();
                } else {
                    pageContent = Blob.valueof('Test String');
                }
                emailAttachmentList.add(emailAttachment);
                emailAttachment.setBody(pageContent);
            }
            mail.setFileAttachments(emailAttachmentList);
        }
        
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        mails.add(mail);
        Messaging.sendEmail(mails);
    }
    
    public static String sendInvoice(List<String> emailStrList, List<String> ccEmailStrList, String subject, String optionalMessage, String recId, string isFinalized, String brandingLocationId){
        return sendInvoice(emailStrList, ccEmailStrList, subject, optionalMessage, recId, isFinalized, brandingLocationId, null);
    }

    public static String sendInvoice(List<String> emailStrList, List<String> ccEmailStrList, String subject, String optionalMessage, String recId, string isFinalized, String brandingLocationId, String replyToEmail) {
        if(emailStrList.size() == 0) {
            return 'email list empty';
        }
        try {
	        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail = setDefaultFields(mail, brandingLocationId, replyToEmail);
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
	        mail.setPlainTextBody(optionalMessage);
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
        return sendSelectedDocument(docWrapperList, toEmailStrList, ccEmailStrList, subject, null);
    }

    public static String sendSelectedDocument(List<DocumentWrapper> docWrapperList, List<String> toEmailStrList, List<String> ccEmailStrList, String subject, String optionalMessage) {
        return sendSelectedDocument(docWrapperList, toEmailStrList, ccEmailStrList, subject, optionalMessage, null);
    }

    public static String sendSelectedDocument(List<DocumentWrapper> docWrapperList, List<String> toEmailStrList, List<String> ccEmailStrList, String subject, String optionalMessage, String replyToEmail) {
       try {
            List<Messaging.EmailFileAttachment> emailAttachmentList = createAttachmentList(docWrapperList);
       		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       		String brandingLocationId = docWrapperList.size() > 0 ? docWrapperList[0].BrandingLocationId : null;
            List<CO_Invoice_Header__c> coInvoiceHeaderList;
            mail = setDefaultFields(mail, brandingLocationId, replyToEmail);
	        mail.setToAddresses(toEmailStrList);
	        mail.setCcAddresses(ccEmailStrList);
            mail.setFileAttachments(emailAttachmentList);
            if(String.isBlank(subject) || docWrapperList[0].DocumentName.startsWith('Invoice')) {
            	coInvoiceHeaderList = [Select Id, Invoice_Number__c, CO_Header__r.Customer__c, CO_Header__r.CO_Type__c, CO_Header__r.Name,  CO_Header__r.Customer_Name__c from CO_Invoice_Header__c where Id =: docWrapperList[0].COInvoiceId];    
                if(coInvoiceHeaderList.size() > 0 && String.isBlank(subject)) {
                    if (docWrapperList.size() == 1) {
                        if (docWrapperList[0].DocumentName == 'Pick Ticket') {
                            subject = 'Part picklist' + ' - ' + coInvoiceHeaderList[0].CO_Header__r.Name +' - ' +  coInvoiceHeaderList[0].CO_Header__r.Customer_Name__c;
                        } else if (docWrapperList[0].DocumentName.startsWith('Invoice')) {
                            subject = 'Invoice' + ' - ' + coInvoiceHeaderList[0].Invoice_Number__c +' - ' +  coInvoiceHeaderList[0].CO_Header__r.Customer_Name__c;
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
            mail.setPlainTextBody(String.isNotBlank(optionalMessage) ? optionalMessage: '');
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});

            // Create message history record for Customer Order Invoice
            if(coInvoiceHeaderList != null && !coInvoiceHeaderList.isEmpty() && !toEmailStrList.isEmpty()) {
                String customerId = (coInvoiceHeaderList[0].CO_Header__r.CO_Type__c == Constants.CHECKOUT_TYPE_CUSTOMER && 
                                        coInvoiceHeaderList[0].CO_Header__r.Customer__c != null) ? coInvoiceHeaderList[0].CO_Header__r.Customer__c : null;
                MessageHistoryService.addMessageHistoryRecord(docWrapperList[0].COInvoiceId, customerId, 
                                                                'Email Invoice PDF', 'Emailed Invoice', toEmailStrList[0]);
            }
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
                    emailAttachmentList.add(generateInvoicePreviewAttachment(docWrapperObj.DocumentName, Page.Invoice, docWrapperObj.COInvoiceId, docWrapperObj.BrandingLocationId, selectedDocJsonRec, 'false'));
                }
            } else if(docWrapperObj.DocumentName.startsWith('Invoice')) {
                emailAttachmentList.add(generateInvoicePreviewAttachment('Customer Order Invoice', Page.Invoice, docWrapperObj.COInvoiceId, docWrapperObj.BrandingLocationId, null, 'true'));
            } else if(docWrapperObj.DocumentName == 'VendorOrderPDF') {
                emailAttachmentList.add(generateAttachment(docWrapperObj.DocumentName, Page.PrintVendorOrder, docWrapperObj.VendorOrderId, docWrapperObj.BrandingLocationId));
            } else if(docWrapperObj.DocumentName == 'AttachmentFile') {
            	attachmentIdList.add(docWrapperObj.AttachmentId);
            } else if(docWrapperObj.DocumentName == 'Customer Approval') {
            	emailAttachmentList.add(generateAttachment(docWrapperObj.DocumentName, Page.ServiceWorkSheetPDF, docWrapperObj.CustomerApprovalId, docWrapperObj.BrandingLocationId));
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
    	return getEmailAttachmentFromAttachmentObject(attachmentIdList, null);
    }

    private static List<Messaging.EmailFileAttachment> getEmailAttachmentFromAttachmentObject(List<String> attachmentIdList, Map<String, String> attIdToNameMap) {
    	List<Messaging.EmailFileAttachment> emailAttachmentList = new List<Messaging.EmailFileAttachment>();
    	if(AccessControl.ifObjectFieldIsAccessible('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Attachment> attachmentToEmailList = [SELECT Name,Body FROM Attachment WHERE Id IN :attachmentIdList];
        for(Integer i=0; i < attachmentToEmailList.size(); i++) {
			Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
            String attName = (attIdToNameMap != null && attIdToNameMap.containsKey(attachmentToEmailList[i].Id)) ? attIdToNameMap.get(attachmentToEmailList[i].Id) : attachmentToEmailList[i].Name;
			emailAttachment.setFileName(attName);
			emailAttachment.setBody(attachmentToEmailList[i].Body);
    		emailAttachmentList.add(emailAttachment);
		}
		return emailAttachmentList;
    }
    
    private static Messaging.EmailFileAttachment generateInvoicePreviewAttachment(String fileName, PageReference pageToEmail, String recordId, String brandingLocationId, String selectedDocJson, String isFinalized) {
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        PageReference emailPage = pageToEmail;
        emailAttachment.setFileName(fileName + '.pdf');
        emailPage.getparameters().put('id', recordId);
        emailPage.getparameters().put('isFinalized', isFinalized);
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
        if(fileName == 'Customer Approval') {
            pageToEmail.getparameters().put('customerApprovalId', recordId);
        } else {
            pageToEmail.getparameters().put('id', recordId);
        }
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
        public String CustomerApprovalId;
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
        mail = setDefaultFields(mail, null, null);
        mail.setToAddresses(emailStrList);
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        mails.add(mail);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(mails);
        }
    }

    public static void sendSupportMailWithAttachment(List<String> emailStrList, String subject, String htmlBody, Messaging.EmailFileAttachment emailAttachment) {
        if(!emailStrList.isEmpty()) {
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSenderDisplayName('BlackPurl Team');
            if(String.isNotBlank(Configurations__c.getOrgDefaults().Sent_From_Email_Id__c)){
                mail.setReplyTo(Configurations__c.getOrgDefaults().Sent_From_Email_Id__c);
            }
            mail.setToAddresses(emailStrList);
            mail.setSubject(subject);
            mail.setHtmlBody(htmlBody);
            if(emailAttachment != null) {
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {emailAttachment});
            }
            mails.add(mail);
            if(!Test.isRunningTest()){
                Messaging.sendEmail(mails);
            }
        }
    }
    
    private static Messaging.SingleEmailMessage setDefaultFields(Messaging.SingleEmailMessage mail, String brandingLocationId, String replyToEmail) {
    	List<Business_Profile__c> businessProfiles;
    	Branding_Location__c brandingLocationRec;
    	if(String.isBlank(brandingLocationId)) {
    		businessProfiles = SOQLUtil.getBusinessProfileData(new List<id>());
    	} else {
    		for(Branding_Location__c brandingLocRec: BrandingLocationSOQLUtil.getBrandingLocationDetailListByFilter(new Map<String, String>{'Id' => brandingLocationId})) {
	     		brandingLocationRec = brandingLocRec;
	     	}
    	}

        if(brandingLocationRec != null) {
            businessName = brandingLocationRec.Business_Location_Name__c;
            if(String.isBlank(replyToEmail)) replyToEmail = brandingLocationRec.Business_Email_Address__c;
        } else if(businessProfiles.size() > 0) {
            businessName = String.isNotBlank(businessProfiles[0].Business_Name__c) ? businessProfiles[0].Business_Name__c : FALLBACK_SENDER;
            if(String.isBlank(replyToEmail)) replyToEmail = businessProfiles[0].Business_Email__c;
        } else if(String.isBlank(replyToEmail)) {
            replyToEmail = Configurations__c.getInstance().Sent_From_Email_Id__c;
        }
        
        List<OrgWideEmailAddress> oweaList = [select Id from OrgWideEmailAddress Where IsVerified = true Order By CreatedDate DESC LIMIT 1];
        
		if(!oweaList.isEmpty()) {
		    mail.setOrgWideEmailAddressId(oweaList[0].Id);
		} else {
			mail.setSenderDisplayName(businessName);
		}
        mail.setReplyTo(replyToEmail);
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
        public String OptionalMessage;
        public String ReplyTo;
    }
    
    public static Map<String, String> pageNameToFileNameMap = new Map<String, String>{'OrderFulfillmentInvoice' => 'Order Fulfillment',
                                                                                        'PrintPaymentOnAccount' => 'Payment Receipt'};
}