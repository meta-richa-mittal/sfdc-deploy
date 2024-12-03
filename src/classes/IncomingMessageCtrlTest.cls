/**
 * Author: Reena Singh
 * Since: Nov 25, 2020
 * Name: IncomingMessageCtrlTest
 * Description: Controller test Class of Incoming Message.
**/
@isTest
public without sharing class IncomingMessageCtrlTest {

    @testSetup
    private static void setup() {       
        TestDataFactory.disableFLSChecks();
        Account testCustomer = TestUtil.createCustomer(true, 'Test Customer', 'a.b@gmail.com', 'Jaipur', '987456123');
        Message_Read_By__c messageReadyBy = new Message_Read_By__c();
        Message_History__c messageHistory = new Message_History__c();
        messageHistory.Sent_To__c = testCustomer.Id;
        insert messageHistory;
        messageReadyBy.Message__c = messageHistory.Id;
        messageReadyBy.User__c = UserInfo.getUserId();
        messageReadyBy.Message_Status__c = 'Unread';
        insert messageReadyBy;

        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        generalConfig.Enable_Two_Way_Text__c = true;
        upsert generalConfig;
    }

    @isTest
    private static void getIncomingMessagesForCurrentUserTest() {
        IncomingMessageService.SortingWrapper sortingObj = new IncomingMessageService.SortingWrapper();
        sortingObj.NumberOfRecPerPage = 25;
        sortingObj.SortDirForTimeRec = 'DESC';
        Test.startTest();
        IncomingMessageCtrl controller = new IncomingMessageCtrl();
        String unReadMsg = BPUtility.getDecodedString(IncomingMessageCtrl.getIncomingMessagesForCurrentUser(BPUtility.getEncodedString(System.JSON.serialize(sortingObj))));
        System.assertNotEquals(null, unReadMsg);
        Test.stopTest();
    }

    @isTest
    private static void getIncomingReadMessagesForCurrentUserTest() {
        IncomingMessageService.SortingWrapper sortingObj = new IncomingMessageService.SortingWrapper();
        sortingObj.NumberOfRecPerPage = 25;
        sortingObj.SortDirForTimeRec = 'DESC';
        List<Message_Read_By__c> messageReadyByList = [SELECT Id, Message_Status__c, Message__r.SMS_Body__c, Message__r.Sent_To__r.Name, Message__r.Incoming_SMS_Time__c, Message__r.Formatted_Phone__c FROM Message_Read_By__c where Message__r.Sent_To__c != null AND Message_Status__c = 'Unread'];
        system.assertEquals(messageReadyByList.size(), 1);
        messageReadyByList[0].Message_Status__c = 'Read';
        update messageReadyByList[0];
        Test.startTest();
        String readMsg = BPUtility.getDecodedString(IncomingMessageCtrl.getIncomingMessagesForCurrentUser(BPUtility.getEncodedString(System.JSON.serialize(sortingObj))));
        System.assertNotEquals(null, readMsg);
        Test.stopTest();
    }

    @isTest
    private static void toggleMessageReadStatusTest() {
        List<Message_Read_By__c> messageReadByList = [Select Id, Message_Status__c from Message_Read_By__c ];
        Test.startTest();
        String result = BPUtility.getDecodedString(IncomingMessageCtrl.toggleMessageReadStatus(BPUtility.getEncodedString(messageReadByList[0].Id)));
        System.assertEquals('Success', result);
        Test.stopTest();
    }

    @isTest
    private static void markAllAsReadTest() {
        List<Message_Read_By__c> messageReadByList = [Select Id, Message_Status__c from Message_Read_By__c where Message_Status__c = 'Unread'];
        system.assertEquals(messageReadByList.size(), 1);
        system.assertEquals(messageReadByList[0].Message_Status__c, 'Unread');
        Test.startTest();
        String result = BPUtility.getDecodedString(IncomingMessageCtrl.markAllAsRead());
        system.assertEquals('Success',result);
    	Test.stopTest();
    }

    @isTest
    private static void getUnreadMessageCountTest() {
        List<Message_Read_By__c> messageReadByList = [SELECT Id, Message_Status__c FROM Message_Read_By__c WHERE Message_Status__c = 'Unread' AND User__c =: UserInfo.getUserId()];
        system.assertEquals(messageReadByList.size() > 0, true);
        Test.startTest();
        System.assertEquals(1, IncomingMessageCtrl.getUnreadMessageCount());
    	Test.stopTest();
    }

    @isTest
    private static void getUnreadMessageCountForZeroTest() {
        General_Configurations__c generalConfig = General_Configurations__c.getOrgDefaults();
        generalConfig.Enable_Two_Way_Text__c = false;
        upsert generalConfig;
        Test.startTest();
        System.assertEquals(0, IncomingMessageCtrl.getUnreadMessageCount());
    	Test.stopTest();
    }

}