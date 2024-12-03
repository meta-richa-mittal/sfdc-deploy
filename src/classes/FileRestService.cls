@RestResource(urlMapping = '/GetAttachmentDetail/*')
global without sharing class FileRestService {
    
    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        String attachmentId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        List<Attachment> attachList = [SELECT Name, Body FROM Attachment WHERE Id =: attachmentId];
        
        if(attachList.size() == 0) {
        	throw new BlackpurlException('Could not found attachment with Id - ' + attachmentId);
        }
        FileWrapper fileObj = new FileWrapper();
        fileObj.FileName = attachList[0].Name;
        fileObj.FileBody = (attachList[0].Body).toString();
      
        return EncodingUtil.base64Encode(Blob.valueOf(System.JSON.serialize(fileObj)));
    }
    
    public class FileWrapper {
      public String FileName;
      public String FileBody;
    }
}