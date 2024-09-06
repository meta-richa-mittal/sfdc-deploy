public without sharing class MessageHistoryService {
    
    public static void addMessageHistoryRecord(String customerId, PlivoIncomingMessageService.MessageWrapper messageObj) {
    	List<Message_History__c> msgUUIDList = [Select Id from Message_History__c where Message_UUID__c =: messageObj.MessageUUID];
    	if(msgUUIDList.size() == 0) {
	        Message_History__c messageRec = new Message_History__c();
	        messageRec.Activity__c = Constants.MESSAGE_HISTORY_ACTIVITY_TEXT_MESSAGE;
	        messageRec.Sent_To__c = customerId;
	        messageRec.Text__c = messageObj.MessageText;
	        messageRec.SMS_Direction__c = Constants.SMS_DIRECTION_REPLY;
	        messageRec.Message_UUID__c = messageObj.MessageUUID;
	        messageRec.Phone__c = messageObj.CustomerPhone;
	        messageRec.Incoming_SMS_Time__c = system.now();
	        messageRec.Dealership_Phone__c = messageObj.DealershipPhone;
	        if(AccessControl.ifObjectFieldIsCreateable('Message_History__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	        insert messageRec;
	        
	        createMessageReadByRecords(messageRec.Id);
    	}
    }
    
    public static List<CustomerDetail.MessageHistory> getTextHistory(String customerId, String coHeaderId) {
    	List<CO_Header__c> coHeaderList = [SELECT CreatedDate, Order_Closed_Date__c FROM CO_Header__c WHERE Id =: coHeaderId];
    	if(coHeaderList.size() == 0) throw new BlackPurlException('Invalid CO Id');
    	
    	List<Message_History__c> messageHistoryList = [SELECT Text__c, Incoming_SMS_Time__c, CreatedDate, SMS_Direction__c, 
    													SMS_Sent_From__c, Formatted_Phone__c, CO_Header__r.Name, Sent_To__c 
    													FROM Message_History__c WHERE Activity__c = :Constants.MESSAGE_HISTORY_ACTIVITY_TEXT_MESSAGE AND Sent_To__c =: customerId 
    													AND ((SMS_Direction__c = :Constants.SMS_DIRECTION_SENT AND CreatedDate >= :coHeaderList[0].CreatedDate) 
    													OR (SMS_Direction__c = :Constants.SMS_DIRECTION_REPLY AND Incoming_SMS_Time__c >= :coHeaderList[0].CreatedDate)) 
    													AND CreatedDate <= :coHeaderList[0].Order_Closed_Date__c 
    													order by CreatedDate desc];
    													
    	List<CustomerDetail.MessageHistory> messageHistoryWrapperList = new List<CustomerDetail.MessageHistory>();
    	for(Message_History__c msgRec: messageHistoryList) {
    		messageHistoryWrapperList.add(new CustomerDetail.MessageHistory(msgRec, true));
    	}
    	
    	return messageHistoryWrapperList;
    }
    
    private static void createMessageReadByRecords(String messageRecId) {
    	if(General_Configurations__c.getInstance().Enable_Two_Way_Text__c) {
	        List<User> userList = [Select Id from User where Id IN (Select User__c from User_To_Group__c where User_Group__r.View_Incoming_Text_Messages__c = 'Primary')];
	        List<Message_Read_By__c> messageReadbyListToInsert = new List<Message_Read_By__c>();
	        
	        for(User useRec : userList) {
	        	Message_Read_By__c msgReadByRec = new Message_Read_By__c();
	        	msgReadByRec.User__c = useRec.Id;
	        	msgReadByRec.Message__c = messageRecId;
	        	msgReadByRec.Message_Status__c = Constants.MESSAGE_STATUS_UNREAD;
	        	messageReadbyListToInsert.add(msgReadByRec);
	        }
	        if(messageReadbyListToInsert.size() > 0) {
	        	if(AccessControl.ifObjectFieldIsCreateable('Message_Read_By__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
	        	insert messageReadbyListToInsert;
	        }
    	}
    }
}