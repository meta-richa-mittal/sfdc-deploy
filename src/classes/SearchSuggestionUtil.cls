/*
*
 * Author: Ashish Garg
 * Since: March 13, 2015
 * Name: SearchSuggestionUtil
 * Description: Utility class to hold methods related to search methods
**/
public without sharing class SearchSuggestionUtil {
    // Text to be searched
    public static String textToSearch {get; private set;}

    public static String createJSON(List<GenericSearchUtil.SearchedSObjectWrapper> searchedResultsToSortList, GenericSearchUtil.QueryJSON searchObj) {
        textToSearch = String.escapeSingleQuotes(searchObj.SearchText.toLowerCase());

        map<String, List<SuggestedRecordEntity>> groupedRecords = new map<String, List<SuggestedRecordEntity>>();
        for(GenericSearchUtil.SearchedSObjectWrapper searchedObj: searchedResultsToSortList) {
            String objName = searchedObj.objectName;
            String objNameWithNamespace = (objName.contains('__c') && !objName.contains(Constants.NAMESPACE)) ? Constants.NAMESPACE + objName : objName;
            
            // Check for Customer/vendor object
            if(objName == 'Account' ){
                if((searchObj.ObjectLabel == '' || searchObj.ObjectLabel == 'customer') && Boolean.valueOf(searchedObj.SearchedObj.get('Is_Customer__c')) ){
                    objNameWithNamespace = Constants.customerObjectLabel;
                } else if((searchObj.ObjectLabel == '' || searchObj.ObjectLabel == 'vendor') &&  Boolean.valueOf(searchedObj.SearchedObj.get('Is_Vendor__c')) ){
                    objNameWithNamespace = Constants.vendorObjectLabel;
                }
            }
            
            if(!groupedRecords.containsKey(objNameWithNamespace)) {
                groupedRecords.put(objNameWithNamespace, new List<SuggestedRecordEntity>());
            }
            groupedRecords.get(objNameWithNamespace).add(new SuggestedRecordEntity(searchedObj.SearchedObj));
        }

        // Create JSON for the result with suggested object records first
        return createSuggestedItemsJSON(groupedRecords, searchObj.PreferredObject, searchObj.ObjectLabel, searchObj.SearchableObjects);
    }
    
    public static String getSearchSuggestionJSON(SearchSuggestionJSON.QueryJSON searchQueryJSON){
        textToSearch = String.escapeSingleQuotes(searchQueryJSON.SearchText.toLowerCase());
        List<sObject> searchObjRecords = new List<sObject>();
        if(searchQueryJSON.SearchText != null && searchQueryJSON.SearchText.length() != 0){
            //system.assert(false, searchQueryJSON);
            searchObjRecords = getRecordsWithOrgSearch(searchQueryJSON.ObjectLabel, searchQueryJSON.SearchText, searchQueryJSON.SearchableObjects, searchQueryJSON.FilterValues);
        }
        //system.assert(false, searchObjRecords);
        
        // Grouped result as per objects
        // Create a list of SuggestedRecordEntity with each object and process sorting
        map<String, List<SuggestedRecordEntity>> groupedSortedRecords = getGroupedSortedRecords(searchQueryJSON.ObjectLabel, searchObjRecords);
        
        // Create JSON for the result with suggested object records first
        String searchJSONString = createSuggestedItemsJSON(groupedSortedRecords, searchQueryJSON.PreferredObject, searchQueryJSON.ObjectLabel, searchQueryJSON.SearchableObjects);

        //system.assert(false, searchJSONString);
        return searchJSONString;
    }
    
    /** 
     * Name: getRecordsWithOrgSearch
     * Desc: Method to Get filter record by filter record Id
     * @param: 
     * @return: List<Sobject> - List of filter object's record 
    **/
    private static List<Sobject> getRecordsWithOrgSearch(String objectLabel, String searchText, String SearchableObjects, List<SearchSuggestionJSON.FilterJSON> FilterValues) {
        String soslQuery = '';
        
        // Object name to which search in
        String objectName = (objectLabel != null && objectLabel.trim().length() != 0) ? String.escapeSingleQuotes(Constants.objectDisplayLabelToObjectName.get(objectLabel)) : null;
        
        searchText = (searchText != null) ? searchText : '';
        searchText = SOSLUtil.formatTextValueToBeSearched(searchText);
        
        // Searchable ordered list
        List<String> objectsOrderedList = new List<String>();
        if(SearchableObjects != null && SearchableObjects.trim().length() != 0){
            for(String objName : SearchableObjects.split(',')) {
                objName = (objName.contains('__c') && !objName.contains(Constants.NAMESPACE)) ? Constants.NAMESPACE + objName : objName;
                objName = BPUtility.escapeSingleQuotes(objName);
                objectsOrderedList.add(objName);
            }
        } else {
            objectsOrderedList = Constants.objectsOrderedList;
        }
        
        String customerSearchText = '';
        String vendorSearchText = '';
        
        // Set searchable fields here
        soslQuery += ' IN ALL FIELDS RETURNING ';
        
        String additionalAccountFields = ',Is_Customer__c,Is_Vendor__c';
        String customerVendorQueryString = '';
        
        
        List<String> searchableObjNameList = new List<String>();
        for(String objName : objectsOrderedList) {
            String whereCondition = '';
            
            if(objectName != null && objectName != objName ){
                continue;
            } else if(objectName != null) {
                if(FilterValues != null){
                    for(SearchSuggestionJSON.FilterJSON FilterJSON : FilterValues){
                        if(FilterJSON.FilterObject != null && objectName.contains(FilterJSON.FilterObject)) {
                            if(whereCondition != ''){
                                //whereCondition += ' OR ';
                                
                                if(!objectName.contains(CONSTANTS.NAMESPACE)) {
                                    objectName = CONSTANTS.NAMESPACE + objectName;
                                }
                                whereCondition += (objectName ==  CONSTANTS.NAMESPACE + 'Part__c' && 
                                					(FilterJSON.Field == 'Non_Inventory_Part__c' || FilterJSON.Field == 'AvailableParts__c' || FilterJSON.Field == 'Part_Number__c')) || 
                                                (objectName ==  CONSTANTS.NAMESPACE + 'Fee__c' && FilterJSON.Field == 'Type__c') ? ' AND ' : ' OR ';

                            } else {
                                whereCondition = ' WHERE ';
                            }
                            if(FilterJSON.Field == 'AvailableParts__c'){
                            	whereCondition += BPUtility.escapeSingleQuotes(FilterJSON.Field) + ' ' +(FilterJSON.Operator != null ? BPUtility.escapeSingleQuotes(FilterJSON.Operator) : '>')+ ' ' + 0;
                            } else if(FilterJSON.Field == 'Part_Number__c') {
                            	whereCondition += BPUtility.escapeSingleQuotes(FilterJSON.Field) + '!=\'' + BPUtility.escapeSingleQuotes(FilterJSON.Value) + '\'';
                            } else if(FilterJSON.Value == 'true' || FilterJSON.Value == 'false') {
                                whereCondition += BPUtility.escapeSingleQuotes(FilterJSON.Field) + '= ' + BPUtility.escapeSingleQuotes(FilterJSON.Value);
                            } else {
                                whereCondition += BPUtility.escapeSingleQuotes(FilterJSON.Field) + '=\'' + BPUtility.escapeSingleQuotes(FilterJSON.Value) + '\'';
                            }
                        }   
                    }
                }
                if(objectName == 'User') {
                    if(whereCondition != ''){
                        whereCondition += ' AND ';
                    } else {
                        whereCondition = ' WHERE ';
                    }
                    whereCondition += 'IsActive = true';
                }
            }
            else if(objName != null) {
                if(FilterValues != null){
                    for(SearchSuggestionJSON.FilterJSON FilterJSON : FilterValues){
                        if(FilterJSON.FilterObject != null && !FilterJSON.FilterObject.contains(CONSTANTS.NAMESPACE)
                        	&& FilterJSON.FilterObject != 'Vendor' && FilterJSON.FilterObject != 'Customer') {
                            FilterJSON.FilterObject = CONSTANTS.NAMESPACE + FilterJSON.FilterObject;
                        }
                        if(objName == FilterJSON.FilterObject ) {
                            if(whereCondition != ''){
                                if(!objName.contains(CONSTANTS.NAMESPACE)) {
                                    objName = CONSTANTS.NAMESPACE + objName;
                                }
                                 whereCondition += ((objName == CONSTANTS.NAMESPACE + 'Customer_Owned_Unit__c') ||(objName ==  CONSTANTS.NAMESPACE + 'Product__c' && FilterJSON.Field == 'Vendor__c') ||
                                						(objName ==  CONSTANTS.NAMESPACE + 'Part__c' 
                                							&& FilterJSON.Field == 'Non_Inventory_Part__c' || FilterJSON.Field == 'AvailableParts__c')) ? ' AND ' : ' OR ';
                            } else {
                                whereCondition = ' WHERE ';
                            }
                            //whereCondition += FilterJSON.Field + '=\'' + FilterJSON.Value + '\'';
                            if(FilterJSON.Field == 'AvailableParts__c'){
                            	whereCondition += BPUtility.escapeSingleQuotes(FilterJSON.Field) + ' ' +(FilterJSON.Operator != null ? BPUtility.escapeSingleQuotes(FilterJSON.Operator) : '>')+ ' ' + 0;
                            }else if(FilterJSON.Value == 'true' || FilterJSON.Value == 'false') {
                                whereCondition += BPUtility.escapeSingleQuotes(FilterJSON.Field) + '= ' + BPUtility.escapeSingleQuotes(FilterJSON.Value);
                            } else if(FilterJSON.Operator == '!=') {
                                whereCondition += BPUtility.escapeSingleQuotes(FilterJSON.Field) + ' != \'' + BPUtility.escapeSingleQuotes(FilterJSON.Value) + '\'';
                            } else {
                                whereCondition += BPUtility.escapeSingleQuotes(FilterJSON.Field) + '=\'' + BPUtility.escapeSingleQuotes(FilterJSON.Value) + '\'';
                            }
                        }   
                    }
                }
                if(objectName == 'User') {
                    if(whereCondition != ''){
                        whereCondition += ' AND ';
                    } else {
                        whereCondition = ' WHERE ';
                    }
                    
                    whereCondition += 'IsActive = true';
                }
            }
            
            // Search fields depending on deisplay field and display additional info maps defined in constant class based on use custom setting
            String searchFields = '';
            //system.assert(false, objName + '\n\n\n ' +  Constants.objectToSearchableFieldsMap);
            for(String searchField : Constants.objectToSearchableFieldsMap.get(objName)){
                searchField = String.escapeSingleQuotes(searchField);
                if(searchField.contains('__c'))
                    searchFields += CONSTANTS.NAMESPACE + searchField + ',';
                else
                    searchFields += searchField + ',';
            }
            searchFields= searchFields.replaceAll( '\\s+', '');
            searchFields = searchFields.substring(0, searchFields.length() - 1);

			
			// Added by TK - Prevent Inactive Records.
			String tempObjName = objName;
	        if(!tempObjName.contains(CONSTANTS.NAMESPACE) && !objName.equalsIgnoreCase(Constants.customerObjectLabel) 
	        		&& !objName.equalsIgnoreCase(Constants.vendorObjectLabel)) {
	            tempObjName = CONSTANTS.NAMESPACE + tempObjName;
	        }
	        if(BPUtility.objectAPINameToActiveFlagAPIName.containsKey(tempObjName)) {
	        	if(!whereCondition.contains('Active__c')) {
	        		whereCondition += (whereCondition.toLowerCase().contains('where') ? 
	        							' AND ' + BPUtility.objectAPINameToActiveFlagAPIName.get(tempObjName) + ' = TRUE ' :
	        							' WHERE ' + BPUtility.objectAPINameToActiveFlagAPIName.get(tempObjName) + ' = TRUE ');
	        	} 
	        }
			
            // Set object returning fields here
            if( !objName.equalsIgnoreCase(Constants.customerObjectLabel) && !objName.equalsIgnoreCase(Constants.vendorObjectLabel) ){
                if(objName.equalsIgnoreCase(Constants.NAMESPACE + 'Part__c')) {
                    searchFields += ', Vendor__r.Is_Foreign_Vendor__c, Vendor__r.Country__c, Vendor__r.Country__r.Currency_Code__c ';
                }
                soslQuery += objName + ' (LastModifiedDate,' + searchFields + whereCondition;
                soslQuery += ' ORDER BY LastModifiedDate DESC';
                soslQuery += '),';
            } else if(objName.equalsIgnoreCase(Constants.customerObjectLabel)){
                customerSearchText = 'IsCustomer';
                if(customerVendorQueryString != ''){
                    //customerVendorQueryString += ' OR Is_Customer__c=true';
                } else if(customerVendorQueryString == ''){
                    customerVendorQueryString = 'Account (LastModifiedDate,Is_Customer__c,Is_Vendor__c,Vendor_Code__c,Part_Category_Default__c,Part_Category_Default__r.Name,' + searchFields + whereCondition;
                }
            } else if(objName.equalsIgnoreCase(Constants.vendorObjectLabel)){
                vendorSearchText = 'IsVendor';
                if(customerVendorQueryString != ''){
                    //customerVendorQueryString += ' OR Is_Vendor__c=true';
                } else if(customerVendorQueryString == ''){
                    customerVendorQueryString = 'Account (LastModifiedDate,Is_Customer__c,Is_Vendor__c,Vendor_Code__c,Part_Category_Default__c,Part_Category_Default__r.Name,Is_Foreign_Vendor__c,Country__r.Currency_Code__c,Country__r.Conversion_Rate_With_Markup__c,' + searchFields + whereCondition;
                }
            }
        }
        
        String soslQueryFind = 'Find \'*' + searchText + '*\'' ;
        if(customerVendorQueryString.length() == 0){
            soslQuery = soslQueryFind + soslQuery.substring(0, soslQuery.length() - 1);
        } else {
            customerVendorQueryString += ' ORDER BY LastModifiedDate DESC)';
            soslQueryFind = 'Find \'*';
            
            if(objectLabel == null || objectLabel == ''){
                soslQueryFind += searchText + '* OR (';
            }
            soslQueryFind += searchText + '*'
                                        + (( customerSearchText != '' || vendorSearchText != '' )
                                            ? (' AND (' 
                                                + ((customerSearchText != '') ? customerSearchText : '')
                                                + ((vendorSearchText != '') ? ((customerSearchText != '') ? (' OR ' + vendorSearchText) : ('' + vendorSearchText)) : '')
                                                + ')'
                                            )
                                            : ''
                                          );
            if(objectLabel == null || objectLabel == ''){
                soslQueryFind += ')';
            }
            soslQueryFind += '\'';
            soslQuery = soslQueryFind + soslQuery + ' ' + customerVendorQueryString;
        }
        //system.assert(false, searchableObjNameList);
        for(String objName : searchableObjNameList) {
            if(objName == 'Customer' || objName == 'Vendor') {
                objName = 'Account';
            }
            if(AccessControl.ifObjectFieldIsAccessible(objName) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        } 
        //system.assert(false, soslQuery);
        List<List<Sobject>> sobjectList = Search.query(soslQuery);
        //system.assert(false, soslQuery + '\n\n\n\n' + sobjectList);
        
        List<sObject> searchObjRecords = new List<sObject>();
        for(List<sObject> sObjList : sobjectList){
            searchObjRecords.addAll(sObjList);
        }
        
        //System.assert(false, soslQuery + '\n' + searchObjRecords);
        return searchObjRecords;
    }
        
    private static map<String, List<SuggestedRecordEntity>> getGroupedSortedRecords(String objLabel, List<sObject> searchObjRecords){
        //system.assert(false, objLabel);
        map<String, List<SuggestedRecordEntity>> groupedRecords = new map<String, List<SuggestedRecordEntity>>();
        
        if(searchObjRecords != null && searchObjRecords.size() != 0){
            // Group the records with each object
            for(sObject sObj : searchObjRecords){
                String objName = String.valueOf(sObj.getSObjecttype());
                
                // Check for Customer/vendor object
                if( objName == 'Account' ){
                    if((objLabel == '' || objLabel == 'customer') && Boolean.valueOf(sObj.get('Is_Customer__c')) ){
                        objName = Constants.customerObjectLabel;
                        List<SuggestedRecordEntity> objRecords = (groupedRecords.containsKey(objName)) ? groupedRecords.get(objName) : new List<SuggestedRecordEntity>();
                        objRecords.add(new SuggestedRecordEntity(sObj));
                        groupedRecords.put(objName, objRecords);
                    }
                    if( (objLabel == '' || objLabel == 'vendor') &&  Boolean.valueOf(sObj.get('Is_Vendor__c')) ){
                        objName = Constants.vendorObjectLabel;
                        List<SuggestedRecordEntity> objRecords = (groupedRecords.containsKey(objName)) ? groupedRecords.get(objName) : new List<SuggestedRecordEntity>();
                        objRecords.add(new SuggestedRecordEntity(sObj));
                        groupedRecords.put(objName, objRecords);
                    }
                    if( objLabel == '' && !Boolean.valueOf(sObj.get('Is_Vendor__c')) && !Boolean.valueOf(sObj.get('Is_Customer__c')) ){
                        List<SuggestedRecordEntity> objRecords = (groupedRecords.containsKey(objName)) ? groupedRecords.get(objName) : new List<SuggestedRecordEntity>();
                        objRecords.add(new SuggestedRecordEntity(sObj));
                        groupedRecords.put(objName, objRecords);
                    }
                }
                //#1128 Subhrant
                else if(objName == CONSTANTS.NAMESPACE +'Unit_Model__c' ){
                        if(objLabel == 'UnitModel'){
                            objName = Constants.unitModelObjectLabel;
                            List<SuggestedRecordEntity> objRecords = (groupedRecords.containsKey(objName)) ? groupedRecords.get(objName) : new List<SuggestedRecordEntity>();
                            objRecords.add(new SuggestedRecordEntity(sObj));
                            groupedRecords.put(objName, objRecords);
                        }else{
                             List<SuggestedRecordEntity> objRecords = (groupedRecords.containsKey(objName)) ? groupedRecords.get(objName) : new List<SuggestedRecordEntity>();
                             objRecords.add(new SuggestedRecordEntity(sObj));
                             groupedRecords.put(objName, objRecords);
                        
                        }
                }
                 else {
                    List<SuggestedRecordEntity> objRecords = (groupedRecords.containsKey(objName)) ? groupedRecords.get(objName) : new List<SuggestedRecordEntity>();
                    objRecords.add(new SuggestedRecordEntity(sObj));
                    groupedRecords.put(objName, objRecords);
                }
            }
            
            // Sort each object related records
            for(String objName : groupedRecords.keySet()){
                List<SuggestedRecordEntity> objRecords = groupedRecords.get(objName);
                objRecords.sort();
            }
        }
        
        return groupedRecords;
    }
    
    private static String createSuggestedItemsJSON(map<String, List<SuggestedRecordEntity>> groupedSortedRecords, String preferredObject, String objLabel, String SearchableObjects){
        List<SearchSuggestionJSON.ResultJSON> resultSuggestionRecords = new List<SearchSuggestionJSON.ResultJSON>();
        
        // Add default suggested objects in the result JSON
        if(objLabel == null || objLabel == ''){
            resultSuggestionRecords.addAll(addDefaultSugegstedObjects(textToSearch, SearchableObjects));
        }
        if(groupedSortedRecords != null && groupedSortedRecords.size() != 0){
            // Prepare a list of object names so aj to sort the object records grouping (Preferred object name will be at first position)
            List<String> sortedObjectNameList = new List<String>();
            if(SearchableObjects != null && SearchableObjects.trim().length() != 0){
                for(String objName : SearchableObjects.split(',')) {
                    objName = (objName.contains('__c') && !objName.contains(Constants.NAMESPACE)) ? Constants.NAMESPACE + objName : objName;
                    sortedObjectNameList.add(objName);
                }
            } else {
                sortedObjectNameList = Constants.objectsOrderedList;
            }
            
            if(preferredObject != null && preferredObject.trim().length() != 0){
                sortedObjectNameList.add(0, preferredObject);
            }
            
            if(groupedSortedRecords.containsKey('Account')){
                sortedObjectNameList.add(0, 'Account');
            }
            
            // Make Set of SearchableObjects List - Adding NameSpace.
            Set<String> searchableObjectsSet = new Set<String>();
            if(SearchableObjects != null) {
                for(String searchableObjectStr : SearchableObjects.split(',')) {
                    searchableObjectsSet.add((searchableObjectStr.contains('__c') && !searchableObjectStr.contains(Constants.NAMESPACE)) ? CONSTANTS.NAMESPACE + searchableObjectStr : searchableObjectStr);
                }
            }
            
            // Add sorted result in SearchSuggestionJSON.ResultJSON list so to format for JSON
            for(String objName : sortedObjectNameList){
                if(groupedSortedRecords.containsKey(objName) && (SearchableObjects == null || searchableObjectsSet.contains(objName))){
                    String displayFieldName = Constants.objectToDisplayFieldsMap.get(objName);
                    displayFieldName = (displayFieldName.contains('__c') && !displayFieldName.contains(Constants.NAMESPACE)) ? CONSTANTS.NAMESPACE + displayFieldName : displayFieldName;
                    
                    if(objName != CONSTANTS.NAMESPACE + 'Part__c') {
                        if(objName == CONSTANTS.NAMESPACE +'UnitModel'){
                            for(SuggestedRecordEntity sObjItem : groupedSortedRecords.get(objName)){
                                    
                                    resultSuggestionRecords.add( new SearchSuggestionJSON.ResultJSON( sObjItem.record,
                                                                                              String.valueOf(sObjItem.record.get(displayFieldName)), 
                                                                                              String.valueOf(sObjItem.record.get('Id')),
                                                                                              '',
                                                                                              objName,
                                                                                              '', '', '', '' 
                                                                                            ));
                            }                                       
                                                                                    
                        }else{
                            for(SuggestedRecordEntity sObjItem : groupedSortedRecords.get(objName)){
                                    resultSuggestionRecords.add( new SearchSuggestionJSON.ResultJSON( sObjItem.record,
                                                                                              String.valueOf(sObjItem.record.get(displayFieldName)), 
                                                                                              String.valueOf(sObjItem.record.get('Id')),
                                                                                              Constants.objectToAdditionalInfoDisplayMap.get(objName),
                                                                                              objName,
                                                                                              '', '', '', '' 
                                                                                            ));
                            }       
                        }
                        
                    } else {
                        for(SuggestedRecordEntity sObjItem : groupedSortedRecords.get(objName)){
                            //system.assert(false, objName);
                            resultSuggestionRecords.add( new SearchSuggestionJSON.ResultJSON( sObjItem.record,
                                                                                              String.valueOf(sObjItem.record.get(displayFieldName)), 
                                                                                              String.valueOf(sObjItem.record.get('Id')),
                                                                                              Constants.objectToAdditionalInfoDisplayMap.get(objName),
                                                                                              objName,
                                                                                              String.valueOf(sObjItem.record.get(CONSTANTS.NAMESPACE+'Qty_In_Stock__c')),
                                                                                              String.valueOf(sObjItem.record.get(CONSTANTS.NAMESPACE+'Qty_Committed__c')),
                                                                                              String.valueOf(sObjItem.record.get(CONSTANTS.NAMESPACE+'Retail_Price__c')),
                                                                                              String.valueOf(sObjItem.record.get(CONSTANTS.NAMESPACE+'AvailableParts__c'))
                                                                                            ));
                        }
                    }
                    
                    groupedSortedRecords.remove(objName);
                    if(groupedSortedRecords.size() == 0){
                        break;
                    }
                }
            }
        }
        return System.JSON.serialize(resultSuggestionRecords);
    }
    
    // Add default suggested objects in the result JSON
    private static List<SearchSuggestionJSON.ResultJSON> addDefaultSugegstedObjects(String searchText, String SearchableObjects){
        List<SearchSuggestionJSON.ResultJSON> resultSuggestionRecords = new List<SearchSuggestionJSON.ResultJSON>();
        
        // Map for object/section name to its related type (Object/Section) in Customer Order page
        // Map is used in search suggestions list for all page realted objects and sections to display
        Map<String,String> coPageObjSectionsMap = new Map<String, String>{ 
                                                                            Label.Customer_Object_Display_Label => 'Object',
                                                                            Label.User_Object_Display_Label => 'Object',
                                                                            Label.Part_Object_Display_Label => 'Object',
                                                                            Label.Category_Object_Display_Label => 'Object',
                                                                            Label.Vendor_Object_Display_Label => 'Object',
                                                                            Label.Kit_Object_Display_Label => 'Object',
                                                                            Label.Fee_Object_Display_Label => 'Object',
                                                                            Label.Payment_Section_Display_Label => 'section',
                                                                            Label.Suggested_Items_Section_Display_Label => 'section' 
                                                                        };
        if(SearchableObjects.indexOf('Part__c') > -1) {
            SearchableObjects += ',' + Label.Part_Object_Display_Label;
        }
        //system.assert(false, SearchableObjects);
        for( String nameKey : coPageObjSectionsMap.keySet()){
            if( (searchText.length() == 0 || nameKey.toLowerCase().indexOf(searchText.toLowerCase()) > -1) &&
                        SearchableObjects.toLowerCase().indexOf(searchText.toLowerCase()) > -1){
                String value = (Constants.objectDisplayLabelToObjectName.containsKey(nameKey)) ? Constants.objectDisplayLabelToObjectName.get(nameKey) : nameKey;
                String info = coPageObjSectionsMap.get(nameKey);
                nameKey = (coPageObjSectionsMap.get(nameKey) == 'Object') ? (nameKey + ':') : nameKey;
                resultSuggestionRecords.add( new SearchSuggestionJSON.ResultJSON( null, nameKey, value, null, info, '','','', '') );   
            }
        }
        //system.assert(false, resultSuggestionRecords);
        return resultSuggestionRecords;
    }
}