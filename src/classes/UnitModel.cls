/**
 * Author: Tarun Khandelwal
 * Since: May 26, 2015
 * Name: UnitModel
 * Description: Apex class to handle JSON related oprations of UnitModel object.
**/
public without sharing class UnitModel {
	
	// Id
	public String Id;
	
	// Name
	public String UnitModelName;
	
	// Sub Model
	public String SubModelName;
	
	// Model Description
	public String MakeModelDescription;
	
	// Constructor
    public UnitModel(Unit_Model__c unitModelRec) {
    	this.UnitModelName = unitModelRec.Name__c ;
    	this.Id = unitModelRec.Id;
    	this.SubModelName = unitModelRec.Sub_Model__c;
    	this.MakeModelDescription = unitModelRec.Description__c;
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> unitModelFields = new List<String>{ 'Id',
	                                                    'Name__c',
	                                                    'Sub_Model__c',
	                                                    'Description__c',
														'Unit_Make__r.Id'
                                               		 };
        return unitModelFields;
    }
}