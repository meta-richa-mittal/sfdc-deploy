/** 
* Author: Nidhi Sharma
* Since: June 14, 2021 
* Name: VendorSearchService 
* Description: Apex class which contains all search methods related to vendor.
**/
public without sharing class VendorSearchService {
    
    private static List<String> defaultFieldListToQuery = new List<String>{'Id', 'Name'};
    private static Integer limitRecord = 51;	//sending 51 to show more then 50 records found
    
    public static List<Account> getVendorsByName(List<String> queryFieldList, List<FilterJSON> filerObjList) {
    	queryFieldList = queryFieldList != null && queryFieldList.size() > 0 ? queryFieldList : defaultFieldListToQuery;
    	String query = 'SELECT ' + String.join(queryFieldList, ',') + ' FROM Account ' + SOQLUtility.getWhereClauseWithANDCondition(filerObjList, true);
        query += ' ORDER BY Name ASC LIMIT ' + limitRecord;
    	return SOQLUtility.getQueryResults('Account', query);
    }
    
    public static List<Vendor> getVendorObjList(List<Account> vendorList) {
    	List<Vendor> wrapperList = new List<Vendor>();
        for(Account vendorRec : vendorList) {
            wrapperList.add(new Vendor(vendorRec.Id, vendorRec.Name));
        }
        return wrapperList;
    }
}