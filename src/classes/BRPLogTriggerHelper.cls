public without sharing class BRPLogTriggerHelper {
    public static void afterInsert(List<BRP_Log__c> newList) {
		notifySupportTeamOnFirstAccountingFailure(newList);
    }

    public static void notifySupportTeamOnFirstAccountingFailure(List<BRP_Log__c> newList){
		if(!isCheckPartInventoryLogAndSendMailSuccess(newList) && isErrorLogExists(newList)) {
			checkForFirstBPErrorOfDay();
		} 
    }
    
    private static Boolean isErrorLogExists(List<BRP_Log__c> newList) {
		Boolean isErrorLogExist = false;
		for(BRP_Log__c bpLogRec : newList) {
			if((bpLogRec.Response_Code__c != '200' && bpLogRec.Response_Code__c != '201') && bpLogRec.Type__c == 'Error' && bpLogRec.Entity_Name__c != 'Parts Inventory') {
				isErrorLogExist = true;
				break;
			}
		}
		return isErrorLogExist;
	}

	private static Boolean isCheckPartInventoryLogAndSendMailSuccess(List<BRP_Log__c> newList) {
		Boolean isErrorLogExist = false;
		for(BRP_Log__c bpLogRec : newList) {
			if((bpLogRec.Response_Code__c != '200' && bpLogRec.Response_Code__c != '201' && bpLogRec.Response_Code__c != '503') && bpLogRec.Type__c == 'Error' && bpLogRec.Entity_Name__c == 'Parts Inventory') {
				notifySupportTeamForAccountingFirstFailure(bpLogRec);
				isErrorLogExist = true;
				break;
			}
		}
		return isErrorLogExist;
	}

    private static void checkForFirstBPErrorOfDay() {
		
		if(AccessControl.ifObjectFieldIsAccessible('BRP_Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<BRP_Log__c> logRecordList = [SELECT Name, CreatedDate,  Entity_Name__c,  Apex_Class__c FROM BRP_Log__c 
							WHERE CreatedDate = TODAY AND Response_Code__c != '200' AND Response_Code__c != '201' AND Type__c = 'Error' LIMIT 2];
		if(logRecordList.size() == 1 && logRecordList[0].Name != null ) {
		    notifySupportTeamForAccountingFirstFailure(logRecordList[0]);
		}
    }
    
    private static void notifySupportTeamForAccountingFirstFailure(BRP_Log__c logRecord) {
		String entityNameInUpperCase = (logRecord.Entity_Name__c != null) ? (logRecord.Entity_Name__c).toUpperCase() : '';
		String Url = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + logRecord.Id;
		String entityType = logRecord.Entity_Name__c;
		
		String subject = UserInfo.getOrganizationName() + ' - Encountered a problem while syncing ' + entityNameInUpperCase + ' to '+ 'BRP';
		String htmlBody = getEmailTemplateBodyForAccountingIntegrationFailure(Url, logRecord.Apex_Class__c, entityNameInUpperCase, logRecord.Name, entityType);
		SendEmail.sendFirstErrorEmail(entityNameInUpperCase, htmlBody, subject);  
	}
	
	private static String getEmailTemplateBodyForAccountingIntegrationFailure(String Url,String apexClassName, String entityNameInUpperCase, String logRecordName, String enityType) {
		String htmlBody = '';
		htmlBody += '<span> Hi Support Team, </span>';
		htmlBody += '<p><span>An error occured while syncing ' + entityNameInUpperCase +  ' to '+ 'BRP' +'. </span>';
		htmlBody += '<span>Please check logs for more detail </span> </p>';
		htmlBody += '<p style="font-weight: bold;"> Information :</p>';
    	htmlBody += '<table style="width:400px ;border-collapse: collapse;" >';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid ">Company Name </td>';
		htmlBody +=	    '<td style="border : 1px solid ">' + UserInfo.getOrganizationName() + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid ">Org Id </td>';
		htmlBody +=	    '<td style="border : 1px solid ">' + UserInfo.getOrganizationId() + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid ">Log Number </td>';
		htmlBody +=	    '<td style="border : 1px solid "> <a href=" '+ Url + '">' + logRecordName +'</a> </td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr style="border : 1px solid ">';
		htmlBody +=	    '<td style="border : 1px solid ">Entity </td>';
		htmlBody +=	    '<td style="border : 1px solid ">' + enityType + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	 '</table>';
    	htmlBody += '<p style="margin-top: 20px;margin-bottom:5px;">From</p>';
    	htmlBody += '<p style="margin:0px;">Blackpurl Admin</p>';
		return htmlBody; 
	}
}