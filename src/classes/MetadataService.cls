/*
* Name : MetadataService
* Date : 18 July 2019
* Desc : Service Class for Custom Metadata
*/
public class MetadataService {
	
	/**
     * Name: getAllExemptFeeOnFormList
     * Desc: To get all all ExemptFeeOnForm records from Database by executing query
     * @param: (1) 
     * @return: List of all ExemptFeeOnForm records
    **/
    public static List<Sobject> getAllExemptFeeOnFormList() {
        String query = 'SELECT Id, Label FROM Exempt_Fee_On_Form__mdt';
        List<Exempt_Fee_On_Form__mdt> exemptFeeOnFormsList = Database.query(query);
        return exemptFeeOnFormsList;
    }
    
    public static List<SMS_Template_Variable__mdt> getSMSTemplateVariableList() { 
        return [Select Order_Number__c, Label, Description__c from SMS_Template_Variable__mdt where Active__c = true Order by Order_Number__c ASC];
    }
}