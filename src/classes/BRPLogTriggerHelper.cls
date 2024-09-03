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
			if((bpLogRec.Response_Code__c != '200' && bpLogRec.Response_Code__c != '201') && bpLogRec.Type__c == 'Error' && bpLogRec.Entity_Name__c != 'Parts Inventory' && 
				!skipFirstFailureNotifyEntitySet.contains(bpLogRec.Entity_Name__c)) {
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
		List<BRP_Log__c> logRecordList = [SELECT Name, CreatedDate,  Entity_Name__c, Apex_Class__c, Response_Code__c, Error_Messages__c FROM BRP_Log__c 
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
		if(isNoActionRequired(logRecord)) {
			subject += ' (No Action Required)';
		}
		String htmlBody = getEmailTemplateBodyForAccountingIntegrationFailure(Url, logRecord, entityNameInUpperCase);
		SendEmail.sendFirstErrorEmail(entityNameInUpperCase, htmlBody, subject);  
	}
	
	private static Boolean isNoActionRequired(BRP_Log__c logRec) {
		Set<String> noActionEntitySet = new Set<String> {'Parts Inventory','DMSInfo','GetPartsMaster'};
		return (internalServerErrorCodeSet.contains(logRec.Response_Code__c) && noActionEntitySet.contains(logRec.Entity_Name__c));
	}
	
	private static String getEmailTemplateBodyForAccountingIntegrationFailure(String Url, BRP_Log__c logRec, String entityNameInUpperCase) {
		String htmlBody = '';
		htmlBody += '<span> Hi Support Team, </span>';
		htmlBody += '<p><span>An error occured while syncing ' + entityNameInUpperCase +  ' to '+ 'BRP' +'. </span>';
		htmlBody += '<span>Please check logs for more detail </span> </p>';
		htmlBody += '<p style="font-weight: bold;"> Information :</p>';
    	htmlBody += '<table style="width:400px ;border-collapse: collapse;" >';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; width:30%;">Company Name </td>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; ">' + UserInfo.getOrganizationName() + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; width:30%;">Org Id </td>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; ">' + UserInfo.getOrganizationId() + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; width:30%;">Log Number </td>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; "> <a href=" '+ Url + '">' + logRec.Name +'</a> </td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; width:30%;">Entity </td>';	
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; ">' + logRec.Entity_Name__c + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; width:30%;">Error </td>';	
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; ">' + (logRec.Error_Messages__c != null ? logRec.Error_Messages__c : '') + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; width:30%;">Response Code</td>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; ">' + logRec.Response_Code__c + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	 '</table>';
    	htmlBody += '<p style="margin-top: 20px;margin-bottom:5px;">From</p>';
    	htmlBody += '<p style="margin:0px;">Blackpurl Admin</p>';
		return htmlBody; 
	}

	private static Set<String> internalServerErrorCodeSet = new Set<String> {'500', '501',  '502', '503', '504', '505'};
	private static Set<String> skipFirstFailureNotifyEntitySet = new Set<String>{'Parts Invoice', 'Repair Order', 'Retail Delivery Reporting'};
}