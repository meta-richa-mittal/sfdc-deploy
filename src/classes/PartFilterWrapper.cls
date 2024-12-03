/** 
* Author: Nidhi Sharma
* Since: June 14, 2021 
* Name: PartFilterWrapper 
* Description: Apex class which contains all search methods related to vendor.
**/
public without sharing class PartFilterWrapper {
	
	public Integer StartIndex;
	public Integer RecordCount;
	public String PartItemDesc;
	public List<String> VendorList;
	public List<String> TagList;
	public List<String> CategoryList;
	public String StartDateCreated;
	public String EndDateCreated;
	public String HardCodedWhereClause;
}