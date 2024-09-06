@RestResource(urlMapping = '/GetAttachmentBody/*')
global without sharing class AttachmentBodyRestService {
    
    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        String attachmentId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        List<Attachment> attachList = [SELECT Body FROM Attachment WHERE Id =: attachmentId];
        return EncodingUtil.base64Encode(attachList[0].Body);
    }
}