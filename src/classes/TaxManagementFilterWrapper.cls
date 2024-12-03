/** 
* Author: Balveer Choudhary
* Since: Nov 22, 2022 
* Name: FilterJSON 
* Description: Apex class which contains fields to filtr Tax rates and Tax codes.
**/
public without sharing class TaxManagementFilterWrapper {
	public Integer StartIndex;
	public Integer RecordCount;
	public String SearchKeyword;	//Searching in Tax rates and Tax codes
    public Boolean IsTaxRate;
    public Boolean IsTaxCode;
	public String TransectionType;
	public Boolean IncludeInactive;
	public Boolean IncludeAutomatedRates;
}