/**
 * Author: Namarta Gocher
 * Since: December 19, 2022
 * Name: ExportPartWrongQtyCommittedService
 * Description: Service class to generate CSV file for Parts which shows wrong Committed Qty.
**/
public with sharing class ExportPartWrongQtyCommittedService {

    public static String createFileData(List<Part__c> partList) {
        String fileContent = '';
        for(Part__c partRec: partList) {
            partRec.Qty_Committed__c = partRec.Qty_Committed__c != null ? partRec.Qty_Committed__c : 0;
            Decimal actualQtyCommitted = 0;

            for(CO_Line_Item__c coli: partRec.CO_Line_Items__r) {
                actualQtyCommitted += ((coli.Qty_Committed__c != null ? coli.Qty_Committed__c : 0) - (coli.Oversold_Qty__c != null ? coli.Oversold_Qty__c : 0));
            }
 
            for(Return_VO_Line_Item__c rvoli: partRec.Return_VO_Line_Items__r) {
                    actualQtyCommitted += rvoli.Return_Qty__c;
            }

            if(actualQtyCommitted != partRec.Qty_Committed__c) {
				fileContent += partRec.Id + ','; //Part SF Id
                fileContent += partRec.Part_Number__c + ','; //Part Number
                fileContent += partRec.Vendor_Name__c + ','; //Vendor Name
                fileContent += partRec.Vendor_Code__c + ','; //Vendor Code
                fileContent += String.valueOf(partRec.Qty_Committed__c) + ',' ; //Current Committed Qty
                fileContent += String.valueOf(actualQtyCommitted) + '\n'; //Committed Qty should be
            }
        }
        return fileContent;
    }

    public static void createAttachment(String fileContent) {
        Attachment attachment = new Attachment();
        attachment.ParentId = getParentId(); 
        attachment.ContentType = 'text/csv';
        attachment.Name = 'PartWrongQtyCommitted_' + Datetime.now().format('yyyyMMdd_HHmmss') + '.csv';
        attachment.Body = Blob.valueOf(fileContent);
        DMLUtility.insertSobjectList('Attachment', attachment);
    }
    
    public static String getParentId() {
        if(!AccessControl.ifObjectFieldIsAccessible('File_Storage__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<File_Storage__c> fileStorageList = [SELECT Id FROM File_Storage__c WHERE Name__c = 'L1 Support Document' LIMIT 1];
        
        File_Storage__c fileStorageRec = new File_Storage__c();
        if(fileStorageList.size() > 0) {
            fileStorageRec = fileStorageList[0];
        } else {
            fileStorageRec.Name__c = 'L1 Support Document';
            DMLUtility.insertSobjectList('File_Storage__c', fileStorageRec);
        }
        return fileStorageRec.Id;
    }

    public static void sendEmailWithAttachment(String fileData) {
        String header = 'Part#,Vendor Name,Qty Committed,Part URL\n';
        Blob attContent = Blob.valueOf(header + fileData);

        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName('attachment.csv');
        emailAttachment.setBody(attContent);

        String subject = UserInfo.getOrganizationName() +' - Incorrect Committed Parts Alert';
        String htmlBody = '<span> Hi Support Team, </span><p>Please find the attached list of parts with incorrect committed quantities.</p>';
        SendEmail.sendSupportMailWithAttachment(new List<String>{'blackpurl@metacube.com'}, subject, htmlBody, emailAttachment);
    }
}