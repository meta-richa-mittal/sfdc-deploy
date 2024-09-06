/**
 * Author: Rajat Jain
 * Since: May 30, 2018
 * Name: IntegrityCheckForQBCtrl
 * Description: Ctrl class for IntegrityCheckForQBCtrl
**/
public without sharing class IntegrityCheckForQBCtrl {
    
    private List<String> listOfEntities = new List<String>();   
	public void sendIntegrityCheckMailToSupportTeam() {
		populateEntityNameToAsyncRecordListMap();
		checkBeforeNotification(entityNameToAsyncRecordListMap);
	}
	
   	private void populateEntityNameToAsyncRecordListMap() {
   		String query;    
		for(String entity : objectAPINameToObjectLabelMap.keySet()) {
	        if(enitiesWithQBJournalEntryFlagSet.contains(entity)) {
				query = 'SELECT Name from ' + entity + ' where availForQBJournalEntrySync__c = true ORDER By Name';
		    } else if(entity == 'Account'){
		    	query = 'SELECT Name, Is_Customer__c, Is_Vendor__c, availForQBSync__c, Vendor_AvailForQBSync__c, Claims_for_Service_Work__c  from ' + entity + ' where availForQBSync__c = true OR Vendor_AvailForQBSync__c = true ORDER By Name';
	        } else if(entity == 'CO_Invoice_Header__c') {
		    	query = 'SELECT Name, availForQBSync__c, availForQBJournalEntrySync__c, availForQBCOInvoicePayment__c from ' + entity + ' where availForQBSync__c = true OR availForQBJournalEntrySync__c = true OR availForQBCOInvoicePayment__c = true ORDER By Name';
	        } else if(entity == 'AR_Payment__c') {
		    	query = 'SELECT Name, Available_For_QB_AR_Payment_Sync__c from Payment_on_Account__c where Available_For_QB_AR_Payment_Sync__c = true ORDER By Name';
	        } else if(entity == 'Payment_on_Account__c') {
		    	query = 'SELECT Name, Available_For_QB_Sync__c from ' + entity + ' where Available_For_QB_Sync__c = true ORDER By Name';
	        } else if(entity == 'Hours_Logged__c') {
		    	query = 'SELECT Name, Available_For_QB_Sync__c from ' + entity + ' where Available_For_QB_Sync__c = true ORDER By Name';
	        } else if(entity == 'Customer_Owned_Unit__c') {
		    	query = 'SELECT Name, availForQBSync__c, Available_For_QB_NITC_JE_Sync__c, Available_For_QB_Consignment_Sync__c, Available_For_QB_Unit_Invoice_JE_Sync__c, Avail_For_QB_Sync_Category__c from ' + entity + 
		    		' where availForQBSync__c = true OR Available_For_QB_NITC_JE_Sync__c = true OR Available_For_QB_Consignment_Sync__c = true' + 
					' OR Available_For_QB_Unit_Invoice_JE_Sync__c = true OR Avail_For_QB_Sync_Category__c = true ORDER By Name';
	        } else if(entity == 'Vendor_Invoicing_Header__c') {
		    	query = 'SELECT Name, availForQBSync__c, Available_For_QB_Variance_JE_Sync__c from ' + entity + ' where availForQBSync__c = true OR Available_For_QB_Variance_JE_Sync__c = true ORDER By Name';
	        } else if(entity == 'Return_CR_Header__c') {
		    	query = 'SELECT Name, Available_For_QB_Sync__c, Available_For_QB_Variance_JE_Sync__c from ' + entity + ' where Available_For_QB_Sync__c = true OR Available_For_QB_Variance_JE_Sync__c = true ORDER By Name';
	        } else if(entity == 'Cash_Reconciliation__c' || entity == 'Count_Session__c') {
		    	query = 'SELECT Name, Available_For_QB_Sync__c from ' + entity + ' where Available_For_QB_Sync__c = true ORDER By Name';
	        } else if(entity == 'Part__c') {
		    	query = 'SELECT Name, Avail_For_QB_Sync_Category__c from ' + entity + ' where Avail_For_QB_Sync_Category__c = true ORDER By Name';
	        } else if(entity == 'Deal_Item__c') {
		    	query = 'SELECT Name, Avail_For_QB_Sync__c, Lien_Payout_Avail_For_QB_Sync__c from ' + entity + ' where Avail_For_QB_Sync__c = true OR Lien_Payout_Avail_For_QB_Sync__c = true ORDER By Name';
	        } else {
				query = 'SELECT Name from ' + entity + ' where availForQBSync__c = true ORDER By Name';
	        }
		    List<SObject> sObjectRecList = Database.query(query);
		    setEntityNameToAsyncRecordListMap(entity, sObjectRecList);
    	}
   	}
   	
   	public void setEntityNameToAsyncRecordListMap(String entity, List<SObject> sObjectRecList) {
   		if(entity == 'Account') {
   			List<EntityInfoWrapper> notSyncCustomerNameList = new List<EntityInfoWrapper>();
   			List<EntityInfoWrapper> notSyncVendorNameList = new List<EntityInfoWrapper>();
    		for(SObject sObjRec : sObjectRecList) {
	    		if(Boolean.valueOf(sobjRec.get('Is_Customer__c')) && Boolean.valueOf(sobjRec.get('availForQBSync__c'))){
	    			notSyncCustomerNameList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Customer'));
	    		} else if(Boolean.valueOf(sobjRec.get('Is_Vendor__c')) && Boolean.valueOf(sobjRec.get('Claims_for_Service_Work__c')) && Boolean.valueOf(sobjRec.get('availForQBSync__c'))){
	    			notSyncCustomerNameList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Customer'));
	    		}
	    		if(Boolean.valueOf(sobjRec.get('Is_Vendor__c')) && Boolean.valueOf(sobjRec.get('Vendor_AvailForQBSync__c'))){
	    			notSyncVendorNameList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Vendor'));
	    		}
    		}
    		entityNameToAsyncRecordListMap.put('Customer', notSyncCustomerNameList);
    		listOfEntities.add('Customer');
    		entityNameToAsyncRecordListMap.put('Vendor', notSyncVendorNameList);
    		listOfEntities.add('Vendor');
	    } else if(entity == 'CO_Invoice_Header__c') {
   			List<EntityInfoWrapper> notSyncCOInvoiceList = new List<EntityInfoWrapper>();
   			List<EntityInfoWrapper> notSyncCOInvoiceJEList = new List<EntityInfoWrapper>();
   			List<EntityInfoWrapper> notSyncCOInvoicePayemntJEList = new List<EntityInfoWrapper>();
    		for(SObject sObjRec : sObjectRecList) {
	    		if(Boolean.valueOf(sobjRec.get('availForQBSync__c'))){
	    			notSyncCOInvoiceList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Customer Order Invoice'));
	    		} 
	    		if(Boolean.valueOf(sobjRec.get('availForQBJournalEntrySync__c')) ){
	    			notSyncCOInvoiceJEList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Customer Order Invoice JE'));
	    		}
	    		if(Boolean.valueOf(sobjRec.get('availForQBCOInvoicePayment__c')) ){
	    			notSyncCOInvoicePayemntJEList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Customer Order Invoice Payment JE'));
	    		}
    		}
    		entityNameToAsyncRecordListMap.put('Customer Order Invoice', notSyncCOInvoiceList);
    		listOfEntities.add('Customer Order Invoice');
    		entityNameToAsyncRecordListMap.put('Customer Order Invoice JE', notSyncCOInvoiceJEList);
    		listOfEntities.add('Customer Order Invoice JE');
    		entityNameToAsyncRecordListMap.put('Customer Order Invoice Payment JE', notSyncCOInvoicePayemntJEList);
    		listOfEntities.add('Customer Order Invoice Payment JE');
	    } else if(entity == 'Customer_Owned_Unit__c') {
   			List<EntityInfoWrapper> notSyncUnitInvoiceList = new List<EntityInfoWrapper>();
   			List<EntityInfoWrapper> notSyncUnitNITCJEList = new List<EntityInfoWrapper>();
   			List<EntityInfoWrapper> notSyncUnitConsignmentList = new List<EntityInfoWrapper>();
			List<EntityInfoWrapper> notSyncUnitInvoiceJEList = new List<EntityInfoWrapper>();
			List<EntityInfoWrapper> notSyncUnitCategoryList = new List<EntityInfoWrapper>();
   			
   			String unitConsignmentLabel = IntegrationUtility.entityNameToEntityMap.get(IntegrationUtility.UNIT_CONSIGNMENT);
			String unitInvoiceJELabel = IntegrationUtility.entityNameToEntityMap.get(IntegrationUtility.UNIT_INVOICE_JE);
			String unitCategoryLabel = IntegrationUtility.entityNameToEntityMap.get(IntegrationUtility.STOCK_UNIT_CATEGORY);
    		for(SObject sObjRec : sObjectRecList) {
	    		if(Boolean.valueOf(sobjRec.get('availForQBSync__c'))){
	    			notSyncUnitInvoiceList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Unit'));
	    		} 
	    		if(Boolean.valueOf(sobjRec.get('Available_For_QB_NITC_JE_Sync__c')) ){
	    			notSyncUnitNITCJEList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Unit NITC JE'));
	    		}
	    		if(Boolean.valueOf(sobjRec.get('Available_For_QB_Consignment_Sync__c')) ){
	    			notSyncUnitConsignmentList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')), 
	    					unitConsignmentLabel));
	    		}
				if(Boolean.valueOf(sobjRec.get('Available_For_QB_Unit_Invoice_JE_Sync__c')) ){
	    			notSyncUnitInvoiceJEList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')), 
							unitInvoiceJELabel));
	    		}
				if(Boolean.valueOf(sobjRec.get('Avail_For_QB_Sync_Category__c')) ){
	    			notSyncUnitCategoryList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')), 
							unitCategoryLabel));
	    		}
    		}
    		entityNameToAsyncRecordListMap.put('Unit', notSyncUnitInvoiceList);
    		listOfEntities.add('Unit');
    		entityNameToAsyncRecordListMap.put('Unit NITC JE', notSyncUnitNITCJEList);
    		listOfEntities.add('Unit NITC JE');
    		entityNameToAsyncRecordListMap.put(unitConsignmentLabel, notSyncUnitConsignmentList);
    		listOfEntities.add(unitConsignmentLabel);
			entityNameToAsyncRecordListMap.put(unitInvoiceJELabel, notSyncUnitInvoiceJEList);
    		listOfEntities.add(unitInvoiceJELabel);
			entityNameToAsyncRecordListMap.put(unitCategoryLabel, notSyncUnitCategoryList);
    		listOfEntities.add(unitCategoryLabel);
	    } else if(entity == 'Vendor_Invoicing_Header__c') {
			List<EntityInfoWrapper> notSyncVIBillList = new List<EntityInfoWrapper>();
			List<EntityInfoWrapper> notSyncVIVarianceJEList = new List<EntityInfoWrapper>();
			for(SObject sObjRec : sObjectRecList) {
				if(Boolean.valueOf(sobjRec.get('availForQBSync__c'))){
					notSyncVIBillList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Vendor Invoice'));
				} 
				if(Boolean.valueOf(sobjRec.get('Available_For_QB_Variance_JE_Sync__c')) ){
					notSyncVIVarianceJEList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),'Vendor Invoice Variance JE'));
				}
			}
			entityNameToAsyncRecordListMap.put('Vendor Invoice', notSyncVIBillList);
			listOfEntities.add('Vendor Invoice');
			entityNameToAsyncRecordListMap.put('Vendor Invoice Variance JE', notSyncVIVarianceJEList);
			listOfEntities.add('Vendor Invoice Variance JE');
		} else if(entity == 'Return_CR_Header__c') {
			List<EntityInfoWrapper> notSyncRCRList = new List<EntityInfoWrapper>();
			List<EntityInfoWrapper> notSyncRCRVarianceJEList = new List<EntityInfoWrapper>();
			for(SObject sObjRec : sObjectRecList) {
				if(Boolean.valueOf(sobjRec.get('Available_For_QB_Sync__c'))){
					notSyncRCRList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')), String.valueOf(sobjRec.get('Name')), 'Vendor Credit'));
				}
				if(Boolean.valueOf(sobjRec.get('Available_For_QB_Variance_JE_Sync__c')) ){
					notSyncRCRVarianceJEList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')), String.valueOf(sobjRec.get('Name')), 'Vendor Credit Variance JE'));
				}
			}
			entityNameToAsyncRecordListMap.put('Vendor Credit', notSyncRCRList);
			listOfEntities.add('Vendor Credit');
			entityNameToAsyncRecordListMap.put('Vendor Credit Variance JE', notSyncRCRVarianceJEList);
			listOfEntities.add('Vendor Credit Variance JE');
	 	} else if(entity == 'Deal_Item__c') {
			List<EntityInfoWrapper> notSyncStockedTradeInList = new List<EntityInfoWrapper>();
			List<EntityInfoWrapper> notSyncLienPayoutList = new List<EntityInfoWrapper>();

			String stockedTradeInLabel = IntegrationUtility.entityNameToEntityMap.get(IntegrationUtility.STOCK_TRADE_IN);
			String lienPayoutLabel = IntegrationUtility.entityNameToEntityMap.get(IntegrationUtility.LIEN_PAYOUT);
			for(SObject sObjRec : sObjectRecList) {
				if(Boolean.valueOf(sobjRec.get('Avail_For_QB_Sync__c'))){
					notSyncStockedTradeInList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')), String.valueOf(sobjRec.get('Name')), stockedTradeInLabel));
				}
				if(Boolean.valueOf(sobjRec.get('Lien_Payout_Avail_For_QB_Sync__c')) ){
					notSyncLienPayoutList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')), String.valueOf(sobjRec.get('Name')), lienPayoutLabel));
				}
			}
			entityNameToAsyncRecordListMap.put(stockedTradeInLabel, notSyncStockedTradeInList);
			listOfEntities.add(stockedTradeInLabel);
			entityNameToAsyncRecordListMap.put(lienPayoutLabel, notSyncLienPayoutList);
			listOfEntities.add(lienPayoutLabel);
	 	} else {
	    	List<EntityInfoWrapper> notSyncEntityNameList = new List<EntityInfoWrapper>();
	    	for(SObject sObjRec : sObjectRecList) {
	    		notSyncEntityNameList.add(new EntityInfoWrapper(String.valueOf(sobjRec.get('Id')),String.valueOf(sobjRec.get('Name')),objectAPINameToObjectLabelMap.get(entity)));
	    	}
	    	entityNameToAsyncRecordListMap.put(objectAPINameToObjectLabelMap.get(entity), notSyncEntityNameList);
	    	listOfEntities.add(objectAPINameToObjectLabelMap.get(entity));
	    }
   	}
   	
   	private void checkBeforeNotification(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
   	    Boolean needToNofifySupportTeam = false;
   	    for(String entityName : entityNameToAsyncRecordListMap.keySet()) {
   	        if(entityNameToAsyncRecordListMap.get(entityName).size() > 0) {
   	            needToNofifySupportTeam = true;
   	            break;
   	        }
   	    }
   	    if(needToNofifySupportTeam) {
   	        notifyTheSupportAdmin(entityNameToAsyncRecordListMap);
   	    }
   	}
   	
   	private void notifyTheSupportAdmin(Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap) {
   		String subject = UserInfo.getOrganizationName() +' - QuickBooks Online Integrity script result';
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
		htmlBody += '<p>Following records are not synced with QuickBooks Online. Org Details are as follows - </p>';
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
   	
   	private Set<String> enitiesWithQBJournalEntryFlagSet = new Set<String>{'CO_Deposit__c','CO_Invoice_Payment__c','Vendor_Receiving_Header__c'};
	
	private Map<String, List<EntityInfoWrapper>> entityNameToAsyncRecordListMap = new Map<String, List<EntityInfoWrapper>>();
	
	private Map<String, String> objectAPINameToObjectLabelMap = new Map<String,String>{'Account' => 'Customer',
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
												'Return_CR_Header__c'  => 'Vendor Credit',
												'AR_Payment__c' => 'AR Payment',
												'Payment_on_Account__c' => 'AR Payment JE',
												'Hours_Logged__c' => 'Clocking Entry',
												'Count_Session__c' => 'Count Session',
												'Cash_Reconciliation__c' => 'Cash Reconciliation',
												'Part__c' => 'Part Category',
												'Deal_Item__c' => 'Lien Payout'
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