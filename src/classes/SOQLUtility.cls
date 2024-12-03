public without sharing class SOQLUtility {
    
    public static final String STARTS_WITH = 'startswith';
    public static final String CONTAINS = 'contains';
    public static final String EQUALS = '=';
    public static final String NOTEQUALS = '!=';
    public static final String TRUE_VALUE = 'true';
    public static final String FALSE_VALUE = 'false';
    
    public static Integer getAvailableQueryRowsLimit() {
		return Limits.getLimitQueryRows() - Limits.getQueryRows();   
	}
	
	// Common method for checking FLS while doing query
	public static List<SObject> getQueryResults(String objectAPIName, String query) {
    	if(!AccessControl.ifObjectFieldIsAccessible(objectAPIName)) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	system.debug('query::' + query);
        return Database.query(query);
    }
    
	
	public static List<Price_Level__c> getAllPriceLevel() {
        String query = 'SELECT '; 
        for(String fieldsName : PriceLevel.fieldsList()){
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Price_Level__c Order by Default__c DESC, Active__c DESC, Name__c';
        if(AccessControl.ifObjectFieldIsAccessible('Price_Level__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Price_Level__c> priceLevelList = Database.query(query);
		
        return priceLevelList;
    }
    
	public static List<Sobject> getSODetailsByFieldName(Map<String, String> fieldNameToFieldValueMap) {
        String query;   
        query = 'SELECT '; 
        for(String fieldName : SOHeaderWrapper.getSOHeaderFieldsList()){
        	fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        } 
        
        query = query.substring(0, query.length()-2);
        query += ' FROM Service_Order_Header__c ';
        
        boolean isWhereClauseAdded = false;
        if(fieldNameToFieldValueMap.size() > 0) {
            for(String fieldName : fieldNameToFieldValueMap.keySet()) {
            	fieldName = BPUtility.escapeSingleQuotes(fieldName);
                if(!isWhereClauseAdded) {
                    query += 'WHERE '+ fieldName + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\'';
                    isWhereClauseAdded = true;
                } else {
                    query += 'AND '+ fieldName + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\'';
                }
            }
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Service_Order_Header__c> soHeaderList = Database.query(query);
        return soHeaderList;
    }
    
    public static List<Sobject> getCOHeaderDetails(Id coHeaderId, Integer fieldsToQueryLevel) {
        String query;   
        query = 'SELECT '; 
        CustomerOrderWrapper.COHeader coWrapperObj = new CustomerOrderWrapper.COHeader(fieldsToQueryLevel);
        for(String fieldsName : coWrapperObj.fieldsList()){
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        
        query += '(SELECT Id from CO_Invoice_Headers__r WHERE Invoice_Status__c = \'Active\')';
        
        query += ', (SELECT Id FROM Service_Order_Headers__r LIMIT 1)';
        query += ', (SELECT Id FROM Deals__r LIMIT 1)';
        query += ', (SELECT Id FROM Vendor_Order_Line_Items__r LIMIT 1)';
        query += ', (SELECT Special_Order_Status__c FROM CO_Section_Details__r WHERE Section_Type__c = \'' + COSectionDetailService.MERCHANDISE + '\' LIMIT 1)';
        //Child query
        query += ', (Select ';
        for(String fieldName : COHeaderWrapper.taxExemptionFields){
            query += fieldName + ', ';
        } 
        query = query.substring(0, query.length()-2);
        query += ' FROM Tax_Exemptions__r WHERE Type__c = \'' + TaxUtility.EXEMPTION + '\')';
        query += ' FROM ' + Constants.NAMESPACE + 'CO_Header__c ';
        if(coHeaderId != null) {
            query += 'WHERE ID = :coHeaderId';
        }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Header__c> coHeaderRec = Database.query(query);
        return coHeaderRec;
    }
    
    public static String getWhereClause(Map<String, String> fieldNameToFieldValueMap, Boolean isWhereClauseAdded) { 
    	String whereClause = '';
        if(fieldNameToFieldValueMap != null && fieldNameToFieldValueMap.size() > 0) {
            for(String fieldName : fieldNameToFieldValueMap.keySet()) {
                if(!isWhereClauseAdded) {
                    whereClause += 'WHERE ';
                    isWhereClauseAdded = true;
                } else {
                    whereClause += 'AND ';
                }
        		if(fieldNameToFieldValueMap.get(fieldName) != null && (fieldNameToFieldValueMap.get(fieldName).equalsIgnoreCase('false') || 
        						fieldNameToFieldValueMap.get(fieldName).equalsIgnoreCase('true'))) {
                    whereClause += BPUtility.escapeSingleQuotes(fieldName) + ' = ' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + ' ';
                } else {
                    whereClause += BPUtility.escapeSingleQuotes(fieldName) + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\' ';
                }
            }
        }
        return whereClause;
    }
	
	//For AND condition only
	public static String getWhereClauseWithANDCondition(List<FilterJSON> filerObjList, Boolean addWhereKeyword) {
		List<String> filterStrList = new List<String>();
		if(filerObjList != null) {
			for(FilterJSON filterObj : filerObjList) {
				if(String.isNotBlank(filterObj.Field) && String.isNotBlank(filterObj.Operator)) {
					String filterStr = '';
					if(filterObj.Operator.equalsIgnoreCase(STARTS_WITH)) {
						filterStr = filterObj.Field + ' Like \'' + BPUtility.escapeSingleQuotes(filterObj.Value) + '%\'';
					} else if(filterObj.Operator.equalsIgnoreCase(CONTAINS)) {
						filterStr = filterObj.Field + ' Like \'%' + BPUtility.escapeSingleQuotes(filterObj.Value) + '%\'';
					} else if(filterObj.Operator.equalsIgnoreCase('IN') || filterObj.Operator.equalsIgnoreCase('Not IN')) {
						if(String.isNotBlank(filterObj.Value)) {
							filterStr = filterObj.Field + ' ' + filterObj.Operator + ' ' + convertListToStringForWhereClause(filterObj.Value.split(','));
						}
					} else {
						if(String.isNotBlank(filterObj.Value) && !filterObj.Value.equalsIgnoreCase(TRUE_VALUE) && !filterObj.Value.equalsIgnoreCase(FALSE_VALUE)) {
							filterObj.Value = '\'' + filterObj.Value + '\'';
						}
						filterStr = filterObj.Field + ' ' + filterObj.Operator + ' ' + filterObj.Value;
					}
					filterStrList.add(filterStr);
				}
			}
		}
		return !filterStrList.isEmpty() ? (addWhereKeyword ? 'WHERE (' : '(' ) + String.join(filterStrList, ' AND ') + ') ' : '';
	}
	
	public static String convertListToStringForWhereClause(List<String> listToConvert) {
        for(String str: listToConvert) {
            str = BPUtility.escapeSingleQuotes(str);
        }
    	return '(\''+ String.join(listToConvert, '\',\'') +'\')';
    }
    
    //For lazy loading
    public static String getLimitClause(Integer startIndex, Integer recordCount) {
    	String limitClause = 'LIMIT ';
    	if(startIndex != null && recordCount != null) {
	    	if(startIndex >= 0 && startIndex <= 2000) {
	    		limitClause += recordCount + ' OFFSET ' + startIndex;
	    	} else if(startIndex > 2000) {
	    		limitClause += (recordCount + startIndex);
	    	}
    	} else {
    		limitClause += getAvailableQueryRowsLimit();
    	}
    	return limitClause;
    }
    
    public static List<SObject> getLimitRecordsBasedOnRecordCount(List<SObject> sobjList, Integer startIndex) {
    	List<SObject> sobjListToReturn = new List<SObject>();
    	for(Integer i=startIndex; i<sobjList.size(); i++) {
    		sobjListToReturn.add(sobjList.get(i));
    	}
    	return sobjListToReturn;
    }

    public static List<Stamp_Duty_Calculators__c> getAllStampDutyList() {
        String query = 'SELECT '; 
        for(String fieldsName : StampDuty.fieldsList()) {
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Stamp_Duty_Calculators__c Order by Name__c';
        if(AccessControl.ifObjectFieldIsAccessible('Stamp_Duty_Calculators__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Stamp_Duty_Calculators__c> stampDutyList = Database.query(query);
        return stampDutyList;
    }

    public static Stamp_Duty_Calculators__c getStampDutyRecordById(String recordId) {
        String query = 'SELECT '; 
        for(String fieldsName : StampDuty.fieldsList()) {
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Stamp_Duty_Calculators__c WHERE ID = \'' + recordId +'\'';
        if(AccessControl.ifObjectFieldIsAccessible('Stamp_Duty_Calculators__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        Stamp_Duty_Calculators__c stampDutyRecord = Database.query(query);
        return stampDutyRecord;
    }
}