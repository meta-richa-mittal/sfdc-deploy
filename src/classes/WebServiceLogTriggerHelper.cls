/**
 * Author: Nikhil Kumar Srivastava
 * Since: May 07, 2019
 * Name: WebServiceLogTriggerHelper
 * Description: Helper Class to execute operation on WebServiceLog
**/
public without sharing class WebServiceLogTriggerHelper {
	
	public static void afterInsert(List<WebService_Log__c> newList) {
		notifySupportTeamOnFirstAccountingFailure(newList);
	} 
	
	public static void notifySupportTeamOnFirstAccountingFailure(List<WebService_Log__c> newList){
		if(isErrorLogExists(newList)) {
			checkForFirstXeroErrorOfDay();
		} 
	}
	
	private static Boolean isErrorLogExists(List<WebService_Log__c> newList) {
		Boolean isErrorLogExist = false;
		for(WebService_Log__c webLogRec : newList) {
			if((webLogRec.Response_Code__c != '200' && webLogRec.Response_Code__c != '201') && webLogRec.Status__c != 'OK'&& 
			     !webLogRec.Name.startsWithIgnoreCase('xero')) {
				isErrorLogExist = true;
				break;
			}
		}
		return isErrorLogExist;
	}

	private static void checkForFirstXeroErrorOfDay() {
		String activeAccountingIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
		
		if(AccessControl.ifObjectFieldIsAccessible('WebService_Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<WebService_Log__c> logRecordList = [SELECT Name, CreatedDate, Endpoint__c, IFW_IntegrationConfig__c, Status__c, Entity_Name__c, 
							IFW_IntegrationConfig__r.Integration_Name__c, Apex_Class__c FROM WebService_Log__c 
							WHERE CreatedDate = TODAY AND Response_Code__c != '200' AND Status__c != 'OK' LIMIT 2];
		if(logRecordList.size() == 1 && logRecordList[0].IFW_IntegrationConfig__r.Integration_Name__c != null && 
				logRecordList[0].IFW_IntegrationConfig__r.Integration_Name__c.equalsIgnoreCase(activeAccountingIntegrationName)) {
			IntegrationFailureNotificationService.notifySupportTeamForAccountingFirstFailure(logRecordList, activeAccountingIntegrationName);
		}
	}
}