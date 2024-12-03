/** 
* Author: Nidhi Sharma
* Since: Nov 19, 2020
* Name: IncomingMessageWrapper 
* Description: Apex wrapper which contains Incoming message fields.
**/
public without sharing class IncomingMessageWrapper {
    public List<IncomingMessage> UnreadMessageList;
    public List<IncomingMessage> ReadMessageList;
    public Map<String, List<COWrapper>> CustomerIdToRelatedCOInfoListMap;
    
    public IncomingMessageWrapper(List<IncomingMessage> unreadMsgList, List<IncomingMessage> readMsgList, List<CO_Header__c> coList) {
    	this.UnreadMessageList = unreadMsgList;
    	this.ReadMessageList = readMsgList;
    	
    	this.CustomerIdToRelatedCOInfoListMap = new Map<String, List<COWrapper>>();
    	for(CO_Header__c coRec : coList) {
    		if(!this.CustomerIdToRelatedCOInfoListMap.containsKey(coRec.Customer__c)) {
    			this.CustomerIdToRelatedCOInfoListMap.put(coRec.Customer__c, new List<COWrapper>());
    		}
    		this.CustomerIdToRelatedCOInfoListMap.get(coRec.Customer__c).add(new COWrapper(coRec));
    	}
    }
    
    public class COWrapper {
    	public String Id;
    	public String Name;
    	public String SectionTotalStr;
    	
    	public COWrapper(CO_Header__c coRec) {
    		this.Id = coRec.Id;
    		this.Name = coRec.Name;
    		this.SectionTotalStr = '';
    		if(coRec.TotalNumberOfCOLI__c > 0 && (coRec.Selling_Group__c == 'Part Sale' || coRec.Selling_Group__c == 'Cash Sale' || 
    																							coRec.Selling_Group__c == 'Internal Service')) {
    			this.SectionTotalStr += 'Parts & accessories $' + BPUtility.formatToDecimal(coRec.Merchandise_Total__c);
    		}
    		if(coRec.TotalNumberOfSOHeader__c > 0) {
    			this.SectionTotalStr += (this.SectionTotalStr.length() > 0 ? ', ' : '');
    			this.SectionTotalStr += 'Service $' + BPUtility.formatToDecimal(coRec.Service_Order_Subtotal__c);
    		}
    		if(coRec.NumberOfDeals__c > 0) {
    			this.SectionTotalStr += (this.SectionTotalStr.length() > 0 ? ', ' : '');
    			this.SectionTotalStr += 'Deal $' + BPUtility.formatToDecimal(coRec.Deal_Header_Total__c);
    		}
    	}	
    }
    
    public class IncomingMessage {
    	public String MessageReadById;
    	public String Text;
    	public String CustomerName;
    	public String TimeReceived;
    	public String CustomerId;
    	public String CustomerPhone;
    	
    	public IncomingMessage(Message_Read_By__c msgReadByRec) {
    		this.MessageReadById = msgReadByRec.Id;
    		this.Text = msgReadByRec.Message__r.SMS_Body__c;
    		if(msgReadByRec.Message__r.Incoming_SMS_Time__c != null) {
    			this.TimeReceived = BPUtility.getFormatedDateAndTimeWithHypen(msgReadByRec.Message__r.Incoming_SMS_Time__c);
    		}
    		
    		if(msgReadByRec.Message__r.Sent_To__c != null) {
    			this.CustomerId = msgReadByRec.Message__r.Sent_To__c;
    			this.CustomerName = msgReadByRec.Message__r.Sent_To__r.Name;
    		}
    		this.CustomerPhone = msgReadByRec.Message__r.Formatted_Phone__c;
    	}	
    }
    
    public static List<String> getMsgReadByFieldList() {
    	return new List<String>{'Id', 
    							'Message_Status__c',
    							'Message__r.SMS_Body__c',
    							'Message__r.Sent_To__r.Name', 
    							'Message__r.Incoming_SMS_Time__c', 
    							'Message__r.Formatted_Phone__c'
    							};
    }
    
    public static List<String> getCOFieldList() {
    	return new List<String>{'Id', 
    							'Name',
    							'Merchandise_Total__c',
    							'Service_Order_Subtotal__c', 
    							'Deal_Header_Total__c', 
    							'Customer__c',
    							'TotalNumberOfCOLI__c',
    							'TotalNumberOfSOHeader__c',
    							'NumberOfDeals__c',
    							'Selling_Group__c'
    							};
    }
}