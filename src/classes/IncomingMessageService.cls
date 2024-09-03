/** 
* Author: Nidhi Sharma
* Since: Nov 19, 2020
* Name: IncomingMessageService 
* Description: Apex class which contains Incoming message methods.
**/
public without sharing class IncomingMessageService {
    
    public static IncomingMessageWrapper getIncomingMessagesByUser(String userId, String sortingJson) {
    	userId = String.isBlank(userId) ? UserInfo.getUserId() : userId;
    	SortingWrapper sortingObj = (SortingWrapper) System.JSON.deserialize(sortingJson, SortingWrapper.class);
    	
    	List<Message_Read_By__c> readMsgReadByList = IncomingMessageSOQLUtil.getMessageReadByRecords(new Map<String, String>{'User__c' => userId, 
    																		'Message_Status__c' => Constants.MESSAGE_STATUS_READ}, sortingObj);
    	
    	sortingObj.NumberOfRecPerPage = null;
    	List<Message_Read_By__c> unreadMsgReadByList = IncomingMessageSOQLUtil.getMessageReadByRecords(new Map<String, String>{'User__c' => userId, 
								'Message_Status__c' => Constants.MESSAGE_STATUS_UNREAD}, sortingObj);
    	
    	Set<String> customerIdSet = new Set<String>();
    	List<IncomingMessageWrapper.IncomingMessage> unreadMsgList = new List<IncomingMessageWrapper.IncomingMessage>();	
    	List<IncomingMessageWrapper.IncomingMessage> readMsgList = new List<IncomingMessageWrapper.IncomingMessage>();																
    	for(Message_Read_By__c msgRec : unreadMsgReadByList) {
    		customerIdSet.add(msgRec.Message__r.Sent_To__c);
    		unreadMsgList.add(new IncomingMessageWrapper.IncomingMessage(msgRec));
    	}	
    	for(Message_Read_By__c msgRec : readMsgReadByList) {
    		customerIdSet.add(msgRec.Message__r.Sent_To__c);
    		readMsgList.add(new IncomingMessageWrapper.IncomingMessage(msgRec));
    	}
    	readMsgReadByList = unreadMsgReadByList = null;
    	
    	List<CO_Header__c> coHeaderList = new List<CO_Header__c>();
    	if(customerIdSet.size() > 0) {
    		coHeaderList = IncomingMessageSOQLUtil.getCOHeaderListByCustomerIds(customerIdSet);
    	}
    	return new IncomingMessageWrapper(unreadMsgList, readMsgList, coHeaderList);
    }
    
    public static void toggleMessageReadStatus(String messageReadById) {
    	if(String.isNotBlank(messageReadById)) {
    		if(AccessControl.ifObjectFieldIsAccessible('Message_Read_By__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    		List<Message_Read_By__c> messageReadByList = [Select Id, Message_Status__c from Message_Read_By__c WHERE Id =: messageReadById];
    		if(messageReadByList.size() > 0) {
    			messageReadByList[0].Message_Status__c = messageReadByList[0].Message_Status__c == Constants.MESSAGE_STATUS_READ ? 
										Constants.MESSAGE_STATUS_UNREAD : Constants.MESSAGE_STATUS_READ;
				if(AccessControl.ifObjectFieldIsUpdateable('Message_Read_By__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }						
				update messageReadByList[0];
    		}
    	}
    }
    
    public static void markAllAsReadByUser(String userId) {
    	userId = String.isBlank(userId) ? UserInfo.getUserId() : userId;
    	
		if(AccessControl.ifObjectFieldIsAccessible('Message_Read_By__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Message_Read_By__c> messageReadByList = [Select Id, Message_Status__c from Message_Read_By__c where User__c =: userId 
															AND Message_Status__c =: Constants.MESSAGE_STATUS_UNREAD];
		if(messageReadByList.size() > 0) {
			for(Message_Read_By__c msgReadByRec : messageReadByList) {
				msgReadByRec.Message_Status__c = Constants.MESSAGE_STATUS_READ;
			}
        	if(AccessControl.ifObjectFieldIsUpdateable('Message_Read_By__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        	update messageReadByList;
        }
    }
    
    public static Integer getUnreadMessageCount() {
    	if(General_Configurations__c.getOrgDefaults().Enable_Two_Way_Text__c) {
    		List<AggregateResult> aggList = [Select Count(Id) unreadMsgCount from Message_Read_By__c 
    											where User__c =: UserInfo.getUserId() AND Message_Status__c = :Constants.MESSAGE_STATUS_UNREAD AND Message__r.Sent_To__c != null];
    		if(aggList.size() > 0) {
	            return (Integer) aggList[0].get('unreadMsgCount');
	        }
    	}
    	return 0;
    }
    
    public class SortingWrapper {
    	public Integer NumberOfRecPerPage = 25;
    	public String SortDirForTimeRec = 'DESC';
    }
}