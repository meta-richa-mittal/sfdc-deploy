/** 
* Author: Raghav Khandelwal
* Since: Apr 10, 2021 
* Name: BRPPartsMasterBatch 
* Description: Batch class
**/
global without sharing class BRPPartsMasterBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private String recordSetReferenceId;
	private DateTime importDate;
	public String vendorId;
	public Vendor_Master__c vendorMasterRec;
	public Price_File_Mapping__c pfMappingRec;
	public Map<String, String> pfCategoryNameToIdMap = new Map<String, String>();
	public AutomatedPriceFileImportService.FieldMappingWrapper fieldMappingObj;
	
	public AutomatedPriceFileImportService.ResultWrapper importResults = new AutomatedPriceFileImportService.ResultWrapper(0, 0, 0, new Set<Id>());
	private static String Recordset_Ref_Error = 'Error';
	
    global BRPPartsMasterBatch() {
        this.recordSetReferenceId = '';
    }
    
    global BRPPartsMasterBatch(String recordSetReferenceId) {
        this.recordSetReferenceId = recordSetReferenceId;
    }
    
    global BRPPartsMasterBatch(String recordSetReferenceId, AutomatedPriceFileImportService.ResultWrapper importResults) {
        this.recordSetReferenceId = recordSetReferenceId;
        this.importResults = importResults;
    }
        
    global Iterable<String> start(Database.BatchableContext bc) {
    	setDefaultFields();
    	if(vendorMasterRec == null) {
    		BRPLogService obj = new BRPLogService('GetPartsMaster', null, null, null, null, 'BRP Vendor Or Vendor Master is missing', 'Error', 'BRPPartsMasterBatch', 'start');
    		obj.createLog();
    		this.recordSetReferenceId = Recordset_Ref_Error;
    		return new List<String>();
    	}
        return new List<String>{recordSetReferenceId};
    }
        
	global void execute(SchedulableContext SC) {
		Database.executeBatch(new BRPPartsMasterBatch(), 200);
	}

    global void execute(Database.batchableContext bc, List<String> iterableList) {
    	HttpResponse response = new HttpResponse();
    	try {
	    	String requestBody = BRPPartsMasterService.createRequestBody(recordSetReferenceId);
	    	recordSetReferenceId = '';
	    	response = BRPUtility.syncToBRP('GetPartsMaster', requestBody);
	        
	        if(response.getStatusCode() == 200) {
	        	if(response.getBody().containsIgnoreCase('ShowPartsMaster')) {
        			this.recordSetReferenceId = BRPPartsMasterService.getRecordSetReferenceId(response);
	        		try {
	        			Set<String> multipleKeysSet = new Set<String>{'PartMasterLine', 'SupersedingPartGroup', 'ProductLineCode', 'PartMasterPricing', 'ItemIdentification'};
	            
		            BRPResponseWrapper responseObj = BRPUtility.parseXMLResponse(response.getBody(), multipleKeysSet);
		            if(responseObj != null && responseObj.ShowPartsMaster != null && responseObj.ShowPartsMaster.ShowPartsMasterDataArea != null && 
		            			responseObj.ShowPartsMaster.ShowPartsMasterDataArea.PartMaster != null) {	
		            	BRPPartsMasterService.importParts(responseObj.ShowPartsMaster.ShowPartsMasterDataArea.PartMaster.PartMasterLine, 
		            			this.pfCategoryNameToIdMap, this.pfMappingRec, this.fieldMappingObj, this.importResults);
	            	}
		            System.debug('responseObj...'+ System.JSON.serialize(responseObj));
		            System.debug('response.getBody()...'+response.getBody());
		            
		            BRPLogService obj = new BRPLogService('GetPartsMaster', requestBody, null, null, null, response.getBody(), 'Info', 'BRPPartsMasterBatch', 'execute');
					obj.createLog();
        			} catch(Exception e) {
			    		BRPLogService obj = new BRPLogService('GetPartsMaster', 'recordSetReferenceId - ' + this.recordSetReferenceId, null, null, null, 
			    				e.getMessage() + ' - ' + response.getBody(), 'Error', 'BRPPartsMasterBatch', 'execute');
						obj.createLog();
			    	}
	        	} else if(response.getBody().containsIgnoreCase('ConfirmBOD') && 
		        	response.getBody().containsIgnoreCase('No changes to Parts Master catalog since previous update request')) {
	        		BRPLogService obj = new BRPLogService('GetPartsMaster', requestBody, null, null, String.valueOf(response.getStatusCode()), response.getBody(), 'Info', 'BRPPartsMasterBatch', 'execute');
	        		obj.createLog();
	        	} else {
	        		handleAPIError(Recordset_Ref_Error, requestBody, response);
	        	}
	    	} else {
	    		handleAPIError(Recordset_Ref_Error, requestBody, response);
	    	}
    	} catch(Exception e) {
    		BRPLogService obj = new BRPLogService('GetPartsMaster', 'recordSetReferenceId - ' + this.recordSetReferenceId, null, null, null, e.getMessage() + response.getBody(), 'Error', 'BRPPartsMasterBatch', 'execute');
			obj.createLog();
			this.recordSetReferenceId = Recordset_Ref_Error;
    	}
    }
    
	global void finish(Database.batchableContext bc) {
		if(String.isNotBlank(this.recordSetReferenceId)) {
            if(!this.recordSetReferenceId.containsIgnoreCase(Recordset_Ref_Error)) {
            	Database.executeBatch(new BRPPartsMasterBatch(this.recordSetReferenceId, this.importResults));
            } else {
            	handleFinish(false);
            }
        } else {
        	handleFinish(true);
        }
    }
    
	private void setDefaultFields() {
		importDate = system.now();
    	List<BRP_Vendors_List__c> brpVendors = [Select Id, Name from BRP_Vendors_List__c where Is_Used_For_Parts_Master__c = true LIMIT 1];
    	if(brpVendors.size() > 0) {
    		this.vendorId = brpVendors[0].Name;
    		
    		Map<String, Object> fieldNameToFieldValueMap = new Map<String, Object>{'Blackpurl_Vendor__c' => this.vendorId, 
    								'Vendor_Master_Type__c' => 'BRP Parts Master'};
			List<Vendor_Master__c> vendorMasterList = AutomatedPriceFileSOQLUtil.getVendorMasterList(new List<String>(), fieldNameToFieldValueMap);
    		this.vendorMasterRec = vendorMasterList.size() > 0 ? vendorMasterList[0] : null;
    		
    		if(this.vendorMasterRec != null) {
				this.fieldMappingObj = new AutomatedPriceFileImportService.FieldMappingWrapper();
	            this.fieldMappingObj.IsMfgNumberMapped = this.vendorMasterRec.Mfg_Num__c;
	            this.fieldMappingObj.IsSKUNumberMapped = this.vendorMasterRec.SKU_Num__c;
	            this.fieldMappingObj.IsReplacedByMapped = this.vendorMasterRec.Replaced_By__c;
	            this.fieldMappingObj.IsReplacesMapped = this.vendorMasterRec.Replaces__c;
	            this.fieldMappingObj.IsPackageQtyMapped = this.vendorMasterRec.Pkg_Qty__c;
	            this.fieldMappingObj.VendorId = this.vendorId;
	            
	    		fieldNameToFieldValueMap = new Map<String, Object>{'Vendor_Master__c' => this.vendorMasterRec.Id};
	        	List<Price_File_Mapping__c> priceFileMappingList = AutomatedPriceFileSOQLUtil.getPriceFileMappingList(new List<String>(), fieldNameToFieldValueMap);
	    		if(priceFileMappingList.size() > 0) {
	    			this.pfMappingRec = priceFileMappingList[0];
		            this.fieldMappingObj.PriceFileFieldMappingId = priceFileMappingList[0].Id;
		            this.fieldMappingObj.OverridePartPkgSetting = priceFileMappingList[0].Is_Packaged_Part__c;
		            this.fieldMappingObj.IsForcedCategory = priceFileMappingList[0].Is_Forced_Category__c;
		            
		            createCategoryMap();
	    		}
	    	}
    	}
	}
	
    public void createCategoryMap() {
    	if(this.pfMappingRec != null && String.isNotBlank(this.pfMappingRec.Category__c)) {
    		List<AutomatedPriceFileMappingWrapper.CategoryMappingWrapper> categoryMappingList = String.isBlank(this.pfMappingRec.Category__c) ? 
    						new List<AutomatedPriceFileMappingWrapper.CategoryMappingWrapper>() : 
    						(List<AutomatedPriceFileMappingWrapper.CategoryMappingWrapper>) System.JSON.deserialize(this.pfMappingRec.Category__c, 
    							List<AutomatedPriceFileMappingWrapper.CategoryMappingWrapper>.class);
    		
    		for(AutomatedPriceFileMappingWrapper.CategoryMappingWrapper catObj : categoryMappingList) {
    			this.pfCategoryNameToIdMap.put(catObj.Key, catObj.Value);
    		}
        }
    }
    
    private void handleAPIError(String recordSetRefId, String requestBody, HttpResponse response) {
		this.recordSetReferenceId = recordSetRefId;
		BRP_log__c brpLogRec = BRPUtility.handleResponse('GetPartsMaster', requestBody, response);
        brpLogRec.Apex_Class__c = 'BRPPartsMasterBatch';
        System.debug('brpLogRec..'+brpLogRec);
		DMLUtility.insertSobjectList('BRP_log__c', brpLogRec);
	}
	
    private void handleFinish(Boolean isSuccess) {
    	if(isSuccess != null && isSuccess) {
    		setlastTimeForApiExecutedInBRPSettings(this.importDate);
    	}
    	if(this.vendorMasterRec != null && String.isNotBlank(this.vendorMasterRec.Id)) {
    		insertSummaryLog(this.importResults.NewParts, this.importResults.UpdatedParts, this.importResults.FailedParts, this.vendorMasterRec.Id);
    	}
    	ImportSupersessionPart_Batch batchObj = new ImportSupersessionPart_Batch(new List<String>(), 200);
    }
    
    private void insertSummaryLog(Integer insertedRecordCount, Integer updatedRecordCount, Integer failedRecordCount, String vendorMasterId) {
        Summary_Log__c summaryLog = new Summary_Log__c();
        summaryLog.Type__c = Constants.APF;
        summaryLog.Inserted_Record_Count__c = insertedRecordCount;
        summaryLog.Updated_Record_Count__c = updatedRecordCount;
        summaryLog.Failed_Record_Count__c = failedRecordCount;
        summaryLog.Vendor_Master__c = vendorMasterId;
        if(summaryLog != null) {
			DMLUtility.insertSobjectList('Summary_Log__c', summaryLog);
        }
    }

    private void setlastTimeForApiExecutedInBRPSettings(DateTime importDate) {
        BRP_Settings__c brpSettingRecord = BRP_Settings__c.getOrgDefaults();
        brpSettingRecord.Parts_Master_Successful_Imported_Date__c = importDate != null ? importDate : System.now();
        if(brpSettingRecord != null) {
			DMLUtility.updateSobjectList('BRP_Settings__c', brpSettingRecord);
        }
    }
}