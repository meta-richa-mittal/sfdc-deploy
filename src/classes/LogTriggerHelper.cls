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
			checkForFirstErrorOfDay(newList);
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
	
	private static void checkForFirstErrorOfDay(List<Log__c> newList) {
		if(AccessControl.ifObjectFieldIsAccessible('Log__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Log__c> logList = [SELECT Id, Name, Apex_Class__c, Integration_Type__c, CreatedDate, Method_Params__c, Method__c FROM Log__c WHERE CreatedDate = TODAY AND Type__c='Error' AND
									Integration_Type__c != null LIMIT : SOQLUtil.getAvailableQueryRowsLimit()];
		Map<String, List<Log__c>> integrationTypeToLogListMap = new Map<String, List<Log__c>>();
		for(Log__c logRec: logList) {
			if(!integrationTypeToLogListMap.containsKey(logRec.Integration_Type__c)) {
				integrationTypeToLogListMap.put(logRec.Integration_Type__c, new List<Log__c>());
			}
			integrationTypeToLogListMap.get(logRec.Integration_Type__c).add(logRec);
		}

		if(integrationTypeToLogListMap.size() > 0) {
			if(isLogsContainQBRelatedRec(newList) && integrationTypeToLogListMap.containsKey(LogService.QUICKBOOKS) && integrationTypeToLogListMap.get(LogService.QUICKBOOKS).size() == 1) {
				notifySupportTeam(integrationTypeToLogListMap.get(LogService.QUICKBOOKS)[0]);
			}
		}
	}
	
	private static Boolean isLogsContainQBRelatedRec(List<Log__c> newList) {
		Boolean isLogsContainQBRelatedRec = false;
		for(Log__c log : newList) {
			if(log.Integration_Type__c == LogService.QUICKBOOKS) {
				isLogsContainQBRelatedRec = true;
				break;
			}
		}
		return isLogsContainQBRelatedRec;
	}

	private static void notifySupportTeam(Log__c logRecord) {
		String classNameInUpperCase = (classNameToEntityNameMap.get(logRecord.Apex_Class__c) != null) ? 
										(classNameToEntityNameMap.get(logRecord.Apex_Class__c)).toUpperCase() : '';
		String subject = UserInfo.getOrganizationName();
		if(logRecord.Integration_Type__c == LogService.QUICKBOOKS) {
			subject += '-  Encountered a problem while syncing ' + classNameInUpperCase + ' to QuickBooks Online';
		} else if(FTPLogIntegrationType.contains(logRecord.Integration_Type__c)) {
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
		} else if(logRecord.Integration_Type__c == LogService.QUICKBOOKS) {
			String classNameInUpperCase = (classNameToEntityNameMap.get(logRecord.Apex_Class__c) != null) ? 
										(classNameToEntityNameMap.get(logRecord.Apex_Class__c)).toUpperCase() : '';
			htmlBody += '<p><span>An error occured while syncing ' + classNameInUpperCase +  ' to QuickBooks Online. </span>';
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
		} else {
			htmlBody +=	    '<td style="border : 1px solid; padding-left: 5px;">' + classNameToEntityNameMap.get(logRecord.Apex_Class__c) + '</td>';
		}
		htmlBody +=	  '</tr>';
		htmlBody +=	 '</table>';
    	htmlBody += '<p style="margin-top: 20px;margin-bottom:5px;">From</p>';
    	htmlBody += '<p style="margin:0px;">Blackpurl Admin</p>';
		return htmlBody;
	}
	
	private static Map<String,String> classNameToEntityNameMap = new Map<String,String> {'CustomerService' => 'Customer',
																	 'VendorService' => 'Vendor',
																	 'ItemCategoryService' => 'Category',
																	 'CustomerInvoiceService' => 'Customer Order Invoice',
																	 'COInvoiceJournalEntryService' => 'Customer Order Invoice',
																	 'FIFOBucketService' => 'Part',
																	 'StoreCreditJournalEntryService' => 'Store Credit', 
																	 'UnitService' => 'Unit', 
																	 'UnitPriceAndCostService' => 'Unit Price Adjustment', 
																	 'CODepositJournalEntryService' => 'Customer Order Deposit', 
																	 'VendorInvoiceService' => 'Vendor Invoice', 
																	 'VendorReturnService' => 'Vendor Return', 
																	 'VORJournalEntryService' => 'Vendor Recieve',
																	 'FIFOBucketActivityLineItemService' => 'Part Adjustment',
																	 'COInvoicePaymentJournalEntryService' => 'Payment',
																	 'COInvoicePaymentService' => 'Payment',
																	 'PartCategoryService'	=>	'Part Category Change',
																	 'UnitCategoryService'	=>	'Stock Unit Category Change',
																	 'QBHoursLoggedService'	=>	'Clocking Entry',
																	 'QBARPaymentService'	=> 'AR Payment',
																	 'QBPaymentOnAccountService'	=> 'AR Payment JE'
	};
	
	private static Set<String> FTPLogIntegrationType = new Set<String>{LogService.FTP, LogService.INTEXT, LogService.GENERIC_EXPORT, LogService.STOCK_UNIT_EXPORT};
	private static Set<String> SOMLogIntegrationType = new Set<String>{LogService.SOM};
}