/** 
* Author: Nidhi Sharma
* Since: June 3, 2021 
* Name: WebsiteProductManagementSOQLUtil 
* Description: Apex class which contains all soql queried related to Website_Product__c object.
**/
public without sharing class WebsiteProductManagementSOQLUtil {
	
    public static List<Website_Product__c> getAllProducts(WebsiteProductFilterWrapper filterObj) {
    	String query = 'SELECT ' + String.join(WebsiteProductWrapper.fieldsList, ', ') + ' FROM Website_Product__c' + getWhereClauseByFilterStr(filterObj);
    	query += ' ORDER BY Title__c ASC, Variant_Position__c ASC ' + SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);
    	List<SObject> sobjList = SOQLUtility.getQueryResults('Website_Product__c', query);
    	
    	if(filterObj.StartIndex != null && filterObj.StartIndex > 2000 && filterObj.RecordCount != null) {
    		sobjList = SOQLUtility.getLimitRecordsBasedOnRecordCount(sobjList, filterObj.StartIndex);
    	}
    	return sobjList;
    }
    
    public static List<AggregateResult> getProductStatics(WebsiteProductFilterWrapper filterObj) {
    	String query = 'SELECT Count(Id) ProductCount FROM Website_Product__c' + getWhereClauseByFilterStr(filterObj);
    	return SOQLUtility.getQueryResults('Website_Product__c', query);
    }
    
    private static String getWhereClauseByFilterStr(WebsiteProductFilterWrapper filterObj) {
    	List<String> filterStrList = new List<String>{'Delete_Pending__c = false'};
    	
    	if(filterObj != null) {
	    	if(filterObj.productVendorList != null && !filterObj.productVendorList.isEmpty()) {
	    	    filterObj.productVendorList = BPUtility.escapeSingleQuotes(filterObj.productVendorList);
	    		filterStrList.add('Product_Vendor__c IN ' + SOQLUtility.convertListToStringForWhereClause(filterObj.productVendorList));
	    	}
	    	if(filterObj.statusList != null && !filterObj.statusList.isEmpty()) {
	    		filterStrList.add('Status__c IN ' + SOQLUtility.convertListToStringForWhereClause(filterObj.statusList));
	    	}
	    	if(String.isNotBlank(filterObj.SearchKeyword)) {
                filterObj.SearchKeyword = BPUtility.escapeSingleQuotes(filterObj.SearchKeyword.trim());
                filterStrList.add('(Title__c LIKE \'' + filterObj.SearchKeyword + '%\' OR Variant_Options__c LIKE \'' + filterObj.SearchKeyword + '%\')');
	    	}
	    	if(!isFirstCall(filterObj)) {
	    		String createdBefore = Datetime.valueOf(filterObj.dateTimeWhenSearchExecuted).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
	    		system.debug('createdBefore::' + createdBefore);
	    		filterStrList.add('CreatedDate <= ' + createdBefore);
	    	}
	    	if(String.isNotBlank(filterObj.ShopifyProductId)) {
                filterObj.ShopifyProductId = filterObj.ShopifyProductId.trim();
                filterStrList.add('(Product_Id__c = \'' + filterObj.ShopifyProductId + '\')');
	    	}
    	}
    	return (!filterStrList.isEmpty() ? ' WHERE ' + String.join(filterStrList, ' AND ') : '');
    }
    
    private static Boolean isFirstCall(WebsiteProductFilterWrapper filterObj) {
    	return (String.isBlank(filterObj.dateTimeWhenSearchExecuted) || filterObj.StartIndex == null || filterObj.StartIndex == 0);
    }
    
    public static List<String> getProductVendor(String searchKeyword) {
    	List<String> productVendorList = new List<String>();
    	if(String.isNotBlank(searchKeyword) && searchKeyword.length() >= 3) {
	    	String query = 'SELECT Product_Vendor__c FROM Website_Product__c where Product_Vendor__c Like \'%' + searchKeyword + '%\' group By Product_Vendor__c ' +
	    		'LIMIT ' + SOQLUtility.getAvailableQueryRowsLimit();
	    	List<AggregateResult> aggResults = Database.query(query);
	    	for(AggregateResult aggResult : aggResults) {
	    		productVendorList.add(String.valueOf(aggResult.get(Constants.NAMESPACE + 'Product_Vendor__c')));
	    	}
    	}
    	return productVendorList;
    }
    
    public static List<Website_Product__c> getProductVariantsByProductId(String websiteProductId) {
        String query = 'SELECT ' + String.join(WebsiteProductVariantWrapper.fieldList, ', ') + ' FROM Website_Product__c ' + 
                            SOQLUtility.getWhereClause(new Map<String, String>{'Product_Id__c' => websiteProductId}, false);
        query += ' ORDER BY Title__c ASC, Variant_Position__c ASC Limit ' + SOQLUtility.getAvailableQueryRowsLimit();
        return SOQLUtility.getQueryResults('Website_Product__c', query);
    }

	public static List<Website_Product__c> getProductVariantsByPartId(String partId) {
	    if(!AccessControl.ifObjectFieldIsAccessible('Part__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Part__c> partList = [SELECT Shopify_Product__r.Product_Id__c FROM Part__c WHERE Id =: partId Limit 1];
        
        List<Website_Product__c> variantList = new List<Website_Product__c>();
		if(partList.size() > 0 && String.isNotBlank(partList[0].Shopify_Product__r.Product_Id__c)) {
			String query = 'SELECT ' + String.join(WebsiteProductVariantWrapper.fieldList, ', ') + ' FROM Website_Product__c ' +
						SOQLUtility.getWhereClause(new Map<String, String>{'Product_Id__c' => partList[0].Shopify_Product__r.Product_Id__c}, false);
			query += ' ORDER BY Title__c ASC, Variant_Position__c ASC Limit ' + SOQLUtility.getAvailableQueryRowsLimit();
			variantList = SOQLUtility.getQueryResults('Website_Product__c', query);
		} 
		return variantList;
	}
}