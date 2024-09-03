/** 
* Author: Nidhi Sharma
* Since: Nov 19, 2020
* Name: TextMessageTemplateService 
* Description: Apex class which contains Text message template methods.
**/
public without sharing class TextMessageTemplateService {
    
    public static List<TemplateVariable> getSMSTemplateVariables() {
    	List<TemplateVariable> smsTemplateVarLabelList = new List<TemplateVariable>();
    	List<SMS_Template_Variable__mdt> smsTemplateVariableList = MetadataService.getSMSTemplateVariableList();
    	for(SMS_Template_Variable__mdt smsTemplateVariable : smsTemplateVariableList) {
    		smsTemplateVarLabelList.add(new TemplateVariable(smsTemplateVariable));
    	}
    	return smsTemplateVarLabelList;
    }
    
    public static List<String> getSMSTemplateVarLabels() {
    	List<String> smsTemplateVarLabelList = new List<String>();
    	List<SMS_Template_Variable__mdt> smsTemplateVariableList = MetadataService.getSMSTemplateVariableList();
    	for(SMS_Template_Variable__mdt smsTemplateVariable : smsTemplateVariableList) {
    		smsTemplateVarLabelList.add(smsTemplateVariable.Label);
    	}
    	return smsTemplateVarLabelList;
    }
    
    public static List<SMSTemplateWrapper> getAllSMSTemplates() {
    	return getAllSMSTemplates(true);
    }
    
    public static List<SMSTemplateWrapper> getAllSMSTemplates(Boolean isTemplateBodyNeeded) {
        List<SMSTemplateWrapper> smsTemplateObjList = new List<SMSTemplateWrapper>();
        List<Text_Message_Template__c> smsTemplateRecList = SMSTemplateSOQLUtil.getSMSTemplates(null);
        for(Text_Message_Template__c smsTemplateRec : smsTemplateRecList) {
            smsTemplateObjList.add(new SMSTemplateWrapper(smsTemplateRec, isTemplateBodyNeeded));
        }
        return smsTemplateObjList;
    }
    
    public static void saveSMSTemplate(String smsTemplateObjStr) {
    	SMSTemplateWrapper smsTemplateObj = (SMSTemplateWrapper) System.JSON.deserialize(smsTemplateObjStr, SMSTemplateWrapper.class);
    	Text_Message_Template__c smsTemplateRec = setSMSTemplateFields(smsTemplateObj);
    	try {
	    	if(String.isBlank(smsTemplateRec.Id)) {
	    		if(AccessControl.ifObjectFieldIsCreateable('Text_Message_Template__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	    		insert smsTemplateRec;
	    	} else {
	    		if(AccessControl.ifObjectFieldIsUpdateable('Text_Message_Template__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
	    		update smsTemplateRec;	
	    	}
    	} catch(DmlException e) {
    		if(e.getMessage().contains('REQUIRED_FIELD_MISSING') && e.getMessage().contains('Template_Name__c')) {
    			throw new BlackpurlException('Template name is required');
    		} else if(e.getMessage().contains('DUPLICATE_VALUE') && e.getMessage().contains('Template_Name__c')) {
    			throw new BlackpurlException('Template name already exists, please select a new template name');
    		}
    	}
    }
    
    public static void deleteSMSTemplateById(String smsTemplateId) {
    	if(String.isBlank(smsTemplateId)) throw new BlackpurlException('Invalid template id to delete - ' + smsTemplateId);
    	if(AccessControl.ifObjectIsDeletable('Text_Message_Template__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
    	delete new Text_Message_Template__c(Id = smsTemplateId);
    }
    
    private static Text_Message_Template__c setSMSTemplateFields(SMSTemplateWrapper smsTemplateObj) {
    	Text_Message_Template__c smsTemplateRec = new Text_Message_Template__c();
    	smsTemplateRec.Id = smsTemplateObj.Id;
    	smsTemplateRec.Template_Name__c = smsTemplateObj.Name;
    	smsTemplateRec.Template_Body__c = smsTemplateObj.Message;
    	return smsTemplateRec;
    }
    
    public class TemplateVariable {
    	public String Label;
    	public String Description;
    	
    	public TemplateVariable(SMS_Template_Variable__mdt smsTemplateVariable) {
    		this.Label = smsTemplateVariable.Label;
    		this.Description = smsTemplateVariable.Description__c;
    	}
    }
}