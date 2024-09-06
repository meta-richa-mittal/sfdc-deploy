@isTest
public class SendEmailRestServiceTest {
    static testMethod void testSendEmail() {
        SendEmailRestService.PostResponseWrapper resWrapperObj = new SendEmailRestService.PostResponseWrapper();
        resWrapperObj.ErrorMsg ='None';
        resWrapperObj.FileName = 'Employee Report.csv';
        resWrapperObj.ServerName = 'FTP';
        resWrapperObj.StatusCode = '200';

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/SendEmail/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        String response = SendEmailRestService.sendEmail(resWrapperObj);
        system.assertEquals('Success', response);
    }
    
    static testMethod void testSendEmailForBlankError() {
        SendEmailRestService.PostResponseWrapper resWrapperObj = new SendEmailRestService.PostResponseWrapper();
        resWrapperObj.ErrorMsg = null;
        resWrapperObj.FileName = 'Employee Report.csv';
        resWrapperObj.ServerName = '';
        resWrapperObj.StatusCode = 'Success';

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/SendEmail/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        String response = SendEmailRestService.sendEmail(resWrapperObj);
        system.assertEquals('Success', response);
    }
    
    static testMethod void testSendEmailForBlankStatusCode() {
        SendEmailRestService.PostResponseWrapper resWrapperObj = new SendEmailRestService.PostResponseWrapper();
        resWrapperObj.ErrorMsg = null;
        resWrapperObj.FileName = 'Employee Report.csv';
        resWrapperObj.ServerName = null;
        resWrapperObj.StatusCode = '';

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/SendEmail/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        String response = SendEmailRestService.sendEmail(resWrapperObj);
        system.assertEquals('Success', response);
    }
    
    static testMethod void testSendEmailForFTPServer() {
        SendEmailRestService.PostResponseWrapper resWrapperObj = new SendEmailRestService.PostResponseWrapper();
        resWrapperObj.ErrorMsg = null;
        resWrapperObj.FileName = 'Employee Report.csv';
        resWrapperObj.StatusCode = 'Success';
		resWrapperObj.ServerName = 'FTP';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/SendEmail/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        String response = SendEmailRestService.sendEmail(resWrapperObj);
        system.assertEquals('Success', response);
    }
    
    static testMethod void testSendEmailForStausCode() {
        SendEmailRestService.PostResponseWrapper resWrapperObj = new SendEmailRestService.PostResponseWrapper();
        resWrapperObj.ErrorMsg = null;
        resWrapperObj.FileName = 'Employee Report.csv';
        resWrapperObj.StatusCode = 'Error';
		resWrapperObj.ServerName = 'FTP';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/SendEmail/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        String response = SendEmailRestService.sendEmail(resWrapperObj);
        system.assertEquals('Success', response);
    }

}