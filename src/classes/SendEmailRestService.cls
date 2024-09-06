@RestResource(urlMapping = '/SendEmail/*')
global without sharing class SendEmailRestService {
        
    @HttpPost
    global static String sendEmail(PostResponseWrapper postResponse) {
    	String subject = UserInfo.getOrganizationName();
    	try {
			subject += String.isNotBlank(postResponse.FileName) ? ' File - ' + postResponse.FileName + ' ' : ' <fileName_missing> ';
			
			postResponse.ServerName = String.isNotBlank(postResponse.ServerName) ? postResponse.ServerName : '';
			
			if(String.isNotBlank(postResponse.ErrorMsg)) {
				subject += 'posting Failed on ' + postResponse.ServerName;
			} else {
				if(String.isNotBlank(postResponse.StatusCode) && (postResponse.StatusCode == '200' || postResponse.StatusCode == '201' || postResponse.StatusCode.equalsIgnoreCase('Success'))) {
					subject += 'posted Successfully on ' + postResponse.ServerName;
				} else {
					subject += 'posting Failed on ' + postResponse.ServerName;
				}
			}

	        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.ToAddresses = new List<String>{'blackpurl@metacube.com'};
			message.Subject = subject;
			message.PlainTextBody = 'Hi,\n\n'+ 
									postResponse.ServerName + ' file posting response is ' + postResponse.toString() + '\n\n' +
									'Thank You\nTeam Blackpurl';
			
		    // Added retry logic for failed SOM file posting
			BP_Configurations__c BPConfigurations = BP_Configurations__c.getOrgDefaults();        
			if(postResponse.ServerName == 'SOM' && !postResponse.StatusCode.equalsIgnoreCase('Success') && BPConfigurations.SOM_File_Posting_Retry_Count__c < 4) {
				BPConfigurations.SOM_File_Posting_Retry_Count__c = BPConfigurations.SOM_File_Posting_Retry_Count__c + 1;
				upsert BPConfigurations;	
				SOMUtility.retryFilePostingToSOM();
				return 'Success';
			} else if(!postResponse.StatusCode.equalsIgnoreCase('Success')) {
				Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
			}
			
			createLog(postResponse);
    	} catch(Exception e) {
    		insertLog(postResponse.ServerName, null, 'SendEmailRestService', 'Error', postResponse.toString(), 
                      'Something went wrong while sending email- ' + e.getMessage());
    	}
        return 'Success';
    }
    
    private static void createLog(PostResponseWrapper postResponse) {
    	if(postResponse != null && String.isNotBlank(postResponse.ServerName) && postResponse.ServerName.equalsIgnoreCase('BRP')) {
    		return;
    	}
    	if(postResponse != null && String.isBlank(postResponse.ErrorMsg)) {
			if(String.isNotBlank(postResponse.ServerName) && (postResponse.ServerName.equalsIgnoreCase('FTP') || postResponse.ServerName.equalsIgnoreCase('SOM'))) {
	        	if(String.isNotBlank(postResponse.StatusCode) && (postResponse.StatusCode == '200' || postResponse.StatusCode == '201' || 
	        				postResponse.StatusCode.equalsIgnoreCase('Success'))) {
	        		insertLog(postResponse.ServerName, 'Success', 'SendEmailRestService', 'INFO', postResponse.toString(), 
	                          'File posted successfully');
	        	} else {
	        		insertLog(postResponse.ServerName, postResponse.StatusCode, 'SendEmailRestService', 'Error', postResponse.toString(), 
	                          'Something went wrong in file posting at ' + postResponse.ServerName);
	        	}
	        }
        } else {
            insertLog(postResponse.ServerName, null, 'SendEmailRestService', 'Error', postResponse.toString(), 
                      'Some error occured at Java program');
        }
    }
    
    private static void insertLog(String integrationType, String errorCode, String apexLass,
                                 String type, String methodParam, String logInfo) {
        insert new Log__c(Integration_Type__c = integrationType, Error_Code__c = errorCode,
						Apex_Class__c = apexLass, Type__c = type, 
						Method_Params__c = methodParam, Log_Info__c = logInfo);
    }
    
    global class PostResponseWrapper {
        public String StatusCode;
        public String ServerName;
        public String FileName;
        public String ErrorMsg;
       	public GenericExportService.FTPWrapper FtpDetail; 
       
	}
}