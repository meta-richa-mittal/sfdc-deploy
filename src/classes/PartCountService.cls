/**
 * Author: Nidhi Sharma
 * Since: August 28, 2019
 * Name: PartCountService
 * Description: 
**/
public without sharing class PartCountService {
    private static String fileSeparator = '\t';
    
    public static List<CountSessionWrapper> getCountSessionListByTabName(String countSessionTabName) {
    	String status = 'In Progress\' OR Status__c = \'Posting';
    	String orderByStr = ' ORDER BY Name ';
    	if(countSessionTabName.toUpperCase() == 'COUNT HISTORY') {
    		status = 'Closed';
    		 orderByStr = ' ORDER BY Count_Date_Time__c DESC ';
    	}
    	
    	List<Count_Session__c> countSessionRecList = PartCountSOQLUtil.getCountSessionDetailByFieldFilter(new Map<String, String>{'Status__c' => status}, orderByStr);
    	List<CountSessionWrapper> countSessionObjList = new List<CountSessionWrapper>();
    	for(Count_Session__c countSessionRec : countSessionRecList) {
    		countSessionObjList.add(new CountSessionWrapper(countSessionRec, false));
    	}
    	return countSessionObjList;
    }
    
    public static void saveCountSession(String countSessionJson) {
    	CountSessionWrapper countSessionObj = (CountSessionWrapper) System.JSON.deserialize(countSessionJson, CountSessionWrapper.class);
    	Count_Session__c countSessionRec = setCountSessionFields(countSessionObj);
    	
    	if(AccessControl.ifObjectFieldIsCreateable('Count_Session__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
    	if(AccessControl.ifObjectFieldIsUpdateable('Count_Session__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
    	upsert countSessionRec;
    	
    	if(String.isBlank(countSessionObj.Id) && String.isNotBlank(countSessionObj.Type) && ((countSessionObj.Type).toUpperCase() == 'CYCLE COUNT' || 
    								(countSessionObj.Type).toUpperCase() == 'FULL INVENTORY')) {
			Database.executeBatch(new CreateCountSessionLineItemsBatch(countSessionRec.Id), 25);
    	}
    }
    
    private static Count_Session__c setCountSessionFields(CountSessionWrapper countSessionObj) {
    	Count_Session__c countSessionRec = new Count_Session__c(Id = countSessionObj.Id);
    	countSessionRec.Name__c = countSessionObj.Name;
    	countSessionRec.Status__c = 'In Progress';
		countSessionRec.Type__c = countSessionObj.Type;
		if(countSessionObj.Type == 'Random count') {
			countSessionRec.Is_Creation_Completed__c = true; 
		}
    	if(countSessionObj.CountDate != null) {
    		Date countDate  = HomeSearchFilterInterface.getDateFromString(countSessionObj.CountDate).date();
    		DateTime countDateTime = datetime.newInstance(countDate.year(),countDate.month(),countDate.day(),
    								system.now().hour(), system.now().minute(), system.now().second());
    		countSessionRec.Count_Date_Time__c = countDateTime;
    	} else {
    		countSessionRec.Count_Date_Time__c = system.now();
    	}
    	
    	if(String.isNotBlank(countSessionObj.Type) && (countSessionObj.Type).toUpperCase() == 'CYCLE COUNT') {
    		if(countSessionObj.SelectedLocationNames != null && countSessionObj.SelectedLocationNames.size() > 0) {
                List<String> locationStrListForFields = TagUtil.convertTagListIntoTagString(new List<String>(countSessionObj.SelectedLocationNames));
                if(locationStrListForFields.size() > 0) {
                	countSessionRec.Assigned_Location_1__c = locationStrListForFields[0];
                	if(locationStrListForFields.size() == 2) {
                		countSessionRec.Assigned_Location_2__c = locationStrListForFields[1];
                	}
                }
    		}
    		
    		if(countSessionObj.SelectedVendorIds != null && countSessionObj.SelectedVendorIds.size() > 0) {
    			countSessionRec.Vendors__c = String.join(countSessionObj.SelectedVendorIds, ';');
    		}
    		
    		if(countSessionObj.SelectedCategoryIds != null && countSessionObj.SelectedCategoryIds.size() > 0) {
    			countSessionRec.Categories__c = String.join(countSessionObj.SelectedCategoryIds, ';');
    		}
    	}
    	
    	return countSessionRec;
    }
    
    public static CountSessionWrapper getCountSessionDetailById(String countSessionId) {
    	try{
    		List<Count_Session__c> countSessionRecList = PartCountSOQLUtil.getCountSessionDetailByFieldFilter(new Map<String, String>{'Id' => countSessionId});
    		return new CountSessionWrapper(countSessionRecList[0], true);	
    	} catch(Exception e) {
    		throw new BlackpurlException('No record found');
    	}
    }
    
    public static CountSessionLineItemWrapper getAllCountSessionLIBySessionIdAndTabName(String countSessionId, String tabName, String lastRecUniqueNameValue, Integer queryRecordsLimit) {
    	tabName = (tabName != null) ? tabName : Constants.COUNTED_PARTS;
    	Map<String, String> fieldNameToValueMap = getFilterFieldsMap(countSessionId, tabName);
		List<Count_Session_Line_Item__c> countSessionLineItemRecList = PartCountSOQLUtil.getPartialCountSessionLineItemsByFieldFilter(fieldNameToValueMap, lastRecUniqueNameValue, queryRecordsLimit);
		CountSessionLineItemWrapper countSessionLIWrapper;
		if(countSessionLineItemRecList.size() > 0) {
    		countSessionLIWrapper = new CountSessionLineItemWrapper(countSessionLineItemRecList);
    	} else {
    		List<Count_Session__c> countSessionRecList = PartCountSOQLUtil.getCountSessionDetailByFieldFilter(new Map<String, String>{'Id' => countSessionId});
    		countSessionLIWrapper = new CountSessionLineItemWrapper(countSessionRecList[0], null);
    	}
    	
    	return countSessionLIWrapper;
    }
    
    public static CountSessionLineItemWrapper getPaginatedCountSessionLIBySessionIdAndTabName(String countSessionId, String pageInfoWrapperStr) {
    	PageInfoWrapper pageInfoObj = (PageInfoWrapper) System.JSON.deserialize(pageInfoWrapperStr, PageInfoWrapper.class);
    	pageInfoObj.TabName = (pageInfoObj.TabName != null) ? pageInfoObj.TabName : Constants.COUNTED_PARTS;
    	
    	if(pageInfoObj.PageSize == null || pageInfoObj.PageSize <= 0) {
    		if(GeneralConfiguration.getHomeSearchGridPageSize() != null && GeneralConfiguration.getHomeSearchGridPageSize() > 0) {
    			pageInfoObj.PageSize = Integer.valueOf(GeneralConfiguration.getHomeSearchGridPageSize());
	    	} else {
	    		pageInfoObj.PageSize = 25;
	    	}
    	}
    	
    	Map<String, String> fieldNameToValueMap = getFilterFieldsMap(countSessionId, pageInfoObj.TabName);
    	List<AggregateResult> countSessionLICountResult = PartCountSOQLUtil.getCountSessionLineItemsCountByFieldFilter(fieldNameToValueMap);
        Integer totalCountSessionLI = Integer.valueOf(countSessionLICountResult[0].get('expr0'));
        
    	//Page
    	pageInfoObj.CurrentPage = (pageInfoObj.CurrentPage != null && pageInfoObj.CurrentPage > 0) ? pageInfoObj.CurrentPage : 1;
    	
    	if(pageInfoObj.CurrentPage > 1) {
	    	//when last page has 1 record and that gets deleted
	    	Integer totalPages = (totalCountSessionLI != null && totalCountSessionLI != 0) ? (totalCountSessionLI / pageInfoObj.PageSize) : 0;
	    	if(Math.mod(totalCountSessionLI, pageInfoObj.PageSize) != null && math.mod(totalCountSessionLI, pageInfoObj.PageSize) > 0 ) {
	        	totalPages += 1;
	        }
	    	if(pageInfoObj.CurrentPage > 1 && (pageInfoObj.CurrentPage > totalPages)) {
	    		pageInfoObj.CurrentPage = totalPages;
	    	}
    	}
		List<Count_Session_Line_Item__c> countSessionLineItemRecList = PartCountSOQLUtil.getCountSessionLineItemsByFieldFilter(fieldNameToValueMap, pageInfoObj);
		
		CountSessionLineItemWrapper countSessionLIWrapper;
		if(countSessionLineItemRecList.size() > 0) {
    		countSessionLIWrapper = new CountSessionLineItemWrapper(totalCountSessionLI, pageInfoObj, countSessionLineItemRecList);
    	} else {
    		List<Count_Session__c> countSessionRecList = PartCountSOQLUtil.getCountSessionDetailByFieldFilter(new Map<String, String>{'Id' => countSessionId});
    		countSessionLIWrapper = new CountSessionLineItemWrapper(countSessionRecList[0], pageInfoObj.PageSize);
    	}
    	
    	return countSessionLIWrapper;
    }
    
    public static Map<String, String> getFilterFieldsMap(String countSessionId, String tabName) {
    	Map<String, String> fieldNameToValueMap = new Map<String, String>{'Count_Session__c' => countSessionId};
		if(tabName.equalsIgnoreCase(Constants.COUNTED_PARTS)) {
			fieldNameToValueMap.put('Is_Counted__c', 'true');
		} else if(tabName.equalsIgnoreCase(Constants.UNCOUNTED_PARTS)) {
			fieldNameToValueMap.put('Is_Selected_Part__c', 'true');
			fieldNameToValueMap.put('Is_Counted__c', 'false');
		} else if(tabName.equalsIgnoreCase(Constants.ISSUES_TO_RESOLVE)) {
			fieldNameToValueMap.put('Issue_Indicator__c', '!= null');
		} else if(tabName.equalsIgnoreCase(Constants.ADJUSTMENTS)) {
			fieldNameToValueMap.put('Variance__c', '!= 0');
		}
		
		return fieldNameToValueMap;
    }
    
    public static CountSessionLineItemWrapper.CountSessionLineItem getSelectedPartInfo(String countSessionId, String partId) {
    	//check for part on other active count session	#8122
    	Map<String, Count_Session_Line_Item__c> partIdToCSLIRecOnOtherActiveCSRecMap = 
    				checkForPartOnOtherActiveCountSession(countSessionId, new List<Part__c>{new Part__c(Id = partId)});
    	if(partIdToCSLIRecOnOtherActiveCSRecMap.values().size() > 0) {
    			throw new BlackPurlException('Error: ' + partIdToCSLIRecOnOtherActiveCSRecMap.values()[0].Count_Session__r.Name);
    	}
		Map<String, String> fieldNameToValueMap = new Map<String, String>{'Count_Session__c' => countSessionId, 'Part__c' => partId, 'Issue_Indicator__c' => '= null'};
		List<Count_Session_Line_Item__c> countSessionRecList = PartCountSOQLUtil.getCountSessionLineItemsByFieldFilter(fieldNameToValueMap, null);
		
		CountSessionLineItemWrapper.CountSessionLineItem countSessionLineItemObj;
		if(countSessionRecList.size() > 0) {
			countSessionLineItemObj = new CountSessionLineItemWrapper.CountSessionLineItem(countSessionRecList[0]);
		} else {
			List<Part__c> partRecList = PartCountSOQLUtil.getSelectedPartInfo(partId);
			if(partRecList.size() > 0) {
				countSessionLineItemObj = new CountSessionLineItemWrapper.CountSessionLineItem(partRecList[0]);
			}
		}
		return countSessionLineItemObj;	
    }
    
    public static void saveCountSessionLineItem(String countSessionLIJson) {
		CountSessionLineItemWrapper.CountSessionLineItem countSessionLIObj = 
				(CountSessionLineItemWrapper.CountSessionLineItem) System.JSON.deserialize(countSessionLIJson, CountSessionLineItemWrapper.CountSessionLineItem.class);
		
		Count_Session_Line_Item__c countSessionLIRec = setCountSessionLineItemFields(countSessionLIObj);
		
		DMLUtility.upsertSobjectList('Count_Session_Line_Item__c', countSessionLIRec);
    }
    
    private static Count_Session_Line_Item__c setCountSessionLineItemFields(CountSessionLineItemWrapper.CountSessionLineItem countSessionLIObj) {
    	
    	Count_Session_Line_Item__c countSessionLineItemRec = new Count_Session_Line_Item__c(Id = countSessionLIObj.Id, Count_Session__c = countSessionLIObj.CountSessionId);
    	countSessionLineItemRec.Counted_Qty__c = countSessionLIObj.CountedQty;
    	countSessionLineItemRec.Is_Counted__c = true;
    	
    	if(String.isBlank(countSessionLIObj.Id)) {
    		countSessionLineItemRec.Id = countSessionLIObj.Id;
    		countSessionLineItemRec.Part__c = countSessionLIObj.PartId;
			countSessionLineItemRec.Cost__c = countSessionLIObj.Cost;
			countSessionLineItemRec.Qty_Available__c = countSessionLIObj.QtyAvailable;
    	}
    	
		if(countSessionLIObj.Locations != null) {
			List<String> locationNames = countSessionLIObj.Locations.split(';');
            List<String> locationStrListForFields = TagUtil.convertTagListIntoTagString(locationNames);
            if(locationStrListForFields.size() > 0) {
            	countSessionLineItemRec.Assigned_Location_1__c = locationStrListForFields[0];
            	if(locationStrListForFields.size() == 2) {
            		countSessionLineItemRec.Assigned_Location_2__c = locationStrListForFields[1];
            	}
            }
		}
		
		return countSessionLineItemRec;
    }
    
    public static void deleteCountSessionLineItem(String countSessionLIId) {
		Map<String, String> fieldNameToValueMap = new Map<String, String>{'Id' => countSessionLIId};
		List<Count_Session_Line_Item__c> countSessionLIRecList = PartCountSOQLUtil.getCountSessionLineItemsByFieldFilter(fieldNameToValueMap, null);
		
		if(countSessionLIRecList.size() > 0) {
			if(countSessionLIRecList[0].Is_Selected_Part__c && countSessionLIRecList[0].Is_Counted__c) {
				countSessionLIRecList[0].Is_Counted__c = false;
				countSessionLIRecList[0].Counted_Qty__c = 0;
				if(AccessControl.ifObjectFieldIsUpdateable('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
				update countSessionLIRecList[0];
			} else {
				if(AccessControl.ifObjectIsDeletable('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
				delete countSessionLIRecList[0];
			}
		}
    }
    
    public static void deleteAllIssues(String countSessionRecId) {
		Map<String, String> fieldNameToValueMap = getFilterFieldsMap(countSessionRecId, Constants.ISSUES_TO_RESOLVE);
		List<Count_Session_Line_Item__c> countSessionLIRecList = PartCountSOQLUtil.getCountSessionLineItemsByFieldFilter(fieldNameToValueMap, null);
		
		if(countSessionLIRecList.size() > 0) {
			if(AccessControl.ifObjectIsDeletable('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
			delete countSessionLIRecList;
		}
    }
    
    public static void finalizeCountSession(String countSessionJson) {
    	CountSessionWrapper countSessionObj = (CountSessionWrapper)System.JSON.deserialize(countSessionJson, CountSessionWrapper.class);
    	Count_Session__c countSessionRec = new Count_Session__c(Id = countSessionObj.Id);
    	countSessionRec.Status__c = 'Posting';
    	countSessionRec.Adjustment_Category__c = countSessionObj.AdjustmentCategoryId;
    	countSessionRec.Finalized_Date__c = countSessionRec.Finalized_Date__c != null ? countSessionRec.Finalized_Date__c : System.now();
    	countSessionRec.Is_Adjust_Uncounted_Parts_To_Zero_Qty__c = countSessionObj.IsAdjustUncountedPartsToZeroQty;
    	
    	if(AccessControl.ifObjectFieldIsUpdateable('Count_Session__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
    	update countSessionRec;
    	Database.executeBatch(new FinalizeCountSessionBatch(countSessionRec), 25);
    }
    
    public static CountSessionLineItemWrapper getCountSessionLineItemSearchResult(String searchObjStr) {
    	PageInfoWrapper pageInfoObj = (PageInfoWrapper) System.JSON.deserialize(searchObjStr, PageInfoWrapper.class);
    	pageInfoObj.TabName = (pageInfoObj.TabName != null) ? pageInfoObj.TabName : Constants.COUNTED_PARTS;
    	
    	if(pageInfoObj.PageSize == null || pageInfoObj.PageSize <= 0) {
    		if(GeneralConfiguration.getHomeSearchGridPageSize() != null && GeneralConfiguration.getHomeSearchGridPageSize() > 0) {
    			pageInfoObj.PageSize = Integer.valueOf(GeneralConfiguration.getHomeSearchGridPageSize());
	    	} else {
	    		pageInfoObj.PageSize = 25;
	    	}
    	}
		
		//Filter and Query
    	Map<String, String> fieldNameToValueMap = getFilterFieldsMap(pageInfoObj.CountSessionId, pageInfoObj.TabName);
    	List<GenericSearchUtil.FieldFilter> fieldFilterList = getFilterFieldsFromSearchStr(pageInfoObj.SearchStr);
		List<Count_Session_Line_Item__c> countSessionLineItemRecList = PartCountSOQLUtil.getCountSessionLineItemsBySearchText(fieldNameToValueMap, fieldFilterList);
		
		//Sorting
		List<GenericSearchUtil.SearchedSObjectWrapper> sortedList = sortSearchedResults(pageInfoObj.SearchStr, countSessionLineItemRecList);
		//Pagination
		List<Count_Session_Line_Item__c> paginatedRecordsList = getPaginatedRecords(sortedList, pageInfoObj);
		//Wrapper
		CountSessionLineItemWrapper csliWrapperObj = new CountSessionLineItemWrapper(sortedList.size(), pageInfoObj, paginatedRecordsList);
		
    	return csliWrapperObj;
    }
    
    public static String deleteCountSession(String countSessionId) {
		List<Count_Session__c> countSessionRecList = [SELECT Id, Status__c FROM Count_Session__c WHERE Id =: countSessionId];
		
		if(countSessionRecList.size() > 0) {
			if(countSessionRecList[0].Status__c != 'Posting') {
				delete countSessionRecList;
				return system.JSON.serialize(new ResponseWrapper('Success', 'Deleted successfully'));
			}
			return system.JSON.serialize(new ResponseWrapper('Error', 'Count session is in posting status'));
		}
		return system.JSON.serialize(new ResponseWrapper('Error', 'Count session already deleted'));
    }
    
    private static List<GenericSearchUtil.FieldFilter> getFilterFieldsFromSearchStr(String searchStr) {
    	List<GenericSearchUtil.FieldFilter> fieldFilterList = new List<GenericSearchUtil.FieldFilter>();
    	
		if(String.isNotBlank(searchStr)) {
            List<String> searchTextList = searchStr.split(' ');
            List<String> textFieldsList = new List<String>{'Part_Number__c', 'Description__c'};
            
            for(String searchTextSubStr : searchTextList) {
	            for(String textFieldStr : searchableFieldsList) {
	            	fieldFilterList.add(new GenericSearchUtil.FieldFilter(textFieldStr, 'Like', '\'%' + searchTextSubStr + '%\''));
	            }
            }
		}
		
		return fieldFilterList;
    }
    
    public static Map<String, Integer> processCountFileImport(String countSessionRecId, String partToImportListJson) {
		Boolean isMergeDuplicateParts = false;
		CountSessionLineItemWrapper.CountSessionImportFileWrapper countSessionImportFileWrapperObj = 
    													(CountSessionLineItemWrapper.CountSessionImportFileWrapper) System.JSON.deserialize(partToImportListJson, 
    													CountSessionLineItemWrapper.CountSessionImportFileWrapper.class);
		List<CountSessionLineItemWrapper.CountSessionLineItem> countSessionLIList = countSessionImportFileWrapperObj.CountSessionLineItems;
		isMergeDuplicateParts = countSessionImportFileWrapperObj.MergeDuplicateParts;
    													
    	Map<String, List<CountSessionLineItemWrapper.CountSessionLineItem>> partNumberToCSLIObjListMap = new Map<String, List<CountSessionLineItemWrapper.CountSessionLineItem>>();
		String partNumberLowerCase;
		Integer totalValidParts = 0;
    	for(CountSessionLineItemWrapper.CountSessionLineItem csliObj : countSessionLIList) {
			partNumberLowerCase = (csliObj.PartNumber.trim()).toLowerCase();
			if(String.isNotBlank(partNumberLowerCase)) {
				totalValidParts++;
				if(!partNumberToCSLIObjListMap.containsKey(partNumberLowerCase)) {
					partNumberToCSLIObjListMap.put(partNumberLowerCase, new List<CountSessionLineItemWrapper.CountSessionLineItem>());
				}
				partNumberToCSLIObjListMap.get(partNumberLowerCase).add(csliObj);
			}
    	}
    	
    	Map<String, Part__c> partNumberFoundInDBToPartRecMap = checkIfPartExistsInDB(countSessionRecId, partNumberToCSLIObjListMap.keySet());

		Map<String, Count_Session_Line_Item__c> partIdToCSLIRecOnOtherActiveCSRecMap = 
    										checkForPartOnOtherActiveCountSession(countSessionRecId, partNumberFoundInDBToPartRecMap.values());
    										
    	Map<String, Count_Session_Line_Item__c> partIdToCSLIRecMap = 
    										checkForExistingCountSessionLIRecord(countSessionRecId, partNumberFoundInDBToPartRecMap.values());
    						
    	List<Count_Session_Line_Item__c> csliRecListToUpsert = getCountSessionLIRecListToUpsert(countSessionRecId, partNumberToCSLIObjListMap, 
    											partNumberFoundInDBToPartRecMap, partIdToCSLIRecOnOtherActiveCSRecMap, partIdToCSLIRecMap, isMergeDuplicateParts);
    	
    	if(AccessControl.ifObjectFieldIsCreateable('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
    	if(AccessControl.ifObjectFieldIsUpdateable('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }					
    	upsert csliRecListToUpsert;
    	
		Integer errorCount = 0;
    	for(Count_Session_Line_Item__c csliRec : csliRecListToUpsert) {
    		if(!String.isBlank(csliRec.Issue_Indicator__c)) {
    			errorCount++;
	    	}
    	}
    	Integer successCount = totalValidParts - errorCount;
    	return new Map<String, Integer>{'Success' => successCount, 'Issues' => errorCount};    	
    }
    
    private static Map<String, Part__c> checkIfPartExistsInDB(String countSessionRecId, Set<String> partNumberSet) {
    	List<Part__c> partRecList = PartCountSOQLUtil.getPartByPartNumber(partNumberSet);
    	Map<String, Part__c> partNumberFoundInDBToPartRecMap = new Map<String, Part__c>();
		Set<String> duplicatePartNumberSet = new Set<String>();
    	for(String partNumber :  partNumberSet) {
    		for(Part__c partRec : partRecList) {
    			if(partNumber.equalsIgnoreCase(partRec.Part_Id__c) || partNumber.equalsIgnoreCase(partRec.Part_Number__c)) {
    				if(!partNumberFoundInDBToPartRecMap.containsKey(partNumber)) {
	    				partNumberFoundInDBToPartRecMap.put(partNumber, partRec);
	    			} else {
	    				partNumberFoundInDBToPartRecMap.put(partNumber, null);
	    			}
    			} else if(partNumber.equalsIgnoreCase(partRec.SKU_Number__c)) {
					if(!partNumberFoundInDBToPartRecMap.containsKey(partNumber)) {
	    				partNumberFoundInDBToPartRecMap.put(partNumber, partRec);
	    			} else {
	    				duplicatePartNumberSet.add(partNumber);
	    			}
				}
    		}
    	}
    	partNumberFoundInDBToPartRecMap.remove(null);
		for(String partNumberFoundInDBToPartRec : partNumberFoundInDBToPartRecMap.keySet()) {
			if(duplicatePartNumberSet.contains(partNumberFoundInDBToPartRec)) {
				partNumberFoundInDBToPartRecMap.remove(partNumberFoundInDBToPartRec);
			}
		}
    	return partNumberFoundInDBToPartRecMap;
    }
    
    private static Map<String, Count_Session_Line_Item__c> checkForPartOnOtherActiveCountSession(String countSessionRecId, List<Part__c> partsFoundInDBList) {
    	if(AccessControl.ifObjectFieldIsAccessible('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Count_Session_Line_Item__c> csliRecList = [Select Id, Count_Session__r.Name, Part__c, Is_Counted__c from Count_Session_Line_Item__c 
								where Count_Session__c !=: countSessionRecId AND Part__c IN: partsFoundInDBList AND Count_Session__r.Status__c = 'In Progress'];
    	
    	Map<String, Count_Session_Line_Item__c> partIdToCSLIRecMap = new Map<String, Count_Session_Line_Item__c>();
    	for(Count_Session_Line_Item__c csliRec : csliRecList) {
    		partIdToCSLIRecMap.put(csliRec.Part__c, csliRec);
    	}
    	
    	return partIdToCSLIRecMap;
    }
    
    private static Map<String, Count_Session_Line_Item__c> checkForExistingCountSessionLIRecord(String countSessionRecId, List<Part__c> partsFoundInDBList) {
    	if(AccessControl.ifObjectFieldIsAccessible('Count_Session_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Count_Session_Line_Item__c> csliRecList = [Select Id, Part__c, Is_Counted__c, Counted_Qty__c, Assigned_Location_1__c, Assigned_Location_2__c from Count_Session_Line_Item__c 
    								where Count_Session__c =: countSessionRecId AND Part__c IN: partsFoundInDBList AND Issue_Indicator__c = null];
    	
    	Map<String, Count_Session_Line_Item__c> partIdToCSLIRecMap = new Map<String, Count_Session_Line_Item__c>();
    	for(Count_Session_Line_Item__c csliRec : csliRecList) {
    		partIdToCSLIRecMap.put(csliRec.Part__c, csliRec);
    	}
    	
    	return partIdToCSLIRecMap;
    }
    
    private static List<Count_Session_Line_Item__c> getCountSessionLIRecListToUpsert(String countSessionRecId, 
						Map<String, List<CountSessionLineItemWrapper.CountSessionLineItem>> partNumberToCSLIObjListMap, 
						Map<String, Part__c> partNumberFoundInDBToPartRecMap, Map<String, Count_Session_Line_Item__c> partIdToCSLIRecOnOtherActiveCSRecMap, 
						Map<String, Count_Session_Line_Item__c> partIdToCSLIRecMap, Boolean isMergeDuplicateParts) {
    	
		List<Count_Session_Line_Item__c> csliRecListToUpsert = new List<Count_Session_Line_Item__c>();
		Set<String> partIdSet = new Set<String>();
		Boolean isDuplicate = false;
    	for(String partNumber : partNumberFoundInDBToPartRecMap.keySet()) {
    		for(CountSessionLineItemWrapper.CountSessionLineItem csliObj : partNumberToCSLIObjListMap.get(partNumber)) {
				isDuplicate = false;
	    		Count_Session_Line_Item__c csliRecToUpsert = new Count_Session_Line_Item__c(Count_Session__c = countSessionRecId);	
	    		if(partNumberFoundInDBToPartRecMap.get(partNumber) == null) {	// Missing vendor issue
	    			csliRecToUpsert.Part_Number__c = csliObj.PartNumber;
		    		csliRecToUpsert.Issue_Indicator__c = Constants.MISSING_VENDOR;
		    		
	    		} else {
	    			Part__c partRec = partNumberFoundInDBToPartRecMap.get(partNumber);
		    		if(partIdToCSLIRecOnOtherActiveCSRecMap.containsKey(partRec.Id)) {	//Active on other count session
			    		csliRecToUpsert.Part__c = partRec.Id;
			    		csliRecToUpsert.Issue_Indicator__c = Constants.ACTIVE_COUNT;
		    		} else {
						if(isMergeDuplicateParts) {
							isDuplicate = true;
							partIdSet.add(partRec.Id);
						}
		    			if(partIdToCSLIRecMap.containsKey(partRec.Id)) {		//If part already exists on current session in either Counted or uncounted tab
			    			Count_Session_Line_Item__c existingCSLIRec = partIdToCSLIRecMap.get(partRec.Id);
							if(existingCSLIRec.Counted_Qty__c == null) existingCSLIRec.Counted_Qty__c = 0;
							if(csliObj.CountedQty == null) 	csliObj.CountedQty = 0;
							
                            if(existingCSLIRec.Is_Counted__c) {	// if part already exists in counted parts tab - DUPLICATE PART issue
								if(isMergeDuplicateParts) {
											existingCSLIRec.Counted_Qty__c += csliObj.CountedQty;
											existingCSLIRec = mergeCSLILocation(existingCSLIRec, csliObj.Locations);
								} else {
									csliRecToUpsert.Part__c = partRec.Id;
									csliRecToUpsert.Issue_Indicator__c = Constants.DUPLICATE_PART;
								}	
			    			} else {	// if part already exists in uncounted parts tab - Add in counted part tab
			    				csliRecToUpsert.Id = existingCSLIRec.Id;
					    		csliRecToUpsert.Is_Counted__c = true;
								csliRecToUpsert.Part__c = partRec.Id;
					    		partIdToCSLIRecMap.get(partRec.Id).Is_Counted__c = true;
								if(isMergeDuplicateParts) { // if part already exists in uncounted parts tab - Add its Qty and location counted part tab
									partIdToCSLIRecMap.get(partRec.Id).Counted_Qty__c += csliObj.CountedQty;
									setLocationOnCountSessionLineItemRec(partIdToCSLIRecMap.get(partRec.Id), csliObj.Locations);
								}
			    			}
			    		} else {	// When part was not already added in coount session - Create New count session line item record
				    		csliRecToUpsert.Part__c = partRec.Id;
				    		csliRecToUpsert.Is_Counted__c = true;
				    		csliRecToUpsert.Cost__c = (partRec.Average_Cost__c != null && partRec.Average_Cost__c != 0) ? partRec.Average_Cost__c : partRec.Last_Cost__c;
				    		csliRecToUpsert.Qty_Available__c = partRec.AvailableParts__c;
				    		partIdToCSLIRecMap.put(partRec.Id, csliRecToUpsert);
			    		}
		    		}
				}
					csliRecToUpsert.Counted_Qty__c = csliObj.CountedQty;
					csliRecToUpsert = setLocationOnCountSessionLineItemRec(csliRecToUpsert, csliObj.Locations);
				if(!isDuplicate) {
					csliRecListToUpsert.add(csliRecToUpsert);
				}
    		}	
    		partNumberToCSLIObjListMap.remove(partNumber);
    	}
		if(isMergeDuplicateParts) {
			for(String partId : partIdSet) {
				if((partIdToCSLIRecMap.keySet()).contains(partId)){
					csliRecListToUpsert.add(partIdToCSLIRecMap.get(partId));
				}
			}
		}
    	//Parts that were not found in DB = Invalid part issue
    	for(String partNumber : partNumberToCSLIObjListMap.keySet()) {
    		for(CountSessionLineItemWrapper.CountSessionLineItem csliObj : partNumberToCSLIObjListMap.get(partNumber)) {
	    		Count_Session_Line_Item__c csliRecToUpsert = new Count_Session_Line_Item__c(Count_Session__c = countSessionRecId);
				csliRecToUpsert.Part_Number__c = csliObj.PartNumber;
	    		csliRecToUpsert.Counted_Qty__c = csliObj.CountedQty;
	    		csliRecToUpsert = setLocationOnCountSessionLineItemRec(csliRecToUpsert, csliObj.Locations);
	    		csliRecToUpsert.Issue_Indicator__c = Constants.INVALID_PART;
	    		csliRecListToUpsert.add(csliRecToUpsert);
    		}
    	}
    	return csliRecListToUpsert;
    }
    
    private static Count_Session_Line_Item__c mergeCSLILocation(Count_Session_Line_Item__c countSessionLineItemRec, String locationsStr) {
		String newLocationsStr;
		if(String.isNotBlank(countSessionLineItemRec.Assigned_Location_1__c) && countSessionLineItemRec.Assigned_Location_1__c.length() > 1) {
			newLocationsStr = countSessionLineItemRec.Assigned_Location_1__c.substring(1, countSessionLineItemRec.Assigned_Location_1__c.length());
			if(String.isNotBlank(countSessionLineItemRec.Assigned_Location_2__c) && countSessionLineItemRec.Assigned_Location_2__c.length() > 1) {
				newLocationsStr += countSessionLineItemRec.Assigned_Location_2__c.substring(1, countSessionLineItemRec.Assigned_Location_2__c.length());
			}
			newLocationsStr += locationsStr;
		} else {
			newLocationsStr = locationsStr;
		}

		countSessionLineItemRec = setLocationOnCountSessionLineItemRec(countSessionLineItemRec, newLocationsStr);
		return countSessionLineItemRec;
	}
    private static Count_Session_Line_Item__c setLocationOnCountSessionLineItemRec(Count_Session_Line_Item__c countSessionLineItemRec, String locationsStr) {
    	if(locationsStr != null) {
			List<String> locationNames = new List<String>();
			Set<String> LowerCaseLocationNamesSet = new Set<String>();
			for(String location : locationsStr.split(';')) {
				if(!LowerCaseLocationNamesSet.contains(location.toLowerCase())) {
					LowerCaseLocationNamesSet.add(location.toLowerCase());
					locationNames.add(location);
				}
			}
            List<String> locationStrListForFields = TagUtil.convertTagListIntoTagString(locationNames);
            if(locationStrListForFields.size() > 0) {
            	countSessionLineItemRec.Assigned_Location_1__c = locationStrListForFields[0];
            	if(locationStrListForFields.size() == 2) {
            		countSessionLineItemRec.Assigned_Location_2__c = locationStrListForFields[1];
            	}
            }
		}
		
		return countSessionLineItemRec;
    }
    
    private static List<GenericSearchUtil.SearchedSObjectWrapper> sortSearchedResults(String searchString, List<Count_Session_Line_Item__c> countSessionLineItemRecList) {
    	List<GenericSearchUtil.SearchedSObjectWrapper> sortedList = new List<GenericSearchUtil.SearchedSObjectWrapper>();
    	for(Count_Session_Line_Item__c csliRec : countSessionLineItemRecList) {
            setPriority(sortedList, csliRec, GenericSearchSorting.setMatchingCriteriaToMatchedResultsMap(searchableFieldsList, searchString, (SObject)csliRec));
        }
        
        sortedList.sort();
    	return sortedList;
    }
    
    private static void setPriority(List<GenericSearchUtil.SearchedSObjectWrapper> sortedList, SObject searchRec, 
    											Map<String, Boolean> matchingCriteriaToMatchedResultsMap) {
    												
        for(Integer counter = 0; counter < GenericSearchUtil.matchingCriteriaPriorityList.size(); counter++) {
            if(matchingCriteriaToMatchedResultsMap.containsKey(GenericSearchUtil.matchingCriteriaPriorityList[counter])) {
                sortedList.add( new GenericSearchUtil.SearchedSObjectWrapper(searchRec, 
                                getPriorityNumber((counter + 1)), null));
                break;
            }
        }
	}
	
    public static Boolean isCountSessionCreationCompleted(String countSessionId) {
		List<Count_Session__c> countSessionList = [Select Id, Is_Creation_Completed__c from Count_Session__c where Id =: countSessionId];
		if(countSessionList.size() > 0) {
			return countSessionList[0].Is_Creation_Completed__c;
		}
		return false;
	}

    private static Decimal getPriorityNumber(Integer matchingCriteriaPriority) {
    	return (100 * matchingCriteriaPriority);
    }
    
	private static List<Count_Session_Line_Item__c> getPaginatedRecords(List<GenericSearchUtil.SearchedSObjectWrapper> sortedList, PageInfoWrapper pageInfoObj) {
    		
        Decimal totalRecords = sortedList.size();
        
        Decimal numberOfRecordsOnSelectedPage = pageInfoObj.PageSize;
        if((pageInfoObj.PageSize * pageInfoObj.CurrentPage) > totalRecords) {
            numberOfRecordsOnSelectedPage = (totalRecords - (pageInfoObj.PageSize * (pageInfoObj.CurrentPage - 1)));
        }
        
        Integer startIndex = pageInfoObj.PageSize * (pageInfoObj.CurrentPage - 1);
        Integer endIndex = (pageInfoObj.PageSize * pageInfoObj.CurrentPage) - 1;
        endIndex = (endIndex >= sortedList.size() ? sortedList.size() - 1 : endIndex);
        
        List<Count_Session_Line_Item__c> paginatedRecordsList = new List<Count_Session_Line_Item__c>();
        for(Integer index = startIndex; index <= endIndex; index++) {
			paginatedRecordsList.add((Count_Session_Line_Item__c) sortedList[index].SearchedObj);
		}
		
		return paginatedRecordsList;
	}
    
    public class PageInfoWrapper {
    	public Integer CurrentPage;
    	public Integer PageSize;
    	public String TabName;
    	public String CountSessionId;
    	public String SearchStr;
    }
    
    private static List<String> searchableFieldsList = new List<String>{'Part_Number_Formula__c', 'Part__r.Description__c'};
	
	public static Map<String, String> issueIndicatorToIssueDescriptionMap = new Map<String, String>{'Duplicate part' => 'Duplicate count',
                                                                                                      'Invalid part' => 'Invalid part#',
                                                                                                      'Missing vendor' => 'Multiple vendors for this part #',
                                                                                                      'Active count' => 'Active on different count, must delete'
                                                                                                    };
}