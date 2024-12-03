/**
 * Author: Tarun Khandelwal
 * Since: April 15, 2016
 * Name: HomeSearchReportUtil
 * Description: Apex class to handle all operations related to Home Search Reporting Data
**/
public without sharing class HomeSearchReportUtil {
	
	public Static String NUMERIC_TYPE_1 = 'Number';
	public Static String NUMERIC_TYPE_2 = 'Currency';
	public Static Set<String> textFieldTypes = new Set<String>{'Text', 'Date'};
	public static String COUNT_RECORD_ALIASE = 'TotalRecords';
	public static String COUNT_RECORD_LABEL = 'Total Records';
	public static Integer QUERY_LIMIT_RECORDS = GeneralConfiguration.getHomeSearchReportExportQueryLimit() != null ?  GeneralConfiguration.getHomeSearchReportExportQueryLimit() : 1000;
	public static final Integer PART_AUTONUMBER_DIGITS = 8;
	public static final Integer PART_QUERY_LIMIT_RECORDS = 50000;
	
	public static Set<String> fieldLabelSet = new Set<String>();
	public static Map<String, String> fieldLabelToTypeMap = new Map<String, String>();
	public static Set<Id> partIdSet = new Set<Id>();
	
	public static String getReportingResult(HomeSearchFilterWrapper filterWrapperObj) {
		String seachableObject = HomeSearchUtil.getGenericObjectNameBySelectedObject(filterWrapperObj.Type.Objects);
		Boolean isGroup = checkForGroup(seachableObject);
		 
		Map<String, List<String>> objeNameToNumericFieldAPINameMap = new Map<String, List<String>>();
		List<AggregateResult> aggregateResultList = new List<AggregateResult>();
		Set<String> NumericFieldAPINameSet = new Set<String>();
		List<HomeSearchReportResultWrapper> hsResultWrapper = new List<HomeSearchReportResultWrapper>();
		fieldLabelSet.add(COUNT_RECORD_ALIASE);
		
		Boolean isExecuteOnlyPartSearchForGroup = false;
		if(!filterWrapperObj.Type.Objects.contains(Label.Generic_Object_Label) && isGroup 
			&& filterWrapperObj.Type.Objects.contains('Parts') && filterWrapperObj.Part_Name.Value1 != 'P-00000000') {
			isExecuteOnlyPartSearchForGroup = true;
			filterWrapperObj.Type.Objects = new Set<String>{'Parts'};
		}
		
	 	if(!filterWrapperObj.Type.Objects.contains(Label.Generic_Object_Label)
	 		&& filterWrapperObj.Type.Objects.contains('Parts') && filterWrapperObj.Part_Name != null) {
	 		String partName = filterWrapperObj.Part_Name.Value1;
	 		String query = 'SELECT Name FROM Part__c';
			query += ' WHERE Active__c = true AND Name >= :partName';
	        query += ' Order by Name ASC LIMIT 1';
	        List<Part__c> partList = Database.query(query);
	 		if(partList.size() == 1) {
	 			filterWrapperObj.Part_Name.Value1 = partList[0].Name;
	 		} else {
	 			if(isGroup) {
	 				if(isExecuteOnlyPartSearchForGroup) {
	 					return '';
	 				}
	 			} else {
	 				return '';
	 			}
	 		}
		}
		
		Map<String, String> objNameToWhereClauseMap = HomeSearchReportInterface.getWhereClauseForObjects(filterWrapperObj);
		//Map<String, List<HomeSearchFilterInterface.FieldFilter>> objNameToFieldFilterListMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
		//List<HomeSearchFilterInterface.FieldFilter> filterList = objectFiltersMap.get(objName);
		
		if(!filterWrapperObj.Type.Objects.contains(Label.Generic_Object_Label) 
			&& filterWrapperObj.Type.Objects.contains('Parts')) {

			String query = 'SELECT Id, Name FROM Part__c';
			String whereClauseString = objNameToWhereClauseMap.get('Parts');
			if(String.isNotBlank(whereClauseString)) {
	        	query += ' ' + whereClauseString;
	        }
	        query += ' Order by Name LIMIT '+PART_QUERY_LIMIT_RECORDS;
	        system.debug('check query---------------  '+query);
	        List<Part__c> partList = Database.query(query);
			partIdSet = new Set<Id>();
			for(Part__c part : partList) {
				partIdSet.add(part.Id);
			}
	        if(partList.size() > 0) {
				whereClauseString += ' ' + 'AND Id In :partIdSet';
				objNameToWhereClauseMap.put('Parts',whereClauseString);
	        	hsResultWrapper.add(new HomeSearchReportResultWrapper(null, 'LastSearchedPartName', partList[partList.size()-1].Name));
	        }

		}
		
		Set<String> objectsSet = getObjectNamesSet(filterWrapperObj);
		
		if(!isGroup) {
			objeNameToNumericFieldAPINameMap = getNumericColumns(seachableObject, filterWrapperObj.IsSummaryFormat);
			if(objectsSet.contains('Customer Payments')) {
				if(objeNameToNumericFieldAPINameMap.containsKey('Customer Payments')) {
					objeNameToNumericFieldAPINameMap.put('Customer Deposits', objeNameToNumericFieldAPINameMap.get('Customer Payments'));
					
					if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('AR Payments')) {
						objeNameToNumericFieldAPINameMap.put('AR Payments', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('AR Payments'));
						for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('AR Payments').size(); i++) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('AR Payments')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('AR Payments')[i]);
							fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('AR Payments')[i]);
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('AR Payments')[i], NUMERIC_TYPE_2);
						}
					}
					
				}
			}
			
			if(objectsSet.contains('Tax Detail Customer Invoices')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Tax Detail Customer Invoices')) {
					objeNameToNumericFieldAPINameMap.put('Tax Detail Customer Invoices', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Tax Detail Customer Invoices'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Tax Detail Customer Invoices').size(); i++) {
						fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Tax Detail Customer Invoices')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Tax Detail Customer Invoices')[i]);
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Tax Detail Customer Invoices')[i]);
						fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Tax Detail Customer Invoices')[i], NUMERIC_TYPE_2);
					}
				}
			}
			
			if(objectsSet.contains('Tax Detail Vendor Invoices')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Tax Detail Vendor Invoices')) {
					objeNameToNumericFieldAPINameMap.put('Tax Detail Vendor Invoices', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Tax Detail Vendor Invoices'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Tax Detail Vendor Invoices').size(); i++) {
						fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Tax Detail Vendor Invoices')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Tax Detail Vendor Invoices')[i]);
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Tax Detail Vendor Invoices')[i]);
						fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Tax Detail Vendor Invoices')[i], NUMERIC_TYPE_2);
					}
				}
			}
            
			if(objectsSet.contains('Invoiced Items')) {
				if(objeNameToNumericFieldAPINameMap.containsKey('Invoiced Items')) {
					Map<String, Map<String, Boolean>> permissionsMap = HomeSearchUtil.getUserPermissions();
	 				Boolean primaryPermission = permissionsMap.get('Costs').get('read only');
	 				if(!primaryPermission) {
	 					objeNameToNumericFieldAPINameMap.put('SOLI Without Permission', HomeSearchUtil.objectNameToNumericFieldApiNameMap.get('SOLI'));
						objeNameToNumericFieldAPINameMap.put('Option and Fee Without Permission', HomeSearchUtil.objectNameToNumericFieldApiNameMap.get('Option and Fee'));
	 				} else {
                        objeNameToNumericFieldAPINameMap.put('SOLI', HomeSearchUtil.objectNameToNumericFieldApiNameMap.get('SOLI'));
                        objeNameToNumericFieldAPINameMap.put('Option and Fee', HomeSearchUtil.objectNameToNumericFieldApiNameMap.get('Option and Fee'));
	 				}
					fieldAPINameToFieldLabelMap.put('Qty_Needed__c', 'Qty_Sold');
				}
			}
			if(objectsSet.contains('Customer Invoice Details COLI')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details COLI')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details COLI', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details COLI'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details COLI').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details COLI')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details COLI')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details COLI')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details COLI')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details COLI')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details COLI')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details COLI')[i], NUMERIC_TYPE_2);
						}
					}
				}
			}
			if(objectsSet.contains('Customer Invoice Details SOLI')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details SOLI')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details SOLI', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details SOLI'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details SOLI').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details SOLI')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details SOLI')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details SOLI')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details SOLI')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details SOLI')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details SOLI')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details SOLI')[i], NUMERIC_TYPE_2);
						}
					}
				}
			}
			if(objectsSet.contains('Customer Invoice Details Option and Fee')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details Option and Fee')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details Option and Fee', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Option and Fee'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Option and Fee').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Option and Fee')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Option and Fee')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Option and Fee')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Option and Fee')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Option and Fee')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Option and Fee')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Option and Fee')[i], NUMERIC_TYPE_2);
						}
					}
				}
			}
			if(objectsSet.contains('Customer Invoice Details Deal UPC')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details Deal UPC')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details Deal UPC', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal UPC'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal UPC').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal UPC')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal UPC')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal UPC')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal UPC')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal UPC')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal UPC')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal UPC')[i], NUMERIC_TYPE_2);
						}
					}
				}
			}
			if(objectsSet.contains('Customer Invoice Details Trade in')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details Trade in')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details Trade in', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Trade in'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Trade in').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Trade in')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Trade in')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Trade in')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Trade in')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Trade in')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Trade in')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Trade in')[i], NUMERIC_TYPE_2);
						}
					}
				}
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details Lien')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details Lien', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Lien'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Lien').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Lien')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Lien')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Lien')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Lien')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Lien')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Lien')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Lien')[i], NUMERIC_TYPE_2);
						}
					}
				}
			}
			if(objectsSet.contains('Customer Invoice Details FI Product')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details FI Product')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details FI Product', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details FI Product'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details FI Product').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details FI Product')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details FI Product')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details FI Product')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details FI Product')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details FI Product')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details FI Product')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details FI Product')[i], NUMERIC_TYPE_2);
						}
					}
				}
			}
			if(objectsSet.contains('Customer Invoice Details Deal Finance')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details Deal Finance')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details Deal Finance', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal Finance'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal Finance').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal Finance')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal Finance')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal Finance')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal Finance')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal Finance')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal Finance')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal Finance')[i], NUMERIC_TYPE_2);
						}
					}
				}
			}
			if(objectsSet.contains('Customer Invoice Details Deal')) {
				if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('Customer Invoice Details Deal')) {
					objeNameToNumericFieldAPINameMap.put('Customer Invoice Details Deal', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal'));
					for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal').size(); i++) {
						if(String.isNotBlank(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal')[i])) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Customer Invoice Details Deal')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal')[i]);
						}
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal')[i]);
						if(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal')[i] == 'QTY') {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal')[i], NUMERIC_TYPE_1);
						} else {
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('Customer Invoice Details Deal')[i], NUMERIC_TYPE_2);
						}
					}
				}
			}
			for(String objName : objectsSet) {
				if(objName == 'Customer Invoice Details Trade in') {
					aggregateResultList.addAll(getAggregateResultByObjName(objName, objeNameToNumericFieldAPINameMap.get(objName), objNameToWhereClauseMap.get(objName)));
					aggregateResultList.addAll(getAggregateResultByObjName(objName, objeNameToNumericFieldAPINameMap.get('Customer Invoice Details Lien'), objNameToWhereClauseMap.get(objName)));
				} else {
					if(objeNameToNumericFieldAPINameMap.containsKey(objName)) {
						aggregateResultList.addAll(getAggregateResultByObjName(objName, objeNameToNumericFieldAPINameMap.get(objName), objNameToWhereClauseMap.get(objName)));
					} else {
						aggregateResultList.addAll(getAggregateResultByObjName(objName, new List<String>(), objNameToWhereClauseMap.get(objName)));
					}
				}
                
                if(objNameToChildObjHSColumnListMap.containsKey(objName)) {
                	hsResultWrapper.addAll(getChildObjectAggregateResult(objName, filterWrapperObj));
                }
            }
		} else {
			if(seachableObject != Label.Generic_Object_Label) {
				for(String objName : filterWrapperObj.Type.Objects) {
					List<String> fieldAPINameList = HomeSearchUtil.objectToCommonNumericFieldAPIName.get(objName);
					
					for(Integer i = 0; i < fieldAPINameList.size(); i++) {
						fieldAPINameToFieldLabelMap.put(fieldAPINameList[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get(objName)[i]);
						fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get(objName)[i]);
						fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get(objName)[i], HomeSearchUtil.objectToCommonNumericFieldTypeMap.get(objName)[i]);
					}
					aggregateResultList.addAll(getAggregateResultByObjName(objName, HomeSearchUtil.objectToCommonNumericFieldAPIName.get(objName), objNameToWhereClauseMap.get(objName)));
					if(objName == 'Customer Payments') {	
                        aggregateResultList.addAll(getAggregateResultByObjName('Customer Deposits', HomeSearchUtil.objectToCommonNumericFieldAPIName.get(objName), objNameToWhereClauseMap.get('Customer Deposits')));
                        if(HomeSearchUtil.objectToCommonNumericFieldLabelName.containsKey('AR Payments')) {
						for(Integer i = 0; i < HomeSearchUtil.objectToCommonNumericFieldLabelName.get('AR Payments').size(); i++) {
							fieldAPINameToFieldLabelMap.put(HomeSearchUtil.objectToCommonNumericFieldAPIName.get('AR Payments')[i], HomeSearchUtil.objectToCommonNumericFieldLabelName.get('AR Payments')[i]);
							fieldLabelSet.add(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('AR Payments')[i]);
							fieldLabelToTypeMap.put(HomeSearchUtil.objectToCommonNumericFieldLabelName.get('AR Payments')[i], NUMERIC_TYPE_2);
						}
					}
                        
                        aggregateResultList.addAll(getAggregateResultByObjName('AR Payments', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('AR Payments'), objNameToWhereClauseMap.get('AR Payments')));
					}
					
					if(objName == 'Invoiced Items') {	
                        aggregateResultList.addAll(getAggregateResultByObjName('SOLI', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('SOLI'), objNameToWhereClauseMap.get('SOLI')));
                        aggregateResultList.addAll(getAggregateResultByObjName('Option and Fee', HomeSearchUtil.objectToCommonNumericFieldAPIName.get('Option and Fee'), objNameToWhereClauseMap.get('Option and Fee')));
					}
				}
			} else {
				Set<String> objectSet = new Set<String>();
				if(filterWrapperObj.Type.Objects.size() == 0 || (filterWrapperObj.Type.Objects.size() == 1 && filterWrapperObj.Type.Objects.contains(Label.Generic_Object_Label))) {
					objectSet = HomeSearchUtil.displayObjectNameToTypeNumber.keySet();
				} else {
					objectSet = filterWrapperObj.Type.Objects;
				}
                
                Set<String> objectNameCheckforDuplicateSet = new Set<String>();
				for(String objName : objectSet) {
                    if(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName) == 'Account' ||
                        !objectNameCheckforDuplicateSet.contains(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName)))
                    {
						aggregateResultList.addAll(getAggregateResultByObjName(objName, new List<String>(), objNameToWhereClauseMap.get(objName)));
						if(objName == 'Customer Payments') {
								aggregateResultList.addAll(getAggregateResultByObjName('Customer Deposits', new List<String>(), objNameToWhereClauseMap.get('Customer Deposits')));
								aggregateResultList.addAll(getAggregateResultByObjName('AR Payments', new List<String>(), objNameToWhereClauseMap.get('AR Payments')));
						}
						if(objName == 'Invoiced Items') {
							aggregateResultList.addAll(getAggregateResultByObjName('SOLI', new List<String>(), objNameToWhereClauseMap.get('SOLI')));
							aggregateResultList.addAll(getAggregateResultByObjName('Option and Fee', new List<String>(), objNameToWhereClauseMap.get('Option and Fee')));
						}
	                    objectNameCheckforDuplicateSet.add(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName));
					}
				}
			}
		}
        hsResultWrapper.addAll(getWrapperList(fieldLabelSet, aggregateResultList));
		String objNameSelected = HomeSearchUtil.getGenericObjectNameBySelectedObject(filterWrapperObj.Type.Objects);
		List<HomeSearch_Grid_Column__mdt> hsColumnsSetting = CustomMetadataTypeUtil.getGridColumnsMetadataTypeSettings(objNameSelected);
		for(HomeSearch_Grid_Column__mdt hsColumn : hsColumnsSetting) {
			if(hsColumn.Display_Object_Name__c == 'Vendor Orders' || hsColumn.Display_Object_Name__c == 'Vendor Returns') {
				if(hsColumn.Label == 'Vendor' || hsColumn.Label == 'Status') {
					hsResultWrapper.add(new HomeSearchReportResultWrapper(null, hsColumn.Label.replaceAll(' ', '_'), hsColumn.Type__c));
				}
			} else if((hsColumn.Display_Object_Name__c == 'Customer Invoice Details' && hsColumn.Type__c != NUMERIC_TYPE_1 && hsColumn.Type__c != NUMERIC_TYPE_2) || (hsColumn.Display_Object_Name__c != 'Customer Invoice Details' && (textFieldTypes.contains(hsColumn.Type__c) || (hsColumn.Label == 'Item' && hsColumn.Type__c == 'Link')
					|| (objectsSet.contains('Invoiced Items') && hsColumn.Label == 'Type' && hsColumn.Type__c == 'Icon')) && hsColumn.Field_API_Name__c != null)
				|| (hsColumn.Display_Object_Name__c == 'Parts to Pull' && (hsColumn.Label == 'Order Number' || hsColumn.Label == 'Location')) || (hsColumn.Display_Object_Name__c == 'VO Items' && hsColumn.Type__c == 'Link')) {
				hsResultWrapper.add(new HomeSearchReportResultWrapper(null, hsColumn.Label.replaceAll(' ', '_'), hsColumn.Type__c));
			}
		}
		return system.Json.serialize(hsResultWrapper);
	}

	public static Set<String> getObjectNamesSet(HomeSearchFilterWrapper filterWrapperObj) {
		Set<String> objectsSet = new Set<String>();
		for(String objectName : filterWrapperObj.Type.Objects) {
			objectsSet.add(objectName);
			if(objectsSet.contains('Customer Payments')) {
				objectsSet.add('Customer Deposits');
				objectsSet.add('AR Payments');
			}
			if(objectsSet.contains('Special Order')) {
				objectsSet.add('SO Special Order');
			}
			if(objectsSet.contains('Invoiced Items')) {
				objectsSet.add('SOLI');
				objectsSet.add('Option and Fee');
			} else if(objectsSet.contains('Customer Invoice Details')) {
				HomeSearchFilterService.setObjectNamesForCustomerInvoiceDetails(objectsSet, filterWrapperObj);
			}
			if(objectsSet.contains('Tax Detail')) {
			    objectsSet.remove('Tax Detail');
			    if(filterWrapperObj.Tax_Detail_Invoice_Type == '0') {
	                objectsSet.add('Tax Detail Customer Invoices');
	                objectsSet.add('Tax Detail Vendor Invoices');
	            } else if(filterWrapperObj.Tax_Detail_Invoice_Type == 'Selling') {
	                objectsSet.add('Tax Detail Customer Invoices');
	            } else if(filterWrapperObj.Tax_Detail_Invoice_Type == 'Purchasing') {
	                objectsSet.add('Tax Detail Vendor Invoices');
	            }
            }
		}
		return objectsSet;
	}
	
	private static String formatPartAutoNumber(Integer limitValue) {
        String limitStr = String.valueOf(limitValue);
        for(Integer i = 0; i < (PART_AUTONUMBER_DIGITS - String.valueOf(limitValue).length()); i++) {
            limitStr = '0' + limitStr;
        }
        limitStr = 'P-' + limitStr;
        return limitStr;
    }
	
    public static List<HomeSearchReportResultWrapper> getChildObjectAggregateResult(String objName, HomeSearchFilterWrapper filterWrapperObj) {
    	List<HomeSearchReportResultWrapper> hsResultWrapper = new List<HomeSearchReportResultWrapper>();
    	Map<String, Map<String, String>> childObjAPINameToFieldAPINameToLabelMap = new Map<String, Map<String, String>>();
    	Map<String, Set<String>> childObjNameToFieldLabelSetMap = new Map<String, Set<String>>();
    	
    	List<HomeSearch_Grid_Column__mdt> hsColumnList = objNameToChildObjHSColumnListMap.get(objName);
		for(HomeSearch_Grid_Column__mdt hsColumn : hsColumnList) {
			
			List<String> objAndFieldAPINameList = hsColumn.Field_API_Name__c.split('__child.');
    		if(!childObjAPINameToFieldAPINameToLabelMap.containsKey(objAndFieldAPINameList[0])) {
    			childObjAPINameToFieldAPINameToLabelMap.put(objAndFieldAPINameList[0], new Map<String, String>());
    			childObjNameToFieldLabelSetMap.put(objAndFieldAPINameList[0], new Set<String>());
    		}
    		
    		Map<String, String> fieldAPINameToLabelMap = childObjAPINameToFieldAPINameToLabelMap.get(objAndFieldAPINameList[0]);
    		fieldAPINameToLabelMap.put(objAndFieldAPINameList[1], hsColumn.Label.replaceAll(' ', '_'));
    		
    		childObjNameToFieldLabelSetMap.get(objAndFieldAPINameList[0]).add(hsColumn.Label.replaceAll(' ', '_'));
            fieldLabelToTypeMap.put(hsColumn.Label.replaceAll(' ', '_'), hsColumn.Type__c);
		}
		
		List<AggregateResult> childObjAggregateResultList = new List<AggregateResult>();
		
		if(childObjAPINameToFieldAPINameToLabelMap.size() > 0) {
			Map<String, List<HomeSearchFilterInterface.FieldFilter>> objNameToFieldFilterListMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
			
			for(String childObjName : childObjAPINameToFieldAPINameToLabelMap.keySet()) {
				String parentObjAPIName = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName);
				parentObjAPIName = parentObjAPIName.replace('__c', '__r');
				
				
				String whereClause = getWhereClauseForChildObjAggregate(objName, parentObjAPIName, childObjName, objNameToFieldFilterListMap.get(objName), filterWrapperObj);
				childObjAggregateResultList = getChildAggregateResultByObjName(childObjName, 
	    					new List<String> (childObjAPINameToFieldAPINameToLabelMap.get(childObjName).keySet()), 
	    					childObjAPINameToFieldAPINameToLabelMap.get(childObjName), whereClause);
	    		
	    		hsResultWrapper.addAll(getWrapperList(childObjNameToFieldLabelSetMap.get(childObjName), childObjAggregateResultList));
			}
		}
        return hsResultWrapper;
    }

	public static String getWhereClauseForChildObjAggregate(String objName, String parentObjAPIName, String childObjName, List<HomeSearchFilterInterface.FieldFilter> fieldFilterList, HomeSearchFilterWrapper filterWrapperObj) {
		String whereClause = HomeSearchReportInterface.getWhereClause(objName, fieldFilterList, parentObjAPIName);
				if(childObjName == 'Hours_Logged__c') {
					whereClause += ((whereClause != '') ? ' AND ' : ' where ' ) + 'Is_Removed__c = false AND End_Date_Time__c != null ';
					whereClause += (objName == 'Service Jobs') ? ' AND Service_Order_Header__c != null AND Service_Order_Header__r.SO_Status__c != \''+ServicejobUtil.INVOICED+'\' ' : '';
				} else if(childObjName == 'Unit_Price_Cost__c' && filterWrapperObj.Inventory_Unit_In_Stock_As_Of != null && !String.isBlank(filterWrapperObj.Inventory_Unit_In_Stock_As_Of.SelectedOption) && filterWrapperObj.Inventory_Unit_In_Stock_As_Of.SelectedOption != '0') {
					String dtValue = HomeSearchFilterInterface.getDateFromString(filterWrapperObj.Inventory_Unit_In_Stock_As_Of.Value1).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
					whereClause += ((whereClause != '') ? ' AND ' : ' where ' ) + '((Adjustment_Date__c <=' + dtValue + ') OR (Type__c IN (\'Base\', \'Factory\') AND Adjustment_Date__c = null)  OR (Type__c = \'Dealer\' AND CreatedDate <=' + dtValue + '))';
				} else if(childObjName == 'Service_Order_Line_Item__c' && objName == 'Service Jobs') {
					whereClause += ((whereClause != '') ? ' AND ' : ' where ' ) + ' Service_Order_Header__c != null ';
				}
				String containsClause = HomeSearchReportInterface.getContainsCondition(objName, filterWrapperObj.SearchText, parentObjAPIName);
		    	
		    	if(whereClause != '' && containsClause != '') {
					whereClause = whereClause + ' AND ' + containsClause;
				} else if(whereClause == '' && containsClause != ''){
					whereClause = ' WHERE ' + containsClause;
				}

				// We are using 'Deal Units' as object name for 'Inventory Unit' to get the assigned tags for Inventory Unit as the query is on UnitPriceAndCost object which do not have Assigned_Tags__c field
				if(objName == 'Inventory Unit' && filterWrapperObj.AssignedTags != null && filterWrapperObj.AssignedTags.size() > 0) {
					if(whereClause != '') {
						whereClause += ' AND ' + HomeSearchReportInterface.getAssignedTagClause('Deal Units', filterWrapperObj.AssignedTags, 'Tag');
					} else {
						whereClause = ' WHERE ' + HomeSearchReportInterface.getAssignedTagClause('Deal Units', filterWrapperObj.AssignedTags, 'Tag');
					}
				}
		return whereClause;
    }
    
	private static List<HomeSearchReportResultWrapper> getWrapperList(Set<String> fieldLabelNameSet, List<AggregateResult> aggregateResultList) {
		List<HomeSearchReportResultWrapper> hsResultWrapper = new List<HomeSearchReportResultWrapper>();
		for(String fieldLabelName : fieldLabelNameSet) {
			Decimal value = 0;
			for(AggregateResult aggregate : aggregateResultList) {
				try {
					if(aggregate.get(fieldLabelName) != null) {
						value += (Decimal)aggregate.get(fieldLabelName);
					}
				} catch(exception e) {
					
				}
			}
			hsResultWrapper.add(new HomeSearchReportResultWrapper(value, fieldLabelName, fieldLabelToTypeMap.get(fieldLabelName)));
		}
		return hsResultWrapper;
	}
	
	private static Boolean checkForGroup(String objName) {
		Boolean isGroup = false;
		if(HomeSearchUtil.groupNameToGroupObjectsMap.containsKey(objName) || objName == Label.Generic_Object_Label) {
			isGroup = true;
		}
		return isGroup;
	}
	
	private static Map<String, String> fieldAPINameToFieldLabelMap = new Map<String, String>();
    public static Map<String, List<HomeSearch_Grid_Column__mdt>> objNameToChildObjHSColumnListMap = new Map<String, List<HomeSearch_Grid_Column__mdt>>();
	
	private static Map<String, List<String>> getNumericColumns(String objName, Boolean isSummaryFormat) {
		Map<String, List<String>> objeNameToNumericFieldAPINameMap = new Map<String, List<String>>();
		List<HomeSearch_Grid_Column__mdt> hsColumnsSetting = CustomMetadataTypeUtil.getGridColumnsMetadataTypeSettings(objName);
 		for(HomeSearch_Grid_Column__mdt hsColumn : hsColumnsSetting) {
 			if(objName != 'Invoiced Items' || (objName == 'Invoiced Items' && isSummaryFormat != null && 
 				((isSummaryFormat && hsColumn.Label != 'Revenue' && hsColumn.Label != 'Profit') || 
 				(!isSummaryFormat && hsColumn.Label != 'Total Revenue' && hsColumn.Label != 'Total Profit'))))
 			{	
                if((hsColumn.Type__c == NUMERIC_TYPE_1 || hsColumn.Type__c == NUMERIC_TYPE_2) && hsColumn.Field_API_Name__c != null) {
                	if(hsColumn.Field_API_Name__c.contains('__child.')) {
                		if(!objNameToChildObjHSColumnListMap.containsKey(objName)) {
                			objNameToChildObjHSColumnListMap.put(objName, new List<HomeSearch_Grid_Column__mdt>());
                		}
                		objNameToChildObjHSColumnListMap.get(objName).add(hsColumn);
                		continue;
                	}
					if(!objeNameToNumericFieldAPINameMap.containsKey(hsColumn.Display_Object_Name__c)) {
						objeNameToNumericFieldAPINameMap.put(hsColumn.Display_Object_Name__c, new List<String>{hsColumn.Field_API_Name__c});
					} else {
						List<String> numericFieldAPINameList = objeNameToNumericFieldAPINameMap.get(hsColumn.Display_Object_Name__c);
						numericFieldAPINameList.add(hsColumn.Field_API_Name__c);
					}
					if(hsColumn.Label != null) {
						fieldAPINameToFieldLabelMap.put(hsColumn.Field_API_Name__c, hsColumn.Label.replaceAll(' ', '_'));
						fieldLabelSet.add(hsColumn.Label.replaceAll(' ', '_'));
						fieldLabelToTypeMap.put(hsColumn.Label.replaceAll(' ', '_'), hsColumn.Type__c);
					}
				} 
			}
		}
		fieldAPINameToFieldLabelMap.put('Id', COUNT_RECORD_ALIASE);
		return objeNameToNumericFieldAPINameMap;
	}
	
	public static List<AggregateResult> getAggregateResultByObjName(String objName, List<String> numericFieldAPINameList) {
		List<AggregateResult> aggregateResultList = new List<AggregateResult>();
		String query = '';
		
		query += 'SELECT COUNT(Id) ' + COUNT_RECORD_ALIASE + ', ';
		for(String fieldName : numericFieldAPINameList) {
			if(fieldName != 'Id') {
				query += 'SUM(' + fieldName + ') ' + fieldAPINameToFieldLabelMap.get(fieldName) + ', ';
			} else {
				query += 'COUNT(' + fieldName + ') ' + fieldAPINameToFieldLabelMap.get(fieldName) + ', ';
			}
		}
		query = query.substring(0, query.length() - 2);
		query += ' FROM ' + HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName);
		
		//system.assert(false, query);
		if(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName) != null){
			if(AccessControl.ifObjectFieldIsAccessible(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName)) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		}
		aggregateResultList = Database.query(query);
		return aggregateResultList;
	}
	
	public static List<AggregateResult> getAggregateResultByObjName(String objName, List<String> numericFieldAPINameList, String whereClauseString) {
		List<AggregateResult> aggregateResultList = new List<AggregateResult>();
        String query = '';
        
		query += 'SELECT COUNT(Id) ' + COUNT_RECORD_ALIASE + ', ';
		for(String fieldName : numericFieldAPINameList) {
			String regExp = '_[0-9]'; // regex to remove chars appended at last of field name
			String fieldAPIName = fieldName.replaceAll(regExp, '');
			if(String.isNotBlank(fieldAPIName)) {
				if(fieldAPIName != 'Id') {
					query += 'SUM(' + fieldAPIName + ') ' + fieldAPINameToFieldLabelMap.get(fieldName) + ', ';
				} else {
					query += 'COUNT(' + fieldAPIName + ') ' + fieldAPINameToFieldLabelMap.get(fieldName) + ', ';
				}
			}
		}
		query = query.substring(0, query.length() - 2);
		query += ' FROM ' + HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName);
		
		// get where clause
		//String whereClauseString = getWhereClause(objName, filterList);
		if(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName) != null){
			if(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName).indexOf(',') != -1) {
    			List<String> objectsAPINameList = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName).split(',');
    			for(String objAPIName : objectsAPINameList) {
    				if(AccessControl.ifObjectFieldIsAccessible(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objAPIName)) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    			}
			} else {
				if(AccessControl.ifObjectFieldIsAccessible(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName)) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
			}
		}
		
		if(String.isNotBlank(whereClauseString)) {
        	query += ' ' + whereClauseString;
        }
		
		system.debug('Aggregate Query BY TARUN : ' + query);
		
		aggregateResultList = Database.query(query);
		return aggregateResultList;
	}
	
    public static List<AggregateResult> getChildAggregateResultByObjName(String objName, List<String> numericFieldAPINameList, 
    													Map<String, String> fieldAPINameToLabelMap, String whereClauseString) {
        List<AggregateResult> aggregateResultList = new List<AggregateResult>();
        String query = '';
        
        query += 'SELECT COUNT(Id) ' + COUNT_RECORD_ALIASE + ', ';
        for(String fieldName : numericFieldAPINameList) {
            query += 'SUM(' + fieldName + ') ' + fieldAPINameToLabelMap.get(fieldName) + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM ' + objName;
        
        // get where clause
        //String whereClauseString = getWhereClause(objName, filterList);
        if(objName != null) {
            if(AccessControl.ifObjectFieldIsAccessible(objName) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        }
        
        if(String.isNotBlank(whereClauseString)) {
            query += ' ' + whereClauseString;
        }
        
        system.debug('Aggregate Query BY TARUN : ' + query);
        
        //system.assert(false, query);
        aggregateResultList = Database.query(query);
        return aggregateResultList;
    }
    
	public static String getRportingDataByHomeSearchFilters(HomeSearchFilterWrapper filterWrapperObj, String selectedObjName, String uniqueValueFieldLastValue, Map<String, String> objAPINameToLastValueMap) {
		List<HomeSearchFilterInterface.FilterLabel> filterLabelList = HomeSearchFilterInterface.getFilterLabelList(filterWrapperObj);
		return (getRportingDataByHomeSearchFilters(filterWrapperObj, selectedObjName, uniqueValueFieldLastValue, filterLabelList, objAPINameToLastValueMap));
    }
    
    public static String getRportingDataByHomeSearchFilters(HomeSearchFilterWrapper filterWrapperObj, 
    														String selectedObjName, 
    														String uniqueValueFieldLastValue,
															List<HomeSearchFilterInterface.FilterLabel> filterLabelList,
															Map<String, String> objAPINameToLastValueMap
    													) {
    	String objAPIName = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(selectedObjName);
    	if(objAPINameToLastValueMap == null) {
			objAPINameToLastValueMap = new Map<String, String>();
		}
		PaginationSorting pageAndSortMapping;
		if(selectedObjName == 'Invoiced Items' && filterWrapperObj.IsSummaryFormat) {
			pageAndSortMapping = new PaginationSorting();
		}
    	Map<String, List<sObject>> resultRecordsMap = getRportRecordsByHomeSearchFilters(filterWrapperObj, new Set<String>{selectedObjName}, uniqueValueFieldLastValue, pageAndSortMapping, objAPINameToLastValueMap);
        List<sObject> resultRecords;
        if(resultRecordsMap.containsKey('Parts Order')) {
        	resultRecords = new List<sObject>((List<sObject>) resultRecordsMap.get('Parts Order'));
        } else if(selectedObjName == 'Customer Invoice Details') {
        	resultRecords = new List<sObject>();
        	for(String objName: HomeSearchUtil.objectsToSearchForCustomerInvoiceDetailsSearch) {
        		if(HomeSearchUtil.displayObjectNameToObjectAPINameMap.containsKey(objName) && resultRecordsMap.containsKey(HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName))) {
					String objectAPI = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objName);
					List<sObject> sObjectList = (List<sObject>)resultRecordsMap.get(objectAPI);
					if(sObjectList.size() > 0) {
						objAPINameToLastValueMap.put(objectAPI, String.valueOf(sObjectList[sObjectList.size() - 1].get(HomeSearchUtil.searchableObjectToUniqueValueFieldMap.get(objectAPI))));
					}
					resultRecords.addAll(sObjectList);
        		}
        	}
        } else {
        	resultRecords = new List<sObject>((List<sObject>) resultRecordsMap.get(objAPIName));
        }
        if(objAPIName == 'CO_Section_Detail__c' && resultRecordsMap.containsKey('Service_Order_Header__c')) {
    		resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Service_Order_Header__c') );
    	}
    	if(objAPIName == 'CO_Invoice_Payment__c' && resultRecordsMap.containsKey('CO_Deposit__c') && resultRecordsMap.containsKey('Payment_on_Account__c')) {
    		resultRecords.addAll( (List<sObject>)resultRecordsMap.get('CO_Deposit__c') );
    		resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Payment_on_Account__c') );
    	}
    	if(objAPIName == 'Vendor_Order_Header__c' && resultRecordsMap.containsKey('Return_VO_Header__c')) {
    		resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Return_VO_Header__c') );
    	}
		if(objAPIName == 'Vendor_Order_Header__c' && resultRecordsMap.containsKey('Return_CR_Header__c')) {
    		resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Return_CR_Header__c') );
    	}
    	if(objAPIName == 'Part_FIFO_Bucket__c' && resultRecordsMap.containsKey('Part_FIFO_Bucket__c')) {
            resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Part_FIFO_Bucket_Activity_Line_Item__c') );
        } 
		if(objAPIName == 'CO_Line_Item__c') {
    		if(resultRecordsMap.containsKey('Service_Order_Line_Item__c')) {
    			resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Service_Order_Line_Item__c') );
    		}
    		if(resultRecordsMap.containsKey('Option_Fee__c')) {
    			resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Option_Fee__c') );
    		}
    	}
    	
    	if(selectedObjName == 'Tax Detail') {
            if(filterWrapperObj.Tax_Detail_Invoice_Type == '0') {
            	resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Vendor_Invoicing_Header__c') );
                resultRecords.addAll( (List<sObject>)resultRecordsMap.get('CO_Invoice_Header__c') );
            } else if(filterWrapperObj.Tax_Detail_Invoice_Type == 'Selling') {
                resultRecords.addAll( (List<sObject>)resultRecordsMap.get('CO_Invoice_Header__c') );
            } else if(filterWrapperObj.Tax_Detail_Invoice_Type == 'Purchasing') {
                resultRecords.addAll( (List<sObject>)resultRecordsMap.get('Vendor_Invoicing_Header__c') );
            }
        }
        resultRecordsMap = null;
        // Get JSON string for result records in ResultWrapper instance
    	Integer totalRecordsFound = 0;
    	HomeSearchResultWrapper.getJSONForSObjectRecords( resultRecords, 
														  HomeSearchUtil.getGenericObjectNameBySelectedObject(filterWrapperObj.Type.Objects), 
														  totalRecordsFound,
														  null,
                                                          false, false, filterWrapperObj.IsSummaryFormat, filterWrapperObj.Type.Objects, filterWrapperObj 
														);
    	String lastRecordUniqueFieldValue = '';
    	if(resultRecords.size() > 0 && objAPIName != null) {
    		lastRecordUniqueFieldValue = String.valueOf(resultRecords[resultRecords.size() - 1].get(HomeSearchUtil.searchableObjectToUniqueValueFieldMap.get(objAPIName)));
    	}
    	Integer resultRecSize = resultRecords.size();
    	resultRecords = null;
    	//heap size left = 6000000
    	ReportWrapper ResultData = new ReportWrapper(HomeSearchResultWrapper.result, 
    												 lastRecordUniqueFieldValue,
    												 (resultRecSize < QUERY_LIMIT_RECORDS),
    												 resultRecSize,
													 filterLabelList,
													 objAPINameToLastValueMap
    												);    												
    	HomeSearchResultWrapper.result = null;											
		return system.Json.serialize(ResultData);
    }
    
    public static Map<String, List<sObject>> getRportRecordsByHomeSearchFilters(HomeSearchFilterWrapper filterWrapperObj, 
    														Set<String> selectedObjNames, 
    														String uniqueValueFieldLastValue,
															PaginationSorting pageAndSortMapping,
															Map<String, String> objAPINameToLastValueMap
    													) {
    	Map<String, List<sObject>> resultRecordsMap = new Map<String, List<sObject>>();
    	// Ensure the filter wrapper contains only single object
    	// Since, we are not querying the result in loop in apex, so we need to have only 1 object name in filter wrapper
    	// Next, remaining results of remaining objects will be queried in next context call by page so as to avoid governor limits
		filterWrapperObj.Type.Objects = selectedObjNames;
		Set<String> objectsSet = new Set<String>();
		for(String objectName : selectedObjNames) {
			objectsSet.add(objectName);
			if(objectsSet.contains('Customer Payments') && !objectsSet.contains('Customer Deposits')) {
				objectsSet.add('Customer Deposits');
				objectsSet.add('AR Payments');
			} else if(objectsSet.contains('Invoiced Items') && !objectsSet.contains('SOLI')) {
				objectsSet.add('SOLI');
				objectsSet.add('Option and Fee');
			} else if(objectsSet.contains('Part FIFO')) {
			    objectsSet.add('Part FIFO Line Item');
			    QUERY_LIMIT_RECORDS = 15000;
			} else if(objectsSet.contains('Special Order')) {
			    objectsSet.add('SO Special Order');
			} else if(objectsSet.contains('Tax Detail')) {
			    objectsSet.remove('Tax Detail');
			    if(filterWrapperObj.Tax_Detail_Invoice_Type == '0') {
                    objectsSet.add('Tax Detail Customer Invoices');
                    objectsSet.add('Tax Detail Vendor Invoices');
                } else if(filterWrapperObj.Tax_Detail_Invoice_Type == 'Selling') {
                    objectsSet.add('Tax Detail Customer Invoices');
                } else if(filterWrapperObj.Tax_Detail_Invoice_Type == 'Purchasing') {
                    objectsSet.add('Tax Detail Vendor Invoices');
                }
            } else if(objectsSet.contains('Customer Invoice Details')) {
			    HomeSearchFilterService.setObjectNamesForCustomerInvoiceDetails(objectsSet, filterWrapperObj);
				objectsSet = new Set<String>(HomeSearchUtil.filterListBasedOnPermissions(new List<String>(objectsSet), HomeSearchUtil.filterLabelToPermissionNameMap));
            }
		}
		// Condition for CO Deposits				
    	// Get objects where clause from Home Search screen
    	Map<String,String> objectsWhereConditions = HomeSearchReportInterface.getWhereClauseForObjects(filterWrapperObj);
    	/*if(objectsWhereConditions.containsKey('Customer Payments')) {
    		objectsWhereConditions.put('Customer Deposits', objectsWhereConditions.get('Customer Payments'));
    	}*/
    	// Create query string:
    	for(String selectedObjName : objectsSet) {
        	String objAPIName;
    	    String objQuery;
    		if(HomeSearchUtil.displayObjectNameToObjectAPINameSpecialSearchMap.containsKey(selectedObjName)) {
    	        objAPIName = HomeSearchUtil.displayObjectNameToObjectAPINameSpecialSearchMap.get(selectedObjName);
    	        objQuery = createSOQLForObject(    objAPIName, 
                                                    objectsWhereConditions.get(selectedObjName),
                                                    HomeSearchUtil.searchableObjectToUniqueValueFieldMap.get(objAPIName),
                                                    uniqueValueFieldLastValue,
                                                    pageAndSortMapping, filterWrapperObj,
                                                    selectedObjName
                                                );
    	    } else {
    	        objAPIName = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(selectedObjName);
				if (objAPINameToLastValueMap != null && objAPINameToLastValueMap.keySet().Size() > 0) {
					uniqueValueFieldLastValue = objAPINameToLastValueMap.containsKey(objAPIName) ?  objAPINameToLastValueMap.get(objAPIName) : '';
				}
				String specialObjectName = selectedObjName.contains('Customer Invoice Details') ? selectedObjName : null;
    	        objQuery = createSOQLForObject(    objAPIName, 
                                                    objectsWhereConditions.get(selectedObjName),
                                                    HomeSearchUtil.searchableObjectToUniqueValueFieldMap.get(objAPIName),
                                                    uniqueValueFieldLastValue,
                                                    pageAndSortMapping, filterWrapperObj,
                                                    specialObjectName
                                                );
                                                
    	    	if(selectedObjNames.contains('Parts to Pull') && pageAndSortMapping != null && !objQuery.containsIgnoreCase(' limit ')) {
                    objQuery += ' LIMIT ' + (pageAndSortMapping.CurrentPage * pageAndSortMapping.PageSize);
                }
    	    }
            
	    	system.debug('QUERYYYYYYY objAPIName: \n' + objQuery);
            if(selectedObjName == 'Parts Order') {
            	resultRecordsMap.put('Parts Order', (List<sObject>)Database.query(objQuery));
            } else {
		    	resultRecordsMap.put(objAPIName, (List<sObject>)Database.query(objQuery));
			}
            
        }
    	if(objectsSet.contains('Customer Deposits')) {
    		objectsSet.remove('Customer Deposits');
    	}
    	if(objectsSet.contains('AR Payments')) {
    		objectsSet.remove('AR Payments');
    	}
    	if(objectsSet.contains('Vendor Return')) {
    		objectsSet.remove('Vendor Return');
    	}
		if(objectsSet.contains('Vendor Credit')) {
			objectsSet.remove('Vendor Credit');
    	}
    	if(objectsSet.contains('SO Special Order')) {
    		objectsSet.remove('SO Special Order');
    	}
    	if(!objectsSet.contains('SOLI')) {
			objectsSet.remove('SOLI');
		}
		if(!objectsSet.contains('Option and Fee')) {
			objectsSet.remove('Option and Fee');
		}
		if(!objectsSet.contains('Part FIFO Line Item')) {
            objectsSet.remove('Part FIFO Line Item');
        }
    	return resultRecordsMap;
    }
    
    public static String createSOQLForObject(	String objName, 
    											String whereClause, 
    											String uniqueValueOrderByField, 
    											String uniqueValueFieldLastValue,
    											PaginationSorting pageAndSortMapping, HomeSearchFilterWrapper filterWrapperObj,
    											String specialObjectName
    										) {
    	
        if(AccessControl.ifObjectFieldIsAccessible(objName) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }	
    	
    	Map<String, String> childObjNameToFilterFieldName;
    	Map<String, List<HomeSearchFilterInterface.FieldFilter>> objNameToFieldFilterListMap;
    	String searchName = (HomeSearchUtil.displayObjectAPINameToObjectNameMap.get(CONSTANTS.NAMESPACE+objName));
        searchName = (String.isNotBlank(searchName) && searchName.containsIgnoreCase('Customer Unit') && filterWrapperObj.Type.Objects.contains('Inventory Unit')) ? 'Inventory Unit' : searchName;

    	if(HomeSearchUtil.searchNameToChildQueryObjNameToFieldToFilterNameMap.containsKey(searchName)) {
			childObjNameToFilterFieldName = HomeSearchUtil.searchNameToChildQueryObjNameToFieldToFilterNameMap.get(searchName);
			objNameToFieldFilterListMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
    	}
    	
    	String query = 'SELECT ';
    	Set<String> fieldSet;
    	if(String.isNotBlank(specialObjectName) && HomeSearchUtil.displayObjectNameToObjectAPINameSpecialSearchMap.containsKey(specialObjectName)
    											&& HomeSearchUtil.searchableSpecialObjectToFieldsMap.containsKey(objName)) {
    	    fieldSet = HomeSearchUtil.searchableSpecialObjectToFieldsMap.get(objName);
    	} else {
    	    fieldSet = HomeSearchUtil.searchableObjectToFieldsMap.get(objName);
    	}
    	
    	for(String fieldName : fieldSet) {	
    		if(childObjNameToFilterFieldName != null) {
    			String fieldAPIName;
    			String childObjAPIName;
    			for(String childObjName : childObjNameToFilterFieldName.keySet()) {
    				if(fieldName.contains(childObjName)) {
    					childObjAPIName = childObjName;
    					fieldAPIName = childObjNameToFilterFieldName.get(childObjName);
    					break;
    				}
    			}
    			if(String.isNotBlank(fieldAPIName)) {
    				Boolean isFieldToFilterFound = false;
    				HomeSearchFilterInterface.FieldFilter filterObj;
    				for(HomeSearchFilterInterface.FieldFilter fieldFilter : objNameToFieldFilterListMap.get(searchName)) {
    					if(fieldFilter.FieldName == fieldAPIName){
    						String actualAPIName = fieldAPIName;
	    					if(HomeSearchUtil.childObjNameToFilterFieldNameToAPIName.containsKey(childObjAPIName)) {
	    						actualAPIName = HomeSearchUtil.childObjNameToFilterFieldNameToAPIName.get(childObjAPIName).get(fieldFilter.FieldName);
	    					}
	    					if(!isFieldToFilterFound) {
	    						fieldName = fieldName.replace(')', ' WHERE ' + actualAPIName + ' ' + fieldFilter.Operator + ' ' + fieldFilter.FieldValue) + '),';
	    						query += fieldName;
	    					} else {
	    						query = query.subString(0, query.length() - 2);
	    						query += ' AND ' + actualAPIName + ' ' + fieldFilter.Operator + ' ' + fieldFilter.FieldValue + '),';
	    					}
    						
    						isFieldToFilterFound = true;
    					}
    				}
    				if(!isFieldToFilterFound) {
    					query += fieldName + ',';
    				}
    				
    			} else {
    				query += fieldName + ',';
    			}
    		} else {
    			query += fieldName + ',';
    		}
    	}
    	query = query.subString(0, query.length() - 1);
    	query += ' FROM ' + objName;
    	
    	if(whereClause != null && whereClause.trim().length() != 0) {
    		query += ' ' + whereClause;
    	}
    	
    	if(uniqueValueFieldLastValue != null && uniqueValueFieldLastValue.trim().length() != 0) {
    		if(whereClause != null && whereClause.trim().length() != 0) {
    			query += ' AND ';
    		} else {
    			query += ' WHERE ';
    		}
    		query += uniqueValueOrderByField + '>\'' + BPUtility.escapeSingleQuotes(uniqueValueFieldLastValue) + '\'';
    	}
        
    	if(pageAndSortMapping != null) {
            if(pageAndSortMapping.Sorting != null && pageAndSortMapping.Sorting.size() > 0) {
            	if(pageAndSortMapping.Sorting.size() == 1) {
            		updateSortJson(pageAndSortMapping, objName);
            	}
                String sortClause = ' ORDER BY ';
                for(PaginationSorting.SortAttrs sortAttr : pageAndSortMapping.Sorting) {
                    String sortFieldAPIName = getSortFieldNameForObject(objName, sortAttr.FieldName);
                    if(sortFieldAPIName != null && sortFieldAPIName != '' && sortFieldAPIName != 'Type') {
                        sortClause += sortFieldAPIName + ' ' + sortAttr.SortDirection + ' NULLS LAST, ';
                    }
                }
                
                if(sortClause != ' ORDER BY ') {
                    //sortClause = sortClause.subString(0, sortClause.length() - 2);
                    sortClause += ' NAME DESC '; // This is for to remove SOQL Issue. The records on page 3 and 4 are coming same.
                    query += sortClause;
                }
            }
            
            // Because we have removed pagination for "Technician Performance" Search - Added by TK -
            if(!HomeSearchUtil.objectWithNoPaginationSet.contains(objName) && 
                   !(String.isNotBlank(specialObjectName) && HomeSearchUtil.displayObjectNameToObjectAPINameSpecialSearchMap.containsKey(specialObjectName))) {
					query += ' LIMIT ' + (pageAndSortMapping.CurrentPage * pageAndSortMapping.PageSize);				
            }
        } else if(uniqueValueOrderByField != null && uniqueValueOrderByField.trim().length() != 0) {
            query += ' ORDER BY ' + uniqueValueOrderByField + ' ASC';
            query += ' LIMIT ' + QUERY_LIMIT_RECORDS;
        }
    	return query;
    }

	public static void updateSortJson(PaginationSorting pageAndSortMapping, String objName) {
		if(pageAndSortMapping.Sorting == null || pageAndSortMapping.Sorting.isEmpty()) return;
		if(pageAndSortMapping.Sorting[0].FieldName == 'LastModifiedDate__c') {
			pageAndSortMapping.Sorting[0].FieldName = 'LastModifiedDate';
		} else if(pageAndSortMapping.Sorting[0].FieldName == 'CreatedDate__c') {
			pageAndSortMapping.Sorting[0].FieldName = 'CreatedDate';
			if(objName == 'CO_Invoice_Header__c') {
				pageAndSortMapping.Sorting[0].FieldName = 'Invoice_Date__c';
			}
		}
	}
    
    /**
     * Name: getSortFieldNameForObject
     * Desc: Method to Get sort Field for object
     * @param:  (1) objName - String - Object Name
     *			(2) fieldLabel - String - Field Label
     * @return: String  
     **/
	private static String getSortFieldNameForObject(String objAPIName, String fieldLabel) {
        String fieldAPIName;
        if(fieldLabel != null 
            && HomeSearchUtil.searchableObjectToFieldsMap.containsKey(objAPIName) 
            && HomeSearchUtil.searchableObjectToFieldsMap.get(objAPIName).contains(fieldLabel)
        ){
            fieldAPIName = fieldLabel;
        } else if(fieldLabel != null 
                    && HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName.containsKey(objAPIName) 
                    && HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName.get(objAPIName).containsKey(fieldLabel)
                ) {
            fieldAPIName = HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName.get(objAPIName).get(fieldLabel);
        } else if(fieldLabel != null 
                    && HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName.containsKey(CONSTANTS.NAMESPACE + objAPIName) 
                    && HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName.get(CONSTANTS.NAMESPACE + objAPIName).containsKey(fieldLabel)
                ) {
            fieldAPIName = HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName.get(CONSTANTS.NAMESPACE + objAPIName).get(fieldLabel);
        } else if(fieldLabel != null &&
					HomeSearchUtil.groupFieldNameToObjAPINameToFieldAPINameMap.containsKey(fieldLabel) &&
					HomeSearchUtil.groupFieldNameToObjAPINameToFieldAPINameMap.get(fieldLabel).containsKey(objAPIName)) {
			
			fieldAPIName = HomeSearchUtil.groupFieldNameToObjAPINameToFieldAPINameMap.get(fieldLabel).get(objAPIName);
		}
        
        //System.debug('@@@@ fieldAPIName: ' + fieldAPIName);
        return (fieldAPIName != null) ? fieldAPIName : '';
    }
    
    public class ReportWrapper {
    	public HomeSearchResultWrapper.ResultWrapper ResultData {private set; get;}
    	public String UniqueFieldName {private set; get;}
    	public Boolean IsProcessCompleted {private set; get;}
    	public Integer TotalRecords {private set; get;}
    	public List<HomeSearchFilterInterface.FilterLabel> FilterLabelList {private set; get;}
		public Map<String, String> ObjAPINameToLastValueMap {private set; get;}
    	
    	public ReportWrapper(HomeSearchResultWrapper.ResultWrapper ResultData, 
    						 String UniqueFieldName, 
    						 Boolean IsProcessCompleted, 
    						 Integer TotalRecords,
							 List<HomeSearchFilterInterface.FilterLabel> filterLabelList,
							 Map<String, String> objAPINameToLastValueMap
    					) {
    		this.ResultData = ResultData;
    		this.UniqueFieldName = UniqueFieldName;
    		this.IsProcessCompleted = IsProcessCompleted;
    		this.TotalRecords = TotalRecords;
    		this.FilterLabelList = filterLabelList;
			this.ObjAPINameToLastValueMap = objAPINameToLastValueMap;
			
    	}
    }
}