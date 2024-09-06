public without sharing class GenericSearchCtrl {
    
    public static String getSearchResults(String searchQueryJsonStr) {
        searchQueryJsonStr = BPUtility.getDecodedString(searchQueryJsonStr);
        GenericSearchUtil.QueryJSON searchObj = (GenericSearchUtil.QueryJSON) system.JSON.deserialize(searchQueryJsonStr, GenericSearchUtil.QueryJSON.class);
        
        // Get Configurations for Searching
        List<Search_Configuration__mdt> searchConfigList = getSearchConfigurations(searchObj.SearchableObjects, (searchObj.IsSpecialSearch != null ? searchObj.IsSpecialSearch : false));
        
        Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap = new Map<String, Search_Configuration__mdt>();
        for(Search_Configuration__mdt searchConfigRec : searchConfigList) {
            objNameToSearchConfigRecMap.put(searchConfigRec.Label, searchConfigRec);
        }
        
        Map<String, List<Sobject>> objNameToSearchRecordListMap = 
                    getSearchingRecord(searchObj.ObjectLabel, searchObj.SearchText, searchObj.FilterValues, searchConfigList);
        
        // Apply sorting
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = 
                    GenericSearchSorting.sortSearchedResults(objNameToSearchRecordListMap, searchObj.SearchText, objNameToSearchConfigRecMap);
        //system.assert(false, searchedResultsToSortList.size());
        // Create Return JSON
        String searchJSONString = createJSON(searchedResultsToSortList, objNameToSearchConfigRecMap);
        return searchJSONString;
    }
    
    public static List<GenericSearchUtil.SearchedSObjectWrapper> getGobalSearchResults(GenericSearchUtil.QueryJSON searchObj, String keyWordName) {
        // Get Configurations for Searching
        List<Search_Configuration__mdt> searchConfigList = getSearchConfigurations(searchObj.SearchableObjects, false);
        
        Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap = new Map<String, Search_Configuration__mdt>();
        for(Search_Configuration__mdt searchConfigRec : searchConfigList) {
            objNameToSearchConfigRecMap.put(searchConfigRec.Label, searchConfigRec);
        }
        
        Map<String, List<Sobject>> objNameToSearchRecordListMap = 
                    getSearchingRecord(searchObj.ObjectLabel, searchObj.SearchText, searchObj.FilterValues, searchConfigList);
        List<SObject> vendorRecordsList = new List<SObject>();
        if(objNameToSearchRecordListMap.containsKey('Account')) {
        	List<SObject> accountRecordsList = objNameToSearchRecordListMap.get('Account');
        	for(Integer counter = 0; counter < accountRecordsList.size(); counter++) {
	            if((String.valueOf(accountRecordsList[counter].get(Constants.NAMESPACE +'Is_Customer__c')) == 'true') &&
	                         (String.valueOf(accountRecordsList[counter].get(Constants.NAMESPACE +'Is_Vendor__c')) == 'true')) {
	                         	
	                if(String.isNotBlank(keyWordName)) {
	                	if(keyWordName == 'Customers') {
	                		accountRecordsList[counter].put(Constants.NAMESPACE +'Is_Vendor__c', false);
	                	} else if(keyWordName == 'Vendors') {
	                		accountRecordsList[counter].put(Constants.NAMESPACE +'Is_Customer__c', false);
	                	}
	                } else {
	                	SObject vendor = accountRecordsList[counter].clone(true, true);
		                vendor.put(Constants.NAMESPACE +'Is_Customer__c', false);
		                vendorRecordsList.add(vendor);
		                accountRecordsList[counter].put(Constants.NAMESPACE +'Is_Vendor__c', false);
	                }
	            }
	        }
	        accountRecordsList.addAll(vendorRecordsList);
	        objNameToSearchRecordListMap.put('Account', accountRecordsList);
        }
        // Apply sorting
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = 
                    GenericSearchSorting.sortSearchedResults(objNameToSearchRecordListMap, searchObj.SearchText, objNameToSearchConfigRecMap);
        //system.assert(false, searchedResultsToSortList.size());
        return searchedResultsToSortList;
    }
    
    private static Set<String> searchConfigFieldSet = new Set<String> {'Searchable_Field_Set__c',
                                                                         'Order__c',
                                                                         'Label',
                                                                         'Additional_Fields_To_Query__c',
                                                                         'Display_Field_Name__c',
                                                                         'Additional_Info_To_Display__c',
                                                                         'Fixed_Where_Clause__c'
                                                                        };
                                                                        
    private static List<Search_Configuration__mdt> getSearchConfigurations(String searchableObjects, Boolean isSpecialSearch) {
        List<String> objectList = new List<String>();
        if(searchableObjects != null && searchableObjects.trim().length() > 0){
            for(String objName : searchableObjects.split(',')) {
                objectList.add(GenericSearchUtil.getObjectAPIName(objName));
            }
        }
        
        String configQuery = 'SELECT ';
        for(String searchableField : searchConfigFieldSet) {
            configQuery += searchableField + ',';
        }
        configQuery = configQuery.subString(0, configQuery.length() - 1);
        configQuery += ' FROM Search_Configuration__mdt WHERE Enable_Search__c = TRUE ';
        if(objectList.size() > 0) {
            configQuery += + 'AND Label IN: objectList';
        }
        if(!isSpecialSearch) {
        	if(configQuery.contains('WHERE')) {
            	configQuery += ' AND Is_Special_Search__c = false';
        	} else {
        		configQuery += ' WHERE Is_Special_Search__c = false';
        	}
        }
        return Database.query(configQuery);
    }
    
    public static Map<String, List<Sobject>> getSearchingRecord(String objectName, String searchText, List<GenericSearchUtil.FilterJSON> filterValues, List<Search_Configuration__mdt> searchConfigList) {
        Map<String, List<Sobject>> objNameToSearchRecordListMap = new Map<String, List<Sobject>>();
        searchText = (searchText != null) ? searchText : '';
        //searchText = SOSLUtil.formatTextValueToBeSearched(searchText);
        searchText = String.escapeSingleQuotes(searchText);
        String query = '';
        
        for(Search_Configuration__mdt searchConfig : searchConfigList) {
        	List<sObject> resultRecords = new List<sObject>();
            if(searchConfig.Label == 'Account') {
            	query = getSOQLQuery(searchConfig, searchText, filterValues, true);
            	resultRecords = (List<sObject>)Database.query(query);
            	Set<Id> recordIds = getSearchedRecordIds(resultRecords);
            	if(resultRecords.size() < 5) {
            		query = getSOQLQuery(searchConfig, searchText, filterValues, false, recordIds);
            		resultRecords.addAll((List<sObject>)Database.query(query));
            	}
            } else {
            	query = getSOQLQuery(searchConfig, searchText, filterValues, false);
            	resultRecords = (List<sObject>)Database.query(query);
            }
            objNameToSearchRecordListMap.put(searchConfig.Label, resultRecords);
        }
        
        return objNameToSearchRecordListMap;
    }
    
    private static String getSOQLQuery(Search_Configuration__mdt searchConfig, String searchText, List<GenericSearchUtil.FilterJSON> filterList, 
    									Boolean isStartsWithSearch) {
    	return getSOQLQuery(searchConfig, searchText, filterList, isStartsWithSearch, new Set<Id>());			
	}
    
    private static String getSOQLQuery(Search_Configuration__mdt searchConfig, String searchText, List<GenericSearchUtil.FilterJSON> filterList, 
    									Boolean isStartsWithSearch, Set<Id> recordIds) {
        String objectAPIName = GenericSearchUtil.getObjectAPIName(searchConfig.Label);
        String query = 'SELECT ';
        if(String.isNotBlank(searchConfig.Searchable_Field_Set__c)) {
            query += searchConfig.Searchable_Field_Set__c + ',';
        }
        if(String.isNotBlank(searchConfig.Additional_Fields_To_Query__c)) {
            query += searchConfig.Additional_Fields_To_Query__c + ',';
        }
        query = query.subString(0, query.length() - 1);
        query += ' FROM ' + objectAPIName;
    	query += getWhereClause(searchText, searchConfig, filterList, objectAPIName, isStartsWithSearch);
        if(recordIds.size() > 0) {
        	query += ' AND Id NOT IN: recordIds' ;
        }
        query += ' ORDER BY LastModifiedDate DESC ';
        query += ' LIMIT ' + (GenericSearchUtil.limitedRecordsObjectSet.contains(objectAPIName) ? 
        						GenericSearchUtil.MAX_RECORD_FOR_SPECIAL_OBJECTS : SOQLUtil.getAvailableQueryRowsLimit());
        return query;
    }
    
    private static Set<Id> getSearchedRecordIds(List<sObject> sObjectList) {
    	Set<Id> recordIds = new Set<Id>();
    	for(sObject sobj : sObjectList) {
    		recordIds.add(sObj.Id);
    	}
    	return recordIds;
    }
    
    public static String getWhereClause(String searchText, Search_Configuration__mdt searchConfig, List<GenericSearchUtil.FilterJSON> filterList,	
    										String objectAPIName, Boolean isStartsWithSearch) {
        String whereClause = getFilterClause(searchText, searchConfig.Fixed_Where_Clause__c, filterList, searchConfig.Label);
        String containsClause = getContainsClause(searchText, searchConfig, objectAPIName, isStartsWithSearch);
        
        if(String.isNotBlank(whereClause) && String.isNotBlank(containsClause)) {
            whereClause = whereClause + ' AND ' + containsClause;
        } else if(String.isBlank(whereClause) && String.isNotBlank(containsClause)) {
            whereClause = ' WHERE ' + containsClause;
        }
        return whereClause;
    }
    
    public static String getFilterClause(String searchText, String fixedWhereClause, List<GenericSearchUtil.FilterJSON> filterList, String objName) {
        String whereClause = '';
        for(GenericSearchUtil.FilterJSON fieldFilter : filterList) {
            if(fieldFilter.FilterObject.equalsIgnoreCase(objName)) {
	            whereClause += (String.isBlank(whereClause)) ? ' WHERE ' : ' AND ';
	            if(fieldFilter.Field != null && fieldFilter.Field.trim().length() > 0) {
	                String filterFieldName = fieldFilter.Field;
	                whereClause += (fieldFilter.Field + ' ' + fieldFilter.Operator + ' ' + fieldFilter.Value);
	            } else {
	                whereClause += fieldFilter.Value;
	            }
            }
        }
        whereClause += (String.isNotBlank(fixedWhereClause)) ? ((whereClause.contains('WHERE')) ? ' AND ' : ' WHERE ') + fixedWhereClause : '';
        
        return whereClause;
    }
    
    public static String getContainsClause(String searchText, Search_Configuration__mdt searchConfig, String objectAPIName, 
    										Boolean isStartsWithOnly) {
        List<GenericSearchUtil.FieldFilter> fieldFilterList = new List<GenericSearchUtil.FieldFilter>();
        
        if(String.isNotBlank(searchText)) {
            List<String> searchTextList = searchText.split(' ');
            List<String> textFieldsList = new List<String>();
            if(String.isNotBlank(searchConfig.Searchable_Field_Set__c)) {
                textFieldsList.addAll(searchConfig.Searchable_Field_Set__c.split(','));
            }
            for(String searchTextSubStr : searchTextList) {
                if(searchTextSubStr.length() >= GenericSearchUtil.MIN_SEARCH_CHAR_TO_SEARCH) {
		            for(String textFieldStr : textFieldsList) {
		            	if(objectAPIName == 'Part__c') {
		            		if(textFieldStr == 'Description__c') {
                        		fieldFilterList.add(new GenericSearchUtil.FieldFilter(textFieldStr, 'Like', '\'%' + searchText + '%\''));
                        	} else {
                            	fieldFilterList.add(new GenericSearchUtil.FieldFilter(textFieldStr, 'Like', '\'' + searchText + '%\''));
                        	}
		            	} else {
		            		if(isStartsWithOnly) {
		            			fieldFilterList.add(new GenericSearchUtil.FieldFilter(textFieldStr, 'Like', '\'' + searchText + '%\''));
		            		} else {
		            			fieldFilterList.add(new GenericSearchUtil.FieldFilter(textFieldStr, 'Like', '\'%' + searchTextSubStr + '%\''));
		            		}
		            	}
		            }
		            if(objectAPIName == 'Part__c' || isStartsWithOnly) {
	                	break;
	                }
                }
            }
        }
        
        String containsClause = '( ';
        for(GenericSearchUtil.FieldFilter fieldFilterRec : fieldFilterList) {
            containsClause += fieldFilterRec.FieldName + ' ' + fieldFilterRec.Operator + ' ' + fieldFilterRec.FieldValue + ' OR ';
        }
        if(fieldFilterList.size() == 0 || containsClause.length() <= 2) {
            containsClause = '';
        } else {
            containsClause = containsClause.substring(0, containsClause.length() - 3);
            containsClause += ')';
        }
        return containsClause;
    }
    
    public static String createJSON(List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList, Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap) {
        List<GenericSearchResultsWrapper> suggestionRecords = new List<GenericSearchResultsWrapper>();
        List<CountSessionLineItemWrapper.CountSessionLineItem> countSessionLineItemSuggestionRecords = new List<CountSessionLineItemWrapper.CountSessionLineItem>();
        
        Integer counter = 0;
        if(searchedResultsToSortList.size() > 0) {
            for(GenericSearchUtil.SearchedSObjectWrapper resultWrapperRecord : searchedResultsToSortList) {
            	if(resultWrapperRecord.objectName == 'Count_Session_Line_Item__c') {
            		countSessionLineItemSuggestionRecords.add(
            						new CountSessionLineItemWrapper.CountSessionLineItem((Count_Session_Line_Item__c)resultWrapperRecord.SearchedObj));
            	} else {
            	if(resultWrapperRecord.objectName == 'Service_Order_Header__c' && (((List<Event__c>) resultWrapperRecord.SearchedObj.getSobjects('Events__r')) != null && 
            		(((List<Event__c>) resultWrapperRecord.SearchedObj.getSobjects('Events__r')).size() > 0))) {
            		continue;
            	}
                
                suggestionRecords.add(new GenericSearchResultsWrapper(resultWrapperRecord, objNameToSearchConfigRecMap.get(resultWrapperRecord.objectName)));
	                }
                counter++;
                if(counter == GenericSearchUtil.MAX_RECORDS_TO_DISPLAY) {
                    break;
                }
            }
        }
        if(objNameToSearchConfigRecMap.containsKey('Count_Session_Line_Item__c')){
        	return system.JSON.serialize(countSessionLineItemSuggestionRecords, true);
        }
        return system.JSON.serialize(suggestionRecords, true);
    }
}