/**
 * Author: Nidhi Sharma
 * Since: August 28, 2019
 * Name: PartCountController
 * Description: 
**/

global without sharing class PartCountController {
    
    global PartCountController (NewHomePageCtrl controller){}
    public PartCountController() {}
    
    @RemoteAction
    global static String getCountSessionListByTabName(String countSessionTabName) {
    	countSessionTabName = BPUtility.getDecodedString(countSessionTabName);
    	try {
    		List<CountSessionWrapper> countSessionObjList = PartCountService.getCountSessionListByTabName(countSessionTabName);
    		return BPUtility.getEncodedString(System.JSON.serialize(countSessionObjList));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String getActiveLocationList() {
        return BPUtility.getEncodedString(System.JSON.serialize(LocationManagementService.getActiveLocationList()));
    }
    
    @RemoteAction
    global static String getVendorList() {
    	List<Vendor> vendorObjList = Vendor_Service.getVendorList();
    	return BPUtility.getEncodedString(System.JSON.serialize(vendorObjList, true));
    }
    
    @RemoteAction
    global static String getPartCategories() {
    	List<CategoryService.CategoryWrapper> categoryList = CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => Constants.CATEGORY_TYPE_PART});
    	return BPUtility.getEncodedString(System.JSON.serialize(categoryList));
    }
    
    @RemoteAction
    global static String getCountSessionDetailById(String countSessionId) {
    	countSessionId = BPUtility.getDecodedString(countSessionId);
    	try {
    		CountSessionWrapper countSessionObj = PartCountService.getCountSessionDetailById(countSessionId);
    		return BPUtility.getEncodedString(System.JSON.serialize(countSessionObj));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
	}
    
    @RemoteAction
    global static String saveCountSession(String countSessionJson) {
    	countSessionJson = BPUtility.getDecodedString(countSessionJson);
    	try {
    		PartCountService.saveCountSession(countSessionJson);
    		return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String getCountSessionLineItemsByCountSessionId(String countSessionId, String pageSortWrapperStr) {
    	countSessionId = BPUtility.getDecodedString(countSessionId);
    	pageSortWrapperStr = BPUtility.getDecodedString(pageSortWrapperStr);
    	try {
    		CountSessionLineItemWrapper countSessionLineItemWrapperObj = PartCountService.getPaginatedCountSessionLIBySessionIdAndTabName(countSessionId, pageSortWrapperStr);
    		return BPUtility.getEncodedString(System.JSON.serialize(countSessionLineItemWrapperObj));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String getSelectedPartInfo(String countSessionId, String partId) {
    	countSessionId = BPUtility.getDecodedString(countSessionId);
    	partId = BPUtility.getDecodedString(partId);
    	try {
    		CountSessionLineItemWrapper.CountSessionLineItem countSessionLIObj = PartCountService.getSelectedPartInfo(countSessionId, partId);
    		return BPUtility.getEncodedString(System.JSON.serialize(countSessionLIObj));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String saveCountSessionLineItem(String countSessionLIJson) {
    	countSessionLIJson = BPUtility.getDecodedString(countSessionLIJson);
    	try {
    		PartCountService.saveCountSessionLineItem(countSessionLIJson);
    		return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String deleteCountSessionLineItem(String countSessionLIId) {
    	countSessionLIId = BPUtility.getDecodedString(countSessionLIId);
    	try {
    		PartCountService.deleteCountSessionLineItem(countSessionLIId);
    		return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String deleteAllIssues(String countSessionRecId) {
    	countSessionRecId = BPUtility.getDecodedString(countSessionRecId);
    	try {
    		PartCountService.deleteAllIssues(countSessionRecId);
    		return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String exportCountSession(String countSessionId, String lineItemTabName) {
    	return BPUtility.getEncodedString('');
    }
    
    @RemoteAction
    global static String finalizeCountSession(String countSessionJson) {
    	countSessionJson = BPUtility.getDecodedString(countSessionJson);
    	try {
    		PartCountService.finalizeCountSession(countSessionJson);
    		return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String getAdjustmentCategories() {
    	List<CategoryService.CategoryWrapper> categoryList = CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => Constants.CATEGORY_TYPE_ADJUSTMENT});
    	return BPUtility.getEncodedString(System.JSON.serialize(categoryList));
    }
    
    @RemoteAction
    global static String getCountSessionSearchResult(String searchObjWrapper) {
    	searchObjWrapper = BPUtility.getDecodedString(searchObjWrapper);
    	try {
	        CountSessionLineItemWrapper countSessionLineItemWrapperObj = 
	        						PartCountService.getCountSessionLineItemSearchResult(searchObjWrapper);
	        return BPUtility.getEncodedString(System.JSON.serialize(countSessionLineItemWrapperObj));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
	
	@RemoteAction
    global static String processCountFileImport(String countSessionId, String partToImportListJson) {
    	countSessionId = BPUtility.getDecodedString(countSessionId);
    	partToImportListJson = BPUtility.getDecodedString(partToImportListJson);
    	try {
	        Map<String, Integer> result = PartCountService.processCountFileImport(countSessionId, partToImportListJson);
	        return BPUtility.getEncodedString(System.JSON.serialize(result));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String deleteCountSession(String countSessionId) {
    	countSessionId = BPUtility.getDecodedString(countSessionId);
    	try {
    		return BPUtility.getEncodedString(PartCountService.deleteCountSession(countSessionId));
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    }
    
    @RemoteAction
    global static String resolveCountIssue(String countSessionLIJson, String resolveCountSessionIssueLIId) {
    	try {
    		saveCountSessionLineItem(countSessionLIJson);
    		deleteCountSessionLineItem(resolveCountSessionIssueLIId);
    		return BPUtility.getEncodedString('Success');
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
	}
	
	@RemoteAction
    global static String checkForCompletedCountSession(String countSessionId) {
    	try {
			countSessionId = BPUtility.getDecodedString(countSessionId);
			if(!PartCountService.isCountSessionCreationCompleted(countSessionId)) {
				return BPUtility.getEncodedString('Please wait while the uncounted parts list is being generated.');
			}
    	} catch(Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
		return BPUtility.getEncodedString('success');
    }

	@RemoteAction
    global static String mergeAllDuplicateCountSessionLineItems(String countSessionRecId) {
		return BPUtility.getEncodedString(PartCountService.mergeAllDuplicateCountSessionLineItems(BPUtility.getDecodedString(countSessionRecId)));
    }
    
	@RemoteAction
    global static String getMergeAllDuplicateCSLIBatchStatus(String batchId) {
		return BPUtility.getEncodedString(PartCountService.getMergeAllDuplicateCSLIBatchStatus(BPUtility.getDecodedString(batchId)));
	}
}