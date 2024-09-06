/** 
* Author: Manoj Sharma
* Since: July 29, 2021
* Name: IntegrationIntegrityCheckService 
* Description: Commonn Scheduler controller for Scheduling nightly support notification for async records.
**/
public without sharing class IntegrationIntegrityCheckService {

    public static void checkIFWForIntegrityMail() {
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Send_Failure_Notification__c' => true,
                                                                                                                            'Accounting_Enabled__c' => true});
        if(integrationConfigList.size() > 0) {
            sendIntegrityMailToSupportTeam(integrationConfigList); 
        }
    }

    private static void sendIntegrityMailToSupportTeam(List<IFW_IntegrationConfig__c> integrationConfigList) {
        Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap;
        Messaging.EmailFileAttachment emailAttachment;
        for(IFW_IntegrationConfig__c ifwConfigRec : integrationConfigList) {
            entityNameToAsyncRecordListMap = new Map<String, List<EntityInfoWrapper>>();
            if(integrationNameToObjectNameToQueryMap.containsKey(ifwConfigRec.Integration_Name__c)) {
                for(String entityName : integrationNameToObjectNameToQueryMap.get(ifwConfigRec.Integration_Name__c).keySet()) {
                    setEntityNameToAsyncRecordListMap(entityName, Database.query((integrationNameToObjectNameToQueryMap.get(ifwConfigRec.Integration_Name__c)).get(entityName)), entityNameToAsyncRecordListMap);
                }
                emailAttachment = ifwConfigRec.Integration_Name__c != 'Shopify' ? getAttachment(getDataForCSVFile(entityNameToAsyncRecordListMap)) : null;
                sendNotification(ifwConfigRec.Integration_Name__c, getEmailTemplateBody(entityNameToAsyncRecordListMap, ifwConfigRec.Integration_Name__c), emailAttachment, entityNameToAsyncRecordListMap);
            }
        }
    }
    
   	private static void setEntityNameToAsyncRecordListMap(String entity, List<SObject> sObjectRecList, Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
    	List<EntityInfoWrapper> notSyncEntityNameList = new List<EntityInfoWrapper>();
    	for(SObject sObjRec : sObjectRecList) {
    		notSyncEntityNameList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),entity));
    	}
    	entityNameToAsyncRecordListMap.put(entity, notSyncEntityNameList);
   	}

    private static void sendNotification(String activeIntegrationName, String htmlBody, Messaging.EmailFileAttachment emailAttachment, Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
        if(needToNotify(entityNameToAsyncRecordListMap)) {
            sendNotificationToAdmin(activeIntegrationName, htmlBody, emailAttachment, entityNameToAsyncRecordListMap);
        }
    }

    private static Boolean needToNotify(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
        for(String entityName : entityNameToAsyncRecordListMap.keySet()) {
            if(entityNameToAsyncRecordListMap.get(entityName).size() > 0) {
                return true;
            }
        }
        return false;
    }

    private static void sendNotificationToAdmin(String activeIntegrationName, String htmlBody, Messaging.EmailFileAttachment emailAttachment, Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
        String subject = UserInfo.getOrganizationName() +' - ' + activeIntegrationName + ' Integrity script result';
        String defaultEmail = GeneralConfiguration.getSupportEmailRecipient();
        
        List<String> emailStrList = new List<String>();
        if(String.isNotBlank(defaultEmail)) {
            emailStrList = defaultEmail.split(';');
        } else {
            emailStrList.add(GeneralConfiguration.getSupportEmail());
        }
     
        sendMail(emailStrList, subject, htmlBody, emailAttachment);
    }

    private static void sendMail(List<String> emailStrList, String subject, String htmlBody, Messaging.EmailFileAttachment emailAttachment) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(emailStrList);
        if(String.isNotBlank(Configurations__c.getOrgDefaults().Sent_From_Email_Id__c)){
            mail.setReplyTo(Configurations__c.getOrgDefaults().Sent_From_Email_Id__c);
        }
        mail.setSenderDisplayName('BlackPurl Team');
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        if(emailAttachment != null) {
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {emailAttachment});
        }
        mails.add(mail);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(mails);
        }
    }

    private static Messaging.EmailFileAttachment getAttachment(String dataForCSVFile) {
        if(String.isNotBlank(dataForCSVFile)) {
            Blob pageContent = Blob.valueOf(dataForCSVFile);
            Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
            emailAttachment.setFileName('attachment.csv');
            emailAttachment.setBody(pageContent);
            return emailAttachment;
        }
        return null;
    }

    private static String getEmailTemplateBody(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap, String activeIntegrationName){
        String htmlBody = '';
        htmlBody += '<span> Hi Support Team, </span>';
        htmlBody += '<p>Following records are not synced with ' + activeIntegrationName + '. Org Details are as follows - </p>';
        htmlBody += '<table >';
        htmlBody +=	  '<tr >';
        htmlBody +=	    '<td >Company Name - </td>';
        htmlBody +=	    '<td >' + UserInfo.getOrganizationName() + '</td>';
        htmlBody +=	  '</tr>';
        htmlBody +=	  '<tr >';
        htmlBody +=	    '<td>Org Id - </td>';
        htmlBody +=	    '<td>' + UserInfo.getOrganizationId() + '</td>';
        htmlBody +=	  '</tr>';
        htmlBody +=	 '</table>';
        htmlBody += '<p style="font-weight: bold;"> Information :</p>';
        htmlBody += '<table style="width:400px ;border-collapse: collapse;" >';
        htmlBody += '<tr>';
        htmlBody +=	    '<td style="border : 1px solid;font-weight: bold;"> Entity name </td>';
        htmlBody +=	    '<td style="border : 1px solid;font-weight: bold;">Number of async records ';
        htmlBody += '</tr>';	
        List<String> entityList = new List<String>(entityNameToAsyncRecordListMap.keySet()); 
        entityList.sort();
        for(String entity : entityList) {
            if(entityNameToAsyncRecordListMap.get(entity).size() > 0) {
                htmlBody +=      '<tr >';
                htmlBody +=     '<td style="border : 1px solid;">'+ entity + '</td>';
                htmlBody +=     '<td style="border : 1px solid; ">';
                htmlBody +=     (entityNameToAsyncRecordListMap.get(entity)).size() ;
                htmlBody +=     '</td>';
                htmlBody +=   '</tr>';
            }
        }
        htmlBody +=	 '</table>';
        htmlBody += '<p style="margin-top: 20px;margin-bottom:5px;">From</p>';
        htmlBody += '<p style="margin:0px;">Blackpurl Admin</p>';
        return htmlBody;
    }

    private static String getDataForCSVFile(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
        List<String> entityList = new List<String>(entityNameToAsyncRecordListMap.keySet()); 
        entityList.sort();
        String Url = System.URL.getSalesforceBaseUrl().toExternalForm()+'/' ;
        String header = 'Entity type,Entity Name,Entity record URL \n';
        String dataForCSVFile = header;
        for(String entity : entityList) {
            string recordString =  '';
            for(EntityInfoWrapper entityObj : entityNameToAsyncRecordListMap.get(entity)) {
                recordString += entityObj.EntityType + ',' + entityObj.Name + ', ' + Url + entityObj.EntityId + '\n' ;
            }
            dataForCSVFile = dataForCSVFile + recordString;
        }
        return dataForCSVFile;
    }

    public class EntityInfoWrapper {
		public String EntityId;
		public String Name;
		public String EntityType;
		
		public EntityInfoWrapper(String entityId, String name, String entityType ) {
			this.EntityId = entityId;
			this.Name = name;
			this.EntityType = entityType;
		}
    }

    public static Map<String, Map<String,String>> integrationNameToObjectNameToQueryMap = 
                                                    new Map<String, Map<String,String>>{ 'Shopify'    =>  
                                                    new Map<String,String> {'Website Product' => 'SELECT Name FROM Website_Product__c WHERE Status__c = \'Error\' OR Delete_Pending__c = True ORDER By Name '}};
    
}