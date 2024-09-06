/**
 * Author: Nikhil Kumar Srivastava
 * Since: May 16, 2019
 * Name: IntegrationFailureNotificationService
 * Description: handle notification to Support 
**/
public without sharing class IntegrationFailureNotificationService {
	
	public static void notifySupportTeamForAccountingFirstFailure(List<WebService_Log__c> logRecordList, String activeAccountingIntegrationName) {
		if(logRecordList.size() == 0) return;
		WebService_Log__c logRecord = logRecordList[0]; // done for Bulkify Apex Methods Using Collections In Methods
		String entityNameInUpperCase = (IntegrationUtility.entityNameToEntityMap.get(logRecord.Entity_Name__c) != null) ? 
										(IntegrationUtility.entityNameToEntityMap.get(logRecord.Entity_Name__c)).toUpperCase() : '';
		String Url = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + logRecord.Id;
		String entityType = IntegrationUtility.entityNameToEntityMap.get(logRecord.Entity_Name__c);
		
		String subject = UserInfo.getOrganizationName() + ' - Encountered a problem while syncing ' + entityNameInUpperCase + ' to '+ activeAccountingIntegrationName;
		String htmlBody = getEmailTemplateBodyForAccountingIntegrationFailure(Url, logRecord.Apex_Class__c, entityNameInUpperCase, logRecord.Name, entityType);
		SendEmail.sendFirstErrorEmail(entityNameInUpperCase, htmlBody, subject);  
	}
	
	public static String getEmailTemplateBodyForAccountingIntegrationFailure(String Url,String apexClassName, String entityNameInUpperCase, String logRecordName, String enityType) {
		String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
		String htmlBody = '';
		htmlBody += '<span> Hi Support Team, </span>';
		if(apexClassName == 'AccountingIntegrationSettingsCtrl'){
			htmlBody += '<p><span>An error occured while connecting to '+ activeIntegrationName +'. </span>';
		} else {
			htmlBody += '<p><span>An error occured while syncing ' + entityNameInUpperCase +  ' to '+ activeIntegrationName +'. </span>';
		}
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