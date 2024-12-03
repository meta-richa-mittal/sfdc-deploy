/**
* Author : Manoj Sharma
* Since : April 13, 2023
* Name : FilePostToSOMQueueable
* Description : Queueable class to post files to SFTP server and handle retry
**/
public without sharing class FilePostToSOMQueueable  implements Queueable, Database.AllowsCallouts{
    public String endPoint;
    public String authHeaderValue;
    public String fileName;
    public Blob bodyBlob;
    private static List<Log__c> logListToInsert = new List<Log__c>();
    public Integer retryCount;
    public FilePostToSOMQueueable(String endPoint, String authHeaderValue, Blob bodyBlob, String fileName, Integer retryCount) {
        this.endPoint = endPoint;
        this.authHeaderValue = authHeaderValue;
        this.fileName = fileName;
        this.bodyBlob = bodyBlob;
        this.retryCount = retryCount;
    }
    
    public void execute(QueueableContext context) {
        uploadToSFTPServer(endPoint, authHeaderValue, bodyBlob, fileName, retryCount);
    }   

    private static void uploadToSFTPServer(String endPoint, String authHeaderValue, Blob bodyBlob, String fileName, Integer retryCount) {
        String boundary = '----------------------------741e90d31eff';
        try{
            HTTPResponse postRes = doPost(endPoint, bodyBlob, boundary, authHeaderValue);
        
            HTTPResponse getRes = doGet(endPoint + '/' + fileName, authHeaderValue);
            logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Error_Code__c = String.valueOf(postRes.getStatusCode()),
                        Apex_Class__c = 'FilePostToSOMQueueable - Post response', Type__c = 'Info', 
                        Method_Params__c = 'File name ' + fileName, 
                        Log_Info__c =  postRes.getBody().length() > 2000 ? postRes.getBody().subString(0, 2000) : postRes.getBody()));
            
            // Retry if file failed to post
            if(getRes.getStatusCode() != 200 && getRes.getStatusCode() != 201 && retryCount < 4) {
                retryCount++;
                logListToInsert = new List<Log__c>(); 
                System.enqueueJob(new FilePostToSOMQueueable(endPoint, authHeaderValue, bodyBlob, fileName, retryCount));
            } else {
                if(getRes.getStatusCode() != 200 && getRes.getStatusCode() != 201) {
                    logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Error_Code__c = String.valueOf(getRes.getStatusCode()),
                            Method_Params__c = 'File name ' + fileName, 
                            Apex_Class__c = 'FilePostToSOMQueueable - Get response', Type__c = 'Error'));
                            
                } else {
                    logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Error_Code__c = String.valueOf(getRes.getStatusCode()),
                            Method_Params__c = 'File name ' + fileName, 
                            Apex_Class__c = 'FilePostToSOMQueueable - Get response', Type__c = 'Info'));
                }
                sendFinishMail(getRes, fileName);
            }
        } catch(Exception e) {
            logListToInsert.add(new Log__c(Integration_Type__c = 'SOM', Log_Info__c = e.getMessage(),
            Method_Params__c = 'fileType ' + fileName, Method__c = 'uploadToSFTPServer()', 
            Apex_Class__c = 'FilePostToSOMQueueable', Type__c = 'Error'));
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
        HTTPResponse res = new HTTPResponse();
        if(!Test.isRunningTest()) {
            res = http.send(req);
        } else {
            res.setStatusCode(200);
            res.setBody('File posted');
        }
        return res;
    }
    
    private static HTTPResponse doGet(String endPoint, String authHeaderValue) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endPoint);
        req.setHeader('Authorization', authHeaderValue);
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        if(!Test.isRunningTest()) {
            res = http.send(req);
        } else {
            res.setStatusCode(200);
            res.setBody('File posted');
        }
        return res;
    }

    private static void sendFinishMail(HTTPResponse res, String fileName) {
        if(fileName.startsWithIgnoreCase('POO-')) {
            SOMPartsOnOrderBatch.sendFinishMail(res, fileName);
        } else if(fileName.startsWithIgnoreCase('PSI-')) {
            SOMPartSalesTransactionBatchScheduler.sendFinishMail(res, fileName);
        }
    }
}