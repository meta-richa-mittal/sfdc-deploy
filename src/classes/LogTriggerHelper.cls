/**
 * Author: Rajat Jain
 * Since: May 22, 2018
 * Name: LogTriggerHelper 
 * Description: Helper Class to execute operation on log 
**/
public without sharing class LogTriggerHelper {
	
	public static void afterInsert(List<Log__c> newList) {
		Boolean isErrorLogExist = false;
		for(Log__c logRec : newList) {
			if(logRec.Type__c == 'Error') {
				isErrorLogExist = true;
				break;
			}
		}
		
		if(isErrorLogExist) {
			notifySupportTeamForFTPAndSOMError(newList);
		}
	}
	
	private static void notifySupportTeamForFTPAndSOMError(List<Log__c> newList) {
		for(Log__c logRec : newList) {
			if(logRec.Type__c == 'Error' && (FTPLogIntegrationType.contains(logRec.Integration_Type__c) || (SOMLogIntegrationType.contains(logRec.Integration_Type__c) && logRec.Error_Code__c != '503'))) {
				// send email
				notifySupportTeam(logRec);
				break;
			}
		}
	}

	private static void notifySupportTeam(Log__c logRecord) {
		String subject = UserInfo.getOrganizationName();
		if(FTPLogIntegrationType.contains(logRecord.Integration_Type__c)) {
			subject += logRecord.Integration_Type__c == LogService.INTEXT ? ' - URGENT' : '';
			subject += ' -  Encountered a problem while posting file to FTP';
		} else if(SOMLogIntegrationType.contains(logRecord.Integration_Type__c)) {
			subject += ' -  Encountered a problem while posting file to SOM';
		}
		String htmlBody = getEmailTemplateBody(logRecord) ;
		String defaultEmail = GeneralConfiguration.getSupportEmailRecipient();
		List<String> emailStrList = new List<String>();
		if(String.isNotBlank(defaultEmail)) {
			emailStrList = defaultEmail.split(';');
		} else {
			String supportMail = GeneralConfiguration.getSupportEmail();
			emailStrList = new List<String>{supportMail};
		}
		if(!Test.isRunningTest()){
			SendEmail.sendSupportMail(emailStrList, subject, htmlBody);
		}
		
	}
	
	public static String getEmailTemplateBody(Log__c logRecord) {
		String htmlBody = '';
		string Url = System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+logRecord.Id;
		String SOMFileName = logRecord.Method_Params__c;
		String SOMFileType = '';
		Map<String,String> SOMFileNameToFileTypeMap = new Map<String,String>{'INV_' => 'Part Inventory','POO_' => 'Parts On Order', 'PSI_' => 'Part Sales Transaction'};
		htmlBody += '<span> Hi Support Team, </span>';
		if(logRecord.Apex_Class__c == 'AccountingIntegrationSettingsCtrl'){
			htmlBody += '<p><span>An error occured while connecting to QuickBooks Online. </span>';
		} else if(FTPLogIntegrationType.contains(logRecord.Integration_Type__c)) {
			htmlBody += '<p><span>An error occured while posting file to FTP. </span>';
		} else if(SOMLogIntegrationType.contains(logRecord.Integration_Type__c)) {
			if(logRecord.Method__c == 'handleFinish()') {
				SOMFileName = SOMFileName != null ? SOMFileName.Replace('fileType ','') : '';
				SOMFileType = SOMFileName;
			} else {
				SOMFileName = SOMFileName != null ? SOMFileName.Replace('File name ','') : '';
				if(SOMFileName.length() >= 4) {
					SOMFileType = SOMFileNameToFileTypeMap.get(SOMFileName.substring(0,4)) != null ? SOMFileNameToFileTypeMap.get(SOMFileName.substring(0,4)) : '';
				}
			}
			htmlBody += '<p><span>An error occured while posting '+ SOMFileType +' file to SOM. </span>';
		}
		htmlBody += '<span>Please check logs for more detail </span> </p>';
		htmlBody += '<p style="font-weight: bold;"> Information :</p>';
    	htmlBody += '<table style="width:400px ;border-collapse: collapse;" >';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">Company Name </td>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">' + UserInfo.getOrganizationName() + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">Org Id </td>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">' + UserInfo.getOrganizationId() + '</td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr >';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">Log Number </td>';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;"> <a href=" '+ Url + '">' + logRecord.Name +'</a> </td>';
		htmlBody +=	  '</tr>';
		htmlBody +=	  '<tr style="border : 1px solid ">';
		htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">Entity </td>';
		if(FTPLogIntegrationType.contains(logRecord.Integration_Type__c)) {
			htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">' + LogService.FTP + '</td>';
		} else if(SOMLogIntegrationType.contains(logRecord.Integration_Type__c)) {
			htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">' + SOMFileName + '</td>';
		}
		htmlBody +=	  '</tr>';
		htmlBody +=	 '</table>';
    	htmlBody += '<p style="margin-top: 20px;margin-bottom:5px;">From</p>';
    	htmlBody += '<p style="margin:0px;">Blackpurl Admin</p>';
		return htmlBody;
	}
	
	private static Set<String> FTPLogIntegrationType = new Set<String>{LogService.FTP, LogService.INTEXT, LogService.GENERIC_EXPORT, LogService.STOCK_UNIT_EXPORT};
	private static Set<String> SOMLogIntegrationType = new Set<String>{LogService.SOM};
}