public without sharing class PostInstallLogTriggerHelper {
    
    public static void afterUpdate(List<Post_Install_Log__c> newList) {
        notifySupportTeamForScriptFailure(newList);
    }

    public static void notifySupportTeamForScriptFailure(List<Post_Install_Log__c> newList) {
        String versionNumber = getVersionNumber(newList);
        List<Post_Install_Log__c> postInstallLogList = [SELECT Id, Name, Status__c, Error_Message__c, Script_Name__c, Script_Included_For_Package__c, Script_Run_For_Package__c, Notified_For_Failure__c FROM Post_Install_Log__c WHERE Script_Run_For_Package__c =: versionNumber];
        
        if(isAllScriptExecutedForPackage(postInstallLogList)) {
            notifySupportTeam(postInstallLogList);
        }
    }

    public static Boolean isAllScriptExecutedForPackage(List<Post_Install_Log__c> postInstallLogList) {
        Boolean isAllScriptExecuted = true;
        for(Post_Install_Log__c postInstallLogRec : postInstallLogList) {
            if(postInstallLogRec.Status__c == 'Pending') {
                isAllScriptExecuted = false;
                break;
            }
        }
        return isAllScriptExecuted;
    }

    public static void notifySupportTeam(List<Post_Install_Log__c> postInstallLogList) {
        List<Post_Install_Log__c> erroredPostInstallLogList = new List<Post_Install_Log__c>();
        for(Post_Install_Log__c postInstallLogRec : postInstallLogList) {
            if(postInstallLogRec.Status__c == 'Errored' && !postInstallLogRec.Notified_For_Failure__c) {
                postInstallLogRec.Notified_For_Failure__c = true;
                erroredPostInstallLogList.add(postInstallLogRec);
            }
        }
        if(erroredPostInstallLogList.size() > 0) {
            update erroredPostInstallLogList;
            sendScriptFailureMailToSupport(erroredPostInstallLogList);
        }
    }
    
    public static String getVersionNumber(List<Post_Install_Log__c> newList) {
        String versionNumber = '';
        for(Post_Install_Log__c postInstallLogRec: newList) {
            versionNumber = postInstallLogRec.Script_Run_For_Package__c != null ? postInstallLogRec.Script_Run_For_Package__c : '';
            break;
        }
        return versionNumber;
    }

    public static void sendScriptFailureMailToSupport(List<Post_Install_Log__c> erroredPostInstallLogList) {
		String subject = 'Action Required - Post install script failed during package upgrade ('+ erroredPostInstallLogList[0].Script_Run_For_Package__c +') on '+ UserInfo.getOrganizationName();
        String emailhtmlBody = getEmailTemplateBody(erroredPostInstallLogList);
		List<String> emailStrList = new List<String>{'blackpurl@metacube.com'};

		if(!Test.isRunningTest()){
			SendEmail.sendSupportMail(emailStrList, subject, emailhtmlBody);
		}
    }

    public static String getEmailTemplateBody(List<Post_Install_Log__c> erroredPostInstallLogList) {
        string logUrl;
        String htmlBody = '<span> Hello, </span>';
		Integer serialNumber = 1;

        htmlBody += '<p><span>Some error occured while executing following post install script(s). Please check log for more details.</span> </p>';
		htmlBody += '<table>';
        htmlBody += '<tr>';
        htmlBody += '<td style="font-weight: bold;">Org Id <td/>';
        htmlBody += '<td> - '+ UserInfo.getOrganizationId() +' <td/>';
        htmlBody += '<tr/>';
        htmlBody += '<tr>';
        htmlBody += '<td style="font-weight: bold;">Org Name <td/>';
        htmlBody += '<td> - '+ UserInfo.getOrganizationName() +' <td/>';
        htmlBody += '<tr/>';
        htmlBody += '</table>';
        htmlBody += '<br />';
        htmlBody += '<div style="overflow-x: auto;">';
        htmlBody += '<table style="width:100% ;border-collapse: collapse;">';
        htmlBody += '<col />';
        htmlBody += '<col />';
        htmlBody += '<col />';
        htmlBody += '<col />';
        htmlBody += '<col style="width: 40%;" />';
        htmlBody +=	  '<tr >';
        htmlBody +=	    '<th style="border : 1px solid; padding-left: 5px;"># </th>';
        htmlBody +=	    '<th style="border : 1px solid; padding-left: 5px;">Log # </th>';
        htmlBody +=	    '<th style="border : 1px solid; padding-left: 5px;">Script Name </td>';
        htmlBody +=	    '<th style="border : 1px solid; padding-left: 5px;">Script For </td>';
        htmlBody +=	    '<th style="border : 1px solid; padding-left: 5px;">Error Message </td>';
        htmlBody +=	  '</tr>';

        for(Post_Install_Log__c erroredPostInstallLogRec : erroredPostInstallLogList) {
            logUrl = System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+erroredPostInstallLogRec.Id;
            htmlBody +=	  '<tr >';
            htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; text-align: center; ">' + serialNumber + '</td>';
            htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; text-align: center; "> <a href=" '+ logUrl + '">' + erroredPostInstallLogRec.Name +'</a> </td>';
            htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">' + erroredPostInstallLogRec.Script_Name__c + '</td>';
            htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; text-align: center; ">' + erroredPostInstallLogRec.Script_Included_For_Package__c + '</td>';
            htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px; width : 40%;">' + erroredPostInstallLogRec.Error_Message__c + '</td>';
            htmlBody +=	  '</tr>';
            serialNumber++;
        }

        htmlBody +=	 '</table>';
        htmlBody +=	 '</div>';
        htmlBody += '<p style="margin-top: 20px;margin-bottom:5px;">From</p>';
        htmlBody += '<p style="margin:0px;">Blackpurl Admin</p>';

		return htmlBody;
	}

}