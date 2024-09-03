public without sharing class GenericSearchCtrl {

    private static String PERFORM_SOSL = 'Perform SOSL';
    private static Boolean isSOSLEnabled = isSOSLEnabled();
    private static Boolean isGlobalSearch = false;
    private static String namespace;
    private static Boolean isUpdateSTAJSON = false;
    private static final String EXACT_MATCH = 'Exact';

    private static Set<String> searchConfigFieldSet = new Set<String> {'Searchable_Field_Set__c',
                                                                         'Order__c',
                                                                         'Label',
                                                                         'Additional_Fields_To_Query__c',
                                                                         'Display_Field_Name__c',
                                                                         'Additional_Info_To_Display__c',
                                                                         'Fixed_Where_Clause__c',
                                                                         'DeveloperName'
                                                                        };

    private static Boolean isSOSLEnabled() {
        String performSOSLStr = GeneralConfiguration.getConfigurationByName(PERFORM_SOSL);
        return String.isNotBlank(performSOSLStr) ? Boolean.valueOf(performSOSLStr) : false;
    }
    
    public static String getSearchResults(String searchQueryJsonStr) {
        searchQueryJsonStr = BPUtility.getDecodedString(searchQueryJsonStr);
        GenericSearchUtil.QueryJSON searchObj = (GenericSearchUtil.QueryJSON) system.JSON.deserialize(searchQueryJsonStr, GenericSearchUtil.QueryJSON.class);
        
        if(searchObj.FromIndex != null && searchObj.ToIndex != null) {
            isUpdateSTAJSON = true;
        }
        searchObj.FromIndex = searchObj.FromIndex != null ? searchObj.FromIndex : 0;
        searchObj.ToIndex = searchObj.ToIndex != null ? searchObj.ToIndex : GenericSearchUtil.MAX_RECORDS_TO_DISPLAY;
        
        // get object list to search
        List<String> objectList = getObjectListToSearch(searchObj.SearchableObjects);
        
        // Get Configurations for Searching
        Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap = getObjNameToSearchConfigMdtMap(objectList, (searchObj.IsSpecialSearch != null ? searchObj.IsSpecialSearch : false), searchObj.SearchConfigNames);
        
        // Perform search
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = performSearch(searchObj, objectList, objNameToSearchConfigRecMap, null);
        
        // Create Return JSON
        return createJSON(searchedResultsToSortList, objNameToSearchConfigRecMap, searchObj);
    }

    public static String getSearchSuggestionJSON(String searchQueryJsonStr) {
        searchQueryJsonStr = BPUtility.getDecodedString(searchQueryJsonStr);
        GenericSearchUtil.QueryJSON searchObj = (GenericSearchUtil.QueryJSON) system.JSON.deserialize(searchQueryJsonStr, GenericSearchUtil.QueryJSON.class);
        
        // get object list to search
        List<String> objectList = getObjectListToSearch(searchObj.SearchableObjects);

        // Get Configurations for Searching
        Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap = getObjNameToSearchConfigMdtMap(objectList, (searchObj.IsSpecialSearch != null ? searchObj.IsSpecialSearch : false), searchObj.SearchConfigNames);
        
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = performSearch(searchObj, objectList, objNameToSearchConfigRecMap, null);
        
        // Create Return JSON
        return SearchSuggestionUtil.createJSON(searchedResultsToSortList, searchObj);
    }
    
    public static List<GenericSearchUtil.SearchedSObjectWrapper> getGobalSearchResults(GenericSearchUtil.QueryJSON searchObj, String keyWordName) {
        isGlobalSearch = true;
        // get object list to search
        List<String> objectList = getObjectListToSearch(searchObj.SearchableObjects);
        
        // Get Configurations for Searching
        Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap = getObjNameToSearchConfigMdtMap(objectList, false, null);
        
        // Perform search
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = performSearch(searchObj, objectList, objNameToSearchConfigRecMap, keyWordName);
        return searchedResultsToSortList;
    }

    private static List<GenericSearchUtil.SearchedSObjectWrapper> performSearch(GenericSearchUtil.QueryJSON searchObj, List<String> objectList, Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap, String keyWordName) {
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = new List<GenericSearchUtil.SearchedSObjectWrapper>();
        String soslOnlySearch = GeneralConfiguration.getConfigurationByName(GeneralConfiguration.SOSL_SEARCH_ONLY);
        Boolean isSOSLOnlySearch = (String.isNotBlank(soslOnlySearch) && soslOnlySearch.equalsIgnoreCase('true'));
        if(isSOSLEnabled || isSOSLOnlySearch) {
            namespace = GeneralConfiguration.getNamespace();
            List<String> objectListForSOSLSearch = new List<String>();
            List<String> objectListForSOQLSearch = new List<String>();
            for(String objName : objectList) {
                if((isSOSLOnlySearch && GenericSearchUtil.objectNameToSOSLSearchableFieldsNameListMap.keySet().contains(objName)) || (!isSOSLOnlySearch && GenericSearchUtil.objectNameToSOSLSearchableFieldsNameListMap.keySet().contains(objName))) {
                    objectListForSOSLSearch.add(objName);
                } else {
                    objectListForSOQLSearch.add(objName);
                }
            }
            if(objectListForSOQLSearch.size() > 0) {
                searchedResultsToSortList = performSOQLSearch(searchObj, objectListForSOQLSearch, objNameToSearchConfigRecMap, keyWordName);
            }
            if(objectListForSOSLSearch.size() > 0) {
                searchedResultsToSortList.addAll(performSOSLSearch(searchObj, objectListForSOSLSearch, objNameToSearchConfigRecMap));
            }
        } else {
            searchedResultsToSortList = performSOQLSearch(searchObj, objectList, objNameToSearchConfigRecMap, keyWordName);
        }

        // apply sorting
        searchedResultsToSortList.sort();
        return searchedResultsToSortList;
    }
    
    private static List<String> getObjectListToSearch(String searchableObjects) {
        List<String> objectList = new List<String>();
        if(searchableObjects != null && searchableObjects.trim().length() > 0){
            for(String objName : searchableObjects.split(',')) {
                objectList.add(GenericSearchUtil.getObjectAPIName(objName));
            }
        }
        return objectList;
    }

    private static Map<String, Search_Configuration__mdt> getObjNameToSearchConfigMdtMap(List<String> objectList, Boolean isSpecialSearch, String searchConfigNames) {
        List<String> searchConfigNameList = new List<String>();
        if(searchConfigNames != null && searchConfigNames.trim().length() > 0){
            for(String objName : searchConfigNames.split(',')) {
                searchConfigNameList.add(objName);
            }
        }

        Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap = new Map<String, Search_Configuration__mdt>();
        List<Search_Configuration__mdt> searchConfigList = getSearchConfigurations(objectList, (isSpecialSearch != null ? isSpecialSearch : false), searchConfigNameList);
        for(Search_Configuration__mdt searchConfigRec : searchConfigList) {
            objNameToSearchConfigRecMap.put(searchConfigRec.Label, searchConfigRec);
            if(searchConfigNameList.contains(searchConfigRec.DeveloperName)) {
                objectList.add(searchConfigRec.Label);
            }
        }
        return objNameToSearchConfigRecMap;
    }

    private static List<GenericSearchUtil.SearchedSObjectWrapper> performSOQLSearch(GenericSearchUtil.QueryJSON searchObj, List<String> objectList, Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap, String keyWordName) {
        Map<String, List<Sobject>> objNameToSearchRecordListMap = 
                    getSearchingRecord(objectList, searchObj.SearchText, searchObj.FilterValues, objNameToSearchConfigRecMap);
        
        if(isGlobalSearch && String.isNotBlank(keyWordName)) {
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
        }

        // Prepare data for sorting searched records
        return GenericSearchSorting.prepareDataForSorting(objNameToSearchRecordListMap, searchObj.SearchText, objNameToSearchConfigRecMap);
    }

    private static List<Search_Configuration__mdt> getSearchConfigurations(List<String> objectList, Boolean isSpecialSearch, List<String> SearchConfigNameList) {
        String configQuery = 'SELECT ';
        for(String searchableField : searchConfigFieldSet) {
            configQuery += searchableField + ',';
        }
        configQuery = configQuery.subString(0, configQuery.length() - 1);
        configQuery += ' FROM Search_Configuration__mdt WHERE Enable_Search__c = TRUE ';
        if(!SearchConfigNameList.isEmpty()) {
            configQuery += ' AND DeveloperName IN: SearchConfigNameList';
        } else if(objectList.size() > 0) {
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
    
    public static Map<String, List<Sobject>> getSearchingRecord(List<String> objectList, String searchText, List<GenericSearchUtil.FilterJSON> filterValues, Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap) {
        Map<String, List<Sobject>> objNameToSearchRecordListMap = new Map<String, List<Sobject>>();
        searchText = (searchText != null) ? searchText : '';
        searchText = String.escapeSingleQuotes(searchText);
        String query = '';
        
        for(String objName : objectList) {
            if(!objNameToSearchConfigRecMap.containsKey(objName)) continue;
            Search_Configuration__mdt searchConfig = objNameToSearchConfigRecMap.get(objName);
        	List<sObject> resultRecords = new List<sObject>();
            if(searchConfig.Label == 'Account') {
            	query = getSOQLQuery(searchConfig, searchText, filterValues, true);
            	resultRecords = (List<sObject>)Database.query(query);
            	Set<Id> recordIds = getSearchedRecordIds(resultRecords);
            	if(resultRecords.size() < 5) {
            		query = getSOQLQuery(searchConfig, searchText, filterValues, false, recordIds);
            		resultRecords.addAll((List<sObject>)Database.query(query));
            	}
            } else if(searchConfig.Label == 'Country__c') {
            	query = getSOQLQuery(searchConfig, searchText, filterValues, true);
            	resultRecords = (List<sObject>)Database.query(query);
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
        if(objectAPIName == 'Country__c') {
            query += ' ORDER BY Currency_Code__c ASC ';
        } else if(objectAPIName.equalsIgnoreCase('CO_Header__c')) {
            query += ' ORDER BY Search_Priority__c, Name DESC';
        } else if(objectAPIName.equalsIgnoreCase('Return_CR_Header__c')) {
            query += ' ORDER BY LastModifiedDate DESC';
        } else if(objectAPIName.equalsIgnoreCase('Customer_Owned_Unit__c')) {
            query += ' ORDER BY Search_Priority__c ASC';
        } else {
            query += ' ORDER BY Last_Modified_Date__c DESC ';
        }
        query += ' LIMIT ' + (GenericSearchUtil.limitedRecordsObjectSet.contains(objectAPIName) ? 
        						GenericSearchUtil.MAX_RECORD_FOR_SPECIAL_OBJECTS : 1000);
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
            if(fieldFilterList.size() == 0){
                for(String textFieldStr : textFieldsList) {
                    if(isStartsWithOnly) {
                        fieldFilterList.add(new GenericSearchUtil.FieldFilter(textFieldStr, 'Like', '\'' + searchText + '%\''));
                    } else {
                        fieldFilterList.add(new GenericSearchUtil.FieldFilter(textFieldStr, 'Like', '\'%' + searchText + '%\''));
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

    private static List<GenericSearchUtil.SearchedSObjectWrapper> performSOSLSearch(GenericSearchUtil.QueryJSON searchObj, List<String> objectList, 
                                                                                        Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap) {
        String soslOnlySearch = GeneralConfiguration.getConfigurationByName(GeneralConfiguration.SOSL_SEARCH_ONLY);
        Set<Id> excludeRecIdSet = new Set<Id>();
        
        Long startTime = system.now().getTime();
        
        if(String.isNotBlank(soslOnlySearch) && soslOnlySearch.equalsIgnoreCase('true')) {
        	List<List<SObject>> searchList = getSOSLResults(searchObj, objectList, objNameToSearchConfigRecMap, searchObj.FilterValues, EXACT_MATCH, excludeRecIdSet);
        	System.debug('After First Query ' + (system.now().getTime() - startTime));
        	for(List<SObject> sobjObjResultList : searchList) {
                for(SObject sobj : sobjObjResultList) {
                    excludeRecIdSet.add(String.valueOf(sobj.get('Id')));
                }
            }
        	searchList.addAll(getSOSLResults(searchObj, objectList, objNameToSearchConfigRecMap, searchObj.FilterValues, 'All', excludeRecIdSet));
        	System.debug('After Second Query ' + (system.now().getTime() - startTime));
        	
            return getSOSLResultsWithSorting(searchObj.SearchText, searchList, objNameToSearchConfigRecMap);
        
        } else {
        	List<List<SObject>> searchList = getSOSLResults(searchObj, objectList, objNameToSearchConfigRecMap, searchObj.FilterValues, 'All', excludeRecIdSet);
            return getSOSLResultsBasedOnSpecificFieldsSearch(searchObj.SearchText, searchList, objNameToSearchConfigRecMap);
        }
    }

    private static List<List<SObject>> getSOSLResults(GenericSearchUtil.QueryJSON searchObj, List<String> objectList, Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap, 
    														List<GenericSearchUtil.FilterJSON> filterList, String matchingTye, Set<Id> excludeRecIdSet) {
        // Create search group for SOSL
        String searchQuery = getSOSLSearchQuery(searchObj.SearchText, matchingTye);
        String soslQuery = 'Find :searchQuery IN ALL FIELDS RETURNING ' ;
        soslQuery += getSOSLObjectsAndFields(searchObj, objectList, objNameToSearchConfigRecMap, filterList, matchingTye, excludeRecIdSet);
        system.debug(soslQuery);
        return search.query(soslQuery);
    }

    private static String getSOSLSearchQuery(String searchText, String matchingTye) {
        searchText = GenericSearchUtil.formatDynamicTextInSOSL(searchText);
        if(matchingTye == EXACT_MATCH) {
        	return '"' + searchText + '"';
        } else {
        	return '*' + searchText + ' OR ' + searchText + '* OR *' + searchText + '*';
        }
	}

    private static String getSOSLObjectsAndFields(GenericSearchUtil.QueryJSON searchObj, List<String> objectList, 
    												Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap, List<GenericSearchUtil.FilterJSON> filterList,
    												String matchingTye, Set<Id> excludeRecIdSet) {
        String objectAndFieldsStr = '';
        for(String objName: objectList) {
            objectAndFieldsStr += objName;
            objectAndFieldsStr += '(';
            if(objNameToSearchConfigRecMap.containsKey(objName)) {
                Search_Configuration__mdt searchConfig = objNameToSearchConfigRecMap.get(objName);
                if(String.isNotBlank(searchConfig.Searchable_Field_Set__c)) {
                    for(String fieldName: searchConfig.Searchable_Field_Set__c.split(',')) {
                        fieldName = fieldName;
                        objectAndFieldsStr += fieldName + ',';
                    }
                }
                if(String.isNotBlank(searchConfig.Additional_Fields_To_Query__c)) {
                    for(String fieldName: searchConfig.Additional_Fields_To_Query__c.split(',')) {
                        fieldName = fieldName;
                        objectAndFieldsStr += fieldName + ',';
                    }
                }
                objectAndFieldsStr = objectAndFieldsStr.substring(0, objectAndFieldsStr.length() - 1);

                // get filter clause
                objectAndFieldsStr += getSOSLFilterClause(searchObj, searchConfig.Fixed_Where_Clause__c, filterList, objName, matchingTye, excludeRecIdSet);
            } else {
                objectAndFieldsStr += 'Name';
            }
            if(String.isBlank(matchingTye) || !matchingTye.equalsIgnoreCase(EXACT_MATCH)) objectAndFieldsStr += ' ORDER BY Last_Modified_Date__c DESC';
            objectAndFieldsStr += ' limit 250), ';
        }
        objectAndFieldsStr = objectAndFieldsStr.substring(0, objectAndFieldsStr.length() - 2);
        return BPUtility.addNamespaceToQuery(objectAndFieldsStr, namespace);
    }

    private static String getSOSLFilterClause(GenericSearchUtil.QueryJSON searchObj, String fixedWhereClause, List<GenericSearchUtil.FilterJSON> filterList, 
    												String objName, String matchingTye, Set<Id> excludeRecIdSet) {
        String whereClause = '';
        //add default WHERE clause
        if(String.isNotBlank(fixedWhereClause)) {
            whereClause = ' WHERE Active__c = TRUE';
        }
        if(objName.equalsIgnoreCase('Account')) {
            if(searchObj != null && String.isNotBlank(searchObj.SearchableObjects) && !searchObj.SearchableObjects.split(',').isEmpty()) {
                if(searchObj.SearchableObjects.split(',')[0].equalsIgnoreCase('Vendor')) {
                    whereClause += (String.isBlank(whereClause)) ? ' WHERE ' : ' AND ';
                    whereClause += ('Is_Vendor__c = TRUE');
                } else if(searchObj.SearchableObjects.split(',')[0].equalsIgnoreCase('Customer')) {
                    whereClause += (String.isBlank(whereClause)) ? ' WHERE ' : ' AND ';
                    whereClause += ('Is_Customer__c = TRUE');
                }
            }
        } else if(objName.equalsIgnoreCase('Part__c') && (String.isBlank(matchingTye) || !matchingTye.equalsIgnoreCase(EXACT_MATCH))) {
        	String searchString = (searchObj.SearchText != null ? searchObj.SearchText.replaceAll('-', '') : searchObj.SearchText);
            whereClause += (String.isBlank(whereClause)) ? ' WHERE ' : ' AND ';
            whereClause += ('(NOT Name LIKE \'%' + BPUtility.escapeSingleQuotes(searchString) + '%\')');
        }

        if(GenericSearchUtil.objectNameToSOSLSearchableFieldsNameListMap.keySet().contains(objName)) {
            // add filterList
            for(GenericSearchUtil.FilterJSON fieldFilter : filterList) {
                if(fieldFilter.FilterObject.equalsIgnoreCase(objName)) {
                    whereClause += (String.isBlank(whereClause)) ? ' WHERE ' : ' AND ';
                    if(fieldFilter.Field != null && fieldFilter.Field.trim().length() > 0) {
                        whereClause += (fieldFilter.Field + ' ' + fieldFilter.Operator + ' ' + fieldFilter.Value);
                    } else {
                        whereClause += fieldFilter.Value;
                    }
                }
            }
        }
        
        if(!excludeRecIdSet.isEmpty()) {
        	whereClause += (String.isBlank(whereClause)) ? ' WHERE ' : ' AND ';
        	whereClause += ' Id NOT IN: excludeRecIdSet';
        }
        
        return whereClause;
    }

    private static List<GenericSearchUtil.SearchedSObjectWrapper> getSOSLResultsBasedOnSpecificFieldsSearch(String searchText, List<List<Sobject>> searchList, 
                                                                                                                Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap) {
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = new List<GenericSearchUtil.SearchedSObjectWrapper>();
        
        for(List<Sobject> sObjList: searchList) {
            if(sObjList.isEmpty()) continue;
            String objWithNamespace = sObjList[0].getSObjectType().getDescribe().getName();
            String objName = objWithNamespace.replace(namespace, '');
            Search_Configuration__mdt searchConfig = objNameToSearchConfigRecMap.get(objName);
            for(Sobject sObjRec: sObjList) {
                Integer matchingCriteriaPriority; // assign priority based on exact/startswith/conatins match
                for(String fieldName: GenericSearchUtil.objectNameToSOSLSearchableFieldsNameListMap.get(objName)) {
                    String fieldValue = sObjRec.get(fieldName) != null ? String.valueOf(sObjRec.get(fieldName)) : null;
                    if(fieldValue != null && fieldValue.containsIgnoreCase(searchText)) {
                        matchingCriteriaPriority = matchingCriteriaPriority != null ? matchingCriteriaPriority : 3;
                        if(fieldValue.equalsIgnoreCase(searchText)) {
                            matchingCriteriaPriority = 1;
                            break;
                        } else if(fieldValue.startsWithIgnoreCase(searchText)) {
                            matchingCriteriaPriority = 2;
                        }
                    }
                }
                if(matchingCriteriaPriority != null) {
                    Decimal orderNumber = GenericSearchSorting.getPriorityNumber(searchConfig.Order__c, matchingCriteriaPriority);
                    searchedResultsToSortList.add( new GenericSearchUtil.SearchedSObjectWrapper(sObjRec, orderNumber, objName));
                }
            }
        }
        return searchedResultsToSortList;
    }

	// SOSL search custom sorting
    private static List<GenericSearchUtil.SearchedSObjectWrapper> getSOSLResultsWithSorting(String searchText, List<List<Sobject>> searchList, 
                                                                                                                Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap) {
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = new List<GenericSearchUtil.SearchedSObjectWrapper>();
        
        for(List<Sobject> sObjList: searchList) {
            if(sObjList.isEmpty()) continue;
            String objWithNamespace = sObjList[0].getSObjectType().getDescribe().getName();
            String objName = objWithNamespace.replace(namespace, '');
            Search_Configuration__mdt searchConfig = objNameToSearchConfigRecMap.get(objName);
            for(Sobject sObjRec : sObjList) {
                Integer matchingCriteriaPriority = 4; // assign priority based on exact/startswith/conatins match
                Integer matchedFieldIndex = 19; // assuming max numbers of searchable fields to be 20 therefore index is 19 (substracting 1) as index starts from 0
                
                for(Integer i = 0; i < GenericSearchUtil.objectNameToSOSLSearchableFieldsNameListMap.get(objName).size(); i++) {
                	String fieldName = GenericSearchUtil.objectNameToSOSLSearchableFieldsNameListMap.get(objName)[i];
                    String fieldValue = GenericSearchUtil.getFieldValueFromSObject(sObjRec, fieldName);

                    if(fieldValue != null && fieldValue.containsIgnoreCase(searchText)) {
                    	matchingCriteriaPriority = (matchingCriteriaPriority < 3 ? matchingCriteriaPriority : 3);
                        if(fieldValue.equalsIgnoreCase(searchText)) {
                            matchingCriteriaPriority = 1;
                            matchedFieldIndex = i;
                            break;
                        } else if(fieldValue.startsWithIgnoreCase(searchText)) {
                            matchingCriteriaPriority = 2;
                            if(matchedFieldIndex > i) {
                            	matchedFieldIndex = i;
                            }
                        }
                    } else if(fieldValue != null) {
                    	if(matchingCriteriaPriority > 3) {
                        	// The Levenshtein distance is the number of changes needed to change one String into another.
                        	Integer levenshteinDistance = fieldValue.getLevenshteinDistance(searchText);
                        	if(matchingCriteriaPriority > (3 + levenshteinDistance)) {
                        		matchingCriteriaPriority = (3 + levenshteinDistance);
                        		matchedFieldIndex = i;
                        	}
                        }
                    }
                }
                
                // sorting index is calculated based on matchingCriteriaPriority and matchedFieldIndex, 20 is assumed to be maximum searchable fields
                Decimal sortingIndex = (20 * (matchingCriteriaPriority - 1) + (matchedFieldIndex + 1));
                
                if(matchingCriteriaPriority != null) {
                    if(GenericSearchUtil.objectNameToInnerSortingFieldName.containsKey(objName)) {
                        Object fieldValue = sObjRec.get(GenericSearchUtil.objectNameToInnerSortingFieldName.get(objName));
                        sortingIndex += GenericSearchUtil.getSortIndexForInnerSorting((fieldValue != null ? (Decimal)fieldValue : 0));
                    }
                    searchedResultsToSortList.add( new GenericSearchUtil.SearchedSObjectWrapper(sObjRec, sortingIndex, objName));
                }
            }
        }
        return searchedResultsToSortList;
    }

    private static List<GenericSearchUtil.SearchedSObjectWrapper> generateSOSLResultsWrapper(List<List<Sobject>> searchList) {
        List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList = new List<GenericSearchUtil.SearchedSObjectWrapper>();
        for(List<Sobject> sObjList: searchList) {
            for(Sobject sObjRec: sObjList) {
                String objName = sObjList[0].getSObjectType().getDescribe().getName().replace(namespace, '');
                searchedResultsToSortList.add(new GenericSearchUtil.SearchedSObjectWrapper(sObjRec, 1, objName));
            }
        }
        return searchedResultsToSortList;
    }

    public static String createJSON(List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList, 
                                        Map<String, Search_Configuration__mdt> objNameToSearchConfigRecMap, 
                                        GenericSearchUtil.QueryJSON searchObj) {
        List<GenericSearchResultsWrapper> suggestionRecords = new List<GenericSearchResultsWrapper>();
        List<CountSessionLineItemWrapper.CountSessionLineItem> countSessionLineItemSuggestionRecords = new List<CountSessionLineItemWrapper.CountSessionLineItem>();
        
        if(searchedResultsToSortList.size() > 0) {
            for(Integer counter=searchObj.FromIndex; counter<searchObj.ToIndex && counter<searchedResultsToSortList.size(); counter++) {
            	GenericSearchUtil.SearchedSObjectWrapper resultWrapperRecord = searchedResultsToSortList[counter];
            	if(resultWrapperRecord.objectName == 'Count_Session_Line_Item__c') {
            		countSessionLineItemSuggestionRecords.add(
            						new CountSessionLineItemWrapper.CountSessionLineItem((Count_Session_Line_Item__c)resultWrapperRecord.SearchedObj));
            	} else {
                    if(resultWrapperRecord.objectName == 'Service_Order_Header__c' && (((List<Event__c>) resultWrapperRecord.SearchedObj.getSobjects('Events__r')) != null && 
                        (((List<Event__c>) resultWrapperRecord.SearchedObj.getSobjects('Events__r')).size() > 0)) && objNameToSearchConfigRecMap.containsKey('Service_Order_Header__c') && objNameToSearchConfigRecMap.get('Service_Order_Header__c').DeveloperName == 'Service_Order_Header') {
                        continue;
                    } 
                    if(resultWrapperRecord.objectName == 'Country__c') {
                        String homeCurrency = QuickBooks_Configurations__c.getOrgDefaults().Home_Currency__c;
                        Country__c countryRec = (Country__c)resultWrapperRecord.SearchedObj;
                        if(countryRec.Currency_Code__c == homeCurrency) {
                            continue;
                        }
                    }
                    suggestionRecords.add(new GenericSearchResultsWrapper(resultWrapperRecord, objNameToSearchConfigRecMap.get(resultWrapperRecord.objectName)));
                }
            }
        }
        if(objNameToSearchConfigRecMap.containsKey('Count_Session_Line_Item__c')){
        	return system.JSON.serialize(countSessionLineItemSuggestionRecords, true);
        }
        if(isUpdateSTAJSON) {
            return system.JSON.serialize(new Map<String, Object>{'TotalRecords' => searchedResultsToSortList.size(), 'SearchedRecords' => suggestionRecords}, true);
        } else {
            return system.JSON.serialize(suggestionRecords, true);
        }
    }
}