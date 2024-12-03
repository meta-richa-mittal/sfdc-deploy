/** 
* Author: Reena Singh
* Since: July 09, 2020 
* Name: IntegrityCheckForBRPCtrl 
* Description: Apex class to check integration on BRP.
**/
public without sharing class IntegrityCheckForBRPCtrl {
	
    private List<String> listOfEntities = new List<String>();  
    private Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap = new Map<String, List<EntityInfoWrapper>>();
     
	public void sendIntegrityCheckMailToSupportTeam() {
		populateEntityNameToAsyncRecordListMap();
		checkBeforeNotification(entityNameToAsyncRecordListMap);
    }
    
    private void populateEntityNameToAsyncRecordListMap() {
        String query;    
        for(String entity : objectAPINameToObjectLabelMap.keySet()) {
            if(entity == 'CO_Invoice_Header__c') {
                query = 'SELECT Name, Available_For_BRP_Parts_Invoice_Sync__c, Available_For_BRP_RDR_Sync__c, Available_For_BRP_Repair_Order_Sync__c, Available_For_Retail_Transactions_Sync__c from ' + entity + ' where Available_For_BRP_Parts_Invoice_Sync__c = true OR Available_For_BRP_RDR_Sync__c = true OR Available_For_BRP_Repair_Order_Sync__c = true OR Available_For_Retail_Transactions_Sync__c = true ORDER By Name';
            }
            List<SObject> sObjectRecList = Database.query(query);
            setEntityNameToAsyncRecordListMap(entity, sObjectRecList);
        }
    }

    public void setEntityNameToAsyncRecordListMap(String entity, List<SObject> sObjectRecList) {
        if(entity == 'CO_Invoice_Header__c') {
            List<EntityInfoWrapper> notSyncBRPPartsInvoiceList = new List<EntityInfoWrapper>();
            List<EntityInfoWrapper> notSyncBRPRDRList = new List<EntityInfoWrapper>();
            List<EntityInfoWrapper> notSyncBRPRepairOrderList = new List<EntityInfoWrapper>();
            List<EntityInfoWrapper> notSyncBRPRetailTransactionList = new List<EntityInfoWrapper>();
            for(SObject sObjRec : sObjectRecList) {
                if(Boolean.valueOf(sobjRec.get('Available_For_BRP_Parts_Invoice_Sync__c'))){
                    notSyncBRPPartsInvoiceList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'BRP Parts Invoice'));
                } 
                if(Boolean.valueOf(sobjRec.get('Available_For_BRP_Repair_Order_Sync__c')) ){
                    notSyncBRPRepairOrderList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'BRP Repair Order'));
                }
                if(Boolean.valueOf(sobjRec.get('Available_For_BRP_RDR_Sync__c')) ){
                    notSyncBRPRDRList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'BRP Retail Delivery Reporting'));
                }
                if(Boolean.valueOf(sobjRec.get('Available_For_Retail_Transactions_Sync__c')) ){
                    notSyncBRPRetailTransactionList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'BRP Retail Transactions'));
                }
            }
		    entityNameToAsyncRecordListMap.put('BRP Parts Invoice', notSyncBRPPartsInvoiceList);
			listOfEntities.add('BRP Parts Invoice');
			entityNameToAsyncRecordListMap.put('BRP Repair Order', notSyncBRPRepairOrderList);
			listOfEntities.add('BRP Repair Order');
			entityNameToAsyncRecordListMap.put('BRP Retail Delivery Reporting', notSyncBRPRDRList);
			listOfEntities.add('BRP Retail Delivery Reporting');
            entityNameToAsyncRecordListMap.put('BRP Retail Transactions', notSyncBRPRetailTransactionList);
			listOfEntities.add('BRP Retail Transactions');
        } 
    }

    private void checkBeforeNotification(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
        Boolean needToNotifySupportTeam = false;
        for(String entityName : entityNameToAsyncRecordListMap.keySet()) {
            if(entityNameToAsyncRecordListMap.get(entityName).size() > 0) {
                needToNotifySupportTeam = true;
                break;
            }
        }
        if(needToNotifySupportTeam) {
            notifyTheSupportAdmin(entityNameToAsyncRecordListMap);
        }
    }

    private void notifyTheSupportAdmin(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
        String subject = UserInfo.getOrganizationName() +' - BRP Integrity script result';
        String htmlBody = getEmailTemplateBody(entityNameToAsyncRecordListMap) ;
        String defaultEmail = GeneralConfiguration.getSupportEmailRecipient();
        List<String> emailStrList = new List<String>();
        if(String.isNotBlank(defaultEmail)) {
            emailStrList = defaultEmail.split(';');
        } else {
            emailStrList.add(GeneralConfiguration.getSupportEmail());
        }
        
        SendEmail.sendSupportMailWithAttachment(emailStrList, subject, htmlBody, getAttachment());
    }

    private Messaging.EmailFileAttachment getAttachment() {
        Blob pageContent = Blob.valueOf(getDataForCSVFile());
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName('attachment.csv');
        emailAttachment.setBody(pageContent);
        return emailAttachment;
    }
    
    private String getDataForCSVFile() {
        listOfEntities.sort();
        String Url = System.URL.getSalesforceBaseUrl().toExternalForm()+'/' ;
        String header = 'Entity type,Entity Name,Entity record URL \n';
        String dataForCSVFile = header;
        for(String entity : listOfEntities) {
            string recordString =  '';
            for(EntityInfoWrapper entityObj : entityNameToAsyncRecordListMap.get(entity)) {
                recordString += entityObj.EntityType + ',' + entityObj.Name + ', ' + Url + entityObj.EntityId + '\n' ;
            }
            dataForCSVFile = dataForCSVFile + recordString;
        }
        return dataForCSVFile;
    }

    public String getEmailTemplateBody(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap){
        listOfEntities.sort();
        String htmlBody = '';
        htmlBody += '<span> Hi Support Team, </span>';
        htmlBody += '<p>Following records are not synced with BRP. Org Details are as follows - </p>';
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
        for(String entity : listOfEntities) {
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

    private Map<String, String> objectAPINameToObjectLabelMap = new Map<String,String>{'CO_Invoice_Header__c' => 'Customer Order Invoice'};

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
}