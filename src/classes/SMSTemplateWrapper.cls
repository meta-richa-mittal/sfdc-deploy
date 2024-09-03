/** 
* Author: Nidhi Sharma
* Since: Nov 19, 2020
* Name: IncomingMessageWrapper 
* Description: Apex wrapper which contains Incoming message fields.
**/
public without sharing class SMSTemplateWrapper {
    public String Id;
    public String Name;
    public String Message;
    public String FormattedMessage;
    
    public SMSTemplateWrapper(Text_Message_Template__c smsTemplateRec, Boolean isTemplateBodyNeeded) {
        this.Id = smsTemplateRec.Id;
        this.Name = smsTemplateRec.Template_Name__c;
        if(isTemplateBodyNeeded) {
            this.Message = smsTemplateRec.Template_Body__c;
            // This field is used for HTML formatted text message body, used on tiles on view template page
            this.FormattedMessage = (smsTemplateRec.Template_Body__c != null ? smsTemplateRec.Template_Body__c.replace('\n', '</br>') : '');
        }
    }
    
    public static List<String> getFieldList() {
    	return new List<String>{'Id', 'Template_Name__c', 'Template_Body__c'};
    }
}