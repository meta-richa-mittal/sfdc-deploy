/** 
* Author: Nidhi Sharma
* Since: Nov 19, 2020
* Name: IncomingMessageCtrl 
* Description: Apex class which contains Incoming message methods.
**/
global without sharing class IncomingMessageCtrl {
    
    global IncomingMessageCtrl(NewHomePageCtrl controller){} 
    public IncomingMessageCtrl() {}
    
    
    @RemoteAction
    global static String getIncomingMessagesForCurrentUser(String sortingJson) {
    	sortingJson = BPUtility.getDecodedString(sortingJson);
        return BPUtility.getEncodedString(System.JSON.serialize(IncomingMessageService.getIncomingMessagesByUser(null, sortingJson), true));
    }
    
    @RemoteAction
    global static String toggleMessageReadStatus(String messageReadById) {
    	messageReadById = BPUtility.getDecodedString(messageReadById);
        IncomingMessageService.toggleMessageReadStatus(messageReadById);
        return BPUtility.getEncodedString('Success');
    }
    
    @RemoteAction
    global static String markAllAsRead() {
        IncomingMessageService.markAllAsReadByUser(null);
        return BPUtility.getEncodedString('Success');
    }
    
    @RemoteAction
    global static Integer getUnreadMessageCount() {
        return IncomingMessageService.getUnreadMessageCount();
    }
}