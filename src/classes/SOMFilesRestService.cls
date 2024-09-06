@RestResource(urlMapping = '/SOMFile/*')
global without sharing class SOMFilesRestService {
    
    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String attachmentId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        Attachment attchmentRec = [SELECT Body FROM Attachment WHERE Id =: attachmentId];
        return EncodingUtil.base64Encode(attchmentRec.Body);
    }
}