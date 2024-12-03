/** 
* Author: Nidhi Sharma
* Since: June 11, 2021 
* Name: FilterJSON 
* Description: Apex class which contains filter json wrapper for query.
**/
public without sharing class FilterJSON {
    public String Field;
    public String Operator;
    public String Value;
    
    public FilterJSON(String field, String operator, String value) {
        this.Field = field;
        this.Operator = operator;
        this.Value = value;
     }
}