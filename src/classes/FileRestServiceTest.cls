@isTest
public class FileRestServiceTest {
    @testSetup
    static void dataSetup() {
        Account customer = TestUtil.createCustomer(true, 'Test', 'avc@gmail.com', 'Jaipur', '111111111');  

        String header = 'Name';
        String body = 'Test';
        
        Attachment att = new Attachment();
        att.ContentType = 'text/csv';
        att.Name = 'Employee Report.csv';
        att.Body = Blob.valueOf(header + '\n' + body);
        att.ParentId = customer.Id;

        insert att;
    }

    static testMethod void testGet() {
      
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        Attachment attachmentObj = [ SELECT Id, name, body  FROM Attachment LIMIT 1 ];
        req.requestURI = '/services/apexrest/GetAttachmentDetail/' + attachmentObj.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        String attachmentResp = FileRestService.doGet();
        System.debug(attachmentResp);
        system.assertNotEquals(null, attachmentResp);
    }

}