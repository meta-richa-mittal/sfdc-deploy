/**
 * Author: Richa Mittal
 * Since: Aug 7, 2018
 * Name: COFormWrapper
 * Description: Used to convert CO Form object's serialize and deserialize operations
**/
public without sharing class COFormWrapper {
	
	public String Id;
	public String FormName;
	public String Description;
	public String CreatedDate;
	public String ModifiedDate;
	public String Source;
	public String AttachmentId;
	public String AttachmentURL;
	public Boolean IsRequired;
	public Boolean IsActive;
	public Boolean IsManualUpload;
	public Boolean IsLandscape;
	public Boolean IsEditable;
    public String FormEditConfig;
    public String EditModalName;
    public String FormId;
    public List<FormUserDefinedFieldWrapper> UserDefinedFieldsList;
    public String UserDefinedFieldsFormEditConfig;
	
	public COFormWrapper(CO_Form__c coFormRec) {
		this.Id = coFormRec.Id;
		this.FormName = coFormRec.Form_Name__c;
		this.Description = coFormRec.Description__c;
		this.CreatedDate = (coFormRec.CreatedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(coFormRec.CreatedDate.year(), 
																		coFormRec.CreatedDate.month(), coFormRec.CreatedDate.day())) : '' ;
        this.ModifiedDate = (coFormRec.LastModifiedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(coFormRec.LastModifiedDate.year(), 
															coFormRec.LastModifiedDate.month(), coFormRec.LastModifiedDate.day())) : '' ;
        this.Source = coFormRec.Source__c;
        this.IsRequired = coFormRec.Is_Required_Form__c;
        this.IsActive = false;
        this.IsManualUpload = coFormRec.Is_Manually_Uploaded__c;
        this.IsLandscape = (coFormRec.Form__c != null ? coFormRec.Form__r.Landscape_Mode__c : false);
        this.FormId = coFormRec.Form__c;
        this.UserDefinedFieldsList = coFormRec.User_Defined_Fields_Config__c == null ? new List<FormUserDefinedFieldWrapper>() 
                                        : (List<FormUserDefinedFieldWrapper>) System.JSON.deserialize(coFormRec.User_Defined_Fields_Config__c, List<FormUserDefinedFieldWrapper>.class);

	}
	
	public COFormWrapper(CO_Form__c coFormRec, Boolean isFormActive) {
		this.Id = coFormRec.Id;
		this.FormName = coFormRec.Form_Name__c;
		this.Description = coFormRec.Description__c;
		this.CreatedDate = (coFormRec.CreatedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(coFormRec.CreatedDate.year(), 
																		coFormRec.CreatedDate.month(), coFormRec.CreatedDate.day())) : '' ;
        this.ModifiedDate = (coFormRec.LastModifiedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(coFormRec.LastModifiedDate.year(), 
															coFormRec.LastModifiedDate.month(), coFormRec.LastModifiedDate.day())) : '' ;
        this.Source = coFormRec.Source__c;
        this.IsRequired = coFormRec.Is_Required_Form__c;
        this.IsActive = isFormActive;
        this.IsManualUpload = coFormRec.Is_Manually_Uploaded__c;
        this.IsEditable = coFormRec.Is_Editable__c;
        this.FormEditConfig = coFormRec.Is_Editable__c ? coFormRec.Form_Edit_Config__c : null;
        this.EditModalName = coFormRec.Edit_Modal_Name__c;
        this.IsLandscape = (coFormRec.Form__c != null ? coFormRec.Form__r.Landscape_Mode__c : false);
        this.FormId = coFormRec.Form__c;
        this.UserDefinedFieldsList = coFormRec.User_Defined_Fields_Config__c == null ? new List<FormUserDefinedFieldWrapper>() 
                                        : (List<FormUserDefinedFieldWrapper>) System.JSON.deserialize(coFormRec.User_Defined_Fields_Config__c, List<FormUserDefinedFieldWrapper>.class);
        this.UserDefinedFieldsFormEditConfig = coFormRec.User_Defined_Fields_Form_Edit_Config__c;
	}
	
	/**
     * Name: fieldsList
     * Desc: Method to get all fields related to CO_Form__c object
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList() {
        return new List<String>{'Id',
        						'Form_Name__c',
                                'Description__c',
                                'Source__c',
                                'CreatedDate',
                                'LastModifiedDate',
                                'Service_Order_Header__c',
                                'Deal__c',
                                'Deal_Finance__c',
                                'Is_Required_Form__c',
                                'Form__c',
                                'Is_Manually_Uploaded__c',
                                'Form__r.Landscape_Mode__c',
                                'Is_Editable__c',
                                'Form_Edit_Config__c',
                                'Edit_Modal_Name__c',
                                'User_Defined_Fields_Config__c',
                                'User_Defined_Fields_Form_Edit_Config__c'
                            };
    }

    public class COPrintFormWrapper {
        public String RecordId;
        public String DealItemId;
    }

    public class FormUserDefinedFieldWrapper {
        public String Label;
        public String Value;
        public Integer Order;
        public String ConfigKey;
        public String DataType;
    }
}