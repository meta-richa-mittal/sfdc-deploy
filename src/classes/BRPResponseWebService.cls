@RestResource(urlMapping = '/BRPResponse/*')
global without sharing class BRPResponseWebService {
        
    @HttpPost
    global static String sendEmail(PostResponseWrapper postResponse) {
    	SendEmailRestService.PostResponseWrapper emailResponseObj= new SendEmailRestService.PostResponseWrapper();
    	try {
    		emailResponseObj.ServerName = 'BRP';
	        emailResponseObj.StatusCode = (postResponse != null && postResponse.StatusCode != null) ? String.valueOf(postResponse.StatusCode) : null;
	        emailResponseObj.FileName = postResponse.FileName;
	        
	        HttpResponse res = new HttpResponse();
			if(postResponse.StatusCode != null) {
				res.setStatusCode(postResponse.StatusCode);
			}
    		if(postResponse.IsJavaSuccess) {
    			// handle BRP response
    			res.setBody(postResponse.ResponseXMLString);
    		} else {
				// Error from Java program
    			res.setBody('Some error occured at Java program - ' + postResponse.ErrorResponse);
				if(postResponse.ErrorResponse != null && postResponse.ErrorResponse.contains('Failed to deliver synchronous message: senderChannel')) {
					MergeAndPostToBRPQueueable.BRPFileDetailWrapper brpDetailWrapperObj = (MergeAndPostToBRPQueueable.BRPFileDetailWrapper) System.JSON.deserialize(postResponse.RequestParamStr, MergeAndPostToBRPQueueable.BRPFileDetailWrapper.class);
					if(!brpDetailWrapperObj.IsRetryFilePosting) {
						BPUtility.abortAlreadyScheduleJobs('BRP Part Inventory Merge And Post Scheduler');
						DateTime dtVal = system.now().addMinutes(15);
						String CRON_EXP = String.valueOf(dtVal.second()) + ' ' + String.valueOf(dtVal.minute()) + ' ' + String.valueOf(dtVal.hour()) +
													   ' ' + String.valueOf(dtVal.day()) + ' ' + String.valueOf(dtVal.month()) + ' ?' + ' ' + String.valueOf(dtVal.year());
						system.schedule('BRP Part Inventory Merge And Post Scheduler', CRON_EXP, new MergeAndPostToBRPScheduler(brpDetailWrapperObj.ExportType, brpDetailWrapperObj.AttachmentIdList, DateTimeUtility.parseDateTime(brpDetailWrapperObj.DateTimeValue), true));
						return 'success';
					}
				}
    		}
    		BRP_log__c brpLogRec = BRPUtility.handleResponse('Parts Inventory', postResponse.RequestParamStr, res);
    		brpLogRec.Apex_Class__c = 'BRPResponseWebService';
    		brpLogRec.Method__c = 'sendEmail';
    		insert brpLogRec;
    	} catch(Exception e) {
    		emailResponseObj.StatusCode = null;
    		emailResponseObj.ErrorMsg = 'Error while handling BRP response';
    		insert new BRPLogService().sampleLog('Parts Inventory', postResponse.toString(), null, null, (postResponse != null ? String.valueOf(postResponse.StatusCode) : null), 
        														('Error while handling BRP response - ' + e.getMessage() + '\n\n' + e.getStackTraceString()), 
        														'Error', 'BRPResponseWebService', 'sendEmail', null);
    	}
    	SendEmailRestService.sendEmail(emailResponseObj);
        return 'Success';
    }
    
    global class PostResponseWrapper {
    	public String RequestParamStr;
    	public String ErrorResponse;
		public Boolean IsJavaSuccess;
		public Integer StatusCode;
		public String ResponseXMLString;
		public String FileName;
	}
}