/**
 * Author: Tarun Khandelwal
 * Since: Aug 26, 2019 
 * Name: LocationWrapper
 * Description: Used to handle all JSON related work of Location
**/
public without sharing class LocationWrapper {
    
    public String Id;
    public String Name;
    public Boolean IsActive;
    public DateTime CreatedDate;
    
    public LocationWrapper(Location__c locationRec) {
        this.Id = locationRec.Id;
        this.Name = locationRec.Name__c;
        this.IsActive = locationRec.Active__c;
        this.CreatedDate = locationRec.CreatedDate;
    }

    public class PaginatedLocation {
        public String SortBy;
        public Boolean Reverse;
        public String LocationSearchStr;
        public Integer StartIndex;
        public Integer RecordCount;
    }
    
    public static List<String> getLocationFieldList() {
        return new List<String>{ 'Id', 
                                'Name__c',
                                'Active__c',
                                'CreatedDate'
                        };
    }
}