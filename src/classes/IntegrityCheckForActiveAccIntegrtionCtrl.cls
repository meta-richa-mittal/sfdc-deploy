/**
 * Author: Nikhil Kumar Srivastava
 * Since: May 08, 2019
 * Name: IntegrityCheckForActiveAccIntegrtionCtrl
 * Description: Ctrl class for IntegrityCheckForActiveAccIntegrtionCtrl
**/
public without sharing class IntegrityCheckForActiveAccIntegrtionCtrl {
	
	private List<String> entityList = new List<String>();
	private Map<String, String> entityNameToSyncFlagAPINameMap = new Map<String, String>();
	private Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap = new Map<String, List<EntityInfoWrapper>>();
	private String activeAccountingIntegrationName;
	
	public IntegrityCheckForActiveAccIntegrtionCtrl() {
		activeAccountingIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
		populateEntityNameToSyncFlagAPINameMap();
		populateEntityNameToAsyncRecordListMap(); 
	}
	
  public void sendIntegrityCheckMailToSupportTeam() {
	  checkBeforeNotification(entityNameToAsyncRecordListMap);
  }
  
	 private void populateEntityNameToAsyncRecordListMap() {
		 String query;    
	  for(String entityName : entityNameToObjectAPINameMap.keySet()) {
		  if(entityNameToSyncFlagAPINameMap.containsKey(entityName)) {
			  query = 'SELECT Name FROM ' + entityNameToObjectAPINameMap.get(entityName) + ' WHERE ' + entityNameToSyncFlagAPINameMap.get(entityName) +' = TRUE ORDER By Name';
			  setEntityNameToAsyncRecordListMap(entityName, Database.query(query));
		  }
		 }
	 }
	 
	 public void setEntityNameToAsyncRecordListMap(String entity, List<SObject> sObjectRecList) {
	  List<EntityInfoWrapper> notSyncEntityNameList = new List<EntityInfoWrapper>();
	  for(SObject sObjRec : sObjectRecList) {
		  notSyncEntityNameList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),IntegrationUtility.entityNameToEntityMap.get(entity)));
	  }
	  entityNameToAsyncRecordListMap.put(IntegrationUtility.entityNameToEntityMap.get(entity), notSyncEntityNameList);
	  entityList.add(IntegrationUtility.entityNameToEntityMap.get(entity));
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
			 notifySupportAdmin(entityNameToAsyncRecordListMap);
		 }
	 }
	 
	 private void notifySupportAdmin(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
		 String subject = UserInfo.getOrganizationName() +' - ' + activeAccountingIntegrationName + ' Integrity script result';
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
  
	 public String getEmailTemplateBody(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap){
		 entityList.sort();
		 String htmlBody = '';
	  htmlBody += '<span> Hi Support Team, </span>';
	  htmlBody += '<p>Following records are not synced with ' + activeAccountingIntegrationName + '. Org Details are as follows - </p>';
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
	 
  private Map<String, String> objectAPINameToObjectLabelMap = new Map<String,String>{ 'Account' => 'Customer',
																					  'Category__c '=> 'Category',
																					  'CO_Deposit__c' => 'Customer Order Deposit',
																					  'CO_Invoice_Header__c' => 'Customer Order Invoice',
																					  'Part_FIFO_Bucket__c'  => 'Part',
																					  'Part_FIFO_Bucket_Activity_Line_Item__c' => 'Part Adjustment',
																					  'CO_Invoice_Payment__c' => 'Payment',
																					  'Store_Credit__c'  => 'Store Credit',
																					  'Customer_Owned_Unit__c'  => 'Unit',
																					  'Unit_Price_Cost__c' => 'Unit Price Adjustment',
																					  'Vendor_Invoicing_Header__c' => 'Vendor Invoice',
																					  'Vendor_Receiving_Header__c' => 'Vendor Receiving',
																					  'Return_VO_Header__c'  => 'Vendor Return',
																					  'Customer_Owned_Unit__c' => 'Stock Unit Category',
																					  'Customer_Owned_Unit__c' => 'Unit Invoice JE',
																					  'Part__c' => 'Part Category Change',
																					  'Count_Session__c' => 'Count Session',
																					  'Hours_Logged__c' => 'Clocking Entry', 
																					  'Cash_Reconciliation__c' => 'Cash Reconciliation'
  };
											  
  private void populateEntityNameToSyncFlagAPINameMap() {
	  List<Integration_Entity__mdt> integrationEntityList = 
			  [SELECT Entity_Name__c, Label, Sync_Flag_API_Name__c FROM Integration_Entity__mdt where Label =: activeAccountingIntegrationName];	
	  for(Integration_Entity__mdt integrationEntityRec : integrationEntityList) {
		  entityNameToSyncFlagAPINameMap.put(integrationEntityRec.Entity_Name__c, integrationEntityRec.Sync_Flag_API_Name__c);
	  }
  }
  
  private Map<String,String> entityNameToObjectAPINameMap = new Map<String, String> { 'Unit_Price_Cost' => 'Unit_Price_Cost__c',
																					  'Invoice' => 'CO_Invoice_Header__c',
																					  'Part_FIFO' => 'Part_FIFO_Bucket__c',
																					  'CO_Deposit' => 'CO_Deposit__c',
																					  'Part_FIFO_Bucket_Activity_Line_Item' => 'Part_FIFO_Bucket_Activity_Line_Item__c',
																					  'VO_Invoice' => 'Vendor_Invoicing_Header__c',
																					  'VO_Invoice_Varinace_JE' => 'Vendor_Invoicing_Header__c',
																					  'CO_Invoice_JE' => 'CO_Invoice_Header__c',
																					  'Lien_Payout' => 'Deal_Item__c',
																					  'VO_Return' => 'Return_CR_Header__c',
																					  'VO_Return_Variance_JE' => 'Return_CR_Header__c',
																					  'Stock_Trade_In' => 'Deal_Item__c',
																					  'CO_Invoice_Payment' => 'CO_Invoice_Payment__c',
																					  'Unit_Invoice' => 'Customer_Owned_Unit__c',
																					  'Unit_Invoice_JE' => 'Customer_Owned_Unit__c',
																					  'Vendor' => 'Account',
																					  'Stock_Unit_Category' => 'Customer_Owned_Unit__c',
																					  'Store_Credit' => 'Store_Credit__c',
																					  'Item_Category' => 'Category__c',
																					  'Part_Category' => 'Part__c',
																					  'Invoice_Payment' => 'CO_Invoice_Header__c',
																					  'Vendor_Receiving' => 'Vendor_Receiving_Header__c',
																					  'Customer' => 'Account',
																					  'AR_Payment' => 'AR_Payment__c',
																					  'Payment_on_Account' => 'Payment_on_Account__c',
																					  'Count_Session_JE' => 'Count_Session__c',
																					  'Hours_Logged' => 'Hours_Logged__c',
																					  'Unit_NITC_JE' => 'Customer_Owned_Unit__c',
																					  IntegrationUtility.UNIT_CONSIGNMENT => 'Customer_Owned_Unit__c',
																					  IntegrationUtility.CASH_RECONCILIATION => 'Cash_Reconciliation__c'
  };
											  
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