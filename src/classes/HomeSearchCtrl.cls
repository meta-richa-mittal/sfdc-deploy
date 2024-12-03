/**
 * Author: 
 * Since: 
 * Name: HomeSearchCtrl
 * Description: Controller class to handle methods for Home Search page
**/
global without sharing class HomeSearchCtrl {
	public static List<String> filterObjFieldsList = new List<String>{	'Additional_Field_Json__c', 'Common__c', 'CommonFilterCategory__c', 'Custom__c', 'Reconciliation__c',
																		'Display_Hidden_Column__c', 'Export_Field_Json__c', 'Export_File_Format__c',
																		'Export_GroupBy_Field__c', 'favorite__c', 'Field_Filter_Json__c','Field_Filter_Json_2__c','Field_Filter_JSON_Hash_Code__c',
																		'Filter_JSON__c', 'Filter_Label__c', 'Last_Modified_Date_Filter__c',
																		'Show_All_Records__c', 'Sort_Json__c', 'Summary_Field_Json__c', 'Filter_User__c', 'Filter_User__r.Name', 
																		'Email_Addresses__c', 'Report_Format__c', 'Report_Frequency__c', 'Schedule_At__c', 'Schedule_On__c', 'Is_Report_Scheduled__c'
																	};
	
	
	public Decimal Home_Search_Grid_Page_Size { get{return GeneralConfiguration.getHomeSearchGridPageSize();} private set;}
	
	global HomeSearchCtrl (NewHomePageCtrl controller){}
    public HomeSearchCtrl() {}
    
	/**
	 * Name: getFilterObjectTypes
	 * Description: Method to get the object labels which can be filtered on home search screen filter diaplog box
	 * @Param:	
	 * @Return:	String - JSON Sting
	 * 
	**/ 
	@RemoteAction   
    global static String getFilterObjectTypes() {
    		if(AccessControl.ifObjectFieldIsAccessible('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
			String filterQuery = 'SELECT Id';
			for(String fieldStr : filterObjFieldsList) {
				filterQuery += ', ' + fieldStr;
			}
			filterQuery += ' FROM Filter__c'; 
			filterQuery += ' WHERE Common__c = TRUE OR Reconciliation__c = TRUE';
			filterQuery += ' OR (Filter_User__c = \'' + UserInfo.getUserId() + '\' AND (Custom__c = TRUE OR favorite__c = TRUE))';
			filterQuery += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
			List<Filter__c> listfilter = (List<Filter__c>)Database.query(filterQuery);
			
			List<String> filterObjectTypesList = CustomMetadataTypeUtil.getFilterObjectTypes();
			filterObjectTypesList = HomeSearchUtil.filterListBasedOnPermissions(filterObjectTypesList, HomeSearchUtil.filterLabelToPermissionNameMap);
			Map<String, String> filterLabelToDisplayObjMap = CustomMetadataTypeUtil.getFilterDisplayObjectLabel();
			
			Set<String> filterLabelList = new Set<String>(HomeSearchUtil.filterListBasedOnPermissions(new List<String>(filterLabelToDisplayObjMap.keySet()), HomeSearchUtil.filterLabelToPermissionNameMap));
			
			for(String filterLabel: filterLabelToDisplayObjMap.keySet()) {
				if(!filterLabelList.contains(filterLabel)) {
					filterLabelToDisplayObjMap.remove(filterLabel);
				}
			}
			
			listfilter = getFilterListBasedOnUserPermissions(listfilter);
    	 	HomeSearchMasterData hsMasterDataRec = new HomeSearchMasterData(filterObjectTypesList, 
    	 																	new HomeSearchFilterWrapper(),
    	 																	new HomeSearchAllFilter(listfilter),
    	 																	false,								// Default false. Not used on page. Can be removed
    	 																	filterLabelToDisplayObjMap
                                                                        );
			return BPUtility.getEncodedString(System.Json.serialize(hsMasterDataRec));
	}
	
	private static List<Filter__c> getFilterListBasedOnUserPermissions(List<Filter__c> filterList) {
		Map<String, Filter__c> entityTypeToFilterMap = new Map<String, Filter__c>();
		List<Filter__c> filterListToReturn = new List<Filter__c>();
		for(Filter__c filter: filterList) {
			entityTypeToFilterMap.put(filter.Filter_Label__c, filter);
		}
		Map<String, Map<String, Boolean>> permissionsMap = HomeSearchUtil.getUserPermissions();
		String PrimaryLabel = '';
		String SecondaryLabel = '';
		
		for(String entityType: HomeSearchUtil.entityTypeToPermissionNameMap.keySet()) {
			String name = HomeSearchUtil.entityTypeToPermissionNameMap.get(entityType);
			PrimaryLabel = Constants.permissionTypeToLabelListMap.get(name)[0];
	    	SecondaryLabel = Constants.permissionTypeToLabelListMap.get(name)[1];
	    	
    		if(!permissionsMap.get(name).get(PrimaryLabel)) {
    			entityTypeToFilterMap.remove(entityType);
    		}
	    	
		}
		for(Filter__c filter: entityTypeToFilterMap.values()) {
			filterListToReturn.add(filter);
		}
		
		return filterListToReturn;
	}
	
	/**
	 * Name: updateUserReportMode
	 * Description: Method to update report mode check variable on user
	 * @Param:	
	 * @Return:	String - JSON Sting
	 * 
	**/
	@RemoteAction
    global static String updateUserReportMode(Boolean isPortModeOn) {
    		/*String filterQuery = 'SELECT Id';
			for(String fieldStr : filterObjFieldsList) {
				filterQuery += ', ' + fieldStr;
			}
			filterQuery += ' FROM Filter__c';
			filterQuery += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
			List<Filter__c> listfilter = (List<Filter__c>)Database.query(filterQuery);
			
			User currentUser = new User( Id = UserInfo.getUserId());
			currentUser.Is_Report_Mode_On__c = isPortModeOn;
    	 	update currentUser;
    	 	*/
			return BPUtility.getEncodedString('True');
	}
	
    /**
	 * Name: getGridFilterConfigurations
	 * Description: Method to get the home search grid filter settings based on Obejct name
	 * @Param:	1) String objectName - Obejct name selected in home search filter panel
	 * @Return:	String - Serialized string for grid filter settings respective to object name
	 * 
	**/
	@RemoteAction
    global static String getGridFilterConfigurations(String objectNamesStr) {
    	objectNamesStr = BPUtility.getDecodedString(objectNamesStr);
        
    	Set<String> objectNames = (Set<String>)System.JSON.deserialize(objectNamesStr, Set<String>.class);
    	if(objectNames == null || objectNames.size() == 0) {
    		objectNames = new Set<String>{Label.Generic_Object_Label};
    	}
		return BPUtility.getEncodedString(CustomMetadataTypeUtil.getGridFilterConfigurations(objectNames));
	}
	
	@RemoteAction
    global static String getActiveTagList() {
    	return BPUtility.getEncodedString(System.JSON.serialize(TagManagementCtrl.getActiveTagList()));
    }
    
    @RemoteAction
    global static String getActiveLocationList() {
        return BPUtility.getEncodedString(System.JSON.serialize(LocationManagementService.getActiveLocationList()));
    }
	
	/**
	 * Name: getGridColumnsConfiguration
	 * Description: Method to get the home search grid columns configurations based on object name seldcted from UI
	 * @Param:	1) String objectName - Obejct name selected in home search filter panel
	 * @Return:	String - Serialized string for grid columns configurations respective to object name
	 * 
	**/
	@RemoteAction
    global static String getGridColumnsConfiguration(String objectNamesStr, String filterJSON) {
    	objectNamesStr = BPUtility.getDecodedString(objectNamesStr);
        filterJSON = BPUtility.getDecodedString(filterJSON);
        
    	Set<String> objectNames = (Set<String>)System.JSON.deserialize(objectNamesStr, Set<String>.class);
    	if(objectNames == null || objectNames.size() == 0) {
    		objectNames = new Set<String>{Label.Generic_Object_Label};
    	}
		return BPUtility.getEncodedString(CustomMetadataTypeUtil.getGridColumnsConfiguration(objectNames, filterJSON));
	}
	
	@RemoteAction
	@readOnly
    global static String getReportingRecords(String filterJSON) {
    	filterJSON = BPUtility.getDecodedString(filterJSON);
        
    	HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
    	return BPUtility.getEncodedString(HomeSearchReportUtil.getReportingResult(filterWrapperObj));
    }
	
	@RemoteAction
    global static String getPartIdsHavingActivity(String filterJSON) {
    	return PreviewGridRecordsCtrl.getPartIdsHavingActivity(filterJSON);
    }
    
    @RemoteAction
    public static String getPartMovementActivityReportData(String filterJSON, String partIdSet) {
    	return PreviewGridRecordsCtrl.getPartMovementActivityReportData(filterJSON, partIdSet);
    }
    
    @RemoteAction
    public static String getPartMovementDataWithNoActivity(String filterJSON, String uniqueValueFieldLastValue, String partIdSet) {
    	filterJSON = BPUtility.getDecodedString(filterJSON);
    	uniqueValueFieldLastValue = BPUtility.getDecodedString(uniqueValueFieldLastValue);
    	partIdSet = BPUtility.getDecodedString(partIdSet);
    	return BPUtility.getEncodedString(PartMovementReportService.getPartMovementDataWithNoActivity(filterJSON, uniqueValueFieldLastValue, partIdSet, true));
    }
	
	/**
	 * Name: getFilteredRecords
	 * Description: Getting Records According to given filter parameter 
	 * @Param:	(1) filterJSON - String  - Filter JSON String 
	 *			(2) pageAndSortFiltersJSON - String - 
	 * @Return:	
	 * 
	**/ 
	@RemoteAction
	@readOnly
    global static String getFilteredRecords(String filterJSON, String pageAndSortFiltersJSON) {
    	filterJSON = BPUtility.getDecodedString(filterJSON);
    	pageAndSortFiltersJSON = BPUtility.getDecodedString(pageAndSortFiltersJSON);
    	
    	HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
		Map<String, List<HomeSearchFilterInterface.FieldFilter>> objectFiltersMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
		
		Boolean isRecentSearch = true;
		Set<String> fixedResultObjects = new Set<String>{'Customers', 'Vendors'};
		for(String str : filterWrapperObj.Type.Objects){
			if(str == 'Any'){
			 	isRecentSearch = true;
			 	break;
			}
			else{
				 isRecentSearch = false;
			}
		}		
		List<HomeSearchFilterInterface.FilterLabel> filterLabelList = HomeSearchFilterInterface.getFilterLabelList(filterWrapperObj);
		PaginationSorting pageAndSortMapping = (PaginationSorting) System.JSON.deserialize(pageAndSortFiltersJSON, PaginationSorting.class);

		Integer totalRecordsFound;
		String JSONString = '[]';
		
		if(	(filterWrapperObj.SearchText == '' || filterWrapperObj.SearchText == null)
			&& isRecentSearch && filterWrapperObj.Type.Objects.contains(Label.Generic_Object_Label)
		) {
    		List<sObject> searchResults = HomeSearchRecentRecords.getOrgBlankSearchResults(pageAndSortMapping, filterWrapperObj);
        	JSONString = HomeSearchResultWrapper.getJSONForSObjectRecords(searchResults, Label.Generic_Object_Label, HomeSearchRecentRecords.totalRecordsFound, 
        			filterLabelList, false, false, filterWrapperObj.Type.Objects);
    	} else {
    		if(objectFiltersMap.size() == 1 && objectFiltersMap.containsKey(Label.Generic_Object_Label)) { 
                for(String objName : HomeSearchUtil.displayObjectNameToTypeNumber.keySet()) {
    				objectFiltersMap.put(objName, objectFiltersMap.get(Label.Generic_Object_Label));
    			}
    			objectFiltersMap.remove(Label.Generic_Object_Label);
    		}
    		Set<String> objNamesSet = objectFiltersMap.keySet();

			if(!objNamesSet.contains('Customer Invoice Details')) {
				objNamesSet = new Set<String>(HomeSearchUtil.filterListBasedOnPermissions(new List<String>(objNamesSet), HomeSearchUtil.filterLabelToPermissionNameMap));
			}
    		//List<String> objNamesList = HomeSearchUtil.filterListBasedOnPermissions(new List<String>(objNamesSet), HomeSearchUtil.filterLabelToPermissionNameMap);
    		// Get records with SOQL approach for all selected objects
    		Map<String, List<sObject>> resultRecordsMap = HomeSearchReportUtil.getRportRecordsByHomeSearchFilters(	filterWrapperObj, 
																													objNamesSet, 
    																												null,
																													pageAndSortMapping,
																													null
    																											);
    		
    		if(filterWrapperObj.Type.Objects.contains('Customer Deposits')) {
	    		filterWrapperObj.Type.Objects.remove('Customer Deposits');
	    	}
    		if(filterWrapperObj.Type.Objects.contains('AR Payments')) {
	    		filterWrapperObj.Type.Objects.remove('AR Payments');
	    	}
	    	if(filterWrapperObj.Type.Objects.contains('SO Special Order')) {
	    		filterWrapperObj.Type.Objects.remove('SO Special Order');
	    	}
	    	if(filterWrapperObj.Type.Objects.contains('Vendor Return')) {
	    		filterWrapperObj.Type.Objects.remove('Vendor Return');
	    	}
			if(filterWrapperObj.Type.Objects.contains('Vendor Credit')) {
	    		filterWrapperObj.Type.Objects.remove('Vendor Credit');
	    	}
	    	if(filterWrapperObj.Type.Objects.contains('SOLI')) {
	    		filterWrapperObj.Type.Objects.remove('SOLI');
	    	}
	    	if(filterWrapperObj.Type.Objects.contains('Option and Fee')) {
	    		filterWrapperObj.Type.Objects.remove('Option and Fee');
	    	}
    		if(filterWrapperObj.Type.Objects.contains('Part FIFO Line Item')) {
                filterWrapperObj.Type.Objects.remove('Part FIFO Line Item');
            }
            if(filterWrapperObj.Type.Objects.contains('Tax Detail') && (filterWrapperObj.Type.Objects.contains('Tax Detail Customer Invoices'))) {
                filterWrapperObj.Type.Objects.remove('Tax Detail Customer Invoices');
            }
            if(filterWrapperObj.Type.Objects.contains('Tax Detail') && (filterWrapperObj.Type.Objects.contains('Tax Detail Vendor Invoices'))) {
                filterWrapperObj.Type.Objects.remove('Tax Detail Vendor Invoices');
            }
            if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details COLI') || filterWrapperObj.Type.Objects.contains('Customer Invoice Details SOLI') || filterWrapperObj.Type.Objects.contains('Customer Invoice Details Option and Fee')
            			|| filterWrapperObj.Type.Objects.contains('Customer Invoice Details Deal UPC') || filterWrapperObj.Type.Objects.contains('Customer Invoice Details Trade in') || filterWrapperObj.Type.Objects.contains('Customer Invoice Details FI Product')
						|| filterWrapperObj.Type.Objects.contains('Customer Invoice Details Deal Finance') || filterWrapperObj.Type.Objects.contains('Customer Invoice Details Deal')) {
            	filterWrapperObj.Type.Objects.add('Customer Invoice Details');	
            }
            if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details COLI')) {
            	filterWrapperObj.Type.Objects.remove('Customer Invoice Details COLI');
            }
            if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details SOLI')) {
            	filterWrapperObj.Type.Objects.remove('Customer Invoice Details SOLI');
            }
            if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details Option and Fee')) {
            	filterWrapperObj.Type.Objects.remove('Customer Invoice Details Option and Fee');
            }
            if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details Deal UPC')) {
            	filterWrapperObj.Type.Objects.remove('Customer Invoice Details Deal UPC');
            }
            if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details Trade in')) {
            	filterWrapperObj.Type.Objects.remove('Customer Invoice Details Trade in');
            }
            if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details FI Product')) {
            	filterWrapperObj.Type.Objects.remove('Customer Invoice Details FI Product');
            }
			if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details Deal Finance')) {
            	filterWrapperObj.Type.Objects.remove('Customer Invoice Details Deal Finance');
            }
			if(filterWrapperObj.Type.Objects.contains('Customer Invoice Details Deal')) {
            	filterWrapperObj.Type.Objects.remove('Customer Invoice Details Deal');
            }
    		// Loop over records so as to get last page size records so as paginate records
    		// we have already applied sorting on SOQL and limited records to current page size so as to minimize more efforts in pagination and sorting
    		Map<String, List<sObject>> paginatedRecordsMap = new Map<String, List<sObject>>();
    		
            Decimal totalNumberOfRecords = 0;
            for(String objAPIName : resultRecordsMap.keySet()) {
                totalNumberOfRecords += resultRecordsMap.get(objAPIName).size();
            }
            
            Decimal remianingRecords = 0;
            if(pageAndSortMapping.PageSize * pageAndSortMapping.CurrentPage >= totalNumberOfRecords) {
                remianingRecords = totalNumberOfRecords - (pageAndSortMapping.PageSize * (pageAndSortMapping.CurrentPage - 1));
            } else {
                remianingRecords = pageAndSortMapping.PageSize;
            }
            
            if(resultRecordsMap.keySet().size() > 1){
                remianingRecords = pageAndSortMapping.PageSize * pageAndSortMapping.CurrentPage;
            }
            
            for(Integer i = 1; i <= remianingRecords; i++) {
    			for(String objAPIName : resultRecordsMap.keySet()) {
    				if((!HomeSearchUtil.objectWithNoPaginationSet.contains(objAPIName) && !filterWrapperObj.Type.Objects.contains('Tax Detail') && !filterWrapperObj.Type.Objects.contains('Customer Invoice Details')) 
    						|| filterWrapperObj.Type.Objects.contains('Parts to Pull')) {
	    				List<sObject> recordsList = resultRecordsMap.get(objAPIName);
	    				List<sObject> paginatedRecordsList = (paginatedRecordsMap.containsKey(objAPIName)) ? paginatedRecordsMap.get(objAPIName) : new List<sObject>();
	    				
	    				if(recordsList.size() - i >= 0) {
	    					if(paginatedRecordsList.size() > 0) {
	    						paginatedRecordsList.add(0, recordsList[recordsList.size() - i]);
	    					} else {
	    						paginatedRecordsList.add(recordsList[recordsList.size() - i]);
	    					}
	    					paginatedRecordsMap.put(objAPIName, paginatedRecordsList);
	    				}
    				} else if(!paginatedRecordsMap.containsKey(objAPIName)) {
    					/*if(objAPIName == 'Parts Order') {
    						paginatedRecordsMap.put(objAPIName, new List<sObject>());
    						Decimal noOfRecordsToAddInList = (remianingRecords < resultRecordsMap.get(objAPIName).size() ? 
    							remianingRecords : resultRecordsMap.get(objAPIName).size());
    						for(Integer j = 0; j < noOfRecordsToAddInList; j++) {
    							sObject sobjRec = (resultRecordsMap.get(objAPIName))[j];
    							paginatedRecordsMap.get(objAPIName).add(sobjRec);
    						}
    					} else {*/
						paginatedRecordsMap.put(objAPIName, resultRecordsMap.get(objAPIName));
    					//}
    					
    				}
    			}
    		}
    		// sort records and get JSON result
    		List<String> objectsToSearch = new List<String>(paginatedRecordsMap.keySet());
    		String objectTypeSortDirection;
			Boolean isAnyFilterPresent = true;
			
			Integer indexVal = -1;
			Integer indexForType = -1;
			/*for(PaginationSorting.SortAttrs sortField : pageAndSortMapping.Sorting) {
                indexVal++;
                if(sortField.FieldName == 'Type') {
                    objectTypeSortDirection = sortField.SortDirection;
                    indexForType = indexVal;
                } else {
                    isAnyFilterPresent = true;
                }
            }
            if(indexForType != -1) {
                pageAndSortMapping.Sorting.remove(indexForType);
            }*/
			
			System.debug('### objectTypeSortDirection: \n\n' + objectTypeSortDirection);
			System.debug('### objectsToSearch: \n\n' + objectsToSearch);
			System.debug('### isAnyFilterPresent: \n\n' + isAnyFilterPresent);
			System.debug('### paginatedRecordsMap: \n\n' + paginatedRecordsMap);
			System.debug('### pageAndSortMapping: \n\n' + pageAndSortMapping);
        	//System.debug('### resultRecords: \n\n' + resultRecords);
        	// Serialize JSON based on object type
	        List<sObject> resultRecords = new List<sObject>();
        	if(!filterWrapperObj.Type.Objects.contains('Part FIFO') && !filterWrapperObj.Type.Objects.contains('Tax Detail') && 
        		!filterWrapperObj.Type.Objects.contains('Customer Invoice Details') && !(filterWrapperObj.Type.Objects.contains('Invoiced Items') && filterWrapperObj.IsSummaryFormat != null && filterWrapperObj.IsSummaryFormat)) {
        		resultRecords = HomeSearchSOSL.sortTheRecords(objectTypeSortDirection, objectsToSearch, isAnyFilterPresent, paginatedRecordsMap, pageAndSortMapping);
        	} else {
        		for(String key : paginatedRecordsMap.keySet()) {
        			resultRecords.addAll((List<sObject>) paginatedRecordsMap.get(key));
        		}
        	}
        	
        	if(filterWrapperObj.Type.Objects.contains('Part FIFO') || filterWrapperObj.Type.Objects.contains('Tax Detail')) {
        		JSONString = HomeSearchResultWrapper.getJSONForSObjectRecords(resultRecords, 
							  HomeSearchUtil.getGenericObjectNameBySelectedObject(filterWrapperObj.Type.Objects),
							  -1,
							  filterLabelList, true, filterWrapperObj.IncludeInactiveRecords, filterWrapperObj.IsSummaryFormat,
							  filterWrapperObj.Type.Objects, filterWrapperObj
							);
        	} else {
				if(HomeSearchUtil.getGenericObjectNameBySelectedObject(filterWrapperObj.Type.Objects) == 'Inventory Unit'){
					JSONString = HomeSearchResultWrapper.getJSONForSObjectRecords(resultRecords, 
							  HomeSearchUtil.getGenericObjectNameBySelectedObject(filterWrapperObj.Type.Objects),
							  -1,
							  filterLabelList,true, filterWrapperObj.IncludeInactiveRecords, filterWrapperObj.IsSummaryFormat,
							  filterWrapperObj.Type.Objects, filterWrapperObj
							);
				} else{
                    JSONString = HomeSearchResultWrapper.getJSONForSObjectRecords(resultRecords, 
							  HomeSearchUtil.getGenericObjectNameBySelectedObject(filterWrapperObj.Type.Objects),
							  -1,
							  filterLabelList, filterWrapperObj.IncludeInactiveRecords, filterWrapperObj.IsSummaryFormat,
							  filterWrapperObj.Type.Objects
							);
				}
        	}
    	}
		
		/*if(objectFiltersMap.size() != 0 && (filterWrapperObj.Type.Objects != null && filterWrapperObj.Type.Objects.size() != 0)) {
			JSONString = HomeSearchSOSL.searchRecords(objectFiltersMap, filterWrapperObj.Type.Objects, filterWrapperObj.SearchText);
		}*/
		//System.assert(false, JSONString);
        return BPUtility.getEncodedString(JSONString);
	}
	
	@RemoteAction
	global static String getTaxDetailsByFilterJson(String filterJSON) {
		filterJSON = BPUtility.getDecodedString(filterJSON);
    	
    	HomeSearchFilterWrapper homeSerachFilterObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
		
		String JSONString;
		if(homeSerachFilterObj.Type.Objects.contains('Tax Detail')) {
			homeSerachFilterObj.Type.Objects.add('Tax Detail Unit Adjustments');
            if(homeSerachFilterObj.Tax_Detail_Invoice_Type == '0' || homeSerachFilterObj.Tax_Detail_Invoice_Type.equalsIgnoreCase('Purchasing')) {
                homeSerachFilterObj.Type.Objects.add('Tax Detail Unit Invoices');
                homeSerachFilterObj.Type.Objects.add('Tax Detail Vendor Returns');
            }
			homeSerachFilterObj.Type.Objects.remove('Tax Detail');
			Map<String, List<HomeSearchFilterInterface.FieldFilter>> objectFiltersMap = HomeSearchFilterInterface.getFilterList(homeSerachFilterObj);
			
			Map<String, List<sObject>> resultRecordsMap = HomeSearchReportUtil.getRportRecordsByHomeSearchFilters(homeSerachFilterObj, 
																														homeSerachFilterObj.Type.Objects, 
																														null,
																														null,
																														null);
			JSONString = System.JSON.serialize(getTaxReportingFromMultipleObjects(resultRecordsMap, homeSerachFilterObj));
		}
        return BPUtility.getEncodedString(JSONString);
	}

	private static List<HomeSearchResultWrapper.TaxReporting> getTaxReportingFromMultipleObjects(Map<String, List<sObject>> resultRecordsMap, HomeSearchFilterWrapper filterWrapperObj) {
        List<HomeSearchResultWrapper.TaxReporting> taxReportingObjList = new List<HomeSearchResultWrapper.TaxReporting>();
		Set<Id> applicableTaxIdSet = new Set<Id>();
		for(String objAPIName : resultRecordsMap.keySet()) {
			for(SObject sobjRec : resultRecordsMap.get(objAPIName)) {
				String taxId;
				if(objAPIName.equalsIgnoreCase('Unit_Price_Cost__c')) {
					taxId = String.valueOf(sobjRec.get(Constants.NAMESPACE + 'Applicable_Tax__c'));
				} else if(objAPIName.equalsIgnoreCase('Return_CR_Header__c')) {
					taxId = (sobjRec.get(Constants.NAMESPACE +'Vendor__c') != null && String.valueOf(sobjRec.getSobject(Constants.NAMESPACE + 'Vendor__r').get(Constants.NAMESPACE +'Purchase_Tax__c')) != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Vendor__r').get(Constants.NAMESPACE +'Purchase_Tax__c')) : null;
				} else if(objAPIName.equalsIgnoreCase('Customer_Owned_Unit__c')) {
					taxId = (sobjRec.get(Constants.NAMESPACE +'Referenced_Unit__c') != null && String.valueOf(sobjRec.getSobject(Constants.NAMESPACE + 'Referenced_Unit__r').get(Constants.NAMESPACE +'Unit_Purchase_Tax__c')) != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Referenced_Unit__r').get(Constants.NAMESPACE +'Unit_Purchase_Tax__c')) : null;
				}
				if(String.isNotBlank(taxId)) {
					applicableTaxIdSet.add(taxId);
				}
			}
		}
		if(!applicableTaxIdSet.isEmpty() && filterWrapperObj.Selected_Sales_Tax_Items != null && !filterWrapperObj.Selected_Sales_Tax_Items.isEmpty()) {
			String query = 'Select Name, Sales_Tax__c, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c FROM Applicable_Taxes__c WHERE Sales_Tax__c IN: applicableTaxIdSet';
			Set<String> selectedSalesTaxItemNames = filterWrapperObj.Selected_Sales_Tax_Items;

			Map<Id, String> salesTaxIdToSalesTaxItemNameMap = new Map<Id, String>();
			Map<Id, List<Applicable_Taxes__c>> salesTaxIdToApplicableTaxListMap = new Map<Id, List<Applicable_Taxes__c>>();
			for(Applicable_Taxes__c applicableTax : Database.query(query)) {
				if(!salesTaxIdToApplicableTaxListMap.containsKey(applicableTax.Sales_Tax__c)) {
					salesTaxIdToApplicableTaxListMap.put(applicableTax.Sales_Tax__c, new List<Applicable_Taxes__c>());
				}
				salesTaxIdToSalesTaxItemNameMap.put(applicableTax.Sales_Tax__c, applicableTax.Sales_Tax_Item__r.Name__c);
				salesTaxIdToApplicableTaxListMap.get(applicableTax.Sales_Tax__c).add(applicableTax);
			}
			//system.assert(false, salesTaxIdToApplicableTaxListMap);
		
			for(String objAPIName : resultRecordsMap.keySet()) {
				for(SObject sobjRec : resultRecordsMap.get(objAPIName)) {
					String taxId;
					if(objAPIName.equalsIgnoreCase('Unit_Price_Cost__c')) {
						taxId = sobjRec.get(Constants.NAMESPACE + 'Applicable_Tax__c') != null ? String.valueOf(sobjRec.get(Constants.NAMESPACE + 'Applicable_Tax__c')) : null;
					} else if(objAPIName.equalsIgnoreCase('Return_CR_Header__c')) {
						taxId = (sobjRec.get(Constants.NAMESPACE +'Vendor__c') != null && String.valueOf(sobjRec.getSobject(Constants.NAMESPACE + 'Vendor__r').get(Constants.NAMESPACE +'Purchase_Tax__c')) != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Vendor__r').get(Constants.NAMESPACE +'Purchase_Tax__c')) : null;
					} else if(objAPIName.equalsIgnoreCase('Customer_Owned_Unit__c')) {
						taxId = (sobjRec.get(Constants.NAMESPACE +'Referenced_Unit__c') != null && String.valueOf(sobjRec.getSobject(Constants.NAMESPACE + 'Referenced_Unit__r').get(Constants.NAMESPACE +'Unit_Purchase_Tax__c')) != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Referenced_Unit__r').get(Constants.NAMESPACE +'Unit_Purchase_Tax__c')) : null;
					}
					HomeSearchResultWrapper.TaxReporting taxReportingObj;
					if(salesTaxIdToApplicableTaxListMap.containsKey(taxId) && (filterWrapperObj.Selected_Sales_Tax_Items.contains('All') || filterWrapperObj.Selected_Sales_Tax_Items.contains(salesTaxIdToSalesTaxItemNameMap.get(taxId)))) {
						for(Applicable_Taxes__c applicableTax : salesTaxIdToApplicableTaxListMap.get(taxId)) {
							if(objAPIName.equalsIgnoreCase('Unit_Price_Cost__c')) {
								taxReportingObj = new HomeSearchResultWrapper.TaxReporting((Unit_Price_Cost__c)sobjRec, applicableTax.Sales_Tax_Item__r, null);
							} else if(objAPIName.equalsIgnoreCase('Return_CR_Header__c')) {
								taxReportingObj = new HomeSearchResultWrapper.TaxReporting((Return_CR_Header__c)sobjRec, applicableTax.Sales_Tax_Item__r, null);
							} else if(objAPIName.equalsIgnoreCase('Customer_Owned_Unit__c')) {
								taxReportingObj = new HomeSearchResultWrapper.TaxReporting((Customer_Owned_Unit__c)sobjRec, applicableTax.Sales_Tax_Item__r, null);
							}
							taxReportingObjList.add(taxReportingObj);
						}
					} else if(!salesTaxIdToApplicableTaxListMap.containsKey(taxId)) {
						if(objAPIName.equalsIgnoreCase('Unit_Price_Cost__c')) {
							if(((Unit_Price_Cost__c)sobjRec).Vendor__c != null && (filterWrapperObj.Selected_Sales_Tax_Items.contains('All') || filterWrapperObj.Selected_Sales_Tax_Items.contains(HomeSearchUtil.nonTaxablePurchases))) {
								taxReportingObj = new HomeSearchResultWrapper.TaxReporting((Unit_Price_Cost__c)sobjRec, null, HomeSearchUtil.nonTaxablePurchases);
							} else if(((Unit_Price_Cost__c)sobjRec).Customer__c != null && (filterWrapperObj.Selected_Sales_Tax_Items.contains('All') || filterWrapperObj.Selected_Sales_Tax_Items.contains(HomeSearchUtil.nonTaxableSales))) {
								taxReportingObj = new HomeSearchResultWrapper.TaxReporting((Unit_Price_Cost__c)sobjRec, null, HomeSearchUtil.nonTaxableSales);
							}
						} else if(objAPIName.equalsIgnoreCase('Return_CR_Header__c') && (filterWrapperObj.Selected_Sales_Tax_Items.contains('All') || filterWrapperObj.Selected_Sales_Tax_Items.contains(HomeSearchUtil.nonTaxablePurchases))) {
							taxReportingObj = new HomeSearchResultWrapper.TaxReporting((Return_CR_Header__c)sobjRec, null, HomeSearchUtil.nonTaxablePurchases);
						} else if(objAPIName.equalsIgnoreCase('Customer_Owned_Unit__c') && (filterWrapperObj.Selected_Sales_Tax_Items.contains('All') || filterWrapperObj.Selected_Sales_Tax_Items.contains(HomeSearchUtil.nonTaxablePurchases))) {
							taxReportingObj = new HomeSearchResultWrapper.TaxReporting((Customer_Owned_Unit__c)sobjRec, null, HomeSearchUtil.nonTaxablePurchases);	
						}
						if(taxReportingObj != null) taxReportingObjList.add(taxReportingObj);
					}
				}
			}
		}
		return taxReportingObjList;
    }

	/**
	 * Name: saveFilterRecord
	 * Description: Save and Edit the record based On the value passed
	 * @Param:  (1) String filterId - FilterId passed from the Front panel
	 *          (2) String filterName - FilterName passed from the FrontPanel
	 *          (3) String fieldFilterJson - 
	 *			(4) String displayHiddenColumn - 
	 *			(5) String additionalFieldJson - 
	 * @Return: String
	**/
	@RemoteAction
	global static String saveFilterRecord(	String filterId, 
											String filterName, 
											String fieldFilterJson, 
											String sortJson, 
											String displayHiddenColumn, 
											String additionalFieldJson,
											String summaryFieldsJSON,
											String exportFieldsJSON,
											String exportFileFormat,
											String exportGroupFieldType,
											Boolean showAllrecords
										) {
		filterId = BPUtility.getDecodedString(filterId);
    	filterName = BPUtility.getDecodedString(filterName);
    	fieldFilterJson = BPUtility.getDecodedString(fieldFilterJson);
    	sortJson = BPUtility.getDecodedString(sortJson);
    	displayHiddenColumn = BPUtility.getDecodedString(displayHiddenColumn);
    	additionalFieldJson = BPUtility.getDecodedString(additionalFieldJson);
    	summaryFieldsJSON = BPUtility.getDecodedString(summaryFieldsJSON);
    	exportFieldsJSON = BPUtility.getDecodedString(exportFieldsJSON);
    	exportFileFormat = BPUtility.getDecodedString(exportFileFormat);
    	exportGroupFieldType = BPUtility.getDecodedString(exportGroupFieldType);
    	
		if(AccessControl.ifObjectFieldIsCreateable('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }									
		if(AccessControl.ifObjectFieldIsUpdateable('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		Filter__c filterRecordToSave = new Filter__c();
		if(filterId != null){
			filterRecordToSave.Id = filterId;
		} else {
			filterRecordToSave.Custom__c = true;
		}
		
		if(filterName != '') {
			filterRecordToSave.Filter_Label__c = (filterName == null) ? '' : filterName;
		}
		if(FieldFilterJson != '') {
			FieldFilterJson = UserTriggerHelper.setFieldFilterJSON(FieldFilterJson);
			filterRecordToSave.Field_Filter_Json__c = (FieldFilterJson == null) ? '' : FieldFilterJson.substring(0,FieldFilterJson.length()) ;
			filterRecordToSave.Field_Filter_Json_2__c = (FieldFilterJson == null || FieldFilterJson.length() <= 131072 ) ? '' : FieldFilterJson.substring(131072, FieldFilterJson.length());
		}
		if(sortJson != '') {
			filterRecordToSave.Sort_Json__c = (sortJson == null) ? '' : sortJson;
		}
		if(String.isNotBlank(DisplayHiddenColumn)) {
			DisplayHiddenColumnWrapper displayColumnJson = (DisplayHiddenColumnWrapper) System.JSON.deserialize(DisplayHiddenColumn, DisplayHiddenColumnWrapper.class);
			displayColumnJson.HiddenColumns = null;
			filterRecordToSave.Display_Hidden_Column__c = System.JSON.serialize(displayColumnJson);
		}
		if(AdditionalFieldJson != '') {
			filterRecordToSave.Additional_Field_Json__c = (AdditionalFieldJson == null) ? '' : AdditionalFieldJson;
		}
		
		if(summaryFieldsJSON != null && summaryFieldsJSON != '' && summaryFieldsJSON.trim().length() != 2) {
			filterRecordToSave.Summary_Field_Json__c = (summaryFieldsJSON == null) ? '' : summaryFieldsJSON;
		}
		if(exportFieldsJSON != null && exportFieldsJSON != '' && exportFieldsJSON.trim().length() != 2) {
			filterRecordToSave.Export_Field_Json__c = (exportFieldsJSON == null) ? '' : exportFieldsJSON;
		}
		if(exportFileFormat != '') {
			filterRecordToSave.Export_File_Format__c = (exportFileFormat == null) ? '' : exportFileFormat;
		}
		if(exportGroupFieldType != '') {
			filterRecordToSave.Export_GroupBy_Field__c = (exportGroupFieldType == null) ? '' : exportGroupFieldType;
		}
		
		filterRecordToSave.Show_All_Records__c = showAllrecords;
		
		filterRecordToSave.Filter_User__c = UserInfo.getUserId();
		
		upsert filterRecordToSave;
		
		return 	getSavedFilterList(filterRecordToSave.Id);		
	}
	
	/**
	 * Name: previewExportRecords
	 * Description: Save and Edit the record based On the value passed
	 * @Param:  (1) String filterId - FilterId passed from the Front panel
	 *          (2) String filterName - FilterName passed from the FrontPanel
	 *          (3) String fieldFilterJson - 
	 *			(4) String displayHiddenColumn - 
	 *			(5) String additionalFieldJson - 
	 * @Return: String
	**/
	@RemoteAction
	global static String previewExportRecords(	String fieldFilterJson, 
												String sortJson, 
												String displayHiddenColumn, 
												String summaryFieldJSON,
												String exportFileFormat,
												String exportGroupFieldType
											) {
		fieldFilterJson = BPUtility.getDecodedString(fieldFilterJson);
    	sortJson = BPUtility.getDecodedString(sortJson);
    	displayHiddenColumn = BPUtility.getDecodedString(displayHiddenColumn);
    	summaryFieldJSON = BPUtility.getDecodedString(summaryFieldJSON);
    	exportFileFormat = BPUtility.getDecodedString(exportFileFormat);
    	exportGroupFieldType = BPUtility.getDecodedString(exportGroupFieldType);
    			
		Filter__c filterRecordToSave = new Filter__c();
		filterRecordToSave.Filter_Label__c = 'Preview Report';
		filterRecordToSave.Field_Filter_Json__c = (FieldFilterJson == null) ? '' : FieldFilterJson.substring(0,FieldFilterJson.length()) ;
		filterRecordToSave.Field_Filter_Json_2__c = (FieldFilterJson == null || FieldFilterJson.length() <= 131072) ? '' : FieldFilterJson.substring(131072, FieldFilterJson.length());
		filterRecordToSave.Sort_Json__c = (sortJson == null) ? '' : sortJson;
		filterRecordToSave.Display_Hidden_Column__c = (DisplayHiddenColumn == null) ? '' : DisplayHiddenColumn;
		filterRecordToSave.Summary_Field_Json__c = (summaryFieldJSON == null) ? '' : summaryFieldJSON;
		filterRecordToSave.Export_File_Format__c = (exportFileFormat == null) ? '' : exportFileFormat;
		filterRecordToSave.Export_GroupBy_Field__c = (exportGroupFieldType == null) ? '' : exportGroupFieldType;
		filterRecordToSave.Filter_User__c = UserInfo.getUserId();
		DMLUtility.insertSobjectList('Filter__c', filterRecordToSave);
		return 	BPUtility.getEncodedString(filterRecordToSave.Id);		
	}
	
	
	/**
	 * Name: checkForSimilarFilter
	 * Description: Getting Similar Filter
	 * @Param:  (1) String fieldFilterJson - 
	 * @Return: String Filter Name
	**/
	@RemoteAction
	global static String checkForSimilarFilter(String fieldFilterJson) {
		fieldFilterJson = BPUtility.getDecodedString(fieldFilterJson);
    	
    	fieldFilterJson = UserTriggerHelper.setFieldFilterJSON(fieldFilterJson);
		Decimal fieldJSONHashCode = (fieldFilterJson != null) ? fieldFilterJson.hashCode() : 0;
		if(AccessControl.ifObjectFieldIsAccessible('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Filter__c> filterList = [select Id, 
											 Filter_Label__c 
											 from Filter__c 
											 where Field_Filter_JSON_Hash_Code__c = :fieldJSONHashCode
											 And Filter_User__c =: UserInfo.getUserId()
									];
		
		String filterName;
		if(filterList.size() > 0) {
			filterName = filterList[0].Filter_Label__c;
		} 
		return BPUtility.getEncodedString(filterName);
	}
	
	 /**
	 * Name: getFilterFields
	 * Description:Function get filter item by Id
	 * @Param:  (1) String filterId - FilterId passed from the Front panel
	 * @Return: String  JSON String
	 **/
	@RemoteAction
	global static String getFilterFields(String filterId){
		filterId = BPUtility.getDecodedString(filterId);
    	filterId = BPUtility.escapeSingleQuotes(filterId);
		if(AccessControl.ifObjectFieldIsAccessible('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		String filterQuery = 'SELECT Id';
		for(String fieldStr : filterObjFieldsList) {
			filterQuery += ', ' + fieldStr;
		}
		filterQuery += ' FROM Filter__c';
		filterQuery += ' WHERE Id =: filterId';
		filterQuery += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
		List<Filter__c> listfilter = (List<Filter__c>)Database.query(filterQuery);
		
		Filter__c FilterJsonReturn = listfilter[0];		
		
		HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(FilterJsonReturn.Field_Filter_Json__c, HomeSearchFilterWrapper.class);

	 	GenericFilterWrapper GenericfilterWrapperObj =new GenericFilterWrapper( FilterJsonReturn);
	 	
	 	List<Unit_Data_Field_Config__c> configList = [Select Name from Unit_Data_Field_Config__c 
    			where Name != null AND Display_Label__c != null order by Name];
	
    	Set<String> unitDataFieldNameSet = new Set<String>();
    	for(Unit_Data_Field_Config__c configRec : configList) {
    		unitDataFieldNameSet.add(configRec.Name);
    	}
    	if(GenericfilterWrapperObj.DisplayHiddenColumn != null) {
			DisplayHiddenColumnWrapper DisplayHiddenColumnJson = (DisplayHiddenColumnWrapper) System.JSON.deserialize(GenericfilterWrapperObj.DisplayHiddenColumn, DisplayHiddenColumnWrapper.class);
			
			Map<String, DisplayedColumnsWrapper> displayColumnLabelToObjMap = new Map<String, DisplayedColumnsWrapper>();
			for(Integer i=0; i<DisplayHiddenColumnJson.DisplayedColumns.size(); i++) {
				if(DisplayHiddenColumnJson.DisplayedColumns[i].RecordKey.contains('Unit_Data')){
					displayColumnLabelToObjMap.put(DisplayHiddenColumnJson.DisplayedColumns[i].RecordKey.toUpperCase().replace('_', ' '), null);
				} else {
					displayColumnLabelToObjMap.put(DisplayHiddenColumnJson.DisplayedColumns[i].Label.toUpperCase(), null);
				}
			}
			
			List<DisplayedColumnsWrapper> displayColumns = new List<DisplayedColumnsWrapper>();
			List<DisplayedColumnsWrapper> hiddenColumns = new List<DisplayedColumnsWrapper>();

			if(filterWrapperObj != null && filterWrapperObj.Type != null && filterWrapperObj.Type.Objects != null && filterWrapperObj.Type.Objects.size() > 0) {
				List<String> objectList = new List<String>(filterWrapperObj.Type.Objects);
				for(HomeSearch_Grid_Column__mdt gridColumnMdt : CustomMetadataTypeUtil.getGridColumnsMetadataTypeSettings(objectList[0])) {
					DisplayedColumnsWrapper columnObj = new DisplayedColumnsWrapper(gridColumnMdt);
					if(displayColumnLabelToObjMap.containsKey(gridColumnMdt.Label.toUpperCase())) {
						columnObj.IsDisplayed = true;
						columnObj.IsHidden = !columnObj.IsDisplayed;
						displayColumnLabelToObjMap.put(gridColumnMdt.Label.toUpperCase(), columnObj);	//To maintain order of columns
					} else {
						columnObj.IsDisplayed = false;
						columnObj.IsHidden = !columnObj.IsDisplayed;
						hiddenColumns.add(columnObj);
					}
				}
				for(DisplayedColumnsWrapper columnObj : displayColumnLabelToObjMap.values()) {
					if(columnObj != null) displayColumns.add(columnObj);
				}
				DisplayHiddenColumnJson.DisplayedColumns = displayColumns;
				DisplayHiddenColumnJson.HiddenColumns = hiddenColumns;
			}
			
			for(Integer i=0; i<DisplayHiddenColumnJson.DisplayedColumns.size(); i++) {
				if(CustomMetadataTypeUtil.genericUnitDataFieldSet.contains(DisplayHiddenColumnJson.DisplayedColumns[i].Label) && 
									!unitDataFieldNameSet.contains(DisplayHiddenColumnJson.DisplayedColumns[i].Label)) {
					DisplayHiddenColumnJson.DisplayedColumns.remove(i);
					i--;
				}
			}
			for(Integer i=0; i<DisplayHiddenColumnJson.HiddenColumns.size(); i++) {
				if(CustomMetadataTypeUtil.genericUnitDataFieldSet.contains(DisplayHiddenColumnJson.HiddenColumns[i].Label) && 
									!unitDataFieldNameSet.contains(DisplayHiddenColumnJson.HiddenColumns[i].Label)) {
					DisplayHiddenColumnJson.HiddenColumns.remove(i);
					i--;
				}
			}
			GenericfilterWrapperObj.DisplayHiddenColumn = System.Json.serialize(DisplayHiddenColumnJson);
			
			if(HomeSearchUtil.entityTypeToCostColumnsMap.keySet().contains(FilterJsonReturn.Filter_Label__c)) {
				SummaryAndExportColumnWrapper SummaryAndExportColumnJson = (SummaryAndExportColumnWrapper) System.JSON.deserialize(GenericfilterWrapperObj.SummaryFieldsJSON, SummaryAndExportColumnWrapper.class);
				Map<String, Map<String, Boolean>> permissionsMap = HomeSearchUtil.getUserPermissions();
				Boolean primaryPermission = permissionsMap.get('Costs').get('read only');
				Boolean modifyPermission = permissionsMap.get('Costs').get('modify');
				Boolean permissionForPartCost = permissionsMap.get('Part costs').get('enabled');
				Boolean permissionForUnitCost = permissionsMap.get('Unit costs').get('enabled');
				Boolean permissionForDealCommissions = permissionsMap.get('Deal commissions').get('enabled');
				
				if(!primaryPermission) {
					for(String costField: HomeSearchUtil.entityTypeToCostColumnsMap.get(FilterJsonReturn.Filter_Label__c)) {
						for(Integer i=0; i<DisplayHiddenColumnJson.DisplayedColumns.size(); i++) {
							if(DisplayHiddenColumnJson.DisplayedColumns[i].Label == costField) {
								DisplayHiddenColumnJson.DisplayedColumns.remove(i);
							}
						}
						
						for(Integer i=0; i<DisplayHiddenColumnJson.HiddenColumns.size(); i++) {
							if(DisplayHiddenColumnJson.HiddenColumns[i].Label == costField) {
								DisplayHiddenColumnJson.HiddenColumns.remove(i);
							}
						}
						
						for(Integer i=0; i<SummaryAndExportColumnJson.visible.size(); i++) {
							if(SummaryAndExportColumnJson.visible[i].Label == costField) {
								SummaryAndExportColumnJson.visible.remove(i);
							}
						}
						
						for(Integer i=0; i<SummaryAndExportColumnJson.Hidden.size(); i++) {
							if(SummaryAndExportColumnJson.Hidden[i].Label == costField) {
								SummaryAndExportColumnJson.Hidden.remove(i);
							}
						}
					}
					GenericfilterWrapperObj.DisplayHiddenColumn = System.Json.serialize(DisplayHiddenColumnJson);
					GenericfilterWrapperObj.SummaryFieldsJSON = System.Json.serialize(SummaryAndExportColumnJson);
					GenericfilterWrapperObj.ExportFieldsJSON = GenericfilterWrapperObj.SummaryFieldsJSON;				
				
				} else { 
					if(!modifyPermission && HomeSearchUtil.entityTypeToModifyCostColumnsMap.containsKey(FilterJsonReturn.Filter_Label__c)) {
						for(String costField: (HomeSearchUtil.entityTypeToModifyCostColumnsMap.get(FilterJsonReturn.Filter_Label__c)).keySet()) {
							for(Integer i=0; i<DisplayHiddenColumnJson.DisplayedColumns.size(); i++) {
								if(DisplayHiddenColumnJson.DisplayedColumns[i].Label == costField) {
									DisplayHiddenColumnJson.DisplayedColumns.remove(i);
								} 
							}
							
							for(Integer i=0; i<DisplayHiddenColumnJson.HiddenColumns.size(); i++) {
								if(DisplayHiddenColumnJson.HiddenColumns[i].Label == costField) {
									DisplayHiddenColumnJson.HiddenColumns.remove(i);
								}
							}
							
							for(Integer i=0; i<SummaryAndExportColumnJson.visible.size(); i++) {
								if(SummaryAndExportColumnJson.visible[i].Label == costField) {
									SummaryAndExportColumnJson.visible.remove(i);
								}
							}
							
							for(Integer i=0; i<SummaryAndExportColumnJson.Hidden.size(); i++) {
								if(SummaryAndExportColumnJson.Hidden[i].Label == costField) {
									SummaryAndExportColumnJson.Hidden.remove(i);
								}
							}
						}
						GenericfilterWrapperObj.DisplayHiddenColumn = System.Json.serialize(DisplayHiddenColumnJson);
						GenericfilterWrapperObj.SummaryFieldsJSON = System.Json.serialize(SummaryAndExportColumnJson);
						GenericfilterWrapperObj.ExportFieldsJSON = GenericfilterWrapperObj.SummaryFieldsJSON;
					}
					
					if(!permissionForPartCost && HomeSearchUtil.entityTypeToPartCostColumnsMap.containsKey(FilterJsonReturn.Filter_Label__c)) {
						for(String costField: HomeSearchUtil.entityTypeToPartCostColumnsMap.get(FilterJsonReturn.Filter_Label__c)) {
							for(Integer i=0; i<DisplayHiddenColumnJson.DisplayedColumns.size(); i++) {
								if(DisplayHiddenColumnJson.DisplayedColumns[i].Label == costField) {
									DisplayHiddenColumnJson.DisplayedColumns.remove(i);
								}
							}
							
							for(Integer i=0; i<DisplayHiddenColumnJson.HiddenColumns.size(); i++) {
								if(DisplayHiddenColumnJson.HiddenColumns[i].Label == costField) {
									DisplayHiddenColumnJson.HiddenColumns.remove(i);
								}
							}
							
							for(Integer i=0; i<SummaryAndExportColumnJson.visible.size(); i++) {
								if(SummaryAndExportColumnJson.visible[i].Label == costField) {
									SummaryAndExportColumnJson.visible.remove(i);
								}
							}
							
							for(Integer i=0; i<SummaryAndExportColumnJson.Hidden.size(); i++) {
								if(SummaryAndExportColumnJson.Hidden[i].Label == costField) {
									SummaryAndExportColumnJson.Hidden.remove(i);
								}
							}
						}
						GenericfilterWrapperObj.DisplayHiddenColumn = System.Json.serialize(DisplayHiddenColumnJson);
						GenericfilterWrapperObj.SummaryFieldsJSON = System.Json.serialize(SummaryAndExportColumnJson);
						GenericfilterWrapperObj.ExportFieldsJSON = GenericfilterWrapperObj.SummaryFieldsJSON;
					}
					
					if(!permissionForUnitCost && HomeSearchUtil.entityTypeToUnitCostColumnsMap.containsKey(FilterJsonReturn.Filter_Label__c)) {
						for(String costField: HomeSearchUtil.entityTypeToUnitCostColumnsMap.get(FilterJsonReturn.Filter_Label__c)) {
							for(Integer i=0; i<DisplayHiddenColumnJson.DisplayedColumns.size(); i++) {
								if(DisplayHiddenColumnJson.DisplayedColumns[i].Label == costField) {
									DisplayHiddenColumnJson.DisplayedColumns.remove(i);
								}
							}
							
							for(Integer i=0; i<DisplayHiddenColumnJson.HiddenColumns.size(); i++) {
								if(DisplayHiddenColumnJson.HiddenColumns[i].Label == costField) {
									DisplayHiddenColumnJson.HiddenColumns.remove(i);
								}
							}
							
							for(Integer i=0; i<SummaryAndExportColumnJson.visible.size(); i++) {
								if(SummaryAndExportColumnJson.visible[i].Label == costField) {
									SummaryAndExportColumnJson.visible.remove(i);
								}
							}
							
							for(Integer i=0; i<SummaryAndExportColumnJson.Hidden.size(); i++) {
								if(SummaryAndExportColumnJson.Hidden[i].Label == costField) {
									SummaryAndExportColumnJson.Hidden.remove(i);
								}
							}
						}
						GenericfilterWrapperObj.DisplayHiddenColumn = System.Json.serialize(DisplayHiddenColumnJson);
						GenericfilterWrapperObj.SummaryFieldsJSON = System.Json.serialize(SummaryAndExportColumnJson);
						GenericfilterWrapperObj.ExportFieldsJSON = GenericfilterWrapperObj.SummaryFieldsJSON;
					}

					if(!permissionForDealCommissions) {
						if(filterWrapperObj != null && filterWrapperObj.Type != null && filterWrapperObj.Type.Objects != null && filterWrapperObj.Type.Objects.size() > 0) {
							List<String> objectList = new List<String>(filterWrapperObj.Type.Objects);
							if(HomeSearchUtil.entityTypeToCommissionColumnsMap.containsKey(objectList[0])) {
								for(String commissionField: HomeSearchUtil.entityTypeToCommissionColumnsMap.get(objectList[0])) {
									for(Integer i=0; i<DisplayHiddenColumnJson.DisplayedColumns.size(); i++) {
										if(DisplayHiddenColumnJson.DisplayedColumns[i].Label == commissionField) {
											DisplayHiddenColumnJson.DisplayedColumns.remove(i);
										}
									}
									
									for(Integer i=0; i<DisplayHiddenColumnJson.HiddenColumns.size(); i++) {
										if(DisplayHiddenColumnJson.HiddenColumns[i].Label == commissionField) {
											DisplayHiddenColumnJson.HiddenColumns.remove(i);
										}
									}
									
									for(Integer i=0; i<SummaryAndExportColumnJson.visible.size(); i++) {
										if(SummaryAndExportColumnJson.visible[i].Label == commissionField) {
											SummaryAndExportColumnJson.visible.remove(i);
										}
									}
									
									for(Integer i=0; i<SummaryAndExportColumnJson.Hidden.size(); i++) {
										if(SummaryAndExportColumnJson.Hidden[i].Label == commissionField) {
											SummaryAndExportColumnJson.Hidden.remove(i);
										}
									}
								}
								GenericfilterWrapperObj.DisplayHiddenColumn = System.Json.serialize(DisplayHiddenColumnJson);
								GenericfilterWrapperObj.SummaryFieldsJSON = System.Json.serialize(SummaryAndExportColumnJson);
								GenericfilterWrapperObj.ExportFieldsJSON = GenericfilterWrapperObj.SummaryFieldsJSON;
							}
						}
					}
				}
				
				String locale = GeneralConfiguration.getCompanyLocale();
				if((FilterJsonReturn.Filter_Label__c == 'Invoice Summary' || FilterJsonReturn.Filter_Label__c == 'Recent Customer Invoices') && 
																			(String.isBlank(locale) || locale != 'Australia')) {
					for(Integer i=0; i < DisplayHiddenColumnJson.HiddenColumns.size(); i++) {
						if(DisplayHiddenColumnJson.HiddenColumns[i].Label == 'Stamp Duty Total') {
							DisplayHiddenColumnJson.HiddenColumns.remove(i);
						}
					}
					
					for(Integer i=0; i<SummaryAndExportColumnJson.visible.size(); i++) {
						if(SummaryAndExportColumnJson.visible[i].Label == 'Stamp Duty Total') {
							SummaryAndExportColumnJson.visible.remove(i);
						}
					}
					
					for(Integer i=0; i<SummaryAndExportColumnJson.Hidden.size(); i++) {
						if(SummaryAndExportColumnJson.Hidden[i].Label == 'Stamp Duty Total') {
							SummaryAndExportColumnJson.Hidden.remove(i);
						}
					}
					GenericfilterWrapperObj.DisplayHiddenColumn = System.Json.serialize(DisplayHiddenColumnJson);
					GenericfilterWrapperObj.SummaryFieldsJSON = System.Json.serialize(SummaryAndExportColumnJson);
					GenericfilterWrapperObj.ExportFieldsJSON = GenericfilterWrapperObj.SummaryFieldsJSON;
				}
			}
		}	
        if(FilterJsonReturn.Filter_Label__c == 'Recent Parts' || FilterJsonReturn.Filter_Label__c == 'Part Inventory Aging' || 
	 	             FilterJsonReturn.Filter_Label__c == 'Part Inventory Valuation') {
            List<AdditionalFieldWrapper> AdditionalFieldJsonObj = (List<AdditionalFieldWrapper>) System.JSON.deserialize(GenericfilterWrapperObj.AdditionalFieldJson, List<AdditionalFieldWrapper>.class);
            for(AdditionalFieldWrapper additionalFieldWrapperObj : AdditionalFieldJsonObj) {
                List<String> subStrList = additionalFieldWrapperObj.Label.split(' ');
                if(subStrList.size() > 1 && HomeSearchUtil.agingPeriodsToPeriodValueMap.containsKey(subStrList[0])) {
                    additionalFieldWrapperObj.Label = HomeSearchUtil.agingPeriodsToPeriodValueMap.get(subStrList[0]) + subStrList[1];
                }
            }
            GenericfilterWrapperObj.AdditionalFieldJson = System.Json.serialize(AdditionalFieldJsonObj);
        }
       if((!HomeSearchUtil.getUserPermissions().get('Costs').get('modify')) ) {
        	for(String entityType: HomeSearchUtil.entityTypeToModifyCostColumnsMap.keySet()) {
				if(FilterJsonReturn.Filter_Label__c == entityType) {
					List<AdditionalFieldWrapper> AdditionalFieldJsonObj = (List<AdditionalFieldWrapper>) System.JSON.deserialize(GenericfilterWrapperObj.AdditionalFieldJson, List<AdditionalFieldWrapper>.class);
					for(Integer i=0; i < AdditionalFieldJsonObj.size(); i++) {
						
						List<String> fieldToRemoveList = HomeSearchUtil.entityTypeToModifyCostColumnsMap.get(entityType).values();
						for(String fieldName : fieldToRemoveList) {
							if(AdditionalFieldJsonObj[i].UIFieldKey == fieldName)
							AdditionalFieldJsonObj.remove(i);
						}
					}
				GenericfilterWrapperObj.AdditionalFieldJson = System.Json.serialize(AdditionalFieldJsonObj);
				}
			}
        }
        if((FilterJsonReturn.Filter_Label__c == 'Stock Units' || FilterJsonReturn.Filter_Label__c == 'Stock Unit Valuation') 
        	&& !GeneralConfiguration.getAccrueTradeTaxUntilUnitSold()) {
    		List<AdditionalFieldWrapper> additionalFieldJsonObj = (List<AdditionalFieldWrapper>) System.JSON.deserialize(GenericfilterWrapperObj.AdditionalFieldJson, List<AdditionalFieldWrapper>.class);
    		Integer index = -1;
			for(Integer i = 0; i < additionalFieldJsonObj.size(); i++) {
				if(additionalFieldJsonObj[i].UIFieldKey == 'Inventory_Unit_NITC_Withheld') {
					index = i;
					break;
				}
			}
			if(index != -1)  {
				additionalFieldJsonObj.remove(index);
			}
			GenericfilterWrapperObj.AdditionalFieldJson = System.Json.serialize(additionalFieldJsonObj);
		}
		return BPUtility.getEncodedString(System.Json.serialize(GenericfilterWrapperObj));   
	}
	
	 /**
	 * Name: GenericFilterWrapper
 	 * Description:  Generic Filter WrapperClass return Json Of  Filter Clicked
	 **/
	public class GenericFilterWrapper{
		public String FilterLabel;
		public String FieldFilterJson;
		public Decimal FieldFilterJsonHashCode;
		public String SortJson;
		public String DisplayHiddenColumn;
		public String AdditionalFieldJson;
		public Boolean Favorite;
		public Boolean Custom;
		public Boolean Common;
		
		public String SummaryFieldsJSON;
		public String ExportFieldsJSON;
		public String ExportFileFormat;
		public String ExportGroupField;
		public Boolean IsReportOn;
		
		public List<String> ObjectList;
		public String FilterGenerationDate;
		 
		 /**
		 * Name: GenericFilterWrapper
		 * Description: Constructor
		 * @Param: 1) Filter__c filterRec - Filter Record
		 * @Return: 
		 **/
		public GenericFilterWrapper(Filter__c filterRec) {
			this.FilterLabel =  filterRec.Filter_Label__c;
			this.FieldFilterJson = ((filterRec.Field_Filter_Json__c != null ? filterRec.Field_Filter_Json__c : '' ) 
									+ (filterRec.Field_Filter_Json_2__c  != null ? filterRec.Field_Filter_Json_2__c : ''));
			this.FieldFilterJsonHashCode = filterRec.Field_Filter_JSON_Hash_Code__c;
			this.SortJson=  filterRec.Sort_Json__c;
			this.DisplayHiddenColumn = filterRec.Display_Hidden_Column__c;
			this.AdditionalFieldJson =  filterRec.Additional_Field_Json__c;
			this.Favorite = filterRec.favorite__c;
			this.Custom = filterRec.Custom__c;
			this.Common = filterRec.Common__c;
			
			this.SummaryFieldsJSON =  filterRec.Summary_Field_Json__c;
			this.ExportFieldsJSON =  filterRec.Export_Field_Json__c;
			this.ExportFileFormat =  filterRec.Export_File_Format__c;
			this.ExportGroupField =  filterRec.Export_GroupBy_Field__c;
			this.IsReportOn =  filterRec.Show_All_Records__c;
			this.FilterGenerationDate = BPUtility.getFormatedDateAndTime(system.now());
		}
	} 
	
	 /**
	 * Name: DisplayHiddenColumnWrapper
 	 * Description:  Generic Filter WrapperClass return Json Of  Filter Clicked
	 **/
	public class DisplayHiddenColumnWrapper{
		public List<DisplayedColumnsWrapper> DisplayedColumns;
		public List<DisplayedColumnsWrapper> HiddenColumns;
	} 
	
	/**
	 * Name: SummaryAndExportColumnWrapper
 	 * Description:  Generic Filter WrapperClass return Json Of  Filter Clicked
	 **/
	public class SummaryAndExportColumnWrapper{
		public List<DisplayedColumnsWrapper> visible;
		public List<DisplayedColumnsWrapper> Hidden;
		
	} 
	
	/**
	 * Name: DisplayedColumnsWrapper
 	 * Description:  Generic Filter WrapperClass return Json Of  Filter Clicked
	 **/
	public class DisplayedColumnsWrapper{
		public String RecordKey;
		public String Type;
		public String Label;
		public Boolean IsHidden;
		public Boolean IsDisplayed;
		public String FieldAPIName;
		public Decimal TotalValue;

		public DisplayedColumnsWrapper(){}
		public DisplayedColumnsWrapper(HomeSearch_Grid_Column__mdt gridColumn) {
			this.Label = gridColumn.Label;
			this.Type = gridColumn.Type__c;
			this.IsDisplayed = gridColumn.Is_Display__c;
			this.FieldAPIName = gridColumn.Field_API_Name__c;
			this.IsHidden = !this.IsDisplayed;
			this.RecordKey = this.Label.replace(' ', '_').replace('/', '_');
		}
	} 
	
    public class AdditionalFieldWrapper {
        public String UIFieldKey;
        public Boolean IsDisplayed;
        public String Label;
    }
    
	/**
	 * Name: deleteFilterRecord
	 * Description: Delete the record based on the Id passed
	 * @Param: 		(1) String filterId - filterId Passed to delete The Record from the Front Panel
	 * @Return: String  - Filter List String 
	**/
	@RemoteAction
	global static String deleteFilterRecord(String filterId) {
		filterId = BPUtility.getDecodedString(filterId);
    	
		if(filterId != null){
			if(AccessControl.ifObjectIsDeletable('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
			Filter__c filterRecordToDelete = new Filter__c(Id = filterId);
			delete filterRecordToDelete;
		}
		return BPUtility.getEncodedString(getAllfilterList());
	}
	/**
	 * Name: renameCopyFilterRecord
	 * Description: Rename the copy filter record based On the Id passed
	 * @Param: 	(1) String filterId - filterId Passed to delete The Record from the Front Panel
	 *         	(2) String filterName - filterName passed from front panel
	 *			(3) Boolean Iscopy - Copied Or Not
	 * @Return:  String  - Filter List String 
	**/

	@RemoteAction
	global static String renameCopyFilterRecord(String filterId, String filterName, Boolean Iscopy) {
		filterId = BPUtility.getDecodedString(filterId);
    	filterName = BPUtility.getDecodedString(filterName);
    	filterId = BPUtility.escapeSingleQuotes(filterId);
		if(AccessControl.ifObjectFieldIsCreateable('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }									
		if(AccessControl.ifObjectFieldIsUpdateable('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		if(filterId != null){
			Filter__c filterRecordToRename ;
			if(!Iscopy) {
				filterRecordToRename = new Filter__c(Id = filterId, Filter_Label__c = filterName );	
			} else {
				if(AccessControl.ifObjectFieldIsAccessible('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
				String filterQuery = 'SELECT Id';
				for(String fieldStr : filterObjFieldsList) {
					filterQuery += ', ' + fieldStr;
				}
				filterQuery += ' FROM Filter__c';
				filterQuery += ' WHERE Id =: filterId';
				List<Filter__c> filterList = (List<Filter__c>)Database.query(filterQuery);
				
				if(filterList.size() > 0) {
					filterRecordToRename = filterList[0].clone(false, false, false, false);	
					filterRecordToRename.Filter_Label__c = filterName;
					filterRecordToRename.Custom__c = true;
					filterRecordToRename.Common__c = false;
					filterRecordToRename.Favorite__c = false;
				}
			}
			upsert filterRecordToRename;
		}
		return BPUtility.getEncodedString(getAllfilterList());
	}
	
	/**
	 * Name: markFilterAsFavorite
	 * Description: Mark the record  as favourite based on the Id passed
	 * @Param: 	(1) String filterId - filterId Passed to delete The Record from the Front Panel
	 *			(2) Boolean Favorite - Favorite Or Not
	 * @Return: 
	**/
	@RemoteAction
	global static String markFilterAsFavorite(String filterId , Boolean Favorite) {
		filterId = BPUtility.getDecodedString(filterId);
    	
		if(filterId != null){
			if(AccessControl.ifObjectFieldIsUpdateable('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
			Filter__c filterRecordToChange = new filter__c(Id = filterId, favorite__c= Favorite );
			update filterRecordToChange;
		}
		return BPUtility.getEncodedString(getAllfilterList());
	}
	
	
	/**
	 * Name: getAllfilterList
	 * Description: Function get records for the filter list
	 * @Param: 
	 * @Return: String - Filter List String 
	**/
	public static String getAllfilterList( ){
		if(AccessControl.ifObjectFieldIsAccessible('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		String filterQuery = 'SELECT Id';
		for(String fieldStr : filterObjFieldsList) {
			filterQuery += ', ' + fieldStr;
		}
		filterQuery += ' FROM Filter__c';
		filterQuery += ' WHERE Filter_User__c = \'' + UserInfo.getUserId() + '\'';
		filterQuery += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
		List<Filter__c> listfilter = (List<Filter__c>)Database.query(filterQuery);
		
		HomeSearchAllFilter hsMasterDataRec = new HomeSearchAllFilter(listfilter);
	   	return System.Json.serialize(hsMasterDataRec);                     
	}
	
	
	/**
	 * Name: getSavedFilterList
	 * Description: function return fiter after saving records
	 * @Param: (1) filterId - String - filterId Passed to delete The Record from the Front Panel
	 * @Return: String - Filter JSON String 
	**/
	public static String getSavedFilterList( String  filterId){
		if(AccessControl.ifObjectFieldIsAccessible('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		filterId = BPUtility.escapeSingleQuotes(filterId);
		String filterQuery = 'SELECT Id';
		for(String fieldStr : filterObjFieldsList) {
			filterQuery += ', ' + fieldStr;
		}
		filterQuery += ' FROM Filter__c';
		filterQuery += ' WHERE Filter_User__c = \'' + UserInfo.getUserId() + '\'';
		filterQuery += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
		List<Filter__c> listfilter = (List<Filter__c>)Database.query(filterQuery);
		
		if(AccessControl.ifObjectFieldIsAccessible('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		filterQuery = 'SELECT Id';
		for(String fieldStr : filterObjFieldsList) {
			filterQuery += ', ' + fieldStr;
		}
		filterQuery += ' FROM Filter__c';
		filterQuery += ' WHERE Id=: filterId';
		List<Filter__c> listCurrentFilter = (List<Filter__c>)Database.query(filterQuery);
      
      	Filter__c Currentfilter = listCurrentFilter[0];
                           
       	HomeSearchAllFilter hsMasterDataRec = new HomeSearchAllFilter(listfilter);
       	FilterItem currentFilterRec =new FilterItem(Currentfilter);
       	
       	FilterItemWrapper SavedFilterJson = new FilterItemWrapper(currentFilterRec,hsMasterDataRec);
	  	return BPUtility.getEncodedString(System.Json.serialize(SavedFilterJson));                     
                            
	}
	
	/**
	 * Name: getReportData
	 * Description: Getting report result data for grid filters applied
	 * @Param:	(1) filterJSON - String  - Filter JSON String 
	 * @Return:	String
	 * 
	**/
	@RemoteAction
    global static String getReportData(String filterJSON, String selectedObjName, String uniqueValueFieldLastValue,  String objAPINameToLastValue) {
    	filterJSON = BPUtility.getDecodedString(filterJSON);
    	selectedObjName = BPUtility.getDecodedString(selectedObjName);
		uniqueValueFieldLastValue = BPUtility.getDecodedString(uniqueValueFieldLastValue);
		objAPINameToLastValue = BPUtility.getDecodedString(objAPINameToLastValue);
		Map<String, String> objAPINameToLastValueMap = new Map<String, String>();
		if(objAPINameToLastValue != null) {
			objAPINameToLastValueMap = (Map<String, String>)JSON.deserialize(objAPINameToLastValue, Map<String, String>.class);
		}
    	HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
    	return BPUtility.getEncodedString(HomeSearchReportUtil.getRportingDataByHomeSearchFilters(filterWrapperObj, selectedObjName, uniqueValueFieldLastValue, objAPINameToLastValueMap));
	}

    global static String getReportData(String filterJSON, String selectedObjName, String uniqueValueFieldLastValue) {
    	return '';
	}
    
    @RemoteAction
	global static String getTransactionTypesForPartSale() {
		List<Transaction_Type__c> transactionTypesList = [SELECT Id, Code_Label__c  FROM Transaction_Type__c WHERE Type__c = 'Part Sale' order by Code_Label__c asc];
		List<String> codeLabelList = new List<String>();
		for(Transaction_Type__c transactionType: transactionTypesList) {
			codeLabelList.add(transactionType.Code_Label__c);
		}
		return BPUtility.getEncodedString(system.json.serialize(codeLabelList));       
	}

	// Not in use now
	@RemoteAction
	global static String isReportSchedulable(String filterId) { return ''; }

	@RemoteAction
	global static String scheduleReport(String scheduleReportJson) {
		return BPUtility.getEncodedString(HSReportSchedulingService.scheduleReport(BPUtility.getDecodedString(scheduleReportJson)));
	}

	@RemoteAction
	global static String deleteScheduledReport(String filterId) {
		return BPUtility.getEncodedString(HSReportSchedulingService.deleteScheduledReport(BPUtility.getDecodedString(filterId)));
	}

	/**
	 * Name: getDataForPartWithNoActivity
	 * Description: Getting report result data for grid filters applied
	 * @Param:	(1) filterJSON - String  - Filter JSON String 
	 * @Return:	String
	 * 
	**/
	@RemoteAction
	@readOnly
    global static String getDataForPartWithNoActivity(String partFoundIdSet, String filterJSON) {
    	partFoundIdSet = BPUtility.getDecodedString(partFoundIdSet);
    	filterJSON = BPUtility.getDecodedString(filterJSON);
    	
    	Set<String> partWithNOActivityIDSet = (Set<String>)system.json.deserialize(partFoundIdSet, Set<String>.class);
    	
    	HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
    	DateTime dtValue;
    	String dateStr;
    	Decimal totalPartFound = 0;
    	
    	if(HomeSearchResultWrapper.validatePartFIFO(new HomeSearchResultWrapper.PartMovement(), filterWrapperObj)) {
	    	if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '1') {
	            dateStr = 'TODAY';
	        } else if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '2') {
	            dateStr = 'YESTERDAY';
	        } else if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '3') {
	            dateStr = 'LAST_N_DAYS:7';
	        } else if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '4') {
	            dateStr = 'LAST_N_DAYS:30';
	        } else if(filterWrapperObj.Part_FIFO_Date.SelectedOption == '5' && filterWrapperObj.Part_FIFO_Date.Value1 != null) {
	    		dtValue = HomeSearchFilterInterface.getDateFromString(filterWrapperObj.Part_FIFO_Date.Value1);
	    	}
			Map<String, List<HomeSearchFilterInterface.FieldFilter>> objectFiltersMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
	    	
	    	String whereClause = '';
	    	if(String.isNotBlank(filterWrapperObj.Part_FIFO_Category) && filterWrapperObj.Part_FIFO_Category != '0') {
	            whereClause += ' AND Category__c = \'' + BPUtility.escapeSingleQuotes(filterWrapperObj.Part_FIFO_Category) + '\'';
	        }
	        if(String.isNotBlank(filterWrapperObj.Part_FIFO_Part_Type) && filterWrapperObj.Part_FIFO_Part_Type != '0') {
	            whereClause += ' AND Part_Type__c LIKE \'' + BPUtility.escapeSingleQuotes(filterWrapperObj.Part_FIFO_Part_Type) + '%\'';
	        }
	        if(String.isNotBlank(filterWrapperObj.Part_FIFO_Vendor)) {
	            whereClause += ' AND Vendor__r.Name LIKE \'' + BPUtility.escapeSingleQuotes(filterWrapperObj.Part_FIFO_Vendor) + '%\'';
	        }
	        
	    	String query = 'SELECT (SELECT Qty_In_Stock_When_Created__c, Average_Cost_When_Created__c, CreatedDate, Qty_In__c, Cost__c ' +  
	 				 'FROM Part_FIFO_Buckets__r ' + 
	 				 'WHERE ' + (dtValue != null ? 'CreatedDate <: dtValue ' : ('CreatedDate < ' + dateStr)) + ' AND Is_FIFO_Bucket__c = true order BY CreatedDate desc limit 1), ' + 
	 				 '(SELECT Qty_In_Stock_When_Created__c, Average_Cost_When_Created__c, CreatedDate, Qty_Out__c, Part_FIFO_Bucket__r.Cost__c ' +  
		 				 'FROM Part_FIFO_Bucket_Activity_Line_Items__r ' + 
		 				 'WHERE ' + (dtValue != null ? 'CreatedDate <: dtValue ' : ('CreatedDate < ' + dateStr)) + ' AND Part_FIFO_Bucket__r.Is_FIFO_Bucket__c = true order BY CreatedDate desc, Part_FIFO_Bucket__r.CreatedDate DESC limit 1) ' +   
	 				 'FROM Part__c ' + 
	 				 'WHERE ' + (dtValue != null ? 'CreatedDate <: dtValue ' : ('CreatedDate < ' + dateStr)) + ' AND Id NOT IN: partWithNOActivityIDSet ' + (whereClause.length() > 0 ? whereClause : '');
	    	
	    	for(Part__c partRec : Database.query(query)) {
	    		if(getDetailsForPartNoFound(partRec)) {
	    			totalPartFound++;
	    		}
	    	}
	    	partWithNOActivityIDSet.clear();
    	}
    	return BPUtility.getEncodedString(system.json.serialize(new List<decimal>{totalOpeningQty, totalOpeningCost, totalPartFound}));
	}

	@RemoteAction
    global static String getSpecificDateRangeInvoiceIds(String filterJSON) {
    	return BPUtility.getEncodedString(System.Json.serialize(InvoiceDetailReportService.getSpecificDateRangeInvoiceIds(BPUtility.getDecodedString(filterJSON))));
	}

	@RemoteAction
	global static String getSharedFilters() {
		List<Filter__c> sharedFilterList = HomeSearchUtil.getSharedFiltersForUser(UserInfo.getUserId());
		sharedFilterList = getFilterListBasedOnUserPermissions(sharedFilterList);
		return BPUtility.getEncodedString(System.Json.serialize(new HomeSearchAllFilter(sharedFilterList)));
	}

	@RemoteAction
    global static String getUserList() {
    	return BPUtility.getEncodedString(System.Json.serialize(UserService.getUserListWithSharedFilters(new List<String>{UserInfo.getUserId()})));
	}

	@RemoteAction
    global static void shareFilterWithUsers(String filterId, String userIdsJson) {
		HomeSearchUtil.shareFilterWithUsers(BPUtility.getDecodedString(filterId), (Set<String>)System.JSON.deserialize(BPUtility.getDecodedString(userIdsJson), Set<String>.class));
	}

	@RemoteAction
    global static void deleteSharedReport(String filterId) {
		HomeSearchUtil.deleteSharedReport(BPUtility.getDecodedString(filterId), UserInfo.getUserId());
	}
	
	private static Decimal totalOpeningQty = 0;
	private static Decimal totalOpeningCost = 0;
	private static Boolean getDetailsForPartNoFound(Part__c partRec) {
		Decimal qty = 0;
		if(partRec.Part_FIFO_Bucket_Activity_Line_Items__r.size() > 0 && partRec.Part_FIFO_Buckets__r.size() > 0 && partRec.Part_FIFO_Buckets__r[0].CreatedDate < partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].CreatedDate) {
			partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c != null ? partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c : 0);
			partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c != null ? partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c : 0);
			partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Average_Cost_When_Created__c = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Average_Cost_When_Created__c != null ? partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Average_Cost_When_Created__c : 0);
			Decimal bucketLICost = (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Part_FIFO_Bucket__c != null && partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Part_FIFO_Bucket__r.Cost__c != null ? partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Part_FIFO_Bucket__r.Cost__c : 0);
			
			qty = partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c - partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c;
			totalOpeningCost += (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_In_Stock_When_Created__c * partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Average_Cost_When_Created__c) - 
								  (partRec.Part_FIFO_Bucket_Activity_Line_Items__r[0].Qty_Out__c * bucketLICost) ;
		} else if(partRec.Part_FIFO_Buckets__r.size() > 0) {
			partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c = (partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c != null ? partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c : 0);
			partRec.Part_FIFO_Buckets__r[0].Qty_In__c = (partRec.Part_FIFO_Buckets__r[0].Qty_In__c != null ? partRec.Part_FIFO_Buckets__r[0].Qty_In__c : 0);
			partRec.Part_FIFO_Buckets__r[0].Average_Cost_When_Created__c = (partRec.Part_FIFO_Buckets__r[0].Average_Cost_When_Created__c != null ? partRec.Part_FIFO_Buckets__r[0].Average_Cost_When_Created__c : 0);
			partRec.Part_FIFO_Buckets__r[0].Cost__c = (partRec.Part_FIFO_Buckets__r[0].Cost__c != null ? partRec.Part_FIFO_Buckets__r[0].Cost__c : 0);
			
			qty =  partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c + partRec.Part_FIFO_Buckets__r[0].Qty_In__c;
			totalOpeningCost += partRec.Part_FIFO_Buckets__r[0].Qty_In_Stock_When_Created__c * partRec.Part_FIFO_Buckets__r[0].Average_Cost_When_Created__c + 
						  partRec.Part_FIFO_Buckets__r[0].Qty_In__c * partRec.Part_FIFO_Buckets__r[0].Cost__c ;
		}
		totalOpeningQty += qty;
		return (qty != 0) ? true : false;
	}
	
	 /**
	 * Name: FilterItem
	 * Description: Current filter record Wrapper Class
	 **/
	public class FilterItem{
		public String Id;
		public String Name;
		public String Type;
		
		public String GridDisplayHiddenColumnsJSON;
		public String SummaryDisplayHiddenColumnsJSON;
		public String ExportDisplayHiddenColumnsJSON;
		
		/**
		 * Name: FilterItem
		 * Description: Constructor
		 * @Param: (1) currentfilter - Filter__c - Filter Record
		 * @Return:  
		**/
		public FilterItem( Filter__c currentfilter) {
			this.Id = currentfilter.Id;
			this.Name = currentfilter.Filter_Label__c;
			this.GridDisplayHiddenColumnsJSON = currentfilter.Display_Hidden_Column__c;
			this.SummaryDisplayHiddenColumnsJSON = currentfilter.Summary_Field_Json__c;
			this.ExportDisplayHiddenColumnsJSON = currentfilter.Export_Field_Json__c;
			
			if(currentfilter.favorite__c) {
				this.Type = 'favorite';
			} else if(currentfilter.Common__c) {
				this.Type = 'Common';
			} else if(currentfilter.Custom__c){
				this.Type = 'Custom';
			}
		}
	}
	
	/**
	 * Name: FilterItemWrapper
	 * Description:  Wrapper Class to get current filter and list of all filter
	**/
	public class FilterItemWrapper {
		public FilterItem CurrentFilter;
		public HomeSearchAllFilter AllFilterJSON;
		
		public FilterItemWrapper(FilterItem currentFilter,HomeSearchAllFilter allFilterJSON ) {
			this.CurrentFilter =currentFilter;
			this.AllFilterJSON =allFilterJSON;
		}
		
	}
	
	/**
	 * Name: HomeSearchMasterData
	 * Description:  Wrapper Class Home Search Master Data
	**/
	public class HomeSearchMasterData {
		  
		public List<String> ObjectList;
		public HomeSearchFilterWrapper FilterFormJSON;
		public HomeSearchAllFilter AllFilterJSON; 
		public Boolean IsReportOn;
		public Map<String, String> ObjectLabelToObjectDisplayNameMap;
		public String PartAgingPRD1 {get{return GeneralConfiguration.getPartAgingPeriod1();} set;}
 		public String PartAgingPRD2 {get{return GeneralConfiguration.getPartAgingPeriod2();} set;}
 		public String PartAgingPRD3 {get{return GeneralConfiguration.getPartAgingPeriod3();} set;}
		public List<GeneralConfiguration.UnitDataFieldConfigWrapper> UnitDataFieldConfigObjList;
		
		/**
		 * Name: HomeSearchMasterData
		 * Description: Constructor
		 * @Param: 	(1) objects - List<String> - object list string
		 *			(2) hsFilterWrapperRec - HomeSearchFilterWrapper - HomeSearchFilterWrapper Record
		 *			(3) allfilterJsonObj - HomeSearchAllFilter - HomeSearchAllFilter Record
		 * @Return:  
		**/
		public HomeSearchMasterData(List<String> objects, HomeSearchFilterWrapper hsFilterWrapperRec, HomeSearchAllFilter allfilterJsonObj, Boolean IsReportOn, Map<String, String> objectLabelToDisplayNameMap) {
			this.ObjectList = new List<String>();
			this.ObjectList.addAll(objects);
			this.AllFilterJSON = allfilterJsonObj;
			this.FilterFormJSON = hsFilterWrapperRec;
			this.IsReportOn = IsReportOn;			
			this.ObjectLabelToObjectDisplayNameMap = objectLabelToDisplayNameMap;
			this.UnitDataFieldConfigObjList = GeneralConfiguration.getUnitDataFieldsConfig();
		}
	}
}