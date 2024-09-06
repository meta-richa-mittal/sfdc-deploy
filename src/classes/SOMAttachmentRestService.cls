@RestResource(urlMapping='/SOMAttachment/*')
global without sharing class SOMAttachmentRestService {

    @HttpGet
    global static String doGet() {
        String somPartInvFileNameExcludingBatchNum = BP_Configurations__c.getOrgDefaults().SOM_Part_Inventory_File_Name__c;
        if(String.isNotBlank(somPartInvFileNameExcludingBatchNum)) {
            SOM_Configuration__c somConfigRec = SOM_Configuration__c.getOrgDefaults();
			SOMConfigWrapper somConfigObj = new SOMConfigWrapper();
			somConfigObj.FileName = somPartInvFileNameExcludingBatchNum;
			somConfigObj.Username = somConfigRec.Username__c;
			somConfigObj.Password = somConfigRec.Password__c;
			somConfigObj.Folder = somConfigRec.Upload_Directory__c;
            somConfigObj.IdStr = '';
            
            somPartInvFileNameExcludingBatchNum += '%';
            List<Attachment> attList = [SELECT Id FROM Attachment WHERE Name Like :somPartInvFileNameExcludingBatchNum Order By Name ASC];
          
            for(Attachment attch : attList) {
                somConfigObj.IdStr += (attch.Id + ',');
            }
            return EncodingUtil.base64Encode(Blob.valueOf(System.JSON.serialize(somConfigObj)));
        }
        return '';
    }
    
    public class SOMConfigWrapper {
        public String IdStr;
        public String FileName;
        public String Username;
        public String Password;
        public String Folder;
    }
}