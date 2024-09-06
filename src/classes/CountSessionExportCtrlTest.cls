@isTest
private class CountSessionExportCtrlTest {
    @TestSetup
    static void setup(){
        Count_Session__c countSessionRec = new Count_Session__c();
        countSessionRec.Name__c = 'Test count';
        countSessionRec.Type__c = 'Random count';
        insert countSessionRec;

        Count_Session_Line_Item__c csliRec = new Count_Session_Line_Item__c(Count_Session__c = countSessionRec.Id);
        csliRec.Part_Number__c = 'test part';
        csliRec.Counted_Qty__c = 10;
        csliRec.Is_Counted__c = true;
        csliRec.Issue_Indicator__c = 'Invalid part';
        insert csliRec;
    }

    @isTest
    private static void testGetCountSessionReportData() {
        List<Count_Session__c> countSessionRec = [Select id from Count_Session__c limit 1];
        String id = BPUtility.getEncodedString(countSessionRec[0].id);
        String res = CountSessionExportCtrl.getCountSessionReportData(id,BPUtility.getEncodedString('Counted parts'),BPUtility.getEncodedString('Test count'));
        res = BPUtility.getDecodedString(res);
        CountSessionExportCtrl.CountSessionReportWrapper countSessionWrapperList = (CountSessionExportCtrl.CountSessionReportWrapper)
    	                                               System.json.deserialize(res, CountSessionExportCtrl.CountSessionReportWrapper.class);
        system.assertEquals(7,  countSessionWrapperList.CountSessionInfo.size());
    }


}